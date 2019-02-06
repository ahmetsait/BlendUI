module blendui.ui.window;

import std.algorithm : clamp;
import std.concurrency : thisTid, Tid;
import std.exception : ErrnoException;
import std.format : format;
import std.stdio : write, writef, writeln, writefln, stderr;
import std.string : toStringz, fromStringz;

import blendui.application;
import blendui.core;
import blendui.events;
import blendui.graphics.gl;
import blendui.math;
import blendui.ui;
import blendui.util;

import derelict.sdl2.sdl;

import gfm.math.vector : vec4f;

public enum WindowStartPosition : ubyte
{
	undefined		= 0,
	centerScreen	= 1,
	centerParent	= 2,
	manual			= 3,
}

//region IWindow
public interface IWindow : IDisposable
{
	void* getSystemWindow();

	string title() @property;
	string title(string value) @property;

	Rectangle!int bounds() @property;
	Rectangle!int bounds(Rectangle!int value) @property;

	Size!int maxSize() @property;
	Size!int maxSize(Size!int value) @property;

	Size!int minSize() @property;
	Size!int minSize(Size!int value) @property;

	bool resizable() @property;
	bool resizable(bool value) @property;

	bool borderless() @property;
	bool borderless(bool) @property;

	bool maximized() @property;
	bool maximized(bool value) @property;

	bool minimized() @property;
	bool minimized(bool value) @property;

	bool hasFocus() @property;

	void show(Window owner);
	void hide();
	void activate();
	void close();

	int getDisplayIndex();
	float getDisplayDPI();
}
//endregion

public class Window : IWindow, IWidgetContainer, IEventReceiver, IDisposable
{
	//region Constructors
	public this(string title, int width = 800, int height = 600)
	{
		auto bounds = Rectangle!int(SDL_WINDOWPOS_CENTERED, SDL_WINDOWPOS_CENTERED, width, height);
		this(
			title,
			bounds,
			maximized,
			minimized,
			resizable,
			showInTaskBar,
			borderless
			);
	}
	
	public this(string title, Rectangle!int bounds, bool maximized, bool minimized, bool resizable, bool showInTaskBar, bool borderless)
	{
		this(
			title,
			bounds,
			SDL_WINDOW_OPENGL | SDL_WINDOW_HIDDEN
			| ((_maximized = maximized) == true ? SDL_WINDOW_MAXIMIZED : 0)
			| ((_minimized = minimized) == true ? SDL_WINDOW_MINIMIZED : 0)
			| ((_resizable = resizable) == true ? SDL_WINDOW_RESIZABLE : 0)
			| ((_showInTaskBar = showInTaskBar) == false ? SDL_WINDOW_SKIP_TASKBAR : 0)
			| ((_borderless = borderless) == true ? SDL_WINDOW_BORDERLESS : 0)
			);
	}
	
	protected this(string title, Rectangle!int bounds, SDL_WindowFlags windowFlags)
	{
		this._title = title;
		this._bounds = bounds;
		this._tid = thisTid;
		
		//Set defaults
		import std.traits;
		foreach(name; __traits(allMembers, typeof(this)))
		{
			foreach(uda; getUDAs!(mixin(name), DefaultValue))
			{
				mixin(uda.symbol) = mixin(name);
			}
		}
		
		sdlWindow = SDL_CreateWindow(
			title.toStringz(),
			bounds.x, bounds.y, bounds.width, bounds.height,
			windowFlags
		);
		sdlWindow.enforceSDLNotNull("Could not create SDL window");

		SDL_AddEventWatch(&eventWatcher, cast(void*)this);

		Application.registerWindow(this);
		Application.getSharedGLContext(sdlWindow);
	}
	//endregion

	//region Properties
	private Tid _tid;
	public Tid tid() @property
	{
		return _tid;
	}

	protected SDL_Window* sdlWindow;
	public SDL_Window* getSDLWindow() nothrow @nogc
	{
		return sdlWindow;
	}

