# SDWebImageWebPCoder

[![CI Status](http://img.shields.io/travis/SDWebImage/SDWebImageWebPCoder.svg?style=flat)](https://travis-ci.org/SDWebImage/SDWebImageWebPCoder)
[![Version](https://img.shields.io/cocoapods/v/SDWebImageWebPCoder.svg?style=flat)](http://cocoapods.org/pods/SDWebImageWebPCoder)
[![License](https://img.shields.io/cocoapods/l/SDWebImageWebPCoder.svg?style=flat)](http://cocoapods.org/pods/SDWebImageWebPCoder)
[![Platform](https://img.shields.io/cocoapods/p/SDWebImageWebPCoder.svg?style=flat)](http://cocoapods.org/pods/SDWebImageWebPCoder)
[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/SDWebImage/SDWebImageWebPCoder)

Starting with the SDWebImage 5.0 version, we moved the [libwebp](https://github.com/webmproject/libwebp) support code from the Core Repo to this stand-alone repo.

## Requirements

+ iOS 8
+ macOS 10.10
+ tvOS 9.0
+ watchOS 2.0

## Installation

#### CocoaPods

SDWebImageWebPCoder is available through [CocoaPods](http://cocoapods.org). To install it, simply add the following line to your Podfile:

```ruby
pod 'SDWebImageWebPCoder'
```

#### Carthage

SDWebImageWebPCoder is available through [Carthage](https://github.com/Carthage/Carthage).

```
github "SDWebImage/SDWebImageWebPCoder"
```

## Usage

```objective-c
SDImageWebPCoder *webPCoder = [SDImageWebPCoder sharedCoder];
[[SDWebImageCodersManager sharedInstance] addCoder:webPCoder];

UIImageView *imageView;
NSURL *WebPURL = ...;
[imageView sd_setImageWithURL:WebPURL];
```

## Example

To run the example project, clone the repo, and run `pod install` from the Example directory first.

This is a demo to show how to use `WebP` and animated `WebP` images via `SDWebImage`.

## Author

[Bogdan Poplauschi](https://github.com/bpoplauschi)

## License

SDWebImageWebPCoder is available under the MIT license. See [the LICENSE file](https://github.com/SDWebImage/SDWebImageWebPCoder/blob/master/LICENSE) for more info.
