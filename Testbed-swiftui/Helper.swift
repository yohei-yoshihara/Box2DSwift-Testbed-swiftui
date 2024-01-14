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

import CoreGraphics
import Box2D
import Foundation

func randomFloat() -> b2Float {
  var rand = b2Float(arc4random_uniform(1000)) / b2Float(1000)
  rand = b2Float(2.0) * rand - b2Float(1.0)
  return rand
}

func randomFloat(_ low: b2Float, _ high: b2Float) -> b2Float {
  let rand = (b2Float(arc4random_uniform(1000)) / b2Float(1000)) * (high - low) + low
  return rand
}

func convertScreenToWorld(_ _tp: CGPoint, size: CGSize, viewCenter: b2Vec2) -> b2Vec2 {
  let l = min(size.width, size.height)
  
  var tp = _tp
  tp.y = size.height - tp.y
  
  if size.width > size.height {
    tp.x -= (size.width - size.height) / 2.0
  } else {
    tp.y -= (size.height - size.width) / 2.0
  }
  
  let u = b2Float(tp.x / l)
  let v = b2Float(tp.y / l)
  let extents = Settings.extents
  let lower = viewCenter - extents
  let upper = viewCenter + extents
  var p = b2Vec2()
  p.x = (1.0 - u) * lower.x + b2Float(u) * upper.x
  p.y = (1.0 - v) * lower.y + b2Float(v) * upper.y
  return p
}

func calcViewBounds(viewSize: CGSize, viewCenter: b2Vec2, extents: b2Vec2) -> (lower: b2Vec2, upper: b2Vec2) {
  var lower = viewCenter - extents
  var upper = viewCenter + extents
  
  if viewSize.width > viewSize.height {
    let r = Float(viewSize.height) / Float(extents.y)
    let d = Float(viewSize.width - viewSize.height) / r
    lower.x -= d
    upper.x += d
  } else {
    let r = Float(viewSize.width) / Float(extents.x)
    let d = Float(viewSize.height - viewSize.width) / r
    lower.y -= d
    upper.y += d
  }
  return (lower, upper)
}

class Settings : CustomStringConvertible, ObservableObject {
  enum Hertz: Int {
    case hz30 = 30
    case hz60 = 60
  }
  static let extents = b2Vec2(25.0, 25.0)
  init() {
    assert(Settings.extents.x == Settings.extents.y)
    viewCenter = b2Vec2(0.0, 20.0)
    hz = .hz60
    velocityIterations = 8
    positionIterations = 3
    drawShapes = true
    drawJoints = true
    drawAABBs = false
    drawContactPoints = false
    drawContactNormals = false
    drawContactImpulse = false
    drawFrictionImpulse = false
    drawCOMs = false
    drawStats = false
    drawProfile = false
    enableWarmStarting = true
    enableContinuous = true
    enableSubStepping = false
    enableSleep = true
    pause = false
    singleStep = false
  }
  @Published var viewCenter = b2Vec2(0.0, 20.0)
  @Published var hz: Hertz = .hz60
  @Published var velocityIterations = 8
  @Published var positionIterations = 3
  @Published var drawShapes = true
  @Published var drawJoints = true
  @Published var drawAABBs = false
  @Published var drawContactPoints = false
  @Published var drawContactNormals = false
  @Published var drawContactImpulse = false
  @Published var drawFrictionImpulse = false
  @Published var drawCOMs = false
  @Published var drawStats = false
  @Published var drawProfile = false
  @Published var enableWarmStarting = true
  @Published var enableContinuous = true
  @Published var enableSubStepping = false
  @Published var enableSleep = true
  @Published var pause = false
  @Published var singleStep = false
  
  func calcViewBounds() -> (lower: b2Vec2, upper: b2Vec2) {
    let lower = viewCenter - Settings.extents
    let upper = viewCenter + Settings.extents
    return (lower, upper)
  }
  
  func calcTimeStep() -> b2Float {
    var timeStep: b2Float = b2Float(1.0) / b2Float(hz.rawValue)
    if pause {
      if singleStep {
        singleStep = false
      }
      else {
        timeStep = b2Float(0.0)
      }
    }
    return timeStep
  }
  
  var debugDrawFlag : UInt32 {
    var flags: UInt32 = 0
    if drawShapes {
      flags |= b2DrawFlags.shapeBit
    }
    if drawJoints {
      flags |= b2DrawFlags.jointBit
    }
    if drawAABBs {
      flags |= b2DrawFlags.aabbBit
    }
    if drawCOMs {
      flags |= b2DrawFlags.centerOfMassBit
    }
    return flags
  }
  
