//
//  load.swift
//  Echoes
//
//  Created by Harry Zhu on 11/20/25.
//

import Foundation
import UIKit
import Combine


final class local_IO: ObservableObject {
    static let local_io = local_IO()
    @Published var all: [emotion_memory] = []
    
    private var save_URL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("memories.json")
    }
    
    private init() {
        load()
    }

    func add_memory(_ memory: emotion_memory) {
        all.append(memory)
        save()
    }
    
    func items(for e: emotion) -> [emotion_memory] {
        all.filter { $0.emotion == e }
    }
    
    func save() {
        do {
            let data = try JSONEncoder().encode(all)
            try data.write(to: save_URL)
        } catch {
            print("Save error:", error)
        }
    }
    
    func load() {
        do {
            let data = try Data(contentsOf: save_URL)
            all = try JSONDecoder().decode([emotion_memory].self, from: data)
        } catch {
            all = []  // 第一次运行时会走到这里
        }
    }
}

func save_image(_ filename: String, _ image: UIImage) -> String? {
    guard let data = image.jpegData(compressionQuality: 1.0) else {
        return nil
    }

    let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        .appendingPathComponent(filename + ".jpg")

    do {
        try data.write(to: url)
        return url.path
    } catch {
//        alert("cannot save image")
        return nil
    }
}

