/* Licensed under the MIT/X11 license.
 * Copyright (c) 2006-2008 the OpenTK Team.
 * This notice may not be removed from any source distribution.
 * See license.txt for licensing details.
 * 
 * Contributions by Georg Wächter and Ahmet Sait Koçak.
 */
module blendui.math.beziercurve;

import std.range : isInputRange, isInfinite, ElementType;
import std.traits : isFloatingPoint;

import gfm.math.vector : vec2;

import blendui.core;
import blendui.math.mathhelper;

///Represents a bezier curve with as many points as you want.
public struct BezierCurve(T) if(isFloatingPoint!T)
{
    ///The points of this curve.
    ///First point and the last points represent the anchor points.
    public vec2!T[] points;

    ///The parallel value.
    ///This value defines whether the curve should be calculated as a
    ///parallel curve to the original bezier curve. A value of 0 represents
    ///the original curve, 5 i.e. stands for a curve that has always a distance
    ///of 5 to the orignal curve at any point.
    public T parallel;

    ///Constructs a new BezierCurve.
    ///Params:
    ///	points	= The points.
	public this(U)(U points) if(isInputRange!U && !isInfinite!U && is(ElementType!U : vec2!T))
    {
        if (points is null)
			throw new ArgumentNullException("Must point to a valid range of vec2!T structures.", points.stringof);

		for(; !points.empty; points.popFront())
        	this.points ~= points.front;
        this.parallel = 0.0f;
    }

    ///Constructs a new <see cref="BezierCurve.
    ///Params:
    ///	points	= The points.
    public this(vec2!T[] points ...)
    {
        if (points is null)
			throw new ArgumentNullException("Must point to a valid range of vec2!T structures.", points.stringof);

		this.points = points.dup;
        this.parallel = 0.0f;
    }

    ///Constructs a new BezierCurve.
    ///Params:
    ///	parallel	= The parallel value.
    ///	points		= The points.
    public this(T parallel, vec2!T[] points ...)
    {
        if (points is null)
			throw new ArgumentNullException("Must point to a valid range of vec2!T structures.", points.stringof);

		this.points = points.dup;
        this.parallel = parallel;
    }

    ///Constructs a new BezierCurve.
    ///Params:
    ///	parallel	= The parallel value.
    ///	points		= The points.
	public this(U)(T parallel, U points) if(isInputRange!U && !isInfinite!U && is(ElementType!U : vec2!T))
    {
        if (points is null)
			throw new ArgumentNullException("Must point to a valid range of vec2!T structures.", points.stringof);

		for(; !points.empty; points.popFront())
			this.points ~= points.front;
        this.parallel = parallel;
    }

    ///Calculates the point with the specified t.
    ///Params:
    ///	t	= The t value, between 0.0f and 1.0f.
    ///Returns: Resulting point.
    public vec2!T CalculatePoint(T t)
    {
        return BezierCurve.CalculatePoint(points, t, parallel);
    }

    ///Calculates the length of this bezier curve.
    ///The precision gets better as the `precision`
    ///value gets smaller.
    ///Params:
    ///	precision	= The precision.
    ///Returns: Length of curve.
    public T CalculateLength(T precision)
    {
        return BezierCurve.CalculateLength(points, precision, parallel);
    }

    ///Calculates the length of the specified bezier curve.
    ///The precision gets better as the `precision`
    ///value gets smaller.
    ///Params:
    ///	points		= The points.
    ///	precision	= The precision.
    ///Returns: Length of curve.
	public static T CalculateLength(U)(U points, T precision) if(isInputRange!U && !isInfinite!U && is(ElementType!U : vec2!T))
    {
        return BezierCurve.CalculateLength(points, precision, 0.0f);
    }

    ///Calculates the length of the specified bezier curve.
    ///The precision gets better as the `precision`
    ///value gets smaller.
    ///The `parallel` parameter defines whether the curve should be calculated as a
    ///parallel curve to the original bezier curve. A value of 0 represents
    ///the original curve, 5 represents a curve that has always a distance
    ///of 5 to the orignal curve.
    ///Params:
    ///	points		= The points.
    ///	precision	= The precision value.
    ///	parallel	= The parallel value.
    ///Returns: Length of curve.
	public static T CalculateLength(U)(U points, T precision, T parallel) if(isInputRange!U && !isInfinite!U && is(ElementType!U : vec2!T))
    {
        T length = 0.0f;
        vec2!T old = BezierCurve.CalculatePoint(points, 0.0f, parallel);

        for (T i = precision; i < (1.0f + precision); i += precision)
        {
            vec2!T n = CalculatePoint(points, i, parallel);
            length += (n - old).Length;
            old = n;
        }

        return length;
    }

    ///Calculates the point on the given bezier curve with the specified t parameter.
    ///Params:
    ///	points	= The points.
    ///	t		= The t parameter, a value between 0.0f and 1.0f.
    ///Returns: Resulting point.
	public static vec2!T CalculatePoint(U)(U points, T t) if(isInputRange!U && !isInfinite!U && is(ElementType!U : vec2!T))
    {
        return BezierCurve.CalculatePoint(points, t, 0.0f);
    }

    ///Calculates the point on the given bezier curve with the specified t parameter.
    ///The `parallel` parameter defines whether the curve should be calculated as a
    ///parallel curve to the original bezier curve. A value of 0 represents
    ///the original curve, 5 represents a curve that has always a distance
    ///of 5 to the orignal curve.
    ///Params:
    ///	points		= The points.
    ///	t			= The t parameter, a value between 0.0f and 1.0f.
    ///	parallel	= The parallel value.
    ///Returns: Resulting point.
	public static vec2!T CalculatePoint(U)(U points, T t, T parallel) if(isInputRange!U && !isInfinite!U && is(ElementType!U : vec2!T))
    {
        vec2!T r = vec2!T();
        double c = 1.0 - cast(double)t;
        T temp;
        int i = 0;

		foreach (vec2!T pt; points)
        {
			temp = cast(T)MathHelper.BinomialCoefficient(points.Count - 1, i) * cast(T)(System.Math.Pow(t, i) *
                    System.Math.Pow(c, (points.Count - 1) - i));

            r.X += temp * pt.X;
            r.Y += temp * pt.Y;
            i++;
        }

        if (parallel == 0.0f)
            return r;

        vec2!T perpendicular = vec2!T();

        if (t != 0.0f)
            perpendicular = r - BezierCurve.CalculatePointOfDerivative(points, t);
        else
            perpendicular = points[1] - points[0];

        return r + vec2!T.Normalize(perpendicular).PerpendicularRight * parallel;
    }

    ///Calculates the point with the specified t of the derivative of the given 
	///bezier function.
    ///Params:
    ///	points	= The points.
    ///	t		= The t parameter, value between 0.0f and 1.0f.
    ///Returns: Resulting point.
	private static vec2!T CalculatePointOfDerivative(U)(U points, T t) if(isInputRange!U && !isInfinite!U && is(ElementType!U : vec2!T))
    {
        vec2!T r = vec2!T();
        double c = 1.0 - cast(double)t;
        T temp;
        int i = 0;

		foreach (vec2!T pt; points)
        {
			temp = cast(T)MathHelper.BinomialCoefficient(points.Count - 2, i) * cast(T)(System.Math.Pow(t, i) *
                    System.Math.Pow(c, (points.Count - 2) - i));

            r.X += temp * pt.X;
            r.Y += temp * pt.Y;
            i++;
        }

        return r;
    }
}
