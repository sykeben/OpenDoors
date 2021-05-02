// CONSOLE CODE
// Requires "system/coretext.asm"
// Note: Console size is 36 wide by 20 tall.

	.memblock "Console: Subroutines"

	// Zero-page pointer addresses.
	// These can NEVER be used anywhere else if you EVER enable the autorefresh on IRQ.
	// The autorefresh routine does not care what is stored at these addresses.
	// They will be overwritten without any mercy.
		.const C_SLO = $FB
		.const C_SHI = $FC
		.const C_DLO = $FD
		.const C_DHI = $FE
		.const C_NLO = $43	// These one's are okay, though.
		.const C_NHI = $44	// They are only used for non-interrupt subroutines.

	// Refreshes console text.
	C_RTXT:	{
		// Initialize source pointer.
		lda #<C_TBUF
		sta C_SLO
		lda #>C_TBUF
		sta C_SHI

		// Initialize destination pointer.
		lda #<$047a
		sta C_DLO
		lda #>$047a
		sta C_DHI

		// Initialize registers.
		ldx #0

		// Update line in screen memory
	loop1:	ldy #0
	loop2:	lda (C_SLO),y
		sta (C_DLO),y
		cpy #35
		beq endl2
		iny
		jmp loop2

	endl2:	// Finish if reached end.
		cpx #19
		beq endl1

		// Advance source pointer.
		clc
		lda C_SLO
		adc #36
		sta C_SLO
		bcc lordy
		inc C_SHI

		// Advance destination pointer.
	lordy:	clc
		lda C_DLO
		adc #40
		sta C_DLO
		bcc hirdy
		inc C_DHI

		// Move down a line and go back.
	hirdy:	inx
		jmp loop1

	endl1:	// Done, go back!
		rts
	}

	// Refreshes console colors.
	C_RCLR:	{
		// Initialize source pointer.
		lda #<C_CBUF
		sta C_SLO
		lda #>C_CBUF
		sta C_SHI

		// Initialize destination pointer.
		lda #<$d87a
		sta C_DLO
		lda #>$d87a
		sta C_DHI

		// Initialize registers.
		ldx #0

		// Update line in color memory
	loop1:	ldy #0
	loop2:	lda (C_SLO),y
		sta (C_DLO),y
		cpy #35
		beq endl2
		iny
		jmp loop2

	endl2:	// Finish if reached end.
		cpx #19
		beq endl1

		// Advance source pointer.
		clc
		lda C_SLO
		adc #36
		sta C_SLO
		bcc lordy
		inc C_SHI

		// Advance destination pointer.
	lordy:	clc
		lda C_DLO
		adc #40
		sta C_DLO
		bcc hirdy
		inc C_DHI

		// Move down a line and go back.
	hirdy:	inx
		jmp loop1

	endl1:	// Done, go back!
		rts
	}

	// Autorefresh IRQ.
	C_IRQ: {
		// Perform update if flag = 1.
		// Do not perform update otherwise.
		ldx C_FLAG
		cpx #$01
		beq on
		jmp off

	on:	// Perform text & color update.
		jsr C_RTXT
		jsr C_RCLR

	off:	// Acknowledge interrupt & go back to normal.
		lda #$00
		asl $d019
		jmp $ea31
	}

	// Prepares autorefresh on IRQ.
	// Routine written from: https://www.c64-wiki.com/wiki/Raster_interrupt
	C_PREP: {
		// Set autorefresh enable flag to 0.
		jsr C_IOFF

		// Disable interrupts while we modify them.
		sei
		lda #%01111111
		sta $dc0d

		// Clear MSB of VIC raster register.
		and $d011
		sta $d011

		// Acknowledge pending interrupts from CIA-1 and 2.
		lda $dc0d
		lda $dd0d

		// Set rasterline when IRQ happens.
		// Let's be real, this can be optimized so we don't get screen tearing ever,
		// but for now this value seems to work fine.
		lda #210
		sta $d012

		// Set vectors to point to our new IRQ.
		lda #<C_IRQ
		sta $0314
		lda #>C_IRQ
		sta $0315

		// Enable raster IRQ's from VIC.
		lda #%00000001
		sta $d01a

		// Re-enable IRQ's.
		cli
		rts
	}

	// Enables IRQ autorefresh.
	C_ION: {
		// Set active flag to 1.
		ldx #$01
		stx C_FLAG
		rts
	}

	// Disables IRQ autorefresh.
	C_IOFF: {
		// Set active flag to 0.
		ldx #$00
		stx C_FLAG
		rts
	}



// CONSOLE BUFFERS

	.memblock "Console: Buffers"

	// Text & color buffers.
	// Note: The text buffer is encoded as raw characters.
	// This is because the console update routines directly modify screen memory.
	// An unintended side-effect of this is that you can use more cool characters.
	C_TBUF: .fill 648,' '
		.text "what is going on here?              "
		.text "cool terminal stuff!                "
	// C_TBUF:	.fill 720,$01
	C_TEND: // Buffer end marker.
	C_CBUF: .fill 720,$01
	C_CEND:	// Buffer end marker.

	// Autorefresh enable flag.
	// I would normally put this in the zero page,
	// but it won't be used that often so who cares.
	C_FLAG: .byte $00

	// Line offset.
	// This is so we don't have to keep moving memory around.
	C_LOFF: .byte $00