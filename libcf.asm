default rel
bits 64


%macro copy 3
; rcx = size , rsi = srcptr , rdi = destptr
; change this to some kind of simd copy in the future
; masking makes doing this easy in parallel
	mov rcx, %3
	xor rbx, rbx
%%loop:	mov rax, [%1+rbx*8]
	mov [%2+rbx*8], rax
	inc rbx
	dec rcx
	jnz %%loop
%endmacro

%macro primframe 1
	mov qword [framearray+frameindex], 1
	lea rax, [%1]
	mov qword [framearray+frameindex+8], rax
%endmacro

%macro popframe 2
	mov %1, [rbp]
	shl %1, 1
	sar %1, 1
	add %1, framearray
	sub rbp, 8
	mov %2, [%1]
	add %1, 8
%endmacro

%macro pushcont 1
	lea rax, [%1]
	push rax
%endmacro

%macro prepnum 1
	shl %1, 2
	sar %1, 2
%endmacro

%define hasharr r15
%define framearray r14
; it's worth noting that r13 has addressing limitations, making index the best fit.
%define frameindex r13 ; we might also just call this frameoff and ignore scaling
%define dwframeindex r13d ; we might also just call this frameoff and ignore scaling

%define phi64 11400714819323198485
%define framesize 0x80
%define allocframe add frameindex, framesize

%macro qtag 2
	mov %2, 1<<63
	or %1, %2
%endmacro
%macro pushquot 3
	primframe %1
	mov %2, frameindex
	qtag %2, %3
	allocframe
%endmacro

%macro seqhash 2
	mov rcx, %2
	xor rbx, rbx
;	mov eax, $2
%%loop:	mov rdx, phi64
	imul rdx, [%1+rbx*8]
;	crc32 rax, rdx
	xor rax, rdx
	shl rax, 2
	inc rbx 
	dec rcx
	jnz %%loop
%endmacro

%macro copyshift 3
	mov %1, %2
	shr %1, %3
%endmacro

%macro hashsrch 2
	copyshift ebx, e%1, 0x13 ; log2(32+qword[3]-page[10]*cnt[6])
	jmp %%start
%%loop:	add ebx, 8
	and ebx, 0x7ffff
%%start:mov rdx, [hasharr+rbx]
	test edx, edx
	setz %2
	cmp edx, e%1
	setz cl
	or cl, %2
	test cl, 1
	jz %%loop
	shr rdx, 32
	; rbx has index or rdx has frame index
%endmacro

section .text
	global init
	global load
	; we can't quote numbers atm
init:	push framearray
	push frameindex
	mov framearray, rdi
	mov frameindex, 0
	allocframe
	pushquot dup, rdx, rcx
	pushquot swap, rdx, rcx
	pushquot pop, rdx, rcx
	pushquot quote, rdx, rcx
	pushquot cat, rdx, rcx
	pushquot app, rdx, rcx
	pushquot add, rdx, rcx
	allocframe
	mov rax, frameindex
	pop frameindex
	pop framearray
	ret

load:	push rbx
	push framearray
	push frameindex
	push hasharr
	push r12
	push rbp
	mov framearray, [rdx]
	mov frameindex, [rdx+8]
	mov hasharr, [rdx+16]
	mov rbp, [rdx+24]
	push rdx
	pushcont .end
	cmp rsi, 0
	jz .end
	lea rsi, [rsi*8]
	sub rsp, rsi
	add rsi, rdi
	mov r10, rsp
.loop:	mov rax, [rdi]
	mov [r10], rax
	add rdi, 8
	add r10, 8
	cmp rsi, rdi
	jne .loop
	jmp decode
.end:	mov rax, rbp
	pop rdx
	mov [rdx+8], frameindex
	pop rbp
	pop r12
	pop hasharr
	pop frameindex
	pop framearray
	pop rbx
	ret


add:	mov rax, [rbp]
	prepnum rax
	sub rbp, 8
	mov rbx, [rbp]
	prepnum rbx
	add rax, rbx
	mov [rbp], rax
	jmp decode


quote:
	popframe r12, r11
	mov r11, 1
	xor rax, rax
	seqhash r12, r11
	shr rax, 32
	hashsrch ax, r10b
	add rbp, 8
	cmp r10b, 1
	je .comp
	mov rbx, 1<<63
	or rdx, rbx
	mov [rbp], rdx
	jmp decode
.comp:	allocframe
	mov rdx, frameindex
	shl rdx, 32
	or rdx, rax
	mov [hasharr+rbx], rdx
	mov rax, 1<<63
	mov rdx, frameindex
	or rdx, rax
	mov [rbp], rdx
	lea rdx, [framearray+frameindex]
	mov qword [rdx], 1
	add rdx, 8
	mov rax, [r12]
	mov [rdx], rax
	jmp decode


cat:	popframe r12, r11
	popframe r8, r9
	xor rax, rax
	seqhash r8, r9
	seqhash r12, r11
	shr rax, 32

	hashsrch ax, r10b ; rcx = bool , rdx = 
	cmp r10b, 1
	je .comp
	add rbp, 8
	mov rbx, 1<<63
	or rdx, rbx
	mov [rbp], rdx
	jmp decode
.comp:
	allocframe
	add rbp, 8
	mov rdx, frameindex
	shl rdx, 32
	or rdx, rax
	mov [hasharr+rbx], rdx
	mov rax, 1<<63
	mov rdx, frameindex
	or rdx, rax
	mov [rbp], rdx
	
	lea rcx, [r9+r11]
	lea rdx, [framearray+frameindex]
	mov [rdx], rcx
	add rdx, 8
	copy r8, rdx, r9
	lea rdi, [rdx+r9*8]
	copy r12, rdi, r11
	jmp decode

app:
	popframe rsi, rcx
	lea rax, [rcx*8]
	sub rsp, rax
	mov rdi, rsp
	copy rsi, rdi, rcx
	jmp decode

dcdlup:	pop rax
	mov rbx, rax
	shl rax, 1
	sar rax, 1
	; checking second bit of tag
	cmp rax, 0 
	cmovns rax, rbx
	add rbp, 8
	mov [rbp], rax
decode:	cmp qword [rsp], 0
	js dcdlup
	ret



dup:	mov rax, [rbp]
	add rbp, 8
	mov qword [rbp], rax
	jmp decode
swap:	mov rax, qword [rbp-8]
	xchg rax, qword [rbp]
	mov qword [rbp-8], rax
	jmp decode
pop:	sub rbp, 8
	jmp decode


