import SwiftUI
import SwiftData

enum SortOption: String, CaseIterable, Identifiable {
    case featured, newest, priceLowToHigh, priceHighToLow, topRated, biggestDiscount

    var id: String { rawValue }

    var title: String {
        switch self {
        case .featured: "Featured"
        case .newest: "Newest"
        case .priceLowToHigh: "Price: Low to High"
        case .priceHighToLow: "Price: High to Low"
        case .topRated: "Top Rated"
        case .biggestDiscount: "Biggest Discount"
        }
    }
}

enum PriceBracket: String, CaseIterable, Identifiable {
    case any, under50, from50to100, from100to250, over250

    var id: String { rawValue }

    var title: String {
        switch self {
        case .any: "Any Price"
        case .under50: "Under $50"
        case .from50to100: "$50 – $100"
        case .from100to250: "$100 – $250"
        case .over250: "$250+"
        }
    }

    func contains(_ price: Double) -> Bool {
        switch self {
        case .any: true
        case .under50: price < 50
        case .from50to100: (50..<100).contains(price)
        case .from100to250: (100..<250).contains(price)
        case .over250: price >= 250
        }
    }
}

struct ProductFilter: Equatable {
    var sort: SortOption = .featured
    var price: PriceBracket = .any
    var minimumRating: Double = 0
    var inStockOnly = false
    var onSaleOnly = false
    var categoryIDs: Set<String> = []

    /// Number of active refinements (sort excluded), shown on the filter button.
    var activeCount: Int {
        [price != .any, minimumRating > 0, inStockOnly, onSaleOnly, !categoryIDs.isEmpty].filter { $0 }.count
    }

    func apply(to products: [Product], searchText: String) -> [Product] {
        let query = searchText.trimmingCharacters(in: .whitespaces)
        let matches = products.filter { product in
            (query.isEmpty || product.matches(query))
                && price.contains(product.price)
                && product.rating >= minimumRating
                && (!inStockOnly || product.isInStock)
                && (!onSaleOnly || product.isOnSale)
                && (categoryIDs.isEmpty || categoryIDs.contains(product.category?.id ?? ""))
        }
        return matches.sorted(by: sort)
    }
}

extension Product {
    /// Case- and diacritic-insensitive match across the fields people search by.
    func matches(_ query: String) -> Bool {
        [name, brand, summary, category?.name ?? ""].contains { $0.localizedStandardContains(query) }
            || colors.contains { $0.localizedStandardContains(query) }
    }
}

extension Array where Element == Product {
    func sorted(by option: SortOption) -> [Product] {
        sorted { a, b in
            switch option {
            case .featured:
                if a.isFeatured != b.isFeatured { return a.isFeatured }
                return a.rating > b.rating
            case .newest:
                if a.isNew != b.isNew { return a.isNew }
                return a.name < b.name
            case .priceLowToHigh: return a.price < b.price
            case .priceHighToLow: return a.price > b.price
            case .topRated: return a.rating > b.rating
            case .biggestDiscount: return a.discountPercent > b.discountPercent
            }
        }
    }
}

/// Grid of products for a scope (category, deals, wishlist…) with search, sort, and filters.
struct ProductListView: View {
    let scope: ListingScope

    @Query private var allProducts: [Product]
    @Query(sort: \ProductCategory.sortOrder) private var categories: [ProductCategory]
    @State private var searchText = ""
    @State private var filter = ProductFilter()
    @State private var showingFilters = false

    private var results: [Product] {
        filter.apply(to: allProducts.filter(scope.includes), searchText: searchText)
    }

    private var showsCategoryFilter: Bool {
        if case .category = scope { return false }
        return true
    }

