import SwiftUI

struct CartView: View {
    let products: [Product]
    @Binding var cart: Cart
    let onChange: (Cart) async -> Void
    let onClear: () async -> Void

    var body: some View {
        NavigationStack {
            Group {
                if cart.lines.isEmpty { ContentUnavailableView("Your cart is empty", systemImage: "cart", description: Text("Add products to continue.")) }
                else { List { ForEach(cart.lines) { line in
                    let product = products.first(where: { $0.id == line.productId })
                    HStack { VStack(alignment: .leading) { Text(product?.name ?? "Product").font(.headline); Text("\(line.quantity) × \(product?.currency ?? "") \(Double(product?.priceMinor ?? 0) / 100, specifier: "%.2f")").foregroundStyle(.secondary) }; Spacer(); Stepper("\(line.quantity)", value: Binding(get: { line.quantity }, set: { value in Task { var next = cart; if let index = next.lines.firstIndex(where: { $0.id == line.id }) { next.lines[index].quantity = value }; next.lines.removeAll { $0.quantity < 1 }; cart = next; await onChange(next) } }), in: 1...99).labelsHidden() }
                } } }
            }
            .navigationTitle("Cart")
            .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Clear", role: .destructive) { Task { await onClear() } }.disabled(cart.lines.isEmpty) } }
        }
    }
}
