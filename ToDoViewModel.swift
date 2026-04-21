//
//  ToDoViewModel.swift
//  L25020028-ToDoApp
//
//  Data per-user: users/{uid}/todos
//

import Foundation
import FirebaseFirestore

@MainActor
final class ToDoViewModel: ObservableObject {

    @Published var items:        [ToDoItem] = []
    @Published var isLoading:    Bool       = true
    @Published var errorMessage: String     = ""
    @Published var showError:    Bool       = false

    private let db:       Firestore
    private let uid:      String
    private var listener: ListenerRegistration?

    init(uid: String) {
        self.uid = uid
        self.db  = Firestore.firestore()
        listenToFirestore()
    }

    deinit {
        listener?.remove()
    }

    private var todosRef: CollectionReference {
        db.collection("users").document(uid).collection("todos")
    }

    private func listenToFirestore() {
        listener = todosRef
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
                self.items     = documents.compactMap { try? $0.data(as: ToDoItem.self) }
                self.isLoading = false
            }
    }

    func add(_ item: ToDoItem) {
        do {
            _ = try todosRef.addDocument(from: item)
        } catch {
            errorMessage = "Gagal menambah task: \(error.localizedDescription)"
            showError    = true
        }
    }

    func delete(id: String) {
        todosRef.document(id).delete { [weak self] error in
            if let error {
                self?.errorMessage = "Gagal menghapus task: \(error.localizedDescription)"
                self?.showError    = true
            }
        }
    }

    func toggleDone(item: ToDoItem) {
        guard let id = item.id else { return }
        todosRef.document(id).updateData(["isDone": !item.isDone]) { [weak self] error in
            if let error {
                self?.errorMessage = "Gagal update task: \(error.localizedDescription)"
                self?.showError    = true
            }
        }
    }

    func update(_ item: ToDoItem) {
        guard let id = item.id else { return }
        do {
            try todosRef.document(id).setData(from: item)
        } catch {
            errorMessage = "Gagal update task: \(error.localizedDescription)"
            showError    = true
        }
    }

    var doneCount:    Int { items.filter {  $0.isDone }.count }
    var pendingCount: Int { items.filter { !$0.isDone }.count }
    var highPriorityCount: Int {
        items.filter { $0.priority == .high && !$0.isDone }.count
    }
}
