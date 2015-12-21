////////////////////////////////////////////////////////////////////////////////
// Filename: spsc_queue.h
// Implementation of a lock-free single producer single consumer queue for
// generic objects. This class allows transferring ownership of a sequence of
// objects (e.g. images) from one thread to another in a safe manner.
//   - Damien Loterie (11/2014)
////////////////////////////////////////////////////////////////////////////////
#ifndef _SPSC_QUEUE_H_
#define _SPSC_QUEUE_H_

//////////////
// INCLUDES //
//////////////
#include <memory>
#include <vector>
#include <windows.h>

/////////////
// GLOBALS //
/////////////
#define SPSC_QUEUE_SIZE_POW   17
#define SPSC_QUEUE_SIZE       (1<<SPSC_QUEUE_SIZE_POW)
#define SPSC_QUEUE_SIZE_MASK  (SPSC_QUEUE_SIZE-1)
#define T_ptr   std::unique_ptr<T>


////////////////////////////////////////////////////////////////////////////////
// Class definition: SPSC_Queue
////////////////////////////////////////////////////////////////////////////////
template <class T>
class SPSC_Queue
{
private:
	T_ptr*   Queue;

	__declspec (align(64)) volatile size_t PushCount;
	__declspec (align(64)) volatile size_t PopCount;

	__declspec (align(64)) volatile size_t PushCondition;
	HANDLE  Signal;

public:
	SPSC_Queue();
	~SPSC_Queue();

	void  TryPush(T_ptr&);
	void  TryPop(T_ptr&);
	T_ptr TryPop();
	void  Clear();

	size_t GetCount();

	DWORD  SPSC_Queue<T>::Wait(size_t, DWORD);
};


////////////////////////////////////////////////////////////////////////////////
// Class implementation: SPSC_Queue
////////////////////////////////////////////////////////////////////////////////
template <class T>
SPSC_Queue<T>::SPSC_Queue()
{
	Queue = new T_ptr[SPSC_QUEUE_SIZE];

  	PushCount = 0;
	PopCount = 0;

	PushCondition = 0;
	Signal = CreateEvent(NULL, true, false, NULL);
}

template <class T>
SPSC_Queue<T>::~SPSC_Queue()
{
	delete[] Queue;

	if (Signal != NULL)
		CloseHandle(Signal);
}

template <class T>
void SPSC_Queue<T>::TryPush(T_ptr& obj)
{
	if ((PushCount - PopCount) < SPSC_QUEUE_SIZE)
	{
		// Queue element
		Queue[PushCount & SPSC_QUEUE_SIZE_MASK] = std::move(obj);

		// Increment counter
		MemoryBarrier();
		PushCount++;

		// Send signal if needed
		MemoryBarrier();
		if (PushCondition>0 && PushCount>=PushCondition)
			SetEvent(Signal);
	}
}

template <class T>
void SPSC_Queue<T>::TryPop(T_ptr& obj)
{
	if (PushCount > PopCount)
	{
		obj = std::move(Queue[PopCount & SPSC_QUEUE_SIZE_MASK]);

		MemoryBarrier();
		PopCount++;
	}
}

template <class T>
T_ptr SPSC_Queue<T>::TryPop()
{
	// Create an empty pointer
	T_ptr obj;

	// Attempt to fill it
	TryPop(obj);

	// Return
	return obj;
}

template <class T>
void SPSC_Queue<T>::Clear()
{
	// Pop all elements
	while (TryPop());
}




template <class T>
size_t SPSC_Queue<T>::GetCount()
{
	// Return
	return PushCount-PopCount;
}

template <class T>
DWORD SPSC_Queue<T>::Wait(size_t n, DWORD timeoutMilliseconds)
{
	// Check if the condition is already satisfied
	// (if it is, no need to do all the synchronization work)
	if (PushCount >= (PopCount + n))
		return WAIT_OBJECT_0;

	// Check if we actually intend to wait
	if (timeoutMilliseconds == 0)
		return WAIT_TIMEOUT;

	// Set the push count that we want to wait for
	PushCondition = PopCount + n;     

	// Reset the synchronization object
	MemoryBarrier();
	if (!ResetEvent(Signal))
	{
		// In case of failure:
		// Disable signalling again
		PushCondition = 0;

		// Return error
		return WAIT_FAILED;
	}

	// Check again if the condition is satisfied
	// (it could be that we missed a signal between the start
	//  of this routine and the ResetEvent call)
	MemoryBarrier();
	if (PushCount >= PushCondition) 
	{
		// Disable signalling again
		PushCondition = 0;

		// Return
		return WAIT_OBJECT_0;
	}

	// Wait for signal
	int result = WaitForSingleObject(Signal, timeoutMilliseconds);

	// Disable signalling again
	PushCondition = 0;

	// Return
	return result;

}



#endif
