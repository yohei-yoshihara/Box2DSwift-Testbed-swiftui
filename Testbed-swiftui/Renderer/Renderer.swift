/**
 Copyright (c) 2006-2014 Erin Catto http://www.box2d.org
 Copyright (c) 2015 - Yohei Yoshihara
 
 This software is provided 'as-is', without any express or implied
 warranty.  In no event will the authors be held liable for any damages
 arising from the use of this software.
 
 Permission is granted to anyone to use this software for any purpose,
 including commercial applications, and to alter it and redistribute it
 freely, subject to the following restrictions:
 
 1. The origin of this software must not be misrepresented; you must not
 claim that you wrote the original software. If you use this software
 in a product, an acknowledgment in the product documentation would be
 appreciated but is not required.
 
 2. Altered source versions must be plainly marked as such, and must not be
 misrepresented as being the original software.
 
 3. This notice may not be removed or altered from any source distribution.
 
 This version of box2d was developed by Yohei Yoshihara. It is based upon
 the original C++ code written by Erin Catto.
 */

import SwiftUI
import Foundation
import QuartzCore
import Metal
import MetalKit
import simd
import Box2D

let VertexAttributeLocation: GLuint = 0

let maxNumberOfVertices = 65536

let MaxFramesInFlight = 3

struct Vertex {
  var pos: SIMD2<Float>
  var color: SIMD4<Float>
  
  init(x: Float, y: Float, r: Float, g: Float, b: Float, a: Float) {
    self.pos = SIMD2<Float>(x, y)
    self.color = SIMD4<Float>(r, g, b, a)
  }
  
  init(pos: SIMD2<Float>, color: SIMD4<Float>) {
    self.pos = pos
    self.color = color
  }
}

enum DrawMode {
  case lineLoop
  case triangleFan
  case lines
  case points
}

enum DrawCommand {
  case lineLoop(start: Int, count: Int)
  case triangleFan(start: Int, count: Int)
  case lines(start: Int, count: Int)
  case points(start: Int, count: Int)
}

class Renderer : NSObject, b2Draw, MTKViewDelegate {
  class WorkSet {
    var commands = [DrawCommand]()
    var numberOfVertices = 0
    var vertexBuffer: MTLBuffer
    var uniforms = Uniforms()
    var color = SIMD4<Float>(0, 0, 0, 0)
    var pointSize: Float = 0.0
    
    init(vertexBuffer: MTLBuffer) {
      self.vertexBuffer = vertexBuffer
    }
    
    func clear() {
      commands.removeAll(keepingCapacity: true)
      numberOfVertices = 0
    }
  }
  
  let inFlightSemaphore  = DispatchSemaphore(value: MaxFramesInFlight)
  var workSets = [WorkSet]()
  var currentBuffer = 0

  var viewportSize = vector_uint2(0, 0)
  var viewSize: CGSize = .zero

  var metalKitView: MTKView
  var device: MTLDevice
  var pipelineState: MTLRenderPipelineState
  var commandQueue: MTLCommandQueue
  var testCase: TestCase
  var world: b2World?
  var groundBody: b2Body?
  var contactListener: ContactListener?
  var bombLauncher: BombLauncher?
  var mouseJoint: b2MouseJoint?
  
  var settings: Settings

