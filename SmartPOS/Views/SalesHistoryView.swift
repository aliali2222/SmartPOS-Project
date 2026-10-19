import SwiftUI
import SwiftData

struct SalesHistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \SaleTransaction.date, order: .reverse) private var allSales: [SaleTransaction]
    @Query private var products: [Product]
    
    @State private var filterByDate = false
    @State private var startDate = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
    @State private var endDate = Date()
    
    @State private var saleToReturn: SaleTransaction?
    @State private var sharedPDF: SharedPDFItem?
    
    var filteredSales: [SaleTransaction] {
        guard filterByDate else { return allSales }
        let startOfDay = Calendar.current.startOfDay(for: startDate)
        let endOfDay = Calendar.current.date(bySettingHour: 23, minute: 59, second: 59, of: endDate) ?? endDate
        
        return allSales.filter { sale in
            sale.date >= startOfDay && sale.date <= endOfDay
        }
    }
    
    var netRevenue: Double {
        filteredSales
            .filter { !$0.isReturned }
            .reduce(0) { $0 + $1.totalAmount }
    }
    
    var netProfit: Double {
        filteredSales
            .filter { !$0.isReturned }
            .reduce(0) { $0 + $1.totalProfit }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                HStack(spacing: 12) {
                    StatCard(
                        title: "صافي المبيعات",
                        value: String(format: "%.2f", netRevenue),
                        color: .green
                    )
                    StatCard(
                        title: "صافي الأرباح",
                        value: String(format: "%.2f", netProfit),
                        color: .blue
                    )
                }
                .padding()
                
                VStack(spacing: 8) {
                    Toggle("تصفية المبيعات بالتاريخ", isOn: $filterByDate.animation())
                        .font(.subheadline.bold())
                    
                    if filterByDate {
                        HStack {
                            DatePicker("من:", selection: $startDate, displayedComponents: .date)
                                .labelsHidden()
                            Text("إلى")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            DatePicker("إلى:", selection: $endDate, displayedComponents: .date)
                                .labelsHidden()
                        }
                        .padding(.top, 4)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 10)
                
                if filteredSales.isEmpty {
                    ContentUnavailableView(
                        "لا توجد مبيعات",
                        systemImage: "doc.text.magnifyingglass",
                        description: Text("لم يتم العثور على فواتير في هذه الفترة الزمنية.")
                    )
                } else {
                    List {
                        ForEach(filteredSales) { sale in
                            DisclosureGroup {
                                ForEach(sale.items) { item in
                                    HStack {
                                        Text("\(item.productName) (×\(item.quantity))")
                                            .font(.subheadline)
                                        Spacer()
                                        Text("\(item.subtotal, specifier: "%.2f")")
                                            .font(.subheadline)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                
                                VStack(alignment: .leading, spacing: 10) {
                                    Button {
                                        if let url = InvoicePDFGenerator.generatePDF(for: sale) {
                                            sharedPDF = SharedPDFItem(url: url)
                                        }
                                    } label: {
                                        Label("تصدير ومشاركة الفاتورة (PDF / طباعة)", systemImage: "printer.fill")
                                            .font(.subheadline.bold())
                                            .foregroundStyle(.blue)
                                    }
                                    
                                    if !sale.isReturned {
                                        Divider()
                                        Button(role: .destructive) {
                                            saleToReturn = sale
                                        } label: {
                                            Label("استرجاع الفاتورة وإعادة الكميات للمخزون", systemImage: "arrow.uturn.backward.circle.fill")
                                                .font(.subheadline.bold())
                                        }
                                    }
                                }
                                .padding(.top, 6)
                                
                            } label: {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        HStack {
                                            Text(sale.invoiceNumber)
                                                .font(.headline)
                                            
                                            if sale.isReturned {
                                                Text("مسترجعة")
                                                    .font(.caption2.bold())
                                                    .padding(.horizontal, 6)
                                                    .padding(.vertical, 2)
                                                    .background(Color.red.opacity(0.15))
                                                    .foregroundStyle(.red)
                                                    .clipShape(Capsule())
                                            }
                                        }
                                        
                                        Text(sale.date.formatted(date: .abbreviated, time: .shortened))
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    
                                    Spacer()
                                    
                                    Text("\(sale.totalAmount, specifier: "%.2f")")
                                        .font(.headline)
                                        .strikethrough(sale.isReturned, color: .red)
                                        .foregroundStyle(sale.isReturned ? .secondary : .primary)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("سجل المبيعات والتقارير")
            .sheet(item: $sharedPDF) { item in
                ShareSheet(items: [item.url])
                    .presentationDetents([.medium, .large])
            }
            .alert(
                "تأكيد استرجاع الفاتورة",
                isPresented: Binding(
                    get: { saleToReturn != nil },
                    set: { if !$0 { saleToReturn = nil } }
                ),
                presenting: saleToReturn
            ) { sale in
                Button("تأكيد الاسترجاع", role: .destructive) {
                    processReturn(for: sale)
                }
                Button("إلغاء", role: .cancel) {
                    saleToReturn = nil
                }
            } message: { sale in
                Text("هل تريد استرجاع الفاتورة رقم (\(sale.invoiceNumber))؟ سيتم إعادة جميع الكميات المباعة إلى المخزون وخصم المبلغ من صافي المبيعات.")
            }
        }
    }
    
    private func processReturn(for sale: SaleTransaction) {
        guard !sale.isReturned else { return }
        sale.isReturned = true
        
        for item in sale.items {
            if let matchingProduct = products.first(where: { $0.id == item.productID }) {
                matchingProduct.stockQuantity += item.quantity
            }
        }
        
        saleToReturn = nil
    }
}
