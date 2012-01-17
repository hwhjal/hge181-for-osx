/*
 *  system.cpp
 *  hgecore_osx
 *
 *  Created by Andrew Onofreytchuk on 5/3/10.
 *  Copyright 2010 Andrew Onofreytchuk (a.onofreytchuk@gmail.com). All rights reserved.
 *
 */

#include "main.h"
#include "../Ini/SimpleIni.h"


int			nRef=0;
HGE_Impl*	pHGE=0;



HGE* CALL hgeCreate(int ver)
{
	if (ver==HGE_VERSION)
		return (HGE*) HGE_Impl::_Interface_Get();
	else
		return 0;
}

HGE_Impl::HGE_Impl()
{
	bRendererInit = false;
	glView = 0;
	glContextWindowed = glContextFullscreen = nil;
	
	hwnd=0;
	bActive=false;
	szError[0]=0;
	
	pTargets=0;
	pCurTarget=0;
	VertArray=0;
	textures=0;
	nVertexBufferSize = nIndexBufferSize = 0;
	glVertexBuffer = nil;
	glIndexBuffer = nil;
	bGLVARSupported = false;
	bGLAppleFenceSupported = false;
	nGLMaxTexUnits = 0;
	nGLMaxTexSize = 0;
	bKeepDesktopMode = false;	
	
	hBass=0;
	bSilent=false;
	streams=0;
	
	hSearch=false;
	res=0;
	
	queue=0;
	Char=VKey=Zpos=0;
	Xpos=Ypos=0.0f;
	bMouseOver=false;
	bCaptured=false;
	
	nHGEFPS=HGEFPS_UNLIMITED;
	fTime=0.0f;
	fDeltaTime=0.0f;
	nFPS=0;
	
	procFrameFunc=0;
	procRenderFunc=0;
	procFocusLostFunc=0;
	procFocusGainFunc=0;
	procGfxRestoreFunc=0;
	procExitFunc=0;
	szIcon=0;
	strcpy(szWinTitle,"HGE");
	nScreenWidth=800;
	nScreenHeight=600;
	nScreenBPP=32;
	bWindowed=true;
	bZBuffer=false;
	bTextureFilter=true;
	szLogFile[0]=0;
	szIniFile[0]=0;
	szAppPath[0]=0;
	bUseSound=true;
	nSampleRate=44100;
	nFXVolume=100;
	nMusVolume=100;
	nStreamVolume=100;
	nFixedDelta=0;
	bHideMouse=true;
	bDontSuspend=false;
	
	bTextureClamp = false;
	
	nPowerStatus=HGEPWR_UNSUPPORTED;
	
	/*nPowerStatus=HGEPWR_UNSUPPORTED;
	hKrnl32 = NULL;
	lpfnGetSystemPowerStatus = NULL;*/
	
#ifdef DEMO
	bDMO=true;
#endif
	
	NSAutoreleasePool *pool = [NSAutoreleasePool new];

	mainBundle = [NSBundle mainBundle];
	NSString *res = [mainBundle resourcePath];
	[res getCString:szAppPath maxLength:sizeof(szAppPath) encoding:NSASCIIStringEncoding];
	strcat (szAppPath, "/");
	
	[pool release];
	
	// Get byteorder
	char prop_buff [1024] = {};
	int prop [2], be_res;
	unsigned int *p_res = (unsigned int *) prop_buff;
	size_t prop_buf_size;
	prop_buf_size = sizeof (prop_buff);
	
	prop [0] = CTL_HW; prop [1] = HW_BYTEORDER;
	prop_buf_size = sizeof (prop_buff);
	be_res = sysctl (prop, 2, prop_buff, &prop_buf_size, NULL, 0);
	nByteOrder = *p_res;
	
	// Search init
	searchIndex = 0;
	localFileManager = [NSFileManager defaultManager];
	
	if(nHGEFPS>0)
		nFixedDelta=int(1000.0f/nHGEFPS);
	else
		nFixedDelta=0;	

}

HGE_Impl* HGE_Impl::_Interface_Get()
{
	if(!pHGE) pHGE=new HGE_Impl();
	
	nRef++;
	
	return pHGE;
}


