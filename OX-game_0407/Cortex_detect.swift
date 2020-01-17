//
//  Cortex_detect.swift
//  OX-game_0407
//
//  Created by Christian Lin on 2019/5/16.
//  Copyright © 2019 Christian Lin. All rights reserved.
//

import Foundation
import CoreData
import UIKit

class CortexDetect {
    
    // first index represents diffirent patter
    let patterns_identity = [[2, 1, 0, 0],
                             [3, 0, 1, 0],
                             [9, 0, 0, 1],
                             [5, 1, 1, 0],
                             [11, 1, 0, 1],
                             [12, 0, 1, 1],
                             [14, 1, 1, 1],
                             [1, -1, 1, 0],
                             [7, -1, 0 , 1],
                             [6, 0, -1, 1],
                             [4, -1, -1, 1],
                             [8, 1, -1, 1],
                             [10, -1, 1, 1],
                             [0, 0, 0, 0]]
    
    // database coefficient
    let PatternsUD = UserDefaults.standard
    let DatabaseVC = DatabaseOfPattern()
    let PatternInfoVC = PatternInfoViewController()
    var patterns_amount = 0
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    
    // Scan the Checkerboard and record the current state and convert to specific pattern
    func ScanBoard(current_board: [Int]) -> [Int] {
        var result_board_buffer = [Int]()
        var result_board = [0, 0, 0]
        
        for i in 0...current_board.count - 1 {
            if i % 3 == 0 {
                if current_board[i] == 1 { result_board_buffer.append(2) }
                else if current_board[i] == -1 { result_board_buffer.append(-2) }
                else { result_board_buffer.append(0) }
            } else if i % 3 == 1 {
                if current_board[i] == 1 { result_board_buffer.append(3) }
                else  if current_board[i] == -1 { result_board_buffer.append(-3) }
                else { result_board_buffer.append(0) }
            } else {
                if current_board[i] == 1 { result_board_buffer.append(9) }
                else if current_board[i] == -1 { result_board_buffer.append(-9) }
                else { result_board_buffer.append(0) }
            }
        }
        
        print("result_board_buffer = \(result_board_buffer)")
        
        result_board[0] = result_board_buffer[0] + result_board_buffer[1] + result_board_buffer[2]
        result_board[1] = result_board_buffer[3] + result_board_buffer[4] + result_board_buffer[5]
        result_board[2] = result_board_buffer[6] + result_board_buffer[7] + result_board_buffer[8]

        print("result_board = \(result_board)")
        
        return result_board
    }
    
    // Convert pattern info into identity array
    func ConvertInfoToIdentity(pattern: [Int]) -> [Int] {
        var result_array = [Int]()
        
        for i in 0...pattern.count - 1 {
            for j in 0...patterns_identity.count - 1 {
                if pattern[i] == patterns_identity[j][0] {
                    result_array.append(patterns_identity[j][1])
                    result_array.append(patterns_identity[j][2])
                    result_array.append(patterns_identity[j][3])
                    break
                } else if pattern[i] == -patterns_identity[j][0] {
                    result_array.append(-patterns_identity[j][1])
                    result_array.append(-patterns_identity[j][2])
                    result_array.append(-patterns_identity[j][3])
                }
            }
        }
        return result_array
    }
    
    // Highest score patterns detect
    func RuleDetect(input: [Int], rule_patterns: [[Int]]) -> [[Int]] {
        var buffer = [Int]()
        var possible_step_patterns = [[Int]]()
        
        // Rule detect
        for i in 0...DatabaseVC.defualt_rule_patterns_amount - 1 {
            buffer.append(rule_patterns[i][0])
            buffer.append(rule_patterns[i][1])
            buffer.append(rule_patterns[i][2])
            
            let cortex_numb = ConvertInfoToIdentity(pattern: buffer)
            var corresponding_amount = 0
            //print("cortex_numb = \(cortex_numb)")
                        
            for j in 0...8 {
                if cortex_numb[j] != 0, cortex_numb[j] == input[j] { corresponding_amount += 1 }
                if corresponding_amount == 2 {
                    if input[rule_patterns[i][3]] == 0 {
                        buffer.removeAll()
                        //print("next step is \(pattern)")
                        possible_step_patterns.append(rule_patterns[i])
                        break
                    }
                }
            }
            buffer.removeAll()
        }
        
        // Learning pattern detect
        if rule_patterns.count > 48 {
            for i in DatabaseVC.defualt_rule_patterns_amount...rule_patterns.count - 1 {
                buffer.append(rule_patterns[i][0])
                buffer.append(rule_patterns[i][1])
                buffer.append(rule_patterns[i][2])
                
                let cortex_numb = ConvertInfoToIdentity(pattern: buffer)
                var corresponding_amount = 0
                //print("cortex_numb = \(cortex_numb)")
                
                for j in 0...8 {
                    if cortex_numb[j] == input[j] { corresponding_amount += 1 }
                    if corresponding_amount == 9 {
                        if input[rule_patterns[i][3]] == 0 {
                            buffer.removeAll()
                            //print("next step is \(pattern)")
                            possible_step_patterns.append(rule_patterns[i])
                            break
                        }
                    }
                }
                buffer.removeAll()
            }
        }
        print("possible_step_patterns = \(possible_step_patterns)")
        return possible_step_patterns // Corresponding pattern return positive int, no corresponding pattern return -1
    }
    
