////////////////////////////////////////////////////////////////////////////////
// Filename: communicationclass.h
// Object allowing interprocess communication with e.g. MATLAB.
//  - Damien Loterie (01/2014)
////////////////////////////////////////////////////////////////////////////////
#ifndef _COMMUNICATIONCLASS_H_
#define _COMMUNICATIONCLASS_H_


//////////////
// INCLUDES //
//////////////
#include <windows.h>
#include "textureclass.h"
#include "d3dclass.h"
#include "parameterclass.h"
#include "pulseclass.h"


////////////////////////////////////////////////////////////////////////////////
// Class name: CommunicationClass
////////////////////////////////////////////////////////////////////////////////
class CommunicationClass
{
public:
	CommunicationClass();
	CommunicationClass(const CommunicationClass&);
	~CommunicationClass();

	bool			Initialize(ParameterClass* params);
	void			Shutdown();
	bool			PreProcess(ID3D11DeviceContext*, TextureClass*);
	bool			PostProcess(D3DClass* d3dclass);
	ParameterClass* GetSharedParameters();
	
private:
	bool LoadFrame(ID3D11DeviceContext*, TextureClass*);
	bool SaveTime(D3DClass* d3dclass);
	int  GetZeroBasedIndexForNextFrame();

	HANDLE hDataFile;
	HANDLE hTimeFile;
	HANDLE hConfigFile;
	HANDLE hSignal;

	UCHAR*				pData;
	double*				pTime;
	ParameterClass*		pConfig;

	int			  dividerCounter;
	int			  numberOfFrames;
	int			  bytesPerFrame;

	bool		  previousRunState;
	bool		  keepRunTime;
	bool          frameUpdated;
	bool          lastFrame;

	LARGE_INTEGER presentTimeReference;
	LARGE_INTEGER presentTimeFrequency;

	#ifdef ENABLE_TRIGGERING
		PulseClass*   pPulse; 
	#endif

};
#endif

/////////////
// GLOBALS //
/////////////
#ifndef  COMM_CONFIG_FILE
#define	 COMM_CONFIG_FILE "DirectX_Fullscreen_ConfigFile"
#define	 COMM_DATA_FILE   "DirectX_Fullscreen_DataFile"
#define	 COMM_TIME_FILE   "DirectX_Fullscreen_TimeFile"
#define	 COMM_SIGNAL	  "DirectX_Fullscreen_Signal"
#define	 COMM_MUTEX		  "DirectX_Fullscreen_Mutex"
#endif