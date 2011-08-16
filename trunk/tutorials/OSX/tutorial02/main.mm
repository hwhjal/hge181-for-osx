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

HGE *hge = 0;
GLclampf c = 0.0f;	

// Pointers to the HGE objects we will use
hgeSprite*			spr;
hgeSprite*			spt;
hgeFont*			fnt;
hgeParticleSystem*	par;

// Handles for HGE resourcces
HTEXTURE			tex;
HEFFECT				snd;

int scrDx = 800;
int scrDy = 600;
const bool bWnd = true;
//int scrDx = 1280;
//int scrDy = 1024;
//bool bWnd = false;


// Some "gameplay" variables
float x=100.0f, y=100.0f;
float dx=0.0f, dy=0.0f;

const float speed=190;
const float friction=0.98f;

bool FrameFunc()
{
	float dt=hge->Timer_GetDelta();	
	
	 // Process keys
	if (hge->Input_GetKeyState(HGEK_ESCAPE)) return true;
	if (hge->Input_GetKeyState(HGEK_LEFT))	dx-=speed*dt;
	if (hge->Input_GetKeyState(HGEK_RIGHT)) dx+=speed*dt;
	if (hge->Input_GetKeyState(HGEK_UP)) dy-=speed*dt;
	if (hge->Input_GetKeyState(HGEK_DOWN)) dy+=speed*dt;
	
	if(hge->Input_GetKeyState(HGEK_W))
	{
		scrDx = 1280;
		scrDy = 1024;		
		hge->System_SetState(HGE_SCREENWIDTH, 1280);
		hge->System_SetState(HGE_SCREENHEIGHT, 1024);		
		hge->System_SetState(HGE_WINDOWED, false);
	}
	if(hge->Input_GetKeyState(HGEK_Q))
	{ 
		scrDx = 800;
		scrDy = 600;
		hge->System_SetState(HGE_SCREENWIDTH, 800);
		hge->System_SetState(HGE_SCREENHEIGHT, 600);		
		hge->System_SetState(HGE_WINDOWED, true);
	}
	
	
	
	// Do some movement calculations and collision detection	
	dx*=friction; dy*=friction; x+=dx; y+=dy;
	if(x>scrDx) {x=scrDx-(x-scrDx);dx=-dx;}
	if(x<16) {x=16+16-x;dx=-dx;}
	if(y>scrDy) {y=scrDy-(y-scrDy);dy=-dy;}
	if(y<16) {y=16+16-y;dy=-dy;}
	
	// Update particle system
	par->info.nEmission=(int)(dx*dx+dy*dy)*2;
	par->MoveTo(x,y);
	par->Update(dt);
	
	return false;
}


// This function will be called by HGE when
// the application window should be redrawn.
// Put your rendering code here.
bool RenderFunc()
{
	// Render graphics
	hge->Gfx_BeginScene();
	hge->Gfx_Clear(0);
	par->Render();
	spr->Render(x, y);
	fnt->printf(5, 5, HGETEXT_LEFT, "dt:%.3f\nFPS:%d (constant)", hge->Timer_GetDelta(), hge->Timer_GetFPS());
	hge->Gfx_EndScene();
	
	return false;
}


int main (int argc, char * const argv[])
{
	hge = hgeCreate (HGE_VERSION);
	
	// Set up log file, frame function, render function and window title
	hge->System_SetState(HGE_LOGFILE, "hge_tut02.log");
	hge->System_SetState(HGE_FRAMEFUNC, FrameFunc);
	hge->System_SetState(HGE_RENDERFUNC, RenderFunc);
	hge->System_SetState(HGE_TITLE, "HGE Tutorial 02 - Using input, sound and rendering");
	hge->System_SetState(HGE_FPS, 60);
	
	// Set up video mode 
	hge->System_SetState(HGE_WINDOWED, bWnd);
	hge->System_SetState(HGE_ZBUFFER, true);
	hge->System_SetState(HGE_SCREENWIDTH, scrDx);
	hge->System_SetState(HGE_SCREENHEIGHT, scrDy);
	hge->System_SetState(HGE_SCREENBPP, 32);
	
	if(hge->System_Initiate())
	{
		tex=hge->Texture_Load("particles.png");
		
		// Create and set up a sprite
		spr=new hgeSprite(tex, 96, 64, 32, 32);
		spr->SetColor(0xFFFFA000);
		spr->SetHotSpot(16,16);
		
		// Load a font
		fnt=new hgeFont("font1.fnt");
		
		// Create and set up a particle system
		spt=new hgeSprite(tex, 32, 32, 32, 32);
		spt->SetBlendMode(BLEND_COLORMUL | BLEND_ALPHAADD | BLEND_NOZWRITE);
		spt->SetHotSpot(16,16);
		par=new hgeParticleSystem("trail.psi",spt);
		par->Fire();
		
		// Let's rock now!
		hge->System_Start();
		
		// Delete created objects and free loaded resources
		delete par;
		delete fnt;
		delete spt;
		delete spr;
		hge->Texture_Free(tex);		
	}	
	
    return 0;
}
