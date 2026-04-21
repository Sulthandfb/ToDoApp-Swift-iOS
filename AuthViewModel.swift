//
//  AuthViewModel.swift
//  L25020028-ToDoApp
//

import Foundation
import FirebaseAuth

@MainActor
final class AuthViewModel: ObservableObject {

    @Published var currentUser: User?
    @Published var isLoading    = false
    @Published var errorMessage = ""
    @Published var showError    = false

    private var authHandle: AuthStateDidChangeListenerHandle?

    init() {
        listenAuthState()
    }

    deinit {
        if let handle = authHandle {
            Auth.auth().removeStateDidChangeListener(handle)
        }
    }

    private func listenAuthState() {
        authHandle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            Task { @MainActor in
                self?.currentUser = user
            }
        }
    }

    func register(email: String, password: String, name: String) async {
        isLoading = true
        errorMessage = ""
        do {
            let result = try await Auth.auth().createUser(withEmail: email, password: password)
            let changeRequest = result.user.createProfileChangeRequest()
            changeRequest.displayName = name
            try await changeRequest.commitChanges()
            currentUser = Auth.auth().currentUser
        } catch {
            errorMessage = friendlyError(error)
            showError = true
        }
        isLoading = false
    }

    func login(email: String, password: String) async {
        isLoading = true
        errorMessage = ""
        do {
            try await Auth.auth().signIn(withEmail: email, password: password)
        } catch {
            errorMessage = friendlyError(error)
            showError = true
        }
        isLoading = false
    }

    func logout() {
        do {
            try Auth.auth().signOut()
            currentUser = nil
        } catch {
            errorMessage = "Logout failed: \(error.localizedDescription)"
            showError = true
        }
    }

    private func friendlyError(_ error: Error) -> String {
        let code = AuthErrorCode(_nsError: error as NSError)
        switch code.code {
        case .emailAlreadyInUse: return "This email is already in use. Try logging in instead."
        case .invalidEmail:      return "The email format is invalid."
        case .weakPassword:      return "Password must be at least 6 characters."
        case .wrongPassword:     return "Incorrect password. Please try again."
        case .userNotFound:      return "Account not found. Please register first."
        case .networkError:      return "No internet connection."
        case .tooManyRequests:   return "Too many attempts. Please wait a moment."
        default:                 return error.localizedDescription
        }
    }

    var displayName: String {
        currentUser?.displayName?.components(separatedBy: " ").first ?? "User"
    }
    var userEmail: String { currentUser?.email ?? "" }
    var userUID:   String { currentUser?.uid ?? "" }
}
