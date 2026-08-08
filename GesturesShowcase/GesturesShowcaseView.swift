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
                    .draggable(GestureToken.token) {
                        Circle()
                            .fill(.blue.gradient)
                            .frame(width: 54, height: 54)
                            .overlay(Image(systemName: "sparkle").foregroundStyle(.white))
                    }

                Image(systemName: "arrow.right")
                    .foregroundStyle(.secondary)

                RoundedRectangle(cornerRadius: 16)
                    .fill(isTargeted ? Color.blue.opacity(0.2) : Color.blue.opacity(0.08))
                    .strokeBorder(.blue, style: StrokeStyle(lineWidth: 2, dash: [6]))
                    .frame(width: 90, height: 90)
                    .overlay {
                        Image(systemName: dropped ? "checkmark.circle.fill" : "tray")
                            .font(.title)
                            .foregroundStyle(.blue)
                    }
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
    @State private var scale: CGFloat = 1
    @GestureState private var pinchScale: CGFloat = 1

    var body: some View {
        DemoCard(title: "Magnify", subtitle: "Pinch to scale the star, release to keep") {
            VStack(spacing: 10) {
                Image(systemName: "star.fill")
                    .resizable()
                    .frame(width: 60, height: 60)
                    .foregroundStyle(.yellow.gradient)
                    .scaleEffect(scale * pinchScale)
                    .gesture(
                        MagnifyGesture()
                            .updating($pinchScale) { value, state, _ in
                                state = value.magnification
                            }
                            .onEnded { value in
                                scale = max(0.5, min(3, scale * value.magnification))
                            }
                    )

                Text(String(format: "%.2fx", scale * pinchScale))
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
    @GestureState private var pinchAngle: Angle = .zero

    var body: some View {
        DemoCard(title: "Rotate", subtitle: "Twist with two fingers to spin the arrow") {
            VStack(spacing: 10) {
                Image(systemName: "location.north.fill")
                    .resizable()
                    .frame(width: 50, height: 50)
                    .foregroundStyle(.purple.gradient)
                    .rotationEffect(angle + pinchAngle)
                    .gesture(
                        RotateGesture()
                            .updating($pinchAngle) { value, state, _ in
                                state = value.rotation
                            }
                            .onEnded { value in
                                angle += value.rotation
                            }
                    )

                Text("\(Int((angle + pinchAngle).degrees))°")
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
