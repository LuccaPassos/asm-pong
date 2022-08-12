; Lucca Passos Covre - Sistemas Embarcados I
; Turma 05.1  
;
segment code
..start:
    mov     ax, data
    mov     ds, ax
    mov     ax, stack
    mov     ss, ax
    mov     sp, stacktop

;   Salva o modo corrente de video

    mov     ah, 0Fh
    int     10h
    mov  	[modo_anterior], al

;   Alterar o modo de video para gráfico 640x480 e 16 cores
    
    mov     al, 12h
    mov     ah, 0
    int     10h
	call    constroi_interface	

animacao:
    mov     ah,0bh
    int     21h         ; Le buffer de teclado
    cmp     al,0        ; Se AL =0 nada foi digitado. Se AL =255 então há algum caracter na STDIN
    jne     adelante
    jmp     segue       ; se AL = 0 então nada foi digitado e a animação do jogo deve continuar

adelante:
    mov     ah, 08H     ; Ler caracter da STDIN
    int     21H
    cmp     al, 27      ; Verifica se foi Esc. Se foi, finaliza o programa
    jne     segue
    jmp     sai

segue:
    call    desenha_requete

    ; Apaga a bola
    mov		byte[cor], preto
    call    desenha_bola

    ; Incrementa a direção
    mov     ax, word[y_direcao]
    add     ax, word[y_bola]

    cmp     ax, [borda_superior]
    jge     eh_superior
    
    cmp     ax, [borda_inferior]
    jle     eh_inferior

    cmp     ax, [y_base_raquete]
    jl      avanca

    mov     bx, 50
    add     bx, [y_base_raquete]
    cmp     ax, bx
    jg      avanca

    call    checa_raquete

    avanca:

    mov     word[y_bola], ax

    continua_1:    

    mov     ax, word[x_direcao]
    add     ax, word[x_bola]
    
    cmp     ax, [borda_direita]
    jge     eh_direita
    
    cmp     ax, [borda_esquerda]
    jle     eh_esquerda
    
    mov     word[x_bola], ax

    continua_2:

    ; Desenha a bola
    mov		byte[cor], vermelho
    call    desenha_bola
    
    call    delay

    jmp     animacao

    eh_superior:
    mov     word[y_direcao], -1
    dec     word[y_bola]
    jmp     continua_1  
    
    eh_inferior:
    mov     word[y_direcao], 1
    inc     word[y_bola]
    jmp     continua_1

    eh_direita:
    mov     word[x_direcao], -1
    dec     word[x_bola]
    inc     byte[ponto_cpu]
    call    escreve_ponto_cpu
    jmp     continua_2  

    eh_esquerda:
    mov     word[x_direcao], 1
    inc     word[x_bola]
    jmp     continua_2 

checa_raquete:
    mov     bx, word[x_direcao]
    add     bx, word[x_bola]
    
    cmp     bx, 590 ; Descontando o diâmetro
    jne     volta
    mov     word[x_direcao], -1
    dec     word[x_bola]
    inc     byte[ponto_usuario]
    call    escreve_ponto_usuario
    
    volta:
    ret     

sai:
    mov  	ah,0    ; set video mode
    mov  	al,[modo_anterior]  ; modo anterior
    int  	10h
    mov     ax,4c00h
    int     21h


delay: ; Esteja atento pois talvez seja importante salvar contexto (no caso, CX, o que NÃO foi feito aqui).
    mov cx, word [velocidade] ; Carrega “velocidade” em cx (contador para loop)
    del2:
    push cx ; Coloca cx na pilha para usa-lo em outro loop
    mov cx, 0800h ; Teste modificando este valor
    del1:
    loop del1 ; No loop del1, cx é decrementado até que volte a ser zero
    pop cx ; Recupera cx da pilha
    loop del2 ; No loop del2, cx é decrementado até que seja zero
    ret

constroi_interface:

    ; Caixa
    mov		byte[cor], branco
    mov		ax, 0
    push	ax
    mov		ax, 479
    push	ax
    mov		ax, 640
    push	ax
    mov		ax, 479
    push	ax
    call	line

    mov		byte[cor], branco
    mov		ax, 0
    push	ax
    mov		ax, 0
    push	ax
    mov		ax, 640
    push	ax
    mov		ax, 0
    push	ax
    call	line

    mov		byte[cor], branco
    mov		ax, 0
    push	ax
    mov		ax, 0
    push	ax
    mov		ax, 0
    push	ax
    mov		ax, 479
    push	ax
    call	line

    mov		byte[cor], branco
    mov		ax, 639
    push	ax
    mov		ax, 0
    push	ax
    mov		ax, 639
    push	ax
    mov		ax, 480
    push	ax
    call	line


    ; Linha do cabeçalho
    mov		byte[cor], branco
    mov		ax, 0
    push	ax
    mov		ax, 420
    push	ax
    mov		ax, 640
    push	ax
    mov		ax, 420
    push	ax
    call	line

    call    escreve_cabecalho
    call    escreve_placar
    call    escreve_velocidade

    ret

