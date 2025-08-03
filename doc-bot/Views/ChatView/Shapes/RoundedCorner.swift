//
//  RoundedCorner.swift
//  doc-bot
//
//  Created by LUIZ FELIPE ALVES LIMA on 02/08/25.
//


import SwiftUI

/// A shape that allows rounding of specific corners, creating a gentler message bubble appearance.
struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect, byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}
