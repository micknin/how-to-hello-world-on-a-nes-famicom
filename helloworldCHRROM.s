
;  ███████████████████████████████████████████████████████████████████████████
;██      ►this is a code that writes "HELLO, WORLD!" on the NES/famicom◄    ██
;██                                                                         ██
;██ •this is the version that uses CHR ROM                                  ██
;██                                                                         ██
;██ •this code uses CC65 as compiler (converts this .S file to a .NES file) ██
;██ →you can use the "chrROM assembler.bat" file to compile the code        ██
;██ →cc65 link: https://cc65.github.io/                                     ██
;██                          ♦written by micknin, on github. 21/04/2025♦    ██
;███████████████████████████████████████████████████████████████████████████  

.segment "HEADER" ;This segment is only for the NES compiler and emulators. 
                  ;It's like the specifications of the physical cartridge, such as the mapper type, for example.
                  ;→see https://www.nesdev.org/wiki/INES for more details.

.byte "NES" ;identification string for NES emulators
.byte $1A
.byte $02
.byte $01
.byte %00000000 	;mapper and mirroing;01
.byte $00
.byte $08

.segment "VECTORS" ;this segment defines the values of the RESET, NMI and IRQ vector addresses in addr $FFFA to addr $FFFF in rom 
                   ;(the 6502 CPU uses these addresses to know where to jump when some type of interruption occurs, like the reset,nmi and irq)

.addr nmi

.addr reset

;.addr irq ;;only a few mappers, like the MMC3 or the MMC5 can use this interruption... I think, :^


.segment "STARTUP" ;here is a good place to put data and variables, but also works if you put in the "CODE" segment

textmsg: ;the hello world msg
.byte $08,$05,$0c,$0c,$0f,$1d,$00,$17,$0f,$12,$0c,$04,$1b

;-----ppu registers----; (ppu means "picture processing unit". is basically the NES "gpu".)
;PPU registers extend from the address $2000 to $2007, and one at the address $4014
;oamdma is at the address $4014, along with APU registers and I/O controller port.
;→see https://www.nesdev.org/wiki/PPU_programmer_reference for more details.
ppuctrl .set $2000
ppumask .set $2001
ppustatus .set $2002
oamaddr .set $2003
oamdata .set $2004
ppuscroll .set $2005
ppuaddr .set $2006
ppudata .set $2007
oamdma .set $4014


;-----cpu RAM variables----;
framecounter .set $ff

.segment "CODE" ;the assembly code starts here :D

reset: ;the code starts here!
ldx #$ff ;loads the value FF to X 
txs ;sets the CPU stack pointer position (sp) to $ff (the CPU stack goes from addr $0100 to $01ff) using value in X

resetRAM: ;this code resets the RAM
lda #$01 ;loads the value 01 to A
sta $01 ;store the value in A at addr $01 
lda #$00 ;loads the value 00 to A
sta $00 ;store the value in A at addr $00
tay ;transfer the value in A to Y
ldx #$07 ;you know, loads the value 07 to X.
: ;resets addr $0100 to $07ff (change everything to the value 00)
sta ($00),y ;uses the values in addr $00 and $01 to create a 16bit addr(two bytes), sums with the value in Y, and stores the value in A on that 16bit addr
iny ;increment/add +1 to Y
bne :- ;jumps to a specified position if the value is not 00 (in this case, ":-" indicates that it is to jump to the next ":" above(-3 lines). If it was a ":+", it would indicate to jump to the next ":" at the bottom)
inc $01 ;increment/add +1 to the addr $01
dex ;decrease/subtract -1 from X
bne :-
: ;resets zero page ($00 to $ff)
sta $00,y ;store the value in A at addr $00+Y (Ex: if it was a "STA $02,Y", and the value in Y was 03, it would store the value in A at addr $05)
iny
bne :-


ppustarttime: ;wait 3 frames for the PPU "wake up".
ldx #$03
:
lda ppustatus ;loads the value in ppustatus (addr $2002) to A
beq :-
dex
bne :-


lda #$00 ;disables the NMI and the background display (when the VRAM is changed at the same time that an image is displayed on the screen, the ppu address gets corrupted, and causes errors in the displayed image.)
sta ppuctrl
sta ppumask

