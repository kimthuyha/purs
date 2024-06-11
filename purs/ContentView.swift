//
//  ContentView.swift
//  purs
//
//  Created by Kim Thuy Ha on 6/7/24.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = LocationDetailsViewModel()
    var body: some View {
        ZStack(alignment: .topLeading) {
            GeometryReader { geometry in
                Image("background")
                    .resizable()
                    .scaledToFill() // Fills the entire safe area, potentially cropping
                    .ignoresSafeArea(.all) // Caution: might obscure content on some devices
                    .frame(width: geometry.size.width, height: geometry.size.height) // Optional for exact size
                    .offset(x: geometry.size.width * 0.08, y: 0)
            }
            VStack(spacing: 0) {
                Header(viewModel: viewModel)
                ZStack(alignment: .topLeading) {
                    OpeningHoursCard(viewModel: viewModel)
                }
                
                
                if !viewModel.isExpanded {
                    Footer().edgesIgnoringSafeArea(.bottom)
                    
                }
                
            }
            
        }
    }
    
}




struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
