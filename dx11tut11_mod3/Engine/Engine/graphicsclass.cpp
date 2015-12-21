////////////////////////////////////////////////////////////////////////////////
// Filename: graphicsclass.cpp
// Wrapper for Direct3D 9 graphics functionalities.
// This code is adapted from the tutorials on rastertek.com (unknown author).
//  - Damien Loterie (01/2014)
////////////////////////////////////////////////////////////////////////////////
#include "graphicsclass.h"
#include "errors.h"

GraphicsClass::GraphicsClass()
{
	m_D3D = 0;
	m_TextureShader = 0;
	m_Bitmap = 0;
}


GraphicsClass::GraphicsClass(const GraphicsClass& other)
{
}


GraphicsClass::~GraphicsClass()
{
}


bool GraphicsClass::Initialize(ParameterClass* params, HWND hwnd)
{
	bool result;


	// Create the Direct3D object.
	m_D3D = new D3DClass;
	if(!m_D3D)
	{
		return false;
	}

	// Initialize the Direct3D object.
	result = m_D3D->Initialize(params, VSYNC_ENABLED, hwnd, params->fullscreen, SCREEN_DEPTH, SCREEN_NEAR);
	if(!result)
	{
		ReportError("Could not initialize Direct3D.");
		return false;
	}

	// Create the texture shader object.
	m_TextureShader = new TextureShaderClass;
	if(!m_TextureShader)
	{
		return false;
	}

	// Initialize the texture shader object.
	result = m_TextureShader->Initialize(m_D3D->GetDevice(), hwnd);
	if(!result)
	{
		ReportError("Could not initialize the texture shader object.");
		return false;
	}

	// Create the bitmap object.
	m_Bitmap = new BitmapClass;
	if(!m_Bitmap)
	{
		return false;
	}

	// Initialize the bitmap object.
	result = m_Bitmap->Initialize(params, m_D3D->GetDevice(), m_D3D->GetDeviceContext());
	if(!result)
	{
		ReportError("Could not initialize the bitmap object.");
		return false;
	}

	return true;
}


void GraphicsClass::Shutdown()
{
	// Release the bitmap object.
	if(m_Bitmap)
	{
		m_Bitmap->Shutdown();
		delete m_Bitmap;
		m_Bitmap = 0;
	}

	// Release the texture shader object.
	if(m_TextureShader)
	{
		m_TextureShader->Shutdown();
		delete m_TextureShader;
		m_TextureShader = 0;
	}

	// Release the D3D object.
	if(m_D3D)
	{
		m_D3D->Shutdown();
		delete m_D3D;
		m_D3D = 0;
	}

	return;
}


bool GraphicsClass::Render()
{
	D3DXMATRIX viewMatrix, orthoMatrix;
	bool result;

	// Clear the buffers to begin the scene.
	//m_D3D->BeginScene(0.5f, 0.5f, 0.5f, 0.0f);
	m_D3D->BeginScene(0.0f, 0.0f, 0.0f, 0.0f);

	// Get the world and projection, and ortho matrices from the camera and d3d objects.
	m_D3D->GetViewMatrix(viewMatrix);
	m_D3D->GetOrthoMatrix(orthoMatrix);

	// Put the bitmap vertex and index buffers on the graphics pipeline to prepare them for drawing.
	result = m_Bitmap->Render(m_D3D->GetDeviceContext());
	if(!result)
	{
		return false;
	}

	// Render the bitmap with the texture shader.
	result = m_TextureShader->Render(m_D3D->GetDeviceContext(), m_Bitmap->GetIndexCount(), viewMatrix, orthoMatrix, m_Bitmap->GetTextureView());
	if(!result)
	{
		return false;
	}

	// Present the rendered scene to the screen.
	m_D3D->EndScene();

	return true;
}

D3DClass* GraphicsClass::GetD3D()
{
	return m_D3D;
}

TextureClass* GraphicsClass::GetTexture()
{
	return m_Bitmap->GetTexture();
}