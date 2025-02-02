_DepositPKMN:
	ld hl, wOptions
	ld a, [hl]
	push af
	set 4, [hl]
	ld a, [wVramState]
	push af
	xor a
	ld [wVramState], a
	ldh a, [hInMenu]
	push af
	ld a, 1
	ldh [hInMenu], a
	xor a
	ldh [hMapAnims], a
	call BillsPC_InitRAM
	xor a
	ld [wBillsPC_LoadedBox], a
	jr .handleLoop
.loop
	jumptable .Jumptable
.handleLoop
	call DelayFrame
	call JoyTextDelay
	ld a, [wJumptableIndex]
	bit 7, a
	jr z, .loop
.done
	call ClearSprites
	pop af
	ldh [hInMenu], a
	pop af
	ld [wVramState], a
	pop af
	ld [wOptions], a
	ret

.Jumptable
	dw .Init
	dw .HandleJoypad
	dw .WhatsUp
	dw .Submenu
	dw BillsPC_EndJumptableLoop

.Init
	xor a
	ldh [hBGMapMode], a
	call ClearSprites
	call CopyBoxmonSpecies
	call BillsPC_BoxName
	ld de, PCString_ChooseaPKMN
	call BillsPC_PlaceText
	ld a, 5
	ld [wBillsPC_NumMonsOnScreen], a
	call BillsPC_RefreshTextboxes
	call PCMonInfo
	ld a, $ff
	ld [wCurPartySpecies], a
	ld a, SCGB_BILLS_PC
	call BillsPC_ApplyPalettes
	call ApplyTilemapInVBlank
	call BillsPC_UpdateSelectionCursor
	jp BillsPC_IncrementJumptableIndex

.HandleJoypad
	ld hl, hJoyPressed
	ld a, [hl]
	and B_BUTTON
	jr nz, .b_button
	ld a, [hl]
	and A_BUTTON
	jr nz, .a_button
	call Withdraw_UpDown
	and a
	ret z
	call BillsPC_UpdateSelectionCursor
	xor a
	ldh [hBGMapMode], a
	call BillsPC_RefreshTextboxes
	call PCMonInfo
	ld a, 1
	ldh [hBGMapMode], a
	call DelayFrame
	jp DelayFrame

.a_button
	call BillsPC_GetSelectedPokemonSpecies
	and a
	ret z
	inc a
	jr z, .b_button
	ld a, 2
	ld [wJumptableIndex], a
	ret

.go_back
	ld hl, wJumptableIndex
	dec [hl]
	ret

.b_button
	ld a, 4
	ld [wJumptableIndex], a
	ret

.WhatsUp
	xor a
	ldh [hBGMapMode], a
	call ClearSprites
	call BillsPC_GetSelectedPokemonSpecies
	ld [wCurPartySpecies], a
	ld a, SCGB_BILLS_PC
	call BillsPC_ApplyPalettes
	ld de, PCString_WhatsUp
	call BillsPC_PlaceText
	ld a, 1
	ld [wMenuCursorY], a
	jp BillsPC_IncrementJumptableIndex

.Submenu
	ld hl, BillsPCDepositMenuHeader
	call CopyMenuHeader
	ld a, [wMenuCursorY]
	ld [wMenuCursorBuffer], a
	call VerticalMenu
	jp c, BillsPCDepositFuncCancel
	ld a, [wMenuCursorY]
	dec a
	and 3
	jumptable

	dw BillsPCDepositFuncDeposit
	dw BillsPCDepositFuncStats
	dw BillsPCDepositFuncRelease
	dw BillsPCDepositFuncCancel

BillsPCDepositFuncDeposit:
	call BillsPC_BlackoutPrevention
	jp c, BillsPCDepositFuncCancel
	call DepositPokemon
	jr c, .box_full
	xor a
	ld [wJumptableIndex], a
	ld [wBillsPC_CursorPosition], a
	ld [wBillsPC_ScrollPosition], a
	ret

.box_full
	ld de, PCString_WhatsUp
	jp BillsPC_PlaceText

BillsPCDepositFuncStats:
	call LoadStandardMenuHeader
	call BillsPC_StatsScreen
	call ExitMenu
	call PCMonInfo
	call BillsPC_GetSelectedPokemonSpecies
	ld [wCurPartySpecies], a
	ld a, SCGB_BILLS_PC
	jp BillsPC_ApplyPalettes

BillsPCDepositFuncRelease:
	call BillsPC_BlackoutPrevention
	jr c, BillsPCDepositFuncCancel
	call BillsPC_IsMonAnEgg
	jr c, BillsPCDepositFuncCancel
	call BillsPC_GetScrollCursorPosition
	call CheckForSpecialGiftMon
	jr c, .specialGiftMon
	ld a, [wMenuCursorY]
	push af
	ld de, PCString_ReleasePKMN
	call BillsPC_PlaceText
	call LoadStandardMenuHeader
	lb bc, 14, 11
	call PlaceYesNoBox
	ld a, [wMenuCursorY]
	dec a
	call ExitMenu
	and a
	jr nz, .failed_release
	xor a
	ld [wPokemonWithdrawDepositParameter], a
	callba RemoveMonFromPartyOrBox
	call ReleasePKMN_ByePKMN
	xor a
	ld [wJumptableIndex], a
	ld [wBillsPC_CursorPosition], a
	ld [wBillsPC_ScrollPosition], a
	pop af
	ret

.specialGiftMon
	ld de, PCString_CantReleaseThis
	call BillsPC_PlaceText
	ld de, SFX_WRONG
	jp KillPlayWaitSFX

.failed_release
	ld de, PCString_WhatsUp
	call BillsPC_PlaceText
	pop af
	ld [wMenuCursorY], a
	ret

BillsPC_GetScrollCursorPosition:
	ld a, [wBillsPC_CursorPosition]
	ld hl, wBillsPC_ScrollPosition
	add [hl]
	ld [wCurPartyMon], a
	ret

BillsPCDepositFuncCancel:
	xor a
	ld [wJumptableIndex], a
	ret

BillsPCDepositMenuHeader:
	db $40 ; flags
	db 04, 09 ; start coords
	db 13, 19 ; end coords
	dw .MenuData2
	db 1 ; default option

.MenuData2
	db $80 ; flags
	db 4 ; items
	db "Déposer@"
	db "Données@"
	db "Libérer@"
	db "Retour@"

_WithdrawPKMN:
	ld hl, wOptions
	ld a, [hl]
	push af
	set 4, [hl]
	ld a, [wVramState]
	push af
	xor a
	ld [wVramState], a
	ldh a, [hInMenu]
	push af
	ld a, 1
	ldh [hInMenu], a
	xor a
	ldh [hMapAnims], a
	call BillsPC_InitRAM
	ld a, NUM_BOXES + 1
	ld [wBillsPC_LoadedBox], a
	jr .handleLoop
.loop
	jumptable .Jumptable
.handleLoop
	call DelayFrame
	call JoyTextDelay
	ld a, [wJumptableIndex]
	bit 7, a
	jr z, .loop
.done
	call ClearSprites
	pop af
	ldh [hInMenu], a
	pop af
	ld [wVramState], a
	pop af
	ld [wOptions], a
	ret

.Jumptable
	dw .Init
	dw .Joypad
	dw .PrepSubmenu
	dw BillsPC_Withdraw
	dw BillsPC_EndJumptableLoop

.Init
	ld a, NUM_BOXES + 1
	ld [wBillsPC_LoadedBox], a
	xor a
	ldh [hBGMapMode], a
	call ClearSprites
	call CopyBoxmonSpecies
	call BillsPC_BoxName
	ld de, PCString_ChooseaPKMN
	call BillsPC_PlaceText
	ld a, 5
	ld [wBillsPC_NumMonsOnScreen], a
	call BillsPC_RefreshTextboxes
	call PCMonInfo
	ld a, $ff
	ld [wCurPartySpecies], a
	ld a, SCGB_BILLS_PC
	call BillsPC_ApplyPalettes
	call ApplyTilemapInVBlank
	call BillsPC_UpdateSelectionCursor
	jp BillsPC_IncrementJumptableIndex

