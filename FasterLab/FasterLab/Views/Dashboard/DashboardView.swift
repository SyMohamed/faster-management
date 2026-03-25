import SwiftUI
import FirebaseDatabase

struct DashboardView: View {
    @ObservedObject var auth = AuthService.shared

    @State private var orderCount = 0
    @State private var chemicalCount = 0
    @State private var assetCount = 0
    @State private var bookingCount = 0
    @State private var safetyCount = 0
    @State private var guideCount = 0
    @State private var activityItems: [ActivityItem] = []
    @State private var isLoading = true

    var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        let name = auth.currentUser?.name.components(separatedBy: " ").first ?? ""
        if hour < 12 { return "Good morning, \(name)" }
        if hour < 17 { return "Good afternoon, \(name)" }
        return "Good evening, \(name)"
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Hero section
                VStack(spacing: 8) {
                    Text("DIGITAL WORKSPACE")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundStyle(FasterTheme.accent)
                        .tracking(3)

                    Text(greeting)
                        .font(.system(size: 24, weight: .heavy))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color(hex: "#e4edf8"), Color(hex: "#7d99b8")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )

                    Text("Your lab management hub")
                        .font(.system(size: 13))
                        .foregroundStyle(FasterTheme.muted2)
                }
                .padding(.top, 8)
                .padding(.bottom, 4)

                // Stats grid
                if isLoading {
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                    ], spacing: 12) {
                        ForEach(0..<6, id: \.self) { _ in
                            SkeletonStatCard()
                        }
                    }
                    .padding(.horizontal, 16)
                } else {
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                    ], spacing: 12) {
                        StatCard(icon: "cart", label: "Orders", count: orderCount, color: FasterTheme.blue)
                        StatCard(icon: "flask", label: "Chemicals", count: chemicalCount, color: FasterTheme.teal)
                        StatCard(icon: "wrench.and.screwdriver", label: "Assets", count: assetCount, color: FasterTheme.purple)
                        StatCard(icon: "calendar.badge.clock", label: "Bookings", count: bookingCount, color: FasterTheme.amber)
                        StatCard(icon: "shield.checkered", label: "Safety", count: safetyCount, color: FasterTheme.red)
                        StatCard(icon: "book", label: "Guides", count: guideCount, color: FasterTheme.green)
                    }
                    .padding(.horizontal, 16)
                }

                // Activity Feed
                ActivityFeedView(items: activityItems)
                    .padding(.horizontal, 16)
            }
            .padding(.bottom, 24)
        }
        .background(FasterTheme.background)
        .onAppear { loadStats() }
    }

    private func loadStats() {
        let db = Database.database().reference()

        // Load counts for each module
        db.child("faster_orders").observeSingleEvent(of: .value) { snap in
            orderCount = Int(snap.childrenCount)
        }
        db.child("faster_chemicals").observeSingleEvent(of: .value) { snap in
            chemicalCount = Int(snap.childrenCount)
        }
        db.child("faster_assets_v5").observeSingleEvent(of: .value) { snap in
            assetCount = Int(snap.childrenCount)
        }
        db.child("faster_planning").observeSingleEvent(of: .value) { snap in
            bookingCount = Int(snap.childrenCount)
        }
        db.child("faster_safety/reports").observeSingleEvent(of: .value) { snap in
            safetyCount = Int(snap.childrenCount)
        }
        db.child("faster_guide/docs").observeSingleEvent(of: .value) { snap in
            var count = 0
            for child in snap.children {
                if let catSnap = child as? DataSnapshot {
                    count += Int(catSnap.childrenCount)
                }
            }
            guideCount = count
            isLoading = false
        }
    }
}

// MARK: - Stat Card

struct StatCard: View {
    let icon: String
    let label: String
    let count: Int
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundStyle(color)

            Text("\(count)")
                .font(.system(size: 22, weight: .bold, design: .monospaced))
                .foregroundStyle(FasterTheme.text)

            Text(label)
                .font(.system(size: 10, weight: .medium, design: .monospaced))
                .foregroundStyle(FasterTheme.muted)
                .textCase(.uppercase)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .fasterCard()
    }
}

struct SkeletonStatCard: View {
    @State private var shimmer = false

    var body: some View {
        VStack(spacing: 8) {
            RoundedRectangle(cornerRadius: 4)
                .fill(FasterTheme.surface2)
                .frame(width: 20, height: 20)
            RoundedRectangle(cornerRadius: 4)
                .fill(FasterTheme.surface2)
                .frame(width: 30, height: 18)
            RoundedRectangle(cornerRadius: 4)
                .fill(FasterTheme.surface2)
                .frame(width: 50, height: 10)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .fasterCard()
        .opacity(shimmer ? 0.4 : 0.9)
        .animation(.easeInOut(duration: 1.4).repeatForever(), value: shimmer)
        .onAppear { shimmer = true }
    }
}

// MARK: - Activity Item

struct ActivityItem: Identifiable {
    let id = UUID()
    let icon: String
    let message: String
    let module: String
    let timestamp: Date
}
