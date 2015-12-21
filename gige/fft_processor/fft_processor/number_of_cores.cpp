#include "number_of_cores.h"

int numberOfCores()
{
	SYSTEM_LOGICAL_PROCESSOR_INFORMATION *procInfo = NULL;
	DWORD  returnBytes = 0;
	size_t returnSize = 0;
	int    processorCoreCount = 0;

	// Get processor info length
	GetLogicalProcessorInformation(procInfo, &returnBytes);

	// Check size consistency
	if (returnBytes%sizeof(SYSTEM_LOGICAL_PROCESSOR_INFORMATION) != 0)
	{
		return 0;
	}
	else
	{
		returnSize = returnBytes / sizeof(SYSTEM_LOGICAL_PROCESSOR_INFORMATION);
	}

	// Allocate
	procInfo = (SYSTEM_LOGICAL_PROCESSOR_INFORMATION*)malloc(returnBytes);
	if (procInfo == NULL)
		return 0;

	// Get processor info data
	GetLogicalProcessorInformation(procInfo, &returnBytes);

	// Scan information
	for (size_t i = 0; i < returnSize; i++)
	{
		if (procInfo[i].Relationship == RelationProcessorCore)
		{
			processorCoreCount++;
		}
	}

	// Free resources
	free(procInfo);

	// Return
	return processorCoreCount;
}