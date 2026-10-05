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

    init(
        onBegin: @escaping () -> Void,
        onClose: @escaping () -> Void,
        beginCheckButtonDisabled: Bool = false,
        cameraPosition: LivenessCamera
    ) {
        self.onBegin = onBegin
        self.onClose = onClose
        self.beginCheckButtonDisabled = beginCheckButtonDisabled
        self.cameraPosition = cameraPosition
    }

    var body: some View {
        // The preview sits behind the whole page rather than above the button, so it
        // fills the screen exactly like the recording preview that follows.
        ZStack {
            CameraPreviewView(cameraPosition: cameraPosition)
            VStack {
                InstructionView(
                    icon: .centerYourFace,
                    text: LocalizedStrings.preview_center_your_face_text
                )
                .padding(.top, 22)
                Spacer()
                beginCheckButton
            }
        }
        .closeButtonOverlay(action: onClose)
    }

    private var beginCheckButton: some View {
        Button(
            action: onBegin,
            label: {
                Text(LocalizedStrings.get_ready_begin_check)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    // Inside the label, so that the whole capsule is tappable rather than
                    // just the text
                    .frame(height: 48)
                    ._background { Color.white }
                    .clipShape(Capsule())
            }
        )
        .disabled(beginCheckButtonDisabled)
        .padding([.leading, .trailing], 24)
        .padding(.bottom, 14)
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
