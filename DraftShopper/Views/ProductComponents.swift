import SwiftUI
import SwiftData

/// Square product photo with rounded corners.
struct ProductImage: View {
    let name: String
    var cornerRadius: CGFloat = Theme.cardRadius

    var body: some View {
        Image(name)
            .resizable()
            .scaledToFit()
            .clipShape(.rect(cornerRadius: cornerRadius, style: .continuous))
            .accessibilityHidden(true)
    }
}

/// Heart toggle that adds or removes a product from the wishlist.
struct FavoriteButton: View {
    @Bindable var product: Product
    var style: Style = .overlay

    enum Style { case overlay, toolbar }

    var body: some View {
        Button {
            withAnimation(.snappy) { product.isFavorite.toggle() }
        } label: {
            switch style {
            case .overlay:
                Image(systemName: product.isFavorite ? "heart.fill" : "heart")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(product.isFavorite ? Theme.coral : .primary)
                    .frame(width: 34, height: 34)
                    .glassEffect(.regular.interactive(), in: .circle)
            case .toolbar:
                Image(systemName: product.isFavorite ? "heart.fill" : "heart")
                    .foregroundStyle(product.isFavorite ? Theme.coral : .primary)
            }
        }
        .buttonStyle(.plain)
        .contentTransition(.symbolEffect(.replace))
        .sensoryFeedback(.selection, trigger: product.isFavorite)
        .accessibilityLabel(product.isFavorite ? "Remove from Wishlist" : "Add to Wishlist")
    }
}

/// Grid / carousel card linking to the product's detail screen.
struct ProductCard: View {
    let product: Product

    var body: some View {
        NavigationLink(value: product) {
            VStack(alignment: .leading, spacing: 8) {
                ProductImage(name: product.imageName)
                    .overlay(alignment: .topLeading) { badge.padding(10) }
                    .overlay {
                        if !product.isInStock {
                            RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous)
                                .fill(.black.opacity(0.35))
                                .overlay {
                                    Text("Sold Out")
                                        .font(.caption.weight(.bold))
                                        .foregroundStyle(.white)
                                }
                        }
                    }

                VStack(alignment: .leading, spacing: 3) {
                    Text(product.brand.uppercased())
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Text(product.name)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.primary)
                        .lineLimit(2, reservesSpace: true)
                        .multilineTextAlignment(.leading)
                    HStack {
                        PriceView(price: product.price, originalPrice: product.originalPrice)
                        Spacer(minLength: 4)
                        RatingView(rating: product.rating)
                    }
                }
                .padding(.horizontal, 2)
            }
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .overlay(alignment: .topTrailing) {
            FavoriteButton(product: product)
                .padding(8)
        }
        .accessibilityElement(children: .contain)
    }

    @ViewBuilder private var badge: some View {
        if product.isOnSale {
            BadgeLabel(text: "-\(product.discountPercent)%")
        } else if product.isNew {
            BadgeLabel(text: "NEW", tint: Theme.accent)
        }
    }
}

/// Compact list row used by search results.
struct ProductRow: View {
    let product: Product

    var body: some View {
        HStack(spacing: 14) {
            ProductImage(name: product.imageName, cornerRadius: 12)
                .frame(width: 64, height: 64)
            VStack(alignment: .leading, spacing: 3) {
                Text(product.name)
                    .font(.subheadline.weight(.medium))
                    .lineLimit(2)
                Text(product.brand)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                PriceView(price: product.price, originalPrice: product.originalPrice, font: .footnote)
            }
        }
        .padding(.vertical, 2)
    }
}

/// Section title with an optional "See All" link.
struct SectionHeader: View {
    let title: String
    var destination: ListingScope?

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .font(.title3.weight(.bold))
                .foregroundStyle(Theme.ink)
                .accessibilityAddTraits(.isHeader)
            Spacer()
            if let destination {
                NavigationLink("See All", value: destination)
                    .font(.subheadline.weight(.semibold))
            }
        }
        .padding(.horizontal)
    }
}

/// Horizontally scrolling row of product cards.
struct ProductCarousel: View {
    let title: String
    let products: [Product]
    var destination: ListingScope?

    var body: some View {
        if !products.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                SectionHeader(title: title, destination: destination)
                ScrollView(.horizontal) {
                    LazyHStack(alignment: .top, spacing: 14) {
                        ForEach(products) { product in
                            ProductCard(product: product)
                                .frame(width: 168)
                        }
                    }
                    .scrollTargetLayout()
                }
                .contentMargins(.horizontal, 16, for: .scrollContent)
                .scrollTargetBehavior(.viewAligned)
                .scrollIndicators(.hidden)
            }
        }
    }
}

#Preview {
    NavigationStack {
        ProductCard(product: PreviewSupport.sampleProduct)
            .frame(width: 180)
            .padding()
    }
    .modelContainer(PreviewSupport.container)
    .tint(Theme.accent)
}
