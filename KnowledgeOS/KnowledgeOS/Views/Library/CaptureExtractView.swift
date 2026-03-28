import SwiftUI
import PhotosUI

struct CaptureExtractView: View {
    @EnvironmentObject var authService: AuthService
    @Environment(\.dismiss) private var dismiss

    let bookId: String

    @State private var step = 1 // 1: Capture, 2: Review OCR, 3: Tag & Save
    @State private var selectedImages: [UIImage] = []
    @State private var ocrResults: [(image: UIImage, text: String, pageNumber: String)] = []
    @State private var combinePages = false
    @State private var tags: [String] = []
    @State private var chapter = ""
    @State private var isProcessing = false
    @State private var isSaving = false
    @State private var showCamera = false
    @State private var showPhotoPicker = false
    @State private var photoPickerItems: [PhotosPickerItem] = []

    private let ocrService = OCRService()
    private let firestoreService = FirestoreService()
    private let storageService = StorageService()

    var body: some View {
        NavigationStack {
            Group {
                switch step {
                case 1: captureStep
                case 2: reviewStep
                case 3: tagStep
                default: EmptyView()
                }
            }
            .background(Theme.bg)
            .navigationTitle("Capture Extract")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    // MARK: - Step 1: Capture
    private var captureStep: some View {
        VStack(spacing: 20) {
            Spacer()

            Button { showCamera = true } label: {
                Label("Take Photo", systemImage: "camera")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Theme.surfaceElevated)
                    .foregroundColor(Theme.textPrimary)
                    .cornerRadius(Theme.cardRadius)
                    .overlay(RoundedRectangle(cornerRadius: Theme.cardRadius).stroke(Theme.border, lineWidth: 1))
            }

            PhotosPicker(
                selection: $photoPickerItems,
                maxSelectionCount: 10,
                matching: .images
            ) {
                Label("Choose from Photos", systemImage: "photo.on.rectangle")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Theme.surfaceElevated)
                    .foregroundColor(Theme.textPrimary)
                    .cornerRadius(Theme.cardRadius)
                    .overlay(RoundedRectangle(cornerRadius: Theme.cardRadius).stroke(Theme.border, lineWidth: 1))
            }
            .onChange(of: photoPickerItems) { items in
                Task { await loadPhotos(items) }
            }

            if !selectedImages.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(selectedImages.indices, id: \.self) { index in
                            ZStack(alignment: .topTrailing) {
                                Image(uiImage: selectedImages[index])
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 80, height: 100)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))

                                Button {
                                    selectedImages.remove(at: index)
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.white)
                                        .background(Circle().fill(.black.opacity(0.5)))
                                }
                                .offset(x: 4, y: -4)
                            }
                        }
                    }
                }

                if selectedImages.count > 1 {
                    Toggle("One passage across pages", isOn: $combinePages)
                        .font(.subheadline)
                        .foregroundColor(Theme.textSecondary)
                }

                Button {
                    extractText()
                } label: {
                    Text("Extract Text")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Theme.extract)
                        .foregroundColor(.white)
                        .cornerRadius(Theme.inputRadius)
                }
            }

            Spacer()
        }
        .padding()
        .fullScreenCover(isPresented: $showCamera) {
            CameraView { image in
                if let image { selectedImages.append(image) }
            }
        }
    }

    // MARK: - Step 2: Review
    private var reviewStep: some View {
        ScrollView {
            VStack(spacing: 16) {
                if isProcessing {
                    ProgressView("Extracting text...")
                        .frame(maxWidth: .infinity, minHeight: 200)
                } else {
                    ForEach(ocrResults.indices, id: \.self) { index in
                        VStack(alignment: .leading, spacing: 8) {
                            Image(uiImage: ocrResults[index].image)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(maxHeight: 150)
                                .clipShape(RoundedRectangle(cornerRadius: 8))

                            TextEditor(text: $ocrResults[index].text)
                                .font(.system(.body, design: .monospaced))
                                .frame(minHeight: 120)
                                .scrollContentBackground(.hidden)
                                .background(Theme.surface)
                                .cornerRadius(Theme.inputRadius)
                                .overlay(RoundedRectangle(cornerRadius: Theme.inputRadius).stroke(Theme.border, lineWidth: 1))

                            TextField("Page #", text: $ocrResults[index].pageNumber)
                                .keyboardType(.numberPad)
                                .padding()
                                .background(Theme.surface)
                                .cornerRadius(Theme.inputRadius)
                                .overlay(RoundedRectangle(cornerRadius: Theme.inputRadius).stroke(Theme.border, lineWidth: 1))
                        }
                        .padding()
                        .background(Theme.surfaceElevated)
                        .cornerRadius(Theme.cardRadius)
                    }

                    Button {
                        step = 3
                    } label: {
                        Text("Next")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Theme.accent)
                            .foregroundColor(.white)
                            .cornerRadius(Theme.inputRadius)
                    }
                }
            }
            .padding()
        }
    }

    // MARK: - Step 3: Tag & Save
    private var tagStep: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Preview
                ForEach(ocrResults.indices, id: \.self) { index in
                    VStack(alignment: .leading) {
                        Text(ocrResults[index].text)
                            .font(.system(.body, design: .monospaced))
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Theme.extractDim)
                            .overlay(
                                Rectangle().fill(Theme.extract).frame(width: 3),
                                alignment: .leading
                            )
                            .cornerRadius(Theme.inputRadius)
                    }
                }

                TextField("Chapter (optional)", text: $chapter)
                    .padding()
                    .background(Theme.surface)
                    .cornerRadius(Theme.inputRadius)
                    .overlay(RoundedRectangle(cornerRadius: Theme.inputRadius).stroke(Theme.border, lineWidth: 1))

                // Tags section (simplified — would use TagInputView component)
                Text("Tags")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(Theme.textSecondary)

                Button {
                    saveExtracts()
                } label: {
                    Text(isSaving ? "Saving..." : "Save Extract\(ocrResults.count > 1 ? "s" : "")")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Theme.extract)
                        .foregroundColor(.white)
                        .cornerRadius(Theme.inputRadius)
                }
                .disabled(isSaving)
            }
            .padding()
        }
    }

    // MARK: - Actions

    private func loadPhotos(_ items: [PhotosPickerItem]) async {
        selectedImages = []
        for item in items {
            if let data = try? await item.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                selectedImages.append(image)
            }
        }
    }

    private func extractText() {
        step = 2
        isProcessing = true
        Task {
            let results = await ocrService.recognizeTexts(from: selectedImages)
            ocrResults = results.map { (image: $0.image, text: $0.text ?? "", pageNumber: "") }

            if combinePages && ocrResults.count > 1 {
                let combinedText = ocrResults.map(\.text).joined(separator: "\n\n")
                ocrResults = [(image: ocrResults[0].image, text: combinedText, pageNumber: "")]
            }

            isProcessing = false
        }
    }

    private func saveExtracts() {
        guard let userId = authService.userId else { return }
        isSaving = true

        Task {
            for result in ocrResults {
                // Upload photo
                let path = try? await storageService.uploadPhoto(userId: userId, bookId: bookId, image: result.image)

                let extract = Extract(
                    bookId: bookId,
                    content: result.text,
                    pageNumber: Int(result.pageNumber),
                    chapter: chapter.isEmpty ? nil : chapter,
                    tags: tags,
                    sourcePhotoPaths: path.map { [$0] } ?? []
                )

                _ = try? await firestoreService.createExtract(userId: userId, extract: extract)
            }

            isSaving = false
            dismiss()
        }
    }
}

// MARK: - Camera View (UIKit wrapper)
struct CameraView: UIViewControllerRepresentable {
    let completion: (UIImage?) -> Void

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(completion: completion) }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let completion: (UIImage?) -> Void
        init(completion: @escaping (UIImage?) -> Void) { self.completion = completion }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            completion(info[.originalImage] as? UIImage)
            picker.dismiss(animated: true)
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            completion(nil)
            picker.dismiss(animated: true)
        }
    }
}
