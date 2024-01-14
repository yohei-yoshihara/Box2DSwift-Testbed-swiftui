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

struct TilesView: View {
  @State var testCase = Tiles()
  @StateObject var info = TilesInfo()
  var body: some View {
    ZStack {
      TestbedView(testCase: testCase)
      
      HStack {
        VStack(alignment: .leading) {
          Text(String(format: "dynamic tree height = %d, min = %d", 
                      info.height, info.minimumHeight))
            .foregroundStyle(.white)
          Text(String(format: "create time = %6.2f ms, fixture count = %d",
                      info.createTime, info.fixtureCount))
            .foregroundStyle(.white)
          Spacer()
        }
        Spacer()
      }
      .padding()
    }
    .onAppear {
      testCase.info = info
    }
    .navigationTitle("Tiles")
  }
}

class TilesInfo: ObservableObject {
  @Published var height = 0
  @Published var minimumHeight = 0
  @Published var createTime: Float = 0.0
  @Published var fixtureCount = 0
}
