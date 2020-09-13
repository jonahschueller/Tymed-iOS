//
//  HomeDashCollectionViewController.swift
//  Tymed
//
//  Created by Jonah Schueller on 28.04.20.
//  Copyright © 2020 Jonah Schueller. All rights reserved.
//

import Foundation
import UIKit
import SwiftUI

private let nowReuseIdentifier = "homeNowCell"
private let taskSelectionCell = "taskSelection"

private let tasksSection = "tasksSection"
private let currentSection = "currentSection"
private let nextSection = "nextSection"
private let daySection = "daySection"
private let nextDaySection = "nextDaySection"
private let weekSection = "weekSection"

class HomeDashCollectionView: HomeBaseCollectionView {
    
    var cellColor: UIColor = .red
    
    var subjects: [Subject]?
    var events: [CalendarEvent]?
    
    private var taskSelection: HomeDashTaskSelectorCellType = .next
    
    //MARK: Section lesson arrays
    var currentEvents: [CalendarEvent]?
    
    var nextEvents: [CalendarEvent]?
    
    var dayEvents: [CalendarEvent]?
    
    var nextDay: Day?
    var nextDayEvents: [CalendarEvent]?
    
    var tasks: [Task]?
    
    var taskOverviewDelegate: TaskOverviewTableviewCellDelegate?
    
    //MARK: UI setup
    override internal func setupUserInterface() {
        super.setupUserInterface()
        
        collectionView.register(HomeCollectionViewHeader.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: "homeHeader")
        collectionView.register(UINib(nibName: "HomeDashTaskOverviewCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: homeDashTaskOverviewCollectionViewCell)
        collectionView.register(HomeDashTaskSelectorCollectionViewCell.self, forCellWithReuseIdentifier: taskSelectionCell)
        collectionView.register(HomeDashTaskOverviewNoTasksCollectionViewCell.self, forCellWithReuseIdentifier: "noTaskCell")
        
        collectionView.register(HomeLessonCollectionViewCell.self, forCellWithReuseIdentifier: homeLessonCell)
        HomeEventCollectionViewCell.register(collectionView)
        
        
    }
    
    /// Returns the lesson for a given uuid
    /// - Parameter uuid: UUID of the lesson
    /// - Returns: Lesson with the given uuid. Nil if lesson does not exist in lessons list.
    private func event(for uuid: UUID) -> CalendarEvent? {
        return events?.filter { return $0.id == uuid }.first
    }
    
    private func event(for indexPath: IndexPath) -> CalendarEvent? {
        let identifier = section(for: indexPath)
        
        switch identifier {
        case currentSection:
            return currentEvents?[indexPath.row]
        case nextSection:
            return nextEvents?[indexPath.row]
        case daySection:
            return dayEvents?[indexPath.row]
        case weekSection:
            return events?[indexPath.row]
        case nextDaySection:
            return nextDayEvents?[indexPath.row]
        default:
            return nil
        }
    }
    
    private func appendSection(_ events: [CalendarEvent]?, with identifier: String) {
        if (events?.count ?? 0) > 0 {
            addSection(id: identifier)
        }
    }
    
    //MARK: fetchData()
    override internal func fetchData() {
        
//        lessons = TimetableService.shared.fetchLessons()
        
        currentEvents = TimetableService.shared.calendarEvents(within: Date())
        
        dayEvents = TimetableService.shared.calendarEventsFor(day: Date())
        
        nextDayEvents = TimetableService.shared.getNextCalendarEvents(startingFrom: Date().nextDay)
        
        nextEvents = nextDayEvents?.sorted().reduce([], { (result, event) -> [CalendarEvent] in
            if result.isEmpty {
                return [event]
            }
            
            if result.first?.startDate == event.startDate {
                var newRes = result
                newRes.append(event)
                return newRes
            }
            return result
        })
        
        sectionIdentifiers = []
        
        loadTask()
        
        addSection(id: tasksSection)
        
        appendSection(currentEvents, with: currentSection)
        appendSection(nextEvents, with: nextSection)
        appendSection(dayEvents, with: daySection)
        appendSection(nextDayEvents, with: nextDaySection)
//        appendSection(lessons, with: weekSection)
        
    }

    private func loadTask() {
        
        tasks = taskSelection.tasks()
        tasks?.reverse()
    }
    
    override func reload() {
        loadTask()
        super.reload()
    }
    
    // MARK: - UICollectionViewDataSource

    //MARK: numberOfItemsInSection
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection identifier: String) -> Int {
        
        switch identifier {
        case tasksSection:
            return 5
        case currentSection:
            return currentEvents?.count ?? 0
        case nextSection:
            return nextEvents?.count ?? 0
        case daySection:
            return dayEvents?.count ?? 0
        case weekSection:
            return events?.count ?? 0
        case nextDaySection:
            return nextDayEvents?.count ?? 0
        default:
            return 0
            
        }
    }
    
    //MARK: cellForItemAt
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let sectionId = self.section(for: indexPath)
        
        switch sectionId {
        case tasksSection:
            if indexPath.row < 4 {
                let cell = dequeueCell(taskSelectionCell, indexPath) as! HomeDashTaskSelectorCollectionViewCell
                
                let type = selectorType(for: indexPath.row)
                
                cell.isSelected = type == taskSelection
                cell.type = type
                
                
                return cell
            }else if tasks?.count ?? 0 > 0 {
                let cell = dequeueCell(homeDashTaskOverviewCollectionViewCell, indexPath) as! HomeDashTaskOverviewCollectionViewCell
                
                cell.size = .large
                cell.tasks = tasks
                cell.homeDelegate = homeDelegate
                cell.taskOverviewDelegate = taskOverviewDelegate
                cell.reload()
                
                return cell
            }else {
                let cell = dequeueCell("noTaskCell", indexPath) as! HomeDashTaskOverviewNoTasksCollectionViewCell
                
                cell.homeDelegate = homeDelegate
                cell.type = taskSelection
                
                return cell
            }
            
        case currentSection, nextSection, daySection, weekSection, nextDaySection:
            guard let event = event(for: indexPath) else {
                return UICollectionViewCell()
            }
            
            if event.isLesson {
                let cell = dequeueCell(homeLessonCell, indexPath) as! HomeLessonCollectionViewCell
                
                cell.lesson = event.asLesson
                return cell
            } else if event.isEvent {
                let cell = dequeueCell(homeEventCell, indexPath) as! HomeEventCollectionViewCell
                
                cell.event = event.asEvent
                return cell
            }
            
            return UICollectionViewCell()
        default:
            return UICollectionViewCell()
        }
        
    }
    
