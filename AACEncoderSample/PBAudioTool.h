//
//  PBASBDExtension.h
//
//  Created by pebble8888 on 2016/07/02.
//  Copyright © 2016年 pebble8888. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@interface PBAudioTool : NSObject
+ (AudioStreamBasicDescription)monoWAVWithSampleRate:(uint32_t)sampleRate;
@end
