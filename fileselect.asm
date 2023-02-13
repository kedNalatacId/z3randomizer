
;FS prefix means file_select, since these defines and macros are specific to this screen

!FS_COLOR_BROWN = $0000 ;(only used for: Shovel, hammer, powder)
!FS_COLOR_RED = $0400
!FS_COLOR_YELLOW = $0800
!FS_COLOR_BLUE = $0C00
!FS_COLOR_GRAY = $1000 ;(Used to gray out items)
!FS_COLOR_BOOTS = $1400
!FS_COLOR_GREEN = $1800
!FS_COLOR_BW = $1C00

!FS_HFLIP = $4000
!FS_VFLIP = $8000

macro fs_draw8x8(screenrow,screencol)
	;Note due to XKAS's screwy math this formula is misleading.
	;in normal math we have $1004+2*col+$40*row
	STA.w <screenrow>*$20+<screencol>*2+$1004
endmacro
macro fs_draw16x8(screenrow,screencol)
	%fs_draw8x8(<screenrow>,<screencol>)
	INC A
	%fs_draw8x8(<screenrow>,<screencol>+1)
endmacro
macro fs_draw8x16(screenrow,screencol)
	%fs_draw8x8(<screenrow>,<screencol>)
	!ADD #$0010
	%fs_draw8x8(<screenrow>+1,<screencol>)
endmacro
macro fs_draw16x16(screenrow,screencol)
	%fs_draw16x8(<screenrow>,<screencol>)
	!ADD #$000F
	%fs_draw16x8(<screenrow>+1,<screencol>)
endmacro

macro fs_LDY_screenpos(screenrow,screencol)
	LDY.w #<screenrow>*$20+<screencol>*2+$1004
endmacro

macro fs_drawItem(screenrow,screencol,tileAddress)
	LDX.w #<tileAddress>
	%fs_LDY_screenpos(<screenrow>,<screencol>)
	JSR DrawItem
endmacro
macro fs_drawItemGray(screenrow,screencol,tileAddress)
	LDX.w #<tileAddress>
	%fs_LDY_screenpos(<screenrow>,<screencol>)
	JSR DrawItemGray
endmacro

macro fs_drawItemBasic(address,screenrow,screencol,tileAddress)
	LDX.w #<tileAddress>
	%fs_LDY_screenpos(<screenrow>,<screencol>)
	LDA.l <address>
	JSR DrawItemBasic
endmacro

macro fs_drawBottle(address,screenrow,screencol)
	%fs_LDY_screenpos(<screenrow>,<screencol>)
	LDA.l <address>
	JSR DrawBottle
endmacro

DrawItem:
	LDA.w $0000,X : STA.w $0000, Y
	LDA.w $0002,X : STA.w $0002, Y
	LDA.w $0004,X : STA.w $0040, Y
	LDA.w $0006,X : STA.w $0042, Y
RTS
DrawItemGray:
	LDA.w $0000,X : AND.w #$E3FF : ORA.w #!FS_COLOR_GRAY : STA.w $0000, Y
	LDA.w $0002,X : AND.w #$E3FF : ORA.w #!FS_COLOR_GRAY : STA.w $0002, Y
	LDA.w $0004,X : AND.w #$E3FF : ORA.w #!FS_COLOR_GRAY : STA.w $0040, Y
	LDA.w $0006,X : AND.w #$E3FF : ORA.w #!FS_COLOR_GRAY : STA.w $0042, Y
RTS
DrawItemBasic:
	AND.w #$00FF : BEQ +
		JMP DrawItem
	+
JMP DrawItemGray

DrawBottle:
	AND.w #$00FF : BNE +
		LDX.w #FileSelectItems_empty_bottle
		JMP DrawItemGray
	+ : DEC #2 : BNE +
		LDX.w #FileSelectItems_empty_bottle
		JMP DrawItem
	+ : DEC : BNE +
		LDX.w #FileSelectItems_red_potion
		JMP DrawItem
	+ : DEC : BNE +
		LDX.w #FileSelectItems_green_potion
		JMP DrawItem
	+ : DEC : BNE +
		LDX.w #FileSelectItems_blue_potion
		JMP DrawItem
	+ : DEC : BNE +
		LDX.w #FileSelectItems_fairy_bottle
		JMP DrawItem
	+ : DEC : BNE +
		LDX.w #FileSelectItems_bee_bottle
		JMP DrawItem
	+
	LDX.w #FileSelectItems_good_bee_bottle
JMP DrawItem


DrawPlayerFile:
	LDA.b FrameCounter : AND.w #$0001 : BNE .normal
		JSR DrawPlayerFileShared

		INC.w SkipOAM ; Suppress animated tile updates for this frame

		; re-enable  Stripe Image format upload on this frame
		; Value loaded must match what gets set by AltBufferTable
		LDA.w #$0161 : STA.w GFXStripes+2

		LDA.w #$C000>>1
		XBA
		STA.w GFXStripes+$0402

		LDA.w #$C03E>>1
		XBA
		STA.w GFXStripes+$0408

		LDA.w #$C000|57
		XBA
		STA.w GFXStripes+$0404
		STA.w GFXStripes+$040A
	
		LDA.w #$12BF
		STA.w GFXStripes+$0406
		ORA.w #$4000
		STA.w GFXStripes+$040C
	
		LDA.w #$C0C6>>1
		XBA
		STA.w GFXStripes+$040E

		LDA.w #$4001
		XBA
		STA.w GFXStripes+$0410

		LDA.l DisableFlashing
		AND.w #$00FF
		BEQ .flashing

		LDA.w #$26BE
		BRA .draw_access_icon

.flashing
		LDA.w #$0188
		NOP ; 2 cycles wasted to be equal

.draw_access_icon
		STA.w GFXStripes+$0412

		LDA.w #$FFFF
		STA.w GFXStripes+$0414


		BRA .done
	.normal
	STZ.w SkipOAM ; ensure core animated tile updates are not suppressed
	LDA.w #$FFFF : STA.w GFXStripes+2 ; Suppress Stripe Image format upload on this frame
