//
//  graphics.mm
//  hgecore_osx
//
//  Created by Andrew Onofreytchuk on 5/3/10.
//  Copyright 2010 Andrew Onofreytchuk (a.onofreytchuk@gmail.com). All rights reserved.
//

#include "main.h"


/*
 TODO:	+ Context sharing
		Enum All modes (enum_adapter_modes)
		Get Current Display mode (get_desktop_mode)
		Set fullscreen with mode changing 
		+ Path to bundle
		Packed files support
		+ Arrange window's rect size with contentRectForFrameRect:styleMask:
		+ Get native texture size
 */


GLuint nVertexBuffer;

void CALL Texture_SizeToPow2 (int &width, int &height)
{
	// int w = *width, h = *height;
	int w = 1, h = 1;
	
	while (w < width) {w = w << 1;}
	while (h < height) {h = h << 1;}
	
	width = w;
	height = h;
}


bool HGE_Impl::_GfxInit()
{
	
	if(!_init_lost()) return false;	
	
	
	return true;
}

void HGE_Impl::_OpeGLCapsGet ()
{
	const GLubyte* strVers = glGetString (GL_VERSION);
	
	bGLVARSupported = false;
	bGLAppleFenceSupported = false;
	nGLMaxTexUnits = 0;
	nGLMaxTexSize = 0;
	
	// Extensions caps
	const GLubyte* strExt;
	strExt = glGetString (GL_EXTENSIONS);
	glGetIntegerv (GL_MAX_TEXTURE_UNITS, &nGLMaxTexUnits);												// Max texture units
	glGetIntegerv (GL_MAX_TEXTURE_SIZE,	 &nGLMaxTexSize);												// Max texture size	
	bGLVARSupported =  gluCheckExtension (( const GLubyte *) "GL_APPLE_vertex_array_range", strExt);	// VAR
	bGLAppleFenceSupported =  gluCheckExtension (( const GLubyte *) "GL_APPLE_fence", strExt);			// Apple Fence
	
	// Dump renderer info
	System_Log("Renderer: %s",glGetString (GL_RENDERER));
	System_Log("Vendor: %s",glGetString (GL_VENDOR));
	System_Log("OpenGL version: %s", strVers);
	System_Log("OpenGL bGLVARSupported: %d", (unsigned long)bGLVARSupported);
	System_Log("OpenGL bGLAppleFenceSupported: %d", (unsigned long)bGLAppleFenceSupported);
	System_Log("OpenGL nGLMaxTexUnits: %d", nGLMaxTexUnits);
	System_Log("OpenGL nGLMaxTexSize: %d", nGLMaxTexSize);
}

bool HGE_Impl::_GfxContextCreate()
{
	if (bWindowed)
	{
		// Release old renderer
		if (0 != glView) [glView release];
		glView = nil;
		
		NSOpenGLPixelFormatAttribute attributes [] = { 
			NSOpenGLPFAAccelerated,
			NSOpenGLPFANoRecovery,
			NSOpenGLPFADoubleBuffer,	
			NSOpenGLPFAColorSize, (NSOpenGLPixelFormatAttribute)nScreenBPP,
			NSOpenGLPFAWindow,
			NSOpenGLPFAMinimumPolicy,	// ????
			NSOpenGLPFAClosestPolicy,
			(NSOpenGLPixelFormatAttribute)0 };
		
		NSOpenGLPixelFormatAttribute attributes_Z [] = { 
			NSOpenGLPFAAccelerated,
			NSOpenGLPFANoRecovery,
			NSOpenGLPFADoubleBuffer,	
			NSOpenGLPFAColorSize, (NSOpenGLPixelFormatAttribute)nScreenBPP,
			NSOpenGLPFAWindow,
			NSOpenGLPFADepthSize, (NSOpenGLPixelFormatAttribute)16,
			NSOpenGLPFAMinimumPolicy,	// ????
			NSOpenGLPFAClosestPolicy,
			(NSOpenGLPixelFormatAttribute)0 };
		
		NSOpenGLPixelFormatAttribute *attr = attributes;
		if (bZBuffer) attr = attributes_Z;
		
		NSOpenGLPixelFormat *format;
		format = [[NSOpenGLPixelFormat alloc] initWithAttributes:attr];
		if (!format)
		{
			_PostError ("No OpegGL pixel format found");
			return false;			
		}
		
		glView = [[NSOpenGLView alloc] initWithFrame:rect pixelFormat:format];
		
		if (!glView)
		{
			_PostError ("Cannot create GLView object");
			return false;			
		}
		
		// Get an OpenGL context
		if (nil == glContextFullscreen) glContextWindowed = [[NSOpenGLContext alloc] initWithFormat:format shareContext:nil];
			else
			{
				glContextWindowed = [[NSOpenGLContext alloc] initWithFormat:format shareContext:glContextFullscreen];
				[glContextFullscreen release];
				glContextFullscreen = nil;
			}

		[glView setOpenGLContext: glContextWindowed];		
		[hwnd setContentView:glView];
		[glContextWindowed setView:[hwnd contentView]];		
		[glContextWindowed makeCurrentContext]; 

		[format release];
	}
	else
	{
		if (0 != hwnd)
			[hwnd setContentView:nil];
		
		// Pixelformat
		NSOpenGLPixelFormatAttribute attributes [] = {
			NSOpenGLPFAFullScreen,
			NSOpenGLPFAScreenMask,
			(NSOpenGLPixelFormatAttribute)CGDisplayIDToOpenGLDisplayMask(kCGDirectMainDisplay),
			NSOpenGLPFAColorSize, (NSOpenGLPixelFormatAttribute)nScreenBPP,
			NSOpenGLPFADoubleBuffer,
			NSOpenGLPFAAccelerated,
			(NSOpenGLPixelFormatAttribute)0 };
		
		NSOpenGLPixelFormatAttribute attributes_Z [] = {
			NSOpenGLPFAFullScreen,
			NSOpenGLPFAScreenMask,
			(NSOpenGLPixelFormatAttribute)CGDisplayIDToOpenGLDisplayMask(kCGDirectMainDisplay),
			NSOpenGLPFAColorSize, (NSOpenGLPixelFormatAttribute)nScreenBPP,
			NSOpenGLPFADepthSize, (NSOpenGLPixelFormatAttribute)16,
			NSOpenGLPFADoubleBuffer,
			NSOpenGLPFAAccelerated,
			(NSOpenGLPixelFormatAttribute)0 };
		NSOpenGLPixelFormatAttribute *attr = attributes;
		if (bZBuffer) attr = attributes_Z;
		
		NSOpenGLPixelFormat *format = [[NSOpenGLPixelFormat alloc]
									   initWithAttributes:attr];
		
		if (nil == glContextWindowed) glContextFullscreen = [[NSOpenGLContext alloc] initWithFormat:format shareContext:nil];
			else
			{
				glContextFullscreen = [[NSOpenGLContext alloc] initWithFormat:format shareContext:glContextWindowed];
				[glContextWindowed release];
				glContextWindowed = nil;
			}
		
		if (!glContextFullscreen)
		{
			[format release];
			_PostError ("Cannot create GLView object");
			return false;			
		}
		
		[format release];
		format = nil;
		
		if (!bKeepDesktopMode)
		{
			// Get display res
			mDesktopWidth = CGDisplayPixelsWide (kCGDirectMainDisplay);
			mDesktopHeight = CGDisplayPixelsHigh (kCGDirectMainDisplay);
			mDesktopBPP = CGDisplayBitsPerPixel (kCGDirectMainDisplay);
			mDesktopRR = 0;
			
			// Capture main display
			if (CGDisplayNoErr != CGDisplayCapture (kCGDirectMainDisplay)) 
			{
				_PostError ("CGCaptureAllDisplays failed");				
				[glContextFullscreen release];
				glContextFullscreen = nil;
				return false;
			}
			CFDictionaryRef displayMode;
			boolean_t exactMatch;
			
			displayMode = CGDisplayBestModeForParametersAndRefreshRate (kCGDirectMainDisplay,
																		nScreenBPP, nScreenWidth, nScreenHeight, 0, &exactMatch);
			CGDisplaySwitchToMode (kCGDirectMainDisplay, displayMode);
		}
		
		[glContextFullscreen setFullScreen];
		[glContextFullscreen makeCurrentContext]; 
	}
	
	return true;	
}

