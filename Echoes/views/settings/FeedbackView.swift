//
//  FeedbackView.swift
//  Echoes
//

import SwiftUI
import UIKit

/// 反馈页。
///
/// 重构前「Submit」按钮是空的：`submitted = true` 弹一句"Thanks!"，
/// 但内容根本没发出去。这里做成**真的能送出**：优先打开邮件客户端，
/// 没有配邮件账号时退回复制到剪贴板，两种结果都给明确提示。
struct FeedbackView: View {

    @State private var subject = ""
    @State private var content = ""
    @State private var includeDiagnostics = true
    @State private var resultMessage: String?

    private var diagnostics: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "?"
        return """
        ---
        App: \(AppInfo.name) \(version) (\(build))
        Device: \(UIDevice.current.model)
        System: \(UIDevice.current.systemName) \(UIDevice.current.systemVersion)
        """
    }

    private var fullBody: String {
        includeDiagnostics ? content + "\n\n" + diagnostics : content
    }

    private var canSubmit: Bool {
        !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        Form {
            Section("主题") {
                TextField("一句话概括", text: $subject)
            }

            Section("详细描述") {
                TextEditor(text: $content)
                    .frame(minHeight: 160)
            }

            Section {
                Toggle("附加设备与版本信息", isOn: $includeDiagnostics)
            } footer: {
                Text("有助于我们定位问题。不包含任何照片或表情记录。")
            }

            Section {
                Button {
                    submit()
                } label: {
                    Text("发送反馈")
                        .appText(16, weight: .semibold)
                        .frame(maxWidth: .infinity)
                }
                .disabled(!canSubmit)

                Button("复制反馈内容") {
                    UIPasteboard.general.string = fullBody
                    resultMessage = "已复制到剪贴板。"
                }
                .disabled(!canSubmit)
            } footer: {
                if let resultMessage {
                    Text(resultMessage)
                }
            }
        }
        .navigationTitle("反馈与建议")
        .navigationBarTitleDisplayMode(.inline)
        .alert(
            "反馈",
            isPresented: Binding(
                get: { resultMessage != nil },
                set: { if !$0 { resultMessage = nil } }
            )
        ) {
            Button("好", role: .cancel) { resultMessage = nil }
        } message: {
            Text(resultMessage ?? "")
        }
    }

    private func submit() {
        var components = URLComponents()
        components.scheme = "mailto"
        components.path = AppInfo.feedbackEmail
        components.queryItems = [
            URLQueryItem(name: "subject", value: subject.isEmpty ? "Echoes 反馈" : subject),
            URLQueryItem(name: "body", value: fullBody),
        ]

        guard let url = components.url else {
            copyToClipboard(reason: "反馈内容里有非法字符，已复制到剪贴板。")
            return
        }

        // iOS 27 起 `canOpenURL` 已弃用，官方建议直接尝试打开并处理失败 ——
        // 这里照做：打不开就退回复制到剪贴板，不让用户白写一遍。
        UIApplication.shared.open(url, options: [:]) { opened in
            guard opened else {
                copyToClipboard(
                    reason: "这台设备没有配置邮件客户端，内容已复制到剪贴板，可以粘贴到任意渠道发给我们。"
                )
                return
            }
            resultMessage = "已打开邮件客户端，点发送就完成了。"
        }
    }

    private func copyToClipboard(reason: String) {
        UIPasteboard.general.string = fullBody
        resultMessage = reason
    }
}
