/*
** Haaf's Game Engine 1.8
** Copyright (C) 2003-2007, Relish Games
** hge.relishgames.com
**
** hge_tut06 - Creating menus
*/


// Copy the files "menu.wav", "font1.fnt", "font1.png",
// "bg.png" and "cursor.png" from the folder "precompiled"
// to the folder with executable file. Also copy hge.dll
// and bass.dll to the same folder.

#import <Cocoa/Cocoa.h>

#define _HGE_TARGET_OSX_


#include "../../../include/hge.h"
#include "../../../include/hgefont.h"
#include "../../../include/hgegui.h"

#include "menuitem.h"

#include <math.h>


// Pointer to the HGE interface.
// Helper classes require this to work.
HGE *hge=0;

// Some resource handles
HEFFECT				snd;
HTEXTURE			tex;
hgeQuad				quad;

// Pointers to the HGE objects we will use
hgeGUI				*gui;
hgeFont				*fnt;
hgeSprite			*spr;


bool FrameFunc()
{
	float dt=hge->Timer_GetDelta();
	static float t=0.0f;
	float tx,ty;
	int id2;
	static int lastid=0;

	// If ESCAPE was pressed, tell the GUI to finish
	if(hge->Input_GetKeyState(HGEK_ESCAPE)) { lastid=5; gui->Leave(); }
	if(hge->Input_GetKeyState(HGEK_W))
	{
		static bool fl = false;
		if (!fl)
		{
			hge->System_SetState(HGE_SCREENWIDTH, 1280);
			hge->System_SetState(HGE_SCREENHEIGHT, 1024);		
			hge->System_SetState(HGE_WINDOWED, false);
			// hge->Gfx_SetTransform(/*(1280-800)/2*/1280/2, 1024/2/*(1024 - 600)/2+*/, (1280-800)/2, (1024 - 600)/2, M_PI/4, 1.0f, 1.0f);
			fl = true;
		}
	}
	if(hge->Input_GetKeyState(HGEK_Q))
	{ 
		static bool fl2 = false;
		if (!fl2)
		{
			hge->System_SetState(HGE_SCREENWIDTH, 800);
			hge->System_SetState(HGE_SCREENHEIGHT, 600);		
			hge->System_SetState(HGE_WINDOWED, true);
			hge->Gfx_SetTransform(400, 300, 0, 0, -M_PI/4, 1.0f, 1.0f);
			fl2 = true;
		}
	}
	if(hge->Input_GetKeyState(HGEK_E)) 
		hge->Gfx_SetTransform ();

	
	// We update the GUI and take an action if
	// one of the menu items was selected
	id2=gui->Update(dt);
	if(id2 == -1)
	{
		switch(lastid)
		{
			case 1:
			case 2:
			case 3:
			case 4:
				gui->SetFocus(1);
				gui->Enter();
				break;

			case 5: 
				return true;
				break;
		}
	}
	else if(id2) { lastid=id2; gui->Leave(); }

	// Here we update our background animation
	t+=dt;
	tx=50*cosf(t/60);
	ty=50*sinf(t/60);

	quad.v[0].tx=tx;        quad.v[0].ty=ty;
	quad.v[1].tx=tx+800/64; quad.v[1].ty=ty;
	quad.v[2].tx=tx+800/64; quad.v[2].ty=ty+600/64;
	quad.v[3].tx=tx;        quad.v[3].ty=ty+600/64;

	return false;
}


bool RenderFunc()
{
	// Render graphics
	hge->Gfx_BeginScene();
	hge->Gfx_Clear(0); 
	hge->Gfx_RenderQuad(&quad);
	gui->Render();
	fnt->SetColor(0xFFFFFFFF);
	fnt->printf(5, 5, HGETEXT_LEFT, "dt:%.3f\nFPS:%d", hge->Timer_GetDelta(), hge->Timer_GetFPS());
	hge->Gfx_EndScene();

	return false;
}


int main (int argc, char * const argv[])
{
	hge = hgeCreate(HGE_VERSION);

	hge->System_SetState(HGE_LOGFILE, "hge_tut06.log");
	hge->System_SetState(HGE_FRAMEFUNC, FrameFunc);
	hge->System_SetState(HGE_RENDERFUNC, RenderFunc);
	hge->System_SetState(HGE_TITLE, "HGE Tutorial 06 - Creating menus");
	hge->System_SetState(HGE_WINDOWED, true);
	hge->System_SetState(HGE_SCREENWIDTH, 800);
	hge->System_SetState(HGE_SCREENHEIGHT, 600);
	hge->System_SetState(HGE_SCREENBPP, 32);
	hge->System_SetState(HGE_FPS, 60);

	if(hge->System_Initiate())
	{

		// Load sound and textures
		quad.tex=hge->Texture_Load("bg.png");
		tex=hge->Texture_Load("cursor.png");
		snd=hge->Effect_Load("menu.wav");
		if(!quad.tex || !tex || !snd)
		{
			// If one of the data files is not found, display
			// an error message and shutdown.
			// MessageBox(NULL, "Can't load BG.PNG, CURSOR.PNG or MENU.WAV", "Error", MB_OK | MB_ICONERROR | MB_APPLMODAL);
			hge->System_Shutdown();
			hge->Release();
			return 0;
		}

		// Set up the quad we will use for background animation
		quad.blend=BLEND_ALPHABLEND | BLEND_COLORMUL | BLEND_NOZWRITE;

		for(int i=0;i<4;i++)
		{
			// Set up z-coordinate of vertices
			quad.v[i].z=0.5f;
			// Set up color. The format of DWORD col is 0xAARRGGBB
			quad.v[i].col=0xFFFFFFFF;
		}

		quad.v[0].x=0; quad.v[0].y=0;
		quad.v[1].x=800; quad.v[1].y=0;
		quad.v[2].x=800; quad.v[2].y=600;
		quad.v[3].x=0; quad.v[3].y=600;


		// Load the font, create the cursor sprite
		fnt=new hgeFont("font1.fnt");
		spr=new hgeSprite(tex,0,0,32,32);

		// Create and initialize the GUI
		gui=new hgeGUI();

		gui->AddCtrl(new hgeGUIMenuItem(1,fnt,snd,400,200,0.0f,"Play"));
		gui->AddCtrl(new hgeGUIMenuItem(2,fnt,snd,400,240,0.1f,"Options"));
		gui->AddCtrl(new hgeGUIMenuItem(3,fnt,snd,400,280,0.2f,"Instructions"));
		gui->AddCtrl(new hgeGUIMenuItem(4,fnt,snd,400,320,0.3f,"Credits"));
		gui->AddCtrl(new hgeGUIMenuItem(5,fnt,snd,400,360,0.4f,"Exit"));

		gui->SetNavMode(HGEGUI_UPDOWN | HGEGUI_CYCLED);
		gui->SetCursor(spr);
		gui->SetFocus(1);
		gui->Enter();

		// Let's rock now!
		hge->System_Start();

		// Delete created objects and free loaded resources
		delete gui;
		delete fnt;
		delete spr;
		hge->Effect_Free(snd);
		hge->Texture_Free(tex);
		hge->Texture_Free(quad.tex);
	}

	// Clean up and shutdown
	hge->System_Shutdown();
	hge->Release();
	return 0;
}
