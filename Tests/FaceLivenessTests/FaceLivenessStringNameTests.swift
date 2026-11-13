//
// Copyright (c) EyeLinkMedia Ltd, 2026-present.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import FaceLiveness

final class FaceLivenessStringNameTests: XCTestCase {

    func testDefaultValue_everyName_hasBundledEnglish() {
        for name in FaceLivenessStringName.allCases {
            XCTAssertFalse(
                name.defaultValue.hasPrefix("amplify_ui_liveness_"),
                "\(name) is missing from Base.lproj/Localizable.strings"
            )
        }
    }

    func testLocalizedValue_injectedStrings_usesThem() {
        let strings = LivenessStrings { "translated \($0)" }

        let value = LivenessStateMachine.FaceNotPreparedReason.notInOval.localizedValue(using: strings)

        XCTAssertEqual(value, "translated fitInOval")
    }
}
