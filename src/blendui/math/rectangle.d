//TODO: unittest
module blendui.math.rectangle;

import std.algorithm.comparison : min, max;
import std.traits : isNumeric;
import gfm.math.vector : vec4;
import blendui.util;
import blendui.math.point;
import blendui.math.size;

///Represents a rectangular region on a two-dimensional plane.
public struct Rectangle(T) if(isNumeric!T)
{
	public Point!T location;	///The top-left corner of the Rectangle.
	public Size!T size;			///The width and height of the Rectangle.

	///Constructs a new Rectangle instance.
	///Params:
	///	location	= The top-left corner of the Rectangle.
	///	size		= The width and height of the Rectangle.
	public this(Point!T location, Size!T size)
	{
		this.location = location;
		this.size = size;
	}
	
	///Constructs a new Rectangle instance.
	///Params:
	///	x		= The x coordinate of the Rectangle.
	///	y		= The y coordinate of the Rectangle.
	///	width	= The width of the Rectangle.
	///	height	= The height of the Rectangle. 
	public this(T x, T y, T width, T height)
	{
		this(Point!T(x, y), Size!T(width, height));
	}
	
	///Makes the current rectangle instance normalized
	///by taking absolute values of width and height
	///then adjusts location.
	public void normalize()
	{
		if(width < 0)
		{
			x += width;
			width = -width;
		}
		if(height < 0)
		{
			y += height;
			height = -height;
		}
	}
	
	///Returns a normalized instance of the current rectangle
	///by taking absolute values of width and height
	///then adjusts location.
	public Rectangle!T normalized()
	{
		Rectangle!T newSize = this;
		if(newSize.width < 0)
		{
			newSize.x += newSize.width;
			newSize.width = -newSize.width;
		}
		if(newSize.height < 0)
		{
			newSize.y += newSize.height;
			newSize.height = -newSize.height;
		}
		return newSize;
	}

	//This doesn't work: "Error: need `this` for `x` of type `T`"
	//alias x = location.x;

	//HACK: Need to return ref because: https://issues.dlang.org/show_bug.cgi?id=8006

	///Gets the x coordinate of the Rectangle.
	public ref T x() @property
	{
		return location.x;
	}

	///Sets the x coordinate of the Rectangle.
	public T x(T value) @property
	{
		return location.x = value;
	}

	///Gets the y coordinate of the Rectangle.
	public ref T y() @property
	{
		return location.y;
	}

	///Sets the y coordinate of the Rectangle.
	public T y(T value) @property
	{
		return location.y = value;
	}

	///Gets the width of the Rectangle.
	public ref T width() @property
	{
		return size.width;
	}
	
	///Sets the width of the Rectangle.
	public T width(T value) @property
	{
		return size.width = value;
	}
	
	///Gets the height of the Rectangle.
	public ref T height() @property
	{
		return size.height;
	}
	
	///Sets the height of the Rectangle.
	public T height(T value) @property
	{
		return size.height = value;
	}
	
	///Gets the x coordinate of the left edge of this Rectangle.
	public T left() @property { return x; }
	
	///Sets the x coordinate of the left edge of this Rectangle.
	public T left(T value) @property { width += x - value; return x = value; }
	
	///Gets the x coordinate of the right edge of this Rectangle.
	public T right() @property { return x + width; }

	///Sets the x coordinate of the right edge of this Rectangle.
	public T right(T value) @property { width = value - x; return right; }
	
	///Gets the y coordinate of the top edge of this Rectangle.
	public T top() @property { return y; }

	///Sets the y coordinate of the top edge of this Rectangle.
	public T top(T value) @property { height += y - value; return y = value; }
	
	///Gets the y coordinate of the bottom edge of this Rectangle.
	public T bottom() @property { return y + height; }
	
	///Sets the y coordinate of the bottom edge of this Rectangle.
	public T bottom(T value) @property { height = value - y; return bottom; }

