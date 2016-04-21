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
        captureSession?.sessionPreset = AVCaptureSessionPreset1920x1080
        
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
        let greyScaleImage = convertToGrayScale(image)
        
        print("image: H=\(image.size.height) W=\(image.size.width)")
        print("greyScaleImage: H=\(greyScaleImage.size.height) W=\(greyScaleImage.size.width)")
        
        let imageBitMap = intensityValuesFromImage(greyScaleImage)
        
        let summedTable = calculateSummedAreaTable(imageBitMap.pixelValues, width: imageBitMap.width, height: imageBitMap.height)
        
        let matches = findLightSquare(summedTable!, width: imageBitMap.height, height: imageBitMap.width)
        
        let outputGreyScale = processPixelsInImage(greyScaleImage, match: matches, width: imageBitMap.width, height: imageBitMap.height)
        let outputColour = processPixelsInImage(image, match: matches, width: imageBitMap.width, height: imageBitMap.height)
        // Deug prints
//      
//        print("#######################")
//        var counter = 0
//        for pixel in summedTable! {
//            if counter == imageBitMap.width {
//                print("\(pixel)")
//                counter = 0;
//            } else {
//                counter = counter + 1
//                print("\(pixel) ", terminator: "")
//            }
//        }
//        
//        counter = 0
//        for pixel in imageBitMap.pixelValues! {
//            if counter == imageBitMap.width {
//                print("\(pixel)")
//                counter = 0;
//            } else {
//                counter = counter + 1
//                print("\(pixel) ", terminator: "")
//            }
//        }
//        
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
        
//        var testPixel = pixelBuffer
//        for _ in 0...353 {
//            testPixel = testPixel + 1
//            testPixel.memory = self.rgba(red: 255, green: 255, blue: 0, alpha: 255)
//        }
        
        
//        var currentPixel = pixelBuffer
        let maxMatches = 20
        var matchCounter = 0
        var firstCounter = 0
        for coord in match {
            if coord.squareWidth != coord.squareHeight || firstCounter < (maxMatches/2){
                var topDrawer = pixelBuffer + getPixelIndex(coord.x, y: coord.y, height: width)
                var bottomDrawer = pixelBuffer + getPixelIndex(coord.x + coord.squareWidth, y: coord.y, height: width)
                for _ in 0..<coord.squareHeight {
                    // Top
                    topDrawer.memory = self.rgba(red: 0, green: 255, blue: 0, alpha: 255)
                    topDrawer = topDrawer + width
                    
                    // Bottom
                    bottomDrawer.memory = self.rgba(red: 0, green: 255, blue: 0, alpha: 255)
                    bottomDrawer = bottomDrawer + width
                }
                
                var rightDrawer = pixelBuffer + getPixelIndex(coord.x, y: coord.y, height: width)
                var leftDrawer = pixelBuffer + getPixelIndex(coord.x, y: coord.y + coord.squareHeight, height: width)
                
                
                //print("leftDrawer start coord: x=\(coord.x) y=\(coord.y + coord.squareHeight) pixelIndex=\(getPixelIndex(coord.x, y: coord.y + coord.squareHeight, height: width))")
                for _ in 0..<coord.squareWidth {
                    // Left
                    leftDrawer.memory = self.rgba(red: 0, green: 255, blue: 0, alpha: 255)
                    //let hex = String(leftDrawer.memory, radix: 16)
                    //print("Hex=\(hex)")
                    leftDrawer = leftDrawer + 1
                
                    
                    // Right
                    rightDrawer.memory = self.rgba(red: 0, green: 255, blue: 0, alpha: 255)
                    rightDrawer = rightDrawer + 1
                }
                
                
                //print("Painting: x=\(coord.x) y=\(coord.y) for height=\(coord.squareHeight) width=\(coord.squareWidth)")
                
                if matchCounter > maxMatches {
                    break;
                } else {
                    //matchCounter = matchCounter + 1
                    //firstCounter = firstCounter + 1
                }
            }
        }
        
