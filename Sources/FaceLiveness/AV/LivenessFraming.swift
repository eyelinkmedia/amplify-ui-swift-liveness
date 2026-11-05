//
// Copyright (c) EyeLinkMedia Ltd, 2026-present.
//
// SPDX-License-Identifier: Apache-2.0
//

import CoreGraphics

/// How much of the camera frame the check records, which sets how far from the camera the
/// user holds the phone
public enum LivenessFraming: Sendable, Equatable {
    /// The whole camera frame
    case standard

    /// The centre of the camera frame, `zoom` times smaller, so the user holds the phone `zoom`
    /// times further away. The screen shows exactly what is recorded, and the oval grows as
    /// with `standard`.
    case cropped(zoom: CGFloat)

    /// Like `cropped`, but when the oval appears the screen zooms out to the whole camera frame
    /// while the oval grows, so the oval grows `zoom` times less
    case croppedWithZoomOut(zoom: CGFloat)
}

extension LivenessFraming {
    /// How many times smaller than the camera frame the recorded part is
    var recordingCropZoom: CGFloat {
        switch self {
        case .standard:
            return 1
        case .cropped(let zoom), .croppedWithZoomOut(let zoom):
            return max(zoom, 1)
        }
    }

    /// How much the preview is magnified before the oval appears, to show exactly what is
    /// recorded
    var startPreviewMagnification: CGFloat {
        recordingCropZoom
    }

    /// How much the preview is magnified once the oval appears
    var challengePreviewMagnification: CGFloat {
        switch self {
        case .standard, .croppedWithZoomOut:
            return 1
        case .cropped:
            return recordingCropZoom
        }
    }
}
