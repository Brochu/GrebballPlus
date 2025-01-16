@echo off
odin build . -out:odin_app.exe -debug -define:TRACK_MEM=true
