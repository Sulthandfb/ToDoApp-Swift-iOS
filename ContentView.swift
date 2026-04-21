//
//  ContentView.swift
//  L25020028-ToDoApp
//

import SwiftUI

// ════════════════════════════════════════════════════════════
// MARK: - COLOR THEME
// ════════════════════════════════════════════════════════════

extension Color {
    static let brandBlue     = Color(red: 0.38, green: 0.55, blue: 0.95)
    static let brandBlueSoft = Color(red: 0.86, green: 0.91, blue: 1.00)
    static let brandBlueDark = Color(red: 0.22, green: 0.37, blue: 0.82)
    static let bgPage        = Color(red: 0.94, green: 0.96, blue: 1.00)
    static let textPrimary   = Color(red: 0.13, green: 0.15, blue: 0.28)
    static let textSecondary = Color(red: 0.55, green: 0.58, blue: 0.70)
}

// ════════════════════════════════════════════════════════════
// MARK: - ROOT
// ════════════════════════════════════════════════════════════

struct ContentView: View {
    @ObservedObject var authVM: AuthViewModel
    @StateObject private var viewModel: ToDoViewModel
    @State private var showSplash = true

    init(authVM: AuthViewModel) {
        self.authVM = authVM
        _viewModel = StateObject(wrappedValue: ToDoViewModel(uid: authVM.userUID))
    }

    var body: some View {
        Group {
            if showSplash {
                SplashView { showSplash = false }
            } else {
                HomeView(viewModel: viewModel, authVM: authVM)
            }
        }
        .animation(.easeInOut(duration: 0.5), value: showSplash)
    }
}

// ════════════════════════════════════════════════════════════
// MARK: - SPLASH VIEW
// ════════════════════════════════════════════════════════════

struct SplashView: View {
    var onStart: () -> Void
    @State private var appeared = false

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.82, green: 0.89, blue: 1.0),
                         Color(red: 0.94, green: 0.97, blue: 1.0)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            ).ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()
                ZStack {
                    RoundedRectangle(cornerRadius: 32)
                        .fill(Color.white.opacity(0.6))
                        .frame(width: 240, height: 240)
                        .shadow(color: Color.brandBlue.opacity(0.2), radius: 30, x: 0, y: 10)
                    VStack(spacing: 14) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 20)
                                .fill(LinearGradient(
                                    colors: [Color.brandBlue, Color.brandBlueDark],
                                    startPoint: .topLeading, endPoint: .bottomTrailing))
                                .frame(width: 80, height: 80)
                                .shadow(color: Color.brandBlue.opacity(0.4), radius: 16, x: 0, y: 8)
                            Image(systemName: "checkmark.square.fill")
                                .font(.system(size: 36)).foregroundColor(.white)
                        }
                        HStack(spacing: 8) {
                            miniCard(icon: "chart.bar.fill", color: .orange)
                            miniCard(icon: "clock.fill",     color: .brandBlue)
                            miniCard(icon: "star.fill",      color: .green)
                        }
                    }
                }
                .scaleEffect(appeared ? 1 : 0.8)
                .opacity(appeared ? 1 : 0)

                Spacer()

                VStack(spacing: 12) {
                    Text("Welcome to\nGoTask")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .multilineTextAlignment(.center).foregroundColor(Color.textPrimary)
                    Text("A workspace to manage your tasks\nand boost your productivity")
                        .font(.system(size: 15, design: .rounded))
                        .multilineTextAlignment(.center).foregroundColor(Color.textSecondary).lineSpacing(4)
                }
                .padding(.horizontal, 40)
                .opacity(appeared ? 1 : 0).offset(y: appeared ? 0 : 20)

                Spacer()

                Button(action: onStart) {
                    Text("Let's Start")
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .foregroundColor(.white).frame(maxWidth: .infinity).padding(.vertical, 18)
                        .background(LinearGradient(colors: [Color.brandBlue, Color.brandBlueDark],
                                                   startPoint: .leading, endPoint: .trailing))
                        .cornerRadius(18)
                        .shadow(color: Color.brandBlue.opacity(0.45), radius: 16, x: 0, y: 8)
                }
                .padding(.horizontal, 32).padding(.bottom, 56)
                .opacity(appeared ? 1 : 0).offset(y: appeared ? 0 : 30)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.7, dampingFraction: 0.75).delay(0.2)) { appeared = true }
        }
    }

    private func miniCard(icon: String, color: Color) -> some View {
        RoundedRectangle(cornerRadius: 10).fill(color.opacity(0.12)).frame(width: 40, height: 40)
            .overlay(Image(systemName: icon).font(.system(size: 16)).foregroundColor(color))
    }
}

