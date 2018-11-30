/* Licensed under the MIT/X11 license.
 * Copyright (c) 2006-2008 the OpenTK Team.
 * This notice may not be removed from any source distribution.
 * See license.txt for licensing details.
 * 
 * Contributions by Georg Wächter and Ahmet Sait Koçak.
 */
module blendui.math.beziercurvequadric;

import std.traits : isFloatingPoint;

import gfm.math.vector : vec2;

import blendui.core;

///Represents a quadric bezier curve with two anchor and one control point.
public struct BezierCurveQuadric(T) if(isFloatingPoint!T)
{
	///Start anchor point.
	public vec2!T startAnchor;

	///End anchor point.
	public vec2!T endAnchor;

	///Control point, controls the direction of both endings of the curve.
	public vec2!T controlPoint;

	///The parallel value.
	///This value defines whether the curve should be calculated as a
	///parallel curve to the original bezier curve. A value of 0 represents
	///the original curve, 5 i.e. stands for a curve that has always a distance
	///of 5 to the orignal curve at any point.
	public T parallel;

	///Constructs a new BezierCurveQuadric.
	///Params:
	///	startAnchor		= The start anchor.
	///	endAnchor		= The end anchor.
	///	controlPoint	= The control point.
	public this(vec2!T startAnchor, vec2!T endAnchor, vec2!T controlPoint)
	{
	    this.startAnchor = startAnchor;
	    this.endAnchor = endAnchor;
	    this.controlPoint = controlPoint;
	    this.parallel = 0.0f;
	}

	///Constructs a new BezierCurveQuadric.
	///Params:
	///	parallel		= The parallel value.
	///	startAnchor		= The start anchor.
	///	endAnchor		= The end anchor.
	///	controlPoint	= The control point.
	public this(T parallel, vec2!T startAnchor, vec2!T endAnchor, vec2!T controlPoint)
	{
	    this.parallel = parallel;
	    this.startAnchor = startAnchor;
	    this.endAnchor = endAnchor;
	    this.controlPoint = controlPoint;
	}

	///Calculates the point with the specified t.
	///Params:
	///	t	= The t value, between 0.0f and 1.0f.
	///Returns: Resulting point.
	public vec2!T CalculatePoint(T t)
	{
	    vec2!T r = vec2!T();
	    T c = 1.0f - t;

	    r.X = (c * c * startAnchor.X) + (2 * t * c * controlPoint.X) + (t * t * endAnchor.X);
	    r.Y = (c * c * startAnchor.Y) + (2 * t * c * controlPoint.Y) + (t * t * endAnchor.Y);

	    if (parallel == 0.0f)
	        return r;

	    vec2!T perpendicular = vec2!T();

	    if (t == 0.0f)
	        perpendicular = controlPoint - startAnchor;
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

	    r.X = (1.0f - t) * startAnchor.X + t * controlPoint.X;
	    r.Y = (1.0f - t) * startAnchor.Y + t * controlPoint.Y;

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
