import SwiftUI

/// Draft Shoppr's "Ink & Marker" brand palette. Each color has light and dark variants in the asset catalog.
enum Theme {
    /// Ink Indigo, the primary brand color (also the app's AccentColor).
    static let accent = Color("AccentColor")
    /// Marker Coral, used for sale prices, badges, and highlights.
    static let coral = Color("BrandCoral")
    /// Indigo-tinted surface for chips, tiles, and grouped content.
    static let surface = Color("BrandSurface")
    /// High-contrast headline color that reads as deep indigo in light mode.
    static let ink = Color("BrandInk")

    static let cardRadius: CGFloat = 18

    static let heroGradient = LinearGradient(
        colors: [Color(hex: 0x5B4BFF), Color(hex: 0x3426B5)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    /// Approximate swatch for a product color name.
    static func swatch(for name: String) -> Color {
        swatches[name] ?? .gray
    }

    private static let swatches: [String: Color] = [
        "Chalk": Color(hex: 0xF4F1EA), "Black": Color(hex: 0x1C1C1E), "Graphite": Color(hex: 0x4A4A4F),
        "Volt": Color(hex: 0xC6F432), "Cognac": Color(hex: 0x9A4E22), "Espresso": Color(hex: 0x4B2E20),
        "Slate": Color(hex: 0x5D6670), "Moss": Color(hex: 0x6B7445), "Matte Black": Color(hex: 0x2A2A2C),
        "Crimson": Color(hex: 0xC8202F), "Snow": Color(hex: 0xF7F7F7), "Midnight": Color(hex: 0x1D2340),
        "Navy & Brass": Color(hex: 0x2B3352), "Charcoal": Color(hex: 0x3A3B3F), "Sand": Color(hex: 0xD9C7A7),
        "Walnut": Color(hex: 0x7A5233), "Steel/Black": Color(hex: 0xA7ABB1), "Tan Suede": Color(hex: 0xB08A62),
        "Tortoise": Color(hex: 0x6E4A2B), "Olive": Color(hex: 0x6A6B3A), "Light Wash": Color(hex: 0x9DB5D3),
        "Indigo": Color(hex: 0x2E3A66), "White": Color(hex: 0xFAFAFA), "Navy": Color(hex: 0x1F2A4D),
        "Oat": Color(hex: 0xE6DCC8), "Cloud": Color(hex: 0xF0F0F2), "Sage": Color(hex: 0xA8B5A0),
        "Black & White": Color(hex: 0x777777), "Cobalt": Color(hex: 0x1F4AA8), "Ivory": Color(hex: 0xF6EFDC),
        "Ocean": Color(hex: 0x1E6F8C),
    ]
}

extension Color {
    init(hex: UInt32) {
        self.init(
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255
        )
    }
}

/// The app logo, drawn from the bundled brand artwork.
struct BrandLogo: View {
    var size: CGFloat = 72

    var body: some View {
        Image("BrandLogo")
            .resizable()
            .scaledToFit()
            .frame(width: size, height: size)
            .clipShape(.rect(cornerRadius: size * 0.225, style: .continuous))
            .shadow(color: Theme.accent.opacity(0.3), radius: size * 0.12, y: size * 0.06)
            .accessibilityHidden(true)
    }
}

/// Small capsule label, e.g. "-20%" or "NEW".
struct BadgeLabel: View {
    let text: String
    var tint: Color = Theme.coral

    var body: some View {
        Text(text)
            .font(.caption2.weight(.bold))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .foregroundStyle(.white)
            .background(tint, in: .capsule)
    }
}

/// Star rating with numeric value and review count.
struct RatingView: View {
    let rating: Double
    var reviewCount: Int?

    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: "star.fill")
                .foregroundStyle(.orange)
                .imageScale(.small)
            Text(rating, format: .number.precision(.fractionLength(1)))
                .fontWeight(.semibold)
            if let reviewCount {
                Text("(\(reviewCount))")
                    .foregroundStyle(.secondary)
            }
        }
        .font(.caption)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityText)
    }

    private var accessibilityText: String {
        let stars = rating.formatted(.number.precision(.fractionLength(1)))
        if let reviewCount { return "Rated \(stars) out of 5, \(reviewCount) reviews" }
        return "Rated \(stars) out of 5"
    }
}

/// Current price with an optional struck-through original price.
struct PriceView: View {
    let price: Double
    var originalPrice: Double?
    var font: Font = .subheadline

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 6) {
            Text(price.currency)
                .font(font.weight(.bold))
                .foregroundStyle(isOnSale ? Theme.coral : .primary)
            if let originalPrice, isOnSale {
                Text(originalPrice.currency)
                    .font(.caption)
                    .strikethrough()
                    .foregroundStyle(.secondary)
                    .accessibilityLabel("was \(originalPrice.currency)")
            }
        }
    }

    private var isOnSale: Bool { (originalPrice ?? 0) > price }
}
