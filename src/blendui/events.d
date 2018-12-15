module blendui.events;

import std.stdio : writeln, writefln;
import core.stdc.stdlib : alloca;
import std.algorithm.mutation : remove;

import blendui.core;
import blendui.util;

///Basic event type that allows listeners to subscribe. Used very similar to C#
///events. Only class/interface member functions are supported. Any attempt to
///use anything other than class/interface member functions will likely crash.
public struct Event(T...)
{
	import std.signals : rt_attachDisposeEvent, rt_detachDisposeEvent, _d_toObject;

	public alias listener_t = void delegate(T);

	private listener_t[] listeners;
	
	public @disable void opAssign(this T)(T value);

	///Subscribes a listener delegate to this event.
	///Same delegate cannot be added multiple times.
	public void add(listener_t listener)
	{
		if(listeners.contains(listener))
			throw new InvalidOperationException("Delegate is already subscribed.");
		else
		{
			listeners ~= listener;
			Object o = _d_toObject(listener.ptr);
			if(o !is null)
				rt_attachDisposeEvent(o, &unhook);
		}
	}

	///Unsubscribes a listener delegate from this event.
	public void remove(listener_t listener)
	{
		sizediff_t x;
		if((x = listeners.lastIndexOf(listener)) < 0)
			throw new InvalidOperationException("Delegate is not subscribed.");
		else
		{
			bool detach = true;
			void* ptr = listeners[x].ptr;
			listeners = listeners.remove(x);
			foreach(l; listeners)
			{
				if(l.ptr == ptr)
				{
					detach = false;
					break;
				}
			}
			if(detach)
			{
				Object o = _d_toObject(ptr);
				if(o !is null)
					rt_detachDisposeEvent(o, &unhook);
			}
		}
	}
	
	public void opOpAssign(string op)(listener_t listener)
	{
		static if(op == "+")
			this.add(listener);
		else static if(op == "-")
			this.remove(listener);
	}

	public void clear()
	{
		foreach(l; listeners)
		{
			Object o = _d_toObject(l.ptr);
			if(o !is null)
				rt_detachDisposeEvent(o, &unhook);
		}
		listeners = null;
	}

	public void fire(T args)
	{
		auto current = (cast(listener_t*)alloca(listeners.length * listener_t.sizeof))[0 .. listeners.length];
		current[] = listeners[];
		foreach(listener; current)
			listener(args);
	}
	
	public void opCall(T args) { fire(args); }

	private void unhook(Object o)
	{
		int removed = 0;
		for(ptrdiff_t i = listeners.length - 1; i >= 0; i--)
		{
			if(_d_toObject(listeners[i].ptr) is o)
			{
				listeners.remove(i);
				removed++;
			}
		}
		listeners.length -= removed;
	}

	~this()
	{
		foreach(l; listeners)
		{
			Object o = _d_toObject(l.ptr);
			if(o !is null)
				rt_detachDisposeEvent(o, &unhook);
		}
	}
}

///Basic event type that allows listeners to subscribe. Used very similar to C#
///events. All kinds of delegates are supported. Doesn't automatically
///unsubscribe from destroyed objects. Faster. Use with caution.
public struct EventUnsafe(T...)
{
	public alias listener_t = void delegate(T);
	
	private listener_t[] listeners;
	
	public @disable void opAssign(this T)(T value);
	
	///Subscribes a listener delegate to this event.
	///Same delegate cannot be added multiple times.
	public void add(listener_t listener)
	{
		if(listeners.contains(listener))
			throw new InvalidOperationException("Delegate is already subscribed.");
		else
			listeners ~= listener;
	}
	
	///Unsubscribes a listener delegate from this event.
	public void remove(listener_t listener)
	{
		sizediff_t x;
		if((x = listeners.lastIndexOf(listener)) < 0)
			throw new InvalidOperationException("Delegate is not subscribed.");
		else
			listeners = listeners.remove(x);
	}
	
	public void opOpAssign(string op)(listener_t listener)
	{
		static if(op == "+")
			this.add(listener);
		else static if(op == "-")
			this.remove(listener);
	}
	
	public void clear()
	{
		listeners = null;
	}
	
	public void fire(T args)
	{
		auto current = (cast(listener_t*)alloca(listeners.length * listener_t.sizeof))[0 .. listeners.length];
		current[] = listeners[];
		foreach(listener; current)
			listener(args);
	}
	
	public void opCall(T args) { fire(args); }
}

unittest
{
	struct TestEventArgs
	{
		string str;
		double d;
	}

	class TestCapsule
	{
		import std.format : format;

		public string[5] strList;
		public int call = 0;

		void event_Fired()
		{
			strList[0] = ("Event fired!");
			call++;
		}
		
		void event_Fired(Object sender, int i)
		{
			strList[1] = format("%s\tSome int: %d", typeof(sender).stringof, i);
			call++;
		}
		
		void event_MathRequired(Object sender, int i)
		{
			import std.math : sqrt;
			strList[2] = format("Sqrt(%d) = %f", i, sqrt(float(i)));
			call++;
		}
		
		void event_Fired(Object sender, TestEventArgs args)
		{
			strList[3] = format("%s\tSome struct: %s", sender !is null ? typeid(sender) : null, args);
			call++;
		}
		
		void event_Fired(Event!() e)
		{
			strList[4] = format("This is madness: %s", typeid(e));
			call++;
		}
	}

	TestCapsule capsule = new TestCapsule;
	
	Event!() event;
	event.add(&capsule.event_Fired);
	event.fire();
	assert(capsule.call == 1);
	static assert(!__traits(compiles, event = Event!().init));
	
	Event!(Object, int) event1;
	event1.add(&capsule.event_Fired);
	event1 += &capsule.event_MathRequired;
	event1.fire(capsule, int.max);
	assert(capsule.call == 3);
	event1.remove(&capsule.event_Fired);
	event1.fire(capsule, int.min);
	assert(capsule.call == 4);
	event1 -= &capsule.event_MathRequired;
	event1.fire(new Object, 0); //Should be no-op
	assert(capsule.call == 4);
	assert(capsule.strList[0] == "Event fired!");
	assert(capsule.strList[1] == "Object\tSome int: 2147483647");
	assert(capsule.strList[2] == "Sqrt(-2147483648) = -nan" ||
		capsule.strList[2] == "Sqrt(-2147483648) = nan");
	//TODO: Figure out if -nan is a thing and report bug if not
	
	Event!(Object, TestEventArgs) event2;
	TestEventArgs tea = TestEventArgs("I could be writing C#", double.epsilon);
	event2.add(&capsule.event_Fired);
	event2.fire(new Object, tea);
	assert(capsule.call == 5);
	event2.clear();
	event2.fire(new Object, tea); //Should be no-op
	assert(capsule.call == 5);
	assert(capsule.strList[3] == "object.Object\tSome struct: TestEventArgs(\"I could be writing C#\", 2.22045e-16)");

	Event!(Event!()) evented;	//Because why not
	evented.add(&capsule.event_Fired);
	evented.fire(Event!().init);
	assert(capsule.call == 6);
	assert(capsule.strList[4] == "This is madness: blendui.events.Event!().Event");

	destroy(capsule);
}
