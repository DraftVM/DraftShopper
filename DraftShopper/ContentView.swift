import SwiftUI
import SwiftData

/// Root view: shows sign-in until a session exists, then the main tab interface.
struct ContentView: View {
    @AppStorage(StorageKey.isSignedIn) private var isSignedIn = false
    @AppStorage(StorageKey.appearance) private var appearance: AppAppearance = .system

    var body: some View {
        Group {
            if isSignedIn {
                MainTabView()
                    .transition(.opacity)
            } else {
                SignInView()
                    .transition(.opacity)
            }
        }
        .animation(.smooth, value: isSignedIn)
        .tint(Theme.accent)
        .preferredColorScheme(appearance.colorScheme)
    }
}

struct MainTabView: View {
    @Environment(AppRouter.self) private var router
    @Query private var cartItems: [CartItem]

    private var bagCount: Int { cartItems.reduce(0) { $0 + $1.quantity } }

    var body: some View {
        @Bindable var router = router
        TabView(selection: $router.selectedTab) {
            Tab("Home", systemImage: "house", value: .home) {
                HomeView()
            }
            Tab("Orders", systemImage: "shippingbox", value: .orders) {
                OrdersView()
            }
            Tab("Bag", systemImage: "bag", value: .bag) {
                CartView()
            }
            .badge(bagCount)
            Tab("Profile", systemImage: "person.crop.circle", value: .profile) {
                ProfileView()
            }
            Tab(value: .search, role: .search) {
                SearchView()
            }
        }
        #if os(iOS)
        .tabBarMinimizeBehavior(.onScrollDown)
        #endif
    }
}

#Preview("Signed in") {
    MainTabView()
        .environment(AppRouter())
        .modelContainer(PreviewSupport.container)
        .tint(Theme.accent)
}
