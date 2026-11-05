//
// Copyright (c) EyeLinkMedia Ltd, 2026-present.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import FaceLiveness

final class LivenessFramingTests: XCTestCase {

    /// Given: The `standard` framing
    /// When: Its magnifications are read
    /// Then: The whole camera frame is recorded and shown throughout
    func testStandardRecordsAndShowsTheWholeFrame() {
        let framing = LivenessFraming.standard

        XCTAssertEqual(framing.recordingCropZoom, 1)
        XCTAssertEqual(framing.startPreviewMagnification, 1)
        XCTAssertEqual(framing.challengePreviewMagnification, 1)
    }

    /// Given: The `cropped` framing
    /// When: Its magnifications are read
    /// Then: The preview shows exactly what is recorded throughout
    func testCroppedShowsWhatIsRecordedThroughout() {
        let framing = LivenessFraming.cropped(zoom: 1.4)

        XCTAssertEqual(framing.recordingCropZoom, 1.4)
        XCTAssertEqual(framing.startPreviewMagnification, 1.4)
        XCTAssertEqual(framing.challengePreviewMagnification, 1.4)
    }

    /// Given: The `croppedWithZoomOut` framing
    /// When: Its magnifications are read
    /// Then: The preview shows what is recorded, then zooms out to the whole camera frame
    func testCroppedWithZoomOutZoomsOutToTheWholeFrame() {
        let framing = LivenessFraming.croppedWithZoomOut(zoom: 1.4)

        XCTAssertEqual(framing.recordingCropZoom, 1.4)
        XCTAssertEqual(framing.startPreviewMagnification, 1.4)
        XCTAssertEqual(framing.challengePreviewMagnification, 1)
    }

    /// Given: A cropped framing with a zoom below 1
    /// When: Its crop zoom is read
    /// Then: The whole camera frame is recorded, as it cannot record more
    func testZoomBelowOneRecordsTheWholeFrame() {
        XCTAssertEqual(LivenessFraming.cropped(zoom: 0.5).recordingCropZoom, 1)
    }

    /// Given: A cropper with a zoom of 1.4 and a 3:4 camera frame
    /// When: The recorded part of the frame is computed
    /// Then: It is the centre of the frame, 1.4 times smaller
    func testCropRectIsTheCentreOfTheFrame() {
        let cropper = RecordedFrameCropper(zoom: 1.4)

        let rect = cropper.cropRect(frameSize: CGSize(width: 1080, height: 1440))

        XCTAssertEqual(rect.width, 1080 / 1.4, accuracy: 0.001)
        XCTAssertEqual(rect.height, 1440 / 1.4, accuracy: 0.001)
        XCTAssertEqual(rect.midX, 540, accuracy: 0.001)
        XCTAssertEqual(rect.midY, 720, accuracy: 0.001)
    }

    /// Given: A cropper and a camera frame taller than 3:4
    /// When: The recorded part of the frame is computed
    /// Then: It keeps the 3:4 of the recording, centred
    func testCropRectKeepsTheRecordedAspectRatio() {
        let cropper = RecordedFrameCropper(zoom: 1)

        let rect = cropper.cropRect(frameSize: CGSize(width: 1080, height: 1920))

        XCTAssertEqual(rect, CGRect(x: 0, y: 240, width: 1080, height: 1440))
    }

    /// Given: The challenge oval on a preview that shows exactly what is recorded
    /// When: The preview shows the whole camera frame instead, 1.4 times more
    /// Then: The oval is drawn 1.4 times smaller, as far from the centre of the preview
    func testChallengeOvalShrinksAroundTheCentreOnAZoomedOutPreview() {
        let previewSize = CGSize(width: 393, height: 852)
        let cameraRect = CGRect(x: 60, y: 100, width: 300, height: 400)
        let cameraSize = CGSize(width: 480, height: 640)

        let recordedFrame = OvalGeometry.challengeOvalFrame(
            fromCameraRect: cameraRect,
            cameraSize: cameraSize,
            previewSize: previewSize,
            recordedFrameScale: 1
        )
        let zoomedOutFrame = OvalGeometry.challengeOvalFrame(
            fromCameraRect: cameraRect,
            cameraSize: cameraSize,
            previewSize: previewSize,
            recordedFrameScale: 1 / 1.4
        )

        XCTAssertEqual(zoomedOutFrame.width, recordedFrame.width / 1.4, accuracy: 0.001)
        XCTAssertEqual(zoomedOutFrame.height, recordedFrame.height / 1.4, accuracy: 0.001)
        XCTAssertEqual(zoomedOutFrame.midX - previewSize.width / 2, (recordedFrame.midX - previewSize.width / 2) / 1.4, accuracy: 0.001)
        XCTAssertEqual(zoomedOutFrame.midY - previewSize.height / 2, (recordedFrame.midY - previewSize.height / 2) / 1.4, accuracy: 0.001)
    }
}
