import SwiftUI

struct InvoicePrintView: View {
    let sale: SaleTransaction
    var companyName: String = "مؤسسة المبيعات الذكية"
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(companyName)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(.black)
                    
                    Text("فاتورة مبيعات ضريبية مبسطة")
                        .font(.system(size: 14))
                        .foregroundStyle(.gray)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 6) {
                    Text("رقم الفاتورة: \(sale.invoiceNumber)")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.black)
                    
                    Text("التاريخ: \(sale.date.formatted(date: .numeric, time: .shortened))")
                        .font(.system(size: 13))
                        .foregroundStyle(.gray)
                    
                    if sale.isReturned {
                        Text("حالة الفاتورة: مسترجعة")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(.red)
                    }
                }
            }
            
            Divider()
                .background(.black)
            
            HStack {
                Text("الصنف")
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text("الكمية")
                    .frame(width: 70, alignment: .center)
                Text("سعر الوحدة")
                    .frame(width: 100, alignment: .center)
                Text("الإجمالي")
                    .frame(width: 100, alignment: .trailing)
            }
            .font(.system(size: 14, weight: .bold))
            .padding(.vertical, 8)
            .padding(.horizontal, 10)
            .background(Color.gray.opacity(0.15))
            .foregroundStyle(.black)
            
            VStack(spacing: 0) {
                ForEach(sale.items) { item in
                    HStack {
                        Text(item.productName)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Text("\(item.quantity)")
                            .frame(width: 70, alignment: .center)
                        Text(String(format: "%.2f", item.unitPrice))
                            .frame(width: 100, alignment: .center)
                        Text(String(format: "%.2f", item.subtotal))
                            .frame(width: 100, alignment: .trailing)
                    }
                    .font(.system(size: 13))
                    .foregroundStyle(.black)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 10)
                    
                    Divider()
                }
            }
            
            Spacer(minLength: 20)
            
            HStack {
                Spacer()
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("عدد الأصناف:")
                            .foregroundStyle(.gray)
                        Spacer()
                        Text("\(sale.items.count)")
                            .bold()
                    }
                    
                    Divider()
                    
                    HStack {
                        Text("الإجمالي النهائي:")
                            .font(.system(size: 16, weight: .bold))
                        Spacer()
                        Text(String(format: "%.2f", sale.totalAmount))
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(sale.isReturned ? .red : .black)
                    }
                }
                .frame(width: 240)
                .padding()
                .background(Color.gray.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .foregroundStyle(.black)
            
            Divider()
            
            Text("شكراً لتعاملكم معنا - تم إصدار هذه الفاتورة إلكترونياً")
                .font(.system(size: 12))
                .foregroundStyle(.gray)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, 8)
        }
        .padding(32)
        .frame(width: 595)
        .background(Color.white)
    }
}

@MainActor
struct InvoicePDFGenerator {
    static func generatePDF(for sale: SaleTransaction) -> URL? {
        let invoiceView = InvoicePrintView(sale: sale)
            .environment(\.layoutDirection, .rightToLeft)
            .environment(\.locale, Locale(identifier: "ar"))
            .environment(\.colorScheme, .light)
        
        let renderer = ImageRenderer(content: invoiceView)
        
        let tempURL = FileManager.default.temporaryDirectory
            .appending(path: "Invoice-\(sale.invoiceNumber).pdf")
        
        renderer.render { size, context in
            var box = CGRect(x: 0, y: 0, width: size.width, height: size.height)
            
            guard let pdfContext = CGContext(tempURL as CFURL, mediaBox: &box, nil) else {
                return
            }
            
            pdfContext.beginPDFPage(nil)
            context(pdfContext)
            pdfContext.endPDFPage()
            pdfContext.closePDF()
        }
        
        return tempURL
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

struct SharedPDFItem: Identifiable {
    let id = UUID()
    let url: URL
}
