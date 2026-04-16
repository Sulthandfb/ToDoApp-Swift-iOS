//
//  ContentView.swift
//  L25020028-ToDoApp
//
// ============================================================
//  STRUKTUR FILE (baca dari atas ke bawah):
//
//  1. MODEL       → ToDoItem        data satu tugas
//  2. VIEWMODEL   → ToDoViewModel   logika + sumber data utama
//  3. MAIN VIEW   → ContentView     tampilan list utama
//  4. CARD VIEW   → ToDoCardView    satu baris item di list
//  5. DETAIL VIEW → ToDoDetailView  halaman detail + edit
//  6. ADD VIEW    → AddToDoView     sheet tambah tugas baru
// ============================================================

import SwiftUI

// ════════════════════════════════════════════════════════════
// MARK: - 1. MODEL
// ════════════════════════════════════════════════════════════
//
// Mengapa struct?
// → Struct adalah VALUE TYPE: setiap assignment membuat salinan baru.
// → Aman untuk SwiftUI karena @Published bisa mendeteksi perubahan
//   pada array of struct ketika seluruh elemen diganti (items[i] = baru).
//
// Identifiable → SwiftUI bisa track tiap item unik di ForEach/List
//   tanpa perlu kita tulis id: \.id secara manual.

struct ToDoItem: Identifiable {
    let id: UUID        // tidak boleh diubah setelah dibuat (let, bukan var)
    var title: String
    var detail: String
    var isDone: Bool
    var dueDate: Date

    // Custom init dengan nilai default — memudahkan pembuatan item baru
    // Caller cukup tulis ToDoItem(title: "Beli susu") tanpa isi semua field
    init(
        id: UUID = UUID(),
        title: String,
        detail: String = "",
        isDone: Bool = false,
        dueDate: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.detail = detail
        self.isDone = isDone
        self.dueDate = dueDate
    }
}

// ════════════════════════════════════════════════════════════
// MARK: - 2. VIEWMODEL
// ════════════════════════════════════════════════════════════
//
// @ObservableObject
// → Protokol yang membuat class ini bisa "diamati" oleh SwiftUI.
// → Di balik layar, Combine framework membuat Publisher untuk
//   setiap property @Published di dalam class ini.
// → View yang subscribe akan otomatis di-render ulang saat ada perubahan.
//
// Mengapa class, bukan struct?
// → @ObservableObject hanya bisa diterapkan ke class (reference type).
// → Semua view yang subscribe pegang REFERENSI ke objek yang sama,
//   bukan salinan — sehingga data selalu sinkron di semua view.
//
// final → class ini tidak boleh di-subclass (baik untuk performa compiler)

final class ToDoViewModel: ObservableObject {

    // @Published
    // → Setiap kali 'items' berubah, Combine otomatis broadcast sinyal
    //   ke semua view yang sedang menampilkan data dari ViewModel ini.
    // → SwiftUI menangkap sinyal itu dan memanggil body view lagi.
    @Published var items: [ToDoItem] = [
        ToDoItem(
            title: "Design UI",
            detail: "Follow Microsoft To Do style",
            dueDate: Date().addingTimeInterval(3600)     // 1 jam dari sekarang
        ),
        ToDoItem(
            title: "Implement features",
            detail: "Add/edit/delete, navigation",
            dueDate: Date().addingTimeInterval(86400)    // 1 hari dari sekarang
        )
    ]

    // ── Tambah ───────────────────────────────────────────────
    // insert(at: 0) → item baru muncul di paling atas list
    func add(_ item: ToDoItem) {
        items.insert(item, at: 0)
    }

    // ── Hapus ────────────────────────────────────────────────
    // removeAll: cari berdasarkan id (UUID) bukan index,
    // karena index bisa berubah kalau list sedang di-filter/sort.
    func delete(id: UUID) {
        items.removeAll { $0.id == id }
    }

    // ── Toggle selesai ───────────────────────────────────────
    // guard: keluar lebih awal kalau id tidak ditemukan (defensive programming)
    // toggle(): membalik nilai Bool — true jadi false, false jadi true
    func toggleDone(id: UUID) {
        guard let index = items.firstIndex(where: { $0.id == id }) else { return }
        items[index].isDone.toggle()
    }

    // ── Computed properties ──────────────────────────────────
    // Dihitung ulang setiap kali dipanggil — tidak disimpan di memori.
    // Karena bergantung pada @Published items, perubahan items otomatis
    // membuat nilai ini ikut "berubah" saat view membacanya kembali.
    var doneCount: Int    { items.filter {  $0.isDone }.count }
    var pendingCount: Int { items.filter { !$0.isDone }.count }
}