.Joypad
	ld hl, hJoyPressed
	bit B_BUTTON_F, [hl]
	jr nz, .b_button
	bit A_BUTTON_F, [hl]
	jr nz, .a_button
	call Withdraw_UpDown
	and a
	ret z
	call BillsPC_UpdateSelectionCursor
	xor a
	ldh [hBGMapMode], a
	call BillsPC_RefreshTextboxes
	call PCMonInfo
	ld a, 1
	ldh [hBGMapMode], a
	call DelayFrame
	jp DelayFrame
.a_button
	call BillsPC_GetSelectedPokemonSpecies
	and a
	ret z
	inc a
	jr z, .b_button
	ld a, 2
	ld [wJumptableIndex], a
	ret

.b_button
	ld a, 4
	ld [wJumptableIndex], a
	ret

.PrepSubmenu
	xor a
	ldh [hBGMapMode], a
	call ClearSprites
	call BillsPC_GetSelectedPokemonSpecies
	ld [wCurPartySpecies], a
	ld a, SCGB_BILLS_PC
	call BillsPC_ApplyPalettes
	ld de, PCString_WhatsUp
	call BillsPC_PlaceText
	ld a, 1
	ld [wMenuCursorY], a
	jp BillsPC_IncrementJumptableIndex

BillsPC_Withdraw:
	ld hl, .MenuHeader
	call CopyMenuHeader
	ld a, [wMenuCursorY]
	ld [wMenuCursorBuffer], a
	call VerticalMenu
	jp c, .cancel
	ld a, [wMenuCursorY]
	dec a
	and 3
	jumptable

	dw .withdraw
	dw .stats
	dw .release
	dw .cancel

.withdraw
	call BillsPC_BlackoutPrevention
	jp c, .cancel
	call TryWithdrawPokemon
	jr c, .FailedWithdraw
	xor a
	ld [wJumptableIndex], a
	ld [wBillsPC_CursorPosition], a
	ld [wBillsPC_ScrollPosition], a
	ret
.FailedWithdraw
	ld de, PCString_WhatsUp
	jp BillsPC_PlaceText

.stats
	call LoadStandardMenuHeader
	call BillsPC_StatsScreen
	call ExitMenu
	call PCMonInfo
	call BillsPC_GetSelectedPokemonSpecies
	ld [wCurPartySpecies], a
	ld a, SCGB_BILLS_PC
	jp BillsPC_ApplyPalettes

.release
	ld a, [wMenuCursorY]
	push af
	call BillsPC_IsMonAnEgg
	jr c, .FailedRelease
	ld de, PCString_ReleasePKMN
	call BillsPC_PlaceText
	call LoadStandardMenuHeader
	lb bc, 14, 11
	call PlaceYesNoBox
	ld a, [wMenuCursorY]
	dec a
	call ExitMenu
	and a
	jr nz, .FailedRelease
	call BillsPC_GetScrollCursorPosition
	ld a, PC_DEPOSIT
	ld [wPokemonWithdrawDepositParameter], a
	callba RemoveMonFromPartyOrBox
	call ReleasePKMN_ByePKMN
	xor a
	ld [wJumptableIndex], a
	ld [wBillsPC_CursorPosition], a
	ld [wBillsPC_ScrollPosition], a
	pop af
	ret
.FailedRelease
	ld de, PCString_WhatsUp
	call BillsPC_PlaceText
	pop af
	ld [wMenuCursorY], a
	ret

.cancel
	xor a
	ld [wJumptableIndex], a
	ret

.MenuHeader
	db $40 ; flags
	db 04, 09 ; start coords
	db 13, 19 ; end coords
	dw .MenuData
	db 1 ; default option

.MenuData
	db $80 ; flags
	db 4 ; items
	db "Retirer@"
	db "Données@"
	db "Libérer@"
	db "Retour@"

_MovePKMNWithoutMail:
	ld hl, wOptions
	ld a, [hl]
	push af
	set 4, [hl]
	ld a, [wVramState]
	push af
	xor a
	ld [wVramState], a
	ldh a, [hInMenu]
	push af
	ld a, 1
	ldh [hInMenu], a
	xor a
	ldh [hMapAnims], a
	call BillsPC_InitRAM
	ld a, [wCurBox]
	and $f
	inc a
	ld [wBillsPC_LoadedBox], a
	jr .handleLoop
.loop
	jumptable .Jumptable
.handleLoop
	call DelayFrame
	call JoyTextDelay
	ld a, [wJumptableIndex]
	bit 7, a
	jr z, .loop
	call ClearSprites
	pop af
	ldh [hInMenu], a
	pop af
	ld [wVramState], a
	pop af
	ld [wOptions], a
	ret

.Jumptable
	dw .Init
	dw .Joypad
	dw .PrepSubmenu
	dw .MoveMonWOMailSubmenu
	dw .PrepInsertCursor
	dw .JoypadInsertCursor
	dw BillsPC_EndJumptableLoop

.Init
	xor a
	ldh [hBGMapMode], a
	call ClearSprites
	call CopyBoxmonSpecies
	ld de, PCString_ChooseaPKMN
	call BillsPC_PlaceText
	ld a, 5
	ld [wBillsPC_NumMonsOnScreen], a
	call BillsPC_RefreshTextboxes
	call BillsPC_MoveMonWOMail_BoxNameAndArrows
	call PCMonInfo
	ld a, $ff
	ld [wCurPartySpecies], a
	ld a, SCGB_BILLS_PC
	call BillsPC_ApplyPalettes
	call ApplyTilemapInVBlank
	call BillsPC_UpdateSelectionCursor
	jp BillsPC_IncrementJumptableIndex

.Joypad
	ld hl, hJoyPressed
	bit B_BUTTON_F, [hl]
	jr nz, .b_button
	bit A_BUTTON_F, [hl]
	jr nz, .a_button
	call MovePkmnWithoutMail_DPad
	jr c, .d_pad
	and a
	ret z
	call BillsPC_UpdateSelectionCursor
	xor a
	ldh [hBGMapMode], a
	call BillsPC_RefreshTextboxes
	call PCMonInfo
	ld a, 1
	ldh [hBGMapMode], a
	jp Delay2

.d_pad
	xor a
	ld [wBillsPC_CursorPosition], a
	ld [wBillsPC_ScrollPosition], a
	ld [wJumptableIndex], a
	ret

.a_button
	call BillsPC_GetSelectedPokemonSpecies
	and a
	ret z
	inc a
	jr z, .b_button
	ld a, 2
	ld [wJumptableIndex], a
	ret

.b_button
	ld a, 6
	ld [wJumptableIndex], a
	ret

.PrepSubmenu
	xor a
	ldh [hBGMapMode], a
	call ClearSprites
	call BillsPC_GetSelectedPokemonSpecies
	ld [wCurPartySpecies], a
	ld a, SCGB_BILLS_PC
	call BillsPC_ApplyPalettes
	ld de, PCString_WhatsUp
	call BillsPC_PlaceText
	ld a, 1
	ld [wMenuCursorY], a
	jp BillsPC_IncrementJumptableIndex

.MoveMonWOMailSubmenu
	ld hl, .MenuHeader
	call CopyMenuHeader
	ld a, [wMenuCursorY]
	ld [wMenuCursorBuffer], a
	call VerticalMenu
	jp c, .Cancel
	ld a, [wMenuCursorY]
	dec a
	and 3
	jumptable

	dw .Move
	dw .Stats
	dw .Cancel

.Move
	call BillsPC_BlackoutPrevention
	jp c, .Cancel
	ld a, [wBillsPC_LoadedBox]
	and a
	jr nz, .notParty
	call BillsPC_GetScrollCursorPosition
	call CheckForSpecialGiftMon
	jr c, .specialGiftMon
