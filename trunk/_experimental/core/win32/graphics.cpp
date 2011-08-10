/*
** Haaf's Game Engine 1.8
** Copyright (C) 2003-2007, Relish Games
** hge.relishgames.com
**
** Core functions implementation: graphics
*/


#include "hge_impl.h"
#include <d3d8.h>
#include <d3dx8.h>
#include "core/file_system/FileSystem.h"

//----------------------------------------------------------------------------
#include "shiny/include/Shiny.h"
//----------------------------------------------------------------------------
#define LOCK_RENDER_TARGET_TO_AVOID_STALL
//----------------------------------------------------------------------------
// Rendering Performance Optimizations

// Purpose: previous view-port settings saving to avoid transformation matrix 
//			recalculation with the same parameters
// Reason:	to accelerate code performance which intensively uses 
//			Gfx_SetClipping() function
//#define ENABLE_TRANSFORMATION_MATRIX_CACHING

//----------------------------------------------------------------------------
void CALL HGE_Impl::Gfx_Clear(DWORD color)
{
    PROFILE_FUNC();
	if(pCurTarget)
	{
		if(pCurTarget->pDepth)
		{
			pD3DDevice->Clear( 0, NULL, D3DCLEAR_TARGET | D3DCLEAR_ZBUFFER, color, 1.0f, 0 );

			// HGE_MODIFY (Single Pass Multitexturing) {
			pD3DDevice->Clear( 1, NULL, D3DCLEAR_TARGET | D3DCLEAR_ZBUFFER, color, 1.0f, 0 );
			// }
		}
		else
		{
			pD3DDevice->Clear( 0, NULL, D3DCLEAR_TARGET, color, 1.0f, 0 );

			// HGE_MODIFY (Single Pass Multitexturing) {
			pD3DDevice->Clear( 1, NULL, D3DCLEAR_TARGET, color, 1.0f, 0 );
			// }
		}
	}
	else
	{
		if(bZBuffer)
		{
			pD3DDevice->Clear( 0, NULL, D3DCLEAR_TARGET | D3DCLEAR_ZBUFFER, color, 1.0f, 0 );

			// HGE_MODIFY (Single Pass Multitexturing) {
			pD3DDevice->Clear( 1, NULL, D3DCLEAR_TARGET | D3DCLEAR_ZBUFFER, color, 1.0f, 0 );
			// }
		}
		else
		{
			pD3DDevice->Clear( 0, NULL, D3DCLEAR_TARGET, color, 1.0f, 0 );

			// HGE_MODIFY (Single Pass Multitexturing) {
			pD3DDevice->Clear( 1, NULL, D3DCLEAR_TARGET, color, 1.0f, 0 );
			// }
		}
	}
}

void CALL HGE_Impl::Gfx_SetClipping(int x, int y, int w, int h)
{
    PROFILE_FUNC();
	D3DVIEWPORT8 vp;
	int scr_width, scr_height;

	if(!pCurTarget) {
		scr_width=pHGE->System_GetStateInt(HGE_SCREENWIDTH);
		scr_height=pHGE->System_GetStateInt(HGE_SCREENHEIGHT);
	}
	else {
		scr_width=Texture_GetWidth((HTEXTURE)pCurTarget->pTex);
		scr_height=Texture_GetHeight((HTEXTURE)pCurTarget->pTex);
	}

	if(!w) {
		vp.X=0;
		vp.Y=0;
		vp.Width=scr_width;
		vp.Height=scr_height;
	}
	else
	{
		if(x<0) { w+=x; x=0; }
		if(y<0) { h+=y; y=0; }

		if(x+w > scr_width) w=scr_width-x;
		if(y+h > scr_height) h=scr_height-y;

		if(w<0) w=0;	// добавлено, поскольку pD3DDevice->SetViewport(&vp) кидает
		if(h<0) h=0;	// исключение при отрицательных значениях

		vp.X=x;
		vp.Y=y;
		vp.Width=w;
		vp.Height=h;
	}

	vp.MinZ=0.0f;
	vp.MaxZ=1.0f;

#ifdef ENABLE_TRANSFORMATION_MATRIX_CACHING
	static D3DVIEWPORT8 prevVp;

	if (prevVp.X != vp.X || prevVp.Y != vp.Y || 
		prevVp.Width != vp.Width || prevVp.Height != vp.Height)
	{
#endif // ENABLE_TRANSFORMATION_MATRIX_CACHING
		_render_batch();
		pD3DDevice->SetViewport(&vp);

		D3DXMATRIX tmp;
		D3DXMatrixScaling(&matProj, 1.0f, -1.0f, 1.0f);
		D3DXMatrixTranslation(&tmp, -0.5f, +0.5f, 0.0f);
		D3DXMatrixMultiply(&matProj, &matProj, &tmp);
		D3DXMatrixOrthoOffCenterLH(&tmp, (float)vp.X, (float)(vp.X+vp.Width), -((float)(vp.Y+vp.Height)), -((float)vp.Y), vp.MinZ, vp.MaxZ);
		D3DXMatrixMultiply(&matProj, &matProj, &tmp);
		pD3DDevice->SetTransform(D3DTS_PROJECTION, &matProj);

#ifdef ENABLE_TRANSFORMATION_MATRIX_CACHING
		prevVp.X = vp.X;
		prevVp.Y = vp.Y;
		prevVp.Width = vp.Width;
		prevVp.Height = vp.Height;
	}
#endif // ENABLE_TRANSFORMATION_MATRIX_CACHING
}

void CALL HGE_Impl::Gfx_SetTransform(float x, float y, float dx, float dy, float rot, float hscale, float vscale)
{
    PROFILE_FUNC();
	D3DXMATRIX tmp;

	if(vscale==0.0f) D3DXMatrixIdentity(&matView);
	else
	{
		D3DXMatrixTranslation(&matView, -x, -y, 0.0f);
		D3DXMatrixScaling(&tmp, hscale, vscale, 1.0f);
		D3DXMatrixMultiply(&matView, &matView, &tmp);
		D3DXMatrixRotationZ(&tmp, -rot);
		D3DXMatrixMultiply(&matView, &matView, &tmp);
		D3DXMatrixTranslation(&tmp, x+dx, y+dy, 0.0f);
		D3DXMatrixMultiply(&matView, &matView, &tmp);
	}

	_render_batch();
	pD3DDevice->SetTransform(D3DTS_VIEW, &matView);
}

