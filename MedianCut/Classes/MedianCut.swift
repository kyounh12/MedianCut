
//
//  MedianCut.swift
//  MedianCut_Example
//
//  Created by 이준석 on 2017. 12. 1..
//  Copyright © 2017년 CocoaPods. All rights reserved.
//

import Foundation
import UIKit

public class MedianCut {
    /**
     Data pointer of given image.
     */
    private var data: UnsafePointer<UInt8>!
    
    /**
     colorDepth of MedianCut.
     */
    private var colorDepth: Int = 8
    private var resizeTargetSize: CGSize = CGSize(width: 256, height: 256)
    
    
    /**
     Inits MedianCut with specified colorDepth and target image size.
     
     - Parameter colorDepth: `colorDepth` of MedianCut. Must provide a value more than 4. The result of extracting colors gives at most 2^(`colorDepth`) colors. Setting a value of 4 means you can get at most 16 colors from the image. The number of colors could be less then 2^(`colorDepth`) since MedianCut removes similar colors from the result array. Default value is 8.
     - Parameter resizeTargetSize: Size to apply when resizing image to get colors from image. Providing larger size increases time to get results. If resized image's number of pixels is smaller than 2^(`colorDepth`), result array may only contains a single color. Default value is 256 * 256.
     
     */
    public convenience init(colorDepth: Int = 8, resizeTargetSize: CGSize = CGSize(width: 256, height: 256)) {
        self.init()
        
        self.colorDepth = max(colorDepth, 4)
        self.resizeTargetSize = resizeTargetSize
    }
    
    /**
     Extract colors from given image.
     
     - Parameter image: The image to extract colors.
     - Parameter completion: Completion Block.
     - Parameter succeed: If color extraction is done successfully.
     - Parameter colors: Extraced colors from image.
     */
    public func getColors(image: UIImage, completion: @escaping (_ succeed: Bool, _ colors: [UIColor]) -> Void) {
        
        DispatchQueue.main.async {
            
            // Resize image to improve performance and get dominant colors
            let _resizedImage: UIImage? = self.resizeImage(image: image, targetSize: self.resizeTargetSize)
            
            // Get color data from image
            let _bmp: CFData? = _resizedImage?.cgImage?.dataProvider?.data
            
            guard let bmp = _bmp, let resizedImage = _resizedImage else {
                // Failed to get color data
                completion(false, [])
                return
            }
            
            // Get rgba array pointer
            self.data = CFDataGetBytePtr(bmp)
            
            // Pointers array saving 'blue' value index in image rbga data array
            var pointers: [Int] = []
            
            // Data array has (number of pixels * 4) elements since each pixel is represented with 4 values (r,g,b,a)
            // To get all 'blue' value index, simply loop through 0 to pixel numbers and multiply by 4.
            for i in 0..<Int(resizedImage.size.width * resizedImage.scale * resizedImage.size.height * resizedImage.scale) {
                pointers.append(i*4)
            }
            
            // Result color tables
            var colorTables: [UIColor] = []
            
            // Get colors from image
            self.getColorTables(pointers: pointers, colorTable: &colorTables, depth: 0)
            
            // Filter out similar colors
            colorTables = colorTables.uniqueColors
            
            //            colorTables = colorTables.sorted(by: { (a, b) -> Bool in
            //                if a.hueValue == b.hueValue {
            //                    if a.brightnessValue == b.brightnessValue {
            //                        return a.saturationValue > b.saturationValue
            //                    } else {
            //                        return a.brightnessValue > b.brightnessValue
            //                    }
            //                } else {
            //                    return a.hueValue > b.hueValue
            //                }
            //            })
            
            completion(true, colorTables)
        }
    }
    
