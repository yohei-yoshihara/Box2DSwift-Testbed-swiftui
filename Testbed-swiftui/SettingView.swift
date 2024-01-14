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

struct SettingView: View {
  @EnvironmentObject var settings: Settings
  
  var body: some View {
    Form {
      Section(header: Text("Basic")) {
        Picker("Velocity Iterations:", selection: $settings.velocityIterations) {
          ForEach(0 ..< 20) {
            Text("\($0)")
          }
        }
        Picker("Position Iterations:", selection: $settings.positionIterations) {
          ForEach(0 ..< 20) {
            Text("\($0)")
          }
        }
        Picker("Hertz:", selection: $settings.hz) {
          Text("30hz").tag(Settings.Hertz.hz30)
          Text("60hz").tag(Settings.Hertz.hz60)
        }
        Toggle("Sleep", isOn: $settings.enableSleep)
        Toggle("Warm Starting", isOn: $settings.enableWarmStarting)
        Toggle("Time of Impact", isOn: $settings.enableContinuous)
        Toggle("Sub-Stepping", isOn: $settings.enableSubStepping)
      }
      Section(header: Text("Draw")) {
        Toggle("Shapes", isOn: $settings.drawShapes)
        Toggle("Joints", isOn: $settings.drawJoints)
        Toggle("AABBs", isOn: $settings.drawAABBs)
        Toggle("Contact Points", isOn: $settings.drawContactPoints)
        Toggle("Contact Normals", isOn: $settings.drawContactNormals)
        Toggle("Contact Impulses", isOn: $settings.drawContactImpulse)
        Toggle("Friction Impulses", isOn: $settings.drawFrictionImpulse)
        Toggle("Center of Masses", isOn: $settings.drawCOMs)
        Toggle("Statistics", isOn: $settings.drawStats)
        Toggle("Profile", isOn: $settings.drawProfile)
      }
    }
    .padding()
  }
}

#Preview {
  SettingView()
}
