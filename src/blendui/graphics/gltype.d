module blendui.graphics.gltype;

import std.traits;

import blendui.graphics.gl;
import blendui.util;

import gfm.math.vector;
import gfm.math.matrix;

public:

template toGLType(T)
{
	enum toGLType = glTypes[dTypes.indexOf(T.stringof)];
}

template toGLSuffix(T)
{
	enum toGLSuffix = glSuffixes[dTypes.indexOf(T.stringof)];
}

template isGLType(T)
{
	enum bool isGLType = dTypes.contains(T.stringof);
}

immutable dTypes = [
	"byte",
	"short",
	"int",
	"float",
	"double",
	"ubyte",
	"ushort",
	"uint",
];

immutable glTypes = [
	GL_BYTE,
	GL_SHORT,
	GL_INT,
	GL_FLOAT,
	GL_DOUBLE,
	GL_UNSIGNED_BYTE,
	GL_UNSIGNED_SHORT,
	GL_UNSIGNED_INT,
];

immutable glSuffixes = [
	"b",
	"s",
	"i",
	"f",
	"d",
	"ub",
	"us",
	"ui",
];
