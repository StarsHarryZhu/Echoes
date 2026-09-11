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
    private let shutterDiameter: CGFloat = 60
    private let barHeight: CGFloat = 62

    var body: some View {
        // 结构上刻意保持简单：底栏本身留在布局流里，**只让底衬往下延伸**。
        //
        // 之前用 GeometryReader + `ignoresSafeArea` 让整条栏也下沉，结果栏被推到
        // 屏幕边缘之外、图标文字都被切掉。根本原因是不该让"栏"离开布局流 ——
        // 需要盖住 home indicator 的只是它背后的那层底色。
        bar
            .padding(.horizontal, 12)
            .padding(.bottom, 6)
            .background(alignment: .bottom) { backdrop }
    }

    /// 栏后面的底衬：下半段与页面同色（不透明），向上渐隐到透明，
    /// 让内容从栏后干净地淡出，同时盖住栏下方的安全区。
    private var backdrop: some View {
        LinearGradient(
            stops: [
                .init(color: Color(.systemGroupedBackground).opacity(0), location: 0),
                .init(color: Color(.systemGroupedBackground), location: 0.35),
                .init(color: Color(.systemGroupedBackground), location: 1),
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .frame(height: barHeight + 44)
        // 往下伸出布局边界，铺满 home indicator 那条安全区。
        .ignoresSafeArea(edges: .bottom)
        .allowsHitTesting(false)
    }

    private var bar: some View {
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
        .background(
            Capsule(style: .continuous)
                .fill(.ultraThinMaterial)
                .glassEffect(.regular, in: Capsule(style: .continuous))
        )
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
