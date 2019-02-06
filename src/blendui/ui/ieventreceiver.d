module blendui.ui.ieventreceiver;

import derelict.sdl2.types;

public interface IEventReceiver
{
	bool handleEvent(ref SDL_Event event);
}
