// MAIN PROGRAM

		#import	"symbols/kernal.asm"
		#import "system/coretext.asm"
		#import "system/console.asm"



// BASIC LOADER

		.pc=$0801 "Main: BASIC Loader"

		// Basic line: 10 SYS 4096
		.byte $0c,$08,$0a,$00,$9e,$20,$34,$30,$39,$36,$00,$00,$00



// INITIALIZER

		.pc=$1000 "Main: Initializer"

		// Initialize video chip.
		jsr K_CINT

		// Go into lowercase mode.
		setUppercaseMode(false)

		// Setup initialization colors.
		setTheme(0,0,15)

		// Draw title.
		setCursor(1,1)
		printString(M_TITL)

		// Draw top of box.
		setCursor(1,2)
		printChar($6F)
		printLineHorizontal($B7,36)
		printChar($70)

		// Draw bottom of box.
		setCursor(1,23)
		printChar($6C)
		printLineHorizontal($AF,36)
		printChar($BA)

		// Draw left side of box.
		setCursor(1,3)
		printLineVertical($B4,20)

		// Draw right side of box.
		setCursor(38,3)
		printLineVertical($AA,20)

		// Revert to running colors.
		setTheme(11,0,1)



// SYSTEM CONSOLE

		.memblock "Main: System Console"

		// Prepare and enable autoupdate.
		prepAutorefresh()
		autorefreshEnable(true)

		// Offset this bad boi.
		lda #36
		sta C_SOLO



// "HALT" LOOP
	
	halt:	jmp halt



// MAIN DATA

	.memblock "Main: Data"

		// Title of the console window.
	M_TITL:	.byte $6f,$50,$45,$4e,$64,$4f,$4f,$52,$53,$00 // "OpenDoors"
