import Foundation
import SwiftData

/// Static catalog that populates the on-device SwiftData store on first launch.
enum SeedData {
    private static let shoeSizes = ["7", "8", "9", "10", "11", "12"]
    private static let apparelSizes = ["XS", "S", "M", "L", "XL"]

    static func seedIfNeeded(_ context: ModelContext) {
        let count = (try? context.fetchCount(FetchDescriptor<Product>())) ?? 0
        guard count == 0 else { return }
        seed(context)
    }

    /// Wipes the bag, orders, and catalog, then reseeds. Used by "Reset Demo Data".
    static func reset(_ context: ModelContext) {
        // Batch deletes only affect saved data, so flush pending inserts first or they'd survive the reset.
        try? context.save()
        try? context.delete(model: CartItem.self)
        try? context.delete(model: OrderLine.self)
        try? context.delete(model: CustomerOrder.self)
        try? context.delete(model: Product.self)
        try? context.delete(model: ProductCategory.self)
        try? context.save()
        seed(context)
    }

    private static func seed(_ context: ModelContext) {
        let categories = makeCategories()
        categories.forEach(context.insert)
        let byID = Dictionary(uniqueKeysWithValues: categories.map { ($0.id, $0) })

        for (categoryID, product) in makeProducts() {
            context.insert(product)
            product.category = byID[categoryID]
        }
        seedOrders(context)
        try? context.save()
    }

    private static func makeCategories() -> [ProductCategory] {
        [
            ProductCategory(id: "footwear", name: "Footwear", symbolName: "shoe.2.fill", tagline: "Step into something new", imageName: "sneakers_white", sortOrder: 0),
            ProductCategory(id: "audio", name: "Audio", symbolName: "headphones", tagline: "Sound, refined", imageName: "headphones_aurum", sortOrder: 1),
            ProductCategory(id: "accessories", name: "Accessories", symbolName: "handbag.fill", tagline: "The finishing touch", imageName: "watch_chrono", sortOrder: 2),
            ProductCategory(id: "apparel", name: "Apparel", symbolName: "tshirt.fill", tagline: "Everyday essentials", imageName: "jacket_denim", sortOrder: 3),
            ProductCategory(id: "home", name: "Home", symbolName: "lamp.desk.fill", tagline: "Make it yours", imageName: "lamp_desk", sortOrder: 4),
            ProductCategory(id: "tech", name: "Tech", symbolName: "camera.fill", tagline: "Tools for creators", imageName: "camera_mirrorless", sortOrder: 5),
        ]
    }