.notParty
	ld a, [wBillsPC_ScrollPosition]
	ld [wBillsPC_BackupScrollPosition], a
	ld a, [wBillsPC_CursorPosition]
	ld [wBillsPC_BackupCursorPosition], a
	ld a, [wBillsPC_LoadedBox]
	ld [wBillsPC_BackupLoadedBox], a
	ld a, 4
	ld [wJumptableIndex], a
	ret

.Stats
	call LoadStandardMenuHeader
	call BillsPC_StatsScreen
	call ExitMenu
	call PCMonInfo
	call BillsPC_GetSelectedPokemonSpecies
	ld [wCurPartySpecies], a
	ld a, SCGB_BILLS_PC
	jp BillsPC_ApplyPalettes

.specialGiftMon
	ld de, PCString_CantMoveThisPKMN
	call BillsPC_PlaceText
	ld de, SFX_WRONG
	call KillPlayWaitSFX
.Cancel
	xor a
	ld [wJumptableIndex], a
	ret

.MenuHeader
	db $40 ; flags
	db 04, 09 ; start coords
	db 13, 19 ; end coords
	dw .MenuData2
	db 1 ; default option

.MenuData2
	db $80 ; flags
	db 3 ; items
	db "Déplacer@"
	db "Données@"
	db "Retour@"

.PrepInsertCursor
	xor a
	ldh [hBGMapMode], a
	call CopyBoxmonSpecies
	ld de, PCString_MoveToWhere
	call BillsPC_PlaceText
	ld a, 5
	ld [wBillsPC_NumMonsOnScreen], a
	call BillsPC_RefreshTextboxes
	call BillsPC_MoveMonWOMail_BoxNameAndArrows
	call ClearSprites
	call BillsPC_UpdateInsertCursor
	call ApplyTilemapInVBlank
	jp BillsPC_IncrementJumptableIndex

.JoypadInsertCursor
	ld hl, hJoyPressed
	bit B_BUTTON_F, [hl]
	jr nz, .b_button_insert_cursor
	bit A_BUTTON_F, [hl]
	jr nz, .a_button_insert_cursor
	call MovePkmnWithoutMail_DPad
	jr c, .dpad_insert_cursor
	and a
	ret z
	call BillsPC_UpdateInsertCursor
	xor a
	ldh [hBGMapMode], a
	call BillsPC_RefreshTextboxes
	ld a, 1
	ldh [hBGMapMode], a
	call DelayFrame
	jp DelayFrame

.dpad_insert_cursor
	xor a
	ld [wBillsPC_CursorPosition], a
	ld [wBillsPC_ScrollPosition], a
	ld a, 4
	ld [wJumptableIndex], a
	ret

.a_button_insert_cursor
	call BillsPC_CheckSpaceInDestination
	jr c, .no_space
	call MovePKMNWitoutMail_InsertMon
	xor a
	ld [wJumptableIndex], a
	ret

.no_space
	ld hl, wJumptableIndex
	dec [hl]
	ret

.b_button_insert_cursor
	ld a, [wBillsPC_BackupScrollPosition]
	ld [wBillsPC_ScrollPosition], a
	ld a, [wBillsPC_BackupCursorPosition]
	ld [wBillsPC_CursorPosition], a
	ld a, [wBillsPC_BackupLoadedBox]
	ld [wBillsPC_LoadedBox], a
	xor a
	ld [wJumptableIndex], a
	ret

BillsPC_InitRAM:
	call ClearBGPalettes
	call ClearSprites
	call ClearTileMap
	call BillsPC_InitGFX
	ld hl, wBillsPCPokemonList
	ld bc, $338 ;TODO: replace this magic number
	xor a
	call ByteFill
	xor a
	ld [wJumptableIndex], a
	ld [wcf64], a
	ld [wcf65], a
	ld [wcf66], a
	ld [wBillsPC_CursorPosition], a
	ld [wBillsPC_ScrollPosition], a
	ret

BillsPC_IncrementJumptableIndex:
	ld hl, wJumptableIndex
	inc [hl]
	ret

BillsPC_EndJumptableLoop:
	ld hl, wJumptableIndex
	set 7, [hl]
	ret

_StatsScreenDPad:
	ld a, [wBillsPC_NumMonsOnScreen]
	ld d, a
	ld a, [wBillsPC_NumMonsInBox]
	and a
	ret z
	sub 2
	ret z
	inc a
	ld e, a
	jr BillsPC_PressUpDownCheck

Withdraw_UpDown:
	ld hl, hJoyLast
	ld a, [wBillsPC_NumMonsOnScreen]
	ld d, a
	ld a, [wBillsPC_NumMonsInBox]
	ld e, a
	and a
	ret z
BillsPC_PressUpDownCheck:
	bit D_UP_F, [hl]
	jr nz, BillsPC_PressUp
	bit D_DOWN_F, [hl]
	jr nz, BillsPC_PressDown
	xor a
	ret

MovePkmnWithoutMail_DPad:
	ld hl, hJoyLast
	ld a, [wBillsPC_NumMonsOnScreen]
	ld d, a
	ld a, [wBillsPC_NumMonsInBox]
	ld e, a
	and a
	jr z, .check_left_right
	bit D_UP_F, [hl]
	jr nz, BillsPC_PressUp
	bit D_DOWN_F, [hl]
	jr nz, BillsPC_PressDown

.check_left_right
	bit D_LEFT_F, [hl]
	jr nz, BillsPC_PressLeft
	bit D_RIGHT_F, [hl]
	jr nz, BillsPC_PressRight
	xor a
	ret

BillsPC_PressUp:
	ld hl, wBillsPC_CursorPosition
	ld a, [hl]
	and a
	jr nz, .not_top
	ld hl, wBillsPC_ScrollPosition
	ld a, [hl]
	and a
	ret z
.not_top
	dec [hl]
	jr BillsPC_UpDownDidSomething

BillsPC_PressDown:
	ld a, [wBillsPC_CursorPosition]
	ld hl, wBillsPC_ScrollPosition
	add [hl]
	inc a
	cp e
	jr c, .ok
	xor a
	ret

.ok
	ld hl, wBillsPC_CursorPosition
	ld a, [hl]
	inc a
	cp d
	jr c, .bottom
	ld hl, wBillsPC_ScrollPosition
.bottom
	inc [hl]
BillsPC_UpDownDidSomething:
	ld a, TRUE
	and a
	ret

BillsPC_PressLeft:
	ld hl, wBillsPC_LoadedBox
	ld a, [hl]
	dec [hl]
	and a
	scf
	ret nz
	ld [hl], NUM_BOXES
	ret

BillsPC_PressRight:
	ld hl, wBillsPC_LoadedBox
	ld a, [hl]
	inc [hl]
	cp NUM_BOXES
	scf
	ret nz
	ld [hl], 0
	ret

BillsPC_PlaceText:
	push de
	hlcoord 0, 15
	lb bc, 1, 18
	call TextBox
	pop de
	hlcoord 1, 16
	jp PlaceText

BillsPC_MoveMonWOMail_BoxNameAndArrows:
	call BillsPC_BoxName
	hlcoord 8, 1
	ld [hl], $5f
	hlcoord 19, 1
	ld [hl], $5e
	ret

BillsPC_BoxName:
	hlcoord 8, 0
	lb bc, 1, 10
	call TextBox

	ld a, [wBillsPC_LoadedBox]
	and a
	jr z, .party

	cp NUM_BOXES + 1
	jr nz, .gotbox

	ld a, [wCurBox]
	inc a
.gotbox
	dec a
	ld hl, wBoxNames
	ld bc, BOX_NAME_LENGTH
	rst AddNTimes
	ld e, l
	ld d, h
	jr .print

.party
	ld de, .PartyPKMN
.print
	hlcoord 10, 1
	jp PlaceString

.PartyPKMN:
	db "Party <PK><MN>@"

PCMonInfo:
; Display a monster's pic and
; attributes when highlighting
; it in a PC menu.

; Includes the neat cascading
; effect when showing the pic.

