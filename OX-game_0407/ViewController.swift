//
//  ViewController.swift
//  OX-game_0407
//
//  Created by Christian Lin on 2019/4/7.
//  Copyright © 2019 Christian Lin. All rights reserved.
//

import UIKit
import CoreData

class ViewController: UIViewController {
    
    // All UI on the mainview controller
    @IBOutlet weak var Start_btn: UIButton!
    @IBOutlet weak var LearnByOwn: UIButton!
    @IBOutlet weak var TeachByUser: UIButton!
    @IBOutlet weak var CheckerBoard: UIImageView!
    @IBOutlet weak var Final_state: UILabel!
    @IBOutlet weak var new_game_btn: UIButton!
    
    // Learning made coefficient
    var LearnOwn = 0
    var LearnUser = 0
    
    // Detect what symbal gonna draw on the CheckerBoard
    var symbal_flag = 0
    var first_man = 0
    
    // CheckerBoard matrix in order to record current CheckerBoard state
    let initial_state = [0,0,0,0,0,0,0,0,0]
    var stateCheckerboard = [0,0,0,0,0,0,0,0,0]
    var original_pattern = [Int]()
    var final_pattern = [Int]()
    var current_column = 0
    var current_row = 0
    var same_cortex = false
    
    // Save the nought and cross images
    var symbals = [UIImageView]()
    var symbals_prediction = [UIImageView]()
    var stop = false
    
    // Learning mode
    let DataCollectVC = DatabaseOfPattern()
    let PatternInfoVC = PatternInfoViewController()
    let Cortex = CortexDetect()
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    var patterns_array = [[Int]]() // To store all patterns, including rules and new patterns from user
    
    // Winning state
    let winning_state = [[0,1,2], [3,4,5], [6,7,8], [0,3,6], [1,4,7], [2,5,8], [0,4,8], [2,4,6]]
    var winnerAppear = 0
    
    // Learning coefficient
    var Learn = false
    var Teach = false
    var next_step = 0
    
    // UserDefaults to store how many patterns stored in Coredata
    var PatternsUD = UserDefaults.standard
    var patterns_array_amount = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //get the current state of replay_or_replace
        if let buffer = PatternsUD.object(forKey: "pattern_amount") {
            patterns_array_amount = buffer as! Int
        } else {
            patterns_array_amount = 0
        }
        
        // Add rules to Coredata
        //print("count = \(patterns_array_amount)")
        if patterns_array_amount == 0 {
            for rule in DataCollectVC.highest_score_patterns {
                DataCollectVC.storePatterns(pattern: rule)
            }
        }
        
        // Preload all patterns in an array
        if PatternInfoVC.pattern_arrays.count == 0 {
            let group = DispatchGroup()
            group.enter()
            
            DispatchQueue.main.async {
                self.ReloadOldData()
                group.leave()
            }
            
            group.notify(queue: .main) {
                self.ReadPatterns()
            }
        }
        
        // Add tap detector on CheckerBoard
        let tap_action = UILongPressGestureRecognizer(target: self, action: #selector(CheckerBoard_tapGesture))
        tap_action.minimumPressDuration = 0
        CheckerBoard.addGestureRecognizer(tap_action)
        CheckerBoard.isUserInteractionEnabled = false
        
        // Timer to detect when the conputer playing
        Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { (timer) in self.randomPlaying()}
        
    }
    
    func showResult() {
        // Print current state and print if it's neccessary
        let state = detectCheckerboardState()
        
        if state == "continue" {
            return
        } else if state == "tie" {
            Final_state.textColor = #colorLiteral(red: 0.4666666687, green: 0.7647058964, blue: 0.2666666806, alpha: 1)
            Final_state.text = "TIE"
            Final_state.isHidden = false
            new_game_btn.isHidden = false
        } else if state == "nought" {
            Final_state.textColor = #colorLiteral(red: 0.01680417731, green: 0.1983509958, blue: 1, alpha: 1)
            Final_state.adjustsFontSizeToFitWidth = true
            Final_state.text = "BLUE WIN"
            Final_state.isHidden = false
            new_game_btn.isHidden = false
            winnerAppear = 1
        } else if state == "cross" {
            Final_state.textColor = #colorLiteral(red: 1, green: 0.1491314173, blue: 0, alpha: 1)
            Final_state.adjustsFontSizeToFitWidth = true
            Final_state.text = "RED WIN"
            Final_state.isHidden = false
            new_game_btn.isHidden = false
            winnerAppear = 1
        }
    }
    
