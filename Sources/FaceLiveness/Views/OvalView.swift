//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import UIKit

class OvalView: UIView {
    let ovalFrame: CGRect

    init(frame: CGRect, ovalFrame: CGRect) {
        self.ovalFrame = ovalFrame
        super.init(frame: frame)
        backgroundColor = .clear
    }

    override func draw(_ rect: CGRect) {
        let mask = UIBezierPath(rect: bounds)
        let oval = UIBezierPath(ovalIn: ovalFrame)
        mask.append(oval.reversing())

        UIColor.black.withAlphaComponent(0.384).setFill()
        mask.fill()

        UIColor.clear.setFill()
        UIColor.white.setStroke()
        oval.lineWidth = 4
        oval.stroke()
    }

    required init?(coder: NSCoder) { nil }
}
