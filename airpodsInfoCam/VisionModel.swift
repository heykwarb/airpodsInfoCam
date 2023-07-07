//
//  CameraModel.swift
//  lens
//
//  Created by Yohey Kuwabara on 2021/01/10.
//

import SwiftUI
import AVFoundation
import Vision

class VisionModel: NSObject, ObservableObject, AVCapturePhotoCaptureDelegate, AVCaptureVideoDataOutputSampleBufferDelegate{
    
    @Published var session = AVCaptureSession()
    
    @Published var videoOutput = AVCaptureVideoDataOutput()
    @Published var photoOutput = AVCapturePhotoOutput()
    @Published var preview : AVCaptureVideoPreviewLayer!
    let videoDataOutputQueue = DispatchQueue(label: "VideoDataOutput", qos: .userInitiated, attributes: [], autoreleaseFrequency: .workItem)
    
    @Published var alert = false
    
    @Published var isTaken = false
    @Published var isSaved = false
    @Published var picData = Data(count: 0)
    @Published var backCamera = true
    
    var frameRate: Int = 30
    
    @Published var uiImage = UIImage()
    
    //classification
    @Published var classifying = false
    
    @Published var label: String = ""
    @Published var confidence: Float = 0
    
    //object detection
    var objectDetectionRequest = [VNRequest]()
    @Published var objectDetected = false
    @Published var objectDetectedView = false
    
    @Published var runObjectDetection = false
    @Published var bounds: CGRect = .zero
    
    @Published var imageSize: CGSize = .zero
    
    @Published var positionX: CGFloat = 0
    @Published var positionY: CGFloat = 0
    
    @Published var arViewWidth: CGFloat = 200
    
    var boxWidth: CGFloat = 0
    var boxHeight: CGFloat = 0
    
    let minWidth: CGFloat = 200
    
    var outputTimes: Int = 1
    var counter: Int = 1
    var trueCounter = 0
    var falseCounter = 0
    
