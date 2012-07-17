/*
 *  hge_impl.h
 *  hgecore_osx
 *
 *  Created by Andrew Pepper on 5/3/10.
 *  Copyright 2010 __MyCompanyName__. All rights reserved.
 *
 */


#ifndef HGE_IMPL_H
#define HGE_IMPL_H

#include "../../../include/hge.h"

#include <assert.h>

#define ASSERT assert

#define VERTEX_BUFFER_SIZE 4000

/* The classes below are exported */
#pragma GCC visibility push(default)


// typedef BOOL (WINAPI *GetSystemPowerStatusFunc)(LPSYSTEM_POWER_STATUS);


struct CRenderTargetList
{
	int					width;
	int					height;
	GLuint				framebuffer;
	GLuint				texture;
	bool				bDepth;
	CRenderTargetList*	next;
};

struct CTextureLockInfo
{
	bool				readonly;
	Rect				lockRect;
	void				*data;
};

struct CTextureList
{
	HTEXTURE			tex;
	int					width, realWidth;
	int					height, realHeight;
	int					bpp;
	GLenum				internalFormat, format, type;
	CTextureLockInfo	lockInfo;
	CTextureList*		next;
};

struct CResourceList
{
	char				filename[_MAX_PATH];
	char				password[64];
	CResourceList*		next;
};

struct CStreamList
{
	HSTREAM				hstream;
	void*				data;
	CStreamList*		next;
};

struct CInputEventList
{
	hgeInputEvent		event;
	CInputEventList*	next;
};

struct POINT
{
	int x, y;
};

typedef struct _tVkeyMap
{
	int mac, win, linux;
} tVkeyMap;


void DInit();
void DDone();
bool DFrame();


class HGE_Impl : public HGE
{
	
public:	
	
	static HGE_Impl*	_Interface_Get();

	virtual	void		CALL	Release();
	//	
	virtual bool		CALL	System_Initiate();
	virtual void		CALL	System_Shutdown();
	virtual bool		CALL	System_Start();
	virtual void		CALL	System_SetStateBool  (hgeBoolState   state, bool        value);
	virtual void		CALL	System_SetStateFunc  (hgeFuncState   state, hgeCallback value);
	virtual void		CALL	System_SetStateHwnd  (hgeHwndState   state, HWND        value);
	virtual void		CALL	System_SetStateInt   (hgeIntState    state, int         value);
	virtual void		CALL	System_SetStateString(hgeStringState state, const char *value);
	virtual bool		CALL	System_GetStateBool  (hgeBoolState  );
	virtual hgeCallback	CALL	System_GetStateFunc  (hgeFuncState  );
	virtual HWND		CALL	System_GetStateHwnd  (hgeHwndState  );
	virtual int			CALL	System_GetStateInt   (hgeIntState   );
	virtual const char*	CALL	System_GetStateString(hgeStringState);
	virtual char*		CALL	System_GetErrorMessage();
	virtual	void		CALL	System_Log(const char *format, ...);
	virtual bool		CALL	System_Launch(const char *url) {ASSERT(0);};
	virtual void		CALL	System_Snapshot(const char *filename=0) {ASSERT(0);};
	//	
	virtual void*		CALL	Resource_Load(const char *filename, DWORD *size=0);
	virtual void		CALL	Resource_Free(void *res);
	virtual bool		CALL	Resource_AttachPack(const char *filename, const char *password=0);
	virtual void		CALL	Resource_RemovePack(const char *filename);
	virtual void		CALL	Resource_RemoveAllPacks();
	virtual char*		CALL	Resource_MakePath(const char *filename=0);
	virtual char*		CALL	Resource_EnumFiles(const char *wildcard=0);
	virtual char*		CALL	Resource_EnumFolders(const char *wildcard=0);
	char*						getNextSearchResult (NSString *fileType);
	//	
	virtual	void		CALL	Ini_SetInt(const char *section, const char *name, int value);
	virtual	int 		CALL	Ini_GetInt(const char *section, const char *name, int def_val);
	virtual	void		CALL	Ini_SetFloat(const char *section, const char *name, float value);
	virtual	float		CALL	Ini_GetFloat(const char *section, const char *name, float def_val);
	virtual	void		CALL	Ini_SetString(const char *section, const char *name, const char *value);
	virtual	char*		CALL	Ini_GetString(const char *section, const char *name, const char *def_val);

