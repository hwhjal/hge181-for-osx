//
//  GLAppAppDelegate.m
//  GLApp
//
//  Created by Andrew Pepper on 04.09.11.
//  Copyright 2011 Home. All rights reserved.
//

#import "appdelegate.h"
#import "viewcontroller.h"
#include "hge_impl.h"

@implementation GLAppAppDelegate

@synthesize window;
@synthesize viewController;
// @synthesize eaglView;

+ (BOOL) forceLoadChunk
{
	return YES;}


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
	HGE_Impl *pHGE =HGE_Impl::_Interface_Get ();
	
	self.window  = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] applicationFrame]];
	self.viewController = pHGE->ios_getViewController ();	
	
	[self.window addSubview: self.viewController.view];
    self.window.rootViewController = viewController;	
	[self.window makeKeyAndVisible];
	
	EAGLView * eagl = (EAGLView *)self.viewController.view;
	pHGE->ios_setMainWindow (self.window);
	pHGE->Gfx_SetTransform (0, 0, 0, 0, 0, 0, 0);
	pHGE->Gfx_SetTransform (0, 0, eagl.framebufferWidth, 0, M_PI/2, 1, 1);
	pHGE->Release();
	
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
	pHGE = HGE_Impl::_Interface_Get ();
	pHGE->_FocusChange (false);
	pHGE->Release();
	
	[self.viewController stopAnimation];
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
	pHGE = HGE_Impl::_Interface_Get ();	
	pHGE->_FocusChange (true);
	pHGE->Release();
	
	[self.viewController startAnimation];
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    [self.viewController stopAnimation];
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Handle any background procedures not related to animation here.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Handle any foreground procedures not related to animation here.
}

- (void)applicationDidReceiveMemoryWarning:(UIApplication *)application
{
}

- (void)dealloc
{
	[viewController release];
    [window release];
    
    [super dealloc];
}

@end
