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

struct ContentView: View {
  @State var isPresented = false
  @StateObject private var settings = Settings()
  var body: some View {
    NavigationStack {
      List {
        NavigationLink("Add Pair") { AddPairView() }
        NavigationLink("Apply Force") { ApplyForceView() }
        NavigationLink("Body Types") { BodyTypesView() }
        NavigationLink("Breakable") { BreakableView() }
        NavigationLink("Bridge") { BridgeView() }
        NavigationLink("Bullet") { BulletView() }
        NavigationLink("Cantilever") { CantileverView() }
        NavigationLink("Car") { CarView() }
        NavigationLink("Chain") { ChainView() }
        NavigationLink("Character Collision") { CharacterCollisionView() }
        NavigationLink("Collision Filtering") { CollisionFilteringView() }
        NavigationLink("Collision Processing") { CollisionProcessingView() }
        NavigationLink("Compound Shapes") { CompoundShapesView() }
        NavigationLink("Confined") { ConfinedView() }
        NavigationLink("Continuous Test") { ContinuousTestView() }
        NavigationLink("Conveyor Belt") { ConveyorBeltView() }
        NavigationLink("Distance Test") { DistanceTestView() }
        NavigationLink("Dominos") { DominosView() }
        NavigationLink("Dump Shell") { DumpShellView() }
        NavigationLink("Dynamic Tree Test") { DynamicTreeTestView() }
        NavigationLink("Edge Shapes") { EdgeShapesView() }
        NavigationLink("Edge Test") { EdgeTestView() }
        NavigationLink("Gear") { GearView() }
        NavigationLink("Mobile Balanced") { MobileBalancedView() }
        NavigationLink("Mobile") { MobileView() }
        NavigationLink("Motor Joint") { MotorJointView() }
        NavigationLink("One Sided PlatformView") { OneSidedPlatformView() }
        NavigationLink("Pinball") { PinballView() }
        NavigationLink("Poly Collision") { PolyCollisionView() }
        NavigationLink("Poly Shapes") { PolyShapesView() }
        NavigationLink("Prismatic") { PrismaticView() }
        NavigationLink("Pulleys") { PulleysView() }
        NavigationLink("Pyramid") { PyramidView() }
        NavigationLink("Ray Cast") { RayCastView() }
        NavigationLink("Revolute") { RevoluteView() }
        NavigationLink("Rope Joint") { RopeJointView() }
        NavigationLink("Sensor Test") { SensorTestView() }
        NavigationLink("Shape Editing") { ShapeEditingView() }
        NavigationLink("Slider Crank") { SliderCrankView() }
        NavigationLink("Sphere Stack") { SphereStackView() }
        NavigationLink("Theo Jansen") { TheoJansenView() }
        NavigationLink("Tiles") { TilesView() }
        NavigationLink("Time of Impact") { TimeOfImpactView() }
        NavigationLink("Tumbler") { TumblerView() }
        NavigationLink("Varying Friction") { VaryingFrictionView() }
        NavigationLink("Varying Restitution") { VaryingRestitutionView() }
        NavigationLink("Vertical Stack") { VerticalStackView() }
        NavigationLink("Web") { WebView() }
      }
      .navigationTitle("Box2D Testbed")
      .toolbar {
        ToolbarItem(placement: .automatic) {
          Button("Settings") {
            isPresented = true
          }
          .popover(isPresented: $isPresented, content: {
            SettingView()
              .padding()
          })
        }
      }
    }
    .environmentObject(settings)
  }
}

#Preview {
  ContentView()
}