    private func presentLessonDetail(_ indexPath: IndexPath) {
        guard let lesson = self.event(for: indexPath)? .asLesson else {
            return
        }
        homeDelegate?.presentLessonEditView(for: lesson)
    }
    
    private func selectorType(for index: Int) -> HomeDashTaskSelectorCellType {
        switch index {
        case 0:     return .next
        case 1:     return .done
        case 2:     return .planned
        case 3:     return .open
        default:    return .all
        }
    }
    
    //MARK: didSelectItemAt
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        let sectionId = self.section(for: indexPath)
        
        switch sectionId {
        case tasksSection:
            if indexPath.row < 4 {
                taskSelection = selectorType(for: indexPath.row)
                
                loadTask()
                
                collectionView.reloadSections(IndexSet(arrayLiteral: 0))
            }
            
            break
        case currentSection, nextSection, daySection, weekSection, nextDaySection:
            presentLessonDetail(indexPath)
            break
        default:
            break
        }
        
    }

    private func headerTitle(for section: String) -> String {
        switch section {
        case tasksSection:      return "Tasks"
        case currentSection:    return "Now"
        case nextSection:       return "Next"
        case daySection:        return "Today"
        case nextDaySection:    return "\(nextDay?.string() ?? "")"
        case weekSection:       return "All"
        default:                return "-"
        }
    }
    
    //MARK: supplementaryView
    override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        
        if kind == UICollectionView.elementKindSectionHeader {
            let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "homeHeader", for: indexPath) as! HomeCollectionViewHeader
            
            // Set the title of the section header according to the section type
            header.label.text = headerTitle(for: section(for: indexPath))
            
            return header
        }
        
        return UICollectionReusableView()
    }
    
    //MARK: sizeForHeaderInSection
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return CGSize(width: collectionView.frame.width, height: 40)
    }
    
    override func collectionView(_ collectionView: UICollectionView, contextMenuConfigurationForItemAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        
        guard let lesson = self.event(for: indexPath)?.asLesson else {
            return nil
        }
        
        guard let uuid = lesson.id else {
            return nil
        }
        
        let config = UIContextMenuConfiguration(identifier: uuid as NSUUID, previewProvider: { () -> UIViewController? in
            
            // ViewController to give the user a preview of the lessonEditView
            let lessonEdit = UIHostingController(
                rootView: LessonEditContentView(lesson: lesson, dismiss: { }))
            
            return lessonEdit
        }) { (elements) -> UIMenu? in
            
            let delete = UIAction(title: "Delete", image: UIImage(systemName: "trash")) { (action) in
                
                guard let lesson = self.event(for: indexPath)?.asLesson else {
                    return
                }
                
                TimetableService.shared.deleteLesson(lesson)
                
                
                self.homeDelegate?.presentLessonEditView(for: lesson)
                
            }
            
            return UIMenu(title: "", image: nil, children: [delete])
        }
        
        return config
    }
    
    override func collectionView(_ collectionView: UICollectionView, willPerformPreviewActionForMenuWith configuration: UIContextMenuConfiguration, animator: UIContextMenuInteractionCommitAnimating) {
        
        guard let id = (configuration.identifier as? NSUUID) as UUID? else {
            return
        }
        
        animator.addCompletion {
            guard let lesson = self.event(for: id)?.asLesson else {
                return
            }
            
            self.homeDelegate?.presentLessonEditView(for: lesson)
        }
        
    }
    
}


extension HomeDashCollectionView {
    
    //MARK: sizeForItemAt
    override func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let sectionId = section(for: indexPath)
        
        switch sectionId {
        case tasksSection:
            // If the task is a selector task
            if indexPath.row < 4 {
                return CGSize(width: (collectionView.contentSize.width -  20) / 2, height: 45)
            } else if tasks?.count ?? 0 == 0 { // Task add cell
                return CGSize(width: collectionView.contentSize.width, height: 45)
            }
            // Task Overview cell
            return CGSize(width: collectionView.contentSize.width, height: 20 + CGFloat((tasks?.count ?? 0) * 60))
        case currentSection, nextSection, daySection, weekSection, nextDaySection:
            guard let event = self.event(for: indexPath) else {
                return .zero
            }
            
            if let lesson = event.asLesson {
                // Lesson cell
                let height = HomeLessonCellConfigurator.height(for: lesson)
                
                return CGSize(width: collectionView.contentSize.width, height: height)
            }else if event.asEvent != nil {
                return CGSize(width: collectionView.contentSize.width, height: 50)
            }
            
            return .zero
        default:
            return CGSize.zero
        }
        
    }

}



