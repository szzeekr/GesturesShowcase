import SwiftUI
import UniformTypeIdentifiers

struct GesturesShowcaseView: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    TapDemoCard()
                    LongPressDemoCard()
                    DragDropDemoCard()
                    MagnifyDemoCard()
                    RotateDemoCard()
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Gestures")
        }
    }
}

// MARK: - Shared card chrome

private struct DemoCard<Content: View>: View {
    let title: String
    let subtitle: String
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            content
                .frame(maxWidth: .infinity, minHeight: 160)
        }
        .padding()
        .background(.background, in: RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.06), radius: 8, y: 4)
    }
}

// MARK: - Tap

private struct TapDemoCard: View {
    @State private var tapCount = 0
    @State private var isFilled = false

    var body: some View {
        DemoCard(title: "Tap", subtitle: "Single tap toggles the fill, double tap resets") {
            VStack(spacing: 10) {
                Circle()
                    .fill(isFilled ? .pink : .clear)
                    .stroke(.pink, lineWidth: 4)
                    .frame(width: 70, height: 70)
                    .overlay {
                        Text("\(tapCount)")
                            .font(.title2.bold())
                            .foregroundStyle(isFilled ? .white : .pink)
                    }
                    .onTapGesture {
                        tapCount += 1
                        isFilled.toggle()
                    }
                    .onTapGesture(count: 2) {
                        tapCount = 0
                        isFilled = false
                    }

                Text("Tap to count, double-tap to reset")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
        }
    }
}

// MARK: - Long Press

private struct LongPressDemoCard: View {
    @State private var progress: CGFloat = 0
    @State private var isComplete = false
    @GestureState private var isPressing = false

    private let holdDuration: TimeInterval = 1.0

