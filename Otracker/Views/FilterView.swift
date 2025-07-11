import SwiftUI
import SwiftData

struct FilterView: View {

    @Query(sort: \Category.name) private var categories: [Category]
    @Query(sort: \SourceOfFund.name) private var sources: [SourceOfFund]
    
    @Binding var startDate: Date
    @Binding var endDate: Date
    @Binding var selectedCategory: Category?
    @Binding var selectedSource: SourceOfFund?
    
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("filter_view_date_range_header")) {
                    DatePicker("filter_view_from_date_label", selection: $startDate, displayedComponents: .date)
                    DatePicker("filter_view_to_date_label", selection: $endDate, displayedComponents: .date)
                }
                
                Section(header: Text("filter_view_other_filters_header")) {
                    Picker("filter_view_category_picker_label", selection: $selectedCategory) {
                        Text("filter_view_all_categories_option").tag(Category?.none)
                        ForEach(categories) { category in
                            Text(category.name).tag(category as Category?)
                        }
                    }
                    
                    Picker("filter_view_source_picker_label", selection: $selectedSource) {
                        Text("filter_view_all_sources_option").tag(SourceOfFund?.none)
                        ForEach(sources) { source in
                            Text(source.name).tag(source as SourceOfFund?)
                        }
                    }
                }
            }
            .navigationTitle("filter_view_title")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("filter_view_reset_button") {
                        resetFilters()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("filter_view_done_button") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func resetFilters() {
        startDate = .distantPast
        endDate = .distantFuture
        selectedCategory = nil
        selectedSource = nil
    }
}
