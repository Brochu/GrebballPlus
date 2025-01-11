@echo off
SET debug=""

:: Loop through all arguments
for %%A in (%*) do (
    if "%%A"=="-d" (
        set debug="-Zi"
    )
)

cl.exe -nologo -std:c++20 -Zi -EHsc -MDd -Od -DCURL_STATICLIB -I.\include\ ^
.\src\main.cpp ^
-link -NODEFAULTLIB:MSVCRT -libpath:libs\ ^
advapi32.lib crypt32.lib normaliz.lib ws2_32.lib wldap32.lib libcurl_a.lib ^
-out:Grebball++.exe

del main.obj
