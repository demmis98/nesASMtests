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
 lda #%10011111
 sta $4000
 lda #%00001111
 sta $4001
 lda #%00000000
 sta $4002
 lda #%00100000
 sta $4003
 lda #%00001111
 sta $4015
 lda #%01000000
 sta $4017

 lda #%00110000
 sta $2000
 lda #%00011000
 sta $2001
 ldx #$00
ppu_loop:
 stx $23
 lda $23
 sta $2400,x
 cmp $FF
 bne ppu_loop
palletes:
 lda $0f
 sta $3f00
 lda $0f
 sta $3f00
 lda $0f
 sta $3f00
 lda $0f
 sta $3f00

game_loop:
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
 lda #%00011000
 sta $2001
 inc $50
 jmp after_controller
down:
 lda #%00111000
 sta $2001
 inc $50
 jmp after_controller
left:
 lda #%10011000
 sta $2001
 inc $50
 jmp after_controller
right:
 lda #%01011000
 sta $2001
 inc $50
 jmp after_controller
after_controller:
 jmp game_loop

nmi:
 rts
; Character memory
.segment "CHARS"