	public SDL_SysWMinfo getSystemWindowInfo()
	{
		static systemWindowInfoExist = false;
		static SDL_SysWMinfo systemWindowInfo;
		if (disposed)
			throw new ObjectDisposedException("Can not retrieve system window info from a disposed window.");
		if (!systemWindowInfoExist)
		{
			SDL_VERSION(&systemWindowInfo.version_);
			SDL_GetWindowWMInfo(sdlWindow, &systemWindowInfo)
				.enforceSDLEquals(SDL_TRUE, "Could not retrieve system window info.");
			systemWindowInfoExist = true;
		}
		return systemWindowInfo;
	}

	public void* getSystemWindow()
	{
		SDL_SysWMinfo sysWindowInfo = getSystemWindowInfo();
		switch(sysWindowInfo.subsystem)
		{
			version(Windows)
			{
				case SDL_SYSWM_WINDOWS:
					return sysWindowInfo.info.win.window;
			}
			version(Posix)
			{
				case SDL_SYSWM_X11:
					return sysWindowInfo.info.x11.window;
			}
			version(linux)
			{
				case SDL_SYSWM_WAYLAND:
					return sysWindowInfo.info.wl.surface;
				case SDL_SYSWM_MIR:
					return sysWindowInfo.info.mir.surface;
			}
			version(OSX)
			{
				case SDL_SYSWM_COCOA:
					return sysWindowInfo.info.cocoa.window;
			}
			default:
				throw new UnsupportedException("Getting window handle is not supported for this platform.");
				//TODO: Implement support for various different platforms
		}
	}

	protected uint id = 0;
	public uint getSDLWindowID()
	{
		if (id == 0)
		{
			if (sdlWindow == null)
				throw new Exception("Cannot query ID on null SDL window.");
			else
				return id = SDL_GetWindowID(sdlWindow).enforceSDLNotEquals(0);
		}
		else
			return id;
	}

	public Size!int getClampedSize(Size!int value)
	{
		value.clamp(minSize, maxSize, !minSize.isEmpty, !maxSize.isEmpty);
		return value;
	}
	
	public void clampSize(ref Size!int value)
	{
		value.clamp(minSize, maxSize, !minSize.isEmpty, !maxSize.isEmpty);
	}

	protected Rectangle!int _bounds;
	public Event!Window boundsChanged;
	public Rectangle!int bounds() @property
	{
		return _bounds;
	}
	public Rectangle!int bounds(Rectangle!int value) @property
	{
		auto old = _bounds;
		if (old.location != value.location)
		{
			_bounds.location = value.location;
			SDL_SetWindowPosition(sdlWindow, _bounds.x, _bounds.y);
		}
		clampSize(value.size);
		if (old.size != value.size)
		{
			_bounds.size = value.size;
			SDL_SetWindowSize(sdlWindow, _bounds.width, _bounds.height);
		}
		return _bounds;
	}

	public Event!Window locationChanged;
	public Point!int location() @property
	{
		return _bounds.location;
	}
	public Point!int location(Point!int value) @property
	{
		auto old = _bounds.location;
		if (old != value)
		{
			_bounds.location = value;
			SDL_SetWindowPosition(sdlWindow, _bounds.x, _bounds.y);
		}
		return _bounds.location;
	}

	public Point!int getLocationNormalized()
	{
		int x, y;
		SDL_GetWindowPosition(sdlWindow, &x, &y);
		return Point!int(x, y);
	}

	public Event!Window sizeChanged;
	public Size!int size() @property
	{
		return _bounds.size;
	}
	public Size!int size(Size!int value) @property
	{
		clampSize(value);
		auto old = _bounds.size;
		if (old != value)
		{
			_bounds.size = value;
			SDL_SetWindowSize(sdlWindow, _bounds.width, _bounds.height);
		}
		return _bounds.size;
	}

