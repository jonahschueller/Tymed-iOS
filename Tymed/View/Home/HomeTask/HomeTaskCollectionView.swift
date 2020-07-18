//
//  HomeTaskCollectionView.swift
//  Tymed
//
//  Created by Jonah Schueller on 27.05.20.
//  Copyright © 2020 Jonah Schueller. All rights reserved.
//

import UIKit

private let nowReuseIdentifier = "homeNowCell"
private let taskTypeSelectorIdentifier = "taskTypeSelectorIdentifier"
private let addTaskIdentifier = "addTaskIdentifier"

private let headerSection = "typeSection"
private let todaySection = "todaySection"
private let allSection = "allSection"
private let doneSection = "doneSection"
private let expiredSection = "expiredSection"
private let openSection = "openSection"
private let archivedSection = "archivedSection"

class HomeTaskCollectionView: HomeBaseCollectionView {
    
    var todayTasks: [Task]?
    var allTasks: [Task]?
    var doneTasks: [Task]?
    var expiredTasks: [Task]?
    var openTasks: [Task]?
    var archivedTask: [Task]?
    
    private var typeCellSelectors = [HomeDashTaskSelectorCellType]()
    
    //MARK: UI setup
    internal override func setupUserInterface() {
        super.setupUserInterface()
        
        register(HomeCollectionViewHeader.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: "homeHeader")
        register(HomeTaskCollectionViewCell.self, forCellWithReuseIdentifier: homeTaskCell)
        
        register(HomeDashTaskSelectorCollectionViewCell.self, forCellWithReuseIdentifier: taskTypeSelectorIdentifier)
        register(UINib(nibName: "HomeDashTaskOverviewCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: homeDashTaskOverviewCollectionViewCell)
        
        register(HomeDashTaskOverviewNoTasksCollectionViewCell.self, forCellWithReuseIdentifier: addTaskIdentifier)
        
        
        if let flowLayout = collectionViewLayout as? UICollectionViewFlowLayout {
            
            flowLayout.minimumInteritemSpacing = 16
            
        }
    }
    
    private func identifier(for indexPath: IndexPath) -> String {
        let identifier = self.section(for: indexPath.section)
        
        switch identifier {
        case headerSection:
            return indexPath.row < typeCellSelectors.count ?  taskTypeSelectorIdentifier : addTaskIdentifier
        case todaySection, allSection, doneSection, expiredSection, openSection, archivedSection:
            return homeDashTaskOverviewCollectionViewCell
        default:
            return ""
        }
        
    }
    
    private func setupSections(_ tasks: [Task]?, section: String, type: HomeDashTaskSelectorCellType) {
        if tasks?.count ?? 0 > 0 {
            addSection(id: section)
            typeCellSelectors.append(type)
        }
    }
    
    //MARK: fetchData()
    internal override func fetchData() {
        
        todayTasks = TimetableService.shared.getTasksOfToday()
        allTasks = TimetableService.shared.getAllTasks()
        doneTasks = TimetableService.shared.getCompletedTasks()
        expiredTasks = TimetableService.shared.getExpiredTasks()
        openTasks = TimetableService.shared.getOpenTasks()
        archivedTask = TimetableService.shared.getArchivedTasks()
        
        sectionIdentifiers = []
        typeCellSelectors = []
        
        addSection(id: headerSection)
        
        setupSections(todayTasks, section: todaySection, type: .today)
        setupSections(openTasks, section: openSection, type: .open)
        setupSections(doneTasks, section: doneSection, type: .done)
        setupSections(expiredTasks, section: expiredSection, type: .expired)
        setupSections(archivedTask, section: archivedSection, type: .archived)
        setupSections(allTasks, section: allSection, type: .all)
        
    }
    
    // MARK: - UICollectionViewDataSource

    //MARK: numberOfItemsInSection
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let identifier = self.section(for: section)
        
        if identifier == headerSection {
            return typeCellSelectors.count + 1
        }
        return 1
    }
    
    private func tasks(for section: String) -> [Task]? {
        switch section {
        case todaySection:
            return todayTasks
        case allSection:
            return allTasks
        case doneSection:
            return doneTasks
        case expiredSection:
            return expiredTasks
        case openSection:
            return openTasks
        case archivedSection:
            return archivedTask
        default:
            return []
        }
    }
    
    private func configureCell(_ cell: UICollectionViewCell, identifier: String, indexPath: IndexPath) {
        
        if identifier == taskTypeSelectorIdentifier {
            let cell = (cell as! HomeDashTaskSelectorCollectionViewCell)
            
            cell.selectedIndicator.isHidden = true
            cell.type = typeCellSelectors[indexPath.row]
            
            
        }else if identifier == addTaskIdentifier {
            let addCell = (cell as! HomeDashTaskOverviewNoTasksCollectionViewCell)
            
            addCell.taskDelegate = taskDelegate
            
        } else if identifier == homeDashTaskOverviewCollectionViewCell {
            let taskCell = (cell as! HomeDashTaskOverviewCollectionViewCell)
            
            let section = self.section(for: indexPath.section)
            
            taskCell.tasks = self.tasks(for: section)
            taskCell.taskDelegate = taskDelegate
            taskCell.reload()
            
        }

        
    }
    
    //MARK: cellForItemAt
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {

        let identifier = self.identifier(for: indexPath)

        let cell = dequeueCell(identifier, indexPath)

        configureCell(cell, identifier: identifier, indexPath: indexPath)
        
        return cell

    }
    
    private func presentDetail(_ tasks: [Task]?, _ indexPath: IndexPath) {
        if let task = tasks?[indexPath.row] {
            homeDelegate?.taskDetail(self, for: task)
        }
    }
    
    private func sectionIdentifier(for type: HomeDashTaskSelectorCellType) -> String? {
        switch type {
        case .today:    return todaySection
        case .all:      return allSection
        case .done:     return doneSection
        case .expired:  return expiredSection
        case .open:     return openSection
        case .archived:  return archivedSection
        }
    }
    
    //MARK: didSelectItemAt
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {

//        presentDetail(tasks, indexPath)
        let section = self.section(for: indexPath.section)
        let identifier = self.identifier(for: indexPath)

        if section == headerSection {
            if identifier == addTaskIdentifier {
                taskDelegate?.onAddTask(nil, completion: nil)
            }else {
                guard let id = sectionIdentifier(for: typeCellSelectors[indexPath.row]) else {
                    return
                }
                
                guard let index = self.section(for: id) else {
                    return
                }
                
                let headerOffset = collectionView.collectionViewLayout
                    .layoutAttributesForSupplementaryView(ofKind: UICollectionView.elementKindSectionHeader, at:
                                                        IndexPath(row: 0, section: index))?.frame.origin.y ?? 0
                
                collectionView.setContentOffset(CGPoint(x: collectionView.contentOffset.x, y: headerOffset - collectionView.contentInset.top), animated: true)
                
//                collectionView.scrollToItem(at: IndexPath(row: 0, section: index), at: .top, animated: true)
            }

        }
    }
    
    //MARK: supplementaryView
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        
        if kind == UICollectionView.elementKindSectionHeader {
            let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "homeHeader", for: indexPath) as! HomeCollectionViewHeader
            
            let sectionId = section(for: indexPath)
            
            switch sectionId{
            case headerSection:
                header.label.text = "Tasks"
            case todaySection:
                header.label.text =  "Today"
            case allSection:
                header.label.text =  "All"
            case doneSection:
                header.label.text = "Done"
            case expiredSection:
                header.label.text = "Expired"
            case openSection:
                header.label.text = "Open"
            case archivedSection:
                header.label.text = "Archived"
            default:
                header.label.text = ""
            }
            return header
        }
        
        return UICollectionReusableView()
    }
    
    //MARK: sizeForHeaderInSection
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        let height: CGFloat = 50
        
        return CGSize(width: collectionView.frame.width, height: height)
    }
    
    override func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let identifier = self.identifier(for: indexPath)
        
        var width: CGFloat = (collectionView.frame.width - 2 * 20)
        var height: CGFloat = 50
        
        if identifier == taskTypeSelectorIdentifier ||
            (identifier == addTaskIdentifier && typeCellSelectors.count % 2 != 0) {
            width = (collectionView.frame.width - 60) / 2
        }
        
        if identifier == homeDashTaskOverviewCollectionViewCell {
            
            let tasks = self.tasks(for: self.section(for: indexPath.section))
            
            height = 20 + CGFloat((tasks?.count ?? 0) * 60)
        }
        
        return CGSize(width: width, height: height)
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        homeDelegate?.didScroll(scrollView)
    }
    
}

