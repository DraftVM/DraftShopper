import SwiftUI
import SwiftData

struct CheckoutView: View {
    /// Called after the confirmation is dismissed so the bag can pop back to its root.
    let onFinish: () -> Void

    @Environment(\.modelContext) private var modelContext
    @Environment(AppRouter.self) private var router
    @Query(sort: \CartItem.addedAt, order: .reverse) private var items: [CartItem]
    @AppStorage(StorageKey.userName) private var userName = ""
    @AppStorage(StorageKey.shippingAddress) private var savedAddress = "1 Infinite Loop, Cupertino, CA 95014"

    @State private var address = ""
    @State private var delivery: DeliveryMethod = .standard
    @State private var payment: PaymentMethod = .applePay
    @State private var promoInput = ""
    @State private var appliedPromo = ""
    @State private var promoMessage: String?
    @State private var isPlacing = false
    @State private var placedOrder: CustomerOrder?

    private var subtotal: Double { items.reduce(0) { $0 + $1.lineTotal } }
    private var discount: Double { Pricing.discount(for: appliedPromo, subtotal: subtotal) }
    private var shipping: Double { delivery.cost(forSubtotal: subtotal) }
    private var tax: Double { Pricing.tax(on: subtotal - discount) }
    private var total: Double { subtotal - discount + shipping + tax }

    var body: some View {
        Form {
            Section("Ship To") {
                VStack(alignment: .leading, spacing: 4) {
                    Text(userName.isEmpty ? "Recipient" : userName)
                        .font(.subheadline.weight(.semibold))
                    TextField("Street, City, State ZIP", text: $address, axis: .vertical)
                        .textContentType(.fullStreetAddress)
                        .lineLimit(2...4)
                }
            }

            Section("Delivery") {
                Picker("Delivery", selection: $delivery) {
                    ForEach(DeliveryMethod.allCases) { method in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(method.title)
                                Text(method.estimate)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            let cost = method.cost(forSubtotal: subtotal)
                            Text(cost == 0 ? "Free" : cost.currency)
                                .foregroundStyle(.secondary)
                        }
                        .tag(method)
                    }
                }
                .pickerStyle(.inline)
                .labelsHidden()
            }

            Section("Payment") {
                Picker("Payment", selection: $payment) {
                    ForEach(PaymentMethod.allCases) { method in
                        Label(method.title, systemImage: method.symbolName).tag(method)
                    }
                }
                .pickerStyle(.inline)
                .labelsHidden()
            }

            Section {
                HStack {
                    TextField("Promo code", text: $promoInput)
                        .autocorrectionDisabled()
                        #if os(iOS)
                        .textInputAutocapitalization(.characters)
                        #endif
                        .onSubmit(applyPromo)
                    Button("Apply", action: applyPromo)
                        .disabled(promoInput.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            } header: {
                Text("Promo Code")
            } footer: {
                if let promoMessage {
                    Text(promoMessage)
                        .foregroundStyle(discount > 0 ? .green : .red)
                } else {
                    Text("Try DRAFT10 or WELCOME15.")
                }
            }

            Section("Order Summary") {
                ForEach(items) { item in
                    if let product = item.product {
                        HStack {
                            Text("\(item.quantity)×")
                                .foregroundStyle(.secondary)
                                .monospacedDigit()
                            Text(product.name)
                                .lineLimit(1)
                            Spacer()
                            Text(item.lineTotal.currency)
                                .monospacedDigit()
                        }
                        .font(.subheadline)
                    }
                }
                SummaryRow(title: "Subtotal", value: subtotal)
                if discount > 0 {
                    SummaryRow(title: "Promo", value: discount, note: appliedPromo.uppercased(), isNegative: true)
                }
                SummaryRow(title: "Shipping", value: shipping)
                SummaryRow(title: "Tax", value: tax)
                SummaryRow(title: "Total", value: total, isEmphasized: true)
            }
        }
        .navigationTitle("Checkout")
        .inlineNavigationTitle()
        .safeAreaBar(edge: .bottom) {
            Button(action: placeOrder) {
                Group {
                    if isPlacing {
                        ProgressView()
                    } else {
                        Text("Place Order · \(total.currency)")
                    }
                }
                .font(.headline)
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.glassProminent)
            .controlSize(.large)
            .disabled(isPlacing || items.isEmpty || address.trimmingCharacters(in: .whitespaces).isEmpty)
            .padding(.horizontal)
            .padding(.vertical, 10)
        }
        .onAppear {
            if address.isEmpty { address = savedAddress }
        }
        .sensoryFeedback(.success, trigger: placedOrder)
        .sheet(item: $placedOrder, onDismiss: onFinish) { order in
            OrderConfirmationView(order: order) {
                placedOrder = nil
            } onViewOrders: {
                placedOrder = nil
                router.selectedTab = .orders
            }
            .interactiveDismissDisabled()
        }
    }

    private func applyPromo() {
        let code = promoInput.trimmingCharacters(in: .whitespaces).uppercased()
        withAnimation {
            if Pricing.promoCodes[code] != nil {
                appliedPromo = code
                promoMessage = "\(code) applied. You saved \(Pricing.discount(for: code, subtotal: subtotal).currency)."
            } else {
                appliedPromo = ""
                promoMessage = "That code isn't valid."
            }
        }
    }

    private func placeOrder() {
        isPlacing = true
        let trimmedAddress = address.trimmingCharacters(in: .whitespacesAndNewlines)
        savedAddress = trimmedAddress
        Task {
            // Simulate payment authorization.
            try? await Task.sleep(for: .seconds(1))
            let order = modelContext.placeOrder(
                items: items, promoCode: appliedPromo, delivery: delivery,
                payment: payment, address: trimmedAddress
            )
            try? modelContext.save()
            isPlacing = false
            placedOrder = order
        }
    }
}

struct OrderConfirmationView: View {
    let order: CustomerOrder
    let onContinue: () -> Void
    let onViewOrders: () -> Void

    @State private var appeared = false

    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 84))
                .foregroundStyle(Theme.accent)
                .symbolEffect(.bounce, value: appeared)
            VStack(spacing: 8) {
                Text("Order Placed!")
                    .font(.largeTitle.weight(.bold))
                    .foregroundStyle(Theme.ink)
                Text("Thanks for shopping with Draft Shoppr. We'll let you know when order \(order.number) ships.")
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
            }
            VStack(spacing: 10) {
                infoRow("Order", order.number)
                infoRow("Items", "\(order.itemCount)")
                infoRow("Total", order.total.currency)
                infoRow("Delivery", order.deliveryMethod)
            }
            .padding()
            .background(Theme.surface, in: .rect(cornerRadius: 16, style: .continuous))
            Spacer()
            VStack(spacing: 12) {
                Button(action: onViewOrders) {
                    Text("View Orders").font(.headline).frame(maxWidth: .infinity)
                }
                .buttonStyle(.glassProminent)
                Button(action: onContinue) {
                    Text("Continue Shopping").font(.headline).frame(maxWidth: .infinity)
                }
                .buttonStyle(.glass)
            }
            .controlSize(.large)
        }
        .padding(24)
        .onAppear { appeared = true }
    }

    private func infoRow(_ title: String, _ value: String) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title).foregroundStyle(.secondary)
            Spacer()
            Text(value).fontWeight(.semibold).multilineTextAlignment(.trailing)
        }
        .font(.subheadline)
    }
}

#Preview {
    NavigationStack {
        CheckoutView(onFinish: {})
    }
    .environment(AppRouter())
    .modelContainer(PreviewSupport.container)
    .tint(Theme.accent)
}
