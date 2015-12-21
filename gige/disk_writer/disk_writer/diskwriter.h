////////////////////////////////////////////////////////////////////////////////
// Filename: diskwriter.h
////////////////////////////////////////////////////////////////////////////////
#ifndef _DISKWRITER_H_
#define _DISKWRITER_H_

//////////////
// INCLUDES //
//////////////
#include <windows.h>
#include <string>
#include <PvBuffer.h>
#include "spsc_queue.h"
#include "iimagequeue.h"

////////////////////////////////////////////////////////////////////////////////
// Class name: DiskWriter
////////////////////////////////////////////////////////////////////////////////
class DiskWriter : public IImageQueue
{
public:
	DiskWriter();
	~DiskWriter();

	bool	Initialize(LPCTSTR, IImageQueue*, bool);
	void	Shutdown();

	bool							FlushImages();
	std::unique_ptr<PvBuffer>		GetImage();
	std::unique_ptr<std::string>	GetError();
	size_t							GetNumberOfAvailableImages();
	size_t							GetNumberOfWrittenImages();
	size_t							GetNumberOfErrors();
	DWORD							WaitImages(size_t, DWORD);


private:
	IImageQueue				*pSource;
	SPSC_Queue<PvBuffer>	queue;
	bool					pass_through;

	HANDLE					WriterThread;
	HANDLE					WriterFile;
	bool volatile			WriterStopFlag = false;
	size_t					NumberOfWrittenImages;
	bool					WriteBuffer(std::unique_ptr<PvBuffer>&);
	DWORD					WriteBuffersContinuously();
	static DWORD WINAPI		DiskWriter::WriterStaticStart(LPVOID);

	

	SPSC_Queue<std::string>	WriterErrors;
	void					PushError(std::string);
	std::string				GetQueuedError();
};
#endif
