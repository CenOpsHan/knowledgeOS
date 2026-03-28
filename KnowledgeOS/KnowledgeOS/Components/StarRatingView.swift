import SwiftUI

struct StarRatingView: View {
    let rating: Int
    var onChange: ((Int) -> Void)? = nil
    var size: CGFloat = 18

    var body: some View {
        HStack(spacing: 4) {
            ForEach(1...5, id: \.self) { i in
                Button {
                    onChange?(rating == i ? 0 : i)
                } label: {
                    Image(systemName: i <= rating ? "star.fill" : "star")
                        .font(.system(size: size))
                        .foregroundColor(i <= rating ? Theme.star : Theme.textTertiary)
                }
                .disabled(onChange == nil)
            }
        }
    }
}
