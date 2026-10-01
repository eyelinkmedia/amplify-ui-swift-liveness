//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import SwiftUI

struct CameraPreviewView: View {
    // The oval as fractions of the camera frame, rather than of the screen, so it covers
    // the same part of the frame on every iPhone. The size reproduces the original layout
    // (60% x 55% of the area above the begin button) on a 393x852pt screen, which keeps the
    // distance users start the check from. It is centered like the oval the server sends.
    private static let ovalWidthRatio = 0.42
    private static let ovalHeightRatio = 0.51
    private static let ovalCenterXRatio = 0.5
    private static let ovalCenterYRatio = 0.5
    private static let cameraFrameSize = CGSize(width: 480, height: 640)
    
    @StateObject var model: CameraPreviewViewModel
    
    init(cameraPosition: LivenessCamera) {
        self._model = StateObject(wrappedValue: CameraPreviewViewModel(cameraPosition: cameraPosition))
    }
    
    var body: some View {
        GeometryReader { geometry in
            let ovalFrame = Self.ovalFrame(previewSize: geometry.size)
            ZStack {
                ImageFrameView(image: model.currentImageFrame)
                    .mask(
                        Ellipse()
                            .frame(width: ovalFrame.width, height: ovalFrame.height)
                            .position(x: ovalFrame.midX, y: ovalFrame.midY)
                    )
                Ellipse()
                    .stroke(Color.livenessPreviewBorder, style: StrokeStyle(lineWidth: 3))
                    .frame(width: ovalFrame.width, height: ovalFrame.height)
                    .position(x: ovalFrame.midX, y: ovalFrame.midY)
            }
        }
        .edgesIgnoringSafeArea(.all)
        .onDisappear {
            model.stopSession()
        }
    }

    /// Maps the oval from the camera frame onto the preview, which aspect-fills the frame
    /// (see `ImageFrameView`) and crops whichever sides overflow.
    private static func ovalFrame(previewSize: CGSize) -> CGRect {
        let scale = max(
            previewSize.width / cameraFrameSize.width,
            previewSize.height / cameraFrameSize.height
        )
        let originX = (previewSize.width - cameraFrameSize.width * scale) / 2
        let originY = (previewSize.height - cameraFrameSize.height * scale) / 2
        let width = cameraFrameSize.width * ovalWidthRatio * scale
        let height = cameraFrameSize.height * ovalHeightRatio * scale

        return CGRect(
            x: originX + cameraFrameSize.width * ovalCenterXRatio * scale - width / 2,
            y: originY + cameraFrameSize.height * ovalCenterYRatio * scale - height / 2,
            width: width,
            height: height
        )
    }
}

struct CameraPreviewView_Previews: PreviewProvider {
    static var previews: some View {
        CameraPreviewView(cameraPosition: .front)
    }
}
