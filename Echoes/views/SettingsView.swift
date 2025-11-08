//
//  SettingsView.swift
//  Echoes
//
//  Created by One on 11/7/25.
//

import SwiftUI

        // 占位的设置页（你可改成自己的内容/结构）
        struct SettingsView: View {
            @Environment(\.dismiss) private var dismiss

            var body: some View {
                NavigationStack {
                    List {
                        Section("General") {
                            Toggle("Smart Grouping", isOn: .constant(true))
                            Toggle("Analyze New Photos", isOn: .constant(false))
                        }
                        Section("Appearance") {
                            Picker("Title Size", selection: .constant(34)) {
                                Text("Large").tag(34)
                                Text("Medium").tag(28)
                                Text("Small").tag(22)
                            }
                        }
                    }
                    .navigationTitle("Settings")
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button("Done") { dismiss() }
                        }
                    }
                }
            }
        }



#Preview {
    SettingsView()
}
