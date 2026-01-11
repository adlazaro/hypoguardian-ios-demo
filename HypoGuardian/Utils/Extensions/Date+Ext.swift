//
//  Date+Ext.swift
//  HypoGuardian
//
//  Created by Adrian Lazaro on 28/10/24.
//

import Foundation

extension Date {
    
    //Returns a Date() object 14 years ago
    var fourteenYearsAgo: Date {
        Calendar.current.date(byAdding: .year, value: -14, to: Date())!
    }
    
    //Returns a Date() object 100 years ago
    var oneHundredYearsAgo: Date {
        Calendar.current.date(byAdding: .year, value: -100, to: Date())!
    }
    
    static func customStartOfDay(for date: Date) -> Date {
        Calendar.current.startOfDay(for: date)
    }
    
    static func customEndOfDay(for date: Date) -> Date {
        Calendar.current.date(byAdding: DateComponents(day: 1, second: -1), to: Calendar.current.startOfDay(for: date))!
    }
}