// ════════════════════════════════════════════════════════════
// MARK: - 3. MAIN VIEW
// ════════════════════════════════════════════════════════════
//
// ContentView adalah "root view" — view paling atas yang mengurus
// state utama dan mendistribusikan data ke child views di bawahnya.

struct ContentView: View {

    // @StateObject
    // → SwiftUI MEMBUAT dan MEMILIKI instance ToDoViewModel ini.
    // → Instance tidak dihancurkan meskipun ContentView di-recreate.
    // → Gunakan @StateObject ketika VIEW INILAH yang pertama membuat instance.
    //
    // ⚠️  Kesalahan umum: @ObservedObject var viewModel = ToDoViewModel()
    //     → Ini membuat instance baru setiap parent re-render → data hilang!
    //     → @ObservedObject hanya untuk instance yang DITERIMA dari luar (parent).
    @StateObject private var viewModel = ToDoViewModel()

    // @State — data lokal milik ContentView sendiri
    // → Disimpan SwiftUI di luar struct (struct di-recreate tiap render)
    // → Setiap perubahan nilai @State → body dipanggil ulang → UI update
    @State private var showAddTask      = false   // kontrol sheet AddToDoView
    @State private var searchText       = ""      // isi kotak pencarian
    @State private var selectedSegment  = 0       // filter: All / In Progress / Done
    @State private var quickAddText     = ""      // isi field quick add
    @State private var showQuickAddField = false  // tampilkan/sembunyikan quick add