  init(metalKitView: MTKView, testCase: TestCase, settings: Settings) {
    self.metalKitView = metalKitView
    guard let device = metalKitView.device else {
      fatalError("device is nil")
    }
    self.device = device
    self.testCase = testCase
    self.settings = settings

    let defaultLibrary = device.makeDefaultLibrary()!
    let vertexFunction = defaultLibrary.makeFunction(name: "vertexShader")
    let fragmentFunction = defaultLibrary.makeFunction(name: "fragmentShader")
    
    let vertexDescriptor = MTLVertexDescriptor()
    vertexDescriptor.attributes[0].format = .float3
    vertexDescriptor.attributes[0].bufferIndex = 0
    vertexDescriptor.attributes[0].offset = 0
    vertexDescriptor.attributes[1].format = .float4
    vertexDescriptor.attributes[1].bufferIndex = 0
    vertexDescriptor.attributes[1].offset = MemoryLayout<SIMD3<Float>>.stride
    vertexDescriptor.layouts[0].stride = MemoryLayout<Vertex>.stride
    vertexDescriptor.layouts[0].stepFunction = .perVertex
    
    let pipelineStateDescriptor = MTLRenderPipelineDescriptor()
    pipelineStateDescriptor.label = "Pipeline"
    pipelineStateDescriptor.vertexFunction = vertexFunction
    pipelineStateDescriptor.fragmentFunction = fragmentFunction
    pipelineStateDescriptor.colorAttachments[0].pixelFormat = metalKitView.colorPixelFormat
    pipelineStateDescriptor.vertexDescriptor = vertexDescriptor
    
    guard let pipelineState = try? device.makeRenderPipelineState(descriptor: pipelineStateDescriptor) else {
      fatalError("failed to create pipeline state")
    }
    self.pipelineState = pipelineState
    
    guard let commandQueue = device.makeCommandQueue() else {
      fatalError("failed to make a command queue")
    }
    self.commandQueue = commandQueue
    
    for i in 0 ..< MaxFramesInFlight {
      let size = MemoryLayout<Vertex>.stride * maxNumberOfVertices
      guard let vertexBuffer = device.makeBuffer(length: size,
                                                 options: [.storageModeShared]) else {
        fatalError("failed to make a vertex buffer")
      }
      vertexBuffer.label = "Vertex Buffer \(i)"
      vertexBuffer.contents().withMemoryRebound(to: Vertex.self, capacity: maxNumberOfVertices) { pointer in
        pointer[0].pos = SIMD2<Float>(0, 0)
        pointer[0].color = SIMD4<Float>(0, 0, 0, 0)
      }
      workSets.append(WorkSet(vertexBuffer: vertexBuffer))
    }
    
    super.init()
    initialize()
    metalKitView.delegate = self
  }
  
  func initialize() {
    metalKitView.preferredFramesPerSecond = settings.hz.rawValue

    let gravity = b2Vec2(0.0, -10.0)
    let world = b2World(gravity: gravity)
    let contactListener = ContactListener()
    world.setContactListener(contactListener)
    world.setDebugDraw(self)
    setFlags(settings.debugDrawFlag)
    
    let bombLauncher = BombLauncher(world: world, renderView: self, viewCenter: settings.viewCenter)
    
    testCase.world = world
    testCase.bombLauncher = bombLauncher
    testCase.contactListener = contactListener
    testCase.stepCount = 0
    testCase.debugDraw = self
    testCase.settings = settings
    
    let bodyDef = b2BodyDef()
    groundBody = world.createBody(bodyDef)
    
    testCase.prepare()
    
    self.world = world
    self.contactListener = contactListener
    self.bombLauncher = bombLauncher
  }
  
