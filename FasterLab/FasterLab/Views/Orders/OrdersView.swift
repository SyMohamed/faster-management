import SwiftUI

struct OrdersView: View {
    @ObservedObject var auth = AuthService.shared
    @State private var orders: [Order] = []
    @State private var searchText = ""
    @State private var filterStatus: Order.OrderStatus?
    @State private var showAddSheet = false
    @State private var editingOrder: Order?
    @State private var observerHandle: UInt?

    var filteredOrders: [Order] {
        var result = orders
        if let filter = filterStatus {
            result = result.filter { $0.status == filter }
        }
        if !searchText.isEmpty {
            let q = searchText.lowercased()
            result = result.filter {
                $0.item.lowercased().contains(q) ||
                $0.requester.lowercased().contains(q) ||
                $0.pr.lowercased().contains(q) ||
                $0.po.lowercased().contains(q)
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
                    TextField("Search orders...", text: $searchText)
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
                        ForEach(Order.OrderStatus.allCases, id: \.self) { status in
                            FilterChip(label: status.rawValue, isActive: filterStatus == status) {
                                filterStatus = status
                            }
                        }
                    }
                }
            }
            .padding(16)

            // Orders list
            if orders.isEmpty {
                Spacer()
                EmptyStateView(icon: "cart", message: "No orders yet")
                Spacer()
            } else if filteredOrders.isEmpty {
                Spacer()
                EmptyStateView(icon: "magnifyingglass", message: "No matching orders")
                Spacer()
            } else {
                ScrollView {
                    LazyVStack(spacing: 10) {
                        ForEach(filteredOrders) { order in
                            OrderCard(order: order, onEdit: {
                                editingOrder = order
                            }, onDelete: {
                                deleteOrder(order)
                            }, isReadOnly: auth.isReadOnly)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 24)
                }
            }
        }
        .background(FasterTheme.background)
        .navigationTitle("Orders")
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
            OrderFormView(order: .constant(Order()), onSave: saveOrder)
                .presentationDetents([.large])
        }
        .sheet(item: $editingOrder) { order in
            OrderFormView(order: .constant(order), onSave: saveOrder)
                .presentationDetents([.large])
        }
        .onAppear { startObserving() }
        .onDisappear { stopObserving() }
    }

    private func startObserving() {
        observerHandle = FirebaseService.shared.observeOrders { newOrders in
            orders = newOrders
        }
    }

    private func stopObserving() {
        if let handle = observerHandle {
            FirebaseService.shared.removeObserver(path: "faster_orders", handle: handle)
        }
    }

    private func saveOrder(_ order: Order) {
        Task {
            try? await FirebaseService.shared.saveOrder(order)
        }
    }

    private func deleteOrder(_ order: Order) {
        Task {
            try? await FirebaseService.shared.deleteOrder(order.id)
        }
    }
}

// MARK: - Order Card

struct OrderCard: View {
    let order: Order
    let onEdit: () -> Void
    let onDelete: () -> Void
    let isReadOnly: Bool

    var statusColor: Color {
        FasterTheme.semanticColor(order.status.color)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(order.item)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(FasterTheme.text)
                        .lineLimit(1)
                    Text(order.requester)
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundStyle(FasterTheme.muted)
                }
                Spacer()
                StatusBadge(text: order.status.rawValue, color: statusColor)
            }

            HStack(spacing: 16) {
                if !order.pr.isEmpty {
                    Label(order.pr, systemImage: "doc.text")
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundStyle(FasterTheme.muted)
                }
                if !order.po.isEmpty {
                    Label(order.po, systemImage: "shippingbox")
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundStyle(FasterTheme.muted)
                }
                if !order.delivery.isEmpty {
                    Label(order.delivery, systemImage: "calendar")
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundStyle(FasterTheme.muted)
                }
            }

            if !isReadOnly {
                HStack(spacing: 12) {
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

// MARK: - Order Form

struct OrderFormView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var order: Order
    let onSave: (Order) -> Void

    @State private var item = ""
    @State private var requester = ""
    @State private var status: Order.OrderStatus = .prSubmitted
    @State private var pr = ""
    @State private var po = ""
    @State private var delivery = ""
    @State private var comments = ""

    var body: some View {
        NavigationStack {
            ZStack {
                FasterTheme.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 14) {
                        FormField(label: "Item / Description") {
                            TextField("Item description", text: $item)
                                .fasterInput()
                        }
                        FormField(label: "Requester") {
                            TextField("Requester name", text: $requester)
                                .fasterInput()
                        }
                        FormField(label: "Status") {
                            Picker("Status", selection: $status) {
                                ForEach(Order.OrderStatus.allCases, id: \.self) { s in
                                    Text(s.rawValue).tag(s)
                                }
                            }
                            .pickerStyle(.segmented)
                        }
                        FormField(label: "PR Number") {
                            TextField("PR number", text: $pr)
                                .fasterInput()
                        }
                        FormField(label: "PO Number") {
                            TextField("PO number", text: $po)
                                .fasterInput()
                        }
                        FormField(label: "Expected Delivery") {
                            TextField("YYYY-MM-DD", text: $delivery)
                                .fasterInput()
                        }
                        FormField(label: "Comments") {
                            TextField("Comments", text: $comments, axis: .vertical)
                                .lineLimit(3...6)
                                .fasterInput()
                        }
                    }
                    .padding(16)
                }
            }
            .navigationTitle(order.id.isEmpty ? "New Order" : "Edit Order")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(FasterTheme.muted)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .foregroundStyle(FasterTheme.accent)
                        .fontWeight(.bold)
                }
            }
            .onAppear { populateFields() }
        }
    }

    private func populateFields() {
        item = order.item
        requester = order.requester
        status = order.status
        pr = order.pr
        po = order.po
        delivery = order.delivery
        comments = order.comments
    }

    private func save() {
        var updated = order
        updated.item = item
        updated.requester = requester
        updated.status = status
        updated.pr = pr
        updated.po = po
        updated.delivery = delivery
        updated.comments = comments
        if updated.created.isEmpty {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            updated.created = formatter.string(from: Date())
        }
        updated.createdBy = AuthService.shared.currentUsername
        updated.addedBy = AuthService.shared.currentUsername
        onSave(updated)
        dismiss()
    }
}

// MARK: - Shared Components

struct FilterChip: View {
    let label: String
    let isActive: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 12, weight: .medium, design: .monospaced))
                .foregroundStyle(isActive ? .black : FasterTheme.muted)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isActive ? FasterTheme.accent : FasterTheme.surface2)
                .clipShape(Capsule())
                .overlay(
                    Capsule().stroke(isActive ? Color.clear : FasterTheme.border1, lineWidth: 1)
                )
        }
    }
}

struct FormField<Content: View>: View {
    let label: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundStyle(FasterTheme.muted)
                .textCase(.uppercase)
            content()
        }
    }
}

struct EmptyStateView: View {
    let icon: String
    let message: String

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 36))
                .foregroundStyle(FasterTheme.muted2)
            Text(message)
                .font(.system(size: 14))
                .foregroundStyle(FasterTheme.muted)
        }
    }
}