    func Check(){
        // first checking camera has got permission...
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            setUp()
            return
            // Setting Up Session
        case .notDetermined:
            // retusting for permission....
            AVCaptureDevice.requestAccess(for: .video) { (status) in
                if status{
                    self.setUp()
                }
            }
        case .denied:
            self.alert.toggle()
            return
            
        default:
            return
        }
    }
    
    func setUp(){
        print("setting up camera")
        
        do{
            // setting configs...
            self.session.beginConfiguration()
            session.sessionPreset = .hd1920x1080 // Model image size is smaller.
            
            // change for your own...
            var device: AVCaptureDevice?
            
            if backCamera == true{
                device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back)
                
            }else{
                device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front)
            }
            device?.activeVideoMinFrameDuration = CMTimeMake(value: 1, timescale: Int32(frameRate))
            
            let input = try AVCaptureDeviceInput(device: device!)
            
            // checking and adding to session...
            if self.session.canAddInput(input){
                self.session.addInput(input)
            }
            
            // same for output....
            if self.session.canAddOutput(videoOutput){
                self.session.addOutput(videoOutput)
                
                // Add a video data output
                videoOutput.alwaysDiscardsLateVideoFrames = true
                videoOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_420YpCbCr8BiPlanarFullRange)]
                videoOutput.setSampleBufferDelegate(self, queue: videoDataOutputQueue)
            }
            let captureConnection = videoOutput.connection(with: .video)
            // Always process the frames
            captureConnection?.isEnabled = true
            
            //set up imageSize??
            let dimensions = CMVideoFormatDescriptionGetDimensions((device?.activeFormat.formatDescription)!)
            imageSize.height = UIScreen.main.bounds.width
            imageSize.width = UIScreen.main.bounds.height
            
            self.session.commitConfiguration()
            
            classifying = true
            
            objectDetection()
        }
        catch{
            print(error.localizedDescription)
        }
    }
    
    func switchCam(){
        print("switched camera")
        self.backCamera.toggle()
        print(backCamera)
        self.session.stopRunning()
        setUp()
        self.session.startRunning()
    }
    
    func take(){
        print("take")
        self.photoOutput.capturePhoto(with: AVCapturePhotoSettings(), delegate: self)
        
        DispatchQueue.global(qos: .background).async {
            self.session.stopRunning()
            DispatchQueue.main.async {
                withAnimation{self.isTaken.toggle()}
            }
        }
    }
    
    func savePic(){
        guard let image = UIImage(data: self.picData) else{return}
        // saving Image...
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
        
        self.isSaved = true
        
        print("saved Successfully....")
    }
    
    func reTake(){
        DispatchQueue.global(qos: .background).async {
            self.session.startRunning()
            DispatchQueue.main.async {
                withAnimation{self.isTaken.toggle()}
                //clearing ...
                self.isSaved = false
                self.picData = Data(count: 0)
            }
        }
        print("retake")
    }
    
    func restart(){
        trueCounter = 0
        falseCounter = 0
        self.session.startRunning()
    }
    
    func ear1_openess(pixelBuffer: CVPixelBuffer){
        print("classification")
        // Model
        guard let model = try? VNCoreMLModel(for: YOLOv3Tiny().model) else {
            fatalError("Error create VMCoreMLModel")
        }
        
        //VNCoreMLRequest
        let request = VNCoreMLRequest(model: model) { request, error in
            self.objectDetectionRequest = [request]
            
            //VNClassificationObservation
            guard let results = request.results as? [VNClassificationObservation] else {
                fatalError("Error results")
            }
            DispatchQueue.main.async(execute: {
                if let classification = results.first {
                    print("identifier = \(classification.identifier)")
                    print("confidence = \(classification.confidence)")
                    
                    //label
                    self.label = classification.identifier
                    //confidence
                    self.confidence = Float(round(classification.confidence * 100))
                    
                    if self.confidence <= 90{
                        self.trueCounter = 0
                        self.falseCounter += 1
                        if self.falseCounter > self.frameRate{ //detects continuously more than a second
                            withAnimation(.easeInOut(duration: 0.4)){
                                self.objectDetected = false
                            }
                        }
                    }else{
                        self.falseCounter = 0
                        self.trueCounter += 1
                        if self.trueCounter > 1*self.frameRate{ //detects continuously more than a second
                            withAnimation(.easeInOut(duration: 0.4)){
                                self.objectDetected = true
                                self.session.stopRunning()
                            }
                        }
                    }
                } else {
                    print("classification error")
                }
            })
        }
        
        // Convert to CIImage
        ///guard let ciImage = CIImage(image: uiImage) else {
            ///fatalError("Error convert CIImage")
        ///}
        //Handler
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])
        do {
            try handler.perform([request])
            ///print("handler")
        } catch {
            print(error)
        }
    }
    
    func objectDetection() {
        print("object detection")
        
        // Model
        guard let visionModel = try? VNCoreMLModel(for: AirPodsPro_ear1_2().model) else {
            fatalError("Error create VMCoreMLModel")
        }
        
        do {
            let request = VNCoreMLRequest(model: visionModel, completionHandler: { (request, error) in
                
                DispatchQueue.main.async(execute: { [self] in
                    // perform all the UI updates on the main queue
                    if let results = request.results {
                        for observation in results where observation is VNRecognizedObjectObservation {
                            guard let objectObservation = observation as? VNRecognizedObjectObservation else {
                                continue
                            }
                            // Select only the label with the highest confidence.
                            let topLabelObservation = objectObservation.labels[0] //highest confidencial label
                            self.label = topLabelObservation.identifier
                            self.confidence = topLabelObservation.confidence
                            
                            print(self.label)
                            print("confidence: \(self.confidence)")
                            
                            //object bound
                            var rect = objectObservation.boundingBox
                            rect.origin.y = 1 - rect.origin.y
                            self.bounds = VNImageRectForNormalizedRect(objectObservation.boundingBox, Int(self.imageSize.width), Int(self.imageSize.height))
                            
                            print(objectObservation.boundingBox)
                            print("bounds width: \(self.bounds.width)")
                            print("bounds height: \(self.bounds.height)")
                            print("bounds midX: \(self.bounds.midX)")
                            print("bounds midY: \(self.bounds.midY)")
                            print("imageSize: \(self.imageSize)")
                            
                            withAnimation(){
                                positionX = self.bounds.midY
                                positionY = self.bounds.midX ///- self.bounds.width/2
                                
                                boxWidth = self.bounds.width
                                boxHeight = self.bounds.height
                                
                                if bounds.width >= minWidth{
                                    self.arViewWidth = self.bounds.width
                                }else{
                                    self.arViewWidth = minWidth
                                }
                                
                            }
                        }
                        
                        if results == []{
                            self.trueCounter = 0
                            self.falseCounter += 1
                            if self.falseCounter > 1*self.frameRate{
                                withAnimation(.easeInOut(duration: 0.4)){
                                    self.objectDetected = false
                                }
                            }
                        }else{
                            self.falseCounter = 0
                            self.trueCounter += 1
                            if self.trueCounter > 1*self.frameRate{
                                withAnimation(.easeInOut(duration: 0.4)){
                                    self.objectDetected = true
                                    
                                    ///ear1_openess(pixelBuffer: <#T##CVPixelBuffer#>)
                                }
                            }
                        }
                    }
                })
            })
            ///request.imageCropAndScaleOption = .scaleFill
            self.objectDetectionRequest = [request]
        } catch let error as NSError {
            print("Model loading went wrong: \(error)")
        }
    }
    
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        print("photo output")
        if error != nil{
            return
        }
        
        if let imageData = photo.fileDataRepresentation() {
            uiImage = UIImage(data: imageData)!
            self.picData = imageData
        }
    }
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        ///print("capture output")
        if classifying == true{
            outputTimes = frameRate //times you want output in a second
            counter += 1
            if counter % (Int(frameRate)/Int(outputTimes)) == 0 {
                guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
                    return
                }
                
                let exifOrientation = exifOrientationFromDeviceOrientation()
                //object detection handler
                let imageRequestHandler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: exifOrientation, options: [:])
                do {
                    ///classification(pixelBuffer: pixelBuffer)
                    try imageRequestHandler.perform(objectDetectionRequest)
                } catch {
                    print(error)
                }
            }
        }
    }
    
    public func exifOrientationFromDeviceOrientation() -> CGImagePropertyOrientation {
        let curDeviceOrientation = UIDevice.current.orientation
        let exifOrientation: CGImagePropertyOrientation
        
        switch curDeviceOrientation {
        case UIDeviceOrientation.portraitUpsideDown:  // Device oriented vertically, home button on the top
            exifOrientation = .left
        case UIDeviceOrientation.landscapeLeft:       // Device oriented horizontally, home button on the right
            exifOrientation = .upMirrored
        case UIDeviceOrientation.landscapeRight:      // Device oriented horizontally, home button on the left
            exifOrientation = .down
        case UIDeviceOrientation.portrait:            // Device oriented vertically, home button on the bottom
            exifOrientation = .up
        default:
            exifOrientation = .up
        }
        return exifOrientation
    }
}
