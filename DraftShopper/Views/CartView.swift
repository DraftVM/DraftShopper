import SwiftUI
import SwiftData

struct CartView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AppRouter.self) private var router
    @Query(sort: \CartItem.addedAt, order: .reverse) private var items: [CartItem]
    @State private var path = NavigationPath()

    private var subtotal: Double { items.reduce(0) { $0 + $1.lineTotal } }
    private var itemCount: Int { items.reduce(0) { $0 + $1.quantity } }

    var body: some View {
        NavigationStack(path: $path) {
            Group {
                if items.isEmpty {
                    emptyState
                } else {
                    bagList
                }
            }
            .navigationTitle("Bag")
            .navigationDestination(for: CheckoutRoute.self) { _ in
                CheckoutView(onFinish: { path = NavigationPath() })
            }
            .shopDestinations()
        }
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label("Your Bag Is Empty", systemImage: "bag")
        } description: {
            Text("Items you add will show up here.")
        } actions: {
            Button("Start Shopping") { router.selectedTab = .home }
                .buttonStyle(.glassProminent)
        }
    }

    private var bagList: some View {
        List {
            if subtotal < Pricing.freeShippingThreshold {
                FreeShippingProgress(subtotal: subtotal)
            }

            Section {
                ForEach(items) { item in
                    CartRow(item: item)
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button("Remove", systemImage: "trash", role: .destructive) {
                                withAnimation { modelContext.delete(item) }
                            }
                        }
                        .swipeActions(edge: .leading) {
                            if let product = item.product {
                                Button("Save for Later", systemImage: "heart") {
                                    withAnimation {
                                        product.isFavorite = true
                                        modelContext.delete(item)
                                    }
                                }
                                .tint(Theme.coral)
                            }
                        }
                }
            } header: {
                Text("\(itemCount) \(itemCount == 1 ? "Item" : "Items")")
            }

            Section("Summary") {
                SummaryRow(title: "Subtotal", value: subtotal)
                SummaryRow(
                    title: "Shipping",
                    value: DeliveryMethod.standard.cost(forSubtotal: subtotal),
                    note: "Standard"
                )
                SummaryRow(title: "Estimated Tax", value: Pricing.tax(on: subtotal))
                SummaryRow(
                    title: "Estimated Total",
                    value: subtotal + DeliveryMethod.standard.cost(forSubtotal: subtotal) + Pricing.tax(on: subtotal),
                    isEmphasized: true
                )
            }
        }
        .safeAreaBar(edge: .bottom) {
            NavigationLink(value: CheckoutRoute()) {
                Text("Checkout")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.glassProminent)
            .controlSize(.large)
            .padding(.horizontal)
            .padding(.vertical, 10)
        }
    }
}

struct CheckoutRoute: Hashable {}

private struct FreeShippingProgress: View {
    let subtotal: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label {
                Text("Add **\((Pricing.freeShippingThreshold - subtotal).currency)** more for free shipping")
            } icon: {
                Image(systemName: "shippingbox.fill").foregroundStyle(Theme.coral)
            }
            .font(.subheadline)
            ProgressView(value: subtotal, total: Pricing.freeShippingThreshold)
                .tint(Theme.coral)
        }
        .padding(.vertical, 4)
    }
}

private struct CartRow: View {
    @Bindable var item: CartItem

    var body: some View {
        if let product = item.product {
            HStack(alignment: .top, spacing: 14) {
                ProductImage(name: product.imageName, cornerRadius: 12)
                    .frame(width: 84, height: 84)

                VStack(alignment: .leading, spacing: 4) {
                    Text(product.name)
                        .font(.subheadline.weight(.semibold))
                        .lineLimit(2)
                    if let options = item.optionsSummary {
                        Text(options)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    HStack {
                        PriceView(price: item.lineTotal, font: .subheadline)
                        Spacer()
                        QuantityControl(quantity: $item.quantity, maximum: max(1, min(10, product.stock)))
                    }
                    .padding(.top, 4)
                }
            }
            .padding(.vertical, 4)
        }
    }
}

/// Compact − / + control for bag rows.
private struct QuantityControl: View {
    @Binding var quantity: Int
    let maximum: Int

    var body: some View {
        HStack(spacing: 0) {
            Button("Decrease", systemImage: "minus") { quantity -= 1 }
                .disabled(quantity <= 1)
            Text("\(quantity)")
                .font(.subheadline.monospacedDigit().weight(.semibold))
                .frame(minWidth: 26)
                .contentTransition(.numericText())
            Button("Increase", systemImage: "plus") { quantity += 1 }
                .disabled(quantity >= maximum)
        }
        .labelStyle(.iconOnly)
        .buttonStyle(.borderless)
        .font(.caption.weight(.bold))
        .frame(height: 32)
        .padding(.horizontal, 6)
        .background(Theme.surface, in: .capsule)
        .animation(.snappy, value: quantity)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Quantity")
        .accessibilityValue("\(quantity)")
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment: if quantity < maximum { quantity += 1 }
            case .decrement: if quantity > 1 { quantity -= 1 }
            @unknown default: break
            }
        }
    }
}

struct SummaryRow: View {
    let title: String
    let value: Double
    var note: String?
    var isNegative = false
    var isEmphasized = false

    var body: some View {
        HStack {
            Text(title)
            if let note {
                Text(note).foregroundStyle(.secondary)
            }
            Spacer()
            if value == 0 && title == "Shipping" {
                Text("Free").foregroundStyle(.green)
            } else {
                Text(isNegative ? "−\(value.currency)" : value.currency)
                    .foregroundStyle(isNegative ? Color.green : Color.primary)
                    .monospacedDigit()
            }
        }
        .font(isEmphasized ? .headline : .subheadline)
    }
}

#Preview {
    CartView()
        .environment(AppRouter())
        .modelContainer(PreviewSupport.container)
        .tint(Theme.accent)
}
