//
//  AuthView.swift
//  L25020028-ToDoApp
//

import SwiftUI
import FirebaseAuth

// ════════════════════════════════════════════════════════════
// MARK: - AUTH GATE
// ════════════════════════════════════════════════════════════

struct AuthGateView: View {
    @StateObject private var authVM = AuthViewModel()

    var body: some View {
        Group {
            if authVM.currentUser != nil {
                ContentView(authVM: authVM)
            } else {
                LoginView(authVM: authVM)
            }
        }
        .animation(.easeInOut(duration: 0.4), value: authVM.currentUser?.uid)
    }
}

// ════════════════════════════════════════════════════════════
// MARK: - LOGIN VIEW
// ════════════════════════════════════════════════════════════

struct LoginView: View {
    @ObservedObject var authVM: AuthViewModel

    @State private var email      = ""
    @State private var password   = ""
    @State private var showPass   = false
    @State private var goRegister = false
    @State private var appeared   = false

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.82, green: 0.89, blue: 1.0),
                         Color(red: 0.94, green: 0.97, blue: 1.0)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {

                    // ── Illustration ──────────────────────
                    VStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(Color(red: 0.38, green: 0.55, blue: 0.95).opacity(0.12))
                                .frame(width: 100, height: 100)
                            Image(systemName: "checkmark.square.fill")
                                .font(.system(size: 44))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [Color(red: 0.38, green: 0.55, blue: 0.95),
                                                 Color(red: 0.22, green: 0.37, blue: 0.82)],
                                        startPoint: .topLeading, endPoint: .bottomTrailing)
                                )
                        }
                        .padding(.top, 70)
                        .scaleEffect(appeared ? 1 : 0.7)
                        .opacity(appeared ? 1 : 0)

                        VStack(spacing: 6) {
                            Text("Welcome Back!")
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .foregroundColor(Color(red: 0.13, green: 0.15, blue: 0.28))
                            Text("Sign in to your GoTask account")
                                .font(.system(size: 14, design: .rounded))
                                .foregroundColor(Color(red: 0.55, green: 0.58, blue: 0.70))
                        }
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 10)
                    }

                    // ── Form ──────────────────────────────
                    VStack(spacing: 14) {
                        inputField(icon: "envelope.fill", placeholder: "Email",
                                   text: $email, isEmail: true, isSecure: false, showPass: .constant(false))

                        inputField(icon: "lock.fill", placeholder: "Password",
                                   text: $password, isEmail: false, isSecure: true, showPass: $showPass)

                        // Login Button
                        Button {
                            Task { await authVM.login(email: email, password: password) }
                        } label: {
                            ZStack {
                                if authVM.isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .frame(maxWidth: .infinity).padding(.vertical, 17)
                                        .background(Color(red: 0.38, green: 0.55, blue: 0.95))
                                        .cornerRadius(16)
                                } else {
                                    Text("Login")
                                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity).padding(.vertical, 17)
                                        .background(LinearGradient(
                                            colors: [Color(red: 0.38, green: 0.55, blue: 0.95),
                                                     Color(red: 0.22, green: 0.37, blue: 0.82)],
                                            startPoint: .leading, endPoint: .trailing))
                                        .cornerRadius(16)
                                        .shadow(color: Color(red: 0.38, green: 0.55, blue: 0.95).opacity(0.4),
                                                radius: 12, x: 0, y: 6)
                                }
                            }
                        }
                        .disabled(authVM.isLoading || email.isEmpty || password.isEmpty)
                        .opacity(email.isEmpty || password.isEmpty ? 0.5 : 1)

                        // Divider
                        HStack {
                            Rectangle().fill(Color.gray.opacity(0.2)).frame(height: 1)
                            Text("or").font(.caption)
                                .foregroundColor(Color(red: 0.55, green: 0.58, blue: 0.70))
                            Rectangle().fill(Color.gray.opacity(0.2)).frame(height: 1)
                        }

                        Button { goRegister = true } label: {
                            HStack(spacing: 4) {
                                Text("Don't have an account?")
                                    .font(.system(size: 14, design: .rounded))
                                    .foregroundColor(Color(red: 0.55, green: 0.58, blue: 0.70))
                                Text("Register")
                                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                                    .foregroundColor(Color(red: 0.38, green: 0.55, blue: 0.95))
                            }
                        }
                    }
                    .padding(24)
                    .background(Color.white)
                    .cornerRadius(28)
                    .shadow(color: .black.opacity(0.06), radius: 20, x: 0, y: 8)
                    .padding(.horizontal, 24)
                    .padding(.top, 32)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 20)

                    Spacer(minLength: 40)
                }
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1)) {
                appeared = true
            }
        }
        .alert("Login Failed", isPresented: $authVM.showError) {
            Button("OK", role: .cancel) { authVM.showError = false }
        } message: {
            Text(authVM.errorMessage)
        }
        .fullScreenCover(isPresented: $goRegister) {
            RegisterView(authVM: authVM)
        }
    }
}

