import SwiftUI

/// Local-only sign in / create account. Any well-formed email and a 6+ character password are accepted.
struct SignInView: View {
    private enum Field: Hashable { case name, email, password }

    @AppStorage(StorageKey.isSignedIn) private var isSignedIn = false
    @AppStorage(StorageKey.userName) private var userName = ""
    @AppStorage(StorageKey.userEmail) private var userEmail = ""
    @AppStorage(StorageKey.memberSince) private var memberSince = 0.0

    @State private var isCreatingAccount = false
    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var errorMessage: String?
    @State private var isWorking = false
    @State private var showingPasswordHelp = false
    @FocusState private var focusedField: Field?

    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                header
                form
                actions
                demoHint
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 40)
            .frame(maxWidth: 460)
            .frame(maxWidth: .infinity)
        }
        .scrollDismissesKeyboard(.interactively)
        .background {
            LinearGradient(colors: [Theme.surface, Color.clear], startPoint: .top, endPoint: .center)
                .ignoresSafeArea()
        }
        .sensoryFeedback(.error, trigger: errorMessage) { _, new in new != nil }
        .alert("Reset Password", isPresented: $showingPasswordHelp) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Draft Shoppr keeps everything on this device, so any password of 6 or more characters will sign you in.")
        }
    }

    private var header: some View {
        VStack(spacing: 16) {
            BrandLogo(size: 88)
            VStack(spacing: 6) {
                Text("Draft Shoppr")
                    .font(.largeTitle.weight(.heavy))
                    .foregroundStyle(Theme.ink)
                Text(isCreatingAccount ? "Create your account to start shopping." : "Good finds, first draft. Sign in to continue.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .contentTransition(.opacity)
            }
        }
        .padding(.top, 20)
    }

    private var form: some View {
        VStack(spacing: 14) {
            if isCreatingAccount {
                field(systemImage: "person") {
                    TextField("Full name", text: $name)
                        .textContentType(.name)
                        .focused($focusedField, equals: .name)
                        .submitLabel(.next)
                        .onSubmit { focusedField = .email }
                }
                .transition(.move(edge: .top).combined(with: .opacity))
            }
            field(systemImage: "envelope") {
                TextField("Email", text: $email)
                    .emailFieldStyle()
                    .focused($focusedField, equals: .email)
                    .submitLabel(.next)
                    .onSubmit { focusedField = .password }
            }
            field(systemImage: "lock") {
                SecureField("Password", text: $password)
                    .textContentType(isCreatingAccount ? .newPassword : .password)
                    .focused($focusedField, equals: .password)
                    .submitLabel(.go)
                    .onSubmit(submit)
            }

            if let errorMessage {
                Label(errorMessage, systemImage: "exclamationmark.circle.fill")
                    .font(.footnote)
                    .foregroundStyle(.red)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .transition(.opacity)
            }

            if !isCreatingAccount {
                Button("Forgot password?") {
                    showingPasswordHelp = true
                }
                .font(.footnote.weight(.semibold))
                .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
    }

    private var actions: some View {
        VStack(spacing: 14) {
            Button(action: submit) {
                Group {
                    if isWorking {
                        ProgressView()
                    } else {
                        Text(isCreatingAccount ? "Create Account" : "Sign In")
                    }
                }
                .font(.headline)
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.glassProminent)
            .controlSize(.large)
            .disabled(isWorking)

            Button {
                signIn(name: "Guest Shopper", email: "guest@draftshoppr.app")
            } label: {
                Text("Continue as Guest")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.glass)
            .controlSize(.large)

            HStack(spacing: 4) {
                Text(isCreatingAccount ? "Already have an account?" : "New to Draft Shoppr?")
                    .foregroundStyle(.secondary)
                Button(isCreatingAccount ? "Sign In" : "Create one") {
                    withAnimation(.smooth) {
                        isCreatingAccount.toggle()
                        errorMessage = nil
                    }
                }
                .fontWeight(.semibold)
            }
            .font(.footnote)
            .padding(.top, 4)
        }
    }

    private var demoHint: some View {
        Text("Demo app: everything stays on this device. Use any email and a password of 6+ characters.")
            .font(.caption)
            .foregroundStyle(.tertiary)
            .multilineTextAlignment(.center)
    }

    private func field<Content: View>(systemImage: String, @ViewBuilder content: () -> Content) -> some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .foregroundStyle(.secondary)
                .frame(width: 22)
                .accessibilityHidden(true)
            content()
        }
        .padding(.horizontal, 16)
        .frame(minHeight: 52)
        .background(.background.secondary, in: .rect(cornerRadius: 14, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(.separator, lineWidth: 0.5)
        }
    }

    private func submit() {
        let trimmedEmail = email.trimmingCharacters(in: .whitespaces)
        let trimmedName = name.trimmingCharacters(in: .whitespaces)

        withAnimation {
            if isCreatingAccount && trimmedName.isEmpty {
                errorMessage = "Please enter your name."
            } else if !isValidEmail(trimmedEmail) {
                errorMessage = "Enter a valid email address."
            } else if password.count < 6 {
                errorMessage = "Password must be at least 6 characters."
            } else {
                errorMessage = nil
            }
        }
        guard errorMessage == nil else { return }

        focusedField = nil
        isWorking = true
        Task {
            // Brief pause so the sign-in feels deliberate, as it would with a real service.
            try? await Task.sleep(for: .milliseconds(600))
            let displayName = trimmedName.isEmpty ? nameFromEmail(trimmedEmail) : trimmedName
            signIn(name: displayName, email: trimmedEmail)
            isWorking = false
        }
    }

    private func signIn(name: String, email: String) {
        userName = name
        userEmail = email
        if memberSince == 0 { memberSince = Date.now.timeIntervalSince1970 }
        isSignedIn = true
    }

    private func isValidEmail(_ value: String) -> Bool {
        value.wholeMatch(of: /[^@\s]+@[^@\s]+\.[A-Za-z]{2,}/) != nil
    }

    /// "jane.doe@example.com" → "Jane Doe"
    private func nameFromEmail(_ value: String) -> String {
        let local = value.split(separator: "@").first.map(String.init) ?? value
        return local
            .split(whereSeparator: { $0 == "." || $0 == "_" || $0 == "-" })
            .map { $0.capitalized }
            .joined(separator: " ")
    }
}

#Preview {
    SignInView()
        .tint(Theme.accent)
}
