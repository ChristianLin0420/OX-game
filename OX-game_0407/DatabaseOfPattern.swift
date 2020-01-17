//
//  DatabaseOfPattern.swift
//  OX-game_0407
//
//  Created by Christian Lin on 2019/4/19.
//  Copyright © 2019 Christian Lin. All rights reserved.
//

import Foundation
import CoreData
import UIKit

class DatabaseOfPattern {
    
    let PatternInfoVC = PatternInfoViewController()
    
    // UserDefaults to store how many patterns stored in Coredata
    var PatternsUD = UserDefaults.standard
    var patterns_amount = 0
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    
    // Highest scores patterns
    let highest_score_patterns = [[5, 0, 0, 2, 9010],  // positive integer : nought
                                 [0, 5, 0, 5, 9010],   // [A1, A2, A3, next, score]
                                 [0, 0, 5, 8, 9010],
                                 [11, 0, 0, 1, 9010],
                                 [0, 11, 0, 4, 9010],
                                 [0, 0, 11, 7, 9010],
                                 [12, 0, 0, 0, 9010],
                                 [0, 12, 0, 3, 9010],
                                 [0, 0, 12, 6, 9010],
                                 [2, 2, 0, 6, 9010],
                                 [2, 0, 2, 3, 9010],
                                 [0, 2, 2, 0, 9010],
                                 [3, 3, 0, 7, 9010],
                                 [3, 0, 3, 4, 9010],
                                 [0, 3, 3, 1, 9010],
                                 [9, 9, 0, 8, 9010],
                                 [9, 0, 9, 5, 9010],
                                 [0, 9, 9, 2, 9010],
                                 [2, 3, 0, 8, 9010],
                                 [2, 0, 9, 4, 9010],
                                 [0, 3, 9, 0, 9010],
                                 [9, 3, 0, 6, 9010],
                                 [9, 0, 2, 4, 9010],
                                 [0, 3, 2, 2, 9010],
                                 [-5, 0, 0, 2, 9005],  // negative iteger : cross
                                 [0, -5, 0, 5, 9005],
                                 [0, 0, -5, 8, 9005],
                                 [-11, 0, 0, 1, 9005],
                                 [0, -11, 0, 4, 9005],
                                 [0, 0, -11, 7, 9005],
                                 [-12, 0, 0, 0, 9005],
                                 [0, -12, 0, 3, 9005],
                                 [0, 0, -12, 6, 9005],
                                 [-2, -2, 0, 6, 9005],
                                 [-2, 0, -2, 3, 9005],
                                 [0, -2, -2, 0, 9005],
                                 [-3, -3, 0, 7, 9005],
                                 [-3, 0, -3, 4, 9005],
                                 [0, -3, -3, 1, 9005],
                                 [-9, -9, 0, 8, 9005],
                                 [-9, 0, -9, 5, 9005],
                                 [0, -9, -9, 2, 9005],
                                 [-2, -3, 0, 8, 9005],
                                 [-2, 0, -9, 4, 9005],
                                 [0, -3, -9, 0, 9005],
                                 [-9, -3, 0, 6, 9005],
                                 [-9, 0, -2, 4, 9005],
                                 [0, -3, -2, 2, 9005]]
    let defualt_max_score = 9000
    let defualt_rule_patterns_amount = 48

    // Turn pattern array into string
    func patternArrayToString(pattern_array: [Int]) -> String {
        var result_string = ""
        
        for i in 0...pattern_array.count - 1 {
            var buffer_temp: String = ""
            if i != 4 {
                if (pattern_array[i] < 10 && pattern_array[i] > 0) { buffer_temp = String(format:"0%1d",pattern_array[i]) }
                else if (pattern_array[i] >= 10 && pattern_array[i] < 15) { buffer_temp = String(format:"%2d",pattern_array[i]) }
                else if (pattern_array[i] < 0 ) { buffer_temp = String(format:"%2d",pattern_array[i] + 50) } // negative value becaomes positive
                else if (pattern_array[i] == 0) { buffer_temp = "00" }
            } else if i == 4 {
                if (pattern_array[i] > 0 && pattern_array[i] < 10) { buffer_temp = String(format:"000%1d",pattern_array[i]) }
                else if (pattern_array[i] >= 10 && pattern_array[i] < 100) { buffer_temp = String(format:"00%2d",pattern_array[i]) }
                else if (pattern_array[i] >= 100 && pattern_array[i] < 1000) { buffer_temp = String(format:"0%3d",pattern_array[i]) }
                else if (pattern_array[i] >= 1000) { buffer_temp = String(format:"%4d",pattern_array[i]) }
            }
            
            result_string = result_string + buffer_temp
        }
                
        return result_string
    }
    
    // Store patterns
    func storePatterns(pattern: [Int]) {
        
        let managedContext = appDelegate.persistentContainer.viewContext
        let entity = NSEntityDescription.entity(forEntityName: "Pattern", in: managedContext)!
        let pattern_info = NSManagedObject(entity: entity, insertInto: managedContext)
        let pattern_string = patternArrayToString(pattern_array: pattern)
        
        if let amount = PatternsUD.object(forKey: "pattern_amount") {
            patterns_amount = amount as! Int
        } else {
            patterns_amount = 0
        }
        
        //print("pattern_array_count = \(patterns_amount)")
        
        pattern_info.setValue(pattern_string, forKey: "pattern_array")
        
        PatternsUD.set(patterns_amount + 1, forKey: "pattern_amount")
        PatternsUD.synchronize()
        
        do {
            try managedContext.save()
            PatternInfoVC.pattern_arrays.append(pattern_info)
        } catch let error as NSError {
            print("Could not save. \(error), \(error.userInfo)")
        }
    }
}
