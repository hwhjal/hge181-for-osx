/*
** Haaf's Game Engine 1.7
** Copyright (C) 2003-2007, Relish Games
** hge.relishgames.com
**
** hgeSprite helper class header
*/


#ifndef HGESPRITE_H
#define HGESPRITE_H


#include "hge.h"
#include "hgerect.h"


/*
** HGE Sprite class
*/
class hgeSprite
{
public:
	hgeSprite(HTEXTURE tex, float x, float y, float w, float h);
	hgeSprite(const hgeSprite &spr);
	virtual ~hgeSprite() { hge->Release(); }
	
	
	void		Render(float x, float y);
	void		RenderWithOpacity(float x, float y, float opacity);
	void		RenderEx(float x, float y, float rot, float hscale=1.0f, float vscale=0.0f);
	void		RenderStretch(float x1, float y1, float x2, float y2);
	void		RenderStretchWithOpacity(float x1, float y1, float x2, float y2, float opacity);
	void		Render4V(float x0, float y0, float x1, float y1, float x2, float y2, float x3, float y3);

	void		SetTexture(HTEXTURE tex);
	void		SetTextureRect(float x, float y, float w, float h, bool adjSize = true);
	void		SetColor(DWORD col, int i=-1);
	void		SetZ(float z, int i=-1);
	void		SetBlendMode(int blend) { quad.blend=blend; }
	void		SetHotSpot(float x, float y) { hotX=x; hotY=y; }
	void		SetFlip(bool bX, bool bY, bool bHotSpot = false);

	// HGE_MODIFY (Single Pass Multitexturing) {
	void		SetMask(HTEXTURE texture, float x, float y, float w, float h);
	void		SetMaskHotSpot(float x, float y) { mask_hotX=x; mask_hotY=y; }
	void		SetMaskOffset(float dx, float dy);
	void		GetMaskOffset(float* dx, float* dy) const;
	void		SetMaskScale(float sx, float sy) {quad.x_mask_scale = sx; quad.y_mask_scale = sy;};
	void		GetMaskScale(float* sx, float* sy) const {*sx = quad.x_mask_scale; *sy = quad.y_mask_scale;};
	//void		SetMaskAngle(float angle) {quad.mask_angle = angle;};
	//float		GetMaskAngle() const {return quad.mask_angle;};
	// }

	HTEXTURE	GetTexture() const { return quad.tex; }
	void		GetTextureRect(float *x, float *y, float *w, float *h) const { *x=tx; *y=ty; *w=width; *h=height; }
    void        GetCurrentTextureRect(float &x1, float &y1, float &x2, float &y2) const
                    {x1 = quad.v[0].tx * tex_width;
                     y1 = quad.v[0].ty * tex_height;
                     x2 = width;
                     y2 = height;}

	DWORD		GetColor(int i=0) const { return quad.v[i].col; }
	float		GetZ(int i=0) const { return quad.v[i].z; }
	int			GetBlendMode() const { return quad.blend; }
	void		GetHotSpot(float *x, float *y) const { *x=hotX; *y=hotY; }
	void		GetFlip(bool *bX, bool *bY) const { *bX=bXFlip; *bY=bYFlip; }

	float		GetWidth() const { return width; }
	float		GetHeight() const { return height; }
	hgeRect*	GetBoundingBox(float x, float y, hgeRect *rect) const { rect->Set(x-hotX, y-hotY, x-hotX+width, y-hotY+height); return rect; }
	hgeRect*	GetBoundingBoxEx(float x, float y, float rot, float hscale, float vscale,  hgeRect *rect) const;
    bool        TestSpritePoint(float x, float y, int alphaThreshold = 1) const;

protected:
	hgeSprite();
	static HGE	*hge;

	hgeQuad		quad;
	float		tx, ty, width, height;
	float		tex_width, tex_height;
	float		hotX, hotY;
	bool		bXFlip, bYFlip, bHSFlip;

	// HGE_MODIFY (Single Pass Multitexturing) {
	float		mask_hotX, mask_hotY;
	float		mask_dx, mask_dy;
	float		mask_scale_x, mask_scale_y;
	// }
};


#endif