bool CALL HGE_Impl::System_Initiate()
{
	NSAutoreleasePool *pool = [NSAutoreleasePool new];
	
	System_Log("HGE Started..\n");
	
	System_Log("HGE version: %X.%X", HGE_VERSION>>8, HGE_VERSION & 0xFF);
	System_Log("Application: %s",szWinTitle);
	System_Log("OS: Mac OS X");
	
	application = (Application*)[Application sharedApplication];
	[application setDelegate:application];	
	[application preRun];	
	
	// Cerate window	
	_CreateWindow ();
	
	// Input init
	_InputInit();
	
	// Gfx init
	if (!_GfxInit())
	{
		System_Log("_GfxInit failed");	
		System_Shutdown();
		[pool release];
		return false;
	}
	// Sound init
	if (!_SoundInit())
	{
		System_Log("Bass didn`t load!");	
		System_Shutdown();
		[pool release];
		return false;
	}	
	
	fTime=0.0f;
	t0=t0fps=CFAbsoluteTimeGetCurrent ();
	dt=cfps=0;
	nFPS=0;	
	
	System_Log("Init done.\n");	
	
	[pool release];
	return true;
}

void CALL HGE_Impl::_CreateWindow ()
{
	if (bWindowed)
	{	
		NSRect frame = NSMakeRect(0, 0, nScreenWidth, nScreenHeight);
		unsigned int styleMask = NSTitledWindowMask | NSClosableWindowMask | NSMiniaturizableWindowMask;
		// Corretct frame size with given content rect
		// frame = [NSWindow frameRectForContentRect: frame styleMask: styleMask];
		rect = frame;
		hwnd =  [[NSWindow alloc] initWithContentRect:rect styleMask:styleMask backing: NSBackingStoreBuffered defer:false];
		if (!hwnd)
		{
			_PostError("Can't create window");
			return;
		}	
		
		[hwnd setBackgroundColor:[NSColor blackColor]];
		NSString* title = [[NSString alloc] initWithBytes:szWinTitle length:strlen(szWinTitle) encoding:NSASCIIStringEncoding];		
		[hwnd setTitle: title];
		[hwnd display];
		[hwnd center];
		[hwnd makeKeyAndOrderFront: hwnd];
		[hwnd setAcceptsMouseMovedEvents: YES];
		[hwnd makeMainWindow];
	}
	else
	{
		hwnd = 0;
	}	
}

	
void CALL HGE_Impl::System_SetStateBool (hgeBoolState state, bool value)
{
	switch(state)
	{
		case HGE_WINDOWED:

			if(VertArray) break;
			if((glContextWindowed || glContextFullscreen) && bWindowed != value)
			{
				bWindowed=value;
				_GfxRestore();
			}
			else bWindowed=value;
			break;
			
		case HGE_ZBUFFER:		
			if(!bGLInitDone)	bZBuffer=value;
			break;
			
		/*case HGE_TEXTUREFILTER: bTextureFilter=value;
			if(pD3DDevice)
			{
				_render_batch();
				if(bTextureFilter)
				{
					pD3DDevice->SetTextureStageState(0,D3DTSS_MAGFILTER,D3DTEXF_LINEAR);
					pD3DDevice->SetTextureStageState(0,D3DTSS_MINFILTER,D3DTEXF_LINEAR);
				}
				else
				{
					pD3DDevice->SetTextureStageState(0,D3DTSS_MAGFILTER,D3DTEXF_POINT);
					pD3DDevice->SetTextureStageState(0,D3DTSS_MINFILTER,D3DTEXF_POINT);
				}
			}
			break;*/
			
		case HGE_USESOUND:		if(bUseSound!=value)
		{
			bUseSound=value;
			if(bUseSound && hwnd) _SoundInit();
			if(!bUseSound && hwnd) _SoundDone();
		}
		break;
			
		case HGE_HIDEMOUSE:		bHideMouse=value; break;
			
		case HGE_DONTSUSPEND:	bDontSuspend=value; break;
			
#ifdef DEMO
		case HGE_SHOWSPLASH:	bDMO=value; break;
#endif
		case HGE_TEXTURECLAMP:  bTextureClamp = value; break;
	}

}

