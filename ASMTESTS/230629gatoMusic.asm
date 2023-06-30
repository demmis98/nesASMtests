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
DMC_CONFIG  =   $4010
CONTROLLER_1=   $4016
APU_STATUS  =   $4015
APU_FRAMES  =   $4017

;my variables

BG_TEMP_1   =   $00
BG_TEMP_2   =   $01
BG_COLOR    =   $02
BG_TIMER    =   $03

PRESS       =   $07
PRESS_BREAK =   $08

TURN        =   $09

CURSOR_TEMP =   $0a
CURSOR_COUNT=   $0b
CURSOR_BLINK=   $0c
CURSOR_X_Y  =   $0d
CURSOR_X    =   $0e
CURSOR_Y    =   $0f

INPUT_BREAK =   $10
INPUT_COUNT =   $11
INPUT_TEMP  =   $12
INPUT_1     =   $13

NAMETABLES  =   $1d
SCROLL_X    =   $1e
SCROLL_Y    =   $1f

BOARD_START =   $20
CHECKS_H    =   $30
CHECKS_V    =   $33
CHECKS_D    =   $36

CHECKS_1    =   $3d
CHECKS_2    =   $3e
CHECKS_3    =   $3f

BOARD_SPRITE   =   $40
BOARD_X_Y      =   $41
BOARD_WIN      =   $42
BOARD_X        =   $43
BOARD_Y        =   $44
BOARD_COUNT    =   $45

MUSIC_MAX      =   $4a
MUSIC_HIGH     =   $4c
MUSIC_TEMP     =   $4d
MUSIC_TIMER    =   $4e
MUSIC_COUNT    =   $4f

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
	;even rows
 lda #$01
 sta BG_TEMP_2
 ldx #$00
 stx BG_TEMP_1
 @loop_even:
 lda #$20
 sta PPU_ADDR
 clc
 lda BG_TEMP_1
 adc BG_TEMP_2
 sta PPU_ADDR
 lda #$0b
 sta PPU_DATA
 lda #$0a
 sta PPU_DATA
 lda #$0b
 sta PPU_DATA

 lda BG_TEMP_1
 adc #$40
 sta BG_TEMP_1

 inx
 cpx #$03
 bne @loop_even

	;odd rows
 lda #$20
 sta BG_TEMP_1
 ldy #$00
 @loop_odd_y:
 ldx #$00
 stx BG_TEMP_2
 @loop_odd_x:
 lda #$20
 sta PPU_ADDR
 clc
 lda BG_TEMP_1
 adc BG_TEMP_2
 sta PPU_ADDR
 
 lda #$0b
 sta PPU_DATA
 
 inx
 stx BG_TEMP_2
 cpx #$05
 bne @loop_odd_x

 clc
 lda BG_TEMP_1
 adc #$40
 sta BG_TEMP_1
 iny
 cpy #$02
 bne @loop_odd_y 

 
 lda #$95	;scroll
 sta SCROLL_X
 lda #$90
 sta SCROLL_Y
 

init_board:
 lda #$0a
 ldx #$00
 @loop_memory:
 sta BOARD_START, x
 
 inx
 cpx #$09
 bne @loop_memory

 lda #$0c	;turn
 sta TURN
 


enable_rendering:
 lda #%00000001 	;select nametables
 sta NAMETABLES
 sta PPU_CTRL
 lda #%00011110
 sta PPU_MASK


init_sound:
 lda #$01		;music n stuff
 sta APU_STATUS
 lda #%00000000
 sta SQR1_SWEEP
 sta SQR1_VOLUME
 lda #$40
 sta APU_FRAMES

 lda #%0010000
 sta SQR1_HIGH
 sta MUSIC_HIGH

 lda #$03
 sta MUSIC_MAX

;████████████████████████████████████████████████████████████████

game_loop:

frame_do_once:

process_music:
 ldx MUSIC_TIMER
 inx
 cpx #$20
 bne @not_reset_timer
 ldx #$00

 lda MUSIC_HIGH
 sta SQR1_HIGH

 ldy MUSIC_COUNT
 sty MUSIC_TEMP

 lda TURN
 cmp #$0d
 beq @p2_turn
 tya
 clc
 adc MUSIC_MAX
 tay

 @p2_turn:

 lda music_notes, y
 sta SQR1_LOW
 lda music_volumes, y
 sta SQR1_VOLUME

 ldy MUSIC_TEMP

 iny
 cpy MUSIC_MAX
 bne @not_reset_count
 ldy #$00

 @not_reset_count:
 sty MUSIC_COUNT

 @not_reset_timer:
 stx MUSIC_TIMER


