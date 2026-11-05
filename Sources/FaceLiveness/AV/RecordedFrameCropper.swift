//
// Copyright (c) EyeLinkMedia Ltd, 2026-present.
//
// SPDX-License-Identifier: Apache-2.0
//

import AVFoundation
import CoreImage

/// Crops the centre of each camera frame, `zoom` times smaller, and scales it to the 480x640
/// the check records
final class RecordedFrameCropper {
    let outputSize = CGSize(width: 480, height: 640)
    let zoom: CGFloat
    // No color management, so the pixel values the light challenge relies on pass through
    private let context = CIContext(options: [
        .workingColorSpace: NSNull(),
        .outputColorSpace: NSNull(),
        .cacheIntermediates: false
    ])
    private var pool: CVPixelBufferPool?

    init(zoom: CGFloat) {
        self.zoom = zoom
    }

    /// The part of a camera frame of `frameSize` that is recorded
    func cropRect(frameSize: CGSize) -> CGRect {
        let aspectRatio = outputSize.width / outputSize.height
        let width = min(frameSize.width, frameSize.height * aspectRatio) / zoom
        let height = width / aspectRatio
        return CGRect(
            x: (frameSize.width - width) / 2,
            y: (frameSize.height - height) / 2,
            width: width,
            height: height
        )
    }

    func crop(_ sampleBuffer: CMSampleBuffer) -> CMSampleBuffer? {
        guard let source = sampleBuffer.imageBuffer else { return nil }

        let recordedRect = cropRect(frameSize: CGSize(
            width: CVPixelBufferGetWidth(source),
            height: CVPixelBufferGetHeight(source)
        ))
        let image = CIImage(cvPixelBuffer: source)
            .cropped(to: recordedRect)
            .transformed(by: CGAffineTransform(translationX: -recordedRect.minX, y: -recordedRect.minY))
            .transformed(by: CGAffineTransform(
                scaleX: outputSize.width / recordedRect.width,
                y: outputSize.height / recordedRect.height
            ))

        guard let output = makeOutputBuffer() else { return nil }
        context.render(image, to: output)
        return makeSampleBuffer(imageBuffer: output, timingFrom: sampleBuffer)
    }

    private func makeOutputBuffer() -> CVPixelBuffer? {
        if pool == nil {
            let attributes: [String: Any] = [
                kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA,
                kCVPixelBufferWidthKey as String: Int(outputSize.width),
                kCVPixelBufferHeightKey as String: Int(outputSize.height),
                kCVPixelBufferIOSurfacePropertiesKey as String: [String: Any]()
            ]
            CVPixelBufferPoolCreate(nil, nil, attributes as CFDictionary, &pool)
        }
        guard let pool else { return nil }

        var buffer: CVPixelBuffer?
        CVPixelBufferPoolCreatePixelBuffer(nil, pool, &buffer)
        return buffer
    }

    private func makeSampleBuffer(imageBuffer: CVPixelBuffer, timingFrom sampleBuffer: CMSampleBuffer) -> CMSampleBuffer? {
        var timing = CMSampleTimingInfo()
        guard CMSampleBufferGetSampleTimingInfo(sampleBuffer, at: 0, timingInfoOut: &timing) == noErr else {
            return nil
        }

        var formatDescription: CMVideoFormatDescription?
        CMVideoFormatDescriptionCreateForImageBuffer(
            allocator: nil,
            imageBuffer: imageBuffer,
            formatDescriptionOut: &formatDescription
        )
        guard let formatDescription else { return nil }

        var output: CMSampleBuffer?
        CMSampleBufferCreateReadyWithImageBuffer(
            allocator: nil,
            imageBuffer: imageBuffer,
            formatDescription: formatDescription,
            sampleTiming: &timing,
            sampleBufferOut: &output
        )
        return output
    }
}