void CALL HGE_Impl::System_SetStateFunc(hgeFuncState state, hgeCallback value)
{
	switch(state)
	{
		case HGE_FRAMEFUNC:		 procFrameFunc=value; break;
		case HGE_RENDERFUNC:	 procRenderFunc=value; break;
		case HGE_FOCUSLOSTFUNC:	 procFocusLostFunc=value; break;
		case HGE_FOCUSGAINFUNC:	 procFocusGainFunc=value; break;
		case HGE_GFXRESTOREFUNC: procGfxRestoreFunc=value; break;
		case HGE_EXITFUNC:		 procExitFunc=value; break;
	}
}

void CALL HGE_Impl::System_SetStateHwnd(hgeHwndState state, HWND value)
{
	/*switch(state)
	{
		case HGE_HWNDPARENT:	if(!hwnd) hwndParent=value; break;
	}*/
}

void CALL HGE_Impl::System_SetStateInt(hgeIntState state, int value)
{
	switch(state)
	{
		case HGE_SCREENWIDTH:	if(!bRendererInit) nScreenWidth=value; break;
			
		case HGE_SCREENHEIGHT:	if(!bRendererInit) nScreenHeight=value; break;
				
		case HGE_SCREENBPP:		if(!bRendererInit) nScreenBPP=value; break;
			
		case HGE_SAMPLERATE:	if(!bSoundInit) nSampleRate=value;
			break;
			
		case HGE_FXVOLUME:		nFXVolume=value;
			_SetFXVolume(nFXVolume);
			break;
			
		case HGE_MUSVOLUME:		nMusVolume=value;
			_SetMusVolume(nMusVolume);
			break;
			
		case HGE_STREAMVOLUME:	nStreamVolume=value;
			_SetStreamVolume(nStreamVolume);
			break;
			
		case HGE_FPS:
			
			if(VertArray) break;
			
			if(bRendererInit)
			{
				if((nHGEFPS>=0 && value <0) || (nHGEFPS<0 && value>=0))
				{
					if(value==HGEFPS_VSYNC)
					{
						// d3dppW.SwapEffect = D3DSWAPEFFECT_COPY_VSYNC;
						// d3dppFS.FullScreen_PresentationInterval = D3DPRESENT_INTERVAL_ONE;
					}
					else
					{
						// d3dppW.SwapEffect = D3DSWAPEFFECT_COPY;
						// d3dppFS.FullScreen_PresentationInterval = D3DPRESENT_INTERVAL_IMMEDIATE;
					}
					// _GfxRestore();
				}
			}
			nHGEFPS=value;
			if(nHGEFPS>0) 
				nFixedDelta=int(1000.0f/value);
			else
				nFixedDelta=0;
			break;
	}
}

void CALL HGE_Impl::System_SetStateString(hgeStringState state, const char *value)
{
	FILE *hf;
	
	switch(state)
	{
		case HGE_ICON:
			szIcon=value;
			if(pHGE->hwnd)
			{
				NSString *iconName = [[NSString alloc] initWithBytes:value length:strlen(value) encoding:NSASCIIStringEncoding];
				NSImage *myImage = [[NSImage alloc] initWithContentsOfFile:iconName];
				[NSApp setApplicationIconImage: myImage];
			}
		break;
			
		case HGE_TITLE:
			strcpy(szWinTitle,value);
		break;
			
		case HGE_INIFILE:		
			if(value)
				strcpy(szIniFile, Resource_MakePath(value));
		else
			szIniFile[0]=0;
			break;
			
		case HGE_LOGFILE:
			if(value)
			{
				strcpy(szLogFile, Resource_MakePath(value));
				hf=fopen(szLogFile, "w");
				if(!hf) szLogFile[0]=0;
				else fclose(hf);
			}
			else szLogFile[0]=0;
		break;
	}
}

