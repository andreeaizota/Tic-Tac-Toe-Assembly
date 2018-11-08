.386
.model flat, stdcall
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;includem biblioteci, si declaram ce functii vrem sa importam
includelib msvcrt.lib
extern exit: proc
extern malloc: proc
extern memset: proc

includelib canvas.lib
extern BeginDrawing: proc
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;declaram simbolul start ca public - de acolo incepe executia
public start
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;sectiunile programului, date, respectiv cod
.data
;aici declaram date
window_title DB "Tic Tac Toe",0
area_width EQU 400
area_height EQU 500
area DD 0 ;pointer la matricea de pixeli

arg1 EQU 8
arg2 EQU 12
arg3 EQU 16
arg4 EQU 20

x DD 0
y DD 0

click_count_on_table DD 0
X_sau_0 DD 9 dup(0) ;va contine 1 pe pozitiile pe care se pune x si 2 pe pozitiile pe care se pune 0

symbol_width EQU 10
symbol_height EQU 20
include digits.inc
include letters.inc

.code
; procedura make_text afiseaza o litera sau o cifra la coordonatele date
; arg1 - simbolul de afisat (litera sau cifra)
; arg2 - pointer la vectorul de pixeli
; arg3 - pos_x
; arg4 - pos_y
make_text proc
	push ebp
	mov ebp, esp
	pusha
	
	mov eax, [ebp+arg1] ; citim simbolul de afisat
	cmp eax, 'A'
	jl make_digit
	cmp eax, 'Z'
	jg make_digit
	sub eax, 'A'
	lea esi, letters
	jmp draw_text
make_digit:
	cmp eax, '0'
	jl make_space
	cmp eax, '9'
	jg make_space
	sub eax, '0'
	lea esi, digits
	jmp draw_text
make_space:	
	mov eax, 26 ; de la 0 pana la 25 sunt litere, 26 e space
	lea esi, letters
	
draw_text:
	mov ebx, symbol_width
	mul ebx
	mov ebx, symbol_height
	mul ebx
	add esi, eax
	mov ecx, symbol_height
bucla_simbol_linii:
	mov edi, [ebp+arg2] ; pointer la matricea de pixeli
	mov eax, [ebp+arg4] ; pointer la coord y
	add eax, symbol_height
	sub eax, ecx
	mov ebx, area_width
	mul ebx
	add eax, [ebp+arg3] ; pointer la coord x
	shl eax, 2 ; inmultim cu 4, avem un DWORD per pixel
	add edi, eax
	push ecx
	mov ecx, symbol_width
bucla_simbol_coloane:
	cmp byte ptr [esi], 0
	je simbol_pixel_alb
	mov dword ptr [edi], 0
	jmp simbol_pixel_next
simbol_pixel_alb:
	mov dword ptr [edi], 0FFFFFFh
simbol_pixel_next:
	inc esi
	add edi, 4
	loop bucla_simbol_coloane
	pop ecx
	loop bucla_simbol_linii
	popa
	mov esp, ebp
	pop ebp
	ret
make_text endp

; un macro ca sa apelam mai usor desenarea simbolului
make_text_macro macro symbol, x, y
	push y
	push x
	push area
	push symbol
	call make_text
	add esp, 16
endm

macro_linie_verticala macro x,y,lungime,culoare
	LOCAL repeta
	pusha
	mov ecx,lungime
	mov esi,x
	mov edi,y
	mov ebx,area
	repeta: 
		mov eax,area_width
		mul esi
		add eax,edi
		mov dword ptr [ebx+eax*4],culoare
		inc esi
	loop repeta
	popa 
endm

macro_linie_orizontala macro x,y,lungime,culoare
	LOCAL repeta
	pusha
	mov ecx,lungime
	mov esi,x
	mov edi,y
	mov ebx,area
	repeta: 
		mov eax,area_width
		mul esi
		add eax,edi
		mov dword ptr [ebx+eax*4],culoare
		inc edi
	loop repeta
	popa 
