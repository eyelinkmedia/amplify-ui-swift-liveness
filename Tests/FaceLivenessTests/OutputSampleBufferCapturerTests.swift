//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import AVFoundation
@testable import FaceLiveness

final class OutputSampleBufferCapturerTests: XCTestCase {
    private var faceDetector: MockFaceDetector!
    private var videoChunker: VideoChunker!
    private var capturer: OutputSampleBufferCapturer!

    override func setUp() {
        faceDetector = MockFaceDetector()
        videoChunker = VideoChunker(
            assetWriter: LivenessAVAssetWriter(),
            assetWriterDelegate: VideoChunker.AssetWriterDelegate(),
            assetWriterInput: LivenessAVAssetWriterInput()
        )
        capturer = OutputSampleBufferCapturer(faceDetector: faceDetector, videoChunker: videoChunker)
    }

    override func tearDown() {
        faceDetector = nil
        videoChunker = nil
        capturer = nil
    }

    /// Given: The get ready screen showing the check's camera
    /// When: A frame arrives
    /// Then: It goes neither to face detection nor to the video
    func testFramesAreDroppedWhileThePreviewShows() throws {
        capturer.isPreviewing.value = true
        videoChunker.start()

        capturer.handle(try makeFrame(at: 0))

        XCTAssertEqual(faceDetector.interactions, [])
        XCTAssertNil(videoChunker.startTimeSeconds, "the frame was recorded")
    }

    /// Given: The check has taken over the camera from the get ready screen
    /// When: A frame arrives
    /// Then: It goes to face detection and the video again
    func testFramesGoToTheCheckOnceThePreviewStops() throws {
        capturer.isPreviewing.value = true
        videoChunker.start()

        capturer.isPreviewing.value = false
        capturer.handle(try makeFrame(at: 0))

        XCTAssertEqual(faceDetector.interactions, ["detectFaces(from:)"])
        XCTAssertNotNil(videoChunker.startTimeSeconds, "the frame wasn't recorded")
    }

    /// Given: The get ready screen showing the check's camera
    /// When: The check sets up its preview of the camera
    /// Then: It takes over the get ready screen's preview layer rather than giving the running
    ///       session a second one, which rebuilds the session and froze the main thread
    func testCheckTakesOverTheGetReadyPreviewLayer() throws {
        let captureSession = LivenessCaptureSession(
            captureDevice: .init(avCaptureDevice: nil),
            outputDelegate: capturer
        )
        captureSession.captureSession = AVCaptureSession()
        try captureSession.startPreview()
        let getReadyLayer = try XCTUnwrap(captureSession.sharedPreviewLayer)

        let frame = CGRect(x: 0, y: 0, width: 390, height: 844)
        let checkLayer = try captureSession.configureCamera(frame: frame)

        XCTAssertTrue(checkLayer === getReadyLayer)
        XCTAssertEqual(checkLayer.frame, frame)
        XCTAssertFalse(capturer.isPreviewing.value)
    }

    /// Given: The get ready screen starting the check's camera
    /// When: Configuring the camera fails
    /// Then: No session is left for the check to reuse, and frames go to the check again, so
    ///       the check configures the camera itself and reports the error if it fails again
    func testFailedPreviewLeavesNoSessionForTheCheck() {
        let captureSession = LivenessCaptureSession(
            captureDevice: .init(avCaptureDevice: nil),
            outputDelegate: capturer
        )

        XCTAssertThrowsError(try captureSession.startPreview())

        XCTAssertNil(captureSession.captureSession)
        XCTAssertNil(captureSession.sharedPreviewLayer)
        XCTAssertFalse(capturer.isPreviewing.value)
    }
}
