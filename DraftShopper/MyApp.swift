import SwiftUI
import SwiftData

@main struct MyApp: App {
    private let container: ModelContainer
    @State private var router = AppRouter()

    init() {
        do {
            container = try ModelContainer(for: ProductCategory.self, Product.self, CartItem.self, CustomerOrder.self, OrderLine.self)
        } catch {
            fatalError("Unable to open the Draft Shoppr store: \(error)")
        }
        SeedData.seedIfNeeded(container.mainContext)
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(router)
        }
        .modelContainer(container)
    }
}
