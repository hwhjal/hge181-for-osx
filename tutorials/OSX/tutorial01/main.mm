#include <iostream>


#import <Cocoa/Cocoa.h>

#define _HGE_TARGET_OSX_

#include <math.h>

#include "../../../include/hge.h"
#include "../../../include/hgecolor.h"
#include "../../../include/hgesprite.h"
#include "../../../include/hgedistort.h"
#include "../../../include/hgefont.h"
#include "../../../include/hgeparticle.h"

// Pointer to the HGE interface (helper classes require this to work)

int SCREEN_WIDTH  = 1280;
int SCREEN_HEIGHT = 1024;

#define MIN_OBJECTS	100
#define MAX_OBJECTS 2000

struct sprObject
{
	float x,y;
	float dx,dy;
	float scale,rot;
	float dscale,drot;
	DWORD color;
};

sprObject*	pObjects;
int			nObjects;
int			nBlend;

// Pointer to the HGE interface (helper classes require this to work)

HGE *hge=0;

// Resource handles

HTEXTURE			tex, bgtex;
hgeSprite			*spr, *bgspr;
hgeFont				*fnt;

// Set up blending mode for the scene



void SetBlend(int blend)
{
	static int sprBlend[5]=
	{
		BLEND_COLORMUL | BLEND_ALPHABLEND | BLEND_NOZWRITE,
		BLEND_COLORADD | BLEND_ALPHABLEND | BLEND_NOZWRITE,
		BLEND_COLORMUL | BLEND_ALPHABLEND | BLEND_NOZWRITE,
		BLEND_COLORMUL | BLEND_ALPHAADD   | BLEND_NOZWRITE,
		BLEND_COLORMUL | BLEND_ALPHABLEND | BLEND_NOZWRITE
	};
	
	static DWORD fntColor[5]=
	{
		0xFFFFFFFF, 0xFF000000, 0xFFFFFFFF, 0xFF000000, 0xFFFFFFFF
	};
	
	static DWORD sprColors[5][5]=
	{
		{ 0xFFFFFFFF, 0xFFFFE080, 0xFF80A0FF, 0xFFA0FF80, 0xFFFF80A0 },
		{ 0xFF000000, 0xFF303000, 0xFF000060, 0xFF006000, 0xFF600000 },
		{ 0x80FFFFFF, 0x80FFE080, 0x8080A0FF, 0x80A0FF80, 0x80FF80A0 },
		{ 0x80FFFFFF, 0x80FFE080, 0x8080A0FF, 0x80A0FF80, 0x80FF80A0 },
		{ 0x40202020, 0x40302010, 0x40102030, 0x40203010, 0x40102030 }
	};
	
	if(blend>4) blend=0;
	nBlend=blend;
	
	spr->SetBlendMode(sprBlend[blend]);
	fnt->SetColor(fntColor[blend]);
	for(int i=0;i<MAX_OBJECTS;i++) pObjects[i].color=sprColors[blend][hge->Random_Int(0,4)];
}

bool FrameFunc()
{
	float dt=hge->Timer_GetDelta();
	int i;
	
	// Process keys
	if(hge->Input_GetKeyState(HGEK_W))
	{ 
		SCREEN_WIDTH  = 1280;
		SCREEN_HEIGHT = 1024;		
		hge->System_SetState(HGE_SCREENWIDTH, 1280);
		hge->System_SetState(HGE_SCREENHEIGHT, 1024);		
		hge->System_SetState(HGE_WINDOWED, false);
	}
	if(hge->Input_GetKeyState(HGEK_Q))
	{ 
		SCREEN_WIDTH  = 800;
		SCREEN_HEIGHT = 600;
		hge->System_SetState(HGE_SCREENWIDTH, 800);
		hge->System_SetState(HGE_SCREENHEIGHT, 600);		
		hge->System_SetState(HGE_WINDOWED, true);
	}
	
	switch(hge->Input_GetKey())
	{
		case HGEK_UP:		if(nObjects<MAX_OBJECTS) nObjects+=100; break;
		case HGEK_DOWN:		if(nObjects>MIN_OBJECTS) nObjects-=100; break;
		case HGEK_SPACE:	SetBlend(++nBlend); break;
		case HGEK_ESCAPE:	return true;
	}
	
	// Update the scene
	
	for(i=0;i<nObjects;i++)
	{
		pObjects[i].x+=pObjects[i].dx*dt;
		if(pObjects[i].x>SCREEN_WIDTH || pObjects[i].x<0) pObjects[i].dx=-pObjects[i].dx;
		pObjects[i].y+=pObjects[i].dy*dt;
		if(pObjects[i].y>SCREEN_HEIGHT || pObjects[i].y<0) pObjects[i].dy=-pObjects[i].dy;
		pObjects[i].scale+=pObjects[i].dscale*dt;
		if(pObjects[i].scale>2 || pObjects[i].scale<0.5) pObjects[i].dscale=-pObjects[i].dscale;
		pObjects[i].rot+=pObjects[i].drot*dt;
	}
	
	return false;
}


