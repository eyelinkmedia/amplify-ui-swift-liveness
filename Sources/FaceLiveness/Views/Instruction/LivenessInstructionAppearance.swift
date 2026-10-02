//
// Copyright (c) EyeLinkMedia Ltd, 2026-present.
//
// SPDX-License-Identifier: Apache-2.0
//

import UIKit

/// Styling of the instruction shown at the top of the check: an icon with a title below it.
public struct LivenessInstructionAppearance: Sendable {
    /// 28pt bold system font when nil
    public let titleFont: UIFont?

    /// Shown while the user positions their face, before the oval appears. No icon when nil.
    public let centerYourFaceIcon: UIImage?

    /// Shown while the user fits their face into the oval. No icon when nil.
    public let moveCloserIcon: UIImage?

    /// Shown while the check is being verified. No icon when nil.
    public let verifyingIcon: UIImage?

    public init(
        titleFont: UIFont? = nil,
        centerYourFaceIcon: UIImage? = nil,
        moveCloserIcon: UIImage? = nil,
        verifyingIcon: UIImage? = nil
    ) {
        self.titleFont = titleFont
        self.centerYourFaceIcon = centerYourFaceIcon
        self.moveCloserIcon = moveCloserIcon
        self.verifyingIcon = verifyingIcon
    }
}
