import Foundation
import Testing
import SwiftUI
@testable import DraftShopper

@Suite("Model logic")
@MainActor
struct ModelLogicTests {
    // MARK: Product

    @Test("Discount percentage and sale state")
    func productDiscount() {
        let onSale = TestSupport.makeProduct(price: 89, originalPrice: 110)
        #expect(onSale.isOnSale)
        #expect(onSale.discountPercent == 19)

        let fullPrice = TestSupport.makeProduct(price: 89)
        #expect(!fullPrice.isOnSale)
        #expect(fullPrice.discountPercent == 0)

        // An "original" price at or below the current price is not a sale.
        let notReallyOnSale = TestSupport.makeProduct(price: 89, originalPrice: 80)
        #expect(!notReallyOnSale.isOnSale)
        #expect(notReallyOnSale.discountPercent == 0)
    }

    @Test("Stock state")
    func productStock() {
        #expect(TestSupport.makeProduct(stock: 1).isInStock)
        #expect(!TestSupport.makeProduct(stock: 0).isInStock)
    }

    @Test("Search matches name, brand, summary, and colors, ignoring case and accents")
    func productMatching() {
        let product = TestSupport.makeProduct(
            name: "Heritage Leather Chukka", brand: "Northloom",
            summary: "Hand-finished café-style boot", colors: ["Cognac", "Espresso"]
        )
        #expect(product.matches("leather"))
        #expect(product.matches("NORTHLOOM"))
        #expect(product.matches("cafe"))
        #expect(product.matches("cognac"))
        #expect(!product.matches("sneaker"))
    }

    // MARK: Cart & order lines

    @Test("Cart item totals and option summaries")
    func cartItem() {
        let product = TestSupport.makeProduct(price: 28)
        let item = CartItem(product: product, quantity: 3, size: "M", color: "Navy")
        #expect(item.lineTotal == 84)
        #expect(item.optionsSummary == "Navy · Size M")

        let plain = CartItem(product: product, quantity: 1, size: nil, color: nil)
        #expect(plain.optionsSummary == nil)

        let sizeOnly = CartItem(product: product, quantity: 1, size: "9", color: nil)
        #expect(sizeOnly.optionsSummary == "Size 9")
    }

    @Test("Order totals and status round trip")
    func orderTotals() {
        let order = CustomerOrder(
            number: "DS-1", subtotal: 100, discount: 10, shipping: 6.99, tax: 7.43,
            shippingAddress: "Somewhere", deliveryMethod: "Standard", paymentMethod: "Apple Pay"
        )
        #expect(order.status == .processing)
        #expect(abs(order.total - 104.42) < 0.001)

        order.status = .delivered
        #expect(order.statusRaw == "delivered")
        #expect(order.status == .delivered)

        order.statusRaw = "not-a-status"
        #expect(order.status == .processing, "Unknown raw values fall back to processing")
    }

    @Test("Order statuses advance in display order")
    func orderStatusSteps() {
        let steps = OrderStatus.allCases.map(\.step)
        #expect(steps == [0, 1, 2, 3])
        #expect(OrderStatus.processing.step < OrderStatus.delivered.step)
    }

    // MARK: App state

    @Test("Appearance maps to the expected color scheme")
    func appearance() {
        #expect(AppAppearance.system.colorScheme == nil)
        #expect(AppAppearance.light.colorScheme == .light)
        #expect(AppAppearance.dark.colorScheme == .dark)
    }

    @Test("Listing scopes include the right products")
    func listingScopes() {
        let deal = TestSupport.makeProduct(price: 10, originalPrice: 20)
        let featuredNew = TestSupport.makeProduct(isFeatured: true, isNew: true)
        let favorite = TestSupport.makeProduct()
        favorite.isFavorite = true

        #expect(ListingScope.all.includes(deal))
        #expect(ListingScope.deals.includes(deal))
        #expect(!ListingScope.deals.includes(featuredNew))
        #expect(ListingScope.featured.includes(featuredNew))
        #expect(ListingScope.newArrivals.includes(featuredNew))
        #expect(ListingScope.favorites.includes(favorite))
        #expect(!ListingScope.favorites.includes(deal))
        #expect(ListingScope.favorites.title == "Wishlist")
    }
}
