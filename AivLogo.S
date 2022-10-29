.define PPUCTRL $2000
.define PPUMASK $2001
.define OAMADDR $2003
.define OAMDATA $2004
.define PPUSCROLL $2005
.define PPUADDR $2006
.define PPUDATA $2007

.define JOYPAD1 $4016

.define BUTTONS $00
.define SCROLL_X $01
.define DRAW_LOOP $02
.define SPRITE_X_OFFSET $03
.define SPRITE_Y_OFFSET $04
; .define SPRITE_ATTRIBUTE $05
.define CURRENT_X_DRAW $06
.define CURRENT_Y_SPRITE $07
.define CURRENT_SPRITE $08

; 3th number => MIRROR 
.DB "NES", $1A, 2, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0

.ORG $8000
    
start:
    ; set sprite offsets
    LDA #$78
    STA SPRITE_X_OFFSET
    LDA #$90
    STA SPRITE_Y_OFFSET
    ; imposto i parametri della PPU
    LDA #%10010000
    STA PPUCTRL
    
    LDA #%00011110
    STA PPUMASK
    
    ; Indirizzo la PPU all'indirizzo della palette del bakcround
    LDA #$3F
    STA PPUADDR
    LDA #$00
    STA PPUADDR
    
    ; scrivo i colori 
    LDA #$0F
    STA PPUDATA
    
    ; la PPU shifta in automatico
    LDA #$00
    STA PPUDATA
    LDA #$28
    STA PPUDATA
    LDA #$10
    STA PPUDATA
    
    ; Indirizzo la PPU all'indirizzo della palette degli sprite
    LDA #$3F
    STA PPUADDR
    LDA #$11
    STA PPUADDR
    
    LDA #$16
    STA PPUDATA
    LDA #$27
    STA PPUDATA
    LDA #$18
    STA PPUDATA
    
    JSR drawlogo
    
loop:
    JSR drawsprite
    JMP loop
  
drawlogo:
    ; scrivo nella name tables
    LDA #$20
    STA PPUADDR
    LDA #$E0
    STA PPUADDR

    LDA #$02
    STA DRAW_LOOP
    
    draw_loop:    
        LDX #$00
        draw:   
        TXA
        STA PPUDATA
        ; check if i need to go on new line
        ADC #01
        AND #$0F
        BNE not_new_line
        ; draw 16 empty cell
        TXA
        CLC
        ADC #01    
        STA CURRENT_X_DRAW
        AND #$F0
            loop_withe_spaces:
            TYA
            STA PPUDATA
            INY
            CPY CURRENT_X_DRAW  
            BNE loop_withe_spaces
        not_new_line:
        INX
        BNE draw

        DEC DRAW_LOOP
        BEQ end_draw_loop
        LDA #$24
        STA PPUADDR
        LDA #$E0
        STA PPUADDR
        JMP draw_loop
    end_draw_loop:
    ;reset PPU to initial offset
    LDA #$20
    STA PPUADDR
    LDA #$00
    STA PPUADDR
    RTS
    
drawsprite:
    LDA #00
    STA OAMADDR
    STA CURRENT_SPRITE
    
    LDY #$00
        loop_sprite_height:
        LDX #$00
        TYA
        CLC
        ASL A
        ASL A
        ASL A
        ADC SPRITE_Y_OFFSET
        STA CURRENT_Y_SPRITE
            loop_sprite_wight:
            LDA CURRENT_Y_SPRITE
            STA OAMDATA
            LDA CURRENT_SPRITE
            STA OAMDATA
            LDA #00
            STA OAMDATA
            TXA
            CLC
            ASL A
            ASL A
            ASL A
            ADC SPRITE_X_OFFSET
            STA OAMDATA            
            INC CURRENT_SPRITE
            INX
            CPX #$02
            BNE loop_sprite_wight
        INY
        CPY #$04
        BNE loop_sprite_height
    RTS
  
; At the same time that we strobe BIT 0, we initialize the ring counter
; so we're hitting two birds with one stone here
readjoy:
    PHA ; evito globbering
    LDA #$01
    ; While the strobe bit is set, buttons will be continuously reloaded.
    ; This means that reading from JOYPAD1 will only return the state of the
    ; first button: button A.
    STA JOYPAD1
    STA BUTTONS
    LSR A       ; now A is 0
    ; By storing 0 into JOYPAD1, the strobe bit is cleared and the reloading stops.
    ; This allows all 8 buttons (newly reloaded) to be read from JOYPAD1.
    STA JOYPAD1
joyloop:
    LDA JOYPAD1
    LSR A           ; bit 0 -> Carry
    ROL BUTTONS  ; Carry -> bit 0; bit 7 -> Carry
    BCC joyloop
    PLA ; globbering
    RTS

nmi:
    PHA ; evito globbering
    JSR readjoy
    LDA BUTTONS
    AND #01
    BNE scrollleft
    LDA BUTTONS
    AND #02
    BNE scrollright
    LDA BUTTONS
    AND #04
    BNE scrollspritedown
    LDA BUTTONS
    AND #08
    BNE scrollspritetop
    PLA ; globbering
    RTI
    scrollleft:
    LDA SCROLL_X
    CMP #$FF
    BEQ notscrollleft
    INC SCROLL_X
    notscrollleft:
    LDA SCROLL_X
    STA PPUSCROLL
    ; scroll sprite
    INC SPRITE_X_OFFSET
    notscrollspriteleft:
    JMP endscroll
    scrollright:
    LDA SCROLL_X
    BEQ notscrollright
    DEC SCROLL_X
    notscrollright:
    LDA SCROLL_X
    STA PPUSCROLL
    ; scroll sprite
    DEC SPRITE_X_OFFSET
    endscroll:
    LDA #0
    STA PPUSCROLL
    PLA ; globbering
    RTI
    scrollspritedown:
    INC SPRITE_Y_OFFSET
    PLA ; globbering
    RTI
    scrollspritetop:
    DEC SPRITE_Y_OFFSET
    PLA ; globbering
    RTI

irq:
  RTI

.goto $FFFA

.dw nmi
.dw start
.DW irq

.INCBIN "Assemblyes/6502/NES/Tables/mario0.chr"
.INCBIN "Assemblyes/6502/NES/Tables/aiv256.chr"