bool RenderFunc()
{
	int i;
	
	// Render the scene
	
	hge->Gfx_BeginScene();
	hge->Gfx_Clear(0);
	bgspr->Render(0,0);
	
	for(i=0;i<nObjects;i++)
	{
		spr->SetColor(pObjects[i].color); 
		spr->RenderEx(pObjects[i].x, pObjects[i].y, pObjects[i].rot, pObjects[i].scale);
	}
	
	fnt->printf(7, 7, HGETEXT_LEFT, "UP and DOWN to adjust number of hares: %d\nSPACE to change blending mode: %d\nFPS: %d, dt:%.3f", nObjects, nBlend, hge->Timer_GetFPS(), hge->Timer_GetDelta());
	
	hge->Gfx_EndScene();
	
	return false;
}

int main (int argc, char * const argv[])
{
	int i;
	
	hge = hgeCreate(HGE_VERSION);
	
	// Set desired system states and initialize HGE
	
	hge->System_SetState(HGE_LOGFILE, "hge_tut07.log");
	hge->System_SetState(HGE_FRAMEFUNC, FrameFunc);
	hge->System_SetState(HGE_RENDERFUNC, RenderFunc);
	hge->System_SetState(HGE_TITLE, "HGE Tutorial 07 - Thousand of Hares");
	hge->System_SetState(HGE_USESOUND, false);
	hge->System_SetState(HGE_WINDOWED, false);
	// hge->System_SetState(HGE_FPS, 60);
	hge->System_SetState(HGE_SCREENWIDTH, SCREEN_WIDTH);
	hge->System_SetState(HGE_SCREENHEIGHT, SCREEN_HEIGHT);
	hge->System_SetState(HGE_SCREENBPP, 32);
	
	if(hge->System_Initiate())
	{
		
		// Load textures
		
		bgtex=hge->Texture_Load("bg2.png");
		tex=hge->Texture_Load("zazaka.png");
		if(!bgtex || !tex)
		{
			// If one of the data files is not found,
			// display an error message and shutdown
			// MessageBox(NULL, "Can't load BG2.PNG or ZAZAKA.PNG", "Error", MB_OK | MB_ICONERROR | MB_APPLMODAL);
			// hge->System_Shutdown();
			hge->Release();
			return 0;
		}
		
		// Load font, create sprites
		
		fnt=new hgeFont("font2.fnt");
		spr=new hgeSprite(tex,0,0,64,64);
		spr->SetHotSpot(32,32);
		
		bgspr=new hgeSprite(bgtex,0,0,SCREEN_WIDTH,SCREEN_HEIGHT);
		bgspr->SetBlendMode(BLEND_COLORADD | BLEND_ALPHABLEND | BLEND_NOZWRITE);
		bgspr->SetColor(0xFF000000,0);
		bgspr->SetColor(0xFF000000,1);
		bgspr->SetColor(0xFF000040,2);
		bgspr->SetColor(0xFF000040,3);
		
		// Initialize objects list
		
		pObjects=new sprObject[MAX_OBJECTS];
		nObjects=1000;
		
		for(i=0;i<MAX_OBJECTS;i++)
		{
			pObjects[i].x=hge->Random_Float(0,SCREEN_WIDTH);
			pObjects[i].y=hge->Random_Float(0,SCREEN_HEIGHT);
			pObjects[i].dx=hge->Random_Float(-200,200);
			pObjects[i].dy=hge->Random_Float(-200,200);
			pObjects[i].scale=hge->Random_Float(0.5f,2.0f);
			pObjects[i].dscale=hge->Random_Float(-1.0f,1.0f);
			pObjects[i].rot=hge->Random_Float(0,M_PI*2);
			pObjects[i].drot=hge->Random_Float(-1.0f,1.0f);
		}
		
		SetBlend(0);
		
		// Let's rock now!
		
		hge->System_Start();
		
		// Delete created objects and free loaded resources
		
		delete[] pObjects;
		delete fnt;
		delete spr;
		delete bgspr;
		hge->Texture_Free(tex);
		hge->Texture_Free(bgtex);
	}
	
	// Clean up and shutdown
	
	// hge->System_Shutdown();
	hge->Release();
	return 0;
}