endm

macro_linie_oblica1 macro x,y,lungime
	LOCAL repeta
	pusha
	mov ecx,lungime
	mov esi,x
	mov edi,y
	mov ebx,area
	repeta: 
		mov eax,area_width
		mul esi
		add eax,edi
		mov dword ptr [ebx+eax*4],00FFh
		inc edi
		inc esi
	loop repeta
	popa 
endm

macro_linie_oblica2 macro x,y,lungime
	LOCAL repeta
	pusha
	mov ecx,lungime
	mov esi,x
	mov edi,y
	mov ebx,area
	repeta: 
		mov eax,area_width
		mul esi
		add eax,edi
		mov dword ptr [ebx+eax*4],00FFh
		dec edi
		inc esi
	loop repeta
	popa 
endm

play_again_macro macro
	make_text_macro 'P',160,420
	make_text_macro 'L',170,420
	make_text_macro 'A',180,420
	make_text_macro 'Y',190,420
	make_text_macro ' ',200,420
	make_text_macro 'A',210,420
	make_text_macro 'G',220,420
	make_text_macro 'A',230,420
	make_text_macro 'I',240,420
	make_text_macro 'N',250,420
	macro_linie_orizontala 410,150,120,0
	macro_linie_orizontala 450,150,120,0
	macro_linie_verticala 410,150,40,0
	macro_linie_verticala 410,270,40,0
endm

turn proc
	push ebp
	mov ebp,esp
	
	push eax
	push ebx
	xor edx,edx
	mov eax,[ebp+arg1]
	mov ebx,2
	div ebx
	pop ebx
	pop eax
	
	mov esp,ebp
	pop ebp
	ret
turn endp

verificare_castigator proc
	push ebp
	mov ebp,esp
	push eax
	push ebx
	
caz1: 
	mov eax,[ebp+8]
	mov ebx,[ebp+12]
	cmp eax,ebx
	jne caz2
	mov eax,[ebp+16]
	cmp eax,ebx
	jne caz2
	cmp eax,2
	je O_castiga
	cmp eax,1
	je X_castiga
	
caz2: 
	mov eax,[ebp+20]
	mov ebx,[ebp+24]
	cmp eax,ebx
	jne caz3
	mov eax,[ebp+28]
	cmp eax,ebx
	jne caz3
	cmp eax,2
	je O_castiga
	cmp eax,1
	je X_castiga
	
caz3: 
	mov eax,[ebp+32]
	mov ebx,[ebp+36]
	cmp eax,ebx
	jne caz4
	mov eax,[ebp+40]
	cmp eax,ebx
	jne caz4
	cmp eax,2
	je O_castiga
	cmp eax,1
	je X_castiga
	
caz4: 
	mov eax,[ebp+8]
	mov ebx,[ebp+20]
	cmp eax,ebx
	jne caz5
	mov ebx,[ebp+32]
	cmp eax,ebx
	jne caz5
	cmp eax,2
	je O_castiga
	cmp eax,1
	je X_castiga
	
caz5: 
	mov eax,[ebp+12]
	mov ebx,[ebp+24]
	cmp eax,ebx
	jne caz6
	mov eax,[ebp+36]
	cmp eax,ebx
	jne caz6
	cmp eax,2
	je O_castiga
	cmp eax,1
	je X_castiga
	
caz6: 
	mov eax,[ebp+16]
	mov ebx,[ebp+28]
	cmp eax,ebx
	jne caz7
	mov eax,[ebp+40]
	cmp eax,ebx
	jne caz7
	cmp eax,2
	je O_castiga
	cmp eax,1
	je X_castiga
	
caz7: 
	mov eax,[ebp+8]
	mov ebx,[ebp+24]
	cmp eax,ebx
	jne caz8
	mov eax,[ebp+40]
	cmp eax,ebx
	jne caz8
	cmp eax,2
	je O_castiga
	cmp eax,1
	je X_castiga
	