	protected Size!int _maxSize;
	public Event!Window maxSizeChanged;
	public Size!int maxSize() @property
	{
		return _maxSize;
	}
	public Size!int maxSize(Size!int value) @property
	{
		value.clamp(minSize, typeof(value).zero, true, false);
		auto old = _maxSize;
		if (old != value)
		{
			_maxSize = value;
			SDL_SetWindowMaximumSize(sdlWindow, _maxSize.width, _maxSize.height);
			maxSizeChanged(this);
		}
		return _maxSize;
	}

	protected Size!int _minSize;
	public Event!Window minSizeChanged;
	public Size!int minSize() @property
	{
		return _minSize;
	}
	public Size!int minSize(Size!int value) @property
	{
		value.clamp(typeof(value).zero, maxSize, false, true);
		auto old = _minSize;
		if (old != value)
		{
			_minSize = value;
			SDL_SetWindowMinimumSize(sdlWindow, _minSize.width, _minSize.height);
			minSizeChanged(this);
		}
		return _minSize;
	}

	protected float _opacity = 1.0f;
	public Event!Window opacityChanged;
	public float opacity() @property
	{
		return _opacity;
	}
	public float opacity(float value) @property
	{
		import std.algorithm : clamp;
		auto old = _opacity;
		if (old != value)
		{
			_opacity = value.clamp(0f, 1f);
			SDL_SetWindowOpacity(sdlWindow, _opacity);
			opacityChanged(this);
		}
		return _opacity;
	}

	protected bool _resizable = true;
	public Event!Window resizableChanged;
	public bool resizable() @property
	{
		return _resizable;
	}
	public bool resizable(bool value) @property
	{
		auto old = _resizable;
		if (old != value)
		{
			_resizable = value;
			SDL_SetWindowResizable(sdlWindow, _resizable);
			resizableChanged(this);
		}
		return _resizable;
	}

	protected bool _borderless;
	public Event!Window borderlessChanged;
	public bool borderless() @property
	{
		return _borderless;
	}
	public bool borderless(bool value) @property
	{
		auto old = _borderless;
		if (old != value)
		{
			_borderless = value;
			SDL_SetWindowBordered(sdlWindow, !_borderless);
			borderlessChanged(this);
		}
		return _borderless;
	}

	protected bool _maximized;
	public Event!Window maximizedChanged;
	public bool maximized() @property
	{
		return _maximized;
	}
	public bool maximized(bool value) @property
	{
		auto old = _maximized;
		if (old != value)
		{
			_maximized = value;
			if (_maximized)
				SDL_MaximizeWindow(sdlWindow);
			else
				SDL_RestoreWindow(sdlWindow);
		}
		return _maximized;
	}

	protected bool _minimized;
	public Event!Window minimizedChanged;
	public bool minimized() @property
	{
		return _minimized;
	}
	public bool minimized(bool value) @property
	{
		auto old = _minimized;
		if (old != value)
		{
			_minimized = value;
			if (_minimized)
				SDL_MinimizeWindow(sdlWindow);
			else
				SDL_RestoreWindow(sdlWindow);
		}
		return _minimized;
	}

	protected bool _showInTaskBar = true;
	public Event!Window showInTaskBarChanged;
	public bool showInTaskBar() @property
	{
		return _showInTaskBar;
	}
	public bool showInTaskBar(bool value) @property
	{
		auto old = _showInTaskBar;
		if (old != value)
		{
			_showInTaskBar = value;
			throw new NotImplementedException("Setting taskbar visiblity is not implemented.");
			//TODO: Implement
			//showInTaskBarChanged(this);
		}
		return _showInTaskBar;
	}

	protected bool _visible;
	public Event!Window visibleChanged;
	public bool visible() @property
	{
		return _visible;
	}
	public bool visible(bool value) @property
	{
		auto old = _visible;
		if (old != value)
		{
			_visible = value;
			if (_visible)
				SDL_ShowWindow(sdlWindow);
			else
				SDL_HideWindow(sdlWindow);
		}
		return _visible;
	}