.done
	LDA.w #$0004 : STA.b Scrap02 ; thing we wrote over
RTL


DrawPlayerFileShared:
	PHX : PHY : PHB

	SEP #$20 ; set 8-bit accumulator
	LDA.b #FileSelectItems>>16 : PHA : PLB
	REP #$20 ; restore 16 bit accumulator

	LDA.l ExtendedFileNameSRAM+$08 : ORA.w #!FS_COLOR_BW
	%fs_draw8x16(6,5)
	LDA.l ExtendedFileNameSRAM+$0A : ORA.w #!FS_COLOR_BW
	%fs_draw8x16(6,6)
	LDA.l ExtendedFileNameSRAM+$0C : ORA.w #!FS_COLOR_BW
	%fs_draw8x16(6,7)
	LDA.l ExtendedFileNameSRAM+$0E : ORA.w #!FS_COLOR_BW
	%fs_draw8x16(6,8)

	LDA.l ExtendedFileNameSRAM+$10 : ORA.w #!FS_COLOR_BW
	%fs_draw8x16(9,5)
	LDA.l ExtendedFileNameSRAM+$12 : ORA.w #!FS_COLOR_BW
	%fs_draw8x16(9,6)
	LDA.l ExtendedFileNameSRAM+$14 : ORA.w #!FS_COLOR_BW
	%fs_draw8x16(9,7)
	LDA.l ExtendedFileNameSRAM+$16 : ORA.w #!FS_COLOR_BW
	%fs_draw8x16(9,8)

	JSR FileSelectDrawHudBar

	; Bow
	LDA.l BowTrackingSRAM : AND.w #$0040 : BEQ +
		LDA.l EquipmentSRAM+$00 : AND.w #$00FF : BEQ ++
			%fs_drawItem(3,12,FileSelectItems_silver_bow)
			BRA .bow_end
		++
		%fs_drawItem(3,12,FileSelectItems_silver_arrow)
		BRA .bow_end
	+
	LDA.l EquipmentSRAM : AND.w #$00FF : BEQ +
		%fs_drawItem(3,12,FileSelectItems_bow)
		BRA .bow_end
	+
	%fs_drawItemGray(3,12,FileSelectItems_bow)
	.bow_end

	; Boomerang
	LDA.l InventoryTrackingSRAM : AND.w #$00C0 : CMP.w #$00C0 : BNE +
		%fs_drawItem(3,14,FileSelectItems_both_boomerang)
		BRA .boomerang_end
	+
	LDA.l InventoryTrackingSRAM : AND.w #$0040 : BEQ +
		%fs_drawItem(3,14,FileSelectItems_red_boomerang)
		BRA .boomerang_end
	+
	LDA.l InventoryTrackingSRAM : AND.w #$0080 : BEQ +
		%fs_drawItem(3,14,FileSelectItems_blue_boomerang)
		BRA .boomerang_end
	+
	%fs_drawItemGray(3,14,FileSelectItems_blue_boomerang)
	.boomerang_end

	; Hookshot
	%fs_drawItemBasic(EquipmentSRAM+$02,3,16,FileSelectItems_hookshot)

	; Bombs
	; %fs_drawItemBasic(EquipmentSRAM+$03,3,18,FileSelectItems_bombs)

	; Powder
	LDA.l InventoryTrackingSRAM : AND.w #$0010 : BEQ +
		%fs_drawItem(3,20,FileSelectItems_powder)
		BRA ++
	+
		%fs_drawItemGray(3,20,FileSelectItems_powder)
	++

	; Mushroom
	LDA.l InventoryTrackingSRAM : AND.w #$0008 : BEQ +
		%fs_drawItem(3,18,FileSelectItems_mushroom)
		BRA ++
	+
		%fs_drawItemGray(3,18,FileSelectItems_mushroom)
	++

	; Flute
	LDA.l InventoryTrackingSRAM : AND.w #$0003 : BEQ +
		%fs_drawItem(7,16,FileSelectItems_flute)
		BRA ++
	+
		%fs_drawItemGray(7,16,FileSelectItems_flute)
	++

	; Shovel
	LDA.l InventoryTrackingSRAM : AND.w #$0004 : BEQ +
		%fs_drawItem(9,12,FileSelectItems_shovel)
		BRA ++
	+
		%fs_drawItemGray(9,12,FileSelectItems_shovel)
	++

	; Fire Rod
	%fs_drawItemBasic(EquipmentSRAM+$05,5,12,FileSelectItems_fire_rod)

	; Ice Rod
	%fs_drawItemBasic(EquipmentSRAM+$06,5,14,FileSelectItems_ice_rod)

	; Bombos Medallion
	%fs_drawItemBasic(EquipmentSRAM+$07,5,16,FileSelectItems_bombos)

	; Ether Medallion
	%fs_drawItemBasic(EquipmentSRAM+$08,5,18,FileSelectItems_ether)

	; Quake Medallion
	%fs_drawItemBasic(EquipmentSRAM+$09,5,20,FileSelectItems_quake)

	; Lamp
	%fs_drawItemBasic(EquipmentSRAM+$0A,7,12,FileSelectItems_lamp)

	; Hammer
	%fs_drawItemBasic(EquipmentSRAM+$0B,7,14,FileSelectItems_hammer)

	; Bug Net
	%fs_drawItemBasic(EquipmentSRAM+$0D,7,18,FileSelectItems_bugnet)

	; Book of Mudora
	%fs_drawItemBasic(EquipmentSRAM+$0E,7,20,FileSelectItems_book)

	; Red Cane
	%fs_drawItemBasic(EquipmentSRAM+$10,9,14,FileSelectItems_redcane)

	; Blue Cane
	%fs_drawItemBasic(EquipmentSRAM+$11,9,16,FileSelectItems_bluecane)

	; Cape
	%fs_drawItemBasic(EquipmentSRAM+$12,9,18,FileSelectItems_cape)

	; Mirror
	%fs_drawItemBasic(EquipmentSRAM+$13,9,20,FileSelectItems_mirror)

	; Bottles
	%fs_drawBottle(EquipmentSRAM+$1C,3,23)
	%fs_drawBottle(EquipmentSRAM+$1D,5,23)
	%fs_drawBottle(EquipmentSRAM+$1E,7,23)
	%fs_drawBottle(EquipmentSRAM+$1F,9,23)

	; Sword
	LDA.l EquipmentSRAM+$19 : AND.w #$00FF : BNE +
		%fs_drawItemGray(3,26,FileSelectItems_fighters_sword)
		BRA ++
	+ : DEC : BNE +
		%fs_drawItem(3,26,FileSelectItems_fighters_sword)
		BRA ++
	+ : DEC : BNE +
		%fs_drawItem(3,26,FileSelectItems_master_sword)
		BRA ++
	+ : DEC : BNE +
		%fs_drawItem(3,26,FileSelectItems_tempered_sword)
		BRA ++
	+ : DEC : BNE +
		%fs_drawItem(3,26,FileSelectItems_gold_sword)
		BRA ++
	+
		; a sword value above 4 is either corrupted or 0xFF (a.k.a. swordless)
		%fs_drawItemGray(3,26,FileSelectItems_fighters_sword)
	++

	; Shield
	LDA.l EquipmentSRAM+$1A : AND.w #$00FF : BNE +
		%fs_drawItemGray(5,26,FileSelectItems_fighters_shield)
		BRA ++
	+ : DEC : BNE +
		%fs_drawItem(5,26,FileSelectItems_fighters_shield)
		BRA ++
	+ : DEC : BNE +
		%fs_drawItem(5,26,FileSelectItems_fire_shield)
		BRA ++
	+
		%fs_drawItem(5,26,FileSelectItems_mirror_shield)
	++

	; Mail
	LDA.l EquipmentSRAM+$1B : AND.w #$00FF : BNE +
		%fs_drawItem(7,26,FileSelectItems_green_mail)
		BRA ++
	+ : DEC : BNE +
		%fs_drawItem(7,26,FileSelectItems_blue_mail)
		BRA ++
	+
		%fs_drawItem(7,26,FileSelectItems_red_mail)
	++

	; Heart Pieces
	LDA.l EquipmentSRAM+$2B : AND.w #$00FF : BNE +
		%fs_drawItem(9,26,FileSelectItems_heart_piece_0_of_4)
		BRA ++
	+ : DEC : BNE +
		%fs_drawItem(9,26,FileSelectItems_heart_piece_1_of_4)
		BRA ++
	+ : DEC : BNE +
		%fs_drawItem(9,26,FileSelectItems_heart_piece_2_of_4)
		BRA ++
	+
		%fs_drawItem(9,26,FileSelectItems_heart_piece_3_of_4)
	++

	LDA.l EquipmentSRAM+$0108 : AND.w #$00FF
	JSL.l HexToDec
	LDA.l HexToDecDigit4 : AND.w #$00FF : !ADD.w #$210+!FS_COLOR_BW : %fs_draw8x8(11,26)
	LDA.l HexToDecDigit5 : AND.w #$00FF : !ADD.w #$210+!FS_COLOR_BW : %fs_draw8x8(11,27)

	; Boots
	%fs_drawItemBasic(EquipmentSRAM+$15,3,28,FileSelectItems_boots)

	; Gloves
	LDA.l EquipmentSRAM+$14 : AND.w #$00FF : BNE +
		%fs_drawItemGray(5,28,FileSelectItems_gloves)
		BRA ++
	+ : DEC : BNE +
		%fs_drawItem(5,28,FileSelectItems_gloves)
		BRA ++
	+
		%fs_drawItem(5,28,FileSelectItems_mitts)
	++

	; Flippers
	%fs_drawItemBasic(EquipmentSRAM+$16,7,28,FileSelectItems_flippers)

	; Moon Pearl
	%fs_drawItemBasic(EquipmentSRAM+$17,9,28,FileSelectItems_pearl)

	; Pendants
	LDA.l EquipmentSRAM+$34 : AND.w #$0004 : BEQ +
		%fs_drawItem(12,12,FileSelectItems_green_pendant)
		BRA ++
	+
		%fs_drawItem(12,12,FileSelectItems_no_pendant)
	++

	LDA.l EquipmentSRAM+$34 : AND.w #$0002 : BEQ +
		%fs_drawItem(12,14,FileSelectItems_blue_pendant)
		BRA ++
	+
		%fs_drawItem(12,14,FileSelectItems_no_pendant)
	++

	LDA.l EquipmentSRAM+$34 : AND.w #$0001 : BEQ +
		%fs_drawItem(12,16,FileSelectItems_red_pendant)
		BRA ++
	+
		%fs_drawItem(12,16,FileSelectItems_no_pendant)
	++

	; Crystals
	LDA.l EquipmentSRAM+$3A : AND.w #$0002 : BEQ +
		LDA.w #$0297|!FS_COLOR_BLUE
		BRA ++
	+
		LDA.w #$0287|!FS_COLOR_GRAY
	++ : %fs_draw16x8(13,18)

	LDA.l EquipmentSRAM+$3A : AND.w #$0010 : BEQ +
		LDA.w #$0297|!FS_COLOR_BLUE
		BRA ++
	+
		LDA.w #$0287|!FS_COLOR_GRAY
	++ : %fs_draw16x8(12,19)

	LDA.l EquipmentSRAM+$3A : AND.w #$0040 : BEQ +
		LDA.w #$0297|!FS_COLOR_BLUE
		BRA ++
	+
		LDA.w #$0287|!FS_COLOR_GRAY
	++ : %fs_draw16x8(13,20)

	LDA.l EquipmentSRAM+$3A : AND.w #$0020 : BEQ +
		LDA.w #$0297|!FS_COLOR_BLUE
		BRA ++
	+
		LDA.w #$0287|!FS_COLOR_GRAY
	++ : %fs_draw16x8(12,21)

	LDA.l EquipmentSRAM+$3A : AND.w #$0004 : BEQ +
		LDA.w #$0297|!FS_COLOR_RED
		BRA ++
	+
		LDA.w #$0287|!FS_COLOR_GRAY
	++ : %fs_draw16x8(13,22)

	LDA.l EquipmentSRAM+$3A : AND.w #$0001 : BEQ +
		LDA.w #$0297|!FS_COLOR_RED
		BRA ++
	+
		LDA.w #$0287|!FS_COLOR_GRAY
	++ : %fs_draw16x8(12,23)

	LDA.l EquipmentSRAM+$3A : AND.w #$0008 : BEQ +
		LDA.w #$0297|!FS_COLOR_BLUE
		BRA ++
	+
		LDA.w #$0287|!FS_COLOR_GRAY
	++ : %fs_draw16x8(13,24)


	PLB : PLY : PLX
