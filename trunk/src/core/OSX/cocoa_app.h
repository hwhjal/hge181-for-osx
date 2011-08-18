//
//  cocoa_app.h
//  hgecore_osx
//
//  Created by Andrew Onofreytchuk on 5/3/10.
//  Copyright 2010 Andrew Onofreytchuk (a.onofreytchuk@gmail.com). All rights reserved.
//


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

- (BOOL) applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)theApplication;

- (void) preRun;
- (void) run;
- (bool) isRunning;
- (NSEvent *) eventGet;
- (void) handleEvent;

@end

