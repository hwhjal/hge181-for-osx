//
//  timer.mm
//  hgecore_osx
//
//  Created by Andrew Onofreytchuk on 5/3/10.
//  Copyright 2010 Andrew Onofreytchuk (a.onofreytchuk@gmail.com). All rights reserved.
//


#include "main.h"


float CALL HGE_Impl::Timer_GetTime()
{
	return fTime;
}

float CALL HGE_Impl::Timer_GetDelta()
{
	return fDeltaTime;
}


int CALL HGE_Impl::Timer_GetFPS()
{
	return nFPS;
}