    var body: some View {
        let results = results
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                summaryBar(count: results.count)
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 158), spacing: 14)], spacing: 22) {
                    ForEach(results) { product in
                        ProductCard(product: product)
                    }
                }
                .padding(.horizontal)
            }
            .padding(.vertical, 8)
        }
        .overlay {
            if results.isEmpty {
                emptyState
            }
        }
        .navigationTitle(scope.title)
        .searchable(text: $searchText, prompt: "Search \(scope.title)")
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Menu {
                    Picker("Sort By", selection: $filter.sort) {
                        ForEach(SortOption.allCases) { Text($0.title).tag($0) }
                    }
                } label: {
                    Label("Sort", systemImage: "arrow.up.arrow.down")
                }
                Button {
                    showingFilters = true
                } label: {
                    Label("Filters", systemImage: filter.activeCount > 0
                          ? "line.3.horizontal.decrease.circle.fill"
                          : "line.3.horizontal.decrease")
                }
                .badge(filter.activeCount)
            }
        }
        .sheet(isPresented: $showingFilters) {
            FilterSheet(filter: $filter, categories: showsCategoryFilter ? categories : [])
                .presentationDetents([.medium, .large])
        }
        .animation(.smooth, value: filter)
    }

    private func summaryBar(count: Int) -> some View {
        HStack {
            Text("\(count) \(count == 1 ? "item" : "items")")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
            if filter.activeCount > 0 {
                Button("Clear Filters") {
                    let sort = filter.sort
                    filter = ProductFilter()
                    filter.sort = sort
                }
                .font(.subheadline.weight(.semibold))
            }
        }
        .padding(.horizontal)
    }

    @ViewBuilder private var emptyState: some View {
        if !searchText.isEmpty {
            ContentUnavailableView.search(text: searchText)
        } else if scope == .favorites && filter.activeCount == 0 {
            ContentUnavailableView(
                "Your Wishlist Is Empty",
                systemImage: "heart",
                description: Text("Tap the heart on any product to save it for later.")
            )
        } else {
            ContentUnavailableView(
                "No Matches",
                systemImage: "line.3.horizontal.decrease.circle",
                description: Text("Try removing some filters to see more products.")
            )
        }
    }
}

struct FilterSheet: View {
    @Binding var filter: ProductFilter
    let categories: [ProductCategory]
    @Environment(\.dismiss) private var dismiss

    private let ratingOptions: [(String, Double)] = [("Any", 0), ("3+", 3), ("4+", 4), ("4.5+", 4.5)]

    var body: some View {
        NavigationStack {
            Form {
                Section("Price") {
                    Picker("Price", selection: $filter.price) {
                        ForEach(PriceBracket.allCases) { Text($0.title).tag($0) }
                    }
                    .pickerStyle(.inline)
                    .labelsHidden()
                }

                Section("Customer Rating") {
                    Picker("Minimum Rating", selection: $filter.minimumRating) {
                        ForEach(ratingOptions, id: \.1) { option in
                            Text(option.0).tag(option.1)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section("Availability") {
                    Toggle("In Stock Only", isOn: $filter.inStockOnly)
                    Toggle("On Sale", isOn: $filter.onSaleOnly)
                }

                if !categories.isEmpty {
                    Section("Categories") {
                        ForEach(categories) { category in
                            Toggle(isOn: binding(for: category.id)) {
                                Label(category.name, systemImage: category.symbolName)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Filters")
            .inlineNavigationTitle()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Reset") {
                        let sort = filter.sort
                        filter = ProductFilter()
                        filter.sort = sort
                    }
                    .disabled(filter.activeCount == 0)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done", role: .confirm) { dismiss() }
                }
            }
        }
    }

    private func binding(for id: String) -> Binding<Bool> {
        Binding {
            filter.categoryIDs.contains(id)
        } set: { isOn in
            if isOn { filter.categoryIDs.insert(id) } else { filter.categoryIDs.remove(id) }
        }
    }
}

#Preview {
    NavigationStack {
        ProductListView(scope: .all)
            .shopDestinations()
    }
    .environment(AppRouter())
    .modelContainer(PreviewSupport.container)
    .tint(Theme.accent)
}
