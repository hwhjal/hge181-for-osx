//
//  sound.mm
//  hgecore_osx
//
//  Created by Andrew Pepper on 6/12/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#include "main.h"

HEFFECT CALL HGE_Impl::Effect_Load(const char *filename, DWORD size)
{
	return 0;
}

void CALL HGE_Impl::Effect_Free(HEFFECT eff)
{
	// if(hBass) BASS_SampleFree(eff);
}



HMUSIC CALL HGE_Impl::Music_Load(const char *filename, DWORD size)
{
	return 0;
}

HSTREAM CALL HGE_Impl::Stream_Load(const char *filename, DWORD size)
{
	return 0;
}

void CALL HGE_Impl::Music_Free(HMUSIC mus)
{
	// if(hBass) BASS_MusicFree(mus);
}

void CALL HGE_Impl::Music_SetAmplification(HMUSIC music, int ampl)
{
	// if(hBass) BASS_MusicSetAttribute(music, BASS_MUSIC_ATTRIB_AMPLIFY, ampl);
}

void CALL HGE_Impl::Stream_Free(HSTREAM stream)
{
	// CStreamList *stmItem=streams, *stmPrev=0;
	
	/*if(hBass)
	{
		while(stmItem)
		{
			if(stmItem->hstream==stream)
			{
				if(stmPrev) stmPrev->next=stmItem->next;
				else streams=stmItem->next;
				Resource_Free(stmItem->data);
				delete stmItem;
				break;
			}
			stmPrev=stmItem;
			stmItem=stmItem->next;
		}
		BASS_StreamFree(stream);
	}*/
}
