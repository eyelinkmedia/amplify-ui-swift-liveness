//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import SwiftUI

struct GetReadyPageView: View {
    let beginCheckButtonDisabled: Bool
    let onBegin: () -> Void
    let onClose: () -> Void
    let cameraPosition: LivenessCamera
    let sharedCaptureSession: LivenessCaptureSession?
    @Environment(\.livenessStrings) private var strings

    init(
        onBegin: @escaping () -> Void,
        onClose: @escaping () -> Void,
        beginCheckButtonDisabled: Bool = false,
        cameraPosition: LivenessCamera,
        sharedCaptureSession: LivenessCaptureSession? = nil
    ) {
        self.onBegin = onBegin
        self.onClose = onClose
        self.beginCheckButtonDisabled = beginCheckButtonDisabled
        self.cameraPosition = cameraPosition
        self.sharedCaptureSession = sharedCaptureSession
    }

    var body: some View {
        // The preview sits behind the whole page rather than above the button, so it
        // fills the screen exactly like the recording preview that follows.
        ZStack {
            CameraPreviewView(cameraPosition: cameraPosition, sharedCaptureSession: sharedCaptureSession)
            VStack {
                InstructionView(
                    icon: .centerYourFace,
                    text: strings[.centerFace]
                )
                .padding(.top, 22)
                Spacer()
                beginCheckButton
            }
        }
        .closeButtonOverlay(action: onClose)
    }

    private var beginCheckButton: some View {
        PrimaryButton(
            title: strings[.startCheck],
            action: onBegin
        )
        .disabled(beginCheckButtonDisabled)
    }
}

struct GetReadyPageView_Previews: PreviewProvider {
    static var previews: some View {
        GetReadyPageView(
            onBegin: {},
            onClose: {},
            cameraPosition: .front)
    }
}
