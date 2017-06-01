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
            }
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
    
    static func findSquares(summedTable: [Int], width: Int, height: Int) -> [(x: Int, y: Int, squareWidth: Int, squareHeight: Int)] {
        var matches = [(x: Int, y: Int, squareWidth: Int, squareHeight: Int)]()
        let squareScale = 10
        // 16:9 aspect ratio for 1280:720
        let searchHeight = 9 * squareScale //x
        let searchWidth = 16 * squareScale //y
        let threshold = Double(255 / 2)
        
        var x = 0
        var y = 0
        var complete = false
        
        while (x < height || y < width) {
            var finalX: Int
            if complete {
                break
            }
            
            if (x >= height) {
                x = 0
                y = y + searchWidth
            }
            
            if (x + searchHeight >= height) {
                x = height - searchHeight
                finalX = x - 1
            } else {
                finalX = x
            }
            if (y + searchWidth >= width) {
                y = width - searchWidth - 1
                complete = true
            }
            
            let outerCorners = getSummedSquareIndexes(finalX, y: y, height: height, width: width, searchHeight: searchHeight, searchWidth: searchWidth)
            let innerCorners = getSummedSquareIndexes(finalX+16, y: y+9, height: height, width: width, searchHeight: searchHeight-16, searchWidth: searchWidth - 9)
            
            if y > width {
                print("Debug")
            }
            
            let totalSum = getSummedArea(summedTable, corners: outerCorners, x: x, y: y)
            let innerSum = getSummedArea(summedTable, corners: innerCorners, x: x, y: y)
            let outerSum = totalSum - innerSum
            
            let innerPixelCount = (searchHeight-16) * (searchWidth-9)
            let outerPixelCount = (searchHeight * searchWidth) - innerPixelCount
            
            let innerAverage = Double(innerSum) / Double(innerPixelCount)
            let outerAverage = Double(outerSum) / Double(outerPixelCount)
            
            if fabs(innerAverage - outerAverage) > threshold {
                matches.append((x, y, searchWidth, searchHeight))
            }
            x = x + searchHeight
        }
        
        return matches
    }
    
    static func getPixelIndex(x: Int, y: Int, height: Int) -> Int {
        return (x + (y * height))
    }
    
    static func getSummedSquareIndexes(x: Int, y: Int, height: Int, width: Int, searchHeight: Int, searchWidth: Int) -> (A: Int, B: Int, C: Int, D: Int) {
        let A = getPixelIndex(x-1, y: y-1, height: height)
        
        var B: Int
        if x + searchHeight > height {
            B = getPixelIndex(height - searchHeight - 1, y: y - 1, height: height)
        } else {
            B = getPixelIndex(x + searchHeight, y: y - 1, height: height)
        }
        
        var C: Int
        if y + searchWidth > width {
            C = getPixelIndex(x - 1, y: width - searchWidth - 1, height: height)
        } else {
            C = getPixelIndex(x - 1, y: y + searchWidth, height: height)
        }
        
        var D: Int
        if x + searchHeight > height && y + searchWidth > width {
            D = getPixelIndex(height - searchHeight - 1, y: width - searchWidth - 1, height: height)
        } else if y + searchWidth > width {
            D = getPixelIndex(x + searchHeight, y: width - searchWidth - 1, height: height)
        } else if x + searchHeight > height {
            D = getPixelIndex(height - 1, y: y + searchWidth, height: height)
        } else {
            D = getPixelIndex(x + searchHeight, y: y + searchWidth, height: height)
        }
        
        if D > 921600 {
            print("DEBUG")
        }
        
        return (A, B, C, D)
    }
    
    static func getSummedArea(summedTable: [Int], corners: (A: Int, B: Int, C: Int, D: Int), x: Int, y: Int) -> Int {
        var sum: Int
        if x == 0 && y == 0 {
            sum = summedTable[corners.D]
        } else if x == 0 {
            sum = summedTable[corners.D] - summedTable[corners.B]
        } else if y == 0 {
            sum = summedTable[corners.D] - summedTable[corners.C]
        } else {
            sum = summedTable[corners.A] + summedTable[corners.D] - summedTable[corners.B] - summedTable[corners.C]
        }
        return sum
    }
}






















