//
// Copyright (c) EyeLinkMedia Ltd, 2026-present.
//
// SPDX-License-Identifier: Apache-2.0
//

import AVFoundation
import SwiftUI

/// Shows a capture session's `AVCaptureVideoPreviewLayer`, which draws the frames on the GPU, set
/// up like the preview of the recording screen. The layer is the session's own rather than this
/// view's, so the check can take it over without giving the session a second one.
struct CameraPreviewLayerView: UIViewRepresentable {
    let previewLayer: AVCaptureVideoPreviewLayer?

    func makeUIView(context: Context) -> PreviewView {
        let view = PreviewView()
        view.backgroundColor = .black
        view.previewLayer = previewLayer
        return view
    }

    func updateUIView(_ uiView: PreviewView, context: Context) {}

    final class PreviewView: UIView {
        var previewLayer: AVCaptureVideoPreviewLayer? {
            didSet {
                guard let previewLayer else { return }
                layer.addSublayer(previewLayer)
                setNeedsLayout()
            }
        }

        override func layoutSubviews() {
            super.layoutSubviews()
            // once the check has taken the layer over, it's no longer this view's to lay out
            guard let previewLayer, previewLayer.superlayer === layer else { return }
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            previewLayer.frame = bounds
            CATransaction.commit()
        }
    }
}
