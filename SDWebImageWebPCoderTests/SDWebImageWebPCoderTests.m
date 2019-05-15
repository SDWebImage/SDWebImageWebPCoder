/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

@import Foundation;
@import XCTest;
#import <SDWebImage/SDWebImage.h>
#import <SDWebImageWebPCoder/SDWebImageWebPCoder.h>

const int64_t kAsyncTestTimeout = 5;

@interface SDWebImageWebPCoderTests : XCTestCase
@end

@interface SDWebImageWebPCoderTests (Helpers)
- (void)verifyCoder:(id<SDImageCoder>)coder
  withLocalImageURL:(NSURL *)imageUrl
   supportsEncoding:(BOOL)supportsEncoding
    isAnimatedImage:(BOOL)isAnimated;
@end

// Internal header
@interface SDAnimatedImageView ()
@property (nonatomic, assign) BOOL isProgressive;
@end

@interface SDWebPCoderFrame : NSObject
@property (nonatomic, assign) NSUInteger index; // Frame index (zero based)
@property (nonatomic, assign) NSUInteger blendFromIndex; // The nearest previous frame index which blend mode is WEBP_MUX_BLEND
@end

@implementation SDWebImageWebPCoderTests

+ (void)setUp {
    [[SDImageCodersManager sharedManager] addCoder:[SDImageWebPCoder sharedCoder]];
}

+ (void)tearDown {
    [[SDImageCodersManager sharedManager] removeCoder:[SDImageWebPCoder sharedCoder]];
}

- (void)test01ThatWEBPWorks {
    XCTestExpectation *expectation = [self expectationWithDescription:@"WEBP"];
    NSURL *imageURL = [NSURL URLWithString:@"http://www.ioncannon.net/wp-content/uploads/2011/06/test2.webp"];
    [[SDWebImageDownloader sharedDownloader] downloadImageWithURL:imageURL options:0 progress:nil completed:^(UIImage * _Nullable image, NSData * _Nullable data, NSError * _Nullable error, BOOL finished) {
        if (image && data && !error && finished) {
            [expectation fulfill];
        } else {
            XCTFail(@"Something went wrong");
        }
    }];
    [self waitForExpectationsWithTimeout:kAsyncTestTimeout handler:nil];
}

- (void)test02ThatProgressiveWebPWorks {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Progressive WebP download"];
    NSURL *imageURL = [NSURL URLWithString:@"http://www.ioncannon.net/wp-content/uploads/2011/06/test9.webp"];
    [[SDWebImageDownloader sharedDownloader] downloadImageWithURL:imageURL options:SDWebImageDownloaderProgressiveLoad progress:nil completed:^(UIImage * _Nullable image, NSData * _Nullable data, NSError * _Nullable error, BOOL finished) {
        if (image && data && !error && finished) {
            [expectation fulfill];
        } else if (finished) {
            XCTFail(@"Something went wrong");
        } else {
            // progressive updates
        }
    }];
    [self waitForExpectationsWithTimeout:kAsyncTestTimeout handler:nil];
}

- (void)test11ThatStaticWebPCoderWorks {
    NSURL *staticWebPURL = [[NSBundle bundleForClass:[self class]] URLForResource:@"TestImageStatic" withExtension:@"webp"];
    [self verifyCoder:[SDImageWebPCoder sharedCoder]
    withLocalImageURL:staticWebPURL
     supportsEncoding:YES
      isAnimatedImage:NO];
}

- (void)test12ThatAnimatedWebPCoderWorks {
    NSURL *animatedWebPURL = [[NSBundle bundleForClass:[self class]] URLForResource:@"TestImageAnimated" withExtension:@"webp"];
    [self verifyCoder:[SDImageWebPCoder sharedCoder]
    withLocalImageURL:animatedWebPURL
     supportsEncoding:YES
      isAnimatedImage:YES];
}

- (void)test21UIImageWebPCategory {
    // Test invalid image data
    UIImage *image = [UIImage sd_imageWithWebPData:nil];
    XCTAssertNil(image);
    // Test valid image data
    NSURL *staticWebPURL = [[NSBundle bundleForClass:[self class]] URLForResource:@"TestImageStatic" withExtension:@"webp"];
    NSData *data = [NSData dataWithContentsOfURL:staticWebPURL];
    image = [UIImage sd_imageWithWebPData:data];
    XCTAssertNotNil(image);
}

- (void)test31AnimatedImageViewSetAnimatedImageWEBP {
    SDAnimatedImageView *imageView = [SDAnimatedImageView new];
    NSURL *animatedWebPURL = [[NSBundle bundleForClass:[self class]] URLForResource:@"TestImageAnimated" withExtension:@"webp"];
    NSData *animatedImageData = [NSData dataWithContentsOfURL:animatedWebPURL];
    SDAnimatedImage *image = [SDAnimatedImage imageWithData:animatedImageData];
    imageView.image = image;
    XCTAssertNotNil(imageView.image);
    XCTAssertNotNil(imageView.currentFrame); // current frame
}

