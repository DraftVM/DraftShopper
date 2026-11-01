import Foundation
import Testing
@testable import DraftShopper

@Suite("Product filtering and sorting")
@MainActor
struct ProductFilterTests {
    private let cheap = TestSupport.makeProduct(id: "cheap", name: "Mug", price: 22, rating: 4.7, isNew: true)
    private let mid = TestSupport.makeProduct(id: "mid", name: "Lamp", price: 89, originalPrice: 110, rating: 4.5, isFeatured: true)
    private let pricey = TestSupport.makeProduct(id: "pricey", name: "Camera", price: 1199, rating: 4.8, stock: 0)

    private var all: [Product] { [cheap, mid, pricey] }

    @Test("Price brackets have inclusive lower and exclusive upper bounds")
    func priceBrackets() {
        #expect(PriceBracket.any.contains(10_000))
        #expect(PriceBracket.under50.contains(49.99))
        #expect(!PriceBracket.under50.contains(50))
        #expect(PriceBracket.from50to100.contains(50))
        #expect(!PriceBracket.from50to100.contains(100))
        #expect(PriceBracket.from100to250.contains(100))
        #expect(PriceBracket.over250.contains(250))
        #expect(!PriceBracket.over250.contains(249.99))
    }

    @Test("A default filter returns everything and counts as inactive")
    func defaultFilter() {
        let filter = ProductFilter()
        #expect(filter.activeCount == 0)
        #expect(filter.apply(to: all, searchText: "").count == 3)
    }

    @Test("Active refinements are counted, sort is not")
    func activeCount() {
        var filter = ProductFilter()
        filter.sort = .priceHighToLow
        #expect(filter.activeCount == 0)
        filter.price = .under50
        filter.minimumRating = 4
        filter.inStockOnly = true
        filter.onSaleOnly = true
        filter.categoryIDs = ["home"]
        #expect(filter.activeCount == 5)
    }

    @Test("Each refinement narrows the results")
    func refinements() {
        var filter = ProductFilter()

        filter.price = .under50
        #expect(filter.apply(to: all, searchText: "").map(\.id) == ["cheap"])

        filter = ProductFilter()
        filter.inStockOnly = true
        #expect(Set(filter.apply(to: all, searchText: "").map(\.id)) == ["cheap", "mid"])

        filter = ProductFilter()
        filter.onSaleOnly = true
        #expect(filter.apply(to: all, searchText: "").map(\.id) == ["mid"])

        filter = ProductFilter()
        filter.minimumRating = 4.7
        #expect(Set(filter.apply(to: all, searchText: "").map(\.id)) == ["cheap", "pricey"])
    }

    @Test("Search text is trimmed and combined with filters")
    func searchWithFilters() {
        var filter = ProductFilter()
        #expect(filter.apply(to: all, searchText: "  lamp ").map(\.id) == ["mid"])
        #expect(filter.apply(to: all, searchText: "nothing matches").isEmpty)

        filter.inStockOnly = true
        #expect(filter.apply(to: all, searchText: "camera").isEmpty)
    }

    @Test("Sort options order products as labeled", arguments: [
        (SortOption.priceLowToHigh, ["cheap", "mid", "pricey"]),
        (SortOption.priceHighToLow, ["pricey", "mid", "cheap"]),
        (SortOption.topRated, ["pricey", "cheap", "mid"]),
        (SortOption.featured, ["mid", "pricey", "cheap"]),
        (SortOption.newest, ["cheap", "pricey", "mid"]),
        (SortOption.biggestDiscount, ["mid", "cheap", "pricey"]),
    ])
    func sorting(option: SortOption, expected: [String]) {
        let ids = all.sorted(by: option).map(\.id)
        if option == .biggestDiscount {
            // Only the leader is defined; ties among undiscounted items keep no particular order.
            #expect(ids.first == expected.first)
        } else {
            #expect(ids == expected)
        }
    }
}