;████████████████████████████████████████████████████████████████

process_board:
	;cell counter
 ldx BOARD_COUNT
 inx
 cpx #$09
 bne @not_reset_cells
 ldx #$00

 @not_reset_cells:
 stx BOARD_COUNT

 ldx BOARD_X	;column
 inx
 cpx #$03
 bne @not_reset_colums
 ldx #$00
 ldy BOARD_Y	;row
 iny
 cpy #$03
 bne @not_reset_rows
 ldy #$00

 @not_reset_rows:
 sty BOARD_Y

 @not_reset_colums:
 stx BOARD_X

 ldx BOARD_COUNT
 lda BOARD_START, x
 sta BOARD_SPRITE

 lda BOARD_Y	;colum and row
 jsr shift_y
 
 sta BOARD_X_Y
 lda BOARD_X
 asl
 clc
 adc BOARD_X_Y
 sta BOARD_X_Y

;████████████████████████████████████████████████████████████████

process_round:
	;init
 lda #$00
 ldx #$00
 @loop_init:
 sta CHECKS_H, x 

 inx
 cpx #$08
 bne @loop_init

	;check for rows
 ldy #$00
 @loop_h:
 sty CHECKS_1
 
 lda #$00
 ldx CHECKS_1
 @loop_h_offset:
 clc
 adc #$03 
 dex
 cpx #$ff
 bne @loop_h_offset
 sbc #$03
 sta CHECKS_1

 ldx #$00
 @loop_h_cells:
 txa
 clc
 adc CHECKS_1

 stx CHECKS_2
 tax
 lda BOARD_START, x
 cmp #$0a
 beq @empty_h
 clc
 adc CHECKS_H, y
 sta CHECKS_H, y

 @empty_h:
 ldx CHECKS_2

 inx
 cpx #$03
 bne @loop_h_cells

 iny
 cpy #$03
 bne @loop_h

	;check for colums
 ldy #$00
 @loop_v:
 sty CHECKS_1
 
 ldx #$00
 @loop_v_cells:
 tya
 stx CHECKS_1
 clc
 adc CHECKS_1

 tax
 lda BOARD_START, x
 cmp #$0a
 beq @empty_v
 clc
 adc CHECKS_V, y
 sta CHECKS_V,y

 @empty_v:
 ldx CHECKS_1

 inx
 inx
 inx
 cpx #$09
 bne @loop_v_cells

 iny
 cpy #$03
 bne @loop_v

	;checks for diagonals
 ldx #$00
 @loop_d_1:
 lda BOARD_START, x
 cmp #$0a
 beq @empty_d_1
 clc
 adc CHECKS_D
 sta CHECKS_D

 @empty_d_1:

 inx
 inx
 inx
 inx
 cpx #$0c
 bne @loop_d_1

	;second diagonal
 ldx #$02
 ldy #$01
 @loop_d_2:
 lda BOARD_START, x
 cmp #$0a
 beq @empty_d_2
 clc
 adc CHECKS_D, y
 sta CHECKS_D, y

 @empty_d_2:

 inx
 inx
 cpx #$08
 bne @loop_d_2

	;check for wins
 ldy #$00
 ldx #$00
 @loop_wins:
 lda CHECKS_H, x
 cmp #$24
 bne @p1_not_win
 ldy #$01

 @p1_not_win:

 cmp #$27
 bne @ending_wins
 ldy #$01

 @ending_wins:
 
 inx
 cpx #$08
 bne @loop_wins
 sty BOARD_WIN
 

;████████████████████████████████████████████████████████████████

