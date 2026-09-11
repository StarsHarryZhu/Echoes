//
//  TextStyle.swift
//  Echoes
//

import SwiftUI
import UIKit

/// 全应用统一字体。
///
/// 随包字体是 `SmileySans.otf`（PostScript 名 `SmileySans-Oblique`）。
/// 重构前的 `text_style` 每次渲染都会调一次 `UIFont(name:size:)` 去探测字体是否存在 ——
/// 字体注册是启动时的事，结果不会变，所以这里探测一次就好。
nonisolated enum AppFont {

    /// 字体是否成功注册。`Info.plist` 的 `UIAppFonts` 出问题时为 false，走系统字体兜底。
    static let isAvailable: Bool = {
        UIFont(name: AppInfo.fontName, size: 17) != nil
    }()

    static func font(size: CGFloat) -> Font {
        isAvailable ? .custom(AppInfo.fontName, size: size) : .system(size: size)
    }

    /// 给 `UINavigationBarAppearance` 用的 `UIFont`（SwiftUI 的 `Font` 用不了）。
    static func navigationFont(size: CGFloat, weight: UIFont.Weight) -> UIFont {
        if isAvailable, let custom = UIFont(name: AppInfo.fontName, size: size) {
            return custom
        }
        return .systemFont(ofSize: size, weight: weight)
    }
}

/// 应用字体的 `ViewModifier` 包装。
struct TextStyle: ViewModifier {
    var size: CGFloat = 28
    var weight: Font.Weight?

    func body(content: Content) -> some View {
        content.font(AppFont.font(size: size).weight(weight ?? .regular))
    }
}

extension View {
    /// 用应用字体渲染。
    func appText(_ size: CGFloat, weight: Font.Weight? = nil) -> some View {
        modifier(TextStyle(size: size, weight: weight))
    }
}
