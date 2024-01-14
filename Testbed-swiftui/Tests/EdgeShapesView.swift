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

struct EdgeShapesView: View {
  @State var testCase = EdgeShapes()
  @State var isPresented = false
  var body: some View {
    TestbedView(testCase: testCase)
      .toolbar {
        ToolbarItem(placement: .automatic) {
          Button("Drop") {
            isPresented = true
          }
          .popover(isPresented: $isPresented) {
            List {
              ForEach(1..<7) { i in
                Button {
                  testCase.onDropStuff(index: i - 1)
                } label: {
                  Text("\(i)")
                    .frame(maxWidth: .infinity)
                }
              }
            }
          }
        }
        ToolbarItem(placement: .automatic) {
          Button("Delete") {
            testCase.onDeleteStuff()
          }
        }
      }
      .navigationTitle("Edge Shapes")
  }
}