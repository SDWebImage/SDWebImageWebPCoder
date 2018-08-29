//
//  ViewController.m
//  SDWebImageWebPCoderExample
//
//  Created by Bogdan Poplauschi on 28/08/2018.
//  Copyright © 2018 SDWebImage. All rights reserved.
//

#import "ViewController.h"
#import <SDImageWebPCoder/SDImageWebPCoder.h>
#import <SDWebImage/SDWebImage.h>

@interface ViewController ()
@property (weak, nonatomic) IBOutlet UIImageView *imageView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    [[SDImageCodersManager sharedManager] addCoder:[SDImageWebPCoder sharedCoder]];
    
    [self.imageView sd_setImageWithURL:[NSURL URLWithString:@"http://littlesvr.ca/apng/images/SteamEngine.webp"]];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
