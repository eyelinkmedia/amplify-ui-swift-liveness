//
// Copyright (c) EyeLinkMedia Ltd, 2026-present.
//
// SPDX-License-Identifier: Apache-2.0
//

import CoreGraphics

/// Oval geometry shared by the get-ready and the liveness screens. Both show the camera
/// frame aspect-filled across the whole view, so a rect in the frame lands on the same spot
/// of the screen in either of them.
enum OvalGeometry {
    // The oval shown before the check starts, as fractions of the camera frame rather than
    // of the screen, so it covers the same part of the frame on every iPhone. The size
    // reproduces the original layout (60% x 55% of the area above the begin button) on a
    // 393x852pt screen, which keeps the distance users start the check from. It is centered
    // like the oval the server sends.
    private static let startOvalWidthRatio = 0.42
    private static let startOvalHeightRatio = 0.51
    private static let startOvalCenterXRatio = 0.5
    private static let startOvalCenterYRatio = 0.5
    private static let cameraFrameSize = CGSize(width: 480, height: 640)

    // The oval the server sends is drawn slightly smaller so that it clears the close
    // button. Only the drawing changes: matching still compares the face with the server's
    // oval, and a face that fills the drawn one is well within its match tolerance.
    private static let challengeOvalScale = 0.95

    /// The oval the server sends, `rect` in a camera frame of `cameraSize`, as drawn on a
    /// preview of `previewSize`
    static func challengeOvalFrame(fromCameraRect rect: CGRect, cameraSize: CGSize, previewSize: CGSize) -> CGRect {
        let frame = previewRect(fromCameraRect: rect, cameraSize: cameraSize, previewSize: previewSize)
        return frame.insetBy(
            dx: frame.width * (1 - challengeOvalScale) / 2,
            dy: frame.height * (1 - challengeOvalScale) / 2
        )
    }

    /// The oval shown before the check starts, in the coordinates of a preview of `previewSize`
    static func startOvalFrame(previewSize: CGSize) -> CGRect {
        let width = cameraFrameSize.width * startOvalWidthRatio
        let height = cameraFrameSize.height * startOvalHeightRatio
        let cameraRect = CGRect(
            x: cameraFrameSize.width * startOvalCenterXRatio - width / 2,
            y: cameraFrameSize.height * startOvalCenterYRatio - height / 2,
            width: width,
            height: height
        )
        return previewRect(fromCameraRect: cameraRect, cameraSize: cameraFrameSize, previewSize: previewSize)
    }

    /// Maps a rect from a camera frame of `cameraSize` onto the preview, which aspect-fills
    /// the frame and crops whichever sides overflow.
    static func previewRect(fromCameraRect rect: CGRect, cameraSize: CGSize, previewSize: CGSize) -> CGRect {
        guard cameraSize.width > 0, cameraSize.height > 0 else { return rect }

        let scale = max(
            previewSize.width / cameraSize.width,
            previewSize.height / cameraSize.height
        )
        let originX = (previewSize.width - cameraSize.width * scale) / 2
        let originY = (previewSize.height - cameraSize.height * scale) / 2

        return CGRect(
            x: originX + rect.minX * scale,
            y: originY + rect.minY * scale,
            width: rect.width * scale,
            height: rect.height * scale
        )
    }
}
