import SwiftUI

struct SafetyView: View {
    @ObservedObject var auth = AuthService.shared
    @State private var reports: [SafetyReport] = []
    @State private var searchText = ""
    @State private var filterSeverity: SafetyReport.Severity?
    @State private var showAddSheet = false
    @State private var selectedReport: SafetyReport?
    @State private var observerHandle: UInt?

    var filteredReports: [SafetyReport] {
        var result = reports.sorted { $0._ts > $1._ts }
        if let sev = filterSeverity {
            result = result.filter { $0.severity == sev }
        }
        if !searchText.isEmpty {
            let q = searchText.lowercased()
            result = result.filter {
                $0.title.lowercased().contains(q) ||
                $0.location.lowercased().contains(q) ||
                $0.description.lowercased().contains(q)
            }
        }
        return result
    }

    var openCount: Int { reports.filter { $0.status == .open }.count }
    var criticalCount: Int { reports.filter { $0.severity == .critical && $0.status == .open }.count }

    var body: some View {
        VStack(spacing: 0) {
            // Alert banners
            if criticalCount > 0 {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.octagon.fill")
                        .foregroundStyle(FasterTheme.red)
                    Text("\(criticalCount) critical report\(criticalCount == 1 ? "" : "s") open")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(FasterTheme.red)
                    Spacer()
                }
                .padding(12)
                .background(FasterTheme.red.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .padding(.horizontal, 16)
                .padding(.top, 8)
            }

            // Stats row
            HStack(spacing: 12) {
                MiniStatCard(label: "Total", value: "\(reports.count)", color: FasterTheme.blue)
                MiniStatCard(label: "Open", value: "\(openCount)", color: FasterTheme.amber)
                MiniStatCard(label: "Critical", value: "\(criticalCount)", color: FasterTheme.red)
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)

            // Search & Filter
            VStack(spacing: 10) {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(FasterTheme.muted)
                    TextField("Search reports...", text: $searchText)
                        .foregroundStyle(FasterTheme.text)
                }
                .padding(10)
                .background(FasterTheme.surface2)
                .clipShape(RoundedRectangle(cornerRadius: 8))

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        FilterChip(label: "All", isActive: filterSeverity == nil) {
                            filterSeverity = nil
                        }
                        ForEach(SafetyReport.Severity.allCases, id: \.self) { sev in
                            FilterChip(label: sev.rawValue, isActive: filterSeverity == sev) {
                                filterSeverity = sev
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 10)

            // List
            if filteredReports.isEmpty {
                Spacer()
                EmptyStateView(icon: "shield.checkered", message: reports.isEmpty ? "No safety reports" : "No matching reports")
                Spacer()
            } else {
                ScrollView {
                    LazyVStack(spacing: 10) {
                        ForEach(filteredReports) { report in
                            SafetyCard(report: report, onTap: {
                                selectedReport = report
                            }, onResolve: {
                                resolveReport(report)
                            }, onDelete: {
                                Task { try? await FirebaseService.shared.deleteSafetyReport(report.id) }
                            }, isAdmin: auth.isAdmin, isReadOnly: auth.isReadOnly)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }
            }
        }
        .background(FasterTheme.background)
        .navigationTitle("Safety Hub")
        .toolbar {
            if !auth.isReadOnly {
                ToolbarItem(placement: .primaryAction) {
                    Button { showAddSheet = true } label: {
                        Image(systemName: "plus.circle.fill")
                            .foregroundStyle(FasterTheme.accent)
                    }
                }
            }
        }
        .sheet(isPresented: $showAddSheet) {
            SafetyFormView(report: SafetyReport()) { report in
                Task { try? await FirebaseService.shared.saveSafetyReport(report) }
            }
            .presentationDetents([.large])
        }
        .sheet(item: $selectedReport) { report in
            SafetyDetailView(report: report)
                .presentationDetents([.large])
        }
        .onAppear { startObserving() }
        .onDisappear { stopObserving() }
    }

    private func startObserving() {
        observerHandle = FirebaseService.shared.observeSafetyReports { reports = $0 }
    }

    private func stopObserving() {
        if let handle = observerHandle {
            FirebaseService.shared.removeObserver(path: "faster_safety/reports", handle: handle)
        }
    }

    private func resolveReport(_ report: SafetyReport) {
        var updated = report
        updated.status = .resolved
        updated.resolvedBy = auth.currentUsername
        updated.resolvedAt = Int64(Date().timeIntervalSince1970 * 1000)
        Task { try? await FirebaseService.shared.saveSafetyReport(updated) }
    }
}

// MARK: - Mini Stat Card

struct MiniStatCard: View {
    let label: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 18, weight: .bold, design: .monospaced))
                .foregroundStyle(color)
            Text(label)
                .font(.system(size: 10, weight: .medium, design: .monospaced))
                .foregroundStyle(FasterTheme.muted)
                .textCase(.uppercase)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .fasterCard()
    }
}

