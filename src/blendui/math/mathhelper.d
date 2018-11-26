/* Licensed under the MIT/X11 license.
 * Copyright (c) 2006-2008 the OpenTK Team.
 * This notice may not be removed from any source distribution.
 * See license.txt for licensing details.
 *
 * Contributions by Andy Gill, James Talton, Georg Wächter and Ahmet Sait Koçak.
 */
module blendui.math.mathhelper; //TODO: Add unittests

import std.math : PI;
import std.traits : isNumeric, isIntegral, isFloatingPoint;

///Contains common mathematical functions and constants.
public static class MathHelper
{
	///Defines the value of Pi as a $(D float).
	public enum float Pi = PI; //Seems like degrading floating point conversions are totally fine... Meh

	///Defines the value of Pi divided by two as a $(D float).
	public enum float PiOver2 = PI / 2;

	///Defines the value of Pi divided by three as a $(D float).
	public enum float PiOver3 = PI / 3;

	///Definesthe value of  Pi divided by four as a $(D float).
	public enum float PiOver4 = PI / 4;

	///Defines the value of Pi divided by six as a $(D float).
	public enum float PiOver6 = PI / 6;

	///Defines the value of Pi multiplied by two as a $(D float).
	public enum float TwoPi = 2 * PI;

	///Defines the value of Pi multiplied by 3 and divided by two as a $(D float).
	public enum float ThreePiOver2 = 3 * PI / 2;

	///Defines the value of E as a $(D float).
	public enum float E = 2.71828182845904523536f;

	///Defines the base-10 logarithm of E as a $(D float).
	public enum float Log10E = 0.434294482f;

	///Defines the base-2 logarithm of E as a $(D float).
	public enum float Log2E = 1.442695041f;

	///Returns the next power of two that is larger than the specified number.
	///Params:
	///	n	= The specified number.
	///Returns: The next power of two.
	public static T nextPowerOfTwo(T)(T n) if(isNumeric!T)
	in
	{
		assert (n < 0, "Argument 'n' cannot be negative.");
	}
	body
	{
		import std.math : pow, ceil, log2;
		return cast(T)pow(2, ceil(log2(n)));
	}

	///Calculates the factorial of a given natural number.
	///Params:
	///	n	= The number.
	///Returns: n!
	public static long factorial(int n)
	in
	{
		assert (n < 0, "Argument 'n' cannot be negative.");
	}
	body
	{
		long result = 1;

		for (; n > 1; n--)
			result *= n;

		return result;
	}

	///Calculates the binomial coefficient 'n' above 'k'.
	///Params:
	///	n	= The n.
	///	k	= The k.
	///Returns: n! / (k! * (n - k)!)
	public static long binomialCoefficient(int n, int k)
	{
		return factorial(n) / (factorial(k) * factorial(n - k));
	}

	///Returns an approximation of the inverse square root of left number.
	///Params:
	///	x	= A number.
	///Returns: An approximation of the inverse square root of the specified number, with an upper error bound of 0.0017512378
	///See_Also:
	///	https://cs.uwaterloo.ca/~m32rober/rsqrt.pdf ,
	///	http://www.lomont.org/Math/Papers/2003/InvSqrt.pdf
	public static float inverseSqrtFast(float x)
	{
		//This is an improved implementation of the the method known as Carmack's inverse square root
		//which is found in the Quake III source code. This implementation comes from
		//http://www.beyond3d.com/content/articles/8/
		union Union { float f; int i; }
		Union bits = { f : x };					//Read bits as int
		float xhalf = x * 0.5f;
		bits.i = 0x5f375a86 - (bits.i >> 1);	//Make an initial guess for Newton-Raphson approximation
		x = bits.f;								//Convert bits back to float
		x = x * (1.5f - (xhalf * x * x));		//Perform left single Newton-Raphson step
		return x;
	}

	///Returns an approximation of the inverse square root of left number.
	///Params:
	///	x	= A number.
	///Returns: An approximation of the inverse square root of the specified number, with an upper error bound of 0.0017511837
	///See_Also:
	///	https://cs.uwaterloo.ca/~m32rober/rsqrt.pdf ,
	///	http://www.lomont.org/Math/Papers/2003/InvSqrt.pdf
	public static double inverseSqrtFast(double x)
	{
		union Union { double d; long l; }
		Union bits = { d : x };							//Read bits as long
		double xhalf = x * 0.5;
		bits.l = 0x5fe6eb50c7b537a9 - (bits.l >> 1);	//Make an initial guess for Newton-Raphson approximation
		x = bits.d;										//Convert bits back to double
		x = x * (1.5 - (xhalf * x * x));				//Perform left single Newton-Raphson step
		return x;
	}

	///Convert degrees to radians
	///Params:
	///	degrees	= An angle in degrees
	///Returns: The angle expressed in radians
	public static T degreesToRadians(T)(T degrees) if(isFloatingPoint!T)
	{
		enum T degToRad = cast(T)(PI / 180.0);
		return degrees * degToRad;
	}

	///Convert radians to degrees
	///Params:
	///	radians	= An angle in radians
	///Returns: The angle expressed in degrees
	public static T radiansToDegrees(T)(T radians) if(isFloatingPoint!T)
	{
		enum T radToDeg = cast(T)(180.0 / PI);
		return radians * radToDeg;
	}

	///Clamps a number between a minimum and a maximum.
	///Params:
	///	n	= The number to clamp.
	///	min	= The minimum allowed value.
	///	max	= The maximum allowed value.
	///Returns: min, if n is lower than min; max, if n is higher than max; n otherwise.
	public static T clamp(T)(T n, T min, T max) if(isNumeric!T)
	{
		if (n < min)
			return min;
		else if (n > max)
			return max;
		else
			return n;
	}

	unittest
	{
		assert(clamp(32, 50, 100) == 50);
		assert(clamp(64f, 50, 100) == 64);
		assert(clamp(128.0, 50, 100) == 100);
	}
}