	//	
	virtual void		CALL	Random_Seed(int seed=0);
	virtual int			CALL	Random_Int(int min, int max);
	virtual float		CALL	Random_Float(float min, float max);
	
	virtual float		CALL	Timer_GetTime();
	virtual float		CALL	Timer_GetDelta();
	virtual int			CALL	Timer_GetFPS();
	//	
	virtual HEFFECT		CALL	Effect_Load(const char *filename, DWORD size=0);
	virtual void		CALL	Effect_Free(HEFFECT eff);
	virtual HCHANNEL	CALL 	Effect_Play(HEFFECT eff);
	virtual HCHANNEL	CALL 	Effect_PlayEx(HEFFECT eff, int volume=100, int pan=0, float pitch=1.0f, bool loop=false);
	//	
	virtual HMUSIC		CALL 	Music_Load(const char *filename, DWORD size=0);
	virtual void		CALL	Music_Free(HMUSIC mus);
	virtual HCHANNEL	CALL 	Music_Play(HMUSIC mus, bool loop, int volume = 100, int order = 0, int row = 0);
	virtual void		CALL	Music_SetAmplification(HMUSIC music, int ampl);
	virtual int			CALL	Music_GetAmplification(HMUSIC music);
	virtual int			CALL	Music_GetLength(HMUSIC music) ;
	virtual void		CALL	Music_SetPos(HMUSIC music, int order, int row);
	virtual bool		CALL	Music_GetPos(HMUSIC music, int *order, int *row);
	virtual void		CALL	Music_SetInstrVolume(HMUSIC music, int instr, int volume);
	virtual int			CALL	Music_GetInstrVolume(HMUSIC music, int instr);
	virtual void		CALL	Music_SetChannelVolume(HMUSIC music, int channel, int volume);
	virtual int			CALL	Music_GetChannelVolume(HMUSIC music, int channel);
	//	
	virtual HSTREAM		CALL	Stream_Load(const char *filename, DWORD size=0);
	virtual void		CALL	Stream_Free(HSTREAM stream);
	virtual HCHANNEL	CALL	Stream_Play(HSTREAM stream, bool loop, int volume = 100);
	//	
	virtual void		CALL 	Channel_SetPanning(HCHANNEL chn, int pan);
	virtual void		CALL 	Channel_SetVolume(HCHANNEL chn, int volume);
	virtual void		CALL 	Channel_SetPitch(HCHANNEL chn, float pitch);
	virtual void		CALL 	Channel_Pause(HCHANNEL chn);
	virtual void		CALL 	Channel_Resume(HCHANNEL chn);
	virtual void		CALL 	Channel_Stop(HCHANNEL chn);
	virtual void		CALL 	Channel_PauseAll();
	virtual void		CALL 	Channel_ResumeAll();
	virtual void		CALL 	Channel_StopAll();
	virtual bool		CALL	Channel_IsPlaying(HCHANNEL chn);
	virtual float		CALL	Channel_GetLength(HCHANNEL chn);
	virtual float		CALL	Channel_GetPos(HCHANNEL chn);
	virtual void		CALL	Channel_SetPos(HCHANNEL chn, float fSeconds);
	virtual void		CALL	Channel_SlideTo(HCHANNEL channel, float time, int volume, int pan = -101, float pitch = -1);
	virtual bool		CALL	Channel_IsSliding(HCHANNEL channel);
	//	
	virtual void		CALL	Input_GetMousePos(float *x, float *y);
	virtual void		CALL	Input_SetMousePos(float x, float y);
	virtual int			CALL	Input_GetMouseWheel();
	virtual bool		CALL	Input_IsMouseOver();
	virtual bool		CALL	Input_KeyDown(int key);
	virtual bool		CALL	Input_KeyUp(int key);
	virtual bool		CALL	Input_GetKeyState(int key);
	virtual char*		CALL	Input_GetKeyName(int key);
	virtual int			CALL	Input_GetKey();
	virtual int			CALL	Input_GetChar();
	virtual bool		CALL	Input_GetEvent(hgeInputEvent *event);
    virtual void        CALL    Input_SetCursor(HCURSOR cursor);	
	