desenha_requete:
    mov		byte[cor], branco_intenso
    mov		ax, 600 
    push	ax
    mov		ax, [y_base_raquete]
    push	ax
    mov		ax, 600
    push	ax

    mov		ax, [y_base_raquete]
    add     ax, 50
    push	ax
    call	line
    ret

; Limites:  10,     10 (inferior esquerdo)
;           10,     410 (superior esquerdo)
;           629,    410 (superior direito)
;           629,    10 (superior direito)
desenha_bola:
    mov		ax, [x_bola]
    push    ax
    mov		ax, [y_bola]
    push    ax
    mov		ax, 10 ; raio
    push    ax
    call    full_circle
    ret


escreve:
    call	cursor
    mov     al, [bx+cabecalho]
    call	caracter
    inc     bx			;proximo caracter
    inc		dl			;avanca a coluna
    loop    escreve
    ret

escreve_cabecalho:
    mov     cx, 58  ; Caracteres
    mov     bx, 0   ; Offset
    mov     dh, 1   ; Linha
    mov     dl, 10   ; Coluna
    call    escreve ; "Exercicio de Programacao de Sistemas Embarcados 1 - 2022/2"
    ret

escreve_placar:
    mov     cx, 37  ; Caracteres
    mov     bx, 58  ; Offset
    mov     dh, 2   ; Linha
    mov     dl, 5   ; Coluna
    call    escreve ; "Lucca Passos Covre 00 x 00 Computador"
    ret

escreve_velocidade:
    mov     cx, 19  ; Caracteres
    mov     bx, 95  ; Offset
    mov     dh, 2   ; Linha
    mov     dl, 55  ; Coluna
    call    escreve ; "Velocidade Atual: "
    ret

escreve_ponto_cpu:
    mov     dh, 2   ; Linha
    mov     dl, 29   ; Coluna
    mov		byte[cor], branco

    ; Calcula pontos
    mov		ax, 0
	mov		al, byte[ponto_cpu]
	mov		bl, 10
	div		bl
	add		al, '0'
	add		ah, '0'
    
    ; Imprime dezena
    call	cursor
    call	caracter
    
    ; Imprime unidade
    mov     dl, 30
    mov     al, ah
    call	cursor
    call	caracter

    ret

escreve_ponto_usuario:
    push    ax
    push    bx
    push    dx
    mov     dh, 2   ; Linha
    mov     dl, 24   ; Coluna
    mov		byte[cor], branco

    ; Calcula pontos
    mov		ax, 0
	mov		al, byte[ponto_usuario]
	mov		bl, 10
	div		bl
	add		al, '0'
	add		ah, '0'
    
    ; Imprime dezena
    call	cursor
    call	caracter
    
    ; Imprime unidade
    mov     dl, 25
    mov     al, ah
    call	cursor
    call	caracter
    pop     dx
    pop     bx
    pop     ax
    ret











;_________________________________________________________________________
;   Função cursor
;   dh = linha (0-29) e  dl=coluna  (0-79)
cursor:
    pushf
    push    ax
    push 	bx
    push	cx
    push	dx
    push	si
    push	di
    push    bp
    mov     ah, 2
    mov     bh, 0
    int     10h
    pop     bp
    pop     di
    pop		si
    pop		dx
    pop		cx
    pop		bx
    pop		ax
    popf
    ret

;_________________________________________________________________________
;   Função caracter escrito na posição do cursor
;   al= caracter a ser escrito
;   cor definida na variavel cor
caracter:
    pushf
    push    ax
    push 	bx
    push	cx
    push	dx
    push	si
    push	di
    push	bp
    mov     ah, 9
    mov     bh, 0
    mov     cx, 1
    mov     bl, [cor]
    int     10h
    pop		bp
    pop		di
    pop		si
    pop		dx
    pop		cx
    pop		bx
    pop		ax
    popf
    ret


;_____________________________________________________________________________
;
;   fun��o plot_xy
;
; push x; push y; call plot_xy;  (x<639, y<479)
; cor definida na variavel cor
plot_xy:
		push		bp
		mov		bp,sp
		pushf
		push 		ax
		push 		bx
		push		cx
		push		dx
		push		si
		push		di
	    mov     	ah,0ch
	    mov     	al,[cor]
	    mov     	bh,0
	    mov     	dx,479
		sub		dx,[bp+4]
	    mov     	cx,[bp+6]
	    int     	10h
		pop		di
		pop		si
		pop		dx
		pop		cx
		pop		bx
		pop		ax
		popf
		pop		bp
		ret		4

