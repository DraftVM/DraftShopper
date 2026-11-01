import SwiftUI
import SwiftData

/// UserDefaults keys for lightweight session and preference state.
enum StorageKey {
    static let isSignedIn = "session.isSignedIn"
    static let userName = "session.userName"
    static let userEmail = "session.userEmail"
    static let memberSince = "session.memberSince"
    static let shippingAddress = "profile.shippingAddress"
    static let appearance = "prefs.appearance"
    static let orderUpdates = "prefs.orderUpdates"
    static let recentSearches = "search.recent"
}

enum AppAppearance: String, CaseIterable, Identifiable {
    case system, light, dark

    var id: String { rawValue }

    var title: String {
        switch self {
        case .system: "System"
        case .light: "Light"
        case .dark: "Dark"
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: nil
        case .light: .light
        case .dark: .dark
        }
    }
}

enum AppTab: Hashable {
    case home, orders, bag, profile, search
}

/// Shared tab selection so any screen can jump to another tab (e.g. "View Bag").
@Observable
final class AppRouter {
    var selectedTab: AppTab = .home
}

/// The product collections a listing screen can show.
enum ListingScope: Hashable {
    case all, featured, newArrivals, deals, favorites
    case category(ProductCategory)

    var title: String {
        switch self {
        case .all: "All Products"
        case .featured: "Featured"
        case .newArrivals: "New Arrivals"
        case .deals: "Deals"
        case .favorites: "Wishlist"
        case .category(let category): category.name
        }
    }

    func includes(_ product: Product) -> Bool {
        switch self {
        case .all: true
        case .featured: product.isFeatured
        case .newArrivals: product.isNew
        case .deals: product.isOnSale
        case .favorites: product.isFavorite
        case .category(let category): product.category?.id == category.id
        }
    }
}

extension View {
    /// Registers the shared shopping destinations on a navigation stack.
    func shopDestinations() -> some View {
        navigationDestination(for: Product.self) { ProductDetailView(product: $0) }
            .navigationDestination(for: ListingScope.self) { ProductListView(scope: $0) }
    }

    /// Inline navigation title on iOS; no-op elsewhere.
    func inlineNavigationTitle() -> some View {
        #if os(iOS)
        navigationBarTitleDisplayMode(.inline)
        #else
        self
        #endif
    }

    /// Configures a text field for email entry.
    func emailFieldStyle() -> some View {
        #if os(iOS)
        textContentType(.emailAddress)
            .keyboardType(.emailAddress)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
        #else
        textContentType(.username)
            .autocorrectionDisabled()
        #endif
    }
}

/// In-memory container seeded with the catalog, for SwiftUI previews.
@MainActor
enum PreviewSupport {
    static let container: ModelContainer = {
        let schema = Schema([ProductCategory.self, Product.self, CartItem.self, CustomerOrder.self, OrderLine.self])
        do {
            let container = try ModelContainer(for: schema, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
            SeedData.seedIfNeeded(container.mainContext)
            return container
        } catch {
            fatalError("Failed to create preview container: \(error)")
        }
    }()

    static var sampleProduct: Product {
        let descriptor = FetchDescriptor<Product>(predicate: #Predicate { $0.id == "headphones_aurum" })
        if let product = try? container.mainContext.fetch(descriptor).first {
            return product
        }
        fatalError("Preview catalog is missing sample product")
    }
}