// ════════════════════════════════════════════════════════════
// MARK: - HOME VIEW
// ════════════════════════════════════════════════════════════

struct HomeView: View {
    @ObservedObject var viewModel: ToDoViewModel
    @ObservedObject var authVM:    AuthViewModel
    @State private var showAddTask    = false
    @State private var searchText     = ""
    @State private var selectedFilter = FilterTab.all

    enum FilterTab: String, CaseIterable {
        case all = "All", inProgress = "In Progress", done = "Done", high = "High"
    }

    private var filtered: [ToDoItem] {
        var list = viewModel.items
        if !searchText.isEmpty {
            list = list.filter {
                $0.title.localizedCaseInsensitiveContains(searchText) ||
                $0.detail.localizedCaseInsensitiveContains(searchText)
            }
        }
        switch selectedFilter {
        case .all:        break
        case .inProgress: list = list.filter { !$0.isDone }
        case .done:       list = list.filter {  $0.isDone }
        case .high:       list = list.filter {  $0.priority == .high }
        }
        return list
    }

    private var progress: Double {
        guard !viewModel.items.isEmpty else { return 0 }
        return Double(viewModel.doneCount) / Double(viewModel.items.count)
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                Color.bgPage.ignoresSafeArea()
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        progressCard
                        searchBarView
                        filterTabsView
                        taskSectionHeader
                        taskListView
                        Color.clear.frame(height: 80)
                    }
                    .padding(.horizontal, 20).padding(.top, 4)
                }
                Button { showAddTask = true } label: {
                    ZStack {
                        Circle()
                            .fill(LinearGradient(colors: [Color.brandBlue, Color.brandBlueDark],
                                                 startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(width: 56, height: 56)
                            .shadow(color: Color.brandBlue.opacity(0.5), radius: 14, x: 0, y: 6)
                        Image(systemName: "plus").font(.system(size: 22, weight: .semibold)).foregroundColor(.white)
                    }
                }
                .padding(.trailing, 24).padding(.bottom, 32)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { navBar }
            .sheet(isPresented: $showAddTask) { AddToDoView(viewModel: viewModel) }
            .alert("Error", isPresented: $viewModel.showError) {
                Button("OK", role: .cancel) {}
            } message: { Text(viewModel.errorMessage) }
        }
    }

    @ToolbarContentBuilder
    private var navBar: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            VStack(alignment: .leading, spacing: 0) {
                Text("Hi, \(authVM.displayName) 👋")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(Color.textPrimary)
                Text("Homepage")
                    .font(.system(size: 11, design: .rounded)).foregroundColor(Color.textSecondary)
            }
        }
        ToolbarItem(placement: .navigationBarTrailing) {
            Menu {
                Text(authVM.userEmail).font(.caption).foregroundColor(Color.textSecondary)
                Divider()
                Button(role: .destructive) { authVM.logout() } label: {
                    Label("Logout", systemImage: "rectangle.portrait.and.arrow.right")
                }
            } label: {
                ZStack {
                    Circle().fill(Color.brandBlueSoft).frame(width: 36, height: 36)
                    Image(systemName: "person.fill").font(.system(size: 15)).foregroundColor(Color.brandBlue)
                }
            }
        }
    }

    private var progressCard: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 24)
                .fill(LinearGradient(colors: [Color.brandBlue, Color.brandBlueDark],
                                     startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(maxWidth: .infinity).frame(height: 130)
            Circle().fill(Color.white.opacity(0.08)).frame(width: 120, height: 120).offset(x: 110, y: -30)
            Circle().fill(Color.white.opacity(0.05)).frame(width: 80, height: 80).offset(x: 130, y: 40)
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Today's progress summary")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundColor(.white.opacity(0.9))
                    Text("\(viewModel.items.count) Tasks")
                        .font(.system(size: 12, design: .rounded)).foregroundColor(.white.opacity(0.65))
                    HStack(spacing: -8) {
                        ForEach(0..<3, id: \.self) { i in
                            Circle().fill([Color.orange, Color.green, Color.pink][i])
                                .frame(width: 28, height: 28)
                                .overlay(Circle().stroke(Color.white, lineWidth: 2))
                                .overlay(Text(["A","B","C"][i])
                                    .font(.system(size: 10, weight: .bold)).foregroundColor(.white))
                        }
                        ZStack {
                            Circle().fill(Color.white.opacity(0.25)).frame(width: 28, height: 28)
                                .overlay(Circle().stroke(Color.white, lineWidth: 2))
                            Image(systemName: "plus").font(.system(size: 10, weight: .bold)).foregroundColor(.white)
                        }
                    }
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 8) {
                    Text("Progress").font(.system(size: 11, weight: .medium, design: .rounded)).foregroundColor(.white.opacity(0.7))
                    Text("\(Int(progress * 100))%").font(.system(size: 22, weight: .bold, design: .rounded)).foregroundColor(.white)
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color.white.opacity(0.25)).frame(width: 90, height: 6)
                        Capsule().fill(Color.white).frame(width: max(6, 90 * progress), height: 6)
                    }
                }
            }
            .padding(.horizontal, 24)
        }
        .shadow(color: Color.brandBlue.opacity(0.35), radius: 20, x: 0, y: 8)
    }

    private var searchBarView: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass").foregroundColor(Color.textSecondary)
            TextField("Search tasks...", text: $searchText).font(.system(size: 14, design: .rounded))
            if !searchText.isEmpty {
                Button { searchText = "" } label: {
                    Image(systemName: "xmark.circle.fill").foregroundColor(Color.textSecondary)
                }
            }
        }
        .padding(.horizontal, 16).padding(.vertical, 13)
        .background(Color.white).cornerRadius(16)
        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
    }

    private var filterTabsView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(FilterTab.allCases, id: \.self) { tab in
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { selectedFilter = tab }
                    } label: {
                        Text(tab.rawValue)
                            .font(.system(size: 13, weight: selectedFilter == tab ? .semibold : .regular, design: .rounded))
                            .foregroundColor(selectedFilter == tab ? .white : Color.textSecondary)
                            .padding(.horizontal, 18).padding(.vertical, 9)
                            .background(
                                selectedFilter == tab
                                ? AnyView(LinearGradient(colors: [Color.brandBlue, Color.brandBlueDark],
                                                         startPoint: .leading, endPoint: .trailing))
                                : AnyView(Color.white))
                            .cornerRadius(12)
                            .shadow(color: selectedFilter == tab
                                    ? Color.brandBlue.opacity(0.35) : Color.black.opacity(0.03),
                                    radius: selectedFilter == tab ? 8 : 3, x: 0, y: 2)
                    }
                }
            }
        }
    }

    private var taskSectionHeader: some View {
        HStack {
            Text("Today's Task").font(.system(size: 16, weight: .bold, design: .rounded)).foregroundColor(Color.textPrimary)
            Spacer()
            Text("See All").font(.system(size: 13, weight: .medium, design: .rounded)).foregroundColor(Color.brandBlue)
        }
    }

    private var taskListView: some View {
        Group {
            if viewModel.isLoading {
                ProgressView().padding(.top, 40)
            } else if filtered.isEmpty {
                VStack(spacing: 14) {
                    ZStack {
                        Circle().fill(Color.brandBlueSoft).frame(width: 80, height: 80)
                        Image(systemName: "checklist").font(.system(size: 32)).foregroundColor(Color.brandBlue)
                    }
                    .padding(.top, 30)
                    Text("No tasks yet").font(.system(size: 16, weight: .semibold, design: .rounded)).foregroundColor(Color.textPrimary)
                    Text("Tap + to add your first task").font(.system(size: 13, design: .rounded)).foregroundColor(Color.textSecondary)
                }
                .frame(maxWidth: .infinity).padding(.vertical, 20)
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(filtered) { item in
                        NavigationLink(destination: ToDoDetailView(item: item, viewModel: viewModel)) {
                            GoTaskCard(item: item) { viewModel.toggleDone(item: item) }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }
}

// ════════════════════════════════════════════════════════════
// MARK: - GOTASK CARD
// ════════════════════════════════════════════════════════════

struct GoTaskCard: View {
    let item: ToDoItem
    let onToggle: () -> Void

    private var categoryColor: Color {
        switch item.priority {
        case .high:   return Color(red: 1.0, green: 0.38, blue: 0.38)
        case .medium: return Color(red: 1.0, green: 0.65, blue: 0.20)
        case .low:    return Color(red: 0.28, green: 0.78, blue: 0.56)
        }
    }

    private var categoryIcon: String {
        switch item.priority {
        case .high:   return "flame.fill"
        case .medium: return "briefcase.fill"
        case .low:    return "leaf.fill"
        }
    }

    private var isOverdue: Bool { !item.isDone && item.dueDate < Date() }

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle().fill(categoryColor.opacity(0.12)).frame(width: 46, height: 46)
                Image(systemName: categoryIcon).font(.system(size: 18)).foregroundColor(categoryColor)
            }
            VStack(alignment: .leading, spacing: 5) {
                Text(item.title)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundColor(item.isDone ? Color.textSecondary : Color.textPrimary)
                    .strikethrough(item.isDone, color: Color.textSecondary).lineLimit(1)
                HStack(spacing: 4) {
                    Image(systemName: "clock").font(.system(size: 10))
                    Text(item.dueDate.formatted(date: .abbreviated, time: .shortened)).font(.system(size: 11, design: .rounded))
                }
                .foregroundColor(isOverdue ? .red.opacity(0.7) : Color.textSecondary)
            }
            Spacer()
            VStack(spacing: 8) {
                Image(systemName: "chevron.right").font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Color.textSecondary.opacity(0.4))
                Button(action: onToggle) {
                    ZStack {
                        Circle().strokeBorder(item.isDone ? categoryColor : Color.gray.opacity(0.3), lineWidth: 2)
                            .frame(width: 22, height: 22)
                            .background(Circle().fill(item.isDone ? categoryColor.opacity(0.15) : Color.clear))
                        if item.isDone {
                            Image(systemName: "checkmark").font(.system(size: 10, weight: .bold)).foregroundColor(categoryColor)
                        }
                    }
                }.buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 16).padding(.vertical, 14)
        .background(Color.white).cornerRadius(18)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(item.isDone ? categoryColor.opacity(0.2) : Color.clear, lineWidth: 1))
    }
}

