import Foundation
import Testing
import SwiftData
@testable import DraftShopper

/// End-to-end bag → checkout → order flows against an in-memory SwiftData store.
@Suite("Shopping flow integration")
@MainActor
struct ShoppingFlowIntegrationTests {
    @Test("Adding the same product and options merges into one line")
    func addToCartMerges() throws {
        let container = try TestSupport.makeContainer()
        let context = container.mainContext
        let sneaker = try TestSupport.product("sneakers_white", in: context)

        context.addToCart(sneaker, quantity: 1, size: "9", color: "Chalk")
        context.addToCart(sneaker, quantity: 2, size: "9", color: "Chalk")

        let items = try TestSupport.cartItems(in: context)
        #expect(items.count == 1)
        #expect(items.first?.quantity == 3)
    }

    @Test("Different sizes or colors become separate lines")
    func addToCartSeparatesOptions() throws {
        let container = try TestSupport.makeContainer()
        let context = container.mainContext
        let sneaker = try TestSupport.product("sneakers_white", in: context)

        context.addToCart(sneaker, size: "9", color: "Chalk")
        context.addToCart(sneaker, size: "10", color: "Chalk")
        context.addToCart(sneaker, size: "9", color: "Black")

        #expect(try TestSupport.cartItems(in: context).count == 3)
    }

    @Test("Quantity per line is capped at 10")
    func addToCartCapsQuantity() throws {
        let container = try TestSupport.makeContainer()
        let context = container.mainContext
        let mug = try TestSupport.product("mug_ceramic", in: context)

        context.addToCart(mug, quantity: 8)
        context.addToCart(mug, quantity: 8)

        #expect(try TestSupport.cartItems(in: context).first?.quantity == 10)
    }

    @Test("Placing an order snapshots lines, totals, and empties the bag")
    func placeOrder() throws {
        let container = try TestSupport.makeContainer()
        let context = container.mainContext
        let mug = try TestSupport.product("mug_ceramic", in: context)          // $22
        let tee = try TestSupport.product("tshirt_essential", in: context)     // $28
        let startingMugStock = mug.stock

        context.addToCart(mug, quantity: 2, color: "Sage")
        context.addToCart(tee, quantity: 1, size: "L", color: "Navy")
        let order = context.placeOrder(
            items: try TestSupport.cartItems(in: context),
            promoCode: "draft10", delivery: .standard, payment: .applePay,
            address: "1 Infinite Loop, Cupertino, CA 95014"
        )
        try context.save()

        // Totals: subtotal 72, 10% off = 7.20, under $75 → $6.99 shipping, tax on 64.80.
        #expect(order.subtotal == 72)
        #expect(order.discount == 7.2)
        #expect(order.shipping == 6.99)
        #expect(order.tax == Pricing.tax(on: 64.8))
        #expect(abs(order.total - (72 - 7.2 + 6.99 + order.tax)) < 0.001)
        #expect(order.status == .processing)
        #expect(order.number.hasPrefix("DS-"))
        #expect(order.paymentMethod == PaymentMethod.applePay.title)

        // Line snapshots keep the chosen options.
        #expect(order.itemCount == 3)
        let mugLine = try #require(order.lines.first { $0.productID == "mug_ceramic" })
        #expect(mugLine.quantity == 2)
        #expect(mugLine.color == "Sage")
        #expect(mugLine.price == 22)

        // Side effects: bag emptied, stock reduced, order persisted.
        #expect(try TestSupport.cartItems(in: context).isEmpty)
        #expect(mug.stock == startingMugStock - 2)
        #expect(try context.fetchCount(FetchDescriptor<CustomerOrder>()) == 3)
    }

