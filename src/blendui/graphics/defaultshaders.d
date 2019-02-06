module blendui.graphics.defaultshaders;

import blendui.graphics.shader;

Shader shaderQuadratic, shaderTrigonometric;

public:

Shader shaderSimple() @property
{
	static bool created = false;
	static Shader shader;
	if (!created)
	{
		shader = new Shader(vert_Simple, frag_Simple);
		created = true;
	}
	return shader;
}

string vert_Simple = `
	#version 330 core

	layout (location = 0) in vec2 vPosition;

	uniform int width;
	uniform int height;

	uniform vec4 color;

	uniform vec2 offset = vec2(0, 0);
	uniform float rotation = 0;
	uniform float scale = 1;

	float map(float value, float min1, float max1, float min2, float max2)
	{
		return (value - min1) * (max2 - min2) / (max1 - min1) + min2;
	}
	
	vec2 rotate(vec2 v, float a)
	{
		float s = sin(a);
		float c = cos(a);
		mat2 m = mat2(c, s, -s, c);
		return m * v;
	}

	void main()
	{
		vec2 pos = vPosition.xy;
		pos = rotate(pos, rotation);
		pos *= scale;
		pos += offset;
		pos = vec2(map(pos.x, 0, width, -1, 1), map(pos.y, 0, height, 1, -1));
		gl_Position = vec4(pos, 0.0, 1.0);
	}
`;

string frag_Simple = `
	#version 330 core

	uniform vec4 color;

	out vec4 fragColor;

	void main()
	{
		fragColor = color;
	}
`;

string geo_QuadraticBezierRound = `
	#version 330 core
	layout (triangles) in;
	layout (triangle_strip, max_vertices = 48) out;

	uniform int segments;
	
	void main()
	{
		int _segments = segments > 16 ? 16 : segments;

		vec4 pos0 = gl_in[0].gl_Position;
		vec4 pos1 = gl_in[1].gl_Position;
		vec4 pos2 = gl_in[2].gl_Position;

		float t = float(1) / float(_segments);
		vec4 start = mix(pos0, pos1, t);
		vec4 end = mix(pos1, pos2, t);
		vec4 current = mix(start, end, t);
		for (int i = 1; i < _segments; i++)
		{
			t = float(i + 1) / float(_segments);
			start = mix(pos0, pos1, t);
			end = mix(pos1, pos2, t);
			vec4 next = mix(start, end, t);
			
			gl_Position = pos0;
			EmitVertex();
			
			gl_Position = current;
			EmitVertex();
			
			gl_Position = next;
			EmitVertex();
			
			EndPrimitive();
			
			current = next;
		}
	}
`;

string geo_TrigonometricRound = `
	#version 330 core
	layout (points) in;
	layout (triangle_strip, max_vertices = 48) out;

	uniform int width;
	uniform int height;

	uniform float rotation = 0;
	uniform float scale = 1;

	uniform int segments;
	uniform float angle;
	uniform float radius;

	const float PI = 3.1415926535897932384626433832795;

	void main()
	{
		int _segments = segments > 16 ? 16 : segments;

		vec4 pos = gl_in[0].gl_Position;
		vec2 r = radius / vec2(width, height) * scale;

		float a = angle + rotation;
		vec2 edge = pos.xy + vec2(cos(a) * r.x, sin(a) * r.y);
		a = angle + rotation + float(1) / _segments * PI / 2;
		vec2 current = pos.xy + vec2(cos(a) * r.x, sin(a) * r.y);
		for (int i = 1; i < _segments; i++)
		{
			a = angle + rotation + float(i + 1) / _segments * PI / 2;
			vec2 next = pos.xy + vec2(cos(a) * r.x, sin(a) * r.y);

			gl_Position = vec4(edge, 0, 1);
			EmitVertex();
			
			gl_Position = vec4(current, 0, 1);
			EmitVertex();
			
			gl_Position = vec4(next, 0, 1);
			EmitVertex();
			
			EndPrimitive();

			current = next;
		}
	}
`;