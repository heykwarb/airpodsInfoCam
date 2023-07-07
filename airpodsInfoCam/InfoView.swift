//
//  InfoView.swift
//  SneakerInfoCam
//
//  Created by Yohey Kuwabara on 2022/07/27.
//

import SwiftUI
import CoreML

struct InfoARView: View {
    @EnvironmentObject var visionModel: VisionModel
    
    @State var inStock = false
    @State var shoeSize = 1
    
    @State var colorSelected = 1
        
    var body: some View {
        let cornerRadius: CGFloat = 10
        let shadowRadius: CGFloat = 5
        
        let batteryWidth: CGFloat = 24
        let batteryPercentage: CGFloat = 20
        
        var batteryName = "battery.25"
        
        ZStack{
            VStack(alignment: .center){
                Text("AirPods Pro Case")
                    .font(.title)
                    .fontWeight(.bold)
                
                Image(systemName: batteryName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 50)
                    
                Text("\(Int(batteryPercentage)) %")
                    .font(.body)
            }
            .padding()
            .background(.thinMaterial)
            .cornerRadius(cornerRadius)
            .shadow(radius: shadowRadius)
        }
        .frame(width: visionModel.arViewWidth)
    }
}

struct InfoARView_Previews: PreviewProvider {
    static var previews: some View {
        InfoARView().environmentObject(VisionModel())
    }
}

struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        Path { path in
            path.move(to: CGPoint(x: rect.midX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
            path.closeSubpath()
        }
    }
}

struct ARTestView: View {
    var body: some View {
        VStack{
            Text("Braun x OffWhite Watch")
                .font(.custom("Baskerville", size: 22))
        }
        .padding()
        .background(.thinMaterial)
        .cornerRadius(10)
    }
}
