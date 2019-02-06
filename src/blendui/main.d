import std.format : format;
import std.stdio : write, writeln, stderr;

import blendui.application;
import blendui.core;
import blendui.events;
import blendui.graphics.gl;
import blendui.math;
import blendui.ui;

import derelict.sdl2.sdl;
import gfm.math.vector;

version(unittest)
void main()
{
	writeln("----------------------\n.::Done unittesting::.");
}
else
int main(string[] args)
{
	Application.initialize();
	{
		Window window = new Window("Blend UI Test", 400, 400);
		GridLayout grid = new GridLayout;
		Button.default_ForeColor = vec4f(0.5, 0.5, 1, 1);
		Button button = new Button;
		grid.addWidget(button, Rectangle!int(0, 0, 400, 200));
		window.widget = grid;
		window.show();
	}
	Application.run();
	Application.terminate();

	return 0;
}
