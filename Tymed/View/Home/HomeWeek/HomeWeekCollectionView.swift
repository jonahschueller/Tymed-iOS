//
//  HomeWeekCollectionView.swift
//  Tymed
//
//  Created by Jonah Schueller on 12.05.20.
//  Copyright © 2020 Jonah Schueller. All rights reserved.
//

import UIKit
//MARK: HomeWeekCollectionView
class HomeWeekCollectionView: HomeBaseCollectionView {
    
    
    var lessons: [Lesson] = []
    
    private var weekDays: [Day] = []
    private var week: [Day: [Lesson]] = [:]
    
    //MARK: setupUI()
    override internal func setupUserInterface() {
        super.setupUserInterface()
        
        collectionView.dragDelegate = self
        collectionView.dropDelegate = self
        collectionView.dragInteractionEnabled = true
        
        collectionView.register(HomeCollectionViewHeader.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: "homeHeader")
        collectionView.register(HomeWeekLessonCollectionViewCell.self, forCellWithReuseIdentifier: homeLessonCell)
        
    }
    
    //MARK: fetchDate()
    /// Fetches the lesson data from core data
    override func fetchData() {
        
        // Fetch all lessons
        lessons = TimetableService.shared.fetchLessons() ?? []
        
        
        week = TimetableService.shared.sortLessonsByWeekDay(lessons)
        
        weekDays = Array(week.keys)
        
        // Sort the days from monday to sunday
        weekDays.sort(by: { (d1, d2) -> Bool in
            return d1 < d2
        })
        
        collectionView.reloadData()
        
        scrollTo(day: .current)
        
    }
    
    private func duration(of lesson: Lesson) -> Int {
        return Int(lesson.end - lesson.start)
    }
    
    private func heightRelativeToDuration(of lesson: Lesson) -> CGFloat {
        let duration = Double(self.duration(of: lesson)) * 0.75
        
        return CGFloat(max(25, duration))
    }
    
    //MARK: scrollTo(date: )
    /// Scrolls the collection view to the first lesson that fits the date.
    /// If there is no lesson that fits the date. The next lesson after that date will be chosen
    /// - Parameters:
    ///   - date: Date to search for the alogorithm
    ///   - animated: scroll animation yes/no
    func scrollTo(date: Date, _ animated: Bool = false) {
        guard let day = Day(rawValue: Calendar.current.component(.weekday, from: date)) else {
            print("scrollTo(date:) failed")
            return
        }
        let time = Time(from: date)
        
        scrollTo(day: day, time: time, animated)
    }
    
    //MARK: scrollTo(day: )
    func scrollTo(day: Day, _ animated: Bool = false) {
        if let section = weekDays.firstIndex(of: day) {
            collectionView.scrollToItem(at: IndexPath(row: 0, section: section), at: .top, animated: animated)
        }else {
            if !week.isEmpty {
                scrollTo(day: day.rotatingNext(), animated)
            }
        }
    }
    
    //MARK: scrollTo(day:, time: )
    func scrollTo(day: Day, time: Time, _ animated: Bool = false) {
        if let section = weekDays.firstIndex(of: day) {
            let lessons = self.lessons(for: day) ?? []
            
            // In case the last lesson of today ends before the requested time
            // -> Go to next day
            if let l = lessons.last, l.endTime < time {
                if !week.isEmpty { // Avoid endless recursion for the case there are no lessons
                    scrollTo(day: day.rotatingNext(), time: Time.zero, animated)
                }
                return
            }
            // Search for the lesson that is closest to the req. time
            let closest = lessons.reduce(lessons.first) { (l1, l2) -> Lesson? in
                guard let s1 = l1?.startTime, let e1 = l1?.startTime else {
                    return nil
                }
                // In case the requested time is within a lesson -> return that lesson
                if Time.between(s1, time, t3: e1) {
                    return l1
                }
                
                // In case the requested time is before the first lesson -> return that lesson
                if let t1 = l1?.startTime, time <= t1 {
                    return l1
                }
                
                return l2
            }
            
            var row = 0
            
            if closest != nil {
                row = lessons.firstIndex(of: closest!) ?? 0
                print("scrolling to \(closest!.day) - \(closest!.startTime.string()!)")
            }
            
            // Scroll to the lesson
            collectionView.scrollToItem(at: IndexPath(row: row, section: section), at: .top, animated: animated)
        }else {
            if !week.isEmpty {
                scrollTo(day: day.rotatingNext(), time: Time.zero, animated)
            }
        }
    }
    