process_player_input:

 lda INPUT_BREAK
 cmp #$00
 bne @break

 lda INPUT_1	;up button
 and #%00001000
 cmp #%00001000
 bne @up_not_pressed
 ldy CURSOR_Y
 dey
 cpy #$ff
 bne @not_min_y
 ldy #$02
 @not_min_y:
 sty CURSOR_Y

 sta INPUT_BREAK
 @up_not_pressed:

 lda INPUT_1	;down button
 and #%00000100
 cmp #%00000100
 bne @down_not_pressed
 ldy CURSOR_Y
 iny
 cpy #$03
 bne @not_max_y
 ldy #$00
 @not_max_y:
 sty CURSOR_Y

 sta INPUT_BREAK
 @down_not_pressed:

 lda INPUT_1	;right button
 and #%00000001
 cmp #%00000001
 bne @right_not_pressed
 ldx CURSOR_X
 inx
 cpx #$03
 bne @not_max_x
 ldx #$00
 @not_max_x:
 stx CURSOR_X

 sta INPUT_BREAK
 @right_not_pressed:

 lda INPUT_1	;left button
 and #%00000010
 cmp #%00000010
 bne @left_not_pressed
 ldx CURSOR_X
 dex
 cpx #$ff
 bne @not_min_x
 ldx #$02
 @not_min_x:
 stx CURSOR_X

 sta INPUT_BREAK
 @left_not_pressed:

 @break:
 lda INPUT_1
 sta INPUT_BREAK

;████████████████████████████████████████████████████████████████


 lda PRESS_BREAK
 cmp #$00
 bne @press_break

 lda INPUT_1	;select and start buttons
 and #%00110000
 cmp #%00110000
 bne @select_not_pressed
 sta PRESS_BREAK
 jmp @restart

 @select_not_pressed:

 lda INPUT_1	;a button
 and #%10000000
 cmp #%10000000
 bne @a_not_pressed

 lda BOARD_WIN
 cmp #$00
 beq @not_win

 @restart:

 lda #$0a
 ldx #$00
 stx BOARD_WIN
 @loop_restart:
 sta BOARD_START, x

 inx
 cpx #$09
 bne @loop_restart

 jmp @a_not_pressed 
 @not_win:

 lda CURSOR_X
 ldx CURSOR_Y
 @loop_cursor_cell:
 clc
 adc #$03
 
 dex
 cpx #$ff
 bne @loop_cursor_cell
 sbc #$03
 sta CURSOR_TEMP

 tax
 lda BOARD_START, x
 cmp #$0a
 bne @cell_not_empty

 lda TURN
 sta BOARD_START, x

 lda #$0c
 cmp TURN
 bne @not_x

 lda #$0d	;is x
 sta TURN

 jmp @cell_not_empty
 @not_x:
 sta TURN

 @cell_not_empty:

 sta PRESS_BREAK
 @a_not_pressed:

 @press_break:
 lda INPUT_1
 sta PRESS_BREAK

;████████████████████████████████████████████████████████████████

	;when someone wins
win:
 lda BOARD_WIN
 cmp #$00
 beq @not_win

 lda #$01
 sta CURSOR_BLINK
 jmp frame_loop

 @not_win:

;████████████████████████████████████████████████████████████████

process_cursor:
 ldx CURSOR_COUNT
 inx
 cpx #$1e
 bne @not_blink
 lda #$01
 sta CURSOR_BLINK

 @not_blink:
 cpx #$3c
 bne @blink
 ldx #$00
 stx CURSOR_COUNT
 stx CURSOR_BLINK

 @blink:
 stx CURSOR_COUNT

	;coordinates
 lda CURSOR_Y
 jsr shift_y

 sta CURSOR_X_Y
 lda CURSOR_X
 asl
 clc
 adc CURSOR_X_Y
 sta CURSOR_X_Y

;████████████████████████████████████████████████████████████████

frame_loop:

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

 bit PPU_STATUS
 bmi vBlankDo
 
 jmp frame_loop

vBlankDo:
	;render board
 lda #$20
 sta PPU_ADDR

 lda BOARD_X_Y
 sta PPU_ADDR
 
 lda BOARD_SPRITE
 sta PPU_DATA

	;render cursor
 lda CURSOR_BLINK
 cmp #$00
 bne @not_blink
 lda #$20
 sta PPU_ADDR
 lda CURSOR_X_Y
 sta PPU_ADDR
 
 lda TURN
 sta PPU_DATA

 @not_blink:

	;render_scroll
 ldx SCROLL_X
 ldy SCROLL_Y
 stx PPU_SCROLL
 sty PPU_SCROLL

	;set scroll
 lda NAMETABLES
 sta PPU_CTRL 

 jmp game_loop

shift_y:
 ldx #$00
 @loop_shifts:
 asl 
 inx
 cpx #$06
 bne @loop_shifts
 rts

nmi:
 rti

;████████████████████████████████████████████████████████████████

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

music_notes:
 .byte $fd, $c9, $a9, $e1, $a9, $86
music_volumes:
 .byte %00011000, %00011000, %00011000, %00011000, %00011000, %00011000

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