//
//  SettingsView.swift
//  Echoes
//
//  Created by Harry Zhu on 2025/11/7.
//

import SwiftUI
import StoreKit // RateUsView 需要

// 二级页路由
private enum Subpage: Hashable {
    case about, feedback, rate
}

// MARK: - 全屏设置页（白底卡片布局）— 采用 push（右进左出）
struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss

    // 示例开关/选项（持久化）
    @AppStorage("grid")
        private var grid: Bool = settings.grid
    @AppStorage("gradienter")
        private var gradienter: Bool = settings.gradienter
    @AppStorage("record_mode")
        private var record_mode: Int = settings.record_mode
    @AppStorage("cache_size")
        private var cache_size: String = settings.cache_size

    // ✅ push 用的导航路径
    @State private var path = NavigationPath()

    var body: some View {
        NavigationStack(path: $path) {
            ZStack {
                Color(.systemBackground).ignoresSafeArea() // 白底

                VStack(spacing: 16) {
                    // 顶部导航（自定义，居中标题）
                    TopBar(title: "Settings", icon: "xmark") {
                        dismiss() // 关闭整个设置页（通常是从 fullScreenCover 弹出的）
                    }

                    ScrollView {
                        VStack(spacing: 20) {

                            // MARK: Capture
                            SettingsCard(header: "Capture") {
                                SettingToggleRow(icon: "square.grid.3x3", iconColor: .black, title: "Preview Grid", isOn: $grid)
                                Divider()
                                SettingToggleRow(icon: "line.diagonal", iconColor: .black, title: "Gradienter", isOn: $gradienter)
                            }

                            // MARK: 性能
                            SettingsCard(header: "性能") {
                                SettingNavRow(icon: "slider.horizontal.3", iconColor: .black, title: "性能设置") {
                                    // path.append(.performance) // 需要时再加
                                }
                            }

                            // MARK: 录制模式
                            SettingsCard(header: "录制模式") {
                                SettingNavRow(icon: "cube.box", iconColor: .black, title: "录制模式", detail: record_mode_text) {
                                    // path.append(.recordMode) // 需要时再加
                                }
                            }

                            // MARK: 通用
                            SettingsCard(header: "通用") {
                                SettingNavRow(icon: "person.badge.plus", iconColor: .black, title: "Personal Infomation") { }
                                Divider()
                                SettingValueRow(icon: "trash", iconColor: .red, title: "Clear Cache", value: cache_size) {
                                    // 执行清理动作后，更新 cacheSizeText
                                }
                            }

                            // MARK: About（→ push 子页）
                            SettingsCard(header: "About") {
                                SettingNavRow(icon: "info.circle", iconColor: .black, title: "About us") {
                                    path.append(Subpage.about)
                                }
                                Divider()
                                SettingNavRow(icon: "envelope.badge", iconColor: .black, title: "Feedback and Suggestions") {
                                    path.append(Subpage.feedback)
                                }
                                Divider()
                                SettingNavRow(icon: "star", iconColor: .black, title: "Go Score") {
                                    path.append(Subpage.rate)
                                }
                            }

                            Spacer(minLength: 24)
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 16)
                    }
                }
            }
            // ✅ 注册子页（右进左出动画）
            .navigationDestination(for: Subpage.self) { page in
                switch page {
                case .about:
                    AboutUsView(onBack: { path.removeLast() })
                case .feedback:
                    FeedbackView(onBack: { path.removeLast() })
                case .rate:
                    RateUsView(onBack: { path.removeLast() })
                }
            }
            // 使用自定义 TopBar，隐藏系统导航栏
            .toolbar(.hidden, for: .navigationBar)
        }
    }

    private var record_mode_text: String {
        switch record_mode {
        case 0: return "仅录制原片"
        default: return "自定义"
        }
    }
}


#Preview {
    SettingsView()
}
