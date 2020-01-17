//
//  PatternInfoViewController.swift
//  OX-game_0407
//
//  Created by Christian Lin on 2019/5/9.
//  Copyright © 2019 Christian Lin. All rights reserved.
//

import UIKit
import CoreData

class PatternInfoViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    // Patterns info(pattern array, pattern point, pattern rank)
    var pattern_arrays: [NSManagedObject] = []
    
    // UserDefaults
    var PatternsUD = UserDefaults.standard
    
    // TableView
    @IBOutlet weak var PatternInfoTableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //register(_:forCellReuseIdentifier:) guarantees your table view will return a cell of the correct type when the Cell reuseIdentifier is provided to the dequeue method.
        PatternInfoTableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        
        //getting data from CoreData
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
        
        let managedContext = appDelegate.persistentContainer.viewContext
        let fetchRequest_pattern_info = NSFetchRequest<NSManagedObject>(entityName: "Pattern")
        
        do {
            pattern_arrays = try managedContext.fetch(fetchRequest_pattern_info)
        } catch {
            print(error)
        }
        
        PatternInfoTableView.reloadData()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        print("pattern_array = \(pattern_arrays.count)")
        return pattern_arrays.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let pattern = pattern_arrays[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        cell.textLabel?.text = pattern.value(forKeyPath: "pattern_array") as? String
        
        return cell
    }
    
    // Watch pattern information
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let pattern = pattern_arrays[indexPath.row]
        print(pattern.value(forKeyPath: "pattern_array") as? String as Any)
        
        PatternsUD.set(pattern.value(forKeyPath: "pattern_array"), forKey: "pattern_string")
        PatternsUD.synchronize()
        
        performSegue(withIdentifier: "ShowStrategy", sender: self) 
    }
    
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        print("deselect")
    }
}