	virtual bool		CALL	Gfx_BeginScene(HTARGET target=0);
	virtual void		CALL	Gfx_EndScene();
	virtual void		CALL	Gfx_Clear(DWORD color);
	virtual void		CALL	Gfx_RenderLine(float x1, float y1, float x2, float y2, DWORD color=0xFFFFFFFF, float z=0.5f);
	virtual void		CALL	Gfx_RenderTriple(const hgeTriple *triple);
	virtual void		CALL	Gfx_RenderQuad(const hgeQuad *quad);
	virtual hgeVertex*	CALL	Gfx_StartBatch(int prim_type, HTEXTURE tex, HTEXTURE tex_mask, int blend, int *max_prim);
	virtual void		CALL	Gfx_FinishBatch(int nprim);
	virtual void		CALL	Gfx_SetClipping(int x=0, int y=0, int w=0, int h=0);
	virtual void		CALL	Gfx_SetTransform(float x=0, float y=0, float dx=0, float dy=0, float rot=0, float hscale=0, float vscale=0);

	virtual HTARGET		CALL	Target_Create(int width, int height, bool zbuffer);
	virtual void		CALL	Target_Free(HTARGET target);
	virtual HTEXTURE	CALL	Target_GetTexture(HTARGET target);
	
	virtual HTEXTURE	CALL	Texture_Create(int width, int height);
	virtual HTEXTURE	CALL	Texture_Load(const char *filename, DWORD size=0, bool bMipmap=false);
	virtual void		CALL	Texture_Free(HTEXTURE tex);
	virtual int			CALL	Texture_GetWidth(HTEXTURE tex, bool bOriginal=false);
	virtual int			CALL	Texture_GetHeight(HTEXTURE tex, bool bOriginal=false);
	virtual void*		CALL	Texture_Lock(HTEXTURE tex, bool bReadOnly=true, int left=0, int top=0, int width=0, int height=0);
	virtual void		CALL	Texture_Unlock(HTEXTURE tex);
	
	bool				_ProcessMessage (NSEvent *event);
	bool				_GfxInit();
	void				_CreateWindow ();
	void				_GfxDone();
	bool				_GfxRestore();
//	void				_AdjustWindow();
//	void				_Resize(int width, int height);
	bool				_init_lost();
	void				_OpeGLCapsGet ();
	bool				_GfxContextCreate();
	POINT				_GetMousePos ();
	
	
	void				_render_batch(bool bEndScene=false);
	void				_SetBlendMode(int blend);
	void				_SetProjectionMatrix(int width, int height, bool flip);
	
	
	//////// Implementation ////////
	
	// void				_FocusChange(bool bAct);
	void				_PostError(const char *error);
	
	NSWindow			*hwnd;
	NSRect				rect;
	bool				bActive;
	char				szError[256];
	char				szAppPath[_MAX_PATH];
	char				szIniString[256];
	Application			*application;	
	
	// System States
	bool				bRendererInit;
	bool				bSoundInit;
	int					nByteOrder;
	bool				(*procFrameFunc)();
	bool				(*procRenderFunc)();
	bool				(*procFocusLostFunc)();
	bool				(*procFocusGainFunc)();
	bool				(*procGfxRestoreFunc)();
	bool				(*procExitFunc)();
	const char*			szIcon;
	char				szWinTitle[256];
	int					nScreenWidth;
	int					nScreenHeight;
	int					nScreenBPP;
	bool				bWindowed;
	bool				bZBuffer;
	bool				bTextureFilter;
	char				szIniFile[_MAX_PATH];
	char				szLogFile[_MAX_PATH];
	bool				bUseSound;
	int					nSampleRate;
	int					nFXVolume;
	int					nMusVolume;
	int					nStreamVolume;
	int					nHGEFPS;
	bool				bHideMouse;
	bool				bDontSuspend;
	int					nPowerStatus;
	
	// Graphix
	bool				bGLInitDone;
	bool				bKeepDesktopMode;
	int					mDesktopWidth, mDesktopHeight, mDesktopBPP, mDesktopRR;
	NSWindow*			window;
	NSOpenGLView*		glView;
	NSOpenGLContext*	glContextWindowed, *glContextFullscreen;
	CTextureList*		textures;
	hgeVertex*			VertArray;
	hgeVertex*			glVertexBuffer;
	unsigned short*		glIndexBuffer;
	int					nVertexBufferSize, nIndexBufferSize;
	CRenderTargetList*	pTargets;
	CRenderTargetList*	pCurTarget;	
	int					nPrim;
	int					CurPrimType;
	int					CurBlendMode;
	HTEXTURE			CurTexture;	
	// OpenGL Caps
	bool				bGLVARSupported;
	bool				bGLAppleFenceSupported;
	GLint				nGLMaxTexUnits;
	GLint				nGLMaxTexSize;
	GLuint				nGLFence;
	
