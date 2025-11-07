//
//  ImageView.swift
//  Echoes
//
//  Created by Harry Zhu on 2025/11/7.
//

import SwiftUI
import UIKit


struct ImageView: View {
    var image: UIImage
    var body: some View {
        Image(uiImage: image)
    }
}

#Preview {
    let image = UIImage(systemName: "photo")!
    ImageView(image: image)
}
