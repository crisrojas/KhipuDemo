//
//  KhipuExperimentApp.swift
//  KhipuExperiment
//
//  Created by Cristian Felipe Patiño Rojas on 07/04/2023.
//

import SwiftUI
import Khipu

@main
struct KhipuExperimentApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView(state: state, core: core)
        }
    }
}

let timelineRecorder = TimelineRecorderMiddleware(store: store)
fileprivate let store = createRamStore()
fileprivate let state = ViewState(store: store)
fileprivate let core  = createCore(recorder: timelineRecorder, store: store)

