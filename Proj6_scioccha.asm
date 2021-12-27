TITLE Project 6     (Proj6_scioccha.asm)

; Author: Alexandra SCiocchetti
; Last Modified: 12/1/21
; OSU email address: scioccha@oregonstate.edu
; Course number/section: 271   CS271 Section 400
; Project Number: 6                Due Date: 12/5/21
; Description: This program takes as input 10 numbers, 
; which are read as strings (invalid input such as letters
; and symbols are rejected by the program), converts those strings
; to signed integers using ASCII values, calculates the sum and 
; rounded average of the integers, and then converts them back
; to strings and displays the list of numbers, the sum and the 
; rounded average.

INCLUDE Irvine32.inc

; -------------------------------------------------------------------------------------------------------------
; Name: mGetString
; Prompts the user to enter a number, reads that number using the Irvine readString procedure, and saves it
; Preconditions: Maxsize of string is defined
; Registers: edx and ecx both used (popped and restored)
; Receives: user prompt, savedStr (memory location in which to save the string)
; Returns: string value saved in memory to savedStr, stringLength in EAX
; -------------------------------------------------------------------------------------------------------------
mGetString	MACRO	prompt, savedStr
	PUSH	edx												
	PUSH	ecx

	MOV		edx, prompt
	CALL	WriteString
	MOV		edx, savedStr
	MOV		ecx, MAXSIZE						
	CALL	ReadString
	
	POP		ecx
	POP		edx
ENDM

; -------------------------------------------------------------------------------------------------------------
; Name: mDisplayString
; Takes an array of strings, locates the correct string, and prints it to output using WriteString
; Registers: edx and edi are both used (Popped and Restored), eax also used but value is not changed
; Preconditions: EAX contains memory location of string within array, strArray is passed to Macro
; Receives: strArray passed by procedure. Also eax contains pointer to location
; Returns: NA, string is printed in console. 
; -------------------------------------------------------------------------------------------------------------
mDisplayString MACRO	inputStr
	PUSH	edx												
	PUSH	edi

	MOV		edx, inputStr
	CALL	WriteString
	
	POP		edi
	POP		edx
ENDM


TOTALNUM		= 10
MAXSIZE			= 12			; maxsize is 12 to account for too large inputs, plus sign value
CONVERSION		= 10
UNSIGNEDREGMAX  = 4294967295	; unsigned register max, used to determine if int is negative
ASCIIHI			= 57			
ASCIILOW		= 48

.data

intro1		BYTE		"PROGRAMMING ASSIGNMENT 6: Designing low-level I/O procedures ",13,10
			BYTE		"Written by Alexandra Sciocchetti",13,10
			BYTE		" ",13,10
			BYTE		"Please provide 10 signed decimal integers", 13,10
			BYTE		"Each number needs to be small enough to fit inside a 32 bit register.", 13,10
			BYTE		"After you have finished inputting the raw numbers I will display a ", 13,10
			BYTE		"list of the integers, their sum, and their average value.", 13,10
			BYTE		" ", 13,10,0
prompt1		BYTE		"Please enter a signed number: ",0
errormsg	BYTE		"ERROR: You did not enter a signed number or your number was too big.", 13,10, 0
display1	BYTE		"You entered the following numbers: ",13,10,0
comma		BYTE		", ",0
display2	BYTE		"The sum of those numbers is: ",0
display3	BYTE		" ",13,10
			BYTE		"The rounded average is: ",0
farewell	BYTE		"Thanks for playing. See you next time!", 13,10,0
sLen		DWORD		?
intArray	SDWORD		TOTALNUM DUP(?)
strArray	SDWORD		TOTALNUM DUP(?)
storedStr   DWORD		?
sumAndAvg	SDWORD		2 DUP(?)
strSumAvg	SDWORD		2 DUP(?)
negSign		DWORD		45
plusSign	DWORD		43
sumAvgSize  DWORD		2
strSign		SDWORD		0
storedByte  BYTE		12 DUP(?)