	protected WindowStartPosition _startPosition = WindowStartPosition.centerParent;
	public WindowStartPosition startPosition() @property
	{
		return _startPosition;
	}
	public WindowStartPosition startPosition(WindowStartPosition value) @property
	{
		return _startPosition = value;
	}

	protected string _title;
	public Event!Window titleChanged;
	public string title() @property
	{
		return _title;
	}
	public string title(string value) @property
	{
		auto old = _title;
		if (old != value)
		{
			_title = value;
			SDL_SetWindowTitle(sdlWindow, _title.toStringz());
			titleChanged(this);
		}
		return _title;
	}

	version(Windows)
	{
		pragma(lib, "user32");
		//pragma(lib, "kernel32");
	}

	protected Window _owner;
	public Window owner() @property
	{
		return _owner;
	}
	public Window owner(Window value) @property
	{
		auto systemWindowInfo = this.getSystemWindowInfo();
		switch (systemWindowInfo.subsystem)
		{
			version(Windows)
			{
				import core.sys.windows.windows : SetWindowLongPtr, GWLP_HWNDPARENT, LONG_PTR, GetLastError, SetLastError;
				case SDL_SYSWM_WINDOWS:
					//FIXME: Check for parenting cycle
					//FIXME: Register owned windows in owner and make them close owneds
					auto ownerHandle = cast(LONG_PTR)value.getSystemWindowInfo().info.win.window;
					SetLastError(0);
					SetWindowLongPtr(systemWindowInfo.info.win.window, GWLP_HWNDPARENT, ownerHandle);
					immutable error = GetLastError();
					if (error != 0)
						throw new ErrnoException("Could not adjust window owner.", error);
				break;
			}
			case SDL_SYSWM_X11:
				SDL_SetWindowModalFor(sdlWindow, value.getSDLWindow()).enforceSDLEquals(0, "Could not adjust window owner.");
				break;
			case SDL_SYSWM_COCOA:
				goto default;
			default:
				throw new NotImplementedException("Setting owner window is not implemented for this platform.");
				//TODO: Implement support for various different platforms
		}
		return _owner;
	}

	@DefaultValue(_backColor.stringof)
	public static vec4f default_BackColor = vec4f(0.25f, 0.25f, 0.25f, 1.00f);

	protected vec4f _backColor;
	public Event!Window backColorChanged;
	public vec4f backColor()
	{
		return _backColor;
	}
	public vec4f backColor(vec4f value)
	{
		auto old = _backColor;
		if (old !is value)
		{
			_backColor = value;
			backColorChanged(this);
		}
		return _backColor;
	}
	
	protected Widget _widget;
	public Event!Window widgetChanged;
	public Widget widget()
	{
		return _widget;
	}
	public Widget widget(Widget value)
	{
		auto old = _widget;
		if (old !is value)
		{
			_widget = value;
			widgetChanged(this);
		}
		return _widget;
	}
	
	/+protected int _layoutSuspend = 0;
	public bool layoutSuspended() @property
	{
		return _layoutSuspend > 0;
	}

	public auto suspendLayout()
	{
		return rlock(_layoutSuspend);
	}+/
	//endregion

