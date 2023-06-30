
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
 ldy #$0b
 lda #$00
 sta $0a

 ldx #$00
 @loop_v: 	;vertical
 sty $50, x
 lda #$20
 sta $2006
 lda $0a
 adc #$04
 sta $2006
 sty $2007

 lda #$20
 sta $2006
 lda $0a
 adc #$0b
 sta $2006
 sty $2007
 
 lda $0a
 adc #$20
 sta $0a
 
 inx

 cpx #$01
 beq @load_bg_vertical

 @compare_for_loop_v:
 cpx #$0f
 bne @loop_v

 jmp @end_background_vertical

 @load_bg_vertical:
 ldy #$10
 jmp  @compare_for_loop_v

 @load_bg_down:
 ldy #$0d
 jmp  @compare_for_loop_v

 @end_background_vertical:

 lda #$00
 sta $0a
 @loop_h_double:
 lda #$0e	;background horizontal
 sta $09
 
 lda #$20
 sta $2006
 lda $0a
 adc #$80
 sta $2006

 ldx #$00
 @loop_horizontal:
 lda $09
 sta $2007

 inx

 cpx #$01
 beq @load_bg_horizontal
 cpx #$0e
 beq @load_bg_right

 @compare_for_loop_h:
 cpx #$0f
 bne @loop_horizontal
 lda $0a
 adc #$20
 sta $0a
 cmp #$40
 bne @loop_h_double
 jmp @end_loop_horizontal

 @load_bg_horizontal:
 lda #$0f
 sta $09
 jmp  @compare_for_loop_h

 @load_bg_right:
 lda #$0c
 sta $09
 jmp  @compare_for_loop_h

 @end_loop_horizontal:

 lda #$c0	;scrolling
 sta $2005
 lda #$bf
 sta $2005

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

 bit $2002
 bmi frameDo
 jmp game_loop

frameDo:
 
 jmp game_loop
nmi:
 rti

;palletes and stuff
palletes:
;oem sprites
 .byte $0f, $28, $38, $39
 .byte $0f, $0c, $1c, $30
 .byte $0f, $11, $21, $31
 .byte $0f, $2b, $2a, $29
;background
 .byte $0f, $04, $14, $24
 .byte $0f, $16, $26, $36
 .byte $0f, $02, $21, $31
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



  .byte %00100000; up_border
  .byte %01011100
  .byte %10111110
  .byte %10111110
  .byte %10110110
  .byte %10110110
  .byte %10110110
  .byte %10110110
  .byte %00011100;
  .byte %00111110
  .byte %01111111
  .byte %01111111
  .byte %01111111
  .byte %01111111
  .byte %01111111
  .byte %01111111

  .byte %11110000; right_border
  .byte %00000000
  .byte %11111100
  .byte %11111110
  .byte %00001110
  .byte %11111110
  .byte %11111100
  .byte %00000000
  .byte %00000000;
  .byte %11111100
  .byte %11111110
  .byte %11111111
  .byte %11111111
  .byte %11111111
  .byte %11111110
  .byte %11111100

  .byte %10110110; down_border
  .byte %10110110
  .byte %10110110
  .byte %10110110
  .byte %10111110
  .byte %10111110
  .byte %01011100
  .byte %00100000
  .byte %01111111;
  .byte %01111111
  .byte %01111111
  .byte %01111111
  .byte %01111111
  .byte %01111111
  .byte %00111110
  .byte %00011100

  .byte %00111111; left_border
  .byte %01000000
  .byte %10111111
  .byte %01111111
  .byte %01110000
  .byte %01111111
  .byte %00111111
  .byte %00000000
  .byte %00000000;
  .byte %00111111
  .byte %01111111
  .byte %11111111
  .byte %11111111
  .byte %11111111
  .byte %01111111
  .byte %00111111


  .byte %11111111; horizontal_border
  .byte %00000000
  .byte %11111111
  .byte %11111111
  .byte %00000000
  .byte %11111111
  .byte %11111111
  .byte %00000000
  .byte %00000000;
  .byte %11111111
  .byte %11111111
  .byte %11111111
  .byte %11111111
  .byte %11111111
  .byte %11111111
  .byte %11111111

  .byte %10110110; vertical_border
  .byte %10110110
  .byte %10110110
  .byte %10110110
  .byte %10110110
  .byte %10110110
  .byte %10110110
  .byte %10110110
  .byte %01111111;
  .byte %01111111
  .byte %01111111
  .byte %01111111
  .byte %01111111
  .byte %01111111
  .byte %01111111
  .byte %01111111

  .byte %01111111; omni_border
  .byte %11111111
  .byte %11111111
  .byte %11111111
  .byte %11111111
  .byte %11111111
  .byte %11111111
  .byte %11111111
  .byte %10110110;
  .byte %00110110
  .byte %11110111
  .byte %11110111
  .byte %00000000
  .byte %11100111
  .byte %11100111
  .byte %01100110