//
//  sound.mm
//  hgecore_osx
//
//  Created by Andrew Onofreytchuk on 5/3/10.
//  Copyright 2010 Andrew Onofreytchuk (a.onofreytchuk@gmail.com). All rights reserved.
//

#include "main.h"

HEFFECT CALL HGE_Impl::Effect_Load(const char *filename, DWORD size)
{
	DWORD length, samples,_size;
	HSAMPLE hs,buffer;
	HSTREAM hstrm;
	BASS_CHANNELINFO info;
	void  *data;
	//int 
	if(hBass)
	{
		if(bSilent) return 1;
		
		if(size) { data=(void *)filename; _size=size; }
		else
		{
			data=Resource_Load(filename, &_size);
			if(!data) return NULL;
		}
		
		hs=BASS_SampleLoad(true, data, 0, _size, 2, BASS_SAMPLE_OVER_VOL);
		if(!hs) {
			hstrm=BASS_StreamCreateFile(true, data, 0, _size, BASS_STREAM_DECODE);
			if(hstrm) {
				length=(DWORD)BASS_ChannelGetLength(hstrm, BASS_POS_BYTE );
				BASS_ChannelGetInfo(hstrm, &info);
				samples=length;
				if(info.chans < 2) samples>>=1;
				if((info.flags & BASS_SAMPLE_8BITS) == 0) samples>>=1;
				buffer=BASS_SampleCreate(samples, info.freq, 2, 4, info.flags | BASS_SAMPLE_OVER_VOL);
				if(!buffer)
				{
					
					_PostError("Can't create sound effect: Not enough memory");
				}
				else
				{
					//BASS_ChannelGetData(hstrm, buffer, length);
					hs=buffer;
					//	hs=BASS_SampleCreateDone();
					
					if(!hs)	_PostError("Can't create sound effect");
				}
				BASS_StreamFree(hstrm);
			}
		}
		
		if(!size) Resource_Free(data);
		return hs;
	}
	else return 0;
}

HCHANNEL CALL HGE_Impl::Effect_Play(HEFFECT eff)
{
	if(hBass)
	{
		HCHANNEL chn;
		chn=BASS_SampleGetChannel(eff, false);
		BASS_ChannelPlay(chn, true);
		return chn;
	}
	else return 0;
}

HCHANNEL CALL HGE_Impl::Effect_PlayEx(HEFFECT eff, int volume, int pan, float pitch, bool loop)
{
	if(hBass)
	{
		BASS_SAMPLE info;
		HCHANNEL chn;
		BASS_SampleGetInfo(eff, &info);
		
		chn=BASS_SampleGetChannel(eff, false);
		BASS_ChannelSetAttribute ( chn, BASS_ATTRIB_FREQ,(int)(pitch*info.freq) );
		BASS_ChannelSetAttribute ( chn, BASS_ATTRIB_VOL,volume );
		BASS_ChannelSetAttribute ( chn, BASS_ATTRIB_PAN,pan );
		
		info.flags &= ~BASS_SAMPLE_LOOP;
		if(loop) info.flags |= BASS_SAMPLE_LOOP;
		BASS_ChannelFlags ( chn, info.flags, info.flags );
		BASS_ChannelPlay(chn, true);
		return chn;
	}
	else return 0;
}


void CALL HGE_Impl::Effect_Free(HEFFECT eff)
{
	if(hBass) BASS_SampleFree(eff);
}


HMUSIC CALL HGE_Impl::Music_Load(const char *filename, DWORD size)
{
	void *data;
	DWORD _size;
	HMUSIC hm;
	
	if(hBass)
	{
		if(size)
		{
			data=(void *)filename;
			_size=size;
		}
		else
		{
			data=Resource_Load(filename, &_size);
			if(!data) return 0;
		}
		
		hm=BASS_MusicLoad(true, data, 0, 0, BASS_MUSIC_PRESCAN | BASS_MUSIC_POSRESETEX | BASS_MUSIC_RAMP, 0);
		if(!hm)	_PostError("Can't load music");
		if(!size) Resource_Free(data);
		return hm;
	}
	else return 0;
}

