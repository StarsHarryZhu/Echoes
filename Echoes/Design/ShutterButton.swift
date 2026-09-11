//
//  ShutterButton.swift
//  Echoes
//

import SwiftUI

/// 底部 tab 栏配件里的拍照控件。
///
/// 外观沿用重构前那颗大圆按钮（`.ultraThinMaterial` 圆底 + 白色描边 + 阴影），
/// 但补上了它缺失的按下反馈：原实现的 `isPressed` 是个从未被写入的 `@State`，
/// 那个 `scaleEffect` 永远不会生效。
///
/// 现在它被放进 `tabViewBottomAccessory` 提供的胶囊槽里，所以外层再包一层
/// 同形状的胶囊背景 —— 这样配件读起来是一个完整的控件，而不是一颗
/// 悬在半空、压住旁边底色的圆钮。
struct ShutterButton: View {

    var size: CGFloat = 52
    var isBusy: Bool = false
    /// 旁边的一行说明文字（例如「拍下此刻的表情」）。
    var caption: String? = nil
    var action: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                circle

                if let caption {
                    Text(caption)
                        .appText(14, weight: .medium)
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                }
            }
            .padding(.horizontal, caption == nil ? 8 : 16)
            .padding(.vertical, 6)
            .background(
                Capsule(style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        Capsule(style: .continuous)
                            .stroke(.white.opacity(0.18), lineWidth: 1)
                    )
            )
            .contentShape(Capsule(style: .continuous))
        }
        .buttonStyle(.plain)
        .disabled(isBusy)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(L10n.shutterLabel)
        .accessibilityHint(L10n.shutterHint)
        .accessibilityAddTraits(.isButton)
    }

    private var circle: some View {
        ZStack {
            Circle()
                .fill(.ultraThinMaterial)
                .overlay(Circle().stroke(.white.opacity(0.3), lineWidth: 1))
                .shadow(radius: 4, y: 2)

            if isBusy {
                ProgressView().controlSize(.small)
            } else {
                Image(systemName: "camera.fill")
                    .font(.system(size: size * 0.4))
                    .foregroundStyle(.primary)
            }
        }
        .frame(width: size, height: size)
        .scaleEffect(isPressed ? 0.9 : 1)
        .animation(.spring(response: 0.22, dampingFraction: 0.7), value: isPressed)
    }
}

#Preview {
    VStack(spacing: 20) {
        ShutterButton(caption: L10n.shutterHint) {}
        ShutterButton(isBusy: true, caption: L10n.saving) {}
        ShutterButton(isBusy: false, caption: nil) {}
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}
