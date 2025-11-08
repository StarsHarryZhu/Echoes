//
//  CreaterIntorView.swift
//  Echoes
//
//  Created by Harry Zhu on 2025/11/8.
//

import SwiftUI

struct CreatersIntroView: View {
    private let intro_size: CGFloat = 16
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()
            VStack(spacing: 16) {
                TopBar(title: "About Creaters", onTap: { dismiss() })

                ScrollView {
                    VStack(spacing: 20) {

                        SettingsCard(header: "Team") {
                            VStack(alignment: .leading, spacing: 14) {
                                MemberRow(icon: "person.crop.circle.fill", name: "Hui Jin", role: "Product & Design")
                                Divider()
                                MemberRow(icon: "person.crop.circle.fill", name: "Huanyi Zhu", role: "Product & Design")
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 14)
                        }

                        SettingsCard(header: "Our Story") {
                            Text(intro_text)
                                .modifier(text_style(
                                    size: intro_size,
                                ))
                                .foregroundStyle(.primary)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 14)
                        }

                        Spacer(minLength: 24)
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .navigationBarTitleDisplayMode(.inline)
    }
}


//#Preview {
//    CreaterIntorView()
//}