HCHANNEL CALL HGE_Impl::Music_Play(HMUSIC mus, bool loop, int volume, int order, int row)
{
	if(hBass)
	{
		DWORD pos = BASS_ChannelGetPosition(mus, BASS_POS_MUSIC_ORDER);
		
		if(order == -1) order = LOWORD(pos);
		if(row == -1) row = HIWORD(pos);
		BASS_ChannelSetPosition( mus, MAKELONG(order, row), BASS_POS_MUSIC_ORDER );
		
		
		BASS_CHANNELINFO info;
		BASS_ChannelGetInfo(mus, &info);
		BASS_ChannelSetAttribute ( mus, BASS_ATTRIB_FREQ,info.freq );
		BASS_ChannelSetAttribute ( mus, BASS_ATTRIB_VOL,volume );
		
		info.flags &= ~BASS_SAMPLE_LOOP;
		if(loop) info.flags |= BASS_SAMPLE_LOOP;
		BASS_ChannelFlags( mus, info.flags, info.flags );
		
		BASS_ChannelPlay(mus, false);
		
		return mus;
	}
	else return 0;
}

void CALL HGE_Impl::Music_Free(HMUSIC mus)
{
	if(hBass) BASS_MusicFree(mus);
}

void CALL HGE_Impl::Music_SetAmplification(HMUSIC music, int ampl)
{
	if(hBass) BASS_ChannelSetAttribute( music, BASS_ATTRIB_MUSIC_AMPLIFY, ampl );
}

int CALL HGE_Impl::Music_GetAmplification(HMUSIC music)
{
	if(hBass) 
	{
		float retVal = 0.0f;
		BASS_ChannelGetAttribute( music, BASS_ATTRIB_MUSIC_AMPLIFY, &retVal );
		return retVal;
	}
	else return -1;
}

int CALL HGE_Impl::Music_GetLength(HMUSIC music)
{
	if(hBass)
	{
		return BASS_ChannelGetLength(music, BASS_POS_MUSIC_ORDER);
	}
	else return -1;
}

void CALL HGE_Impl::Music_SetPos(HMUSIC music, int order, int row)
{
	if(hBass)
	{
		BASS_ChannelSetPosition(music, MAKELONG(order, row), BASS_POS_MUSIC_ORDER);
	}
}

bool CALL HGE_Impl::Music_GetPos(HMUSIC music, int *order, int *row)
{
	if(hBass)
	{
		DWORD pos;
		pos = BASS_ChannelGetPosition(music, BASS_POS_MUSIC_ORDER);
		if(pos == -1) return false;
		*order = LOWORD(pos);
		*row = HIWORD(pos);
		return true;
	}
	else return false;
}

void CALL HGE_Impl::Music_SetInstrVolume(HMUSIC music, int instr, int volume)
{
	if(hBass)
	{
		BASS_ChannelSetAttribute(music, BASS_ATTRIB_MUSIC_VOL_INST + instr, volume);	
	}
}

int CALL HGE_Impl::Music_GetInstrVolume(HMUSIC music, int instr)
{
	if(hBass)
	{
		float retVal = 0.0f;
		BASS_ChannelGetAttribute(music, BASS_ATTRIB_MUSIC_VOL_INST + instr, &retVal);
		return retVal;	
	}
	else return -1;
}

void CALL HGE_Impl::Music_SetChannelVolume(HMUSIC music, int channel, int volume)
{
	if(hBass)
	{
		BASS_ChannelSetAttribute(music, BASS_ATTRIB_MUSIC_VOL_CHAN + channel, volume);
	}
}

int CALL HGE_Impl::Music_GetChannelVolume(HMUSIC music, int channel)
{
	if(hBass)
	{
		float retVal = 0.0f;
		BASS_ChannelGetAttribute(music, BASS_ATTRIB_MUSIC_VOL_CHAN + channel, &retVal);
		return retVal;
	}
	else return -1;
}

