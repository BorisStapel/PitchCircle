import SwiftUI

struct CentsArcGauge: View {
    let cents: Double?

    private let minCents: Double = -50
    private let maxCents: Double = 50

    var body: some View {
        VStack(spacing: 6) {
            GeometryReader { geometry in
                let size = geometry.size
                let center = CGPoint(x: size.width / 2, y: size.height - 8)
                let radius = min(size.width / 2 - 10, size.height - 18)

                ZStack {
                    Path { path in
                        path.addArc(
                            center: center,
                            radius: radius,
                            startAngle: .degrees(180),
                            endAngle: .degrees(0),
                            clockwise: false
                        )
                    }
                    .stroke(Color.inactiveStroke, style: StrokeStyle(lineWidth: 7, lineCap: .round))

                    ForEach([-50.0, -25.0, 0.0, 25.0, 50.0], id: \.self) { tick in
                        let angle = gaugeAngle(for: tick)
                        let outerPoint = point(on: center, radius: radius + (tick == 0 ? 1 : 0), angle: angle)
                        let innerPoint = point(on: center, radius: radius - (tick == 0 ? 13 : 9), angle: angle)

                        Path { path in
                            path.move(to: innerPoint)
                            path.addLine(to: outerPoint)
                        }
                        .stroke(
                            tick == 0 ? Color.notePrimary : Color.inactiveText.opacity(0.55),
                            style: StrokeStyle(lineWidth: tick == 0 ? 2.5 : 1.5, lineCap: .round)
                        )
                    }

                    Path { path in
                        path.move(to: center)
                        path.addLine(to: point(on: center, radius: radius - 16, angle: needleAngle))
                    }
                    .stroke(gaugeColor, style: StrokeStyle(lineWidth: 3, lineCap: .round))

                    Circle()
                        .fill(gaugeColor)
                        .frame(width: 10, height: 10)
                        .position(point(on: center, radius: radius - 16, angle: needleAngle))

                    Circle()
                        .fill(Color.notePrimary)
                        .frame(width: 10, height: 10)
                        .position(center)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .frame(width: 160, height: 75)

            Text(centsLabel)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(gaugeColor)
                .contentTransition(.numericText())
        }
        .animation(.easeOut(duration: 0.14), value: clampedCents)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Tuning")
        .accessibilityValue(centsAccessibilityLabel)
    }

    private var clampedCents: Double {
        min(max(cents ?? 0, minCents), maxCents)
    }

    private var needleAngle: Double {
        270 + (clampedCents / maxCents) * 90
    }

    private var gaugeColor: Color {
        let magnitude = abs(cents ?? 0)

        switch magnitude {
        case 0..<5:
            return .micActive
        case 5..<15:
            return .centsWarning
        default:
            return .centsDanger
        }
    }

    private var centsLabel: String {
        guard let cents else { return "No tuning data" }
        return String(format: "%+.0f¢", cents)
    }

    private var centsAccessibilityLabel: String {
        guard let cents else { return "No tuning data" }
        return String(format: "%+.0f cents", cents)
    }

    private func gaugeAngle(for cents: Double) -> Double {
        270 + (cents / maxCents) * 90
    }

    private func point(on center: CGPoint, radius: CGFloat, angle: Double) -> CGPoint {
        let radians = angle * .pi / 180
        return CGPoint(
            x: center.x + CGFloat(cos(radians)) * radius,
            y: center.y + CGFloat(sin(radians)) * radius
        )
    }
}
