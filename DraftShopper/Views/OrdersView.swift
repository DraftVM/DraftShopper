import SwiftUI
import SwiftData

struct OrdersView: View {
    @Environment(AppRouter.self) private var router
    @Query(sort: \CustomerOrder.placedAt, order: .reverse) private var orders: [CustomerOrder]

    var body: some View {
        NavigationStack {
            Group {
                if orders.isEmpty {
                    ContentUnavailableView {
                        Label("No Orders Yet", systemImage: "shippingbox")
                    } description: {
                        Text("When you place an order, you can track it here.")
                    } actions: {
                        Button("Start Shopping") { router.selectedTab = .home }
                            .buttonStyle(.glassProminent)
                    }
                } else {
                    List(orders) { order in
                        NavigationLink(value: order) {
                            OrderRow(order: order)
                        }
                    }
                }
            }
            .navigationTitle("Orders")
            .navigationDestination(for: CustomerOrder.self) { OrderDetailView(order: $0) }
            .shopDestinations()
        }
    }
}

private struct OrderRow: View {
    let order: CustomerOrder

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Order \(order.number)")
                        .font(.subheadline.weight(.semibold))
                    Text(order.placedAt, format: .dateTime.month(.abbreviated).day().year())
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                StatusBadge(status: order.status)
            }
            HStack(spacing: -10) {
                ForEach(order.sortedLines.prefix(4)) { line in
                    ProductImage(name: line.imageName, cornerRadius: 10)
                        .frame(width: 46, height: 46)
                        .overlay {
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .strokeBorder(.background, lineWidth: 2)
                        }
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text(order.total.currency)
                        .font(.subheadline.weight(.bold))
                    Text("\(order.itemCount) \(order.itemCount == 1 ? "item" : "items")")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
    }
}

struct StatusBadge: View {
    let status: OrderStatus

    private var tint: Color {
        switch status {
        case .processing: .orange
        case .shipped, .outForDelivery: Theme.accent
        case .delivered: .green
        }
    }

    var body: some View {
        Label(status.title, systemImage: status.symbolName)
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .foregroundStyle(tint)
            .background(tint.opacity(0.14), in: .capsule)
    }
}

struct OrderDetailView: View {
    let order: CustomerOrder

    @Environment(\.modelContext) private var modelContext
    @Environment(AppRouter.self) private var router
    @State private var showingHelp = false
    @State private var boughtAgain = 0

    var body: some View {
        List {
            Section {
                OrderTimeline(status: order.status)
                    .padding(.vertical, 6)
            } header: {
                Text("Placed \(order.placedAt.formatted(date: .long, time: .shortened))")
            }

            Section("Items") {
                ForEach(order.sortedLines) { line in
                    HStack(spacing: 14) {
                        ProductImage(name: line.imageName, cornerRadius: 12)
                            .frame(width: 60, height: 60)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(line.name)
                                .font(.subheadline.weight(.medium))
                            Text(line.brand)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            if let options = line.optionsSummary {
                                Text(options)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 2) {
                            Text((line.price * Double(line.quantity)).currency)
                                .font(.subheadline.weight(.semibold))
                            Text("Qty \(line.quantity)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }

            Section("Delivery") {
                LabeledContent("Ship To", value: order.shippingAddress)
                LabeledContent("Method", value: order.deliveryMethod)
                LabeledContent("Payment", value: order.paymentMethod)
            }

            Section("Summary") {
                SummaryRow(title: "Subtotal", value: order.subtotal)
                if order.discount > 0 {
                    SummaryRow(title: "Promo", value: order.discount, isNegative: true)
                }
                SummaryRow(title: "Shipping", value: order.shipping)
                SummaryRow(title: "Tax", value: order.tax)
                SummaryRow(title: "Total", value: order.total, isEmphasized: true)
            }

            Section {
                Button("Buy Again", systemImage: "arrow.clockwise") {
                    modelContext.buyAgain(order)
                    boughtAgain += 1
                    router.selectedTab = .bag
                }
                Button("Get Help with This Order", systemImage: "questionmark.circle") {
                    showingHelp = true
                }
            }
        }
        .navigationTitle(order.number)
        .inlineNavigationTitle()
        .sensoryFeedback(.success, trigger: boughtAgain)
        .alert("We're Here to Help", isPresented: $showingHelp) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Support is reachable at help@draftshoppr.app. (This is a demo, so no messages are sent.)")
        }
    }
}

/// Horizontal step tracker: Processing → Shipped → Out for Delivery → Delivered.
private struct OrderTimeline: View {
    let status: OrderStatus

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label(status.title, systemImage: status.symbolName)
                .font(.headline)
                .foregroundStyle(Theme.accent)
            HStack(spacing: 0) {
                ForEach(OrderStatus.allCases, id: \.self) { step in
                    let reached = step.step <= status.step
                    Circle()
                        .fill(reached ? Theme.accent : Color.secondary.opacity(0.3))
                        .frame(width: 12, height: 12)
                    if step != OrderStatus.allCases.last {
                        Capsule()
                            .fill(step.step < status.step ? Theme.accent : Color.secondary.opacity(0.3))
                            .frame(height: 3)
                    }
                }
            }
            HStack {
                ForEach(OrderStatus.allCases, id: \.self) { step in
                    Text(step.title)
                        .font(.caption2)
                        .foregroundStyle(step.step <= status.step ? .primary : .secondary)
                        .frame(maxWidth: .infinity, alignment: alignment(for: step))
                        .multilineTextAlignment(textAlignment(for: step))
                }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Order status: \(status.title)")
    }

    private func alignment(for step: OrderStatus) -> Alignment {
        switch step {
        case .processing: .leading
        case .delivered: .trailing
        default: .center
        }
    }

    private func textAlignment(for step: OrderStatus) -> TextAlignment {
        switch step {
        case .processing: .leading
        case .delivered: .trailing
        default: .center
        }
    }
}

#Preview {
    OrdersView()
        .environment(AppRouter())
        .modelContainer(PreviewSupport.container)
        .tint(Theme.accent)
}