bool CALL HGE_Impl::System_GetStateBool(hgeBoolState state)
{
	switch(state)
	{
		case HGE_WINDOWED:		return bWindowed;
		case HGE_ZBUFFER:		return bZBuffer;
		case HGE_TEXTUREFILTER:	return bTextureFilter;
		case HGE_USESOUND:		return bUseSound;
		case HGE_DONTSUSPEND:	return bDontSuspend;
		case HGE_HIDEMOUSE:		return bHideMouse;
		case HGE_BYTEORDER:
			if (1234 == nByteOrder) return false;
				else return true;
		break;			
			
#ifdef DEMO
		case HGE_SHOWSPLASH:	return bDMO;
#endif
			
			/* HGE_MODIFY: (Texture clamping) { */
		 case HGE_TEXTURECLAMP:  return bTextureClamp;
			/* } */
	}
	
	return false;
}

hgeCallback CALL HGE_Impl::System_GetStateFunc(hgeFuncState state)
{
	switch(state)
	{
		case HGE_FRAMEFUNC:		return procFrameFunc;
		case HGE_RENDERFUNC:	return procRenderFunc;
		case HGE_FOCUSLOSTFUNC:	return procFocusLostFunc;
		case HGE_FOCUSGAINFUNC:	return procFocusGainFunc;
		case HGE_EXITFUNC:		return procExitFunc;
	}
	
	return NULL;
}

HWND CALL HGE_Impl::System_GetStateHwnd(hgeHwndState state)
{
	switch(state)
	{
		case HGE_HWND:			return hwnd;
		case HGE_HWNDPARENT:	return 0;
	}
	
	return 0;
}

int CALL HGE_Impl::System_GetStateInt(hgeIntState state)
{
	switch(state)
	{
		case HGE_SCREENWIDTH:	return nScreenWidth;
		case HGE_SCREENHEIGHT:	return nScreenHeight;
		case HGE_SCREENBPP:		return nScreenBPP;
		case HGE_SAMPLERATE:	return nSampleRate;
		case HGE_FXVOLUME:		return nFXVolume;
		case HGE_MUSVOLUME:		return nMusVolume;
		case HGE_STREAMVOLUME:	return nStreamVolume;
		case HGE_FPS:			return nHGEFPS;
		case HGE_POWERSTATUS:	return 0/*nPowerStatus*/;
	}
	
	return 0;
}

const char* CALL HGE_Impl::System_GetStateString(hgeStringState state) {
	switch(state) {
		case HGE_ICON:			return szIcon;
		case HGE_TITLE:			return szWinTitle;
		case HGE_INIFILE:		if (szIniFile[0]) return szIniFile;	else return NULL;
		case HGE_LOGFILE:		if (szLogFile[0]) return szLogFile;	else return NULL;
		case HGE_APPPATH:		if (szAppPath[0]) return szAppPath; else return NULL;
	}
	
	return NULL;
}



char* CALL HGE_Impl::System_GetErrorMessage()
{
	return szError;
}

void CALL HGE_Impl::System_Log(const char *szFormat, ...)
{
	FILE *hf = NULL;
	va_list ap;
	
	if(!szLogFile[0]) return;
	
	hf = fopen(szLogFile, "a");
	if(!hf) return;
	
	va_start(ap, szFormat);
	vfprintf(hf, szFormat, ap);
	va_end(ap);
	
	fprintf(hf, "\n");
	
	fclose(hf);
}

void HGE_Impl::_PostError(const char *error)
{
	System_Log(error);
	strcpy(szError,error);
}

void CALL HGE_Impl::System_Shutdown()
{
	System_Log("\nFinishing..");
	
	_ClearQueue();	
	_SoundDone();	
	_GfxDone();
	
	[localFileManager release];
	if (hSearch)
	{
		globfree(&fileSearcher);
		hSearch = false;
		searchIndex = 0;
	}

	
	/*timeEndPeriod(1);
	_DonePowerStatus();
	
	if(hwnd)
	{
		DestroyWindow(hwnd);
		hwnd=0;
	}	
	*/
	
	System_Log("The End.");
}



