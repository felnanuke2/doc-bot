//
//  CustomTextFieldStyle.swift
//  doc-bot
//
//  Created by LUIZ FELIPE ALVES LIMA on 02/08/25.
//


import SwiftUI

struct CustomTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color(.systemGray4), lineWidth: 0.5)
            )
    }
}
