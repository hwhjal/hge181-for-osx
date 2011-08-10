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

#define _HGE_TARGET_OSX_

#import <Cocoa/Cocoa.h>
#import <Foundation/Foundation.h>

// System
#include <iostream>
#include <stdio.h>
#include <stdlib.h>
#include <sys/sysctl.h>

#import <OpenGL/gl.h>
#import <OpenGl/glu.h>


// HGE
#import "cocoa_app.h"
#include "hge_impl.h"

#endif