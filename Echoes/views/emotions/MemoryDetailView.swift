//
//  MemoryDetailView.swift
//  Echoes
//
//  Created by Harry Zhu on 2025/11/9.
//

import SwiftUI

struct MemoryDetailView: View {
    var text_size: CGFloat = 14
    var date_size: CGFloat = 22
    let memory: emotion_memory
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(memory.emotion.tint.opacity(0.12))
                        .frame(height: 320)
                    cover_image(of: memory)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 300)
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .strokeBorder(.quaternary, lineWidth: 1)
                )
                .padding(.horizontal)

                Text(formattedDate(memory.date))                    .modifier(text_style(
                        size: date_size,
                    ))
                    .bold()
                HStack(spacing: 8) {
                    Image(systemName: memory.emotion.icon)
                        .foregroundStyle(memory.emotion.tint)
                    Text(memory.emotion.rawValue)
                        .modifier(text_style(
                            size: text_size,
                        ))
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.bottom, 24)
        }
        .navigationTitle("Detail")
        .navigationBarTitleDisplayMode(.inline)
    }
}

//#Preview {
//    MemoryDetailView()
//}