; Example: Species, level, gender,
; whether it's holding an item.

	hlcoord 0, 0
	lb bc, 15, 8
	call ClearBox

	hlcoord 8, 14
	lb bc, 1, 3
	call ClearBox

	call BillsPC_GetSelectedPokemonSpecies
	and a
	ret z
	cp -1
	ret z

	ld [wd265], a
	hlcoord 1, 4
	xor a
	ld b, 7
.row
	ld c, 7
	push af
	push hl
.col
	ld [hli], a
	add 7
	dec c
	jr nz, .col
	pop hl
	ld de, SCREEN_WIDTH
	add hl, de
	pop af
	inc a
	dec b
	jr nz, .row

	call BillsPC_LoadMonStats
	ld a, [wd265]
	ld [wCurPartySpecies], a
	ld [wCurSpecies], a
	call GetBaseData
	ld de, vBGTiles tile $00
	predef GetFrontpic
	ld a, [wCurPartySpecies]
	ld [wd265], a
	cp EGG
	ret z

	call GetBasePokemonName
	hlcoord 1, 14
	call PlaceString

	hlcoord 1, 12
	call PrintLevel

	ld a, 3
	ld [wMonType], a
	callba GetGender
	jr c, .skip_gender
	ld a, "♂"
	jr nz, .printgender
	ld a, "♀"
.printgender
	hlcoord 5, 12
	ld [hl], a
.skip_gender

	ld a, [wTempMonItem]
	and a
	ret z

	ld d, a
	ld a, $5d ; item icon
	hlcoord 7, 12
	ld [hl], a
	ret

BillsPC_LoadMonStats:
	ld a, [wBillsPC_CursorPosition]
	ld hl, wBillsPC_ScrollPosition
	add [hl]
	ld e, a
	ld d, 0
	ld hl, wBillsPCPokemonList + 1
	add hl, de
	add hl, de
	add hl, de
	ld a, [hl]
	and a
	jr z, .party
	cp NUM_BOXES + 1
	jr z, .sBox
	ld b, a
	call GetBoxPointer
	sbk b
	push hl
	ld bc, sBoxMon1Level - sBox
	add hl, bc
	ld bc, BOXMON_STRUCT_LENGTH
	ld a, e
	rst AddNTimes
	ld a, [hl]
	ld [wTempMonLevel], a
	pop hl
	push hl
	ld bc, sBoxMon1Item - sBox
	add hl, bc
	ld bc, BOXMON_STRUCT_LENGTH
	ld a, e
	rst AddNTimes
	ld a, [hl]
	ld [wTempMonItem], a
	pop hl
	ld bc, sBoxMon1DVs - sBox
	add hl, bc
	ld bc, BOXMON_STRUCT_LENGTH
	ld a, e
	rst AddNTimes
	ld de, wTempMonDVs
	ld a, [hli]
	ld [de], a
	inc de
	ld a, [hl]
	ld [de], a
	jp CloseSRAM

.party
	ld hl, wPartyMon1Level
	ld bc, PARTYMON_STRUCT_LENGTH
	ld a, e
	rst AddNTimes
	ld a, [hl]
	ld [wTempMonLevel], a
	ld hl, wPartyMon1Item
	ld bc, PARTYMON_STRUCT_LENGTH
	ld a, e
	rst AddNTimes
	ld a, [hl]
	ld [wTempMonItem], a
	ld hl, wPartyMon1DVs
	ld bc, PARTYMON_STRUCT_LENGTH
	ld a, e
	rst AddNTimes
	ld de, wTempMonDVs
	ld a, [hli]
	ld [de], a
	inc de
	ld a, [hl]
	ld [de], a
	ret

.sBox
	sbk BANK(sBox)
	ld hl, sBoxMon1Level
	ld bc, BOXMON_STRUCT_LENGTH
	ld a, e
	rst AddNTimes
	ld a, [hl]
	ld [wTempMonLevel], a

	ld hl, sBoxMon1Item
	ld bc, BOXMON_STRUCT_LENGTH
	ld a, e
	rst AddNTimes
	ld a, [hl]
	ld [wTempMonItem], a

	ld hl, sBoxMon1DVs
	ld bc, BOXMON_STRUCT_LENGTH
	ld a, e
	rst AddNTimes
	ld de, wTempMonDVs
	ld a, [hli]
	ld [de], a
	inc de
	ld a, [hl]
	ld [de], a

	jp CloseSRAM

BillsPC_RefreshTextboxes:
	hlcoord 8, 2
	lb bc, 10, 10
	call TextBox

	hlcoord 8, 2
	ld [hl], "└"
	hlcoord 19, 2
	ld [hl], "┘"

	ld a, [wBillsPC_ScrollPosition]
	ld e, a
	ld d, 0
	ld hl, wBillsPCPokemonList
	add hl, de
	add hl, de
	add hl, de
	ld e, l
	ld d, h
	hlcoord 9, 4
	ld a, [wBillsPC_NumMonsOnScreen]
.loop
	push af
	push de
	push hl
	call .PlaceNickname
	pop hl
	ld de, 2 * SCREEN_WIDTH
	add hl, de
	pop de
	inc de
	inc de
	inc de
	pop af
	dec a
	jr nz, .loop
	ret

.CancelString
	text "Cancel"
	done

.PlaceNickname
	ld a, [de]
	and a
	ret z
	inc a
	jr nz, .get_nickname
	ld de, .CancelString
	jp PlaceText

.get_nickname
	inc de
	ld a, [de]
	ld b, a
	inc de
	ld a, [de]
	ld e, a
	ld a, b
	and a
	jr z, .party
	cp NUM_BOXES + 1
	jr z, .sBox
	push hl
	call GetBoxPointer
	sbk b
	push hl
	ld bc, sBoxMons - sBox
	add hl, bc
	ld bc, BOXMON_STRUCT_LENGTH
	ld a, e
	rst AddNTimes
	ld a, [hl]
	pop hl
	and a
	jr z, .boxfail
	ld bc, sBoxMonNicknames - sBox
	add hl, bc
	ld bc, PKMN_NAME_LENGTH
	ld a, e
	rst AddNTimes
	ld de, wStringBuffer1
	ld bc, PKMN_NAME_LENGTH
	rst CopyBytes
	scls
	pop hl
	ld de, wStringBuffer1
	jp PlaceString

.boxfail
	scls
	pop hl
	jr .placeholder_string

.party
	push hl
	ld hl, wPartySpecies
	ld d, 0
	add hl, de
	ld a, [hl]
	and a
	jr z, .partyfail
	ld hl, wPartyMonNicknames
	ld bc, PKMN_NAME_LENGTH
	ld a, e
	ld de, wStringBuffer1
	call CopyNthStruct
	pop hl
	ld de, wStringBuffer1
	jp PlaceString

.partyfail
	pop hl
	jr .placeholder_string

.sBox
	push hl
	sbk BANK(sBox)
	ld hl, sBoxSpecies
	ld d, 0
	add hl, de
	ld a, [hl]
	and a
	jr z, .sBoxFail
	ld hl, sBoxMonNicknames
	ld bc, PKMN_NAME_LENGTH
	ld a, e
	ld de, wStringBuffer1
	call CopyNthStruct
	scls
	pop hl
	ld de, wStringBuffer1
	jp PlaceString

.sBoxFail
	scls
	pop hl
.placeholder_string
	ld de, .Placeholder
	jp PlaceText

.Placeholder
	text "-----"
	done

MACRO copy_box_data
.loop\@
	ld a, [hl]
	inc a
	jr z, .done\@
	dec a
	jr z, .done\@
	ld [de], a
	inc de
	ld a, [wBillsPC_LoadedBox]
	ld [de], a
	inc de
	ld a, [wd003]
	ld [de], a
	inc a
	ld [wd003], a
	inc de
	inc hl
	ld a, [wd004]
	inc a
	ld [wd004], a
	jr .loop\@

.done\@
IF \1
	scls
