////////////////////////////////////////////////////////////////////////////////
// Filename: graphicsclass.h
// Wrapper for Direct3D 9 graphics functionalities.
// This code is adapted from the tutorials on rastertek.com (unknown author).
//  - Damien Loterie (01/2014)
////////////////////////////////////////////////////////////////////////////////
#ifndef _GRAPHICSCLASS_H_
#define _GRAPHICSCLASS_H_


///////////////////////
// MY CLASS INCLUDES //
///////////////////////
#include "d3dclass.h"
#include "textureshaderclass.h"
#include "bitmapclass.h"
#include "parameterclass.h"


/////////////
// GLOBALS //
/////////////
//const bool FULL_SCREEN = true;
const bool VSYNC_ENABLED = true;
const float SCREEN_DEPTH = 1000.0f;
const float SCREEN_NEAR = 0.1f;


////////////////////////////////////////////////////////////////////////////////
// Class name: GraphicsClass
////////////////////////////////////////////////////////////////////////////////
class GraphicsClass
{
public:
	GraphicsClass();
	GraphicsClass(const GraphicsClass&);
	~GraphicsClass();

	bool Initialize(ParameterClass* params, HWND);
	void Shutdown();
	bool Render();
	D3DClass* GetD3D();
	TextureClass* GetTexture();

private:
	D3DClass*			m_D3D;
	TextureShaderClass* m_TextureShader;
	BitmapClass*		m_Bitmap;
};

#endif