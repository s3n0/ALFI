CODE    SEGMENT
        ASSUME cs:CODE,ds:CODE
;
	ORG	100h
;
START:	mov	ax,3
	int	10h		;video-mode === CLS
;
	mov	ah,9
	mov	dx,offset TXT
	int	21h
;
	call	RESET
;
KLV:	mov	ax,0C00h
	int	21h		;nulujem bufer keyboardu a (chybne) zavolam sub-sluzbu cislo 0
	in	al,60h		;citam scan-kod
;
	cmp	al,01h		;...ESC koniec
	jnz	H0
	call	RESET
	mov	ah,4Ch
	int	21h
;
H0:	cmp	al,72		;...sipka hore
	jnz	H1
	call	HORE
;
H1:	cmp	al,80		;...sipka dole
	jnz	H2
	call	DOLE
;
H2:	cmp	al,75		;...sipka vlavo
	jnz	H3
	call	VLAVO
;
H3:	cmp	al,77		;...sipka vpravo
	jnz	H4
	call	VPRAVO
;
H4:	cmp	al,4Ah		;...GREY- pisem
	jnz	H5
	call	MINUS
;
H5:	cmp	al,4Eh		;...GREY+ nepisem
	jnz	H6
	call	PLUS
;
H6:	jmp	KLV
;
;
;
;
;
;********************ZACIATOK-rutiniek-pre-riadenie************************
;
POC=7		;pocet taktov pre otacanie krokoveho motora
;ukazatele   =   0    1    2    3    4    5    6    7   =  register  DI  aj  SI
TAKT:	db	066H,077H,055H,0DDH,099H,0BBH,0AAH,0EEH
;TAKT:	db	088H,0AAH,022H,066H,044H,055H,011H,099H
;-je to vlastne 4-bitova hodnota pre riadenie styroch cievok v motori 1 alebo 2
; lenze pouzitie dvoch 4-bitovych kopii (jeden bajt) mi pomaha pri odoberani
; kodu najprv pre motor X (spodne 4 bity) a potom pre motor Y (horne 4 bity),
; pricom nemusim pouzit instrukciu pre posuvanie (rotaciu) bitov v registry CPU
;
;
;pre pero ZDVIHNI/SPUSTI sluzi len 1 bit (vstupno-vystupny) na inej adrese
;
MINUS:	add	dx,2
	mov	al,00000000b
	out	dx,al
	sub	dx,2
	ret
;
PLUS:	add	dx,2
	mov	al,00001000b
	out	dx,al
	sub	dx,2
	ret
;
;pre motor VLAVO/VPRAVO sluzia 4 bity na pravej strane bajtu
;
VLAVO:	mov	al,[bx+si]
	and	al,00Fh		;AL <= pozicia motora VLAVO/VPRAVO
	mov	ah,[bx+di]
	and	ah,0F0h		;do AH dam poziciu druheho motora
	or	al,ah
	out	dx,al
	inc	si
	cmp	si,POC+1	;IF si > POC THEN si = 0
	jnz	N1
	mov	si,0
N1:	call	PAUZx
	ret
;
VPRAVO:	mov	al,[bx+si]
	and	al,00Fh		;AL <= pozicia motora VLAVO/VPRAVO
	mov	ah,[bx+di]
	and	ah,0F0h		;do AH dam poziciu druheho motora
	or	al,ah
	out	dx,al
	dec	si
	cmp	si,-1		;IF si < 0 THEN si = POC
	jnz	N2
	mov	si,POC
N2:	call	PAUZx
	ret
;
;pre motor HORE/DOLE sluzia 4 bity na lavej strane bajtu
;
HORE:	mov	al,[bx+di]
	and	al,0F0h		;AL <= pozicia motora HORE/DOLE
	mov	ah,[bx+si]
	and	ah,00Fh		;do AH dam poziciu druheho motora
	or	al,ah
	out	dx,al
	inc	di
	cmp	di,POC+1	;IF di > POC THEN di =0
	jnz	N3
	mov	di,0
N3:	call	PAUZy
	ret
;
DOLE:	mov	al,[bx+di]
	and	al,0F0h		;AL <= pozicia motora HORE/DOLE
	mov	ah,[bx+si]
	and	ah,00Fh		;do AH dam poziciu druheho motora
	or	al,ah
	out	dx,al
	dec	di
 	cmp	di,-1		;IF di < 0 THEN di = POC
	jnz	N4
	mov	di,POC
N4:	call	PAUZy
	ret
;
;
;ako pauzovace su zrobene male rutiny zvlast pre os X, zvlast pre os Y
;su pouzite citace pametovych buniek casovaca, preto to nefunguje pod Windows95
;
;
PAUZx:	push	ax bx es
	mov	ax,0040h
	mov	es,ax
	mov	bx,006Ch
	xor	ax,ax
	mov	es:[bx],ax
	mov	ax,8000
CAKx:	cmp	ax,es:[bx]
	jc	CAKx
	pop	es bx ax
	ret
;
;
PAUZy:	push	ax bx es
	mov	ax,0040h
	mov	es,ax
	mov	bx,006Ch
	xor	ax,ax
	mov	es:[bx],ax
	mov	ax,5000
CAKy:	cmp	ax,es:[bx]
	jc	CAKy
	pop	es bx ax
	ret
;
;
RESET:	xor	ax,ax
	mov	si,ax		;SI=ukazatel 1. motora na tabulku
	mov	di,ax		;DI=ukazatel 2. motora na tabulku
	mov	dx,378h
	out	dx,al
	call	MINUS
	mov	bx,offset TAKT
	ret
;
;**********************KONIEC-rutiniek-pre-riadenie**************************
;
;
;
;
;
TXT:	db	10,13,'         -   ...nepisem'
	db	10,13,'         +   ...pisem'
	db	10,13,'     8       ...hore'
	db	10,13,'  4     6    ...vlavo/vpravo'
	db	10,13,'     2       ...dole'
	db	10,10,10,10,13,'ESC=koniec'
	db	"$"
;
;
CODE    ENDS
        END 	START