  func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
    viewportSize.x = UInt32(size.width)
    viewportSize.y = UInt32(size.height)
  }
  
  func preRender(in view: MTKView) {
    inFlightSemaphore.wait()
    currentBuffer = (currentBuffer + 1) % MaxFramesInFlight
    
    workSets[currentBuffer].clear()
  }
  
  func draw(mode: DrawMode, vertices: [SIMD2<Float>]) {
    if vertices.isEmpty { return }
    
    let color = workSets[currentBuffer].color
    
    switch mode {
    case .lineLoop:
      // Metal does not support line loop, emulate with line strip
      var subvertices = [Vertex]()
      for vertex in vertices {
        subvertices.append(Vertex(pos: vertex, color: workSets[currentBuffer].color))
      }
      subvertices.append(Vertex(pos: vertices[0], color: workSets[currentBuffer].color))
      
      let start = workSets[currentBuffer].numberOfVertices
      let count = subvertices.count
      
      workSets[currentBuffer].vertexBuffer.contents().withMemoryRebound(to: Vertex.self, capacity: maxNumberOfVertices) { pointer in
        for i in 0 ..< subvertices.count {
          pointer[start + i] = subvertices[i]
        }
      }
      
      let command = DrawCommand.lineLoop(start: start, count: count)
      workSets[currentBuffer].commands.append(command)
      
      workSets[currentBuffer].numberOfVertices += count
      break
      
    case .triangleFan:
      guard vertices.count > 2 else {
        fatalError("to draw triangle fan, vertex data must have at least 3 vertices")
      }
      // Metal does not support triangle fan, emulate with triangles
      var subvertices = [Vertex]()
      subvertices.reserveCapacity((vertices.count - 2) * 3)
      let v0 = vertices[0]
      var v1 = vertices[1]
      for i in 2 ..< vertices.count {
        subvertices.append(Vertex(pos: v0, color: color))
        subvertices.append(Vertex(pos: v1, color: color))
        subvertices.append(Vertex(pos: vertices[i], color: color))
        v1 = vertices[i]
      }
      let start = workSets[currentBuffer].numberOfVertices
      let count = subvertices.count
      
      workSets[currentBuffer].vertexBuffer.contents().withMemoryRebound(to: Vertex.self, capacity: maxNumberOfVertices) { pointer in
        for i in 0 ..< subvertices.count {
          pointer[start + i] = subvertices[i]
        }
      }
      
      let command = DrawCommand.triangleFan(start: start, count: count)
      workSets[currentBuffer].commands.append(command)
      
      workSets[currentBuffer].numberOfVertices += count
      break
      
    case .lines:
      var subvertices = [Vertex]()
      subvertices.reserveCapacity(vertices.count)
      for vertex in vertices {
        subvertices.append(Vertex(pos: vertex, color: color))
      }
      let start = workSets[currentBuffer].numberOfVertices
      let count = subvertices.count
      
      workSets[currentBuffer].vertexBuffer.contents().withMemoryRebound(to: Vertex.self, capacity: maxNumberOfVertices) { pointer in
        for i in 0 ..< subvertices.count {
          pointer[start + i] = subvertices[i]
        }
      }
      
      let command = DrawCommand.lines(start: start, count: count)
      workSets[currentBuffer].commands.append(command)
      
      workSets[currentBuffer].numberOfVertices += count
      break
      
    case .points:
      guard workSets[currentBuffer].pointSize > 0 else {
        fatalError("pointSize must be more than 0 to draw points")
      }
      let sx = workSets[currentBuffer].uniforms.mvp[0].x
      let sy = workSets[currentBuffer].uniforms.mvp[1].y
      let halfX: Float = (workSets[currentBuffer].pointSize / Float(2.0)) * sx
      let halfY: Float = (workSets[currentBuffer].pointSize / Float(2.0)) * sy

      var subvertices = [Vertex]()
      for vertex in vertices {
        let v0 = SIMD2<Float>(vertex.x - halfX, vertex.y - halfY)
        let v1 = SIMD2<Float>(vertex.x + halfX, vertex.y - halfY)
        let v2 = SIMD2<Float>(vertex.x - halfX, vertex.y + halfY)
        let v3 = SIMD2<Float>(vertex.x + halfX, vertex.y + halfY)
        subvertices.append(Vertex(pos: v0, color: color))
        subvertices.append(Vertex(pos: v1, color: color))
        subvertices.append(Vertex(pos: v2, color: color))
        
        subvertices.append(Vertex(pos: v1, color: color))
        subvertices.append(Vertex(pos: v2, color: color))
        subvertices.append(Vertex(pos: v3, color: color))
      }
      let start = workSets[currentBuffer].numberOfVertices
      let count = subvertices.count
      
      workSets[currentBuffer].vertexBuffer.contents().withMemoryRebound(to: Vertex.self, capacity: maxNumberOfVertices) { pointer in
        for i in 0 ..< subvertices.count {
          pointer[start + i] = subvertices[i]
        }
      }
      
      let command = DrawCommand.points(start: start, count: count)
      workSets[currentBuffer].commands.append(command)
      
      workSets[currentBuffer].numberOfVertices += count
      break
    }
  }
  
  func postRender(in view: MTKView) {
    let commandBuffer = commandQueue.makeCommandBuffer()!
    commandBuffer.label = "Command"
    
    let renderPassDescriptor = view.currentRenderPassDescriptor!
    
    let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor)!
    renderEncoder.label = "RenderEncoder"
    renderEncoder.setViewport(MTLViewport(originX: 0.0, originY: 0.0, width: Double(viewportSize.x), height: Double(viewportSize.y), znear: -1.0, zfar: 1.0))
    renderEncoder.setRenderPipelineState(pipelineState)
    renderEncoder.setVertexBuffer(workSets[currentBuffer].vertexBuffer,
                                  offset: 0,
                                  index: Int(VertexBuffer.rawValue))
    
    renderEncoder.setVertexBytes(&workSets[currentBuffer].uniforms,
                                 length: MemoryLayout<Uniforms>.size,
                                 index: Int(UniformsBuffer.rawValue))
    
    for command in workSets[currentBuffer].commands {
      switch command {
      case .lineLoop(start: let start, count: let count):
        renderEncoder.drawPrimitives(type: .lineStrip, vertexStart: start, vertexCount: count)
      case .triangleFan(start: let start, count: let count):
        renderEncoder.drawPrimitives(type: .triangle, vertexStart: start, vertexCount: count)
      case .lines(start: let start, count: let count):
        renderEncoder.drawPrimitives(type: .line, vertexStart: start, vertexCount: count)
      case .points(start: let start, count: let count):
        renderEncoder.drawPrimitives(type: .triangle, vertexStart: start, vertexCount: count)
      }
    }
    
    renderEncoder.endEncoding()
    
    commandBuffer.present(view.currentDrawable!)
    
    commandBuffer.addCompletedHandler { commandBuffer in
      self.inFlightSemaphore.signal()
    }
    
    commandBuffer.commit()
  }
  
  func setOrtho2D(left: Float, right: Float, bottom: Float, top: Float) {
    //    let zNear: GLfloat = -1.0
    //    let zFar: GLfloat = 1.0
    //    let inv_z: GLfloat = 1.0 / (zFar - zNear)
    let inv_y: Float = 1.0 / (top - bottom)
    let inv_x: Float = 1.0 / (right - left)
    //    var mat33: [GLfloat] = [
    //      2.0 * inv_x,
    //      0.0,
    //      0.0,
    //
    //      0.0,
    //      2.0 * inv_y,
    //      0.0,
    //
    //      -(right + left) * inv_x,
    //      -(top + bottom) * inv_y,
    //      1.0
    //    ]
    let mat33: simd_float3x3 = simd_float3x3([
      SIMD3<Float>(
        Float(2.0 * inv_x),
        0.0,
        0.0
      ),
      SIMD3<Float>(
        0.0,
        2.0 * inv_y,
        0.0
      ),
      SIMD3<Float>(
        -(right + left) * inv_x,
         -(top + bottom) * inv_y,
         1.0
      )])
    
    workSets[currentBuffer].uniforms.mvp = mat33
  }
  
  func setColor(red: Float, green: Float, blue: Float, alpha: Float) {
    workSets[currentBuffer].color = SIMD4<Float>(red, green, blue, alpha)
  }
  
  func setPointSize(_ pointSize: Float) {
    workSets[currentBuffer].pointSize = pointSize
  }
  
  func enableBlend() {
    //    glEnable(GLenum(GL_BLEND))
    //    glBlendFunc(GLenum(GL_SRC_ALPHA), GLenum(GL_ONE_MINUS_SRC_ALPHA))
  }
  
  func disableBlend() {
    //    glDisable(GLenum(GL_BLEND))
  }

  // MARK: move some codes from RenderView to here
  
  var vertexData = [SIMD2<Float>]()
  var left: b2Float = -1
  var right: b2Float = 1
  var bottom: b2Float = -1
  var top: b2Float = 1
  
