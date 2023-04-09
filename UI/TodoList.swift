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
    
    let todos: [ToDo]
    let client: TodoListClient?
    
    public init(todos: [ToDo], client: TodoListClient? = nil) {
        self.todos = todos
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
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
//                    Button {
//                        client?.edit(true)
//                    } label: {
//                        Text("Edit")
//                    }
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


public extension View {
    func buttonify(performing action: @escaping () -> ()) -> some View {
        Button(action: action, label: {self})
    }
}
