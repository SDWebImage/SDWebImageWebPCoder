# SDImageWebPCoder

[![CI Status](http://img.shields.io/travis/SDWebImage/SDImageWebPCoder.svg?style=flat)](https://travis-ci.org/SDWebImage/SDImageWebPCoder)
[![Version](https://img.shields.io/cocoapods/v/SDImageWebPCoder.svg?style=flat)](http://cocoapods.org/pods/SDImageWebPCoder)
[![License](https://img.shields.io/cocoapods/l/SDImageWebPCoder.svg?style=flat)](http://cocoapods.org/pods/SDImageWebPCoder)
[![Platform](https://img.shields.io/cocoapods/p/SDImageWebPCoder.svg?style=flat)](http://cocoapods.org/pods/SDImageWebPCoder)
[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/SDWebImage/SDImageWebPCoder)

Starting with the SDWebImage 5.0 version, we moved the [libwebp](https://github.com/webmproject/libwebp) support code from the Core Repo to this stand-alone repo.

## Requirements

+ iOS 8
+ macOS 10.10
+ tvOS 9.0
+ watchOS 2.0

## Installation

#### CocoaPods

SDImageWebPCoder is available through [CocoaPods](http://cocoapods.org). To install it, simply add the following line to your Podfile:

```ruby
pod 'SDImageWebPCoder'
```

#### Carthage

SDImageWebPCoder is available through [Carthage](https://github.com/Carthage/Carthage).

```
github "SDWebImage/SDImageWebPCoder"
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

SDImageWebPCoder is available under the MIT license. See [the LICENSE file](https://github.com/SDWebImage/SDImageWebPCoder/blob/master/LICENSE) for more info.
