mode 128,32
::you can change the file path to wherever you want, as long as the .s file is in the same folder
C:\cc65\bin\ca65 C:\code\helloworldCHRROM.s -o C:\code\helloworldCHRROM.o -t nes
C:\cc65\bin\ld65 C:\code\helloworldCHRROM.o -o C:\code\helloworldCHRROM.nes -t nes
pause 
exit