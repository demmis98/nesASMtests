.segment "HEADER"
  ; .byte "NES", $1A      ; iNES header identifier
  .byte $4E, $45, $53, $1A
  .byte 2               ; 2x 16KB PRG code
  .byte 1               ; 1x  8KB CHR data
  .byte $01, $00        ; mapper 0, vertical mirroring

.segment "VECTORS"
  ;; When an NMI happens (once per frame if enabled) the label nmi:
  .addr nmi
  ;; When the processor first turns on or is reset, it will jump to the label reset:
  .addr reset
  ;; External interrupt IRQ (unused)
  .addr 0

; "nes" linker config requires a STARTUP section, even if it's empty
.segment "STARTUP"

.segment "CODE"

reset:
  lda #$00
  sta $00
  sta $01
  sta $02
  sta $03
  sta $04
  sta $05
  sta $06
  sta $41
  sta $42
  sta $44
 sta $69
  ldx #0
  jmp init_loop
init_loop:
  sta $4000,x
  inx
  cpx #$13
  bne init_loop
  sta $4015


main:
 ldx #10
 stx $00
 stx $01

init_apu:
 lda #$30
 sta $4000
 lda #$80
 sta $4001
 ; We have to skip over $4014 (OAMDMA)
 lda #$0F
 sta $4015
 lda #$08
 sta $4017
 
 lda #<279
 sta $4002
 sta $08
 lda #>279
 sta $09
 sta $4003

   lda #%10111111
   sta $4000
   jmp game_loop
        rts

game_loop:
 

controller:
 inc $10
 lda #$01 ;initialize controller
 sta $41
 sta $4016
 lda #$00
 sta $4016
 ldx #$00
controller_loop:
 lda $4016
 lsr a
 rol $41
 bcc controller_loop
 lda $41
 sta $42
audio:
 clc
 lda $42
 and #%00001000
 beq up
audio_continue:
 
 inc $69
 lda $44
 sta $4002

 jmp game_loop
up:
 inc $44
 jmp audio_continue


nmi:
; Character memory
.segment "CHARS"