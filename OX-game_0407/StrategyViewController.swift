//
//  StrategyViewController.swift
//  OX-game_0407
//
//  Created by Christian on 2019/5/23.
//  Copyright © 2019 Christian Lin. All rights reserved.
//

import UIKit

class StrategyViewController: UIViewController {

    // UI
    @IBOutlet weak var pattern_number: UILabel!
    @IBOutlet weak var pattern_point: UILabel!
    @IBOutlet weak var checkboard: UIImageView!
    
    // UserDefaults
    var PatternsUD = UserDefaults.standard
    var pattern_numb = ""
    var pattern_score = ""
    
    // Save the nought and cross images
    var symbals = [UIImageView]()
    var symbals_prediction = [UIImageView]()
    
    // Identity coefficient
    let Cortex = CortexDetect()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let buffer = PatternsUD.object(forKey: "pattern_string") {
            pattern_numb = buffer as! String
        } else {
            pattern_numb = ""
        }
        
        let pattern_array = CreatePatternArray(pattern_string: pattern_numb)
        
        pattern_number.text = "Number: \(pattern_numb)"
        pattern_point.text = "Point: \(pattern_array[4])"
        
        CurrentBoardState(pattern_array: pattern_array)
        ShowNextStep(column: pattern_array[3] % 3, row: pattern_array[3] / 3)
        
    }
    
    // Convert Pattern Info to array
    func CreatePatternArray(pattern_string: String) -> [Int] {
        var result_array = [Int]()
        var pattern_string_buffer = [String]()
        
        if (pattern_string.count > 0) {
            var data: String = ""
            for i in 0...(pattern_string.count / 12 - 1) {
                let lowerBound = pattern_string.index(pattern_string.startIndex, offsetBy: i * 12)
                let upperBound = pattern_string.index(pattern_string.startIndex, offsetBy: i * 12 + 12)
                data = String(pattern_string[lowerBound..<upperBound])
                pattern_string_buffer.append(data)
            }
        }
        
        for i in 0...pattern_string_buffer.count - 1 {
            var data: String = ""
            for j in 0...pattern_string_buffer[i].count / 2 - 1 {
                let lowerBound = pattern_string_buffer[i].index(pattern_string_buffer[i].startIndex, offsetBy: j * 2)
                let upperBound = pattern_string_buffer[i].index(pattern_string_buffer[i].startIndex, offsetBy: j * 2 + 2)
                data = String(pattern_string_buffer[i][lowerBound..<upperBound])
                result_array.append(Int(data)!)
            }
            
            // Handle score part
            for i in 0...2 {
                if result_array[i] > 14 { result_array[i] -= 50 }
            }
            
            // Handle score
            result_array[4] = result_array[4] * 100 + result_array[5]
            result_array.remove(at: 5)
        }
        return result_array
    }
    
    // Drawing symbals
    func DrawingSymbal(column: Int, row: Int, kind: Int) {
        let x = Double(checkboard.frame.size.width) * Double(column) / 3
        let y = Double(checkboard.frame.size.height) * Double(row) / 3
        let symbal_width = CGFloat(checkboard.frame.size.width) / 3
        let symbal_height = CGFloat(checkboard.frame.size.height) / 3
        let checkerboard_x = checkboard.bounds.midX - CGFloat(checkboard.frame.size.width / 2.2)
        let checkerboard_y = checkboard.bounds.midY + CGFloat(checkboard.frame.size.width / 3.5)
        
        if kind == 1 {
            let image = UIImage(named: "noughts_0")!
            let new_symbal = UIImageView(image: image)
            new_symbal.frame = CGRect(x: CGFloat(x) + checkerboard_x, y: CGFloat(y) + checkerboard_y, width: symbal_width, height: symbal_height)
            symbals.append(new_symbal)
            self.view.addSubview(new_symbal)
        } else if kind == -1 {
            let image = UIImage(named: "cross_0")!
            let new_symbal = UIImageView(image: image)
            new_symbal.frame = CGRect(x: CGFloat(x) + checkerboard_x, y: CGFloat(y) + checkerboard_y, width: symbal_width, height: symbal_height)
            symbals.append(new_symbal)
            self.view.addSubview(new_symbal)
        }
        
    }
    
    // Show next step
    func ShowNextStep(column: Int, row: Int) {
        let images = [UIImage(named: "noughts_0")!, UIImage(named: "noughts_1")!, UIImage(named: "noughts_2")!, UIImage(named: "noughts_3")!]
        let x = Double(checkboard.frame.size.width) * Double(column) / 3
        let y = Double(checkboard.frame.size.height) * Double(row) / 3
        let symbal_width = CGFloat(checkboard.frame.size.width) / 3
        let symbal_height = CGFloat(checkboard.frame.size.height) / 3
        let checkerboard_x = checkboard.bounds.midX - CGFloat(checkboard.frame.size.width / 2.2)
        let checkerboard_y = checkboard.bounds.midY + CGFloat(checkboard.frame.size.width / 3.5)
        
        let animatedImage = UIImage.animatedImage(with: images, duration: 0.5)
        let new_prdiction_symbal = UIImageView(image: animatedImage)
        new_prdiction_symbal.frame = CGRect(x: CGFloat(x) + checkerboard_x, y: CGFloat(y) + checkerboard_y, width: symbal_width, height: symbal_height)
        symbals_prediction.append(new_prdiction_symbal)
        self.view.addSubview(new_prdiction_symbal)
    }
    
    // Put noughts and crosses on the current board
    func CurrentBoardState(pattern_array: [Int]) {
        var boardState = [Int]()
        
        for i in 0...2 {
            for j in 0...Cortex.patterns_identity.count - 1 {
                if pattern_array[i] == Cortex.patterns_identity[j][0] {
                    boardState.append(Cortex.patterns_identity[j][1])
                    boardState.append(Cortex.patterns_identity[j][2])
                    boardState.append(Cortex.patterns_identity[j][3])
                } else if pattern_array[i] == -Cortex.patterns_identity[j][0] {
                    boardState.append(-Cortex.patterns_identity[j][1])
                    boardState.append(-Cortex.patterns_identity[j][2])
                    boardState.append(-Cortex.patterns_identity[j][3])
                }
            }
        }
        
        print("boardState = \(boardState)")
        
        for i in 0...8 {
            let column = i % 3
            let row = i / 3
            
            DrawingSymbal(column: column, row: row, kind: boardState[i])
        }
    }
}
