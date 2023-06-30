;VARIABLES

PPU_CTRL    =   $2000	; PPU
PPU_MASK    =   $2001
PPU_STATUS  =   $2002	;can be used for vBlank checks
OAM_ADDR    =   $2003
OAM_DATA    =   $2004
PPU_SCROLL  =   $2005
PPU_ADDR    =   $2006
PPU_DATA    =   $2007
OAM_DMA     =   $4014

SQR1_VOLUME =   $4000	; APU
SQR1_SWEEP  =   $4001
SQR1_LOW    =   $4002
SQR1_HIGH   =   $4003
SQR2_VOLUME =   $4004
SQR2_SWEEP  =   $4005
SQR2_LOW    =   $4006
SQR2_HIGH   =   $4007
DMC_CONFIG  =   $4010
CONTROLLER_1=   $4016
APU_STATUS  =   $4015
APU_FRAMES  =   $4017

MUSIC_1_VOL =   $00	;my variables
MUSIC_1_LOW =   $01
MUSIC_1_HIGH=   $02
MUSIC_1_TICK=   $03
MUSIC_1_MAX =   $04
MUSIC_2_VOL =   $05
MUSIC_2_LOW =   $06
MUSIC_2_HIGH=   $07
MUSIC_2_TICK=   $08
MUSIC_2_MAX =   $09

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

; Main code segement for the program
.segment "CODE"

reset:
  sei		; disable IRQs
  cld		; disable decimal mode
  ldx #$40
  stx APU_FRAMES; disable APU frame IRQ
  ldx #$ff 	; Set up stack
  txs		;  .
  inx		; now X = 0
  stx PPU_CTRL	; disable NMI
  stx PPU_MASK 	; disable rendering
  stx DMC_CONFIG; disable DMC IRQs

;; first wait for vblank to make sure PPU is ready
vblankwait1:
  bit PPU_STATUS
  bpl vblankwait1

clear_memory:
  lda #$00
  sta $0000, x
  sta $0100, x
  sta $0200, x
  sta $0300, x
  sta $0400, x
  sta $0500, x
  sta $0600, x
  sta $0700, x
  inx
  bne clear_memory

;; second wait for vblank, PPU is ready after this
vblankwait2:
  bit PPU_STATUS
  bpl vblankwait2

;████████████████████████████████████████████████████████████████

main:

init_sound:
 lda #%00000011		;music n stuff
 sta APU_STATUS
 lda #%00000000
 sta SQR1_SWEEP
 sta SQR2_SWEEP
 lda #$40
 sta APU_FRAMES


;████████████████████████████████████████████████████████████████

game_loop:

frame_do_once:

process_music:

 lda APU_STATUS
 and #%00000001
 cmp #%00000001
 beq @not_halted_1

 ldx MUSIC_1_TICK
 cpx MUSIC_1_MAX
 bne @not_max_1
 ldx #$00

 lda music_1_low
 sta MUSIC_1_MAX
 lda music_1_high
 sta MUSIC_1_VOL

 @not_max_1:
 inx
 stx MUSIC_1_TICK

 lda MUSIC_1_VOL
 sta SQR1_VOLUME

 lda music_1_low, x
 sta SQR1_LOW
 lda music_1_high, x
 sta SQR1_HIGH

 @not_halted_1:

;████████████████████████████████████████████████████████████████

 lda APU_STATUS
 and #%00000010
 cmp #%00000010
 beq @not_halted_2

 ldx MUSIC_2_TICK
 cpx MUSIC_2_MAX
 bne @not_max_2
 ldx #$00

 lda music_2_low
 sta MUSIC_2_MAX
 lda music_2_high
 sta MUSIC_2_VOL

 @not_max_2:
 inx
 stx MUSIC_2_TICK

 lda MUSIC_2_VOL
 sta SQR2_VOLUME

 lda music_2_low, x
 sta SQR2_LOW
 lda music_2_high, x
 sta SQR2_HIGH

 @not_halted_2:

;████████████████████████████████████████████████████████████████

frame_loop:

 bit PPU_STATUS
 bmi vBlankDo
 
 jmp frame_loop

vBlankDo:
 jmp game_loop

nmi:
 rti

;████████████████████████████████████████████████████████████████

;stuff

music_1_low:	;first one is duration
 .byte $1a
 .byte $fe, $53, $7c, $ab, $ab, $c4, $c4
 .byte $53, $7c, $ab, $c4, $c4, $fc, $fc
 .byte $fe, $53, $7c, $ab, $ab, $c4, $c4
 .byte $53, $7c, $ab, $c4, $fc
music_1_high:	;first one is volume
 .byte %00011000
 .byte %01010000, %00010001, %00100001, %00100001, %00100001, %00100001, %00110001
 .byte %01010001, %00010001, %00100001, %00100001, %00100001, %00100001, %00110001
 .byte %01010000, %00010001, %00100001, %00100001, %00100001, %00100001, %00110001
 .byte %01010001, %00010001, %00100001, %00100001, %01000001

music_2_low:	;same format
 .byte $08
 .byte $f8, $a6, $f8, $a6
 .byte $a6, $88, $a6, $88
music_2_high:
 .byte %00011000
 .byte %00110011, %00110010, %00110011, %00110010
 .byte %00110010, %00110011, %00110010, %00110011

