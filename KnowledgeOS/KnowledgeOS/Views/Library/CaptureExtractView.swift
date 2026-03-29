import SwiftUI
import PhotosUI

struct CaptureExtractView: View {
    @EnvironmentObject var authService: AuthService
    @Environment(\.dismiss) private var dismiss

    let bookId: String

    // Flow: 1=Capture, 2=Crop, 3=OCR/Select, 4=Review, 5=Tag & Save
    @State private var step = 1
    @State private var selectedImages: [UIImage] = []
    @State private var currentImageIndex = 0
    @State private var processedImages: [UIImage] = [] // after crop
    @State private var ocrBlocks: [[OCRTextBlock]] = [] // per image
    @State private var finalTexts: [(text: String, pageNumber: String, image: UIImage)] = []
    @State private var combinePages = false
    @State private var tags: [String] = []
    @State private var chapter = ""
    @State private var isProcessing = false
    @State private var isSaving = false
    @State private var showCamera = false
    @State private var photoPickerItems: [PhotosPickerItem] = []

    private let ocrService = OCRService()
    private let firestoreService = FirestoreService()
    private let storageService = StorageService()

    var body: some View {
        NavigationStack {
            Group {
                switch step {
                case 1: captureStep
                case 2: cropStep
                case 3: selectStep
                case 4: reviewStep
                case 5: tagStep
                default: EmptyView()
                }
            }
            .background(Color(.systemBackground))
            .navigationTitle(stepTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    private var stepTitle: String {
        switch step {
        case 1: return "Capture"
        case 2: return "Crop (\(currentImageIndex + 1)/\(selectedImages.count))"
        case 3: return "Select Text (\(currentImageIndex + 1)/\(processedImages.count))"
        case 4: return "Review"
        case 5: return "Tag & Save"
        default: return ""
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
                    .foregroundColor(Theme.textPrimary)
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: Theme.cardRadius))
                    .overlay(RoundedRectangle(cornerRadius: Theme.cardRadius).stroke(Theme.border, lineWidth: 0.5))
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
                    .foregroundColor(Theme.textPrimary)
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: Theme.cardRadius))
                    .overlay(RoundedRectangle(cornerRadius: Theme.cardRadius).stroke(Theme.border, lineWidth: 0.5))
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
                    currentImageIndex = 0
                    processedImages = []
                    step = 2
                } label: {
                    Text("Next: Crop")
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

    // MARK: - Step 2: Crop

    private var cropStep: some View {
        ImageCropView(
            image: selectedImages[currentImageIndex],
            onCrop: { cropped in
                processedImages.append(cropped)
                advanceCrop()
            },
            onSkip: {
                processedImages.append(selectedImages[currentImageIndex])
                advanceCrop()
            }
        )
    }

    private func advanceCrop() {
        if currentImageIndex + 1 < selectedImages.count {
            currentImageIndex += 1
        } else {
            // All images cropped, run OCR
            currentImageIndex = 0
            ocrBlocks = []
            step = 3
            runOCR()
        }
    }

    // MARK: - Step 3: Select Text

    private var selectStep: some View {
        Group {
            if isProcessing {
                VStack {
                    ProgressView("Extracting text...")
                    Text("Analyzing image \(currentImageIndex + 1) of \(processedImages.count)")
                        .font(.caption)
                        .foregroundColor(Theme.textSecondary)
                        .padding(.top, 8)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if currentImageIndex < ocrBlocks.count {
                TextSelectionView(
                    image: processedImages[currentImageIndex],
                    blocks: Binding(
                        get: { ocrBlocks[currentImageIndex] },
                        set: { ocrBlocks[currentImageIndex] = $0 }
                    ),
                    onConfirm: { advanceSelection() }
                )
            }
        }
    }

    private func advanceSelection() {
        let selected = ocrBlocks[currentImageIndex].filter(\.isSelected)
        let text = selected.map(\.text).joined(separator: "\n")
        finalTexts.append((text: text, pageNumber: "", image: processedImages[currentImageIndex]))

        if currentImageIndex + 1 < processedImages.count {
            currentImageIndex += 1
        } else {
            if combinePages && finalTexts.count > 1 {
                let combinedText = finalTexts.map(\.text).joined(separator: "\n\n")
                finalTexts = [(text: combinedText, pageNumber: "", image: finalTexts[0].image)]
            }
            step = 4
        }
    }

    private func runOCR() {
        isProcessing = true
        Task {
            for img in processedImages {
                do {
                    let blocks = try await ocrService.recognizeBlocks(from: img)
                    ocrBlocks.append(blocks)
                } catch {
                    ocrBlocks.append([])
                }
            }
            isProcessing = false
        }
    }

    // MARK: - Step 4: Review

    private var reviewStep: some View {
        ScrollView {
            VStack(spacing: 16) {
                ForEach(finalTexts.indices, id: \.self) { index in
                    VStack(alignment: .leading, spacing: 8) {
                        Image(uiImage: finalTexts[index].image)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxHeight: 120)
                            .clipShape(RoundedRectangle(cornerRadius: 8))

                        TextEditor(text: Binding(
                            get: { finalTexts[index].text },
                            set: { finalTexts[index].text = $0 }
                        ))
                        .font(.system(.body, design: .monospaced))
                        .frame(minHeight: 120)
                        .scrollContentBackground(.hidden)
                        .background(Color.white.opacity(0.4))
                        .cornerRadius(Theme.inputRadius)
                        .overlay(RoundedRectangle(cornerRadius: Theme.inputRadius).stroke(Theme.border, lineWidth: 0.5))

                        TextField("Page #", text: Binding(
                            get: { finalTexts[index].pageNumber },
                            set: { finalTexts[index].pageNumber = $0 }
                        ))
                        .keyboardType(.numberPad)
                        .padding()
                        .background(Color.white.opacity(0.5))
                        .cornerRadius(Theme.inputRadius)
                        .overlay(RoundedRectangle(cornerRadius: Theme.inputRadius).stroke(Theme.border, lineWidth: 0.5))
                    }
                    .padding()
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: Theme.cardRadius))
                }

                Button {
                    step = 5
                } label: {
                    Text("Next: Tag & Save")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Theme.accent)
                        .foregroundColor(.white)
                        .cornerRadius(Theme.inputRadius)
                }
            }
            .padding()
        }
    }

    // MARK: - Step 5: Tag & Save

    private var tagStep: some View {
        ScrollView {
            VStack(spacing: 16) {
                ForEach(finalTexts.indices, id: \.self) { index in
                    Text(finalTexts[index].text)
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

                TextField("Chapter (optional)", text: $chapter)
                    .padding()
                    .background(Color.white.opacity(0.5))
                    .cornerRadius(Theme.inputRadius)
                    .overlay(RoundedRectangle(cornerRadius: Theme.inputRadius).stroke(Theme.border, lineWidth: 0.5))

                if let userId = authService.userId {
                    TagInputView(selectedTags: $tags, userId: userId)
                }

                Button {
                    saveExtracts()
                } label: {
                    Text(isSaving ? "Saving..." : "Save Extract\(finalTexts.count > 1 ? "s" : "")")
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

    private func saveExtracts() {
        guard let userId = authService.userId else { return }
        isSaving = true

        Task {
            for result in finalTexts {
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