.code
main PROC
	PUSH	 OFFSET intro1
	CALL	 introduction

	MOV		 ecx, 0												; ecx used as counter for loop to read all 10 values
	_readValLoop:
	;------------------------------------------------------------------------------------------------------------
	; Uses ecx as a loop counter, pushes all necessary items on to the stack, then calls readVal procedure to read
	; in, validate, and store a user entered number (read as a string). Loop is repeated 10 times to get 10 inputs
	;------------------------------------------------------------------------------------------------------------
		CMP		ECX, TOTALNUM									; once ecx == 10 we are done
		JE		_startSumAvg
		PUSH	OFFSET intArray
		PUSH	plusSign
		PUSH	negSign
		PUSH	OFFSET prompt1
		PUSH	sLen
		PUSH	OFFSET storedStr
		PUSH	OFFSET errormsg
		CALL	readVal

		INC		ecx
		JMP		_readValLoop

	_startSumAvg:
	;------------------------------------------------------------------------------------------------------------
	; pushes intArray and sumAndAvg array onto the stack, then calls the calcSumAvg proc to calculate the sum and
	; average of all integers entered
	;------------------------------------------------------------------------------------------------------------
		PUSH	OFFSET intArray
		PUSH	OFFSET sumAndAvg
		CALL	calcSumAvg										; calculate Sum and Average using intArray
	
	PUSH	OFFSET storedByte
	PUSH	strSign
	PUSH	OFFSET strArray
	PUSH	OFFSET intArray
	PUSH	OFFSET display1
	PUSH	OFFSET comma
	PUSH	TOTALNUM
	CALL	writeVal											; call writeVal to convert all 10 integers to strings and display

	PUSH	OFFSET storedByte
	PUSH	strSign
	PUSH	OFFSET strSumAvg
	PUSH	OFFSET sumAndAvg
	PUSH	OFFSET display2
	PUSH	OFFSET display3
	PUSH	sumAvgSize
	CALL	writeVal											; call writeVal to convert Sum and Avg to strings and display

	PUSH	OFFSET farewell
	CALL	sayGoodbye

	Invoke ExitProcess,0										; exit to operating system
main ENDP

; -- introduction -----------------------------------------------------------------------------------------------
; Procedure to introduce the program to the user
; preconditions: intro1 is a string that introduces the programmer and describes the program. 
; postconditions: NA, all registers and contents preserved
; receives: [ebp+8] = intro1
; returns: NA (introductions printed on the console)
; ---------------------------------------------------------------------------------------------------------------
introduction PROC
	PUSH    ebp
	MOV     ebp,esp
	PUSHAD
	MOV		edx, [ebp+8]
	CALL	Writestring
	
	POPAD
	POP		ebp
	RET		4
introduction ENDP

; -- readVal ---------------------------------------------------------------------------------------------------
; Gets a string from the user, converts it to an integer and stores it in an array. 
; preconditions: intArray is an array with 10 spots, passed on the stack, Globals CONVERSION, ASCIIHI and 
;				ASCIILO have been defined, mGetString macro has been defined
; postconditions: integers entered into intArray, all registers returned to pre-existing state
; receives: [ebp+32] = intArray
;			[ebp+28] = plusSign (ASCII value)
;			[ebp+24] = negSign (ASCII value)
;			[ebp+20] = prompt1 (to get string)
;			[ebp+16] = sLen (records string length)
;			[ebp+12] = storedStr
;			[ebp+8]  = errormsg
; returns: intArray filled with all converted integers
; ---------------------------------------------------------------------------------------------------------------
readVal PROC
	PUSH	ebp
	MOV		ebp, esp
	PUSHAD
	PUSH	ecx
	_getString:
	;------------------------------------------------------------------------------------------------------------
	; Calls mGetString maco, then initializes registers to iterate through the string and convert it to an integer
	; if the length of the string 0, displays an error
	;------------------------------------------------------------------------------------------------------------
		mGetString [ebp+20], [ebp+12]

		MOV		[ebp+16], eax								; copy value in eax to sLen location in memory
		MOV		esi, [ebp+12]								; move address of string into esi
													
		CLD													; clear direction flag
		MOV		edx, 0
		MOV		eax, 0
		MOV		ebx, 1										; starting value for ebx assumes positive int
		MOV		ecx, [ebp+16]								; use sLen as counter for calculateInt loop
		CMP		ecx, 0
		JE		_displayError								; if input is empty (len = 0), display error
		_calculateInt:
		;------------------------------------------------------------------------------------------------------------
		; Loads a byte into the accumulator. IF it is the first byte in the string, checks if it has a sign, if not
		; continues to actual conversion
		;------------------------------------------------------------------------------------------------------------
			CMP		ecx, 0
			JE		_finishCalc
			LODSB											; load byte into accumulator 
			CMP		edx, 0
			JE		_checkSign
			JMP		_continue

			_checkSign:
			;------------------------------------------------------------------------------------------------------------
			; Checks the first byte to see if it is a negative or positive number (if a sign was included). If the sign
			; is negative, moves -1 into ebx register. If the sign was entered in the wrong position or did not accompany
			; a number, displays an error
			;------------------------------------------------------------------------------------------------------------
				CMP		al, [ebp+24]						; see if it equals the negative sign
				JE		_negativeNumber
				CMP		al, [ebp+28]						; see if it equals + sign
				JE		_positiveNumber								
				JMP		_continue

				_negativeNumber:
					CMP		ecx, [ebp+16]						; if negative sign does not occur on first iteration, it is an error
					JL		_displayError						; this is for the edge case that someone enters --5 or -+7, etc.
					CMP		ecx, 1
					JE		_displayError
					MOV		ebx, -1								; ebx used to hold sign value
					DEC		ecx
					JMP		_calculateInt

				_positiveNumber:
					CMP		ecx, [ebp+16]
					JL		_displayError
					CMP		ecx, 1								; if ecx is 1, user entered + without a number attached. This is invalid
					JE		_displayError
					dec		ecx
					JMP		_calculateInt
		
		_continue:
		;------------------------------------------------------------------------------------------------------------
		; Verifies input by comparing it to upper and lower bounds of ASCII values that match single numeric digits. 
		; if invalid, displays an error. If valid, converts the ASCII digit to it's numeric value and adds it to edx,
		; then jumps back to _calculateInt to load the next byte
		;------------------------------------------------------------------------------------------------------------
			IMUL	edx, CONVERSION
			JO		_displayError
			CMP		eax, ASCIIHI
			JG		_displayError
			CMP		eax, ASCIILOW
			JL		_displayError

			SUB		al, ASCIILOW							; convert to numerical value, resulted stored in eax
			ADD		edx, eax
			JO		_displayError							; if overflow, display error

			DEC		ecx
			JMP		_calculateInt

		_displayError:
			MOV		edx, [ebp+8]
			CALL	WriteString								; show error message, then jump back to the top to get a new string
			JMP		_getString
		
		_finishCalc:
		;------------------------------------------------------------------------------------------------------------
		; Once all bytes have been calculated and final numeric value is in edx, value is multiplied by edx to add the 
		; sign value. 
		;------------------------------------------------------------------------------------------------------------
			IMUL	edx, ebx								; add sign through multiplication with ebx

			MOV		edi, [ebp+32]							; load address of intArray into edi
			POP		ecx
			MOV		eax, ecx								; use ecx counter to find the right location in intArray to store calculated int

			IMUL	eax, 4									
			ADD		edi, eax								; Use register indirect to increment edi, then place edx value in edi
			MOV		[edi], edx
	
	MOV		edi, [ebp+12]									; clear value in storedStr back to 0
	MOV		eax, 0
	MOV		[edi], eax

	POPAD
	POP		ebp
	RET		28
