import Foundation
import Testing
@testable import DraftShopper

@Suite("Pricing")
@MainActor
struct PricingTests {
    @Test("Valid promo codes apply their percentage, case- and whitespace-insensitively", arguments: [
        ("DRAFT10", 10.0),
        ("draft10", 10.0),
        ("  Draft10 ", 10.0),
        ("WELCOME15", 15.0),
    ])
    func validPromoCodes(code: String, expected: Double) {
        #expect(Pricing.discount(for: code, subtotal: 100) == expected)
    }

    @Test("Unknown or empty promo codes give no discount", arguments: ["", "DRAFT", "FREE100", "DRAFT 10"])
    func invalidPromoCodes(code: String) {
        #expect(Pricing.discount(for: code, subtotal: 100) == 0)
    }

    @Test("Discounts round to the nearest cent")
    func discountRounding() {
        // 10% of 33.33 = 3.333 → 3.33
        #expect(Pricing.discount(for: "DRAFT10", subtotal: 33.33) == 3.33)
    }

    @Test("Tax uses the configured rate, rounds to cents, and never goes negative")
    func tax() {
        #expect(Pricing.tax(on: 100) == 8.25)
        #expect(Pricing.tax(on: 72) == 5.94)
        #expect(Pricing.tax(on: 0) == 0)
        #expect(Pricing.tax(on: -20) == 0)
    }

    @Test("Standard shipping is free at or above the threshold and for an empty bag")
    func standardShipping() {
        #expect(DeliveryMethod.standard.cost(forSubtotal: 0) == 0)
        #expect(DeliveryMethod.standard.cost(forSubtotal: 74.99) == 6.99)
        #expect(DeliveryMethod.standard.cost(forSubtotal: Pricing.freeShippingThreshold) == 0)
        #expect(DeliveryMethod.standard.cost(forSubtotal: 500) == 0)
    }

    @Test("Express shipping is always charged")
    func expressShipping() {
        #expect(DeliveryMethod.express.cost(forSubtotal: 10) == 14.99)
        #expect(DeliveryMethod.express.cost(forSubtotal: 500) == 14.99)
    }

    @Test("Currency formatting uses US dollars")
    func currencyFormatting() {
        #expect(Double(1199).currency.contains("1,199.00"))
        #expect(Double(22).currency.contains("$"))
    }
}
