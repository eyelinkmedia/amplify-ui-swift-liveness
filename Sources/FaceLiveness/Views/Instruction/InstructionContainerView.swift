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
    @Environment(\.livenessStrings) private var strings

    var body: some View {
        switch viewModel.livenessState.state {
        case .displayingFreshness:
            InstructionView(
                icon: .moveCloser,
                text: strings[.holdStill]
            )
            .onAppear {
                UIAccessibility.post(
                    notification: .announcement,
                    argument: strings[.holdStill]
                )
            }

        case .awaitingFaceInOvalMatch(.faceTooClose, _):
            InstructionView(
                icon: .moveCloser,
                text: strings[.moveBack]
            )
            .onAppear {
                UIAccessibility.post(
                    notification: .announcement,
                    argument: strings[.moveBack]
                )
            }

        case .awaitingFaceInOvalMatch(let reason, _):
            InstructionView(
                icon: .moveCloser,
                text: reason.localizedValue(using: strings)
            )
        case .recording(ovalDisplayed: true):
            InstructionView(
                icon: .moveCloser,
                text: strings[.moveCloser]
            )
            .onAppear {
                UIAccessibility.post(
                    notification: .announcement,
                    argument: strings[.moveCloser]
                )
            }
        case .pendingFacePreparedConfirmation(let reason):
            InstructionView(
                icon: .centerYourFace,
                text: reason.localizedValue(using: strings)
            )
        case .completedDisplayingFreshness:
            InstructionView(
                icon: .verifying,
                text: strings[.verifying]
            )
            .onAppear {
                UIAccessibility.post(
                    notification: .announcement,
                    argument: strings[.verifying]
                )
            }
        case .completedNoLightCheck:
            InstructionView(
                icon: .verifying,
                text: strings[.verifying]
            )
            .onAppear {
                UIAccessibility.post(
                    notification: .announcement,
                    argument: strings[.verifying]
                )
            }
        case .faceMatched:
            if let challenge = viewModel.challengeReceived,
               case .faceMovementAndLightChallenge = challenge {
                InstructionView(
                    icon: .moveCloser,
                    text: strings[.holdStill]
                )
            } else {
                EmptyView()
            }
        default:
            EmptyView()
        }
    }
}
