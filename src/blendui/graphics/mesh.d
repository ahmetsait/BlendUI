module blendui.graphics.mesh;

import std.format;
import std.range;
import std.traits;

import blendui.core;
import blendui.graphics.gl;
import blendui.graphics.gltype;
import blendui.graphics.vertex;

import gfm.math.vector;

import containers.dynamicarray;

/// $(D
/// 	struct Vertex
/// 	{
/// 		public vec3f position;
/// 		public vec3f normal;
/// 		public vec2f texCoord;
/// 		public vec4f color;
/// 	}
/// 	layout (location = 0) in vec3 vPosition;
/// 	layout (location = 1) in vec3 vNormal;
/// 	layout (location = 2) in vec2 vTexCoord;
/// 	layout (location = 3) in vec4 vColor;
/// )
public final class Mesh(V, I = uint) : IDisposable
	if (isInstanceOf!(Vertex, V) && isUnsigned!I)
{
	private uint vao, vbo, ebo;
	public V[] vertices;
	public I[] indices;
	
	public this()
	{
		glGenVertexArrays(1, &vao);
		glGenBuffers(1, &vbo);
		glGenBuffers(1, &ebo);

		glBindVertexArray(vao);
		glBindBuffer(GL_ARRAY_BUFFER, vbo);

		enum stride = V.sizeof;

		static if (hasMember!(V, "position"))
		{
			glEnableVertexAttribArray(0);
			glVertexAttribPointer(0, V.position.v.length, toGLType!(V.position.element_t), GL_FALSE, stride, cast(void*)V.position.offsetof);
		}
		
		static if (hasMember!(V, "normal"))
		{
			glEnableVertexAttribArray(1);
			glVertexAttribPointer(1, V.normal.v.length, toGLType!(V.position.element_t), GL_FALSE, stride, cast(void*)V.normal.offsetof);
		}

		static if (hasMember!(V, "texCoord"))
		{
			glEnableVertexAttribArray(2);
			glVertexAttribPointer(2, V.texCoord.v.length, toGLType!(V.position.element_t), GL_FALSE, stride, cast(void*)V.texCoord.offsetof);
		}

		static if (hasMember!(V, "color"))
		{
			glEnableVertexAttribArray(3);
			glVertexAttribPointer(3, V.color.v.length, toGLType!(V.position.element_t), GL_FALSE, stride, cast(void*)V.color.offsetof);
		}

		glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, ebo);
		glBindVertexArray(0);
	}
	
	public this(V[] vertices, I[] indices, GLenum hint = GL_STATIC_DRAW)
	{
		this();
		this.vertices = vertices;
		this.indices = indices;
		reload(hint);
	}
	
	public void reload(GLenum hint = GL_STATIC_DRAW, bool vertex = true, bool index = true)
	{
		enum stride = V.sizeof;

		glBindVertexArray(vao);
		if (vertex)
		{
			if (vertices == null)
				throw new ArgumentNullException("Vertex array (vertices) cannot be null.");
			glBindBuffer(GL_ARRAY_BUFFER, vbo);
			glBufferData(GL_ARRAY_BUFFER, vertices.length * stride, vertices.ptr, hint);
			int loadedVertexBufferSize;
			glGetBufferParameteriv(GL_ARRAY_BUFFER, GL_BUFFER_SIZE, &loadedVertexBufferSize);
			if (vertices.length * stride != loadedVertexBufferSize)
				throw new GraphicsException("Vertex buffer not uploaded correctly");
		}
		
		if (index)
		{
			if (vertices == null)
				throw new ArgumentNullException("Index array (indices) cannot be null.");
			glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, ebo);
			glBufferData(GL_ELEMENT_ARRAY_BUFFER, indices.length * I.sizeof, indices.ptr, hint);
			int loadedIndexBufferSize;
			glGetBufferParameteriv(GL_ELEMENT_ARRAY_BUFFER, GL_BUFFER_SIZE, &loadedIndexBufferSize);
			if (indices.length * I.sizeof != loadedIndexBufferSize)
				throw new GraphicsException("Index buffer not uploaded correctly");
		}
		glBindVertexArray(0);
	}
	
	public bool checkBufferIntegration()
	{
		foreach (index; indices)
			if (index >= vertices.length)
				return false;
		return true;
	}
	
	public void draw(GLenum primitive = GL_TRIANGLES)
	{
		glBindVertexArray(vao);
		glDrawElements(primitive, cast(GLsizei)indices.length, toGLType!I, cast(void*)0);
		glBindVertexArray(0);
	}

	//region IDisposable implementation
	protected bool _disposed = false; //To detect redundant calls
	public bool disposed() @property
	{
		return _disposed;
	}
	
	protected void dispose(bool disposing)
	{
		if (!_disposed)
		{
			if (disposing)
			{
				//Dispose managed state (managed objects).
				destroy(vertices);
				destroy(indices);
			}
			
			//Free unmanaged resources (unmanaged objects), set large fields to null.
			if (vbo != 0)
			{
				glDeleteBuffers(1, &vbo);
				vbo = 0;
			}
			if (ebo != 0)
			{
				glDeleteBuffers(1, &ebo);
				ebo = 0;
			}
			if (vao != 0)
			{
				glDeleteVertexArrays(1, &vao);
				vao = 0;
			}

			_disposed = true;
		}
	}
	
	//Override a destructor only if Dispose(bool disposing) above has code to free unmanaged resources.
	public ~this()
	{
		//Do not change this code. Put cleanup code in Dispose(bool disposing) above.
		dispose(false);
	}
	
	//This code added to correctly implement the disposable pattern.
	public void dispose()
	{
		import core.memory : GC;
		//Do not change this code. Put cleanup code in Dispose(bool disposing) above.
		dispose(true);
		//Uncomment the following line if the destructor is overridden above.
		GC.clrAttr(cast(void*)this, GC.BlkAttr.FINALIZE);
		//FIXME: D runtime currently doesn't give a shit about GC.BlkAttr.FINALIZE so it's actually pointless
	}
	//endregion
}