// ════════════════════════════════════════════════════════════
// MARK: - DETAIL VIEW
// ════════════════════════════════════════════════════════════

struct ToDoDetailView: View {
    let item: ToDoItem
    @ObservedObject var viewModel: ToDoViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var editedTitle:    String            = ""
    @State private var editedDetail:   String            = ""
    @State private var editedDueDate:  Date              = Date()
    @State private var editedIsDone:   Bool              = false
    @State private var editedPriority: ToDoItem.Priority = .medium
    @State private var showDeleteAlert = false
    @State private var isEditing       = false

    private var priorityColor: Color {
        switch editedPriority {
        case .high:   return Color(red: 1.0, green: 0.38, blue: 0.38)
        case .medium: return Color(red: 1.0, green: 0.65, blue: 0.20)
        case .low:    return Color(red: 0.28, green: 0.78, blue: 0.56)
        }
    }

    var body: some View {
        ZStack {
            Color.bgPage.ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    // Header card
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Label(editedPriority.rawValue, systemImage: editedPriority.icon)
                                .font(.system(size: 12, weight: .semibold, design: .rounded))
                                .foregroundColor(priorityColor)
                                .padding(.horizontal, 12).padding(.vertical, 6)
                                .background(priorityColor.opacity(0.1)).cornerRadius(8)
                            Spacer()
                            Text(editedIsDone ? "Done ✓" : "Pending")
                                .font(.system(size: 12, weight: .semibold, design: .rounded))
                                .foregroundColor(editedIsDone ? .green : .orange)
                                .padding(.horizontal, 12).padding(.vertical, 6)
                                .background(editedIsDone ? Color.green.opacity(0.1) : Color.orange.opacity(0.1))
                                .cornerRadius(8)
                        }
                        if isEditing {
                            TextField("Task Name", text: $editedTitle)
                                .font(.system(size: 20, weight: .bold, design: .rounded))
                        } else {
                            Text(editedTitle).font(.system(size: 20, weight: .bold, design: .rounded)).foregroundColor(Color.textPrimary)
                        }
                        HStack(spacing: 6) {
                            Image(systemName: "calendar").font(.system(size: 12))
                            Text(editedDueDate.formatted(date: .long, time: .shortened)).font(.system(size: 13, design: .rounded))
                        }.foregroundColor(Color.textSecondary)
                    }
                    .padding(20).frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.white).cornerRadius(20).shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 2)

                    // Description
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Description").font(.system(size: 14, weight: .semibold, design: .rounded)).foregroundColor(Color.textPrimary)
                        if isEditing {
                            TextField("Add description...", text: $editedDetail, axis: .vertical)
                                .font(.system(size: 14, design: .rounded)).lineLimit(3...6)
                        } else {
                            Text(editedDetail.isEmpty ? "No description added." : editedDetail)
                                .font(.system(size: 14, design: .rounded)).foregroundColor(Color.textSecondary).lineSpacing(4)
                        }
                    }
                    .padding(20).frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.white).cornerRadius(20).shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 2)

                    // Options
                    VStack(spacing: 0) {
                        Toggle(isOn: $editedIsDone) {
                            Label("Mark as Done", systemImage: "checkmark.circle.fill")
                                .font(.system(size: 14, weight: .medium, design: .rounded)).foregroundColor(Color.textPrimary)
                        }.disabled(!isEditing).padding(16)

                        if isEditing {
                            Divider().padding(.horizontal)
                            VStack(alignment: .leading, spacing: 8) {
                                Label("Priority", systemImage: "flag.fill")
                                    .font(.system(size: 14, weight: .medium, design: .rounded)).foregroundColor(Color.textPrimary)
                                    .padding(.horizontal, 16).padding(.top, 16)
                                Picker("Priority", selection: $editedPriority) {
                                    ForEach(ToDoItem.Priority.allCases, id: \.self) { p in Text(p.rawValue).tag(p) }
                                }.pickerStyle(.segmented).padding(.horizontal, 16).padding(.bottom, 16)
                            }
                            Divider().padding(.horizontal)
                            DatePicker("Due Date", selection: $editedDueDate, displayedComponents: [.date, .hourAndMinute])
                                .font(.system(size: 14, weight: .medium, design: .rounded)).padding(16)
                        }
                    }
                    .background(Color.white).cornerRadius(20).shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 2)

                    if isEditing {
                        Button(action: saveChanges) {
                            Text("Save Changes")
                                .font(.system(size: 16, weight: .semibold, design: .rounded)).foregroundColor(.white)
                                .frame(maxWidth: .infinity).padding(.vertical, 17)
                                .background(LinearGradient(colors: [Color.brandBlue, Color.brandBlueDark],
                                                           startPoint: .leading, endPoint: .trailing))
                                .cornerRadius(16).shadow(color: Color.brandBlue.opacity(0.4), radius: 12, x: 0, y: 6)
                        }.disabled(editedTitle.trimmingCharacters(in: .whitespaces).isEmpty)
                    }

                    Button { showDeleteAlert = true } label: {
                        Text("Delete Task").font(.system(size: 15, weight: .medium, design: .rounded)).foregroundColor(.red)
                            .frame(maxWidth: .infinity).padding(.vertical, 17)
                            .background(Color.red.opacity(0.08)).cornerRadius(16)
                    }
                }.padding(20)
            }
        }
        .navigationTitle("Task Detail").navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(isEditing ? "Cancel" : "Edit") {
                    if isEditing { resetFields() }
                    withAnimation { isEditing.toggle() }
                }
                .font(.system(size: 14, weight: .semibold, design: .rounded)).foregroundColor(Color.brandBlue)
            }
        }
        .onAppear { resetFields() }
        .alert("Delete Task?", isPresented: $showDeleteAlert) {
            Button("Delete", role: .destructive) { if let id = item.id { viewModel.delete(id: id) }; dismiss() }
            Button("Cancel", role: .cancel) {}
        } message: { Text("This task will be permanently deleted.") }
    }

    private func resetFields() {
        editedTitle = item.title; editedDetail = item.detail
        editedDueDate = item.dueDate; editedIsDone = item.isDone; editedPriority = item.priority
    }

    private func saveChanges() {
        var updated = item
        updated.title = editedTitle; updated.detail = editedDetail
        updated.dueDate = editedDueDate; updated.isDone = editedIsDone; updated.priority = editedPriority
        viewModel.update(updated); isEditing = false
    }
}

