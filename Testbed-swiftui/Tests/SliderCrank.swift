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

class SliderCrank: TestCase {
  var joint1: b2RevoluteJoint!
  var joint2: b2PrismaticJoint!
  var prevBody: b2Body!

  func onFriction() {
    joint2.enableMotor(!joint2.isMotorEnabled)
    joint2.bodyB.setAwake(true)
  }
  
  func onMotor() {
    joint1.enableMotor(!joint1.isMotorEnabled)
    joint1.bodyB.setAwake(true)
  }
  
  override func prepare() {
    var ground: b2Body! = nil
    b2Locally {
      let bd = b2BodyDef()
      ground = self.world.createBody(bd)
      
      let shape = b2EdgeShape()
      shape.set(vertex1: b2Vec2(-40.0, 0.0), vertex2: b2Vec2(40.0, 0.0))
      ground.createFixture(shape: shape, density: 0.0)
    }
    
    self.prevBody = ground
      
    // Define crank.
    b2Locally {
      let shape = b2PolygonShape()
      shape.setAsBox(halfWidth: 0.5, halfHeight: 2.0)
        
      let bd = b2BodyDef()
      bd.type = b2BodyType.dynamicBody
      bd.position.set(0.0, 7.0)
      let body = self.world.createBody(bd)
      body.createFixture(shape: shape, density: 2.0)
      
      let rjd = b2RevoluteJointDef()
      rjd.initialize(self.prevBody, bodyB: body, anchor: b2Vec2(0.0, 5.0))
      rjd.motorSpeed = 1.0 * b2_pi
      rjd.maxMotorTorque = 10000.0
      rjd.enableMotor = true
      self.joint1 = self.world.createJoint(rjd)
      
      self.prevBody = body
    }
    
      // Define follower.
    b2Locally {
      let shape = b2PolygonShape()
      shape.setAsBox(halfWidth: 0.5, halfHeight: 4.0)
        
      let bd = b2BodyDef()
      bd.type = b2BodyType.dynamicBody
      bd.position.set(0.0, 13.0)
      let body = self.world.createBody(bd)
      body.createFixture(shape: shape, density: 2.0)
        
      let rjd = b2RevoluteJointDef()
      rjd.initialize(self.prevBody, bodyB: body, anchor: b2Vec2(0.0, 9.0))
      rjd.enableMotor = false
      self.world.createJoint(rjd)
        
      self.prevBody = body
    }
    
      // Define piston
    b2Locally {
      let shape = b2PolygonShape()
      shape.setAsBox(halfWidth: 1.5, halfHeight: 1.5)
        
      let bd = b2BodyDef()
      bd.type = b2BodyType.dynamicBody
      bd.fixedRotation = true
      bd.position.set(0.0, 17.0)
      let body = self.world.createBody(bd)
      body.createFixture(shape: shape, density: 2.0)
        
      let rjd = b2RevoluteJointDef()
      rjd.initialize(self.prevBody, bodyB: body, anchor: b2Vec2(0.0, 17.0))
      self.world.createJoint(rjd)
        
      let pjd = b2PrismaticJointDef()
      pjd.initialize(bodyA: ground, bodyB: body, anchor: b2Vec2(0.0, 17.0), axis: b2Vec2(0.0, 1.0))
        
      pjd.maxMotorForce = 1000.0
      pjd.enableMotor = true
        
      self.joint2 = self.world.createJoint(pjd)
    }
    
      // Create a payload
    b2Locally {
      let shape = b2PolygonShape()
      shape.setAsBox(halfWidth: 1.5, halfHeight: 1.5)
        
      let bd = b2BodyDef()
      bd.type = b2BodyType.dynamicBody
      bd.position.set(0.0, 23.0)
      let body = self.world.createBody(bd)
      body.createFixture(shape: shape, density: 2.0)
    }
  }
  
}
