//
//  ParseTestApp.swift
//  ParseTest
//
//  Created by Jedidiah Laudenslayer on 4/10/24.
//  Copyright © 2024 Parse. All rights reserved.
//

import SwiftUI
import TMGParseLiveQuery
import ParseCore

@main
struct ParseTestApp: App {
    var testObject = TestObject()
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

class TestObject {
    init() {
    }
}
