﻿module blendui.graphics.shader;

import std.conv : to;
import std.string : toStringz, fromStringz;
import std.format : format;

import blendui.core;
import blendui.util;
import blendui.graphics.gl;
import blendui.graphics.gltype;

import gfm.math.vector;
import gfm.math.matrix;

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
			GLsizei infoLen;
			glGetShaderiv(prog, GL_INFO_LOG_LENGTH, &infoLen);
			char[] error = new char[infoLen];
			glGetShaderInfoLog(prog, infoLen, &infoLen, error.ptr);
			throw new GraphicsException(("Failed to link program: " ~ error[0 .. infoLen]).idup);
		}
		id = prog;
	}

	private static uint CompileShader(string source, GLenum type)
	{
		uint shader = glCreateShader(type);
		auto src = source.toStringz();
		assert(source.length > int.max);
		int len = cast(int)source.length;
		glShaderSource(shader, 1, &src, &len);
		glCompileShader(shader);

		int success;
		glGetShaderiv(shader, GL_COMPILE_STATUS, &success);
		if (success == 0)
		{
			int infoLen;
			glGetShaderiv(shader, GL_INFO_LOG_LENGTH, &infoLen);
			char[] error = new char[infoLen];
			glGetShaderInfoLog(shader, infoLen, &infoLen, error.ptr);
			throw new GraphicsException(("Failed to compile shader: " ~ error[0 .. infoLen]).idup);
		}
		return shader;
	}

	public void Use()
	{
		glUseProgram(id);
	}

	public void SetUniform(T)(string name, T value) if (isGLType!T)
	{
		enum string suffix = toGLSuffix!T;
		int* locationPtr = name in uniformTable;
		if (locationPtr != null)
			mixin("glUniform1" ~ suffix ~ "(*locationPtr, value);");
		else
		{
			int location = glGetUniformLocation(id, name.toStringz());
			if (location == -1)
				throw new GraphicsException(format!"Uniform (%s) location could not be retrieved."(name));
			mixin("glUniform1" ~ suffix ~ "(uniformTable[name] = location, value);");
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

	public void SetUniform(T, int N)(string name, Vector!(T, N) value) if (isGLType!T)
	{
		static assert(N >= 2 && N <= 4, "Vector length out of range");

		enum string suffix = toGLSuffix!T;
		int* locationPtr = name in uniformTable;
		if (locationPtr != null)
			mixin("glUniform" ~ N.to!string ~ suffix ~ "v(*locationPtr, 1, value.v.ptr);");
		else
		{
			int location = glGetUniformLocation(id, name.toStringz());
			if (location == -1)
				throw new GraphicsException(format!"Uniform (%s) location could not be retrieved."(name));
			mixin("glUniform" ~ N.to!string ~ suffix ~ "v(uniformTable[name] = location, 1, value.v.ptr);");
		}
	}
	
	unittest
	{
		Shader s;
		static assert(__traits(compiles, s.SetUniform("v", vec2i(1, 2))));
		static assert(__traits(compiles, s.SetUniform("v", vec3ui(3, 4, 5))));
		static assert(__traits(compiles, s.SetUniform("v", vec4f(6, 7, 8, 9))));
	}

	public void SetUniform(T, int R, int C)(string name, Matrix!(T, R, C) value)
	{
		static assert(R >= 2 && R <= 4 && C >= 2 && C <= 4, "Matrix dimension(s) out of range");

		enum string suffix = toGLSuffix!T;
		int* locationPtr = name in uniformTable;
		if (locationPtr != null)
			mixin("glUniformMatrix" ~ (R == C ? R.to!string : C.to!string ~ "x" ~ R.to!string) ~ suffix ~ "v(*locationPtr, 1, true, value.v.ptr);");
		else
		{
			int location = glGetUniformLocation(id, name.toStringz());
			if (location == -1)
				throw new GraphicsException(format!"Uniform (%s) location could not be retrieved."(name));
			mixin("glUniformMatrix" ~ (R == C ? R.to!string : C.to!string ~ "x" ~ R.to!string) ~ suffix ~ "v(uniformTable[name] = location, 1, true, value.v.ptr);");
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
