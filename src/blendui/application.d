module blendui.application;

import std.stdio : write, writef, writeln, writefln, stderr;
import std.conv : to;
import std.format : format;
import std.string : toStringz, fromStringz;

import derelict.sdl2.sdl;
import blendui.gl.all;
import blendui.gl.loader;

import containers : HashSet;

import blendui.core;
import blendui.events;
import blendui.math;
import blendui.ui;
import blendui.util;

public static class Application
{
static:
	//Common DPI values: 96 (1.00), 120 (1.25), 144 (1.50), 168 (1.75), 192 (2.00)
	public immutable float designDPI = 120f;
	public float renderDPI = designDPI;

	private bool running = false;
	
	private HashSet!(Window) windows;

	public void registerWindow(Window window)
	{
		windows.put(window);
	}
	
	public void unregisterWindow(Window window)
	{
		windows.remove(window);
	}

	public void initialize()
	{
		debug writeln("Initializing...");

		debug stderr.write("Loading SDL2 library... ");
		DerelictSDL2.load();
		debug stderr.writeln("Done");

		SDL_SetHint(SDL_HINT_VIDEO_ALLOW_SCREENSAVER, "1").enforceSDLEquals(1);			//It's a general purpose GUI not a game
		SDL_SetHint(SDL_HINT_TIMER_RESOLUTION, "0").enforceSDLEquals(1);				//Do not set timer resolution to save CPU cycles
		SDL_SetHint(SDL_HINT_VIDEO_MINIMIZE_ON_FOCUS_LOSS, "0").enforceSDLEquals(1);	//Disable auto minimize
		SDL_SetHint(SDL_HINT_MOUSE_FOCUS_CLICKTHROUGH, "1").enforceSDLEquals(1);		//Prevent mouse hold up for focus
		SDL_SetHint(SDL_HINT_NO_SIGNAL_HANDLERS, "1").enforceSDLEquals(1);				//Disable SDL signal handling
		
		//Initialize SDL
		SDL_Init(SDL_INIT_VIDEO | SDL_INIT_EVENTS | SDL_INIT_TIMER).enforceSDLEquals(0,
			format!"SDL could not be initialized. SDL_Error: %s"(SDL_GetError()));
		
		//Use OpenGL 3.3 core
		SDL_GL_SetAttribute(SDL_GL_CONTEXT_MAJOR_VERSION, 3).enforceSDLEquals(0);
		SDL_GL_SetAttribute(SDL_GL_CONTEXT_MINOR_VERSION, 3).enforceSDLEquals(0);
		SDL_GL_SetAttribute(SDL_GL_CONTEXT_PROFILE_MASK, SDL_GL_CONTEXT_PROFILE_CORE).enforceSDLEquals(0);
		SDL_GL_SetAttribute(SDL_GL_CONTEXT_FLAGS, SDL_GL_CONTEXT_FORWARD_COMPATIBLE_FLAG).enforceSDLEquals(0);

		//Enable debug context
		debug SDL_GL_SetAttribute(SDL_GL_CONTEXT_FLAGS, SDL_GL_CONTEXT_DEBUG_FLAG).enforceSDLEquals(0);

		//Request some actual bit depth
		SDL_GL_SetAttribute(SDL_GL_RED_SIZE, 8).enforceSDLEquals(0);
		SDL_GL_SetAttribute(SDL_GL_GREEN_SIZE, 8).enforceSDLEquals(0);
		SDL_GL_SetAttribute(SDL_GL_BLUE_SIZE, 8).enforceSDLEquals(0);
		SDL_GL_SetAttribute(SDL_GL_ALPHA_SIZE, 0).enforceSDLEquals(0);
		SDL_GL_SetAttribute(SDL_GL_DOUBLEBUFFER, 1).enforceSDLEquals(0);
		SDL_GL_SetAttribute(SDL_GL_DEPTH_SIZE, 16).enforceSDLEquals(0);
		SDL_GL_SetAttribute(SDL_GL_STENCIL_SIZE, 1).enforceSDLEquals(0);

		//TODO: Add multisample support

		//Enable drag-drop
		SDL_EventState(SDL_DROPTEXT, SDL_ENABLE);
		SDL_EventState(SDL_DROPFILE, SDL_ENABLE);
		SDL_EventState(SDL_DROPBEGIN, SDL_ENABLE);
		SDL_EventState(SDL_DROPCOMPLETE, SDL_ENABLE);

		//Disable text input by default
		SDL_StopTextInput();
		
		debug stderr.writeln("Initializing done.");
	}

