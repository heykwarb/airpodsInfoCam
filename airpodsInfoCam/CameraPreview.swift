//
//  CameraPreview.swift
//  camera
//
//  Created by Yohey Kuwabara on 2020/12/20.
//

import SwiftUI
import AVFoundation


struct CameraPreview: UIViewRepresentable {
    
    @ObservedObject var camera : VisionModel
    
    func makeUIView(context: Context) ->  UIView {
     
        let view = UIView(frame: UIScreen.main.bounds)
        
        camera.preview = AVCaptureVideoPreviewLayer(session: camera.session)
        camera.preview.frame = view.frame
        
        // Your Own Properties...
        camera.preview.videoGravity = .resizeAspectFill
        view.layer.addSublayer(camera.preview)
        
        // starting session
        camera.session.startRunning()
        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        
    }
}
