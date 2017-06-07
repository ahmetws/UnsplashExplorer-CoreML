//
//  CVPixelBufferExtensions.swift
//  CoreMLDemo
//
//  Created by Said Ozcan on 07/06/2017.
//  Copyright © 2017 Said Ozcan. All rights reserved.
//

import UIKit

extension CVPixelBuffer {
    func prepareImage(pixelBuffer: CVPixelBuffer) throws -> CVPixelBuffer {
        let width = CVPixelBufferGetWidth(pixelBuffer)
        let height = CVPixelBufferGetHeight(pixelBuffer)
        let imageDimension : CGFloat = 224.0
        let cropRect = CGRect(x: (CGFloat(width) - imageDimension) / 2.0,
                              y: (CGFloat(height) - imageDimension) / 2.0,
                              width: imageDimension,
                              height: imageDimension)
        
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        let cropped = ciImage.cropping(to: cropRect)
        
        let newPixelBuffer = UnsafeMutablePointer<CVPixelBuffer?>.allocate(capacity: 1)
        
        CVPixelBufferCreate(kCFAllocatorDefault,
                            Int(224),
                            Int(224),
                            kCVPixelFormatType_32BGRA,
                            nil, newPixelBuffer)
        
        if let pixelBuffer = newPixelBuffer.pointee {
            CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)
            
            let ciContext = CIContext(options: nil)
            ciContext.render(cropped, to: pixelBuffer)
            
            CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly)
            
            return pixelBuffer
        } else {
            throw NSError(domain: "co.saidozcan.CVPixelBufferExtensions",
                          code: -1,
                          userInfo: [NSLocalizedDescriptionKey: "Cannot generate pixel buffer"])
        }
    }
}