//  func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
//    renderer.mtkView(view, drawableSizeWillChange: size)
//  }
//  
  func draw(in view: MTKView) {
    preRender(in: view)
    setOrtho2D(left: left, right: right, bottom: bottom, top: top)
    simulationLoop()
    postRender(in: view)
  }

  func preRender() {
  }
  
  func simulationLoop() {
    guard let world else { return }
    updateCoordinate()
    bombLauncher?.render()
    let timeStep = settings.calcTimeStep()
    settings.apply(world)
    contactListener?.clearPoints()
    world.step(timeStep: timeStep,
               velocityIterations: settings.velocityIterations,
               positionIterations: settings.positionIterations)
    world.drawDebugData()
    
    if timeStep > 0.0 {
      testCase.stepCount += 1
    }
    
    contactListener?.drawContactPoints(settings, renderer: self)
    
    testCase.step()
  }
  
  func postRender() {
  }

  func updateCoordinate() {
    let (lower, upper) = calcViewBounds(viewSize: viewSize,
                                        viewCenter: settings.viewCenter,
                                        extents: Settings.extents)
    setOrtho2D(left: lower.x, right: upper.x, bottom: lower.y, top: upper.y)
  }

//  func setOrtho2D(left: b2Float, right: b2Float, bottom: b2Float, top: b2Float) {
//    self.left = left
//    self.right = right
//    self.bottom = bottom
//    self.top = top
//  }
  
  // MARK: - b2Draw
  
  /// Set the drawing flags.
  func setFlags(_ flags : UInt32) {
    m_drawFlags = flags
  }
  
  /// Get the drawing flags.
  var flags: UInt32 {
    get {
      return m_drawFlags
    }
  }
  
  /// Append flags to the current flags.
  func appendFlags(_ flags : UInt32) {
    m_drawFlags |= flags
  }
  
  /// Clear flags from the current flags.
  func clearFlags(_ flags : UInt32) {
    m_drawFlags &= ~flags
  }
  
  /// Draw a closed polygon provided in CCW order.
  func drawPolygon(_ vertices: [b2Vec2], _ color: b2Color) {
    vertexData.removeAll(keepingCapacity: true)
    for v in vertices {
      vertexData.append(SIMD2<Float>(v.x, v.y))
    }
    setColor(red: color.r, green: color.g, blue: color.b, alpha: 1.0)
    draw(mode: .lineLoop, vertices: vertexData)
  }
  
  /// Draw a solid closed polygon provided in CCW order.
  func drawSolidPolygon(_ vertices: [b2Vec2], _ color: b2Color) {
    vertexData.removeAll(keepingCapacity: true)
    for v in vertices {
      vertexData.append(SIMD2<Float>(v.x, v.y))
    }
    enableBlend()
    setColor(red: 0.5 * color.r, green: 0.5 * color.g, blue: 0.5 * color.b, alpha: 0.5)
    draw(mode: .triangleFan, vertices: vertexData)
    disableBlend()
    
    setColor(red: color.r, green: color.g, blue: color.b, alpha: 1.0)
    draw(mode: .lineLoop, vertices: vertexData)
  }
  
  /// Draw a circle.
  func drawCircle(_ center: b2Vec2, _ radius: b2Float, _ color: b2Color) {
    let k_segments = 16
    let k_increment: b2Float = b2Float(2.0 * 3.14159265) / b2Float(k_segments)
    var theta: b2Float = 0.0
    vertexData.removeAll(keepingCapacity: true)
    for _ in 0 ..< k_segments {
      let v = center + radius * b2Vec2(cosf(theta), sinf(theta))
      vertexData.append(SIMD2<Float>(v.x, v.y))
      theta += k_increment
    }
    setColor(red: color.r, green: color.g, blue: color.b, alpha: 1.0)
    draw(mode: .lineLoop, vertices: vertexData)
  }
  
  /// Draw a solid circle.
  func drawSolidCircle(_ center: b2Vec2, _ radius: b2Float, _ axis: b2Vec2, _ color: b2Color) {
    let k_segments = 16
    let k_increment: b2Float = b2Float(2.0 * 3.14159265) / b2Float(k_segments)
    var theta: b2Float = 0.0
    vertexData.removeAll(keepingCapacity: true)
    for _ in 0 ..< k_segments {
      let v = center + radius * b2Vec2(cosf(theta), sinf(theta))
      vertexData.append(SIMD2<Float>(v.x, v.y))
      theta += k_increment
    }
    
    enableBlend()
    setColor(red: 0.5 * color.r, green: 0.5 * color.g, blue: 0.5 * color.b, alpha: 0.5)
    draw(mode: .triangleFan, vertices: vertexData)
    disableBlend()

    setColor(red: color.r, green: color.g, blue: color.b, alpha: 1.0)
    draw(mode: .lineLoop, vertices: vertexData)
    
    let p = center + radius * axis
    vertexData.removeAll(keepingCapacity: true)
    vertexData.append(SIMD2<Float>(center.x, center.y))
    vertexData.append(SIMD2<Float>(p.x, p.y))
    
    setColor(red: color.r, green: color.g, blue: color.b, alpha: 1.0)
    draw(mode: .lines, vertices: vertexData)
  }
  
  /// Draw a line segment.
  func drawSegment(_ p1: b2Vec2, _ p2: b2Vec2, _ color: b2Color) {
    vertexData.removeAll(keepingCapacity: true)
    vertexData.append(SIMD2<Float>(p1.x, p1.y))
    vertexData.append(SIMD2<Float>(p2.x, p2.y))
    setColor(red: color.r, green: color.g, blue: color.b, alpha: 1.0)
    draw(mode: .lines, vertices: vertexData)
  }
  
  /// Draw a transform. Choose your own length scale.
  /// @param xf a transform.
  func drawTransform(_ xf: b2Transform) {
    let p1 = xf.p
    var p2: b2Vec2
    let k_axisScale: b2Float = 0.4
    vertexData.removeAll(keepingCapacity: true)
    vertexData.append(SIMD2<Float>(p1.x, p1.y))
    p2 = p1 + k_axisScale * xf.q.xAxis
    vertexData.append(SIMD2<Float>(p2.x, p2.y))
    setColor(red: 1, green: 0, blue: 0, alpha: 1.0)
    draw(mode: .lines, vertices: vertexData)
    
    vertexData.removeAll(keepingCapacity: true)
    vertexData.append(SIMD2<Float>(p1.x, p1.y))
    p2 = p1 + k_axisScale * xf.q.yAxis
    vertexData.append(SIMD2<Float>(p2.x, p2.y))
    setColor(red: 0, green: 1, blue: 0, alpha: 1.0)
    draw(mode: .lines, vertices: vertexData)
  }
  
  func drawPoint(_ p: b2Vec2, _ size: b2Float, _ color: b2Color) {
    vertexData.removeAll(keepingCapacity: true)
    vertexData.append(SIMD2<Float>(p.x, p.y))
    setColor(red: color.r, green: color.g, blue: color.b, alpha: 1.0)
    setPointSize(size)
    draw(mode: .points, vertices: vertexData)
    setPointSize(0)
  }
  
  func drawAABB(_ aabb: b2AABB, _ color: b2Color) {
    vertexData.removeAll(keepingCapacity: true)
    vertexData.append(SIMD2<Float>(aabb.lowerBound.x, aabb.lowerBound.y))
    vertexData.append(SIMD2<Float>(aabb.upperBound.x, aabb.lowerBound.y))
    vertexData.append(SIMD2<Float>(aabb.upperBound.x, aabb.upperBound.y))
    vertexData.append(SIMD2<Float>(aabb.lowerBound.x, aabb.upperBound.y))
    setColor(red: color.r, green: color.g, blue: color.b, alpha: 1.0)
    draw(mode: .lineLoop, vertices: vertexData)
  }
  
  var m_drawFlags : UInt32 = 0
  
  // MARK: mouse events

  var wp = b2Vec2(0, 0)

  func mouseDown(at position: CGPoint) {
    guard let world else { return }
    wp = convertScreenToWorld(position,
                              size: viewSize,
                              viewCenter: settings.viewCenter)
    
    let d = b2Vec2(0.001, 0.001)
    var aabb = b2AABB()
    aabb.lowerBound = wp - d
    aabb.upperBound = wp + d
    let callback = QueryCallback(point: wp)
    world.queryAABB(callback: callback, aabb: aabb)
    if callback.fixture != nil {
      let body = callback.fixture!.body
      let md = b2MouseJointDef()
      md.bodyA = groundBody
      md.bodyB = body
      md.target = wp
      md.maxForce = 1000.0 * body.mass
      mouseJoint = world.createJoint(md)
      body.setAwake(true)
    }
    else {
      bombLauncher?.mouseDown(position: wp)
    }
  }
  
  func mouseDragged(at position: CGPoint) {
    wp = convertScreenToWorld(position,
                              size: viewSize,
                              viewCenter: settings.viewCenter)
    
    if let mouseJoint {
      mouseJoint.setTarget(wp)
    }
    else {
      bombLauncher?.mouseDragged(position: wp)
    }
  }
  
  func mouseUp(at position: CGPoint) {
    let wp = convertScreenToWorld(position,
                                  size: viewSize,
                                  viewCenter: settings.viewCenter)
    if mouseJoint != nil {
      world?.destroyJoint(mouseJoint!)
      mouseJoint = nil
    }
    else {
      bombLauncher?.mouseUp(position: wp)
    }
  }
  
  func mouseExited() {
    bombLauncher?.mouseExited()
  }

  // MARK: SwiftUI

  var isDragging = false
  
  func onChange(value: DragGesture.Value) {
    if isDragging == false {
      self.mouseDown(at: value.startLocation)
      isDragging = true
    } else {
      self.mouseDragged(at: value.location)
    }
  }

  func onEnd(value: DragGesture.Value) {
    self.mouseUp(at: value.location)
    isDragging = false
  }
  
}
