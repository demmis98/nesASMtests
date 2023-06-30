
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
 inc $50
 lda $50
 cmp #60
 bne @jmp_inc
 inc $66
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
 ;display clock
 lda #$21
 sta $2006
 lda #$08
 sta $2006
 ldx #$00
 @clock_digits:
 lda $60, x
 adc #$01
 sta $2007
 inx
 cpx #$06
 bne @after_clock
 @after_clock:

 jmp game_loop

nmi:
 rti

load_player:
 inc $60
 ldx #$00
 stx $2003
 lda $10
 sta $2004
 lda #$01
 sta $2004
 lda #%00000011
 sta $2004
 lda $11
 sta $2004
 rts


;palletes and stuff
palletes:
;background
 .byte $0f, $2c, $1c, $0c
 .byte $0f, $26, $16, $06
 .byte $0f, $31, $21, $11
 .byte $0f, $29, $2a, $2b
;oem sprites
 .byte $0f, $2c, $1c, $0c
 .byte $0f, $26, $16, $06
 .byte $0f, $31, $21, $11
 .byte $0f, $29, $2a, $2b

backgroundTables:


; Character memory
.segment "CHARS"

  .byte %11111100;
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

  .byte %00000000;
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

  .byte %00000000;
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

  .byte %00000000;
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

  .byte %00000000;
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

  .byte %00000000;
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

  .byte %00000000;
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

  .byte %00000000;
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

  .byte %00000000;
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

  .byte %00000000;
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

  .byte %00000000;
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
