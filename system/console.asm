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
		.const C_MLO = $57	// These one's are okay, though.
		.const C_MHI = $58	// They are only used for non-interrupt subroutines.
		.const C_NLO = $59	// |
		.const C_NHI = $60	// |

	// Refreshes the console using a bunch of pointers.
	C_RCON: {
		// Offset source pointer.
		clc
		lda C_SSLO
		adc C_SOLO
		sta C_SLO
		lda C_SSHI
		adc C_SOHI
		sta C_SHI

		// Initialize registers.
		ldx #0

		// Update line in memory.
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
		bcc srdy
		inc C_SHI

		// Wrap source pointer around if hit end.
	srdy:	lda C_SHI
		cmp C_SEHI
		bne snext
		lda C_SLO
		cmp C_SELO
	snext:	beq swrap
		jmp wrdy
	swrap:	lda C_SSLO
		sta C_SLO
		lda C_SSHI
		sta C_SHI

		// Advance destination pointer.
	wrdy:	clc
		lda C_DLO
		adc #40
		sta C_DLO
		bcc drdy
		inc C_DHI

		// Move down a line and go back.
	drdy:	inx
		jmp loop1

	endl1:	// Done, go back!
		rts
	}

	// Refreshes console text.
	C_RTXT:	{
		// Initialize source start pointer.
		lda #<C_TBUF
		sta C_SSLO
		lda #>C_TBUF
		sta C_SSHI

		// Initialize source end pointer.
		lda #<C_TEND
		sta C_SELO
		lda #>C_TEND
		sta C_SEHI

		// Initialize destination pointer.
		lda #<$047a
		sta C_DLO
		lda #>$047a
		sta C_DHI

		// Perform update and leave.
		jsr C_RCON
		rts
	}

	// Refreshes console colors.
	C_RCLR:	{
		// Initialize source start pointer.
		lda #<C_CBUF
		sta C_SSLO
		lda #>C_CBUF
		sta C_SSHI

		// Initialize source end pointer.
		lda #<C_CEND
		sta C_SELO
		lda #>C_CEND
		sta C_SEHI

		// Initialize destination pointer.
		lda #<$d87a
		sta C_DLO
		lda #>$d87a
		sta C_DHI

		// Perform update and leave.
		jsr C_RCON
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
		autorefreshEnable(false)

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
	.macro prepAutorefresh() {
		jsr C_PREP
	}

	// Enables/disables IRQ autorefresh.
	.macro autorefreshEnable(enabled) {
		ldx #enabled ? $01:$00
		stx C_FLAG
	}

	// Advances offset by one line.
	C_ADV: {
		// Advance offset.
		clc
		lda C_SOLO
		adc #36
		sta C_SOLO
		bcc next
		inc C_SOHI

		// Check for wraparound.
	next:	lda #<C_TEND-C_TBUF
		cmp C_SOLO
		bne ordy
		lda #>C_TEND-C_TBUF
		cmp C_SOHI
		bne ordy

		// Perform wraparound.
		lda #$00
		sta C_SOLO
		sta C_SOHI

		// Done.
	ordy:	rts
	}
	.macro advanceOffset() {
		jsr C_ADV
	}



// CONSOLE BUFFERS

	.memblock "Console: Buffers"

	// Text & color buffers.
	// Note: The text buffer is encoded as raw characters.
	// This is because the console update routines directly modify screen memory.
	// An unintended side-effect of this is that you can use more cool characters.
	C_TBUF: .fill 720,$a0
	// C_TBUF:	.fill 720,$20
	C_TEND: .byte $ff // Buffer end marker.
	// C_CBUF:	.fill 720,$01
	C_CBUF: .fill 36,02
		.fill 36,08
		.fill 36,07
		.fill 36,05
		.fill 36,06
		.fill 36,03
		.fill 36,04
		.fill 36*13,$01
	C_CEND: .byte $ff // Buffer end marker.

	// Autorefresh enable flag.
	// I would normally put this in the zero page,
	// but it won't be used that often so who cares.
	C_FLAG: .byte $00

	// Source offset values.
	// This is used to implement a circular buffer.
	// I don't want to have to shift memory around when I add a line.
	// Only to be used by interrupts.
	C_SOLO: .byte $00
	C_SOHI: .byte $00

	// Source start/end values.
	// These are used by the circular buffer to determine when to return to
	// the start of the buffer and where that start is in memory.
	// Only to be used by interrupts.
	C_SSLO: .byte $00
	C_SSHI: .byte $00
	C_SELO: .byte $00
	C_SEHI: .byte $00