ENDC
	ld a, -1
	ld [de], a
	ld a, [wd004]
	inc a
	ld [wBillsPC_NumMonsInBox], a
ENDM

CopyBoxmonSpecies:
	xor a
	ld hl, wBillsPCPokemonList
	ld bc, 3 * 30
	call ByteFill
	ld de, wBillsPCPokemonList
	xor a
	ld [wd003], a
	ld [wd004], a
	ld a, [wBillsPC_LoadedBox]
	and a
	jr z, .party
	cp NUM_BOXES + 1
	jr z, .sBox
	ld b, a
	call GetBoxPointer
	sbk b
	inc hl
	copy_box_data 1
	ret

.party
	ld hl, wPartySpecies
	copy_box_data 0
	ret

.sBox
	sbk BANK(sBox)
	ld hl, sBoxSpecies
	copy_box_data 1
	ret

BillsPC_GetSelectedPokemonSpecies:
	ld a, [wBillsPC_CursorPosition]
	ld hl, wBillsPC_ScrollPosition
	add [hl]
	ld e, a
	ld d, 0
	ld hl, wBillsPCPokemonList
	add hl, de
	add hl, de
	add hl, de
	ld a, [hl]
	ret

BillsPC_UpdateSelectionCursor:
	ld a, [wBillsPC_NumMonsInBox]
	and a
	jp z, ClearSprites
	ld hl, .OAM
	ld de, wSprites
.loop
	ld a, [hl]
	cp -1
	ret z
	ld a, [wBillsPC_CursorPosition]
	and 7
	swap a
	add [hl]
	inc hl
	ld [de], a
	inc de
rept 3
	ld a, [hli]
	ld [de], a
	inc de
endr
	jr .loop

.OAM
	dsprite 4, 6, 10, 0, $00, $00
	dsprite 4, 6, 11, 0, $00, $00
	dsprite 4, 6, 12, 0, $00, $00
	dsprite 4, 6, 13, 0, $00, $00
	dsprite 4, 6, 14, 0, $00, $00
	dsprite 4, 6, 15, 0, $00, $00
	dsprite 4, 6, 16, 0, $00, $00
	dsprite 4, 6, 17, 0, $00, $00
	dsprite 4, 6, 18, 0, $00, $00
	dsprite 4, 6, 18, 7, $00, $00
	dsprite 7, 1, 10, 0, $00, $40
	dsprite 7, 1, 11, 0, $00, $40
	dsprite 7, 1, 12, 0, $00, $40
	dsprite 7, 1, 13, 0, $00, $40
	dsprite 7, 1, 14, 0, $00, $40
	dsprite 7, 1, 15, 0, $00, $40
	dsprite 7, 1, 16, 0, $00, $40
	dsprite 7, 1, 17, 0, $00, $40
	dsprite 7, 1, 18, 0, $00, $40
	dsprite 7, 1, 18, 7, $00, $40
	dsprite 5, 6,  9, 6, $01, $00
	dsprite 6, 1,  9, 6, $01, $40
	dsprite 5, 6, 19, 1, $01, $20
	dsprite 6, 1, 19, 1, $01, $60
	db -1

BillsPC_UpdateInsertCursor:
	ld hl, .OAM
	ld de, wSprites
.loop
	ld a, [hl]
	cp -1
	ret z
	ld a, [wBillsPC_CursorPosition]
	and 7
	swap a
	add [hl]
	inc hl
	ld [de], a
	inc de
rept 3
	ld a, [hli]
	ld [de], a
	inc de
endr
	jr .loop

.OAM
	dsprite 4, 7, 10, 0, $06, $00
	dsprite 5, 3, 11, 0, $00, $40
	dsprite 5, 3, 12, 0, $00, $40
	dsprite 5, 3, 13, 0, $00, $40
	dsprite 5, 3, 14, 0, $00, $40
	dsprite 5, 3, 15, 0, $00, $40
	dsprite 5, 3, 16, 0, $00, $40
	dsprite 5, 3, 17, 0, $00, $40
	dsprite 5, 3, 18, 0, $00, $40
	dsprite 4, 7, 19, 0, $07, $00
	db -1

BillsPC_CheckSpaceInDestination:
; If moving within a box, no need to be here.
	ld hl, wBillsPC_LoadedBox
	ld a, [wBillsPC_BackupLoadedBox]
	cp [hl]
	jr z, .same_box

; Exceeding box or party capacity is a big no-no.
	ld a, [wBillsPC_LoadedBox]
	and a
	ld e, MONS_PER_BOX + 1
	jr nz, .compare
	ld e, PARTY_LENGTH + 1
.compare
	ld a, [wBillsPC_NumMonsInBox]
	cp e
	jr nc, .no_room
.same_box
	and a
	ret

.no_room
	ld de, PCString_TheresNoRoom
	call BillsPC_PlaceText
	ld de, SFX_WRONG
	call KillPlayWaitSFX
	scf
	ret

BillsPC_BlackoutPrevention:
	ld a, [wBillsPC_LoadedBox]
	and a
	jr nz, .Okay
	ld a, [wBillsPC_NumMonsInBox]
	cp 3
	jr c, .ItsYourLastPokemon
	call BillsPC_GetScrollCursorPosition
	call CheckIfOnlyAliveMonIsCurPartyMon
	jr c, .AllOthersFainted
.Okay
	and a
	ret

.AllOthersFainted
	ld de, PCString_NoMoreUsablePKMN
	jr .NotOkay

.ItsYourLastPokemon
	ld de, PCString_ItsYourLastPKMN
.NotOkay
	call BillsPC_PlaceText
	ld de, SFX_WRONG
	call KillPlayWaitSFX
	scf
	ret

BillsPC_IsMonAnEgg:
	ld a, [wCurPartySpecies]
	cp EGG
	jr z, .egg
	and a
	ret

.egg
	ld de, PCString_NoReleasingEGGS
	call BillsPC_PlaceText
	ld de, SFX_WRONG
	call KillPlayWaitSFX
	scf
	ret

BillsPC_StatsScreen:
	call LowVolume
	call BillsPC_CopyMon
	ld a, 3
	ld [wMonType], a
	predef StatsScreenInit
	call BillsPC_InitGFX
	jp MaxVolume

StatsScreenDPad:
	ld hl, hJoyPressed
	ld a, [hl]
	and A_BUTTON | B_BUTTON | D_RIGHT | D_LEFT
	ld [wMenuJoypad], a
	ret nz
	ld a, [hl]
	and D_DOWN | D_UP
	ld [wMenuJoypad], a
	ret z
	call _StatsScreenDPad
	and a
	jr z, .did_nothing
	call BillsPC_GetSelectedPokemonSpecies
	ld [wd265], a
	call BillsPC_LoadMonStats
	ld a, [wd265]
	ld [wCurPartySpecies], a
	ld [wCurSpecies], a
	call GetBaseData
	jp BillsPC_CopyMon

.did_nothing
	xor a
	ld [wMenuJoypad], a
	ret

BillsPC_CopyMon:
	call BillsPC_GetScrollCursorPosition
	ld a, [wBillsPC_LoadedBox]
	and a
	jr z, .party
	cp NUM_BOXES + 1
	jr nz, .box
	sbk BANK(sBox)
	ld hl, sBoxSpecies
	call CopySpeciesToTemp
	ld hl, sBoxMonNicknames
	call CopyNicknameToTemp
	ld hl, sBoxMonOT
	call CopyOTNameToTemp
	ld hl, sBoxMons
	ld bc, BOXMON_STRUCT_LENGTH
	ld de, wBufferMon
	ld a, [wCurPartyMon]
	call CopyNthStruct
	scls
	jpba CalcwBufferMonStats

.party
	ld hl, wPartySpecies
	call CopySpeciesToTemp
	ld hl, wPartyMonNicknames
	call CopyNicknameToTemp
	ld hl, wPartyMonOT
	call CopyOTNameToTemp
	ld hl, wPartyMons
	ld bc, PARTYMON_STRUCT_LENGTH
	ld a, [wCurPartyMon]
	ld de, wBufferMon
	jp CopyNthStruct

