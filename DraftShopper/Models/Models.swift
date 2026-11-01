import Foundation
import SwiftData

// MARK: - Catalog

@Model
final class ProductCategory {
    @Attribute(.unique) var id: String
    var name: String
    var symbolName: String
    var tagline: String
    var imageName: String
    var sortOrder: Int

    @Relationship(deleteRule: .cascade, inverse: \Product.category)
    var products: [Product] = []

    init(id: String, name: String, symbolName: String, tagline: String, imageName: String, sortOrder: Int) {
        self.id = id
        self.name = name
        self.symbolName = symbolName
        self.tagline = tagline
        self.imageName = imageName
        self.sortOrder = sortOrder
    }
}

@Model
final class Product {
    @Attribute(.unique) var id: String
    var name: String
    var brand: String
    var summary: String
    var highlights: [String]
    var price: Double
    var originalPrice: Double?
    var rating: Double
    var reviewCount: Int
    var imageName: String
    var colors: [String]
    var sizes: [String]
    var stock: Int
    var isFeatured: Bool
    var isNew: Bool
    var isFavorite: Bool = false
    var category: ProductCategory?

    init(
        id: String, name: String, brand: String, summary: String, highlights: [String],
        price: Double, originalPrice: Double? = nil, rating: Double, reviewCount: Int,
        imageName: String, colors: [String], sizes: [String] = [], stock: Int = 25,
        isFeatured: Bool = false, isNew: Bool = false
    ) {
        self.id = id
        self.name = name
        self.brand = brand
        self.summary = summary
        self.highlights = highlights
        self.price = price
        self.originalPrice = originalPrice
        self.rating = rating
        self.reviewCount = reviewCount
        self.imageName = imageName
        self.colors = colors
        self.sizes = sizes
        self.stock = stock
        self.isFeatured = isFeatured
        self.isNew = isNew
    }

    var isOnSale: Bool { (originalPrice ?? 0) > price }
    var isInStock: Bool { stock > 0 }

    /// Whole-number percentage saved versus the original price, or 0 when not discounted.
    var discountPercent: Int {
        guard let originalPrice, originalPrice > price else { return 0 }
        return Int(((originalPrice - price) / originalPrice * 100).rounded())
    }
}

// MARK: - Cart

@Model
final class CartItem {
    var product: Product?
    var quantity: Int
    var size: String?
    var color: String?
    var addedAt: Date

    init(product: Product, quantity: Int, size: String?, color: String?) {
        self.product = product
        self.quantity = quantity
        self.size = size
        self.color = color
        self.addedAt = .now
    }

    var lineTotal: Double { (product?.price ?? 0) * Double(quantity) }

    /// "Cognac · Size 9" style summary of the chosen options.
    var optionsSummary: String? {
        let parts = [color, size.map { "Size \($0)" }].compactMap { $0 }
        return parts.isEmpty ? nil : parts.joined(separator: " · ")
    }
}

// MARK: - Orders

enum OrderStatus: String, CaseIterable, Codable {
    case processing, shipped, outForDelivery, delivered

    var title: String {
        switch self {
        case .processing: "Processing"
        case .shipped: "Shipped"
        case .outForDelivery: "Out for Delivery"
        case .delivered: "Delivered"
        }
    }

    var symbolName: String {
        switch self {
        case .processing: "clock"
        case .shipped: "shippingbox"
        case .outForDelivery: "truck.box"
        case .delivered: "checkmark.seal"
        }
    }

    var step: Int { Self.allCases.firstIndex(of: self) ?? 0 }
}

@Model
final class CustomerOrder {
    @Attribute(.unique) var number: String
    var placedAt: Date
    var statusRaw: String
    var subtotal: Double
    var discount: Double
    var shipping: Double
    var tax: Double
    var shippingAddress: String
    var deliveryMethod: String
    var paymentMethod: String

    @Relationship(deleteRule: .cascade, inverse: \OrderLine.order)
    var lines: [OrderLine] = []

    init(
        number: String, placedAt: Date = .now, status: OrderStatus = .processing,
        subtotal: Double, discount: Double, shipping: Double, tax: Double,
        shippingAddress: String, deliveryMethod: String, paymentMethod: String
    ) {
        self.number = number
        self.placedAt = placedAt
        self.statusRaw = status.rawValue
        self.subtotal = subtotal
        self.discount = discount
        self.shipping = shipping
        self.tax = tax
        self.shippingAddress = shippingAddress
        self.deliveryMethod = deliveryMethod
        self.paymentMethod = paymentMethod
    }

    var status: OrderStatus {
        get { OrderStatus(rawValue: statusRaw) ?? .processing }
        set { statusRaw = newValue.rawValue }
    }

    var total: Double { subtotal - discount + shipping + tax }
    var itemCount: Int { lines.reduce(0) { $0 + $1.quantity } }
    var sortedLines: [OrderLine] { lines.sorted { $0.name < $1.name } }
}

/// A snapshot of a purchased product, so orders stay accurate even if the catalog changes.
@Model
final class OrderLine {
    var productID: String
    var name: String
    var brand: String
    var imageName: String
    var price: Double
    var quantity: Int
    var size: String?
    var color: String?
    var order: CustomerOrder?

    init(productID: String, name: String, brand: String, imageName: String, price: Double, quantity: Int, size: String?, color: String?) {
        self.productID = productID
        self.name = name
        self.brand = brand
        self.imageName = imageName
        self.price = price
        self.quantity = quantity
        self.size = size
        self.color = color
    }

    var optionsSummary: String? {
        let parts = [color, size.map { "Size \($0)" }].compactMap { $0 }
        return parts.isEmpty ? nil : parts.joined(separator: " · ")
    }
}