;-----------------------------------------------------------------------------
;    fun��o full_circle
;	 push xc; push yc; push r; call full_circle;  (xc+r<639,yc+r<479)e(xc-r>0,yc-r>0)
; cor definida na variavel cor					  
full_circle:
	push 	bp
	mov	 	bp,sp
	pushf                        ;coloca os flags na pilha
	push 	ax
	push 	bx
	push	cx
	push	dx
	push	si
	push	di

	mov		ax,[bp+8]    ; resgata xc
	mov		bx,[bp+6]    ; resgata yc
	mov		cx,[bp+4]    ; resgata r
	
	mov		si,bx
	sub		si,cx
	push    ax			;coloca xc na pilha			
	push	si			;coloca yc-r na pilha
	mov		si,bx
	add		si,cx
	push	ax		;coloca xc na pilha
	push	si		;coloca yc+r na pilha
	call line
	
		
	mov		di,cx
	sub		di,1	 ;di=r-1
	mov		dx,0  	;dx ser� a vari�vel x. cx � a variavel y
	
;aqui em cima a l�gica foi invertida, 1-r => r-1
;e as compara��es passaram a ser jl => jg, assim garante 
;valores positivos para d

stay_full:				;loop
	mov		si,di
	cmp		si,0
	jg		inf_full       ;caso d for menor que 0, seleciona pixel superior (n�o  salta)
	mov		si,dx		;o jl � importante porque trata-se de conta com sinal
	sal		si,1		;multiplica por doi (shift arithmetic left)
	add		si,3
	add		di,si     ;nesse ponto d=d+2*dx+3
	inc		dx		;incrementa dx
	jmp		plotar_full
inf_full:	
	mov		si,dx
	sub		si,cx  		;faz x - y (dx-cx), e salva em di 
	sal		si,1
	add		si,5
	add		di,si		;nesse ponto d=d+2*(dx-cx)+5
	inc		dx		;incrementa x (dx)
	dec		cx		;decrementa y (cx)
	
plotar_full:	
	mov		si,ax
	add		si,cx
	push	si		;coloca a abcisa y+xc na pilha			
	mov		si,bx
	sub		si,dx
	push    si		;coloca a ordenada yc-x na pilha
	mov		si,ax
	add		si,cx
	push	si		;coloca a abcisa y+xc na pilha	
	mov		si,bx
	add		si,dx
	push    si		;coloca a ordenada yc+x na pilha	
	call 	line
	
	mov		si,ax
	add		si,dx
	push	si		;coloca a abcisa xc+x na pilha			
	mov		si,bx
	sub		si,cx
	push    si		;coloca a ordenada yc-y na pilha
	mov		si,ax
	add		si,dx
	push	si		;coloca a abcisa xc+x na pilha	
	mov		si,bx
	add		si,cx
	push    si		;coloca a ordenada yc+y na pilha	
	call	line
	
	mov		si,ax
	sub		si,dx
	push	si		;coloca a abcisa xc-x na pilha			
	mov		si,bx
	sub		si,cx
	push    si		;coloca a ordenada yc-y na pilha
	mov		si,ax
	sub		si,dx
	push	si		;coloca a abcisa xc-x na pilha	
	mov		si,bx
	add		si,cx
	push    si		;coloca a ordenada yc+y na pilha	
	call	line
	
	mov		si,ax
	sub		si,cx
	push	si		;coloca a abcisa xc-y na pilha			
	mov		si,bx
	sub		si,dx
	push    si		;coloca a ordenada yc-x na pilha
	mov		si,ax
	sub		si,cx
	push	si		;coloca a abcisa xc-y na pilha	
	mov		si,bx
	add		si,dx
	push    si		;coloca a ordenada yc+x na pilha	
	call	line
	
	cmp		cx,dx
	jb		fim_full_circle  ;se cx (y) est� abaixo de dx (x), termina     
	jmp		stay_full		;se cx (y) est� acima de dx (x), continua no loop
	
	
fim_full_circle:
	pop		di
	pop		si
	pop		dx
	pop		cx
	pop		bx
	pop		ax
	popf
	pop		bp
	ret		6