caz8: 
	mov eax,[ebp+16]
	mov ebx,[ebp+24]
	cmp eax,ebx
	jne egalitate
	mov eax,[ebp+32]
	cmp eax,ebx
	jne egalitate
	cmp eax,2
	je O_castiga
	cmp eax,1
	je X_castiga
	jmp final
	
egalitate: 
	mov ebx,10
repeta: 
	mov eax,[ebp+ebx*4]
	cmp eax,0
	je final
	dec ebx
	cmp ebx,1
	jne repeta
	mov ecx,-1
	jmp final
X_castiga: mov ecx,1
	jmp final
O_castiga: mov ecx,2
final: pop eax
	pop eax
	mov esp,ebp
	pop ebp
	ret
verificare_castigator endp

macro_verificare_castigator macro
	push X_sau_0[32] ;ebp+40
	push X_sau_0[28] ;ebp+36
	push X_sau_0[24] ;ebp+32
	push X_sau_0[20] ;ebp+28
	push X_sau_0[16] ;ebp+24
	push X_sau_0[12] ;ebp+20
	push X_sau_0[8] ;ebp+16
	push X_sau_0[4] ;ebp+12
	push X_sau_0[0] ;ebp+8
	call verificare_castigator
	add esp,36
endm

macro_clear macro
	LOCAL golire
	pusha
	mov eax, area_width
	mov ebx, area_height
	mul ebx
	shl eax, 2
	push eax
	push 255
	push area
	call memset
	add esp, 12
	
	macro_linie_verticala 0,150,300,0h
	macro_linie_verticala 0,250,300,0h
	macro_linie_orizontala 100,50,300,0h
	macro_linie_orizontala 200,50,300,0h
	
	mov click_count_on_table,0
	
	mov ecx,8
	golire: mov edx,0
	mov X_sau_0[ecx*4],edx
	dec ecx
	cmp ecx,-1
	jne golire
	popa
endm

; functia de desenare - se apeleaza la fiecare click
; sau la fiecare interval de 200ms in care nu s-a dat click
; arg1 - evt (0 - initializare, 1 - click, 2 - s-a scurs intervalul fara click)
; arg2 - x
; arg3 - y
draw proc
	push ebp
	mov ebp, esp
	pusha
	
	mov eax, [ebp+arg1]
	cmp eax, 1
	jz evt_click
	cmp eax,2
	jz evt_timer
	;mai jos e codul care intializeaza fereastra cu pixeli albi
	mov eax, area_width
	mov ebx, area_height
	mul ebx
	shl eax, 2
	push eax
	push 255
	push area
	call memset
	add esp, 12
	
evt_click:
	mov eax,[ebp+arg2]
	mov x,eax
	mov eax,[ebp+arg3]
	mov y,eax
	cmp x,50 ;testam daca se da click in interiorul jocului sau in exterior
	jl final_draw
	cmp x,350
	jg final_draw
	cmp y,300
	jg final_draw

	push click_count_on_table
	call turn
	add esp,4
	
	cmp edx,0
	jne O_turn
	
X_turn:
	mov edx,1
test0:
	cmp y,100
	jg test1
	cmp x,150
	jg test1
	
	cmp X_sau_0[0],0
	jne final_draw

	mov X_sau_0[0],edx
	jmp X_pozitia_0
test1: 
	cmp y,100
	jg test2
	cmp x,250
	jg test2
	
	cmp X_sau_0[4],0
	jne final_draw
	
	mov X_sau_0[4],edx
	jmp X_pozitia_1
test2: 
	cmp y,100
	jg test3
	cmp x,350
	jg test3
	
	cmp X_sau_0[8],0
	jne final_draw
	
	mov X_sau_0[8],edx
	jmp X_pozitia_2
test3: 
	cmp y,200
	jg test4
	cmp x,150
	jg test4
	
	cmp X_sau_0[12],0
	jne final_draw
	
	mov X_sau_0[12],edx
	jmp X_pozitia_3
