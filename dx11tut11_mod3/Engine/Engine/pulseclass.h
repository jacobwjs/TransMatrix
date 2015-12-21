////////////////////////////////////////////////////////////////////////////////
// Filename: pulseclass.h
// Object allowing synchronization signals to be generated using 
// an NI acquisition card.
//  - Damien Loterie (01/2014)
////////////////////////////////////////////////////////////////////////////////
#ifdef ENABLE_TRIGGERING
#ifndef _PULSECLASS_H_
#define _PULSECLASS_H_


//////////////
// INCLUDES //
//////////////
#include <windows.h>
#include <NIDAQmx.h>
#pragma comment(lib, "NIDAQmx.lib")

///////////////////////
// MY CLASS INCLUDES //
///////////////////////
#include "parameterclass.h"


///////////////
// CONSTANTS //
///////////////
#define PULSE_CHANNEL "pulse0"
#define PULSE_DEVICE  "Dev1/ctr0"
#define PULSE_TRIGGER "/Dev1/PFI9"


////////////////////////////////////////////////////////////////////////////////
// Class name: PulseClass
////////////////////////////////////////////////////////////////////////////////
class PulseClass
{
public:
	PulseClass();
	PulseClass(const PulseClass&);
	~PulseClass();

	bool Initialize(ParameterClass*);
	void Shutdown();
	bool Process(bool);
	

private:
	void WriteError();
	
	ParameterClass* pConfig;
	bool CheckConfig();

	TaskHandle		m_task;

	double			m_currentDelayTime;
	double			m_currentHighTime;
	double			m_currentLowTime;
	int             m_currentNumber;
	bool			m_currentEnableState;
	bool			m_currentSyncState;
	bool			m_taskIsRunning;

	bool*			m_queue;
	int				m_queueSize;
	int				m_queueIndex;
	bool			QueueCreate();
	void			QueueAdd();
	bool			QueueNext();

};


#endif
#endif