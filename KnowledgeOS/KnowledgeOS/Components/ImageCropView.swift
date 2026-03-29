import SwiftUI

struct ImageCropView: View {
    let image: UIImage
    let onCrop: (UIImage) -> Void
    let onSkip: () -> Void

    @State private var cropRect: CGRect = .zero
    @State private var isDragging = false
    @State private var dragStart: CGPoint = .zero
    @State private var imageFrame: CGSize = .zero

    var body: some View {
        VStack(spacing: 16) {
            Text("Drag to select the region you want to extract")
                .font(.subheadline)
                .foregroundColor(Theme.textSecondary)

            GeometryReader { geo in
                let fitted = fittedImageRect(in: geo.size)

                ZStack {
                    // Image
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: fitted.width, height: fitted.height)
                        .position(x: geo.size.width / 2, y: geo.size.height / 2)

                    // Dimming overlay outside crop
                    if cropRect != .zero {
                        CropOverlay(cropRect: cropRect, bounds: fitted, center: CGPoint(x: geo.size.width / 2, y: geo.size.height / 2))
                    }

                    // Crop border
                    if cropRect != .zero {
                        let offset = CGPoint(
                            x: (geo.size.width - fitted.width) / 2,
                            y: (geo.size.height - fitted.height) / 2
                        )
                        Rectangle()
                            .stroke(Theme.accent, lineWidth: 2)
                            .background(Color.white.opacity(0.05))
                            .frame(width: cropRect.width, height: cropRect.height)
                            .position(
                                x: offset.x + cropRect.midX,
                                y: offset.y + cropRect.midY
                            )

                        // Corner handles
                        ForEach(corners(of: cropRect, offset: offset), id: \.0) { corner in
                            Circle()
                                .fill(Theme.accent)
                                .frame(width: 16, height: 16)
                                .position(x: corner.1, y: corner.2)
                        }
                    }
                }
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 5)
                        .onChanged { value in
                            let offset = CGPoint(
                                x: (geo.size.width - fitted.width) / 2,
                                y: (geo.size.height - fitted.height) / 2
                            )
                            let localStart = CGPoint(
                                x: max(0, min(value.startLocation.x - offset.x, fitted.width)),
                                y: max(0, min(value.startLocation.y - offset.y, fitted.height))
                            )
                            let localEnd = CGPoint(
                                x: max(0, min(value.location.x - offset.x, fitted.width)),
                                y: max(0, min(value.location.y - offset.y, fitted.height))
                            )
                            let minX = min(localStart.x, localEnd.x)
                            let minY = min(localStart.y, localEnd.y)
                            let maxX = max(localStart.x, localEnd.x)
                            let maxY = max(localStart.y, localEnd.y)
                            cropRect = CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
                            imageFrame = fitted
                        }
                )
            }

            HStack(spacing: 16) {
                Button {
                    onSkip()
                } label: {
                    Text("Use Full Image")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .foregroundColor(Theme.textSecondary)
                        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: Theme.inputRadius))
                }

                Button {
                    let cropped = cropImage()
                    onCrop(cropped)
                } label: {
                    Text("Crop & Extract")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(cropRect == .zero ? Theme.accent.opacity(0.5) : Theme.accent)
                        .foregroundColor(.white)
                        .cornerRadius(Theme.inputRadius)
                }
                .disabled(cropRect == .zero)
            }
        }
        .padding()
    }

    private func fittedImageRect(in size: CGSize) -> CGSize {
        let imgAspect = image.size.width / image.size.height
        let viewAspect = size.width / size.height
        if imgAspect > viewAspect {
            let w = size.width
            return CGSize(width: w, height: w / imgAspect)
        } else {
            let h = size.height
            return CGSize(width: h * imgAspect, height: h)
        }
    }

    private func cropImage() -> UIImage {
        guard cropRect != .zero, imageFrame != .zero else { return image }

        let scaleX = image.size.width / imageFrame.width
        let scaleY = image.size.height / imageFrame.height

        let pixelRect = CGRect(
            x: cropRect.origin.x * scaleX,
            y: cropRect.origin.y * scaleY,
            width: cropRect.width * scaleX,
            height: cropRect.height * scaleY
        )

        guard let cgImage = image.cgImage?.cropping(to: pixelRect) else { return image }
        return UIImage(cgImage: cgImage, scale: image.scale, orientation: image.imageOrientation)
    }

    private func corners(of rect: CGRect, offset: CGPoint) -> [(String, CGFloat, CGFloat)] {
        [
            ("tl", offset.x + rect.minX, offset.y + rect.minY),
            ("tr", offset.x + rect.maxX, offset.y + rect.minY),
            ("bl", offset.x + rect.minX, offset.y + rect.maxY),
            ("br", offset.x + rect.maxX, offset.y + rect.maxY),
        ]
    }
}

// Dimming overlay that darkens everything outside the crop rect
private struct CropOverlay: View {
    let cropRect: CGRect
    let bounds: CGSize
    let center: CGPoint

    var body: some View {
        let offset = CGPoint(
            x: center.x - bounds.width / 2,
            y: center.y - bounds.height / 2
        )
        Canvas { context, size in
            // Fill entire image area with dim
            var dimPath = Path()
            dimPath.addRect(CGRect(x: offset.x, y: offset.y, width: bounds.width, height: bounds.height))
            context.fill(dimPath, with: .color(.black.opacity(0.4)))

            // Cut out the crop rect
            var clearPath = Path()
            clearPath.addRect(CGRect(
                x: offset.x + cropRect.origin.x,
                y: offset.y + cropRect.origin.y,
                width: cropRect.width,
                height: cropRect.height
            ))
            context.blendMode = .destinationOut
            context.fill(clearPath, with: .color(.white))
        }
        .allowsHitTesting(false)
    }
}
