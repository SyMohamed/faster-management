import SwiftUI

struct PlanningView: View {
    @ObservedObject var auth = AuthService.shared
    @State private var entries: [PlanningEntry] = []
    @State private var searchText = ""
    @State private var filterStatus: PlanningEntry.PlanningStatus?
    @State private var showAddSheet = false
    @State private var editingEntry: PlanningEntry?
    @State private var observerHandle: UInt?

    var filteredEntries: [PlanningEntry] {
        var result = entries
        if let filter = filterStatus {
            result = result.filter { $0.status == filter }
        }
        if !searchText.isEmpty {
            let q = searchText.lowercased()
            result = result.filter {
                $0.title.lowercased().contains(q) ||
                $0.researcher.lowercased().contains(q) ||
                $0.facility.lowercased().contains(q)
            }
        }
        return result
    }

    var body: some View {
        VStack(spacing: 0) {
            // Search & Filter
            VStack(spacing: 10) {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(FasterTheme.muted)
                    TextField("Search bookings...", text: $searchText)
                        .foregroundStyle(FasterTheme.text)
                }
                .padding(10)
                .background(FasterTheme.surface2)
                .clipShape(RoundedRectangle(cornerRadius: 8))

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        FilterChip(label: "All", isActive: filterStatus == nil) {
                            filterStatus = nil
                        }
                        ForEach(PlanningEntry.PlanningStatus.allCases, id: \.self) { status in
                            FilterChip(label: status.rawValue, isActive: filterStatus == status) {
                                filterStatus = status
                            }
                        }
                    }
                }
            }
            .padding(16)

            if filteredEntries.isEmpty {
                Spacer()
                EmptyStateView(icon: "calendar.badge.clock", message: entries.isEmpty ? "No bookings yet" : "No matching bookings")
                Spacer()
            } else {
                ScrollView {
                    LazyVStack(spacing: 10) {
                        ForEach(filteredEntries) { entry in
                            PlanningCard(entry: entry,
                                isAdmin: auth.isAdmin,
                                isReadOnly: auth.isReadOnly,
                                onApprove: { approveEntry(entry) },
                                onReject: { rejectEntry(entry) },
                                onEdit: { editingEntry = entry },
                                onDelete: { deleteEntry(entry) }
                            )
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 24)
                }
            }
        }
        .background(FasterTheme.background)
        .navigationTitle("Planning")
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
            PlanningFormView(entry: PlanningEntry()) { entry in
                Task { try? await FirebaseService.shared.savePlanning(entry) }
            }
            .presentationDetents([.large])
        }
        .sheet(item: $editingEntry) { entry in
            PlanningFormView(entry: entry) { updated in
                Task { try? await FirebaseService.shared.savePlanning(updated) }
            }
            .presentationDetents([.large])
        }
        .onAppear { startObserving() }
        .onDisappear { stopObserving() }
    }

    private func startObserving() {
        observerHandle = FirebaseService.shared.observePlanning { entries = $0 }
    }

    private func stopObserving() {
        if let handle = observerHandle {
            FirebaseService.shared.removeObserver(path: "faster_planning", handle: handle)
        }
    }

    private func approveEntry(_ entry: PlanningEntry) {
        Task {
            try? await FirebaseService.shared.updatePlanningStatus(
                id: entry.id, status: "Approved", resolvedBy: auth.currentUsername
            )
        }
    }

    private func rejectEntry(_ entry: PlanningEntry) {
        Task {
            try? await FirebaseService.shared.updatePlanningStatus(
                id: entry.id, status: "Rejected", resolvedBy: auth.currentUsername
            )
        }
    }

    private func deleteEntry(_ entry: PlanningEntry) {
        Task { try? await FirebaseService.shared.deletePlanning(entry.id) }
    }
}

// MARK: - Planning Card

struct PlanningCard: View {
    let entry: PlanningEntry
    let isAdmin: Bool
    let isReadOnly: Bool
    let onApprove: () -> Void
    let onReject: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void

