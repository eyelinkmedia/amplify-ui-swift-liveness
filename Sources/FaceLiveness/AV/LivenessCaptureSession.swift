//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import UIKit
import AVFoundation

class LivenessCaptureSession {
    let captureDevice: LivenessCaptureDevice
    private let captureQueue = DispatchQueue(label: "com.amazonaws.faceliveness.cameracapturequeue")
    private let configurationQueue = DispatchQueue(label: "com.amazonaws.faceliveness.sessionconfiguration", qos: .userInteractive)
    /// Receives the camera frames, nil when the session only feeds a preview layer
    let outputDelegate: AVCaptureVideoDataOutputSampleBufferDelegate?
    var captureSession: AVCaptureSession?
    /// The preview `startPreview()` sets up for the get ready screen, which the check then takes
    /// over
    private(set) var sharedPreviewLayer: AVCaptureVideoPreviewLayer?
    
    var outputSampleBufferCapturer: OutputSampleBufferCapturer? {
        return outputDelegate as? OutputSampleBufferCapturer
    }

    init(captureDevice: LivenessCaptureDevice, outputDelegate: AVCaptureVideoDataOutputSampleBufferDelegate?) {
        self.captureDevice = captureDevice
        self.outputDelegate = outputDelegate
    }

    func configureCamera(frame: CGRect) throws -> CALayer {
        // keep the camera the get ready screen started, rather than restarting it
        stopPreview()
        if captureSession == nil {
            try configureCamera()
        }

        guard let captureSession = captureSession else {
            throw LivenessCaptureSessionError.captureSessionUnavailable
        }
        
        // and its preview: a session shows one preview layer at a time, and giving it another
        // while it runs rebuilds the session, which froze the main thread for seconds
        if let sharedPreviewLayer {
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            sharedPreviewLayer.frame = frame
            CATransaction.commit()
            return sharedPreviewLayer
        }

        let previewLayer = previewLayer(
            frame: frame,
            for: captureSession
        )

        return previewLayer
    }
    
    func configureCamera() throws {
        guard let camera = captureDevice.avCaptureDevice
        else { throw LivenessCaptureSessionError.cameraUnavailable }

        let cameraInput = try AVCaptureDeviceInput(device: camera)

        teardownExistingSession(input: cameraInput)
        captureSession = AVCaptureSession()

        guard let captureSession = captureSession else {
            throw LivenessCaptureSessionError.captureSessionUnavailable
        }

        try setupInput(cameraInput, for: captureSession)
        captureSession.sessionPreset = captureDevice.preset
        if let outputDelegate {
            let videoOutput = AVCaptureVideoDataOutput()
            try setupOutput(videoOutput, for: captureSession)
            videoOutput.setSampleBufferDelegate(outputDelegate, queue: captureQueue)
        }
        try captureDevice.configure()
    }

    func startSession() {
        guard let session = captureSession else { return }
        configurationQueue.async {
            session.startRunning()
        }
    }

    /// Starts the camera for the get ready screen, which shows it through `sharedPreviewLayer`.
    /// Its frames are dropped until the check takes over the running session, and that layer, in
    /// `configureCamera(frame:)`.
    func startPreview() throws {
        outputSampleBufferCapturer?.isPreviewing.value = true
        if captureSession == nil {
            do {
                try configureCamera()
            } catch {
                // drop the half-configured session, so the check configures the camera again
                // and reports the error if it fails again
                stopPreview()
                stopRunning()
                throw error
            }
        }
        if sharedPreviewLayer == nil, let captureSession {
            // before the session starts, so it doesn't have to be rebuilt for the preview
            sharedPreviewLayer = previewLayer(frame: .zero, for: captureSession)
        }
        startSession()
    }

    /// Sends the frames to the check again; the camera keeps running.
    func stopPreview() {
        outputSampleBufferCapturer?.isPreviewing.value = false
    }

    func stopRunning() {
        guard let session = captureSession else { return }
        defer {
            captureSession = nil
            sharedPreviewLayer = nil
        }

        if session.isRunning {
            session.stopRunning()
        }

        for input in session.inputs {
            session.removeInput(input)
        }
        
        for output in session.outputs {
            session.removeOutput(output)
        }
    }

    private func teardownExistingSession(input: AVCaptureDeviceInput) {
        stopRunning()
        captureSession?.removeInput(input)
    }

    private func setupInput(
        _ input: AVCaptureDeviceInput,
        for captureSession: AVCaptureSession
    ) throws {
        if captureSession.canAddInput(input) {
            captureSession.addInput(input)
        } else {
            throw LivenessCaptureSessionError.captureSessionInputUnavailable
        }
    }

    private func setupOutput(
        _ output: AVCaptureVideoDataOutput,
        for captureSession: AVCaptureSession
    ) throws {
        if captureSession.canAddOutput(output) {
            captureSession.addOutput(output)
        } else {
            throw LivenessCaptureSessionError.captureSessionOutputUnavailable
        }
        output.videoSettings = [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
        ]

        output.connections
            .filter(\.isVideoOrientationSupported)
            .forEach {
                $0.videoOrientation = .portrait
                $0.isVideoMirrored = true
        }
    }

    private func previewLayer(
        frame: CGRect,
        for captureSession: AVCaptureSession
    ) -> AVCaptureVideoPreviewLayer {
        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.connection?.videoOrientation = .portrait
        previewLayer.frame = frame
        return previewLayer
    }
}
