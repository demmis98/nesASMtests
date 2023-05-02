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
 lda #%10111111
 sta $4000
 lda #%00000000
 sta $4001
 lda #%00000111
 sta $4002
 lda #%00010111
 sta $4003
 lda #%00000001
 sta $4015
 lda #%01000000
 sta $4017
 lda #$50
 sta $50
 sta $51

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


enable_rendering:
 lda #%00110000
 sta $2000
 lda #%00011000
 sta $2001

game_loop:

load_background:
 lda $2002
 lda #$20
 sta $2006
 lda #$40
 sta $2006
 ldx #$00
 @loop:
 lda backgroundName1, x
 sta $2007
 inx
 cpx #$06
 bne @loop

 lda $2002
 lda #$20
 sta $2006
 lda #$40
 sta $2006
 ldx #$00
 @loop2:
 lda $2007
 sta $80,x
 inx
 cpx #$06
 bne @loop2

 
load_player:
 ldx #$00
 stx $2003
 lda $50
 sta $2004
 lda #$00
 sta $2004
 lda #$03
 sta $2004
 lda $51
 sta $2004

controller:
 lda #$01
 sta $4016
 sta $41
 lda #$00
 sta $4016
controller_loop:
 lda $4016
 lsr a
 rol $41
 bcc controller_loop
 lda $41
 sta $42
 lda $42
 cmp #%00001000
 beq up
 cmp #%00000100
 beq down
 cmp #%00000010
 beq left
 cmp #%00000001
 beq right
 jmp after_controller
up:
 inc $50
 jmp after_controller
down:
 dec $50
 jmp after_controller
left:
 inc $51
 jmp after_controller
right:
 dec $51
 jmp after_controller
after_controller:
 jmp game_loop

nmi:
 rti

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

backgroundName1:
 .byte $01, $01, $01, $01, $00, $02
backgroundAtribute1:

; Character memory
.segment "CHARS"

  .byte %00000000;
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
  .byte %00000000

  .byte %11000011;
  .byte %11000011
  .byte %11000011
  .byte %11111111
  .byte %11111111
  .byte %11000011
  .byte %11000011
  .byte %11000011;
  .byte %10000011
  .byte %10000011
  .byte %10000011
  .byte %10111111
  .byte %11101111
  .byte %11000010
  .byte %11000011
  .byte %11000011

  .byte %11111111;
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