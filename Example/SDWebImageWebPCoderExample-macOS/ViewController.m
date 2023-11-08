/*
 * This file is part of the SDWebImage package.
 * (c) DreamPiggy <lizhuoli1126@126.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import "ViewController.h"
#import <SDWebImageWebPCoder/SDWebImageWebPCoder.h>
#import <SDWebImage/SDWebImage.h>

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    // Test transcoding
    NSString *jpegPath = [NSBundle.mainBundle pathForResource:@"before.jpeg" ofType:nil inDirectory:@"examples/pexels-egor-kamelev-920163"];
    NSData *jpegData = [NSData dataWithContentsOfFile:jpegPath];
    NSImage *jpegImage = [[NSImage alloc] initWithData:jpegData];
    
    NSData *webpData = [[SDImageWebPCoder sharedCoder] encodedDataWithImage:jpegImage format:SDImageFormatWebP options:nil];
    NSString  *webpPath = [[jpegPath stringByDeletingLastPathComponent] stringByAppendingPathComponent:@"after.webp"];
    BOOL success = [webpData writeToFile:webpPath atomically:YES];
    NSAssert(success, @"Encode WebP success");
}


- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];

    // Update the view, if already loaded.
}


@end