HSTREAM CALL HGE_Impl::Stream_Load(const char *filename, DWORD size)
{
	void *data;
	DWORD _size;
	HSTREAM hs;
	CStreamList *stmItem;
	
	if(hBass)
	{
		if(bSilent) return 1;
		
		if(size) { data=(void *)filename; _size=size; }
		else
		{
			data=Resource_Load(filename, &_size);
			if(!data) return 0;
		}
		hs=BASS_StreamCreateFile(true, data, 0, _size, 0);
		if(!hs)
		{
			_PostError("Can't load stream");
			if(!size) Resource_Free(data);
			return 0;
		}
		if(!size)
		{
			stmItem=new CStreamList;
			stmItem->hstream=hs;
			stmItem->data=data;
			stmItem->next=streams;
			streams=stmItem;
		}
		return hs;
	}
	else return 0;
}

void CALL HGE_Impl::Stream_Free(HSTREAM stream)
{
	CStreamList *stmItem=streams, *stmPrev=0;
	
	if(hBass)
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
	}
}

HCHANNEL CALL HGE_Impl::Stream_Play(HSTREAM stream, bool loop, int volume)
{
	if(hBass)
	{
		BASS_CHANNELINFO info;
		BASS_ChannelGetInfo(stream, &info);
		
		BASS_ChannelSetAttribute ( stream, BASS_ATTRIB_FREQ,info.freq );
		BASS_ChannelSetAttribute ( stream, BASS_ATTRIB_VOL, volume );
		BASS_ChannelSetAttribute ( stream, BASS_ATTRIB_PAN, 0 );
		
		info.flags &= ~BASS_SAMPLE_LOOP;
		if(loop) info.flags |= BASS_SAMPLE_LOOP;
		BASS_ChannelFlags(stream, info.flags, info.flags);
		BASS_ChannelPlay(stream, true);
		return stream;
	}
	else return 0;
}

void CALL HGE_Impl::Channel_SetPanning(HCHANNEL chn, int pan)
{
	if(hBass) BASS_ChannelSetAttribute(chn, BASS_ATTRIB_PAN, pan);
}

void CALL HGE_Impl::Channel_SetVolume(HCHANNEL chn, int volume)
{
	if(hBass) BASS_ChannelSetAttribute(chn, BASS_ATTRIB_VOL, volume);
}

void CALL HGE_Impl::Channel_SetPitch(HCHANNEL chn, float pitch)
{
	if(hBass)
	{
		BASS_CHANNELINFO info;
		BASS_ChannelGetInfo(chn, &info);
		BASS_ChannelSetAttribute(chn, BASS_ATTRIB_FREQ, (int)(pitch*info.freq));
	}
}

void CALL HGE_Impl::Channel_Pause(HCHANNEL chn)
{
	if(hBass) BASS_ChannelPause(chn);
}

void CALL HGE_Impl::Channel_Resume(HCHANNEL chn)
{
	if(hBass) BASS_ChannelPlay(chn, false);
}

void CALL HGE_Impl::Channel_Stop(HCHANNEL chn)
{
	if(hBass) BASS_ChannelStop(chn);
}

void CALL HGE_Impl::Channel_PauseAll()
{
	if(hBass) BASS_Pause();
}

void CALL HGE_Impl::Channel_ResumeAll()
{
	if(hBass) BASS_Start();
}

void CALL HGE_Impl::Channel_StopAll()
{
	if(hBass)
	{
		BASS_Stop();
		BASS_Start();
	}
}

bool CALL HGE_Impl::Channel_IsPlaying(HCHANNEL chn)
{
	if(hBass)
	{
		if(BASS_ChannelIsActive(chn)==BASS_ACTIVE_PLAYING) return true;
		else return false;
	}
	else return false;
}

float CALL HGE_Impl::Channel_GetLength(HCHANNEL chn) {
	if(hBass)
	{
		return BASS_ChannelBytes2Seconds(chn, BASS_ChannelGetLength(chn, BASS_POS_BYTE));
	}
	else return -1;
}