//HGE *hge = 0;
//GLclampf c = 0.0f;	
//
//// Pointers to the HGE objects we will use
//hgeSprite*			spr;
//hgeSprite*			spt;
//hgeFont*			fnt;
//hgeParticleSystem*	par;
//
//// Handles for HGE resourcces
//HTEXTURE			tex;
//HEFFECT				snd;
//
////int scrDx = 800;
////int scrDy = 600;
////const bool bWnd = true;
//int scrDx = 1280;
//int scrDy = 1024;
//bool bWnd = false;
//
//
//// Some "gameplay" variables
//float x=100.0f, y=100.0f;
//float dx=0.0f, dy=0.0f;
//
//const float speed=190;
//const float friction=0.98f;
//
//bool FrameFunc()
//{
//	float dt=hge->Timer_GetDelta();	
//	
//	 // Process keys
//	if (hge->Input_GetKeyState(HGEK_ESCAPE)) return true;
//	if (hge->Input_GetKeyState(HGEK_LEFT))	dx-=speed*dt;
//	if (hge->Input_GetKeyState(HGEK_RIGHT)) dx+=speed*dt;
//	if (hge->Input_GetKeyState(HGEK_UP)) dy-=speed*dt;
//	if (hge->Input_GetKeyState(HGEK_DOWN)) dy+=speed*dt;
//	
//	if(hge->Input_GetKeyState(HGEK_W))
//	{
//		scrDx = 1280;
//		scrDy = 1024;		
//		hge->System_SetState(HGE_SCREENWIDTH, 1280);
//		hge->System_SetState(HGE_SCREENHEIGHT, 1024);		
//		hge->System_SetState(HGE_WINDOWED, false);
//	}
//	if(hge->Input_GetKeyState(HGEK_Q))
//	{ 
//		scrDx = 800;
//		scrDy = 600;
//		hge->System_SetState(HGE_SCREENWIDTH, 800);
//		hge->System_SetState(HGE_SCREENHEIGHT, 600);		
//		hge->System_SetState(HGE_WINDOWED, true);
//	}
//	
//	
//	
//	// Do some movement calculations and collision detection	
//	dx*=friction; dy*=friction; x+=dx; y+=dy;
//	if(x>scrDx) {x=scrDx-(x-scrDx);dx=-dx;}
//	if(x<16) {x=16+16-x;dx=-dx;}
//	if(y>scrDy) {y=scrDy-(y-scrDy);dy=-dy;}
//	if(y<16) {y=16+16-y;dy=-dy;}
//	
//	// Update particle system
//	par->info.nEmission=(int)(dx*dx+dy*dy)*2;
//	par->MoveTo(x,y);
//	par->Update(dt);
//	
//	return false;
//}
//
//
//// This function will be called by HGE when
//// the application window should be redrawn.
//// Put your rendering code here.
//bool RenderFunc()
//{
//	// Render graphics
//	hge->Gfx_BeginScene();
//	hge->Gfx_Clear(0);
//	par->Render();
//	spr->Render(x, y);
//	fnt->printf(5, 5, HGETEXT_LEFT, "dt:%.3f\nFPS:%d (constant)", hge->Timer_GetDelta(), hge->Timer_GetFPS());
//	hge->Gfx_EndScene();
//	
//	return false;
//}
//
//
//int main (int argc, char * const argv[])
//{
//	hge = hgeCreate (HGE_VERSION);
//	
//	// Set up log file, frame function, render function and window title
//	hge->System_SetState(HGE_LOGFILE, "hge_tut02.log");
//	hge->System_SetState(HGE_FRAMEFUNC, FrameFunc);
//	hge->System_SetState(HGE_RENDERFUNC, RenderFunc);
//	hge->System_SetState(HGE_TITLE, "HGE Tutorial - Using input, sound and rendering");
//	hge->System_SetState(HGE_FPS, 60);
//	
//	// Set up video mode 
//	hge->System_SetState(HGE_WINDOWED, bWnd);
//	hge->System_SetState(HGE_ZBUFFER, true);
//	hge->System_SetState(HGE_SCREENWIDTH, scrDx);
//	hge->System_SetState(HGE_SCREENHEIGHT, scrDy);
//	hge->System_SetState(HGE_SCREENBPP, 32);
//	
//	if(hge->System_Initiate())
//	{
//		tex=hge->Texture_Load("particles.png");
//		
//		// Create and set up a sprite
//		spr=new hgeSprite(tex, 96, 64, 32, 32);
//		spr->SetColor(0xFFFFA000);
//		spr->SetHotSpot(16,16);
//		
//		// Load a font
//		fnt=new hgeFont("font1.fnt");
//		
//		// Create and set up a particle system
//		spt=new hgeSprite(tex, 32, 32, 32, 32);
//		spt->SetBlendMode(BLEND_COLORMUL | BLEND_ALPHAADD | BLEND_NOZWRITE);
//		spt->SetHotSpot(16,16);
//		par=new hgeParticleSystem("trail.psi",spt);
//		par->Fire();
//		
//		// Let's rock now!
//		hge->System_Start();
//		
//		// Delete created objects and free loaded resources
//		delete par;
//		delete fnt;
//		delete spt;
//		delete spr;
//		hge->Texture_Free(tex);		
//	}	
//	
//    return 0;
//}
