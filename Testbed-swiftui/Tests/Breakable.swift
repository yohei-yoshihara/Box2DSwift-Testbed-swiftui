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

import Foundation
import Box2D

class Breakable: TestCase, b2ContactListener {
  override static var title: String { "Breakable" }

  let count = 7
  
  var body1: b2Body!
  var velocity = b2Vec2()
  var angularVelocity: b2Float = 0
  var shape1 = b2PolygonShape()
  var shape2 = b2PolygonShape()
  var piece1: b2Fixture!
  var piece2: b2Fixture!
  
  var broke = false
  var enableBreak = false

  override func prepare() {
    world.setContactListener(self)
    
    // Ground body
    do {
      let bd = b2BodyDef()
      let ground = world.createBody(bd)
      
      let shape = b2EdgeShape()
      shape.set(vertex1: b2Vec2(-40.0, 0.0), vertex2: b2Vec2(40.0, 0.0))
      ground.createFixture(shape:shape, density: 0.0)
    }
    
    // Breakable dynamic body
    do {
      let bd = b2BodyDef()
      bd.type = b2BodyType.dynamicBody
      bd.position.set(0.0, 40.0)
      bd.angle = 0.25 * b2_pi
      self.body1 = world.createBody(bd)
      
      self.shape1.setAsBox(halfWidth: 0.5, halfHeight: 0.5, center: b2Vec2(-0.5, 0.0), angle: 0.0)
      self.piece1 = self.body1.createFixture(shape: self.shape1, density: 1.0)
      
      self.shape2.setAsBox(halfWidth: 0.5, halfHeight: 0.5, center: b2Vec2(0.5, 0.0), angle: 0.0)
      self.piece2 = self.body1.createFixture(shape: self.shape2, density: 1.0)
    }
    
    enableBreak = false
    broke = false
  }

  func postSolve(_ contact: Box2D.b2Contact, impulse: Box2D.b2ContactImpulse) {
    contactListener.postSolve(contact, impulse: impulse)
  
    if broke {
      // The body already broke.
      return
    }
    
    // Should the body break?
    let count = contact.manifold.pointCount
    
    var maxImpulse: b2Float = 0.0
    for i in 0 ..< count {
      maxImpulse = max(maxImpulse, impulse.normalImpulses[i])
    }
    
    if maxImpulse > 40.0 {
      // Flag the body for breaking.
      enableBreak = true
    }
  }

  func doBreak() {
    // Create two bodies from one.
    let body1 = piece1.body
    let center = body1.worldCenter
  
    body1.destroyFixture(piece2)
    piece2 = nil
  
    let bd = b2BodyDef()
    bd.type = b2BodyType.dynamicBody
    bd.position = body1.position
    bd.angle = body1.angle
  
    let body2 = world.createBody(bd)
    piece2 = body2.createFixture(shape: shape2, density: 1.0)
  
    // Compute consistent velocities for new bodies based on
    // cached velocity.
    let center1 = body1.worldCenter
    let center2 = body2.worldCenter
    
    let velocity1 = velocity + b2Cross(angularVelocity, center1 - center)
    let velocity2 = velocity + b2Cross(angularVelocity, center2 - center)
  
    body1.setAngularVelocity(angularVelocity)
    body1.setLinearVelocity(velocity1)
  
    body2.setAngularVelocity(angularVelocity)
    body2.setLinearVelocity(velocity2)
  }

  override func step() {
    if enableBreak {
      doBreak();
      broke = true
      enableBreak = false
    }
  
    // Cache velocities to improve movement on breakage.
    if broke == false {
      velocity = body1.linearVelocity
      angularVelocity = body1.angularVelocity
    }
  }
  
  func beginContact(_ contact : b2Contact) { contactListener.beginContact(contact) }
  func endContact(_ contact: b2Contact) { contactListener.endContact(contact) }
  func preSolve(_ contact: b2Contact, oldManifold: b2Manifold) {
    contactListener.preSolve(contact, oldManifold: oldManifold);
  }
}
