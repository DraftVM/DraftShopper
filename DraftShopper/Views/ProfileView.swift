import SwiftUI
import SwiftData

struct ProfileView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AppRouter.self) private var router
    @AppStorage(StorageKey.isSignedIn) private var isSignedIn = false
    @AppStorage(StorageKey.userName) private var userName = ""
    @AppStorage(StorageKey.userEmail) private var userEmail = ""
    @AppStorage(StorageKey.memberSince) private var memberSince = 0.0
    @AppStorage(StorageKey.appearance) private var appearance: AppAppearance = .system
    @AppStorage(StorageKey.orderUpdates) private var orderUpdates = true

    @Query(filter: #Predicate<Product> { $0.isFavorite }) private var favorites: [Product]
    @Query private var orders: [CustomerOrder]

    @State private var confirmingSignOut = false
    @State private var confirmingReset = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    NavigationLink {
                        EditProfileView()
                    } label: {
                        header
                    }
                }

                Section("Shopping") {
                    Button {
                        router.selectedTab = .orders
                    } label: {
                        row("Orders", systemImage: "shippingbox", value: "\(orders.count)")
                    }
                    .foregroundStyle(.primary)
                    NavigationLink(value: ListingScope.favorites) {
                        row("Wishlist", systemImage: "heart", value: "\(favorites.count)")
                    }
                    NavigationLink {
                        EditProfileView()
                    } label: {
                        row("Shipping Address", systemImage: "house")
                    }
                    NavigationLink {
                        PaymentMethodsView()
                    } label: {
                        row("Payment Methods", systemImage: "creditcard")
                    }
                }

                Section("Preferences") {
                    Picker(selection: $appearance) {
                        ForEach(AppAppearance.allCases) { Text($0.title).tag($0) }
                    } label: {
                        row("Appearance", systemImage: "circle.lefthalf.filled")
                    }
                    Toggle(isOn: $orderUpdates) {
                        row("Order Updates", systemImage: "bell.badge")
                    }
                }

                Section("About") {
                    NavigationLink {
                        CreditsView()
                    } label: {
                        row("Image Credits", systemImage: "photo.on.rectangle")
                    }
                    row("Version", systemImage: "info.circle", value: appVersion)
                    Button(role: .destructive) {
                        confirmingReset = true
                    } label: {
                        row("Reset Demo Data", systemImage: "arrow.counterclockwise")
                    }
                }

                Section {
                    Button("Sign Out", role: .destructive) {
                        confirmingSignOut = true
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .navigationTitle("Profile")
            .shopDestinations()
            .confirmationDialog("Sign out of Draft Shoppr?", isPresented: $confirmingSignOut, titleVisibility: .visible) {
                Button("Sign Out", role: .destructive) { isSignedIn = false }
            } message: {
                Text("Your bag, wishlist, and orders stay saved on this device.")
            }
            .confirmationDialog("Reset all demo data?", isPresented: $confirmingReset, titleVisibility: .visible) {
                Button("Reset", role: .destructive) {
                    SeedData.reset(modelContext)
                }
            } message: {
                Text("This clears your bag, wishlist, and orders, and restores the original catalog.")
            }
        }
    }

    private var header: some View {
        HStack(spacing: 16) {
            Text(initials)
                .font(.title2.weight(.bold))
                .foregroundStyle(.white)
                .frame(width: 64, height: 64)
                .background(Theme.heroGradient, in: .circle)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 3) {
                Text(userName.isEmpty ? "Shopper" : userName)
                    .font(.title3.weight(.semibold))
                Text(userEmail)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                if memberSince > 0 {
                    Text("Member since \(Date(timeIntervalSince1970: memberSince).formatted(.dateTime.month(.wide).year()))")
                        .font(.caption)
                        .foregroundStyle(Theme.accent)
                }
            }
        }
        .padding(.vertical, 6)
    }

    private var initials: String {
        let parts = userName.split(separator: " ").prefix(2)
        let letters = parts.compactMap(\.first).map(String.init).joined()
        return letters.isEmpty ? "DS" : letters.uppercased()
    }

    private var appVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
    }

    private func row(_ title: String, systemImage: String, value: String? = nil) -> some View {
        HStack {
            Label {
                Text(title)
            } icon: {
                Image(systemName: systemImage)
                    .foregroundStyle(Theme.accent)
            }
            if let value {
                Spacer()
                Text(value)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

struct EditProfileView: View {
    @AppStorage(StorageKey.userName) private var userName = ""
    @AppStorage(StorageKey.userEmail) private var userEmail = ""
    @AppStorage(StorageKey.shippingAddress) private var address = "1 Infinite Loop, Cupertino, CA 95014"

    var body: some View {
        Form {
            Section("Personal Info") {
                TextField("Full Name", text: $userName)
                    .textContentType(.name)
                TextField("Email", text: $userEmail)
                    .emailFieldStyle()
            }
            Section {
                TextField("Street, City, State ZIP", text: $address, axis: .vertical)
                    .textContentType(.fullStreetAddress)
                    .lineLimit(2...4)
            } header: {
                Text("Default Shipping Address")
            } footer: {
                Text("Used to prefill checkout. Changes save automatically.")
            }
        }
        .navigationTitle("Edit Profile")
        .inlineNavigationTitle()
    }
}

struct PaymentMethodsView: View {
    var body: some View {
        List {
            Section {
                ForEach(PaymentMethod.allCases) { method in
                    Label {
                        VStack(alignment: .leading) {
                            Text(method.title)
                            if method != .applePay {
                                Text("Expires 08/29")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    } icon: {
                        Image(systemName: method.symbolName)
                            .foregroundStyle(Theme.accent)
                    }
                }
            } footer: {
                Text("These are sample payment methods. No real charges are ever made.")
            }
        }
        .navigationTitle("Payment Methods")
        .inlineNavigationTitle()
    }
}

struct CreditsView: View {
    var body: some View {
        List {
            Section {
                ForEach(ImageCredits.all) { credit in
                    HStack(spacing: 12) {
                        ProductImage(name: credit.id, cornerRadius: 8)
                            .frame(width: 44, height: 44)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(credit.title)
                                .font(.footnote)
                                .lineLimit(2)
                            Text(credit.author)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer(minLength: 0)
                        if let url = credit.url {
                            Link(destination: url) {
                                Image(systemName: "arrow.up.right.square")
                            }
                            .accessibilityLabel("Open source page")
                        }
                    }
                }
            } footer: {
                Text("Product photos come from Wikimedia Commons and are dedicated to the public domain under CC0 1.0. Icons are SF Symbols. Brands and product names in this app are fictional.")
            }
        }
        .navigationTitle("Image Credits")
        .inlineNavigationTitle()
    }
}

#Preview {
    ProfileView()
        .environment(AppRouter())
        .modelContainer(PreviewSupport.container)
        .tint(Theme.accent)
}
