;
; FEMTOTRO - 2018 OVERKILL REMIX
;

; Code and graphics by T.M.R/Cosine
; Music by 4-Mat/Ate Bit/Orb


; A reworking of my Babygang intro from 1991 that's squished down
; further, storing sprites and other data on the screen RAM.


; This source code is formatted for the ACME cross assembler from
; http://sourceforge.net/projects/acme-crossass/
; Compression is handled with Exomizer which can be downloaded at
; http://csdb.dk/release/?id=141402

; build.bat will call both to create an assembled file and then the
; crunched release version.


; Select an output filename
		!to "femtotro.prg",cbm


; Yank in binary data
		* = $0400
		!binary "data/characters.chr"

		* = $0740
		!binary "data/sprites.spr",$080,$000

		* = $0801
		!binary "data/empty_modded.prg",,2

		* = $0b40
		!binary "data/sprites.spr",$100,$080


; Constants
scrn_colour	= $0c
brdr_colour	= $0b

; Labels
cos_at_1	= $50
cos_temp	= $51

scroll_x	= $52
scroll_speed	= $53

colour_cnt	= $54

ghost_store	= $55


; Entry point at $0c40
		* = $0c40

; Stop the interrupts
		sei

; Stash the value at $3fff and clear it
		lda $3fff
		sta ghost_store
		lda #$00
		sta $3fff

; Video initialisation
		lda #$10
		sta $d018

		lda #brdr_colour
		sta $d020
		lda #scrn_colour
		sta $d021

		ldx #$00
colour_init_1	sta $d800,x
		sta $d900,x
		sta $da00,x
		sta $dae8,x
		inx
		bne colour_init_1

		ldx #$00
colour_init_2	lda #$0b
		sta $d990,x
		lda #$01
		sta $d9b8,x
		lda #$00
		sta $d9e0,x
		lda #$0c
		sta $da08,x
		lda #$0b
		sta $da30,x
		inx
		cpx #$28
		bne colour_init_2

; Enable the hardware sprites
		lda #$3f
		sta $d015
		sta $d017
		sta $d01c
		sta $d01d

; Set up the music
		jsr $09ed

; Set the labels that need it
		lda #$00
		sta scroll_x
		sta colour_cnt

		lda #$03
		sta scroll_speed

; Wait for the lower border and open both
main_loop	lda #$f9
		cmp $d012
		bne *-$03

		lda #$13
		sta $d011

		lda #$fc
		cmp $d012
		bne *-$03

		lda #$1b
		sta $d011

; Update the sprite Y positions
		lda cos_at_1
		clc
		adc #$01
		sta cos_at_1

		sta cos_temp

		ldx #$00
cos_update	lda cos_temp
		sec
		sbc #$18
		sta cos_temp

		cmp #$80
		bcc *+$06
		and #$7f
		eor #$7f

		tay
		lda sprite_cos,y
		sta sprite_y_pos,x
		inx
		cpx #$06
		bne cos_update

; Refresh the sprite positions
		ldx #$00
		ldy #$00
sprite_set_1	lda sprite_x_pos,x
		sta $d000,y
		lda sprite_y_pos,x
		sta $d001,y

		lda sprite_cols_1,x
		sta $d027,x
		iny
		iny
		inx
		cpx #$08
		bne sprite_set_1

		lda sprite_x_msb
		sta $d010

; Update the scroller
		ldy scroll_speed
scroll_loop	ldx scroll_x
		inx
		cpx #$08
		bne scr_xb

		ldx #$00
mover		lda $05e1,x
		sta $05e0,x
		inx
		cpx #$26
		bne mover

mread		lda scroll_text
		bne okay

		lda #<scroll_text
		sta mread+$01
		lda #>scroll_text
		sta mread+$02
		jmp mread

okay		cmp #$80
		bcc okay_2

		and #$0f
		sta scroll_speed

		lda #$20
okay_2		tax
		lda char_pos_dcd,x
		sta $0606

		inc mread+$01
		bne *+$05
		inc mread+$02

		ldx #$00
scr_xb		stx scroll_x
		dey
		bne scroll_loop

		lda scroll_x
		eor #$07
		sta $d016

; Update the sprite colours
		lda colour_cnt
		clc
		adc #$01
		cmp #$43
		bne *+$04
		lda #$00
		sta colour_cnt

		lsr
		bcc colour_move_1
		jmp colour_move_2

colour_move_1	tay

		ldx #$00
cm1_loop	lda spr_col_bffr_1+$01,x
		sta spr_col_bffr_1+$00,x
		inx
		cpx #$17
		bne cm1_loop

		cpy #$0a
		bcc *+$04
		ldy #$00

		lda sprite_colxs_1,y
		sta spr_col_bffr_1+$17

		jmp cm_out

colour_move_2	tay

		ldx #$16
cm2_loop	lda spr_col_bffr_2+$00,x
		sta spr_col_bffr_2+$01,x
		dex
		cpx #$ff
		bne cm2_loop

		cpy #$0a
		bcc *+$04
		ldy #$00

		lda sprite_colxs_2,y
		sta spr_col_bffr_2+$00

