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

.segment "CODE"

reset:
  lda #$00
  sta $00
  sta $01
  sta $02
  sta $03
  sta $04
  sta $05
  sta $06
  sta $42


main:
 ldx #10
 stx $00
 stx $01
controller:
 inc $10
 lda #$01 ;initialize controller
 sta $4016
 lda #$00
 sta $42
 sta $4016
 ldx #$00
controller_loop:
 lda $4016
 lsr a
 rol $42
 inx
 clc
 cpx #$08
 bcc controller_loop
 jmp controller
 rts

nmi:
; Character memory
.segment "CHARS"