////////////////////////////////////////////////////////////////////////////////
// Filename: d3dclass.h
// Wrapper for a number of core Direct3D 9 functionalities.
// This code is adapted from the tutorials on rastertek.com (unknown author).
//  - Damien Loterie (01/2014)
////////////////////////////////////////////////////////////////////////////////
#ifndef _D3DCLASS_H_
#define _D3DCLASS_H_


/////////////
// LINKING //
/////////////
#pragma comment(lib, "dxgi.lib")
#pragma comment(lib, "d3d11.lib")
#pragma comment(lib, "d3dx11.lib")
#pragma comment(lib, "d3dx10.lib")
#pragma comment(lib, "dwmapi.lib")

//////////////
// INCLUDES //
//////////////
#include <dxgi.h>
#include <d3dcommon.h>
#include <d3d11.h>
#include <d3dx10math.h>
#include <dwmapi.h>
#include "parameterclass.h"



////////////////////////////////////////////////////////////////////////////////
// Class name: D3DClass
////////////////////////////////////////////////////////////////////////////////
class D3DClass
{
public:
	D3DClass();
	D3DClass(const D3DClass&);
	~D3DClass();

	bool Initialize(ParameterClass* params, bool, HWND, bool, float, float);
	void Shutdown();
	
	void BeginScene(float, float, float, float);
	void EndScene();

	ID3D11Device* GetDevice();
	ID3D11DeviceContext* GetDeviceContext();

	void GetViewMatrix(D3DXMATRIX&);
	void GetOrthoMatrix(D3DXMATRIX&);

	void GetVideoCardInfo(char*, int&);

	LARGE_INTEGER GetPresentTime();
	LARGE_INTEGER GetEndSceneTime();
	LARGE_INTEGER GetProcessingTime();

private:
	bool m_vsync_enabled;
	IDXGISwapChain* m_swapChain;
	ID3D11Device* m_device;
	ID3D11DeviceContext* m_deviceContext;
	ID3D11RenderTargetView* m_renderTargetView;
	ID3D11Texture2D* m_depthStencilBuffer;
	ID3D11DepthStencilState* m_depthStencilState;
	ID3D11DepthStencilView* m_depthStencilView;
	ID3D11RasterizerState* m_rasterState;
	D3DXMATRIX m_viewMatrix;
	D3DXMATRIX m_orthoMatrix;
	LARGE_INTEGER m_presentTime;
	LARGE_INTEGER m_endSceneTime;
	LARGE_INTEGER m_processingTime;
};

#endif