    // Computed property: mengembalikan list yang sudah di-filter
    // Dipanggil setiap render — tidak pakai @State karena nilainya
    // bisa diturunkan (derived) dari state lain yang sudah ada.
    private var filteredItems: [ToDoItem] {
        var list = viewModel.items

        // Filter berdasarkan teks pencarian (case-insensitive)
        if !searchText.isEmpty {
            list = list.filter {
                $0.title.localizedCaseInsensitiveContains(searchText) ||
                $0.detail.localizedCaseInsensitiveContains(searchText)
            }
        }

        // Filter berdasarkan segment yang dipilih
        switch selectedSegment {
        case 1:  return list.filter { !$0.isDone }   // In Progress
        case 2:  return list.filter {  $0.isDone }   // Done
        default: return list                          // All
        }
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                Color(.systemGroupedBackground).ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        statsCardView
                        searchAndFilterView
                        taskListView

                        // Quick Add field — muncul/hilang dengan animasi
                        // .transition: animasi slide dari bawah + fade
                        if showQuickAddField {
                            quickAddFieldView
                                .transition(.move(edge: .bottom).combined(with: .opacity))
                        }

                        // Spacer transparan agar konten tidak ketutup bottom bar
                        Color.clear.frame(height: 80)
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)
                }

                bottomBarView
            }
            .navigationTitle("My Tasks")
            .navigationBarTitleDisplayMode(.large)
            // $showAddTask → Binding ke @State showAddTask
            // Sheet muncul saat showAddTask = true, tutup saat false
            .sheet(isPresented: $showAddTask) {
                // Kirim $showAddTask sebagai @Binding ke AddToDoView
                // sehingga AddToDoView bisa menutup dirinya sendiri
                // dengan set isPresented = false
                AddToDoView(isPresented: $showAddTask) { newItem in
                    viewModel.add(newItem)
                }
            }
            // Animasi spring dipakai untuk transisi showQuickAddField
            .animation(.spring(response: 0.35, dampingFraction: 0.8), value: showQuickAddField)
        }
    }

    // ── Stats Card ───────────────────────────────────────────
    // Menampilkan ringkasan: Total / Pending / Done
    // Dibuat sebagai computed property (private var) agar body tetap bersih
    private var statsCardView: some View {
        HStack(spacing: 0) {
            statItem(value: viewModel.items.count,  label: "Total",   color: .blue)
            Divider().frame(height: 40)
            statItem(value: viewModel.pendingCount, label: "Pending", color: .orange)
            Divider().frame(height: 40)
            statItem(value: viewModel.doneCount,    label: "Done",    color: .green)
        }
        .padding(.vertical, 16)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 2)
    }

    // Helper kecil untuk satu kolom angka di stats card
    private func statItem(value: Int, label: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text("\(value)")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(color)
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    // ── Search & Filter ──────────────────────────────────────
    private var searchAndFilterView: some View {
        VStack(spacing: 12) {
            // Search bar custom (bukan SearchBar built-in)
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)

                // $searchText → Binding: setiap ketikan langsung update @State
                // → filteredItems dihitung ulang → taskListView re-render
                TextField("Search tasks...", text: $searchText)
                    .disableAutocorrection(true)

                // Tombol clear muncul hanya saat ada teks
                if !searchText.isEmpty {
                    Button { searchText = "" } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(12)
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 1)

            // Segmented control — $selectedSegment terikat ke @State di atas
            // Saat user tap segment → selectedSegment berubah → filteredItems update
            Picker("Filter", selection: $selectedSegment) {
                Text("All").tag(0)
                Text("In Progress").tag(1)
                Text("Done").tag(2)
            }
            .pickerStyle(.segmented)
        }
    }

    // ── Task List ────────────────────────────────────────────
    private var taskListView: some View {
        Group {
            if filteredItems.isEmpty {
                // Empty state
                VStack(spacing: 12) {
                    Image(systemName: "checklist")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary.opacity(0.5))
                        .padding(.top, 40)
                    Text("No tasks here")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    Text("Use Quick Add or tap + to get started")
                        .font(.subheadline)
                        .foregroundColor(.secondary.opacity(0.8))
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)

            } else {
                // LazyVStack: view hanya dibuat saat akan masuk layar
                // lebih efisien dari VStack biasa untuk list panjang
                LazyVStack(spacing: 10) {
                    ForEach(filteredItems) { item in

                        // NavigationLink: tap → push ToDoDetailView ke stack
                        NavigationLink(
                            destination: ToDoDetailView(
                                // $viewModel.items[...] → Binding langsung ke elemen array
                                // Perubahan di DetailView langsung update array di ViewModel
                                // tanpa perlu callback tambahan
                                //
                                // firstIndex(where:)! → force unwrap aman di sini karena
                                // item pasti ada di array (kita baru saja iterasi dari sana)
                                item: $viewModel.items[
                                    viewModel.items.firstIndex(where: { $0.id == item.id })!
                                ],
                                onDelete: { viewModel.delete(id: item.id) }
                            )
                        ) {
                            // ToDoCardView menerima item sebagai nilai biasa (bukan Binding)
                            // karena card hanya perlu TAMPILKAN data, tidak mengubahnya.
                            // Toggle dilakukan via callback onToggleDone → viewModel.toggleDone
                            ToDoCardView(item: item) {
                                viewModel.toggleDone(id: item.id)
                            }
                        }
                        .buttonStyle(.plain)   // hilangkan highlight biru default NavigationLink
                    }
                }
            }
        }
    }

    // ── Quick Add Field ──────────────────────────────────────
    // TextField inline yang muncul di atas bottom bar
    private var quickAddFieldView: some View {
        HStack(spacing: 10) {
            Image(systemName: "plus.circle.fill")
                .foregroundColor(.accentColor)
                .font(.title3)

            TextField("Task name...", text: $quickAddText)
                .submitLabel(.done)          // tombol keyboard berubah jadi "Done"
                .onSubmit { submitQuickAdd() }  // dipanggil saat user tap "Done" di keyboard

            if !quickAddText.isEmpty {
                Button(action: submitQuickAdd) {
                    Text("Add")
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 7)
                        .background(Color.accentColor)
                        .cornerRadius(10)
                }
            }

            // Tombol tutup quick add field
            Button {
                withAnimation { showQuickAddField = false }
                quickAddText = ""
            } label: {
                Image(systemName: "xmark")
                    .foregroundColor(.secondary)
                    .font(.footnote)
                    .fontWeight(.semibold)
            }
        }
        .padding(14)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: -2)
    }

    // ── Bottom Bar ───────────────────────────────────────────
    private var bottomBarView: some View {
        HStack(spacing: 16) {

            // Tombol kiri: toggle Quick Add field
            Button {
                withAnimation {
                    showQuickAddField.toggle()
                    if !showQuickAddField { quickAddText = "" }
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: showQuickAddField ? "xmark" : "bolt.fill")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    Text(showQuickAddField ? "Close" : "Quick Add")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
                .foregroundColor(showQuickAddField ? .secondary : .accentColor)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    showQuickAddField
                        ? Color(.systemGray5)
                        : Color.accentColor.opacity(0.12)
                )
                .cornerRadius(12)
            }

            Spacer()

            // Tombol kanan: buka sheet AddToDoView
            Button {
                showAddTask = true    // ubah @State → sheet muncul otomatis
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "plus")
                        .font(.subheadline)
                        .fontWeight(.bold)
                    Text("New Task")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
                .foregroundColor(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(Color.accentColor)
                .cornerRadius(12)
                .shadow(color: Color.accentColor.opacity(0.4), radius: 6, x: 0, y: 3)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(.ultraThinMaterial)   // blur glass effect dari material system
    }

    // ── Quick Add Submit ─────────────────────────────────────
    // Dipanggil dari dua tempat: onSubmit keyboard dan tombol "Add"
    private func submitQuickAdd() {
        let trimmed = quickAddText.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }   // abaikan kalau hanya spasi
        viewModel.add(ToDoItem(title: trimmed))
        quickAddText = ""
        withAnimation { showQuickAddField = false }
    }
}

