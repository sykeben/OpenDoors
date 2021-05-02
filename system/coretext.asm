// CORE TEXT CODE
// Requires "symbols/kernal.asm"

		.memblock "Core Text: Subroutines"
	
	// Zero-page pointer addresses.
	// Yes, I am aware BASIC's "INPUT" uses these, I don't care.
	// In this world BASIC isn't running so $43-$44 will be available.
	// Also, all documentation points to $02 being unused so that's mine now.
	// Since this is not interrupt code, these can be used elsewhere.
		.const T_SLO = $43
		.const T_SHI = $44
		.const T_ACC = $02

	// Prints a character.
	.macro printChar(char) {
		lda #char
		jsr K_CHROUT
	}

	// Prints a null-terminated string.
	T_PSTR: {
		stx T_SLO
		sty T_SHI
		ldy #0
	loop:	lda (T_SLO),y
		cmp #0
		beq endl
		jsr K_CHROUT
		iny
		jmp loop
	endl:	rts
	}
	.macro printString(location) {
		ldx #<location
		ldy #>location
		jsr T_PSTR
	}

	// Prints a horizontal line of characters.
	T_PHLC:{
		stx T_SLO
		sty T_SHI
		ldx #0
	loop:	inx
		lda T_SLO
		jsr K_CHROUT
		cpx T_SHI
		beq endl
		jmp loop
	endl:	rts
	}
	.macro printLineHorizontal(char, count) {
		ldx #char
		ldy #count
		jsr T_PHLC
	}

	// Prints a vertical line of characters.
	T_PVLC: {
		stx T_SLO
		sty T_SHI
		tya
		getCursor()
		stx T_ACC
		adc T_ACC
		sta T_SHI
		dec T_SHI // Somewhere, my math is bad.
		dec T_SHI // Please don't repeat this hack.
	loop:	clc
		jsr K_PLOT
		lda T_SLO
		jsr K_CHROUT
		cpx T_SHI
		beq endl
		inx
		jmp loop
	endl:	rts
	}
	.macro printLineVertical(char, count) {
		ldx #char
		ldy #count
		jsr T_PVLC
	}

	// Sets cursor position.
	.macro setCursor(posX, posY) {
		ldx #posY
		ldy #posX
		clc
		jsr K_PLOT
	}

	// Gets cursor position.
	.macro getCursor() {
		ldx #0
		ldy #0
		sec
		jsr K_PLOT
	}

	// Sets the border color.
	.macro setBorderColor(color) {
		lda #color
		sta $d020
	}

	// Sets the background color.
	.macro setBackgroundColor(color) {
		lda #color
		sta $d021
	}

	// Sets the foreground color.
	.macro setForegroundColor(color) {
		lda #color
		sta $0286
	}

	// Sets color theming.
	.macro setTheme(border, background, foreground) {
		setBorderColor(border)
		setBackgroundColor(background)
		setForegroundColor(foreground)
	}



// CORE TEXT DATA

		.memblock "Core Text: Data"

		// Title of the console window.
	ctitle:	.text @"OPENDOORS V0.1\$00"

		// Test lines.
	ctln1:	.text @".........1.........2.........3......\$00"
	ctln2:	.text @"123456789 123456789 123456789 123456\$00"