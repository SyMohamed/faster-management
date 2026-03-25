import SwiftUI

struct GuideView: View {
    @ObservedObject var auth = AuthService.shared
    @State private var categories: [GuideCategory] = []
    @State private var docs: [String: [GuideDocument]] = [:]
    @State private var expandedCategory: String?
    @State private var catHandle: UInt?
    @State private var docHandles: [String: UInt] = [:]

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                // Header info
                VStack(spacing: 6) {
                    Text("KNOWLEDGE BASE")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundStyle(FasterTheme.accent)
                        .tracking(2)

                    Text("SOPs, manuals, and reference docs")
                        .font(.system(size: 13))
                        .foregroundStyle(FasterTheme.muted)
                }
                .padding(.vertical, 8)

                if categories.isEmpty {
                    EmptyStateView(icon: "book", message: "No guide categories yet")
                        .padding(.top, 40)
                } else {
                    ForEach(categories) { category in
                        GuideCategoryCard(
                            category: category,
                            documents: docs[category.id] ?? [],
                            isExpanded: expandedCategory == category.id,
                            onToggle: {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    if expandedCategory == category.id {
                                        expandedCategory = nil
                                    } else {
                                        expandedCategory = category.id
                                        loadDocs(for: category.id)
                                    }
                                }
                            }
                        )
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
        }
        .background(FasterTheme.background)
        .navigationTitle("Guide")
        .onAppear { startObserving() }
        .onDisappear { stopObserving() }
    }

    private func startObserving() {
        catHandle = FirebaseService.shared.observeGuideCategories { newCats in
            categories = newCats
        }
    }

    private func loadDocs(for categoryId: String) {
        guard docHandles[categoryId] == nil else { return }
        let handle = FirebaseService.shared.observeGuideDocs(categoryId: categoryId) { newDocs in
            docs[categoryId] = newDocs
        }
        docHandles[categoryId] = handle
    }

    private func stopObserving() {
        if let handle = catHandle {
            FirebaseService.shared.removeObserver(path: "faster_guide/categories", handle: handle)
        }
        for (catId, handle) in docHandles {
            FirebaseService.shared.removeObserver(path: "faster_guide/docs/\(catId)", handle: handle)
        }
    }
}

// MARK: - Guide Category Card

struct GuideCategoryCard: View {
    let category: GuideCategory
    let documents: [GuideDocument]
    let isExpanded: Bool
    let onToggle: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Header
            Button(action: onToggle) {
                HStack(spacing: 12) {
                    Text(category.icon)
                        .font(.system(size: 22))
                        .frame(width: 40, height: 40)
                        .background(Color(hex: category.color).opacity(0.15))
                        .clipShape(RoundedRectangle(cornerRadius: 10))

                    VStack(alignment: .leading, spacing: 2) {
                        Text(category.name)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(FasterTheme.text)
                        Text("\(documents.count) document\(documents.count == 1 ? "" : "s")")
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundStyle(FasterTheme.muted)
                    }

                    Spacer()

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(FasterTheme.muted)
                }
                .padding(16)
            }
            .buttonStyle(.plain)

            // Expanded documents
            if isExpanded {
                Divider().background(FasterTheme.border1)

                if documents.isEmpty {
                    Text("No documents in this category")
                        .font(.system(size: 12))
                        .foregroundStyle(FasterTheme.muted)
                        .padding(16)
                } else {
                    VStack(spacing: 0) {
                        ForEach(documents) { doc in
                            GuideDocRow(document: doc)
                            if doc.id != documents.last?.id {
                                Divider()
                                    .background(FasterTheme.border1)
                                    .padding(.leading, 50)
                            }
                        }
                    }
                }
            }
        }
        .fasterCard()
    }
}

// MARK: - Guide Document Row

struct GuideDocRow: View {
    let document: GuideDocument

    var body: some View {
        Button {
            if let url = URL(string: document.link), !document.link.isEmpty {
                UIApplication.shared.open(url)
            }
        } label: {
            HStack(spacing: 12) {
                Text(document.icon)
                    .font(.system(size: 16))
                    .frame(width: 28)

                VStack(alignment: .leading, spacing: 2) {
                    Text(document.title)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(FasterTheme.text)
                        .lineLimit(1)

                    if !document.description.isEmpty {
                        Text(document.description)
                            .font(.system(size: 11))
                            .foregroundStyle(FasterTheme.muted)
                            .lineLimit(1)
                    }
                }

                Spacer()

                if !document.link.isEmpty {
                    Image(systemName: "arrow.up.right")
                        .font(.system(size: 11))
                        .foregroundStyle(FasterTheme.muted2)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
        .buttonStyle(.plain)
    }
}
