module blendui.core;

import std.string : fromStringz, format;
import std.exception : enforce;
import derelict.sdl2.sdl : SDL_GetError;

class InvalidOperationException : Exception
{
	public this(string msg, string file = __FILE__, size_t line = __LINE__, Throwable next = null) @nogc @safe pure nothrow
	{
		super(msg, file, line, next);
	}
}

class NotImplementedException : Exception
{
	public this(string msg, string file = __FILE__, size_t line = __LINE__, Throwable next = null) @nogc @safe pure nothrow
	{
		super(msg, file, line, next);
	}
}

class ArgumentNullException : Exception
{
	public this(string arg, string msg, string file = __FILE__, size_t line = __LINE__, Throwable next = null) @safe pure
	{
		super(format!"Argument '%s' cannot be null. %s"(arg, msg), file, line, next);
	}
}

class UnsupportedException : Exception
{
	public this(string msg, string file = __FILE__, size_t line = __LINE__, Throwable next = null) @nogc @safe pure nothrow
	{
		super(msg, file, line, next);
	}
}

class GraphicsException : Exception
{
	public this(string msg, string file = __FILE__, size_t line = __LINE__, Throwable next = null) @nogc @safe pure nothrow
	{
		super(msg, file, line, next);
	}
}

class SDLException : Exception
{
	public this(string msg, string file = __FILE__, size_t line = __LINE__, Throwable next = null) @nogc @safe pure nothrow
	{
		super(msg, file, line, next);
	}
}

void enforceSDLEquals(int returnCode, int success, string message = null)
{
	enforce!SDLException(returnCode == success, (message == null ? "SDL Error: " : message ~ " -> SDL Error: ") ~ fromStringz(SDL_GetError()).idup);
}

void enforceSDLNotEquals(int returnCode, int success, string message = null)
{
	enforce!SDLException(returnCode != success, (message == null ? "SDL Error: " : message ~ " -> SDL Error: ") ~ fromStringz(SDL_GetError()).idup);
}

void enforceSDLNotNegative(int returnCode, string message = null)
{
	enforce!SDLException(returnCode >= 0, (message == null ? "SDL Error: " : message ~ " -> SDL Error: ") ~ fromStringz(SDL_GetError()).idup);
}

void enforceSDLNotNull(void* returnValue, string message = null)
{
	enforce!SDLException(returnValue != null, (message == null ? "SDL Error: " : message ~ " -> SDL Error: ") ~ fromStringz(SDL_GetError()).idup);
}

interface IDisposable
{
	void Dispose();
}