	//region handleEvent
	public bool handleEvent(ref SDL_Event event)
	{
		if (disposed)
			throw new ObjectDisposedException("Window disposed.");
		switch (event.type)
		{
			case SDL_WINDOWEVENT:
				switch (event.window.event)
				{
					case SDL_WINDOWEVENT_SHOWN:
						_visible = true;
						onShown();
						return true;
					case SDL_WINDOWEVENT_HIDDEN:
						_visible = false;
						onHidden();
						return true;
					case SDL_WINDOWEVENT_EXPOSED:
						onExposed(event);
						return true;
					case SDL_WINDOWEVENT_MOVED:
						_bounds.x = event.window.data1;
						_bounds.y = event.window.data2;
						onMoved();
						return true;
					case SDL_WINDOWEVENT_RESIZED:
						onResized();
						return true;
					case SDL_WINDOWEVENT_SIZE_CHANGED:
						_bounds.width = event.window.data1;
						_bounds.height = event.window.data2;
						onSizeChanged();
						return true;
					case SDL_WINDOWEVENT_MINIMIZED:
						_minimized = true;
						onMinimized();
						return true;
					case SDL_WINDOWEVENT_MAXIMIZED:
						_maximized = true;
						onMaximized();
						return true;
					case SDL_WINDOWEVENT_RESTORED:
						_minimized = false;
						_maximized = false;
						onRestored();
						return true;
					case SDL_WINDOWEVENT_ENTER:
						onMouseEnter();
						return true;
					case SDL_WINDOWEVENT_LEAVE:
						onMouseLeave();
						return true;
					case SDL_WINDOWEVENT_FOCUS_GAINED:
						_hasFocus = true;
						onFocusGained();
						return true;
					case SDL_WINDOWEVENT_FOCUS_LOST:
						_hasFocus = false;
						onFocusLost();
						return true;
					case SDL_WINDOWEVENT_CLOSE:
						bool cancelled = false;
						onClosing(&cancelled);
						if (!cancelled)
						{
							onClosed();
							dispose();
						}
						return true;
					case SDL_WINDOWEVENT_TAKE_FOCUS:
						onFocusOffered();
						return true;
					case SDL_WINDOWEVENT_HIT_TEST:
						onHitTest();
						return true;
					default:
						debug stderr.writefln!"Unhandled window event: 0x%X"(event.window.event);
						return true;
				}
			case SDL_KEYDOWN:
				return onKeyDown(event);
			case SDL_KEYUP:
				return onKeyUp(event);
			case SDL_TEXTEDITING:
				return onTextEditing(event);
			case SDL_TEXTINPUT:
				return onTextInput(event);
			case SDL_MOUSEMOTION:
				return onMouseMove(event);
			case SDL_MOUSEBUTTONDOWN:
				return onMouseDown(event);
			case SDL_MOUSEBUTTONUP:
				return onMouseUp(event);
			case SDL_MOUSEWHEEL:
				return onMouseWheel(event);
			case SDL_DROPBEGIN:
				//TODO
				return false;
			case SDL_DROPTEXT:

				return false;
			case SDL_DROPFILE:

				return false;
			case SDL_DROPCOMPLETE:

				return false;
			default:
				writeln(format!"Unhandled event: %d"(event.type));
				return false;
		}
	}

	extern(C) private static int eventWatcher(void* data, SDL_Event* event)
	{
		Window _this = cast(Window)data;
		if (event.type == SDL_WINDOWEVENT)
		{
			switch(event.window.event)
			{
				case SDL_WINDOWEVENT_EXPOSED:
				case SDL_WINDOWEVENT_SIZE_CHANGED:
				case SDL_WINDOWEVENT_MOVED:
					if (thisTid == _this.tid)
					{
						SDL_Window* win = SDL_GetWindowFromID(event.window.windowID);
						if (win == _this.getSDLWindow())
							_this.handleEvent(*event);
						return 0;
					}
					break;
				default:
					break;
			}
		}
		return 1;
	}
	//endregion

	//region onEvent(...) functions
	protected void onShown()
	{
		visibleChanged(this);
	}

	protected void onHidden()
	{
		visibleChanged(this);
	}

	public Event!Window exposed;
	protected void onExposed(ref SDL_Event event)
	{
		exposed(this);
		if (!_minimized)
			onDraw();
	}
	
	protected void onMoved()
	{
		locationChanged(this);
		boundsChanged(this);
	}

	public Event!Window resized;
	protected void onResized()
	{
		resized(this);
	}
	
	protected void onSizeChanged()
	{
		sizeChanged(this);
		boundsChanged(this);
	}
	
