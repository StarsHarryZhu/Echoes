//
//  AppTabBar.swift
//  Echoes
//
//  自绘底部 tab 栏。
//
//  为什么不直接用系统 `TabView` 的 tab 栏：
//  需求要的是「左右两个归档 + 中间一颗**大圆**拍照键」。系统 tab 栏里放不下
//  一颗明显更大的圆钮 —— 用 `tabViewBottomAccessory` 试过，结果是圆钮和
//  tab 栏各自一片玻璃、互相叠着，看起来像两套控件。
//
//  自绘的代价与补偿：
//  - 丢掉系统 tab 栏的内置玻璃与选中动画 → 用 iOS 26+ 的 `glassEffect`
//    自己画，视觉上仍是液态玻璃；
//  - 丢掉系统 tab 栏的滚动边缘行为与安全区处理 → 底部内边距自己加，
//    并由调用方用 `safeAreaInset` 让内容避让；
//  - 丢掉系统 tab 栏的无障碍容器语义 → 自己补
//    `.accessibilityAddTraits(.isSelected)`。
//
//  换来的是：圆钮和 tab 栏在**同一个坐标系**里，可以真正"嵌"进去，
//  而不是悬浮在别人上面。

import SwiftUI

struct AppTabBar: View {

    @Binding var selection: RootSection
    /// 每次点「拍照」都递增，调用方据此触发一次拍照。
    /// 用计数器而不是闭包，是为了让这个视图保持纯粹的数据驱动。
    @Binding var captureRequest: Int

    /// 三个格子等宽，圆钮正好落在中间那格里。
    private let sideColumnWidth: CGFloat = 96
    private let shutterDiameter: CGFloat = 60
    private let barHeight: CGFloat = 62

    var body: some View {
        HStack(spacing: 0) {
            tabButton(.emotions)
                .frame(maxWidth: .infinity)

            shutter
                .frame(width: shutterDiameter)

            tabButton(.timeline)
                .frame(maxWidth: .infinity)
        }
        .frame(height: barHeight)
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 8)
        // 整条底栏做成一片玻璃 —— 圆钮自己是另一片，两片叠出层次。
        .glassEffect(.regular, in: Capsule(style: .continuous))
        .padding(.horizontal, 12)
        // 底部安全区（home indicator）自己让开：系统 TabView 走了之后没人管了。
        .padding(.bottom, 4)
    }

    // MARK: - 两侧的归档 tab

    private func tabButton(_ target: RootSection) -> some View {
        let isSelected = selection == target

        return Button {
            guard !isSelected else { return }
            selection = target
        } label: {
            VStack(spacing: 2) {
                Image(systemName: target.symbol)
                    .font(.system(size: 19, weight: isSelected ? .semibold : .regular))
                    .symbolVariant(isSelected ? .fill : .none)
                Text(target.title)
                    .appText(10, weight: isSelected ? .semibold : .regular)
            }
            .foregroundStyle(isSelected ? Color.primary : Color.secondary)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(target.title)
        .accessibilityHint(target.accessibilityHint)
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }

    // MARK: - 中间的圆钮

    private var shutter: some View {
        Button {
            captureRequest += 1
        } label: {
            Image(systemName: "camera.fill")
                .font(.system(size: shutterDiameter * 0.36, weight: .medium))
                .foregroundStyle(.primary)
                .frame(width: shutterDiameter, height: shutterDiameter)
                .glassEffect(.regular, in: Circle())
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(L10n.tabCapture)
        .accessibilityHint(L10n.shutterHint)
        .accessibilityAddTraits(.isButton)
    }
}

#Preview {
    @Previewable @State var selection: RootSection = .emotions
    @Previewable @State var request = 0

    return VStack {
        Text("Echoes").appText(24, weight: .bold)
        Spacer()
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color(.systemGroupedBackground))
    .safeAreaInset(edge: .bottom) {
        AppTabBar(selection: $selection, captureRequest: $request)
    }
}
