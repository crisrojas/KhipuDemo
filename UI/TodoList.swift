//
//  TodoList.swift
//  UI
//
//  Created by Cristian Felipe Patiño Rojas on 07/04/2023.
//

import SwiftUI
import Models

public typealias TodoListClient = (
    add: (ToDo) -> (),
    delete: (ToDo) -> (),
    update: (ToDo, ToDo.Change) -> (),
    replay: () -> (),
    edit: (Bool) -> ()
)

extension ToDo {
    var fullTitle: String {
        title.isEmpty
        ? "New item"
        : title
    }
}

public struct TodoList: View {
    
    @State private var isReplayStartAlertVisible = false
 
    let todos: [ToDo]
    let recordedSteps: Int
    let recoredLenght: TimeInterval
    let replayEnabled: Bool
    let client: TodoListClient?
    
    public init(todos: [ToDo], recordedSteps: Int, recordedLength: TimeInterval, replayEnabled: Bool, client: TodoListClient? = nil) {
        self.todos = todos
        self.recordedSteps = recordedSteps
        self.recoredLenght = recordedLength
        self.replayEnabled = replayEnabled
        self.client = client
    }
    
    public var body: some View {
        NavigationView {
            List {
                ForEach(todos) { item in
                    HStack {
                        Image(systemName: item.done ? "checkmark.circle" : "circle")
                            .buttonify {
                                client?.update(item, .toggle)
                            }
                        Text(item.fullTitle)
                    }
                }
                .onDelete(perform: delete)
            }
            .animation(.linear, value: todos)
            .alert(
                "Do you want to replay \(recordedSteps) states (duration: \(Int(recoredLenght))s)?",
                isPresented: $isReplayStartAlertVisible,
                actions: {
                    Button("Cancel") {}
                    Button("Replay") {client?.replay()}
                }
            )
//            .alert("Timeline has finished!", isPresented: $stateHolder.isFinished, actions: {
//                Button("OK") {}
//            })
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading){
                    Button(
                        action: { isReplayStartAlertVisible = true },
                        label: {
                            Image(systemName: "clock.arrow.circlepath")
                                .foregroundColor(!replayEnabled ? .secondary : .yellow)
                        }
                    )
                    .disabled(!replayEnabled)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        client?.edit(true)
                    } label: {
                        Text("Edit")
                    }

                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        client?.add(ToDo())
                    } label: {
                        Image(systemName: "plus")
                    }

                }
            }
        }
    }
    
    private func delete(at offsets: IndexSet) {
        offsets.forEach { index in
            let todo = todos[index]
            client?.delete(todo)
        }
    }
}


public extension View {
    func buttonify(performing action: @escaping () -> ()) -> some View {
        Button(action: action, label: {self})
    }
}
