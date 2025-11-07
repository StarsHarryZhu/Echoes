//
//  UnitType.swift
//  Echoes
//
//  Created by Harry Zhu on 2025/11/7.
//

import Foundation
import SwiftUI

struct button_style: ButtonStyle {
    var size: CGFloat = 28
    var background_color = Color.blue
    var foreground_color = Color.white
    
    func makeBody(configuration: Self.Configuration) -> some View {
        configuration.label
            .font(.system(size: size))
            .padding(size * 0.6)
            .background(background_color)
            .foregroundColor(foreground_color)
            .clipShape(Circle())
            .shadow(radius: 5)
    }
}


struct text_style: ViewModifier {
    var size: CGFloat = 28
    var weight: Font.Weight = .bold
    
    func body(content: Content) -> some View {
        if UIFont(name: text_info.font, size: size) != nil {
            content
                .font(.custom(text_info.font, size: size).weight(weight))
        } else {
            content
                .font(.system(size: size, weight: weight))
        }
    }
}
