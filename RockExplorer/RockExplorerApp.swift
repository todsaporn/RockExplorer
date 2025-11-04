//
//  RockExplorerApp.swift
//  RockExplorer
//
//  Created by Herb on 31/10/2568 BE.
//

import SwiftUI

@main
struct RockExplorerApp: App {
    @StateObject private var collectionViewModel: RockCollectionViewModel
    @StateObject private var locationService = LocationService()
    @StateObject private var radarViewModel: RadarViewModel

    init() {
        let collection = RockCollectionViewModel()
        _collectionViewModel = StateObject(wrappedValue: collection)
        _radarViewModel = StateObject(wrappedValue: RadarViewModel(collection: collection))
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(collectionViewModel)
                .environmentObject(locationService)
                .environmentObject(radarViewModel)
        }
    }
}
