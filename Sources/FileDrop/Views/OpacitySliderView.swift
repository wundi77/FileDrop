import SwiftUI

/// A minimal custom slider for the strip's background opacity: a thin
/// horizontal line with an orange drag handle, rather than the native
/// macOS slider groove/thumb look.
struct OpacitySliderView: View {
    @Binding var value: Double

    static let range: ClosedRange<Double> = 0.01...1.0

    private let trackHeight: CGFloat = 2
    private let handleSize: CGFloat = 12

    var body: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            let fraction = (value - Self.range.lowerBound) / (Self.range.upperBound - Self.range.lowerBound)
            let handleX = fraction * width

            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.white.opacity(0.25))
                    .frame(height: trackHeight)

                Circle()
                    .fill(Color.orange)
                    .frame(width: handleSize, height: handleSize)
                    .offset(x: handleX - handleSize / 2)
            }
            .frame(maxHeight: .infinity)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { drag in
                        let fraction = min(max(drag.location.x / width, 0), 1)
                        value = Self.range.lowerBound + fraction * (Self.range.upperBound - Self.range.lowerBound)
                    }
            )
        }
        .frame(height: 16)
    }
}
