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
            Section(L10n.feedbackSectionSubject) {
                TextField(L10n.feedbackSubjectPlaceholder, text: $subject)
            }

            Section(L10n.feedbackSectionMessage) {
                TextEditor(text: $content)
                    .frame(minHeight: 160)
            }

            Section {
                Toggle(L10n.feedbackDiagnostics, isOn: $includeDiagnostics)
            } footer: {
                Text(L10n.feedbackDiagnosticsFooter)
            }

            Section {
                Button {
                    submit()
                } label: {
                    Text(L10n.feedbackSend)
                        .appText(16, weight: .semibold)
                        .frame(maxWidth: .infinity)
                }
                .disabled(!canSubmit)

                Button(L10n.feedbackCopy) {
                    UIPasteboard.general.string = fullBody
                    resultMessage = L10n.feedbackCopied
                }
                .disabled(!canSubmit)
            } footer: {
                if let resultMessage {
                    Text(resultMessage)
                }
            }
        }
        .navigationTitle(L10n.feedbackTitle)
        .navigationBarTitleDisplayMode(.inline)
        .alert(
            L10n.feedbackTitle,
            isPresented: Binding(
                get: { resultMessage != nil },
                set: { if !$0 { resultMessage = nil } }
            )
        ) {
            Button(L10n.ok, role: .cancel) { resultMessage = nil }
        } message: {
            Text(resultMessage ?? "")
        }
    }

    private func submit() {
        var components = URLComponents()
        components.scheme = "mailto"
        components.path = AppInfo.feedbackEmail
        components.queryItems = [
            URLQueryItem(name: "subject", value: subject.isEmpty ? L10n.feedbackDefaultSubject : subject),
            URLQueryItem(name: "body", value: fullBody),
        ]

        guard let url = components.url else {
            copyToClipboard(reason: L10n.feedbackInvalidContent)
            return
        }

        // iOS 27 起 `canOpenURL` 已弃用，官方建议直接尝试打开并处理失败 ——
        // 这里照做：打不开就退回复制到剪贴板，不让用户白写一遍。
        UIApplication.shared.open(url, options: [:]) { opened in
            guard opened else {
                copyToClipboard(
                    reason: L10n.feedbackNoMailClient
                )
                return
            }
            resultMessage = L10n.feedbackMailOpened
        }
    }

    private func copyToClipboard(reason: String) {
        UIPasteboard.general.string = fullBody
        resultMessage = reason
    }
}
