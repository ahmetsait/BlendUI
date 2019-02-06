module blendui.application;

import std.stdio : write, writef, writeln, writefln, stderr;
import std.conv : to;
import std.format : format;
import std.string : toStringz, fromStringz;
import std.algorithm : canFind, countUntil, map;
import std.array : split, array;

import derelict.sdl2.sdl;
import derelict.freeimage.freeimage;
import derelict.freetype.ft;
import blendui.graphics.gl;
import blendui.graphics.gl.loader;

import containers.hashset;

import blendui.core;
import blendui.events;
import blendui.graphics.font;
import blendui.math;
import blendui.ui;
import blendui.util;

public static class Application
{
static:

	private bool running = false, _glDebugEnabled = false;
	
	public bool glDebugEnabled() @property
	{
		return _glDebugEnabled;
	}
	
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
		debug stderr.writeln("Initializing...");

		debug stderr.write("Loading SDL2 library... ");
		DerelictSDL2.load();
		debug stderr.writeln("Done");
		
		debug stderr.write("Loading FreeImage library... ");
		DerelictFI.load();
		debug stderr.writeln("Done");
		
		debug stderr.write("Loading FreeType library... ");
		DerelictFT.load();

		if (FT_Init_FreeType(&ftLib))
			throw new Exception("Could not load FreeType library.");

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

		//Enable debug context
		debug
			auto ctxflags = SDL_GL_CONTEXT_FORWARD_COMPATIBLE_FLAG | SDL_GL_CONTEXT_DEBUG_FLAG;
		else
			auto ctxflags = SDL_GL_CONTEXT_FORWARD_COMPATIBLE_FLAG;
		SDL_GL_SetAttribute(SDL_GL_CONTEXT_FLAGS, ctxflags).enforceSDLEquals(0);

		//Request some actual bit depth
		SDL_GL_SetAttribute(SDL_GL_RED_SIZE, 8).enforceSDLEquals(0);
		SDL_GL_SetAttribute(SDL_GL_GREEN_SIZE, 8).enforceSDLEquals(0);
		SDL_GL_SetAttribute(SDL_GL_BLUE_SIZE, 8).enforceSDLEquals(0);
		SDL_GL_SetAttribute(SDL_GL_ALPHA_SIZE, 0).enforceSDLEquals(0);
		SDL_GL_SetAttribute(SDL_GL_DEPTH_SIZE, 0).enforceSDLEquals(0);
		SDL_GL_SetAttribute(SDL_GL_STENCIL_SIZE, 8).enforceSDLEquals(0);

		SDL_GL_SetAttribute(SDL_GL_DOUBLEBUFFER, 1).enforceSDLEquals(0);

		//Enable multisampling support
		SDL_GL_SetAttribute(SDL_GL_MULTISAMPLEBUFFERS, 1);
		SDL_GL_SetAttribute(SDL_GL_MULTISAMPLESAMPLES, 4);

		//Enable drag-drop
		SDL_EventState(SDL_DROPTEXT, SDL_ENABLE);
		SDL_EventState(SDL_DROPFILE, SDL_ENABLE);
		SDL_EventState(SDL_DROPBEGIN, SDL_ENABLE);
		SDL_EventState(SDL_DROPCOMPLETE, SDL_ENABLE);

		//Disable text input by default
		SDL_StopTextInput();
		