float CALL HGE_Impl::Channel_GetPos(HCHANNEL chn) {
	if(hBass)
	{
		return BASS_ChannelBytes2Seconds(chn, BASS_ChannelGetPosition(chn, BASS_POS_BYTE));
	}
	else return -1;
}

void CALL HGE_Impl::Channel_SetPos(HCHANNEL chn, float fSeconds) {
	if(hBass)
	{
		BASS_ChannelSetPosition(chn, BASS_ChannelSeconds2Bytes(chn, fSeconds),BASS_POS_BYTE);
	}
}

void CALL HGE_Impl::Channel_SlideTo(HCHANNEL channel, float time, int volume, int pan, float pitch)
{
	if(hBass)
	{
		BASS_CHANNELINFO info;
		BASS_ChannelGetInfo(channel, &info);
		
		int freq;
		if(pitch == -1) freq = -1;
		else freq = (int)(pitch*info.freq);
		
		//BASS_ChannelSlideAttribute (channel, freq, volume, pan, DWORD(time*1000));
		BASS_ChannelSlideAttribute(channel, BASS_ATTRIB_FREQ, freq, DWORD(time*1000));
		BASS_ChannelSlideAttribute(channel, BASS_ATTRIB_VOL, volume, DWORD(time*1000));
		BASS_ChannelSlideAttribute(channel, BASS_ATTRIB_PAN, pan, DWORD(time*1000));
	}
}

bool CALL HGE_Impl::Channel_IsSliding(HCHANNEL channel)
{
	if(hBass)
	{
		if(BASS_ChannelIsSliding(channel, BASS_ATTRIB_FREQ) || BASS_ChannelIsSliding(channel, BASS_ATTRIB_VOL) || BASS_ChannelIsSliding(channel, BASS_ATTRIB_PAN)) 
			return true;
		else return false;
	}
	else return false;
}


//////// Implementation ////////


bool HGE_Impl::_SoundInit()
{
	if(!bUseSound || hBass) return true;
	
	if (HIWORD(BASS_GetVersion()) != BASSVERSION)
	{
		_PostError("Incorrect BASS version");
		return false;
	}
	
	
	bSilent=false;
	if (!BASS_Init(-1,nSampleRate,0,hwnd,NULL))
	{
		System_Log("BASS Init failed, using no sound");
		BASS_Init(-1,nSampleRate,0,hwnd,NULL);
		bSilent=true;
		bSoundInit=false;
		return false;
	}
	else
	{
		System_Log("BASS Init success");
		System_Log("Sample rate: %ld\n", nSampleRate);
		bSoundInit=true;
	}
	
	//BASS_SetConfig(BASS_CONFIG_BUFFER, 5000);
	//BASS_SetConfig(BASS_CONFIG_UPDATEPERIOD, 50);
	
	_SetFXVolume(nFXVolume);
	_SetMusVolume(nMusVolume);
	_SetStreamVolume(nStreamVolume);
	
	hBass = true;
	
	return true;
}

void HGE_Impl::_SoundDone()
{
	CStreamList *stmItem=streams, *stmNext;
	
	if(hBass)
	{
		BASS_Stop();
		BASS_Free();
		
		//int err = BASS_ErrorGetCode(); 
		
		// dlclose(hBass);
		hBass=false;
		
		while(stmItem)
		{
			stmNext=stmItem->next;
			Resource_Free(stmItem->data);
			delete stmItem;
			stmItem=stmNext;
		}
		streams=0;
	}
}

void HGE_Impl::_SetMusVolume(int vol)
{
	if(hBass) BASS_SetConfig(BASS_CONFIG_GVOL_MUSIC, vol);
}

void HGE_Impl::_SetStreamVolume(int vol)
{
	if(hBass) BASS_SetConfig(BASS_CONFIG_GVOL_STREAM, vol);
}

void HGE_Impl::_SetFXVolume(int vol)
{
	if(hBass) BASS_SetConfig(BASS_CONFIG_GVOL_SAMPLE, vol);
}






