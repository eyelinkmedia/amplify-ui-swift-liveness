//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import SwiftUI
import Combine
@_spi(PredictionsFaceLiveness) import AWSPredictionsPlugin

struct InstructionContainerView: View {
    @ObservedObject var viewModel: FaceLivenessDetectionViewModel

    var body: some View {
        switch viewModel.livenessState.state {
        case .displayingFreshness:
            InstructionView(
                icon: .moveCloser,
                text: LocalizedStrings.challenge_instruction_hold_still
            )
            .onAppear {
                UIAccessibility.post(
                    notification: .announcement,
                    argument: LocalizedStrings.challenge_instruction_hold_still
                )
            }

        case .awaitingFaceInOvalMatch(.faceTooClose, _):
            InstructionView(
                icon: .moveCloser,
                text: LocalizedStrings.challenge_instruction_move_face_back
            )
            .onAppear {
                UIAccessibility.post(
                    notification: .announcement,
                    argument: LocalizedStrings.challenge_instruction_move_face_back
                )
            }

        case .awaitingFaceInOvalMatch(let reason, _):
            InstructionView(
                icon: .moveCloser,
                text: .init(reason.localizedValue)
            )
        case .recording(ovalDisplayed: true):
            InstructionView(
                icon: .moveCloser,
                text: LocalizedStrings.challenge_instruction_move_face_closer
            )
            .onAppear {
                UIAccessibility.post(
                    notification: .announcement,
                    argument: LocalizedStrings.challenge_instruction_move_face_closer
                )
            }
        case .pendingFacePreparedConfirmation(let reason):
            InstructionView(
                icon: .centerYourFace,
                text: .init(reason.localizedValue)
            )
        case .completedDisplayingFreshness:
            InstructionView(
                icon: .verifying,
                text: LocalizedStrings.challenge_verifying
            )
            .onAppear {
                UIAccessibility.post(
                    notification: .announcement,
                    argument: LocalizedStrings.challenge_verifying
                )
            }
        case .completedNoLightCheck:
            InstructionView(
                icon: .verifying,
                text: LocalizedStrings.challenge_verifying
            )
            .onAppear {
                UIAccessibility.post(
                    notification: .announcement,
                    argument: LocalizedStrings.challenge_verifying
                )
            }
        case .faceMatched:
            if let challenge = viewModel.challengeReceived,
               case .faceMovementAndLightChallenge = challenge {
                InstructionView(
                    icon: .moveCloser,
                    text: LocalizedStrings.challenge_instruction_hold_still
                )
            } else {
                EmptyView()
            }
        default:
            EmptyView()
        }
    }
}