bool CALL HGE_Impl::Gfx_BeginScene(HTARGET targ)
{
    PROFILE_FUNC();
	LPDIRECT3DSURFACE8 pSurf=0, pDepth=0;
	D3DDISPLAYMODE Mode;
	CRenderTargetList *target=(CRenderTargetList *)targ;

	HRESULT hr = pD3DDevice->TestCooperativeLevel();
	if (hr == D3DERR_DEVICELOST) return false;
	else if (hr == D3DERR_DEVICENOTRESET)
	{
		if(bWindowed)
		{
			if(FAILED(pD3D->GetAdapterDisplayMode(D3DADAPTER_DEFAULT, &Mode)) || Mode.Format==D3DFMT_UNKNOWN) 
			{
				_PostError("Can't determine desktop video mode");
				return false;
			}

			d3dppW.BackBufferFormat = Mode.Format;
			if(_format_id(Mode.Format) < 4) nScreenBPP=16;
			else nScreenBPP=32;
		}

	    if(!_GfxRestore()) return false; 
	}
    
	if(VertArray)
	{
		_PostError("Gfx_BeginScene: Scene is already being rendered");
		return false;
	}
	
	if(target != pCurTarget)
	{
		if(target)
		{
			target->pTex->GetSurfaceLevel(0, &pSurf);
			pDepth=target->pDepth;
		}
		else
		{
			pSurf=pScreenSurf;
			pDepth=pScreenDepth;
		}
		if(FAILED(pD3DDevice->SetRenderTarget(pSurf, pDepth)))
		{
			if(target) pSurf->Release();
			_PostError("Gfx_BeginScene: Can't set render target");
			return false;
		}
		if(target)
		{
			pSurf->Release();
			if(target->pDepth) pD3DDevice->SetRenderState( D3DRS_ZENABLE, D3DZB_TRUE ); 
			else pD3DDevice->SetRenderState( D3DRS_ZENABLE, D3DZB_FALSE ); 
			_SetProjectionMatrix(target->width, target->height);
		}
		else
		{
			if(bZBuffer) pD3DDevice->SetRenderState( D3DRS_ZENABLE, D3DZB_TRUE ); 
			else pD3DDevice->SetRenderState( D3DRS_ZENABLE, D3DZB_FALSE );
			_SetProjectionMatrix(nScreenWidth, nScreenHeight);
		}

		pD3DDevice->SetTransform(D3DTS_PROJECTION, &matProj);
		D3DXMatrixIdentity(&matView);
		pD3DDevice->SetTransform(D3DTS_VIEW, &matView);

		pCurTarget=target;
	}

	pD3DDevice->BeginScene();
	pVB->Lock( 0, 0, (BYTE**)&VertArray, 0 );

	return true;
}

void CALL HGE_Impl::Gfx_EndScene()
{
    PROFILE_FUNC();
    _render_batch(true);

	PROFILE_BEGIN(pD3DDevice_EndScene);
	pD3DDevice->EndScene();
	PROFILE_END();

#ifdef LOCK_RENDER_TARGET_TO_AVOID_STALL
    PROFILE_BEGIN(lock_render_target_to_avoid_stall);
    if (pScreenSurf)
    {
        D3DLOCKED_RECT lockedRect;
        pScreenSurf->LockRect(&lockedRect, NULL, D3DLOCK_READONLY);
        pScreenSurf->UnlockRect();
    }
    PROFILE_END();
#endif LOCK_RENDER_TARGET_TO_AVOID_STALL

    PROFILE_BEGIN(pD3DDevice_Present);
	if(!pCurTarget) pD3DDevice->Present( NULL, NULL, NULL, NULL );
	PROFILE_END();
}

