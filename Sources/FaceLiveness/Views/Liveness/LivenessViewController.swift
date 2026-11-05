//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import UIKit
import AVFoundation
import Vision
import Amplify
@_spi(PredictionsFaceLiveness) import AWSPredictionsPlugin

final class _LivenessViewController: UIViewController {
    let viewModel: FaceLivenessDetectionViewModel
    var previewLayer: CALayer?

    let faceShapeLayer = CAShapeLayer()
    var ovalExists = false
    var ovalRect: CGRect?
    var freshness = Freshness()
    let freshnessView = FreshnessView()
    var readyForOval = false

    init(
        viewModel: FaceLivenessDetectionViewModel
    ) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
        viewModel.livenessViewControllerDelegate = self
        viewModel.normalizeFace = { [weak self] face in
            guard let self = self else { return face }
            return DispatchQueue.main.sync {
                face.normalize(width: self.view.frame.width, height: self.view.frame.width / 3 * 4)
            }
        }
    }
    
    deinit {
        guard let previewLayer = self.previewLayer else { return }
        previewLayer.removeFromSuperlayer()
        (previewLayer as? AVCaptureVideoPreviewLayer)?.session = nil
        self.previewLayer = nil
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        layoutSubviews()
        setupAVLayer()
    }

    override func viewDidLayoutSubviews() {
        previewLayer?.position = view.center
    }

    private func layoutSubviews() {
        freshnessView.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(freshnessView)
        NSLayoutConstraint.activate([
            freshnessView.topAnchor.constraint(equalTo: view.topAnchor),
            freshnessView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            freshnessView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            freshnessView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
        freshnessView.clearColors()
    }

    private func setupAVLayer() {
        guard previewLayer == nil else { return }
        let x = view.frame.minX
        let y = view.frame.minY
        let width = view.frame.width
        let height = width / 3 * 4
        let cameraFrame = CGRect(x: x, y: y, width: width, height: height)

        // The preview fills the whole view (aspect-fill), while face detection and the
        // oval stay in the coordinates of the 3:4 `cameraFrame`.
        guard let avLayer = viewModel.configureCamera(withinFrame: view.bounds) else {
            DispatchQueue.main.async { [weak self] in
                self?.viewModel.livenessState
                    .unrecoverableStateEncountered(.missingVideoPermission)
            }
            return
        }

        avLayer.position = view.center
        self.previewLayer = avLayer
        viewModel.cameraViewRect = cameraFrame

        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            // Magnified like the get-ready preview until the challenge oval appears
            self.setPreviewMagnification(self.viewModel.framing.startPreviewMagnification, animated: false)
            self.view.layer.insertSublayer(avLayer, at: 0)
            self.view.layoutIfNeeded()
            // Continues the oval of the get-ready screen until the challenge oval replaces it
            self.addOvalView(ovalFrame: OvalGeometry.startOvalFrame(previewSize: avLayer.bounds.size))

            self.viewModel.startSession()
        }
    }

    var runningFreshness = false
    var hasSentClientInformationEvent = false
    var challengeID = UUID().uuidString
    var initialFace: FaceDetection?
    var videoStartTimeStamp: UInt64?
    var faceMatchStartTime: UInt64?
    var freshnessEventsComplete = false
    var videoSentCount = 0
    var hasSentFinalEvent = false
    var hasSentEmptyFinalVideoEvent = false
    var ovalView: OvalView?


    required init?(coder: NSCoder) { fatalError() }
}

