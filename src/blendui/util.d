module blendui.util;

import std.format : format;
import std.range : isInfinite, isInputRange, isRandomAccessRange;
import std.traits : isSomeString, isIterable, isCallable;

///Mixin template for creating accessors (get/set)
///Creates a private variable prefixed with an underscore.
template Field(T, string name, bool readOnly = false)
{
	static assert(name.length > 0);

	mixin("private T _" ~ name  ~ ";");
	mixin("public ref " ~ (readOnly ? "const(T) " : "T ") ~ name ~ "() @property { return " ~ (readOnly ? "cast(const)" : "") ~ "_" ~ name ~ "; }");
	mixin((readOnly ? "private" : "public") ~ " T " ~ name ~ "(T value) @property { return _" ~ name ~ " = value; }");
}

///Mixin template for creating accessors (get/set) combined with events.
///Creates a private variable prefixed with an underscore.
template Property(T, string name, bool readOnly = false, bool onChangedMethod = false)
{
	import blendui.events;
	import std.traits : isPointer;

	static assert(name.length > 0);
	
	mixin("private T _" ~ name  ~ ";");
	mixin("public ref " ~ (readOnly ? "const(T) " : "T ") ~ name ~ "() @property { return " ~ (readOnly ? "cast(const)" : "") ~ "_" ~ name ~ "; }");
	enum setterCode = `
		public T %1$s(T value) @property
		{
			auto old = _%1$s;
			_%1$s = value;
			if (old != value)
				%1$sChanged(this);
			return _%1$s;
		}
		public Event!(Object) %1$sChanged;
	`;
	enum onChangedCode = `
		protected void on%sChanged()
		{
			%sChanged(this);
		}
	`;
	static if (!readOnly)
		mixin(format!(setterCode)(name));
	static if (onChangedMethod)
		mixin(format!(onChangedCode)(name.toPascalCase, name));
}

string toPascalCase(S)(S str) if(isSomeString!S)
{
	import std.array : array;
	import std.conv : to;
	import std.string : capitalize;
	import std.uni : isAlpha, byCodePoint;
	import std.utf : toUTF8; 

	dchar[] result = str.byCodePoint.array;
	sizediff_t index = -1;
	foreach(i, ch; result)
	{
		if(isAlpha(ch))
		{
			index = i;
			break;
		}
	}
	if(index != -1)
	{
		//Capitalize is not ligature aware but probably nobody needs this anyway
		result = result[0 .. index] ~ capitalize(result[index].to!dstring) ~ result[index + 1 .. $];
	}
	return result.toUTF8();
}

unittest
{
	assert(toPascalCase("ßtuff") == "SStuff");
	assert(toPascalCase("̏stuff") == "̏Stuff");
	assert(toPascalCase("ﬄ") == "FFL"); //FIXME: Should be Ffl
}

unittest
{
	class TestCapsule
	{
		mixin Field!(int, "counter");
		mixin Property!(bool, "counting", false, true);
		mixin Property!(float[], "percentageList", true);

		public this()
		{
			_percentageList = [0.2f, 0.8f];
		}

		public void countingChangedHandler(Object sender)
		{
			assert(counting == true);
		}
	}
	TestCapsule t = new TestCapsule();
	t.counter = 8;
	static assert(!__traits(compiles, t.percentageList = []));
	const(float[]) pList = t.percentageList;
	assert(pList == [0.2f, 0.8f]);
	t.countingChanged += &t.countingChangedHandler;
	t.counting = true;
	t.onCountingChanged();
}

///Returns whether a value exists in the given iterable range.
public bool contains(Range, V)(Range haystack, V needle) if(isIterable!Range)
{
	foreach(element; haystack)
		if (element == needle)
			return true;
	return false;
}

///Returns index of the first element that is equal to the value in the given iterable range.
public sizediff_t indexOf(Range, V)(Range haystack, V needle) if(isIterable!Range)
{
	sizediff_t i = 0;
	foreach(element; haystack)
		if (element == needle)
			return i;
		else
			i++;
	return -1;
}

///Returns index of the last element that is equal to the value in the given finite iterable range.
public sizediff_t lastIndexOf(Range, V)(Range haystack, V needle) if(isIterable!Range && !isInfinite!Range)
{
	static if(isRandomAccessRange!Range)
	{
		foreach_reverse(i, element; haystack)
			if (element == needle)
				return i;
		return -1;
	}
	else
	{
		sizediff_t found = -1, i = 0;
		foreach(element; haystack)
		{
			if (element == needle)
				found = i;
			i++;
		}
		return found;
	}
}

unittest
{
	import std.range : iota;
	immutable arr = [1, 1, 2, 3, 5, 8, 13, 21];
	assert(arr.contains(1));
	assert(arr.contains(8));
	assert(arr.contains(21));
	assert(!arr.contains(7));
	
	assert(arr.indexOf(1) == 0);
	assert(arr.indexOf(8) == 5);
	assert(arr.indexOf(21) == 7);
	assert(arr.indexOf(4) == -1);
	
	assert(arr.lastIndexOf(1) == 1);
	assert(arr.lastIndexOf(8) == 5);
	assert(arr.lastIndexOf(21) == 7);
	assert(arr.lastIndexOf(4) == -1);

	struct List(T : T[])
	{
	private:
		size_t i = 0;
		T[] list;
	public:
		this(T[] list)
		{
			this.list = list.dup;
		}
		void popFront()
		{
			i++;
		}
		int front()
		{
			return list[i];
		}
		bool empty()
		{
			return !(i < list.length);
		}
	}
	auto r = List!(typeof(arr))(arr);
	assert(r.contains(1));
	assert(r.contains(8));
	assert(r.contains(21));
	assert(!r.contains(7));
	
	assert(r.indexOf(1) == 0);
	assert(r.indexOf(8) == 5);
	assert(r.indexOf(21) == 7);
	assert(r.indexOf(4) == -1);
	
	assert(r.lastIndexOf(1) == 1);
	assert(r.lastIndexOf(8) == 5);
	assert(r.lastIndexOf(21) == 7);
	assert(r.lastIndexOf(4) == -1);
}