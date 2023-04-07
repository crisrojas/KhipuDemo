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
    replay: () -> ()
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
    @State private var isReplayButtonDisabled = false
    
    let todos: [ToDo]
    let recordedSteps: Int
    let recoredLenght: TimeInterval
    let client: TodoListClient?
    
    public init(todos: [ToDo], recordedSteps: Int, recordedLength: TimeInterval, client: TodoListClient? = nil) {
        self.todos = todos
        self.recordedSteps = recordedSteps
        self.recoredLenght = recordedLength
        self.client = client
    }
    
    public var body: some View {
        NavigationView {
            List {
                ForEach(todos) {
                    Text($0.fullTitle)
                }
                .onDelete(perform: delete)
            }
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
                                .foregroundColor(isReplayButtonDisabled ? .secondary : .yellow)
                        }
                    )
                    .disabled(isReplayButtonDisabled)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
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
