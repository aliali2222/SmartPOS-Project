import SwiftUI
import SwiftData

struct InventoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Product.name) private var products: [Product]
    
    @State private var searchText = ""
    @State private var showOnlyLowStock = false
    @State private var showingAddSheet = false
    @State private var productToEdit: Product?
    
    var filteredProducts: [Product] {
        products.filter { product in
            let matchesSearch = searchText.isEmpty ||
                product.name.localizedCaseInsensitiveContains(searchText) ||
                product.sku.localizedCaseInsensitiveContains(searchText)
            let matchesStock = !showOnlyLowStock || product.isLowStock
            return matchesSearch && matchesStock
        }
    }
    
    var lowStockCount: Int {
        products.filter { $0.isLowStock }.count
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                HStack(spacing: 12) {
                    StatCard(
                        title: "إجمالي الأصناف",
                        value: "\(products.count)",
                        color: .blue
                    )
                    StatCard(
                        title: "نواقص المخزون",
                        value: "\(lowStockCount)",
                        color: lowStockCount > 0 ? .red : .green
                    )
                }
                .padding()
                
                Toggle("عرض الأصناف المنخفضة فقط", isOn: $showOnlyLowStock)
                    .padding(.horizontal)
                    .padding(.bottom, 8)
                
                if filteredProducts.isEmpty {
                    ContentUnavailableView(
                        "لا توجد منتجات",
                        systemImage: "shippingbox",
                        description: Text("اضغط على زر (+) في الأعلى لإضافة منتجات للمخزون.")
                    )
                } else {
                    List {
                        ForEach(filteredProducts) { product in
                            Button {
                                productToEdit = product
                            } label: {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(product.name)
                                            .font(.headline)
                                            .foregroundStyle(.primary)
                                        
                                        Text("سعر البيع: \(product.unitPrice, specifier: "%.2f") | التكلفة: \(product.costPrice, specifier: "%.2f")")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    
                                    Spacer()
                                    
                                    VStack(alignment: .trailing, spacing: 4) {
                                        Text("الكمية: \(product.stockQuantity)")
                                            .font(.subheadline.bold())
                                            .foregroundStyle(product.isLowStock ? .red : .primary)
                                        
                                        if product.stockQuantity == 0 {
                                            Text("نفد المخزون")
                                                .font(.caption2.bold())
                                                .padding(.horizontal, 6)
                                                .padding(.vertical, 2)
                                                .background(Color.red.opacity(0.15))
                                                .foregroundStyle(.red)
                                                .clipShape(Capsule())
                                        } else if product.isLowStock {
                                            Text("مخزون منخفض")
                                                .font(.caption2.bold())
                                                .padding(.horizontal, 6)
                                                .padding(.vertical, 2)
                                                .background(Color.orange.opacity(0.15))
                                                .foregroundStyle(.orange)
                                                .clipShape(Capsule())
                                        }
                                    }
                                }
                            }
                        }
                        .onDelete(perform: deleteProducts)
                    }
                }
            }
            .navigationTitle("مراقبة المخزون")
            .searchable(text: $searchText, prompt: "ابحث باسم المنتج أو الرمز...")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        showingAddSheet = true
                    } label: {
                        Label("إضافة منتج", systemImage: "plus.circle.fill")
                    }
                }
            }
            .sheet(isPresented: $showingAddSheet) {
                ProductFormSheet(product: nil)
            }
            .sheet(item: $productToEdit) { product in
                ProductFormSheet(product: product)
            }
        }
    }
    
    private func deleteProducts(offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(filteredProducts[index])
        }
    }
}

struct ProductFormSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    let product: Product?
    
    @State private var name = ""
    @State private var sku = ""
    @State private var costPrice = ""
    @State private var unitPrice = ""
    @State private var stockQuantity = ""
    @State private var minStockAlert = "5"
    
    var body: some View {
        NavigationStack {
            Form {
                Section("بيانات المنتج") {
                    TextField("اسم المنتج", text: $name)
                    TextField("رمز الصنف (SKU) - اختياري", text: $sku)
                }
                
                Section("التسعير") {
                    TextField("سعر التكلفة", text: $costPrice)
                        .keyboardType(.decimalPad)
                    TextField("سعر البيع", text: $unitPrice)
                        .keyboardType(.decimalPad)
                }
                
                Section("المخزون والتنبيهات") {
                    TextField("الكمية المتوفرة حالياً", text: $stockQuantity)
                        .keyboardType(.numberPad)
                    TextField("حد التنبيه بنقص المخزون", text: $minStockAlert)
                        .keyboardType(.numberPad)
                }
            }
            .navigationTitle(product == nil ? "إضافة منتج جديد" : "تعديل المنتج")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("إلغاء") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("حفظ") {
                        saveProduct()
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty || Double(unitPrice) == nil)
                }
            }
            .onAppear {
                if let product {
                    name = product.name
                    sku = product.sku
                    costPrice = String(product.costPrice)
                    unitPrice = String(product.unitPrice)
                    stockQuantity = String(product.stockQuantity)
                    minStockAlert = String(product.minStockAlert)
                }
            }
        }
        .environment(\.layoutDirection, .rightToLeft)
    }
    
    private func saveProduct() {
        let cost = Double(costPrice) ?? 0.0
        let price = Double(unitPrice) ?? 0.0
        let stock = Int(stockQuantity) ?? 0
        let alertLimit = Int(minStockAlert) ?? 5
        
        if let product {
            product.name = name
            product.sku = sku
            product.costPrice = cost
            product.unitPrice = price
            product.stockQuantity = stock
            product.minStockAlert = alertLimit
        } else {
            let newProduct = Product(
                name: name,
                sku: sku,
                costPrice: cost,
                unitPrice: price,
                stockQuantity: stock,
                minStockAlert: alertLimit
            )
            modelContext.insert(newProduct)
        }
    }
}