	///Gets a bool that indicates whether this
	///Rectangle is equal to the empty Rectangle.
	public bool isEmpty() @property
	{
		return location.isEmpty && size.isEmpty;
	}

	///Defines the empty Rectangle.
	public static const Rectangle!T zero = Rectangle!T();

	///Defines the empty Rectangle.
	public static const Rectangle!T empty = Rectangle!T();

	///Constructs a new instance with the specified edges.
	///Params:
	///	left	= The left edge of the Rectangle.
	///	top		= The top edge of the Rectangle.
	///	right	= The right edge of the Rectangle.
	///	bottom	= The bottom edge of the Rectangle.
	public static Rectangle!T fromLTRB(T left, T top, T right, T bottom)
	{
		return Rectangle!T(Point!T(left, top), Size!T(right - left, bottom - top));
	}

	///Tests whether this instance contains the specified x, y coordinates.
	///The left and top edges are inclusive. The right and bottom edges
	///are exclusive.
	///Params:
	///	x	= The x coordinate to test.
	///	y	= The y coordinate to test.
	public bool contains(T x, T y)
	{
		return x >= left && x < right && y >= top && y < bottom;
	}

	///Tests whether this instance contains the specified Point!T.
	///The left and top edges are inclusive. The right and bottom edges
	///are exclusive.
	///Params:
	///	point	= The Point!T to test.
	public bool contains(Point!T point)
	{
		return point.x >= left && point.x < right && point.y >= top && point.y < bottom;
	}

	///Tests whether this instance contains the specified Rectangle.
	///The left and top edges are inclusive. The right and bottom edges
	///are exclusive.
	///Params:
	///	rect	= The Rectangle to test.
	public bool contains(Rectangle!T rect)
	{
		return contains(rect.location) && contains(rect.location + rect.size);
	}
	
	///Union the specified rectangle 'a' and 'b'.
	public static Rectangle!T unionOf(Rectangle!T a, Rectangle!T b)
	{
		import std.algorithm.comparison : min, max;
		T x1 = min(a.x, b.x);
		T x2 = max(a.x + a.width, b.x + b.width);
		T y1 = min(a.y, b.y);
		T y2 = max(a.y + a.height, b.y + b.height);
		
		return Rectangle(x1, y1, x2 - x1, y2 - y1); 
	}

	public static bool intersects(Rectangle!T a, Rectangle!T b)
	{
		Rectangle!T r = intersectionOf(a, b);
		return r.width > 0 && r.height > 0;
	}

	///Calculate intersection of the specified rectangle 'a' and 'b'.
	///If given rectangles do not intersect, a rectangle with negative
	///size is returned.
	public static Rectangle!T intersectionOf(Rectangle!T a, Rectangle!T b)
	{
		import std.algorithm.comparison : min, max;

		return Rectangle!T.fromLTRB(max(a.left, b.left), max(a.top, b.top), min(a.right, b.right), min(a.bottom, b.bottom));
	}

	///Indicates whether this instance is equal to the specified Rectangle.
	public bool opEquals(Rectangle!T other)
	{
		return location == other.location && size == other.size;
	}

	///Returns a $(D string) that describes this instance.
	public string toString()
	{
		import std.string : format;
		return format("{%s; %s}", location, size);
	}

	public vec4!T toVector()
	{
		return vec4!T(x, y, width, height);
	}

	import derelict.sdl2.types : SDL_Rect;

	public SDL_Rect toSDL_Rect()
	{
		return SDL_Rect(x, y, width, height);
	}

	public static Rectangle!int fromSDL_Rect(SDL_Rect rect)
	{
		return Rectangle!int(rect.x, rect.y, rect.w, rect.h);
	}

	version(Windows)
	{
		import core.sys.windows.windef : RECT;

		public RECT toRECT()
		{
			return RECT(left, top, right, bottom);
		}

		public static Rectangle!int fromRECT(RECT rect)
		{
			return fromLTRB(rect.left, rect.top, rect.right, rect.bottom);
		}
	}
	
	alias toVector this;
}