    // Check whether current pattern exists in the cortex, if yes then choose highest score pattern, if no , then create new cortex
    func CheckCortex(input: [Int], cortex_data: [[Int]]) -> Int {
        for i in 0...cortex_data.count - 1 {
            var same = 0
            for j in 0...3 {
                if input[j] == cortex_data[i][j] { same += 1 }
                else if input[j] != cortex_data[i][j] { break }
                if same == 4 { return i }
            }
        }
        return -1 // no corresponding cortex
    }
    
    // Add score if the cortex has stored in the coredata
    func ChangeScore(cortex: [Int], replace_numb: Int) {
        var pattern_string = [String]()
        var pattern_int_buffer = [Int]()
        
        let managedContext = appDelegate.persistentContainer.viewContext
        let fetchRequest_cortex = NSFetchRequest<NSFetchRequestResult>(entityName: "Pattern")
        
        do {
            var result = try managedContext.fetch(fetchRequest_cortex) as! [NSManagedObject]
            let pattern = result[replace_numb].value(forKey: "pattern_array") as! String
            
            if (pattern.count > 0) {
                var data: String = ""
                for i in 0...(pattern.count / 12 - 1) {
                    let lowerBound = pattern.index(pattern.startIndex, offsetBy: i * 12)
                    let upperBound = pattern.index(pattern.startIndex, offsetBy: i * 12 + 12)
                    data = String(pattern[lowerBound..<upperBound])
                    pattern_string.append(data)
                }
            }
            
            for i in 0...pattern_string.count - 1 {
                var data: String = ""
                for j in 0...pattern_string[i].count / 2 - 1 {
                    let lowerBound = pattern_string[i].index(pattern_string[i].startIndex, offsetBy: j * 2)
                    let upperBound = pattern_string[i].index(pattern_string[i].startIndex, offsetBy: j * 2 + 2)
                    data = String(pattern_string[i][lowerBound..<upperBound])
                    pattern_int_buffer.append(Int(data)!)
                }
                
                // Handle score part
                for i in 0...2 {
                    if pattern_int_buffer[i] > 14 { pattern_int_buffer[i] -= 50 }
                }
                
                // Handle score
                pattern_int_buffer[4] = pattern_int_buffer[4] * 100 + pattern_int_buffer[5]
                pattern_int_buffer.remove(at: 5)
            }
        } catch {
            print("fetch dat failed while changing score")
        }
        
        //print("replace numb = \(replace_numb)")
        
        print("cortex before add score = \(pattern_int_buffer)")
        if pattern_int_buffer[4] < DatabaseVC.defualt_max_score && replace_numb >= DatabaseVC.defualt_rule_patterns_amount { pattern_int_buffer[4] = pattern_int_buffer[4] + 1 }
        print("cortex after add score = \(pattern_int_buffer)")
        
        let cortex_string = DatabaseVC.patternArrayToString(pattern_array: pattern_int_buffer)
        //print("new cortex string = \(cortex_string)")
        
        do {
            let result_cortex = try managedContext.fetch(fetchRequest_cortex) as? [NSManagedObject]
            result_cortex![replace_numb].setValue(cortex_string, forKey: "pattern_array")
        } catch {
            print("replace new score action failed!!!")
        }
        
        do {
            try managedContext.save()
        } catch {
            print("new score action failed!!")
        }
    }
    
    // Create new cortex
    func CtreatCortex(new_cortex: [Int]) {
        var cortex = new_cortex
        let managedContext = appDelegate.persistentContainer.viewContext
        let entity = NSEntityDescription.entity(forEntityName: "Pattern", in: managedContext)!
        let pattern_info = NSManagedObject(entity: entity, insertInto: managedContext)
        cortex.append(1)  // Add score in the new cortex
        let patternString = DatabaseVC.patternArrayToString(pattern_array: cortex)
        
        if let amount = PatternsUD.object(forKey: "pattern_amount") {
            patterns_amount = amount as! Int
        } else {
            patterns_amount = 0
        }
        
        print("patternString = \(patternString)")
        
        pattern_info.setValue(patternString, forKey: "pattern_array")
        PatternsUD.setValue(patterns_amount + 1, forKey: "pattern_amount")
        PatternsUD.synchronize()
        
        do {
            try managedContext.save()
            PatternInfoVC.pattern_arrays.append(pattern_info)
        } catch let error as NSError {
            print(error)
        }
    }
}
