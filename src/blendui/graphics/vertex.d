module blendui.graphics.vertex;

import std.traits;

import gfm.math.vector;

public struct Vertex(P = vec3f, N = vec3f, T = vec2f, C = vec4f)
{
	static if (!is(P == void))
		public P position;
	static if (!is(N == void))
		public N normal;
	static if (!is(T == void))
		public T texCoord;
	static if (!is(C == void))
		public C color;
}

public
{
	alias VertexP2 = Vertex!(vec2f, void, void, void);
	alias VertexP2T2 = Vertex!(vec2f, void, vec2f, void);
	alias VertexP2C4 = Vertex!(vec2f, void, void, vec4f);
	alias VertexP2T2C4 = Vertex!(vec2f, void, vec2f, vec4f);
	alias VertexP2C3 = Vertex!(vec2f, void, void, vec3f);
	alias VertexP2T2C3 = Vertex!(vec2f, void, vec2f, vec3f);
}