- (void)test32AnimatedImageViewCategoryProgressive {
    XCTestExpectation *expectation = [self expectationWithDescription:@"test SDAnimatedImageView view category"];
    SDAnimatedImageView *imageView = [SDAnimatedImageView new];
    NSURL *testURL = [NSURL URLWithString:@"http://littlesvr.ca/apng/images/SteamEngine.webp"];
    [imageView sd_setImageWithURL:testURL placeholderImage:nil options:SDWebImageProgressiveLoad progress:^(NSInteger receivedSize, NSInteger expectedSize, NSURL * _Nullable targetURL) {
        dispatch_async(dispatch_get_main_queue(), ^{
            UIImage *image = imageView.image;
            // Progressive image may be nil when download data is not enough
            if (image) {
                XCTAssertTrue(image.sd_isIncremental);
                XCTAssertTrue([image conformsToProtocol:@protocol(SDAnimatedImage)]);
                XCTAssertTrue(imageView.isProgressive);
            }
        });
    } completed:^(UIImage * _Nullable image, NSError * _Nullable error, SDImageCacheType cacheType, NSURL * _Nullable imageURL) {
        XCTAssertNil(error);
        XCTAssertNotNil(image);
        XCTAssertTrue([image isKindOfClass:[SDAnimatedImage class]]);
        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:kAsyncTestTimeout handler:nil];
}

- (void)test33AnimatedImageBlendMethod {
    // Test the optimization for blend and disposal method works without problem
    NSURL *animatedWebPURL = [[NSBundle bundleForClass:[self class]] URLForResource:@"TestImageBlendAnimated" withExtension:@"webp"];
    NSData *data = [NSData dataWithContentsOfURL:animatedWebPURL];
    SDImageWebPCoder *coder = [[SDImageWebPCoder alloc] initWithAnimatedImageData:data options:nil];
    XCTAssertNotNil(coder);
    /**
     This WebP image frames info is below:
     Canvas size: 400 x 400
     Features present: animation transparency
     Background color : 0xFF000000  Loop Count : 0
     Number of frames: 12
     No.: width height alpha x_offset y_offset duration   dispose blend image_size  compression
     1:   400   400    no        0        0       70       none    no       5178    lossless
     2:   400   400   yes        0        0       70       none   yes       1386    lossless
     3:   400   400   yes        0        0       70       none   yes       1472    lossless
     4:   400   394   yes        0        6       70       none   yes       3212    lossless
     5:   371   394   yes        0        6       70       none   yes       1888    lossless
     6:   394   382   yes        6        6       70       none   yes       3346    lossless
     7:   400   388   yes        0        0       70       none   yes       3786    lossless
     8:   394   383   yes        0        0       70       none   yes       1858    lossless
     9:   394   394   yes        0        6       70       none   yes       3794    lossless
     10:   372   394   yes       22        6       70       none   yes       3458    lossless
     11:   400   400    no        0        0       70       none    no       5270    lossless
     12:   320   382   yes        0        6       70       none   yes       2506    lossless
    */
    NSArray<SDWebPCoderFrame *> *frames = [coder valueForKey:@"_frames"];
    XCTAssertEqual(frames.count, 12);
    for (SDWebPCoderFrame *frame in frames) {
        switch (frame.index) {
            // frame: 11 blend == no, means clear the canvas
            case 10:
            case 11:
                XCTAssertEqual(frame.blendFromIndex, 10);
                break;
            default:
                XCTAssertEqual(frame.blendFromIndex, 0);
                break;
        }
    }
}

@end

@implementation SDWebImageWebPCoderTests (Helpers)

- (void)verifyCoder:(id<SDImageCoder>)coder
  withLocalImageURL:(NSURL *)imageUrl
   supportsEncoding:(BOOL)supportsEncoding
    isAnimatedImage:(BOOL)isAnimated {
    NSData *inputImageData = [NSData dataWithContentsOfURL:imageUrl];
    XCTAssertNotNil(inputImageData, @"Input image data should not be nil");
    SDImageFormat inputImageFormat = [NSData sd_imageFormatForImageData:inputImageData];
    XCTAssert(inputImageFormat != SDImageFormatUndefined, @"Input image format should not be undefined");
    
    // 1 - check if we can decode - should be true
    XCTAssertTrue([coder canDecodeFromData:inputImageData]);
    
    // 2 - decode from NSData to UIImage and check it
    UIImage *inputImage = [coder decodedImageWithData:inputImageData options:nil];
    XCTAssertNotNil(inputImage, @"The decoded image from input data should not be nil");
    
    if (isAnimated) {
        // 2a - check images count > 0 (only for animated images)
        XCTAssertTrue(inputImage.sd_isAnimated, @"The decoded image should be animated");
        
        // 2b - check image size and scale for each frameImage (only for animated images)
#if SD_UIKIT
        CGSize imageSize = inputImage.size;
        CGFloat imageScale = inputImage.scale;
        [inputImage.images enumerateObjectsUsingBlock:^(UIImage * frameImage, NSUInteger idx, BOOL * stop) {
            XCTAssertTrue(CGSizeEqualToSize(imageSize, frameImage.size), @"Each frame size should match the image size");
            XCTAssertEqual(imageScale, frameImage.scale, @"Each frame scale should match the image scale");
        }];
#endif
    }
    
    if (supportsEncoding) {
        // 3 - check if we can encode to the original format
        XCTAssertTrue([coder canEncodeToFormat:inputImageFormat], @"Coder should be able to encode");
        
        // 4 - encode from UIImage to NSData using the inputImageFormat and check it
        NSData *outputImageData = [coder encodedDataWithImage:inputImage format:inputImageFormat options:nil];
        XCTAssertNotNil(outputImageData, @"The encoded image data should not be nil");
        UIImage *outputImage = [coder decodedImageWithData:outputImageData options:nil];
        XCTAssertTrue(CGSizeEqualToSize(outputImage.size, inputImage.size), @"Output and input image size should match");
        XCTAssertEqual(outputImage.scale, inputImage.scale, @"Output and input image scale should match");
#if SD_UIKIT
        XCTAssertEqual(outputImage.images.count, inputImage.images.count, @"Output and input image frame count should match");
#endif
    }
}

@end