    @Test("Orders over the threshold ship free with standard delivery, express is always charged")
    func shippingInOrders() throws {
        let container = try TestSupport.makeContainer()
        let context = container.mainContext
        let lamp = try TestSupport.product("lamp_desk", in: context)  // $89

        context.addToCart(lamp)
        let standard = context.placeOrder(items: try TestSupport.cartItems(in: context), promoCode: "", delivery: .standard, payment: .visa, address: "Here")
        #expect(standard.shipping == 0)
        #expect(standard.discount == 0)

        context.addToCart(lamp)
        let express = context.placeOrder(items: try TestSupport.cartItems(in: context), promoCode: "BOGUS", delivery: .express, payment: .visa, address: "Here")
        #expect(express.shipping == 14.99)
        #expect(express.discount == 0)
    }

    @Test("Order snapshots survive later catalog price changes")
    func orderSnapshotsAreStable() throws {
        let container = try TestSupport.makeContainer()
        let context = container.mainContext
        let lamp = try TestSupport.product("lamp_desk", in: context)

        context.addToCart(lamp)
        let order = context.placeOrder(items: try TestSupport.cartItems(in: context), promoCode: "", delivery: .standard, payment: .visa, address: "Here")
        lamp.price = 1
        lamp.name = "Renamed"

        #expect(order.lines.first?.price == 89)
        #expect(order.lines.first?.name == "Arc Desk Lamp")
    }

    @Test("Stock never goes below zero")
    func stockClampsAtZero() throws {
        let container = try TestSupport.makeContainer()
        let context = container.mainContext
        let turntable = try TestSupport.product("turntable_retro", in: context)  // seeded stock 3

        context.insert(CartItem(product: turntable, quantity: 5, size: nil, color: nil))
        context.placeOrder(items: try TestSupport.cartItems(in: context), promoCode: "", delivery: .standard, payment: .visa, address: "Here")

        #expect(turntable.stock == 0)
        #expect(!turntable.isInStock)
    }

    @Test("Buy Again re-adds in-stock items with their options and skips sold-out ones")
    func buyAgain() throws {
        let container = try TestSupport.makeContainer()
        let context = container.mainContext
        let mug = try TestSupport.product("mug_ceramic", in: context)
        let watch = try TestSupport.product("watch_vintage", in: context)  // seeded out of stock
        #expect(!watch.isInStock)

        let order = CustomerOrder(
            number: "DS-TEST", subtotal: 0, discount: 0, shipping: 0, tax: 0,
            shippingAddress: "Here", deliveryMethod: "Standard", paymentMethod: "Visa"
        )
        context.insert(order)
        for line in [
            OrderLine(productID: mug.id, name: mug.name, brand: mug.brand, imageName: mug.imageName, price: mug.price, quantity: 2, size: nil, color: "Sage"),
            OrderLine(productID: watch.id, name: watch.name, brand: watch.brand, imageName: watch.imageName, price: watch.price, quantity: 1, size: nil, color: "Tan Suede"),
        ] {
            context.insert(line)
            line.order = order
        }

        context.buyAgain(order)

        let items = try TestSupport.cartItems(in: context)
        #expect(items.count == 1)
        #expect(items.first?.product?.id == "mug_ceramic")
        #expect(items.first?.quantity == 2)
        #expect(items.first?.color == "Sage")
    }

    @Test("Deleting an order also deletes its lines")
    func deletingOrderCascades() throws {
        let container = try TestSupport.makeContainer()
        let context = container.mainContext
        let order = try #require(try context.fetch(FetchDescriptor<CustomerOrder>()).first)
        let linesBefore = try context.fetchCount(FetchDescriptor<OrderLine>())
        let removed = order.lines.count

        context.delete(order)
        try context.save()

        #expect(try context.fetchCount(FetchDescriptor<OrderLine>()) == linesBefore - removed)
    }

    @Test("Wishlist favorites persist through a save")
    func favoritesPersist() throws {
        let container = try TestSupport.makeContainer()
        let context = container.mainContext
        try TestSupport.product("lamp_desk", in: context).isFavorite = true
        try context.save()

        let favorites = try context.fetch(FetchDescriptor<Product>(predicate: #Predicate { $0.isFavorite }))
        #expect(favorites.map(\.id) == ["lamp_desk"])
    }
}
