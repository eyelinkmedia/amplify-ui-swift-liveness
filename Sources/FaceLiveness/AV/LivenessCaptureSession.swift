//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import UIKit
import AVFoundation
import os

class LivenessCaptureSession {
    let captureDevice: LivenessCaptureDevice
    private let captureQueue = DispatchQueue(label: "com.amazonaws.faceliveness.cameracapturequeue")
    private let configurationQueue = DispatchQueue(label: "com.amazonaws.faceliveness.sessionconfiguration", qos: .userInteractive)
    let outputDelegate: AVCaptureVideoDataOutputSampleBufferDelegate
    var captureSession: AVCaptureSession?
    
    var outputSampleBufferCapturer: OutputSampleBufferCapturer? {
        return outputDelegate as? OutputSampleBufferCapturer
    }

    init(captureDevice: LivenessCaptureDevice, outputDelegate: AVCaptureVideoDataOutputSampleBufferDelegate) {
        self.captureDevice = captureDevice
        self.outputDelegate = outputDelegate
    }

    func configureCamera(frame: CGRect) throws -> CALayer {
        try configureCamera()

        guard let captureSession = captureSession else {
            throw LivenessCaptureSessionError.captureSessionUnavailable
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
        let videoOutput = AVCaptureVideoDataOutput()

        teardownExistingSession(input: cameraInput)
        captureSession = AVCaptureSession()

        guard let captureSession = captureSession else {
            throw LivenessCaptureSessionError.captureSessionUnavailable
        }

        try setupInput(cameraInput, for: captureSession)
        try setupFormat(of: camera, for: captureSession)
        try setupOutput(videoOutput, for: captureSession)
        try captureDevice.configure()
        logFormat(of: camera)

        videoOutput.setSampleBufferDelegate(
            outputDelegate,
            queue: captureQueue
        )
    }

    func startSession() {
        guard let session = captureSession else { return }
        configurationQueue.async {
            session.startRunning()
        }
    }

    func stopRunning() {
        guard let session = captureSession else { return }
        defer {
            captureSession = nil
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

    /// Uses the preset, or a bigger frame when only its centre is recorded, so that the
    /// recorded crop takes real pixels rather than upscaling. Called after the input is
    /// added, as adding it applies the session preset.
    private func setupFormat(of camera: AVCaptureDevice, for captureSession: AVCaptureSession) throws {
        guard captureDevice.framing.recordingCropZoom > 1 else {
            captureSession.sessionPreset = captureDevice.preset
            return
        }
        guard let format = Self.uncroppedFormat(for: camera) else {
            Logger.livenessCamera.error("No 4:3 format of at least 1280x960 at 30 fps, cropping the preset instead")
            captureSession.sessionPreset = captureDevice.preset
            return
        }

        try camera.lockForConfiguration()
        camera.activeFormat = format
        camera.unlockForConfiguration()
    }

    private func logFormat(of camera: AVCaptureDevice) {
        let format = camera.activeFormat
        let dimensions = CMVideoFormatDescriptionGetDimensions(format.formatDescription)
        let framing = String(describing: captureDevice.framing)
        Logger.livenessCamera.info(
            "\(camera.localizedName, privacy: .public): \(dimensions.width)x\(dimensions.height), field of view \(format.videoFieldOfView)°, framing \(framing, privacy: .public)"
        )
    }

    /// The smallest 4:3 format of at least 1280x960 that records at 30 fps
    private static func uncroppedFormat(for camera: AVCaptureDevice) -> AVCaptureDevice.Format? {
        let width = { (format: AVCaptureDevice.Format) in
            CMVideoFormatDescriptionGetDimensions(format.formatDescription).width
        }
        return camera.formats
            .filter { format in
                let dimensions = CMVideoFormatDescriptionGetDimensions(format.formatDescription)
                return dimensions.width * 3 == dimensions.height * 4
                    && dimensions.width >= 1280
                    && format.videoSupportedFrameRateRanges.contains { $0.minFrameRate <= 30 && $0.maxFrameRate >= 30 }
            }
            .min { width($0) < width($1) }
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

extension Logger {
    static let livenessCamera = Logger(subsystem: "com.amazonaws.faceliveness", category: "Camera")
}