readVaL	ENDP

; -- writeVal ---------------------------------------------------------------------------------------------------
; Takes an array of integers, converts them back to string, and displays them through the mDisplayString MACRO 
; preconditions: array of integers is passed on the stack along with necessary prompts and string formatting. 
; postconditions: NA, converted strings are printed and intArray is not changed. 
; receives: [ebp+32] = storedByte array
;			[ebp+28] = strSign (used to temporarily keep track of sign value)
;			[ebp+24] = empty array of strings
;			[ebp+20] = integer array (name varies)
;			[ebp+16] = display/prompt 1
;			[ebp+12] = display/punctionation 1
;			[ebp+8]  = array size
; returns: prints converted strings, strArray filled with reversed strings
; ---------------------------------------------------------------------------------------------------------------
writeVal PROC
	PUSH	ebp
	MOV		ebp, esp
	PUSHAD

	MOV		edx, [ebp+16]
	CALL	CrLf
	CALL	WriteString

	MOV		edi, [ebp+20]									; intArray
	MOV		ecx, 0											; use ecx as a counter
	
	_initialLoop:
	;------------------------------------------------------------------------------------------------------------
	; Moves an integer into eax (using ecx to find position) to be converted, then sets ecx to 0 to use as a counter
	;------------------------------------------------------------------------------------------------------------
		MOV		eax, [edi]
		PUSH	edi
		MOV		edi, [ebp+24]								; empty string array							
		
		MOV		edx, ecx
		IMUL	edx, 4
		ADD		edi, edx									; find location in string array

		PUSH	ecx
		MOV		ecx, 0

		_convertToString:
		;------------------------------------------------------------------------------------------------------------
		; Divides integer by 10, then adds 48 to the remainder to get the ASCII value, stores in the empty string
		; array location pointed to by edi
		;------------------------------------------------------------------------------------------------------------
			MOV		ebx, CONVERSION								; 10 = divisor for string conversion
			CDQ
			CMP		edx, UNSIGNEDREGMAX							; if edx = FFFFFFFF, integer is negative, jump to negative conversion 
			JE		_negativeConversion
			DIV		ebx

			ADD		edx, ASCIILOW								; add 48 to remainder
			PUSH	eax
			MOV		eax, edx

			STOSB												; store in strArray, increment counter
			INC		ecx
			POP		eax
			CMP		eax, 0
			JE		_printString
			JMP		_convertToString
	
			_negativeConversion:
			;------------------------------------------------------------------------------------------------------------
			; If integer sign is negative, multiply eax by -1 so that integer appears positive for conversion, then 
			; move 45 (ASCII - sign) into strSign (passed by reference on the stack)
			;------------------------------------------------------------------------------------------------------------
				IMUL	eax, -1
				PUSH	eax
				MOV		eax, 45
				MOV		[ebp+28], eax
				POP		eax
				INC		ecx
				JMP		_convertToString

	_printString:
	;------------------------------------------------------------------------------------------------------------
	; Checks if integer is negative, if so, stores the ASCII digits for - sign at the back of the string. 
	; the string stored in strArray is backwards. The string is reversed, with each byte being stored in the 
	; storedByte array. mDisplayString MACRO is used to print the string after reversal. 
	;------------------------------------------------------------------------------------------------------------
		MOV		eax, [ebp+28]
		CMP		eax, 45
		JNE		_callmDisplay
		STOSB
		MOV		eax, 0
		MOV		[ebp+28], eax									; reset sign indicator

		_callmDisplay:
			SUB		edi, ecx									; find the "end" of the string
			MOV		esi, edi
			ADD		esi, ecx
			DEC		esi
			MOV		edi, [ebp+32]								; move storedByte array into edi
	
			_revLoop:											; loop to reverse the string and store in byteArray
				STD
				LODSB
				CLD
				STOSB
			  LOOP   _revLoop

			MOV		eax, 0										; store a zero to null terminate
			STOSB
			mDisplayString [ebp+32]

	_nextString:
	;------------------------------------------------------------------------------------------------------------
	; Increment to the next integer in intArray and repeat the process of converting to string and printing
	; once ecx equals the length, stop the loop
	;------------------------------------------------------------------------------------------------------------
		POP		ecx
		INC		ecx
		CMP		ecx, [ebp+8]
		JE		_finishStrings

		POP		edi
		ADD		edi, 4
		MOV		edx, [ebp+12]
		CALL	WriteString

		JMP		_initialLoop

	_finishStrings:
		POP		edi
		POPAD
		POP		ebp
		RET		28
