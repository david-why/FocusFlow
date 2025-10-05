//
//  StoreScreen.swift
//  FocusFlow
//
//  Created by David Wang on 2025/10/4.
//

import SwiftUI

struct StoreItem: Identifiable {
    let id: String
    let name: LocalizedStringKey
    let description: LocalizedStringKey
    let price: Int
}

let storeItems = [
    StoreItem(id: "break-1", name: "1-minute Break Pass", description: "Use this pass to take a 1 minute break on your phone in a focus session! Automatically applied when you leave the app.", price: 30),
    StoreItem(id: "break-5", name: "5-minute Break Pass", description: "Use this pass to take a 5 minute break on your phone in a focus session! Automatically applied when you leave the app.", price: 200)
]

struct StoreScreen: View {
    @AppStorage("coins") var coins: Int = 0
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    Text("You have: \(coinText) \(coins)")
                }
                
                ForEach(storeItems) { item in
                    Section {
                        Button {
                            itemTapped(for: item)
                        } label: {
                            StoreItemView(item: item)
                        }
                        if purchasingItemID == item.id {
                            PurchaseItemView(item: item)
                        }
                    }
                }
            }
            .navigationTitle("Store")
            .animation(.default, value: purchasingItemID)
        }
    }
    
    // MARK: - Purchase form
    
    @State var purchasingItemID: String? = nil
    
    func itemTapped(for item: StoreItem) {
        if purchasingItemID == item.id {
            purchasingItemID = nil
        } else {
            purchasingItemID = item.id
        }
    }
}

struct StoreItemView: View {
    let item: StoreItem
    
    @Environment(StoreService.self) var storeService
    
    var body: some View {
        VStack {
            Text(item.name)
                .font(.headline)
            Text("\(coinText) \(item.price)")
            Text(item.description)
            Text("Owned: \(storeService.count(of: item.id))")
                .foregroundStyle(.secondary)
        }
        .foregroundStyle(.foreground)
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity)
        .padding(.vertical)
    }
}

struct PurchaseItemView: View {
    let item: StoreItem
    
    @AppStorage("coins") var coinsHeld: Int = 0
    @Environment(StoreService.self) var storeService
    
    @State var quantity = 1
    
    var body: some View {
        Stepper(value: $quantity, in: 1...Int.max) {
            Text("Quantity: \(quantity)")
        }
        VStack(alignment: .leading) {
            Text("You need: \(coinText) \(coinsNeeded)")
            Text("You have: \(coinText) \(coinsHeld)")
            if !hasEnoughCoins {
                Text("Not enough coins!")
                    .foregroundStyle(.red)
            } else {
                Text("Coins remaining: \(coinText) \(coinsHeld - coinsNeeded)")
            }
        }
        Button("Purchase!") {
            performPurchase(quantity: quantity)
        }
        .disabled(!hasEnoughCoins)
    }
    
    var coinsNeeded: Int {
        quantity * item.price
    }
    
    var hasEnoughCoins: Bool {
        coinsNeeded <= coinsHeld
    }
    
    // MARK: - Actions
    
    func performPurchase(quantity: Int) {
        guard hasEnoughCoins else { return }
        for _ in 1...quantity {
            storeService.addOwnedItem(id: item.id, price: item.price)
        }
        coinsHeld -= item.price * quantity
    }
}

#Preview {
    StoreScreen()
        .environment(StoreService())
}