	protected void onMaximized()
	{
		maximizedChanged(this);
	}
	
	protected void onMinimized()
	{
		minimizedChanged(this);
	}

	public Event!Window restored;
	protected void onRestored()
	{
		restored(this);
	}

	public Event!Window mouseEnter;
	protected void onMouseEnter()
	{
		mouseEnter(this);
	}

	public Event!Window mouseLeave;
	protected void onMouseLeave()
	{
		mouseLeave(this);
	}

	protected bool _hasFocus;
	public bool hasFocus() @property
	{
		return _hasFocus;
	}

	public Event!Window focusGained;
	protected void onFocusGained()
	{
		focusGained(this);
	}

	public Event!Window focusLost;
	protected void onFocusLost()
	{
		focusLost(this);
	}

	public Event!(Window, bool*) closing;
	protected void onClosing(bool* cancelled)
	{
		closing(this, cancelled);
	}

	public Event!Window closed;
	protected void onClosed()
	{
		closed(this);
	}

	protected void onFocusOffered()
	{
		//debug stderr.writeln("SDL_WINDOWEVENT_TAKE_FOCUS");
		SDL_SetWindowInputFocus(sdlWindow).enforceSDLEquals(0);
		//It seems like it doesn't even matter
	}

	public Event!Window hitTest;
	protected void onHitTest()
	{
		hitTest(this);
	}

	public Event!(Window, SDL_KeyboardEvent*, bool*) keyDown;
	protected bool onKeyDown(ref SDL_Event event)
	{
		bool handled = false;
		if (widget !is null)
			handled = widget.handleEvent(event);
		if (!handled)
			keyDown(this, &event.key, &handled);
		return handled;
	}

	public Event!(Window, SDL_KeyboardEvent*, bool*) keyUp;
	protected bool onKeyUp(ref SDL_Event event)
	{
		bool handled = false;
		if (widget !is null)
			handled = widget.handleEvent(event);
		if (!handled)
			keyUp(this, &event.key, &handled);
		return handled;
	}

	public Event!(Window, SDL_TextEditingEvent*, bool*) textEditing;
	protected bool onTextEditing(ref SDL_Event event)
	{
		bool handled = false;
		if (widget !is null)
			handled = widget.handleEvent(event);
		if (!handled)
			textEditing(this, &event.edit, &handled);
		return handled;
	}

	public Event!(Window, SDL_TextInputEvent*, bool*) textInput;
	protected bool onTextInput(ref SDL_Event event)
	{
		bool handled = false;
		if (widget !is null)
			handled = widget.handleEvent(event);
		if (!handled)
			textInput(this, &event.text, &handled);
		return handled;
	}

	public Event!(Window, SDL_MouseMotionEvent*, bool*) mouseMove;
	protected bool onMouseMove(ref SDL_Event event)
	{
		bool handled = false;
		if (widget !is null)
			handled = widget.handleEvent(event);
		if (!handled)
			mouseMove(this, &event.motion, &handled);
		return handled;
	}

	public Event!(Window, SDL_MouseButtonEvent*, bool*) mouseDown;
	protected bool onMouseDown(ref SDL_Event event)
	{
		bool handled = false;
		if (widget !is null)
			handled = widget.handleEvent(event);
		if (!handled)
			mouseDown(this, &event.button, &handled);
		return handled;
	}

	public Event!(Window, SDL_MouseButtonEvent*, bool*) mouseUp;
	protected bool onMouseUp(ref SDL_Event event)
	{
		bool handled = false;
		if (widget !is null)
			handled = widget.handleEvent(event);
		if (!handled)
			mouseUp(this, &event.button, &handled);
		return handled;
	}

	public Event!(Window, SDL_MouseWheelEvent*, bool*) mouseWheel;
	protected bool onMouseWheel(ref SDL_Event event)
	{
		bool handled = false;
		if (widget !is null)
			handled = widget.handleEvent(event);
		if (!handled)
			mouseWheel(this, &event.wheel, &handled);
		return handled;
	}

