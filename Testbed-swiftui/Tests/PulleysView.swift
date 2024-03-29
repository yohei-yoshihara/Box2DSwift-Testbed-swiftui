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

struct PulleysView: View {
  @State var testCase = Pulleys()
  @StateObject var info = PulleysInfo()
  var body: some View {
    ZStack {
      TestbedView(testCase: testCase)
      HStack {
        VStack(alignment: .leading) {
          Text(String(format:"L1 + %4.2f * L2 = %4.2f", info.ratio, info.l))
            .foregroundStyle(.white)
          Spacer()
        }
        Spacer()
      }
      .padding()
    }
    .navigationTitle("Pulleys")
  }
}

class PulleysInfo: ObservableObject {
  @Published var ratio: Float = 0.0
  @Published var l: Float = 0.0
}