    private func indexPath(for lesson: Lesson) -> IndexPath? {
        var dayIndex: Int?
        var day: Day?
        var row: Int?
        
        for (index, item) in weekDays.enumerated() {
            if item == lesson.day {
                day = item
                dayIndex = index
            }
        }
        
        if day == nil {
            return nil
        }
        
        guard let d = day, let lessons = week[d] else {
            return nil
        }
        
        for (index, l) in lessons.enumerated() {
            if l.id == lesson.id {
                row = index
            }
        }
        
        if let r = row, let d = dayIndex {
            return IndexPath(row: r, section: d)
        }
        
        return nil
    }
    
    /// Returns the lesson for a given uuid
    /// - Parameter uuid: UUID of the lesson
    /// - Returns: Lesson with the given uuid. Nil if lesson does not exist in lessons list.
    private func lesson(for uuid: UUID) -> Lesson? {
        return lessons.filter { return $0.id == uuid }.first
    }
    
    //MARK: lesson(for: )
    private func lesson(for indexPath: IndexPath) -> Lesson? {
        return week[weekDays[indexPath.section]]?[indexPath.row]
    }
    
    private func lessons(for day: Day) -> [Lesson]? {
        return week[day]
    }
    
    private func lessons(for section: Int) -> [Lesson]? {
        return week[weekDays[section]]
    }
    
    //MARK: UICollectionViewDataSource
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return week.keys.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return week[weekDays[section]]?.count ?? 0
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: homeLessonCell, for: indexPath) as! HomeWeekLessonCollectionViewCell
        
        cell.lesson = lesson(for: indexPath)
        cell.tasksImage.isHidden = true
        cell.tasksLabel.isHidden = true
        
        return cell
    }
    
    //MARK: supplementaryView
    override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        
        if kind == UICollectionView.elementKindSectionHeader {
            let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "homeHeader", for: indexPath) as! HomeCollectionViewHeader
            
            header.label.text = lesson(for: indexPath)?.day.string()
            
            return header
        }
        
        return UICollectionReusableView()
    }
    
    //MARK: sizeForItemAt
    override func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        guard let lesson = self.lesson(for: indexPath) else {
            return .zero
        }
        
        let height = heightRelativeToDuration(of: lesson)
        
        return CGSize(width: collectionView.frame.width - 2 * 20, height: height)
    }
    
    //MARK: sizeForHeaderInSection
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return CGSize(width: collectionView.frame.width, height: 40)
    }
    
    
    private func presentDetail(_ lessons: [Lesson]?, _ indexPath: IndexPath) {
        if let lesson = lessons?[indexPath.row] {
            homeDelegate?.lessonDetail(self.collectionView, for: lesson)
        }
    }
    
    //MARK: didSelectItemAt
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        presentDetail(lessons(for: indexPath.section), indexPath)
        
    }
    
    override func collectionView(_ collectionView: UICollectionView, contextMenuConfigurationForItemAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        
        let lesson = self.lesson(for: indexPath)
        
        guard let uuid = lesson?.id else {
            return nil
        }
        
        let config = UIContextMenuConfiguration(identifier: uuid as NSUUID, previewProvider: { () -> UIViewController? in
            
            let lessonDetail = LessonEditViewWrapper()
            
            lessonDetail.lesson = lesson
            
            return lessonDetail
        }) { (elements) -> UIMenu? in
            
            let delete = UIAction(title: "Delete", image: UIImage(systemName: "trash")) { (action) in
                
                guard let lesson = self.lesson(for: indexPath) else {
                    return
                }
                
                TimetableService.shared.deleteLesson(lesson)
                
                self.homeDelegate?.lessonDidDelete(self.collectionView, lesson: lesson)
                
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
            guard let lesson = self.lesson(for: id) else {
                return
            }
            
            self.homeDelegate?.lessonDetail(self.collectionView, for: lesson)
        }
        
    }
    
    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        homeDelegate?.didScroll(scrollView)
    }
    
}
 
