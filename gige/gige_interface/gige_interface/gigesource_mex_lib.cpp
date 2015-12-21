// MATLAB MEX interface class for GigE acquisition with the Pleora SDK
// Based on class_handle.hpp by Oliver Woodford
//  - Damien Loterie (11/2014)

#ifndef _GIGESOURCE_MEX_LIB_CPP_
#define _GIGESOURCE_MEX_LIB_CPP_

#include "mex.h"
#include "gigesource.cpp"

PvString GetPvString(PvResult res)
{
	PvString resStr;
	resStr = res.GetCodeString();
	resStr += PvString(" / ");
	resStr += res.GetDescription();
	return resStr;
}

PvString GetPvString(const mxArray* pArr)
{
	// Check type
	if (!mxIsChar(pArr))
		mexErrMsgTxt("Argument should be a string.");

	// Convert argument to a C string
	char* cStr = mxArrayToString(pArr);
	
	// Convert C string to PvString
	PvString PvStr = PvString(cStr);
	
	// Free C string
	mxFree(cStr);
	
	// Return
	return PvStr;
}

mxArray* GetMxArrayFromPvParValue(PvGenParameter *PvPar)
{
	// Prepare output
	mxArray* mxValue;

	// Type cases
	PvGenType PvParType;
	PvPar->GetType(PvParType);
	switch (PvParType)
	{
		case PvGenTypeInteger:
			mxValue = mxCreateNumericMatrix(1, 1, mxINT64_CLASS, mxREAL);
			((PvGenInteger*)PvPar)->GetValue(*(int64_t*)mxGetData(mxValue));
			break;
		case PvGenTypeEnum:
			mxValue = mxCreateString(PvPar->ToString());
			break;
		case PvGenTypeBoolean:
			mxValue = mxCreateNumericMatrix(1, 1, mxLOGICAL_CLASS, mxREAL);
			((PvGenBoolean*)PvPar)->GetValue(*(bool*)mxGetData(mxValue));
			break;
		case PvGenTypeString:
			mxValue = mxCreateString(PvPar->ToString());
			break;
		case PvGenTypeCommand:
			mxValue = mxCreateString("(command)");
			break;	
		case PvGenTypeFloat:
			mxValue = mxCreateNumericMatrix(1, 1, mxDOUBLE_CLASS, mxREAL);
			((PvGenFloat*)PvPar)->GetValue(*(double*)mxGetData(mxValue));
			break;
		case PvGenTypeUndefined:
			mxValue = mxCreateNumericMatrix(0, 0, mxDOUBLE_CLASS, mxREAL);
			break;
		default:
			break;
		
	}
	
	return mxValue;
}

mxArray* RecastMxArray(mxArray* mxVal, char* outputType)
{
	// Call MATLAB to convert the type
	int result;
	mxArray* plhs[1];
	mxArray* prhs[1] = {mxVal};
	
	result = mexCallMATLAB(1, plhs, 1, prhs, outputType);
	
	// Error
	if (result!=0)
	{
		mexErrMsgTxt("Could not convert the input to the right type.");
		return NULL;
	}
	
	// Success
	return plhs[0];
}

void SetPvParValueFromMxArray(PvGenParameter *PvPar, mxArray* mxValue)
{
	// Type cases
	PvGenType PvParType;
	PvResult  PvSetRes = PvResult::Code::GENERIC_ERROR;
	PvPar->GetType(PvParType);
	switch (PvParType)
	{
		case PvGenTypeFloat:
			if (mxGetNumberOfElements(mxValue)!=1)
				mexErrMsgTxt("The number of elements in the input should be 1.");
			mxValue = RecastMxArray(mxValue,"double");
			PvSetRes = ((PvGenFloat*)PvPar)->SetValue(*(double*)mxGetData(mxValue));
			break;
			
		case PvGenTypeInteger:
			if (mxGetNumberOfElements(mxValue)!=1)
				mexErrMsgTxt("The number of elements in the input should be 1.");
			mxValue = RecastMxArray(mxValue,"int64");
			PvSetRes = ((PvGenInteger*)PvPar)->SetValue(*(int64_t*)mxGetData(mxValue));
			break;
			
		case PvGenTypeBoolean:
			if (mxGetNumberOfElements(mxValue)!=1)
				mexErrMsgTxt("The number of elements in the input should be 1.");
			mxValue = RecastMxArray(mxValue,"logical");
			PvSetRes = ((PvGenBoolean*)PvPar)->SetValue(*(bool*)mxGetData(mxValue));
			break;
			
		case PvGenTypeString:
			PvSetRes = ((PvGenString*)PvPar)->SetValue(GetPvString(mxValue));
			break;
			
		case PvGenTypeEnum:
			PvSetRes = ((PvGenEnum*)PvPar)->SetValue(GetPvString(mxValue));
			break;
			
		case PvGenTypeCommand:
			if (mxGetNumberOfElements(mxValue)!=0)
				mexErrMsgTxt("This parameter is a command, and it does not take an argument.");
			PvSetRes = ((PvGenCommand*)PvPar)->Execute();
			break;	
			
		case PvGenTypeUndefined:
			mexErrMsgTxt("Cannot set this parameter.");
			break;
			
		default:
			break;
		
	}
	
	// Check result
	if (!PvSetRes.IsOK())
		mexErrMsgTxt(GetPvString(PvSetRes));
	
	// Return
	return;
}