    @objc func CheckerBoard_tapGesture(gesture: UITapGestureRecognizer) {
        
        let cgpoint = gesture.location(in: CheckerBoard)
        let checkerboard_width: Double = Double(CheckerBoard!.frame.size.width)
        let checkerboard_height: Double = Double(CheckerBoard!.frame.size.height)
        
        let touchX: Double = Double(cgpoint.x)
        let touchY: Double = Double(cgpoint.y)
        
        let oneThird_width: Double = Double(checkerboard_width / 3)
        let oneThird_height: Double = Double(checkerboard_height / 3)
        
        if gesture.state == .ended {
            let x_number = Int(touchX / oneThird_width)
            let y_number = Int(touchY / oneThird_height)
            
            //print("x = \(x_number), y = \(y_number)")
            
            next_step = x_number + y_number * 3
            
            //print("next_step = \(next_step)")
            
            if Teach == true && Learn == false { TeachByUser_mode() }
            if Learn == true && Teach == false { LearnFromUser() }
            if Teach == true && Learn == true {
                LearnFromUser()
                TeachByUser_mode()
            }
            
            DrawingSymbals(column: x_number, row: y_number)
            showResult()
        }
    }
    
    // Drawing nought or cross on CheckerBoard
    func DrawingSymbals(column: Int, row: Int) {
        
        if current_row == row && current_column == column { same_cortex = true }
        
        let x = Double(CheckerBoard.frame.size.width) * Double(column) / 3
        let y = Double(CheckerBoard.frame.size.height) * Double(row) / 3
        let symbal_width = CGFloat(CheckerBoard.frame.size.width) / 3
        let symbal_height = CGFloat(CheckerBoard.frame.size.height) / 3
        let checkerboard_x = CheckerBoard.bounds.midX - CGFloat(CheckerBoard.frame.size.width / 2.2)
        let checkerboard_y = CheckerBoard.bounds.midY + CGFloat(CheckerBoard.frame.size.width / 3.5)
        
        var check_exist = true
        
        if stateCheckerboard[column + row * 3] != 0 { check_exist = false }
        
        if (check_exist) {
            if symbal_flag == 0 {
                //record which places has already had a symbal
                stateCheckerboard[column + row * 3] = 1
                
                let image = UIImage(named: "noughts_0")!
                let new_symbal = UIImageView(image: image)
                new_symbal.frame = CGRect(x: CGFloat(x) + checkerboard_x, y: CGFloat(y) + checkerboard_y, width: symbal_width, height: symbal_height)
                symbals.append(new_symbal)
                self.view.addSubview(new_symbal)
                symbal_flag = 1
                stop = false
            } else {
                stateCheckerboard[column + row * 3] = -1
                for image in symbals_prediction { image.removeFromSuperview() }
                let image = UIImage(named: "cross_0")!
                let new_symbal = UIImageView(image: image)
                new_symbal.frame = CGRect(x: CGFloat(x) + checkerboard_x, y: CGFloat(y) + checkerboard_y, width: symbal_width, height: symbal_height)
                symbals.append(new_symbal)
                self.view.addSubview(new_symbal)
                symbal_flag = 0
                stop = false
            }
        }
    }
    
