//
//  CameraButton.swift
//  Echoes
//

import SwiftUI

/// 底部中间悬浮的圆形拍照键。
///
/// 外观**逐字还原**重构前 `Button.swift` 里那个 `button` 结构体
/// （`size` 默认 60、实际调用传 70，`.ultraThinMaterial` 圆底、
/// 白色描边、`shadow(radius: 5)`、按下缩放到 0.9）。
///
/// 与原始实现的唯一差别：原版的 `isPressed` 是个从未被写入的 `@State`，
/// 那个 `scaleEffect` 永远不会生效；这里用 `DragGesture` 真的驱动它，
/// 另外加了 `isBusy` 状态供识别期间显示进度。
struct CameraButton: View {

    var image: String = "camera.fill"
    var size: CGFloat = 70
    var foregroundColor: Color = .black
    var isBusy: Bool = false
    var action: () -> Void = {}

    @State private var isPressed = false

    var body: some View {
        Button(action: { action() }) {
            ZStack {
                if isBusy {
                    ProgressView()
                        .controlSize(.regular)
                        .frame(width: size, height: size)
                } else {
                    Image(systemName: image)
                        .font(.system(size: size * 0.4))
                        .frame(width: size, height: size)
                        .foregroundColor(foregroundColor)
                }
            }
            .background(.ultraThinMaterial)
            .clipShape(Circle())
            .shadow(radius: 5)
            .overlay(
                Circle()
                    .stroke(.white.opacity(0.25), lineWidth: 1)
            )
            .scaleEffect(isPressed ? 0.9 : 1.0)
        }
        .buttonStyle(.plain)
        .disabled(isBusy)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
        .accessibilityLabel(L10n.shutterLabel)
        .accessibilityHint(L10n.shutterHint)
    }
}

#Preview {
    ZStack {
        Color(.systemGroupedBackground)
        CameraButton {}
    }
    .ignoresSafeArea()
}