    private static func makeProducts() -> [(String, Product)] {
        [
            // Footwear
            ("footwear", Product(
                id: "sneakers_white", name: "Everyday Court Sneaker", brand: "Fieldnote",
                summary: "A clean, low-profile sneaker in soft full-grain leather that goes with everything from denim to tailoring.",
                highlights: ["Full-grain leather upper", "Cushioned cork-blend footbed", "Stitched rubber cupsole", "Waxed cotton laces"],
                price: 89, originalPrice: 110, rating: 4.7, reviewCount: 312, imageName: "sneakers_white",
                colors: ["Chalk", "Black"], sizes: shoeSizes, isFeatured: true)),
            ("footwear", Product(
                id: "shoes_running", name: "Stride Knit Runner", brand: "Tern Athletics",
                summary: "Lightweight daily trainer with a breathable knit upper and responsive foam that keeps every mile feeling fresh.",
                highlights: ["Engineered knit upper", "Responsive foam midsole", "8 mm heel-to-toe drop", "Reflective heel tab"],
                price: 129, rating: 4.5, reviewCount: 208, imageName: "shoes_running",
                colors: ["Graphite", "Volt"], sizes: shoeSizes, isNew: true)),
            ("footwear", Product(
                id: "boots_chukka", name: "Heritage Leather Chukka", brand: "Northloom",
                summary: "A hand-finished chukka in burnished leather with a Goodyear-welted sole built to be resoled for years.",
                highlights: ["Burnished calf leather", "Goodyear-welted construction", "Leather-lined interior", "Made in Portugal"],
                price: 168, rating: 4.8, reviewCount: 96, imageName: "boots_chukka",
                colors: ["Cognac", "Espresso"], sizes: shoeSizes, isFeatured: true)),
            ("footwear", Product(
                id: "boots_hiking", name: "Ridge Trail Boot", brand: "Tern Athletics",
                summary: "Waterproof mid-height hiker with aggressive lugs and ankle support for rocky, rooty trails.",
                highlights: ["Waterproof breathable membrane", "Vibram-style lug outsole", "Padded ankle collar", "Gusseted tongue"],
                price: 145, originalPrice: 175, rating: 4.4, reviewCount: 141, imageName: "boots_hiking",
                colors: ["Slate", "Moss"], sizes: shoeSizes)),

            // Audio
            ("audio", Product(
                id: "headphones_studio", name: "Monitor One Studio Headphones", brand: "Atlas Audio",
                summary: "Closed-back reference headphones with a flat, honest response for mixing, editing, and focused listening.",
                highlights: ["45 mm neodymium drivers", "Closed-back isolation", "Detachable coiled cable", "Memory-foam ear cushions"],
                price: 199, rating: 4.6, reviewCount: 540, imageName: "headphones_studio",
                colors: ["Matte Black"], isFeatured: true)),
            ("audio", Product(
                id: "headphones_wireless", name: "Pulse Wireless Headphones", brand: "Atlas Audio",
                summary: "Bold, lightweight wireless headphones with punchy sound and all-day battery life.",
                highlights: ["Up to 40 hours of playback", "Bluetooth 5.3 multipoint", "Fast charge: 10 min = 4 hrs", "Foldable design"],
                price: 149, originalPrice: 179, rating: 4.3, reviewCount: 377, imageName: "headphones_wireless",
                colors: ["Crimson", "Snow", "Midnight"])),
            ("audio", Product(
                id: "headphones_aurum", name: "Aurum ANC Headphones", brand: "Atlas Audio",
                summary: "Our flagship noise-cancelling headphones, finished in brushed brass with adaptive ANC that tunes itself to your surroundings.",
                highlights: ["Adaptive active noise cancellation", "Spatial audio with head tracking", "30-hour battery", "Brushed brass accents"],
                price: 279, rating: 4.8, reviewCount: 129, imageName: "headphones_aurum",
                colors: ["Navy & Brass"], isFeatured: true, isNew: true)),
            ("audio", Product(
                id: "speaker_portable", name: "Pocket Boom Speaker", brand: "Lumen Works",
                summary: "A palm-sized Bluetooth speaker with surprising bass and a splash-proof shell for the beach or the shower.",
                highlights: ["IPX5 splash resistance", "12-hour battery", "Stereo pairing", "Built-in speakerphone"],
                price: 59, rating: 4.2, reviewCount: 860, imageName: "speaker_portable",
                colors: ["Charcoal", "Sand"])),
            ("audio", Product(
                id: "turntable_retro", name: "Crate Portable Turntable", brand: "Kettle & Co.",
                summary: "A suitcase-style record player with built-in speakers, wrapped in walnut veneer for that mid-century look.",
                highlights: ["33⅓, 45 and 78 RPM", "Built-in stereo speakers", "RCA and Bluetooth out", "Walnut veneer case"],
                price: 219, rating: 4.5, reviewCount: 74, imageName: "turntable_retro",
                colors: ["Walnut"], stock: 3, isFeatured: true)),

            // Accessories
            ("accessories", Product(
                id: "watch_chrono", name: "Meridian Chronograph", brand: "Oakmoss",
                summary: "A dress chronograph with a crisp white dial, sub-seconds, and a padded leather strap.",
                highlights: ["Japanese quartz chronograph", "Sapphire-coated crystal", "50 m water resistance", "Italian leather strap"],
                price: 249, originalPrice: 299, rating: 4.7, reviewCount: 188, imageName: "watch_chrono",
                colors: ["Steel/Black"], isFeatured: true)),
            ("accessories", Product(
                id: "watch_vintage", name: "Field 1962 Automatic", brand: "Oakmoss",
                summary: "A faithful re-edition of a 1960s field watch with an automatic movement and a soft suede strap.",
                highlights: ["Automatic movement, 40-hr reserve", "Domed crystal", "Exhibition caseback", "Tan suede strap"],
                price: 329, rating: 4.9, reviewCount: 53, imageName: "watch_vintage",
                colors: ["Tan Suede"], stock: 0, isNew: true)),
            ("accessories", Product(
                id: "sunglasses_round", name: "Coastline Sunglasses", brand: "Fieldnote",
                summary: "Classic acetate frames with polarized lenses that cut glare without dulling color.",
                highlights: ["Polarized CR-39 lenses", "100% UVA/UVB protection", "Hand-polished acetate", "Includes hard case"],
                price: 79, rating: 4.4, reviewCount: 265, imageName: "sunglasses_round",
                colors: ["Black", "Tortoise"])),
            ("accessories", Product(
                id: "backpack_canvas", name: "Waxed Canvas Rucksack", brand: "Northloom",
                summary: "A roll-top rucksack in weatherproof waxed canvas with leather trim that only gets better with age.",
                highlights: ["Waxed cotton canvas", "Padded 15\" laptop sleeve", "Vegetable-tanned leather trim", "22 L capacity"],
                price: 135, rating: 4.6, reviewCount: 152, imageName: "backpack_canvas",
                colors: ["Sand", "Olive"])),
            ("accessories", Product(
                id: "wallet_leather", name: "Slim Bifold Wallet", brand: "Northloom",
                summary: "Minimal pebbled-leather bifold that holds your essentials without the bulk.",
                highlights: ["Pebbled full-grain leather", "6 card slots + bill pocket", "RFID-blocking lining", "Under 1 cm thick"],
                price: 49, originalPrice: 65, rating: 4.5, reviewCount: 410, imageName: "wallet_leather",
                colors: ["Black", "Cognac"])),

            // Apparel
            ("apparel", Product(
                id: "jacket_denim", name: "Classic Trucker Jacket", brand: "Draft Studio",
                summary: "The denim jacket you'll reach for every season, cut from rigid cotton denim with a broken-in wash.",
                highlights: ["100% cotton 12 oz denim", "Button-flap chest pockets", "Relaxed fit", "Garment washed for softness"],
                price: 98, rating: 4.6, reviewCount: 233, imageName: "jacket_denim",
                colors: ["Light Wash", "Indigo"], sizes: apparelSizes, isFeatured: true)),
            ("apparel", Product(
                id: "tshirt_essential", name: "Essential Heavyweight Tee", brand: "Draft Studio",
                summary: "A structured heavyweight tee that holds its shape wash after wash.",
                highlights: ["240 gsm organic cotton", "Ribbed crew neck", "Pre-shrunk", "Boxy, modern fit"],
                price: 28, originalPrice: 35, rating: 4.4, reviewCount: 1020, imageName: "tshirt_essential",
                colors: ["Graphite", "White", "Navy"], sizes: apparelSizes)),
            ("apparel", Product(
                id: "sweater_knit", name: "Fisherman Knit Sweater", brand: "Northloom",
                summary: "A chunky cable-knit sweater in soft lambswool, made for cold mornings and long walks.",
                highlights: ["100% lambswool", "Traditional cable knit", "Ribbed cuffs and hem", "Hand wash or dry clean"],
                price: 118, rating: 4.8, reviewCount: 87, imageName: "sweater_knit",
                colors: ["Oat", "Charcoal"], sizes: apparelSizes, isNew: true)),

            // Home
            ("home", Product(
                id: "mug_ceramic", name: "Stoneware Morning Mug", brand: "Kettle & Co.",
                summary: "A generous, hand-glazed stoneware mug that keeps your coffee warm and your mornings slow.",
                highlights: ["12 oz capacity", "Hand-glazed stoneware", "Dishwasher and microwave safe", "Each piece is unique"],
                price: 22, rating: 4.7, reviewCount: 640, imageName: "mug_ceramic",
                colors: ["Cloud", "Sage"])),
            ("home", Product(
                id: "serveware_set", name: "Monochrome Serve Set", brand: "Kettle & Co.",
                summary: "A graphic black-and-white porcelain set for coffee, sugar, and everything in between.",
                highlights: ["Cup, sugar bowl and vessel", "Fine porcelain", "Woven rattan tray included", "Dishwasher safe"],
                price: 64, originalPrice: 80, rating: 4.3, reviewCount: 58, imageName: "serveware_set",
                colors: ["Black & White"])),
            ("home", Product(
                id: "lamp_desk", name: "Arc Desk Lamp", brand: "Lumen Works",
                summary: "A slender, adjustable desk lamp with warm, flicker-free light that's easy on the eyes.",
                highlights: ["Adjustable arm and shade", "Warm 2700K LED", "Touch dimmer, 3 levels", "Weighted steel base"],
                price: 89, rating: 4.5, reviewCount: 190, imageName: "lamp_desk",
                colors: ["White", "Black"], isFeatured: true)),
            ("home", Product(
                id: "planter_ceramic", name: "Glazed Cobalt Planter", brand: "Oakmoss",
                summary: "A deep cobalt glazed planter that makes any succulent or trailing plant the star of the shelf.",
                highlights: ["6\" diameter", "Reactive cobalt glaze", "Drainage hole and cork plug", "Plant not included"],
                price: 38, rating: 4.6, reviewCount: 112, imageName: "planter_ceramic",
                colors: ["Cobalt"], isNew: true)),
            ("home", Product(
                id: "candle_pillar", name: "Ember Pillar Candle", brand: "Oakmoss",
                summary: "A slow-burning, unscented pillar candle poured from natural soy and beeswax.",
                highlights: ["Soy and beeswax blend", "60+ hour burn time", "Cotton wick", "Unscented"],
                price: 24, rating: 4.4, reviewCount: 301, imageName: "candle_pillar",
                colors: ["Ivory"])),

            // Tech
            ("tech", Product(
                id: "camera_mirrorless", name: "Vista Pro Camera Kit", brand: "Lumen Works",
                summary: "A weather-sealed camera with a fast telephoto lens, ready for wildlife, sports, and everything in between.",
                highlights: ["24 MP full-frame sensor", "70–200 mm f/4 lens included", "In-body stabilization", "4K 60p video"],
                price: 1199, rating: 4.8, reviewCount: 64, imageName: "camera_mirrorless",
                colors: ["Black"], isFeatured: true)),
            ("tech", Product(
                id: "keyboard_backlit", name: "Nightfall Backlit Keyboard", brand: "Lumen Works",
                summary: "A low-profile mechanical keyboard with per-key backlighting for late-night sessions.",
                highlights: ["Tactile low-profile switches", "Per-key RGB backlight", "USB-C and Bluetooth", "Aluminum top plate"],
                price: 119, originalPrice: 139, rating: 4.5, reviewCount: 288, imageName: "keyboard_backlit",
                colors: ["Black"])),
            ("tech", Product(
                id: "mouse_wired", name: "Precision Wired Mouse", brand: "Lumen Works",
                summary: "A comfortable, no-fuss mouse with a precise optical sensor and a silent scroll wheel.",
                highlights: ["1600 DPI optical sensor", "Ambidextrous shape", "Silent scroll wheel", "1.8 m braided cable"],
                price: 25, rating: 4.2, reviewCount: 950, imageName: "mouse_wired",
                colors: ["Black"])),
            ("tech", Product(
                id: "smartwatch_round", name: "Orbit Smartwatch", brand: "Tern Athletics",
                summary: "A round-faced smartwatch with an always-on display, GPS, and health tracking in a lightweight case.",
                highlights: ["1.4\" always-on AMOLED", "Built-in GPS", "Heart rate and SpO₂", "7-day battery"],
                price: 229, rating: 4.4, reviewCount: 171, imageName: "smartwatch_round",
                colors: ["Sand", "Black"], isNew: true)),
            ("tech", Product(
                id: "band_fitness", name: "Pace Fitness Band", brand: "Tern Athletics",
                summary: "A slim fitness band that tracks steps, sleep, and workouts for two full weeks on a charge.",
                highlights: ["14-day battery life", "Sleep and stress tracking", "Swim-proof to 50 m", "Quick-release band"],
                price: 59, rating: 4.1, reviewCount: 640, imageName: "band_fitness",
                colors: ["Black", "Ocean"])),
        ]
    }

