import SwiftUI
import SwiftData

struct SearchView: View {
    @Query private var products: [Product]
    @Query(sort: \ProductCategory.sortOrder) private var categories: [ProductCategory]
    @AppStorage(StorageKey.recentSearches) private var recentSearchesRaw = ""
    @State private var query = ""

    private let popularSearches = ["Headphones", "Leather", "Sneakers", "Watch", "Denim", "Lamp"]

    private var recentSearches: [String] {
        recentSearchesRaw.split(separator: "\n").map(String.init)
    }

    private var results: [Product] {
        let trimmed = query.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return [] }
        return products.filter { $0.matches(trimmed) }.sorted(by: .topRated)
    }

    var body: some View {
        NavigationStack {
            List {
                if query.isEmpty {
                    suggestions
                } else {
                    let results = results
                    if !results.isEmpty {
                        Section("\(results.count) \(results.count == 1 ? "Result" : "Results")") {
                            ForEach(results) { product in
                                NavigationLink(value: product) {
                                    ProductRow(product: product)
                                }
                            }
                        }
                    }
                }
            }
            .overlay {
                if !query.isEmpty && results.isEmpty {
                    ContentUnavailableView.search(text: query)
                }
            }
            .navigationTitle("Search")
            .searchable(text: $query, prompt: "Products, brands, and more")
            .onSubmit(of: .search) { saveRecent(query) }
            .shopDestinations()
        }
    }

    @ViewBuilder private var suggestions: some View {
        if !recentSearches.isEmpty {
            Section {
                ForEach(recentSearches, id: \.self) { term in
                    Button {
                        query = term
                    } label: {
                        Label(term, systemImage: "clock.arrow.circlepath")
                            .foregroundStyle(.primary)
                    }
                }
            } header: {
                HStack {
                    Text("Recent")
                    Spacer()
                    Button("Clear") { recentSearchesRaw = "" }
                        .font(.footnote.weight(.semibold))
                        .textCase(nil)
                }
            }
        }

        Section("Popular") {
            ForEach(popularSearches, id: \.self) { term in
                Button {
                    query = term
                    saveRecent(term)
                } label: {
                    Label(term, systemImage: "magnifyingglass")
                        .foregroundStyle(.primary)
                }
            }
        }

        Section("Browse Categories") {
            ForEach(categories) { category in
                NavigationLink(value: ListingScope.category(category)) {
                    Label {
                        Text(category.name)
                    } icon: {
                        Image(systemName: category.symbolName)
                            .foregroundStyle(Theme.accent)
                    }
                }
            }
            NavigationLink(value: ListingScope.all) {
                Label {
                    Text("All Products")
                } icon: {
                    Image(systemName: "square.grid.2x2")
                        .foregroundStyle(Theme.accent)
                }
            }
        }
    }

    /// Keeps the five most recent unique search terms.
    private func saveRecent(_ term: String) {
        let trimmed = term.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        var terms = recentSearches.filter { $0.caseInsensitiveCompare(trimmed) != .orderedSame }
        terms.insert(trimmed, at: 0)
        recentSearchesRaw = terms.prefix(5).joined(separator: "\n")
    }
}

#Preview {
    SearchView()
        .environment(AppRouter())
        .modelContainer(PreviewSupport.container)
        .tint(Theme.accent)
}
