//
//  View2.swift
//  UISetupProject
//
//  Created by Willy Zhang on 2016-04-17.
//  Copyright © 2016 Willy Zhang. All rights reserved.
//

import UIKit
import AVFoundation

class View2: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    var captureSession : AVCaptureSession?
    var stillImageOutput : AVCaptureStillImageOutput?
    var previewLayer : AVCaptureVideoPreviewLayer?
    
    var thresholdPercentage = Float()
    var selectedColor = Int()
    var view3 = View3()
    
    @IBOutlet weak var cameraView: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        previewLayer?.frame = cameraView.bounds
    }
    
    func initView2(view: View3) {
        view3 = view
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        captureSession = AVCaptureSession()
        captureSession?.sessionPreset = AVCaptureSessionPreset1280x720
        
        let backCamera = AVCaptureDevice.defaultDeviceWithMediaType(AVMediaTypeVideo)
        
        do {
            let input =  try AVCaptureDeviceInput(device: backCamera)
            
            captureSession?.addInput(input)
            stillImageOutput = AVCaptureStillImageOutput()
            stillImageOutput?.outputSettings = [AVVideoCodecKey : AVVideoCodecJPEG]
            
            if ((captureSession?.canAddOutput(stillImageOutput)) != nil) {
                captureSession?.addOutput(stillImageOutput)
                
                previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
                previewLayer?.videoGravity = AVLayerVideoGravityResizeAspect
                previewLayer?.connection.videoOrientation = AVCaptureVideoOrientation.Portrait
                cameraView.layer.addSublayer(previewLayer!)
                captureSession?.startRunning()
            }
            
        } catch (let error as NSError) {
            print(error)
        }
    }   
   
    @IBOutlet weak var tempImageView: UIImageView!

    func didPressTakePhoto () {
        if let videoConnection = stillImageOutput?.connectionWithMediaType(AVMediaTypeVideo) {
            videoConnection.videoOrientation = AVCaptureVideoOrientation.Portrait
            stillImageOutput?.captureStillImageAsynchronouslyFromConnection(videoConnection, completionHandler: {
                (sampleBuffer, error) in
                
                if sampleBuffer != nil {
                    let imageData = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(sampleBuffer)
                    let dataProvider = CGDataProviderCreateWithCFData(imageData)
                    
                    let cgImageRef = CGImageCreateWithJPEGDataProvider(dataProvider, nil, true, .RenderingIntentDefault)
                    
                    let image = UIImage(CGImage: cgImageRef!, scale: 1.0, orientation: UIImageOrientation.Right)
                    
                    let images = self.processImage(image)
                    
                    self.tempImageView.image = images.colorImage
                    self.tempImageView.hidden = false
                    
                    self.view3.showImage(images.greyImage)
                }
                
            })
        }
    }
    
    var didTakePhoto = Bool()
    
    func didPressTakeAnother() {
        if didTakePhoto == true {
            tempImageView.hidden = true
            view3.hideImage()
            didTakePhoto = false
        } else {
            captureSession?.startRunning()
            didTakePhoto = true
            didPressTakePhoto()
        }
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        didPressTakeAnother()
    }
    
    func processImage(image: UIImage) -> (colorImage: UIImage, greyImage: UIImage) {

        let greyScaleImage = ImageSearchFunctions.convertToGrayScale(image)
        
        print("image: H=\(image.size.height) W=\(image.size.width)")
        print("greyScaleImage: H=\(greyScaleImage.size.height) W=\(greyScaleImage.size.width)")
        
        let imageBitMap = ImageSearchFunctions.intensityValuesFromImage(greyScaleImage)
        
        let summedTable = ImageSearchFunctions.calculateSummedAreaTable(imageBitMap.pixelValues, width: imageBitMap.width, height: imageBitMap.height)
        
        //let matches = findLightSquare(summedTable!, width: imageBitMap.height, height: imageBitMap.width)
        let matches = ImageSearchFunctions.findSquares(summedTable!, width: imageBitMap.width, height: imageBitMap.height)
        
        
        let outputGreyScale = processPixelsInImage(greyScaleImage, match: matches, width: imageBitMap.width, height: imageBitMap.height)
        let outputColour = processPixelsInImage(image, match: matches, width: imageBitMap.width, height: imageBitMap.height)

        return (outputColour ,outputGreyScale)
    }
    
    func processPixelsInImage(inputImage: UIImage, match: [(x: Int, y: Int, squareWidth: Int, squareHeight: Int)], width: Int, height: Int) -> UIImage {
        let inputCGImage     = inputImage.CGImage
        let colorSpace       = CGColorSpaceCreateDeviceRGB()
//        let width            = CGImageGetWidth(inputCGImage)
//        let height           = CGImageGetHeight(inputCGImage)
        let bytesPerPixel    = 4
        let bitsPerComponent = 8
        let bytesPerRow      = bytesPerPixel * width
        let bitmapInfo       = CGImageAlphaInfo.PremultipliedFirst.rawValue | CGBitmapInfo.ByteOrder32Little.rawValue
        
        let context = CGBitmapContextCreate(nil, width, height, bitsPerComponent, bytesPerRow, colorSpace, bitmapInfo)!
        CGContextDrawImage(context, CGRectMake(0, 0, CGFloat(width), CGFloat(height)), inputCGImage)
        
        let pixelBuffer = UnsafeMutablePointer<UInt32>(CGBitmapContextGetData(context))

        for coord in match {
            var topDrawer = pixelBuffer + ImageSearchFunctions.getPixelIndex(coord.x, y: coord.y, height: width)
            var bottomDrawer = pixelBuffer + ImageSearchFunctions.getPixelIndex(coord.x + coord.squareWidth, y: coord.y, height: width)
            for _ in 0..<coord.squareHeight {
                // Top
                topDrawer.memory = self.rgba(red: 0, green: 255, blue: 0, alpha: 255)
                topDrawer = topDrawer + width
                
                // Bottom
                bottomDrawer.memory = self.rgba(red: 0, green: 255, blue: 0, alpha: 255)
                bottomDrawer = bottomDrawer + width
            }
            
            var rightDrawer = pixelBuffer + ImageSearchFunctions.getPixelIndex(coord.x, y: coord.y, height: width)
            var leftDrawer = pixelBuffer + ImageSearchFunctions.getPixelIndex(coord.x, y: coord.y + coord.squareHeight, height: width)

            for _ in 0..<coord.squareWidth {
                // Left
                leftDrawer.memory = self.rgba(red: 0, green: 255, blue: 0, alpha: 255)
                leftDrawer = leftDrawer + 1
                
                // Right
                rightDrawer.memory = self.rgba(red: 0, green: 255, blue: 0, alpha: 255)
                rightDrawer = rightDrawer + 1
            }
        }
        let outputCGImage = CGBitmapContextCreateImage(context)
        let outputImage = UIImage(CGImage: outputCGImage!, scale: inputImage.scale, orientation: inputImage.imageOrientation)
        
        return outputImage
    }
    
    func alpha(color: UInt32) -> UInt8 {
        return UInt8((color >> 24) & 255)
    }
    
    func red(color: UInt32) -> UInt8 {
        return UInt8((color >> 16) & 255)
    }
    
    func green(color: UInt32) -> UInt8 {
        return UInt8((color >> 8) & 255)
    }
    
    func blue(color: UInt32) -> UInt8 {
        return UInt8((color >> 0) & 255)
    }
    
    func rgba(red red: UInt8, green: UInt8, blue: UInt8, alpha: UInt8) -> UInt32 {
        return (UInt32(alpha) << 24) | (UInt32(red) << 16) | (UInt32(green) << 8) | (UInt32(blue) << 0)
    }
    
    func findLightSquare(summedTable: [Int], width: Int, height: Int) -> [(x: Int, y: Int, squareWidth: Int, squareHeight: Int)] {
        //var matches = [(topLeft: Int, topRight: Int, bottomLeft: Int, bottomRight: Int, squareWidth: Int, squareHeight: Int, startIndex: Int)]()
        var matches = [(x: Int, y: Int, squareWidth: Int, squareHeight: Int)]()
        let threshold = (255 * thresholdPercentage)
        var squareSize = 50
        let iterations = 1
        
        for _ in 0..<iterations {
            var x = 0
            var y = 0
            while (x < height || y < width) {
                var squareHeight = squareSize
                var squareWidth = squareSize
                // scan past width therefore start over at left side again and move down
                if (x > height) {
                    x = 0
                    y = y + squareSize
                }
                
                // Reached the end here therefore exit
                if (y > width) {
                    break
                }
                
                // Find index of the four corners to evaluate the sum
                //let A = (x - 1) + ((y - 1) * width)
                let A = ImageSearchFunctions.getPixelIndex(x-1, y: y-1, height: height)
                
                var B: Int
                if x + squareSize > height {
                    B = ImageSearchFunctions.getPixelIndex(height - 1, y: y - 1, height: height)
                    squareWidth = height - x - 1
                } else {
                    B = ImageSearchFunctions.getPixelIndex(x + squareSize, y: y - 1, height: height)
                }
                
                var C: Int
                if y + squareSize > width {
                    C = ImageSearchFunctions.getPixelIndex(x - 1, y: width - 1, height: height)
                    squareHeight = width - y - 1
                } else {
                    C = ImageSearchFunctions.getPixelIndex(x - 1, y: y + squareSize, height: height)
                }
                
                var D: Int
                if x + squareSize > height && y + squareSize > width {
                    D = ImageSearchFunctions.getPixelIndex(height - 1, y: width - 1, height: height)
                    squareWidth = height - x - 1
                    squareHeight = width - y - 1
                } else if y + squareSize > width {
                    D = ImageSearchFunctions.getPixelIndex(x + squareSize, y: width - 1, height: height)
                    squareHeight = width - y - 1
                } else if x + squareSize > height {
                    D = ImageSearchFunctions.getPixelIndex(height - 1, y: y + squareSize, height: height)
                    squareWidth = height - x - 1
                } else {
                    D = ImageSearchFunctions.getPixelIndex(x + squareSize, y: y + squareSize, height: height)
                }

                var sum = 0
                if x == 0 && y == 0 {
                    sum = summedTable[D]
                } else if x == 0 {
                    sum = summedTable[D] - summedTable[B]
                } else if y == 0 {
                    sum = summedTable[D] - summedTable[C]
                } else {
                    sum = summedTable[A] + summedTable[D] - summedTable[B] - summedTable[C]
                }
                
                let average = Double(sum) / Double(squareHeight * squareWidth)
                
                if (selectedColor == 1) {
                    if (average > Double(threshold)) {
                        matches.append((x, y, squareWidth, squareHeight))
                    }
                } else if (selectedColor == 0) {
                    if (average < Double(threshold)) {
                        matches.append((x, y, squareWidth, squareHeight))
                    }
                }
                
                x = x + squareSize
            }
            
            squareSize = squareSize * 2
        }
        return matches
    }
    
    func getPixelCoordinates(index: Int, width: Int) -> (x: Int, y: Int) {
        return (index % width, index / width);
    }
    

    

}
