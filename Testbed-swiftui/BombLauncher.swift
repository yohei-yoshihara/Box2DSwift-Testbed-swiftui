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

import Box2D

class BombLauncher {
  unowned let world: b2World
  unowned let debugDraw: Renderer
  var viewCenter: b2Vec2
  var drawLine = false
  var lineStart = b2Vec2(), lineEnd = b2Vec2()
  var bomb: b2Body? = nil
  
  init(world: b2World, renderView: Renderer, viewCenter: b2Vec2) {
    self.world = world
    self.debugDraw = renderView
    self.viewCenter = viewCenter
  }
  
  func mouseDown(position: b2Vec2) {
    drawLine = true
    lineStart = position
    lineEnd = position
  }

  func mouseDragged(position: b2Vec2) {
    lineEnd = position
  }

  func mouseUp(position: b2Vec2) {
    drawLine = false
    let multiplier: b2Float = 30.0
    var vel = lineStart - position
    vel *= multiplier
    launchBomb(position: lineStart, velocity: vel)
  }

  func mouseExited() {
    drawLine = false
  }
  
  func launchBomb() {
    let p = b2Vec2(randomFloat(-15.0, 15.0), 30.0)
    let v = -5.0 * p
    launchBomb(position: p, velocity: v)
  }
  
  func launchBomb(position: b2Vec2, velocity: b2Vec2) {
    if bomb != nil {
      world.destroyBody(bomb!)
      bomb = nil
    }
    
    let bd = b2BodyDef()
    bd.type = b2BodyType.dynamicBody
    bd.position = position
    bd.bullet = true
    bomb = world.createBody(bd)
    bomb!.setLinearVelocity(velocity)
    
    let circle = b2CircleShape()
    circle.radius = 0.3
    
    let fd = b2FixtureDef()
    fd.shape = circle
    fd.density = 20.0
    fd.restitution = 0.0
    
    let minV = position - b2Vec2(0.3, 0.3)
    let maxV = position + b2Vec2(0.3, 0.3)
    
    var aabb = b2AABB()
    aabb.lowerBound = minV
    aabb.upperBound = maxV
    
    bomb?.createFixture(fd)
  }
  
  func render() {
    if drawLine {
      debugDraw.drawSegment(lineStart, lineEnd, b2Color(1, 1, 1))
    }
  }
}
