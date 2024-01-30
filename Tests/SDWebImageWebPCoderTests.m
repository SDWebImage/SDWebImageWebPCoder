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
#if __has_include("webp/decode.h") && __has_include("webp/encode.h") && __has_include("webp/demux.h") && __has_include("webp/mux.h")
#import "webp/decode.h"
#import "webp/encode.h"
#import "webp/demux.h"
#import "webp/mux.h"
#elif __has_include(<libwebp/decode.h>) && __has_include(<libwebp/encode.h>) && __has_include(<libwebp/demux.h>) && __has_include(<libwebp/mux.h>)
#import <libwebp/decode.h>
#import <libwebp/encode.h>
#import <libwebp/demux.h>
#import <libwebp/mux.h>
#else
@import libwebp;
#endif

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

@interface SDImageWebPCoder ()
- (void) updateWebPOptionsToConfig:(WebPConfig * _Nonnull)config
                       maxFileSize:(NSUInteger)maxFileSize
                           options:(nullable SDImageCoderOptions *)options;
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
    NSString *key = [SDWebImageManager.sharedManager cacheKeyForURL:testURL];
    [SDImageCache.sharedImageCache removeImageFromMemoryForKey:key];
    [SDImageCache.sharedImageCache removeImageFromDiskForKey:key];
    [imageView sd_setImageWithURL:testURL placeholderImage:nil options:SDWebImageProgressiveLoad progress:^(NSInteger receivedSize, NSInteger expectedSize, NSURL * _Nullable targetURL) {
        dispatch_async(dispatch_get_main_queue(), ^{
            UIImage *image = imageView.image;
            // Progressive image may be nil when download data is not enough
            if (image) {
                XCTAssertTrue(image.sd_isIncremental);
//                XCTAssertTrue([image conformsToProtocol:@protocol(SDAnimatedImage)]);
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
    XCTAssertTrue(coder.animatedImageFrameCount == 0);
    UIImage *image = [coder animatedImageFrameAtIndex:0];
    XCTAssertNil(image);
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

- (void)test46WebPEncodingMonochrome {
    CGSize size = CGSizeMake(512, 512);
    SDGraphicsImageRendererFormat *format = [[SDGraphicsImageRendererFormat alloc] init];
    format.scale = 1;
    SDGraphicsImageRenderer *renderer = [[SDGraphicsImageRenderer alloc] initWithSize:size format:format];
    UIColor *monochromeColor = UIColor.clearColor;
    UIImage *monochromeImage = [renderer imageWithActions:^(CGContextRef ctx) {
        [monochromeColor setFill];
        CGContextFillRect(ctx, CGRectMake(0, 0, size.width, size.height));
    }];
    XCTAssert(monochromeImage);
    NSData *data = [SDImageWebPCoder.sharedCoder encodedDataWithImage:monochromeImage format:SDImageFormatWebP options:nil];
    XCTAssert(data);
}

- (void)testWebPDecodeDoesNotTriggerCACopyImage {
    NSURL *staticWebPURL = [[NSBundle bundleForClass:[self class]] URLForResource:@"TestColorspaceStatic" withExtension:@"webp"];
    NSData *data = [NSData dataWithContentsOfURL:staticWebPURL];
    UIImage *image = [SDImageWebPCoder.sharedCoder decodedImageWithData:data options:@{SDImageCoderDecodeThumbnailPixelSize: @(CGSizeMake(1023, 680))}]; // 1023 * 4 need aligned to 4096
    CGImageRef cgImage = [image CGImage];
    size_t bytesPerRow = CGImageGetBytesPerRow(cgImage);
    XCTAssertEqual(bytesPerRow, 4096);
    CGColorSpaceRef colorspace = CGImageGetColorSpace(cgImage);
    NSString *colorspaceName = (__bridge_transfer NSString *)CGColorSpaceCopyName(colorspace);
#if SD_MAC
    XCTAssertEqual(colorspace, NSScreen.mainScreen.colorSpace.CGColorSpace, @"Color space is not screen");
#else
    XCTAssertEqual(colorspaceName, (__bridge NSString *)kCGColorSpaceSRGB, @"Color space is not sRGB");
#endif
}

- (void)testEncodingSettings {
    WebPConfig config;
    WebPConfigPreset(&config, WEBP_PRESET_DEFAULT, 0.2);

    SDImageCoderOptions *options = @{ SDImageCoderEncodeWebPMethod: @0,
                                      SDImageCoderEncodeWebPPass: @2,
                                      SDImageCoderEncodeWebPPreprocessing: @3,
                                      SDImageCoderEncodeWebPThreadLevel: @4,
                                      SDImageCoderEncodeWebPLowMemory: @5,
                                      SDImageCoderEncodeWebPTargetPSNR: @6,
                                      SDImageCoderEncodeWebPSegments: @7,
                                      SDImageCoderEncodeWebPSnsStrength: @8,
                                      SDImageCoderEncodeWebPFilterStrength: @9,
                                      SDImageCoderEncodeWebPFilterSharpness: @10,
                                      SDImageCoderEncodeWebPFilterType: @11,
                                      SDImageCoderEncodeWebPAutofilter: @12,
                                      SDImageCoderEncodeWebPAlphaCompression: @13,
                                      SDImageCoderEncodeWebPAlphaFiltering: @14,
                                      SDImageCoderEncodeWebPAlphaQuality: @15,
                                      SDImageCoderEncodeWebPShowCompressed: @16,
                                      SDImageCoderEncodeWebPPartitions: @17,
                                      SDImageCoderEncodeWebPPartitionLimit: @18,
                                      SDImageCoderEncodeWebPUseSharpYuv: @19,
                                      SDImageCoderEncodeWebPLossless: @1 };

    [SDImageWebPCoder.sharedCoder updateWebPOptionsToConfig:&config maxFileSize:1200 options:options];

    expect(config.method).to.equal(0);
    expect(config.pass).to.equal(2);
    expect(config.preprocessing).to.equal(3);
    expect(config.thread_level).to.equal(4);
    expect(config.low_memory).to.equal(5);
    expect(config.target_PSNR).to.equal(6);
    expect(config.segments).to.equal(7);
    expect(config.sns_strength).to.equal(8);
    expect(config.filter_strength).to.equal(9);
    expect(config.filter_sharpness).to.equal(10);
    expect(config.filter_type).to.equal(11);
    expect(config.autofilter).to.equal(12);
    expect(config.alpha_compression).to.equal(13);
    expect(config.alpha_filtering).to.equal(14);
    expect(config.alpha_quality).to.equal(15);
    expect(config.show_compressed).to.equal(16);
    expect(config.partitions).to.equal(17);
    expect(config.partition_limit).to.equal(18);
    expect(config.use_sharp_yuv).to.equal(19);
    expect(config.lossless).to.equal(1);
}

- (void)testEncodingSettingsDefaultValue {
    // Ensure that default value is used for values that haven't been defined in options.
    WebPConfig config;
    WebPConfigPreset(&config, WEBP_PRESET_DEFAULT, 0.2);

    SDImageCoderOptions *options = @{
        SDImageCoderEncodeWebPThreadLevel: @4,
        SDImageCoderEncodeWebPTargetPSNR: @6.9
    };

    [SDImageWebPCoder.sharedCoder updateWebPOptionsToConfig:&config maxFileSize:1200 options:options];

    expect(config.method).to.equal(4);
    expect(config.target_PSNR).to.equal(6.9);
}

- (void)testEncodingSettingsIncorrectType {
    // Ensure that default value is used if incorrect type of value is given as option.
    WebPConfig config;
    WebPConfigPreset(&config, WEBP_PRESET_DEFAULT, 0.2);

    SDImageCoderOptions *options = @{
        SDImageCoderEncodeWebPMethod: @"Foo"
    };

    [SDImageWebPCoder.sharedCoder updateWebPOptionsToConfig:&config maxFileSize:1200 options:options];

    expect(config.method).to.equal(4);
}


- (void)testEncodingGrayscaleImage {
    NSURL *grayscaleImageURL = [[NSBundle bundleForClass:[self class]] URLForResource:@"TestImageGrayscale" withExtension:@"jpg"];
    NSData *grayscaleImageData = [NSData dataWithContentsOfURL:grayscaleImageURL];
    UIImage *grayscaleImage = [[UIImage alloc] initWithData:grayscaleImageData];
    expect(grayscaleImage).notTo.beNil();
    
    NSData *webpData = [SDImageWebPCoder.sharedCoder encodedDataWithImage:grayscaleImage format:SDImageFormatWebP options:nil];
    expect(webpData).notTo.beNil();
    
    UIImage *decodedImage = [UIImage sd_imageWithData:webpData];
    expect(decodedImage).notTo.beNil();
    
    // Sample to verify that encoded WebP image's color is correct.
    // The wrong case before bugfix is that each column color will repeats 3 times.
    CGPoint point1 = CGPointMake(271, 764);
    CGPoint point2 = CGPointMake(round(point1.x + decodedImage.size.width / 3), point1.y);
    UIColor *color1 = [decodedImage sd_colorAtPoint:point1];
    UIColor *color2 = [decodedImage sd_colorAtPoint:point2];
    CGFloat r1, r2;
    CGFloat g1, g2;
    CGFloat b1, b2;
    [color1 getRed:&r1 green:&g1 blue:&b1 alpha:nil];
    [color2 getRed:&r2 green:&g2 blue:&b2 alpha:nil];
    expect(255 * r1).notTo.equal(255 * r2);
    expect(255 * g1).notTo.equal(255 * g2);
    expect(255 * b1).notTo.equal(255 * b2);
}

- (void)testWebPEncodingWithICCProfile {
    // Test transcoding
    NSString *jpegPath = [[NSBundle bundleForClass:[self class]] pathForResource:@"TestColorspaceBefore" ofType:@"jpeg"];
    NSData *jpegData = [NSData dataWithContentsOfFile:jpegPath];
    UIImage *jpegImage = [[UIImage alloc] initWithData:jpegData];
    
    NSData *webpData = [[SDImageWebPCoder sharedCoder] encodedDataWithImage:jpegImage format:SDImageFormatWebP options:nil];
    // Re-decode to pick color
    UIImage *webpImage = [[SDImageWebPCoder sharedCoder] decodedImageWithData:webpData options:nil];
    CGPoint point1 = CGPointMake(310, 70);
    UIColor *color1 = [webpImage sd_colorAtPoint:point1];
    CGFloat r1;
    CGFloat g1;
    CGFloat b1;
#if SD_UIKIT
    [color1 getRed:&r1 green:&g1 blue:&b1 alpha:nil];
    expect(255 * r1).beCloseToWithin(0, 5);
    expect(255 * g1).beCloseToWithin(38, 5);
    expect(255 * b1).beCloseToWithin(135, 5);
#else
    @try {
        [color1 getRed:&r1 green:&g1 blue:&b1 alpha:nil];
    }
    @catch (NSException *exception) {}
    expect(255 * r1).beCloseToWithin(0, 5);
#endif
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