RTS
;--------------------------------------------------------------------------------

FileSelectItems:
	.empty_bow ;for an eventual update for retro mode
	dw #$0201|!FS_COLOR_YELLOW, #$02B8|!FS_COLOR_YELLOW, #$02B7|!FS_COLOR_YELLOW, #$0212|!FS_COLOR_YELLOW
	.bow
	dw #$0201|!FS_COLOR_YELLOW, #$0202|!FS_COLOR_YELLOW, #$0211|!FS_COLOR_YELLOW, #$0212|!FS_COLOR_YELLOW
	.silver_bow
	dw #$0201|!FS_COLOR_YELLOW, #$0204|!FS_COLOR_YELLOW, #$0203|!FS_COLOR_RED, #$0212|!FS_COLOR_YELLOW
	.regular_arrow ;for an eventual update for retro mode
	dw #$0200|!FS_COLOR_YELLOW, #$02BA|!FS_COLOR_YELLOW, #$02B9|!FS_COLOR_RED, #$0200|!FS_COLOR_YELLOW
	.silver_arrow
	dw #$0200|!FS_COLOR_YELLOW, #$0214|!FS_COLOR_YELLOW, #$0213|!FS_COLOR_RED, #$0200|!FS_COLOR_YELLOW
	.blue_boomerang
	dw #$0205|!FS_COLOR_BLUE, #$0206|!FS_COLOR_BLUE, #$0200|!FS_COLOR_BW, #$0216|!FS_COLOR_BLUE
	.red_boomerang
	dw #$0205|!FS_COLOR_RED, #$0206|!FS_COLOR_RED, #$0200|!FS_COLOR_BW, #$0216|!FS_COLOR_RED
	.both_boomerang
	dw #$02B6|!FS_COLOR_BLUE, #$02B6|!FS_COLOR_RED, #$02B6|!FS_COLOR_BLUE|!FS_VFLIP, #$02B6|!FS_COLOR_RED|!FS_VFLIP
	.hookshot
	dw #$0200|!FS_COLOR_RED, #$0215|!FS_COLOR_RED, #$0230|!FS_COLOR_RED, #$0200|!FS_COLOR_BW
	.bombs
	dw #$020C|!FS_COLOR_BLUE, #$020D|!FS_COLOR_BLUE, #$021C|!FS_COLOR_BLUE, #$021C|!FS_COLOR_BLUE|!FS_HFLIP
	.fire_rod
	dw #$0220|!FS_COLOR_RED, #$0210|!FS_COLOR_RED, #$0230|!FS_COLOR_RED, #$0231|!FS_COLOR_RED
	.ice_rod
	dw #$0220|!FS_COLOR_BLUE, #$0221|!FS_COLOR_BLUE, #$0230|!FS_COLOR_BLUE, #$0231|!FS_COLOR_BLUE
	.bombos
	dw #$0207|!FS_COLOR_YELLOW, #$0217|!FS_COLOR_YELLOW|!FS_HFLIP|!FS_VFLIP, #$0217|!FS_COLOR_YELLOW, #$0207|!FS_COLOR_YELLOW|!FS_HFLIP|!FS_VFLIP
	.ether
	dw #$0208|!FS_COLOR_YELLOW, #$0218|!FS_COLOR_YELLOW|!FS_HFLIP|!FS_VFLIP, #$0218|!FS_COLOR_YELLOW, #$0208|!FS_COLOR_YELLOW|!FS_HFLIP|!FS_VFLIP
	.quake
	dw #$0209|!FS_COLOR_YELLOW, #$0219|!FS_COLOR_YELLOW|!FS_HFLIP|!FS_VFLIP, #$0219|!FS_COLOR_YELLOW, #$0209|!FS_COLOR_YELLOW|!FS_HFLIP|!FS_VFLIP
	.lamp
	dw #$022C|!FS_COLOR_RED, #$022C|!FS_COLOR_RED|!FS_HFLIP, #$023C|!FS_COLOR_RED, #$023D|!FS_COLOR_RED
	.hammer
	dw #$0222|!FS_COLOR_BROWN, #$0223|!FS_COLOR_BROWN, #$0232|!FS_COLOR_BROWN, #$0233|!FS_COLOR_BROWN
	.bugnet
	dw #$0228|!FS_COLOR_YELLOW, #$0229|!FS_COLOR_YELLOW, #$0238|!FS_COLOR_YELLOW, #$0239|!FS_COLOR_YELLOW
	.shovel
	dw #$0224|!FS_COLOR_BROWN, #$0225|!FS_COLOR_BROWN, #$0234|!FS_COLOR_BROWN, #$0235|!FS_COLOR_BROWN
	.flute
	dw #$0226|!FS_COLOR_BLUE, #$0227|!FS_COLOR_BLUE, #$0236|!FS_COLOR_BLUE, #$0237|!FS_COLOR_BLUE
	.book
	dw #$022A|!FS_COLOR_GREEN, #$022B|!FS_COLOR_GREEN, #$023A|!FS_COLOR_GREEN, #$023B|!FS_COLOR_GREEN
	.redcane
	dw #$021D|!FS_COLOR_RED, #$021E|!FS_COLOR_RED, #$022D|!FS_COLOR_RED, #$022E|!FS_COLOR_RED
	.bluecane
	dw #$021D|!FS_COLOR_BLUE, #$021E|!FS_COLOR_BLUE, #$022D|!FS_COLOR_BLUE, #$022E|!FS_COLOR_BLUE
	.cape
	dw #$0248|!FS_COLOR_RED, #$0249|!FS_COLOR_RED, #$0258|!FS_COLOR_RED, #$0259|!FS_COLOR_RED
	.mirror
	dw #$024A|!FS_COLOR_BLUE, #$024B|!FS_COLOR_BLUE, #$025A|!FS_COLOR_BLUE, #$025B|!FS_COLOR_BLUE

	.flippers
	dw #$020E|!FS_COLOR_BLUE, #$020F|!FS_COLOR_BLUE, #$021F|!FS_COLOR_BLUE|!FS_HFLIP, #$021F|!FS_COLOR_BLUE

	.boots
	dw #$024C|!FS_COLOR_BOOTS, #$024D|!FS_COLOR_BOOTS, #$025C|!FS_COLOR_BOOTS, #$025D|!FS_COLOR_BOOTS

	.pearl
	dw #$0264|!FS_COLOR_RED, #$0265|!FS_COLOR_RED, #$0274|!FS_COLOR_RED, #$0275|!FS_COLOR_RED

	.no_pendant
	dw #$0285|!FS_COLOR_GRAY, #$0286|!FS_COLOR_GRAY, #$02B2|!FS_COLOR_GRAY, #$0296|!FS_COLOR_GRAY
	.green_pendant
	dw #$0285|!FS_COLOR_GREEN, #$0286|!FS_COLOR_GREEN, #$0295|!FS_COLOR_GREEN, #$0296|!FS_COLOR_GREEN
	.blue_pendant
	dw #$0285|!FS_COLOR_BLUE, #$0286|!FS_COLOR_BLUE, #$0295|!FS_COLOR_BLUE, #$0296|!FS_COLOR_BLUE
	.red_pendant
	dw #$0285|!FS_COLOR_RED, #$0286|!FS_COLOR_RED, #$0295|!FS_COLOR_RED, #$0296|!FS_COLOR_RED

	.gloves
	dw #$024E|!FS_COLOR_BROWN, #$024F|!FS_COLOR_BROWN, #$025E|!FS_COLOR_BROWN, #$025F|!FS_COLOR_BROWN
	.mitts
	dw #$0260|!FS_COLOR_YELLOW, #$0261|!FS_COLOR_YELLOW, #$0270|!FS_COLOR_YELLOW, #$0271|!FS_COLOR_YELLOW

	.mushroom
	dw #$0262|!FS_COLOR_RED, #$0263|!FS_COLOR_RED, #$0272|!FS_COLOR_RED, #$0273|!FS_COLOR_RED
	.powder
	dw #$020A|!FS_COLOR_BROWN, #$020B|!FS_COLOR_BROWN, #$021A|!FS_COLOR_BROWN, #$021B|!FS_COLOR_BROWN

	.fighters_sword
	dw #$0266|!FS_COLOR_BLUE, #$0267|!FS_COLOR_BLUE, #$0276|!FS_COLOR_BLUE, #$0277|!FS_COLOR_BLUE
	.master_sword
	dw #$0268|!FS_COLOR_BLUE, #$0269|!FS_COLOR_BLUE, #$0278|!FS_COLOR_RED, #$0279|!FS_COLOR_BLUE
	.tempered_sword
	dw #$0268|!FS_COLOR_RED, #$0269|!FS_COLOR_RED, #$0278|!FS_COLOR_GREEN, #$026A|!FS_COLOR_RED
	.gold_sword
	dw #$0268|!FS_COLOR_YELLOW, #$0269|!FS_COLOR_YELLOW, #$0278|!FS_COLOR_BLUE, #$027A|!FS_COLOR_YELLOW

	.fighters_shield
	dw #$026B|!FS_COLOR_BLUE, #$026B|!FS_COLOR_BLUE|!FS_HFLIP, #$027B|!FS_COLOR_BLUE, #$027B|!FS_COLOR_BLUE|!FS_HFLIP
	.fire_shield
	dw #$026C|!FS_COLOR_BOOTS, #$026C|!FS_COLOR_BOOTS|!FS_HFLIP, #$027C|!FS_COLOR_BOOTS, #$027C|!FS_COLOR_BOOTS|!FS_HFLIP
	.mirror_shield
	dw #$026D|!FS_COLOR_YELLOW, #$026E|!FS_COLOR_YELLOW, #$027D|!FS_COLOR_YELLOW, #$027E|!FS_COLOR_YELLOW

	.green_mail
	dw #$026F|!FS_COLOR_GREEN, #$026F|!FS_COLOR_GREEN|!FS_HFLIP, #$027F|!FS_COLOR_GREEN, #$02B3|!FS_COLOR_GREEN
	.blue_mail
	dw #$026F|!FS_COLOR_BLUE, #$026F|!FS_COLOR_BLUE|!FS_HFLIP, #$027F|!FS_COLOR_BLUE, #$02B4|!FS_COLOR_BLUE
	.red_mail
	dw #$026F|!FS_COLOR_RED, #$026F|!FS_COLOR_RED|!FS_HFLIP, #$027F|!FS_COLOR_RED, #$02B5|!FS_COLOR_RED

	.heart_piece_0_of_4
	dw #$0280|!FS_COLOR_RED, #$0280|!FS_COLOR_RED|!FS_HFLIP, #$0290|!FS_COLOR_RED, #$0290|!FS_COLOR_RED|!FS_HFLIP
	.heart_piece_1_of_4
	dw #$0281|!FS_COLOR_RED, #$0280|!FS_COLOR_RED|!FS_HFLIP, #$0290|!FS_COLOR_RED, #$0290|!FS_COLOR_RED|!FS_HFLIP
	.heart_piece_2_of_4
	dw #$0281|!FS_COLOR_RED, #$0280|!FS_COLOR_RED|!FS_HFLIP, #$0291|!FS_COLOR_RED, #$0290|!FS_COLOR_RED|!FS_HFLIP
	.heart_piece_3_of_4
	dw #$0281|!FS_COLOR_RED, #$0281|!FS_COLOR_RED|!FS_HFLIP, #$0291|!FS_COLOR_RED, #$0290|!FS_COLOR_RED|!FS_HFLIP

	.empty_bottle
	dw #$0240|!FS_COLOR_BW, #$0241|!FS_COLOR_BW, #$0250|!FS_COLOR_BW, #$0251|!FS_COLOR_BW
	.red_potion
	dw #$0242|!FS_COLOR_RED, #$0242|!FS_COLOR_RED|!FS_HFLIP, #$0252|!FS_COLOR_RED, #$0243|!FS_COLOR_RED
	.green_potion
	dw #$0242|!FS_COLOR_GREEN, #$0242|!FS_COLOR_GREEN|!FS_HFLIP, #$0252|!FS_COLOR_GREEN, #$0244|!FS_COLOR_GREEN
	.blue_potion
	dw #$0242|!FS_COLOR_BLUE, #$0242|!FS_COLOR_BLUE|!FS_HFLIP, #$0252|!FS_COLOR_BLUE, #$0245|!FS_COLOR_BLUE
	.fairy_bottle
	dw #$0247|!FS_COLOR_YELLOW|!FS_HFLIP, #$0247|!FS_COLOR_YELLOW, #$0256|!FS_COLOR_BLUE, #$0257|!FS_COLOR_BLUE
	.bee_bottle
	dw #$0240|!FS_COLOR_BW, #$0241|!FS_COLOR_BW, #$0254|!FS_COLOR_YELLOW, #$0255|!FS_COLOR_YELLOW
	.good_bee_bottle
	dw #$0240|!FS_COLOR_BW, #$0241|!FS_COLOR_BW, #$0254|!FS_COLOR_YELLOW, #$0246|!FS_COLOR_YELLOW

