// DELAY SUBROUTINES

		.memblock "Delay: Subroutines"

	// Delays for an arbitrary amount of cycles
	D_CYCL: {
		// Increment until we make it.
		lda #$00
	loop:	inc D_TOTL
		cmp D_TOTL
		bne loop

		// Return.
		rts
	}
	.macro delay(cycles) {
		lda #cycles
		jsr D_CYCL
	}



// DELAY BUFFERS

		.memblock "Delay: Buffers"

	D_TOTL:	.byte $00