mxArray* GetMxStruct(PvGenParameterArray *PvArr)
{
	// Get number of parameters
	uint32_t numFields = PvArr->GetCount();
	
	// Prepare an array of with the field names
	char **fieldNames = (char**)mxCalloc(numFields, sizeof(char*)); //char **fieldNames = new char*[numFields]; 
	for (uint32_t i=0; i<numFields; i++)
	{
		// Get parameter
		PvString PvName = PvArr->Get(i)->GetName();
		
		// Allocate space
		fieldNames[i] = (char*)mxCalloc(PvName.GetLength()+1, sizeof(char)); //fieldNames[i] = new char[PvName.GetLength()+1];
		
		// Copy string
		CopyMemory(fieldNames[i], (const char*)PvName, PvName.GetLength());
		fieldNames[i][PvName.GetLength()+1] = 0;
	}
	
	// Create struct
	mxArray* mxStruct = mxCreateStructMatrix(1, 1, numFields, (const char**)fieldNames);

	// Deallocate space for the field names
	for (uint32_t i=0; i<numFields; i++)
		mxFree(fieldNames[i]); //delete[] fieldNames[i];
	mxFree(fieldNames); //delete[] fieldNames;
	
	// Set field values
	for (uint32_t i=0; i<numFields; i++)
	{
		// Get parameter
		PvGenParameter *PvPar = PvArr->Get(i);
		
		// Load the parameter value
		mxSetFieldByNumber(mxStruct, 0, i, GetMxArrayFromPvParValue(PvPar));
	}
	
	return mxStruct;
}


template<typename T>
void transpose(T* pDataOut, const void* pDataIn, size_t WidthIn, size_t HeightIn)
{
	T* pDataInT  = (T*)pDataIn;

	for (size_t i = 0; i < HeightIn; i++)
	{
		for (size_t j = 0; j < WidthIn; j++)
		{
			pDataOut[j*(HeightIn)+i] = pDataInT[i*(WidthIn)+j];
		}
	}
}

template<typename T, typename TSource>
void transfer_many(T* pMat, uint64_t* pTime, TSource* GigE_instance, size_t Width, size_t Height, size_t Frames)
{
	// Transfer the other frames
	for (size_t i = 0; i < Frames; i++)
	{
		// Pop frame
		std::unique_ptr<PvBuffer> pBuffer = GigE_instance->GetImage();

		// Check validity of buffer
		if (!pBuffer)
			mexErrMsgTxt("transfer_many: One of the images could not be retrieved. Part of the images were dropped.");

		// Get image interface
		PvImage *lImage = pBuffer->GetImage();

		// Check specs
		if (lImage->GetWidth() != Width || lImage->GetHeight() != Height || lImage->GetBitsPerPixel() != sizeof(T)*8)
		{
			pBuffer.reset();
			mexErrMsgTxt("transfer_many: One of the images has inconsistent dimensions. Part of the images were dropped.");
			return;
		}

		// Transpose/copy
		transpose<T>(&pMat[i*Width*Height], lImage->GetDataPointer(), Width, Height);

		// Record timestamp
		pTime[i] = pBuffer->GetTimestamp();
	}
}

#endif