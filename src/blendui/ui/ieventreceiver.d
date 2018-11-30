module blendui.ui.ieventreceiver;

import derelict.sdl2.types;

public interface IEventReceiver
{
	void handleEvent(SDL_Event event);
}
