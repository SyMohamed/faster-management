import SwiftUI

struct AssetsView: View {
    @ObservedObject var auth = AuthService.shared
    @State private var assets: [Asset] = []
    @State private var searchText = ""
    @State private var filterCategory: Asset.AssetCategory?
    @State private var showAddSheet = false
    @State private var editingAsset: Asset?
    @State private var observerHandle: UInt?

    var filteredAssets: [Asset] {
        var result = assets
        if let cat = filterCategory {
            result = result.filter { $0.category == cat }
        }
        if !searchText.isEmpty {
            let q = searchText.lowercased()
            result = result.filter {
                $0.category.displayName.lowercased().contains(q) ||
                $0.notes.lowercased().contains(q) ||
                $0.fields.values.contains { $0.lowercased().contains(q) }
            }
        }
        return result
    }

    var body: some View {
        VStack(spacing: 0) {
            // Search
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(FasterTheme.muted)
                TextField("Search assets...", text: $searchText)
                    .foregroundStyle(FasterTheme.text)
            }
            .padding(10)
            .background(FasterTheme.surface2)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .padding(.horizontal, 16)
            .padding(.top, 12)

            // Category filter
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    FilterChip(label: "All", isActive: filterCategory == nil) {
                        filterCategory = nil
                    }
                    ForEach(Asset.AssetCategory.allCases, id: \.self) { cat in
                        FilterChip(label: cat.displayName, isActive: filterCategory == cat) {
                            filterCategory = cat
                        }
                    }
                }
                .padding(.horizontal, 16)
            }
            .padding(.top, 10)

            // List
            if filteredAssets.isEmpty {
                Spacer()
                EmptyStateView(icon: "wrench.and.screwdriver", message: assets.isEmpty ? "No assets registered" : "No matching assets")
                Spacer()
            } else {
                ScrollView {
                    LazyVStack(spacing: 10) {
                        ForEach(filteredAssets) { asset in
                            AssetCard(asset: asset, onEdit: {
                                editingAsset = asset
                            }, onDelete: {
                                Task { try? await FirebaseService.shared.deleteAsset(asset.id) }
                            }, isReadOnly: auth.isReadOnly)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }
            }
        }
        .background(FasterTheme.background)
        .navigationTitle("Assets")
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
            AssetFormView(asset: Asset()) { asset in
                Task { try? await FirebaseService.shared.saveAsset(asset) }
            }
            .presentationDetents([.large])
        }
        .sheet(item: $editingAsset) { asset in
            AssetFormView(asset: asset) { updated in
                Task { try? await FirebaseService.shared.saveAsset(updated) }
            }
            .presentationDetents([.large])
        }
        .onAppear { startObserving() }
        .onDisappear { stopObserving() }
    }

    private func startObserving() {
        observerHandle = FirebaseService.shared.observeAssets { assets = $0 }
    }

    private func stopObserving() {
        if let handle = observerHandle {
            FirebaseService.shared.removeObserver(path: "faster_assets_v5", handle: handle)
        }
    }
}

// MARK: - Asset Card

struct AssetCard: View {
    let asset: Asset
    let onEdit: () -> Void
    let onDelete: () -> Void
    let isReadOnly: Bool

    var statusColor: Color {
        FasterTheme.semanticColor(asset.status.color)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: asset.category.icon)
                    .font(.system(size: 18))
                    .foregroundStyle(FasterTheme.accent)
                    .frame(width: 36, height: 36)
                    .background(FasterTheme.surface2)
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                VStack(alignment: .leading, spacing: 2) {
                    Text(asset.category.displayName)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(FasterTheme.text)
                    Text(asset.id)
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundStyle(FasterTheme.muted2)
                        .lineLimit(1)
                }

                Spacer()
                StatusBadge(text: asset.status.rawValue, color: statusColor)
            }

            if !asset.notes.isEmpty {
                Text(asset.notes)
                    .font(.system(size: 12))
                    .foregroundStyle(FasterTheme.muted)
                    .lineLimit(2)
            }

            // Dynamic fields preview
            let fieldKeys = Array(asset.fields.keys.prefix(3))
            if !fieldKeys.isEmpty {
                HStack(spacing: 12) {
                    ForEach(fieldKeys, id: \.self) { key in
                        Text("\(key): \(asset.fields[key] ?? "")")
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundStyle(FasterTheme.muted)
                            .lineLimit(1)
                    }
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

// MARK: - Asset Form

struct AssetFormView: View {
    @Environment(\.dismiss) var dismiss
    @State var asset: Asset
    let onSave: (Asset) -> Void

    var body: some View {
        NavigationStack {
            ZStack {
                FasterTheme.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 14) {
                        FormField(label: "Category") {
                            Picker("Category", selection: $asset.category) {
                                ForEach(Asset.AssetCategory.allCases, id: \.self) { cat in
                                    Text(cat.displayName).tag(cat)
                                }
                            }
                            .pickerStyle(.segmented)
                        }

                        FormField(label: "Status") {
                            Picker("Status", selection: $asset.status) {
                                ForEach(Asset.AssetStatus.allCases, id: \.self) { s in
                                    Text(s.rawValue).tag(s)
                                }
                            }
                            .pickerStyle(.segmented)
                        }

                        FormField(label: "Notes") {
                            TextField("Notes", text: $asset.notes, axis: .vertical)
                                .lineLimit(3...6)
                                .fasterInput()
                        }
                    }
                    .padding(16)
                }
            }
            .navigationTitle(asset.id.isEmpty ? "New Asset" : "Edit Asset")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }.foregroundStyle(FasterTheme.muted)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(asset)
                        dismiss()
                    }
                    .foregroundStyle(FasterTheme.accent)
                    .fontWeight(.bold)
                }
            }
        }
    }
}