// ════════════════════════════════════════════════════════════
// MARK: - REGISTER VIEW
// ════════════════════════════════════════════════════════════

struct RegisterView: View {
    @ObservedObject var authVM: AuthViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var name        = ""
    @State private var email       = ""
    @State private var password    = ""
    @State private var confirmPass = ""
    @State private var showPass    = false
    @State private var appeared    = false

    private var isValid: Bool {
        !name.isEmpty && !email.isEmpty &&
        password.count >= 6 && password == confirmPass
    }

    private var passwordMatch: Bool {
        password == confirmPass || confirmPass.isEmpty
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.82, green: 0.89, blue: 1.0),
                         Color(red: 0.94, green: 0.97, blue: 1.0)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {

                    // ── Header ────────────────────────────
                    VStack(spacing: 16) {
                        HStack {
                            Button { dismiss() } label: {
                                ZStack {
                                    Circle().fill(Color.white.opacity(0.8)).frame(width: 38, height: 38)
                                    Image(systemName: "chevron.left")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(Color(red: 0.38, green: 0.55, blue: 0.95))
                                }
                            }
                            Spacer()
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 16)

                        ZStack {
                            Circle()
                                .fill(Color(red: 0.38, green: 0.55, blue: 0.95).opacity(0.12))
                                .frame(width: 100, height: 100)
                            Image(systemName: "person.badge.plus.fill")
                                .font(.system(size: 40))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [Color(red: 0.38, green: 0.55, blue: 0.95),
                                                 Color(red: 0.22, green: 0.37, blue: 0.82)],
                                        startPoint: .topLeading, endPoint: .bottomTrailing)
                                )
                        }
                        .scaleEffect(appeared ? 1 : 0.7)
                        .opacity(appeared ? 1 : 0)