    var body: some View {
        DemoCard(title: "Long Press", subtitle: "Hold the circle for \(Int(holdDuration))s to complete it") {
            VStack(spacing: 10) {
                ZStack {
                    Circle()
                        .stroke(.orange.opacity(0.25), lineWidth: 8)
                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(isComplete ? .green : .orange, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                    Image(systemName: isComplete ? "checkmark" : "hand.tap")
                        .font(.title2)
                        .foregroundStyle(isComplete ? .green : .orange)
                }
                .frame(width: 70, height: 70)
                .scaleEffect(isPressing ? 1.08 : 1)
                .animation(.easeOut(duration: 0.2), value: isPressing)
                .gesture(
                    LongPressGesture(minimumDuration: holdDuration)
                        .updating($isPressing) { value, state, _ in
                            state = value
                        }
                        .onEnded { _ in
                            isComplete = true
                            withAnimation(.easeOut(duration: holdDuration)) {
                                progress = 1
                            }
                        }
                )
                .onLongPressGesture(minimumDuration: holdDuration, perform: {}, onPressingChanged: { pressing in
                    if pressing {
                        isComplete = false
                        progress = 0
                        withAnimation(.linear(duration: holdDuration)) {
                            progress = 1
                        }
                    } else if !isComplete {
                        withAnimation(.easeOut(duration: 0.2)) {
                            progress = 0
                        }
                    }
                })

                Text(isComplete ? "Completed!" : "Press and hold")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
        }
    }
}

// MARK: - Drag and Drop

private struct DragDropDemoCard: View {
    @State private var dropped = false
    @State private var isTargeted = false

    var body: some View {
        DemoCard(title: "Drag & Drop", subtitle: "Drag the token into the drop zone") {
            HStack(spacing: 24) {
                Circle()
                    .fill(.blue.gradient)
                    .frame(width: 54, height: 54)
                    .overlay(Image(systemName: "sparkle").foregroundStyle(.white))
                    .opacity(dropped ? 0.25 : 1)
                    .contentShape(Circle())
                    .draggable(GestureToken.token) {
                        Circle()
                            .fill(.blue.gradient)
                            .frame(width: 54, height: 54)
                            .overlay(Image(systemName: "sparkle").foregroundStyle(.white))
                    }

                Image(systemName: "arrow.right")
                    .foregroundStyle(.secondary)

                RoundedRectangle(cornerRadius: 16)
                    .fill(isTargeted ? Color.blue.opacity(0.25) : Color.blue.opacity(0.08))
                    .strokeBorder(.blue, style: StrokeStyle(lineWidth: isTargeted ? 3 : 2, dash: [6]))
                    .frame(width: 90, height: 90)
                    .overlay {
                        Image(systemName: dropped ? "checkmark.circle.fill" : "tray")
                            .font(.title)
                            .foregroundStyle(.blue)
                    }
                    .scaleEffect(isTargeted ? 1.08 : 1)
                    .animation(.spring(response: 0.25, dampingFraction: 0.7), value: isTargeted)
                    // Extra transparent padding widens the actual hit-tested drop
                    // region beyond the drawn box, so near-misses still land
                    .padding(14)
                    .contentShape(Rectangle())
                    .dropDestination(for: GestureToken.self) { items, _ in
                        guard items.first != nil else { return false }
                        dropped = true
                        return true
                    } isTargeted: { targeted in
                        isTargeted = targeted
                    }
            }
            .frame(maxWidth: .infinity)
            .overlay(alignment: .bottom) {
                if dropped {
                    Button("Reset") { dropped = false }
                        .font(.caption)
                        .padding(.top, 8)
                }
            }
        }
    }
}

private struct GestureToken: Codable, Transferable {
    static var transferRepresentation: some TransferRepresentation {
        CodableRepresentation(contentType: .gestureToken)
    }

    static let token = GestureToken()
}

extension UTType {
    static let gestureToken = UTType(exportedAs: "com.gesturesshowcase.gestureToken")
}

// MARK: - Magnify (pinch)

private struct MagnifyDemoCard: View {
    // Tracks the zoom multiplier while the user is actively pinching
    @State private var currentZoom: CGFloat = 0.0
    // Stores the permanent zoom level after the gesture ends
    @State private var totalZoom: CGFloat = 1.0

    // Keeps the scale from collapsing to 0 (or flipping negative) on zoom-out,
    // and from growing without bound on zoom-in
    private let minZoom: CGFloat = 0.5
    private let maxZoom: CGFloat = 4.0

    private var displayedZoom: CGFloat {
        min(maxZoom, max(minZoom, totalZoom + currentZoom))
    }

    var body: some View {
        DemoCard(title: "Magnify", subtitle: "Pinch to scale the emoji, release to keep") {
            VStack(spacing: 10) {
                Text("🤩")
                    .font(.system(size: 70))
                    .contentShape(Rectangle())
                    // 1. Combine the ongoing pinch value with the saved baseline zoom
                    .scaleEffect(displayedZoom)
                    // highPriorityGesture so the enclosing ScrollView's pan recognizer
                    // (which also accepts 2-finger touches) doesn't steal the pinch first
                    .highPriorityGesture(
                        MagnifyGesture()
                            // 2. Triggers continuously as the user moves their fingers
                            .onChanged { value in
                                // Subtract 1 because value.magnification starts at 1.0
                                currentZoom = value.magnification - 1.0
                            }
                            // 3. Triggers once when the user lifts their fingers
                            .onEnded { _ in
                                totalZoom = displayedZoom
                                currentZoom = 0.0 // Reset the active delta tracker
                            }
                    )

                Text(String(format: "%.2fx", displayedZoom))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
        }
    }
}

// MARK: - Rotation

private struct RotateDemoCard: View {
    @State private var angle: Angle = .zero

    var body: some View {
        DemoCard(title: "Rotate", subtitle: "Drag around the arrow to spin it") {
            VStack(spacing: 10) {
                Image(systemName: "arrow.right")
                    .font(.system(size: 60))
                    .rotationEffect(angle)
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                let center = CGPoint(x: value.startLocation.x, y: value.startLocation.y)
                                let startVector = CGVector(dx: value.startLocation.x - center.x, dy: value.startLocation.y - center.y)
                                let currentVector = CGVector(dx: value.location.x - center.x, dy: value.location.y - center.y)
                                let angleDelta = atan2(currentVector.dy, currentVector.dx) - atan2(startVector.dy, startVector.dx)
                                angle = Angle(radians: Double(angleDelta))
                            }
                    )

                Text("\(Int(angle.degrees))°")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
        }
    }
}

#Preview {
    GesturesShowcaseView()
}
