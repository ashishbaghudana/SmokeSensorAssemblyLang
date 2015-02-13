.model tiny

.data
	portA	equ	0000h
	portB	equ 0002h
	portC	equ	0004h
	creg	equ	0006h
	
	cnt0	equ	0010h
	cnt1	equ	0012h
	cnt2	equ	0014h
	cntreg	equ	0016h
	
.code
.startup
	;initialize 8255
	mov al, 10010001b ; portA = input, portB = output, portC lower = input, portC upper = output
	out creg, al	
	
	mov al, 00000000b
	out portC, al

	
	;initialize 8253
	;initialize counter 0 in mode 0 with a count value of 500
	mov al, 00110000b
	out cntreg, al
	
	mov al, 15h
	out cnt0, al
	
	mov al, 00h
	out cnt0, al
	
	
	;reset the system initially; i.e. close all doors, windows and valves if open.
	mov al, 11010000b 	;enables the motors, rotates the motors in the clockwise direction, enables gate for clock0 for 500 clock pulses
	out portC, al
	
	
	mov dl, 00h
	
x1:	cmp dl, 00h 	;if dl = 00, doors, windows and valve are closed
	jnz x2			;if dl = 01, doors, windows and valve are open
	
	mov al, 00000000b
	out portB, al 	;send address 000 to ADC
	
	mov al, 01000000b
	out portB, al 	;send ALE signal to ADC
	
	mov al, 01100000b
	out portB, al 	;send start signal to ADC
	
	mov al, 01000000b
	out portB, al	;send low pulse on start on ADC
	
	
x3:	in al, portC	;polls for EOC signal
	and al, 01h
	cmp al, 01h
	jnz x3			;if EOC is low, loop back to x3, else proceed
	mov al, 00000000b
	out portB, al
	
	
	in al, portA	;since EOC is high, take the input from the ADC of smoke sensor 0
	out portB, al
	
	mov cl, 97h
	cmp al, cl		;compare al with an arbitrary value
	
	pushf
	pop bx
	and bx, 0080h
	cmp bx, 0000h
	jnz x1
	
	;jl x1			;if al < danger level, jump to x1
	
	mov bl, al		;transfer the value of al to bl register
	mov al, 00h
	
	mov al, 10000000b
	out portB, al 	;send address 001 to ADC
	
	mov al, 11000000b
	out portB, al 	;send ALE signal to ADC
	
	mov al, 11100000b
	out portB, al 	;send start signal to ADC
	
	mov al, 11000000b
	out portB, al	;send low pulse on start on ADC
	
	
x4:	in al, portC	;polls for EOC signal
	and al, 01h
	cmp al, 01h
	mov al, 00000000b
	out portB, al
	
	jnz x4			;if EOC is low, loop back to x4, else proceed
	
	mov al, 00h
	
	in al, portA	;since EOC is high, take input from ADC of smoke sensor 1
	in al, portA
	out portB, al
	
	mov cl, 97h
	cmp al, cl		;compare al with the arbitrary value
	
	pushf
	pop bx
	and bx, 0080h
	cmp bx, 0000h
	jnz x1
	
	mov al, 00000000b
	out portB, al
	mov al, 00110000b	;re-arm counter with a value of 500
	out cntreg, al
	
	mov al, 0fh
	out cnt0, al
	
	mov al, 00h
	out cnt0, al
	
	
	mov al, 10110000b
	out portC, al	;enable the motors, rotate them in the anticlockwise direction, turn on the buzzer and turn on gate0
	
	mov dl, 01h		;set state of doors, windows, valves as open (i.e. previously smoke has been detected)
	jmp x1

x2:	mov al, 00010000b
	out portB, al 	;send address 000 to ADC
	
	mov al, 01010000b
	out portB, al 	;send ALE signal to ADC
	
	mov al, 01110000b
	out portB, al 	;send start signal to ADC
	
	mov al, 01010000b
	out portB, al	;send low pulse on start on ADC
	
	
x5:	in al, portC	;polls for EOC signal
	and al, 01h
	cmp al, 01h
	jnz x5			;if EOC is low, loop back to x5, else proceed
	
	in al, portA	;since EOC is high, take the input from ADC of smoke sensor 0
	mov cl, 97h
	cmp al, cl		;compare al with an arbitrary value
	
	pushf
	pop bx
	and bx, 0080h
	cmp bx, 0000h
	jnz x7
	;jl x7			;if al <= danger level, jump to x7
	
	mov bl, al
	
	mov al, 10010000b
	out portB, al 	;send address 000 to ADC
	
	mov al, 11010000b
	out portB, al 	;send ALE signal to ADC
	
	mov al, 11110000b
	out portB, al 	;send start signal to ADC
	
	mov al, 11010000b
	out portB, al	;send low pulse on start on ADC
	
	
x6:	in al, portC	;polls for EOC signal
	and al, 01h
	cmp al, 01h
	jnz x6			;if EOC is low, loop back to x6, else proceed
	
	in al, portA	;since EOC is high, take input from ADC of smoke sensor 1
	
	mov cl, 97h
	cmp al, cl		;compare al with the arbitrary value
	
	pushf
	pop bx
	and bx, 0080h
	cmp bx, 0000h
	jnz x7
	;jl x7			;if al <= danger level, jump to x7
	
	jmp x1			;if al > danger level for both smoke sensors, jump to x1
	
x7:	mov al, 00110000b		;initialize counter0 in mode0
	out cntreg, al
	
	mov al, 11h			;set a value of 20 in counter0
	out cnt0, al
	
	mov al, 00h
	out cnt0, al
	
	
	mov al, 11010000b
	out portC, al	;close doors, windows and valve
	
	mov dl, 00h		;set previous state bit back to 0
	jmp x1			;continue polling from beginning again

.exit
end