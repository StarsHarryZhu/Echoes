//
//  RateUsView.swift
//  Echoes
//

import StoreKit
import SwiftUI
import UIKit

/// 评分页。
///
/// 重构前的 App Store ID 是写死在视图里的 `"0000000000"` 占位符，
/// 点「Open App Store」会打开一个不存在的页面。现在统一取 `AppInfo.appStoreID`，
/// 并且当它还是占位符时**直接不显示这个按钮**，而不是给用户一个坏链接。
struct RateUsView: View {

    @Environment(\.requestReview) private var requestReview

    private var hasRealAppStoreID: Bool {
        AppInfo.appStoreID != "0000000000" && !AppInfo.appStoreID.isEmpty
    }

    private var writeReviewURL: URL? {
        URL(string: "https://apps.apple.com/app/id\(AppInfo.appStoreID)?action=write-review")
    }

    var body: some View {
        List {
            Section {
                VStack(spacing: 12) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 40))
                        .foregroundStyle(.yellow)
                    Text(AppCopy.rateUs)
                        .appText(15)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
            }

            Section {
                Button {
                    // 系统评分弹窗。展示时机由系统决定，不保证每次都出现。
                    requestReview()
                } label: {
                    Text("在应用内评分")
                        .appText(16, weight: .semibold)
                        .frame(maxWidth: .infinity)
                }
            } footer: {
                Text("系统会自行决定是否弹出评分框，没有弹出是正常的。")
            }

            if hasRealAppStoreID, let url = writeReviewURL {
                Section {
                    Link(destination: url) {
                        Text("前往 App Store 评价")
                            .appText(16, weight: .semibold)
                            .frame(maxWidth: .infinity)
                    }
                }
            }
        }
        .navigationTitle("给我们评分")
        .navigationBarTitleDisplayMode(.inline)
    }
}