		debug stderr.writeln("Initializing done");
	}

	extern(System)
	{
		private void debugCallback(GLenum source, GLenum type, GLuint id, GLenum severity, GLsizei length, in GLchar* message, GLvoid* userParam)
		{
			string sourceStr;
			switch(source)
			{
				case GL_DEBUG_SOURCE_API:
					sourceStr = "API";
					break;
				case GL_DEBUG_SOURCE_APPLICATION:
					sourceStr = "Application";
					break;
				case GL_DEBUG_SOURCE_OTHER:
					sourceStr = "Other";
					break;
				case GL_DEBUG_SOURCE_SHADER_COMPILER:
					sourceStr = "ShaderCompiler";
					break;
				case GL_DEBUG_SOURCE_THIRD_PARTY:
					sourceStr = "ThirdParty";
					break;
				case GL_DEBUG_SOURCE_WINDOW_SYSTEM:
					sourceStr = "WindowSystem";
					break;
				default:
					sourceStr = "?";
					break;
			}
			string typeStr;
			switch(type)
			{
				case GL_DEBUG_TYPE_DEPRECATED_BEHAVIOR:
					typeStr = "DeprecatedBehavior";
					break;
				case GL_DEBUG_TYPE_ERROR:
					typeStr = "Error";
					break;
				case GL_DEBUG_TYPE_MARKER:
					typeStr = "Marker";
					break;
				case GL_DEBUG_TYPE_OTHER:
					typeStr = "Other";
					break;
				case GL_DEBUG_TYPE_PERFORMANCE:
					typeStr = "Performance";
					break;
				case GL_DEBUG_TYPE_POP_GROUP:
					typeStr = "PopGroup";
					break;
				case GL_DEBUG_TYPE_PORTABILITY:
					typeStr = "Portability";
					break;
				case GL_DEBUG_TYPE_PUSH_GROUP:
					typeStr = "PushGroup";
					break;
				case GL_DEBUG_TYPE_UNDEFINED_BEHAVIOR:
					typeStr = "UndefinedBehavior";
					break;
				default:
					typeStr = "?";
					break;
			}
			string severityStr;
			switch(severity)
			{
				case GL_DEBUG_SEVERITY_HIGH:
					severityStr = "High";
					break;
				case GL_DEBUG_SEVERITY_LOW:
					severityStr = "Low";
					break;
				case GL_DEBUG_SEVERITY_MEDIUM:
					severityStr = "Medium";
					break;
				case GL_DEBUG_SEVERITY_NOTIFICATION:
					severityStr = "Notification";
					break;
				default:
					severityStr = "?";
					break;
			}
			synchronized (logLock)
			{
				stderr.writefln!"[%s - Source:%s, Type:%s, Severity:%s] %s"(id, sourceStr, typeStr, severityStr, message.fromStringz());
				stderr.writeln(getStackTrace());
				stderr.flush();
			}
		}

		private void debugCallbackAMD(GLuint id, GLenum category, GLenum severity, GLsizei length, in GLchar* message, GLvoid* userParam)
		{
			string categoryStr;
			switch(category)
			{
				case GL_DEBUG_CATEGORY_API_ERROR_AMD:
					categoryStr = "API";
					break;
				case GL_DEBUG_CATEGORY_APPLICATION_AMD:
					categoryStr = "Application";
					break;
				case GL_DEBUG_CATEGORY_DEPRECATION_AMD:
					categoryStr = "Deprecation";
					break;
				case GL_DEBUG_CATEGORY_OTHER_AMD:
					categoryStr = "Other";
					break;
				case GL_DEBUG_CATEGORY_PERFORMANCE_AMD:
					categoryStr = "Performance";
					break;
				case GL_DEBUG_CATEGORY_SHADER_COMPILER_AMD:
					categoryStr = "ShaderCompiler";
					break;
				case GL_DEBUG_CATEGORY_UNDEFINED_BEHAVIOR_AMD:
					categoryStr = "UndefinedBehavior";
					break;
				case GL_DEBUG_CATEGORY_WINDOW_SYSTEM_AMD:
					categoryStr = "WindowSystem";
					break;
				default:
					categoryStr = "?";
					break;
			}
			string severityStr;
			switch(severity)
			{
				case GL_DEBUG_SEVERITY_HIGH_AMD:
					severityStr = "High";
					break;
				case GL_DEBUG_SEVERITY_LOW_AMD:
					severityStr = "Low";
					break;
				case GL_DEBUG_SEVERITY_MEDIUM_AMD:
					severityStr = "Medium";
					break;
				default:
					severityStr = "?";
					break;
			}
			synchronized (logLock)
			{
				stderr.writefln!"[%s - Category:%s, Severity:%s] %s"(id, categoryStr, severityStr, message.fromStringz());
				stderr.writeln(getStackTrace(), '\n');
				stderr.flush();
			}
		}
	}

	private SDL_GLContext glContext = null;

	public SDL_GLContext getSharedGLContext(SDL_Window* window)
	{
		if (window == null)
			return glContext;

		if (glContext != null)
		{
			return glContext;
		}
		else
		{
			glContext = SDL_GL_CreateContext(window)
				.enforceSDLNotNull("OpenGL context could not be created");
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

				if (GL_KHR_debug)
					glDebugMessageCallbackKHR(&debugCallback, null);
				else if (GL_ARB_debug_output)
					glDebugMessageCallbackARB(&debugCallback, null);
				else if (GL_AMD_debug_output)
					glDebugMessageCallbackAMD(&debugCallbackAMD, null);

				auto err = glGetError();
				if (err != GL_NO_ERROR)
					writefln!"0x%X"(err);

				_glDebugEnabled = GL_KHR_debug || GL_ARB_debug_output || GL_AMD_debug_output;
				if (_glDebugEnabled)
				{
					glEnable(GL_DEBUG_OUTPUT);
					stderr.writeln("Debugging enabled");
				}
			}

			glEnable(GL_MULTISAMPLE);
			glDisable(GL_CULL_FACE);
			glEnable(GL_BLEND);
			glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
			glEnable(GL_LINE_SMOOTH);
			glHint(GL_LINE_SMOOTH_HINT, GL_NICEST);

			//Disable vsync
			SDL_GL_SetSwapInterval(0).enforceSDLEquals(0, "Could not set swap interval (VSync).");

			return glContext;
		}
	}

	public Event!() keymapChanged;
	public Event!() clipboardUpdate;

	public void run()
	{
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
					case SDL_KEYMAPCHANGED:
						keymapChanged.fire();
						break;
					case SDL_CLIPBOARDUPDATE:
						clipboardUpdate.fire();
						break;
					default:
						debug stderr.writefln!"Undispatched event: 0x%X"(event.type);
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
		debug stderr.writeln("Done");
	}
}

private shared static this()
{
	logLock = new Object;
}

private __gshared Object logLock;
