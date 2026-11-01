import Foundation
import SwiftData
@testable import DraftShopper

/// Shared helpers for the Draft Shoppr test suites.
@MainActor
enum TestSupport {
    /// A fresh, isolated in-memory store. Each call gets its own uniquely named configuration
    /// so parallel tests never share data.
    static func makeContainer(seeded: Bool = true) throws -> ModelContainer {
        let schema = Schema([ProductCategory.self, Product.self, CartItem.self, CustomerOrder.self, OrderLine.self])
        let configuration = ModelConfiguration(UUID().uuidString, schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: configuration)
        if seeded {
            SeedData.seedIfNeeded(container.mainContext)
        }
        return container
    }

    static func product(_ id: String, in context: ModelContext) throws -> Product {
        let descriptor = FetchDescriptor<Product>(predicate: #Predicate { $0.id == id })
        guard let product = try context.fetch(descriptor).first else {
            throw TestError.missingProduct(id)
        }
        return product
    }

    static func cartItems(in context: ModelContext) throws -> [CartItem] {
        try context.fetch(FetchDescriptor<CartItem>(sortBy: [SortDescriptor(\.addedAt)]))
    }

    /// Builds a standalone product (not inserted into any store) for pure logic tests.
    static func makeProduct(
        id: String = "test",
        name: String = "Test Product",
        brand: String = "Test Brand",
        summary: String = "A product for tests",
        price: Double = 50,
        originalPrice: Double? = nil,
        rating: Double = 4.0,
        colors: [String] = ["Black"],
        stock: Int = 10,
        isFeatured: Bool = false,
        isNew: Bool = false
    ) -> Product {
        Product(
            id: id, name: name, brand: brand, summary: summary, highlights: [],
            price: price, originalPrice: originalPrice, rating: rating, reviewCount: 1,
            imageName: id, colors: colors, stock: stock, isFeatured: isFeatured, isNew: isNew
        )
    }
}

enum TestError: Error {
    case missingProduct(String)
}
