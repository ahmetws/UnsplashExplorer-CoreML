//
//  DoubleExtensions.swift
//  CoreMLDemo
//
//  Created by Said Ozcan on 06/06/2017.
//  Copyright © 2017 Said Ozcan. All rights reserved.
//

import Foundation

extension Double {
    /// Rounds the double to decimal places value
    func roundTo(places:Int) -> Double {
        let divisor = pow(10.0, Double(places))
        return (self * divisor).rounded() / divisor
    }
}