    /**
     A recursive function to get colors from color pointers
     
     - Parameter pointers: The image color pointers to extract colors.
     - Parameter colorTable: Array to insert result colors.
     - Parameter depth: Depth of current median cut loop.
     */
    private func getColorTables(pointers: [Int], colorTable: inout [UIColor], depth: Int) {
        
        // If it's the last depth of the algorithm, get average color of colors and insert to result array.
        if depth == colorDepth {
            colorTable.append(getAverageColor(pointers: pointers))
            return
        }
        
        // Sort pointers by dominant color values
        let sortedPointers = getDominantSorted(pointers: pointers)
        
        // Median cut pointers
        let separatorIndex: Int = sortedPointers.count / 2
        let front: [Int] = Array(sortedPointers[..<separatorIndex])
        let rear: [Int] = Array(sortedPointers[separatorIndex...])
        
        // Run algorithm recursively
        getColorTables(pointers: front, colorTable: &colorTable, depth: depth + 1)
        getColorTables(pointers: rear, colorTable: &colorTable, depth: depth + 1)
        
    }
    
    /**
     Sort given array by dominant color element. Dominant color element means one of red, green, blue element of a pixel which has the greatest range in pointers array.
     
     - Parameter pointers: The pointer array to sort.
     
     - Returns: Dominant sorted array.
     */
    private func getDominantSorted(pointers: [Int]) -> [Int]{
        // Copy of pointers
        var pointers = pointers
        
        // Each RGB value range, represented by (min, max) tuple.
        var rRange = (255,0)
        var gRange = (255,0)
        var bRange = (255,0)
        
        // Get RGB min, max values in data within given pointer range.
        for pointer in pointers {
            rRange = (min(rRange.0, Int(data[pointer + 2])),max(rRange.1, Int(data[pointer + 2])))
            gRange = (min(gRange.0, Int(data[pointer + 1])),max(gRange.1, Int(data[pointer + 1])))
            bRange = (min(bRange.0, Int(data[pointer])),max(bRange.1, Int(data[pointer])))
        }
        
        // Get one between red, green and blue value that has the greatest range.
        let rangeTable = [(bRange.1 - bRange.0), (gRange.1 - gRange.0), (rRange.1 - rRange.0)]
        let dominantIndex = rangeTable.firstIndex(of: max(rangeTable[0], max(rangeTable[1], rangeTable[2])))!
        
        // Sort pointers by dominant color element.
        pointers = countSort(pointers: pointers, dominantIndex: dominantIndex)
        
        return pointers
    }
    
    /**
     Counting sort given pointers by dominant color element.
     
     - Parameter pointers: The pointer array to sort.
     - Parameter dominantIndex: DominantIndex 0 means blue value, 1 means green value and 2 means red value.
     
     - Returns: Sorted pointer array.
     */
    private func countSort(pointers: [Int], dominantIndex: Int) -> [Int] {
        
        // Arry to count numbers of value exist in pointer array
        var sumArray = Array<Int>.init(repeating: 0, count: 256)
        
        // Result Array
        var sortedArray = Array<Int>.init(repeating: 0, count: pointers.count)
        
        // Count numbers of value in pointer array
        for pointer in pointers {
            let value = Int(data[pointer + dominantIndex])
            sumArray[value] = sumArray[value] + 1
        }
        
        // Sum up counted values to represent index to start fill up with.
        for i in 1..<sumArray.count {
            sumArray[i] = sumArray[i-1] + sumArray[i]
        }
        
        // Fill up sorted array with proper values
        for pointer in pointers {
            let value = Int(data[pointer + dominantIndex])
            
            sortedArray[sumArray[value] - 1] = pointer
            sumArray[value] = sumArray[value] - 1
        }
        
        return sortedArray
    }
    
