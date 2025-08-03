//
//  TypingAnimation.swift
//  doc-bot
//
//  Created by LUIZ FELIPE ALVES LIMA on 02/08/25.
//


import SwiftUI

final class TypingAnimation: ObservableObject {
    @Published var scales: [CGFloat] = [1.0, 1.0, 1.0]
    private var timer: Timer?

    func startAnimation() {
        // A more robust timer implementation for animation
        guard timer == nil else { return }
        timer = Timer.scheduledTimer(withTimeInterval: 0.6, repeats: true) { [weak self] _ in
            guard let self = self else { return }

            let initialScales: [CGFloat] = [0.8, 0.8, 0.8]
            self.scales = initialScales

            DispatchQueue.main.async {
                withAnimation(Animation.easeInOut(duration: 0.3).delay(0)) { self.scales[0] = 1.2 }
                withAnimation(Animation.easeInOut(duration: 0.3).delay(0.15)) {
                    self.scales[1] = 1.2
                }
                withAnimation(Animation.easeInOut(duration: 0.3).delay(0.3)) {
                    self.scales[2] = 1.2
                }
            }
        }
        timer?.fire()
    }

    deinit {
        timer?.invalidate()
    }
}
