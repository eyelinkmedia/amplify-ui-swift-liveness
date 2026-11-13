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
    /// The check's session, shown here so starting the check doesn't restart the camera.
    private var sharedCaptureSession: LivenessCaptureSession?
    let cameraPosition: LivenessCamera

    /// Draws the frames itself; the check takes over the shared session's one
    var previewLayer: AVCaptureVideoPreviewLayer? {
        (sharedCaptureSession ?? previewCaptureSession)?.sharedPreviewLayer
    }

    init(cameraPosition: LivenessCamera, sharedCaptureSession: LivenessCaptureSession? = nil) {
        self.cameraPosition = cameraPosition

        super.init()

        if let sharedCaptureSession {
            self.sharedCaptureSession = sharedCaptureSession
            do {
                try sharedCaptureSession.startPreview()
            } catch {
                Amplify.Logging.default.error("Error starting preview capture session with error: \(error)")
            }
            return
        }

        let avCaptureDevice = AVCaptureDevice.DiscoverySession(
            deviceTypes: [.builtInWideAngleCamera],
            mediaType: .video,
            position: cameraPosition == .front ? .front : .back
        ).devices.first

        // No frame output: the preview layer draws the frames itself
        self.previewCaptureSession = LivenessCaptureSession(
            captureDevice: .init(avCaptureDevice: avCaptureDevice),
            outputDelegate: nil
        )

        do {
            try previewCaptureSession?.startPreview()
        } catch {
            Amplify.Logging.default.error("Error starting preview capture session with error: \(error)")
        }
    }

    func stopSession() {
        // the shared session keeps running for the check, which takes it over when it starts,
        // or stops it if the detector is removed first
        previewCaptureSession?.stopRunning()
    }
}
