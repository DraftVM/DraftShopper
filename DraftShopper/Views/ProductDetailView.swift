import SwiftUI
import SwiftData

struct ProductDetailView: View {
    let product: Product

    @Environment(\.modelContext) private var modelContext
    @Environment(AppRouter.self) private var router
    @State private var selectedColor: String?
    @State private var selectedSize: String?
    @State private var quantity = 1
    @State private var showSizeError = false
    @State private var addedCount = 0
    @State private var showAddedBanner = false

    private var related: [Product] {
        (product.category?.products ?? [])
            .filter { $0.id != product.id }
            .sorted(by: .featured)
            .prefix(8)
            .map { $0 }
    }

    private var maxQuantity: Int { max(1, min(10, product.stock)) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                ProductImage(name: product.imageName, cornerRadius: 28)
                    .overlay(alignment: .topLeading) {
                        HStack(spacing: 6) {
                            if product.isOnSale { BadgeLabel(text: "-\(product.discountPercent)%") }
                            if product.isNew { BadgeLabel(text: "NEW", tint: Theme.accent) }
                        }
                        .padding(14)
                    }

                header
                if !product.colors.isEmpty { colorPicker }
                if !product.sizes.isEmpty { sizePicker }
                quantityPicker
                aboutSection
                infoSection
                ProductCarousel(title: "You May Also Like", products: related)
                    .padding(.horizontal, -16)
            }
            .padding(.horizontal)
            .padding(.bottom, 24)
        }
        .navigationTitle(product.brand)
        .inlineNavigationTitle()
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                FavoriteButton(product: product, style: .toolbar)
                ShareLink(
                    item: "Check out the \(product.name) by \(product.brand) on Draft Shoppr, just \(product.price.currency)!",
                    preview: SharePreview(product.name, image: Image(product.imageName))
                )
            }
        }
        .safeAreaBar(edge: .bottom) { purchaseBar }
        .overlay(alignment: .top) {
            if showAddedBanner { addedBanner }
        }
        .sensoryFeedback(.success, trigger: addedCount)
        .onAppear {
            if selectedColor == nil { selectedColor = product.colors.first }
        }
        .task(id: addedCount) {
            guard addedCount > 0 else { return }
            try? await Task.sleep(for: .seconds(2.5))
            withAnimation { showAddedBanner = false }
        }
    }

    // MARK: Sections

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(product.brand.uppercased())
                .font(.caption.weight(.bold))
                .tracking(1)
                .foregroundStyle(Theme.accent)
            Text(product.name)
                .font(.title2.weight(.bold))
                .foregroundStyle(Theme.ink)
            RatingView(rating: product.rating, reviewCount: product.reviewCount)
            HStack(alignment: .firstTextBaseline) {
                PriceView(price: product.price, originalPrice: product.originalPrice, font: .title2)
                Spacer()
                stockLabel
            }
            .padding(.top, 4)
        }
    }

    @ViewBuilder private var stockLabel: some View {
        if !product.isInStock {
            Label("Out of Stock", systemImage: "xmark.circle.fill")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.red)
        } else if product.stock <= 5 {
            Label("Only \(product.stock) left", systemImage: "flame.fill")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(Theme.coral)
        } else {
            Label("In Stock", systemImage: "checkmark.circle.fill")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.green)
        }
    }

    private var colorPicker: some View {
        VStack(alignment: .leading, spacing: 10) {
            optionTitle("Color", value: selectedColor)
            HStack(spacing: 12) {
                ForEach(product.colors, id: \.self) { color in
                    let isSelected = color == selectedColor
                    Button {
                        selectedColor = color
                    } label: {
                        Circle()
                            .fill(Theme.swatch(for: color))
                            .overlay { Circle().strokeBorder(.separator, lineWidth: 1) }
                            .frame(width: 32, height: 32)
                            .padding(4)
                            .overlay {
                                Circle().strokeBorder(isSelected ? Theme.accent : .clear, lineWidth: 2)
                            }
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(color)
                    .accessibilityAddTraits(isSelected ? .isSelected : [])
                }
            }
        }
        .sensoryFeedback(.selection, trigger: selectedColor)
    }

    private var sizePicker: some View {
        VStack(alignment: .leading, spacing: 10) {
            optionTitle("Size", value: selectedSize)
            ScrollView(.horizontal) {
                HStack(spacing: 8) {
                    ForEach(product.sizes, id: \.self) { size in
                        let isSelected = size == selectedSize
                        Button {
                            selectedSize = size
                            withAnimation { showSizeError = false }
                        } label: {
                            Text(size)
                                .font(.subheadline.weight(.semibold))
                                .frame(minWidth: 48, minHeight: 44)
                                .padding(.horizontal, 4)
                                .foregroundStyle(isSelected ? Color.white : Color.primary)
                                .background(isSelected ? Theme.accent : Theme.surface, in: .rect(cornerRadius: 12, style: .continuous))
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Size \(size)")
                        .accessibilityAddTraits(isSelected ? .isSelected : [])
                    }
                }
            }
            .scrollIndicators(.hidden)
            if showSizeError {
                Label("Please select a size", systemImage: "exclamationmark.circle.fill")
                    .font(.footnote)
                    .foregroundStyle(.red)
                    .transition(.opacity)
            }
        }
        .sensoryFeedback(.selection, trigger: selectedSize)
    }

    private var quantityPicker: some View {
        Stepper(value: $quantity, in: 1...maxQuantity) {
            HStack {
                Text("Quantity")
                    .font(.headline)
                Spacer()
                Text("\(quantity)")
                    .font(.body.monospacedDigit().weight(.semibold))
                    .padding(.trailing, 8)
            }
        }
        .disabled(!product.isInStock)
    }

    private var aboutSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("About This Item")
                .font(.headline)
            Text(product.summary)
                .font(.body)
                .foregroundStyle(.secondary)
            VStack(alignment: .leading, spacing: 8) {
                ForEach(product.highlights, id: \.self) { highlight in
                    Label {
                        Text(highlight)
                    } icon: {
                        Image(systemName: "checkmark")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(Theme.accent)
                    }
                    .font(.subheadline)
                }
            }
            .padding(.top, 2)
        }
    }

    private var infoSection: some View {
        VStack(spacing: 0) {
            infoRow(symbol: "shippingbox", title: "Free shipping over \(Pricing.freeShippingThreshold.currency)", detail: "Standard delivery in 3–5 business days")
            Divider().padding(.leading, 48)
            infoRow(symbol: "arrow.uturn.backward", title: "Free 30-day returns", detail: "Send it back in its original condition")
            Divider().padding(.leading, 48)
            infoRow(symbol: "checkmark.shield", title: "1-year warranty", detail: "Covered against manufacturing defects")
        }
        .background(Theme.surface, in: .rect(cornerRadius: 16, style: .continuous))
    }

    private func infoRow(symbol: String, title: String, detail: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: symbol)
                .font(.title3)
                .foregroundStyle(Theme.accent)
                .frame(width: 26)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.subheadline.weight(.semibold))
                Text(detail).font(.caption).foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
        }
        .padding(14)
        .accessibilityElement(children: .combine)
    }

    private func optionTitle(_ title: String, value: String?) -> some View {
        HStack(spacing: 4) {
            Text(title).font(.headline)
            if let value {
                Text(value).foregroundStyle(.secondary)
            }
        }
    }

    // MARK: Purchase

    private var purchaseBar: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 0) {
                Text("Total")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text((product.price * Double(quantity)).currency)
                    .font(.title3.weight(.bold))
                    .contentTransition(.numericText())
            }
            Button(action: addToBag) {
                Label(product.isInStock ? "Add to Bag" : "Sold Out", systemImage: "bag.badge.plus")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.glassProminent)
            .controlSize(.large)
            .disabled(!product.isInStock)
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
        .animation(.snappy, value: quantity)
    }

    private var addedBanner: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .font(.title3)
                .foregroundStyle(.green)
            Text("Added to your bag")
                .font(.subheadline.weight(.semibold))
            Spacer()
            Button("View Bag") {
                router.selectedTab = .bag
            }
            .font(.subheadline.weight(.bold))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .glassEffect(.regular, in: .capsule)
        .padding(.horizontal)
        .padding(.top, 8)
        .transition(.move(edge: .top).combined(with: .opacity))
    }

    private func addToBag() {
        if !product.sizes.isEmpty && selectedSize == nil {
            withAnimation { showSizeError = true }
            return
        }
        modelContext.addToCart(product, quantity: quantity, size: selectedSize, color: selectedColor)
        addedCount += 1
        withAnimation(.snappy) { showAddedBanner = true }
    }
}

#Preview {
    NavigationStack {
        ProductDetailView(product: PreviewSupport.sampleProduct)
            .shopDestinations()
    }
    .environment(AppRouter())
    .modelContainer(PreviewSupport.container)
    .tint(Theme.accent)
}