//MARK: HomeWeekLessonCollectionViewCell
class HomeWeekLessonCollectionViewCell: HomeLessonCollectionViewCell {
    
    override func reload() {
        
        if let lesson = lesson, Time.between(lesson.startTime, Time.now, t3: lesson.endTime), lesson.day.isToday() {
            
            name.text = lesson.subject?.name
            
            name.textColor = .white
            
            name.sizeToFit()
            
            time.text = "\(lesson.day.string()) - \(lesson.startTime.string() ?? "") - \(lesson.endTime.string() ?? "")"
            
            time.textColor = .white
            
            let color: UIColor? = UIColor(named: lesson.subject?.color ?? "dark") ?? UIColor(named: "dark")

            colorIndicator.backgroundColor = .white
            
            tasksLabel.textColor = .white
            tasksImage.tintColor = .white
            backgroundColor = color
            return
        }
        name.textColor = .white
        time.textColor = .white
        tasksLabel.textColor = .white
        tasksImage.tintColor = .white
        backgroundColor = .secondarySystemGroupedBackground
        super.reload()
    }
    
}


extension HomeWeekCollectionView: UICollectionViewDragDelegate {
    
    func collectionView(_ collectionView: UICollectionView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
        guard let item = lesson(for: indexPath) else {
            return []
        }
        
        guard let id = (item.id?.uuidString ?? "") else {
            return []
        }
        
        let itemProvider = NSItemProvider(object: id as NSString)
        
        let dragItem = UIDragItem(itemProvider: itemProvider)
        dragItem.localObject = item
        return [dragItem]
    }
    
}

extension HomeWeekCollectionView: UICollectionViewDropDelegate {
    
    func reorderItems(coordinator: UICollectionViewDropCoordinator, destination: IndexPath, _ collectionView: UICollectionView) {
        guard let dragItem = coordinator.items.first,
              let first = dragItem.dragItem.localObject as? Lesson,
              let source = indexPath(for: first) else {
            return
        }
        
        collectionView.performBatchUpdates ({
            let day = weekDays[source.section]
            let destDay = weekDays[destination.section]
            week[day]?.remove(at: source.row)
            week[destDay]?.insert(first, at: destination.item)
            
            collectionView.deleteItems(at: [source])
            collectionView.insertItems(at: [destination])
        }, completion: nil)
        collectionView.reloadData()
        
        coordinator.drop(dragItem.dragItem, toItemAt: destination)

    }
    
    
    func collectionView(_ collectionView: UICollectionView, performDropWith coordinator: UICollectionViewDropCoordinator) {
        
        var destinationIndexPath: IndexPath
        
        if let indexPath = coordinator.destinationIndexPath {
            destinationIndexPath = indexPath
        }else {
            destinationIndexPath = IndexPath(row: 1, section: 0)
        }
        
        if coordinator.proposal.operation == .move {
            reorderItems(coordinator: coordinator, destination: destinationIndexPath, collectionView)
        }
        
    }
    
    func collectionView(_ collectionView: UICollectionView, dropSessionDidUpdate session: UIDropSession, withDestinationIndexPath destinationIndexPath: IndexPath?) -> UICollectionViewDropProposal {
        if collectionView.hasActiveDrag {
            return UICollectionViewDropProposal(operation: .move, intent: .insertAtDestinationIndexPath)
        }
        return UICollectionViewDropProposal(operation: .forbidden)
    }
    
    
}
