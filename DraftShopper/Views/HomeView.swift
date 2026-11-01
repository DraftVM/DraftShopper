import SwiftUI
import SwiftData

struct HomeView: View {
    @Query(sort: \ProductCategory.sortOrder) private var categories: [ProductCategory]
    @Query(filter: #Predicate<Product> { $0.isFeatured }, sort: \Product.rating, order: .reverse)
    private var featured: [Product]
    @Query(filter: #Predicate<Product> { $0.isNew }, sort: \Product.name)
    private var newArrivals: [Product]
    @AppStorage(StorageKey.userName) private var userName = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    greeting
                    HeroBanner()
                        .padding(.horizontal)
                    categoryStrip
                    ProductCarousel(title: "Featured", products: featured, destination: .featured)
                    PromoStrip()
                        .padding(.horizontal)
                    ProductCarousel(title: "New Arrivals", products: newArrivals, destination: .newArrivals)
                    categoryGrid
                }
                .padding(.bottom, 24)
            }
            .navigationTitle("Draft Shoppr")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    NavigationLink(value: ListingScope.favorites) {
                        Label("Wishlist", systemImage: "heart")
                    }
                }
            }
            .shopDestinations()
        }
    }

    private var firstName: String {
        userName.split(separator: " ").first.map(String.init) ?? "there"
    }

    private var greeting: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("Hi, \(firstName) 👋")
                .font(.headline)
            Text("What are you shopping for today?")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal)
    }

    private var categoryStrip: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Categories", destination: .all)
            ScrollView(.horizontal) {
                HStack(spacing: 12) {
                    ForEach(categories) { category in
                        NavigationLink(value: ListingScope.category(category)) {
                            VStack(spacing: 8) {
                                Image(systemName: category.symbolName)
                                    .font(.title2)
                                    .foregroundStyle(Theme.accent)
                                    .frame(width: 64, height: 64)
                                    .background(Theme.surface, in: .circle)
                                Text(category.name)
                                    .font(.caption.weight(.medium))
                                    .foregroundStyle(.primary)
                            }
                            .frame(width: 76)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .contentMargins(.horizontal, 16, for: .scrollContent)
            .scrollIndicators(.hidden)
        }
    }

    private var categoryGrid: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Shop by Category")
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 12)], spacing: 12) {
                ForEach(categories) { category in
                    NavigationLink(value: ListingScope.category(category)) {
                        CategoryTile(category: category)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal)
        }
    }
}

/// Large image tile with the category name over a legibility gradient.
private struct CategoryTile: View {
    let category: ProductCategory

    var body: some View {
        Image(category.imageName)
            .resizable()
            .scaledToFill()
            .frame(minWidth: 0, maxWidth: .infinity)
            .frame(height: 150)
            .clipped()
            .overlay {
                LinearGradient(colors: [.clear, .black.opacity(0.65)], startPoint: .center, endPoint: .bottom)
            }
            .overlay(alignment: .bottomLeading) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(category.name)
                        .font(.headline)
                    Text(category.tagline)
                        .font(.caption)
                        .opacity(0.85)
                }
                .foregroundStyle(.white)
                .padding(12)
            }
            .clipShape(.rect(cornerRadius: Theme.cardRadius, style: .continuous))
            .contentShape(.rect)
            .accessibilityElement(children: .combine)
            .accessibilityAddTraits(.isButton)
    }
}

/// Seasonal campaign banner leading to the deals listing.
private struct HeroBanner: View {
    var body: some View {
        NavigationLink(value: ListingScope.deals) {
            HStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 10) {
                    Text("THE FALL DRAFT")
                        .font(.caption.weight(.heavy))
                        .tracking(1.5)
                        .foregroundStyle(Color(hex: 0xFF8467))
                    Text("Up to 25% off\nsound & style")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(.white)
                        .fixedSize(horizontal: false, vertical: true)
                    Text("Shop Deals")
                        .font(.subheadline.weight(.semibold))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(.white, in: .capsule)
                        .foregroundStyle(Color(hex: 0x3426B5))
                        .padding(.top, 4)
                }
                .padding(20)
                Spacer(minLength: 0)
                Image("headphones_aurum")
                    .resizable()
                    .scaledToFill()
                    .frame(width: 160)
                    .clipped()
                    // Screen blending drops the photo's black backdrop into the brand gradient.
                    .blendMode(.screen)
                    .accessibilityHidden(true)
            }
            .frame(height: 190)
            .background(Theme.heroGradient)
            .clipShape(.rect(cornerRadius: 24, style: .continuous))
            .overlay {
                // Dashed inset outline: the "draft" brand motif.
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(Color(hex: 0xFF8467).opacity(0.5), style: StrokeStyle(lineWidth: 1.5, dash: [6, 5]))
                    .padding(8)
                    .allowsHitTesting(false)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("The Fall Draft. Up to 25% off sound and style. Shop deals.")
    }
}

/// Free-shipping and promo code callouts.
private struct PromoStrip: View {
    var body: some View {
        HStack(spacing: 12) {
            promo(symbol: "shippingbox.fill", title: "Free shipping", detail: "On orders over \(Pricing.freeShippingThreshold.currency)")
            promo(symbol: "tag.fill", title: "Code DRAFT10", detail: "10% off your bag")
        }
    }

    private func promo(symbol: String, title: String, detail: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: symbol)
                .foregroundStyle(Theme.coral)
                .font(.title3)
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.footnote.weight(.semibold))
                Text(detail)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
        }
        .padding(12)
        .frame(maxWidth: .infinity)
        .background(Theme.surface, in: .rect(cornerRadius: 14, style: .continuous))
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    HomeView()
        .environment(AppRouter())
        .modelContainer(PreviewSupport.container)
        .tint(Theme.accent)
}
