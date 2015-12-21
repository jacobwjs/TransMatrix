////////////////////////////////////////////////////////////////////////////////
// Filename: systemclass.cpp
// Main program logic for the DirectX interface application.
//  - Damien Loterie (01/2014)
////////////////////////////////////////////////////////////////////////////////
#include "systemclass.h"
#include "errors.h"

SystemClass::SystemClass()
{
	ZeroMemory(this,sizeof(SystemClass));
}


SystemClass::SystemClass(const SystemClass& other)
{
}


SystemClass::~SystemClass()
{
}


bool SystemClass::Initialize(ParameterClass* params)
{
	// Initialize
	bool result;
	m_Parameters = params;

	// Create the communications object.
	m_Communication = new CommunicationClass;
	if(!m_Communication)
	{
		return false;
	}

	// Initialize the communications object.
	result = m_Communication->Initialize(params);
	if(!result)
	{
		return false;
	}

	// Get a pointer to the shared parameters in the communications class.
	m_Parameters = m_Communication->GetSharedParameters();

	// Initialize the windows api.
	InitializeWindows(m_Parameters->screenWidth, m_Parameters->screenHeight);

	// Create the graphics object.  This object will handle rendering all the graphics for this application.
	m_Graphics = new GraphicsClass;
	if(!m_Graphics)
	{
		return false;
	}

	// Initialize the graphics object.
	result = m_Graphics->Initialize(m_Parameters, m_hwnd);
	if(!result)
	{
		return false;
	}
	
	return true;
}


void SystemClass::Shutdown()
{
	// Release the graphics object.
	if(m_Graphics)
	{
		m_Graphics->Shutdown();
		delete m_Graphics;
		m_Graphics = 0;
	}

	// Shutdown the window.
	ShutdownWindows();

	// Release the communications object.
	if(m_Communication)
	{
		m_Communication->Shutdown();
		delete m_Communication;
		m_Communication = 0;
	}

	return;
}


bool SystemClass::Run()
{
	MSG msg;
	bool result;


	// Initialize the message structure.
	ZeroMemory(&msg, sizeof(MSG));
	
	// Loop until there is a quit message from the window or the user.
	while (true)
	{
		// Handle the windows messages.
		if(PeekMessage(&msg, NULL, 0, 0, PM_REMOVE))
		{
			TranslateMessage(&msg);
			DispatchMessage(&msg);
		}

		// If windows signals to end the application then exit out.
		if(msg.message == WM_QUIT)
			return true;

		// Check shared memory to see if the program should close
		if(m_Parameters->quit)
			return true;
		
		// Communications pre-processing
		result = m_Communication->PreProcess(m_Graphics->GetD3D()->GetDeviceContext(), m_Graphics->GetTexture());
		if(!result) {
			ReportError("Communications preprocessing failed.");
			return false;
		}

		// Otherwise do the frame processing.
		result = m_Graphics->Render();
		if(!result)  {
			ReportError("Graphics rendering failed.");
			return false;
		}

		// Communications post-processing
		result = m_Communication->PostProcess(m_Graphics->GetD3D());
		if(!result) {
			ReportError("Communications postprocessing failed.");
			return false;
		}

	}

	return true;
}


void SystemClass::InitializeWindows(int screenWidth, int screenHeight)
{
	WNDCLASSEX wc;

	// Default position of the window
	int posX = 0;
	int posY = 0;

	// Get an external pointer to this object.	
	ApplicationHandle = this;

	// Get the instance of this application.
	m_hinstance = GetModuleHandle(NULL);

	// Give the application a name.
	m_applicationName = "DirectX Fullscreen";

	// Setup the windows class with default settings.
	wc.style         = CS_HREDRAW | CS_VREDRAW | CS_OWNDC;
	wc.lpfnWndProc   = WndProc;
	wc.cbClsExtra    = 0;
	wc.cbWndExtra    = 0;
	wc.hInstance     = m_hinstance;
	wc.hIcon		 = LoadIcon(NULL, IDI_WINLOGO);
	wc.hIconSm       = wc.hIcon;
	wc.hCursor       = LoadCursor(NULL, IDC_ARROW);
	wc.hbrBackground = (HBRUSH)GetStockObject(BLACK_BRUSH);
	wc.lpszMenuName  = NULL;
	wc.lpszClassName = m_applicationName;
	wc.cbSize        = sizeof(WNDCLASSEX);
	
	// Fullscreen parameters
	if (m_Parameters->fullscreen)
	{
		DwmEnableComposition(DWM_EC_DISABLECOMPOSITION);
	}

	// Register the window class.
	RegisterClassEx(&wc);

	// Create the window with the screen settings and get the handle to it.
	m_hwnd = CreateWindowEx(WS_EX_APPWINDOW, m_applicationName, m_applicationName, 
						    WS_CLIPSIBLINGS | WS_CLIPCHILDREN | WS_POPUP,
						    posX, posY, screenWidth, screenHeight, NULL, NULL, m_hinstance, NULL);

	// Bring the window up on the screen and set it as main focus.
	ShowWindow(m_hwnd, SW_SHOW);
	//SetForegroundWindow(m_hwnd);
	//SetFocus(m_hwnd);

	// Hide the mouse cursor.
	ShowCursor(false);

	return;
}


void SystemClass::ShutdownWindows()
{
	// Show the mouse cursor.
	ShowCursor(true);

	// Fix the display settings if leaving full screen mode.
	//if(FULL_SCREEN)
	if (m_Parameters->fullscreen)
	{
		DwmEnableComposition(DWM_EC_ENABLECOMPOSITION);

		// This is only if you change the display settings before going to full screen (see original dx11tut11 code)
		//ChangeDisplaySettings(NULL, 0);
	}

	// Remove the window.
	if (m_hwnd) {
		DestroyWindow(m_hwnd);
		m_hwnd = NULL;
	}

	// Remove the application instance.
	if (m_applicationName && m_hinstance) {
		UnregisterClass(m_applicationName, m_hinstance);
		m_hinstance = NULL;
	}

	// Release the pointer to this class.
	ApplicationHandle = NULL;

	return;
}


LRESULT CALLBACK WndProc(HWND hwnd, UINT umessage, WPARAM wparam, LPARAM lparam)
{
	switch(umessage)
	{
		// Check if the window is being destroyed.
		case WM_DESTROY:
		{
			PostQuitMessage(0);
			return 0;
		}

		// Check if the window is being closed.
		case WM_CLOSE:
		{
			PostQuitMessage(0);		
			return 0;
		}

		// Check if the ESC key has been pressed on the keyboard.
		case WM_KEYDOWN:
		{
			if (wparam == VK_ESCAPE) {
				PostQuitMessage(0);
			}
			return 0;
		}

		// All other messages pass to the message handler in the system class.
		default:
		{
			return DefWindowProc(hwnd, umessage, wparam, lparam);
		}


	}
}