test4: 
	cmp y,200
	jg test5
	cmp x,250
	jg test5
	
	cmp X_sau_0[16],0
	jne final_draw
	
	mov X_sau_0[16],edx
	jmp X_pozitia_4
test5: 
	cmp y,200
	jg test6
	cmp x,350
	jg test6
	
	cmp X_sau_0[20],0
	jne final_draw
	
	mov X_sau_0[20],edx
	jmp X_pozitia_5
test6: 
	cmp y,300
	jg test7
	cmp x,150
	jg test7
	
	cmp X_sau_0[24],0
	jne final_draw
	
	mov X_sau_0[24],edx
	jmp X_pozitia_6
test7: 
	cmp y,300
	jg test8
	cmp x,250
	jg test8
	
	cmp X_sau_0[28],0
	jne final_draw
	
	mov X_sau_0[28],edx
	jmp X_pozitia_7
test8: 
	cmp y,300
	jg final_draw
	cmp x,350
	jg final_draw
	
	cmp X_sau_0[32],0
	jne final_draw
	
	mov X_sau_0[32],edx
	jmp X_pozitia_8	
	
	jmp final_draw
	
O_turn:
	mov edx,2
test00:
	cmp y,100
	jg test11
	cmp x,150
	jg test11
	
	cmp X_sau_0[0],0
	jne final_draw
	
	mov X_sau_0[0],edx
	jmp O_pozitia_0
test11: 
	cmp y,100
	jg test22
	cmp x,250
	jg test22
	
	cmp X_sau_0[4],0
	jne final_draw
	
	mov X_sau_0[4],edx
	jmp O_pozitia_1
test22: 
	cmp y,100
	jg test33
	cmp x,350
	jg test33
	
	cmp X_sau_0[8],0
	jne final_draw
	
	mov X_sau_0[8],edx
	jmp O_pozitia_2
test33: 
	cmp y,200
	jg test44
	cmp x,150
	jg test44
	
	cmp X_sau_0[12],0
	jne final_draw
	
	mov X_sau_0[12],edx
	jmp O_pozitia_3
test44: 
	cmp y,200
	jg test55
	cmp x,250
	jg test55
	
	cmp X_sau_0[16],0
	jne final_draw
	
	mov X_sau_0[16],edx
	jmp O_pozitia_4
test55: 
	cmp y,200
	jg test66
	cmp x,350
	jg test66
	
	cmp X_sau_0[20],0
	jne final_draw
	
	mov X_sau_0[20],edx
	jmp O_pozitia_5
test66: 
	cmp y,300
	jg test77
	cmp x,150
	jg test77
	
	cmp X_sau_0[24],0
	jne final_draw
	
	mov X_sau_0[24],edx
	jmp O_pozitia_6
test77: 
	cmp y,300
	jg test88
	cmp x,250
	jg test88
	
	cmp X_sau_0[28],0
	jne final_draw
	
	mov X_sau_0[28],edx
	jmp O_pozitia_7
test88: 
	cmp y,300
	jg final_draw
	cmp x,350
	jg final_draw
	
	cmp X_sau_0[32],0
	jne final_draw
	
	mov X_sau_0[32],edx
	jmp O_pozitia_8	
	
X_pozitia_0:
	inc click_count_on_table
	macro_linie_oblica1 10,60,80
	macro_linie_oblica2 10,140,80
	jmp final_draw
	
X_pozitia_1: 
	inc click_count_on_table
	macro_linie_oblica1 10,160,80
	macro_linie_oblica2 10,240,80
	jmp final_draw
	
X_pozitia_2: 
	inc click_count_on_table
	macro_linie_oblica1 10,260,80
	macro_linie_oblica2 10,340,80
	jmp final_draw
	
X_pozitia_3: 
	inc click_count_on_table
	macro_linie_oblica1 110,60,80
	macro_linie_oblica2 110,140,80
	jmp final_draw
	
