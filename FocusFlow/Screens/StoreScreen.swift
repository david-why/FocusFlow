//
//  StoreScreen.swift
//  FocusFlow
//
//  Created by David Wang on 2025/10/4.
//

import SwiftUI

struct StoreScreen: View {
    @AppStorage("coins") var coins: Int = 0
    
    @Environment(StoreService.self) var storeService
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    Text("You have: \(coinText) \(coins)")
                    Button("Reset app icon") {
                        UIApplication.shared.setAlternateIconName(nil)
                    }
                }
                
                ForEach(storeService.storeItems) { item in
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
            if let image = item.image {
                Image(image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: 150)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .padding(.bottom, 8)
            }
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
        if !item.single {
            Stepper(value: $quantity, in: 1...Int.max) {
                Text("Quantity: \(quantity)")
            }
        }
        VStack(alignment: .leading) {
            Text("You need: \(coinText) \(coinsNeeded)")
            Text("You have: \(coinText) \(coinsHeld)")
            if !hasEnoughCoins {
                Text("Not enough coins!")
                    .foregroundStyle(.red)
            } else if hasReachedLimit {
                Text("Reached purchase limit")
                    .foregroundStyle(.red)
            } else {
                Text("Coins remaining: \(coinText) \(coinsHeld - coinsNeeded)")
            }
        }
        Button("Purchase!") {
            performPurchase(quantity: quantity)
        }
        .disabled(!canPurchase)
        if case .appIcon = item.special {
            Button("Use this icon!", action: useAppIcon)
                .disabled(!hasReachedLimit)
        }
    }
    
    var coinsNeeded: Int {
        quantity * item.price
    }
    
    var hasEnoughCoins: Bool {
        coinsNeeded <= coinsHeld
    }
    
    var hasReachedLimit: Bool {
        item.single && storeService.count(of: item.id) != 0
    }
    
    var canPurchase: Bool {
        hasEnoughCoins && !hasReachedLimit
    }
    
    // MARK: - Actions
    
    func performPurchase(quantity: Int) {
        guard hasEnoughCoins else { return }
        for _ in 1...quantity {
            storeService.addOwnedItem(id: item.id, price: item.price)
        }
        coinsHeld -= item.price * quantity
    }
    
    func useAppIcon() {
        guard case let .appIcon(name) = item.special else { return }
        UIApplication.shared.setAlternateIconName(name)
    }
}

#Preview {
    StoreScreen()
        .environment(StoreService())
        .onAppear {
            UserDefaults.standard.set(5000, forKey: "coins")
        }
}
