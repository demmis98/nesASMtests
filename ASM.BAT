for /f %%G in ('dir *.asm /b') do cl65 %%~G --verbose --target nes -o %%~G.nes
pause