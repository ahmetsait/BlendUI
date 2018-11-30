module blendui.application;

import std.stdio : write, writef, writeln, writefln, stderr;
import std.conv : to;
import std.format : format;
import std.string : toStringz, fromStringz;

import derelict.sdl2.sdl;
import derelict.opengl3.gl3;

import containers : HashSet;

import blendui.core;
import blendui.events;
import blendui.math;
import blendui.ui;
import blendui.util;

public static class Application
{
	//Common DPI values: 96 (1.00), 120 (1.25), 144 (1.50), 168 (1.75), 192 (2.00)
	public immutable float designDPI = 120f;
	public float renderDPI = designDPI;

	private static bool quitting;
	
	private HashSet!(Window) windows;

	public static void initialize()
	public void registerWindow(Window window)
	{
		windows.put(window);
	}
	
	public void unregisterWindow(Window window)
	{
		windows.remove(window);
	}

	{
		debug writeln("Initializing...");

		debug stderr.write("Loading SDL2 library... ");
		DerelictSDL2.load();
		debug stderr.writeln("Done.");
		debug stderr.write("Loading OpenGL library... ");
		DerelictGL3.load();
		debug stderr.writeln("Done.");

		SDL_SetHint(SDL_HINT_VIDEO_ALLOW_SCREENSAVER, "1").enforceSDLEquals(1);			//It's a general purpose GUI not a game
		SDL_SetHint(SDL_HINT_TIMER_RESOLUTION, "0").enforceSDLEquals(1);				//Do not set timer resolution to save CPU cycles
		SDL_SetHint(SDL_HINT_VIDEO_MINIMIZE_ON_FOCUS_LOSS, "0").enforceSDLEquals(1);	//Disable auto minimize
		SDL_SetHint(SDL_HINT_MOUSE_FOCUS_CLICKTHROUGH, "1").enforceSDLEquals(1);		//Prevent mouse hold up for focus
		SDL_SetHint(SDL_HINT_NO_SIGNAL_HANDLERS, "1").enforceSDLEquals(1);				//Disable SDL signal handling
		
		//Initialize SDL
		SDL_Init(SDL_INIT_VIDEO | SDL_INIT_EVENTS | SDL_INIT_TIMER).enforceSDLEquals(0,
			format!"SDL could not be initialized! SDL_Error: %s"(SDL_GetError()));
		
		//Use OpenGL 3.3 core
		SDL_GL_SetAttribute(SDL_GL_CONTEXT_MAJOR_VERSION, 3).enforceSDLEquals(0);
		SDL_GL_SetAttribute(SDL_GL_CONTEXT_MINOR_VERSION, 3).enforceSDLEquals(0);
		SDL_GL_SetAttribute(SDL_GL_CONTEXT_PROFILE_MASK, SDL_GL_CONTEXT_PROFILE_CORE).enforceSDLEquals(0);

		//Enable drag-drop
		SDL_EventState(SDL_DROPTEXT, SDL_ENABLE);
		SDL_EventState(SDL_DROPFILE, SDL_ENABLE);
		SDL_EventState(SDL_DROPBEGIN, SDL_ENABLE);
		SDL_EventState(SDL_DROPCOMPLETE, SDL_ENABLE);
		
		debug stderr.writeln("Initializing done.");
	}

	private static SDL_GLContext glContext = null;

	public static SDL_GLContext getSharedGLContext(SDL_Window* window)
	{
		if (window == null)
			return glContext;

		if (glContext == null)
		{
			glContext = SDL_GL_CreateContext(window);
			glContext.enforceSDLNotNull("OpenGL context could not be created");
			DerelictGL3.reload(GLVersion.GL33, GLVersion.GL33);
		}

		return glContext;
	}

	public static void run(Window window = null)
	{
		if (window !is null)
			window.show();

		bool exiting = false;
		SDL_Event event;
		while (!exiting)
		{
			if (SDL_WaitEvent(&event))
			{
				switch(event.type)
				{
					case SDL_QUIT:
						exiting = true;
						break;
					default:
						break;
				}
			}
		}
	}

	public static void exit()
	{
		SDL_Event event = void;
		event.type = SDL_QUIT;
		event.quit.timestamp = SDL_GetTicks();
		SDL_PushEvent(&event);
	}

	public static void terminate()
	{
		debug stderr.write("Terminating... ");
		//Quit SDL subsystems
		SDL_Quit();
		debug stderr.writeln("Done.");
	}
}
