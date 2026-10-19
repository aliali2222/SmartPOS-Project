import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            NewSaleView()
                .tabItem {
                    Label("نقطة البيع", systemImage: "cart.fill.badge.plus")
                }
            
            InventoryView()
                .tabItem {
                    Label("المخزون", systemImage: "shippingbox.fill")
                }
            
            SalesHistoryView()
                .tabItem {
                    Label("المبيعات والتقارير", systemImage: "chart.bar.doc.horizontal.fill")
                }
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.title3.bold())
                .foregroundStyle(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(color.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