// ════════════════════════════════════════════════════════════
// MARK: - 4. CARD VIEW
// ════════════════════════════════════════════════════════════
//
// ToDoCardView hanya bertanggung jawab MENAMPILKAN satu item.
// Dia tidak menyimpan state apapun — semua data datang dari luar.
//
// Mengapa item bukan @Binding di sini?
// → Card hanya membaca data untuk ditampilkan, tidak mengubahnya.
// → Toggle selesai dilakukan via callback onToggleDone yang dikirim
//   dari parent (ContentView) → viewModel.toggleDone() di ViewModel.
// → Ini menjaga card tetap "dumb" (presentational only).

struct ToDoCardView: View {
    var item: ToDoItem          // nilai biasa, bukan Binding — card hanya baca
    var onToggleDone: () -> Void  // callback ke parent saat toggle ditekan

    var body: some View {
        HStack(alignment: .center, spacing: 14) {

            // ── Tombol centang ───────────────────────────────
            // Tap → memanggil onToggleDone() → naik ke ContentView
            // → viewModel.toggleDone(id:) → @Published items berubah
            // → SwiftUI re-render card ini dengan data baru
            Button(action: onToggleDone) {
                ZStack {
                    Circle()
                        .strokeBorder(
                            item.isDone ? Color.green : Color.gray.opacity(0.4),
                            lineWidth: 2
                        )
                        .frame(width: 26, height: 26)
                    if item.isDone {
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.green)
                    }
                }
            }
            .buttonStyle(.plain)

            // ── Info tugas ───────────────────────────────────
            VStack(alignment: .leading, spacing: 3) {
                Text(item.title)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .strikethrough(item.isDone, color: .secondary)

                if !item.detail.isEmpty {
                    Text(item.detail)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }

                // Tampilkan due date — merah jika sudah lewat dan belum selesai
                HStack(spacing: 4) {
                    Image(systemName: "clock").font(.caption2)
                    Text(item.dueDate.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption2)
                }
                .foregroundColor(isOverdue(item) ? .red.opacity(0.8) : .secondary.opacity(0.7))
            }

            Spacer()

            // ── Badge status ─────────────────────────────────
            Text(item.isDone ? "Done" : "Pending")
                .font(.caption2)
                .fontWeight(.semibold)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(item.isDone ? Color.green.opacity(0.15) : Color.orange.opacity(0.15))
                .foregroundColor(item.isDone ? .green : .orange)
                .cornerRadius(8)
        }
        .padding(14)
        .background(Color(.systemBackground))
        .cornerRadius(14)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 1)
    }

    // Helper: cek apakah tugas sudah lewat due date dan belum selesai
    private func isOverdue(_ item: ToDoItem) -> Bool {
        !item.isDone && item.dueDate < Date()
    }
}

// ════════════════════════════════════════════════════════════
// MARK: - 5. DETAIL VIEW
// ════════════════════════════════════════════════════════════
//
// ToDoDetailView menampilkan dan memungkinkan edit satu item.
//
// Pola data yang dipakai di sini:
//
//   @Binding var item
//   → Referensi dua arah ke elemen array di ViewModel.
//   → Saat "Save Changes" ditekan, perubahan ditulis langsung
//     ke item di ViewModel — tanpa perlu callback tambahan.
//   → Dikirim dari ContentView sebagai: $viewModel.items[index]
//
//   @State private var editedTitle, editedDetail, ...
//   → Salinan lokal dari data item, dipakai selama user mengedit.
//   → Tujuannya: user bisa batal (cancel) tanpa mengubah data asli.
//   → Baru di-commit ke @Binding saat user tap "Save Changes".

struct ToDoDetailView: View {

    // @Binding: referensi dua arah ke item di dalam array ViewModel
    // Menulis ke property ini langsung mengubah data sumber
    @Binding var item: ToDoItem
    var onDelete: () -> Void

    @Environment(\.dismiss) private var dismiss   // untuk tutup halaman ini

    // @State: salinan lokal untuk editing sementara
    // Diisi dari item saat .onAppear, di-commit ke @Binding saat Save
    @State private var editedTitle:   String = ""
    @State private var editedDetail:  String = ""
    @State private var editedDueDate: Date   = Date()
    @State private var editedIsDone:  Bool   = false
    @State private var showDeleteAlert = false

