//
//  EmotionListView.swift
//  Echoes
//
//  Created by Harry Zhu on 2025/11/9.
//

import SwiftUI

struct EmotionListView: View {
    var name_size: CGFloat = 18
    var date_size: CGFloat = 14
    let emotion: emotion
    let items: [emotion_memory]
    private let cols = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]
    
    var body: some View {
        ScrollView {

            HStack {
                Image(systemName: emotion.icon)
                Text(emotion.rawValue)
                    .modifier(text_style(
                        size: name_size,
                    ))
                    .bold()
                Spacer()
            }
            .foregroundStyle(.white)
            .padding()
            .background(
                LinearGradient(colors: [emotion.tint, emotion.tint.opacity(0.6)],
                               startPoint: .leading, endPoint: .trailing)
            )
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .padding(.horizontal)
            
            LazyVGrid(columns: cols, spacing: 12) {
                ForEach(items) { m in
                    NavigationLink(value: m) {
                        cover_image(of: m).resizable().scaledToFill()
                            .frame(height: 150).clipped()
                            .overlay(alignment: .bottomLeading) {
                                // 显示日期：yyMMdd（例：251108）
                                Text(formatted_date(m.date))
                                    .modifier(text_style(
                                        size: date_size
                                    ))
                                    .bold()
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 6)
                                    .background(.black.opacity(0.35), in: Capsule())
                                    .padding(8)
                            }
                            .cornerRadius(14)
                            .shadow(radius: 3, y: 2)
                    }
                }
            }
            .padding(.horizontal).padding(.top, 12)
        }

        
        .navigationTitle(emotion.rawValue)
        .navigationBarTitleDisplayMode(.inline)

        
        .toolbar {
            ToolbarItem(placement: .principal) {
                HStack(spacing: 8) {
                    Image(systemName: emotion.icon)
                        .font(.system(size: 20, weight: .semibold))
                    Text(emotion.rawValue)
                        .font(.custom(text_info.font, size: 26)).bold()
                    Spacer(minLength: 0)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
}



//#Preview {
//    EmotionListView()
//}
