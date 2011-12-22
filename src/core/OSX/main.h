/*
 *  main.h
 *  hgecore_osx
 *
 *  Created by Andrew Onofreytchuk on 5/3/10.
 *  Copyright 2010 Andrew Onofreytchuk (a.onofreytchuk@gmail.com). All rights reserved.
 *
 */

#ifndef _MAIN_H_
#define _MAIN_H_


#define _HGE_TARGET_OSX_

#import <Cocoa/Cocoa.h>
#import <Foundation/Foundation.h>
#import <AppKit/NSApplication.h>

// System
#include <iostream>
#include <stdio.h>
#include <stdlib.h>
#include <sys/sysctl.h>
#include <assert.h>
#include <glob.h>

#import <OpenGL/gl.h>
#import <OpenGl/glu.h>

// HGE
#import "cocoa_app.h"
#include "hge_impl.h"

#undef DWORD
// Bass
#include "../Bass/OSX/bass.h"

#undef DWORD
// Zlib
#define NOCRYPT
#include "../ZLIB/unzip.h"


#endif	// #ifndef _MAIN_H_