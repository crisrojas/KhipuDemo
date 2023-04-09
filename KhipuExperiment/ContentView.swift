//
//  ContentView.swift
//  KhipuExperiment
//
//  Created by Cristian Felipe Patiño Rojas on 07/04/2023.
//

import SwiftUI
import Models
import UI
import Khipu


struct ContentView: View {
    @State private var isReplayStartAlertVisible = false
    @StateObject var state: ViewState
    @StateObject fileprivate var stateHolder = replayFinishedStateHolder
    let core: Input
    
    var body: some View {
        TodoList(
            todos: state.todos,
            client: todoClient
        )
        #if DEBUG
        .overlay(replayButton, alignment: .topLeading)
        #endif
        .alert(
            "Do you want to replay \(timelineRecorder.totalSteps) states (duration: \(Int(timelineRecorder.totalLength))s)?",
            isPresented: $isReplayStartAlertVisible,
            actions: {
                Button("Cancel") {}
                Button("Replay") {
                    stateHolder.isReplayButtonDisabled = true
                    timelineRecorder.replay {
                        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1)) {
                            stateHolder.isReplayButtonDisabled = false
                            stateHolder.isFinished = true
                        }
                    }
                }
            }
        )
        .alert("Timeline has finished!", isPresented: $stateHolder.isFinished, actions: {
            Button("OK") {}
        })
    }
}

// MARK: - ToDo list actions
extension ContentView {
    func add(_ todo: ToDo) {core(.cmd(.add(todo)))}
    func delete(_ todo: ToDo) {core(.cmd(.delete(todo)))}
    func change(t: ToDo, c: ToDo.Change) {core(.cmd(.change(t, with: c)))}
    func edit(_ editing: Bool) {core(.edit(editing))}
    
    var todoClient: TodoListClient {(
        add: add(_:),
        delete: delete(_:),
        update: change(t:c:),
        edit: edit(_:)
    )}
}

#if DEBUG
extension ContentView {
    var replayButton: some View {
        Button(
            action: { isReplayStartAlertVisible = true },
            label: {
                Image(systemName: "clock.arrow.circlepath")
                    .foregroundColor(stateHolder.isReplayButtonDisabled ? .secondary : .blue)
            }
        )
        .disabled(stateHolder.isReplayButtonDisabled)
        .padding(2)
        .background(Color.blue.opacity(0.2).cornerRadius(6))
        .padding(16)
    }
}
#endif

// We need to store state somewhere, because it will be discarded during timeline replay.
fileprivate final class ReplayFinishedStateHolder: ObservableObject {
    @Published var isFinished = false
    @Published var isReplayButtonDisabled = false
}
fileprivate let replayFinishedStateHolder = ReplayFinishedStateHolder()