	public Event!(Window, string, bool*) textDrop;
	protected bool onTextDrop(string text)
	{
		bool handled = false;
		if (widget !is null)
			handled = widget.handleTextDrop(text);
		if (!handled)
			textDrop(this, text, &handled);
		return handled;
	}

	public Event!(Window, string[], bool*) fileDrop;
	protected bool onFileDrop(string[] files)
	{
		bool handled = false;
		if (widget !is null)
			handled = widget.handleFileDrop(files);
		if (!handled)
			fileDrop(this, files, &handled);
		return handled;
	}

	public Event!Window draw;
	protected void onDraw()
	{
		SDL_GL_MakeCurrent(sdlWindow, Application.getSharedGLContext(sdlWindow));
		int w, h;
		SDL_GL_GetDrawableSize(getSDLWindow(), &w, &h);
		auto viewport = Rectangle!int(0, 0, w, h);
		glViewport(0, 0, w, h);
		glScissor(0, 0, w, h);
		glClearColor(backColor.r, backColor.g, backColor.b, backColor.a);
		glClear(GL_COLOR_BUFFER_BIT | GL_STENCIL_BUFFER_BIT);
		draw(this);
		{
			if (widget !is null && !widget.disposed)
				widget.handleDraw(viewport, getSDLWindow());
		}
		SDL_GL_SwapWindow(sdlWindow);
	}
	//endregion

	//region Functions
	public Event!Window appeared;
	public void show(Window owner = null)
	{
		static bool firstTimeShowing = true;
		
		if (owner !is null)
			this.owner = owner;
		
		if (firstTimeShowing)
		{
			int x, y;
			final switch (startPosition)
			{
				case WindowStartPosition.manual:
					x = bounds.x;
					y = bounds.y;
					break;
				case WindowStartPosition.centerScreen:
					x = y = SDL_WINDOWPOS_CENTERED;
					break;
				case WindowStartPosition.centerParent:
					if (owner is null)
						goto case WindowStartPosition.centerScreen;
					x = owner.bounds.x + (owner.bounds.width - this.bounds.width) / 2;
					y = owner.bounds.y + (owner.bounds.height - this.bounds.height) / 2;
					break;
				case WindowStartPosition.undefined:
					x = y = SDL_WINDOWPOS_UNDEFINED;
					break;
			}
			location = Point!int(x, y);
			firstTimeShowing = false;
			SDL_ShowWindow(sdlWindow);
			appeared(this);
		}
		else
			SDL_ShowWindow(sdlWindow);
	}
	
	public void hide()
	{
		SDL_HideWindow(sdlWindow);
	}
	
	public void activate()
	{
		SDL_RaiseWindow(sdlWindow);
	}
	
	public void close()
	{
		SDL_Event event = void;
		event.type = SDL_WINDOWEVENT;
		event.window.timestamp = SDL_GetTicks();
		event.window.windowID = getSDLWindowID();
		event.window.event = SDL_WINDOWEVENT_CLOSE;
		event.window.data1 = event.window.data2 = 0;	//TODO: Maybe use data as close reason
		SDL_PushEvent(&event);
	}
	
	public int getDisplayIndex()
	{
		return SDL_GetWindowDisplayIndex(sdlWindow);
	}
	
	public float getDisplayDPI()
	{
		float xdpi;
		SDL_GetDisplayDPI(getDisplayIndex(), null, &xdpi, null)
			.enforceSDLEquals(0, "Could not query display DPI.");
		return xdpi;
	}
//endregion

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
				if (widget !is null)
					widget.dispose();
			}

			//Free unmanaged resources (unmanaged objects), set large fields to null.
			SDL_DelEventWatch(&eventWatcher, cast(void*)this);

			if (sdlWindow !is null)
			{
				SDL_DestroyWindow(sdlWindow);
				sdlWindow = null;
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
