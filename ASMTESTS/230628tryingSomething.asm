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

SQR1_VOL    =   $4000	; APU
SQR1_SWEEP  =   $4001
SQR1_LO     =   $4002
SQR1_HI     =   $4003
DMC_CONFIG  =   $4010
CONTROLLER_1=   $4016
APU_STATUS  =   $4015
APU_FRAMES  =   $4017

;my variables

BG_COLOR    =   $0c
BG_TIMER    =   $0d
CURSOR_X    =   $0e
CURSOR_Y    =   $0f

INPUT_BREAK =   $10
INPUT_COUNT =   $11
INPUT_TEMP  =   $12
INPUT_1     =   $13

SCROLL_X    =   $1e
SCROLL_Y    =   $1f

BOARD_START =   $20
H_CHECKS    =   $30
V_CHECKS    =   $33
D_CHECKS    =   $36

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

main:

load_palletes:
 lda PPU_STATUS
 lda #$3f
 sta PPU_ADDR
 lda #$10
 sta PPU_ADDR

 ldx #$00
 @loop:
 lda palletes,x
 sta PPU_DATA
 inx
 cpx #$20
 bne @loop

 

load_sprites:
 lda #$00
 sta OAM_ADDR
 sta OAM_ADDR
 ldx #$00
 @loop:
 lda #$00
 sta OAM_DATA
 lda #$0a
 sta OAM_DATA
 lda #%00100000
 sta OAM_DATA
 lda #$00
 sta OAM_DATA
 inx
 cpx #$40
 bne @loop

load_backgroud:
 lda #$20
 sta PPU_ADDR
 lda #$00
 sta PPU_ADDR
 lda #$0a

 ldy #$00
 @loop_y:
 lda #$0a
 @loop_x:
 sta PPU_DATA
 inx
 cpx #$00
 bne @loop_x
 iny
 cpy #$08
 bne @loop_y

 lda #$0d
 sta BG_COLOR

 ;patterns
 lda #$23
 sta PPU_ADDR
 lda #$c0
 sta PPU_ADDR

 lda #%01010101
 @loop_patterns:
 sta PPU_DATA

 inx
 cpx #$40
 bne @loop_patterns

 ;init board
	;odd rows
 lda #$01
 sta $01
 ldx #$00
 stx $00
 @loop_odd:
 lda #$20
 sta PPU_ADDR
 lda $01
 clc
 adc $00
 sta PPU_ADDR
 lda #$0b
 sta PPU_DATA
 lda #$0a
 sta PPU_DATA
 lda #$0b
 sta PPU_DATA

 lda $00
 adc #$40
 sta $00

 inx
 cpx #$03
 bne @loop_odd
 
 lda #$85	;scroll
 sta SCROLL_X
 lda #$90
 sta SCROLL_Y
 

enable_rendering:
 lda #%00000001
 sta PPU_CTRL
 lda #%00011110
 sta PPU_MASK

init_sound:
 lda #$01
 sta APU_STATUS
 lda #$00
 sta SQR1_SWEEP
 lda #$40
 sta APU_FRAMES

game_loop:

frameDo:

controller:
 lda #$01	;init controller
 sta CONTROLLER_1
 sta INPUT_TEMP
 lda #$00
 sta CONTROLLER_1
 
 @controller_loop:
 lda CONTROLLER_1
 lsr
 rol INPUT_TEMP
 bcc @controller_loop
 lda INPUT_TEMP
 sta INPUT_1

 bit $2002
 bmi vBlankDo
 jmp game_loop

vBlankDo:
 jsr set_scroll

 jsr render_bg_default_color

 jmp game_loop

set_scroll:
 lda SCROLL_X
 sta PPU_SCROLL
 lda SCROLL_Y
 sta PPU_SCROLL
 rts

set_input_break:
 lda #$01
 sta INPUT_BREAK
 inc INPUT_COUNT
 rts

render_bg_default_color:
 lda PPU_STATUS	;default background color
 lda #$3f
 sta PPU_ADDR
 lda #$00
 sta PPU_ADDR
 lda BG_COLOR
 sta PPU_DATA
 rts

nmi:
 rti

;palletes and stuff
palletes:
;oem sprites
 .byte $0f, $01, $11, $21
 .byte $0f, $03, $13, $23
 .byte $0f, $04, $14, $24
 .byte $0f, $06, $16, $26
;background
 .byte $0f, $01, $11, $21
 .byte $0f, $03, $13, $23
 .byte $0f, $04, $14, $24
 .byte $0f, $06, $16, $26

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
  .byte %00011110
  .byte %00011100
  .byte %00011100
  .byte %00011110
  .byte %00011010
  .byte %00001110
  .byte %00000000
  .byte %00000000;
  .byte %00011110
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