// MARK: - Safety Card

struct SafetyCard: View {
    let report: SafetyReport
    let onTap: () -> Void
    let onResolve: () -> Void
    let onDelete: () -> Void
    let isAdmin: Bool
    let isReadOnly: Bool

    var severityColor: Color {
        FasterTheme.semanticColor(report.severity.color)
    }

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(report.title)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(FasterTheme.text)
                            .lineLimit(1)
                            .multilineTextAlignment(.leading)
                        Text(report.location)
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundStyle(FasterTheme.muted)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 4) {
                        StatusBadge(text: report.severity.rawValue, color: severityColor)
                        StatusBadge(text: report.status.rawValue,
                                  color: report.status == .open ? FasterTheme.amber : FasterTheme.green)
                    }
                }

                Text(report.description)
                    .font(.system(size: 12))
                    .foregroundStyle(FasterTheme.muted)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                if !isReadOnly {
                    HStack(spacing: 10) {
                        if report.status == .open && isAdmin {
                            Button(action: onResolve) {
                                Label("Resolve", systemImage: "checkmark.circle")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundStyle(FasterTheme.green)
                            }
                        }
                        Spacer()
                        Button(action: onDelete) {
                            Image(systemName: "trash")
                                .font(.system(size: 13))
                                .foregroundStyle(FasterTheme.red)
                        }
                    }
                }
            }
            .padding(16)
            .fasterCard()
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Safety Detail

struct SafetyDetailView: View {
    let report: SafetyReport

    var body: some View {
        NavigationStack {
            ZStack {
                FasterTheme.background.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            StatusBadge(text: report.severity.rawValue,
                                      color: FasterTheme.semanticColor(report.severity.color))
                            StatusBadge(text: report.status.rawValue,
                                      color: report.status == .open ? FasterTheme.amber : FasterTheme.green)
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Location")
                                .font(.system(size: 11, weight: .bold, design: .monospaced))
                                .foregroundStyle(FasterTheme.muted)
                            Text(report.location)
                                .font(.system(size: 14))
                                .foregroundStyle(FasterTheme.text)
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Description")
                                .font(.system(size: 11, weight: .bold, design: .monospaced))
                                .foregroundStyle(FasterTheme.muted)
                            Text(report.description)
                                .font(.system(size: 14))
                                .foregroundStyle(FasterTheme.text)
                        }

                        if let ts = TimeInterval(exactly: report._ts) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Reported")
                                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                                    .foregroundStyle(FasterTheme.muted)
                                Text(Date(timeIntervalSince1970: ts / 1000), style: .date)
                                    .font(.system(size: 14))
                                    .foregroundStyle(FasterTheme.text)
                            }
                        }
                    }
                    .padding(16)
                }
            }
            .navigationTitle(report.title)
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: - Safety Form

struct SafetyFormView: View {
    @Environment(\.dismiss) var dismiss
    @State var report: SafetyReport
    let onSave: (SafetyReport) -> Void

    var body: some View {
        NavigationStack {
            ZStack {
                FasterTheme.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 14) {
                        FormField(label: "Title") {
                            TextField("Report title", text: $report.title).fasterInput()
                        }
                        FormField(label: "Location") {
                            TextField("Where did it happen?", text: $report.location).fasterInput()
                        }
                        FormField(label: "Severity") {
                            Picker("Severity", selection: $report.severity) {
                                ForEach(SafetyReport.Severity.allCases, id: \.self) { s in
                                    Text(s.rawValue).tag(s)
                                }
                            }
                            .pickerStyle(.segmented)
                        }
                        FormField(label: "Description") {
                            TextField("Detailed description", text: $report.description, axis: .vertical)
                                .lineLimit(4...8)
                                .fasterInput()
                        }
                    }
                    .padding(16)
                }
            }
            .navigationTitle("New Safety Report")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }.foregroundStyle(FasterTheme.muted)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Submit") {
                        report.reporter = AuthService.shared.currentUsername
                        onSave(report)
                        dismiss()
                    }
                    .foregroundStyle(FasterTheme.accent)
                    .fontWeight(.bold)
                }
            }
        }
    }
}
