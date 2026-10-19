import SwiftUI
import SwiftData

struct CartItem: Identifiable {
    let id = UUID()
    let product: Product
    var quantity: Int
    
    var subtotal: Double {
        Double(quantity) * product.unitPrice
    }
    
    var profit: Double {
        Double(quantity) * (product.unitPrice - product.costPrice)
    }
}

struct NewSaleView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Product.name) private var products: [Product]
    
    @State private var cart: [CartItem] = []
    @State private var showingSuccessAlert = false
    @State private var lastInvoiceNumber = ""
    
    var availableProducts: [Product] {
        products.filter { $0.stockQuantity > 0 }
    }
    
    var cartTotal: Double {
        cart.reduce(0) { $0 + $1.subtotal }
    }
    
    var cartProfit: Double {
        cart.reduce(0) { $0 + $1.profit }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                List {
                    Section("الأصناف المتوفرة في المخزون") {
                        if availableProducts.isEmpty {
                            Text("لا توجد منتجات متوفرة للبيع حالياً. أضف منتجات من تبويب المخزون.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        } else {
                            ForEach(availableProducts) { product in
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text(product.name)
                                            .font(.headline)
                                        Text("السعر: \(product.unitPrice, specifier: "%.2f") | المتاح: \(product.stockQuantity)")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    Button {
                                        addToCart(product)
                                    } label: {
                                        Image(systemName: "plus.circle.fill")
                                            .font(.title2)
                                            .foregroundStyle(.blue)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }
                    
                    Section("الفاتورة الحالية (\(cart.count) أصناف)") {
                        if cart.isEmpty {
                            Text("لم يتم اختيار أي صنف بعد")
                                .foregroundStyle(.secondary)
                        } else {
                            ForEach($cart) { $item in
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text(item.product.name)
                                            .font(.subheadline.bold())
                                        Text("الإجمالي: \(item.subtotal, specifier: "%.2f")")
                                            .font(.caption)
                                            .foregroundStyle(.blue)
                                    }
                                    
                                    Spacer()
                                    
                                    Stepper(
                                        "الكمية: \(item.quantity)",
                                        value: $item.quantity,
                                        in: 1...item.product.stockQuantity
                                    )
                                    .fixedSize()
                                }
                            }
                            .onDelete { offsets in
                                cart.remove(atOffsets: offsets)
                            }
                        }
                    }
                }
                
                VStack(spacing: 12) {
                    HStack {
                        Text("إجمالي الفاتورة:")
                            .font(.headline)
                        Spacer()
                        Text("\(cartTotal, specifier: "%.2f")")
                            .font(.title2.bold())
                            .foregroundStyle(.green)
                    }
                    
                    Button {
                        completeSale()
                    } label: {
                        Text("تأكيد وإصدار الفاتورة")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(cart.isEmpty ? Color.gray : Color.blue)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .disabled(cart.isEmpty)
                }
                .padding()
                .background(.ultraThinMaterial)
            }
            .navigationTitle("عملية بيع جديدة")
            .toolbar {
                if !cart.isEmpty {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("إفراغ السلة", role: .destructive) {
                            cart.removeAll()
                        }
                    }
                }
            }
            .alert("تم حفظ الفاتورة بنجاح", isPresented: $showingSuccessAlert) {
                Button("حسناً", role: .cancel) { }
            } message: {
                Text("رقم الفاتورة: \(lastInvoiceNumber)\nتم خصم الكميات من المخزون تلقائياً.")
            }
        }
    }
    
    private func addToCart(_ product: Product) {
        if let index = cart.firstIndex(where: { $0.product.id == product.id }) {
            if cart[index].quantity < product.stockQuantity {
                cart[index].quantity += 1
            }
        } else {
            cart.append(CartItem(product: product, quantity: 1))
        }
    }
    
    private func completeSale() {
        let invoiceNum = "INV-\(Int.random(in: 10000...99999))"
        var saleItems: [SaleItem] = []
        
        for cartItem in cart {
            cartItem.product.stockQuantity -= cartItem.quantity
            
            let saleItem = SaleItem(
                productID: cartItem.product.id,
                productName: cartItem.product.name,
                quantity: cartItem.quantity,
                unitPrice: cartItem.product.unitPrice,
                costPrice: cartItem.product.costPrice
            )
            saleItems.append(saleItem)
        }
        
        let transaction = SaleTransaction(
            invoiceNumber: invoiceNum,
            date: Date(),
            totalAmount: cartTotal,
            totalProfit: cartProfit,
            isReturned: false,
            items: saleItems
        )
        
        modelContext.insert(transaction)
        
        lastInvoiceNumber = invoiceNum
        cart.removeAll()
        showingSuccessAlert = true
    }
}
