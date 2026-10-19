import Foundation
import SwiftData

// MARK: - 1. نموذج المنتج (مراقبة المخزون)
@Model
final class Product {
    var id: UUID
    var name: String
    var sku: String
    var costPrice: Double
    var unitPrice: Double
    var stockQuantity: Int
    var minStockAlert: Int
    
    init(
        name: String,
        sku: String = "",
        costPrice: Double,
        unitPrice: Double,
        stockQuantity: Int,
        minStockAlert: Int = 5
    ) {
        self.id = UUID()
        self.name = name
        self.sku = sku
        self.costPrice = costPrice
        self.unitPrice = unitPrice
        self.stockQuantity = stockQuantity
        self.minStockAlert = minStockAlert
    }
    
    var isLowStock: Bool {
        stockQuantity <= minStockAlert
    }
}

// MARK: - 2. نموذج فاتورة المبيعات
@Model
final class SaleTransaction {
    var id: UUID
    var invoiceNumber: String
    var date: Date
    var totalAmount: Double
    var totalProfit: Double
    var isReturned: Bool
    
    @Relationship(deleteRule: .cascade)
    var items: [SaleItem] = []
    
    init(
        invoiceNumber: String,
        date: Date = Date(),
        totalAmount: Double,
        totalProfit: Double,
        isReturned: Bool = false,
        items: [SaleItem] = []
    ) {
        self.id = UUID()
        self.invoiceNumber = invoiceNumber
        self.date = date
        self.totalAmount = totalAmount
        self.totalProfit = totalProfit
        self.isReturned = isReturned
        self.items = items
    }
}

// MARK: - 3. نموذج العناصر المباعة داخل الفاتورة
@Model
final class SaleItem {
    var id: UUID
    var productID: UUID
    var productName: String
    var quantity: Int
    var unitPrice: Double
    var costPrice: Double
    
    init(
        productID: UUID,
        productName: String,
        quantity: Int,
        unitPrice: Double,
        costPrice: Double
    ) {
        self.id = UUID()
        self.productID = productID
        self.productName = productName
        self.quantity = quantity
        self.unitPrice = unitPrice
        self.costPrice = costPrice
    }
    
    var subtotal: Double {
        Double(quantity) * unitPrice
    }
}
