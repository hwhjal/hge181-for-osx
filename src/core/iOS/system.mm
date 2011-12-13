/*
 *  system.cpp
 *  hgecore_osx
 *
 *  Created by Andrew Pepper on 5/3/10.
 *  Copyright 2010 __MyCompanyName__. All rights reserved.
 *
 */

#include "main.h"
#include "../Ini/SimpleIni.h"

#import "appdelegate.h"
#import "eaglview.h"
#import "viewcontroller.h"


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
	
	window = 0;
	glView = 0;;
	
	bActive = false;
	szError[0]=0;
	
	pTargets=0;
	pCurTarget=0;
	VertArray=0;
	textures=0;
	nVertexBufferSize = nIndexBufferSize = 0;
	glVertexBuffer = nil;
	glIndexBuffer = nil;
	glVertexBufferCopy = nil;
	bGLVARSupported = false;
	bGLAppleFenceSupported = false;
	nGLMaxTexUnits = 0;
	nGLMaxTexSize = 0;
	bKeepDesktopMode = false;
	
	queue=0;
	Char=VKey=Zpos=0;
	Xpos=Ypos=0.0f;
	bMouseOver=true;
	bCaptured=false;
	
	nHGEFPS= 60; // HGEFPS_UNLIMITED;
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
	nScreenWidth=0;
	nScreenHeight=0;
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
	bTerminate = false;
	nBatchID = 0;
	
	bTextureClamp = false;
	bMainMenuHidden = false;
	
	hBass=0;
	bSilent=false;
	streams=0;
	
	hSearch=false;
	res=0;	
	
	iconName = 0;
	
	CurBlendMode = 0;
	CurTexture = 0;
	CurPrimType = 0;
	
	hwnd = 0;
	glVewController = 0;
	glDefaultRenderBuffer = 0;
		
	NSAutoreleasePool *pool = [NSAutoreleasePool new];

	NSBundle *mainBundle = [NSBundle mainBundle];
	NSString *res = [mainBundle resourcePath];
	[res getCString:szAppPath maxLength:sizeof(szAppPath) encoding:NSASCIIStringEncoding];
	strcat (szAppPath, "/");
	
	[pool release];
	
	// Get byteorder
	char prop_buff [1024] = {};
	int prop [2], be_res;
	unsigned int *p_res = (unsigned int *) prop_buff;
	size_t prop_buf_size;
	prop [0] = CTL_HW; prop [1] = HW_BYTEORDER;
	prop_buf_size = sizeof (prop_buff);
	be_res = sysctl (prop, 2, prop_buff, &prop_buf_size, NULL, 0);
	nByteOrder = *p_res;
	
	if(nHGEFPS>0) nFixedDelta=int(1000.0f/nHGEFPS);
		else nFixedDelta=0;	
}


