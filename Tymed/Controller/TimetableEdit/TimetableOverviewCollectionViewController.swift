//
//  AddTableViewController.swift
//  Tymed
//
//  Created by Jonah Schueller on 02.05.20.
//  Copyright © 2020 Jonah Schueller. All rights reserved.
//

import UIKit

protocol TimetableOverviewBaseDelegate {
    
    func reload()
    
    func dismiss()
        
    func popNavigationViewController()
    
    func present(_ viewController: UIViewController)
}

//MARK: DeleteDelegate
protocol TimetableOverviewDeleteDelegate : TimetableOverviewBaseDelegate {
    func requestForDeletion(of timetable: Timetable) -> Bool
}




let addReuseIdentifier = "addCell"
class TimetableOverviewCollectionViewController: UITableViewController {

    var timetables: [Timetable]?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false
        
        let rightItem = UIBarButtonItem(image: UIImage(systemName: "plus",
                                                       withConfiguration: UIImage.SymbolConfiguration(pointSize: 17, weight: .bold)), style: .plain, target: self, action: #selector(showActionSheet))

        navigationItem.rightBarButtonItem = rightItem
        navigationController?.navigationBar.prefersLargeTitles = true
        
        title = "Timetables"
        
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: addReuseIdentifier)
        tableView.register(NoTimetablesTableViewCell.self, forCellReuseIdentifier: "noTimetables")
        
        fetchData()
    }
    
    private func timetable(for index: IndexPath) -> Timetable? {
        return timetables?[index.row]
    }
    
    func fetchData() {
        timetables = TimetableService.shared.fetchTimetables()
        
    }
    
    func reloadScene() {
        fetchData()
        
        tableView.reloadData()
    }
    
    @objc func showActionSheet(_ sender: UIBarButtonItem) {
        
        let alert = UIAlertController(title: "What whould you like to add?", message: "", preferredStyle: .actionSheet)

        alert.addAction(UIAlertAction(title: "Lesson", style: .default , handler:{ (action) in
            let lesson = UINavigationController(rootViewController: LessonAddViewController(style: .insetGrouped))
            self.present(lesson, animated: true, completion: nil)
        }))

        alert.addAction(UIAlertAction(title: "Task", style: .default , handler:{ (action) in
            let task = UINavigationController(rootViewController: TaskAddViewController(style: .insetGrouped))
            self.present(task, animated: true, completion: nil)
        }))

        alert.addAction(UIAlertAction(title: "Timetable", style: .default , handler:{ (action) in
            self.showTimetableAdd()
        }))
        
        alert.addAction(UIAlertAction(title: "Dismiss", style: .cancel, handler: { (action) in
            print("Dismiss")
        }))
        
        if let popOver = alert.popoverPresentationController {
            popOver.barButtonItem = sender
        }
        
        self.present(alert, animated: true, completion: {
            print("completion block")
        })
        
        
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let timetables = self.timetables else {
            return 1
        }
        return max(timetables.count, 1)
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard timetables?.count ?? 0 > 0, let timetable = timetables?[indexPath.row] else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "noTimetables", for: indexPath) as! NoTimetablesTableViewCell
            
            cell.addButton.addTarget(self, action: #selector(showTimetableAdd), for: .touchUpInside)
            
            return cell
        }
        
        let cell = tableView.dequeueReusableCell(withIdentifier: addReuseIdentifier, for: indexPath)
        
        cell.textLabel?.text = timetable.name
        cell.accessoryType = .disclosureIndicator
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        guard timetables?.count ?? 0 > 0 else {
            return tableView.contentSize.height
        }
        
        return 80
    }
    
    @objc func showTimetableAdd() {
        let timetableAdd = TimetableAddViewController(style: .insetGrouped)
        let nav = UINavigationController(rootViewController: timetableAdd)
                
        timetableAdd.timetableBaseDelegate = self
        
        present(nav, animated: true, completion: nil)
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        guard self.timetables?.count ?? 0 > 0 else {
            showTimetableAdd()
            
            return
        }
        
        guard let timetable = self.timetable(for: indexPath) else {
            return
        }
        
        let detailVC = TimetableDetailTableViewController(style: .insetGrouped)
        
        detailVC.timetableDeletionDelegate = self
        detailVC.timetable = timetable
        
        navigationController?.pushViewController(detailVC, animated: true)
    }
}


extension TimetableOverviewCollectionViewController : TimetableOverviewDeleteDelegate {
    
    func present(_ viewController: UIViewController) {
        self.present(viewController, animated: true, completion: nil)
    }
    
    func reload() {
        reloadScene()
    }
    
    func dismiss() {
        dismiss(animated: true, completion: nil)
        reload()
    }
    
    func popNavigationViewController() {
        navigationController?.popViewController(animated: true)
        reload()
    }
    
    func requestForDeletion(of timetable: Timetable) -> Bool {
        TimetableService.shared.deleteTimetable(timetable)
        
        return true
    }
    
}