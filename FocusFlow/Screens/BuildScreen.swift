//
//  BuildScreen.swift
//  FocusFlow
//
//  Created by David Wang on 2025/10/23.
//

import SwiftUI
import SwiftData

struct BuildScreen: View {
    @Environment(\.modelContext) var modelContext
    @State var state: BuildState!
    
    init() {
        state = BuildState(modelContext: modelContext)
    }
    
    var body: some View {
        NavigationStack {
            List {
                BuildCanvas(state: state)
                
                Section {
                    Button("Fall") {
                        Task {
                            await state.fallAndClear()
                        }
                    }
                }
            }
            .navigationTitle("Build")
        }
        .onChange(of: state.items) {
            print(state.items)
        }
        .onAppear {
            if state.items.isEmpty {
                state.addItem(BuildingItem(content: .image(name: "coin"), offsetX: 2, offsetY: 0, zIndex: 1))
            }
        }
    }
}

struct BuildCanvas: View {
    @Bindable var state: BuildState
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            Color.white
                .frame(height: 400)
            ForEach(state.items) { item in
                item.view
                    .offset(x: item.offsetX, y: item.offsetY)
            }
        }
    }
}

@Observable
class BuildState {
    private var modelContext: ModelContext
    private(set) var items: [BuildingItem] = []
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        fetchItems()
    }
    
    private func fetchItems() {
        let descriptor = FetchDescriptor<BuildingItem>()
        guard let models = try? modelContext.fetch(descriptor) else { return }
        Task { @MainActor in
            self.items = models
        }
    }
    
    func addItem(_ item: BuildingItem) {
        modelContext.insert(item)
        items.append(item)
    }
    
    func fallAndClear() async {
        withAnimation(.easeIn(duration: 1)) {
            for i in items.indices {
                items[i].offsetY = 500
            }
        }
        try? await Task.sleep(for: .seconds(1))
        items.removeAll()
        try? modelContext.delete(model: BuildingItem.self)
    }
}

extension BuildingItem {
    var view: some View {
        switch content {
//        case .color(let color, let size): color.frame(width: size.width, height: size.height)
        case .image(let name): Image(name)
        }
    }
}

enum BuildItemContent: Equatable {
    case color(Color, frame: CGSize)
    case image(name: String)
}

#Preview {
    let container = try! ModelContainer(for: BuildingItem.self, configurations: .init(isStoredInMemoryOnly: true))
    let state = BuildState(modelContext: container.mainContext)
    
    TabView {
        Tab("Build", systemImage: "wrench.and.screwdriver") {
            BuildScreen()
        }
        Tab("Home", systemImage: "house") {}
    }
    .modelContainer(container)
//    .onAppear {
//        print("onappear")
//        state.addItem(BuildingItem(content: .image(name: "coin"), offsetX: 2, offsetY: 0, zIndex: 1))
//        state.addItem(BuildingItem(content: .image(name: "coin"), offsetX: 100, offsetY: 100, zIndex: 1))
//    }
}