// ════════════════════════════════════════════════════════════
// MARK: - ADD VIEW
// ════════════════════════════════════════════════════════════

struct AddToDoView: View {
    @ObservedObject var viewModel: ToDoViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var title    = ""
    @State private var detail   = ""
    @State private var dueDate  = Date().addingTimeInterval(86400)
    @State private var priority: ToDoItem.Priority = .medium
    @State private var isDone   = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.bgPage.ignoresSafeArea()
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        formCard {
                            VStack(alignment: .leading, spacing: 8) {
                                formLabel("Task Name")
                                TextField("e.g. UI Design Review", text: $title)
                                    .font(.system(size: 15, design: .rounded)).padding(14)
                                    .background(Color.bgPage).cornerRadius(12)
                            }
                        }
                        formCard {
                            VStack(alignment: .leading, spacing: 12) {
                                formLabel("Category")
                                HStack(spacing: 8) {
                                    ForEach(ToDoItem.Priority.allCases, id: \.self) { p in
                                        Button { withAnimation { priority = p } } label: {
                                            Text(p.rawValue)
                                                .font(.system(size: 13, weight: priority == p ? .semibold : .regular, design: .rounded))
                                                .foregroundColor(priority == p ? .white : Color.textSecondary)
                                                .padding(.horizontal, 18).padding(.vertical, 10)
                                                .background(priority == p ? Color.brandBlue : Color.bgPage).cornerRadius(10)
                                        }
                                    }
                                }
                            }
                        }
                        formCard {
                            VStack(alignment: .leading, spacing: 8) {
                                formLabel("Date & Time")
                                DatePicker("", selection: $dueDate, displayedComponents: [.date, .hourAndMinute]).labelsHidden()
                            }
                        }
                        formCard {
                            VStack(alignment: .leading, spacing: 8) {
                                formLabel("Description")
                                TextField("Add details about this task...", text: $detail, axis: .vertical)
                                    .font(.system(size: 14, design: .rounded)).lineLimit(3...5)
                                    .padding(14).background(Color.bgPage).cornerRadius(12)
                            }
                        }
                        Button {
                            guard !title.trimmingCharacters(in: .whitespaces).isEmpty else { return }
                            viewModel.add(ToDoItem(title: title, detail: detail, isDone: isDone, dueDate: dueDate, priority: priority))
                            dismiss()
                        } label: {
                            Text("Create Task")
                                .font(.system(size: 16, weight: .semibold, design: .rounded)).foregroundColor(.white)
                                .frame(maxWidth: .infinity).padding(.vertical, 17)
                                .background(LinearGradient(colors: [Color.brandBlue, Color.brandBlueDark],
                                                           startPoint: .leading, endPoint: .trailing))
                                .cornerRadius(16).shadow(color: Color.brandBlue.opacity(0.4), radius: 12, x: 0, y: 6)
                        }
                        .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                        .opacity(title.trimmingCharacters(in: .whitespaces).isEmpty ? 0.5 : 1)
                        Spacer(minLength: 20)
                    }.padding(20)
                }
            }
            .navigationTitle("Create New Task").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }.font(.system(size: 14, design: .rounded)).foregroundColor(Color.textSecondary)
                }
            }
        }
    }

    private func formCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        content().padding(16).frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.white).cornerRadius(18).shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 2)
    }

    private func formLabel(_ text: String) -> some View {
        Text(text).font(.system(size: 13, weight: .semibold, design: .rounded)).foregroundColor(Color.textPrimary)
    }
}

// ════════════════════════════════════════════════════════════
// MARK: - PREVIEW
// ════════════════════════════════════════════════════════════

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView(authVM: AuthViewModel())
    }
}
