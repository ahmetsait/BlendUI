module blendui.graphics.shader;

debug import std.stdio : write, writeln;
import std.string : toStringz, fromStringz;
import std.format : format;
import std.conv : to;

import derelict.sdl2.sdl;
import blendui.gl.gl;

import gfm.math.vector;
import gfm.math.matrix;

import blendui.core;
import blendui.math;
import blendui.util;

private immutable uniformTypes = [
	"int",
	"uint",
	"float"
];
private immutable uniformSuffixes = [
	"i",
	"ui",
	"f"
];

public struct Shader
{
	private uint id;
	private int[string] uniformTable;

	public this(string vertSource, string fragSource)
	{
		uint vert = CompileShader(vertSource, GL_VERTEX_SHADER);
		uint frag = CompileShader(fragSource, GL_FRAGMENT_SHADER);
		uint prog = glCreateProgram();
		glAttachShader(prog, vert);
		glAttachShader(prog, frag);
		glLinkProgram(prog);
		glDeleteShader(vert);
		glDeleteShader(frag);

		int success;
		glGetProgramiv(prog, GL_LINK_STATUS, &success);
		if (success == 0)
		{
			int infoLen;
			glGetShaderiv(prog, GL_INFO_LOG_LENGTH, &infoLen);
			char[] error = new char[infoLen];
			glGetShaderInfoLog(prog, error.length, &infoLen, error.ptr);
			throw new GraphicsException(("Failed to link program: " ~ error[0 .. infoLen]).idup);
		}
		id = prog;
	}

	private static uint CompileShader(string source, GLenum type)
	{
		uint shader = glCreateShader(type);
		auto src = source.toStringz();
		int len = source.length;
		glShaderSource(shader, 1, &src, &len);
		glCompileShader(shader);

		int success;
		glGetShaderiv(shader, GL_COMPILE_STATUS, &success);
		if (success == 0)
		{
			int infoLen;
			glGetShaderiv(shader, GL_INFO_LOG_LENGTH, &infoLen);
			char[] error = new char[infoLen];
			glGetShaderInfoLog(shader, error.length, &infoLen, error.ptr);
			throw new GraphicsException(("Failed to compile shader: " ~ error[0 .. infoLen]).idup);
		}
		return shader;
	}

	public void Use()
	{
		glUseProgram(id);
	}

	public void SetUniform(T)(string name, T value) if (uniformTypes.contains(T.stringof))
	{
		enum index = uniformTypes.indexOf(T.stringof);
		int* locationPtr = name in uniformTable;
		if (locationPtr != null)
			mixin(q{glUniform1} ~ uniformSuffixes[index] ~ q{(*locationPtr, value);});
		else
		{
			int location = glGetUniformLocation(id, name.toStringz());
			if (location == -1)
				throw new GraphicsException(format!"Uniform (%s) location could not be retrieved."(name));
			mixin(q{glUniform1} ~ uniformSuffixes[index] ~ q{(uniformTable[name] = location, value);});
		}
	}

	unittest
	{
		Shader s;
		static assert(__traits(compiles, s.SetUniform("i", 5)));
		static assert(__traits(compiles, s.SetUniform("ui", 5u)));
		static assert(__traits(compiles, s.SetUniform("f", 5f)));
		static assert(!__traits(compiles, s.SetUniform("d", 5.0)));
		static assert(!__traits(compiles, s.SetUniform("b", true)));
	}

	public void SetUniform(T, int N)(string name, Vector!(T, N) value) if (uniformTypes.contains(T.stringof))
	{
		static assert(N >= 2 && N <= 4, "Vector length out of range");
		enum index = uniformTypes.indexOf(T.stringof);
		int* locationPtr = name in uniformTable;
		if (locationPtr != null)
			mixin(q{glUniform} ~ N.to!string ~ uniformSuffixes[index] ~ q{v(*locationPtr, 1, value.v.ptr);});
		else
		{
			int location = glGetUniformLocation(id, name.toStringz());
			if (location == -1)
				throw new GraphicsException(format!"Uniform (%s) location could not be retrieved."(name));
			mixin(q{glUniform} ~ N.to!string ~ uniformSuffixes[index] ~ q{v(uniformTable[name] = location, 1, value.v.ptr);});
		}
	}
	
	unittest
	{
		Shader s;
		static assert(__traits(compiles, s.SetUniform("v", vec2i(1, 2))));
		static assert(__traits(compiles, s.SetUniform("v", vec3ui(3, 4, 5))));
		static assert(__traits(compiles, s.SetUniform("v", vec4f(6, 7, 8, 9))));
	}

	public void SetUniform(int R, int C)(string name, Matrix!(float, R, C) value)
	{
		static assert(R >= 2 && R <= 4 && C >= 2 && C <= 4, "Matrix dimension(s) out of range");
		int* locationPtr = name in uniformTable;
		if (locationPtr != null)
			mixin(q{glUniformMatrix} ~ (R == C ? R.to!string : R.to!string ~ "x" ~ C.to!string) ~ q{fv(*locationPtr, 1, true, value.v.ptr);});
		else
		{
			int location = glGetUniformLocation(id, name.toStringz());
			if (location == -1)
				throw new GraphicsException(format!"Uniform (%s) location could not be retrieved."(name));
			mixin(q{glUniformMatrix} ~ (R == C ? R.to!string : R.to!string ~ "x" ~ C.to!string) ~ q{fv(uniformTable[name] = location, 1, true, value.v.ptr);});
		}
	}
	
	unittest
	{
		Shader s;
		static assert(__traits(compiles, s.SetUniform("m", mat2f())));
		static assert(__traits(compiles, s.SetUniform("m", mat3f())));
		static assert(__traits(compiles, s.SetUniform("m", mat4f())));
		static assert(__traits(compiles, s.SetUniform("m", mat2x3f())));
		static assert(__traits(compiles, s.SetUniform("m", mat2x4f())));
		static assert(__traits(compiles, s.SetUniform("m", mat3x2f())));
		static assert(__traits(compiles, s.SetUniform("m", mat3x4f())));
		static assert(__traits(compiles, s.SetUniform("m", mat4x2f())));
		static assert(__traits(compiles, s.SetUniform("m", mat4x3f())));
	}
}