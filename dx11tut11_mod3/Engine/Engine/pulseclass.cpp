////////////////////////////////////////////////////////////////////////////////
// Filename: pulseclass.cpp
// Object allowing synchronization signals to be generated using 
// an NI acquisition card.
//  - Damien Loterie (01/2014)
////////////////////////////////////////////////////////////////////////////////
#ifdef ENABLE_TRIGGERING
#include "pulseclass.h"
#include "errors.h"

#include <iostream>
using namespace std;


PulseClass::PulseClass()
{
	ZeroMemory(this,sizeof(PulseClass));
}


PulseClass::PulseClass(const PulseClass& other)
{
}


PulseClass::~PulseClass()
{
}


bool PulseClass::Initialize(ParameterClass*	params)
{
	int result;

	// Remember parameters
	pConfig = params;
	m_currentDelayTime    = pConfig->pulseDelayTime;
	m_currentHighTime     = pConfig->pulseHighTime;
	m_currentLowTime      = pConfig->pulseLowTime;
	m_currentNumber       = pConfig->pulseNumber;
	m_currentEnableState  = pConfig->pulseEnable;
	m_currentSyncState	  = pConfig->pulseSync;

	// Initialize task
	result = DAQmxCreateTask("", &m_task);
	if(result<0)
	{
		WriteError();
		return false;
	}

	// Create channel
	result = DAQmxCreateCOPulseChanTime(m_task, PULSE_DEVICE, PULSE_CHANNEL, DAQmx_Val_Seconds, DAQmx_Val_Low,
		                                m_currentDelayTime, m_currentLowTime, m_currentHighTime);
	if (result<0)
	{
		WriteError();
		return false;
	}

	// Configure initial delay repetition
	result = DAQmxSetCOEnableInitialDelayOnRetrigger(m_task, PULSE_CHANNEL, true);
	if (result<0)
	{
		WriteError();
		return false;
	}

	// Configure number of samples
	result = DAQmxCfgImplicitTiming(m_task, DAQmx_Val_FiniteSamps, m_currentNumber);
	if (result<0)
	{
		WriteError();
		return false;
	}

	// Configure synced triggering
	if (m_currentSyncState)
	{
		result = DAQmxCfgDigEdgeStartTrig(m_task, PULSE_TRIGGER, DAQmx_Val_Falling);
		if (result < 0)
		{
			WriteError();
			return false;
		}
	}

	// Create the pulse buffer
	result = QueueCreate();
	if (!result)
	{
		ReportError("Couldn't create the pulse buffer.");
		return false;
	}

	// Return
	return true;
}


void PulseClass::Shutdown()
{
	// Release task
	if(m_task != 0) {
		DAQmxStopTask(m_task);
		DAQmxClearTask(m_task);
	}

	// Forget pointers
	pConfig = 0;
	m_task = 0;

	return;
}


bool PulseClass::Process(bool newFrame)
{
	int		result;
	bool32  taskIsDone = 0;
	bool	pulseNow = false;

	// If pulses are not enabled, leave
	if (!pConfig->pulseEnable)
	{
		m_currentEnableState = pConfig->pulseEnable;
		return true;
	}

	// Add a pulse to the queue if this is a new frame
	if (newFrame)
		QueueAdd();

	// Find out if a pulse must be generated on this frame
	pulseNow = QueueNext();

	// Stop task if needed
	if (m_taskIsRunning)
	{
		// Check if task is done
		if (!pulseNow)
		{
			result = DAQmxIsTaskDone(m_task, &taskIsDone);
			if (result<0)
			{
				WriteError();
				return false;
			}
		}

		// Reset task if you have to pulse on this frame or if the task is done 
		if (pulseNow || taskIsDone) {
			// Stop task
			result = DAQmxStopTask(m_task);
			if (result<0)
			{
				WriteError();
				return false;
			}

			// Clear flag
			m_taskIsRunning = false;
		}
	}

	// Reconfigure if needed
	if (!m_taskIsRunning)
		CheckConfig();

	// Check if it's time to send a pulse
	if (pulseNow && !m_taskIsRunning) {

		// Send pulse
		result = DAQmxStartTask(m_task);
		if (result<0)
		{
			WriteError();
			return false;
		}

		// Flag
		m_taskIsRunning = true;
	}

	return true;
}