;-----------------------------------------------------------------------------
;
;   fun��o line
;
; push x1; push y1; push x2; push y2; call line;  (x<639, y<479)
line:
		push		bp
		mov		bp,sp
		pushf                        ;coloca os flags na pilha
		push 		ax
		push 		bx
		push		cx
		push		dx
		push		si
		push		di
		mov		ax,[bp+10]   ; resgata os valores das coordenadas
		mov		bx,[bp+8]    ; resgata os valores das coordenadas
		mov		cx,[bp+6]    ; resgata os valores das coordenadas
		mov		dx,[bp+4]    ; resgata os valores das coordenadas
		cmp		ax,cx
		je		line2
		jb		line1
		xchg		ax,cx
		xchg		bx,dx
		jmp		line1
line2:		; deltax=0
		cmp		bx,dx  ;subtrai dx de bx
		jb		line3
		xchg		bx,dx        ;troca os valores de bx e dx entre eles
line3:	; dx > bx
		push		ax
		push		bx
		call 		plot_xy
		cmp		bx,dx
		jne		line31
		jmp		fim_line
line31:		inc		bx
		jmp		line3
;deltax <>0
line1:
; comparar m�dulos de deltax e deltay sabendo que cx>ax
	; cx > ax
		push		cx
		sub		cx,ax
		mov		[deltax],cx
		pop		cx
		push		dx
		sub		dx,bx
		ja		line32
		neg		dx
line32:		
		mov		[deltay],dx
		pop		dx

		push		ax
		mov		ax,[deltax]
		cmp		ax,[deltay]
		pop		ax
		jb		line5

	; cx > ax e deltax>deltay
		push		cx
		sub		cx,ax
		mov		[deltax],cx
		pop		cx
		push		dx
		sub		dx,bx
		mov		[deltay],dx
		pop		dx

		mov		si,ax
line4:
		push		ax
		push		dx
		push		si
		sub		si,ax	;(x-x1)
		mov		ax,[deltay]
		imul		si
		mov		si,[deltax]		;arredondar
		shr		si,1
; se numerador (DX)>0 soma se <0 subtrai
		cmp		dx,0
		jl		ar1
		add		ax,si
		adc		dx,0
		jmp		arc1
ar1:		sub		ax,si
		sbb		dx,0
arc1:
		idiv		word [deltax]
		add		ax,bx
		pop		si
		push		si
		push		ax
		call		plot_xy
		pop		dx
		pop		ax
		cmp		si,cx
		je		fim_line
		inc		si
		jmp		line4

line5:		cmp		bx,dx
		jb 		line7
		xchg		ax,cx
		xchg		bx,dx
line7:
		push		cx
		sub		cx,ax
		mov		[deltax],cx
		pop		cx
		push		dx
		sub		dx,bx
		mov		[deltay],dx
		pop		dx



		mov		si,bx
line6:
		push		dx
		push		si
		push		ax
		sub		si,bx	;(y-y1)
		mov		ax,[deltax]
		imul		si
		mov		si,[deltay]		;arredondar
		shr		si,1
; se numerador (DX)>0 soma se <0 subtrai
		cmp		dx,0
		jl		ar2
		add		ax,si
		adc		dx,0
		jmp		arc2
ar2:		sub		ax,si
		sbb		dx,0
arc2:
		idiv		word [deltay]
		mov		di,ax
		pop		ax
		add		di,ax
		pop		si
		push		di
		push		si
		call		plot_xy
		pop		dx
		cmp		si,dx
		je		fim_line
		inc		si
		jmp		line6

fim_line:
		pop		di
		pop		si
		pop		dx
		pop		cx
		pop		bx
		pop		ax
		popf
		pop		bp
		ret		8
;*******************************************************************
segment data

cor		db		branco_intenso

preto		    equ		0
azul		    equ		1
verde		    equ		2
cyan		    equ		3
vermelho	    equ		4
magenta		    equ		5
marrom		    equ		6
branco		    equ		7
cinza		    equ		8
azul_claro	    equ		9
verde_claro 	equ		10
cyan_claro	    equ		11
rosa		    equ		12
magenta_claro	equ		13
amarelo		    equ		14
branco_intenso	equ		15

modo_anterior	db		0

cabecalho       db      'Exercicio de Programacao de Sistemas Embarcados 1 - 2022/2', 'Lucca Passos Covre 00 x 00 Computador', 'Velocidade Atual: 1'

x_direcao       dw      1
y_direcao       dw      1

borda_superior	dw		410
borda_inferior	dw		10
borda_esquerda	dw		10
borda_direita	dw		629

x_bola          dw      325
y_bola         	dw  	215

; y_base_raquete  dw  	215
y_base_raquete  dw  	300

ponto_cpu       db      0
ponto_usuario   db      0

velocidade     	dw  	100

deltax		    dw		0
deltay  		dw		0	


segment stack stack
    	resb 		512
stacktop:

