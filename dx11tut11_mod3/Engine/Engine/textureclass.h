////////////////////////////////////////////////////////////////////////////////
// Filename: textureclass.h
// Object representing a texture in Direct3D 9.
// This code is adapted from the tutorials on rastertek.com (unknown author).
//  - Damien Loterie (01/2014)
////////////////////////////////////////////////////////////////////////////////
#ifndef _TEXTURECLASS_H_
#define _TEXTURECLASS_H_


//////////////
// INCLUDES //
//////////////
#include <d3d11.h>
#include <d3dx11tex.h>


////////////////////////////////////////////////////////////////////////////////
// Class name: TextureClass
////////////////////////////////////////////////////////////////////////////////
class TextureClass
{
public:
	TextureClass();
	TextureClass(const TextureClass&);
	~TextureClass();

	bool Initialize(ID3D11Device*, ID3D11DeviceContext*, int, int);
	bool Update(ID3D11DeviceContext*, UCHAR*);
	bool Clear(ID3D11DeviceContext*);
	void Shutdown();

	ID3D11ShaderResourceView* GetTextureView();
	ID3D11Texture2D* GetTexture();

private:
	ID3D11ShaderResourceView* m_textureView;
	ID3D11Texture2D*		  m_texture;
	D3D11_TEXTURE2D_DESC	  m_textureDesc;
	int m_textureWidth;
	int m_textureHeight;
	int m_textureSize;
};

#endif