extension _LivenessViewController: FaceLivenessViewControllerPresenter {
    func displaySingleFrame(uiImage: UIImage) {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            guard let previewLayer = self.previewLayer else { return }
            // The whole camera frame, magnified like the preview, which may show more than
            // is recorded
            let image = self.viewModel.latestCameraFrame
                .map { UIImage(ciImage: CIImage(cvPixelBuffer: $0)) } ?? uiImage
            let imageView = UIImageView(image: image)
            imageView.bounds = previewLayer.bounds
            imageView.center = previewLayer.position
            imageView.transform = previewLayer.affineTransform()
            imageView.contentMode = .scaleAspectFill
            imageView.clipsToBounds = true
            self.view.addSubview(imageView)
            (previewLayer as? AVCaptureVideoPreviewLayer)?.session = nil
            previewLayer.removeFromSuperlayer()
            self.viewModel.stopRecording()
        }
    }

    func displayFreshness(colorSequences: [FaceLivenessSession.DisplayColor]) {
        self.ovalView?.setNeedsDisplay()
        DispatchQueue.main.async { [weak self] in
            self?.viewModel.livenessState.displayingFreshness()
        }
        self.freshness.showColorSequences(
            colorSequences,
            width: UIScreen.main.bounds.width,
            height: UIScreen.main.bounds.height,
            view: self.freshnessView,
            onNewColor: { [weak self] colorEvent in
                self?.viewModel.sendColorDisplayedEvent(colorEvent)
            },
            onComplete: { [weak self] in
                guard let self else { return }
                self.freshnessView.removeFromSuperview()

                self.viewModel.handleFreshnessComplete()
            }
        )
    }

    func stopFreshness() {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.freshness.cancel()
            // Clear the colors but leave the view in the hierarchy so that, if the face
            // returns and re-matches, `displayFreshness(colorSequences:)` can restart the
            // flash on the same view.
            self.freshnessView.clearColors()
        }
    }

    func drawOvalInCanvas(_ ovalRect: CGRect) {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            guard let previewLayer = self.previewLayer else { return }

            let framing = self.viewModel.framing
            let ovalFrame = OvalGeometry.challengeOvalFrame(
                fromCameraRect: ovalRect,
                cameraSize: self.viewModel.cameraViewRect.size,
                previewSize: previewLayer.bounds.size,
                recordedFrameScale: framing.challengePreviewMagnification / framing.recordingCropZoom
            )
            // A preview that zooms out does it while the oval grows, both at once
            self.setPreviewMagnification(framing.challengePreviewMagnification, animated: true)
            if let ovalView = self.ovalView {
                ovalView.setOvalFrame(ovalFrame, animated: true)
            } else {
                self.addOvalView(ovalFrame: ovalFrame)
            }

            self.ovalRect = ovalRect
            self.ovalExists = true
        }
    }
    
    func completeNoLightCheck() {
        self.viewModel.completeNoLightCheck()
    }

    private func addOvalView(ovalFrame: CGRect) {
        guard let previewLayer = self.previewLayer else { return }

        // The bounds rather than the frame, which grows with the magnification
        let ovalView = OvalView(
            frame: CGRect(origin: .zero, size: previewLayer.bounds.size),
            ovalFrame: ovalFrame
        )
        self.ovalView = ovalView
        ovalView.center = previewLayer.position
        self.view.insertSubview(
            ovalView,
            belowSubview: self.freshnessView
        )
    }

    /// Magnifies the preview around its centre, in step with the oval when `animated`. Does
    /// nothing when it is magnified as much already, as the challenge oval is drawn for
    /// several frames in a row.
    private func setPreviewMagnification(_ magnification: CGFloat, animated: Bool) {
        guard let previewLayer = self.previewLayer else { return }
        let transform = CATransform3DMakeScale(magnification, magnification, 1)
        guard !CATransform3DEqualToTransform(previewLayer.transform, transform) else { return }

        CATransaction.begin()
        CATransaction.setDisableActions(true)
        if animated {
            let animation = CABasicAnimation(keyPath: "transform")
            animation.fromValue = previewLayer.transform
            animation.toValue = transform
            animation.duration = OvalView.ovalFrameAnimationDuration
            animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            previewLayer.add(animation, forKey: "transform")
        }
        previewLayer.transform = transform
        CATransaction.commit()
    }
}
