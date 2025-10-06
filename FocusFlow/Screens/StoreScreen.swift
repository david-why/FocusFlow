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
    var image: String? = nil
    var special: StoreItemSpecial = .none
    var single = false
    
    enum StoreItemSpecial {
        case none
        case appIcon(name: String)
    }
}

let storeItems = [
    StoreItem(id: "break-1", name: "1-minute Break Pass", description: "Use this pass to take a 1 minute break on your phone in a focus session! Automatically applied when you leave the app.", price: 30),
    StoreItem(id: "break-5", name: "5-minute Break Pass", description: "Use this pass to take a 5 minute break on your phone in a focus session! Automatically applied when you leave the app.", price: 200),
    StoreItem(id: "icon-rainbow", name: "Rainbow App Icon", description: "Unlock the Rainbow app icon, joyful and diverse like a burst of color!", price: 60, image: "icon_rainbow", special: .appIcon(name: "AppIconRainbow"), single: true),
    StoreItem(id: "icon-coral", name: "Coral App Icon", description: "Unlock the Coral app icon, vibrant and warm like an ocean sunset!", price: 60, image: "icon_coral", special: .appIcon(name: "AppIconCoral"), single: true),
    StoreItem(id: "icon-frost", name: "Frost App Icon", description: "Unlock the Frost app icon, cool and crisp like a winter morning!", price: 60, image: "icon_frost", special: .appIcon(name: "AppIconFrost"), single: true),
    StoreItem(id: "icon-violet", name: "Violet App Icon", description: "Unlock the Violet app icon, mysterious and regal like a twilight sky!", price: 60, image: "icon_violet", special: .appIcon(name: "AppIconViolet"), single: true),
    StoreItem(id: "icon-emerald", name: "Emerald App Icon", description: "Unlock the Emerald app icon, fresh and lively like a lush forest!", price: 60, image: "icon_emerald", special: .appIcon(name: "AppIconEmerald"), single: true)
]

struct StoreScreen: View {
    @AppStorage("coins") var coins: Int = 0
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    Text("You have: \(coinText) \(coins)")
                    Button("Reset app icon") {
                        UIApplication.shared.setAlternateIconName(nil)
                    }
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
