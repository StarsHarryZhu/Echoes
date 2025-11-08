//
//  RateUsView.swift
//  Echoes
//
//  Created by Harry Zhu on 2025/11/7.
//

import SwiftUI
import StoreKit

struct RateUsView: View {
    private let button_text_size: CGFloat = 18
    private let text_size: CGFloat = 16
    
    let onBack: () -> Void
    @Environment(\.requestReview) private var requestReview // iOS 16+

    // 如果用跳转 App Store，请把你的 appID 换上
    private let appID = "0000000000" // ← 替换为你的 App Store ID

    var body: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()

            VStack(spacing: 16) {
                TopBar(title: "Rate Us", onTap: onBack)

                VStack(spacing: 20) {
                    SettingsCard(header: "Support Echoes") {
                        VStack(alignment: .leading, spacing: 12) {
                            Text(rate_us_text)
                                .modifier(text_style(
                                    size: text_size
                                ))
                                .padding(.horizontal, 14)
                                .padding(.top, 14)
                            
                .navigationBarBackButtonHidden(true)
                .navigationBarTitleDisplayMode(.inline)
                            

                            HStack(spacing: 12) {
                                Button {
                                    // 方式 1：系统内评分弹窗（频率受系统控制）
                                    requestReview()
                                } label: {
                                    Text("Rate In-App")
                                        .modifier(text_style(
                                            size: button_text_size,
                                        ))
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 12)
                                        .background(Color.black, in: RoundedRectangle(cornerRadius: 12))
                                        .foregroundStyle(.white)
                                }

                                Button {
                                    // 方式 2：跳转到 App Store
                                    if let url = URL(string: "https://apps.apple.com/app/id\(appID)?action=write-review") {
                                        UIApplication.shared.open(url)
                                    }
                                } label: {
                                    Text("Open App Store")
                                        .modifier(text_style(
                                            size: button_text_size - 1
                                        ))
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 12)
                                        .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 12))
                                        .foregroundStyle(.primary)
                                }
                            }
                            .padding(.horizontal, 14)
                            .padding(.bottom, 14)
                        }
                    }
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            }
        }
    }
}


//#Preview {
//    RateUsView()
//}
