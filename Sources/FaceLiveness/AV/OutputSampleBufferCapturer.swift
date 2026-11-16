//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AVFoundation
import CoreImage

class OutputSampleBufferCapturer: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    let faceDetector: FaceDetector
    let videoChunker: VideoChunker
    /// Set while the get ready screen shows this session's camera through its preview layer;
    /// the frames are dropped until the check takes over the session.
    let isPreviewing = Synchronized(false)

    init(faceDetector: FaceDetector, videoChunker: VideoChunker) {
        self.faceDetector = faceDetector
        self.videoChunker = videoChunker
    }

    func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        handle(sampleBuffer)
    }

    func handle(_ sampleBuffer: CMSampleBuffer) {
        guard !isPreviewing.value else { return }

        videoChunker.consume(sampleBuffer)

        guard let imageBuffer = sampleBuffer.imageBuffer
        else { return }

        faceDetector.detectFaces(from: imageBuffer)
    }
}
