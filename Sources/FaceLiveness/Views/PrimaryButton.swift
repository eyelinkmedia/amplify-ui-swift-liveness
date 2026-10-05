//
// Copyright (c) EyeLinkMedia Ltd, 2026-present.
//
// SPDX-License-Identifier: Apache-2.0
//

import SwiftUI

/// The white capsule button at the bottom of the screens shown before the check, with the
/// insets every one of them places it at
struct PrimaryButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(
            action: action,
            label: {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    // Inside the label, so that the whole capsule is tappable rather than
                    // just the text
                    .frame(height: 48)
                    ._background { Color.white }
                    .clipShape(Capsule())
            }
        )
        .padding([.leading, .trailing], 24)
        .padding(.bottom, 14)
    }
}

struct PrimaryButton_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.black
            PrimaryButton(title: "Start video check", action: {})
        }
    }
}
