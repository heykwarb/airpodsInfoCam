//
//  ContentView.swift
//  SneakerInfoCam
//
//  Created by Yohey Kuwabara on 2022/07/27.
//

import SwiftUI

struct View1: View {
    @EnvironmentObject var visionModel: VisionModel
    ///@ObservedObject var visionModel = VisionModel()
    
    var body: some View {
        ZStack{
            CameraPreview(camera: visionModel)
                .onAppear(){
                    visionModel.Check()
                }
            
            if visionModel.objectDetected == true{
                VStack(alignment: .leading){
                    Spacer()
                    ////Text("bounds width: \(visionModel.bounds.width)")
                    ////Text("bounds height: \(visionModel.bounds.height)")
                    ////Text("bounds minX: \(visionModel.bounds.minX)")
                    ///Text("bounds minY: \(visionModel.bounds.minY)")
                }
                .padding(.vertical)
                
                BoundingBox(boxWidth: visionModel.boxWidth, boxHeight: visionModel.boxHeight)
                    .position(x: visionModel.positionX, y: visionModel.positionY)
                
                ///InfoARView(visionModel: _visionModel)
                ///InfoARView()
                    ///.frame(width: visionModel.arViewWidth)
                    ////.position(x: visionModel.positionX, y: visionModel.positionY)
            }
        }
    }
}

struct View1_Previews: PreviewProvider {
    static var previews: some View {
        View1()
    }
}