    /**
     Get average color of given pointers. Simply calculates arithmetic mean of each rgb values.
     
     - Parameter pointers: The pointer array to extract average color.
     
     - Returns: The average color of pointer array.
     */
    private func getAverageColor(pointers: [Int]) -> UIColor {
        
        // RGB values
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        
        // Sum up each RGB values
        for pointer in pointers {
            r += CGFloat(data[pointer + 2])
            g += CGFloat(data[pointer + 1])
            b += CGFloat(data[pointer])
        }
        
        // Get average of each RGB values
        r = r/CGFloat(pointers.count)/255
        g = g/CGFloat(pointers.count)/255
        b = b/CGFloat(pointers.count)/255
        
        
        return UIColor(red: r, green: g, blue: b, alpha: 1)
        
    }
    
    /**
     Resizes the given `image` to fit in `targetSize`
     
     - Parameter image: The image to resize.
     - Parameter targetSize: Size to fit resized image in.
     
     - Returns: Resized UIImage, the result is optional.
     */
    private func resizeImage(image: UIImage, targetSize: CGSize) -> UIImage? {
        
        // Resize ratio of width/height to figure out which side to fit.
        let size = image.size
        let widthRatio  = targetSize.width  / size.width
        let heightRatio = targetSize.height / size.height
        
        // Original image ratio
        let ratio = size.height / size.width
        
        // Figure out resized image size.
        var newSize: CGSize
        if(widthRatio > heightRatio) {
            newSize = CGSize(width: floor(targetSize.height / ratio) ,height: targetSize.height - 4)
        } else {
            newSize = CGSize(width: targetSize.width - 4, height: floor(targetSize.width * ratio))
        }
        
        // Make a rect to use to draw resized image on.
        let rect = CGRect(x: 0, y:0, width: newSize.width, height: newSize.height)
        
        // Resize the image and draw on given rect.
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1)
        image.draw(in: rect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage
    }
    
    
}

extension UIColor {
    // RGBA Helpers
    var redValue: CGFloat{ return CIColor(color: self).red }
    var greenValue: CGFloat{ return CIColor(color: self).green }
    var blueValue: CGFloat{ return CIColor(color: self).blue }
    var alphaValue: CGFloat{ return CIColor(color: self).alpha }
    
    // HSB Helpers
    var hueValue: CGFloat{
        var h: CGFloat = 0
        var s: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        
        self.getHue(&h, saturation: &s, brightness: &b, alpha: &a)
        
        return h
    }
    
    var saturationValue: CGFloat{
        var h: CGFloat = 0
        var s: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        
        self.getHue(&h, saturation: &s, brightness: &b, alpha: &a)
        
        return s
    }
    
    var brightnessValue: CGFloat{
        var h: CGFloat = 0
        var s: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        
        self.getHue(&h, saturation: &s, brightness: &b, alpha: &a)
        
        return b
    }
    
    /**
     Determine if two colors are similar. If differences between two colors' each rgb values are all less than 0.2, it is considered to be similar.
     
     - Parameter to: The color to compare with.
     
     - Returns: If two colors are similar, returns true. Vise versa
     */
    func isSimilar(to: UIColor) -> Bool {
        // Check red value
        if abs(self.redValue - to.redValue) > 0.2 {
            return false
        }
        
        // Check blue value
        if abs(self.blueValue - to.blueValue) > 0.2 {
            return false
        }
        
        // Check green value
        if abs(self.greenValue - to.greenValue) > 0.2 {
            return false
        }
        
        return true
    }
}

extension Array where Element:UIColor {
    /**
     Get unique colors (filter out similar colors) in UIColor array but keep original order.
     
     - Returns: UIColor array which similar colors are filtered out.
     */
    var uniqueColors: [UIColor] {
        // The unique list kept in a Set for fast retrieval
        var set = Set<UIColor>()
        
        // Keeping the unique list of elements but ordered
        var arrayOrdered = [UIColor]()
        
        // Loop through array to filter out similar colors.
        for value in self {
            if !set.contains(where: { (color) -> Bool in
                if value.isSimilar(to: color) {
                    return true
                } else {
                    return false
                }
            }) {
                set.insert(value)
                arrayOrdered.append(value)
            }
        }
        
        return arrayOrdered
    }
}
