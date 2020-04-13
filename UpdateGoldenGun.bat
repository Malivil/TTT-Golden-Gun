@echo off
set /p changes="Enter Changes: "
"C:\Program Files (x86)\Steam\steamapps\common\GarrysMod\bin\gmpublish.exe"  update -addon "TTT-Golden-Gun.gma" -id "2055695161" -changes "%changes%"
pause