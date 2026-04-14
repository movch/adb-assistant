import SwiftUI

struct CPUGraphView: View {
    let samples: [CPUPoint]

    private let maxPoints = 60

    var body: some View {
        GeometryReader { geo in
            let values = Array(samples.suffix(maxPoints).map(\.value))
            if values.isEmpty {
                Text("No samples")
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                let maxValue = max(values.max() ?? 0, 100)
                let minValue = 0.0
                let stepX = values.count > 1 ? geo.size.width / CGFloat(values.count - 1) : 0

                let path = Path { path in
                    for (index, value) in values.enumerated() {
                        let x = CGFloat(index) * stepX
                        let normalized = (value - minValue) / (maxValue - minValue)
                        let y = geo.size.height - (CGFloat(normalized) * geo.size.height)
                        if index == 0 {
                            path.move(to: CGPoint(x: x, y: y))
                        } else {
                            path.addLine(to: CGPoint(x: x, y: y))
                        }
                    }
                }

                path
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(colors: [.purple, .pink]),
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round)
                    )

                path
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [.purple.opacity(0.3), .clear]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .opacity(0.3)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.secondary.opacity(0.15))
        )
    }
}

struct MemoryGraphView: View {
    let samples: [MemoryPoint]

    private let maxPoints = 60

    var body: some View {
        GeometryReader { geo in
            let values = Array(samples.suffix(maxPoints).map(\.value))
            if values.isEmpty {
                Text("No samples")
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                let maxValue = max(values.max() ?? 0, 100)
                let minValue = 0.0
                let stepX = values.count > 1 ? geo.size.width / CGFloat(values.count - 1) : 0

                let path = Path { path in
                    for (index, value) in values.enumerated() {
                        let x = CGFloat(index) * stepX
                        let normalized = (value - minValue) / (maxValue - minValue)
                        let y = geo.size.height - (CGFloat(normalized) * geo.size.height)
                        if index == 0 {
                            path.move(to: CGPoint(x: x, y: y))
                        } else {
                            path.addLine(to: CGPoint(x: x, y: y))
                        }
                    }
                }

                path
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(colors: [.teal, .green]),
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round)
                    )

                path
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [.teal.opacity(0.3), .clear]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .opacity(0.3)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.secondary.opacity(0.15))
        )
    }
}
