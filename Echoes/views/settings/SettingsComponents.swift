//
//  SettingsComponents.swift
//  Echoes
//

import SwiftUI

/// 设置页的一张卡片：一个分区标题 + 一张圆角容器。
///
/// 重构前的 `SettingsCard` / `SettingRowBase` / `LinkRow` 都把背景写死成
/// `Color.white`，深色模式下会出现白卡片压黑字的问题。这里换成语义色。
struct SettingsCard<Content: View>: View {

    let header: String
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(header)
                .appText(13, weight: .semibold)
                .foregroundStyle(.secondary)
                .padding(.leading, 4)

            VStack(spacing: 0) {
                content
            }
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color(.secondarySystemGroupedBackground))
            )
        }
    }
}

/// 设置行统一的左图标。
struct SettingsIcon: View {

    let icon: String
    var color: Color = .accentColor

    var body: some View {
        Image(systemName: icon)
            .font(.system(size: 16, weight: .semibold))
            .foregroundStyle(color)
            .frame(width: 32, height: 32)
            .background(color.opacity(0.12), in: RoundedRectangle(cornerRadius: 9, style: .continuous))
    }
}

/// 设置行统一的排版。
struct SettingsRowBase<Right: View>: View {

    let icon: String
    var iconColor: Color = .accentColor
    let title: String
    @ViewBuilder var right: Right

    var body: some View {
        HStack(spacing: 12) {
            SettingsIcon(icon: icon, color: iconColor)
            Text(title)
                .appText(16)
                .foregroundStyle(.primary)
            Spacer(minLength: 8)
            right
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .contentShape(Rectangle())
    }
}

/// 可点进去的一行。
struct SettingsNavRow: View {

    let icon: String
    var iconColor: Color = .accentColor
    let title: String
    var detail: String?
    let action: () -> Void

    var body: some View {
        Button {
            action()
        } label: {
            SettingsRowBase(icon: icon, iconColor: iconColor, title: title) {
                HStack(spacing: 6) {
                    if let detail {
                        Text(detail)
                            .appText(15)
                            .foregroundStyle(.secondary)
                    }
                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.tertiary)
                }
            }
        }
        .buttonStyle(.plain)
    }
}

/// 带数值的一行（可点击，例如"清除缓存 12.3 MB"）。
struct SettingsValueRow: View {

    let icon: String
    var iconColor: Color = .accentColor
    let title: String
    let value: String
    var isBusy: Bool = false
    let action: () -> Void

    var body: some View {
        Button {
            action()
        } label: {
            SettingsRowBase(icon: icon, iconColor: iconColor, title: title) {
                HStack(spacing: 8) {
                    if isBusy {
                        ProgressView().controlSize(.small)
                    } else {
                        Text(value)
                            .appText(15)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .buttonStyle(.plain)
        .disabled(isBusy)
    }
}

/// 开关行。
struct SettingsToggleRow: View {

    let icon: String
    var iconColor: Color = .accentColor
    let title: String
    @Binding var isOn: Bool

    var body: some View {
        SettingsRowBase(icon: icon, iconColor: iconColor, title: title) {
            Toggle("", isOn: $isOn)
                .labelsHidden()
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(title)
    }
}

/// 分区之间的分隔线。
struct SettingsDivider: View {
    var body: some View {
        Divider().padding(.leading, 58)
    }
}
