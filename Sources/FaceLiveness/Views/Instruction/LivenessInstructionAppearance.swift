//
// Copyright (c) EyeLinkMedia Ltd, 2026-present.
//
// SPDX-License-Identifier: Apache-2.0
//

import UIKit

/// Styling of the check: the instruction shown at its top, an icon with a title below it, and
/// the case of all its text.
public struct LivenessInstructionAppearance: Sendable {
    /// 28pt bold system font when nil
    public let titleFont: UIFont?

    /// Shows all the text of the check in lowercase: the instructions, the buttons, and the
    /// connecting and camera permission screens. When false it is shown as written in the
    /// strings.
    public let isTextLowercased: Bool

    /// Shown while the user positions their face, before the oval appears. No icon when nil.
    public let centerYourFaceIcon: UIImage?

    /// Shown while the user fits their face into the oval. No icon when nil.
    public let moveCloserIcon: UIImage?

    /// Shown while the check is being verified. No icon when nil.
    public let verifyingIcon: UIImage?

    public init(
        titleFont: UIFont? = nil,
        isTextLowercased: Bool = false,
        centerYourFaceIcon: UIImage? = nil,
        moveCloserIcon: UIImage? = nil,
        verifyingIcon: UIImage? = nil
    ) {
        self.titleFont = titleFont
        self.isTextLowercased = isTextLowercased
        self.centerYourFaceIcon = centerYourFaceIcon
        self.moveCloserIcon = moveCloserIcon
        self.verifyingIcon = verifyingIcon
    }
}

extension LivenessInstructionAppearance {
    /// `text` the way the check shows it
    func displayText(_ text: String) -> String {
        isTextLowercased ? text.lowercased() : text
    }
}
