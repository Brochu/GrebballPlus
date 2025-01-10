@echo off

cl.exe -nologo -std:c++20 -Zi -EHsc -Od -I.\include\ ^
.\src\main.cpp ^
-link -libpath:libs\ libcurl.lib dpp.lib ^
-out:Grebball++.exe


del main.obj
