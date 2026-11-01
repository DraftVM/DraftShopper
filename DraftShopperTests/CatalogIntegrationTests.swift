import Foundation
import Testing
import SwiftData
#if canImport(UIKit)
import UIKit
#endif
@testable import DraftShopper

/// Exercises the seeded SwiftData catalog end to end in an in-memory store.
@Suite("Catalog integration")
@MainActor
struct CatalogIntegrationTests {
    @Test("Seeding creates the full catalog with sample orders")
    func seedingPopulatesStore() throws {
        let container = try TestSupport.makeContainer()
        let context = container.mainContext

        #expect(try context.fetchCount(FetchDescriptor<ProductCategory>()) == 6)
        #expect(try context.fetchCount(FetchDescriptor<Product>()) == 27)
        #expect(try context.fetchCount(FetchDescriptor<CustomerOrder>()) == 2)
        #expect(try context.fetchCount(FetchDescriptor<CartItem>()) == 0)
    }

    @Test("Seeding twice does not duplicate data")
    func seedingIsIdempotent() throws {
        let container = try TestSupport.makeContainer()
        let context = container.mainContext
        SeedData.seedIfNeeded(context)
        SeedData.seedIfNeeded(context)

        #expect(try context.fetchCount(FetchDescriptor<Product>()) == 27)
        #expect(try context.fetchCount(FetchDescriptor<CustomerOrder>()) == 2)
    }

    @Test("Every product belongs to a category and has sane data")
    func productsAreWellFormed() throws {
        let container = try TestSupport.makeContainer()
        let products = try container.mainContext.fetch(FetchDescriptor<Product>())

        for product in products {
            #expect(product.category != nil, "\(product.id) has no category")
            #expect(product.price > 0, "\(product.id) has no price")
            #expect((0...5).contains(product.rating), "\(product.id) rating out of range")
            #expect(!product.colors.isEmpty, "\(product.id) has no colors")
            #expect(!product.highlights.isEmpty, "\(product.id) has no highlights")
            if let original = product.originalPrice {
                #expect(original > product.price, "\(product.id) original price isn't higher")
            }
        }
        #expect(Set(products.map(\.id)).count == products.count, "Product IDs must be unique")
    }

    @Test("Category relationships line up with each product's category")
    func categoryRelationships() throws {
        let container = try TestSupport.makeContainer()
        let categories = try container.mainContext.fetch(FetchDescriptor<ProductCategory>(sortBy: [SortDescriptor(\.sortOrder)]))

        #expect(categories.map(\.id) == ["footwear", "audio", "accessories", "apparel", "home", "tech"])
        #expect(categories.reduce(0) { $0 + $1.products.count } == 27)
        for category in categories {
            #expect(!category.products.isEmpty, "\(category.id) is empty")
            #expect(category.products.allSatisfy { $0.category?.id == category.id })
        }
    }

    @Test("Seeded orders have consistent line snapshots")
    func seededOrders() throws {
        let container = try TestSupport.makeContainer()
        let orders = try container.mainContext.fetch(FetchDescriptor<CustomerOrder>(sortBy: [SortDescriptor(\.placedAt)]))

        #expect(orders.map(\.status) == [.delivered, .shipped])
        for order in orders {
            let linesSubtotal = order.lines.reduce(0) { $0 + $1.price * Double($1.quantity) }
            #expect(abs(linesSubtotal - order.subtotal) < 0.001, "\(order.number) subtotal mismatch")
        }
    }

    @Test("Every catalog image has a CC0 credit entry")
    func imagesAreCredited() throws {
        let container = try TestSupport.makeContainer()
        let context = container.mainContext
        let creditedIDs = Set(ImageCredits.all.map(\.id))
        let productImages = try context.fetch(FetchDescriptor<Product>()).map(\.imageName)
        let categoryImages = try context.fetch(FetchDescriptor<ProductCategory>()).map(\.imageName)

        for name in productImages + categoryImages {
            #expect(creditedIDs.contains(name), "\(name) is missing from Image Credits")
        }
        #expect(ImageCredits.all.allSatisfy { $0.url != nil })
    }

    #if canImport(UIKit)
    @Test("Every catalog image and brand asset is bundled in the app")
    func imagesAreBundled() throws {
        let container = try TestSupport.makeContainer()
        let context = container.mainContext
        let names = try context.fetch(FetchDescriptor<Product>()).map(\.imageName)
            + context.fetch(FetchDescriptor<ProductCategory>()).map(\.imageName)
            + ["BrandLogo"]

        for name in names {
            #expect(UIImage(named: name) != nil, "Asset \(name) is missing from the app bundle")
        }
    }
    #endif

    @Test("Reset clears the bag and user state, then restores the catalog")
    func resetRestoresCatalog() throws {
        let container = try TestSupport.makeContainer()
        let context = container.mainContext
        let mug = try TestSupport.product("mug_ceramic", in: context)
        mug.isFavorite = true
        context.addToCart(mug, quantity: 2, color: "Cloud")
        context.placeOrder(items: try TestSupport.cartItems(in: context), promoCode: "", delivery: .standard, payment: .visa, address: "Here")

        SeedData.reset(context)

        #expect(try context.fetchCount(FetchDescriptor<Product>()) == 27)
        #expect(try context.fetchCount(FetchDescriptor<CartItem>()) == 0)
        #expect(try context.fetchCount(FetchDescriptor<CustomerOrder>()) == 2)
        #expect(try context.fetchCount(FetchDescriptor<OrderLine>()) == 3)
        let restored = try TestSupport.product("mug_ceramic", in: context)
        #expect(!restored.isFavorite)
        #expect(restored.stock == 25)
    }

    @Test("Seeded catalog supports the listing scopes and search")
    func scopesAgainstCatalog() throws {
        let container = try TestSupport.makeContainer()
        let products = try container.mainContext.fetch(FetchDescriptor<Product>())

        let deals = products.filter { ListingScope.deals.includes($0) }
        let featured = products.filter { ListingScope.featured.includes($0) }
        let newArrivals = products.filter { ListingScope.newArrivals.includes($0) }
        let favorites = products.filter { ListingScope.favorites.includes($0) }
        #expect(!deals.isEmpty)
        #expect(deals.allSatisfy { $0.isOnSale })
        #expect(!featured.isEmpty)
        #expect(!newArrivals.isEmpty)
        #expect(favorites.isEmpty)

        let leather = ProductFilter().apply(to: products, searchText: "leather")
        #expect(leather.contains { $0.id == "boots_chukka" })
        #expect(leather.contains { $0.id == "wallet_leather" })

        // Category names are searchable too.
        let audio = ProductFilter().apply(to: products, searchText: "Audio")
        #expect(audio.count >= 5)
    }
}
