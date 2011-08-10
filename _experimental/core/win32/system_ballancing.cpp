//------------------------------------------------------------------------------
#include "system_ballancing.h"
//------------------------------------------------------------------------------
const int DELTA_HISTORY_LENGHT = 30;
#define EXPONENTIAL_FILTERING_DELTA

#define NORMAL_COEFF            0.05f
#define EASY_DROP_DOWN_COEFF    0.001f
#define HIGH_RISING_COEFF       0.4f
//------------------------------------------------------------------------------
HGE_SystemBallancer::HGE_SystemBallancer() :
    m_lastMiddle(0.0f)
{
}

//------------------------------------------------------------------------------
HGE_SystemBallancer::~HGE_SystemBallancer()
{
}

//------------------------------------------------------------------------------
int HGE_SystemBallancer::Ballance(DWORD timeDelta, DWORD minDelay)
{
#ifdef EXPONENTIAL_FILTERING_DELTA

    float deltaAdaptiveCoeff = NORMAL_COEFF;

    if (timeDelta > m_lastMiddle * 1.1f && m_lastMiddle > 15.f)
    {
        deltaAdaptiveCoeff = HIGH_RISING_COEFF;
    }
    else if (timeDelta < m_lastMiddle && timeDelta > 0.75f * m_lastMiddle)
    {
        deltaAdaptiveCoeff = EASY_DROP_DOWN_COEFF;
    }

    float dAdapt = deltaAdaptiveCoeff * (timeDelta - m_lastMiddle);
    m_lastMiddle = m_lastMiddle + dAdapt;

    int nAdaptiveDelta = 0;

    if (m_lastMiddle != 0.0f)
    {
        nAdaptiveDelta = static_cast<int>(m_lastMiddle);
        if (nAdaptiveDelta)
        {
            nAdaptiveDelta = static_cast<int>(nAdaptiveDelta / (1.0f - ((1000 % nAdaptiveDelta) / 1000.0f)));
        }
    }

    return nAdaptiveDelta <= (int)minDelay ? 0 : nAdaptiveDelta - minDelay;

#else
    int pointsCount = m_timeDeltaHistory.size();
    
    m_timeDeltaHistory.push_back(timeDelta);
    if (pointsCount == DELTA_HISTORY_LENGHT)
    {
        m_lastMiddle = ((m_lastMiddle * pointsCount) - m_timeDeltaHistory.front()) / (pointsCount - 1);
        m_timeDeltaHistory.pop_front();
    }

    m_lastMiddle = ((m_lastMiddle * pointsCount) + timeDelta) / (pointsCount + 1);

    if (m_lastMiddle < 0.001)
    {
        m_lastMiddle = timeDelta; // precision problemos
    }

    int nAdaptiveDelta = 0;

    if (m_lastMiddle != 0.0f)
    {
        if (timeDelta > m_lastMiddle * 1.1f && m_lastMiddle > 15.f)
        {
             // raise limit for smoothing (compensating) leaps on fps < 65
            //m_lastMiddle += (timeDelta - m_lastMiddle) * 0.02f;
        }

        nAdaptiveDelta = static_cast<int>(m_lastMiddle);
        if (nAdaptiveDelta)
        {
            nAdaptiveDelta = static_cast<int>(nAdaptiveDelta / (1.0f - ((1000 % nAdaptiveDelta) / 1000.0f)));
        }
    }

    return nAdaptiveDelta <= (int)minDelay ? 0 : nAdaptiveDelta - minDelay;
#endif EXPONENTIAL_FILTERING_DELTA
}
//------------------------------------------------------------------------------