;--------------------------------------------------------------------------------
FileSelectDrawHudBar:
        LDA.w #$029B|!FS_COLOR_GREEN : %fs_draw16x8(0,10)
        LDA.l DisplayRupeesSRAM
        JSL.l HUDHex4Digit_Long
        LDA.b Scrap04 : AND.w #$00FF : !ADD.w #$210+!FS_COLOR_BW : %fs_draw8x8(1,9)
        LDA.b Scrap05 : AND.w #$00FF : !ADD.w #$210+!FS_COLOR_BW : %fs_draw8x8(1,10)
        LDA.b Scrap06 : AND.w #$00FF : !ADD.w #$210+!FS_COLOR_BW : %fs_draw8x8(1,11)
        LDA.b Scrap07 : AND.w #$00FF : !ADD.w #$210+!FS_COLOR_BW : %fs_draw8x8(1,12)

        LDA.w #$028B|!FS_COLOR_BLUE : %fs_draw16x8(0,14)
        LDA.l BombsEquipmentSRAM : AND.w #$00FF
        JSL.l HUDHex2Digit_Long
        TYA : AND.w #$00FF : !ADD.w #$210+!FS_COLOR_BW : %fs_draw8x8(1,14)
        TXA : AND.w #$00FF : !ADD.w #$210+!FS_COLOR_BW : %fs_draw8x8(1,15)

        LDA.l BowTrackingSRAM : AND.w #$0040 : BEQ +
                LDA.w #$0299|!FS_COLOR_RED : %fs_draw16x8(0,17)
                BRA ++
        +
        LDA.w #$0289|!FS_COLOR_BROWN : %fs_draw16x8(0,17)
        ++
        LDA.l CurrentArrowsSRAM : AND.w #$00FF
        JSL.l HUDHex2Digit_Long
        TYA : AND.w #$00FF : !ADD.w #$210+!FS_COLOR_BW : %fs_draw8x8(1,17)
        TXA : AND.w #$00FF : !ADD.w #$210+!FS_COLOR_BW : %fs_draw8x8(1,18)
