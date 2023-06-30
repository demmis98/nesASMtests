
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

enable_rendering:
 lda #%00000010
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

load_player:
 ldx #$10
 sta $12 ;x
 sta $13 ;y
 ldx #$01
 stx $2003
 lda #%00001100
 sta $2004
 lda #%00000000
 sta $2004
 ldx #$05
 stx $2003
 lda #%00001110
 sta $2004
 lda #%00000001
 sta $2004
 lda #$03 ;load speed
 sta $1f

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

 inc $51

 bit $2002
 bmi frameDo
 jmp game_loop

frameDo:
 lda $00
 and #%00000001
 beq @not_right
 inc $10
 inc $10
 @not_right:
 and #%00000010
 beq @not_left
 dec $10
 dec $10
 @not_left:

 lda #%10000000
 cmp $10
 beq @end_speed_x
 bmi @dec_speed_x
 bpl @inc_speed_x

 @dec_speed_x:
 dec $10
 jmp @end_speed_x
 @inc_speed_x:
 inc $10

 @end_speed_x:
 lda $1f
 adc #%10000000
 cmp $10
 bmi @dec_speed_x_2
 jmp @end_speed_x_2
 @dec_speed_x_2:
 dec $10
 @end_speed_x_2:
 lda #%10000000
 sbc $1f
 cmp $10
 beq @inc_speed_x_3
 jmp @end_speed_x_3
 @inc_speed_x_3:
 inc $10
 @end_speed_x_3:

 @move_x:
 lda $10
 sbc #%01111111
 lda #$00
 adc $12
 sbc $01
 sta $12

 @arms_loop:
 inc $14

 @display_player:
 lda #$03 ;x
 sta $2003
 ldx $12
 stx $2004
 lda #$07
 sta $2003
 stx $2004 ;end of x
 lda #$00 ;y
 sta $2003
 ldx $13
 stx $2004
 lda $13
 adc #$07
 ldx #$04
 stx $2003
 sta $2004 ;end of y

 jmp game_loop

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

  .byte %11111100; test
  .byte %11111000
  .byte %11110000
  .byte %11100000
  .byte %11000000
  .byte %10000000
  .byte %00000000
  .byte %11111111;
  .byte %01111111
  .byte %00111111
  .byte %00011111
  .byte %00001111
  .byte %00000111
  .byte %00000011
  .byte %00000001
  .byte %00000000

  .byte %00111111; player head
  .byte %01111111
  .byte %11111101
  .byte %11111101
  .byte %11111111
  .byte %11111110
  .byte %11010100
  .byte %01010100
  .byte %00000000;
  .byte %00000000
  .byte %00001111
  .byte %00011111
  .byte %00011111
  .byte %00111110
  .byte %00001000
  .byte %00001000

  .byte %00111111; player head blink
  .byte %01111111
  .byte %11111111
  .byte %11111101
  .byte %11111111
  .byte %11111110
  .byte %11010100
  .byte %01010100
  .byte %00000000;
  .byte %00000000
  .byte %00001111
  .byte %00011111
  .byte %00011111
  .byte %00111110
  .byte %00001000
  .byte %00001000

  .byte %00011100; player body 1
  .byte %00101010
  .byte %00110010
  .byte %01010001
  .byte %10100001
  .byte %11111111
  .byte %00000000
  .byte %00000000
  .byte %00001000;
  .byte %00011100
  .byte %00011100
  .byte %00111110
  .byte %01111110
  .byte %00000000
  .byte %00011100
  .byte %00011100

  .byte %00011100; player body 2
  .byte %00101010
  .byte %00101010
  .byte %01001001
  .byte %10010001
  .byte %11111111
  .byte %00000000
  .byte %00000000
  .byte %00001000;
  .byte %00011100
  .byte %00011100
  .byte %00111110
  .byte %01111110
  .byte %00000000
  .byte %00011100
  .byte %00011100

  .byte %00011100; player body 3
  .byte %00101010
  .byte %00101010
  .byte %01001001
  .byte %10000101
  .byte %11111111
  .byte %00000000
  .byte %00000000
  .byte %00001000;
  .byte %00011100
  .byte %00011100
  .byte %00111110
  .byte %01111110
  .byte %00000000
  .byte %00011100
  .byte %00011100

  .byte %00011100; player body 4
  .byte %00101010
  .byte %00100110
  .byte %01000101
  .byte %10000011
  .byte %11111111
  .byte %00000000
  .byte %00000000
  .byte %00001000;
  .byte %00011100
  .byte %00011100
  .byte %00111110
  .byte %01111110
  .byte %00000000
  .byte %00011100
  .byte %00011100