//        for _ in 0..<Int(height) {
//            for _ in 0..<Int(width) {
//                let pixel = currentPixel.memory
//                if self.red(pixel) == 0 && self.green(pixel) == 0 && self.blue(pixel) == 0 {
//                    currentPixel.memory = self.rgba(red: 255, green: 0, blue: 0, alpha: 255)
//                }
//                currentPixel = currentPixel + 1
//            }
//        }
        print ("#####################")
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
                let A = getPixelIndex(x-1, y: y-1, height: height)
                
                var B: Int
                if x + squareSize > height {
                    B = getPixelIndex(height - 1, y: y - 1, height: height)
                    squareWidth = height - x - 1
                } else {
                    B = getPixelIndex(x + squareSize, y: y - 1, height: height)
                }
                
                var C: Int
                if y + squareSize > width {
                    C = getPixelIndex(x, y: width - 1, height: height)
                    squareHeight = width - y - 1
                } else {
                    C = getPixelIndex(x, y: y + squareSize, height: height)
                }
                
                var D: Int
                if x + squareSize > height && y + squareSize > width {
                    D = getPixelIndex(height - 1, y: width - 1, height: height)
                    squareWidth = height - x - 1
                    squareHeight = width - y - 1
                } else if y + squareSize > width {
                    D = getPixelIndex(x + squareSize, y: width - 1, height: height)
                    squareHeight = width - y - 1
                } else {
                    D = getPixelIndex(x + squareSize, y: y + squareSize, height: height)
                }

                var codePath = 0
                var sum = 0
                if x == 0 && y == 0 {
                    sum = summedTable[D]
                } else if x == 0 {
                    codePath = 1
                    sum = summedTable[D] - summedTable[B]
                } else if y == 0 {
                    codePath = 2
                    sum = summedTable[D] - summedTable[C]
                } else {
                    codePath = 3
                    sum = summedTable[A] + summedTable[D] - summedTable[B] - summedTable[C]
                }
                
                let average = Double(sum) / Double(squareHeight * squareWidth)
                if (average > 255) {
                    print("Average is \(average) which is greater than 255 \(codePath)")
                }
                
                if (selectedColor == 1) {
                    if (average > Double(threshold)) {
                        matches.append((x, y, squareWidth, squareHeight))
                        //print("Match Found at x=\(x) y=\(y) for squareWidth=\(squareWidth) squareHeight=\(squareHeight)")
                    }
                } else if (selectedColor == 0) {
                    if (average < Double(threshold)) {
                        matches.append((x, y, squareWidth, squareHeight))
                        //print("Match Found at x=\(x) y=\(y) for squareWidth=\(squareWidth) squareHeight=\(squareHeight)")
                    }
                } else {
                    print("UNKNOWN SELECTED COLOUR")
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
    
    func getPixelIndex(x: Int, y: Int, height: Int) -> Int {
        return (x + (y * height))
    }
    
    func calculateSummedAreaTable(pixelValues: [UInt8]?, width: Int, height: Int) -> ([Int]?) {
        var s: [Int]?
        
        s = [Int](count: width * height, repeatedValue: 0)
        // s(x,y) = i(x,y) + s(x-1,y) + s(x,y-1) - s(x-1,y-1)
        
        s![0] = Int(pixelValues![0])
        for x in 1...width {
            s![x] = Int(pixelValues![x]) + s![x-1]
        }
        
        for y in 1..<height {
            s![y * width] = Int(pixelValues![y * width]) + s![(y - 1) * width]
        }
        
        for y in 1..<height {
            for x in 1..<width {
                let index = x + (y * width)
                s![index] = Int(pixelValues![index]) + s![index - 1] + s![index - width] - s![index - width - 1]
            }
        }
        
        return s
    }
    
    func intensityValuesFromImage(image: UIImage?) -> (pixelValues: [UInt8]?, width: Int, height: Int) {
        var width = 0
        var height = 0
        var pixelValues: [UInt8]?
        if (image != nil) {
            let imageRef = image!.CGImage
            width = CGImageGetWidth(imageRef)
            height = CGImageGetHeight(imageRef)
            
            let bytesPerPixel = 1
            // let bytesPerPixel = 3
            let bytesPerRow = bytesPerPixel * width
            let bitsPerComponent = 8
            let totalBytes = width * height * bytesPerPixel
            
            let colorSpace = CGColorSpaceCreateDeviceGray()
            // let colorSpace = CGColorSpaceCreateDeviceRGB()
            pixelValues = [UInt8](count: totalBytes, repeatedValue: 0)
            
            let contextRef = CGBitmapContextCreate(&pixelValues!, width, height, bitsPerComponent, bytesPerRow, colorSpace, 0)
            CGContextDrawImage(contextRef, CGRectMake(0.0, 0.0, CGFloat(width), CGFloat(height)), imageRef)
        }
        
        return (pixelValues, width, height)
    }
    
    func convertToGrayScale(image: UIImage) -> UIImage {
        let width = image.size.width
        let height = image.size.height
        
        let imageRect:CGRect = CGRectMake(0, 0, width, height)
        let colorSpace = CGColorSpaceCreateDeviceGray()

        
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.None.rawValue)
        let context = CGBitmapContextCreate(nil, Int(width), Int(height), 8, 0, colorSpace, bitmapInfo.rawValue)
        
        CGContextDrawImage(context, imageRect, image.CGImage)
        let imageRef = CGBitmapContextCreateImage(context)
        let newImage = UIImage(CGImage: imageRef!, scale: image.scale, orientation: image.imageOrientation)
        
        return newImage
    }
}