RTS
;--------------------------------------------------------------------------------
AltBufferTable:
    LDA.b #$02 : STA.w BG34NBA ; Have Screen 3 use same tile area as screens 1
.noScreen3Change
    REP #$20
    LDX.w #$0400 ; 14 rows with 64 bytes (30 tiles * 2 + 4 byte header)
    ;fill with the blank character
    LDA.w #$0188
    -
        STA.w GFXStripes, X
        DEX : DEX : BNE -

    ; set vram offsets
    LDA.w #$0161 : STA.w GFXStripes+$02 ;file 1 top row
    LDA.w #$2161 : STA.w GFXStripes+$42 ;file 1 bottom row

    LDA.w #$4161 : STA.w GFXStripes+$82 ;gap row top
    LDA.w #$6161 : STA.w GFXStripes+$C2 ;gap row bottom

    LDA.w #$8161 : STA.w GFXStripes+$0102 ;file 2 top row
    LDA.w #$A161 : STA.w GFXStripes+$0142 ;file 2 bottom row

    LDA.w #$C161 : STA.w GFXStripes+$0182 ;gap row top
    LDA.w #$E161 : STA.w GFXStripes+$01C2 ;gap row bottom

    LDA.w #$0162 : STA.w GFXStripes+$0202 ;file 3 top row
    LDA.w #$2162 : STA.w GFXStripes+$0242 ;file 3 bottom row

    LDA.w #$4162 : STA.w GFXStripes+$0282 ;extra gap row top
    LDA.w #$6162 : STA.w GFXStripes+$02C2 ;extra gap row bottom

    LDA.w #$8162 : STA.w GFXStripes+$0302 ;extra gap row top
    LDA.w #$A162 : STA.w GFXStripes+$0342 ;extra gap row bottom

    LDA.w #$C162 : STA.w GFXStripes+$0382 ;extra gap row top
    LDA.w #$E162 : STA.w GFXStripes+$03C2 ;extra gap row bottom

    ; set lengths
    LDA.w #$3B00
    STA.w GFXStripes+$04 ;file 1 top row
    STA.w GFXStripes+$44 ;file 1 bottom row
    STA.w GFXStripes+$84 ;gap row top
    STA.w GFXStripes+$C4 ;gap row bottom
    STA.w GFXStripes+$0104 ;file 2 top row
    STA.w GFXStripes+$0144 ;file 2 bottom row
    STA.w GFXStripes+$0184 ;gap row top
    STA.w GFXStripes+$01C4 ;gap row bottom
    STA.w GFXStripes+$0204 ;file 3 top row
    STA.w GFXStripes+$0244 ;file 3 bottom row
    STA.w GFXStripes+$0284 ;extra gap row top
    STA.w GFXStripes+$02C4 ;extra gap row bottom
    STA.w GFXStripes+$0304 ;extra gap row top
    STA.w GFXStripes+$0344 ;extra gap row bottom
    STA.w GFXStripes+$0384 ;extra gap row top
    STA.w GFXStripes+$03C4 ;extra gap row bottom

    ; Set last packet marker
    LDA.w #$00FF : STA.w GFXStripes+$0402

    ; Draw Unlock option if applicable
    LDA.b GameMode : AND.w #$00FF : CMP.w #$0001 : BNE +
    LDA.l IsEncrypted : AND.w #$00FF : CMP.w #$0002 : BNE +
    PHP : SEP #$30 : PHX : PHY : JSL ValidatePassword : PLY : PLX : PLP
    AND.w #$00FF : BNE +
	    LDA.w #!FSTILE_U_TOP : %fs_draw8x16(14,5)
	    LDA.w #!FSTILE_N_TOP : %fs_draw8x16(14,6)
	    LDA.w #!FSTILE_L_TOP : %fs_draw8x16(14,7)
	    LDA.w #!FSTILE_O_TOP : %fs_draw8x16(14,8)
	    LDA.w #!FSTILE_C_TOP : %fs_draw8x16(14,9)
	    LDA.w #!FSTILE_K_TOP : %fs_draw8x16(14,10)
    +
    SEP #$20

