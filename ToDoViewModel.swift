//
//  Todoviewmodel.swift
//  L25020028-ToDoApp
//
//  Created by 20 on 2026/4/15.
//

import Foundation
import FirebaseFirestore

// ════════════════════════════════════════════════════════════
// MARK: - VIEWMODEL + FIRESTORE
// ════════════════════════════════════════════════════════════
//
// @MainActor  → semua update UI dijamin di main thread
// ObservableObject → bisa dipakai dengan @StateObject di View
//
// Data Flow:
// [App Launch] → listenToFirestore() → snapshot listener aktif
//     │
//     ▼
// Firestore kirim data realtime → items terupdate otomatis
//     │
//     ▼
// @Published items berubah → SwiftUI re-render UI
//
// [User Action] → add/delete/toggle → tulis ke Firestore
//     │
//     ▼
// Firestore update → snapshot listener deteksi perubahan
//     │
//     ▼
// items terupdate → UI re-render

@MainActor
final class ToDoViewModel: ObservableObject {

    // ── Published Properties ──────────────────────────────
    @Published var items: [ToDoItem]    = []
    @Published var isLoading: Bool      = true
    @Published var errorMessage: String = ""
    @Published var showError: Bool      = false

    // ── Firestore Reference ───────────────────────────────
    private let db         = Firestore.firestore()
    private let collection = "todos"
    private var listener: ListenerRegistration?

    // ── init ──────────────────────────────────────────────
    init() {
        listenToFirestore()
    }

    deinit {
        listener?.remove()
    }

    // ════════════════════════════════════════════════════
    // MARK: - Firestore Listener (Realtime)
    // ════════════════════════════════════════════════════
    //
    // addSnapshotListener → Firestore push perubahan ke app
    // secara realtime tanpa perlu polling manual.
    // Setiap kali data di Firestore berubah (dari device mana pun),
    // closure ini dipanggil otomatis.

    private func listenToFirestore() {
        listener = db.collection(collection)
            .order(by: "createdAt", descending: true)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self else { return }

                if let error {
                    self.errorMessage = error.localizedDescription
                    self.showError    = true
                    self.isLoading    = false
                    return
                }

                guard let documents = snapshot?.documents else {
                    self.isLoading = false
                    return
                }

                // Decode setiap Firestore Document → ToDoItem
                self.items = documents.compactMap { doc in
                    try? doc.data(as: ToDoItem.self)
                }
                self.isLoading = false
            }
    }

    // ════════════════════════════════════════════════════
    // MARK: - CRUD Operations
    // ════════════════════════════════════════════════════

    // ── Add ───────────────────────────────────────────────
    // setData(from:) → encode ToDoItem struct → Firestore document
    func add(_ item: ToDoItem) {
        do {
            _ = try db.collection(collection).addDocument(from: item)
        } catch {
            errorMessage = "Gagal menambah task: \(error.localizedDescription)"
            showError    = true
        }
    }

    // ── Delete ────────────────────────────────────────────
    func delete(id: String) {
        db.collection(collection).document(id).delete { [weak self] error in
            if let error {
                self?.errorMessage = "Gagal menghapus task: \(error.localizedDescription)"
                self?.showError    = true
            }
        }
    }

    // ── Toggle Done ───────────────────────────────────────
    func toggleDone(item: ToDoItem) {
        guard let id = item.id else { return }
        db.collection(collection).document(id).updateData([
            "isDone": !item.isDone
        ]) { [weak self] error in
            if let error {
                self?.errorMessage = "Gagal update task: \(error.localizedDescription)"
                self?.showError    = true
            }
        }
    }

    // ── Update ────────────────────────────────────────────
    func update(_ item: ToDoItem) {
        guard let id = item.id else { return }
        do {
            try db.collection(collection).document(id).setData(from: item)
        } catch {
            errorMessage = "Gagal update task: \(error.localizedDescription)"
            showError    = true
        }
    }

    // ════════════════════════════════════════════════════
    // MARK: - Computed Properties
    // ════════════════════════════════════════════════════

    var doneCount:    Int { items.filter {  $0.isDone }.count }
    var pendingCount: Int { items.filter { !$0.isDone }.count }
    var highPriorityCount: Int {
        items.filter { $0.priority == .high && !$0.isDone }.count
    }
}
