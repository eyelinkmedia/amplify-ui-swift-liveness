//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AVFoundation
import CoreImage
import os

class OutputSampleBufferCapturer: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    let faceDetector: FaceDetector
    let videoChunker: VideoChunker
    /// Crops the recorded part out of each camera frame, nil when the whole frame is recorded
    private let frameCropper: RecordedFrameCropper?
    private let latestCameraFrameLock = NSLock()
    private var _latestCameraFrame: CVPixelBuffer?
    private var hasLoggedFrameSize = false

    /// The last whole camera frame, which may be more than is recorded
    var latestCameraFrame: CVPixelBuffer? {
        latestCameraFrameLock.lock()
        defer { latestCameraFrameLock.unlock() }
        return _latestCameraFrame
    }

    init(
        faceDetector: FaceDetector,
        videoChunker: VideoChunker,
        framing: LivenessFraming = .standard
    ) {
        self.faceDetector = faceDetector
        self.videoChunker = videoChunker
        self.frameCropper = framing.recordingCropZoom > 1
            ? RecordedFrameCropper(zoom: framing.recordingCropZoom)
            : nil
    }

    func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        let recordedSampleBuffer: CMSampleBuffer
        if let frameCropper {
            // Dropped rather than recorded whole, which would change the framing mid-video
            guard let croppedSampleBuffer = frameCropper.crop(sampleBuffer) else { return }
            recordedSampleBuffer = croppedSampleBuffer
        } else {
            recordedSampleBuffer = sampleBuffer
        }
        videoChunker.consume(recordedSampleBuffer)

        guard let cameraFrame = sampleBuffer.imageBuffer,
              let recordedFrame = recordedSampleBuffer.imageBuffer
        else { return }

        latestCameraFrameLock.lock()
        _latestCameraFrame = cameraFrame
        latestCameraFrameLock.unlock()
        logFrameSizeOnce(cameraFrame: cameraFrame, recordedFrame: recordedFrame)

        faceDetector.detectFaces(from: recordedFrame)
    }

    private func logFrameSizeOnce(cameraFrame: CVPixelBuffer, recordedFrame: CVPixelBuffer) {
        guard !hasLoggedFrameSize else { return }
        hasLoggedFrameSize = true

        let cameraSize = CGSize(width: CVPixelBufferGetWidth(cameraFrame), height: CVPixelBufferGetHeight(cameraFrame))
        let recordedSize = CGSize(width: CVPixelBufferGetWidth(recordedFrame), height: CVPixelBufferGetHeight(recordedFrame))
        let croppedSize = frameCropper?.cropRect(frameSize: cameraSize).size ?? cameraSize
        Logger.livenessCamera.info(
            "Recording \(Int(croppedSize.width))x\(Int(croppedSize.height)) of the \(Int(cameraSize.width))x\(Int(cameraSize.height)) camera frame, scaled to \(Int(recordedSize.width))x\(Int(recordedSize.height))"
        )
    }
}