RTL
;--------------------------------------------------------------------------------
AltBufferTable_credits:
	JSL AltBufferTable_noScreen3Change

	REP #$20
    LDA.w #$6168 : STA.w GFXStripes+$02 ;file 1 top row
    LDA.w #$8168 : STA.w GFXStripes+$42 ;file 1 bottom row

    LDA.w #$A168 : STA.w GFXStripes+$82 ;gap row top
    LDA.w #$C168 : STA.w GFXStripes+$C2 ;gap row bottom

    LDA.w #$E168 : STA.w GFXStripes+$0102 ;file 2 top row
    LDA.w #$0169 : STA.w GFXStripes+$0142 ;file 2 bottom row

    LDA.w #$2169 : STA.w GFXStripes+$0182 ;gap row top
    LDA.w #$4169 : STA.w GFXStripes+$01c2 ;gap row bottom

    LDA.w #$6169 : STA.w GFXStripes+$0202 ;file 3 top row
    LDA.w #$8169 : STA.w GFXStripes+$0242 ;file 3 bottom row

    LDA.w #$A169 : STA.w GFXStripes+$0282 ;extra gap row top
    LDA.w #$C169 : STA.w GFXStripes+$02C2 ;extra gap row bottom

    LDA.w #$E169 : STA.w GFXStripes+$0302 ;extra gap row top
    LDA.w #$016A : STA.w GFXStripes+$0342 ;extra gap row bottom

    LDA.w #$216A : STA.w GFXStripes+$0382 ;extra gap row top
    LDA.w #$416A : STA.w GFXStripes+$03C2 ;extra gap row bottom

    SEP #$20
