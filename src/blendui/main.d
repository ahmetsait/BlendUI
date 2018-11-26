import std.stdio;
import std.format;

import derelict.sdl2.sdl;
import derelict.opengl3.gl3;

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

	Window window = new Window("Blend UI Test", 1600, 900);

	Application.run(window);
	
	Application.terminate();

	return 0;
}