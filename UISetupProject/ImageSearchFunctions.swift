//
//  ImageSearchFunctions.swift
//  UISetupProject
//
//  Created by Willy Zhang on 2016-04-21.
//  Copyright © 2016 Willy Zhang. All rights reserved.
//

import Foundation
import UIKit

class ImageSearchFunctions {
    
    static func intensityValuesFromImage(image: UIImage?) -> (pixelValues: [UInt8]?, width: Int, height: Int) {
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
    
    static func calculateSummedAreaTable(pixelValues: [UInt8]?, width: Int, height: Int) -> ([Int]?) {
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
        
        for x in 1..<width {
            for y in 1..<height {
                let index = x + (y * width)
                s![index] = Int(pixelValues![index]) + s![index - 1] + s![index - width] - s![index - width - 1]
                //print("\(s![index]) ", terminator:"")
            }
            //print("")
        }
        return s
    }
    
    static func convertToGrayScale(image: UIImage) -> UIImage {
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