  func apply(_ world: b2World) {
    world.setAllowSleeping(enableSleep)
    world.setWarmStarting(enableWarmStarting)
    world.setContinuousPhysics(enableContinuous)
    world.setSubStepping(enableSubStepping)
  }
  
  var description: String {
    return "Settings[viewCenter=\(viewCenter),hz=\(hz),velocityIterations=\(velocityIterations),positionIterations=\(positionIterations),drawShapes=\(drawShapes),drawJoints=\(drawJoints),drawAABBs=\(drawAABBs),drawContactPoints=\(drawContactPoints),drawContactNormals=\(drawContactNormals),drawFrictionImpulse=\(drawFrictionImpulse),drawCOMs=\(drawCOMs),drawStats=\(drawStats),drawProfile=\(drawProfile),enableWarmStarting=\(enableWarmStarting),enableContinuous=\(enableContinuous),enableSubStepping=\(enableSubStepping),enableSleep=\(enableSleep),pause=\(pause),singleStep=\(singleStep)]"
  }
}

struct ContactPoint {
  weak var fixtureA: b2Fixture? = nil
  weak var fixtureB: b2Fixture? = nil
  var normal = b2Vec2()
  var position = b2Vec2()
  var state = b2PointState.nullState
  var normalImpulse: b2Float = 0.0
  var tangentImpulse: b2Float = 0.0
  var separation: b2Float = 0.0
}

class QueryCallback : b2QueryCallback {
  init(point: b2Vec2) {
    self.point = point
    fixture = nil
  }
  
  func reportFixture(_ fixture: b2Fixture) -> Bool {
    let body = fixture.body
    if body.type == b2BodyType.dynamicBody {
      let inside = fixture.testPoint(self.point)
      if inside {
        self.fixture = fixture
        // We are done, terminate the query.
        return false
      }
    }
    // Continue the query.
    return true
  }
  
  var point: b2Vec2
  var fixture: b2Fixture? = nil
}

class DestructionListener : b2DestructionListener {
  func sayGoodbye(_ fixture: Box2D.b2Fixture) {}
  func sayGoodbye(_ joint: Box2D.b2Joint) {}
}

class ContactListener : b2ContactListener {
  var m_points = [ContactPoint]()
  
  func clearPoints() {
    m_points.removeAll(keepingCapacity: true)
  }
  
  func drawContactPoints(_ settings: Settings, renderer: Renderer) {
    if settings.drawContactPoints {
      let k_impulseScale: b2Float = 0.1
      let k_axisScale: b2Float = 0.3
      
      for point in m_points {
        if point.state == b2PointState.addState {
          // Add
          renderer.drawPoint(point.position, 10.0, b2Color(0.3, 0.95, 0.3))
        }
        else if point.state == b2PointState.persistState {
          // Persist
          renderer.drawPoint(point.position, 5.0, b2Color(0.3, 0.3, 0.95))
        }
        
        if settings.drawContactNormals {
          let p1 = point.position
          let p2 = p1 + k_axisScale * point.normal
          renderer.drawSegment(p1, p2, b2Color(0.9, 0.9, 0.9))
        }
        else if settings.drawContactImpulse {
          let p1 = point.position
          let p2 = p1 + k_impulseScale * point.normalImpulse * point.normal
          renderer.drawSegment(p1, p2, b2Color(0.9, 0.9, 0.3))
        }
        
        if settings.drawFrictionImpulse {
          let tangent = b2Cross(point.normal, 1.0)
          let p1 = point.position
          let p2 = p1 + k_impulseScale * point.tangentImpulse * tangent
          renderer.drawSegment(p1, p2, b2Color(0.9, 0.9, 0.3))
        }
      }
    }
  }
  
  func beginContact(_ contact : b2Contact) {}
  func endContact(_ contact: b2Contact) {}
  
  func preSolve(_ contact: b2Contact, oldManifold: b2Manifold) {
    let manifold = contact.manifold
    if manifold.pointCount == 0 {
      return
    }
    
    let fixtureA = contact.fixtureA
    let fixtureB = contact.fixtureB
    let (_/*state1*/, state2) = b2GetPointStates(manifold1: oldManifold, manifold2: manifold)
    let worldManifold = contact.worldManifold
    
    for i in 0 ..< manifold.pointCount {
      var cp = ContactPoint()
      cp.fixtureA = fixtureA
      cp.fixtureB = fixtureB
      cp.position = worldManifold.points[i]
      cp.normal = worldManifold.normal
      cp.state = state2[i]
      cp.normalImpulse = manifold.points[i].normalImpulse
      cp.tangentImpulse = manifold.points[i].tangentImpulse
      cp.separation = worldManifold.separations[i]
      m_points.append(cp)
    }
  }
  
  func postSolve(_ contact: b2Contact, impulse: b2ContactImpulse) {}
}
