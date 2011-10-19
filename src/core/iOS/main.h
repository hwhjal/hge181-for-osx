/*
 *  main.h
 *  hgecore_osx
 *
 *  Created by Andrew Pepper on 5/4/10.
 *  Copyright 2010 __MyCompanyName__. All rights reserved.
 *
 */

#ifndef _MAIN_H_
#define _MAIN_H_

#import <Foundation/Foundation.h>


// System
#include <iostream>
#include <stdio.h>
#include <stdlib.h>
#include <sys/sysctl.h>
#include <assert.h>
#include <glob.h>


#import <UIKit/UIImage.h>
#import <OpenGLES/EAGL.h>
#import <OpenGLES/ES1/gl.h>
#import <OpenGLES/ES1/glext.h>
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>

#import "appdelegate.h"
#import "eaglview.h"
#import "viewcontroller.h"

// HGE
#include "hge_impl.h"

#undef DWORD
// Bass
#include "../Bass/iOS/bass.h"
#undef DWORD

// Zlib
#define NOCRYPT
#include "../ZLIB/unzip.h"





#endif