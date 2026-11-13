//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import SwiftUI

struct CameraPermissionView: View {
    @Binding var displayingCameraPermissionsNeededAlert: Bool
    let onClose: () -> Void
    @Environment(\.livenessInstructionAppearance) private var appearance
    @Environment(\.livenessStrings) private var strings

    init(
        displayingCameraPermissionsNeededAlert: Binding<Bool> = .constant(false),
        onClose: @escaping () -> Void
    ) {
        self._displayingCameraPermissionsNeededAlert = displayingCameraPermissionsNeededAlert
        self.onClose = onClose
    }

    var body: some View {
        // Dark like the rest of the check, which the white button needs to stand out
        ZStack {
            Color.black
                .edgesIgnoringSafeArea(.all)
            VStack(alignment: .center) {
                Spacer()
                VStack {
                    Text(appearance.displayText(strings[.cameraPermissionHeader]))
                        .font(.title2)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .padding(8)

                    Text(appearance.displayText(strings[.cameraPermissionDescription]))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .padding(8)
                }
                Spacer()
                editPermissionButton
            }
        }
        .closeButtonOverlay(action: onClose)
        .alert(isPresented: $displayingCameraPermissionsNeededAlert) {
            Alert(
                title: Text(appearance.displayText(strings[.cameraPermissionAlertTitle])),
                message: Text(appearance.displayText(strings[.cameraPermissionAlertMessage])),
                primaryButton: .default(
                    Text(appearance.displayText(strings[.cameraPermissionAlertUpdate])).bold(),
                    action: {
                        goToSettingsAppPage()
                    }),
                secondaryButton: .default(
                    Text(appearance.displayText(strings[.cameraPermissionAlertNotNow]))
                )
            )
        }
    }

    private func goToSettingsAppPage() {
        guard let settingsAppURL = URL(string: UIApplication.openSettingsURLString)
        else { return }
        UIApplication.shared.open(settingsAppURL, options: [:])
    }

    private var editPermissionButton: some View {
        PrimaryButton(
            title: strings[.cameraPermissionButton],
            action: goToSettingsAppPage
        )
    }
}

struct CameraPermissionView_Previews: PreviewProvider {
    static var previews: some View {
        CameraPermissionView(onClose: {})
    }
}