RTL
;--------------------------------------------------------------------------------
macro LayoutPriority(address)
LDX.w #$003C
- : LDA.w <address>, X : ORA.w #$2000 : STA.w <address>, X
DEX : DEX : BNE -
endmacro

SetItemLayoutPriority:
  REP #$30
  %LayoutPriority($1004)
  %LayoutPriority($1044)
  %LayoutPriority($1084)
  %LayoutPriority($10C4)
  %LayoutPriority($1104)
  %LayoutPriority($1144)
  %LayoutPriority($1184)
  %LayoutPriority($11c4)
  %LayoutPriority($1204)
  %LayoutPriority($1244)
  %LayoutPriority($1284)
  %LayoutPriority($12c4)
  %LayoutPriority($1304)
  %LayoutPriority($1344)

RTL

;--------------------------------------------------------------------------------
LoadFullItemTiles:
	PHA : PHX
		LDA.w DMAP0 : PHA ; preserve DMA parameters
		LDA.w BBAD0 : PHA ; preserve DMA parameters
		LDA.w A1T0L : PHA ; preserve DMA parameters
		LDA.w A1T0H : PHA ; preserve DMA parameters
		LDA.w A1B0 : PHA ; preserve DMA parameters
		LDA.w DAS0L : PHA ; preserve DMA parameters
		LDA.w DAS0H : PHA ; preserve DMA parameters
		;--------------------------------------------------------------------------------
		LDA.b #$80 : STA.w VMAIN ; write read increment on $2119
		LDA.b #$01 : STA.w DMAP0 ; set DMA transfer direction A -> B, bus A auto increment, double-byte mode
		LDA.b #$18 : STA.w BBAD0 ; set bus B destination to VRAM register

		LDA.b #$00 : STA.w VMADDL ; write VRAM destination address
		LDA.b #$30 : STA.w VMADDH ; write VRAM destination address

		LDA.b #$31 : STA.w A1B0 ; set bus A source bank
		LDA.b #FileSelectNewGraphics : STA.w A1T0L ; set bus A source address to ROM
		LDA.b #FileSelectNewGraphics>>8 : STA.w A1T0H ; set bus A source address to ROM

		LDA.w INIDISP : PHA : LDA.b #$80 : STA.w INIDISP ; save screen state & turn screen off

		STZ.w DAS0L : LDA.b #$10 : STA.w DAS0H ; set transfer size to 0x1000
		LDA.b #$01 : STA.w MDMAEN ; begin DMA transfer

		PLA : STA.w INIDISP ; put screen back however it was before
		;--------------------------------------------------------------------------------
		PLA : STA.w DAS0H ; restore DMA parameters
		PLA : STA.w DAS0L ; restore DMA parameters
		PLA : STA.w A1B0 ; restore DMA parameters
		PLA : STA.w A1T0H ; restore DMA parameters
		PLA : STA.w A1T0L ; restore DMA parameters
		PLA : STA.w BBAD0 ; restore DMA parameters
		PLA : STA.w DMAP0 ; restore DMA parameters
	PLX : PLA