    // Create highest score patternin the coredata
    func FindHighestScorePattern(possible_patterns: [[Int]]) -> [Int] {
        var result_steps = [Int]()
        var highestScore = 0
        
        //print("possible_patterns = \(possible_patterns)")
        
        if possible_patterns.count == 0 { return [] }
        
        for i in 0...possible_patterns.count - 1 {
            if possible_patterns[i][4] > highestScore { highestScore = possible_patterns[i][4] }
        }
        
        for i in 0...possible_patterns.count - 1 {
            if possible_patterns[i][4] == highestScore { result_steps.append(possible_patterns[i][3]) }
        }
        
        print("result_steps = \(result_steps)")
        
        return result_steps
    }
    
    // Show predict symbal
    func showPredictSymbal(column: Int, row: Int, kind: Int) {
        let cross_images = [UIImage(named: "cross_0")!, UIImage(named: "cross_1")!, UIImage(named: "cross_2")!, UIImage(named: "cross_3")!]
        let nought_images = [UIImage(named: "noughts_0")!, UIImage(named: "noughts_1")!, UIImage(named: "noughts_2")!, UIImage(named: "noughts_3")!]
        let images = (kind == 0) ? cross_images : nought_images
        let x = Double(CheckerBoard.frame.size.width) * Double(column) / 3
        let y = Double(CheckerBoard.frame.size.height) * Double(row) / 3
        let symbal_width = CGFloat(CheckerBoard.frame.size.width) / 3
        let symbal_height = CGFloat(CheckerBoard.frame.size.height) / 3
        let checkerboard_x = CheckerBoard.bounds.midX - CGFloat(CheckerBoard.frame.size.width / 2.2)
        let checkerboard_y = CheckerBoard.bounds.midY + CGFloat(CheckerBoard.frame.size.width / 3.5)
        
        let animatedImage = UIImage.animatedImage(with: images, duration: 0.5)
        let new_prdiction_symbal = UIImageView(image: animatedImage)
        new_prdiction_symbal.frame = CGRect(x: CGFloat(x) + checkerboard_x, y: CGFloat(y) + checkerboard_y, width: symbal_width, height: symbal_height)
        symbals_prediction.append(new_prdiction_symbal)
        self.view.addSubview(new_prdiction_symbal)
    }
    
    // Create identity array to coredata to store
    func CreateIdentity(current_board: [Int]) -> [Int] {
        var result_array = [Int]()
        var temp_1 = [Int]()
        var temp_2 = [Int]()
        var temp_3 = [Int]()
        let p_coefficient = [2, 3, 9]
        let n_coefficient = [-2, -3, -9]
        var coefficient = [Int]()
        
        for i in 0...2 { temp_1.append(current_board[i]) }
        for i in 3...5 { temp_2.append(current_board[i]) }
        for i in 6...8 { temp_3.append(current_board[i]) }
        
        var temp_sum = 0
        
        for i in 0...2 {
            coefficient = (temp_1[i] >= 0) ? p_coefficient : n_coefficient
            temp_sum += temp_1[i] * coefficient[i];
            if i == 2 {
                result_array.append(temp_sum)
                temp_sum = 0
            }
        }
        
        for i in 0...2 {
            coefficient = (temp_2[i] >= 0) ? p_coefficient : n_coefficient
            temp_sum += temp_2[i] * coefficient[i];
            if i == 2 {
                result_array.append(temp_sum)
                temp_sum = 0
            }
        }
        
        for i in 0...2 {
            coefficient = (temp_3[i] >= 0) ? p_coefficient : n_coefficient
            temp_sum += temp_3[i] * coefficient[i];
            if i == 2 {
                result_array.append(temp_sum)
                temp_sum = 0
            }
        }
        
        //print("identity array = \(result_array)")
        
        return result_array
    }
    
