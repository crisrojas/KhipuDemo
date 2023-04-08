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
    let core: Input
    
    var body: some View {
        let client: TodoListClient = (
            add: add(_:),
            delete: delete(_:),
            update: change(t:c:),
            replay: replay,
            edit: edit(_:)
        )
        
        TodoList(
            todos: state.todos,
            recordedSteps: timelineRecorder.totalSteps,
            recordedLength: timelineRecorder.totalLength,
            replayEnabled: state.replayEnabled,
            client: client
        )
    }
    
    func add(_ todo: ToDo) {core(.cmd(.add(todo)))}
    func delete(_ todo: ToDo) {core(.cmd(.delete(todo)))}
    func change(t: ToDo, c: ToDo.Change) {core(.cmd(.change(t, with: c)))}
    func replay() {core(.replay)}
    func edit(_ editing: Bool) {core(.edit(editing))}
}

