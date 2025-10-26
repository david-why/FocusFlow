//
//  BuildScreen.swift
//  FocusFlow
//
//  Created by David Wang on 2025/10/23.
//

import SwiftUI
import SwiftData
import PhotosUI

struct BuildScreen: View {
    @Environment(\.modelContext) var modelContext
    @Environment(StoreService.self) var storeService
    
    @AppStorage("hasFailedBuild") var hasFailedBuild = false
    
    @Query var items: [BuildingItem]
    
    @State var isPresentingFailedAlert = false
    @State var isPresentingClearAlert = false
    
    var body: some View {
        NavigationStack {
            List {
                BuildCanvas()
                
                Section {
                    Text("Objects: \(items.count) of \(totalObjects) total")
                    Menu {
                        Button("🟥 Rectangle", action: addRectangleAction)
                        Button("🔺 Triangle", action: addTriangleAction)
                        Button("🔴 Ellipse / Circle", action: addEllipseAction)
                    } label: {
                        HStack {
                            Text("Add something...")
                            Spacer()
                        }
                    }
                    .disabled(items.count >= totalObjects)
                    Button("Delete all items", role: .destructive, action: clearItems)
                        .disabled(items.isEmpty)
                }
            }
            .navigationTitle("Build")
        }
        .onAppear(perform: checkHasFailed)
        .alert("You have failed...", isPresented: $isPresentingFailedAlert) {
            Button("It won't happen again!") {}
        } message: {
            Text("You failed a focus session, and everything you've built fell to ashes... Better luck next time :(")
        }
        .alert("Delete everything?", isPresented: $isPresentingClearAlert) {
            Button("Delete", role: .destructive, action: confirmClearItems)
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure? This cannot be undone.")
        }
    }
    
    var totalObjects: Int {
        storeService.count(of: "build-item")
    }
    
    func checkHasFailed() {
        guard !items.isEmpty else { return }
        if hasFailedBuild {
            Task {
                isPresentingFailedAlert = true
                await fallAndClear()
                hasFailedBuild = false
            }
        }
    }
    
    func addRectangleAction() {
        print("adding rectangle")
        modelContext.insert(BuildingItem(content: .rect(color: .random), offsetX: 100, offsetY: 100, zIndex: 0, width: 100, height: 100, rotation: 0))
    }
    
    func addTriangleAction() {
        modelContext.insert(BuildingItem(content: .triangle(color: .random), offsetX: 100, offsetY: 100, zIndex: 0, width: 100, height: 100, rotation: 0))
    }
    
    func addEllipseAction() {
        modelContext.insert(BuildingItem(content: .ellipse(color: .random), offsetX: 100, offsetY: 100, zIndex: 0, width: 100, height: 100, rotation: 0))
    }
    
    func clearItems() {
        isPresentingClearAlert = true
    }
    
    func confirmClearItems() {
        items.forEach(modelContext.delete)
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
            Color.clear
            ForEach(items) { item in
                BuildItemView(item: item)
            }
        }
        .frame(height: 400)
    }
}

struct BuildItemView: View {
    @Bindable var item: BuildingItem
    
    @Environment(\.modelContext) private var modelContext
    
    @State private var isPopoverOpen = false
    @State private var dragStartOffset: CGSize? = nil
    @State private var isResizing = false
    @State private var resizeStartSize: CGSize? = nil
    @State private var rotateStartAngle: Double? = nil
    
    var body: some View {
        item.view
            .popover(isPresented: $isPopoverOpen, attachmentAnchor: .rect(.bounds)) {
                popoverView
                    .presentationCompactAdaptation(.popover)
                    .padding()
            }
            .overlay(alignment: .bottomTrailing) {
                if isResizing {
                    resizeHandle
                }
            }
            .position(x: item.offsetX, y: item.offsetY)
            .zIndex(item.zIndex)
            .onTapGesture(perform: openMenu)
            .gesture(drag)
            .gesture(rotate)
    }
    
