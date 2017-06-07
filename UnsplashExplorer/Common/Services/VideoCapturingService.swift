//
//  VideoCapturingService.swift
//  CoreMLDemo
//
//  Created by Said Ozcan on 06/06/2017.
//  Copyright © 2017 Said Ozcan. All rights reserved.
//

import UIKit
import AVKit
import ImageIO
import CoreML
import AVFoundation

protocol VideoCapturingServiceDelegate : NSObjectProtocol {
    func captureOutputBuffer(buffer:CVImageBuffer)
}

class VideoCapturingService: NSObject {
    
    //MARK: Public Properties
    lazy var previewLayer : AVCaptureVideoPreviewLayer = { [unowned self] in
        let preview = AVCaptureVideoPreviewLayer(session: self.cameraSession)
        preview.bounds = CGRect(origin: CGPoint(x:0, y:0), size: self.previewView.bounds.size)
        preview.position = CGPoint(x: self.previewView.bounds.midX, y: self.previewView.bounds.midY)
        return preview
    }()
    
    //MARK: Private Properties
    fileprivate lazy var cameraSession : AVCaptureSession = {
        let cameraSession = AVCaptureSession()
        cameraSession.sessionPreset = .medium
        return cameraSession
    }()
    
    fileprivate lazy var captureDevice : AVCaptureDevice? = {
        let device = AVCaptureDevice.default(for: AVMediaType.video)
        return device
    }()
    
    fileprivate let previewView : UIView
    fileprivate weak var delegate : VideoCapturingServiceDelegate?
    fileprivate let sessionQueue = DispatchQueue(label:"co.saidozcan.VideoCapturingService.queue")
    
    //MARK: Lifecycle
    init(previewView:UIView, delegate:VideoCapturingServiceDelegate) {
        self.delegate = delegate
        self.previewView = previewView
        
        super.init()

        sessionQueue.async {
            self.setup()
        }
    }
    
    deinit {
        sessionQueue.async {
            self.cameraSession.stopRunning()
        }
    }
    
    //MARK: Private
    fileprivate func setup() {
        guard let captureDevice = self.captureDevice else { return }
        let epsilon : Double = 0.00001
        let desiredFrameRate : Double = 5
        
        do {
            let deviceInput = try AVCaptureDeviceInput(device: captureDevice)
            
            cameraSession.beginConfiguration()
            
            if (cameraSession.canAddInput(deviceInput) == true) {
                cameraSession.addInput(deviceInput)
            }
            
            let dataOutput = AVCaptureVideoDataOutput()
            dataOutput.videoSettings = [(kCVPixelBufferPixelFormatTypeKey as String) : NSNumber(value: kCVPixelFormatType_420YpCbCr8BiPlanarFullRange as UInt32)] // 3
            dataOutput.alwaysDiscardsLateVideoFrames = true
            
            if (cameraSession.canAddOutput(dataOutput) == true) {
                cameraSession.addOutput(dataOutput)
            }
            
            try captureDevice.lockForConfiguration()
            let format = captureDevice.activeFormat
            for range in format.videoSupportedFrameRateRanges {
                if (range.minFrameRate <= (desiredFrameRate + epsilon) &&
                    range.maxFrameRate >= (desiredFrameRate - epsilon)) {
                    captureDevice.activeVideoMaxFrameDuration = CMTime(value: 1,
                                                                       timescale: Int32(desiredFrameRate),
                                                                       flags: CMTimeFlags.valid,
                                                                       epoch: 0)
                    captureDevice.activeVideoMaxFrameDuration = CMTime(value: 1,
                                                                       timescale: Int32(desiredFrameRate),
                                                                       flags: CMTimeFlags.valid,
                                                                       epoch: 0)
                }
            }
            captureDevice.unlockForConfiguration()
            
            
            cameraSession.commitConfiguration() //5
            
            let queue = DispatchQueue(label: "co.saidozcan.videoQueue")
            dataOutput.setSampleBufferDelegate(self, queue: queue)
        }
        catch let error as NSError {
            NSLog("\(error), \(error.localizedDescription)")
        }
    }
    
    //MARK: Public
    func run() {
        guard AVCaptureDevice.authorizationStatus(for: .video) == AVAuthorizationStatus.authorized else {
            return
        }
        sessionQueue.async {
            self.cameraSession.startRunning()
        }
    }
}

extension VideoCapturingService : AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        if let pixelBuffer = try? pixelBuffer.prepareImage(pixelBuffer: pixelBuffer) {
            DispatchQueue.main.async {
                self.delegate?.captureOutputBuffer(buffer:pixelBuffer)
            }
        }
    }
}
