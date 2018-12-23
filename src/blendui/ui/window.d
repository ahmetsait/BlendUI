module blendui.ui.window;

import std.stdio : write, writef, writeln, writefln, stderr;
import std.format : format;
import std.string : toStringz, fromStringz;
import std.algorithm : clamp;
import std.typecons : Nullable;
import std.exception : ErrnoException;

import derelict.sdl2.sdl;
import blendui.graphics.gl;

import gfm.math.vector : vec4f;

import blendui.core;
import blendui.events;
import blendui.math;
import blendui.ui;
import blendui.util;
import blendui.application;

public enum WindowStartPosition : ubyte
{
	undefined		= 0,
	centerScreen	= 1,
	centerParent	= 2,
	manual			= 3,
}

public interface IWindow
{
	//TODO
}

public class Window : IWindow, IWidgetContainer, IEventReceiver, IDisposable
{
	//region Properties
	private SDL_Window* sdlWindow;
	public SDL_Window* getSDLWindow()
	{
		return sdlWindow;
	}

	private bool systemWindowInfoExist = false;
	public SDL_SysWMinfo getSystemWindowInfo()
	{
		static SDL_SysWMinfo systemWindowInfo;

		if (!systemWindowInfoExist)
		{
			SDL_VERSION(&systemWindowInfo.version_);
			SDL_GetWindowWMInfo(sdlWindow, &systemWindowInfo)
				.enforceSDLEquals(SDL_TRUE, "Could not retrieve system window info.");
			systemWindowInfoExist = true;
		}
		return systemWindowInfo;
	}

	private uint id = 0;
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

