module blendui.ui.window;

debug import std.stdio : write, writeln;
import std.string : toStringz, fromStringz;
import std.algorithm : clamp;

import derelict.sdl2.sdl;
import derelict.opengl3.gl3;

import blendui.core;
import blendui.events;
import blendui.math;
import blendui.ui;
import blendui.util;
import blendui.application;

enum WindowStartPosition : ubyte
{
	undefined		= 0,
	centerScreen	= 1,
	centerParent	= 2,
	manual			= 3,
}

interface IWindow
{
	//TODO
}

public class Window : ContainerWidget, IWindow, IEventReceiver, IDisposable
{
	private SDL_Window* window;
	public SDL_Window* getSdlWindow()
	{
		return window;
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
		bool change = false;
		auto old = _bounds;
		if (old.location != value.location)
		{
			_bounds.location = value.location;
			SDL_SetWindowPosition(window, _bounds.x, _bounds.y);
			locationChanged(this);
			change = true;
		}
		clampSize(value.size);
		if (old.size != value.size)
		{
			_bounds.size = value.size;
			SDL_SetWindowSize(window, _bounds.width, _bounds.height);
			sizeChanged(this);
			change = true;
		}
		if (change)
			boundsChanged(this);
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
			SDL_SetWindowPosition(window, _bounds.x, _bounds.y);
			locationChanged(this);
		}
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
			SDL_SetWindowSize(window, _bounds.width, _bounds.height);
			sizeChanged(this);
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
			SDL_SetWindowMaximumSize(window, _maxSize.width, _maxSize.height);
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
			SDL_SetWindowMinimumSize(window, _minSize.width, _minSize.height);
			minSizeChanged(this);
		}
	}

	private float _opacity = 1.0f;
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
			SDL_SetWindowOpacity(window, _opacity);
			opacityChanged(this);
		}
	}

	private bool _resizable = true;
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
			SDL_SetWindowResizable(window, _resizable);
			resizableChanged(this);
		}
	}

	private bool _borderless;
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
			SDL_SetWindowBordered(window, !_borderless);
			borderlessChanged(this);
		}
	}

	private bool _maximized;
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
				SDL_MaximizeWindow(window);
			else
				SDL_RestoreWindow(window);
			maximizedChanged(this);
		}
	}

	private bool _minimized;
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
				SDL_MinimizeWindow(window);
			else
				SDL_RestoreWindow(window);
			minimizedChanged(this);
		}
	}

	private bool _showInTaskBar = true;
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
			//TODO
			showInTaskBarChanged(this);
		}
	}

	private bool _visible;
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
				SDL_ShowWindow(window);
			else
				SDL_HideWindow(window);
			visibleChanged(this);
		}
	}

	private WindowStartPosition _startPosition = WindowStartPosition.centerParent;
	public WindowStartPosition startPosition() @property
	{
		return _startPosition;
	}
	public void startPosition(WindowStartPosition value) @property
	{
		_startPosition = value;
	}

	private string _title;
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
			SDL_SetWindowTitle(window, _title.toStringz());
			titleChanged(this);
		}
	}
	
	private int suspendLayout = 0;

	private Widget activeWidget;
	private Window owner;
	
	public this()
	{
		this("Window", 800, 600);
	}
	
	public this(string title, int width, int height)
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

		window = SDL_CreateWindow(
			title.toStringz(),
			bounds.x, bounds.y, bounds.width, bounds.height,
			windowFlags
		);
		window.enforceSDLNotNull("Could not create SDL window");

		Application.getSharedGLContext(window);
		Application.registerWindow(this);
	}

	private bool firstTimeShowing = true;
	public void show()
	{
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
		}
		_visible = true;
		SDL_ShowWindow(window);
	}

	public void hide()
	{
		_visible = false;
		SDL_HideWindow(window);
	}

	public bool HandleEvent(SDL_Event event)
	{
		return false;
	}

	/+
	 + IDisposable implementation
	 +/
	private bool disposed = false; //To detect redundant calls
	
	protected void Dispose(bool disposing)
	{
		if (!disposed)
		{
			if (disposing)
			{
				//TODO: dispose managed state (managed objects).
			}

			//Free unmanaged resources (unmanaged objects), set large fields to null.
			if (window !is null)
			{
				SDL_DestroyWindow(window);
				window = null;
			}
			
			disposed = true;
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
}