    /// A couple of past orders so the Orders tab has history from the start.
    private static func seedOrders(_ context: ModelContext) {
        let address = "1 Infinite Loop, Cupertino, CA 95014"
        let calendar = Calendar.current

        let delivered = CustomerOrder(
            number: "DS-24817",
            placedAt: calendar.date(byAdding: .day, value: -18, to: .now) ?? .now,
            status: .delivered,
            subtotal: 72, discount: 0, shipping: 6.99, tax: Pricing.tax(on: 72),
            shippingAddress: address, deliveryMethod: "Standard · 3–5 business days", paymentMethod: PaymentMethod.applePay.title
        )
        context.insert(delivered)
        for line in [
            OrderLine(productID: "mug_ceramic", name: "Stoneware Morning Mug", brand: "Kettle & Co.", imageName: "mug_ceramic", price: 22, quantity: 2, size: nil, color: "Cloud"),
            OrderLine(productID: "tshirt_essential", name: "Essential Heavyweight Tee", brand: "Draft Studio", imageName: "tshirt_essential", price: 28, quantity: 1, size: "M", color: "Graphite"),
        ] {
            context.insert(line)
            line.order = delivered
        }

        let shipped = CustomerOrder(
            number: "DS-25033",
            placedAt: calendar.date(byAdding: .day, value: -2, to: .now) ?? .now,
            status: .shipped,
            subtotal: 149, discount: 14.90, shipping: 0, tax: Pricing.tax(on: 134.10),
            shippingAddress: address, deliveryMethod: "Standard · 3–5 business days", paymentMethod: PaymentMethod.visa.title
        )
        context.insert(shipped)
        let headphones = OrderLine(productID: "headphones_wireless", name: "Pulse Wireless Headphones", brand: "Atlas Audio", imageName: "headphones_wireless", price: 149, quantity: 1, size: nil, color: "Crimson")
        context.insert(headphones)
        headphones.order = shipped
    }
}
