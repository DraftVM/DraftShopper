import Foundation
import SwiftData

enum DeliveryMethod: String, CaseIterable, Identifiable {
    case standard, express

    var id: String { rawValue }

    var title: String {
        switch self {
        case .standard: "Standard"
        case .express: "Express"
        }
    }

    var estimate: String {
        switch self {
        case .standard: "3–5 business days"
        case .express: "1–2 business days"
        }
    }

    func cost(forSubtotal subtotal: Double) -> Double {
        switch self {
        case .standard: subtotal >= Pricing.freeShippingThreshold || subtotal == 0 ? 0 : 6.99
        case .express: 14.99
        }
    }
}

enum PaymentMethod: String, CaseIterable, Identifiable {
    case applePay, visa, mastercard

    var id: String { rawValue }

    var title: String {
        switch self {
        case .applePay: "Apple Pay"
        case .visa: "Visa •••• 4242"
        case .mastercard: "Mastercard •••• 8810"
        }
    }

    var symbolName: String {
        switch self {
        case .applePay: "apple.logo"
        case .visa, .mastercard: "creditcard"
        }
    }
}

/// Order math shared by the bag, checkout, and order history.
enum Pricing {
    static let freeShippingThreshold = 75.0
    static let taxRate = 0.0825

    /// Demo promo codes and the fraction of the subtotal they take off.
    static let promoCodes: [String: Double] = ["DRAFT10": 0.10, "WELCOME15": 0.15]

    static func discount(for code: String, subtotal: Double) -> Double {
        guard let rate = promoCodes[code.uppercased().trimmingCharacters(in: .whitespaces)] else { return 0 }
        return (subtotal * rate * 100).rounded() / 100
    }

    static func tax(on amount: Double) -> Double {
        (max(amount, 0) * taxRate * 100).rounded() / 100
    }
}

extension Double {
    var currency: String { formatted(.currency(code: "USD")) }
}

// MARK: - Cart & order actions

extension ModelContext {
    /// Adds a product to the bag, merging with an existing line that has the same options.
    func addToCart(_ product: Product, quantity: Int = 1, size: String? = nil, color: String? = nil) {
        let existing = (try? fetch(FetchDescriptor<CartItem>())) ?? []
        if let match = existing.first(where: { $0.product?.id == product.id && $0.size == size && $0.color == color }) {
            match.quantity = min(match.quantity + quantity, 10)
        } else {
            insert(CartItem(product: product, quantity: quantity, size: size, color: color))
        }
    }

    /// Converts the bag into an order snapshot and empties the bag.
    @discardableResult
    func placeOrder(
        items: [CartItem], promoCode: String, delivery: DeliveryMethod,
        payment: PaymentMethod, address: String
    ) -> CustomerOrder {
        let subtotal = items.reduce(0) { $0 + $1.lineTotal }
        let discount = Pricing.discount(for: promoCode, subtotal: subtotal)
        let shipping = delivery.cost(forSubtotal: subtotal)
        let order = CustomerOrder(
            number: "DS-\(Int.random(in: 30000...99999))",
            subtotal: subtotal,
            discount: discount,
            shipping: shipping,
            tax: Pricing.tax(on: subtotal - discount),
            shippingAddress: address,
            deliveryMethod: "\(delivery.title) · \(delivery.estimate)",
            paymentMethod: payment.title
        )
        insert(order)
        for item in items {
            guard let product = item.product else { continue }
            let line = OrderLine(
                productID: product.id, name: product.name, brand: product.brand,
                imageName: product.imageName, price: product.price,
                quantity: item.quantity, size: item.size, color: item.color
            )
            line.order = order
            insert(line)
            product.stock = max(product.stock - item.quantity, 0)
            delete(item)
        }
        return order
    }

    /// Adds every in-stock item from a past order back into the bag.
    func buyAgain(_ order: CustomerOrder) {
        let ids = Set(order.lines.map(\.productID))
        let products = (try? fetch(FetchDescriptor<Product>(predicate: #Predicate { ids.contains($0.id) }))) ?? []
        for line in order.lines {
            guard let product = products.first(where: { $0.id == line.productID }), product.isInStock else { continue }
            addToCart(product, quantity: line.quantity, size: line.size, color: line.color)
        }
    }
}
