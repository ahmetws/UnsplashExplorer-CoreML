//
//  PredictionService.swift
//  CoreMLDemo
//
//  Created by Said Ozcan on 06/06/2017.
//  Copyright © 2017 Said Ozcan. All rights reserved.
//

import UIKit
import CoreML

class PredictionService: NSObject {
    
    //MARK: Properties
    fileprivate let model = Resnet50()
    
    //MARK: Public
    func predict(input: CVPixelBuffer) -> [PredictionResult]? {
        if let prediction = try? model.prediction(image:input) {
            return self.getPredictionResults(from: prediction)
        }
        return nil
    }
    
    func predict(image:UIImage) -> [PredictionResult]? {
        guard let buffer = image.convert(image: image) else { return nil }
        if let prediction = try? model.prediction(image: buffer) {
            return self.getPredictionResults(from: prediction)
        }
        return nil
    }
    
    //MARK: Private
    fileprivate func getPredictionResults(from output:Resnet50Output) -> [PredictionResult] {
        let sortedProbs = output.classLabelProbs.sorted(by: {$0.1 > $1.1})
        
        var result : [PredictionResult] = []
        for (key, value) in sortedProbs[0..<5] {
            result.append(PredictionResult(possiblePrediction:key, probability:value))
        }
        return result
    }
}