tilereset: ;resets only the first nametable
lda #$20
sta ppuaddr
lda #$00
sta ppuaddr ;the first nametable goes from addr $2000 to $27FF in VRAM
tax
ldy #$04
:
sta ppudata
inx
bne :-
dey
bne :-

palettereset:
lda #$3f
sta ppuaddr 
lda #$00
sta ppuaddr ;the palette address in VRAM goes from addr $3F00 to addr $3F1F
lda #$0f
ldx #$20
:
sta ppudata
dex
bne :-

printmsg: ;FINALLY!; prints the text "HELLO, WORLD!" in the nametable (screen)
lda #$20
sta ppuaddr
lda #$42
sta ppuaddr
ldx #$00
:
lda textmsg,x ;loads the bytes in textmsg in A. the address position is added with the value in X
sta ppudata
inx
cpx #$0d ;number of bytes in textmsg
bne :-

copypalette: ;this code loads the correct palette in the VRAM
lda #$3f
sta ppuaddr
lda #$00
sta ppuaddr
tax
:
lda palette,x
sta ppudata
inx
cpx #$20
bne :-


lda #$00
sta ppuscroll ;sets the x position of the screen to 00
sta ppuscroll ;sets the y position of the screen to 00 (you need to write in ppuscroll 2 times, like ppuaddr. first write the value of x position in ppuscroll, then the y position)
sta ppuaddr 
sta ppuaddr ;sets the ppuaddr to 0000, because the ppuaddr interferes with the screen position (it’s a hardware "error")

lda #$80
sta ppuctrl ;enables the NMI (every time the PPU finishes a frame, it will send a signal to the CPU to jump to a specific location address)
lda #$08
sta ppumask ;enable the background


end: ;wait for the NMI signal
jmp end

nmi: ;if the NMI happens, the CPU jumps here :3
inc framecounter ;adds +1 to the framecounter 
rti ;the CPU returns to where it was before NMI happened

palette:
.byte $0C,$1B,$2A,$39,$0C,$0F,$0F,$0F,$0C,$0F,$0F,$0F,$0C,$0F,$0F,$0F ;background
.byte $0C,$13,$24,$36,$0C,$0F,$0F,$0F,$0C,$0F,$0F,$0F,$0C,$0F,$0F,$0F ;sprites

.segment "CHARS"

