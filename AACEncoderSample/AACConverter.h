//
//  AACConverter.h
//  AACEncoderSample
//
//  Created by pebble8888 on 2016/07/02.
//  Copyright © 2016年 pebble8888. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@interface AACConverter : NSObject
//- (void)run;
- (void)setupEncoder;
- (void)encodeSampleBuffer:(CMSampleBufferRef)sampleBuffer completionBlock:(void (^)(NSData *encodedData, NSError* error))completionBlock;
@end
