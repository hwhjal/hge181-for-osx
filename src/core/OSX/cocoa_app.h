//
//  cocoa_app.h
//  hgecore_osx
//
//  Created by Andrew Pepper on 5/19/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

@interface GLView : NSOpenGLView 

// - (void) drawRect:(NSRect)dirtyRect;
- (void) mouseDown:(NSEvent *)theEvent;
- (void) keyDown:(NSEvent *)theEvent;
- (BOOL) canBecomeKeyView;
- (BOOL) acceptsFirstResponder;
- (BOOL) becomeFirstResponder;
- (BOOL) resignFirstResponder;
- (void) rightMouseDown:(NSEvent *)event;
- (BOOL)canBecomeKeyWindow;
@end

@interface JJApplicationDelegate : NSObject
{
//	GLView *renderer;
//	NSWindow *window;
}

@end


@interface JJMenuPopulator : NSObject
{
}

+(void) populateMainMenu;

+(void) populateApplicationMenu:(NSMenu *)aMenu;
+(void) populateDebugMenu:(NSMenu *)aMenu;
+(void) populateEditMenu:(NSMenu *)aMenu;
+(void) populateFileMenu:(NSMenu *)aMenu;
+(void) populateFindMenu:(NSMenu *)aMenu;
+(void) populateHelpMenu:(NSMenu *)aMenu;
+(void) populateSpellingMenu:(NSMenu *)aMenu;
+(void) populateViewMenu:(NSMenu *)aMenu;
+(void) populateWindowMenu:(NSMenu *)aMenu;

@end


@interface JJConstants : NSObject
{
}

+(NSString *) applicationName;

@end


@interface Application : NSApplication 
{
	NSEvent *event;
}

- (void) preRun;
- (void) run;
- (bool) isRunning;
- (NSEvent *) eventGet;
- (void) handleEvent;
- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)theApplication;


@end