    var body: some View {
        Form {
            Section(header: Text("Task Info")) {
                // $editedTitle → Binding ke @State lokal
                // Perubahan hanya ada di @State sampai user tap Save
                TextField("Title",  text: $editedTitle)
                TextField("Detail", text: $editedDetail)
                Toggle("Completed", isOn: $editedIsDone)
            }

            Section(header: Text("Due Date")) {
                DatePicker(
                    "Due",
                    selection: $editedDueDate,
                    displayedComponents: [.date, .hourAndMinute]
                )
            }

            Section {
                // Tombol Save: tulis @State lokal → @Binding item → update ViewModel
                // Ini adalah satu-satunya tempat data ditulis balik ke sumber
                Button("Save Changes") {
                    item.title   = editedTitle    // tulis ke @Binding
                    item.detail  = editedDetail   // → langsung update array di ViewModel
                    item.dueDate = editedDueDate  // → @Published broadcast ke semua view
                    item.isDone  = editedIsDone
                    dismiss()
                }
                .fontWeight(.semibold)
                .disabled(editedTitle.trimmingCharacters(in: .whitespaces).isEmpty)

                Button("Delete Task", role: .destructive) {
                    showDeleteAlert = true
                }
            }
        }
        .navigationTitle("Task Details")
        .navigationBarTitleDisplayMode(.inline)
        // .onAppear: salin nilai item saat ini ke @State lokal
        // Dipanggil setiap kali view muncul di layar
        .onAppear {
            editedTitle   = item.title
            editedDetail  = item.detail
            editedDueDate = item.dueDate
            editedIsDone  = item.isDone
        }
        .alert("Delete Task?", isPresented: $showDeleteAlert) {
            Button("Delete", role: .destructive) {
                onDelete()   // panggil callback → viewModel.delete(id:)
                dismiss()    // tutup halaman setelah hapus
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This action cannot be undone.")
        }
    }
}

// ════════════════════════════════════════════════════════════
// MARK: - 6. ADD VIEW
// ════════════════════════════════════════════════════════════
//
// AddToDoView adalah sheet untuk membuat tugas baru.
//
// Pola data di sini berbeda dari DetailView:
//
//   @Binding var isPresented
//   → Referensi ke @State showAddTask di ContentView.
//   → Set isPresented = false → sheet otomatis tertutup.
//   → Alternatif modern: @Environment(\.dismiss), tapi @Binding
//     dipakai di sini untuk menunjukkan cara pass kontrol ke child.
//
//   var onAdd: (ToDoItem) -> Void
//   → Callback closure: dipanggil saat user tap "Add".
//   → Data baru dikirim ke parent (ContentView) → viewModel.add()
//   → AddToDoView tidak perlu tahu tentang ViewModel sama sekali.

struct AddToDoView: View {

    // @Binding ke @State showAddTask di ContentView
    // Saat di-set false, SwiftUI otomatis menutup sheet ini
    @Binding var isPresented: Bool

    // @State: field form sementara — hanya hidup selama sheet terbuka
    // Hilang otomatis saat sheet ditutup (view di-destroy)
    @State private var title   = ""
    @State private var detail  = ""
    @State private var dueDate = Date()
    @State private var isDone  = false

    // Closure callback — parent yang menentukan apa yang terjadi dengan item baru
    // Pattern ini menjaga AddToDoView tetap reusable dan tidak tahu tentang ViewModel
    var onAdd: (ToDoItem) -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Task Details")) {
                    TextField("Title",       text: $title)
                    TextField("Description", text: $detail)
                    DatePicker(
                        "Due date",
                        selection: $dueDate,
                        displayedComponents: [.date, .hourAndMinute]
                    )
                    Toggle("Mark as completed", isOn: $isDone)
                }
            }
            .navigationTitle("New Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    // Cancel: set isPresented = false → sheet tutup
                    Button("Cancel") { isPresented = false }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") {
                        guard !title.trimmingCharacters(in: .whitespaces).isEmpty else { return }
                        // Buat item baru dan kirim ke parent via callback
                        onAdd(ToDoItem(title: title, detail: detail, isDone: isDone, dueDate: dueDate))
                        isPresented = false   // tutup sheet
                    }
                    .fontWeight(.semibold)
                    .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}

// ════════════════════════════════════════════════════════════
// MARK: - PREVIEW
// ════════════════════════════════════════════════════════════
//
// Hanya aktif di Xcode Canvas — tidak ikut saat build ke device.
// ContentView pakai @StateObject jadi tidak perlu inject apapun dari luar.

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