;████████████████████████████████████████████████████████████████

; Character memory
.segment "CHARS"

  .byte %00000000; 0
  .byte %00001100
  .byte %00011110
  .byte %00011010
  .byte %00011010
  .byte %00011010
  .byte %00001100
  .byte %00000000
  .byte %00000000;
  .byte %00001100
  .byte %00010010
  .byte %00010010
  .byte %00010010
  .byte %00010010
  .byte %00001100
  .byte %00000000

  .byte %00000000; 1
  .byte %00001000
  .byte %00011000
  .byte %00001000
  .byte %00001000
  .byte %00001000
  .byte %00011100
  .byte %00000000
  .byte %00000000;
  .byte %00001000
  .byte %00011000
  .byte %00001000
  .byte %00001000
  .byte %00001000
  .byte %00011100
  .byte %00000000

  .byte %00000000; 2
  .byte %00001100
  .byte %00011010
  .byte %00000010
  .byte %00001110
  .byte %00011000
  .byte %00011110
  .byte %00000000
  .byte %00000000;
  .byte %00001100
  .byte %00010010
  .byte %00000010
  .byte %00001100
  .byte %00010000
  .byte %00011110
  .byte %00000000

  .byte %00000000; 3
  .byte %00001100
  .byte %00011010
  .byte %00000110
  .byte %00000010
  .byte %00010010
  .byte %00001110
  .byte %00000000
  .byte %00000000;
  .byte %00001100
  .byte %00010010
  .byte %00000100
  .byte %00000010
  .byte %00010010
  .byte %00001100
  .byte %00000000

  .byte %00000000; 4
  .byte %00011010
  .byte %00011010
  .byte %00011010
  .byte %00011110
  .byte %00000010
  .byte %00000010
  .byte %00000000
  .byte %00000000;
  .byte %00010010
  .byte %00010010
  .byte %00010010
  .byte %00011110
  .byte %00000010
  .byte %00000010
  .byte %00000000

  .byte %00000000; 5
  .byte %00011110
  .byte %00011100
  .byte %00011100
  .byte %00000010
  .byte %00011010
  .byte %00001110
  .byte %00000000
  .byte %00000000;
  .byte %00011110
  .byte %00010000
  .byte %00011100
  .byte %00000010
  .byte %00010010
  .byte %00001100
  .byte %00000000

  .byte %00000000; 6
  .byte %00001110
  .byte %00011100
  .byte %00011100
  .byte %00011110
  .byte %00011010
  .byte %00001110
  .byte %00000000
  .byte %00000000;
  .byte %00001110
  .byte %00010000
  .byte %00011100
  .byte %00010010
  .byte %00010010
  .byte %00001100
  .byte %00000000

  .byte %00000000; 7
  .byte %00011110
  .byte %00000010
  .byte %00000110
  .byte %00000110
  .byte %00001100
  .byte %00001100
  .byte %00000000
  .byte %00000000;
  .byte %00011110
  .byte %00000010
  .byte %00000100
  .byte %00000100
  .byte %00001000
  .byte %00001000
  .byte %00000000

  .byte %00000000; 8
  .byte %00001100
  .byte %00011110
  .byte %00001100
  .byte %00011110
  .byte %00011010
  .byte %00001100
  .byte %00000000
  .byte %00000000;
  .byte %00001100
  .byte %00010010
  .byte %00001100
  .byte %00010010
  .byte %00010010
  .byte %00001100
  .byte %00000000

  .byte %00000000; 9
  .byte %00001110
  .byte %00011110
  .byte %00011010
  .byte %00001110
  .byte %00000010
  .byte %00000010
  .byte %00000000
  .byte %00000000;
  .byte %00001110
  .byte %00010010
  .byte %00010010
  .byte %00001110
  .byte %00000010
  .byte %00000010
  .byte %00000000


  .byte %00000000; nada
  .byte %00000000
  .byte %00000000
  .byte %00000000
  .byte %00000000
  .byte %00000000
  .byte %00000000
  .byte %00000000
  .byte %00000000;
  .byte %00000000
  .byte %00000000
  .byte %00000000
  .byte %00000000
  .byte %00000000
  .byte %00000000
  .byte %00000000

  .byte %11111111; border
  .byte %11111111
  .byte %11111111
  .byte %11111111
  .byte %11111111
  .byte %11111111
  .byte %11111111
  .byte %11111111
  .byte %11111111;
  .byte %11111111
  .byte %11111111
  .byte %11111111
  .byte %11111111
  .byte %11111111
  .byte %11111111
  .byte %11111111

  .byte %00000000; x
  .byte %00000000
  .byte %00000000
  .byte %00000000
  .byte %00000000
  .byte %00000000
  .byte %00000000
  .byte %00000000
  .byte %11000011;
  .byte %01100110
  .byte %00111100
  .byte %00011000
  .byte %00011000
  .byte %00111100
  .byte %01100110
  .byte %11000011

  .byte %00000000; o
  .byte %00000000
  .byte %00000000
  .byte %00000000
  .byte %00000000
  .byte %00000000
  .byte %00000000
  .byte %00000000
  .byte %00111100;
  .byte %01100110
  .byte %11000011
  .byte %10000001
  .byte %10000001
  .byte %11000011
  .byte %01100110
  .byte %00111100