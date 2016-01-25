////////////////////////////////////////////////////////////////////////////////
// Filename: gigesource.h
// Class that will connect to the camera, listen for incoming frames, and store
// them in memory. This happens in a dedicated high-priority thread, to avoid
// frame drops. There is a basic error reporting mechanism.
//  - Damien Loterie (11/2014)
////////////////////////////////////////////////////////////////////////////////
#ifndef _GIGESOURCE_H_
#define _GIGESOURCE_H_

//////////////
// INCLUDES //
//////////////
#include <windows.h>
#include <PvString.h>
#include <PvSystem.h>
#include <PvDevice.h>
#include <PvStream.h>
#include <PvPipeline.h>
#include <PvSampleUtils.h>
#include <PvStreamGEV.h>
#include "spsc_queue.h"
#include "iimagequeue.h"

/////////////
// GLOBALS //
/////////////
#define PVSTREAM_NUM_BUFFERS 256
#define PVPIPELINE_NUM_BUFFERS 512

///////////
// MACRO //
///////////
#define PvCheck(functionCall, ...) \
		result = functionCall; \
		if (!result.IsOK()) { \
			##__VA_ARGS__ \
			return result; \
		}


////////////////////////////////////////////////////////////////////////////////
// Class name: GigE_Source
////////////////////////////////////////////////////////////////////////////////
class GigE_Source : IImageQueue
{
public:
	GigE_Source();
	~GigE_Source();

	PvResult Initialize(const PvString);
	void	 Shutdown();

	PvResult Start();
	PvResult Stop();

	PvResult FlushImages();
	std::unique_ptr<PvBuffer> GetImage();
	std::unique_ptr<PvResult> GetError();
	size_t GetNumberOfAvailableImages();
	size_t GetNumberOfErrors();
	DWORD WaitImages(size_t, DWORD);

	PvGenParameterArray *lDeviceParams = NULL;


	/// -------------------------- JWJS -------------------------------------------------
	PvSystem * lPvSystem = NULL;

	const PvDeviceInfo * SelectDevice(PvSystem * aPvSystem);
	PvDevice  * ConnectToDevice(const PvDeviceInfo * aDeviceInfo);
	PvStream  * OpenStream(const PvDeviceInfo * aDeviceInfo);
	void		ConfigureStream(void);

	PvString	GetDeviceIP(void)			{ return lDeviceInfo->GetConnectionID().GetAscii(); }
	PvString	GetDeviceModelName(void)	{ return lDeviceInfo->GetModelName().GetAscii(); }
	PvString	GetDeviceSerialNumber(void) { return lDeviceInfo->GetSerialNumber().GetAscii(); }
	PvString	GetDeviceMACAddress(void)	{ return lDeviceInfo->GetUniqueID().GetAscii(); }

	void		AssignPvDeviceInfo(const PvDeviceInfo * aDeviceInfo) { lDeviceInfo = aDeviceInfo; }
	/// ---------------------------------

private:
	PvDevice	* lDevice = NULL;
	PvStream	* lStream = NULL;


	/// --------------------------- JWJS -------------------------------------------------
	/// Holds all the information about the device we connect to.
	const PvDeviceInfo *lDeviceInfo = NULL;
	/// ---------------------------------

	SPSC_Queue<PvBuffer> queue;
	int64_t bufferSize;

	HANDLE ManagerThread;
	HANDLE ManagerSignal;
	bool volatile ManagerStopFlag = false;
	bool volatile ManagerFlushFlag = false;
	DWORD ManageBuffers();
	static DWORD WINAPI GigE_Source::ManagerStaticStart(LPVOID);

	SPSC_Queue<PvResult> ManagerErrors;
	PvResult GetQueuedError();

	LARGE_INTEGER ManagerT1;
	LARGE_INTEGER ManagerT2;

};
#endif