    // Computer play by random
    func randomPlaying() {
        if symbal_flag == 1 && winnerAppear == 0 && stop == false {
            var oppisiteViewOfCheckboard = [Int]()
            
            for i in stateCheckerboard { oppisiteViewOfCheckboard.append(-i) }
            
            // Input current checkerboard in the cortex detect
            let possible_steps_patterns_0 = Cortex.RuleDetect(input: oppisiteViewOfCheckboard, rule_patterns: patterns_array)
            if possible_steps_patterns_0.count > 0 {
                let temp_possible_steps = FindHighestScorePattern(possible_patterns: possible_steps_patterns_0)
                let next = temp_possible_steps.randomElement()
                if Teach == true { showPredictSymbal(column: next! % 3, row: next! / 3, kind: 0)
                    print("predicting....")
                } else {
                    DrawingSymbals(column: next! % 3, row: next! / 3)
                    showResult()
                }
                stop = true
                return
            }
            
            let possible_steps_patterns_1 = Cortex.RuleDetect(input: stateCheckerboard, rule_patterns: patterns_array)
            let final_possible_steps = FindHighestScorePattern(possible_patterns: possible_steps_patterns_1)
            
            // Check the next step exist or not, if yes then continue using next step, if no then using random to decide next step
            if final_possible_steps.count != 0 {
                let next = final_possible_steps.randomElement()
                DrawingSymbals(column: next! % 3, row: next! / 3)
                showResult()
                return
            }
            
            var randomArray = [Int]()
            
            for index in 0...8 {
                if stateCheckerboard[index] == 0 { randomArray.append(index) }
            }
            
            if randomArray.count == 0 { return }
            
            let randomNumber = randomArray.randomElement()
            let column = randomNumber! % 3
            let row = randomNumber! / 3

            //original_pattern = CreateIdentity(current_board: stateCheckerboard)
            
            current_column = column
            current_row = row
            
            if Teach == true { showPredictSymbal(column: column, row: row, kind: 0) }
            else {
                DrawingSymbals(column: column, row: row)
                showResult()
            }
            
            stop = true
        }
    }
    
    // Detect current state on the board
    func detectCheckerboardState() -> String {
        var notSymbalAmount = 0
        var winner = 0
        
        for i in stateCheckerboard {
            if i != 0 { notSymbalAmount += 1 }
        }
        
        // condition2: one Winner(nought or cross)
        for state in winning_state {
            if stateCheckerboard[state[0]] == stateCheckerboard[state[1]] && stateCheckerboard[state[1]] == stateCheckerboard[state[2]] && stateCheckerboard[state[0]] != 0 {
                winner = stateCheckerboard[state[1]]
                break
            }
        }
        
        if winner == 1 { return "nought" }
        if winner == -1 { return "cross" }
        
        if notSymbalAmount == 9 { return "tie" }
        
        return "continue"
    }

    func resetAllValue() {
        stateCheckerboard = initial_state
        if first_man == 0 { symbal_flag = 0 }
        else if first_man == 1 { symbal_flag = 1 }
        print("first man = \(symbal_flag)")
        winnerAppear = 0
        Final_state.isHidden = true
        new_game_btn.isHidden = true
        
        // Clear all images on view
        for image in symbals { image.removeFromSuperview() }
        for image in symbals_prediction { image.removeFromSuperview() }
    }
    
    func ReloadOldData() {
        let managedContext = appDelegate.persistentContainer.viewContext
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Pattern")
        
        do {
            PatternInfoVC.pattern_arrays = try managedContext.fetch(fetchRequest)
        } catch {
            print("Reload data failed!!!")
        }
    }
    
