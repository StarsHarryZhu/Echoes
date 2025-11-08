//
//  LinkRow.swift
//  Echoes
//
//  Created by Harry Zhu on 2025/11/8.
//

import Foundation
import SwiftUI

struct LinkRow: View {
    let title: String
    let url: URL
    var body: some View {
        Link(destination: url) {
            HStack {
                Text(title).foregroundStyle(.primary)
                
                Spacer()
                Image(systemName: "arrow.up.right")
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 14)
            .background(Color.white.clipShape(RoundedRectangle(cornerRadius: 16)))
        }
        .buttonStyle(.plain)
    }
}
