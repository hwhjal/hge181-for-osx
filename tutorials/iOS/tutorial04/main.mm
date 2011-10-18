#include <iostream>


// #import <Cocoa/Cocoa.h>

#define _IOS

#include <math.h>

#include "../../../include/hge.h"
#include "../../../include/hgecolor.h"
#include "../../../include/hgesprite.h"
#include "../../../include/hgedistort.h"
#include "../../../include/hgefont.h"
#include "../../../include/hgeparticle.h"


HGE *hge=0;


hgeSprite*			spr;
hgeSprite*			spt;
hgeSprite*			tar;
hgeFont*			fnt;
hgeParticleSystem*	par;

HTEXTURE			tex;
HEFFECT				snd;

// HGE render target handle
HTARGET				target;

float x=100.0f, y=100.0f;
float dx=0.0f, dy=0.0f;

const float speed=90;
const float friction=0.98f;
bool FullScreen = true, f1 = false, f2 = false;

void boom()
{
	int pan=int((x-256)/2.56f);
	float pitch=(dx*dx+dy*dy)*0.0005f+0.2f;
	hge->Effect_PlayEx(snd,100,pan,pitch);
}

// This function will be called by HGE when
// render targets were lost and have been just created
// again. We use it here to update the render
// target's texture handle that changes during recreation.
bool GfxRestoreFunc()
{
	if(tar && target) tar->SetTexture(hge->Target_GetTexture(target));
	return false;
}


bool FrameFunc()
{
	
	float dt=hge->Timer_GetDelta();
	
	if (hge->Input_GetKeyState(HGEK_LBUTTON))
	{
		dx = float (rand () % 25);
		dy = float (rand () % 25);
	}
	
	// Process keys
	if (hge->Input_GetKeyState(HGEK_ESCAPE)) return true;
	if (hge->Input_GetKeyState(HGEK_LEFT)) dx-=speed*dt;
	if (hge->Input_GetKeyState(HGEK_RIGHT)) dx+=speed*dt;
	if (hge->Input_GetKeyState(HGEK_UP)) dy-=speed*dt;
	if (hge->Input_GetKeyState(HGEK_DOWN)) dy+=speed*dt;
	
	// Do some movement calculations and collision detection	
	dx*=friction; dy*=friction; x+=dx; y+=dy;
	if(x>496) {x=496-(x-496);dx=-dx;boom();}
	if(x<16) {x=16+16-x;dx=-dx;boom();}
	if(y>496) {y=496-(y-496);dy=-dy;boom();}
	if(y<16) {y=16+16-y;dy=-dy;boom();}
	
	// Update particle system
	par->info.nEmission=(int)(dx*dx+dy*dy);
	par->MoveTo(x,y);
	par->Update(dt);
	
	return false;
}


bool RenderFunc()
{
	int i;
	
	// Render graphics to the texture
	hge->Gfx_BeginScene(target);
	hge->Gfx_Clear(0);
	par->Render();
	spr->Render(x, y);
	hge->Gfx_EndScene();
	hge->Gfx_SetClipping ();
	
	// Now put several instances of the rendered texture to the screen
	hge->Gfx_BeginScene();
	hge->Gfx_Clear(0);
	for(i=0;i<6;i++)
	{
		tar->SetColor(0xFFFFFF | (((5-i)*40+55)<<24));
		tar->RenderEx(i*100.0f, i*50.0f, i*M_PI/8, 1.0f-i*0.1f);
	}
	fnt->printf(5, 5, HGETEXT_LEFT, "Tap the screen");
	fnt->printf(5, 30, HGETEXT_LEFT, "dt:%.3f\nFPS:%d (constant)", hge->Timer_GetDelta(), hge->Timer_GetFPS());
	hge->Gfx_EndScene();
	
	return false;
}


int main (int argc, char * const argv[])
{
	hge = hgeCreate(HGE_VERSION);
	
	hge->System_SetState(HGE_LOGFILE, "hge_tut04.log");
	hge->System_SetState(HGE_FRAMEFUNC, FrameFunc);
	hge->System_SetState(HGE_RENDERFUNC, RenderFunc);
	hge->System_SetState(HGE_GFXRESTOREFUNC, GfxRestoreFunc);
	hge->System_SetState(HGE_TITLE, "HGE Tutorial 04 - Using render targets");
	hge->System_SetState(HGE_FPS, 60);
	hge->System_SetState(HGE_USESOUND, true);
	
	tar=0;
	target=0;
	
	if(hge->System_Initiate()) 
	{
		snd=hge->Effect_Load("menu.wav");
		tex=hge->Texture_Load("particles.png");
		if(!snd || !tex)
		{
			// If one of the data files is not found, display
			// an error message and shutdown.
			hge->System_Shutdown();
			hge->Release();
			return 0;
		}
		
		spr=new hgeSprite(tex, 96, 64, 32, 32);
		spr->SetColor(0xFFFFA000);
		spr->SetHotSpot(16,16);
		
		fnt=new hgeFont("font1.fnt");
		
		spt=new hgeSprite(tex, 32, 32, 32, 32);
		spt->SetBlendMode(BLEND_COLORMUL | BLEND_ALPHAADD | BLEND_NOZWRITE);
		spt->SetHotSpot(16,16);
		par=new hgeParticleSystem("trail.psi",spt);
		par->Fire();
		
		// Create a render target and a sprite for it
		target=hge->Target_Create(512,512,false);
		tar=new hgeSprite(hge->Target_GetTexture(target),0,0,1024,768);
		tar->SetBlendMode(BLEND_COLORMUL | BLEND_ALPHAADD | BLEND_NOZWRITE);
		
		// Let's rock now!
		hge->System_Start();
		
		// Delete created objects and free loaded resources
		delete par;
		delete fnt;
		delete spt;
		delete spr;
		delete tar;
		hge->Target_Free(target);
		hge->Texture_Free(tex);
		hge->Effect_Free(snd);
	}
	
	// Clean up and shutdown
	hge->System_Shutdown();
	hge->Release();
	return 0;
}

