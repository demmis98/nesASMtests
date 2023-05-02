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
 lda #$21
 sta $2006
 lda #$30
 sta $2006
 lda #$03
 sta $2007

enable_rendering:
 lda #%00000010
 sta $2000
 lda #%00011110
 sta $2001

 jsr load_bg_1
game_loop:

controller:
 lda #$01
 sta $4016
 sta $10
 lda #$00
 sta $4016
controller_loop:
 lda $4016
 lsr a
 rol $10
 bcc controller_loop
 lda $10
 sta $11
 lda $11
 cmp #%00001000
 beq @up
 cmp #%01001000
 beq @b_up
 cmp #%01000100
 beq @b_down
 jmp after_controller
 @up:
 jsr load_bg_1
 jmp after_controller
 @b_up:
 inc $20
 jmp after_controller
 @b_down:
 dec $20
 jmp after_controller
after_controller:

 inc $51

 bit $2002
 bmi frameDo
 jmp game_loop
frameDo:
 inc $50
 lda $50
 cmp #60
 bne @jmp_inc
 inc $64
 lda #$00
 sta $50

 ;clock formatting
 lda $66
 cmp #10
 bne @jmp_sec_10
 inc $65
 lda #$00
 sta $66
 @jmp_sec_10:
 inc $13
 lda $65
 cmp #6
 bne @min
 lda #$00
 sta $65
 inc $64
 @min:
 lda $64
 cmp #10
 bne @jmp_min_10
 lda #$00
 sta $64
 inc $63
 @jmp_min_10:
 lda $63
 cmp #6
 bne @hrs
 lda #$00
 sta $63
 inc $62
 @hrs:
 lda $62
 cmp #10
 bne @jmp_hrs_10
 lda #$00
 sta $62
 inc $61
 @jmp_hrs_10:
 lda $61
 cmp #12
 bne @jmp_inc
 lda #$00
 sta $61
 lda $60
 and #%00000001
 beq @pm
 lda #%0000001
 sta $60
 jmp @jmp_inc 
 @pm:
 lda #%00000000
 sta $60
 @jmp_inc:
 @render_clock:
 lda #$22
 sta $2006
 lda #$30
 sta $2006
 lda $64
 sta $2007
 jmp game_loop
nmi:
 rti

load_bg_1:
 lda #$0A
 sta $40
 jsr load_bg
rts
 
load_bg:
 lda $2002
 lda $21;scroll
 sta $2005
 lda $20
 sta $2005

 ldy #$20
 ldx #$00
 @loop_y:
 ldx #$00
 @loop_x:
 lda $2002
 sty $2006
 stx $2006
 lda $40
 sta $2007
 inx
 cpx #$00
 bne @loop_x
 iny
 cpy #$27
 bne @loop_y
rts

load_player:
 rts


;palletes and stuff
palletes:
;background
 .byte $0f, $0c, $1c, $2c
 .byte $0f, $26, $16, $06
 .byte $0f, $31, $21, $11
 .byte $0f, $29, $2a, $2b
;oem sprites
 .byte $0f, $0c, $1c, $2c
 .byte $0f, $26, $16, $06
 .byte $0f, $31, $21, $11
 .byte $0f, $29, $2a, $2b

backgroundTables:


; Character memory
.segment "CHARS"

  .byte %00111100;0
  .byte %01110110
  .byte %01100110
  .byte %01100110
  .byte %01100110
  .byte %01101110
  .byte %00111100
  .byte %00000000
  .byte %00111000;
  .byte %01100100
  .byte %01000100
  .byte %01000100
  .byte %01000100
  .byte %01001100
  .byte %00111000
  .byte %00000000

  .byte %00011000;1
  .byte %00111000
  .byte %00011000
  .byte %00011000
  .byte %00011000
  .byte %00011000
  .byte %00111100
  .byte %00000000
  .byte %00010000;
  .byte %00110000
  .byte %00010000
  .byte %00010000
  .byte %00010000
  .byte %00010000
  .byte %00111000
  .byte %00000000

  .byte %00111100;2
  .byte %01100110
  .byte %01100110
  .byte %00000110
  .byte %00011100
  .byte %00110000
  .byte %01111110
  .byte %00000000
  .byte %00111000;
  .byte %01000100
  .byte %01000100
  .byte %00000100
  .byte %00011000
  .byte %00100000
  .byte %01111100
  .byte %00000000

  .byte %00111100;3
  .byte %01100110
  .byte %00000110
  .byte %00011100
  .byte %00000110
  .byte %01100110
  .byte %00111100
  .byte %00000000
  .byte %00111000;
  .byte %01000100
  .byte %00000100
  .byte %00011000
  .byte %00000100
  .byte %01000100
  .byte %00111000
  .byte %00000000

  .byte %00001100;4
  .byte %00011100
  .byte %00111100
  .byte %01101100
  .byte %11001110
  .byte %01111100
  .byte %00001100
  .byte %00000000
  .byte %00001000;
  .byte %00011000
  .byte %00101000
  .byte %01001000
  .byte %10001100
  .byte %01111000
  .byte %00001000
  .byte %00000000

  .byte %01111100;5
  .byte %01100000
  .byte %01100000
  .byte %01111100
  .byte %00000110
  .byte %01100110
  .byte %00111100
  .byte %00000000
  .byte %01111000;
  .byte %01000000
  .byte %01000000
  .byte %01111000
  .byte %00000100
  .byte %01000100
  .byte %00111000
  .byte %00000000

  .byte %00111100;6
  .byte %01100110
  .byte %01100000
  .byte %01111100
  .byte %01100110
  .byte %01100110
  .byte %00111100
  .byte %00000000
  .byte %00111000;
  .byte %01000100
  .byte %01000000
  .byte %01111000
  .byte %01000100
  .byte %01000100
  .byte %00111000
  .byte %00000000

  .byte %01111110;7
  .byte %00000110
  .byte %00001100
  .byte %00001100
  .byte %00011000
  .byte %00011000
  .byte %00011000
  .byte %00000000
  .byte %01111100;
  .byte %00000100
  .byte %00001000
  .byte %00001000
  .byte %00010000
  .byte %00010000
  .byte %00010000
  .byte %00000000

  .byte %00111100;8
  .byte %01100110
  .byte %01100110
  .byte %00111100
  .byte %01100110
  .byte %01100110
  .byte %00111100
  .byte %00000000
  .byte %00111000;
  .byte %01000100
  .byte %01000100
  .byte %00111000
  .byte %01000100
  .byte %01000100
  .byte %00111000
  .byte %00000000

  .byte %00111100;9
  .byte %01100110
  .byte %01100110
  .byte %01100110
  .byte %00111110
  .byte %00000110
  .byte %00000110
  .byte %00000000
  .byte %00111000;
  .byte %01000100
  .byte %01000100
  .byte %01000100
  .byte %00111100
  .byte %00000100
  .byte %00000100
  .byte %00000000

  .byte %00001111;random tile
  .byte %00111111
  .byte %11111111
  .byte %11111111
  .byte %11111100
  .byte %11110000
  .byte %11000000
  .byte %00000011
  .byte %11110011;
  .byte %11001100
  .byte %00110011
  .byte %11001100
  .byte %00110011
  .byte %11001111
  .byte %00111111
  .byte %11111100