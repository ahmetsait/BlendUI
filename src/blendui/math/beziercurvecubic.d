/* Licensed under the MIT/X11 license.
 * Copyright (c) 2006-2008 the OpenTK Team.
 * This notice may not be removed from any source distribution.
 * See license.txt for licensing details.
 * 
 * Contributions by Georg Wächter and Ahmet Sait Koçak.
 */
module blendui.math.beziercurvecubic;

import std.traits : isFloatingPoint;
import gfm.math.vector : vec2;

///Represents a cubic bezier curve with two anchor and two control points.
public struct BezierCurveCubic(T) if(isFloatingPoint!T)
{
	///Start anchor point.
	public vec2!T startAnchor;

	///End anchor point.
	public vec2!T endAnchor;

	///First control point, controls the direction of the curve start.
	public vec2!T firstControlPoint;

	///Second control point, controls the direction of the curve end.
	public vec2!T secondControlPoint;

	///Gets or sets the parallel value.
	///This value defines whether the curve should be calculated as a
	///parallel curve to the original bezier curve. A value of 0 represents
	///the original curve, 5 i.e. stands for a curve that has always a distance
	///of 5 to the orignal curve at any point.
	public T parallel;

	///Constructs a new BezierCurveCubic.
	///Params:
	///	startAnchor			= The start anchor point.
	///	endAnchor			= The end anchor point.
	///	firstControlPoint	= The first control point.
	///	secondControlPoint	= The second control point.
	public this(vec2!T startAnchor, vec2!T endAnchor, vec2!T firstControlPoint, vec2!T secondControlPoint)
	{
		this.startAnchor = startAnchor;
		this.endAnchor = endAnchor;
		this.firstControlPoint = firstControlPoint;
		this.secondControlPoint = secondControlPoint;
		this.parallel = 0.0f;
	}

	///Constructs a new BezierCurveCubic.
	///Params:
	///	parallel			= The parallel value.
	///	startAnchor			= The start anchor point.
	///	endAnchor			= The end anchor point.
	///	firstControlPoint	= The first control point.
	///	secondControlPoint	= The second control point.
	public this(T parallel, vec2!T startAnchor, vec2!T endAnchor, vec2!T firstControlPoint, vec2!T secondControlPoint)
	{
		this.parallel = parallel;
		this.startAnchor = startAnchor;
		this.endAnchor = endAnchor;
		this.firstControlPoint = firstControlPoint;
		this.secondControlPoint = secondControlPoint;
	}

	///Calculates the point with the specified t.
	///Params:
	///	t	= The t value, between 0.0 and 1.0.
	///Returns: Resulting point.
	public vec2!T CalculatePoint(T t)
	{
		vec2!T r = vec2!T();
		T c = 1.0f - t;

		r.X = (startAnchor.X * c * c * c) + (firstControlPoint.X * 3 * t * c * c) + (secondControlPoint.X * 3 * t * t * c)
			+ endAnchor.X * t * t * t;
		r.Y = (startAnchor.Y * c * c * c) + (firstControlPoint.Y * 3 * t * c * c) + (secondControlPoint.Y * 3 * t * t * c)
			+ endAnchor.Y * t * t * t;

		if (parallel == 0.0f)
			return r;

		vec2!T perpendicular = vec2!T();

		if (t == 0.0f)
			perpendicular = firstControlPoint - startAnchor;
		else
			perpendicular = r - CalculatePointOfDerivative(t);

		return r + vec2!T.Normalize(perpendicular).PerpendicularRight * parallel;
	}

	///Calculates the point with the specified t of the derivative of this function.
	///Params:
	///	t	= The t, value between 0.0f and 1.0f.
	///Returns: Resulting point.
	private vec2!T CalculatePointOfDerivative(T t)
	{
		vec2!T r = vec2!T();
		T c = 1.0f - t;

		r.X = (c * c * startAnchor.X) + (2 * t * c * firstControlPoint.X) + (t * t * secondControlPoint.X);
		r.Y = (c * c * startAnchor.Y) + (2 * t * c * firstControlPoint.Y) + (t * t * secondControlPoint.Y);

		return r;
	}

	///Calculates the length of this bezier curve. The precision
	///gets better when the `precision` parameter gets smaller.
	///Params:
	///	precision	= The precision.
	///Returns: Length of curve.
	public T CalculateLength(T precision)
	{
		T length = 0.0f;
		vec2!T old = CalculatePoint(0.0f);

		for (T i = precision; i < (1.0f + precision); i += precision)
		{
			vec2!T n = CalculatePoint(i);
			length += (n - old).Length;
			old = n;
		}

		return length;
	}
}
