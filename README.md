# MedianCut

[![License](https://img.shields.io/cocoapods/l/MedianCut.svg?style=flat)](http://cocoapods.org/pods/MedianCut)
[![Platform](https://img.shields.io/cocoapods/p/MedianCut.svg?style=flat)](http://cocoapods.org/pods/MedianCut)

A simple color extraction library based on [median cut algorithm](https://en.wikipedia.org/wiki/Median_cut#Implementation_of_color_quantization).

## Example

```swift
// Init
let medianCut = MedianCut(colorDepth: 4, resizeTargetSize: CGSize(width:256, height: 256))

// Get Colors
medianCut.getColors(image: your_image) { (succeeded, colors) in
  if (succeeded) {
    // ...do sth with colors
  } else {
    // ...handle errors
  }
}
```

## Installation

MedianCut is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'MedianCut'
```

## Author

junseok_lee, kyounh12@snu.ac.kr

## License

MedianCut is available under the MIT license. See the LICENSE file for more info.