    // Read the point and rank of the pattern which exists in the Coredata
    func ReadPatterns() {
        let managedContext = appDelegate.persistentContainer.viewContext
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Pattern")
                
        var pattern_string = [String]()
        var pattern_int = [[Int]]()
        var pattern_int_buffer = [Int]()
        
        if PatternInfoVC.pattern_arrays.count == 0 { return }
        
        for index in 0...PatternInfoVC.pattern_arrays.count - 1 {
            do {
                let result = try managedContext.fetch(fetchRequest) as! [NSManagedObject]
                let patterns = result[index].value(forKey: "pattern_array") as! String
                
                if (patterns.count > 0) {
                    var data: String = ""
                    for i in 0...(patterns.count / 12 - 1) {
                        let lowerBound = patterns.index(patterns.startIndex, offsetBy: i * 12)
                        let upperBound = patterns.index(patterns.startIndex, offsetBy: i * 12 + 12)
                        data = String(patterns[lowerBound..<upperBound])
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
                pattern_int.append(pattern_int_buffer)
                pattern_string.removeAll()
                pattern_int_buffer.removeAll()
            } catch {
                print(error)
            }
        }
        patterns_array = pattern_int
        //print("patterns_array = \(patterns_array)")
    }
    
    // User will teach the computer
    func TeachByUser_mode() {
        if symbal_flag == 1 {
            var oppositeCheckerboard = [Int]()
            for i in stateCheckerboard { oppositeCheckerboard.append(-i) }
            var identity_array_buffer = Cortex.ScanBoard(current_board: oppositeCheckerboard) // Return first three value (cross)
            
            identity_array_buffer.append(next_step) // Add solution
            print("identity array buffer = \(identity_array_buffer)")
            
            let check = Cortex.CheckCortex(input: identity_array_buffer, cortex_data: patterns_array)
            print("check = \(check)")
            
            if check > -1 {
                Cortex.ChangeScore(cortex: identity_array_buffer, replace_numb: check)
            } else {
                Cortex.CtreatCortex(new_cortex: identity_array_buffer)
            }
        }
    }
    
    // Computer will obsearve user's strategy
    func LearnFromUser() {
        if symbal_flag == 0 {
            var identity_array_buffer = Cortex.ScanBoard(current_board: stateCheckerboard) // Return first three value (cross)
            
            identity_array_buffer.append(next_step) // Add solution
            print("identity array buffer = \(identity_array_buffer)")
                        
            let check = Cortex.CheckCortex(input: identity_array_buffer, cortex_data: patterns_array)
            print("check = \(check)")
            
            if check > -1 {
                Cortex.ChangeScore(cortex: identity_array_buffer, replace_numb: check)
            } else {
                Cortex.CtreatCortex(new_cortex: identity_array_buffer)
            }
        }
    }
    
    // Start button
    @IBAction func StartGame(_ sender: Any) {
        Start_btn.isHidden = true
        LearnByOwn.isEnabled = true
        TeachByUser.isEnabled = true
        CheckerBoard.isUserInteractionEnabled = true
    }
    
    // Learning mode buttons functions
    @IBAction func LearnByOwn_mode(_ sender: Any) {
        if LearnOwn == 0 {
            LearnByOwn.setImage(UIImage(named: "LearningByOwn_on"), for: .normal)
            Learn = true
            LearnOwn = 1
        } else {
            LearnByOwn.setImage(UIImage(named: "LearningByOwn_off"), for: .normal)
            Learn = false
            LearnOwn = 0
        }
    }
    
    @IBAction func TeachByUser_mode(_ sender: Any) {
        if LearnUser == 0 {
            TeachByUser.setImage(UIImage(named: "LearningByUser_on"), for: .normal)
            Teach = true
            LearnUser = 1
        } else {
            TeachByUser.setImage(UIImage(named: "LearningByUser_off"), for: .normal)
            Teach = false
            LearnUser = 0
        }
    }
    
    @IBAction func Start_New_Game(_ sender: Any) {
        print("-------------------RESET---------------------")
        if first_man == 0 { first_man = 1 }
        else if first_man == 1 { first_man = 0 }
        resetAllValue()
    }
    
    @IBAction func delete_all_data(_ sender: UIButton) {
        
        if PatternInfoVC.pattern_arrays.count == 48 {
            print(patterns_array)
            return
        }
        
        PatternsUD.set(0, forKey: "pattern_amount")
        PatternsUD.synchronize()
        
        if PatternInfoVC.pattern_arrays.count == 0 { return }
        
        print("datacount = \(PatternInfoVC.pattern_arrays.count)")
        
        for i in 48...PatternInfoVC.pattern_arrays.count - 1 {

            let managedContext = appDelegate.persistentContainer.viewContext
            managedContext.delete(PatternInfoVC.pattern_arrays[i])

            do {
                try managedContext.save()
                PatternInfoVC.pattern_arrays.remove(at: i)
            } catch {
                print("delete is fail")
            }
        }
        
    }
    
}

