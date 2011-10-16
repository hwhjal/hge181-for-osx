//
//  timer.mm
//  hgecore_osx
//
//  Created by Andrew Pepper on 5/23/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
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

