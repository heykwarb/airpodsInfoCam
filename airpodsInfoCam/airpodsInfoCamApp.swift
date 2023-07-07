//
//  airpodsInfoCamApp.swift
//  airpodsInfoCam
//
//  Created by Yohey Kuwabara on 2022/07/21.
//

import SwiftUI

@main
struct airpodsInfoCamApp: App {
    var body: some Scene {
        WindowGroup {
            View1()
                .environmentObject(VisionModel())
        }
    }
}