RTL
;--------------------------------------------------------------------------------

SetFileSelectPalette:
	LDA.b GameMode : CMP.b #$04 : BNE +
		; load the vanilla file select screen BG3 palette for naming screen
		LDA.b #$01 : STA.w $0AB2
		JSL.l Palette_Hud
		BRA .done
	+
	JSL.l LoadCustomHudPalette
	.done
JML Palette_SelectScreen ; Jump to the subroutine whose call we wrote over

;--------------------------------------------------------------------------------

LoadCustomHudPalette:
	PHA : PHX
		REP #$20
		LDX.b #$40
		-
		LDA.l GFX_HUD_Palette, X
			STA.l PaletteBuffer, X
			DEX : DEX
		BPL -
		SEP #$20

		INC.b NMICGRAM ; ensure CGRAM gets updated
	PLX : PLA
RTL
;--------------------------------------------------------------------------------
DrawPlayerFile_credits:
	; see $6563C for drawing first file name and hearts
	REP #$20 ; set 16 bit accumulator

	LDA.l EquipmentSRAM+$99 : ORA.w #!FS_COLOR_BW
	%fs_draw8x16(3,5)
	LDA.l EquipmentSRAM+$9B : ORA.w #!FS_COLOR_BW
	%fs_draw8x16(3,6)
	LDA.l EquipmentSRAM+$9D : ORA.w #!FS_COLOR_BW
	%fs_draw8x16(3,7)
	LDA.l EquipmentSRAM+$9F : ORA.w #!FS_COLOR_BW
	%fs_draw8x16(3,8)
 
	LDA.l EquipmentSRAM+$2C : AND.w #$00FF : LSR #3 : STA.b Scrap02
	%fs_LDY_screenpos(0,20)
	LDA.w #$028F|!FS_COLOR_RED
	LDX.w #$000A

	.nextHeart

	STA.w $0000, Y

	INY #2 : DEX : BNE +
		PHA
		TYA : !ADD.w #$40-$14 : TAY
		PLA
	+
	DEC.b Scrap02 : BNE .nextHeart

	JSR DrawPlayerFileShared
RTL
;--------------------------------------------------------------------------------
FSCursorUp:
	LDA.b FileSelectPosition : BNE +
		LDA.b #$04 ; up from file becomes delete
		BRA .done
	+ : CMP.b #$03 : BNE +
		LDA.b #$00 ; up from unlock is the file
		BRA .done
	+
	LDA.l IsEncrypted : CMP.b #$02 : BNE +
	LDA.l ValidKeyLoaded : BNE +
		LDA.b #$03 ; up from delete is unlock for password protected seeds
		BRA .done
	+
	LDA.b #$00 ;otherwise up from delete is file
	.done
	STA.b FileSelectPosition
RTL

FSCursorDown:
	LDA.b FileSelectPosition : BNE +
		LDA.l IsEncrypted : CMP.b #$02 : BNE ++
		LDA.l ValidKeyLoaded : BNE ++
			LDA.b #$03 ; down from file is unlock for password protected seeds
			BRA .done
		++
		LDA.b #$04  ;otherwise down from file is delete
		BRA .done
	+ : CMP.b #$03 : BNE +
		LDA.b #$04 ; down from unlock is delete
		BRA .done
	+
	LDA.b #$00 ; down from delete is file
	.done
	STA.b FileSelectPosition
RTL
;--------------------------------------------------------------------------------
FSSelectFile:
	LDA.l IsEncrypted : CMP.b #$02 : BNE .normal
		STZ.w SFX2 ; temporarily cancel file screen selection sound
		PHX : PHY
			JSL ValidatePassword : BEQ .must_unlock
		PLY : PLX
		LDA.b #$2C : STA.w SFX2 ;file screen selection sound
	.normal
	LDA.b #$F1 : STA.w MusicControlRequest
JML FSSelectFile_continue
	.must_unlock
	PLY : PLX
	LDA.b #$03 : STA.b FileSelectPosition ;set cursor to unlock
	LDA.b #$3C : STA.w SFX2 ; play error sound
JML FSSelectFile_return
;--------------------------------------------------------------------------------
MaybeForceFileName:
        LDA.l ForceFileName : BEQ +
                REP #$20
                LDX.b #$FE
                -
                INX : INX
                LDA.l StaticFileName, X : STA.l ExtendedFileNameSRAM, X
                CPX.b #$16 : BEQ .done
                CPX.b #$08 : BCS -
                STA.l FileNameVanillaSRAM, X
                BRA -
        .done
                SEP #$20
                JML.l InitializeSaveFile

        +
JML.l NameFile_MakeScreenVisible
;--------------------------------------------------------------------------------
