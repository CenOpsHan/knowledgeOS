import SwiftUI

struct TagPillView: View {
    let name: String
    var color: Color = Theme.accent
    var onRemove: (() -> Void)? = nil

    var body: some View {
        HStack(spacing: 4) {
            Text(name)
                .font(.caption2.weight(.medium))
                .foregroundColor(color)

            if let onRemove {
                Button(action: onRemove) {
                    Image(systemName: "xmark")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(color.opacity(0.7))
                }
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(color.opacity(0.15))
        .clipShape(Capsule())
    }
}