bool CALL HGE_Impl::System_Start()
{
	if(!hwnd && bWindowed)
	{
		_PostError("System_Start: System_Initiate wasn't called");
		return false;
	}
	
	if(!procFrameFunc) {
		_PostError("System_Start: No frame function defined");
		return false;
	}
	
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	
	bActive=true;
	
	// MAIN LOOP	
	do
	{
		// Get messages
		NSEvent *event = 0;
		do
		{
			[application run];				
			event = [application eventGet];
			if (0 != event && !_ProcessMessage (event)) [application handleEvent];
		} while (event);

		// Check if mouse is over HGE window for Input_IsMouseOver		
		_UpdateMouse();
		
		// If HGE window is focused or we have the "don't suspend" state - process the main loop
		
		if(bActive || bDontSuspend)
		{
			// Ensure we have at least 1ms time step
			// to not confuse user's code with 0
			
			// do { dt= CFAbsoluteTimeGetCurrent () - t0; } while(dt < 0.001);
			do { dt= CFAbsoluteTimeGetCurrent () - t0; } while(dt < 0.001);			
			// If we reached the time for the next frame
			// or we just run in unlimited FPS mode, then
			// do the stuff
			
			if(dt >= nFixedDelta/1000.0f)
			{
				// fDeltaTime = time step in seconds returned by Timer_GetDelta
				
				fDeltaTime=dt;
				
				// Cap too large time steps usually caused by lost focus to avoid jerks
				
				if(fDeltaTime > 0.5f)
				{
					fDeltaTime = nFixedDelta ? nFixedDelta/1000.0f : 0.01f;
				}
				
				// Update time counter returned Timer_GetTime
				
				fTime += fDeltaTime;
				
				// Store current time for the next frame
				// and count FPS
				
				t0=CFAbsoluteTimeGetCurrent ();
				if(t0-t0fps <= 1)
					cfps++;
				else
				{
					nFPS=cfps; cfps=0; t0fps=t0;
					/// _UpdatePowerStatus();
				}
				
				// Do user's stuff
				if(procFrameFunc())
					if(!pHGE->procExitFunc || (pHGE->procExitFunc && pHGE->procExitFunc()) ) break;
				if(procRenderFunc) procRenderFunc();
				
				// If if "child mode" - return after processing single frame
				
				// if(hwndParent) break;
				
				// Clean up input events that were generated by
				// WindowProc and weren't handled by user's code
				
				_ClearQueue();
				
				// If we use VSYNC - we could afford a little
				// sleep to lower CPU usage
				
				// [glView display];
				// [glContext update];
//				if (bWindowed) [glContextWindowed flushBuffer];
//					else [glContextFullscreen flushBuffer];
			}
			
			// If we have a fixed frame rate and the time
			// for the next frame isn't too close, sleep a bit
			
			else
			{
				if(nFixedDelta && dt+3 < nFixedDelta)
					usleep (10);
					// [NSThread sleepForTimeInterval:0.001];				
			}
		}
		
	} while ([application isRunning]);
	
	[application setDelegate:nil];		
	[pool release];	

	_ClearQueue();	
	bActive=false;
	
	return true;
}

void CALL HGE_Impl::Release()
{
	nRef--;
	
	if(!nRef)
	{
		// if(pHGE->hwnd) pHGE->System_Shutdown();
		// Resource_RemoveAllPacks();
		delete pHGE;
		pHGE=0;
	}
}

POINT HGE_Impl::_GetMousePos ()
{
	POINT res = {};
	NSPoint mousePos = [NSEvent mouseLocation];
	int displayH = CGDisplayPixelsHigh (kCGDirectMainDisplay);
	if (bWindowed && nil != hwnd)
	{
		NSRect frame = [hwnd frame];
		frame = [hwnd contentRectForFrameRect: frame];
		frame.origin.y = displayH - frame.origin.y - frame.size.height;
		mousePos.y = displayH - mousePos.y;
		mousePos.y -= frame.origin.y;
		mousePos.x -= frame.origin.x;
		
		// Check for inwindow rect movements
		NSPoint mp = [NSEvent mouseLocation];
		mp.y = displayH - mp.y;
		Point p;
		p.h = mp.x;
		p.v = mp.y;
		Rect r;		
		r.left = frame.origin.x;
		r.top = frame.origin.y;
		r.right = r.left + frame.size.width;
		r.bottom = r.top + frame.size.height;		
		if (!([hwnd isVisible] && PtInRect (p, &r)))
		{
			mousePos.x = -1;
			mousePos.y = -1;			
			bMouseOver = false;
		}	
	}
		else
		{
			mousePos.y = displayH - mousePos.y;
			bMouseOver = true;
		}

	
	res.x = mousePos.x;
	res.y = mousePos.y;
	
	return res;
}