    var statusColor: Color {
        FasterTheme.semanticColor(entry.status.color)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(entry.title)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(FasterTheme.text)
                        .lineLimit(1)
                    Text(entry.facility)
                        .font(.system(size: 12, weight: .medium, design: .monospaced))
                        .foregroundStyle(FasterTheme.accent)
                }
                Spacer()
                StatusBadge(text: entry.status.rawValue, color: statusColor)
            }

            HStack(spacing: 16) {
                Label(entry.researcher, systemImage: "person")
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(FasterTheme.muted)

                if !entry.startDate.isEmpty {
                    Label("\(entry.startDate) - \(entry.endDate)", systemImage: "calendar")
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundStyle(FasterTheme.muted)
                        .lineLimit(1)
                }
            }

            if !entry.desc.isEmpty {
                Text(entry.desc)
                    .font(.system(size: 12))
                    .foregroundStyle(FasterTheme.muted)
                    .lineLimit(2)
            }

            // Admin approval buttons
            if isAdmin && entry.status == .pendingApproval {
                HStack(spacing: 10) {
                    Button(action: onApprove) {
                        Label("Approve", systemImage: "checkmark")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(.black)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 7)
                            .background(FasterTheme.green)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                    }
                    Button(action: onReject) {
                        Label("Reject", systemImage: "xmark")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 7)
                            .background(FasterTheme.red)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                    }
                    Spacer()
                }
            }

            if !isReadOnly {
                HStack {
                    Spacer()
                    Button { onEdit() } label: {
                        Image(systemName: "pencil")
                            .font(.system(size: 13))
                            .foregroundStyle(FasterTheme.accent)
                    }
                    Button { onDelete() } label: {
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
}

// MARK: - Planning Form

struct PlanningFormView: View {
    @Environment(\.dismiss) var dismiss
    @State var entry: PlanningEntry
    let onSave: (PlanningEntry) -> Void

    var body: some View {
        NavigationStack {
            ZStack {
                FasterTheme.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 14) {
                        FormField(label: "Facility") {
                            TextField("e.g. LPST", text: $entry.facility).fasterInput()
                        }
                        FormField(label: "Experiment Title") {
                            TextField("Title", text: $entry.title).fasterInput()
                        }
                        FormField(label: "Researcher") {
                            TextField("Researcher name", text: $entry.researcher).fasterInput()
                        }
                        FormField(label: "Email") {
                            TextField("Email", text: $entry.email)
                                .keyboardType(.emailAddress)
                                .fasterInput()
                        }
                        FormField(label: "Start Date") {
                            TextField("YYYY-MM-DD", text: $entry.startDate).fasterInput()
                        }
                        FormField(label: "End Date") {
                            TextField("YYYY-MM-DD", text: $entry.endDate).fasterInput()
                        }
                        FormField(label: "Fuel") {
                            TextField("Fuel type", text: $entry.fuel).fasterInput()
                        }
                        FormField(label: "Pressure") {
                            TextField("Pressure spec", text: $entry.pressure).fasterInput()
                        }
                        FormField(label: "Temperature") {
                            TextField("Temperature spec", text: $entry.temp).fasterInput()
                        }
                        FormField(label: "Diagnostic") {
                            TextField("Diagnostic equipment", text: $entry.diag).fasterInput()
                        }
                        FormField(label: "Description") {
                            TextField("Description", text: $entry.desc, axis: .vertical)
                                .lineLimit(3...6)
                                .fasterInput()
                        }
                    }
                    .padding(16)
                }
            }
            .navigationTitle(entry.id.isEmpty ? "New Booking" : "Edit Booking")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }.foregroundStyle(FasterTheme.muted)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        entry.requestedBy = AuthService.shared.currentUsername
                        onSave(entry)
                        dismiss()
                    }
                    .foregroundStyle(FasterTheme.accent)
                    .fontWeight(.bold)
                }
            }
        }
    }
}
