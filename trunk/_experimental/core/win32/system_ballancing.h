//------------------------------------------------------------------------------
// ERS HGE addition
//------------------------------------------------------------------------------
#ifndef SYSTEM_BALLANCING_H
#define SYSTEM_BALLANCING_H
//------------------------------------------------------------------------------
#include "..\..\include\hge.h"
#include <deque>
//------------------------------------------------------------------------------

class HGE_SystemBallancer
{
public:
    HGE_SystemBallancer();
    ~HGE_SystemBallancer();

    int Ballance(DWORD timeDelta, DWORD minDelay);

private:
    std::deque<DWORD>   m_timeDeltaHistory;
    float               m_lastMiddle;
};


//------------------------------------------------------------------------------
#endif //SYSTEM_BALLANCING_H
//------------------------------------------------------------------------------