void CALL HGE_Impl::Gfx_RenderLine(float x1, float y1, float x2, float y2, DWORD color, float z)
{
	PROFILE_FUNC();
	if(VertArray)
	{
		if(CurPrimType!=HGEPRIM_LINES || nPrim>=VERTEX_BUFFER_SIZE/HGEPRIM_LINES || CurTexture0 || CurTexture1 || CurBlendMode!=BLEND_DEFAULT)
		{
			_render_batch();

			CurPrimType=HGEPRIM_LINES;
			if(CurBlendMode != BLEND_DEFAULT) _SetBlendMode(BLEND_DEFAULT);
			if(CurTexture0) { pD3DDevice->SetTexture(0, 0); CurTexture0=0; }
			if(CurTexture1) { pD3DDevice->SetTexture(0, 0); CurTexture1=0; }
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
	PROFILE_FUNC();
	if(VertArray)
	{
		if(CurPrimType!=HGEPRIM_TRIPLES || nPrim>=VERTEX_BUFFER_SIZE/HGEPRIM_TRIPLES || CurTexture0!=triple->tex || CurBlendMode!=triple->blend)
		{
			_render_batch();

			CurPrimType=HGEPRIM_TRIPLES;
			if(CurBlendMode != triple->blend) _SetBlendMode(triple->blend);
			if(triple->tex != CurTexture0) {
				pD3DDevice->SetTexture( 0, (LPDIRECT3DTEXTURE8)triple->tex );
				CurTexture0 = triple->tex;
			}
			pD3DDevice->SetTexture( 1, (LPDIRECT3DTEXTURE8)0 );
			CurTexture1 = 0;
		}

		memcpy(&VertArray[nPrim*HGEPRIM_TRIPLES], triple->v, sizeof(hgeVertex)*HGEPRIM_TRIPLES);
		nPrim++;
	}
}

void CALL HGE_Impl::Gfx_RenderQuad(const hgeQuad *quad)
{
	PROFILE_FUNC();
	if(VertArray)
	{
		// HGE_MODIFY (Single Pass Multitexturing) {
		if(CurPrimType!=HGEPRIM_QUADS || nPrim>=VERTEX_BUFFER_SIZE/HGEPRIM_QUADS || CurTexture0!=quad->tex || CurTexture1!=quad->tex_mask || CurBlendMode!=quad->blend)
		// }			
		{
			_render_batch();

			CurPrimType=HGEPRIM_QUADS;
			if(CurBlendMode != quad->blend) _SetBlendMode(quad->blend);

			if(quad->tex != CurTexture0)
			{
                PROFILE_BEGIN(SetTexture);
				pD3DDevice->SetTexture( 0, (LPDIRECT3DTEXTURE8)quad->tex );
				CurTexture0 = quad->tex;
                PROFILE_END();
			}

			// HGE_MODIFY (Single Pass Multitexturing) {
			if (quad->tex_mask != CurTexture1)
			{
				pD3DDevice->SetTexture( 1, (LPDIRECT3DTEXTURE8)quad->tex_mask );
				CurTexture1 = quad->tex_mask;
			}
			// }
		}

		// HGE_MODIFY (Single Pass Multitexturing) {
		if (quad->tex_mask)
		{
			D3DXMATRIX mat1;
			D3DXMatrixIdentity(&mat1);

			//if (quad->x_mask_scale != 1.f || quad->y_mask_scale != 1.f)
			{
				//*
				float mask_w = (quad->v[1].tx_mask - quad->v[0].tx_mask) * Texture_GetWidth((HTEXTURE)quad->tex_mask);
				float mask_h = (quad->v[2].ty_mask - quad->v[1].ty_mask) * Texture_GetHeight((HTEXTURE)quad->tex_mask);
				//*/

				//*
				float t0_w = (quad->v[1].tx - quad->v[0].tx) * Texture_GetWidth((HTEXTURE)quad->tex);
				float t0_h = (quad->v[2].ty - quad->v[1].ty) * Texture_GetHeight((HTEXTURE)quad->tex);
				//*/

				/*
				float mask_w = Texture_GetWidth((HTEXTURE)quad->tex_mask, true);
				float mask_h = Texture_GetHeight((HTEXTURE)quad->tex_mask, true);
				//*/

				/*
				float t0_w = Texture_GetWidth((HTEXTURE)quad->tex, true);
				float t0_h = Texture_GetHeight((HTEXTURE)quad->tex, true);
				//*/

				float mask_scale_x = t0_w / mask_w / quad->x_mask_scale;
				float mask_scale_y = t0_h / mask_h / quad->y_mask_scale;

				D3DXMatrixScaling(&mat1, mask_scale_x, mask_scale_y, 1.f);
			}

			/*
			if (quad->mask_angle != 0.f)
			{
				D3DXMatrixRotationX(&mat1, quad->mask_angle);
				D3DXMatrixRotationY(&mat1, quad->mask_angle);
			}
			*/

			if (quad->x_mask_offset != 0.f || quad->y_mask_offset != 0.f)
			{
				mat1(2, 0) = -quad->x_mask_offset;
				mat1(2, 1) = -quad->y_mask_offset;
			}

			pD3DDevice->SetTransform(D3DTS_TEXTURE1, &mat1);
		}

		memcpy(&VertArray[nPrim*HGEPRIM_QUADS], quad->v, sizeof(hgeVertex)*HGEPRIM_QUADS);
		nPrim++;

		// HGE_MODIFY (Single Pass Multitexturing) {
		/*
		if (quad->tex_mask)
		{
			memcpy(&VertArray[nPrim*HGEPRIM_QUADS], quad->v, sizeof(hgeVertex)*HGEPRIM_QUADS);
			nPrim++;
		}
		*/
		// }
	}
}

hgeVertex* CALL HGE_Impl::Gfx_StartBatch(int prim_type, HTEXTURE tex, HTEXTURE tex_mask, int blend, int *max_prim)
{
    PROFILE_FUNC();
	if(VertArray)
	{
		_render_batch();

		CurPrimType=prim_type;
		if(CurBlendMode != blend) _SetBlendMode(blend);
		if(tex != CurTexture0)
		{
            PROFILE_BEGIN(SetTexture);
			pD3DDevice->SetTexture( 0, (LPDIRECT3DTEXTURE8)tex );
            PROFILE_END();

			// HGE_MODIFY (Single Pass Multitexturing) {
			if (tex_mask != CurTexture1)
			{
				pD3DDevice->SetTexture( 1, (LPDIRECT3DTEXTURE8)tex_mask );
				CurTexture1 = tex_mask;
			}
			// }

			CurTexture0 = tex;
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

HTARGET CALL HGE_Impl::Target_Create(int width, int height, bool zbuffer)
{
	CRenderTargetList *pTarget;
	D3DSURFACE_DESC TDesc;

	pTarget = new CRenderTargetList;
	pTarget->pTex=0;
	pTarget->pDepth=0;

	if(FAILED(D3DXCreateTexture(pD3DDevice, width, height, 1, D3DUSAGE_RENDERTARGET,
						d3dpp->BackBufferFormat, D3DPOOL_DEFAULT, &pTarget->pTex)))
	{
		_PostError("Can't create render target texture");
		delete pTarget;
		return 0;
	}

	pTarget->pTex->GetLevelDesc(0, &TDesc);
	pTarget->width=TDesc.Width;
	pTarget->height=TDesc.Height;

	if(zbuffer)
	{
		if(FAILED(pD3DDevice->CreateDepthStencilSurface(pTarget->width, pTarget->height,
						D3DFMT_D16, D3DMULTISAMPLE_NONE, &pTarget->pDepth)))
		{   
			pTarget->pTex->Release();
			_PostError("Can't create render target depth buffer");
			delete pTarget;
			return 0;
		}
	}

	pTarget->next=pTargets;
	pTargets=pTarget;

	return (HTARGET)pTarget;
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

			if(pTarget->pTex) pTarget->pTex->Release();
			if(pTarget->pDepth) pTarget->pDepth->Release();

			delete pTarget;
			return;
		}

		pPrevTarget = pTarget;
		pTarget = pTarget->next;
	}
}

HTEXTURE CALL HGE_Impl::Target_GetTexture(HTARGET target)
{
	CRenderTargetList *targ=(CRenderTargetList *)target;
	if(target) return (HTEXTURE)targ->pTex;
	else return 0;
}

HTEXTURE CALL HGE_Impl::Texture_Create(int width, int height)
{
	LPDIRECT3DTEXTURE8 pTex;

	if( FAILED( D3DXCreateTexture( pD3DDevice, width, height,
										1,					// Mip levels
										0,					// Usage
										D3DFMT_A8R8G8B8,	// Format
										D3DPOOL_MANAGED,	// Memory pool
										&pTex ) ) )
	{	
		_PostError("Can't create texture");
		return NULL;
	}

	return (HTEXTURE)pTex;
}

HTEXTURE CALL HGE_Impl::Texture_Load(const char *filename, DWORD size, bool bMipmap)
{
	//const void *data;
    void *data;
	DWORD _size;
	D3DFORMAT fmt1, fmt2;
	LPDIRECT3DTEXTURE8 pTex;
	D3DXIMAGE_INFO info;
	CTextureList *texItem;
    IInputStream *file = NULL;

	if(size) { data=(void *)filename; _size=size; }
	else
	{
     //   file = FS.openFileToRead(filename);
	    //if(!file) return NULL;
     //   _size = file->size();
     //   data = file->buffer();

        data=pHGE->Resource_Load(filename, &_size);

        if(!data) return NULL;
	}

	if(*(DWORD*)data == 0x20534444) // Compressed DDS format magic number
	{
		fmt1=D3DFMT_UNKNOWN;
		fmt2=D3DFMT_A8R8G8B8;
	}
	else
	{
		fmt1=D3DFMT_A8R8G8B8;
		fmt2=D3DFMT_UNKNOWN;
	}

//	if( FAILED( D3DXCreateTextureFromFileInMemory( pD3DDevice, data, _size, &pTex ) ) ) pTex=NULL;
	if( FAILED( D3DXCreateTextureFromFileInMemoryEx( pD3DDevice, data, _size,
										D3DX_DEFAULT, D3DX_DEFAULT,
										bMipmap ? 0:1,		// Mip levels
										0,					// Usage
										fmt1,				// Format
										D3DPOOL_MANAGED,	// Memory pool
										D3DX_FILTER_NONE,	// Filter
										D3DX_DEFAULT,		// Mip filter
										0,					// Color key
										&info, NULL,
										&pTex ) ) )

	if( FAILED( D3DXCreateTextureFromFileInMemoryEx( pD3DDevice, data, _size,
										D3DX_DEFAULT, D3DX_DEFAULT,
										bMipmap ? 0:1,		// Mip levels
										0,					// Usage
										fmt2,				// Format
										D3DPOOL_MANAGED,	// Memory pool
										D3DX_FILTER_NONE,	// Filter
										D3DX_DEFAULT,		// Mip filter
										0,					// Color key
										&info, NULL,
										&pTex ) ) )

	{	
		_PostError("Can't create texture");
		if(!size) Resource_Free(data);
        //if (file) file->release();
		return NULL;
	}

	if(!size) Resource_Free(data);
    //if (file) file->release();
	
	texItem=new CTextureList;
	texItem->tex=(HTEXTURE)pTex;
	texItem->width=info.Width;
	texItem->height=info.Height;
	texItem->next=textures;
	textures=texItem;

	return (HTEXTURE)pTex;
}

void CALL HGE_Impl::Texture_Free(HTEXTURE tex)
{
	LPDIRECT3DTEXTURE8 pTex=(LPDIRECT3DTEXTURE8)tex;
	CTextureList *texItem=textures, *texPrev=0;

	while(texItem)
	{
		if(texItem->tex==tex)
		{
			if(texPrev) texPrev->next=texItem->next;
			else textures=texItem->next;
			delete texItem;
			break;
		}
		texPrev=texItem;
		texItem=texItem->next;
	}
	if(pTex != NULL) pTex->Release();
}

int CALL HGE_Impl::Texture_GetWidth(HTEXTURE tex, bool bOriginal)
{
    PROFILE_FUNC();
	D3DSURFACE_DESC TDesc;
	LPDIRECT3DTEXTURE8 pTex=(LPDIRECT3DTEXTURE8)tex;
	CTextureList *texItem=textures;

	if(bOriginal)
	{
		while(texItem)
		{
			if(texItem->tex==tex) return texItem->width;
			texItem=texItem->next;
		}
		return 0;
	}
	else
	{
		if(FAILED(pTex->GetLevelDesc(0, &TDesc))) return 0;
		else return TDesc.Width;
	}
}


int CALL HGE_Impl::Texture_GetHeight(HTEXTURE tex, bool bOriginal)
{
    PROFILE_FUNC();
	D3DSURFACE_DESC TDesc;
	LPDIRECT3DTEXTURE8 pTex=(LPDIRECT3DTEXTURE8)tex;
	CTextureList *texItem=textures;

	if(bOriginal)
	{
		while(texItem)
		{
			if(texItem->tex==tex) return texItem->height;
			texItem=texItem->next;
		}
		return 0;
	}
	else
	{
		if(FAILED(pTex->GetLevelDesc(0, &TDesc))) return 0;
		else return TDesc.Height;
	}
}


void * CALL HGE_Impl::Texture_Lock(HTEXTURE tex, bool bReadOnly, int left, int top, int width, int height)
{
    PROFILE_FUNC();
	LPDIRECT3DTEXTURE8 pTex=(LPDIRECT3DTEXTURE8)tex;
	D3DSURFACE_DESC TDesc;
	D3DLOCKED_RECT TRect;
	RECT region, *prec;
	int flags;

	pTex->GetLevelDesc(0, &TDesc);
	if(TDesc.Format!=D3DFMT_A8R8G8B8 && TDesc.Format!=D3DFMT_X8R8G8B8) return 0;

	if(width && height)
	{
		region.left=left;
		region.top=top;
		region.right=left+width;
		region.bottom=top+height;
		prec=&region;
	}
	else prec=0;

	if(bReadOnly) flags=D3DLOCK_READONLY;
	else flags=0;

	if(FAILED(pTex->LockRect(0, &TRect, prec, flags)))
	{
		_PostError("Can't lock texture");
		return 0;
	}

	return (DWORD *)TRect.pBits;
}


void CALL HGE_Impl::Texture_Unlock(HTEXTURE tex)
{
    PROFILE_FUNC();
	LPDIRECT3DTEXTURE8 pTex=(LPDIRECT3DTEXTURE8)tex;
	pTex->UnlockRect(0);
}

//////// Implementation ////////

// HGE_MODIFY (Single Pass Multitexturing) {
/*
void Matrix4x4To3x3(D3DXMATRIX *matOut, D3DXMATRIX *matIn)
{
	matOut->_11 = matIn->_11; // Скопировать первую строчку
	matOut->_12 = matIn->_12;
	matOut->_13 = matIn->_13;
	matOut->_14 = 0.0f;
	matOut->_21 = matIn->_21; // Скопировать вторую строчку
	matOut->_22 = matIn->_22;
	matOut->_23 = matIn->_23;
	matOut->_24 = 0.0f;
	matOut->_31 = matIn->_41; // Скопировать нижнюю строчку,
	matOut->_32 = matIn->_42; // используемую для перемещения
	matOut->_33 = matIn->_43;
	matOut->_34 = 0.0f;
	matOut->_41 = 0.0f; // Очистить нижнюю строчку
	matOut->_42 = 0.0f;
	matOut->_43 = 0.0f;
	matOut->_44 = 1.0f;
}
*/

void HGE_Impl::_render_batch(bool bEndScene)
{
	PROFILE_FUNC();
	if(VertArray)
	{
		pVB->Unlock();
		
		if(nPrim)
		{
			switch(CurPrimType)
			{
				case HGEPRIM_QUADS:
                {
                    PROFILE_BEGIN(_draw_indexed_quads);
					pD3DDevice->DrawIndexedPrimitive(D3DPT_TRIANGLELIST, 0, nPrim<<2, 0, nPrim<<1);
                    PROFILE_END();
					break;
                }

				case HGEPRIM_TRIPLES:
                {
                    PROFILE_BEGIN(_draw_indexed_tripples);
					pD3DDevice->DrawPrimitive(D3DPT_TRIANGLELIST, 0, nPrim);
                    PROFILE_END();
					break;
                }

				case HGEPRIM_LINES:
                {
                    PROFILE_BEGIN(_draw_indexed_lines);
					pD3DDevice->DrawPrimitive(D3DPT_LINELIST, 0, nPrim);
                    PROFILE_END();
					break;
                }
			}

			nPrim=0;
		}

		if(bEndScene) VertArray = 0;
		else pVB->Lock( 0, 0, (BYTE**)&VertArray, 0 );
	}
}

void HGE_Impl::_SetBlendMode(int blend)
{
    PROFILE_FUNC();
	// HGE_MODIFY (DirectX blend modes) {
	if (blend & BLEND_DX) {
		if(blend & BLEND_SRC_ZERO)
			pD3DDevice->SetRenderState(D3DRS_SRCBLEND, D3DBLEND_ZERO);
		else if(blend & BLEND_SRC_ONE)
			pD3DDevice->SetRenderState(D3DRS_SRCBLEND, D3DBLEND_ONE);
		else if(blend & BLEND_SRC_SRCCOLOR)
			pD3DDevice->SetRenderState(D3DRS_SRCBLEND, D3DBLEND_SRCCOLOR);
		else if(blend & BLEND_SRC_INVSRCCOLOR)
			pD3DDevice->SetRenderState(D3DRS_SRCBLEND, D3DBLEND_INVSRCCOLOR);
		else if(blend & BLEND_SRC_INVSRCALPHA)
			pD3DDevice->SetRenderState(D3DRS_SRCBLEND, D3DBLEND_INVSRCALPHA);
		else if(blend & BLEND_SRC_DESTALPHA)
			pD3DDevice->SetRenderState(D3DRS_SRCBLEND, D3DBLEND_DESTALPHA);
		else if(blend & BLEND_SRC_INVDESTALPHA)
			pD3DDevice->SetRenderState(D3DRS_SRCBLEND, D3DBLEND_INVDESTALPHA);
		else if(blend & BLEND_SRC_DESTCOLOR)
			pD3DDevice->SetRenderState(D3DRS_SRCBLEND, D3DBLEND_DESTCOLOR);
		else if(blend & BLEND_SRC_INVDESTCOLOR)
			pD3DDevice->SetRenderState(D3DRS_SRCBLEND, D3DBLEND_INVDESTCOLOR);
		else
			pD3DDevice->SetRenderState(D3DRS_SRCBLEND, D3DBLEND_SRCALPHA);

		if(blend & BLEND_DEST_ZERO)
			pD3DDevice->SetRenderState(D3DRS_DESTBLEND, D3DBLEND_ZERO);
		else if(blend & BLEND_DEST_ONE)
			pD3DDevice->SetRenderState(D3DRS_DESTBLEND, D3DBLEND_ONE);
		else if(blend & BLEND_DEST_SRCCOLOR)
			pD3DDevice->SetRenderState(D3DRS_DESTBLEND, D3DBLEND_SRCCOLOR);
		else if(blend & BLEND_DEST_INVSRCCOLOR)
			pD3DDevice->SetRenderState(D3DRS_DESTBLEND, D3DBLEND_INVSRCCOLOR);
		else if(blend & BLEND_DEST_SRCALPHA)
			pD3DDevice->SetRenderState(D3DRS_DESTBLEND, D3DBLEND_SRCALPHA);
		else if(blend & BLEND_DEST_DESTALPHA)
			pD3DDevice->SetRenderState(D3DRS_DESTBLEND, D3DBLEND_DESTALPHA);
		else if(blend & BLEND_DEST_INVDESTALPHA)
			pD3DDevice->SetRenderState(D3DRS_DESTBLEND, D3DBLEND_INVDESTALPHA);
		else if(blend & BLEND_DEST_DESTCOLOR)
			pD3DDevice->SetRenderState(D3DRS_DESTBLEND, D3DBLEND_DESTCOLOR);
		else if(blend & BLEND_DEST_INVDESTCOLOR)
			pD3DDevice->SetRenderState(D3DRS_DESTBLEND, D3DBLEND_INVDESTCOLOR);
		else
			pD3DDevice->SetRenderState(D3DRS_DESTBLEND, D3DBLEND_INVSRCALPHA);

		//pD3DDevice->SetTextureStageState(0, D3DTSS_COLOROP, D3DTOP_MODULATE);
		// HGE_MODIFY (Single Pass Multitexturing) {
		/*
		pD3DDevice->SetTextureStageState(0, D3DTSS_COLORARG1, D3DTA_TEXTURE);
		pD3DDevice->SetTextureStageState(0, D3DTSS_COLOROP, D3DTOP_SELECTARG1);
		*/
		pD3DDevice->SetTextureStageState(1, D3DTSS_COLORARG1, D3DTA_TEXTURE);
		pD3DDevice->SetTextureStageState(1, D3DTSS_COLORARG2, D3DTA_CURRENT);
		pD3DDevice->SetTextureStageState(1, D3DTSS_COLOROP, D3DTOP_MODULATE);
		// }
	}
	else
	{
	// }
		pD3DDevice->SetRenderState(D3DRS_SRCBLEND, D3DBLEND_SRCALPHA);

		if((blend & BLEND_ALPHABLEND) != (CurBlendMode & BLEND_ALPHABLEND))
		{
			if(blend & BLEND_ALPHABLEND) pD3DDevice->SetRenderState(D3DRS_DESTBLEND, D3DBLEND_INVSRCALPHA);
			else pD3DDevice->SetRenderState(D3DRS_DESTBLEND, D3DBLEND_ONE);
		}

		if((blend & BLEND_ZWRITE) != (CurBlendMode & BLEND_ZWRITE))
		{
			if(blend & BLEND_ZWRITE) pD3DDevice->SetRenderState(D3DRS_ZWRITEENABLE, TRUE);
			else pD3DDevice->SetRenderState(D3DRS_ZWRITEENABLE, FALSE);
		}			

		if((blend & BLEND_COLORADD) != (CurBlendMode & BLEND_COLORADD))
		{
			if(blend & BLEND_COLORADD) pD3DDevice->SetTextureStageState(0, D3DTSS_COLOROP, D3DTOP_ADD);
			else pD3DDevice->SetTextureStageState(0, D3DTSS_COLOROP, D3DTOP_MODULATE);

			// HGE_MODIFY (Single Pass Multitexturing) {
			pD3DDevice->SetTextureStageState(1, D3DTSS_COLOROP, D3DTOP_MODULATE);
			// }
		}
		//*/

		//pD3DDevice->SetTextureStageState(0, D3DTSS_COLOROP, D3DTOP_MODULATE);
		// HGE_MODIFY (Single Pass Multitexturing) {
		/*
		pD3DDevice->SetTextureStageState(0, D3DTSS_COLORARG1, D3DTA_TEXTURE);
		pD3DDevice->SetTextureStageState(0, D3DTSS_COLOROP, D3DTOP_SELECTARG1);
		pD3DDevice->SetTextureStageState(1, D3DTSS_COLORARG1, D3DTA_TEXTURE);
		pD3DDevice->SetTextureStageState(1, D3DTSS_COLORARG2, D3DTA_CURRENT);
		pD3DDevice->SetTextureStageState(1, D3DTSS_COLOROP, D3DTOP_MODULATE);

		pD3DDevice->SetTextureStageState( 1, D3DTSS_ALPHAARG1, D3DTA_TEXTURE );
		pD3DDevice->SetTextureStageState( 1, D3DTSS_ALPHAOP,   D3DTOP_SELECTARG1 );
		pD3DDevice->SetTextureStageState( 1, D3DTSS_COLOROP, D3DTOP_BLENDTEXTUREALPHA );
		//*/

		// ? Или наоборот
		pD3DDevice->SetTextureStageState(1, D3DTSS_COLORARG1, D3DTA_CURRENT);
		pD3DDevice->SetTextureStageState(1, D3DTSS_COLORARG2, D3DTA_TEXTURE);
		//pD3DDevice->SetTextureStageState(1, D3DTSS_COLORARG1, D3DTA_TEXTURE);
		//pD3DDevice->SetTextureStageState(1, D3DTSS_COLORARG2, D3DTA_CURRENT);

		pD3DDevice->SetTextureStageState(1, D3DTSS_COLOROP, D3DTOP_MODULATE);
		//pD3DDevice->SetTextureStageState( 1, D3DTSS_ALPHAARG1, D3DTA_TEXTURE );
		//pD3DDevice->SetTextureStageState( 1, D3DTSS_ALPHAOP,   D3DTOP_SELECTARG1 );
		//pD3DDevice->SetTextureStageState( 1, D3DTSS_COLOROP, D3DTOP_BLENDTEXTUREALPHA );

		/*
		pD3DDevice->SetTextureStageState(0,D3DTSS_COLOROP,D3DTOP_SELECTARG1);
		pD3DDevice->SetTextureStageState(0,D3DTSS_COLORARG1,D3DTA_TEXTURE);
		pD3DDevice->SetTextureStageState(0,D3DTSS_ALPHAOP,D3DTOP_SELECTARG1);
		pD3DDevice->SetTextureStageState(0,D3DTSS_ALPHAARG1,D3DTA_TEXTURE);

		pD3DDevice->SetTextureStageState(1,D3DTSS_COLOROP,D3DTOP_SELECTARG1);
		pD3DDevice->SetTextureStageState(1,D3DTSS_COLORARG1,D3DTA_CURRENT);
		pD3DDevice->SetTextureStageState(1,D3DTSS_ALPHAOP,D3DTOP_SELECTARG1);
		pD3DDevice->SetTextureStageState(1,D3DTSS_ALPHAARG1,D3DTA_TEXTURE);
		*/

		/*
		// Enable standard blend.
		pD3DDevice->SetRenderState(D3DRS_ALPHABLENDENABLE, TRUE);
		pD3DDevice->SetRenderState(D3DRS_SRCBLEND, D3DBLEND_SRCALPHA);
		pD3DDevice->SetRenderState(D3DRS_DESTBLEND, D3DBLEND_INVSRCALPHA);
		// If alpha is 0, don't render it, skip this fragment(pixel)
		pD3DDevice->SetRenderState(D3DRS_ALPHATESTENABLE, TRUE);
		pD3DDevice->SetRenderState(D3DRS_ALPHAFUNC, D3DCMP_GREATER);
		pD3DDevice->SetRenderState(D3DRS_ALPHAREF, 0);
		// Mix texture with material or vertex color. Alpha from texture.
		pD3DDevice->SetTextureStageState(0, D3DTSS_COLOROP, D3DTOP_MODULATE);
		pD3DDevice->SetTextureStageState(0, D3DTSS_COLORARG1, D3DTA_TEXTURE);
		pD3DDevice->SetTextureStageState(0, D3DTSS_COLORARG2, D3DTA_DIFFUSE);
		pD3DDevice->SetTextureStageState(0, D3DTSS_ALPHAOP, D3DTOP_SELECTARG1);
		pD3DDevice->SetTextureStageState(0, D3DTSS_ALPHAARG1, D3DTA_TEXTURE);
		pD3DDevice->SetTextureStageState(1, D3DTSS_COLOROP, D3DTOP_DISABLE);
		//*/
		// }

		//* Light map
		/*
		pD3DDevice->SetTextureStageState( 0, D3DTSS_COLOROP,   D3DTOP_MODULATE );
		pD3DDevice->SetTextureStageState( 0, D3DTSS_COLORARG1, D3DTA_TEXTURE );
		pD3DDevice->SetTextureStageState( 0, D3DTSS_COLORARG2, D3DTA_DIFFUSE );
		pD3DDevice->SetTextureStageState( 0, D3DTSS_ALPHAOP,   D3DTOP_SELECTARG2 );
		pD3DDevice->SetTextureStageState( 0, D3DTSS_ALPHAARG2, D3DTA_DIFFUSE );
		//*/
		/*
		pD3DDevice->SetTextureStageState( 1, D3DTSS_COLOROP,   D3DTOP_MODULATE );
		pD3DDevice->SetTextureStageState( 1, D3DTSS_COLORARG1, D3DTA_TEXTURE );
		pD3DDevice->SetTextureStageState( 1, D3DTSS_COLORARG2, D3DTA_CURRENT );
		pD3DDevice->SetTextureStageState( 1, D3DTSS_ALPHAOP,   D3DTOP_SELECTARG1 );
		pD3DDevice->SetTextureStageState( 1, D3DTSS_ALPHAARG1, D3DTA_TEXTURE );
		//*/

		pD3DDevice->SetTextureStageState( 1, D3DTSS_COLOROP,   D3DTOP_MODULATE );
		pD3DDevice->SetTextureStageState( 1, D3DTSS_COLORARG1, D3DTA_TEXTURE );
		pD3DDevice->SetTextureStageState( 1, D3DTSS_COLORARG2, D3DTA_CURRENT );
		pD3DDevice->SetTextureStageState( 1, D3DTSS_ALPHAOP,   D3DTOP_MODULATE );
		pD3DDevice->SetTextureStageState( 1, D3DTSS_ALPHAARG1, D3DTA_TEXTURE );
		//*/


		// HGE_MODIFY: {
	}
	// }

	// original
	/*
	if((blend & BLEND_ALPHABLEND) != (CurBlendMode & BLEND_ALPHABLEND))
	{
		if(blend & BLEND_ALPHABLEND) pD3DDevice->SetRenderState(D3DRS_DESTBLEND, D3DBLEND_INVSRCALPHA);
		else pD3DDevice->SetRenderState(D3DRS_DESTBLEND, D3DBLEND_ONE);
	}

	if((blend & BLEND_ZWRITE) != (CurBlendMode & BLEND_ZWRITE))
	{
		if(blend & BLEND_ZWRITE) pD3DDevice->SetRenderState(D3DRS_ZWRITEENABLE, TRUE);
		else pD3DDevice->SetRenderState(D3DRS_ZWRITEENABLE, FALSE);
	}			

	if((blend & BLEND_COLORADD) != (CurBlendMode & BLEND_COLORADD))
	{
		if(blend & BLEND_COLORADD) pD3DDevice->SetTextureStageState(0, D3DTSS_COLOROP, D3DTOP_ADD);
		else pD3DDevice->SetTextureStageState(0, D3DTSS_COLOROP, D3DTOP_MODULATE);
	}
	*/

	CurBlendMode = blend;
}

void HGE_Impl::_SetProjectionMatrix(int width, int height)
{
    PROFILE_FUNC();
	D3DXMATRIX tmp;
	D3DXMatrixScaling(&matProj, 1.0f, -1.0f, 1.0f);
	D3DXMatrixTranslation(&tmp, -0.5f, height+0.5f, 0.0f);
	D3DXMatrixMultiply(&matProj, &matProj, &tmp);
	D3DXMatrixOrthoOffCenterLH(&tmp, 0, (float)width, 0, (float)height, 0.0f, 1.0f);
	D3DXMatrixMultiply(&matProj, &matProj, &tmp);
}

bool HGE_Impl::_GfxInit()
{
	static const char *szFormats[]={"UNKNOWN", "R5G6B5", "X1R5G5B5", "A1R5G5B5", "X8R8G8B8", "A8R8G8B8"};
	D3DADAPTER_IDENTIFIER8 AdID;
	D3DDISPLAYMODE Mode;
	D3DFORMAT Format=D3DFMT_UNKNOWN;
	UINT nModes, i;
	
// Init D3D
							
	pD3D=Direct3DCreate8(120); // D3D_SDK_VERSION
	if(pD3D==NULL)
	{
		_PostError("Can't create D3D interface");
		return false;
	}

// Get adapter info

	pD3D->GetAdapterIdentifier(D3DADAPTER_DEFAULT, D3DENUM_NO_WHQL_LEVEL, &AdID);
	System_Log("D3D Driver: %s",AdID.Driver);
	System_Log("Description: %s",AdID.Description);
	System_Log("Version: %d.%d.%d.%d",
			   HIWORD(AdID.DriverVersion.HighPart),
			   LOWORD(AdID.DriverVersion.HighPart),
			   HIWORD(AdID.DriverVersion.LowPart),
			   LOWORD(AdID.DriverVersion.LowPart));

	// Single Pass Multitexturing {
	D3DCAPS8 caps;
	pD3D->GetDeviceCaps(D3DADAPTER_DEFAULT, D3DDEVTYPE_HAL, &caps);
	System_Log("MaxSimultaneousTextures: %d", caps.MaxSimultaneousTextures);

	if (caps.MaxSimultaneousTextures < 2)
	{
		_PostError("Single pass multitexturing not supported");
		return false;
	}
	// }

// Set up Windowed presentation parameters
	
	if(FAILED(pD3D->GetAdapterDisplayMode(D3DADAPTER_DEFAULT, &Mode)) || Mode.Format==D3DFMT_UNKNOWN) 
	{
		_PostError("Can't determine desktop video mode");
		if(bWindowed) return false;
	}
	
	ZeroMemory(&d3dppW, sizeof(d3dppW));

	d3dppW.BackBufferWidth  		= nScreenWidth;
	d3dppW.BackBufferHeight 		= nScreenHeight;
	d3dppW.BackBufferFormat 		= Mode.Format;
	d3dppW.BackBufferCount  		= 1;
	d3dppW.MultiSampleType  		= D3DMULTISAMPLE_NONE;
	d3dppW.hDeviceWindow    		= hwnd;
	d3dppW.Windowed					= TRUE;
#ifdef LOCK_RENDER_TARGET_TO_AVOID_STALL
    d3dppW.Flags					= D3DPRESENTFLAG_LOCKABLE_BACKBUFFER;
#endif
	d3dppW.SwapEffect				= D3DSWAPEFFECT_COPY;

	if (nHGEFPS == HGEFPS_VSYNC)
	{
		d3dppW.SwapEffect			= D3DSWAPEFFECT_COPY_VSYNC;
	}
	

	if(bZBuffer)
	{
		d3dppW.EnableAutoDepthStencil = TRUE;
		d3dppW.AutoDepthStencilFormat = D3DFMT_D16;
	}

// Set up Full Screen presentation parameters

	nModes=pD3D->GetAdapterModeCount(D3DADAPTER_DEFAULT);

	for(i=0; i<nModes; i++)
	{
		pD3D->EnumAdapterModes(D3DADAPTER_DEFAULT, i, &Mode);
		if(Mode.Width != (UINT)nScreenWidth || Mode.Height != (UINT)nScreenHeight) continue;
		if(nScreenBPP==16 && (_format_id(Mode.Format) > _format_id(D3DFMT_A1R5G5B5))) continue;
		if(_format_id(Mode.Format) > _format_id(Format)) Format=Mode.Format;
	}

	if(Format == D3DFMT_UNKNOWN)
	{
		_PostError("Can't find appropriate full screen video mode");
		if(!bWindowed) return false;
	}

	ZeroMemory(&d3dppFS, sizeof(d3dppFS));

	d3dppFS.BackBufferWidth  				= nScreenWidth;
	d3dppFS.BackBufferHeight 				= nScreenHeight;
	d3dppFS.BackBufferFormat 				= Format;
	d3dppFS.BackBufferCount  				= 1;
	d3dppFS.MultiSampleType  				= D3DMULTISAMPLE_NONE;
	d3dppFS.hDeviceWindow    				= hwnd;
	d3dppFS.Windowed         				= FALSE;
#ifdef LOCK_RENDER_TARGET_TO_AVOID_STALL
    d3dppFS.Flags							= D3DPRESENTFLAG_LOCKABLE_BACKBUFFER;
#endif

	d3dppFS.SwapEffect						= D3DSWAPEFFECT_FLIP;
	d3dppFS.FullScreen_RefreshRateInHz		= D3DPRESENT_RATE_DEFAULT;
	d3dppFS.FullScreen_PresentationInterval	= D3DPRESENT_INTERVAL_IMMEDIATE;

	if (nHGEFPS == HGEFPS_VSYNC)
	{
		d3dppFS.FullScreen_PresentationInterval = D3DPRESENT_INTERVAL_ONE;
		d3dppFS.SwapEffect						= D3DSWAPEFFECT_COPY_VSYNC;
	}
	

	if (bZBuffer)
	{
		d3dppFS.EnableAutoDepthStencil = TRUE;
		d3dppFS.AutoDepthStencilFormat = D3DFMT_D16;
	}

	d3dpp = bWindowed ? &d3dppW : &d3dppFS;

	if(_format_id(d3dpp->BackBufferFormat) < 4) nScreenBPP=16;
	else nScreenBPP=32;
	
// Create D3D Device

	if( FAILED( pD3D->CreateDevice( D3DADAPTER_DEFAULT, D3DDEVTYPE_HAL, hwnd,
                                  D3DCREATE_SOFTWARE_VERTEXPROCESSING,
                                  d3dpp, &pD3DDevice ) ) )
	{
		_PostError("Can't create D3D device");
		return false;
	}

	_AdjustWindow();

	System_Log("Mode: %d x %d x %s\n",nScreenWidth,nScreenHeight,szFormats[_format_id(Format)]);

// Create vertex batch buffer

	VertArray=0;
	textures=0;

// Init all stuff that can be lost

	_SetProjectionMatrix(nScreenWidth, nScreenHeight);
	D3DXMatrixIdentity(&matView);

	
	if(!_init_lost()) return false;

	Gfx_Clear(0);

	return true;
}

int HGE_Impl::_format_id(D3DFORMAT fmt)
{
	switch(fmt) {
		case D3DFMT_R5G6B5:		return 1;
		case D3DFMT_X1R5G5B5:	return 2;
		case D3DFMT_A1R5G5B5:	return 3;
		case D3DFMT_X8R8G8B8:	return 4;
		case D3DFMT_A8R8G8B8:	return 5;
		default:				return 0;
	}
}

void HGE_Impl::_AdjustWindow()
{
	RECT *rc;
	LONG style;

	if(bWindowed) {rc=&rectW; style=styleW; }
	else  {rc=&rectFS; style=styleFS; }
	SetWindowLong(hwnd, GWL_STYLE, style);

	style=GetWindowLong(hwnd, GWL_EXSTYLE);
	if(bWindowed)
	{
		SetWindowLong(hwnd, GWL_EXSTYLE, style & (~WS_EX_TOPMOST));
	    SetWindowPos(hwnd, HWND_NOTOPMOST, rc->left, rc->top, rc->right-rc->left, rc->bottom-rc->top, SWP_FRAMECHANGED);
	}
	else
	{
		SetWindowLong(hwnd, GWL_EXSTYLE, style | WS_EX_TOPMOST);
	    SetWindowPos(hwnd, HWND_TOPMOST, rc->left, rc->top, rc->right-rc->left, rc->bottom-rc->top, SWP_FRAMECHANGED);
	}
}

void HGE_Impl::_Resize(int width, int height)
{
	if(hwndParent)
	{
		//if(procFocusLostFunc) procFocusLostFunc();

		d3dppW.BackBufferWidth=width;
		d3dppW.BackBufferHeight=height;
		nScreenWidth=width;
		nScreenHeight=height;

		_SetProjectionMatrix(nScreenWidth, nScreenHeight);
		_GfxRestore();

		//if(procFocusGainFunc) procFocusGainFunc();
	}
}

void HGE_Impl::_GfxDone()
{
	CRenderTargetList *target=pTargets, *next_target;
	
	while(textures)	Texture_Free(textures->tex);

	if(pScreenSurf) { pScreenSurf->Release(); pScreenSurf=0; }
	if(pScreenDepth) { pScreenDepth->Release(); pScreenDepth=0; }

	while(target)
	{
		if(target->pTex) target->pTex->Release();
		if(target->pDepth) target->pDepth->Release();
		next_target=target->next;
		delete target;
		target=next_target;
	}
	pTargets=0;

	if(pIB)
	{
		pD3DDevice->SetIndices(NULL,0);
		pIB->Release();
		pIB=0;
	}
	if(pVB)
	{
		if(VertArray) {	pVB->Unlock(); VertArray=0;	}
		pD3DDevice->SetStreamSource( 0, NULL, sizeof(hgeVertex) );
		pVB->Release();
		pVB=0;
	}
	if(pD3DDevice) { pD3DDevice->Release(); pD3DDevice=0; }
	if(pD3D) { pD3D->Release(); pD3D=0; }
}


bool HGE_Impl::_GfxRestore()
{
	CRenderTargetList *target=pTargets;

	//if(!pD3DDevice) return false;
	//if(pD3DDevice->TestCooperativeLevel() == D3DERR_DEVICELOST) return;

	if(pScreenSurf) pScreenSurf->Release();
	if(pScreenDepth) pScreenDepth->Release();

	while(target)
	{
		if(target->pTex) target->pTex->Release();
		if(target->pDepth) target->pDepth->Release();
		target=target->next;
	}

	if(pIB)
	{
		pD3DDevice->SetIndices(NULL,0);
		pIB->Release();
	}
	if(pVB)
	{
		pD3DDevice->SetStreamSource( 0, NULL, sizeof(hgeVertex) );
		pVB->Release();
	}

	pD3DDevice->Reset(d3dpp);

	if(!_init_lost()) return false;

	if(procGfxRestoreFunc) return procGfxRestoreFunc();

	return true;
}


bool HGE_Impl::_init_lost()
{
	CRenderTargetList *target=pTargets;

// Store render target

	pScreenSurf=0;
	pScreenDepth=0;

	pD3DDevice->GetRenderTarget(&pScreenSurf);
	pD3DDevice->GetDepthStencilSurface(&pScreenDepth);
	
	while(target)
	{
		if(target->pTex)
			D3DXCreateTexture(pD3DDevice, target->width, target->height, 1, D3DUSAGE_RENDERTARGET,
							  d3dpp->BackBufferFormat, D3DPOOL_DEFAULT, &target->pTex);
		if(target->pDepth)
			pD3DDevice->CreateDepthStencilSurface(target->width, target->height,
												  D3DFMT_D16, D3DMULTISAMPLE_NONE, &target->pDepth);
		target=target->next;
	}

// Create Vertex buffer
	
	if( FAILED (pD3DDevice->CreateVertexBuffer(VERTEX_BUFFER_SIZE*sizeof(hgeVertex),
                                              D3DUSAGE_WRITEONLY,
											  D3DFVF_HGEVERTEX,
                                              D3DPOOL_DEFAULT, &pVB )))
	{
		_PostError("Can't create D3D vertex buffer");
		return false;
	}

	pD3DDevice->SetVertexShader( D3DFVF_HGEVERTEX );
	pD3DDevice->SetStreamSource( 0, pVB, sizeof(hgeVertex) );

// Create and setup Index buffer

	if( FAILED( pD3DDevice->CreateIndexBuffer(VERTEX_BUFFER_SIZE*6/4*sizeof(WORD),
                                              D3DUSAGE_WRITEONLY,
											  D3DFMT_INDEX16,
                                              D3DPOOL_DEFAULT, &pIB ) ) )
	{
		_PostError("Can't create D3D index buffer");
		return false;
	}

	WORD *pIndices, n=0;
	if( FAILED( pIB->Lock( 0, 0, (BYTE**)&pIndices, 0 ) ) )
	{
		_PostError("Can't lock D3D index buffer");
		return false;
	}

	for(int i=0; i<VERTEX_BUFFER_SIZE/4; i++) {
		*pIndices++=n;
		*pIndices++=n+1;
		*pIndices++=n+2;
		*pIndices++=n+2;
		*pIndices++=n+3;
		*pIndices++=n;
		n+=4;
	}

	pIB->Unlock();
	pD3DDevice->SetIndices(pIB,0);

// Set common render states

	//pD3DDevice->SetRenderState( D3DRS_LASTPIXEL, FALSE );
	pD3DDevice->SetRenderState( D3DRS_CULLMODE, D3DCULL_NONE );
	pD3DDevice->SetRenderState( D3DRS_LIGHTING, FALSE );
	
	pD3DDevice->SetRenderState( D3DRS_ALPHABLENDENABLE,   TRUE );
	pD3DDevice->SetRenderState( D3DRS_SRCBLEND,  D3DBLEND_SRCALPHA );
	pD3DDevice->SetRenderState( D3DRS_DESTBLEND, D3DBLEND_INVSRCALPHA );

	pD3DDevice->SetRenderState( D3DRS_ALPHATESTENABLE, TRUE );
	pD3DDevice->SetRenderState( D3DRS_ALPHAREF,        0x01 );
	pD3DDevice->SetRenderState( D3DRS_ALPHAFUNC, D3DCMP_GREATEREQUAL );

	pD3DDevice->SetTextureStageState( 0, D3DTSS_COLOROP,   D3DTOP_MODULATE );
	pD3DDevice->SetTextureStageState( 0, D3DTSS_COLORARG1, D3DTA_TEXTURE );
	pD3DDevice->SetTextureStageState( 0, D3DTSS_COLORARG2, D3DTA_DIFFUSE );

	pD3DDevice->SetTextureStageState( 0, D3DTSS_ALPHAOP,   D3DTOP_MODULATE );
	pD3DDevice->SetTextureStageState( 0, D3DTSS_ALPHAARG1, D3DTA_TEXTURE );
	pD3DDevice->SetTextureStageState( 0, D3DTSS_ALPHAARG2, D3DTA_DIFFUSE );

	pD3DDevice->SetTextureStageState(0, D3DTSS_MIPFILTER, D3DTEXF_POINT);

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

	// HGE_MODIFY (Texture clamping) {
	if (bTextureClamp)
	{
		pD3DDevice->SetTextureStageState(0,D3DTSS_ADDRESSU,D3DTADDRESS_CLAMP);
		pD3DDevice->SetTextureStageState(0,D3DTSS_ADDRESSV,D3DTADDRESS_CLAMP);
	}
	else
	{
		pD3DDevice->SetTextureStageState(0,D3DTSS_ADDRESSU,D3DTADDRESS_WRAP);
		pD3DDevice->SetTextureStageState(0,D3DTSS_ADDRESSV,D3DTADDRESS_WRAP);
	}
	// }

	// HGE_MODIFY (Single Pass Multitexturing) {
	pD3DDevice->SetTextureStageState(1, D3DTSS_TEXTURETRANSFORMFLAGS, D3DTTFF_COUNT2);

	pD3DDevice->SetTextureStageState(1,D3DTSS_ADDRESSU,D3DTADDRESS_CLAMP);
	pD3DDevice->SetTextureStageState(1,D3DTSS_ADDRESSV,D3DTADDRESS_CLAMP);
	pD3DDevice->SetTextureStageState(1,D3DTSS_BORDERCOLOR, 0x00000000);
	/*
	pD3DDevice->SetTextureStageState(1,D3DTSS_ADDRESSU,D3DTADDRESS_BORDER);
	pD3DDevice->SetTextureStageState(1,D3DTSS_ADDRESSV,D3DTADDRESS_BORDER);
	pD3DDevice->SetTextureStageState(1,D3DTSS_BORDERCOLOR, 0x00000000);
	*/
	// }

	nPrim=0;
	CurPrimType=HGEPRIM_QUADS;
	CurBlendMode = BLEND_DEFAULT;

	// HGE_MODIFY (Single Pass Multitexturing) {
	CurBlendMode = -1;
	// }

	CurTexture0 = NULL;
	CurTexture1 = NULL;

	pD3DDevice->SetTransform(D3DTS_VIEW, &matView);
	pD3DDevice->SetTransform(D3DTS_PROJECTION, &matProj);

	return true;
}