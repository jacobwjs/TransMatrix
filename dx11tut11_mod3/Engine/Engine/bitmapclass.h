////////////////////////////////////////////////////////////////////////////////
// Filename: bitmapclass.h
// Object representing a bitmap texture in Direct3D 9.
// This code is adapted from the tutorials on rastertek.com (unknown author).
//  - Damien Loterie (01/2014)
////////////////////////////////////////////////////////////////////////////////
#ifndef _BITMAPCLASS_H_
#define _BITMAPCLASS_H_


//////////////
// INCLUDES //
//////////////
#include <d3d11.h>
#include <d3dx10math.h>
#include "parameterclass.h"

///////////////////////
// MY CLASS INCLUDES //
///////////////////////
#include "textureclass.h"


////////////////////////////////////////////////////////////////////////////////
// Class name: BitmapClass
////////////////////////////////////////////////////////////////////////////////
class BitmapClass
{
private:
	struct VertexType
	{
		D3DXVECTOR3 position;
	    D3DXVECTOR2 texture;
	};

public:
	BitmapClass();
	BitmapClass(const BitmapClass&);
	~BitmapClass();

	bool Initialize(ParameterClass* params, ID3D11Device*, ID3D11DeviceContext*);
	void Shutdown();
	bool Render(ID3D11DeviceContext*);

	int GetIndexCount();
	ID3D11ShaderResourceView* GetTextureView();
	TextureClass* GetTexture();

private:
	bool InitializeBuffers(ID3D11Device*);
	void ShutdownBuffers();
	bool UpdateBuffers(ID3D11DeviceContext*, int, int);
	void RenderBuffers(ID3D11DeviceContext*);

	bool InitializeTexture(ID3D11Device*, ID3D11DeviceContext*, int, int);
	void ReleaseTexture();

private:
	ID3D11Buffer *m_vertexBuffer, *m_indexBuffer;
	int m_vertexCount, m_indexCount;
	TextureClass* m_Texture;
	int m_screenWidth, m_screenHeight;
	int m_previousPosX, m_previousPosY;

	//int m_bitmapWidth, m_bitmapHeight;
	//int m_positionX, m_positionY;
	int* pBitmapWidth;
	int* pBitmapHeight;
	int* pPositionX;
	int* pPositionY;
};

#endif