.box
	ld b, a
	call GetBoxPointer
	sbk b
	push hl
	inc hl
	call CopySpeciesToTemp
	pop hl
	push hl
	ld bc, sBoxMonNicknames - sBox
	add hl, bc
	call CopyNicknameToTemp
	pop hl
	push hl
	ld bc, sBoxMonOT - sBox
	add hl, bc
	call CopyOTNameToTemp
	pop hl
	ld bc, sBoxMons - sBox
	add hl, bc
	ld bc, BOXMON_STRUCT_LENGTH
	call CopyMonToTemp
	scls
	jpba CalcwBufferMonStats

DepositPokemon:
	call BillsPC_GetScrollCursorPosition
	call CheckForSpecialGiftMon
	jr c, .nonDepositableMon
	ld hl, wPartyMonNicknames
	ld a, [wCurPartyMon]
	call GetNick
	ld a, PC_DEPOSIT
	ld [wPokemonWithdrawDepositParameter], a
	predef SentGetPkmnIntoFromBox
	jr c, .asm_boxisfull
	xor a
	ld [wPokemonWithdrawDepositParameter], a
	callba RemoveMonFromPartyOrBox
	hlcoord 0, 15
	lb bc, 1, 18
	call TextBox
	hlcoord 1, 16
	ld de, PCString_Stored
	call PlaceText
	ld l, c
	ld h, b
	ld de, wStringBuffer1
	call PlaceString
	ld a, "!"
	ld [bc], a
	call ApplyTilemapInVBlank
	call SFXChannelsOff
	ld a, [wCurPartySpecies]
	call PlayCry
	hlcoord 0, 0
	lb bc, 15, 8
	call ClearBox
	hlcoord 8, 14
	lb bc, 1, 3
	call ClearBox
	jp ApplyTilemapInVBlank

.nonDepositableMon
	ld de, PCString_CantDepositThis
	call BillsPC_PlaceText
	jr .playWrongSFXAndSetCarry

.asm_boxisfull
	ld de, PCString_BoxFull
	call BillsPC_PlaceText
.playWrongSFXAndSetCarry
	ld de, SFX_WRONG
	call KillPlayWaitSFX
	scf
	ret

CheckForSpecialGiftMon:
; possible sanity check
	; CheckEvent EVENT_NOBUS_AGGRON_IN_PARTY
	; jr z, .canDeposit

	ld hl, wPartyMonOT
	ld a, [wCurPartyMon]
	call SkipNames
	lb bc, "@", PLAYER_NAME_LENGTH - 1
.loopTerminator
	ld a, [hli]
	cp b
	jr z, .foundTerminator
	dec c
	jr nz, .loopTerminator
.canDeposit
	and a
	ret
.foundTerminator
	ld a, [hl]
	cp "F" ; flag for certain gift mons
	jr nz, .canDeposit
	scf
	ret

TryWithdrawPokemon:
	call BillsPC_GetScrollCursorPosition
	sbk BANK(sBoxMonNicknames)
	ld a, [wCurPartyMon]
	ld hl, sBoxMonNicknames
	call GetNick
	scls
	xor a
	ld [wPokemonWithdrawDepositParameter], a
	predef SentGetPkmnIntoFromBox
	jr c, .PartyFull
	ld a, PC_DEPOSIT
	ld [wPokemonWithdrawDepositParameter], a
	callba RemoveMonFromPartyOrBox
	hlcoord 0, 15
	lb bc, 1, 18
	call TextBox
	hlcoord 1, 16
	ld de, PCString_Got
	call PlaceString
	ld l, c
	ld h, b
	ld de, wStringBuffer1
	call PlaceString
	ld a, "!"
	ld [bc], a
	call ApplyTilemapInVBlank
	call SFXChannelsOff
	ld a, [wCurPartySpecies]
	call PlayCry
	hlcoord 0, 0
	lb bc, 15, 8
	call ClearBox
	hlcoord 8, 14
	lb bc, 1, 3
	call ClearBox
	jp ApplyTilemapInVBlank

.PartyFull
	ld de, PCString_PartyFull
	call BillsPC_PlaceText
	ld de, SFX_WRONG
	call KillPlayWaitSFX
	scf
	ret

ReleasePKMN_ByePKMN:
	hlcoord 0, 0
	lb bc, 15, 8
	call ClearBox
	hlcoord 8, 14
	lb bc, 1, 3
	call ClearBox
	hlcoord 0, 15
	lb bc, 1, 18
	call TextBox

	ld a, [wCurPartySpecies]
	ld [wd265], a
	call GetPokemonName
	hlcoord 1, 16
	ld de, PCString_ReleasedPKMN
	call PlaceText
	hlcoord 0, 15
	lb bc, 1, 18
	call TextBox
	hlcoord 1, 16
	ld de, PCString_Bye
	call PlaceText
	ld l, c
	ld h, b
	inc hl
	ld de, wStringBuffer1
	call PlaceString
	ld a, "!"
	ld [bc], a
	call ApplyTilemapInVBlank
	call SFXChannelsOff
	ld a, [wCurPartySpecies]
	jp PlayCry

MovePKMNWitoutMail_InsertMon:
	push hl
	push de
	push bc
	push af
	hlcoord 0, 15
	lb bc, 1, 18
	call TextBox
	hlcoord 1, 16
	ld de, .Saving_LeaveOn
	call PlaceText
	pop af
	pop bc
	pop de
	pop hl
	ld a, [wCurBox]
	push af
	ld c, 0
	ld a, [wBillsPC_BackupLoadedBox]
	and a
	jr nz, .moving_from_box
	set 0, c

.moving_from_box
	ld a, [wBillsPC_LoadedBox]
	and a
	jr nz, .moving_to_box
	set 1, c

.moving_to_box
	ld a, c
	jumptable .Jumptable
	pop af
	ld e, a
	jpba SaveGameDataFromMoveMon

.Saving_LeaveOn
	ctxt "Sauvegarde en cours"
	done

.Jumptable
	dw .BoxToBox
	dw .PartyToBox
	dw .BoxToParty
	dw .PartyToParty

.BoxToBox
	ld hl, wBillsPC_BackupLoadedBox
	ld a, [wBillsPC_LoadedBox]
	cp [hl]
	jr z, .same_box
	call .CopyFromBox
	jp .CopyToBox

.same_box
	call .CopyFromBox
	call .CheckTrivialMove
	jp .CopyToBox

.PartyToBox
	call .CopyFromParty
	ld a, 1
	ld [wGameLogicPause], a
	callba SaveGameData
	xor a
	ld [wGameLogicPause], a
	jp .CopyToBox

.BoxToParty
	call .CopyFromBox
	jp .CopyToParty

.PartyToParty
	call .CopyFromParty
	call .CheckTrivialMove
	jp .CopyToParty

.CheckTrivialMove
	ld a, [wBillsPC_CursorPosition]
	ld hl, wBillsPC_ScrollPosition
	add [hl]
	ld e, a
	ld a, [wBillsPC_BackupCursorPosition]
	ld hl, wBillsPC_BackupScrollPosition
	add [hl]
	cp e
	ret nc
	ld hl, wBillsPC_CursorPosition
	ld a, [hl]
	and a
	jr z, .top_of_screen
	dec [hl]
	ret

.top_of_screen
	ld hl, wBillsPC_ScrollPosition
	ld a, [hl]
	and a
	ret z
	dec [hl]
	ret

.CopyFromBox
	ld a, [wBillsPC_BackupLoadedBox]
	dec a
	ld e, a
	callba MovePkmnWOMail_SaveGame
	ld a, [wBillsPC_BackupCursorPosition]
	ld hl, wBillsPC_BackupScrollPosition
	add [hl]
	ld [wCurPartyMon], a
	sbk BANK(sBox)
	ld hl, sBoxSpecies
	call CopySpeciesToTemp
	ld hl, sBoxMonNicknames
	call CopyNicknameToTemp
	ld hl, sBoxMonOT
	call CopyOTNameToTemp
	ld hl, sBoxMons
	ld bc, BOXMON_STRUCT_LENGTH
	call CopyMonToTemp
	scls
	callba CalcwBufferMonStats
	ld a, PC_DEPOSIT
	ld [wPokemonWithdrawDepositParameter], a
	jpba RemoveMonFromPartyOrBox

