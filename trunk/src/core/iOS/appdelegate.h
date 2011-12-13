//
//  GLAppAppDelegate.h
//  GLApp
//
//  Created by Andrew Pepper on 04.09.11.
//  Copyright 2011 Home. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "eaglview.h"


@class GLAppViewController;
 

@interface GLAppAppDelegate : NSObject <UIApplicationDelegate> {
    UIWindow *window;
    GLAppViewController *viewController;
}

@property (nonatomic, retain) UIWindow *window;
@property (nonatomic, retain) GLAppViewController *viewController;

+ (BOOL) forceLoadChunk;

@end