writeVal ENDP

; -- calcSumAvg ----------------------------------------------------------------------------------------------
; Calculates the sum of all values entered and the average (rounded down), stores these in sumAndAvg array
; preconditions: intArray contains signed integer values for all values entered by the user, sumAndAvg array
;				is an initialized empty array passed on the stack. Also uses global constant TOTALNUM, which is 
;				the total number of integers provided by the user.
; postconditions: All registers are restored. Values entered in sumAndAvg array as signed integers
; receives: [ebp+12] = intArray
;			[ebp+8] = sumAndAvg array
; returns: returns sumAndAvg array with index 0 containing the sum of integers, and index 1 containing the average
; --------------------------------------------------------------------------------------------------------------
calcSumAvg PROC
	PUSH	ebp
	MOV		ebp, esp
	PUSHAD
	
	MOV		edi, [ebp+12]								; Move intArray into edi to that we can iterate through it
	MOV		eax, 0
	MOV		ecx, TOTALNUM								; use ecx as counter

	_calcSumLoop:
	;-----------------------------------------------------------------------------------------------------------
	; Add each consecutive integer in the intArray to EAX so that it contains the running total
	;-----------------------------------------------------------------------------------------------------------
		CMP		ecx, 0
		JE		_finishCalc
		ADD		eax, [edi]
		ADD		edi, 4
		DEC		ecx
		JMP		_calcSumLoop

	_finishCalc:
	;-----------------------------------------------------------------------------------------------------------
	; Move the sum in eax into the first location in the sumAndAvg array, then divide by 10 to calculate the average
	; and store the average in the second location in the array. 
	;-----------------------------------------------------------------------------------------------------------
		MOV		edi, [ebp+8]
		MOV		[edi], eax
		ADD		edi, 4

		CDQ
		MOV		ebx, TOTALNUM							; divide by 10
		IDIV	ebx
		MOV		[edi], eax								; store calculated average

	POPAD
	POP		ebp
	RET		8
calcSumAvg ENDP

; -- sayGoodbye ------------------------------------------------------------------------------------------------
; Procedure to indicate the end of the program and say goodbye to the user
; preconditions: farewell1 is a string passed on the stack
; postconditions: NA, all registers restored
; receives: [ebp+8] = farewell
; returns: NA (prints farewell onto the console)
; --------------------------------------------------------------------------------------------------------------
sayGoodbye PROC
	PUSH	ebp
	MOV		ebp, esp
	PUSHAD
	MOV		edx, [ebp+8]
	CALL	CrLf
	CALL	CrLf
	CALL	WriteString

	POPAD
	POP		ebp
	RET		4
sayGoodbye ENDP

END main


