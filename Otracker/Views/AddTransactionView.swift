import SwiftUI
import PhotosUI
import SwiftData


struct AddTransactionView: View {
    
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) var dismiss
    
    @Query(sort: \Category.name) private var categories: [Category]
    @Query(sort: \SourceOfFund.name) private var sourcesOfFund: [SourceOfFund]

    @State private var description: String = ""
    @State private var amount: Double = 0.0
    @State private var date: Date = .now
    @State private var selectedCategory: Category?
    @State private var selectedSubcategory: Subcategory?
    @State private var selectedSource: SourceOfFund?
    
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    var transactionToEdit: Transaction?
    var initialData: InitialTransactionData?

    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            Form {

                if transactionToEdit == nil {
                    Section(header: Text("auto_input_section_header")) {
                        // Tombol untuk Scan Struk Gambar
                        PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                            HStack {
                                Image(systemName: "camera.fill")
                                Text("scan_receipt_button")
                            }
                        }
                        .onChange(of: selectedPhotoItem) { _, newItem in
                            processSelectedPhoto(photoItem: newItem)
                        }
                        
                        
                        if isLoading {
                            HStack(spacing: 10) {
                                ProgressView()
                                Text("analyzing_text")
                            }
                        }
                        
                        // Pesan error jika terjadi masalah
                        if let errorMessage = errorMessage {
                            Text(errorMessage)
                                .foregroundColor(.red)
                                .font(.caption)
                        }
                    }
                }
                
                Section(header: Text("transaction_details_section_header")) {
                    TextField("description_placeholder", text: $description)
                    TextField("amount_placeholder", value: $amount, format: .currency(code: "IDR"))
                        .keyboardType(.decimalPad)
                    DatePicker("date_label", selection: $date, displayedComponents: .date)
                }
                
                Section(header: Text("category_source_section_header")) {
                    Picker("category_picker_label", selection: $selectedCategory) {
                        Text("category_picker_placeholder").tag(Category?.none)
                        ForEach(categories) { category in
                            Text(category.name).tag(category as Category?)
                        }
                    }
                    .disabled(transactionToEdit?.category?.name == "Tagihan")
                    
                    if let category = selectedCategory, !category.subcategories.isEmpty {
                        Picker("subcategory_picker_label", selection: $selectedSubcategory) {
                            Text("subcategory_picker_placeholder").tag(Subcategory?.none)
                            ForEach(category.subcategories.sorted(by: { $0.name < $1.name })) { sub in
                                Text(sub.name).tag(sub as Subcategory?)
                            }
                        }
                    }

                    Picker("source_picker_label", selection: $selectedSource) {
                        Text("source_picker_placeholder").tag(SourceOfFund?.none)
                        ForEach(sourcesOfFund) { source in
                            Text(source.name).tag(source as SourceOfFund?)
                        }
                    }
                }
            }
            .navigationTitle(transactionToEdit == nil ? "add_transaction_title" : "edit_transaction_title")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("cancel_button") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("save_button") { saveOrUpdate() }
                        .disabled(description.isEmpty || amount == 0 || selectedCategory == nil || selectedSource == nil)
                }
            }
            .onAppear(perform: loadData)
        }
    }
    
    
    private func loadData() {
        if let transaction = transactionToEdit {
            description = transaction.transactionDescription
            amount = transaction.amount
            date = transaction.date
            selectedCategory = transaction.category
            selectedSubcategory = transaction.subcategory
            selectedSource = transaction.sourceOfFund
        } else if let data = initialData {
            description = data.description ?? ""
            amount = data.amount ?? 0.0
            
            if let sourceName = data.sourceOfFundName {
                selectedSource = sourcesOfFund.first { $0.name.lowercased() == sourceName.lowercased() }
            }
            
            if let categoryName = data.categoryName {
                selectedCategory = categories.first { $0.name.lowercased() == categoryName.lowercased() }
            }
            
            if selectedCategory == nil {
                selectedCategory = categories.first { $0.name == "Lainnya" }
            }
        }
    }
    
    private func saveOrUpdate() {
        guard let finalCategory = selectedCategory, let finalSource = selectedSource else { return }
        
        if let transaction = transactionToEdit {
            transaction.transactionDescription = description
            transaction.amount = amount
            transaction.date = date
            transaction.category = finalCategory
            transaction.subcategory = selectedSubcategory
            transaction.sourceOfFund = finalSource
        } else {
            let newTransaction = Transaction(
                description: description, amount: amount, date: date, category: finalCategory, subcategory: selectedSubcategory, sourceOfFund: finalSource
            )
            modelContext.insert(newTransaction)
        }
        
        try? modelContext.save()
        dismiss()
    }

    private func processSelectedPhoto(photoItem: PhotosPickerItem?) {
            guard let item = photoItem else { return }
            
            isLoading = true
            errorMessage = nil
            
            Task {
                if let data = try? await item.loadTransferable(type: Data.self), let uiImage = UIImage(data: data) {
                    guard let geminiService = GeminiService() else {
                        errorMessage = NSLocalizedString("error_api_key_not_found", comment: "")
                        isLoading = false
                        return
                    }
                    
                    geminiService.analyzeReceipt(image: uiImage) { result in
                        isLoading = false
                        switch result {
                        case .success(let info):
                            self.description = info.merchant_name ?? ""
                            self.amount = info.amount ?? 0.0
                            
                            // --- LOGIKA BARU YANG LEBIH TANGGUH UNTUK TANGGAL ---
                            self.date = parseAndCorrectDate(from: info.transaction_date)
                            
                        case .failure(let error):
                            let format = NSLocalizedString("error_failed_to_analyze", comment: "")
                            errorMessage = String(format: format, error.localizedDescription)
                        }
                    }
                } else {
                    errorMessage = NSLocalizedString("error_failed_to_load_image", comment: "")
                    isLoading = false
            }
        }
    }
    // --- FUNGSI HELPER BARU UNTUK MEM-PARSE DAN MEMPERBAIKI TANGGAL ---
        private func parseAndCorrectDate(from dateString: String?) -> Date {
            // Default ke hari ini jika tidak ada string tanggal
            guard let dateString = dateString, !dateString.isEmpty else {
                return .now
            }
            
            let calendar = Calendar.current
            let currentYear = calendar.component(.year, from: Date())
            
            let formatter = DateFormatter()
            var parsedDate: Date?

            // 1. Coba format paling lengkap dulu: YYYY-MM-DD
            formatter.dateFormat = "yyyy-MM-dd"
            if let date = formatter.date(from: dateString) {
                parsedDate = date
            }
            
            // 2. Jika gagal, coba format umum struk: DD/MM/YYYY
            if parsedDate == nil {
                formatter.dateFormat = "dd/MM/yyyy"
                if let date = formatter.date(from: dateString) {
                    parsedDate = date
                }
            }

            // 3. Jika masih gagal, coba format tanpa tahun: DD/MM
            if parsedDate == nil {
                formatter.dateFormat = "dd/MM"
                if let dateWithWrongYear = formatter.date(from: dateString) {
                    // Ambil hari dan bulan, lalu gabungkan dengan tahun saat ini
                    var components = calendar.dateComponents([.day, .month], from: dateWithWrongYear)
                    components.year = currentYear
                    parsedDate = calendar.date(from: components)
                }
            }
            
            // --- Jaring Pengaman Utama ---
            guard var finalDate = parsedDate else {
                // Jika semua format gagal, kembalikan tanggal hari ini
                return .now
            }
            
            // Cek jika tahun dari hasil parse BUKAN tahun saat ini
            let parsedYear = calendar.component(.year, from: finalDate)
            if parsedYear != currentYear {
                // Paksa ganti tahunnya menjadi tahun saat ini
                var components = calendar.dateComponents([.day, .month], from: finalDate)
                components.year = currentYear
                if let correctedDate = calendar.date(from: components) {
                    finalDate = correctedDate
                }
            }
            
            // Jaring pengaman terakhir: jika tanggalnya masih di masa depan
            // (misalnya, parse 31/12 dan sekarang masih 01/01)
            if finalDate > Date() {
                return .now
            }
            
            return finalDate
        }
}
