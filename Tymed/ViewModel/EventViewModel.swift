//
//  EventViewModel.swift
//  Tymed
//
//  Created by Jonah Schueller on 06.10.20.
//  Copyright © 2020 Jonah Schueller. All rights reserved.
//

import SwiftUI
import EventKit

class EventViewModel: ObservableObject {
    
    private(set) var event: EKEvent
    
    @Published
    var title: String! {
        didSet {
            event.title = title
        }
    }
    
    @Published
    var startDate: Date! {
        didSet {
            event.startDate = startDate
        }
    }
    
    @Published
    var endDate: Date! {
        didSet {
            event.endDate = endDate
        }
    }
    
    @Published
    var isAllDay: Bool = false {
        didSet {
            event.isAllDay = isAllDay
        }
    }
    
    @Published
    var calendar: EKCalendar! {
        didSet {
            event.calendar = calendar
        }
    }
    
    @Published
    var recurrenceRules: [EKRecurrenceRule]? {
        didSet {
            event.recurrenceRules = recurrenceRules
        }
    }
    
    
    var isNew: Bool {
        return event.isNew
    }
    
    var hasChanges: Bool {
        return event.hasChanges
    }
    
    init(_ event: EKEvent){
        self.event = event
        
        refresh()
    }
    
    func rollback() {
        event.rollback()
    }
    
    func save(_ span: EKSpan = .futureEvents) {
        EventService.shared.save(event, span: span)
    }
    
    func refresh() {
        event.refresh()
        
        title = event.title
        startDate = event.startDate
        endDate = event.endDate
        isAllDay = event.isAllDay
        calendar = event.calendar
        recurrenceRules = event.recurrenceRules
    }
    
}
