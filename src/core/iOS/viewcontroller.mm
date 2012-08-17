//
//  GLAppViewController.m
//  GLApp
//
//  Created by Andrew Pepper on 04.09.11.
//  Copyright 2011 Home. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>

#import "viewcontroller.h"
#import "eaglview.h"
#include "hge_impl.h"


@interface GLAppViewController ()
@property (nonatomic, retain) EAGLContext *context;
@property (nonatomic, assign) CADisplayLink *displayLink;
@end

@implementation GLAppViewController

@synthesize animating, context, displayLink;

- (void)loadView
{
	self.wantsFullScreenLayout = YES;
	
    EAGLContext *aContext = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES1];
    
    if (!aContext)
    {
        aContext = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES1];
    }
    
    if (!aContext)
        NSLog(@"Failed to create ES context");
    else if (![EAGLContext setCurrentContext:aContext])
        NSLog(@"Failed to set ES context current");
    
	self.context = aContext;
	[aContext release];
	
	EAGLView *view = [[EAGLView alloc] initWithFrame:CGRectMake (0, 0, [UIScreen mainScreen].currentMode.size.width, [UIScreen mainScreen].currentMode.size.height)];
	self.view = view;
    [(EAGLView *)self.view setContext:context];
    [(EAGLView *)self.view setFramebuffer];
	
    animating = FALSE;
    animationFrameInterval = 1;
    self.displayLink = nil;
}

- (void)dealloc
{
    // Tear down context.
    if ([EAGLContext currentContext] == context)
        [EAGLContext setCurrentContext:nil];
    
    [context release];
    
    [super dealloc];
}

- (void)viewWillAppear:(BOOL)animated
{
    [self startAnimation];
    
    [super viewWillAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [self stopAnimation];
    
    [super viewWillDisappear:animated];
}

- (void)viewDidUnload
{
	[super viewDidUnload];
	
    // Tear down context.
    if ([EAGLContext currentContext] == context)
        [EAGLContext setCurrentContext:nil];
	self.context = nil;	
}

- (NSInteger)animationFrameInterval
{
    return animationFrameInterval;
}

- (void)setAnimationFrameInterval:(NSInteger)frameInterval
{
    /*
	 Frame interval defines how many display frames must pass between each time the display link fires.
	 The display link will only fire 30 times a second when the frame internal is two on a display that refreshes 60 times a second. The default frame interval setting of one will fire 60 times a second when the display refreshes at 60 times a second. A frame interval setting of less than one results in undefined behavior.
	 */
    if (frameInterval >= 1)
    {
        animationFrameInterval = frameInterval;
        
        if (animating)
        {
            [self stopAnimation];
            [self startAnimation];
        }
    }
}

- (void)startAnimation
{
    if (!animating)
    {
        CADisplayLink *aDisplayLink = [[UIScreen mainScreen] displayLinkWithTarget:self selector:@selector(drawFrame)];
        [aDisplayLink setFrameInterval:1/*animationFrameInterval*/];
        [aDisplayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
        self.displayLink = aDisplayLink;
        
        animating = TRUE;
    }
}

- (void)stopAnimation
{
    if (animating)
    {
        [self.displayLink invalidate];
        self.displayLink = nil;
        animating = FALSE;
    }
}

- (void)drawFrame
{
	// [(EAGLView *)self.view setFramebuffer];

	bool isExit = pHGE->ios_renderFrame();
    [(EAGLView *)self.view presentFramebuffer];
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];   
    // Release any cached data, images, etc. that aren't in use.
}


// Handles the start of a touch
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
	UITouch*			touch = [[event touchesForView:self.view] anyObject];
	CGPoint location = [touch locationInView:self.view];
	EAGLView * eagl = (EAGLView *)self.view;
	int x = location.y;
	int y = eagl.framebufferWidth - location.x;
	
	pHGE->_ProcessMessage (c_EVENT_MOUSE, c_EVENT_MOUSE_DOWN, x, y, 0);
	NSLog(@"touchesBegan");
}


// Handles the continuation of a touch.
- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
	UITouch*			touch = [[event touchesForView:self.view] anyObject];
	CGPoint location = [touch locationInView:self.view];
	EAGLView * eagl = (EAGLView *)self.view;
	int x = location.y;
	int y = eagl.framebufferWidth - location.x;
	
	if (UITouchPhaseMoved == [touch phase])
		pHGE->_ProcessMessage (c_EVENT_MOUSE, c_EVENT_MOUSE_MOVE, x, y, 0);
	NSLog(@"touchesMoved");	
}

// Handles the end of a touch event when the touch is a tap.
- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
	UITouch*			touch = [[event touchesForView:self.view] anyObject];
	CGPoint location = [touch locationInView:self.view];
	EAGLView * eagl = (EAGLView *)self.view;
	int x = location.y;
	int y = eagl.framebufferWidth - location.x;
	
	pHGE->_ProcessMessage (c_EVENT_MOUSE, c_EVENT_MOUSE_UP, x, y, 0);
	NSLog(@"touchesEnded");
}




@end
