//
//  ContentView.swift
//  Photos Control Pad
//
//  Created by Paul Wong on 9/13/24.
//

import SwiftUI

struct ContentView: View {

    @State var xValue: CGFloat = 0
    @State var yValue: CGFloat = 0


    var body: some View {
        ControlPad(xValue: $xValue, yValue: $yValue)
            .animation(.smooth(duration: 0.39))
            .overlay(
                VStack(spacing: 10) {
                    HStack(spacing: 10) {
                        Text("X Value: \(Int(xValue))")
                        Text("Y Value: \(Int(yValue))")
                    }
                    .fixedSize(horizontal: true, vertical: false)
                    .font(.system(size: 13).weight(.medium))
                    .foregroundColor(.black)
                    .padding(.vertical, 7)
                    .padding(.horizontal, 11)
                    .background(.white)
                    .clipShape(Capsule())
                    .shadow(color: .black.opacity(0.05), radius: 3, x: 0, y: 3)
                    .shadow(color: .black.opacity(0.16), radius: 39, x: 0, y: 16)

                    Spacer()
                }
                .padding(.top, 40)
                .frame(height: UIScreen.main.bounds.maxY)
            )
    }
}