bool HGE_Impl::_ProcessMessage (NSEvent *event)
{
	if (nil != event)
	{	
//		[hwnd makeKeyAndOrderFront: hwnd];
		
		switch ([event type])
		{
//			case NSAppKitDefined:
//				if ([event subtype] == NSApplicationActivatedEventType || [event subtype] == NSApplicationDeactivatedEventType)
//				{
//					[hwnd makeKeyAndOrderFront: hwnd];					
//					return false;
//				}
//			break;
			// Mouse Left button
			case NSLeftMouseDown:
			{
				POINT mousePos = _GetMousePos ();
				if (-1 != mousePos.x && -1 != mousePos.y)
				{
					if (1 == [event clickCount]) pHGE->_BuildEvent(INPUT_MBUTTONDOWN, HGEK_LBUTTON, 0, 0, mousePos.x, mousePos.y);
						else pHGE->_BuildEvent(INPUT_MBUTTONDOWN, HGEK_LBUTTON, 0, HGEINP_REPEAT, mousePos.x, mousePos.y);
					hwKeyz[HGEK_LBUTTON] = 1;
					return false;
				}
			}
			break;
	 
			case NSLeftMouseUp:
			{
				POINT mousePos = _GetMousePos ();
				if (-1 != mousePos.x && -1 != mousePos.y)
					pHGE->_BuildEvent(INPUT_MBUTTONUP, HGEK_LBUTTON, 0, 0, mousePos.x, mousePos.y);	
				hwKeyz[HGEK_LBUTTON] = 0;
				return false;
			}	
			break;
				
			// Mouse right button
			case NSRightMouseDown:
			{
				POINT mousePos = _GetMousePos ();
				if (-1 != mousePos.x && -1 != mousePos.y)
				{
					pHGE->_BuildEvent(INPUT_MBUTTONDOWN, HGEK_RBUTTON, 0, 0, mousePos.x, mousePos.y);
					if (1 == [event clickCount]) pHGE->_BuildEvent(INPUT_MBUTTONDOWN, HGEK_RBUTTON, 0, 0, mousePos.x, mousePos.y);
						else pHGE->_BuildEvent(INPUT_MBUTTONDOWN, HGEK_RBUTTON, 0, HGEINP_REPEAT, mousePos.x, mousePos.y);
					hwKeyz[HGEK_RBUTTON] = 1;
				}
				return false;
			}
			break;
				
			case NSRightMouseUp:
			{
				POINT mousePos = _GetMousePos ();
				if (-1 != mousePos.x && -1 != mousePos.y)
					pHGE->_BuildEvent(INPUT_MBUTTONUP, HGEK_RBUTTON, 0, 0, mousePos.x, mousePos.y);	
				hwKeyz[HGEK_RBUTTON] = 0;
				return false;
			}	
			break;	
				
			// Mouse Middle button
			case NSOtherMouseDown:
			{
				POINT mousePos = _GetMousePos ();
				if (-1 != mousePos.x && -1 != mousePos.y)
					pHGE->_BuildEvent(INPUT_MBUTTONDOWN, HGEK_MBUTTON, 0, 0, mousePos.x, mousePos.y);	
				return false;
			}
			break;
			case NSOtherMouseUp:
			{
				POINT mousePos = _GetMousePos ();
				if (-1 != mousePos.x && -1 != mousePos.y)
					pHGE->_BuildEvent(INPUT_MBUTTONUP, HGEK_MBUTTON, 0, 0, mousePos.x, mousePos.y);	
				return false;
			}
			break;
				
			// Mouse moving	
			case NSMouseMoved:
			case NSLeftMouseDragged:
			case NSRightMouseDragged:
			{
				POINT mousePos = _GetMousePos ();
				if (-1 != mousePos.x && -1 != mousePos.y)	
					pHGE->_BuildEvent(INPUT_MOUSEMOVE, 0, 0, 0, mousePos.x, mousePos.y);
				return false;
			}
			break;
				
			// Mouse wheel
			case NSScrollWheel:
			{
				if (0 != [event deltaY])
				{
					POINT mousePos = _GetMousePos ();
					if (-1 != mousePos.x && -1 != mousePos.y)
						pHGE->_BuildEvent(INPUT_MOUSEWHEEL, [event deltaY], 0, 0, mousePos.x, mousePos.y);
					return false;
				}
			}
			break;				
	 
			// Keyboard Keydown
			case NSKeyDown:
			{
				unsigned int fkMask = [event modifierFlags];
				
				int macKey = [event keyCode], winKey = -1;
				// Translate key from mac to Windows
				for (int i = 0; i < sizeof (MapVkey)/sizeof (tVkeyMap); i++)
					if (macKey == MapVkey [i].mac)
					{
						winKey = MapVkey [i].win;
						break;
					}
				
				// Check for spec keys
				if (NSControlKeyMask & fkMask)
				{
					return false;
				}
				else if (NSCommandKeyMask & fkMask) 
				{
					if (![event isARepeat] && (winKey == HGEK_F || (HGEK_M && pHGE->System_GetStateBool(HGE_WINDOWED) == false))) {
						pHGE->System_SetStateBool(HGE_WINDOWED, !pHGE->System_GetStateBool(HGE_WINDOWED));
					}
					return false;
				}
				if (-1 == winKey) return false;
				
				// Set hw key
				hwKeyz [winKey] = 1;
				
				unichar asciiKey = [[event charactersIgnoringModifiers] characterAtIndex:0];
				pHGE->_BuildEvent(INPUT_KEYDOWN, winKey, asciiKey, /*(lparam & 0x40000000) ? HGEINP_REPEAT:0*/0, -1, -1);
				return true;
			}
			break;

			// Keyboard Keyup
			case NSKeyUp:
			{
				// Check for spec keys
				unsigned int fkMask = [event modifierFlags];
				if (NSControlKeyMask & fkMask || NSCommandKeyMask & fkMask) return false;
				
				int macKey = [event keyCode], winKey = -1;
				// Translate key from mac to Windows
				for (int i = 0; i < sizeof (MapVkey)/sizeof (tVkeyMap); i++)
					if (macKey == MapVkey [i].mac)
					{
						winKey = MapVkey [i].win;
						break;
					}
				
				if (-1 == winKey) return false;
				
				// Unset hw key
				hwKeyz [winKey] = 0;
				
				unichar asciiKey = [[event charactersIgnoringModifiers] characterAtIndex:0];
				pHGE->_BuildEvent(INPUT_KEYUP, winKey, asciiKey, 0, -1, -1);
				return true;
			}
				break;
				
			default:
				break;
		}
	}
	 
	return false;
}