X_pozitia_4: 
	inc click_count_on_table
	macro_linie_oblica1 110,160,80
	macro_linie_oblica2 110,240,80
	jmp final_draw
	
X_pozitia_5: 
	inc click_count_on_table
	macro_linie_oblica1 110,260,80
	macro_linie_oblica2 110,340,80
	jmp final_draw
	
X_pozitia_6: 
	inc click_count_on_table
	macro_linie_oblica1 210,60,80
	macro_linie_oblica2 210,140,80
	jmp final_draw
	
X_pozitia_7: 
	inc click_count_on_table
	macro_linie_oblica1 210,160,80
	macro_linie_oblica2 210,240,80
	jmp final_draw
	
X_pozitia_8: 
	inc click_count_on_table
	macro_linie_oblica1 210,260,80
	macro_linie_oblica2 210,340,80
	jmp final_draw
	
O_pozitia_0:
	inc click_count_on_table
	macro_linie_orizontala 10,75,50,0f44242h
	macro_linie_orizontala 90,75,50,0f44242h
	macro_linie_verticala 15,75,70,0f44242h
	macro_linie_verticala 15,125,70,0f44242h
	jmp final_draw
	
O_pozitia_1:
	inc click_count_on_table
	macro_linie_orizontala 10,175,50,0f44242h
	macro_linie_orizontala 90,175,50,0f44242h
	macro_linie_verticala 15,175,70,0f44242h
	macro_linie_verticala 15,225,70,0f44242h
	jmp final_draw
	
O_pozitia_2:
	inc click_count_on_table
	macro_linie_orizontala 10,275,50,0f44242h
	macro_linie_orizontala 90,275,50,0f44242h
	macro_linie_verticala 15,275,70,0f44242h
	macro_linie_verticala 15,325,70,0f44242h
	jmp final_draw
	
O_pozitia_3:
	inc click_count_on_table
	macro_linie_orizontala 110,75,50,0f44242h
	macro_linie_orizontala 190,75,50,0f44242h
	macro_linie_verticala 115,75,70,0f44242h
	macro_linie_verticala 115,125,70,0f44242h
	jmp final_draw
	
O_pozitia_4:
	inc click_count_on_table
	macro_linie_orizontala 110,175,50,0f44242h
	macro_linie_orizontala 190,175,50,0f44242h
	macro_linie_verticala 115,175,70,0f44242h
	macro_linie_verticala 115,225,70,0f44242h
	jmp final_draw
	
O_pozitia_5:
	inc click_count_on_table
	macro_linie_orizontala 110,275,50,0f44242h
	macro_linie_orizontala 190,275,50,0f44242h
	macro_linie_verticala 115,275,70,0f44242h
	macro_linie_verticala 115,325,70,0f44242h
	jmp final_draw
	
O_pozitia_6:
	inc click_count_on_table
	macro_linie_orizontala 210,75,50,0f44242h
	macro_linie_orizontala 290,75,50,0f44242h
	macro_linie_verticala 215,75,70,0f44242h
	macro_linie_verticala 215,125,70,0f44242h
	jmp final_draw
	
O_pozitia_7:
	inc click_count_on_table
	macro_linie_orizontala 210,175,50,0f44242h
	macro_linie_orizontala 290,175,50,0f44242h
	macro_linie_verticala 215,175,70,0f44242h
	macro_linie_verticala 215,225,70,0f44242h
	jmp final_draw
	
O_pozitia_8:
	inc click_count_on_table
	macro_linie_orizontala 210,275,50,0f44242h
	macro_linie_orizontala 290,275,50,0f44242h
	macro_linie_verticala 215,275,70,0f44242h
	macro_linie_verticala 215,325,70,0f44242h
	jmp final_draw
	
evt_timer:	

final_draw:
	macro_linie_verticala 0,150,300,0h
	macro_linie_verticala 0,250,300,0h
	macro_linie_orizontala 100,50,300,0h
	macro_linie_orizontala 200,50,300,0h
	
