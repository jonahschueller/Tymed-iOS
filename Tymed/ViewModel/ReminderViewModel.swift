//
//  ReminderViewModel.swift
//  Tymed
//
//  Created by Jonah Schueller on 25.10.20.
//  Copyright © 2020 Jonah Schueller. All rights reserved.
//

import Foundation
import EventKit
import UIKit

class ReminderViewModel: ObservableObject {
    
    private(set) var reminder: EKReminder
    
    @Published var title: String! {
        didSet { reminder.title = title }
    }
    
    @Published var dueDateComponents: DateComponents? {
        didSet { reminder.dueDateComponents = dueDateComponents }
    }
    
    @Published var isCompleted: Bool = false {
        didSet { reminder.isCompleted = isCompleted }
    }
    
    @Published var completionDate: Date? {
        didSet { reminder.completionDate = completionDate }
    }
    
    @Published var calendar: EKCalendar! {
        didSet { reminder.calendar = calendar }
    }
    
    @Published var notes: String? {
        didSet { reminder.notes = notes }
    }
    
    @Published var url: URL? {
        didSet { reminder.url = url }
    }
    
    var isNew: Bool {
        reminder.isNew
    }
    
    var hasChanges: Bool {
        reminder.hasChanges
    }
    
    var hasNotes: Bool {
        reminder.hasNotes
    }
    
    var hasAlarms: Bool {
        reminder.hasAlarms
    }
    
    
    init(_ reminder: EKReminder) {
        self.reminder = reminder
        
        refresh()
    }
    
    func refresh() {
        reminder.refresh()
        
        title = reminder.title
        dueDateComponents = reminder.dueDateComponents
        isCompleted = reminder.isCompleted
        completionDate = reminder.completionDate
        calendar = reminder.calendar
        notes = reminder.notes
        url = reminder.url
        calendar = reminder.calendar
        
    }
    
    func isDue() -> Bool {
        if isCompleted {
            return false
        }
        
        guard let components = reminder.dueDateComponents,
              let date = Calendar.current.date(from: components) else {
            return false
        }
        
        // Decide weather the reminder is due on a day or time
        var granularity: Calendar.Component = .day
        
        if components.hour != nil && components.minute != nil {
            granularity = .minute
        }
        
        return Calendar.current.compare(date, to: Date(), toGranularity: granularity) == ComparisonResult.orderedAscending
    }
    
    func dueDate() -> Date? {
        guard let components = reminder.dueDateComponents else {
            return nil
        }
        
        return Calendar.current.date(from: components)
    }
    
    /// - Returns: Returns a systemImage for the completion state of the reminder
    func iconForCompletion() -> String {
        if isCompleted {
            return "checkmark.circle.fill"
        }else if dueDateComponents == nil {
            return "circle"
        } else if dueDateComponents != nil  && dueDate()! < Date() {
            return "exclamationmark.circle.fill"
        }
        // Default case
        return "circle"
    }
    
    /// - Returns: Returns a color for the completion state of the reminder.
    func completeColor() -> UIColor {
        if isCompleted {
            if dueDateComponents == nil || completionDate ?? Date() <= dueDate() ?? Date() {
                return .systemGreen
            }else {
                return .systemOrange
            }
        }else {
            if dueDateComponents == nil || Date() <= dueDate() ?? Date() {
                return .systemBlue
            }else {
                return .systemRed
            }
        }
    }
}
