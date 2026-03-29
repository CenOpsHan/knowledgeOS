import SwiftUI

struct TextSelectionView: View {
    let image: UIImage
    @Binding var blocks: [OCRTextBlock]
    let onConfirm: () -> Void

    @State private var showOverlay = true

    var selectedCount: Int { blocks.filter(\.isSelected).count }

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text("\(selectedCount)/\(blocks.count) lines selected")
                    .font(.subheadline)
                    .foregroundColor(Theme.textSecondary)
                Spacer()
                Button(allSelected ? "Deselect All" : "Select All") {
                    let newValue = !allSelected
                    for i in blocks.indices { blocks[i].isSelected = newValue }
                }
                .font(.subheadline.weight(.medium))
                .foregroundColor(Theme.accent)
            }

            // Image with tappable text overlays
            GeometryReader { geo in
                let imgSize = fittedSize(in: geo.size)
                let offset = CGPoint(
                    x: (geo.size.width - imgSize.width) / 2,
                    y: (geo.size.height - imgSize.height) / 2
                )

                ZStack(alignment: .topLeading) {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: imgSize.width, height: imgSize.height)
                        .position(x: geo.size.width / 2, y: geo.size.height / 2)

                    if showOverlay {
                        ForEach(blocks.indices, id: \.self) { index in
                            let block = blocks[index]
                            let rect = convertToViewRect(block.boundingBox, imageSize: imgSize, offset: offset)

                            Button {
                                blocks[index].isSelected.toggle()
                            } label: {
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(block.isSelected
                                          ? Theme.accent.opacity(0.2)
                                          : Color.gray.opacity(0.1))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 3)
                                            .stroke(block.isSelected ? Theme.accent : Color.gray.opacity(0.3), lineWidth: 1.5)
                                    )
                            }
                            .frame(width: rect.width, height: rect.height)
                            .position(x: rect.midX, y: rect.midY)
                        }
                    }
                }
            }

            // Toggle overlay visibility
            Toggle("Show text highlights", isOn: $showOverlay)
                .font(.subheadline)
                .foregroundColor(Theme.textSecondary)

            // Selected text preview
            if selectedCount > 0 {
                ScrollView {
                    Text(selectedText)
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(Theme.textPrimary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(8)
                }
                .frame(maxHeight: 100)
                .background(Theme.extractDim)
                .overlay(
                    Rectangle().fill(Theme.extract).frame(width: 3),
                    alignment: .leading
                )
                .cornerRadius(Theme.inputRadius)
            }

            Button {
                onConfirm()
            } label: {
                Text("Use Selected Text")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(selectedCount > 0 ? Theme.accent : Theme.accent.opacity(0.5))
                    .foregroundColor(.white)
                    .cornerRadius(Theme.inputRadius)
            }
            .disabled(selectedCount == 0)
        }
        .padding()
    }

    var selectedText: String {
        blocks.filter(\.isSelected).map(\.text).joined(separator: "\n")
    }

    private var allSelected: Bool {
        blocks.allSatisfy(\.isSelected)
    }

    private func fittedSize(in size: CGSize) -> CGSize {
        let imgAspect = image.size.width / image.size.height
        let viewAspect = size.width / size.height
        if imgAspect > viewAspect {
            return CGSize(width: size.width, height: size.width / imgAspect)
        } else {
            return CGSize(width: size.height * imgAspect, height: size.height)
        }
    }

    /// Convert Vision bounding box (normalized, bottom-left origin) to view coordinates
    private func convertToViewRect(_ bbox: CGRect, imageSize: CGSize, offset: CGPoint) -> CGRect {
        let x = offset.x + bbox.origin.x * imageSize.width
        // Vision y is from bottom, SwiftUI y is from top
        let y = offset.y + (1 - bbox.origin.y - bbox.height) * imageSize.height
        let w = bbox.width * imageSize.width
        let h = bbox.height * imageSize.height
        return CGRect(x: x, y: y, width: w, height: h)
    }
}
