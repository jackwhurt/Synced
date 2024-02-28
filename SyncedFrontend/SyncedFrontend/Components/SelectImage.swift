import SwiftUI

struct SelectImage: View {
    @State private var showingImagePicker = false
    @State private var inputImage: UIImage?
    var onImageSelected: (UIImage) -> Void
    
    var body: some View {
        Button(action: {
            showingImagePicker = true
        }) {
            Image(systemName: "camera")
                .font(.largeTitle)
                .padding()
                .background(Color.black.opacity(0.5))
                .clipShape(Circle())
                .foregroundColor(.white)
        }
        .sheet(isPresented: $showingImagePicker, onDismiss: loadImage) {
            ImagePicker(image: self.$inputImage)
        }
    }
    
    private func loadImage() {
        guard let inputImage = inputImage else { return }
        onImageSelected(inputImage)
    }
}

struct ImagePicker: UIViewControllerRepresentable {
    @Environment(\.presentationMode) var presentationMode
    @Binding var image: UIImage?

    func makeUIViewController(context: Context) -> some UIViewController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: ImagePicker

        init(_ parent: ImagePicker) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.image = image
            }

            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}
