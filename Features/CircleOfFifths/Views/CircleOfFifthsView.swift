import SwiftUI

struct CircleOfFifthsView: View {
    @EnvironmentObject private var detector: PitchDetectorService

    private let size: CGFloat = 264
    private let center: CGPoint = CGPoint(x: 132, y: 132)
    private let outerRadius: CGFloat = 126
    private let middleRadius: CGFloat = 88
    private let innerRadius: CGFloat = 58
    private let centerRadius: CGFloat = 32

    var body: some View {
        ZStack {
            Canvas { context, _ in
                for i in 0..<12 {
                    let startAngle = Angle.degrees(Double(i) * 30 - 105)
                    let endAngle = Angle.degrees(Double(i + 1) * 30 - 105)
                    let isActive = detector.currentPitch?.coFIndex == i

                    let outerPath = sectorPath(inner: middleRadius, outer: outerRadius, start: startAngle, end: endAngle)
                    context.fill(outerPath, with: .color(isActive ? .activeMajorFill : .bgSegment))
                    context.stroke(
                        outerPath,
                        with: .color(isActive ? .activeMajorStroke : .inactiveStroke),
                        lineWidth: isActive ? 1.5 : 0.5
                    )

                    let innerPath = sectorPath(inner: innerRadius, outer: middleRadius, start: startAngle, end: endAngle)
                    context.fill(innerPath, with: .color(isActive ? .activeMinorFill : .bgSegment))
                    context.stroke(
                        innerPath,
                        with: .color(isActive ? .activeMinorStroke : .inactiveStroke),
                        lineWidth: isActive ? 1.5 : 0.5
                    )
                }
            }
            .frame(width: size, height: size)

            Circle()
                .fill(Color.bgCore)
                .frame(width: centerRadius * 2, height: centerRadius * 2)

            ForEach(Array(CircleOfFifthsLayout.majorNames.enumerated()), id: \.offset) { index, majorName in
                Text(majorName)
                    .font(.system(size: detector.currentPitch?.coFIndex == index ? 12 : 11, weight: detector.currentPitch?.coFIndex == index ? .medium : .regular))
                    .foregroundStyle(detector.currentPitch?.coFIndex == index ? Color.activeMajorText : Color.inactiveText)
                    .shadow(color: detector.currentPitch?.coFIndex == index ? Color.activeMajorStroke.opacity(0.25) : .clear, radius: 3)
                    .position(labelPosition(for: index, radius: 110))
            }

            ForEach(Array(CircleOfFifthsLayout.minorNames.enumerated()), id: \.offset) { index, minorName in
                Text(minorName)
                    .font(.system(size: detector.currentPitch?.coFIndex == index ? 11 : 10, weight: detector.currentPitch?.coFIndex == index ? .medium : .regular))
                    .foregroundStyle(detector.currentPitch?.coFIndex == index ? Color.activeMinorText : Color.inactiveText)
                    .shadow(color: detector.currentPitch?.coFIndex == index ? Color.activeMinorStroke.opacity(0.22) : .clear, radius: 3)
                    .position(labelPosition(for: index, radius: 72))
            }

            if let pitch = detector.currentPitch, let index = pitch.coFIndex {
                VStack(spacing: 4) {
                    Text(CircleOfFifthsLayout.majorName(for: index))
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Color.activeMajorText)

                    Text(CircleOfFifthsLayout.minorName(for: index))
                        .font(.system(size: 11, weight: .regular))
                        .foregroundStyle(Color.activeMinorText)
                }
                .padding(.horizontal, 8)
            }
        }
        .frame(width: size, height: size)
        .animation(.easeInOut(duration: detector.currentPitch == nil ? 0.2 : 0.15), value: detector.currentPitch?.coFIndex)
    }

    private func sectorPath(inner: CGFloat, outer: CGFloat, start: Angle, end: Angle) -> Path {
        var path = Path()
        path.addArc(center: center, radius: outer, startAngle: start, endAngle: end, clockwise: false)
        path.addArc(center: center, radius: inner, startAngle: end, endAngle: start, clockwise: true)
        path.closeSubpath()
        return path
    }

    private func labelPosition(for index: Int, radius: CGFloat) -> CGPoint {
        let angle = Angle.degrees(Double(index) * 30 - 90)
        let x = center.x + CGFloat(cos(angle.radians)) * radius
        let y = center.y + CGFloat(sin(angle.radians)) * radius
        return CGPoint(x: x, y: y)
    }
}
