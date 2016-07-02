//
//  ViewController.m
//  AACEncoderSample
//
//  Created by pebble8888 on 2016/07/02.
//  Copyright © 2016年 pebble8888. All rights reserved.
//

#import "ViewController.h"
#import "AACConverter.h"
#import "AACEncoderSample-swift.h"

@interface ViewController ()
{
    //AACConverter* _converter;
    AudioCapture* _capture;
}
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    //_converter = [[AACConverter alloc] init];
    //[_converter run];
    
    _capture = [[AudioCapture alloc] init];
    [_capture start];
}

@end
