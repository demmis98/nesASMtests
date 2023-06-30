
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
  stx $4017	; disable APU frame IRQ
  ldx #$ff 	; Set up stack
  txs		;  .
  inx		; now X = 0
  stx $2000	; disable NMI
  stx $2001 	; disable rendering
  stx $4010 	; disable DMC IRQs

;; first wait for vblank to make sure PPU is ready
vblankwait1:
  bit $2002
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
  bit $2002
  bpl vblankwait2

main:
load_palletes:
 lda $2002
 lda #$3f
 sta $2006
 lda #$10
 sta $2006

 ldx #$00
 @loop:
 lda palletes,x
 sta $2007
 inx
 cpx #$20
 bne @loop
 cpy #$20


load_background:
 lda #$20	;1st row
 sta $2006
 lda #$00
 sta $2006
 
 lda #$00
 sta $2007
 lda #$0b
 sta $2007
 lda #$00
 sta $2007
 lda #$0b
 sta $2007
 lda #$00
 sta $2007

 lda #$20	;2nd
 sta $2006
 lda #$20
 sta $2006

 lda #$0b
 sta $2007
 sta $2007
 sta $2007
 sta $2007
 sta $2007

 lda #$20	;3rd
 sta $2006
 lda #$40
 sta $2006
 
 lda #$00
 sta $2007
 lda #$0b
 sta $2007
 lda #$00
 sta $2007
 lda #$0b
 sta $2007
 lda #$00
 sta $2007

 lda #$20	;4th
 sta $2006
 lda #$60
 sta $2006

 lda #$0b
 sta $2007
 sta $2007
 sta $2007
 sta $2007
 sta $2007

 lda #$20	;5th
 sta $2006
 lda #$80
 sta $2006
 
 lda #$00
 sta $2007
 lda #$0b
 sta $2007
 lda #$00
 sta $2007
 lda #$0b
 sta $2007
 lda #$00
 sta $2007


init_players:
 lda #$0d
 sta $0b

 lda #$00
 sta $1e
 sta $1f

enable_rendering:
 lda #%00000001
 sta $2000
 lda #%00011110
 sta $2001

init_sound:
 lda #$01
 sta $4015
 lda #$00
 sta $4001
 lda #$40
 sta $4017


init_speeds:
 lda #%10000000
 sta $10
 sta $11

game_loop:

controller:
 lda #$01
 sta $4016
 sta $01
 lda #$00
 sta $4016
controller_loop:
 lda $4016
 lsr a
 rol $01
 bcc controller_loop
 lda $01
 sta $00

frameDo:
 lda $10	;button input
 cmp #$01
 beq @no_actions
 lda $00
 and #%00001000
 beq @not_up
 ldx $0e	;if up is pressed
 inx
 cpx #$03
 bne @not_reset_cursor_y
 ldx #$00 
 @not_reset_cursor_y:
 stx $0e
 @not_up:
 lda $00
 and #%00000001
 beq @not_right
 ldx $0f	;if right is pressed
 inx
 cpx #$03
 bne @not_reset_cursor_x
 ldx #$00 
 @not_reset_cursor_x:
 stx $0f
 @not_right:
 @no_actions:

 jsr reset_button_input

 jsr calc_cursor

 jsr calc_board

 bit $2002
 bmi vBlankDo
 jmp game_loop

vBlankDo:
 jsr render_cursor
 jsr set_scrolling
 jsr render_board
 jmp game_loop

reset_button_input:
 lda #$00
 sta $10
 lda $00
 cmp #$00
 beq @end
 lda #$01
 sta $10
 @end:
 rts

calc_cursor:
 inc $08
 lda $08
 cmp #$1e
 bne @not_blink
 ldx #$01
 stx $07
 @not_blink:
 lda $08
 cmp #$00
 bne @not_reset_blink
 ldx #$00
 stx $07
 @not_reset_blink:
 cmp #$3c
 bne @not_reset_timmer
 lda #$00
 @not_reset_timmer:
 sta $08

 lda $07
 cmp #$01
 bne @not_show
 clc
 lda $0e
 rol
 rol
 rol
 rol
 rol
 rol
 sta $1b
 clc
 lda $0f
 rol
 adc $1b
 sta $1b
 @not_show:
 rts

calc_board:

 ldx #$00	;memory to sprite values
 @loop:
 lda $20, x
 cmp #$00
 bne @not_blank
 sta $30, x

 @not_blank:
 lda $20, x
 cmp #$01
 bne @not_circle
 lda #$0b
 sta $30, x

 @not_circle:
 lda $20, x
 cmp #$02
 bne @not_cross
 lda #$0c
 sta $30,x
 @not_cross:

 @skip:
 rts

 @equal:
 lda $20, x
 jmp @after_equal
 @not_equal:
 lda #$00
 @after_equal:
 rts

render_cursor:
 lda #$20
 sta $2006
 lda $1b
 sta $2006
 lda $0b
 sta $2007
 rts

set_scrolling:
 lda #$90	;scrolling
 sta $2005
 lda #$90
 sta $2005
 lda #%00000001
 sta $2000
 rts

render_board:
 ldx #$00
 @loop_1:
 lda #$20
 sta $2006
 clc
 lda $1f
 rol
 sta $2006 
 lda $30, x
 sta $2007
 cpx #$03
 bne @loop_1

 @loop_2:
 lda #$20
 sta $2006
 clc
 lda $1f
 rol
 adc #$40
 sta $2006 
 lda $30, x
 sta $2007
 cpx #$06
 inc $51
 bne @loop_2

 @loop_3:
 lda #$20
 sta $2006
 clc
 lda $1f
 rol
 adc #$80
 sta $2006 
 lda $30, x
 sta $2007
 cpx #$09
 inc $51
 bne @loop_3
 
 rts

nmi:
 rti

;palletes and stuff
palletes:
;oem sprites
 .byte $0f, $0c, $1c, $2c
 .byte $0f, $0c, $1c, $30
 .byte $0f, $11, $21, $31
 .byte $0f, $2b, $2a, $29
;background
 .byte $0f, $0c, $1c, $2c
 .byte $0f, $06, $16, $26
 .byte $0f, $11, $21, $31
 .byte $0f, $2b, $2a, $29

backgroundTables:


; Character memory
.segment "CHARS"

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