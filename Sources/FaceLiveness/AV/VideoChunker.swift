//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AVFoundation
import CoreImage
import UIKit

final class VideoChunker {
    let assetWriter: AVAssetWriter
    let assetWriterDelegate: AssetWriterDelegate
    let assetWriterInput: AVAssetWriterInput
    let pixelBufferAdaptor: AVAssetWriterInputPixelBufferAdaptor

    // Three threads reach this object:
    //   consume(_:)          the capture session's video data output queue
    //   start()              main, via `drawOval`'s dispatched completion
    //   finish(singleFrame:) a global queue, via the `asyncAfter` in
    //                        `...ViewModel+VideoSegmentProcessor`
    private let lock = NSLock()
    private var state = State.pending
    private var startTimeSeconds: Double?
    private var provideSingleFrame: ((UIImage) -> Void)?

    var currentState: State {
        lock.lock()
        defer { lock.unlock() }
        return state
    }

    init(
        assetWriter: AVAssetWriter,
        assetWriterDelegate: AssetWriterDelegate,
        assetWriterInput: AVAssetWriterInput
    ) {
        self.assetWriter = assetWriter
        self.assetWriterDelegate = assetWriterDelegate
        self.assetWriterInput = assetWriterInput
        self.pixelBufferAdaptor = .init(assetWriterInput: assetWriterInput)
        self.assetWriterInput.expectsMediaDataInRealTime = true
        self.assetWriter.delegate = assetWriterDelegate
        self.assetWriter.add(assetWriterInput)
    }

    func start() {
        lock.lock()
        defer { lock.unlock() }

        guard state == .pending else { return }
        assetWriter.startWriting()
        assetWriter.startSession(atSourceTime: .zero)
        state = .writing
    }

    func finish(singleFrame: @escaping (UIImage) -> Void) {
        lock.lock()
        defer { lock.unlock() }

        self.provideSingleFrame = singleFrame
        state = .awaitingSingleFrame

        // explicitly calling `endSession` is unnecessary
        if assetWriter.status != .completed {
            assetWriter.finishWriting {}
        }
    }

    func consume(_ buffer: CMSampleBuffer) {
        if let imageBuffer = buffer.imageBuffer,
           let provideSingleFrame = completeAwaitingSingleFrame() {
            provideSingleFrame(singleFrame(from: imageBuffer))
            return
        }

        append(buffer)
    }

    private func completeAwaitingSingleFrame() -> ((UIImage) -> Void)? {
        lock.lock()
        defer { lock.unlock() }

        guard state == .awaitingSingleFrame else { return nil }
        state = .complete
        return provideSingleFrame
    }

    private func append(_ buffer: CMSampleBuffer) {
        lock.lock()
        defer { lock.unlock() }

        guard state == .writing else { return }

        if assetWriterInput.isReadyForMoreMediaData {
            let timestamp = CMSampleBufferGetPresentationTimeStamp(buffer).seconds
            if startTimeSeconds == nil { startTimeSeconds = timestamp }
            guard let startTimeSeconds else {
                return
            }
            let presentationTime = CMTime(seconds: timestamp - startTimeSeconds, preferredTimescale: 600)
            guard let imageBuffer = buffer.imageBuffer else { return }

            pixelBufferAdaptor.append(
                imageBuffer,
                withPresentationTime: presentationTime
            )
        }
    }

    private func singleFrame(from buffer: CVPixelBuffer) -> UIImage {
        let ciImage = CIImage(cvPixelBuffer: buffer)
        let uiImage = UIImage(ciImage: ciImage)
        return uiImage
    }
}
