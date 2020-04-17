"C:\Program Files (x86)\Steam\steamapps\common\GarrysMod\bin\gmad.exe" create -folder %1
echo Removing old file
del TTT-Golden-Gun.gma
echo Renaming file
ren %1.gma TTT-Golden-Gun.gma
pause