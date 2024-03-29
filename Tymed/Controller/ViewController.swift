//
//  ViewController.swift
//  Tymed
//
//  Created by Jonah Schueller on 27.04.20.
//  Copyright © 2020 Jonah Schueller. All rights reserved.
//

import UIKit
import SwiftUI

class ViewController: UITabBarController {

    let homeVC = HomeViewController(collectionViewLayout: UICollectionViewFlowLayout())
    
    private var selectedTab = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        tabBar.isTranslucent = false
        
        view.backgroundColor = .systemGroupedBackground
        
        let home = generateHomeViewController()
        
        let config = UIImage.SymbolConfiguration(
            font: .systemFont(
                ofSize: 16,
                weight: .semibold),
            scale: .default)
        
        let homeTabItem = UITabBarItem(
            title: "Start",
            image: UIImage(systemName: "house", withConfiguration: config), tag: 0)
        
        homeTabItem.selectedImage = UIImage(systemName: "house.fill", withConfiguration: config)

        
        home.tabBarItem = homeTabItem
        
        let add = generateAddViewController()
        
        let addTabItem = UITabBarItem(
            title: "Timetables",
            image: UIImage(systemName: "plus", withConfiguration: config), tag: 1)
        
        add.tabBarItem = addTabItem
        
        let profile = generateProfileViewController()
        
        let profileTabItem = UITabBarItem(
            title: "Profile",
            image: UIImage(systemName: "person", withConfiguration: config), tag: 2)
        
        profile.tabBarItem = profileTabItem
        
        profileTabItem.selectedImage = UIImage(systemName: "person.fill", withConfiguration: config)
        
        viewControllers = [home, add, profile]
    }
    
    func reload() {
        homeVC.reload()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
//        homeVC.dashCollectionView.reload()
        
    }
    
    private func generateHomeViewController() -> UINavigationController {

       let nav = UINavigationController(navigationBarClass: NavigationBar.self, toolbarClass: nil)
       nav.setViewControllers([homeVC], animated: false)
       
       return nav
    }
       
       
    private func generateAddViewController() -> UIViewController {
        
        let view = UIHostingController(rootView: TimetableOverview().environment(\.managedObjectContext, AppDelegate.persistentContainer))

        let nav = UINavigationController(rootViewController: view)

        return nav
        
    }
    
    private func generateProfileViewController() -> UIViewController {
        let view = UIHostingController(rootView: ProfileView().environment(\.managedObjectContext, AppDelegate.persistentContainer))

        let nav = UINavigationController(rootViewController: view)
        
        return nav
    }
    
    override func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem) {
        
        if item.tag == 0 && selectedTab == 0 {
            homeVC.scrollToPage(page: 0)
        }
        
        selectedTab = item.tag
    }

}
