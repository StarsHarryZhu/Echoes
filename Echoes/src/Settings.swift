//
//  Settings.swift
//  Echoes
//
//  Created by Harry Zhu on 2025/11/8.
//

import Foundation
import SwiftUI
import StoreKit


import Foundation

struct settings {
    static var grid: Bool {
        get { UserDefaults.standard.bool(forKey: "grid") }
        set { UserDefaults.standard.set(true, forKey: "grid") }
    }

    static var gradienter: Bool {
        get { UserDefaults.standard.bool(forKey: "gradienter") }
        set { UserDefaults.standard.set(true, forKey: "gradienter") }
    }
    
    static var record_mode: Int {
        get { UserDefaults.standard.integer(forKey: "record_mode") }
        set { UserDefaults.standard.set(0, forKey: "record_mode") }
    }

    static var cache_size: String {
        get { UserDefaults.standard.string(forKey: "cache_size") ?? "0.00MB"}
        set { UserDefaults.standard.set("0.00MB", forKey: "cache_size") }
    }
}