                        VStack(spacing: 6) {
                            Text("Create a New Account")
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .foregroundColor(Color(red: 0.13, green: 0.15, blue: 0.28))
                            Text("Sign up and start managing your tasks")
                                .font(.system(size: 14, design: .rounded))
                                .foregroundColor(Color(red: 0.55, green: 0.58, blue: 0.70))
                        }
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 10)
                    }

                    // ── Form ──────────────────────────────
                    VStack(spacing: 14) {
                        inputField(icon: "person.fill", placeholder: "Full Name",
                                   text: $name, isEmail: false, isSecure: false, showPass: .constant(false))

                        inputField(icon: "envelope.fill", placeholder: "Email",
                                   text: $email, isEmail: true, isSecure: false, showPass: .constant(false))

                        inputField(icon: "lock.fill", placeholder: "Password (min. 6 characters)",
                                   text: $password, isEmail: false, isSecure: true, showPass: $showPass)

                        // Confirm password
                        VStack(alignment: .leading, spacing: 4) {
                            inputField(icon: "lock.shield.fill",
                                       placeholder: "Confirm Password",
                                       text: $confirmPass, isEmail: false, isSecure: true, showPass: $showPass)
                            if !passwordMatch {
                                Text("Passwords do not match")
                                    .font(.system(size: 11, design: .rounded))
                                    .foregroundColor(.red)
                                    .padding(.leading, 4)
                            }
                        }

                        // Register Button
                        Button {
                            Task { await authVM.register(email: email, password: password, name: name) }
                        } label: {
                            ZStack {
                                if authVM.isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .frame(maxWidth: .infinity).padding(.vertical, 17)
                                        .background(Color(red: 0.38, green: 0.55, blue: 0.95))
                                        .cornerRadius(16)
                                } else {
                                    Text("Create Account")
                                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity).padding(.vertical, 17)
                                        .background(LinearGradient(
                                            colors: [Color(red: 0.38, green: 0.55, blue: 0.95),
                                                     Color(red: 0.22, green: 0.37, blue: 0.82)],
                                            startPoint: .leading, endPoint: .trailing))
                                        .cornerRadius(16)
                                        .shadow(color: Color(red: 0.38, green: 0.55, blue: 0.95).opacity(0.4),
                                                radius: 12, x: 0, y: 6)
                                }
                            }
                        }
                        .disabled(!isValid || authVM.isLoading)
                        .opacity(!isValid ? 0.5 : 1)
                        .padding(.top, 4)

                        Button { dismiss() } label: {
                            HStack(spacing: 4) {
                                Text("Already have an account?")
                                    .font(.system(size: 14, design: .rounded))
                                    .foregroundColor(Color(red: 0.55, green: 0.58, blue: 0.70))
                                Text("Login")
                                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                                    .foregroundColor(Color(red: 0.38, green: 0.55, blue: 0.95))
                            }
                        }
                    }
                    .padding(24)
                    .background(Color.white)
                    .cornerRadius(28)
                    .shadow(color: .black.opacity(0.06), radius: 20, x: 0, y: 8)
                    .padding(.horizontal, 24)
                    .padding(.top, 24)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 20)

                    Spacer(minLength: 40)
                }
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1)) {
                appeared = true
            }
        }
        .alert("Registration Failed", isPresented: $authVM.showError) {
            Button("OK", role: .cancel) { authVM.showError = false }
        } message: {
            Text(authVM.errorMessage)
        }
    }
}

// ════════════════════════════════════════════════════════════
// MARK: - REUSABLE INPUT FIELD
// ════════════════════════════════════════════════════════════

private func inputField(icon: String,
                         placeholder: String,
                         text: Binding<String>,
                         isEmail: Bool,
                         isSecure: Bool,
                         showPass: Binding<Bool>) -> some View {
    HStack(spacing: 12) {
        Image(systemName: icon)
            .font(.system(size: 15))
            .foregroundColor(Color(red: 0.38, green: 0.55, blue: 0.95))
            .frame(width: 20)

        if isSecure && !showPass.wrappedValue {
            SecureField(placeholder, text: text)
                .font(.system(size: 15, design: .rounded))
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
        } else {
            TextField(placeholder, text: text)
                .font(.system(size: 15, design: .rounded))
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .keyboardType(isEmail ? .emailAddress : .default)
        }

        if isSecure {
            Button { showPass.wrappedValue.toggle() } label: {
                Image(systemName: showPass.wrappedValue ? "eye.slash.fill" : "eye.fill")
                    .font(.system(size: 14))
                    .foregroundColor(Color(red: 0.55, green: 0.58, blue: 0.70))
            }
        }
    }
    .padding(.horizontal, 16)
    .padding(.vertical, 14)
    .background(Color(red: 0.94, green: 0.96, blue: 1.0))
    .cornerRadius(14)
}

// ════════════════════════════════════════════════════════════
// MARK: - PREVIEW
// ════════════════════════════════════════════════════════════

struct AuthView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView(authVM: AuthViewModel())
    }
}
