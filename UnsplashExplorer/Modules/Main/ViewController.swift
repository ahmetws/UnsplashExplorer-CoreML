//
//  ViewController.swift
//  UnsplashExplorer
//
//  Created by Ahmet Yalcinkaya on 07/06/2017.
//  Copyright © 2017 swift.ist. All rights reserved.
//

import UIKit
import CoreML

class ViewController: UIViewController {
    
    @IBOutlet weak var unsplashPhotoImageView: UIImageView!
    @IBOutlet weak var changePhotoButton: UIButton!
    @IBOutlet weak var resultsTableView: UITableView!
    
    fileprivate let manager = PredictionService()
    var resultList: [PredictionResult] = []
    
    struct Constants {
        static let randomPhotoUrl = "https://source.unsplash.com/random/800x600"
    }
    
    var waitingForPhotoProcess: Bool = false {
        didSet {
            if waitingForPhotoProcess {
                changePhotoButton.setTitle("Waiting for Photo...", for: .normal)
                changePhotoButton.isEnabled = false
            } else {
                changePhotoButton.setTitle("Change Photo", for: .normal)
                changePhotoButton.isEnabled = true
            }
        }
    }
    
    // MARK: - Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        prepareUI()
        updatePhoto()
    }
    
    func prepareUI() {
        resultsTableView.dataSource = self
    }
    
    // MARK: - Photo Process
    
    func updatePhoto() {
        
        let getPhotoTask = URLSession.shared.dataTask(with: URL(string: Constants.randomPhotoUrl)!) { [weak self]
            (data, response, error) in
            
            DispatchQueue.main.sync() { () -> Void in
                self?.waitingForPhotoProcess = false
            }
            guard error == nil else { return }
            guard let data = data else { return }
            
            if let image = UIImage(data: data) {
                DispatchQueue.main.sync() { () -> Void in
                    self?.processImage(image)
                }
            }
        }
        
        getPhotoTask.resume()
        
    }
    
    func processImage(_ image: UIImage) {
        unsplashPhotoImageView.image = image
        if let predictions = self.manager.predict(image: image) {
            self.resultList = predictions
            self.resultsTableView.reloadData()
        }
    }
    
    // MARK: - Actions
    
    @IBAction func changePhotoTapped(_ sender: Any) {
        waitingForPhotoProcess = true
        updatePhoto()
    }
}

extension ViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return resultList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "PhotoPredictionCell", for: indexPath)
        
        let resultItem = resultList[indexPath.row]
        cell.textLabel?.text = resultItem.possiblePrediction
        cell.detailTextLabel?.text = String(format: "%.02f", resultItem.probability)
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "Predictions"
    }
}