chrfont: ;the CHR font data, in 2BPP format (2 bits per pixel; 4 colors per pixel)
.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$3C,$F7,$F7,$FF,$F7,$E3,$00,$00,$7E,$62,$62,$7E,$62,$62,$62,$00,$3A,$F6,$F4,$FA,$F4,$F6,$3A,$00,$7C,$62,$62,$7C,$62,$62,$7C,$00,$3C,$F4,$E0,$E0,$E0,$F4,$3C,$00,$7E,$62,$60,$60,$60,$62,$7E,$00,$38,$F4,$E3,$E3,$E3,$F4,$38,$00,$7C,$62,$62,$62,$62,$62,$7C,$00,$3C,$F0,$F0,$FA,$F0,$F0,$3C,$00,$7E,$60,$60,$7C,$60,$60,$7E,$00,$3C,$F0,$F0,$FC,$F0,$E0,$00,$00,$7E,$60,$60,$7E,$60,$60,$60,$00,$3A,$F4,$E0,$E0,$E4,$34,$5A,$00,$7C,$62,$60,$60,$6E,$62,$3C,$00,$00,$E3,$F7,$FF,$F7,$E3,$00,$00,$62,$62,$62,$7E,$62,$62,$62,$00,$00,$3C,$3C,$3C,$3C,$3C,$00,$00,$18,$18,$18,$18,$18,$18,$18,$00,$3C,$3C,$1C,$1C,$1C,$30,$48,$00,$7E,$18,$18,$18,$18,$58,$30,$00,$00,$F7,$F4,$FA,$F4,$F7,$00,$00,$62,$62,$66,$7C,$66,$62,$62,$00,$00,$E0,$E0,$E0,$E0,$F0,$3C,$00,$60,$60,$60,$60,$60,$60,$7E,$00,$20,$FF,$F7,$FF,$E3,$E3,$00,$00,$76,$76,$7E,$6A,$6A,$62,$62,$00,$00,$EB,$FF,$FF,$EB,$E7,$00,$00,$62,$72,$7A,$6E,$66,$62,$62,$00,$3C,$F7,$E3,$E3,$E3,$F7,$3C,$00,$7E,$62,$62,$62,$62,$62,$7E,$00,$38,$F4,$F4,$F8,$F0,$E0,$00,$00,$7C,$62,$62,$7C,$60,$60,$60,$00,$3C,$F7,$E3,$E3,$E7,$FF,$3E,$00,$7E,$62,$62,$62,$6A,$66,$7F,$00,$38,$F4,$F4,$FA,$F4,$E2,$00,$00,$7C,$62,$62,$7C,$62,$62,$62,$00,$3C,$F0,$F0,$3C,$07,$07,$3C,$00,$7E,$60,$60,$7E,$02,$02,$7E,$00,$3C,$3C,$18,$18,$18,$18,$00,$00,$7E,$18,$18,$18,$18,$18,$18,$00,$00,$E3,$E3,$E3,$E3,$F7,$3C,$00,$62,$62,$62,$62,$62,$62,$7E,$00,$00,$32,$64,$72,$1C,$38,$04,$00,$62,$62,$32,$34,$34,$1C,$18,$00,$00,$E3,$E3,$FF,$F7,$FF,$20,$00,$62,$62,$6A,$6A,$7E,$76,$76,$00,$64,$3E,$7C,$3C,$7C,$3E,$44,$00,$42,$64,$38,$18,$38,$64,$42,$00,$00,$E3,$37,$1F,$07,$04,$1A,$00,$62,$62,$62,$3E,$02,$02,$3C,$00,$BA,$0C,$12,$3C,$48,$30,$5D,$00,$7C,$06,$0C,$18,$30,$60,$3E,$00,$3C,$3C,$3C,$3C,$18,$3C,$18,$18,$18,$18,$18,$18,$00,$18,$00,$00,$58,$B4,$83,$64,$00,$08,$00,$00,$3C,$62,$62,$02,$0C,$08,$08,$00,$00,$00,$00,$00,$08,$18,$08,$00,$00,$00,$00,$00,$18,$08,$10,$00,$00,$00,$00,$00,$00,$18,$18,$00,$00,$00,$00,$00,$00,$30,$30,$02,$0E,$04,$18,$18,$20,$70,$40,$06,$04,$08,$08,$10,$10,$20,$60,$40,$70,$20,$18,$18,$04,$0E,$02,$60,$20,$10,$10,$08,$08,$04,$06,$00,$3C,$FF,$F3,$EB,$E7,$FF,$3C,$00,$7E,$72,$6A,$6A,$6A,$66,$7E,$00,$20,$5C,$BC,$3C,$1C,$1C,$00,$00,$18,$38,$78,$18,$18,$18,$18,$00,$5A,$B4,$87,$08,$2A,$58,$BD,$00,$3C,$62,$62,$06,$1C,$30,$7E,$00,$5C,$17,$03,$16,$03,$17,$5C,$00,$3E,$62,$06,$0C,$06,$62,$3E,$00,$00,$63,$37,$5F,$07,$03,$00,$00,$62,$62,$62,$3E,$02,$02,$02,$00,$3D,$F0,$F0,$5A,$07,$37,$5A,$00,$7E,$60,$60,$3C,$02,$62,$3C,$00,$0C,$18,$30,$F8,$F7,$37,$18,$00,$1E,$30,$60,$7C,$62,$62,$3C,$00,$BC,$0E,$08,$1C,$08,$30,$10,$00,$7E,$04,$04,$08,$10,$10,$20,$00,$5A,$34,$76,$5A,$76,$34,$5A,$00,$3C,$62,$62,$3C,$62,$62,$3C,$00,$5A,$34,$37,$5F,$0C,$1A,$14,$00,$3C,$62,$62,$3E,$06,$0C,$38,$00,$00,$00,$00,$00,$00,$00,$3A,$00,$00,$00,$00,$00,$00,$00,$7C,$00,$00,$0C,$0C,$00,$00,$0C,$0C,$00,$00,$18,$18,$00,$00,$18,$18,$00,$00,$00,$00,$0C,$00,$00,$00,$00,$00,$00,$00,$18,$00,$00,$00,$00,$00,$00,$08,$0C,$08,$00,$00,$00,$00,$00,$08,$18,$08,$00,$00,$00,$5A,$24,$42,$4C,$52,$20,$5A,$00,$3C,$42,$5A,$5A,$4C,$40,$3C

;end :>