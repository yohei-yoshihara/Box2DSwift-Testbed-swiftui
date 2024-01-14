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

struct GJKInfoView: View {
  @ObservedObject var gjkInfo: GJKInfo
  
  var body: some View {
    HStack {
      VStack(alignment: .leading) {
        Text(String(format: "gjk calls = %d, ave gjk iters = %3.1f, max gjk iters = %d",
                    gjkInfo.gjkCalls, gjkInfo.aveGjkIters, gjkInfo.maxGjkIters))
        .foregroundStyle(.white)
        Text(String(format: "toi calls = %d, ave toi iters = %3.1f, max toi iters = %d",
                    gjkInfo.toiCalls, gjkInfo.aveToiIters, gjkInfo.maxToiIters))
        .foregroundStyle(.white)
        Text(String(format: "ave toi root iters = %3.1f, max toi root iters = %d",
                    gjkInfo.aveToiRootIters, gjkInfo.maxToiRootIters))
        .foregroundStyle(.white)
        if gjkInfo.hasTimeInfo {
          Text(String(format: "ave [max] toi time = %.1f [%.1f] (microseconds)", gjkInfo.aveToiTime, gjkInfo.maxToiTime))
            .foregroundStyle(.white)
        }
        Spacer()
      }
      Spacer()
    }
  }
}

class GJKInfo: ObservableObject {
  @Published var gjkCalls = 0
  @Published var aveGjkIters: Float = 0.0
  @Published var maxGjkIters = 0
  
  @Published var toiCalls = 0
  @Published var aveToiIters: Float = 0.0
  @Published var maxToiIters = 0
  
  @Published var aveToiRootIters: Float = 0.0
  @Published var maxToiRootIters = 0
  
  @Published var hasTimeInfo = false
  @Published var aveToiTime: Float = 0.0
  @Published var maxToiTime: Float = 0.0
}

