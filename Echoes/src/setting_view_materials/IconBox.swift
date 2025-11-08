//
//  IconBox.swift
//  Echoes
//
//  Created by Harry Zhu on 2025/11/7.
//

import Foundation
import SwiftUI

struct IconBox: View {
    let icon: String
    let color: Color
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(.systemGray6))
            Image(systemName: icon)
                .foregroundStyle(color)
        }
        .frame(width: 34, height: 34)
    }
}
