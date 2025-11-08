//
//  AboutUs.swift
//  Echoes
//
//  Created by Harry Zhu on 2025/11/7.
//

import SwiftUI

struct AboutUsView: View {
    let onBack: () -> Void
    
    var body: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()
            
            VStack(spacing: 16) {
                TopBar(title: "About Us", onTap: onBack)
                
                ScrollView {
                    VStack(spacing: 20) {
                        SettingsCard(header: "App") {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Image(systemName: "app.gift.fill")//到时候改成我们的logo
                                        .font(.system(size: 28))
                                        .foregroundStyle(.black)
                                        .frame(width: 40, height: 40)
                                        .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 10))
                                    VStack(alignment: .leading, spacing: 6) {
                                        Text("Echoes").font(.headline)
                                        Text("Capture emotions. Keep memories.")
                                            .font(.subheadline)
                                            .foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                }
                                .navigationBarBackButtonHidden(true)
                                .navigationBarTitleDisplayMode(.inline)
                                Divider()
                                
                                HStack {
                                    Text("Version")
                                    Spacer()
                                    Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")
                                        .foregroundStyle(.secondary)
                                }
                                
                                Divider()
                                
                                HStack {
                                    Text("Build")
                                    Spacer()
                                    Text(Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "-")
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .padding(.vertical, 14)
                            .padding(.horizontal, 14)
                        }
                        
                        SettingsCard(header: "About Creaters") {
                            SettingNavRow(icon: "person", iconColor: .black, title: "Creaters") {
                               //这里要继续写页面
                            }
                            Divider()
                            }
                        }
                        
                        Spacer(minLength: 24)
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
                }
            }
        }
    }


//#Preview {
//    AboutUsView()
//}