.CopyToBox
	ld a, [wBillsPC_LoadedBox]
	dec a
	ld e, a
	callba MovePkmnWOMail_SaveGame
	call BillsPC_GetScrollCursorPosition
	jpba PopMonFromBox

.CopyFromParty
	ld a, [wBillsPC_BackupCursorPosition]
	ld hl, wBillsPC_BackupScrollPosition
	add [hl]
	ld [wCurPartyMon], a
	ld hl, wPartySpecies
	call CopySpeciesToTemp
	ld hl, wPartyMonNicknames
	call CopyNicknameToTemp
	ld hl, wPartyMonOT
	call CopyOTNameToTemp
	ld hl, wPartyMon1Species
	ld bc, PARTYMON_STRUCT_LENGTH
	call CopyMonToTemp
	xor a
	ld [wPokemonWithdrawDepositParameter], a
	jpba RemoveMonFromPartyOrBox

.CopyToParty
	call BillsPC_GetScrollCursorPosition
	jpba PopMonFromParty

CopySpeciesToTemp:
	ld a, [wCurPartyMon]
	ld c, a
	ld b, 0
	add hl, bc
	ld a, [hl]
	ld [wCurPartySpecies], a
	ret

CopyNicknameToTemp:
	ld bc, PKMN_NAME_LENGTH
	ld a, [wCurPartyMon]
	rst AddNTimes
	ld de, wBufferMonNick
	ld bc, PKMN_NAME_LENGTH
	rst CopyBytes
	ret

CopyOTNameToTemp:
	ld bc, NAME_LENGTH
	ld a, [wCurPartyMon]
	ld de, wBufferMonOT
	jp CopyNthStruct

CopyMonToTemp:
	ld a, [wCurPartyMon]
	ld de, wBufferMon
	jp CopyNthStruct

GetBoxPointer:
	dec b
	ld c, b
	ld b, 0
	ld hl, BoxStartAddresses
	add hl, bc
	add hl, bc
	add hl, bc
	ld a, [hli]
	ld b, a
	ld a, [hli]
	ld h, [hl]
	ld l, a
	ret

BoxStartAddresses:
	;  bank, address
	dba sBox1
	dba sBox2
	dba sBox3
	dba sBox4
	dba sBox5
	dba sBox6
	dba sBox7
	dba sBox8
	dba sBox9
	dba sBox10
	dba sBox11
	dba sBox12
	dba sBox13
	dba sBox14

BillsPC_ApplyPalettes:
	ld b, a
	predef GetSGBLayout
	ld a, %11100100
	call DmgToCgbBGPals
	ld a, %11111100
	jp DmgToCgbObjPal0

BillsPC_InitGFX:
	call DisableLCD
	ld hl, vBGTiles tile $00
	ld bc, $31 tiles
	xor a
	call ByteFill
	call LoadStandardFont
	call LoadFontsBattleExtra
	ld hl, PCMailGFX
	ld de, vBGTiles tile $5c
	ld bc, 4 tiles
	rst CopyBytes
	ld hl, PCSelectLZ
	ld de, vObjTiles tile $00
	call Decompress
	ld a, 6
	call SkipMusic
	jp EnableLCD

PCSelectLZ: INCBIN "gfx/pc/pc.2bpp.lz"
PCMailGFX:  INCBIN "gfx/pc/pc_mail.2bpp"

PCString_ChooseaPKMN:
	text "Choisir un <PK><MN>."
	done

PCString_WhatsUp:
	ctxt "Que faire?"
	done

PCString_ReleasePKMN:
	text "Libérer <PK><MN>?"
	done

PCString_MoveToWhere:
	ctxt "Déplacer où?"
	done

PCString_ItsYourLastPKMN:
	ctxt "Dernier <PK><MN>!"
	done

PCString_TheresNoRoom:
	ctxt "Plus de place!"
	done

PCString_NoMoreUsablePKMN:
	ctxt "Plus de <PK><MN>!"
	done

PCString_ReleasedPKMN:
	text "<PK><MN> libéré."
	done

PCString_Bye:
	text "Bye,"
	done

PCString_Stored:
	ctxt "Déposé "
	done

PCString_Got:
	db "Reçu @"

PCString_BoxFull:
	ctxt "Boîte pleine."
	done

PCString_PartyFull:
	ctxt "Équipe pleine!"
	done

PCString_NoReleasingEGGS:
	ctxt "Pas d'OEUF!"
	done

PCString_CantDepositThis:
	ctxt "Dépôt impossible!"
	done

PCString_CantReleaseThis:
	ctxt "Libération impossible"
	done

PCString_CantMoveThisPKMN:
	ctxt "Déplacement impossible"
	done

_ChangeBox:
	call LoadStandardMenuHeader
	call BillsPC_ClearTilemap
.loop
	xor a
	ldh [hBGMapMode], a
	call BillsPC_PrintBoxName
	call BillsPC_PlaceChooseABoxString
	ld hl, _ChangeBox_menudataheader
	call CopyMenuHeader
	xor a
	ld [wMenuScrollPosition], a
	hlcoord 0, 4
	lb bc, 8, 9
	call TextBox
	call ScrollingMenu
	ld a, [wMenuJoypad]
	cp B_BUTTON
	jr z, .done
	call BillsPC_PlaceWhatsUpString
	call BillsPC_ChangeBoxSubmenu
	jr .loop
.done
	jp CloseWindow

BillsPC_ClearTilemap:
	xor a
	ldh [hBGMapMode], a
	hlcoord 0, 0
	ld bc, SCREEN_WIDTH * SCREEN_HEIGHT
	ld a, " "
	jp ByteFill

_ChangeBox_menudataheader:
	db $40 ; flags
	db 05, 01 ; start coords
	db 12, 09 ; end coords
	dw .menudata2
	db 1 ; default option

.menudata2
	db $22 ; flags
	db 4, 0
	db 1
	dba .boxes
	dba .boxnames
	dba NULL
	dba BillsPC_PrintBoxCountAndCapacity

.boxes
	db NUM_BOXES
x = 1
rept NUM_BOXES
	db x
x = x + 1
endr
	db -1

.boxnames
	push de
	ld a, [wMenuSelection]
	dec a
	call GetBoxName
	pop hl
	jp PlaceString

GetBoxName:
	ld bc, BOX_NAME_LENGTH
	ld hl, wBoxNames
	rst AddNTimes
	ld d, h
	ld e, l
	ret

BillsPC_PrintBoxCountAndCapacity:
	hlcoord 11, 7
	lb bc, 5, 7
	call TextBox
	ld a, [wMenuSelection]
	cp -1
	ret z
	hlcoord 12, 9
	ld de, .Pokemon
	call PlaceString
	call GetBoxCount
	ld [wd265], a
	hlcoord 13, 11
	ld de, wd265
	lb bc, 1, 2
	call PrintNum
	ld de, .out_of_20
	jp PlaceString

.Pokemon
	db "#mon@"

.out_of_20
	; db "/20@"
	db "/"
	db "0" + MONS_PER_BOX / 10 ; "2"
	db "0" + MONS_PER_BOX % 10 ; "0"
	db "@"

GetBoxCount:
	ld a, [wCurBox]
	ld c, a
	ld a, [wMenuSelection]
	dec a
	cp c
	jr z, .activebox
	ld c, a
	ld b, 0
	ld hl, BoxStartAddresses
	add hl, bc
	add hl, bc
	add hl, bc
	ld a, [hli]
	ld b, a
	sbk a
	ld a, [hli]
	ld h, [hl]
	ld l, a
	ld a, [hl]
	scls
	ld c, a
	ld a, [wSavedAtLeastOnce]
	and a
	jr z, .newfile
	ld a, c
	ret

