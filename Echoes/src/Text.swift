//
//  UnitType.swift
//  Echoes
//
//  Created by Harry Zhu on 2025/11/7.
//

import Foundation
import SwiftUI


struct text_style: ViewModifier {
    var size: CGFloat = 28

    
    func body(content: Content) -> some View {
        if UIFont(name: text_info.font, size: size) != nil {
            content
                .font(.custom(text_info.font, size: size))

        } else {
            content
                .font(.system(size: size))
        }
    }
}