	// Audio
	bool				hBass;
	bool				bSilent;
	CStreamList*		streams;
	bool				_SoundInit();
	void				_SoundDone();
	void				_SetMusVolume(int vol);
	void				_SetStreamVolume(int vol);
	void				_SetFXVolume(int vol);
	
	
	// Resources
	NSBundle			*mainBundle;
	char				szTmpFilename[_MAX_PATH];
	CResourceList*		res;
	glob_t				fileSearcher;
	NSFileManager		*localFileManager;
	bool				hSearch;
	int					searchIndex;
	char				szFindFileData[_MAX_PATH];

	// WIN32_FIND_DATA		SearchData;	
	
	// Timer
	float				fTime;
	float				fDeltaTime;
	DWORD				nFixedDelta;
	int					nFPS;
	double				t0, t0fps, dt;
	int					cfps;
	
	int					VKey;
	int					Char;
	int					Zpos;
	float				Xpos;
	float				Ypos;
	bool				bMouseOver;
	bool				bCaptured;
	char				keyz[256], hwKeyz [256];
    HCURSOR             m_cursor;	
	CInputEventList*	queue;
	void				_UpdateMouse();
	void				_InputInit();
	void				_ClearQueue();
	void				_BuildEvent(int type, int key, int scan, int flags, int x, int y);
	
	bool				bTextureClamp;
	
#ifdef DEMO
	bool				bDMO;
#endif
	
private:
	HGE_Impl();
	
};