    @ViewBuilder var popoverView: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Button("Delete", role: .destructive) {
                    deleteItem()
                }
                .buttonStyle(.bordered)
                Button("Resize") {
                    resizeItem()
                }
                .buttonStyle(.bordered)
            }
            if hasColor {
                ColorPicker("Color", selection: colorBinding)
            }
            LabeledContent {
                Slider(value: $item.zIndex, in: 0...100)
                    .labelsHidden()
            } label: {
                Text("Layer")
            }
        }
        .frame(width: 300)
    }
    
    @ViewBuilder var resizeHandle: some View {
        GeometryReader { proxy in
            Circle()
                .fill(.blue)
                .frame(width: 8, height: 8)
                .position(x: item.width, y: item.height)
                .gesture(resize)
        }
    }
    
    var drag: some Gesture {
        DragGesture()
            .onChanged { value in
                if let dragStartOffset {
                    item.offsetX = dragStartOffset.width + value.location.x - value.startLocation.x
                    item.offsetY = dragStartOffset.height + value.translation.height
                } else {
                    dragStartOffset = CGSize(width: item.offsetX, height: item.offsetY)
                }
            }
            .onEnded { value in
                if let dragStartOffset {
                    item.offsetX = dragStartOffset.width + value.location.x - value.startLocation.x
                    item.offsetY = dragStartOffset.height + value.translation.height
                }
                dragStartOffset = nil
            }
    }
    
    var rotate: some Gesture {
        RotateGesture()
            .onChanged { value in
                if let rotateStartAngle {
                    item.rotation = rotateStartAngle + value.rotation.degrees
                } else {
                    rotateStartAngle = item.rotation
                }
            }
            .onEnded { value in
                if let rotateStartAngle {
                    item.rotation = rotateStartAngle + value.rotation.degrees
                }
                rotateStartAngle = nil
            }
    }
    
    var resize: some Gesture {
        DragGesture()
            .onChanged { value in
                if let resizeStartSize {
                    item.width = max(1, resizeStartSize.width + value.translation.width)
                    item.height = max(1, resizeStartSize.height + value.translation.height)
                } else {
                    resizeStartSize = CGSize(width: item.width, height: item.height)
                }
            }
            .onEnded { value in
                if let resizeStartSize {
                    item.width = max(1, resizeStartSize.width + value.translation.width)
                    item.height = max(1, resizeStartSize.height + value.translation.height)
                }
                resizeStartSize = nil
                isResizing = false
            }
    }
    
    var hasColor: Bool {
        switch item.content {
        case .rect: true
        case .triangle: true
        case .ellipse: true
        default: false
        }
    }
    
    var colorBinding: Binding<Color> {
        Binding {
            switch item.content {
            case .rect(let color):
                color.color
            case .triangle(let color):
                color.color
            case .ellipse(let color):
                color.color
            default:
                Color.clear
            }
        } set: { color in
            switch item.content {
            case .rect:
                item.content = .rect(color: .init(color))
            case .triangle:
                item.content = .triangle(color: .init(color))
            case .ellipse:
                item.content = .ellipse(color: .init(color))
            default:
                break
            }
        }
    }
    
    func openMenu() {
        isPopoverOpen.toggle()
    }
    
    func deleteItem() {
        print("Deleting item \(item)")
        modelContext.delete(item)
    }
    
    func resizeItem() {
        isResizing.toggle()
        isPopoverOpen = false
    }
}

extension BuildingItem {
    @ViewBuilder var view: some View {
        switch content {
        case .image(let name):
            Image(name)
                .frame(width: width, height: height)
                .rotationEffect(.degrees(rotation))
        case .rect(let color):
            Rectangle()
                .frame(width: width, height: height)
                .rotationEffect(.degrees(rotation))
                .foregroundStyle(color.color)
        case .triangle(let color):
            Triangle()
                .frame(width: width, height: height)
                .rotationEffect(.degrees(rotation))
                .foregroundStyle(color.color)
        case .ellipse(let color):
            Ellipse()
                .frame(width: width, height: height)
                .rotationEffect(.degrees(rotation))
                .foregroundStyle(color.color)
        }
    }
}

#Preview {
    let container = try! ModelContainer(for: BuildingItem.self, configurations: .init(isStoredInMemoryOnly: true))

    TabView {
        Tab("Build", systemImage: "wrench.and.screwdriver") {
            BuildScreen()
        }
        Tab("Home", systemImage: "house") {}
    }
    .modelContainer(container)
    .environment(StoreService())
}