void HGE_Impl::_FocusChange(bool bAct)
{
	bActive = bAct;
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
	
	// Input init
	_InputInit();
	
	// Gfx init
	if (!_GfxInit())
	{
		System_Shutdown();
		[pool release];
		return false;
	}
	
	// Sound init
	if (!_SoundInit ())
		System_Log("Sound init failed.\n");
	
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
}

	
void CALL HGE_Impl::System_SetStateBool (hgeBoolState state, bool value)
{
	switch(state)
	{
		case HGE_WINDOWED:
			break;
			
		case HGE_ZBUFFER:		
			if(!bGLInitDone)
				bZBuffer=value;
			break;
			
		/*case HGE_TEXTUREFILTER:
			bTextureFilter=value;
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
			
		case HGE_USESOUND:
			if(bUseSound!=value)
			{
				bUseSound=value;
				if(bUseSound && hwnd) _SoundInit();
				if(!bUseSound && hwnd) _SoundDone();
			}
		break;
			
		case HGE_HIDEMOUSE:
			bHideMouse=value;
		break;
			
		case HGE_DONTSUSPEND:
			bDontSuspend=value;
		break;
			
	#ifdef DEMO
		case HGE_SHOWSPLASH:
			bDMO=value;
		break;
	#endif
		case HGE_TEXTURECLAMP:
			bTextureClamp = value;
		break;
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
		case HGE_INIFILE:		
			if(value) strcpy(szIniFile, Resource_MakePath(value));
		else szIniFile[0]=0;
			break;
		case HGE_LOGFILE:		if(value)
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
		case HGE_HWND:			return 0;
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
	
	System_Log("The End.");
}

bool CALL HGE_Impl::System_Start()
{
	if(!procFrameFunc) {
		_PostError("System_Start: No frame function defined");
		return false;
	}

	[GLAppAppDelegate forceLoadChunk];	
	
	bActive = true;	
	
	NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
	int retVal = UIApplicationMain(nil, nil, nil, @"GLAppAppDelegate");
	
	[pool release];
	return true;
}

void HGE_Impl::Terminate()
{
	bTerminate = true;
}

void CALL HGE_Impl::Release()
{
	nRef--;
	
	if(!nRef)
	{
		pHGE->System_Shutdown();
		Resource_RemoveAllPacks();
		delete pHGE;
		pHGE=0;
	}
}

POINT HGE_Impl::_GetMousePos ()
{
	
	POINT res = {};
	// NSPoint mousePos = [NSEvent mouseLocation];
	/*int displayH = CGDisplayPixelsHigh (kCGDirectMainDisplay);
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
		}	
	}
	else
	{
		mousePos.y = displayH - mousePos.y;
	}*/

	
//	res.x = mousePos.x;
//	res.y = mousePos.y;
	
	return res;
}


bool HGE_Impl::_ProcessMessage (int event, int subevent, int x, int y, int event_data1)
{
	if (0 != event)
	{
		switch (event)
		{
			// Mouse events
			case c_EVENT_MOUSE:
				if (c_EVENT_MOUSE_DOWN == subevent && hwKeyz[HGEK_LBUTTON] != 1)
				{
					pHGE->_BuildEvent(INPUT_MBUTTONDOWN, HGEK_LBUTTON, 0, 0, x, y);
					hwKeyz[HGEK_LBUTTON] = 1;
					NSLog(@"!!!!!!!!!!!!!!!!!");
					return true;
				}
				if (c_EVENT_MOUSE_UP == subevent)
				{
					pHGE->_BuildEvent(INPUT_MBUTTONUP, HGEK_LBUTTON, 0, 0, x, y);
					hwKeyz[HGEK_LBUTTON] = 0;
					return true;
				}
				if (c_EVENT_MOUSE_MOVE == subevent)
				{
					pHGE->_BuildEvent(INPUT_MOUSEMOVE, 0, 0, 0, x, y);
					return true;
				}
			break;
				
			// Keyboard events
			case c_EVENT_KEYBOARD:
				break;
		}
	}

	/*if (nil != event)
	{	
//		[hwnd makeKeyAndOrderFront: hwnd];
		
		switch ([event type])
		{
	 
			// Keyboard Keydown
			case NSKeyDown:
			{
				// Check for spec keys
				unsigned int fkMask = [event modifierFlags];
				
				int macKey = [event keyCode];
				if ((NSCommandKeyMask & fkMask) && macKey == 3)
				{
					pHGE->System_SetState(HGE_WINDOWED, !pHGE->System_GetState(HGE_WINDOWED));
					return true;
				}
				
				if (NSControlKeyMask & fkMask || NSCommandKeyMask & fkMask) return false;
				
				int winKey = -1;
				// Translate key from mac to Windows
				for (int i = 0; i < sizeof (MapVkey)/sizeof (tVkeyMap); i++)
					if (macKey == MapVkey [i].mac)
					{
						winKey = MapVkey [i].win;
						break;
					}
	
				if (-1 == winKey) return false;
				
				// Set hw key
				hwKeyz [winKey] = 1;
				
				unichar asciiKey = [[event charactersIgnoringModifiers] characterAtIndex:0];
				pHGE->_BuildEvent(INPUT_KEYDOWN, winKey, asciiKey, 0, -1, -1);
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
			
			default:
				break;
		}
	}*/
	 
	return false;
}

void HGE_Impl::ios_setupHGE (int w, int h, int fps)
{
	nScreenWidth = w; nScreenHeight = h;
	nHGEFPS=fps;
	if(nHGEFPS>0)
		nFixedDelta=int(1000.0f/fps);
	else
		nFixedDelta=0;
	
	// Gfx init
	if (!_GfxInit())
	{
		System_Shutdown();
	}	
}


bool HGE_Impl::ios_renderFrame ()
{
	if (!bActive)
		return false;
	
	// Check if mouse is over HGE window for Input_IsMouseOver		
	// _UpdateMouse();
	
	// If HGE window is focused or we have the "don't suspend" state - process the main loop
	
	if(bActive || bDontSuspend)
	{
		// Ensure we have at least 1ms time step
		// to not confuse user's code with 0
		
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
			if(t0-t0fps <= 1) cfps++;
			else
			{
				nFPS=cfps; cfps=0; t0fps=t0;
				/// _UpdatePowerStatus();
			}
			
			// Do user's stuff
			if(procFrameFunc())
				if(!pHGE->procExitFunc || (pHGE->procExitFunc && pHGE->procExitFunc()) )
					return true;
			if(procRenderFunc) 
				procRenderFunc();
			
			_ClearQueue();			
		}		
		// If we have a fixed frame rate and the time
		// for the next frame isn't too close, sleep a bit		
		else
		{
			if(nFixedDelta && dt+3 < nFixedDelta)
				usleep (10);
		}
	}
	else
		usleep(10);

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
