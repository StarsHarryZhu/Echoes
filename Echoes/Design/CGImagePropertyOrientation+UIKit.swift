//
//  CGImagePropertyOrientation+UIKit.swift
//  Echoes
//

import ImageIO
import UIKit

extension CGImagePropertyOrientation {

    /// 把 `UIImage.Orientation` 转成 Vision / ImageIO 用的方向。
    ///
    /// 前置相机拍出的照片像素数据本身是横的，靠 `imageOrientation` 标记"该怎么转"。
    /// Vision 拿到原图时必须同时拿到这个方向，否则人脸框会错位甚至找不到人脸。
    init(_ uiOrientation: UIImage.Orientation) {
        switch uiOrientation {
        case .up: self = .up
        case .down: self = .down
        case .left: self = .left
        case .right: self = .right
        case .upMirrored: self = .upMirrored
        case .downMirrored: self = .downMirrored
        case .leftMirrored: self = .leftMirrored
        case .rightMirrored: self = .rightMirrored
        @unknown default: self = .up
        }
    }
}
