#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_Icon=..\..\code\favicon.ico
#AutoIt3Wrapper_Outfile=script\streamkeyshelper.exe
#AutoIt3Wrapper_Change2CUI=y
#AutoIt3Wrapper_Res_Comment=A helper application for StreamKeysQuantum Firefox extension. 100% Open source, see github
#AutoIt3Wrapper_Res_Description=A helper application for StreamKeysQuantum Firefox extension. 100% Open source, see github
#AutoIt3Wrapper_Res_Fileversion=1.1.180
#AutoIt3Wrapper_Res_ProductName=Stream Keys Quantum Global Command Support Helper
#AutoIt3Wrapper_Res_ProductVersion=1.1.180
#AutoIt3Wrapper_Res_CompanyName=efprojects.com
#AutoIt3Wrapper_Res_LegalCopyright=(c) Egor Aristov, 2018-2020
#AutoIt3Wrapper_Res_LegalTradeMarks=(c) efprojects.com
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****

; StreamKeys-Quantum Firefox Extension helper by Egor3f
; Global Command Support
; version 0.2

#include <TrayConstants.au3>
#include <Array.au3>

Global $commandConfig = IniReadSection("config.ini", "commands")
Global $commandsLength = $commandConfig[0][0]

Opt("TrayAutoPause", 0)
Opt("TrayMenuMode", 1)
Const $activeMessage = "SKQ Active — press to disable temporarily (to use other music/movie programs)"
Const $inactiveMessage = "SKQ Disabled — press to enable again"
$toggleMenuItem = TrayCreateItem($activeMessage)
TrayCreateItem("")
$exitMenuItem = TrayCreateItem("Exit Stream Keys Quantum GCS Helper")
TraySetState($TRAY_ICONSTATE_SHOW)
TrayItemSetState($toggleMenuItem, $TRAY_CHECKED)
$enabled = True

Const $SpecialCommands = ["_toggle"]

Func setHotkeys($toEnable=True, $toDisableSpecial=False)
	For $i = 1 to $commandsLength
		If $toEnable Then
			HotKeySet($commandConfig[$i][1], "processCommand")
		Else
			If _ArraySearch($SpecialCommands, $commandConfig[$i][0]) < 0 Or $toDisableSpecial Then
				HotKeySet($commandConfig[$i][1])
			EndIf
		EndIf
	Next
EndFunc

Func processCommand()
	Dim $command = @HotKeyPressed
	For $i = 1 to $commandsLength
		If $command == $commandConfig[$i][1] Then
			If $commandConfig[$i][0] == "_toggle" Then
				$enabled = Not $enabled
				setHotkeys($enabled)
				TrayItemSetState($toggleMenuItem, $enabled ? $TRAY_CHECKED : $TRAY_UNCHECKED)
				TrayItemSetText($toggleMenuItem, $enabled ? $activeMessage : $inactiveMessage)
			Else
				sendFirefoxMessage($commandConfig[$i][0])
			EndIf
			ExitLoop
		EndIf
	Next
EndFunc

Func sendFirefoxMessage($cm)
	Dim $json = '"' & $cm & '"'
	Dim $len = StringLen($json)
	ConsoleWrite(Binary($len))
	ConsoleWrite($json)
EndFunc

Func updateKeymap($keymap)
	setHotKeys(False, True)
	Dim $kvArray = StringSplit($keymap, "\u001e", 1)
	Global $commandsLength = $kvArray[0]
	Global $commandConfig[$commandsLength + 1][2]
	$commandConfig[0][0] = $commandsLength
	For $i = 1 To $commandsLength
		Dim $kvSplit = StringSplit($kvArray[$i], "\u001f", 1)
		$commandConfig[$i][0] = StringStripWS($kvSplit[1], 8)
		$commandConfig[$i][1] = StringStripWS($kvSplit[2], 8)
	Next
	; _ArrayDisplay($commandConfig)
	IniWriteSection("config.ini", "commands", $commandConfig)
	setHotkeys(True)
EndFunc

setHotkeys()

Global $newDataSize = 0
Global $newData = ""

While 1
    Switch TrayGetMsg()
		Case $toggleMenuItem
			$enabled = Not $enabled
			setHotkeys($enabled)
			TrayItemSetState($toggleMenuItem, $enabled ? $TRAY_CHECKED : $TRAY_UNCHECKED)
			TrayItemSetText($toggleMenuItem, $enabled ? $activeMessage : $inactiveMessage)
		Case $exitMenuItem
			ExitLoop
	EndSwitch

	Dim $dataFromBrowser = ConsoleRead()
	If @extended > 0 Then
		If StringLen($newData) == 0 Then
			Dim $packetSizeString = StringLeft($dataFromBrowser, 4)
			$packetSizeString = StringReverse($packetSizeString) ; Little endian
			$newDataSize = Dec(StringMid(Binary($packetSizeString), 3, 8), 1)
			If $newDataSize <= 0 Then
				ContinueLoop
			EndIf
			$newData &= StringMid($dataFromBrowser, 5)
			If StringLen($newData) >= $newDataSize Then
				updateKeymap(StringMid($newData, 2, StringLen($newData) - 2))
				$newData = ""
				$newDataSize = 0
			EndIf
		Else
			$newData &= $dataFromBrowser
		EndIf
	EndIf
WEnd