const tVkeyMap MapVkey [] =
{
	/*rbKeyUp*/                     {126, 0x26, 103},
	/*rbKeyDown*/                   {125, 0x28, 108},
	/*rbKeyLeft*/                   {123, 0x25, 105},
	/*rbKeyRight*/                  {124, 0x27, 106},
	/*rbKeyDelete*/					{117, 0x2e, 111},
	/*rbKeyEnter*/                  {76, -1, 28},
	/*rbKeyHome*/                   {115, 0x24, 102},
	/*rbKeyEnd*/                    {119, 0x23, 107},
	/*rbKeyPageDown*/               {121, 0x22, 109},
	/*rbKeyPageUp*/                 {116, 0x21, 104},
	/*rbKeyReturn*/                 {36, 0xd, -1},
	/*rbKeyBackspace*/              {51, 0x08, 14},
	/*rbKeyTab*/                    {48, 0x9, 15},
	/*rbKeySpacebar*/               {49, 0x20, 57},
	/*rbKeyShift*/                  {56, 0x10, -1},
	/*rbKeyControl*/                {59, 0x11, -1},
	/*rbKeyMenu*/                   {58, 0x18, 139},        // The Alt key
	/*rbKeyPrintScreen*/			{-1, 42, 210},
	/*rbKeyEscape*/                 {53, 0x1b, 1},
	/*rbKeyCapsLock*/               {57, 0x14, 58},
	/*rbKeyHelp*/                   {114, 0x2f, 138},
	/*rbKeyF1*/                     {122, 112, 59},
	/*rbKeyF2*/                     {120, 113, 60},
	/*rbKeyF3*/                     {99, 114, 61},
	/*rbKeyF4*/                     {118, 115, 62},
	/*rbKeyF5*/                     {96, 116, 63},
	/*rbKeyF6*/                     {97, 117, 64},
	/*rbKeyF7*/                     {98, 118, 65},
	/*rbKeyF8*/                     {100, 119, 66},
	/*rbKeyF9*/                     {101, 120, 67},
	/*rbKeyF10*/                    {109, 121, 68},
	/*rbKeyF11*/                    {103, 122, 87},
	/*rbKeyF12*/                    {111, 123, 88},
	/*rbKeyMacFn*/                  {63, -1, -1},
	/*rbKeyMacOption*/              {58, -1, -1},
	/*rbKeyMacCommand*/             {55, -1, -1},
	/*rbKeyWinLeftWindow*/			{-1, 91, -1},   // On "Natural" keyboards
	/*rbKeyWinRightWindow*/			{-1, 92, -1},   // On "Natural" keyboards
	/*rbKeyWinApplication*/			{110, 93, -1},  // On "Natural" keyboards
	/*rbKeyQ*/                      {12, 81, 16},
	/*rbKeyW*/                      {13, 87, 17},
	/*rbKeyE*/                      {14, 69, 18},
	/*rbKeyR*/                      {15, 82, 19},
	/*rbKeyT*/                      {17, 84, 20},
	/*rbKeyY*/                      {16, 89, 21},
	/*rbKeyU*/                      {32, 85, 22},
	/*rbKeyI*/                      {34, 73, 23},
	/*rbKeyO*/                      {31, 79, 24},
	/*rbKeyP*/                      {35, 80, 25},
	/*rbKeyA*/                      {0, 65, 30},
	/*rbKeyS*/                      {1, 83, 31},
	/*rbKeyD*/                      {2, 68, 32},
	/*rbKeyF*/                      {3, 70, 33},
	/*rbKeyG*/                      {5, 71, 34},
	/*rbKeyH*/                      {4, 72, 35},
	/*rbKeyJ*/                      {38, 74, 36},
	/*rbKeyK*/                      {40, 75, 37},
	/*rbKeyL*/                      {37, 76, 38},
	/*rbKeyZ*/                      {6, 90, 44},
	/*rbKeyX*/                      {7, 88, 45},
	/*rbKeyC*/                      {8, 67, 46},
	/*rbKeyV*/                      {9, 86, 47},
	/*rbKeyB*/                      {11, 66, 48},
	/*rbKeyN*/                      {45, 78, 49},
	/*rbKeyM*/                      {46, 77, 50},
	/*rbKey0*/                      {29, 48, 11},
	/*rbKey1*/                      {18, 49, 2},
	/*rbKey2*/                      {19, 50, 3},
	/*rbKey3*/                      {20, 51, 4},
	/*rbKey4*/                      {21, 52, 5},
	/*rbKey5*/                      {23, 53, 6},
	/*rbKey6*/                      {22, 54, 7},
	/*rbKey7*/                      {26, 55, 8},
	/*rbKey8*/                      {28, 56, 9},
	/*rbKey9*/                      {25, 57, 10},
	/*rbKeyPeriod*/                 {47, 190, 52},
	/*rbKeyComma*/                  {43, 188, 51},
	/*rbKeySlash*/                  {44, 191, 53},  //		The key with /? generally next to right shift key.
	/*rbKeyNum0*/                   {82, 96, 82},   //      On numeric keypad or with NumLock
	/*rbKeyNum1*/                   {83, 97, 79},   //      On numeric keypad or with NumLock
	/*rbKeyNum2*/                   {84, 98, 80},   //      On numeric keypad or with NumLock
	/*rbKeyNum3*/                   {85, 99, 81},   //      On numeric keypad or with NumLock
	/*rbKeyNum4*/                   {86, 100, 75},  //      On numeric keypad or with NumLock
	/*rbKeyNum5*/                   {87, 101, 76},  //      On numeric keypad or with NumLock
	/*rbKeyNum6*/                   {88, 102, 77},  //      On numeric keypad or with NumLock
	/*rbKeyNum7*/                   {89, 103, 71},  //      On numeric keypad or with NumLock
	/*rbKeyNum8*/                   {91, 104, 72},  //      On numeric keypad or with NumLock
	/*rbKeyNum9*/                   {92, 105, 73},  //      On numeric keypad or with NumLock
	/*rbKeyMultiply*/               {67, 106, 55},  //      On numeric keypad or with NumLock
	/*rbKeyAdd*/                    {69, 107, 78},  //      On numeric keypad or with NumLock
	/*rbKeySubtract*/               {78, 109, 74},  //      On numeric keypad or with NumLock
	/*rbKeyDivide*/                 {75, 111, 98},  //      On numeric keypad or with NumLock
	/*rbKeyDecimal*/                {65, 110, 83},  //      On numeric keypad or with NumLock
	/*rbKeyNumEqual*/               {81, -1, 117},  //      On numeric keypad or with NumLock
	/*grave*/						{50, 0xC0, -1},
	/*grave*/						{10, 0xC0, -1},
};


extern HGE_Impl*		pHGE;


#pragma GCC visibility pop

#endif