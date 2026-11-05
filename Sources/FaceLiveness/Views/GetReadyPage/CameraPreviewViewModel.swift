//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import AVFoundation
import Amplify

class CameraPreviewViewModel: NSObject, ObservableObject {
    var previewCaptureSession: LivenessCaptureSession?
    let cameraPosition: LivenessCamera

    /// Shown through a preview layer, which draws the frames itself
    var session: AVCaptureSession? {
        previewCaptureSession?.captureSession
    }

    init(cameraPosition: LivenessCamera) {
        self.cameraPosition = cameraPosition

        super.init()

        let avCaptureDevice = AVCaptureDevice.DiscoverySession(
            deviceTypes: [.builtInWideAngleCamera],
            mediaType: .video,
            position: cameraPosition == .front ? .front : .back
        ).devices.first

        // The session always delivers frames to an output, which the preview has no use for
        let outputDelegate = CameraPreviewOutputSampleBufferDelegate { _ in }

        self.previewCaptureSession = LivenessCaptureSession(
            captureDevice: .init(avCaptureDevice: avCaptureDevice),
            outputDelegate: outputDelegate
        )

        do {
            try previewCaptureSession?.configureCamera()
            previewCaptureSession?.startSession()
        } catch {
            Amplify.Logging.default.error("Error starting preview capture session with error: \(error)")
        }
    }

    func stopSession() {
        previewCaptureSession?.stopRunning()
    }
}