	private Rectangle!int _bounds;
	public Event!Window boundsChanged;
	public Rectangle!int bounds() @property
	{
		return _bounds;
	}
	public void bounds(Rectangle!int value) @property
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
	}

	public Event!Window locationChanged;
	public Point!int location() @property
	{
		return _bounds.location;
	}
	public void location(Point!int value) @property
	{
		auto old = _bounds.location;
		if (old != value)
		{
			_bounds.location = value;
			SDL_SetWindowPosition(sdlWindow, _bounds.x, _bounds.y);
		}
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
	public void size(Size!int value) @property
	{
		clampSize(value);
		auto old = _bounds.size;
		if (old != value)
		{
			_bounds.size = value;
			SDL_SetWindowSize(sdlWindow, _bounds.width, _bounds.height);
		}
	}

	private Size!int _maxSize;
	public Event!Window maxSizeChanged;
	public Size!int maxSize() @property
	{
		return _maxSize;
	}
	public void maxSize(Size!int value) @property
	{
		value.clamp(minSize, typeof(value).zero, true, false);
		auto old = _maxSize;
		if (old != value)
		{
			_maxSize = value;
			SDL_SetWindowMaximumSize(sdlWindow, _maxSize.width, _maxSize.height);
			maxSizeChanged(this);
		}
	}

	private Size!int _minSize;
	public Event!Window minSizeChanged;
	public Size!int minSize() @property
	{
		return _minSize;
	}
	public void minSize(Size!int value) @property
	{
		value.clamp(typeof(value).zero, maxSize, false, true);
		auto old = _minSize;
		if (old != value)
		{
			_minSize = value;
			SDL_SetWindowMinimumSize(sdlWindow, _minSize.width, _minSize.height);
			minSizeChanged(this);
		}
	}

	protected float _opacity = 1.0f;
	public Event!Window opacityChanged;
	public float opacity() @property
	{
		return _opacity;
	}
	public void opacity(float value) @property
	{
		import std.algorithm : clamp;
		auto old = _opacity;
		if (old != value)
		{
			_opacity = value.clamp(0f, 1f);
			SDL_SetWindowOpacity(sdlWindow, _opacity);
			opacityChanged(this);
		}
	}

	protected bool _resizable = true;
	public Event!Window resizableChanged;
	public bool resizable() @property
	{
		return _resizable;
	}
	public void resizable(bool value) @property
	{
		auto old = _resizable;
		if (old != value)
		{
			_resizable = value;
			SDL_SetWindowResizable(sdlWindow, _resizable);
			resizableChanged(this);
		}
	}

	protected bool _borderless;
	public Event!Window borderlessChanged;
	public bool borderless() @property
	{
		return _borderless;
	}
	public void borderless(bool value) @property
	{
		auto old = _borderless;
		if (old != value)
		{
			_borderless = value;
			SDL_SetWindowBordered(sdlWindow, !_borderless);
			borderlessChanged(this);
		}
	}

	protected bool _maximized;
	public Event!Window maximizedChanged;
	public bool maximized() @property
	{
		return _maximized;
	}
	public void maximized(bool value) @property
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
	}

	protected bool _minimized;
	public Event!Window minimizedChanged;
	public bool minimized() @property
	{
		return _minimized;
	}
	public void minimized(bool value) @property
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
	}

	protected bool _showInTaskBar = true;
	public Event!Window showInTaskBarChanged;
	public bool showInTaskBar() @property
	{
		return _showInTaskBar;
	}
	public void showInTaskBar(bool value) @property
	{
		auto old = _showInTaskBar;
		if (old != value)
		{
			_showInTaskBar = value;
			throw new NotImplementedException("Setting taskbar visiblity is not implemented.");
			//TODO: Implement
			//showInTaskBarChanged(this);
		}
	}

	protected bool _visible;
	public Event!Window visibleChanged;
	public bool visible() @property
	{
		return _visible;
	}
	public void visible(bool value) @property
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
	}

	protected WindowStartPosition _startPosition = WindowStartPosition.centerParent;
	public WindowStartPosition startPosition() @property
	{
		return _startPosition;
	}
	public void startPosition(WindowStartPosition value) @property
	{
		_startPosition = value;
	}

	protected string _title;
	public Event!Window titleChanged;
	public string title() @property
	{
		return _title;
	}
	public void title(string value) @property
	{
		auto old = _title;
		if (old != value)
		{
			_title = value;
			SDL_SetWindowTitle(sdlWindow, _title.toStringz());
			titleChanged(this);
		}
	}

	protected Window _owner;
	public Window owner() @property
	{
		return _owner;
	}
	public void owner(Window value) @property
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
			default:
				throw new NotImplementedException("Setting owner window is not implemented for this platform.");
				//TODO: Implement support for various different platforms
		}
	}
	
	private int _suspendLayout = 0;
	private vec4f _backColor;
	
	private Widget[] _widgets;
	private Widget _activeWidget;
	//endregion

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

		sdlWindow = SDL_CreateWindow(
			title.toStringz(),
			bounds.x, bounds.y, bounds.width, bounds.height,
			windowFlags
		);
		sdlWindow.enforceSDLNotNull("Could not create SDL window");

		Application.registerWindow(this);
		Application.getSharedGLContext(sdlWindow);
	}
	//endregion

	//region handleEvent(SDL_Event event)
	public void handleEvent(SDL_Event event)
	{
		switch (event.type)
		{
			case SDL_WINDOWEVENT:
				switch (event.window.event)
				{
					case SDL_WINDOWEVENT_SHOWN:
						_visible = true;
						onShown();
						break;
					case SDL_WINDOWEVENT_HIDDEN:
						_visible = false;
						onHidden();
						break;
					case SDL_WINDOWEVENT_EXPOSED:
						onExposed();
						break;
					case SDL_WINDOWEVENT_MOVED:
						_bounds.x = event.window.data1;
						_bounds.y = event.window.data2;
						onMoved();
						break;
					case SDL_WINDOWEVENT_RESIZED:
						onResized();
						break;
					case SDL_WINDOWEVENT_SIZE_CHANGED:
						_bounds.width = event.window.data1;
						_bounds.height = event.window.data2;
						onSizeChanged();
						break;
					case SDL_WINDOWEVENT_MINIMIZED:
						_minimized = true;
						onMinimized();
						break;
					case SDL_WINDOWEVENT_MAXIMIZED:
						_maximized = true;
						onMaximized();
						break;
					case SDL_WINDOWEVENT_RESTORED:
						_minimized = false;
						_maximized = false;
						onRestored();
						break;
					case SDL_WINDOWEVENT_ENTER:
						onMouseEnter();
						break;
					case SDL_WINDOWEVENT_LEAVE:
						onMouseLeave();
						break;
					case SDL_WINDOWEVENT_FOCUS_GAINED:
						_hasFocus = true;
						onFocusGained();
						break;
					case SDL_WINDOWEVENT_FOCUS_LOST:
						_hasFocus = false;
						onFocusLost();
						break;
					case SDL_WINDOWEVENT_CLOSE:
						bool cancelled = false;
						onClosing(&cancelled);
						if (!cancelled)
						{
							onClosed();
							Dispose();
						}
						break;
					case SDL_WINDOWEVENT_TAKE_FOCUS:
						onFocusOffered();
						break;
					case SDL_WINDOWEVENT_HIT_TEST:
						onHitTest();
						break;
					default:
						debug stderr.writefln!"Unhandled window event: 0x%X"(event.window.event);
						break;
				}
				break;
			case SDL_KEYDOWN:
				onKeyDown(event.key);
				break;
			case SDL_KEYUP:
				onKeyUp(event.key);
				break;
			case SDL_TEXTEDITING:
				onTextEditing(event.edit);
				break;
			case SDL_TEXTINPUT:
				onTextInput(event.text);
				break;
			case SDL_MOUSEMOTION:
				onMouseMove(event.motion);
				break;
			case SDL_MOUSEBUTTONDOWN:
				onMouseDown(event.button);
				break;
			case SDL_MOUSEBUTTONUP:
				onMouseUp(event.button);
				break;
			case SDL_MOUSEWHEEL:
				onMouseWheel(event.wheel);
				break;
			case SDL_DROPBEGIN:
				
				break;
			case SDL_DROPTEXT:
				
				break;
			case SDL_DROPFILE:
				
				break;
			case SDL_DROPCOMPLETE:
				
				break;
			default:
				writeln(format!"Unhandled event: %d"(event.type));
				break;
		}
	}
	
	//endregion

	//region Functions
	public Event!Window shownFirstTime;
	private bool firstTimeShowing = true;
	public void show(Window owner = null)
	{
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
			shownFirstTime(this);
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

	//region onEvent(...) Functions
	protected void onShown()
	{
		visibleChanged(this);
	}

	protected void onHidden()
	{
		visibleChanged(this);
	}

	public Event!Window exposed;
	protected void onExposed()
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

	public Event!(Window, SDL_KeyboardEvent) keyDown;
	protected void onKeyDown(ref SDL_KeyboardEvent event)
	{
		keyDown(this, event);
	}

	public Event!(Window, SDL_KeyboardEvent) keyUp;
	protected void onKeyUp(ref SDL_KeyboardEvent event)
	{
		keyUp(this, event);
	}

	public Event!(Window, SDL_TextEditingEvent) textEditing;
	protected void onTextEditing(ref SDL_TextEditingEvent event)
	{
		auto str = fromStringz(event.text.ptr).idup();
		textEditing(this, event);
	}

	public Event!(Window, SDL_TextInputEvent) textInput;
	protected void onTextInput(ref SDL_TextInputEvent event)
	{
		auto str = fromStringz(event.text.ptr).idup();
		textInput(this, event);
	}

	public Event!(Window, SDL_MouseMotionEvent) mouseMove;
	protected void onMouseMove(ref SDL_MouseMotionEvent event)
	{
		mouseMove(this, event);
	}

	public Event!(Window, SDL_MouseButtonEvent) mouseDown;
	protected void onMouseDown(ref SDL_MouseButtonEvent event)
	{
		mouseDown(this, event);
	}

	public Event!(Window, SDL_MouseButtonEvent) mouseUp;
	protected void onMouseUp(ref SDL_MouseButtonEvent event)
	{
		mouseUp(this, event);
	}

	public Event!(Window, SDL_MouseWheelEvent) mouseWheel;
	protected void onMouseWheel(ref SDL_MouseWheelEvent event)
	{
		mouseWheel(this, event);
	}

	public Event!(Window, string) textDrop;
	protected void onTextDrop(string text)
	{
		textDrop(this, text);
	}

	public Event!(Window, string[]) fileDrop;
	protected void onFileDrop(string[] files)
	{
		fileDrop(this, files);
	}

	public Event!Window draw;
	protected void onDraw()
	{
		SDL_GL_MakeCurrent(sdlWindow, Application.getSharedGLContext(sdlWindow));
		glViewport(0, 0, _bounds.width, _bounds.height);
		glScissor(0, 0, _bounds.width, _bounds.height);
		glClearColor(0.5f, 0.5f, 1f, 1f);
		glClear(GL_COLOR_BUFFER_BIT | GL_STENCIL_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
		SDL_GL_SwapWindow(sdlWindow);
	}
	//endregion

	//region IDisposable implementation
	protected bool _disposed = false; //To detect redundant calls
	public bool disposed() @property
	{
		return _disposed;
	}
	
	protected void Dispose(bool disposing)
	{
		if (!_disposed)
		{
			if (disposing)
			{
				//TODO: dispose managed state (managed objects).
			}

			//Free unmanaged resources (unmanaged objects), set large fields to null.
			if (sdlWindow !is null)
			{
				SDL_DestroyWindow(sdlWindow);
				sdlWindow = null;
				systemWindowInfoExist = false;
			}
			
			_disposed = true;
		}
	}
	
	//Override a destructor only if Dispose(bool disposing) above has code to free unmanaged resources.
	public ~this()
	{
		//Do not change this code. Put cleanup code in Dispose(bool disposing) above.
		Dispose(false);
	}
	
	//This code added to correctly implement the disposable pattern.
	public void Dispose()
	{
		import core.memory : GC;
		//Do not change this code. Put cleanup code in Dispose(bool disposing) above.
		Dispose(true);
		//Uncomment the following line if the destructor is overridden above.
		GC.clrAttr(cast(void*)this, GC.BlkAttr.FINALIZE);
		//FIXME: D runtime currently doesn't give a shit about GC.BlkAttr.FINALIZE so it's actually pointless
	}
	//endregion
}
