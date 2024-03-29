//
//  HomeView.swift
//  Tymed
//
//  Created by Jonah Schueller on 28.09.20.
//  Copyright © 2020 Jonah Schueller. All rights reserved.
//

import SwiftUI

struct HomeView: View {
    
    @StateObject
    var homeViewModel = HomeViewModel()
    
    var body: some View {
        TabView {
            
            ForEach(0..<3) { index in
                
                if index == 0 {
                    HomeDashView(homeViewModel: homeViewModel)
                }else if index == 1 {
                    HomeTaskView(homeViewModel: homeViewModel)
                }else if index == 2 {
//                    TimetableOverview()
                    HomeCalendarView()
                        .environmentObject(homeViewModel)
                }
                
            }
            
        }.tabViewStyle(PageTabViewStyle(indexDisplayMode: .automatic))
        .onAppear {
            homeViewModel.reload()
        }
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
    }
}
