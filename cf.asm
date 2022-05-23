;    <one line to give the program's name and a brief idea of what it does.>
;    Copyright (C) 2022  Quentin Glenn Carver
;
;    This program is free software: you can redistribute it and/or modify
;    it under the terms of the GNU General Public License as published by
;    the Free Software Foundation, either version 3 of the License, or
;    (at your option) any later version.
;
;    This program is distributed in the hope that it will be useful,
;    but WITHOUT ANY WARRANTY; without even the implied warranty of
;    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;    GNU General Public License for more details.
;
;    You should have received a copy of the GNU General Public License
;    along with this program.  If not, see <https://www.gnu.org/licenses/>.

default rel
bits 64

%define PAGESIZE 0x1000 ; 4096
%macro mmap 2
%define PROT_READ_and_WRITE 0x3
%define MAP_PRIVATE_and_ANONYMOUS 0x22
	mov rax, 9		; mmap
	mov rdi, 0		; address
	mov rsi, %2		; length
	mov rdx, PROT_READ_and_WRITE
	mov r10, MAP_PRIVATE_and_ANONYMOUS
	mov r8, -1		; no file
	mov r9, 0 		; no offset
	syscall			; rax has mem
	mov %1, rax
%undef PROT_READ_and_WRITE
%undef MAP_PRIVATE_and_ANONYMOUS
%endmacro 

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

section .bss
initialstack: resq 1
section .text
	global _start
_start:
	mov rdi, 137
	pushcont leavewithvalue
	mmap hasharr, PAGESIZE*16
	mmap framearray, PAGESIZE*16
	mmap rbp, PAGESIZE*16
	allocframe

	pushcont add
	mov r10, 0xc000000000000007
	push r10
	mov r10, 0xc000000000000005
	push r10
	
	pushquot dup, r10, rbx
	pushquot swap, rsi, rdi
	allocframe
	
	pushcont pop
	pushcont pop
	pushcont cat
	pushcont app
	pushcont quote
	pushcont pop
	pushcont quote
	push r10
	push r10
	push rsi
	push r10
	
	jmp decode
leavewithvalue:
	mov rdi, [rbp]
	mov rax, 231
	syscall


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