cm_out		ldx #$00
		ldy #$00
colour_trans	lda spr_col_bffr_1,y
		sta sprite_cols_1,x

		lda spr_col_bffr_2,y
		sta sprite_cols_2,x

		tya
		clc
		adc #$03
		tay
		inx
		cpx #$06
		bne colour_trans

; Play the music
		jsr $0804

; Wait for just above the top of the scroll area
		lda #$88
		cmp $d012
		bne *-$03

		lda #$3f
		sta $d01b

; Wait for during the top of the scroll area
		lda #$8a
		cmp $d012
		bne *-$03

		lda #$0f
		sta $d021

		sta $d027
		sta $d028
		sta $d029
		sta $d02a
		sta $d02b
		sta $d02c

		lda #$0c
		sta $d026

; Wait for during the bottom of the scroll area
		lda #$a0
		cmp $d012
		bne *-$03

		lda #scrn_colour
		sta $d021

		ldx #$00
sprite_set_2	lda sprite_cols_2,x
		sta $d027,x
		inx
		cpx #$06
		bne sprite_set_2

		lda #$00
		sta $d026

; Wait for just below the bottom of the scroll area
		lda #$a5
		cmp $d012
		bne *-$03

		lda #$00
		sta $d01b

; Check to see if space has been pressed
		lda $dc01
		cmp #$ef
		beq *+$05
		jmp main_loop

; Reset some registers
		lda #$00
		sta $d011
		sta $d020
		sta $d021
		sta $d418

; Restore $3fff
		lda ghost_store
		sta $3fff

; Reset the C64 (a linker would go here...)
		jmp $fce2