void HGE_Impl::_SetBlendMode(int blend)
{
	
	// Wait fence
	if (bGLAppleFenceSupported)
		glFinishFenceAPPLE(nGLFence);
	
	if((blend & BLEND_ZWRITE) != (CurBlendMode & BLEND_ZWRITE))
	{
		if(blend & BLEND_ZWRITE) glEnable(GL_DEPTH_TEST);
			else glDisable(GL_DEPTH_TEST);
	}		
	/* if((blend & BLEND_ZWRITE) != (CurBlendMode & BLEND_ZWRITE))
	 {
	 if(blend & BLEND_ZWRITE) pD3DDevice->SetRenderState(D3DRS_ZWRITEENABLE, TRUE);
	 else pD3DDevice->SetRenderState(D3DRS_ZWRITEENABLE, FALSE);
	 }*/	
	
	 if((blend & BLEND_ALPHABLEND) != (CurBlendMode & BLEND_ALPHABLEND))
	 {
		 if(blend & BLEND_ALPHABLEND)
		 {
			 glEnable (GL_BLEND);
			 glTexEnvi (GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_MODULATE);
			 glBlendFunc (GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
		 }
		 else glBlendFunc (GL_SRC_ALPHA, GL_ONE);
	 }	
	/*if((blend & BLEND_ALPHABLEND) != (CurBlendMode & BLEND_ALPHABLEND))
	{
		if(blend & BLEND_ALPHABLEND) pD3DDevice->SetRenderState(D3DRS_DESTBLEND, D3DBLEND_INVSRCALPHA);
		else pD3DDevice->SetRenderState(D3DRS_DESTBLEND, D3DBLEND_ONE);
	}*/ 
	 
	 if((blend & BLEND_COLORADD) != (CurBlendMode & BLEND_COLORADD))
	 {
		 if (blend & BLEND_COLORADD) glTexEnvi( GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_ADD);
			else glTexEnvi (GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_MODULATE);
	 }	 
	/*if((blend & BLEND_COLORADD) != (CurBlendMode & BLEND_COLORADD))
	{
		if(blend & BLEND_COLORADD) pD3DDevice->SetTextureStageState(0, D3DTSS_COLOROP, D3DTOP_ADD);
		else pD3DDevice->SetTextureStageState(0, D3DTSS_COLOROP, D3DTOP_MODULATE);
	}*/
	
	// Set fence
	if (bGLAppleFenceSupported)
		glSetFenceAPPLE(nGLFence);
	
	// Force OpenGL commands to HW
	glFlush();

	CurBlendMode = blend;
}


void HGE_Impl::_SetProjectionMatrix(int width, int height, bool flip)
{
	// Wait fence
	if (bGLAppleFenceSupported)
		glFinishFenceAPPLE(nGLFence);	
	
	glDisable (GL_SCISSOR_TEST);	
	glMatrixMode (GL_PROJECTION);
	glLoadIdentity ();
	glMatrixMode (GL_MODELVIEW);
	glLoadIdentity ();
	if (!flip) glScalef (2.0f / (float)width, 2.0f / (float)height, 1.0f);
		else glScalef (2.0f / (float)width, -2.0f / (float)height, 1.0f);
	glTranslatef (-((float)width / 2.0f), -((float)height / 2.0f), 0.0f);
	glViewport (0, 0, width, height);
	
	
	// Set fence
	if (bGLAppleFenceSupported)
		glSetFenceAPPLE(nGLFence);				
	
	// Force OpenGL commands to HW
	glFlush();
}

bool CALL HGE_Impl::Gfx_BeginScene(HTARGET targ)
{
 	if(VertArray)
	{
		_PostError("Gfx_BeginScene: Scene is already being rendered");
		return false;
	}
	CRenderTargetList *target=(CRenderTargetList *)targ;
	
	// Set fence
	if (bGLAppleFenceSupported)	
		glSetFenceAPPLE (nGLFence);

	
	if(target != pCurTarget)
	{
		if(target)
		{
			glBindFramebufferEXT (GL_FRAMEBUFFER_EXT, target->framebuffer);
		}
		else
		{
			// pSurf=pScreenSurf;
			// pDepth=pScreenDepth;
		}
		if(target)
		{
			if(target->bDepth)
			{	
				glEnable (GL_DEPTH_TEST);
				glDepthFunc (GL_LEQUAL);
				glDepthRange (0.0, 1.0);
				glDepthMask (GL_TRUE);
			}
			else glDisable (GL_DEPTH_TEST);
			_SetProjectionMatrix(target->width, target->height, false);
		}
		else
		{
			// Make the window the target
			glBindFramebufferEXT(GL_FRAMEBUFFER_EXT, 0);

			if(bZBuffer)
			{	
				glEnable (GL_DEPTH_TEST);
				glDepthFunc (GL_LEQUAL);
				glDepthRange (0.0, 1.0);
				glDepthMask (GL_TRUE);
			}
			else glDisable (GL_DEPTH_TEST);
			_SetProjectionMatrix (nScreenWidth, nScreenHeight, true);
		}
		
		pCurTarget=target;
	}
	
	// Get vertex buffer address
	VertArray = glVertexBuffer;
	
	return true;
}

void HGE_Impl::Gfx_Clear (DWORD color) 
{
	float r,g,b,a;
	a = (color>>24) / 255.0f;
	r = ((color>>16) & 0xFF) / 255.0f;
	g = ((color>>8) & 0xFF) / 255.0f;
	b = (color & 0xFF) / 255.0f;
	glClearColor (r,g,b,a);
	
	bool needZClean = false;
	if(pCurTarget)
	{
		if(pCurTarget->bDepth) needZClean = true;
	}
	else
		if (bZBuffer) needZClean = true;
	
	if (needZClean) 
	{
		glClear (GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
		glClearDepth (1.0f);		
	}
		else glClear (GL_COLOR_BUFFER_BIT);
	
}

void CALL HGE_Impl::Gfx_EndScene()
{
	_render_batch (true);
	
	// Display render buffer content
	if (bWindowed) [glContextWindowed flushBuffer];
		else [glContextFullscreen flushBuffer];
}

void CALL HGE_Impl::Gfx_RenderLine(float x1, float y1, float x2, float y2, DWORD color, float z)
{
	if(VertArray)
	{
		if(CurPrimType!=HGEPRIM_LINES || nPrim>=VERTEX_BUFFER_SIZE/HGEPRIM_LINES || CurTexture || CurBlendMode!=BLEND_DEFAULT)
		{
			_render_batch();
			
			CurPrimType=HGEPRIM_LINES;
			if(CurBlendMode != BLEND_DEFAULT)
				_SetBlendMode(BLEND_DEFAULT);

			if(CurTexture)
			{
				// Wait fence
				if (bGLAppleFenceSupported)
					glFinishFenceAPPLE(nGLFence);
				
				glBindTexture (GL_TEXTURE_2D, 0);
				CurTexture=0;
				
				// Set fence
				if (bGLAppleFenceSupported)
					glSetFenceAPPLE(nGLFence);				

				// Force OpenGL commands to HW
				glFlush();				
			}
		}
		
		int i=nPrim*HGEPRIM_LINES;
		VertArray[i].x = x1; VertArray[i+1].x = x2;
		VertArray[i].y = y1; VertArray[i+1].y = y2;
		VertArray[i].z     = VertArray[i+1].z = z;
		VertArray[i].col   = VertArray[i+1].col = color;
		VertArray[i].tx    = VertArray[i+1].tx =
		VertArray[i].ty    = VertArray[i+1].ty = 0.0f;
		
		nPrim++;
	}
}

void CALL HGE_Impl::Gfx_RenderTriple(const hgeTriple *triple)
{
	if(VertArray)
	{
		if(CurPrimType!=HGEPRIM_TRIPLES || nPrim>=VERTEX_BUFFER_SIZE/HGEPRIM_TRIPLES || CurTexture!=triple->tex || CurBlendMode!=triple->blend)
		{
			_render_batch();
			
			CurPrimType=HGEPRIM_TRIPLES;
			if(CurBlendMode != triple->blend) _SetBlendMode(triple->blend);
			if(triple->tex != CurTexture)
			{				
				// Wait fence
				if (bGLAppleFenceSupported)
					glFinishFenceAPPLE(nGLFence);
				
				glBindTexture (GL_TEXTURE_2D, (GLuint) triple->tex);
				
				// Set fence
				if (bGLAppleFenceSupported)
					glSetFenceAPPLE(nGLFence);
				
				// Force OpenGL commands to HW
				glFlush();
				
				CurTexture = triple->tex;
			}
		}
		
		memcpy(&VertArray[nPrim*HGEPRIM_TRIPLES], triple->v, sizeof(hgeVertex)*HGEPRIM_TRIPLES);
		nPrim++;
	}
}

void CALL HGE_Impl::Gfx_RenderQuad(const hgeQuad *quad)
{
	if(VertArray)
	{
		if(CurPrimType!=HGEPRIM_QUADS || nPrim>=VERTEX_BUFFER_SIZE/HGEPRIM_QUADS || CurTexture!=quad->tex || CurBlendMode!=quad->blend)
		{
			_render_batch();

			CurPrimType=HGEPRIM_QUADS;
			if(CurBlendMode != quad->blend) _SetBlendMode(quad->blend);
			if(quad->tex != CurTexture)
			{
				// Wait fence
				if (bGLAppleFenceSupported)
					glFinishFenceAPPLE(nGLFence);
				
				glBindTexture (GL_TEXTURE_2D, quad->tex);

				// Set fence
				if (bGLAppleFenceSupported)
					glSetFenceAPPLE(nGLFence);
				
				// Force OpenGL commands to HW
				glFlush();
				
				CurTexture = quad->tex;
			}
		}
		
		hgeVertex *pDst = &VertArray[nPrim*HGEPRIM_QUADS];
		const hgeVertex *pSrc = quad->v;
		*pDst++ = *pSrc++;
		*pDst++ = *pSrc++;
		*pDst++ = *pSrc++;
		*pDst++ = *pSrc++;
		nPrim++;
	}
}

hgeVertex* CALL HGE_Impl::Gfx_StartBatch(int prim_type, HTEXTURE tex, HTEXTURE tex_mask, int blend, int *max_prim)
{
	if(VertArray)
	{
		_render_batch();
		
		CurPrimType=prim_type;
		if(CurBlendMode != blend) _SetBlendMode(blend);
		if(tex != CurTexture)
		{
			// Wait fence
			if (bGLAppleFenceSupported)
				glFinishFenceAPPLE(nGLFence);
			
			glBindTexture (GL_TEXTURE_2D, (GLuint) tex);
			CurTexture = tex;
			
			// Set fence
			if (bGLAppleFenceSupported)
				glSetFenceAPPLE(nGLFence);		
			
			// Force OpenGL commands to HW
			glFlush();
		}
		
		*max_prim=VERTEX_BUFFER_SIZE / prim_type;
		return VertArray;
	}
	else return 0;
}

void CALL HGE_Impl::Gfx_FinishBatch(int nprim)
{
	nPrim=nprim;
}

void HGE_Impl::_render_batch (bool bEndScene)
{
	if(VertArray)
	{	

		if(nPrim)
		{
			hgeVertex* pVert = glVertexBuffer;
			int buffSize = nPrim * 4;
			if (HGEPRIM_TRIPLES == CurPrimType)
				buffSize = nPrim * 3;
			else
				if (HGEPRIM_LINES == CurPrimType)
					buffSize = nPrim * 2;
				
			if (1234 == nByteOrder)
				for (int i = 0; i < buffSize; i++)
				{
					unsigned char r = pVert->col & 0xff;
					unsigned char b = (pVert->col >> 16) & 0xff;
					unsigned char *pc = (unsigned char *) &pVert->col;
					*(pc+0) = b; 
					*(pc+2) = r; 
					pVert++;
				}
					else
						for (int i = 0; i < buffSize; i++)
						{
							unsigned char r = pVert->col & 0xff;
							unsigned char b = (pVert->col >> 16) & 0xff;
							unsigned char g = (pVert->col >> 8) & 0xff;
							unsigned char a = (pVert->col >> 24) & 0xff;							
							unsigned char *pc = (unsigned char *) &pVert->col;
							*pc = b; 
							*(pc+1) = g; 
							*(pc+2) = r; 
							*(pc+3) = a; 
							pVert++;
						}



			// Wait fence
			if (bGLAppleFenceSupported)
				glFinishFenceAPPLE(nGLFence);
			else
				glFinish();
			
			// Transfer data to buffer
			if (bGLVARSupported)
				glFlushVertexArrayRangeAPPLE (nVertexBufferSize, (void *) glVertexBuffer);
			else
			{
				glBindBuffer (GL_ARRAY_BUFFER, nVertexBuffer);
				glBufferData(GL_ARRAY_BUFFER, nVertexBufferSize, nil, GL_DYNAMIC_DRAW);
				hgeVertex *pBuff =  (hgeVertex *)glMapBuffer(GL_ARRAY_BUFFER, GL_WRITE_ONLY);
				memcpy(pBuff, glVertexBuffer, nVertexBufferSize);
				glUnmapBuffer(GL_ARRAY_BUFFER);				
			}
			
			switch(CurPrimType)
			{
				case HGEPRIM_QUADS:
					glDrawRangeElements (GL_TRIANGLES, 0, nPrim<<2, nPrim*6, GL_UNSIGNED_SHORT, glIndexBuffer);
					// glDrawArrays (GL_QUADS, 0, nPrim*4);
					break;
					
				case HGEPRIM_TRIPLES:
					glDrawArrays (GL_TRIANGLES, 0, nPrim * 3);
					break;					
					
				case HGEPRIM_LINES:
					glDrawArrays (GL_LINES, 0, nPrim * 2);
					break;
			}
			
			nPrim=0;
			
			// Set fence
			if (bGLAppleFenceSupported)
				glSetFenceAPPLE(nGLFence);
			
			// Force HW to process OpenGL commands
			glFlush ();
		
		}
		
		if(bEndScene) VertArray = 0;
			else VertArray = glVertexBuffer;
	} 
}

bool HGE_Impl::_GfxRestore()
{
	// Drop resources
	glDisableClientState (GL_VERTEX_ARRAY);
	
	glDisableClientState (GL_TEXTURE_COORD_ARRAY);
	glDisableClientState (GL_COLOR_ARRAY);
	
    // Release Vertex & Index Buffers
	if (bGLVARSupported)
	{
		// Disable Vertex Array Range extension
		glDisableClientState (GL_VERTEX_ARRAY_RANGE_APPLE);
	}
	
	// Release display if in fullscreen mode
	if (nil != glContextFullscreen && !bKeepDesktopMode)
	{
		CFDictionaryRef displayMode;
		boolean_t exactMatch;
		displayMode = CGDisplayBestModeForParametersAndRefreshRate (kCGDirectMainDisplay,
																	mDesktopBPP, mDesktopWidth, mDesktopHeight, 0, &exactMatch);
		CGDisplaySwitchToMode (kCGDirectMainDisplay, displayMode);
		CGDisplayRelease (kCGDirectMainDisplay);
	}
	
	// Reinit gfx
	if (!_init_lost())
		return false;
	
	// Call restore callback
	if (procGfxRestoreFunc)
		return procGfxRestoreFunc();
	
	return true;
}

void CALL HGE_Impl::Gfx_SetTransform(float x, float y, float dx, float dy, float rot, float hscale, float vscale)
{
	_render_batch();
	
	if(vscale==0.0f)
	{
		GLint mvStackDepth = 1;
		glGetIntegerv(GL_MODELVIEW_STACK_DEPTH, &mvStackDepth);
		if (1 == mvStackDepth) return;
		glMatrixMode (GL_MODELVIEW);
		glPopMatrix();
		glPushMatrix();
	}
	else
	{
		glTranslatef (x, y, 0.0f);			// Move to retation centre
		glScalef (hscale, vscale, 1.0f);	// Scale
		glRotatef(rot*180/M_PI, 0.0f, 0.0f, 1.0f);	// Rotate
		glTranslatef (-x+dx, -y+dy, 0.0f);	// Mov back and translate
		glTranslatef (0.375f, 0.375f, 0.);
	}
}

void CALL HGE_Impl::Gfx_SetClipping (int x, int y, int w, int h)
{
	int scr_width, scr_height;
	int vpX, vpY, vpWidth=scr_width, vpHeight;
	
	if(!pCurTarget)
	{
		scr_width=pHGE->System_GetStateInt(HGE_SCREENWIDTH);
		scr_height=pHGE->System_GetStateInt(HGE_SCREENHEIGHT);
	}
	else
	{
		scr_width=Texture_GetWidth((HTEXTURE)pCurTarget->texture);
		scr_height=Texture_GetHeight((HTEXTURE)pCurTarget->texture);
	}
	
	if(!w)
	{
		vpX=0;
		vpY=0;
		vpWidth=scr_width;
		vpHeight=scr_height;
	}
	else
	{
		if(x<0) { w+=x; x=0; }
		if(y<0) { h+=y; y=0; }
		
		if(x+w > scr_width) w=scr_width-x;
		if(y+h > scr_height) h=scr_height-y;
		
		vpX=x;
		vpY=y;
		vpWidth=w;
		vpHeight=h;
	}
	
	_render_batch();
	
	if (w)
	{
		glEnable (GL_SCISSOR_TEST);
		if(!pCurTarget) glScissor (vpX, scr_height-(vpY+vpHeight), vpWidth, vpHeight);
			else glScissor (vpX, vpY, vpWidth, vpHeight);
	}
	else glDisable (GL_SCISSOR_TEST);
}

bool HGE_Impl::_init_lost()
{
	bRendererInit = false;
	
	// Create window if no window exist 
	if (bWindowed && !hwnd) _CreateWindow ();
		
	// Create context
	if (!_GfxContextCreate ()) return false;
	
	// Set viewport & matrices
	_SetProjectionMatrix(nScreenWidth, nScreenHeight, true);	
	
	// Get Caps
	_OpeGLCapsGet ();
	
	// Vertex buffer	
	if (0 != glVertexBuffer) free (glVertexBuffer);
	nVertexBufferSize = VERTEX_BUFFER_SIZE*sizeof(hgeVertex);
	glVertexBuffer = (hgeVertex*) malloc(nVertexBufferSize);
	memset (glVertexBuffer, 0, nVertexBufferSize);
	
	
	/*glGenBuffers(1, &nVertexBuffer);
	glBindBuffer (GL_ARRAY_BUFFER, nVertexBuffer);*/
	
	/*glEnableClientState(GL_VERTEX_ARRAY);	
	glVertexPointer (3, GL_FLOAT, sizeof (hgeVertex), (GLvoid *) ((char *)&glVertexBuffer->x - (char*)glVertexBuffer));
	glEnableClientState (GL_COLOR_ARRAY);
	glColorPointer (4, GL_UNSIGNED_BYTE, sizeof (hgeVertex), (GLvoid *) ((char *)&glVertexBuffer->col - (char*)glVertexBuffer));
	glEnableClientState (GL_TEXTURE_COORD_ARRAY);
	glTexCoordPointer (2, GL_FLOAT, sizeof (hgeVertex), (GLvoid *) ((char *)&glVertexBuffer->tx - (char*)glVertexBuffer));*/
	
	
	if (bGLVARSupported)
	{
		// Do init with Vertex Array Range extension
		glVertexArrayParameteriAPPLE (GL_VERTEX_ARRAY_STORAGE_HINT_APPLE, GL_STORAGE_SHARED_APPLE);
		glVertexArrayRangeAPPLE (nVertexBufferSize, (void *) glVertexBuffer);
		// Enable states
		glEnableClientState(GL_VERTEX_ARRAY_RANGE_APPLE);
		// Map data
		glEnableClientState(GL_VERTEX_ARRAY);
		glVertexPointer (3, GL_FLOAT, sizeof (hgeVertex), (GLvoid *) &glVertexBuffer->x);
		glEnableClientState (GL_COLOR_ARRAY);
		glColorPointer (4, GL_UNSIGNED_BYTE, sizeof (hgeVertex), (GLvoid *) &glVertexBuffer->col);
		glEnableClientState (GL_TEXTURE_COORD_ARRAY);
		glTexCoordPointer (2, GL_FLOAT, sizeof (hgeVertex), (GLvoid *) &glVertexBuffer->tx);
	}
		else
		{
			// Do init with standart OpenGL
			glEnableClientState (GL_VERTEX_ARRAY);
			glVertexPointer (3, GL_FLOAT, sizeof (hgeVertex), (GLvoid *) &glVertexBuffer->x);
			glEnableClientState (GL_COLOR_ARRAY);
			glColorPointer (4, GL_UNSIGNED_BYTE, sizeof (hgeVertex), (GLvoid *) &glVertexBuffer->col);
			glEnableClientState (GL_TEXTURE_COORD_ARRAY);
			glTexCoordPointer (2, GL_FLOAT, sizeof (hgeVertex), (GLvoid *) &glVertexBuffer->tx);
		}
		
	
	if(bZBuffer)
	{	
		glEnable (GL_DEPTH_TEST);
		glDepthFunc (GL_LEQUAL);
		glDepthRange (0.0, 1.0);
		glDepthMask (GL_TRUE);
	}
	else glDisable (GL_DEPTH_TEST);	
	
	// Create and set Fence
	glGenFencesAPPLE(1, &nGLFence);
	
	// Index buffer
	if (0 != glIndexBuffer) free (glIndexBuffer);
	nIndexBufferSize = VERTEX_BUFFER_SIZE*6/4*sizeof(unsigned short);
	glIndexBuffer = (unsigned short *) malloc (nIndexBufferSize);
	memset (glIndexBuffer, 0, nIndexBufferSize);
	
	unsigned short *pIndices = glIndexBuffer, n=0;
	for(int i=0; i<VERTEX_BUFFER_SIZE/4; i++)
	{
		*pIndices++=n;
		*pIndices++=n+1;
		*pIndices++=n+2;
		*pIndices++=n+2;
		*pIndices++=n+3;
		*pIndices++=n;
		n+=4;
	}
	
	nPrim=0;
	CurPrimType=HGEPRIM_QUADS;
	CurBlendMode = BLEND_DEFAULT;
	CurTexture = NULL;	
	
	// Set Comon states
	glEnable (GL_TEXTURE_2D);
	glDisable (GL_SCISSOR_TEST);
	// glEnable(GL_COLOR_MATERIAL);

	// Texture params
	glTexParameteri (GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
	glTexParameteri (GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR); 
	glTexParameteri (GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, bTextureClamp ? GL_CLAMP : GL_REPEAT);
	glTexParameteri (GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, bTextureClamp ? GL_CLAMP : GL_REPEAT);
	// EF_DEFAULT
	glEnable (GL_BLEND);
	glTexEnvi (GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_MODULATE);
	glBlendFunc (GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
	glDepthFunc (GL_LEQUAL);
	
	// Set data alignment and byte order
	glPixelStorei (GL_UNPACK_ALIGNMENT, 1);
	if (nByteOrder != 1234)
	{
		glPixelStorei (GL_PACK_SWAP_BYTES, GL_TRUE);
		glPixelStorei (GL_UNPACK_SWAP_BYTES, GL_TRUE);
	}	
	bRendererInit = true;
	
	return true;
}



int CALL HGE_Impl::Texture_GetWidth(HTEXTURE tex, bool bOriginal)
{
	CTextureList *texItem=textures;
	
	while(texItem)
	{
		if (texItem->tex==tex)
		{
			return bOriginal ? texItem->width : texItem->realWidth;
		}
		texItem=texItem->next;
	}
	return 0;
}


int CALL HGE_Impl::Texture_GetHeight(HTEXTURE tex, bool bOriginal)
{
	CTextureList *texItem=textures;
	
	while(texItem)
	{
		if (texItem->tex==tex)
		{
			return bOriginal ? texItem->height : texItem->realHeight;
		}
		texItem=texItem->next;
	}
	return 0;
}


HTEXTURE CALL HGE_Impl::Texture_Create(int width, int height)
{
	GLuint name;
	glGenTextures (1, &name);
	
	if (GL_INVALID_VALUE == name)
	{	
		_PostError("Can't create texture");
		return NULL;
	}
	
	int realWidth = width, realHeight = height;
	Texture_SizeToPow2(realWidth, realHeight);
	CTextureList *texItem = 0;

	texItem=new CTextureList;
	texItem->tex = HTEXTURE(name);
	texItem->width=width;
	texItem->height=height;

	texItem->realWidth=realWidth;
	texItem->realHeight=realHeight;
	texItem->width=width;
	texItem->height=height;	
	
	texItem->bpp = 32;
	texItem->internalFormat = GL_RGBA;
	texItem->format = GL_RGBA;
	texItem->type = GL_UNSIGNED_INT_8_8_8_8_REV;	
	texItem->next=textures;
	texItem->lockInfo.data = 0;
	textures=texItem;
	
	return (HTEXTURE)name;
}

HTEXTURE CALL HGE_Impl::Texture_Load(const char *filename, DWORD size, bool bMipmap)
{
	void *data = 0;
	DWORD _size = 0;
	CTextureList *texItem = 0;
	
	if(size) { data=(void *)filename; _size=size; }
	else
	{
		data=pHGE->Resource_Load(filename, &_size);
		if(!data) return NULL;
	}
	
	NSAutoreleasePool *pool = [NSAutoreleasePool new];
	
	NSData *memData = [[NSData alloc] initWithBytes:data length:_size];	
	NSBitmapImageRep *bitmap = [[NSBitmapImageRep alloc] initWithData:memData];
	
	/*unsigned char *ptr = [bitmap bitmapData];
	 int w = [bitmap pixelsWide];
	 int h = [bitmap pixelsHigh];
	 int fmt = [bitmap bitmapFormat];
	 int bpp = [bitmap bitsPerPixel];
	 
	 int bpp2 = [bitmap bitsPerSample];
	 bool alpha = [bitmap hasAlpha];*/
	
	GLint internalFormat = 0;
	GLenum format = 0, type = 0;
	int bitsPerPixel = [bitmap bitsPerPixel];
	switch (bitsPerPixel)
	{
		case 16:
			if ([bitmap hasAlpha])
			{
				internalFormat = GL_RGBA;
				format = GL_RGBA; type = GL_UNSIGNED_SHORT_4_4_4_4_REV;
			}
			else
			{	
				internalFormat = GL_RGB;
				format = GL_RGB; type = GL_UNSIGNED_SHORT_5_6_5;
			}
			break;
			
		case 24:
			internalFormat = GL_RGB8; format = GL_RGB; type = GL_UNSIGNED_BYTE;			
			break;
			
		case 32:
			if ([bitmap hasAlpha])
			{
				internalFormat = GL_RGBA;
				format = GL_RGBA; type = GL_UNSIGNED_INT_8_8_8_8_REV;
			}
			else
			{	
				internalFormat = 4;
				format = GL_RGBA; type = GL_UNSIGNED_BYTE;
			}
			break;
		case 64:
			if ([bitmap hasAlpha])
			{
				internalFormat = GL_RGBA;
				format = GL_RGBA; type = GL_UNSIGNED_SHORT;
			}
			else
			{	
				internalFormat = GL_RGBA;
				format = GL_RGBA; type = GL_UNSIGNED_SHORT;
			}
			break;
	}
	
	// Create texture
	GLuint name;
	glGenTextures (1, &name);	
	if (GL_INVALID_VALUE == name)
	{	
		_PostError("Can't create texture");
		[bitmap release];
		[memData release];
		if(!size) Resource_Free(data);
		
		[pool release];
		return 0;
	}
	glBindTexture (GL_TEXTURE_2D, name);	
	// Texture option
	glTexParameteri (GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
	glTexParameteri (GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR); 
	glTexParameteri (GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, bTextureClamp ? GL_CLAMP : GL_REPEAT);
	glTexParameteri (GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, bTextureClamp ? GL_CLAMP : GL_REPEAT);
	// Pixeldata
	int realWidth = [bitmap pixelsWide], realHeight = [bitmap pixelsHigh];
	Texture_SizeToPow2(realWidth, realHeight);
	
	// Manage memory blocks
	if (realWidth != [bitmap pixelsWide] || realHeight != [bitmap pixelsHigh])
	{
		void *pbuff = malloc (realWidth * realHeight * bitsPerPixel);
		int y = 0, origLineSize = [bitmap bytesPerRow], realLineSize = realWidth * (bitsPerPixel>>3);
		while (y < [bitmap pixelsHigh])
		{
			memcpy ((void *) ((unsigned long) pbuff + y*realLineSize),
					(void *) ((unsigned long) [bitmap bitmapData] + y*origLineSize),
					origLineSize);
			y++;
		}
		glTexImage2D (GL_TEXTURE_2D, 0, internalFormat, realWidth, realHeight, 0, format, type, pbuff);
		free(pbuff);		
	}
		else
			glTexImage2D (GL_TEXTURE_2D, 0, internalFormat, realWidth, realHeight, 0, format, type, [bitmap bitmapData]);
	
	texItem=new CTextureList;
	texItem->tex=(HTEXTURE)name;
	texItem->realWidth=realWidth;
	texItem->realHeight=realHeight;
	texItem->width=[bitmap pixelsWide];
	texItem->height=[bitmap pixelsHigh];
	texItem->bpp = bitsPerPixel;
	texItem->internalFormat = internalFormat;
	texItem->format = format;
	texItem->type = type;	
	texItem->next=textures;
	texItem->lockInfo.data = 0;
	textures=texItem;
	
	// Release data
	[bitmap release];
	[memData release];
	if (!size) Resource_Free(data);
	
	[pool release];
	return (HTEXTURE) name;
}


void* CALL HGE_Impl::Texture_Lock(HTEXTURE tex, bool bReadOnly, int left, int top, int width, int height)
{
	CTextureList *texItem=textures, *texFind=0;
	while(texItem && 0 == texFind)
	{
		if(texItem->tex==tex) texFind = texItem;
		texItem=texItem->next;
	}
	if (0 == texFind || 0 == texFind->tex)
	{
		_PostError("Can't lock texture");
		return 0;
	}
	
	int texture = 0;
	if (0!=texFind) texture = texFind->tex;
		else texture = tex;
	
	GLint tmpTexture;
	int bytesPerPixel = texFind->bpp>>3;
	
	if (0 == texFind->lockInfo.data)
		texFind->lockInfo.data = malloc (texFind->realWidth * texFind->realHeight * bytesPerPixel);
	
	glGetIntegerv(GL_TEXTURE_BINDING_2D, &tmpTexture);
	if (0 == texFind->lockInfo.data)
	{
		glBindTexture(GL_TEXTURE_2D, tmpTexture);
		_PostError("Can't lock texture");
		return 0;
	}
	texFind->lockInfo.readonly = bReadOnly;
	texFind->lockInfo.lockRect.top = top;
	texFind->lockInfo.lockRect.left = left;
	texFind->lockInfo.lockRect.right = left+width;
	texFind->lockInfo.lockRect.bottom = top+height;
	
	glBindTexture(GL_TEXTURE_2D, texture);
	glGetTexImage( GL_TEXTURE_2D , 0 , texFind->format, texFind->type, texFind->lockInfo.data);
	glBindTexture(GL_TEXTURE_2D, tmpTexture);
	
	void *res = (unsigned char *)texFind->lockInfo.data + (top*texFind->realWidth + left)*bytesPerPixel;
	return res;
}


void CALL HGE_Impl::Texture_Unlock(HTEXTURE tex)
{

	CTextureList *texItem=textures, *texFind=0;
	while(texItem && 0 == texFind)
	{
		if(texItem->tex==tex) texFind = texItem;
		texItem=texItem->next;
	}
	if (0 == texFind || 0 == texFind->tex)
	{
		_PostError("Can't lock texture");
		return;
	}
	
	if (!texFind->lockInfo.readonly)
	{
		glBindTexture(GL_TEXTURE_2D, tex);
		
		glTexParameteri (GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
		glTexParameteri (GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR); 
		glTexParameteri (GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, bTextureClamp ? GL_CLAMP : GL_REPEAT);
		glTexParameteri (GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, bTextureClamp ? GL_CLAMP : GL_REPEAT);

		glTexImage2D (GL_TEXTURE_2D, 0, texFind->internalFormat,
					  texFind->realWidth, texFind->realHeight, 0,
					  texFind->format, texFind->type, texFind->lockInfo.data);
	}
	// free(texFind->lockInfo.data);
}

void CALL HGE_Impl::Texture_Free(HTEXTURE tex)
{
	GLuint texture = (GLuint) tex;
	if (0 != texture) glDeleteTextures (1, &texture);

	CTextureList *texItem=textures, *texPrev=0;
	
	while(texItem)
	{
		if(texItem->tex==tex)
		{
			if (0 != texItem->lockInfo.data)
				free (texItem->lockInfo.data);
			if(texPrev) texPrev->next=texItem->next;
			else textures=texItem->next;
			delete texItem;
			break;
		}
		texPrev=texItem;
		texItem=texItem->next;
	}
}

HTARGET CALL HGE_Impl::Target_Create(int width, int height, bool zbuffer)
{
	CRenderTargetList *pTarget;
	
	pTarget = new CRenderTargetList;
	pTarget->framebuffer=0;
	pTarget->texture=0;
	pTarget->bDepth = zbuffer;
	GLenum status;
	glGenFramebuffersEXT (1, &pTarget->framebuffer);
	// Set up the FBO with one texture attachment
	glBindFramebufferEXT (GL_FRAMEBUFFER_EXT, pTarget->framebuffer);
	// glGenTextures(1, &pTarget->texture);
	pTarget->texture = Texture_Create (width, height);	
	
	
	glBindTexture(GL_TEXTURE_2D, pTarget->texture);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
	glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA8, width, height, 0,
				 GL_RGBA, GL_UNSIGNED_BYTE, NULL);
	glFramebufferTexture2DEXT(GL_FRAMEBUFFER_EXT, GL_COLOR_ATTACHMENT0_EXT,
							  GL_TEXTURE_2D, pTarget->texture, 0);
	status = glCheckFramebufferStatusEXT(GL_FRAMEBUFFER_EXT);
	if (status != GL_FRAMEBUFFER_COMPLETE_EXT)
	{
		_PostError("Can't create render target texture");
		delete pTarget;
		glDeleteTextures (1, &pTarget->texture);
		return 0;		
	}
	
	pTarget->width=width;
	pTarget->height=height;	
	pTarget->next=pTargets;
	pTargets=pTarget;

	// Make the window the target
	glBindFramebufferEXT(GL_FRAMEBUFFER_EXT, 0);
	
	return (HTARGET)pTarget;
}

HTEXTURE CALL HGE_Impl::Target_GetTexture(HTARGET target)
{
	CRenderTargetList *targ=(CRenderTargetList *)target;
	if(target) return (HTEXTURE)targ->texture;
		else return 0;
}


void CALL HGE_Impl::Target_Free(HTARGET target)
{
	CRenderTargetList *pTarget=pTargets, *pPrevTarget=NULL;
	
	while(pTarget)
	{
		if((CRenderTargetList *)target == pTarget)
		{
			if(pPrevTarget)
				pPrevTarget->next = pTarget->next;
			else
				pTargets = pTarget->next;
			
			if(pTarget->framebuffer)
			{
				Texture_Free (pTarget->texture);
				glDeleteFramebuffersEXT(1, &pTarget->framebuffer);				
			}
			
			delete pTarget;
			return;
		}
		
		pPrevTarget = pTarget;
		pTarget = pTarget->next;
	}
}

void HGE_Impl::_GfxDone()
{
	CRenderTargetList *target=pTargets, *next_target;
	
	while(target)
	{
		if(target->framebuffer)
		{
			Texture_Free (target->texture);
			glDeleteFramebuffersEXT(1, &target->framebuffer);				
		}		
		next_target=target->next;
		delete target;
		target=next_target;
	}
	pTargets=0;	
	
	while(textures)
		Texture_Free(textures->tex);
	
	// OpenGL Fence
	glDeleteFencesAPPLE(1, &nGLFence);
	
	// Vertex buffer	
	if (0 != glVertexBuffer) free (glVertexBuffer);
	if (0 != glIndexBuffer) free (glIndexBuffer);	
}