final:
	macro_verificare_castigator 
	cmp ecx,1
	je castiga_x
	cmp ecx,2
	je castiga_0
	cmp ecx,-1
	je egalitate
	jmp iesi

castiga_x: 
	make_text_macro 'X',180,350
	make_text_macro ' ',190,350
	make_text_macro 'W',200,350
	make_text_macro 'O',210,350
	make_text_macro 'N',220,350
	make_text_macro 'C',130,380
	make_text_macro 'O',140,380
	make_text_macro 'N',150,380
	make_text_macro 'G',160,380
	make_text_macro 'R',170,380
	make_text_macro 'A',180,380
	make_text_macro 'T',190,380
	make_text_macro 'U',200,380
	make_text_macro 'L',210,380
	make_text_macro 'A',220,380
	make_text_macro 'T',230,380
	make_text_macro 'I',240,380
	make_text_macro 'O',250,380
	make_text_macro 'N',260,380
	make_text_macro 'S',270,380
	play_again_macro
	
	mov ecx,8
	pune_x: mov edx,1
	mov X_sau_0[ecx*4],edx
	dec ecx
	cmp ecx,-1
	jne pune_x
	
	mov eax,[ebp+arg2]
	mov x,eax
	mov eax,[ebp+arg3]
	mov y,eax
	cmp x,150
	jl iesi
	cmp x,270
	jg iesi
	cmp y,410
	jl iesi
	cmp y,450
	jg iesi
	macro_clear
	jmp iesi
	
castiga_0:
	make_text_macro '0',180,350
	make_text_macro ' ',190,350
	make_text_macro 'W',200,350
	make_text_macro 'O',210,350
	make_text_macro 'N',220,350
	make_text_macro 'C',130,380
	make_text_macro 'O',140,380
	make_text_macro 'N',150,380
	make_text_macro 'G',160,380
	make_text_macro 'R',170,380
	make_text_macro 'A',180,380
	make_text_macro 'T',190,380
	make_text_macro 'U',200,380
	make_text_macro 'L',210,380
	make_text_macro 'A',220,380
	make_text_macro 'T',230,380
	make_text_macro 'I',240,380
	make_text_macro 'O',250,380
	make_text_macro 'N',260,380
	make_text_macro 'S',270,380
	play_again_macro
	
	mov ecx,8
	pune_0: mov edx,2
	mov X_sau_0[ecx*4],edx
	dec ecx
	cmp ecx,-1
	jne pune_0
	
	mov eax,[ebp+arg2]
	mov x,eax
	mov eax,[ebp+arg3]
	mov y,eax
	cmp x,150
	jl iesi
	cmp x,270
	jg iesi
	cmp y,410
	jl iesi
	cmp y,450
	jg iesi
	macro_clear
	jmp iesi
	
egalitate:
	make_text_macro 'D',180,350
	make_text_macro 'R',190,350
	make_text_macro 'A',200,350
	make_text_macro 'W',210,350
	play_again_macro
	
	mov eax,[ebp+arg2]
	mov x,eax
	mov eax,[ebp+arg3]
	mov y,eax
	cmp x,150
	jl iesi
	cmp x,270
	jg iesi
	cmp y,410
	jl iesi
	cmp y,450
	jg iesi
	macro_clear	
	
iesi:
	popa
	mov esp, ebp
	pop ebp
	ret
draw endp

start:
	;alocam memorie pentru zona de desenat
	mov eax, area_width
	mov ebx, area_height
	mul ebx
	shl eax, 2
	push eax
	call malloc
	add esp, 4
	mov area, eax
	;apelam functia de desenare a ferestrei
	; typedef void (*DrawFunc)(int evt, int x, int y);
	; void __cdecl BeginDrawing(const char *title, int width, int height, unsigned int *area, DrawFunc draw);
	push offset draw
	push area
	push area_height
	push area_width
	push offset window_title
	call BeginDrawing
	add esp, 20
	
	;terminarea programului
	push 0
	call exit
end start