bool PulseClass::CheckConfig()
{
	int		result;

	// Check pulse high time
	if (pConfig->pulseHighTime != m_currentHighTime) {
		double newHighTime = pConfig->pulseHighTime;

		// Set new value
		result = DAQmxSetCOPulseHighTime(m_task, PULSE_CHANNEL, newHighTime);
		if (result<0)
		{
			WriteError();
			return false;
		}

		// Save new value
		m_currentHighTime = newHighTime;
	}

	// Check pulse low time
	if (pConfig->pulseLowTime != m_currentLowTime) {
		double newLowTime = pConfig->pulseLowTime;

		// Set new value
		result = DAQmxSetCOPulseLowTime(m_task, PULSE_CHANNEL, newLowTime);
		if (result<0)
		{
			WriteError();
			return false;
		}

		// Save new value
		m_currentLowTime = newLowTime;
	}

	// Check pulse delay
	if (pConfig->pulseDelayTime != m_currentDelayTime) {
		double newDelayTime = pConfig->pulseDelayTime;

		// Set new value
		result = DAQmxSetCOPulseTimeInitialDelay(m_task, PULSE_CHANNEL, newDelayTime);
		if (result<0)
		{
			WriteError();
			return false;
		}

		// Save new value
		m_currentDelayTime = newDelayTime;
	}


	// Check number of samples
	if (pConfig->pulseNumber != m_currentNumber) {
		int newNumber = pConfig->pulseNumber;

		// Set new value
		result = DAQmxCfgImplicitTiming(m_task, DAQmx_Val_FiniteSamps, newNumber);
		if (result<0)
		{
			WriteError();
			return false;
		}

		// Save new value
		m_currentNumber = newNumber;
	}

	// Check trigger synchronization
	if (pConfig->pulseSync != m_currentSyncState)
	{
		if (pConfig->pulseSync == true)
		{
			// Enable edge triggering
			result = DAQmxCfgDigEdgeStartTrig(m_task, PULSE_TRIGGER, DAQmx_Val_Falling);
			if (result < 0)
			{
				WriteError();
				return false;
			}

			// Save new state
			m_currentSyncState = true;
		}
		else
		{
			// Disable edge triggering
			result = DAQmxDisableStartTrig(m_task);
			if (result < 0)
			{
				WriteError();
				return false;
			}

			// Save new state
			m_currentSyncState = false;
		}
	}

	// Check pulse buffer
	if ( ((pConfig->pulseDelayFrames + 1) != m_queueSize)
		 || (!m_currentEnableState && pConfig->pulseEnable) )
	{
		result = QueueCreate();
		if (!result)
		{
			ReportError("Couldn't create the pulse buffer.");
			return false;
		}
	}

	// Set enable state
	m_currentEnableState = pConfig->pulseEnable;

	// Success
	return true;

}

void PulseClass::WriteError()
{
	// Create appropriate buffer
	int bufferSize = DAQmxGetExtendedErrorInfo(0,0);
	char* errorBuffer = (char*)malloc(bufferSize);

	// Get error
	DAQmxGetExtendedErrorInfo(errorBuffer,bufferSize);

	// Report error
	ReportError(errorBuffer);

	// Deallocate buffer space
	free(errorBuffer);
}


bool PulseClass::QueueCreate()
{
	// Deallocate previous queue
	if (m_queue)
	{
		delete m_queue;
		m_queue = 0;
	}

	// Allocate new queue
	int queueSize = pConfig->pulseDelayFrames + 1;
	m_queue = new bool[queueSize];
	m_queueIndex = 0;
	
	// Check result and set queueSize
	if (!m_queue)
	{
		m_queueSize = 0;
		return false;
	} else {
		m_queueSize = queueSize;
	}

	// Clear memory there
	ZeroMemory(m_queue, queueSize);

	// Success
	return true;
}

void PulseClass::QueueAdd()
{
	int newPulseIndex = (m_queueIndex + pConfig->pulseDelayFrames) % m_queueSize;
	m_queue[newPulseIndex] = true;
}

bool PulseClass::QueueNext()
{
	// Get the current value
	bool result = m_queue[m_queueIndex];

	// Reset this value
	m_queue[m_queueIndex] = false;

	// Move pointer for the next call
	m_queueIndex = (m_queueIndex + 1) % m_queueSize;

	// Return current value
	return result;
}


#endif