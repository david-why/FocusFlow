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
    @Query var items: [BuildingItem]
    
    var body: some View {
        NavigationStack {
            List {
                BuildCanvas()
                
                Section {
                    Button("Fall") {
                        Task {
                            await fallAndClear()
                        }
                    }
                }
            }
            .navigationTitle("Build")
        }
        .onChange(of: items) {
            debugPrint(items)
        }
    }
    
    func fallAndClear() async {
        withAnimation(.easeIn(duration: 1)) {
            for i in items.indices {
                items[i].offsetY = 500
            }
        }
        try? await Task.sleep(for: .seconds(1))
        items.forEach(modelContext.delete)
    }
}

struct BuildCanvas: View {
    @Query var items: [BuildingItem]
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            Color.white
                .frame(height: 400)
            ForEach(items) { item in
                BuildItemView(item: item)
            }
        }
    }
}

struct BuildItemView: View {
    @Bindable var item: BuildingItem
    
    @State private var dragStartOffset: CGSize? = nil
    
    var body: some View {
        item.view
            .offset(x: item.offsetX, y: item.offsetY)
            .onTapGesture {
                print(item.hashValue)
            }
            .gesture(drag)
    }
    
    var drag: some Gesture {
        DragGesture()
            .onChanged { value in
                if let dragStartOffset {
                    item.offsetX = dragStartOffset.width + value.translation.width
                    item.offsetY = dragStartOffset.height + value.translation.height
                } else {
                    dragStartOffset = CGSize(width: item.offsetX, height: item.offsetY)
                }
            }
            .onEnded { _ in
                dragStartOffset = nil
            }
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
    let context = container.mainContext
    
    TabView {
        Tab("Build", systemImage: "wrench.and.screwdriver") {
            BuildScreen()
        }
        Tab("Home", systemImage: "house") {}
    }
    .modelContainer(container)
    .onAppear {
        context.insert(BuildingItem(content: .image(name: "coin"), offsetX: 0, offsetY: 0, zIndex: 1))
        context.insert(BuildingItem(content: .image(name: "coin"), offsetX: 0, offsetY: 0, zIndex: 1))
    }
}
