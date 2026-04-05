import SwiftUI

struct CircleOfFifthsView: View {
    @EnvironmentObject private var detector: PitchDetectorService

    private let maxSize: CGFloat = 300
    private let outerRadiusRatio: CGFloat = 126.0 / 132.0
    private let middleRadiusRatio: CGFloat = 88.0 / 132.0
    private let innerRadiusRatio: CGFloat = 58.0 / 132.0
    private let centerRadiusRatio: CGFloat = 32.0 / 132.0
    private let majorLabelRadiusRatio: CGFloat = 112.0 / 132.0
    private let minorLabelRadiusRatio: CGFloat = 71.0 / 132.0

    var body: some View {
        GeometryReader { geometry in
            let effectiveSize = max(min(min(geometry.size.width, geometry.size.height), maxSize), 1)
            let radius = effectiveSize / 2
            let center = CGPoint(x: radius, y: radius)
            let outerRadius = radius * outerRadiusRatio
            let middleRadius = radius * middleRadiusRatio
            let innerRadius = radius * innerRadiusRatio
            let centerRadius = radius * centerRadiusRatio
            let majorLabelRadius = radius * majorLabelRadiusRatio
            let minorLabelRadius = radius * minorLabelRadiusRatio

            ZStack {
                Canvas { context, _ in
                    for i in 0..<12 {
                        let startAngle = Angle.degrees(Double(i) * 30 - 105)
                        let endAngle = Angle.degrees(Double(i + 1) * 30 - 105)
                        let isActive = detector.currentPitch?.coFIndex == i

                        let outerPath = sectorPath(
                            center: center,
                            inner: middleRadius,
                            outer: outerRadius,
                            start: startAngle,
                            end: endAngle
                        )
                        context.fill(outerPath, with: .color(isActive ? .activeMajorFill : .bgSegment))
                        context.stroke(
                            outerPath,
                            with: .color(isActive ? .activeMajorStroke : .inactiveStroke),
                            lineWidth: isActive ? 1.5 : 0.5
                        )

                        let innerPath = sectorPath(
                            center: center,
                            inner: innerRadius,
                            outer: middleRadius,
                            start: startAngle,
                            end: endAngle
                        )
                        context.fill(innerPath, with: .color(isActive ? .activeMinorFill : .bgSegment))
                        context.stroke(
                            innerPath,
                            with: .color(isActive ? .activeMinorStroke : .inactiveStroke),
                            lineWidth: isActive ? 1.5 : 0.5
                        )
                    }
                }
                .frame(width: effectiveSize, height: effectiveSize)

                Circle()
                    .fill(Color.bgCore)
                    .frame(width: centerRadius * 2, height: centerRadius * 2)

                ForEach(Array(CircleOfFifthsLayout.majorNames.enumerated()), id: \.offset) { index, majorName in
                    Text(majorName)
                        .font(.system(size: detector.currentPitch?.coFIndex == index ? 14 : 13, weight: detector.currentPitch?.coFIndex == index ? .medium : .regular))
                        .foregroundStyle(detector.currentPitch?.coFIndex == index ? Color.activeMajorText : Color.inactiveText)
                        .shadow(color: detector.currentPitch?.coFIndex == index ? Color.activeMajorStroke.opacity(0.25) : .clear, radius: 3)
                        .position(labelPosition(for: index, radius: majorLabelRadius, center: center))
                }

                ForEach(Array(CircleOfFifthsLayout.minorNames.enumerated()), id: \.offset) { index, minorName in
                    Text(minorName)
                        .font(.system(size: detector.currentPitch?.coFIndex == index ? 12 : 11, weight: detector.currentPitch?.coFIndex == index ? .medium : .regular))
                        .foregroundStyle(detector.currentPitch?.coFIndex == index ? Color.activeMinorText : Color.inactiveText)
                        .shadow(color: detector.currentPitch?.coFIndex == index ? Color.activeMinorStroke.opacity(0.22) : .clear, radius: 3)
                        .position(labelPosition(for: index, radius: minorLabelRadius, center: center))
                }

                if let pitch = detector.currentPitch, let index = pitch.coFIndex {
                    VStack(spacing: 4) {
                        Text(CircleOfFifthsLayout.majorName(for: index))
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(Color.activeMajorText)

                        Text(CircleOfFifthsLayout.minorName(for: index))
                            .font(.system(size: 13, weight: .regular))
                            .foregroundStyle(Color.activeMinorText)
                    }
                    .padding(.horizontal, 8)
                }
            }
            .frame(width: effectiveSize, height: effectiveSize)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(height: maxSize)
        .animation(.easeInOut(duration: detector.currentPitch == nil ? 0.2 : 0.15), value: detector.currentPitch?.coFIndex)
    }

    private func sectorPath(center: CGPoint, inner: CGFloat, outer: CGFloat, start: Angle, end: Angle) -> Path {
        var path = Path()
        path.addArc(center: center, radius: outer, startAngle: start, endAngle: end, clockwise: false)
        path.addArc(center: center, radius: inner, startAngle: end, endAngle: start, clockwise: true)
        path.closeSubpath()
        return path
    }

    private func labelPosition(for index: Int, radius: CGFloat, center: CGPoint) -> CGPoint {
        let angle = Angle.degrees(Double(index) * 30 - 90)
        let x = center.x + CGFloat(cos(angle.radians)) * radius
        let y = center.y + CGFloat(sin(angle.radians)) * radius
        return CGPoint(x: x, y: y)
    }
}
