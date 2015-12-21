// Basic error reporting mechanism
//  - Damien Loterie (01/2014)

#include "errors.h"


void ReportErrorStamp()
{
	int result;
	time_t rawtime;
	struct tm* timeinfo = new struct tm;
	char buffer[128];
	ZeroMemory(buffer,sizeof(buffer));

	time(&rawtime);
	result = localtime_s(timeinfo, &rawtime);
 
	if (result==0)
	{
		strftime(buffer, sizeof(buffer),"[%d/%m/%Y %H:%M:%S]\n", timeinfo);
		fprintf(stderr, buffer);
	} else
	{
		fprintf(stderr, "[TIMESTAMP UNAVAILABLE]\n");
	}

	delete timeinfo;
	return;
}