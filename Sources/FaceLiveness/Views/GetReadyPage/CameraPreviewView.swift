//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import SwiftUI

struct CameraPreviewView: View {
    @StateObject var model: CameraPreviewViewModel
    let framing: LivenessFraming

    init(cameraPosition: LivenessCamera, framing: LivenessFraming = .standard) {
        self._model = StateObject(wrappedValue: CameraPreviewViewModel(cameraPosition: cameraPosition, framing: framing))
        self.framing = framing
    }
    
    var body: some View {
        GeometryReader { geometry in
            let ovalFrame = OvalGeometry.startOvalFrame(previewSize: geometry.size)
            ZStack {
                // Magnified to show exactly what is recorded
                CameraPreviewLayerView(session: model.session)
                    .scaleEffect(framing.startPreviewMagnification)
                    .clipped()
                // Dims the video around the oval, like `OvalView` does while recording
                Path { path in
                    path.addRect(CGRect(origin: .zero, size: geometry.size))
                    path.addEllipse(in: ovalFrame)
                }
                .fill(Color.black.opacity(0.384), style: FillStyle(eoFill: true))
                Ellipse()
                    .stroke(Color.white, style: StrokeStyle(lineWidth: 4))
                    .frame(width: ovalFrame.width, height: ovalFrame.height)
                    .position(x: ovalFrame.midX, y: ovalFrame.midY)
            }
        }
        .edgesIgnoringSafeArea(.all)
        .onDisappear {
            model.stopSession()
        }
    }
}

struct CameraPreviewView_Previews: PreviewProvider {
    static var previews: some View {
        CameraPreviewView(cameraPosition: .front)
    }
}
