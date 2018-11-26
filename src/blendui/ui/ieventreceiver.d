module blendui.ui.ieventreceiver;

import derelict.sdl2.types;

public interface IEventReceiver
{
	bool HandleEvent(SDL_Event event);
}
