import SwiftUI
import SwiftData

struct TransactionHistoryView: View {
    @Query(sort: \Transaction.date, order: .reverse) private var allTransactions: [Transaction]
    
    @State private var searchText: String = ""
    @State private var selectedCategory: Category? = nil
    @State private var selectedSource: SourceOfFund? = nil
    @State private var startDate: Date = .distantPast
    @State private var endDate: Date = .distantFuture
    
    @State private var showingFilterSheet = false
    @State private var showingFormSheet = false
    @State private var transactionToEdit: Transaction?
    
    @StateObject private var speechService = SpeechRecognitionService()
    @State private var showVoiceUI = false
    @State private var isAnalyzingAI = false
    @State private var voiceInitialData: InitialTransactionData? = nil

    private var filteredTransactions: [Transaction] {
        allTransactions.filter { transaction in
            let searchMatch = searchText.isEmpty || transaction.transactionDescription.localizedStandardContains(searchText)
            let categoryMatch = selectedCategory == nil || transaction.category == selectedCategory
            let sourceMatch = selectedSource == nil || transaction.sourceOfFund == selectedSource
            let dateMatch = (startDate == .distantPast && endDate == .distantFuture) || (transaction.date >= startDate && transaction.date < (Calendar.current.date(byAdding: .day, value: 1, to: endDate) ?? .distantFuture))
            return searchMatch && categoryMatch && sourceMatch && dateMatch
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                FilteredTransactionList(transactions: filteredTransactions) { transaction in
                    self.transactionToEdit = transaction
                    self.voiceInitialData = nil
                    self.showingFormSheet = true
                }
                
                if showVoiceUI {
                    VoiceInputOverlay(
                        isRecording: speechService.isRecording,
                        transcribedText: speechService.transcribedText,
                        isAnalyzing: isAnalyzingAI,
                        errorText: speechService.error
                    ) {
                        withAnimation { showVoiceUI = false }
                        speechService.stopRecording()
                    }
                }
            }
            .navigationTitle("history_view_title")
            // --- PERBAIKAN: Gunakan Text() untuk melokalkan prompt ---
            .searchable(text: $searchText, prompt: Text("history_view_search_prompt"))
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button { showingFilterSheet.toggle() } label: { Label("history_view_filter_button", systemImage: "line.3.horizontal.decrease.circle") }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button {
                            self.transactionToEdit = nil
                            self.voiceInitialData = nil
                            self.showingFormSheet = true
                        } label: { Label("history_view_manual_input_menu", systemImage: "square.and.pencil") }
                        
                        Button { handleVoiceInput() } label: { Label("history_view_voice_input_menu", systemImage: "mic.fill") }
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .symbolRenderingMode(.hierarchical)
                            .font(.title2)
                    }
                }
            }
            .sheet(isPresented: $showingFormSheet) {
                AddTransactionView(transactionToEdit: transactionToEdit, initialData: voiceInitialData)
            }
            .sheet(isPresented: $showingFilterSheet) {
                FilterView(startDate: $startDate, endDate: $endDate, selectedCategory: $selectedCategory, selectedSource: $selectedSource)
            }
            .onChange(of: speechService.isRecording) { _, isRecording in
                if !isRecording && !speechService.transcribedText.isEmpty {
                    isAnalyzingAI = true
                    analyzeTextWithAI(text: speechService.transcribedText)
                }
            }
        }
    }
    
    private func handleVoiceInput() {
        if speechService.isRecording {
            speechService.stopRecording()
        } else {
            self.transactionToEdit = nil
            self.voiceInitialData = nil
            withAnimation { self.showVoiceUI = true }
            speechService.startRecording()
        }
    }
    
    private func analyzeTextWithAI(text: String) {
        guard let gemini = GeminiService() else {
            isAnalyzingAI = false
            withAnimation { showVoiceUI = false }
            return
        }
        gemini.analyzeSpokenTransaction(text: text) { result in
            isAnalyzingAI = false
            withAnimation { showVoiceUI = false }
            switch result {
            case .success(let info):
                self.voiceInitialData = .init(
                    description: info.description,
                    amount: info.amount,
                    sourceOfFundName: nil,
                    categoryName: nil
                )
                self.showingFormSheet = true
            case .failure(let error):
                print("AI Analysis Error: \(error.localizedDescription)")
            }
            speechService.transcribedText = ""
        }
    }
}

struct FilteredTransactionList: View {
    @Environment(\.modelContext) private var modelContext
    let transactions: [Transaction]
    var onEdit: (Transaction) -> Void
    var body: some View {
        List {
            ForEach(transactions) { transaction in
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(transaction.transactionDescription).fontWeight(.semibold)
                        Text(transaction.category?.name ?? NSLocalizedString("filtered_list_no_category", comment: "")).font(.caption).foregroundColor(.gray)
                        Text(transaction.date, format: .dateTime.day().month().year()).font(.caption2).foregroundColor(.secondary)
                    }
                    Spacer()
                    Text(transaction.amount, format: .currency(code: "IDR")).foregroundColor(.red)
                }
                .contextMenu {
                    if transaction.category?.name != NSLocalizedString("bills_view_default_category", comment: "") {
                        Button { onEdit(transaction) } label: { Label("filtered_list_edit_action", systemImage: "pencil") }
                    }
                    Button(role: .destructive) { delete(transaction: transaction) } label: { Label("filtered_list_delete_action", systemImage: "trash") }
                }
            }
        }
        .overlay {
            if transactions.isEmpty {
                ContentUnavailableView("filtered_list_empty_title", systemImage: "magnifyingglass", description: Text("filtered_list_empty_description"))
            }
        }
    }
    
    private func delete(transaction: Transaction) {
        withAnimation {
            if let transactionToDelete = transactions.first(where: { $0.id == transaction.id }) {
                modelContext.delete(transactionToDelete)
            }
        }
    }
}

struct VoiceInputOverlay: View {
    var isRecording: Bool
    var transcribedText: String
    var isAnalyzing: Bool
    var errorText: String?
    var onEdit: () -> Void
    var body: some View {
        VStack {
            Spacer()
            VStack(spacing: 20) {
                if let errorText = errorText {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.largeTitle)
                        .foregroundStyle(.yellow)
                    Text(errorText)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal)
                } else if isAnalyzing {
                    ProgressView(LocalizedStringKey("voice_overlay_analyzing"))
                        .padding()
                } else if isRecording {
                    Text(LocalizedStringKey("voice_overlay_listening"))
                                            
                        .font(.title2.bold())
                        Text(transcribedText.isEmpty ? NSLocalizedString("voice_overlay_prompt", comment: "") : transcribedText)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity, minHeight: 60)
                }
                
                Button(isRecording ? LocalizedStringKey("voice_overlay_done_button") : LocalizedStringKey("voice_overlay_cancel_button"), role: isRecording ? .none : .destructive, action: onEdit)
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                    .tint(isRecording ? .red : .accentColor)
            }
            .padding(30)
            .frame(maxWidth: .infinity)
            .background(.ultraThinMaterial, in: .rect(cornerRadius: 20))
            .padding()
            .padding(.bottom, 20)
        }
        .background(Color.black.opacity(0.4).ignoresSafeArea().onTapGesture(perform: onEdit))
        .transition(.move(edge: .bottom).combined(with: .opacity))
        .animation(.spring, value: isRecording)
        .animation(.spring, value: isAnalyzing)
    }
}
