import SwiftUI

struct ChemicalsView: View {
    @ObservedObject var auth = AuthService.shared
    @State private var chemicals: [Chemical] = []
    @State private var searchText = ""
    @State private var filterLocation = "All"
    @State private var showAddSheet = false
    @State private var editingChemical: Chemical?
    @State private var observerHandle: UInt?

    var locations: [String] {
        let locs = Set(chemicals.map { $0.location }).filter { !$0.isEmpty }
        return ["All"] + locs.sorted()
    }

    var filteredChemicals: [Chemical] {
        var result = chemicals
        if filterLocation != "All" {
            result = result.filter { $0.location == filterLocation }
        }
        if !searchText.isEmpty {
            let q = searchText.lowercased()
            result = result.filter {
                $0.name.lowercased().contains(q) ||
                $0.cas.lowercased().contains(q) ||
                $0.owner.lowercased().contains(q)
            }
        }
        return result
    }

    var expiringCount: Int {
        chemicals.filter { $0.isExpiringSoon }.count
    }

    var body: some View {
        VStack(spacing: 0) {
            // Expiry alert
            if expiringCount > 0 {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(FasterTheme.amber)
                    Text("\(expiringCount) chemical\(expiringCount == 1 ? "" : "s") expiring within 30 days")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(FasterTheme.amber)
                    Spacer()
                }
                .padding(12)
                .background(FasterTheme.amber.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .padding(.horizontal, 16)
                .padding(.top, 8)
            }

            // Search
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(FasterTheme.muted)
                TextField("Search chemicals...", text: $searchText)
                    .foregroundStyle(FasterTheme.text)
            }
            .padding(10)
            .background(FasterTheme.surface2)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .padding(.horizontal, 16)
            .padding(.top, 12)

            // Location filter
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(locations, id: \.self) { loc in
                        FilterChip(label: loc, isActive: filterLocation == loc) {
                            filterLocation = loc
                        }
                    }
                }
                .padding(.horizontal, 16)
            }
            .padding(.top, 10)

            // List
            if filteredChemicals.isEmpty {
                Spacer()
                EmptyStateView(icon: "flask", message: chemicals.isEmpty ? "No chemicals registered" : "No matching chemicals")
                Spacer()
            } else {
                ScrollView {
                    LazyVStack(spacing: 10) {
                        ForEach(filteredChemicals) { chem in
                            ChemicalCard(chemical: chem, onEdit: {
                                editingChemical = chem
                            }, onDelete: {
                                Task { try? await FirebaseService.shared.deleteChemical(chem.id) }
                            }, isReadOnly: auth.isReadOnly)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }
            }
        }
        .background(FasterTheme.background)
        .navigationTitle("Chemicals")
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
            ChemicalFormView(chemical: Chemical()) { chem in
                Task { try? await FirebaseService.shared.saveChemical(chem) }
            }
            .presentationDetents([.large])
        }
        .sheet(item: $editingChemical) { chem in
            ChemicalFormView(chemical: chem) { updated in
                Task { try? await FirebaseService.shared.saveChemical(updated) }
            }
            .presentationDetents([.large])
        }
        .onAppear { startObserving() }
        .onDisappear { stopObserving() }
    }

    private func startObserving() {
        observerHandle = FirebaseService.shared.observeChemicals { chemicals = $0 }
    }

    private func stopObserving() {
        if let handle = observerHandle {
            FirebaseService.shared.removeObserver(path: "faster_chemicals", handle: handle)
        }
    }
}

// MARK: - Chemical Card

struct ChemicalCard: View {
    let chemical: Chemical
    let onEdit: () -> Void
    let onDelete: () -> Void
    let isReadOnly: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(chemical.name)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(FasterTheme.text)
                        .lineLimit(1)
                    if !chemical.cas.isEmpty {
                        Text("CAS: \(chemical.cas)")
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundStyle(FasterTheme.muted)
                    }
                }
                Spacer()

                if chemical.isExpired {
                    StatusBadge(text: "Expired", color: FasterTheme.red)
                } else if chemical.isExpiringSoon {
                    StatusBadge(text: "Expiring Soon", color: FasterTheme.amber)
                } else {
                    StatusBadge(text: chemical.status, color: FasterTheme.green)
                }
            }

            HStack(spacing: 16) {
                if !chemical.location.isEmpty {
                    Label(chemical.location, systemImage: "mappin")
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundStyle(FasterTheme.muted)
                }
                if !chemical.qty.isEmpty {
                    Label(chemical.qty, systemImage: "scalemass")
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundStyle(FasterTheme.muted)
                }
                if !chemical.owner.isEmpty {
                    Label(chemical.owner, systemImage: "person")
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundStyle(FasterTheme.muted)
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

// MARK: - Chemical Form

struct ChemicalFormView: View {
    @Environment(\.dismiss) var dismiss
    @State var chemical: Chemical
    let onSave: (Chemical) -> Void

    var body: some View {
        NavigationStack {
            ZStack {
                FasterTheme.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 14) {
                        FormField(label: "Chemical Name") {
                            TextField("Name", text: $chemical.name).fasterInput()
                        }
                        FormField(label: "CAS Number") {
                            TextField("CAS #", text: $chemical.cas).fasterInput()
                        }
                        FormField(label: "Location") {
                            TextField("Storage location", text: $chemical.location).fasterInput()
                        }
                        FormField(label: "Quantity") {
                            TextField("Quantity", text: $chemical.qty).fasterInput()
                        }
                        FormField(label: "Purity") {
                            TextField("Purity %", text: $chemical.purity).fasterInput()
                        }
                        FormField(label: "Owner") {
                            TextField("Owner name", text: $chemical.owner).fasterInput()
                        }
                        FormField(label: "Owner Email") {
                            TextField("Email", text: $chemical.ownerEmail)
                                .keyboardType(.emailAddress)
                                .fasterInput()
                        }
                        FormField(label: "Date Received") {
                            TextField("YYYY-MM-DD", text: $chemical.dateReceived).fasterInput()
                        }
                        FormField(label: "Expiry Date") {
                            TextField("YYYY-MM-DD", text: $chemical.expiryDate).fasterInput()
                        }
                        FormField(label: "Notes") {
                            TextField("Notes", text: $chemical.notes, axis: .vertical)
                                .lineLimit(3...6)
                                .fasterInput()
                        }
                    }
                    .padding(16)
                }
            }
            .navigationTitle(chemical.id.isEmpty ? "New Chemical" : "Edit Chemical")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }.foregroundStyle(FasterTheme.muted)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(chemical)
                        dismiss()
                    }
                    .foregroundStyle(FasterTheme.accent)
                    .fontWeight(.bold)
                }
            }
        }
    }
}
