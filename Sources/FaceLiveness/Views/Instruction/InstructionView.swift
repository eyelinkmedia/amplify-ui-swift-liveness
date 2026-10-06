//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import CoreText
import SwiftUI

struct InstructionView: View {
    enum Icon {
        case centerYourFace
        case moveCloser
        case verifying
    }

    let icon: Icon
    let text: String
    @Environment(\.livenessInstructionAppearance) private var appearance

    var body: some View {
        VStack(spacing: 12) {
            if let iconImage {
                Image(uiImage: iconImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: 32)
                    .accessibilityHidden(true)
            }
            Text(appearance.displayText(text))
                .foregroundColor(.white)
                .font(titleFont)
                .multilineTextAlignment(.center)
        }
        .padding([.leading, .trailing], 24)
    }

    private var iconImage: UIImage? {
        switch icon {
        case .centerYourFace:
            return appearance.centerYourFaceIcon
        case .moveCloser:
            return appearance.moveCloserIcon
        case .verifying:
            return appearance.verifyingIcon
        }
    }

    private var titleFont: Font {
        guard let titleFont = appearance.titleFont else {
            return .system(size: 28, weight: .bold)
        }
        return Font(titleFont as CTFont)
    }
}

extension EnvironmentValues {
    var livenessInstructionAppearance: LivenessInstructionAppearance {
        get { self[LivenessInstructionAppearanceKey.self] }
        set { self[LivenessInstructionAppearanceKey.self] = newValue }
    }
}

private struct LivenessInstructionAppearanceKey: EnvironmentKey {
    static let defaultValue = LivenessInstructionAppearance()
}