void CALL HGE_Impl::Ini_SetInt(const char *section, const char *name, int value)
{
	CSimpleIniA iniFile;
	iniFile.LoadFile ( szIniFile);
	iniFile.SetLongValue(section, name, value );
	iniFile.SaveFile ( szIniFile);
	
}
int CALL HGE_Impl::Ini_GetInt(const char *section, const char *name, int def_val)
{
	CSimpleIniA iniFile;
	iniFile.LoadFile ( szIniFile);
	return iniFile.GetLongValue ( section, name ,def_val);	
}
void CALL HGE_Impl::Ini_SetFloat(const char *section, const char *name, float value)
{
	CSimpleIniA iniFile;
	iniFile.LoadFile ( szIniFile);
	iniFile.SetDoubleValue ( section, name, value );
	iniFile.SaveFile ( szIniFile);
}
float CALL HGE_Impl::Ini_GetFloat(const char *section, const char *name, float def_val)
{
	CSimpleIniA iniFile;
	iniFile.LoadFile ( szIniFile);
	return iniFile.GetDoubleValue (section,name,def_val);
}
void CALL HGE_Impl::Ini_SetString(const char *section, const char *name, const char *value)
{
	CSimpleIniA iniFile;
	iniFile.LoadFile ( szIniFile);
	iniFile.SetValue ( section, name, value );
	iniFile.SaveFile ( szIniFile);
}
char* CALL HGE_Impl::Ini_GetString(const char *section, const char *name, const char *def_val)
{
	CSimpleIniA iniFile;
	iniFile.LoadFile ( szIniFile);
	return (char *)iniFile.GetValue ( section, name ,def_val);
}
