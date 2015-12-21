////////////////////////////////////////////////////////////////////////////////
// Filename: textureclass.cpp
// Object representing a texture in Direct3D 9.
// This code is adapted from the tutorials on rastertek.com (unknown author).
//  - Damien Loterie (01/2014)
////////////////////////////////////////////////////////////////////////////////
// Modified based on:
// * http://stackoverflow.com/questions/14672005/how-to-use-updatesubresource-to-update-the-texture-in-direct3d
// * http://msdn.microsoft.com/en-us/library/windows/desktop/bb205131(v=vs.85).aspx

#include "textureclass.h"
#include "errors.h"

TextureClass::TextureClass()
{
	m_textureView = 0;
	m_texture = 0;
	m_textureWidth = 0;
	m_textureHeight = 0;
	m_textureSize = 0;
}


TextureClass::TextureClass(const TextureClass& other)
{
}


TextureClass::~TextureClass()
{
}


bool TextureClass::Initialize(ID3D11Device* device, ID3D11DeviceContext* deviceContext, int textureWidth, int textureHeight)
{
	HRESULT result;

	// Save parameters
	m_textureWidth = textureWidth;
	m_textureHeight = textureHeight;
	m_textureSize = m_textureWidth*m_textureHeight;
	//m_textureSize = m_textureWidth*m_textureHeight*4;  // (this is for color textures)

	// Create a texture that can be accessed by the CPU
	ZeroMemory(&m_textureDesc, sizeof(m_textureDesc));
	m_textureDesc.Width = textureWidth;
	m_textureDesc.Height = textureHeight;
	m_textureDesc.Format = DXGI_FORMAT_R8_UNORM;
	//m_textureDesc.Format = DXGI_FORMAT_R8G8B8A8_UNORM;  // (this is for color textures)
	m_textureDesc.MipLevels = 1;
	m_textureDesc.ArraySize = 1;
	m_textureDesc.SampleDesc.Quality = 0;
	m_textureDesc.SampleDesc.Count = 1;
	m_textureDesc.Usage = D3D11_USAGE_DYNAMIC;
	m_textureDesc.BindFlags = D3D11_BIND_SHADER_RESOURCE;
	m_textureDesc.CPUAccessFlags = D3D11_CPU_ACCESS_WRITE;

	result = device->CreateTexture2D( &m_textureDesc, NULL, &m_texture );
	if(FAILED(result))
	{
		return false;
	}


	// Get the description of the created texture and check the dimensions (just to be sure)
	m_texture->GetDesc(&m_textureDesc);
	if ( m_textureDesc.Width != textureWidth
		|| m_textureDesc.Height != textureHeight)
	{
		ReportError("Could not create a texture with the requested dimensions.\r\nThe code for this application should be edited to handle this case.");
		return false;
	}


	// Once the texture is created, we must create a shader resource view of it
	// so that shaders may use it.  In general, the view description will match
	// the texture description.
	D3D11_SHADER_RESOURCE_VIEW_DESC textureViewDesc;
	ZeroMemory(&textureViewDesc, sizeof(textureViewDesc));
	textureViewDesc.Format = m_textureDesc.Format;
	textureViewDesc.ViewDimension = D3D11_SRV_DIMENSION_TEXTURE2D;
	textureViewDesc.Texture2D.MipLevels = m_textureDesc.MipLevels;
	textureViewDesc.Texture2D.MostDetailedMip = 0;

	result = device->CreateShaderResourceView(m_texture, &textureViewDesc, &m_textureView);
	if(FAILED(result))
	{
		return false;
	}


	// Fill the texture
	D3D11_MAPPED_SUBRESOURCE mappedTexture;
	result = deviceContext->Map(m_texture, 0, D3D11_MAP_WRITE_DISCARD, 0, &mappedTexture);
	if(FAILED(result))
	{
		return false;
	}

	ZeroMemory((UCHAR*)mappedTexture.pData, m_textureSize);

	//UCHAR* pTexels = (UCHAR*)mappedTexture.pData;
	//for( UINT row = 0; row < m_textureDesc.Height; row++ )
	//{
	//	UINT rowStart = row * mappedTexture.RowPitch;
	//	for( UINT col = 0; col < m_textureDesc.Width; col++ )
	//	{
	//		UINT colStart = col;
	//		//UINT colStart = col * 4;   // (this is for color textures)
	//		if ((col+row)%2==0) {
	//			pTexels[rowStart + colStart + 0] = 255; // Red
	//			//pTexels[rowStart + colStart + 1] = 255; // Green
	//			//pTexels[rowStart + colStart + 2] = 255; // Blue
	//			//pTexels[rowStart + colStart + 3] = 0;   // Alpha
	//		} else {
	//			pTexels[rowStart + colStart + 0] = 0; // Red
	//			//pTexels[rowStart + colStart + 1] = 0; // Green
	//			//pTexels[rowStart + colStart + 2] = 0; // Blue
	//			//pTexels[rowStart + colStart + 3] = 0;   // Alpha
	//		}

	//	}
	//}

	deviceContext->Unmap(m_texture, 0);


	return true;
}

bool TextureClass::Update(ID3D11DeviceContext* deviceContext, UCHAR* pSource)
{
	HRESULT result;

	// Map texture
	D3D11_MAPPED_SUBRESOURCE mappedTexture;
	result = deviceContext->Map(m_texture, 0, D3D11_MAP_WRITE_DISCARD, 0, &mappedTexture);
	if(FAILED(result))
	{
		return false;
	}

	// Copy data (the wrong way)
	// CopyMemory((UCHAR*)mappedTexture.pData, source, min(length, m_textureSize));

	// Copy data (the correct way)
	UCHAR* pDest = (UCHAR*)mappedTexture.pData;
	for(unsigned int row = 0; row < m_textureDesc.Height; row++ )
	{
		CopyMemory(pDest, pSource, m_textureDesc.Width);
		pDest   += mappedTexture.RowPitch;
		pSource += m_textureDesc.Width;
	}

	// Unmap texture
	deviceContext->Unmap(m_texture, 0);

	// Return
	return true;
}

bool TextureClass::Clear(ID3D11DeviceContext* deviceContext)
{
	HRESULT result;

	// Map texture
	D3D11_MAPPED_SUBRESOURCE mappedTexture;
	result = deviceContext->Map(m_texture, 0, D3D11_MAP_WRITE_DISCARD, 0, &mappedTexture);
	if(FAILED(result))
	{
		return false;
	}

	// Copy data
	ZeroMemory((UCHAR*)mappedTexture.pData, m_textureSize);

	// Unmap texture
	deviceContext->Unmap(m_texture, 0);

	// Return
	return true;
}


void TextureClass::Shutdown()
{
	// Release the texture resource.
	if(m_textureView)
	{
		m_textureView->Release();
		m_textureView = 0;
	}

	return;
}


ID3D11ShaderResourceView* TextureClass::GetTextureView()
{
	return m_textureView;
}

ID3D11Texture2D* TextureClass::GetTexture()
{
	return m_texture;
}