//
//  StoreService.swift
//  FocusFlow
//
//  Created by David Wang on 2025/10/4.
//

import Foundation

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

@Observable
class StoreService {
    private(set) var ownedItems: [OwnedItem] = []
    
    private var observation: NSKeyValueObservation? = nil
    
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
