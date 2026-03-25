import SwiftUI

struct ActivityFeedView: View {
    let items: [ActivityItem]

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Activity Feed")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(FasterTheme.text)

                Spacer()

                HStack(spacing: 5) {
                    Circle()
                        .fill(FasterTheme.green)
                        .frame(width: 6, height: 6)
                        .modifier(PulseModifier())

                    Text("LIVE")
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundStyle(FasterTheme.green)
                }
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 14)

            Divider().background(FasterTheme.border1)

            if items.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "tray")
                        .font(.system(size: 24))
                        .foregroundStyle(FasterTheme.muted2)
                    Text("No recent activity")
                        .font(.system(size: 12))
                        .foregroundStyle(FasterTheme.muted)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 32)
            } else {
                ForEach(items) { item in
                    ActivityRow(item: item)
                }
            }
        }
        .fasterCard()
    }
}

struct ActivityRow: View {
    let item: ActivityItem

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Text(item.icon)
                .font(.system(size: 15))
                .frame(width: 28, height: 28)
                .background(FasterTheme.surface2)
                .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 2) {
                Text(item.message)
                    .font(.system(size: 12))
                    .foregroundStyle(FasterTheme.text)
                    .lineLimit(2)

                Text(item.module)
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(FasterTheme.muted)
            }

            Spacer()
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 10)
    }
}

struct PulseModifier: ViewModifier {
    @State private var isPulsing = false

    func body(content: Content) -> some View {
        content
            .opacity(isPulsing ? 0.3 : 1.0)
            .animation(.easeInOut(duration: 2).repeatForever(), value: isPulsing)
            .onAppear { isPulsing = true }
    }
}
