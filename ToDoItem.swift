//
//  ToDoItem.swift
//  L25020028-ToDoApp
//
//  Created by 20 on 2026/4/15.
//

//
//  ToDoItem.swift
//  L25020028-ToDoApp
//

import Foundation
import FirebaseFirestore

// ════════════════════════════════════════════════════════════
// MARK: - MODEL
// ════════════════════════════════════════════════════════════
//
// Codable     → bisa encode/decode ke JSON
// Identifiable → bisa dipakai di ForEach SwiftUI
//
// Firestore menyimpan data sebagai Document.
// Setiap ToDoItem = 1 document di collection "todos"

struct ToDoItem: Identifiable, Codable, Equatable {
    @DocumentID var id: String?       // ID otomatis dari Firestore
    var title: String
    var detail: String
    var isDone: Bool
    var dueDate: Date
    var priority: Priority
    var createdAt: Date

    // ── Priority enum ─────────────────────────────────────
    enum Priority: String, Codable, CaseIterable {
        case low    = "Low"
        case medium = "Medium"
        case high   = "High"

        var color: String {
            switch self {
            case .low:    return "green"
            case .medium: return "orange"
            case .high:   return "red"
            }
        }

        var icon: String {
            switch self {
            case .low:    return "arrow.down.circle.fill"
            case .medium: return "minus.circle.fill"
            case .high:   return "exclamationmark.circle.fill"
            }
        }
    }

    // ── init ──────────────────────────────────────────────
    init(
        id: String? = nil,
        title: String,
        detail: String = "",
        isDone: Bool = false,
        dueDate: Date = Date().addingTimeInterval(86400),
        priority: Priority = .medium,
        createdAt: Date = Date()
    ) {
        self.id        = id
        self.title     = title
        self.detail    = detail
        self.isDone    = isDone
        self.dueDate   = dueDate
        self.priority  = priority
        self.createdAt = createdAt
    }
}
