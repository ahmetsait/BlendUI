import std.stdio : write, writeln, stderr;
import std.format : format;

import derelict.sdl2.sdl;
import blendui.graphics.gl;

import blendui.application;
import blendui.core;
import blendui.events;
import blendui.math;
import blendui.ui;

version(unittest)
void main()
{
	writeln("----------------------\n.::Done unittesting::.");
}
else
int main(string[] args)
{
	Application.initialize();
	Window window = new Window("Blend UI Test", 640, 480);

	window.show();

	Application.run();

	Application.terminate();

	return 0;
}
