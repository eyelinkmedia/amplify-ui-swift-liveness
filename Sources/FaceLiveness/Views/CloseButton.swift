//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import SwiftUI

struct CloseButton: View {
    let action: () -> Void

    var body: some View {
        Button(
            action: action,
            label: {
                if #available(iOS 26.0, *) {
                    icon
                        .foregroundColor(.white)
                        .glassEffect(.regular.interactive(), in: Circle())
                } else {
                    icon
                        .foregroundColor(.livenessLabel)
                        .background(Color.livenessBackground)
                        .clipShape(Circle())
                }
            }
        )
    }

    private var icon: some View {
        Image(systemName: "xmark")
            .font(.system(size: 18, weight: .bold))
            .frame(width: 44, height: 44)
            .accessibilityLabel(Text(LocalizedStrings.close_button_a11y))
    }
}

extension View {
    /// Shows the close button in the top trailing corner of the safe area, where every
    /// screen of the check places it.
    func closeButtonOverlay(action: @escaping () -> Void) -> some View {
        _overlay(alignment: .topTrailing) {
            CloseButton(action: action)
                .padding(.top, 13)
                .padding(.trailing, 20)
        }
    }
}

struct CloseButton_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.gray
            CloseButton(action: {})
        }
    }
}
