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
#import <Expecta/Expecta.h>
#import <objc/runtime.h>

const int64_t kAsyncTestTimeout = 5;

@interface SDWebImageWebPCoderTests : XCTestCase
@end

@interface SDWebImageWebPCoderTests (Helpers)
- (void)verifyCoder:(id<SDImageCoder>)coder
  withLocalImageURL:(NSURL *)imageUrl
   supportsEncoding:(BOOL)supportsEncoding
    isAnimatedImage:(BOOL)isAnimated;
@end

@interface SDWebPCoderFrame : NSObject
@property (nonatomic, assign) NSUInteger index; // Frame index (zero based)
@property (nonatomic, assign) NSUInteger blendFromIndex; // The nearest previous frame index which blend mode is WEBP_MUX_BLEND
@end

@implementation SDWebImageWebPCoderTests

+ (void)setUp {
    [SDImageCache.sharedImageCache clearMemory];
    [SDImageCache.sharedImageCache clearDiskOnCompletion:nil];
    [[SDImageCodersManager sharedManager] addCoder:[SDImageWebPCoder sharedCoder]];
}

+ (void)tearDown {
    [[SDImageCodersManager sharedManager] removeCoder:[SDImageWebPCoder sharedCoder]];
}

- (void)test01ThatWEBPWorks {
    XCTestExpectation *expectation = [self expectationWithDescription:@"WEBP"];
    NSURL *imageURL = [NSURL URLWithString:@"https://www.gstatic.com/webp/gallery3/1_webp_ll.png"];
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
    NSURL *imageURL = [NSURL URLWithString:@"https://www.gstatic.com/webp/gallery3/3_webp_ll.png"];
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

- (void)test34StaticImageNotCreateCGContext {
    NSURL *staticWebPURL = [[NSBundle bundleForClass:[self class]] URLForResource:@"TestImageStatic" withExtension:@"webp"];
    NSData *data = [NSData dataWithContentsOfURL:staticWebPURL];
    SDImageWebPCoder *coder = [[SDImageWebPCoder alloc] initWithAnimatedImageData:data options:nil];
    XCTAssertTrue(coder.animatedImageFrameCount == 1);
    UIImage *image = [coder animatedImageFrameAtIndex:0];
    XCTAssertNotNil(image);
    Ivar ivar = class_getInstanceVariable(coder.class, "_canvas");
    CGContextRef canvas = ((CGContextRef (*)(id, Ivar))object_getIvar)(coder, ivar);
    XCTAssert(canvas == NULL);
}

- (void)test45WebPEncodingMaxFileSize {
    NSURL *staticWebPURL = [[NSBundle bundleForClass:[self class]] URLForResource:@"TestImageStatic" withExtension:@"webp"];
    NSData *data = [NSData dataWithContentsOfURL:staticWebPURL];
    UIImage *image = [UIImage sd_imageWithWebPData:data];
    NSData *dataWithNoLimit = [SDImageWebPCoder.sharedCoder encodedDataWithImage:image format:SDImageFormatWebP options:nil];
    XCTAssertNotNil(dataWithNoLimit);
    NSUInteger maxFileSize = 8192;
    NSData *dataWithLimit = [SDImageWebPCoder.sharedCoder encodedDataWithImage:image format:SDImageFormatWebP options:@{SDImageCoderEncodeMaxFileSize : @(maxFileSize)}];
    XCTAssertNotNil(dataWithLimit);
    XCTAssertGreaterThan(dataWithNoLimit.length, dataWithLimit.length);
    XCTAssertGreaterThan(dataWithNoLimit.length, maxFileSize);
    XCTAssertLessThanOrEqual(dataWithLimit.length, maxFileSize);
}

@end

@implementation SDWebImageWebPCoderTests (Helpers)

- (void)verifyCoder:(id<SDImageCoder>)coder
  withLocalImageURL:(NSURL *)imageUrl
   supportsEncoding:(BOOL)supportsEncoding
    isAnimatedImage:(BOOL)isAnimated {
    SDImageFormat encodingFormat = SDImageFormatWebP;
    
    NSData *inputImageData = [NSData dataWithContentsOfURL:imageUrl];
    expect(inputImageData).toNot.beNil();
    SDImageFormat inputImageFormat = [NSData sd_imageFormatForImageData:inputImageData];
    expect(inputImageFormat).toNot.equal(SDImageFormatUndefined);
    
    // 1 - check if we can decode - should be true
    expect([coder canDecodeFromData:inputImageData]).to.beTruthy();
    
    // 2 - decode from NSData to UIImage and check it
    UIImage *inputImage = [coder decodedImageWithData:inputImageData options:nil];
    expect(inputImage).toNot.beNil();
    
    if (isAnimated) {
        // 2a - check images count > 0 (only for animated images)
        expect(inputImage.sd_isAnimated).to.beTruthy();
        
        // 2b - check image size and scale for each frameImage (only for animated images)
#if SD_UIKIT
        CGSize imageSize = inputImage.size;
        CGFloat imageScale = inputImage.scale;
        [inputImage.images enumerateObjectsUsingBlock:^(UIImage * frameImage, NSUInteger idx, BOOL * stop) {
            expect(imageSize).to.equal(frameImage.size);
            expect(imageScale).to.equal(frameImage.scale);
        }];
#endif
    }
    
    // 3 - check thumbnail decoding
    CGFloat pixelWidth = inputImage.size.width;
    CGFloat pixelHeight = inputImage.size.height;
    expect(pixelWidth).beGreaterThan(0);
    expect(pixelHeight).beGreaterThan(0);
    // check thumnail with scratch
    CGFloat thumbnailWidth = 50;
    CGFloat thumbnailHeight = 50;
    UIImage *thumbImage = [coder decodedImageWithData:inputImageData options:@{
        SDImageCoderDecodeThumbnailPixelSize : @(CGSizeMake(thumbnailWidth, thumbnailHeight)),
        SDImageCoderDecodePreserveAspectRatio : @(NO)
    }];
    expect(thumbImage).toNot.beNil();
    expect(thumbImage.size).equal(CGSizeMake(thumbnailWidth, thumbnailHeight));
    // check thumnail with aspect ratio limit
    thumbImage = [coder decodedImageWithData:inputImageData options:@{
        SDImageCoderDecodeThumbnailPixelSize : @(CGSizeMake(thumbnailWidth, thumbnailHeight)),
        SDImageCoderDecodePreserveAspectRatio : @(YES)
    }];
    expect(thumbImage).toNot.beNil();
    CGFloat ratio = pixelWidth / pixelHeight;
    CGFloat thumbnailRatio = thumbnailWidth / thumbnailHeight;
    CGSize thumbnailPixelSize;
    if (ratio > thumbnailRatio) {
        thumbnailPixelSize = CGSizeMake(thumbnailWidth, round(thumbnailWidth / ratio));
    } else {
        thumbnailPixelSize = CGSizeMake(round(thumbnailHeight * ratio), thumbnailHeight);
    }
    // Image/IO's thumbnail API does not always use round to preserve precision, we check ABS <= 1
    expect(ABS(thumbImage.size.width - thumbnailPixelSize.width)).beLessThanOrEqualTo(1);
    expect(ABS(thumbImage.size.height - thumbnailPixelSize.height)).beLessThanOrEqualTo(1);
    
    
    if (supportsEncoding) {
        // 4 - check if we can encode to the original format
        if (encodingFormat == SDImageFormatUndefined) {
            encodingFormat = inputImageFormat;
        }
        expect([coder canEncodeToFormat:encodingFormat]).to.beTruthy();
        
        // 5 - encode from UIImage to NSData using the inputImageFormat and check it
        NSData *outputImageData = [coder encodedDataWithImage:inputImage format:encodingFormat options:nil];
        expect(outputImageData).toNot.beNil();
        UIImage *outputImage = [coder decodedImageWithData:outputImageData options:nil];
        expect(outputImage.size).to.equal(inputImage.size);
        expect(outputImage.scale).to.equal(inputImage.scale);
#if SD_UIKIT
        expect(outputImage.images.count).to.equal(inputImage.images.count);
#endif
        
        // check max pixel size encoding with scratch
        CGFloat maxWidth = 50;
        CGFloat maxHeight = 50;
        CGFloat maxRatio = maxWidth / maxHeight;
        CGSize maxPixelSize;
        if (ratio > maxRatio) {
            maxPixelSize = CGSizeMake(maxWidth, round(maxWidth / ratio));
        } else {
            maxPixelSize = CGSizeMake(round(maxHeight * ratio), maxHeight);
        }
        NSData *outputMaxImageData = [coder encodedDataWithImage:inputImage format:encodingFormat options:@{SDImageCoderEncodeMaxPixelSize : @(CGSizeMake(maxWidth, maxHeight))}];
        UIImage *outputMaxImage = [coder decodedImageWithData:outputMaxImageData options:nil];
        // Image/IO's thumbnail API does not always use round to preserve precision, we check ABS <= 1
        expect(ABS(outputMaxImage.size.width - maxPixelSize.width)).beLessThanOrEqualTo(1);
        expect(ABS(outputMaxImage.size.height - maxPixelSize.height)).beLessThanOrEqualTo(1);
#if SD_UIKIT
        expect(outputMaxImage.images.count).to.equal(inputImage.images.count);
#endif
    }
}

@end
