//
// Copyright (c) EyeLinkMedia Ltd, 2026-present.
//
// SPDX-License-Identifier: Apache-2.0
//

import SwiftUI

/// Every text the check shows. `FaceLivenessDetectorView` takes a translation of each through
/// its `strings` parameter; `defaultValue` is the English the package ships.
public enum FaceLivenessStringName: CaseIterable, Sendable {
    /// "Start video check": the button of the get-ready screen
    case startCheck
    /// "Center your face": the instruction of the get-ready screen
    case centerFace
    /// "Connecting...": shown while the session starts
    case connecting
    /// "Verifying": shown once the check is recorded
    case verifying
    /// "Hold still": shown while the colored lights flash
    case holdStill
    /// "Move back": the face is too close to the camera during the check
    case moveBack
    /// "Move closer": the face is too far from the camera
    case moveCloser
    /// "Only one face per check"
    case oneFaceOnly
    /// "Move face to fit in oval"
    case fitInOval
    /// "Move face right"
    case moveRight
    /// "Move face left"
    case moveLeft
    /// "Move to dimmer area"
    case moveToDimmerArea
    /// "Move to brighter area"
    case moveToBrighterArea
    /// "Move face in front of camera": no face is detected
    case noFace
    /// "Move face farther away": the face is too close before the check starts
    case tooClose
    /// "Camera is not accessible": the title of the camera permission screen
    case cameraPermissionHeader
    /// "You may have to go into settings to grant camera permissions and close the app and retry."
    case cameraPermissionDescription
    /// "Change Camera Setting": the button of the camera permission screen
    case cameraPermissionButton
    /// "Change Your Camera Settings": the title of the alert leading to Settings
    case cameraPermissionAlertTitle
    /// "Allow camera permission in settings."
    case cameraPermissionAlertMessage
    /// "Update Setting": opens Settings
    case cameraPermissionAlertUpdate
    /// "Not Now": dismisses the alert
    case cameraPermissionAlertNotNow
    /// "Close": the accessibility label of the close button
    case close

    /// The English the package ships
    public var defaultValue: String {
        NSLocalizedString(key, bundle: .module, comment: "")
    }

    private var key: String {
        switch self {
        case .startCheck:
            return "amplify_ui_liveness_get_ready_begin_check"
        case .centerFace:
            return "amplify_ui_liveness_center_your_face_text"
        case .connecting:
            return "amplify_ui_liveness_challenge_connecting"
        case .verifying:
            return "amplify_ui_liveness_challenge_verifying"
        case .holdStill:
            return "amplify_ui_liveness_challenge_instruction_hold_still"
        case .moveBack:
            return "amplify_ui_liveness_challenge_instruction_move_face_back"
        case .moveCloser:
            return "amplify_ui_liveness_challenge_instruction_move_face_closer"
        case .oneFaceOnly:
            return "amplify_ui_liveness_challenge_instruction_multiple_faces_detected"
        case .fitInOval:
            return "amplify_ui_liveness_face_not_prepared_reason_not_in_oval"
        case .moveRight:
            return "amplify_ui_liveness_face_not_prepared_reason_move_face_right"
        case .moveLeft:
            return "amplify_ui_liveness_face_not_prepared_reason_move_face_left"
        case .moveToDimmerArea:
            return "amplify_ui_liveness_face_not_prepared_reason_move_to_dimmer_area"
        case .moveToBrighterArea:
            return "amplify_ui_liveness_face_not_prepared_reason_move_to_brighter_area"
        case .noFace:
            return "amplify_ui_liveness_face_not_prepared_reason_no_face"
        case .tooClose:
            return "amplify_ui_liveness_face_not_prepared_reason_face_too_close"
        case .cameraPermissionHeader:
            return "amplify_ui_liveness_camera_permission_button_header"
        case .cameraPermissionDescription:
            return "amplify_ui_liveness_camera_permission_button_description"
        case .cameraPermissionButton:
            return "amplify_ui_liveness_camera_permission_button_title"
        case .cameraPermissionAlertTitle:
            return "amplify_ui_liveness_camera_setting_alert_title"
        case .cameraPermissionAlertMessage:
            return "amplify_ui_liveness_camera_setting_alert_message"
        case .cameraPermissionAlertUpdate:
            return "amplify_ui_liveness_camera_setting_alert_update_setting_button_text"
        case .cameraPermissionAlertNotNow:
            return "amplify_ui_liveness_camera_setting_alert_not_now_button_text"
        case .close:
            return "amplify_ui_liveness_close_button_a11y"
        }
    }
}

/// The text of the check, as passed to `FaceLivenessDetectorView`
struct LivenessStrings {
    static var english: LivenessStrings {
        LivenessStrings { $0.defaultValue }
    }

    private let string: (FaceLivenessStringName) -> String

    init(_ string: @escaping (FaceLivenessStringName) -> String) {
        self.string = string
    }

    subscript(_ name: FaceLivenessStringName) -> String {
        string(name)
    }
}

extension EnvironmentValues {
    var livenessStrings: LivenessStrings {
        get { self[LivenessStringsKey.self] }
        set { self[LivenessStringsKey.self] = newValue }
    }
}

private struct LivenessStringsKey: EnvironmentKey {
    static var defaultValue: LivenessStrings { .english }
}
