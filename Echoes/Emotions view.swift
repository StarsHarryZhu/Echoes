//
//  Emotion view.swift
//  Echoes
//
//  Created by One on 11/7/25.
//


    import SwiftUI
    import UIKit

    struct EmotionsView: View {
        
        @State private var showCamera = false
        @State private var photos: [UIImage] = []
        
        // 三列网格
        let columns = [
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible())
        ]
        
        var body: some View {
            NavigationStack {
                VStack {
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 10) {
                            ForEach(photos, id: \.self) { photo in
                                Image(uiImage: photo)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(height: 100)
                                    .clipped()
                                    .cornerRadius(8)
                            }
                        }
                        .padding()
                    }
                    
                    Button(action: {
                        showCamera = true
                    }) {
                        Text("📸 Camera")
                            .font(.title2)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                            .padding(.horizontal)
                    }
                }
                .navigationTitle("Emotions")
                .sheet(isPresented: $showCamera) {
                    CameraView { image in
                        if let image = image {
                            photos.append(image)
                        }
                        showCamera = false
                    }
                }
            }
        }
    }

    // MARK: - Camera View (UIKit + UIViewControllerRepresentable)
    struct CameraView: UIViewControllerRepresentable {
        var completion: (UIImage?) -> Void
        
        func makeUIViewController(context: Context) -> UIImagePickerController {
            let picker = UIImagePickerController()
            picker.sourceType = .camera
            picker.cameraDevice = .front  // 前置摄像头
            picker.delegate = context.coordinator
            return picker
        }
        
        func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
        
        func makeCoordinator() -> Coordinator {
            Coordinator(parent: self)
        }
        
        class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
            let parent: CameraView
            
            init(parent: CameraView) {
                self.parent = parent
            }
            
            func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
                let image = info[.originalImage] as? UIImage
                parent.completion(image)
            }
            
            func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
                parent.completion(nil)
            }
        }
    }
#Preview {
    EmotionsView()
}