; Character decoder table
char_pos_dcd	!byte $80,$81,$82,$83,$84,$85,$86,$87		; @ to G
		!byte $88,$89,$8a,$8b,$8c,$8d,$8e,$8f		; H to O
		!byte $90,$91,$92,$93,$94,$95,$96,$97		; P to W
		!byte $98,$99,$9a,$80,$80,$80,$80,$80		; X to Z, 5 * punct.
		!byte $80,$9b,$80,$80,$a1,$80,$80,$ad		; space to '
		!byte $ab,$ac,$80,$a0,$9d,$9e,$9c,$80		; ( to /
		!byte $8f,$a2,$a3,$a4,$a5,$a6,$a7,$a8		; 0 to 7
		!byte $a9,$aa,$80,$80,$80,$80,$80,$9f		; 8 to ?

; Scrolling message
scroll_text	!scr $82,"femtotro - 2018 overkill remix"
		!scr "     "

		!scr $83,"coded by t.m.r (based on my compact "
		!scr "babygang intro from 1991) and using a "
		!scr "remarkably small tune by 4-mat"
		!scr "     "

		!scr $84,"to keep this intro compact the already "
		!scr "small music was unceremoniously ripped apart "
		!scr "with regenerator and bodged to make it take "
		!scr "less space (so i owe 4-mat an apology for "
		!scr "butchering his code, sorry!)"
		!scr "     "

		!scr "i've also got things like the character set "
		!scr "and some of the sprite data being decrunched "
		!scr "directly to the screen ram - the sprite data "
		!scr "pointers are being initialised that way "
		!scr "too - and the last thing in memory is this "
		!scr "scroll text, so if i'd stopped writing "
		!scr "already the intro would only have been"
		!scr $82,"be 3k long!",$84
		!scr "    "

		!scr $85,"and adding the full cosine greetings "
		!scr "list means the final release is over 4k "
		!scr "uncompressed including the screen, but "
		!scr "we might as well since the csdb icc's "
		!scr "rules say we've got enough space for it, "
		!scr "so..."
		!scr "     "

		!scr $86,"happy, fluffy thoughts head towards:"
		!scr "   "

		!scr $87,"absence, "
		!scr "abyss connection, "
		!scr "arkanix labs, "
		!scr "artstate, "
		!scr "ate bit, "
		!scr "atlantis, "

		!scr "booze design, "

		!scr "camelot, "
		!scr "censor design, "
		!scr "chorus, "
		!scr "chrome, "
		!scr "cncd, "
		!scr "cpu, "
		!scr "crescent, "
		!scr "crest, "
		!scr "covert bitops, "

		!scr "defence force, "
		!scr "dekadence, "
		!scr "desire, "
		!scr "dac, "
		!scr "dmagic, "
		!scr "dual crew, "

		!scr "exclusive on, "

		!scr "fairlight, "
		!scr "f4cg, "
		!scr "fire, "
		!scr "flat 3, "
		!scr "focus, "
		!scr "french touch, "
		!scr "funkscientist productions, "

		!scr "genesis project, "
		!scr "gheymaid inc, "

		!scr "hitmen, "
		!scr "hoaxers, "
		!scr "hokuto force, "

		!scr "legion of doom, "
		!scr "level 64, "

		!scr "maniacs of noise, "
		!scr "mayday, "
		!scr "meanteam, "
		!scr "metalvotze, "

		!scr "noname, "
		!scr "nostalgia, "
		!scr "nuance, "

		!scr "offence, "
		!scr "onslaught, "
		!scr "orb, "
		!scr "oxyron, "

		!scr "padua, "
		!scr "performers, "
		!scr "plush, "
		!scr "ppcs, "
		!scr "psytronik, "

		!scr "reptilia, "
		!scr "resource, "
		!scr "rgcd, "

		!scr "secure, "
		!scr "shape, "
		!scr "side b, "
		!scr "singular, "
		!scr "slash, "
		!scr "slipstream, "
		!scr "success and trc, "
		!scr "style, "
		!scr "suicyco industries, "

		!scr "taquart, "
		!scr "tempest, "
		!scr "tek, "
		!scr "triad, "
		!scr "trsi, "

		!scr "viruz, "
		!scr "vision, "

		!scr "wow, "
		!scr "wrath "
		!scr "and xenon...  "
		!scr "     "

		!scr $84,"and now that's all sorted we just have "
		!scr "to dish out the plugs for cosine on the "
		!scr "wibbly wobbly web "
		!scr $82,"- cosine.org.uk - "
		!scr $84,"and my own blog type thingy over at "
		!scr $82,"- jasonkelk.me.uk - "

		!scr $84,"and then sign off, so this been "
		!scr $83,"t.m.r of cosine on 2018-12-08"
		!scr $82,"... .. .  .",$81
		!scr "           "

		!byte $00	; end of text marker


; Set up the screen RAM where the scroller is
		* = $0590
!set byte_cnt=$00
!do {		!byte $ae
		!set byte_cnt=byte_cnt+$01
} until byte_cnt=$28

!set byte_cnt=$00
!do {		!byte $af
		!set byte_cnt=byte_cnt+$01
} until byte_cnt=$28

!set byte_cnt=$00
!do {		!byte $80
		!set byte_cnt=byte_cnt+$01
} until byte_cnt=$28

!set byte_cnt=$00
!do {		!byte $b0
		!set byte_cnt=byte_cnt+$01
} until byte_cnt=$28

!set byte_cnt=$00
!do {		!byte $b1
		!set byte_cnt=byte_cnt+$01
} until byte_cnt=$28


; Sprite positions
sprite_x_pos	!byte $28,$5a,$8c,$be,$e8,$1a,$00,$00
sprite_y_pos	!byte $40,$40,$40,$40,$40,$40,$40,$40
sprite_x_msb	!byte $20

; Sprite colours
sprite_cols_1	!byte $06,$04,$0e,$03,$0d,$01
sprite_cols_2	!byte $01,$07,$0f,$0a,$08,$09

; Sprite colour fade tables
sprite_colxs_1	!byte $06,$04,$0e,$03,$0d,$01,$0d,$03
		!byte $0e,$04

sprite_colxs_2	!byte $09,$08,$0a,$0f,$07,$01,$07,$0f
		!byte $0a,$08

spr_col_bffr_1	!byte $06,$06,$06,$06,$06,$06,$06,$06
		!byte $06,$06,$06,$06,$06,$06,$06,$06
		!byte $06,$06,$06,$06,$06,$06,$06,$06

spr_col_bffr_2	!byte $09,$09,$09,$09,$09,$09,$09,$09
		!byte $09,$09,$09,$09,$09,$09,$09,$09
		!byte $09,$09,$09,$09,$09,$09,$09,$09

; Sprite cosine table
sprite_cos	!byte $ca,$ca,$ca,$ca,$ca,$ca,$ca,$c9
		!byte $c9,$c9,$c8,$c8,$c7,$c7,$c6,$c6
		!byte $c5,$c4,$c3,$c3,$c2,$c1,$c0,$bf
		!byte $be,$bd,$bc,$bb,$ba,$b9,$b7,$b6
		!byte $b5,$b4,$b2,$b1,$b0,$ae,$ad,$ab
		!byte $aa,$a8,$a7,$a5,$a4,$a2,$a0,$9f
		!byte $9d,$9b,$9a,$98,$96,$94,$93,$91
		!byte $8f,$8d,$8c,$8a,$88,$86,$84,$83

		!byte $81,$7f,$7d,$7b,$7a,$78,$76,$74
		!byte $73,$71,$6f,$6d,$6c,$6a,$68,$66
		!byte $65,$63,$61,$60,$5e,$5d,$5b,$5a
		!byte $58,$57,$55,$54,$52,$51,$4f,$4e
		!byte $4d,$4c,$4a,$49,$48,$47,$46,$45
		!byte $44,$43,$42,$41,$40,$3f,$3e,$3e
		!byte $3d,$3c,$3c,$3b,$3b,$3a,$3a,$39
		!byte $39,$39,$38,$38,$38,$38,$38,$38

; Sprite data pointers (written straight to $07f8)
		* = $07f8
		!byte $1d,$1e,$2d,$2e,$2f,$30
