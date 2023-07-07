//
//  DetectionBox.swift
//  GraphicTest1
//
//  Created by Yohey Kuwabara on 2022/10/11.
//

import SwiftUI


struct BoundingBox: View{
    var boxWidth: CGFloat
    var boxHeight: CGFloat
    
    var borderColor: Color = .blue
    
    var cornerR: CGFloat = 5
    
    var stroke: CGFloat = 4
    
    let shadowR: CGFloat = 10
    
    var body: some View{
        //bounding box
        ZStack{
            //blur
            RoundedRectangle(cornerRadius: cornerR)
                .stroke(lineWidth: stroke)
                .foregroundColor(borderColor)
                .frame(width: boxWidth, height: boxHeight)
                .blur(radius: 10)
            //screen blend
            RoundedRectangle(cornerRadius: cornerR)
                .stroke(lineWidth: stroke)
                .foregroundColor(borderColor)
                .frame(width: boxWidth, height: boxHeight)
                .shadow(color: borderColor, radius: shadowR)
                .blendMode(.screen)
            //multiply blend
            RoundedRectangle(cornerRadius: cornerR)
                .stroke(lineWidth: stroke)
                .foregroundColor(borderColor)
                .frame(width: boxWidth, height: boxHeight)
                .shadow(color: borderColor, radius: shadowR)
                .blendMode(.multiply)
                
        }
    }
}

