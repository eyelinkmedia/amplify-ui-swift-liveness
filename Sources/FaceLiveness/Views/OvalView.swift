//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import UIKit

class OvalView: UIView {
    private static let ovalFrameAnimationDuration: CFTimeInterval = 0.3

    private(set) var ovalFrame: CGRect
    private let dimmingLayer = CAShapeLayer()
    private let borderLayer = CAShapeLayer()

    init(frame: CGRect, ovalFrame: CGRect) {
        self.ovalFrame = ovalFrame
        super.init(frame: frame)
        backgroundColor = .clear

        dimmingLayer.fillColor = UIColor.black.withAlphaComponent(0.384).cgColor
        dimmingLayer.fillRule = .evenOdd
        layer.addSublayer(dimmingLayer)

        borderLayer.fillColor = UIColor.clear.cgColor
        borderLayer.strokeColor = UIColor.white.cgColor
        borderLayer.lineWidth = 4
        layer.addSublayer(borderLayer)

        updatePaths()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        updatePaths()
    }

    /// Moves the oval to `ovalFrame`, growing or shrinking it there when `animated`
    func setOvalFrame(_ ovalFrame: CGRect, animated: Bool) {
        // The same oval is set again for every camera frame until the oval is reported as
        // displayed, and restarting the animation would cut it short
        guard ovalFrame != self.ovalFrame else { return }

        let dimmingPath = dimmingLayer.path
        let borderPath = borderLayer.path
        self.ovalFrame = ovalFrame

        // One transaction for the new paths and their animations, otherwise the new paths
        // reach the screen a frame before the animations that start from the old ones
        CATransaction.begin()
        updatePaths()
        if animated {
            addPathAnimation(to: dimmingLayer, from: dimmingPath)
            addPathAnimation(to: borderLayer, from: borderPath)
        }
        CATransaction.commit()
    }

    private func updatePaths() {
        CATransaction.begin()
        CATransaction.setDisableActions(true)

        let dimmingPath = UIBezierPath(rect: bounds)
        dimmingPath.append(UIBezierPath(ovalIn: ovalFrame))
        dimmingLayer.frame = bounds
        dimmingLayer.path = dimmingPath.cgPath

        borderLayer.frame = bounds
        borderLayer.path = UIBezierPath(ovalIn: ovalFrame).cgPath

        CATransaction.commit()
    }

    private func addPathAnimation(to shapeLayer: CAShapeLayer, from path: CGPath?) {
        let animation = CABasicAnimation(keyPath: "path")
        animation.fromValue = path
        animation.toValue = shapeLayer.path
        animation.duration = Self.ovalFrameAnimationDuration
        animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        shapeLayer.add(animation, forKey: "path")
    }

    required init?(coder: NSCoder) { nil }
}
