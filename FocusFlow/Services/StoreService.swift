//
//  StoreService.swift
//  FocusFlow
//
//  Created by David Wang on 2025/10/4.
//

import Foundation
import SwiftUI

struct OwnedItem: Identifiable, Codable {
    var id = UUID()
    let itemID: String
    let purchaseTime: Date
    let purchasePrice: Int
}

extension UserDefaults {
    @objc dynamic var ownedItemsData: Data? {
        data(forKey: "owned_items")
    }
}

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

@Observable
class StoreService {
    private(set) var ownedItems: [OwnedItem] = []
    
    private var observation: NSKeyValueObservation? = nil
    
    let storeItems = [
        StoreItem(id: "build-item", name: "Build!", description: "Let you add an object to the Build tab. Build your own house, shop, city, anything you want!", price: 30),
        StoreItem(id: "break-1", name: "1-minute Break Pass", description: "Use this pass to take a 1 minute break on your phone in a focus session! Automatically applied when you leave the app.", price: 30),
        StoreItem(id: "break-5", name: "5-minute Break Pass", description: "Use this pass to take a 5 minute break on your phone in a focus session! Automatically applied when you leave the app.", price: 200),
        StoreItem(id: "icon-rainbow", name: "Rainbow App Icon", description: "Unlock the Rainbow app icon, joyful and diverse like a burst of color!", price: 60, image: "icon_rainbow", special: .appIcon(name: "AppIconRainbow"), single: true),
        StoreItem(id: "icon-coral", name: "Coral App Icon", description: "Unlock the Coral app icon, vibrant and warm like an ocean sunset!", price: 60, image: "icon_coral", special: .appIcon(name: "AppIconCoral"), single: true),
        StoreItem(id: "icon-frost", name: "Frost App Icon", description: "Unlock the Frost app icon, cool and crisp like a winter morning!", price: 60, image: "icon_frost", special: .appIcon(name: "AppIconFrost"), single: true),
        StoreItem(id: "icon-violet", name: "Violet App Icon", description: "Unlock the Violet app icon, mysterious and regal like a twilight sky!", price: 60, image: "icon_violet", special: .appIcon(name: "AppIconViolet"), single: true),
        StoreItem(id: "icon-emerald", name: "Emerald App Icon", description: "Unlock the Emerald app icon, fresh and lively like a lush forest!", price: 60, image: "icon_emerald", special: .appIcon(name: "AppIconEmerald"), single: true)
    ]
    
    init() {
        loadOwnedItems()
        observation = UserDefaults.standard.observe(\.ownedItemsData) { _, _ in
            print("UserDefaults updated")
            Task { @MainActor in
                self.loadOwnedItems()
            }
        }
    }
    
    deinit {
        observation?.invalidate()
    }
    
    func addOwnedItem(id: String, price: Int) {
        let ownedItem = OwnedItem(itemID: id, purchaseTime: .now, purchasePrice: price)
        ownedItems.append(ownedItem)
        saveOwnedItems()
    }
    
    func count(of itemID: String) -> Int {
        ownedItems.count { $0.itemID == itemID }
    }
    
    func items(of itemID: String) -> [OwnedItem] {
        ownedItems.filter { $0.itemID == itemID }
    }
    
    func delete(_ item: OwnedItem) {
        ownedItems.removeAll { $0.id == item.id }
        saveOwnedItems()
    }
    
    @MainActor private func loadOwnedItems() {
        guard let data = UserDefaults.standard.ownedItemsData,
              let itemList = try? JSONDecoder().decode([OwnedItem].self, from: data) else {
            ownedItems = []
            return
        }
        ownedItems = itemList
    }
    
    private func saveOwnedItems() {
        guard let data = try? JSONEncoder().encode(ownedItems) else {
            return
        }
        UserDefaults.standard.set(data, forKey: "owned_items")
    }
}
