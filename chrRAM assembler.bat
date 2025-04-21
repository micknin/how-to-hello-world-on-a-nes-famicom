mode 128,32
::you can change the file path to wherever you want, as long as the .s file is in the same folder
C:\cc65\bin\ca65 C:\code\helloworldCHRRAM.s -o C:\code\helloworldCHRRAM.o -t nes
C:\cc65\bin\ld65 C:\code\helloworldCHRRAM.o -o C:\code\helloworldCHRRAM.nes -t nes
pause 
exit