	{

	}

	private SDL_GLContext glContext = null;

	public SDL_GLContext getSharedGLContext(SDL_Window* window)
	{
		if (window == null)
			return glContext;

		if (glContext == null)
		{
			glContext = SDL_GL_CreateContext(window);
			glContext.enforceSDLNotNull("OpenGL context could not be created");
			debug stderr.write("Loading OpenGL library... ");
			if (!loadGL())
				throw new GraphicsException("Failed to load OpenGL 3.3");
			debug stderr.writeln("Done");

			debug
			{
				//Diagnostics
				stderr.writeln("========================================");
				stderr.writeln("Renderer: ", glGetString(GL_RENDERER).fromStringz());
				stderr.writeln("OpenGL Version: ", glGetString(GL_VERSION).fromStringz());
				stderr.writeln("GLSL Version: ", glGetString(GL_SHADING_LANGUAGE_VERSION).fromStringz());
				stderr.writeln("Vendor: ", glGetString(GL_VENDOR).fromStringz());
				stderr.writeln("----------------------------------------");
			}
			glEnable(GL_DEBUG_OUTPUT);
			glDisable(GL_CULL_FACE);
			glEnable(GL_BLEND);
			glEnable(GL_LINE_SMOOTH);
			glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
			glHint(GL_LINE_SMOOTH_HINT, GL_NICEST);

			//Disable vsync
			SDL_GL_SetSwapInterval(0).enforceSDLEquals(0, "Could not set swap interval (VSync).");
		}

		return glContext;
	}

	public void run(Window mainWindow = null)
	{
		if (mainWindow !is null)
			mainWindow.show();

		running = true;
		SDL_Event event;
		while (running)
		{
			if (SDL_WaitEvent(&event))
			{
				switch(event.type)
				{
					case SDL_QUIT:
						bool allClosed = true;
						foreach(Window window; windows)
						{
							if (!window.disposed)
							{
								allClosed = false;
								break;
							}
						}
						if (allClosed)
							running = false;
						break;
					case SDL_WINDOWEVENT:
					case SDL_KEYDOWN:
					case SDL_KEYUP:
					case SDL_TEXTEDITING:
					case SDL_TEXTINPUT:
					case SDL_MOUSEMOTION:
					case SDL_MOUSEBUTTONDOWN:
					case SDL_MOUSEBUTTONUP:
					case SDL_MOUSEWHEEL:
						//These windowIDs have the same offset
						foreach(Window window; windows)
						{
							if (window.getSDLWindowID() == event.window.windowID)
								window.handleEvent(event);
						}
						break;
					case SDL_DROPBEGIN:
					case SDL_DROPTEXT:
					case SDL_DROPFILE:
					case SDL_DROPCOMPLETE:
						//windowID of SDL_DropEvent has a different offset
						foreach(Window window; windows)
						{
							if (window.getSDLWindowID() == event.drop.windowID)
								window.handleEvent(event);
						}
						break;
					default:
						debug stderr.writeln(format!"Event not sent: %d"(event.type));
						break;
				}
			}
		}
	}

	public void exit()
	{
		foreach(Window window; windows)
			window.close();
		SDL_Event event = void;
		event.type = SDL_QUIT;
		event.quit.timestamp = SDL_GetTicks();
		SDL_PushEvent(&event);
	}

	public void terminate()
	{
		debug stderr.write("Terminating... ");
		//Quit SDL subsystems
		SDL_Quit();
		debug stderr.writeln("Done.");
	}
}
