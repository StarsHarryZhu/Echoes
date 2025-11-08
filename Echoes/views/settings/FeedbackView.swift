//
//  FeedbackView.swift
//  Echoes
//
//  Created by Harry Zhu on 2025/11/7.
//

import SwiftUI

// B) Feedback
struct FeedbackView: View {
    private let button_text_size: CGFloat = 16
    private let prompt_size: CGFloat = 18
    
    let onBack: () -> Void
    @State private var email: String = ""
    @State private var subject: String = ""
    @State private var content: String = ""
    @State private var includeDiagnostics = true
    @State private var submitted = false

    var body: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()

            VStack(spacing: 16) {
                TopBar(title: "Feedback", onTap: onBack)

                ScrollView {
                    VStack(spacing: 20) {

                        SettingsCard(header: "Contact") {
                            VStack(spacing: 12) {
                                TextField("Email (optional)", text: $email)
                                    .modifier(text_style(
                                        size: prompt_size,
                                    ))
                                    .textInputAutocapitalization(.never)
                                    .keyboardType(.emailAddress)
                                    .padding(12)
                                    .background(Color.white, in: RoundedRectangle(cornerRadius: 12))
                                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(.quaternaryLabel)))
                                    .padding(.horizontal, 14)
                                    .padding(.top, 14)

                                TextField("Subject", text: $subject)
                                    .modifier(text_style(
                                        size: prompt_size,
                                    ))
                                    .padding(12)
                                    .background(Color.white, in: RoundedRectangle(cornerRadius: 12))
                                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(.quaternaryLabel)))
                                    .padding(.horizontal, 14)
                                    .padding(.bottom, 14)
                            }
                        }
                        
                        .navigationBarBackButtonHidden(true)
                        .navigationBarTitleDisplayMode(.inline)
                        
                        SettingsCard(header: "Message") {
                            TextEditor(text: $content)
                                .frame(minHeight: 160)
                                .padding(12)
                                .background(Color.white, in: RoundedRectangle(cornerRadius: 12))
                                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(.quaternaryLabel)))
                                .padding(.horizontal, 14)
                                .padding(.vertical, 14)
                        }

                        SettingsCard(header: "Options") {
                            SettingToggleRow(icon: "wrench.and.screwdriver", iconColor: .black, title: "Include Diagnostics", isOn: $includeDiagnostics)
                        }

                        Button {
                            // TODO: 发送到你的服务端 / 邮件
                            submitted = true
                        } label: {
                            Text("Submit")
                                .modifier(text_style(
                                    size: button_text_size
                                ))
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(.black, in: RoundedRectangle(cornerRadius: 14))
                                .foregroundStyle(.white)
                        }
                        .padding(.horizontal, 16)
                        .alert("Thanks!", isPresented: $submitted) {
                            Button("OK", role: .cancel) { onBack() }
                        } message: {
                            Text("We’ve received your feedback.")
                        }

                        Spacer(minLength: 24)
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
                }
            }
        }
    }
}


//#Preview {
//    FeedbackView()
//}
