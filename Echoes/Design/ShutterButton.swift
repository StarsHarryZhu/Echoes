//
//  ShutterButton.swift
//  Echoes
//

import SwiftUI

/// 底部中间的大圆拍照键。
///
/// 沿用重构前 `CameraButton` 的外观（`.ultraThinMaterial` 圆底 + 白色描边 + 阴影），
/// 但补上了它缺失的按下反馈：原实现的 `isPressed` 是个从未被写入的 `@State`，
/// 那个 `scaleEffect` 永远不会生效。
struct ShutterButton: View {

    var size: CGFloat = 70
    var isBusy: Bool = false
    var action: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(.ultraThinMaterial)
                    .overlay(
                        Circle().stroke(.white.opacity(0.25), lineWidth: 1)
                    )
                    .shadow(radius: 5, y: 2)

                if isBusy {
                    ProgressView()
                        .controlSize(.regular)
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
        .buttonStyle(.plain)
        .disabled(isBusy)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
        .accessibilityLabel("拍照")
        .accessibilityHint("打开前置相机，拍下当前的表情")
        .accessibilityAddTraits(.isButton)
    }
}

#Preview {
    ZStack {
        Color(.systemGroupedBackground)
        ShutterButton {}
    }
    .ignoresSafeArea()
}
