@echo off
SET debug=""

:: Loop through all arguments
for %%A in (%*) do (
    if "%%A"=="-d" (
        set debug="-Zi"
    )
)

cl.exe -nologo -std:c++20 %debug% -EHsc -Od -I.\include\ ^
.\src\main.cpp ^
-link -libpath:libs\ libcurl.lib dpp.lib ^
-out:Grebball++.exe


del main.obj
