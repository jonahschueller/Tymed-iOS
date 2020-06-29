//
//  HomeDashTaskOverviewCollectionViewCell.swift
//  Tymed
//
//  Created by Jonah Schueller on 16.05.20.
//  Copyright © 2020 Jonah Schueller. All rights reserved.
//

import UIKit

protocol HomeTaskDetailDelegate {
    
    func showTaskDetail(_ task: Task)
    
    func didSelectTask(_ cell: HomeDashTaskOverviewCollectionViewCell, _ task: Task, _ at: IndexPath, animated: Bool)
    
    func didDeleteTask(_ task: Task)
    
    func onAddTask(_ cell: HomeDashTaskOverviewCollectionViewCell)
    
    func onSeeAllTasks(_ cell: HomeDashTaskOverviewCollectionViewCell)
}

let homeDashTaskOverviewCollectionViewCell = "homeDashTaskOverviewCollectionViewCell"
class HomeDashTaskOverviewCollectionViewCell: HomeBaseCollectionViewCell, UITableViewDelegate, UITableViewDataSource {
    
    static func register(_ collectionView: UICollectionView) {
        collectionView.register(HomeDashTaskOverviewCollectionViewCell.self, forCellWithReuseIdentifier: homeDashTaskOverviewCollectionViewCell)
    }
    
    var tasks: [Task]?
    
    var taskDelegate: HomeTaskDetailDelegate?
        
    @IBOutlet weak var tableView: UITableView!
    
    @IBAction func onAddTask(_ sender: Any) {
        taskDelegate?.onAddTask(self)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        tableView.backgroundColor = .secondarySystemGroupedBackground
        
        tableView.register(TaskOverviewTableViewCell.self, forCellReuseIdentifier: "homeTaskItem")
        
        tableView.delegate = self
        tableView.dataSource = self
        
        tableView.becomeFirstResponder()
        
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 30, bottom: 0, right: 0)
    }
    
    override func reload() {
        super.reload()
        
        tableView.reloadData()
    }
    
    private func task(for indexPath: IndexPath) -> Task? {
        return tasks?[indexPath.row]
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return min(tasks?.count ?? 0, 3)
    }
   
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "homeTaskItem", for: indexPath) as! TaskOverviewTableViewCell
    
        cell.reload(tasks![indexPath.row])
    
        if indexPath.row == min(tasks?.count ?? 0, 3) - 1 {
            cell.separatorInset = UIEdgeInsets(top: 0, left: cell.frame.width, bottom: 0, right: 0)
        }
        
        return cell
    }
   
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print("tap task cell item")
        guard let task = tasks?[indexPath.row] else {
            return
        }
        
        taskDelegate?.didSelectTask(self, task, indexPath, animated: true)
    }
    
    func tableView(_ tableView: UITableView, willPerformPreviewActionForMenuWith configuration: UIContextMenuConfiguration, animator: UIContextMenuInteractionCommitAnimating) {
        
        let item = Int((configuration.identifier as! NSString) as String) ?? 0
        
        animator.addCompletion {
            let task = self.task(for: IndexPath(row: item, section: 0))!
            
            self.taskDelegate?.showTaskDetail(task)
        }
        
    }
    
    
    func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        let id = "\(indexPath.row)" as NSString
        
        let config = UIContextMenuConfiguration(identifier: id, previewProvider: { () -> UIViewController? in
            
            let detail = TaskDetailTableViewController(style: .insetGrouped)
                
            detail.task = self.task(for: indexPath)
            detail.taskDelegate = self.taskDelegate
            
            return detail
        }) { (element) -> UIMenu? in
            
            let complete = UIAction(title: "Complete", image: UIImage(systemName: "checkmark")) { (action) in
                
                let cell = (tableView.cellForRow(at: indexPath) as! TaskOverviewTableViewCell)
                
                // Delay the complete toogle for the animation.
                // The context menu animation has to end
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                    cell.completeToogle()
                }
                
            }
            
            let delete = UIAction(title: "Delete", image: UIImage(systemName: "trash")) { (action) in
                
                guard let task = self.task(for: indexPath) else {
                    return
                }
                
                TimetableService.shared.deleteTask(task)
                
                self.taskDelegate?.didDeleteTask(task)
                
            }
            
            return UIMenu(title: "", image: nil, children: [complete, delete])
        }
        
        
        return config
    }
    
}