.newfile
	xor a
	ret

.activebox
	ld b, BANK(sBoxCount)
	sbk b
	ld hl, sBoxCount
	ld a, [hl]
	jp CloseSRAM

BillsPC_PrintBoxName:
	hlcoord 0, 0
	lb bc, 2, 18
	call TextBox
	hlcoord 1, 2
	ld de, .Current
	call PlaceText
	ld a, [wCurBox]
	and $f
	call GetBoxName
	hlcoord 11, 2
	jp PlaceString

.Current
	ctxt "Current"
	done

BillsPC_ChangeBoxSubmenu:
	ld hl, .MenuHeader
	call LoadMenuHeader
	call VerticalMenu
	call ExitMenu
	ret c
	ld a, [wMenuCursorY]
	and a
	ret z
	dec a
	jr z, .Switch
	dec a
	jr z, .Name
	dec a
	ret nz

.Print
	call GetBoxCount
	and a
	jr z, .EmptyBox
	ld e, l
	ld d, h
	ld a, [wMenuSelection]
	dec a
	ld c, a
	callba PrintPCBox
	call BillsPC_ClearTilemap
	and a
	ret

.EmptyBox
	call BillsPC_PlaceEmptyBoxString_SFX
	and a
	ret

.Switch
	ld a, [wMenuSelection]
	dec a
	ld e, a
	ld a, [wCurBox]
	cp e
	ret z
	jpba ChangeBoxSaveGame

.Name
	ld b, 4 ; box
	ld de, wd002
	callba NamingScreen
	call ClearTileMap
	call LoadStandardFont
	call LoadFontsBattleExtra
	ld a, [wMenuSelection]
	dec a
	call GetBoxName
	ld e, l
	ld d, h
	ld hl, wd002
	ld c, BOX_NAME_LENGTH - 1
	call .InitString
	ld a, [wMenuSelection]
	dec a
	call GetBoxName
	ld de, wd002
	jp CopyName2

.InitString
; Init a string of length c.
	push hl
	jp _InitString

.MenuHeader
	db $40 ; flags
	db 04, 11 ; start coords
	db 13, 19 ; end coords
	dw .MenuData2
	db 1 ; default option

.MenuData2
	db $80 ; flags
	db 4 ; items
	db "Changer@"
	db "Nommer@"
	db "Imprimer@"
	db "Quitter@"

BillsPC_PlaceChooseABoxString:
	ld de, .ChooseABox
	jr BillsPC_PlaceChangeBoxString

.ChooseABox
	ctxt "Choisir Boîte."
	done

BillsPC_PlaceWhatsUpString:
	ld de, .WhatsUp
	jr BillsPC_PlaceChangeBoxString

.WhatsUp
	ctxt "Que faire?"
	done

BillsPC_PlaceEmptyBoxString_SFX:
	ld de, .NoMonString
	call BillsPC_PlaceChangeBoxString
	ld de, SFX_WRONG
	jp KillPlayWaitSFX

.NoMonString
	ctxt "Aucun #mon."
	done

BillsPC_PlaceChangeBoxString:
	push de
	hlcoord 0, 14
	lb bc, 2, 18
	call TextBox
	pop de
	hlcoord 1, 16
	call PlaceText
	ld a, 1
	ldh [hBGMapMode], a
	ret

_BillsPC:
	call .CheckCanUsePC
	ret c
	call .LogIn
	call .UseBillsPC
	jp CloseSubmenu

.CheckCanUsePC
	ld a, [wPartyCount]
	and a
	ret nz
	ld hl, .Text_GottaHavePokemon
	call MenuTextBoxBackup
	scf
	ret

.Text_GottaHavePokemon
	; You gotta have #mon to call!
	text_jump BillsPC_GottaHaveMon

.LogIn
	xor a
	ldh [hBGMapMode], a
	call LoadStandardMenuHeader
	call ClearPCItemScreen
	ld hl, wOptions
	ld a, [hl]
	push af
	set NO_TEXT_SCROLL, [hl]
	ld hl, .Text_What
	call PrintText
	pop af
	ld [wOptions], a
	jp LoadFontsBattleExtra

.Text_What
	; What?
	text_jump BillsPC_What

.UseBillsPC
	ld hl, .MenuHeader
	call LoadMenuHeader
	ld a, 1
.loop
	ld [wMenuCursorBuffer], a
	call SetPalettes
	xor a
	ld [wWhichIndexSet], a
	ldh [hBGMapMode], a
	call DoNthMenu
	jr c, .cancel
	ld a, [wMenuCursorBuffer]
	push af
	ld a, [wMenuSelection]
	jumptable .Jumptable
	pop bc
	ld a, b
	jr nc, .loop
.cancel
	jp CloseWindow

.MenuHeader
	db $40 ; flags
	db 00, 00 ; start coords
	db 17, 19 ; end coords
	dw .MenuData2
	db 1 ; default option

.MenuData2
	db $80 ; flags
	db 0 ; items
	dw .items
	dw PlaceMenuStrings
	dw .strings

.strings
	db "Retirer <PK><MN>@"
	db "Déposer <PK><MN>@"
	db "Changer Boîte@"
	db "Déplacer <PK><MN>@"
	db "Au revoir!@"

.Jumptable
	dw BillsPC_WithdrawMenu
	dw BillsPC_DepositMenu
	dw BillsPC_ChangeBoxMenu
	dw BillsPC_MovePKMNMenu
	dw BillsPC_SeeYa

.items
	db 5
	db 0 ; RETIRER
	db 1 ; DÉPOSER
	db 2 ; CHANGER BOÎTE
	db 3 ; DÉPLACER PKMN
	db 4 ; AU REVOIR!
	db -1

BillsPC_SeeYa:
	scf
	ret

BillsPC_MovePKMNMenu:
	call LoadStandardMenuHeader
	callba StartMovePkmnWOMail_SaveGame
	jr c, .quit
	call _MovePKMNWithoutMail
	call ReturnToMapFromSubmenu
	call ClearPCItemScreen

.quit
	call CloseWindow
	and a
	ret

BillsPC_DepositMenu:
	call LoadStandardMenuHeader
	call _DepositPKMN
	call ReturnToMapFromSubmenu
	call ClearPCItemScreen
	call CloseWindow
	and a
	ret

CheckIfOnlyAliveMonIsCurPartyMon:
	ld hl, wPartyMon1HP
	ld de, PARTYMON_STRUCT_LENGTH
	ld b, 0
.loop
	ld a, [wCurPartyMon]
	cp b
	jr z, .skip
	ld a, [hli]
	or [hl]
	jr nz, .notfainted
	dec hl

.skip
	inc b
	ld a, [wPartyCount]
	cp b
	jr z, .done
	add hl, de
	jr .loop

.done
	scf
	ret

.notfainted
	and a
	ret

BillsPC_WithdrawMenu:
	call LoadStandardMenuHeader
	call _WithdrawPKMN
	call ReturnToMapFromSubmenu
	call ClearPCItemScreen
	call CloseWindow
	and a
	ret

BillsPC_ChangeBoxMenu:
	call _ChangeBox
	and a
	ret

ClearPCItemScreen:
	call DisableSpriteUpdates
	xor a
	ldh [hBGMapMode], a
	call ClearBGPalettes
	call ClearSprites
	hlcoord 0, 0
	ld bc, SCREEN_HEIGHT * SCREEN_WIDTH
	ld a, " "
	call ByteFill
	hlcoord 0,0
	lb bc, 10, 18
	call TextBox
	hlcoord 0,12
	lb bc, 4, 18
	call TextBox
	call ApplyAttrAndTilemapInVBlank
	jp SetPalettes ; load regular palettes?

CopyCurBoxName::
	ld a, [wCurBox]
	call GetBoxName
	ld de, wStringBuffer1
	rst CopyBytes
	ret
