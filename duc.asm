;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; DUC
;; Copyright (c) 2004 Edward G. Brown
;; All rights reserved.
;;
;; Redistribution and use in source and binary forms, with or without
;; modification, are permitted provided that the following conditions
;; are met:
;;
;; 1. Redistributions of source code must retain the above copyright
;;    notice, this list of conditions and the following disclaimer.
;; 2. Redistributions in binary form must reproduce the above copyright
;;    notice, this list of conditions and the following disclaimer in the
;;    documentation and/or other materials provided with the distribution.
;; 3. Redistributions of modified source code must state specifically that 
;;    modifications exist and must retain the above copyright notice, 
;;    this list of conditions and the following disclaimer.
;; 4. Redistributions in binary form that were built from modified source 
;;    code must state specifically that modifications exist and must 
;;    retain the above copyright notice, this list of conditions and the 
;;    following disclaimer in the documentation and/or other materials 
;;    provided with the distribution.
;; 5. Neither the name of the author Edward G. Brown nor the names of its 
;;    contributors may be used to endorse or promote products derived from 
;;    this software without specific prior written permission.
;; 6. All redistributions whether source or binary must include either 
;;    a) unmodified source code or b) directions to obtain it and must 
;;    retain the above copyright notice, this list of conditions and the 
;;    following disclaimer in the documentation and/or other materials 
;;    provided with the distribution. Modified source is optional.
;;
;; THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS'' AND
;; ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
;; IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
;; ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE
;; FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
;; DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
;; OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
;; HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
;; LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
;; OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
;; SUCH DAMAGE.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;  Source name     : duc.asm 
;;  Executable name : duc
;;  Version         : 0.1
;;  Created date    : 11/11/2004 
;;  Last update     : 11/17/2004
;;  Author          : Edward G. Brown
;;  Description     : DUC: Displace Unprintable Characters
;;                  : This program will strip non-print characters and other junk from filenames. 
;;	   	    : This is particularly useful when dealing with mounted drives, containing 
;;		    : files from another OS.
;;		    : it uses rename
;;
;; 	Options Defined: -h display some help
;; 			 -s don't strip spaces
;; 			 -n strip only non-printables and spaces (unless -s)
;; 			 -r restore "_" underscores with spaces
;; 			 -t test only. show what the new filename would be
;;			 -d delete chars, don't replace with underscores
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	
%include 'system.inc'

[SECTION .text]                 ; Section containing code

global main                     ; Required so linker can find entry point

main:

        create.stack.frame      ; Create Stack Frame

        mov edi,[ebp+8]         ; Load argument count into edi
        mov ebx,[ebp+12]        ; Load pointer to argument table into ebx
        xor edx,edx             ; Clear edx to 0 so we get a fresh increment
        
ridjunk:

	inc edx			; start with first arg [not prg name]
        dec edi                 ; decrement arg counter by 1
        jz NEAR abort           ; get out if only the prg name or out of args

	push edi		; save this bad boy for later in case we have more than one arg

	; see if they are passing options
        mov esi, dword [ebx+edx*4]  ; copy address of the args into edi

	cmp word [esi],"-s"	; don't strip spaces
	jz near set_spaces 
	
	cmp word [esi],"-h"	; help
	jz near help_message

	cmp word [esi],"-n"	; strip noprints and spaces
	jz near set_noprints

	cmp word [esi],"-r"	; restore spaces
	jz near set_restore

	cmp word [esi],"-t"	; restore spaces
	jz near set_test

	cmp word [esi],"-d"	; delete, no underscores
	jz near set_delete

	jmp near args_ok		; if they don't match

help_message:
	sys.write help_msg_len, help_msg, stdout	; usage

	sys.write o_msg_len, o_msg, stdout		; options

	sys.write d_msg_len, d_msg, stdout		; description

	jmp NEAR abort

set_spaces:
	inc byte [spaces]       ; set spaces flag
	jmp NEAR dont

set_noprints:
	inc byte [noprints]     ; set noprints flag
	jmp NEAR dont

set_restore:
	inc byte [restore]      ; set restore flag
	jmp NEAR dont

set_test:
	inc byte [testbit]      ; set test flag
	jmp NEAR dont

set_delete:
	inc byte [deletebit]      ; set delete flag
	jmp NEAR dont

args_ok:
	;; Copy the original arg to the buffer buff
	mov edi,dword buff	; address of buff goes into edi
        xor eax,eax             ; Clear eax to 0 for the character counter
        cld                     ; Clear direction flag for up-memory movsb

        mov esi, dword [ebx+edx*4]  ; copy address of the args into edi
copy:  cmp byte [esi],0         ; Have we found the end of the arg?
        je proceed              ; If so, bounce to the next arg
        movsb                   ; Copy char from [esi] to [edi]; inc edi & esi
        inc eax                 ; Increment total character count
        cmp eax,BUFSIZE         ; See if we've filled the buffer to max count
        je .addnul              ; If so, go add a null to buff & we're done
        jmp copy

.addnul: mov byte [edi],0       ; Tuck a null on the end of buff

proceed:
	; at this point we have a copy of the arg in buff		
	; leave it alone. it will be our from argument to replace()

	mov edi,dword buzz	; address of buff goes into edi
	xor eax,eax             ; Clear eax to 0 for the character counter
        cld                     ; Clear direction flag for up-memory movsb

        mov esi, dword [ebx+edx*4]  ; copy address of the args into edi
stripbad:
	; here we will get rid of stuff
	cmp byte [esi],0        ; Have we found the end of the arg?
        je near renamefile      ; If not, evaluate arg, else renamefile


	; the comparison library

	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; NO PRINTS ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	;cmp byte [esi],00h	; NULL  handled above
	;je near  .replace

	cmp byte [esi],32	; get all these in one big crunch
	jb near .replace	

	;; WE'LL HANDLE SPACES SEPERATELY
	cmp byte [esi],20h	; [Space]
	je near  .spaces

	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; Punctuation etc ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	cmp byte [esi],21h	; !
	je near  .nreplace

	cmp byte [esi],22h	; "
	je near  .nreplace

	;cmp byte [esi],23h	; #
	;je near  .nreplace

	cmp byte [esi],24h	; $
	je near  .nreplace

	;cmp byte [esi],25h	; %
	;je near  .nreplace

	cmp byte [esi],26h	; &
	je near  .nreplace

	cmp byte [esi],27h	; '
	je near  .nreplace

	cmp byte [esi],28h	; (
	je near  .nreplace

	cmp byte [esi],29h	; )
	je near  .nreplace

	cmp byte [esi],2Ah	; *
	je near  .nreplace

	cmp byte [esi],2Bh	; +
	je near  .nreplace

	cmp byte [esi],2Ch	; ,
	je near  .nreplace

	;; special handling only replace if first char. so people can have it in their filenames if they want
	cmp byte [esi],2Dh	; - 
	je near  .firstchar

	;cmp byte [esi],2Eh	; .
	;je near  .nreplace

	cmp byte [esi],3Ah	; :
	je near  .nreplace

	cmp byte [esi],3Bh	; [;] < the semicolon itself
	je near  .nreplace

	cmp byte [esi],3Ch	; <
	je near  .nreplace

	cmp byte [esi],3Dh	; =
	je near  .nreplace

	cmp byte [esi],3Eh	; >
	je near  .nreplace

	cmp byte [esi],3Fh	; ?
	je near  .nreplace

	cmp byte [esi],5Bh	; [
	je near  .nreplace

	cmp byte [esi],5Ch	; \
	je near  .nreplace

	cmp byte [esi],5Dh	; ]
	je near  .nreplace

	cmp byte [esi],5Eh	; ^
	je near  .nreplace

	cmp byte [esi],5Fh      ; we'll replace underscores with a space if requested by "-r"
	je near  .restore

	cmp byte [esi],60h	; `
	je near  .nreplace

	cmp byte [esi],7Bh	; {
	je near  .nreplace

	cmp byte [esi],7Ch	; |
	je near  .nreplace

	cmp byte [esi],7Dh	; }
	je near  .nreplace

	cmp byte [esi],7Eh	; ~
	je near  .nreplace

	cmp byte [esi],7Fh	; DEL
	je near  .replace

	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; Extended ASCII ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	;; Extended Ascii codes
	;; Let's try and just compare to see if it's bigger than 7Fh if so, blast it!
	cmp byte [esi],127	; interesting territory from here on out
	ja near .replace	

.continue:
        movsb                   ; Copy if not bad char

.finish:
        inc eax                 ; Increment total character count
        cmp eax,BUFSIZE         ; See if we've filled the buffer to max count
        je .lastnul             ; If so, go add a null to buff & we're done
        jmp stripbad

.replace: 
	cmp byte [deletebit],1	; is the delete flag set?
	je .delete
	mov byte [edi],5Fh      ; Tuck an underscore on instead of the bad char
	inc esi			; movsb would do this if it were ordinary mov
	inc edi			; movsb would do this if it were ordinary mov
	jmp .finish

.delete:			; we just increment so that char is gone for good
	inc esi			; movsb would do this if it were ordinary mov
	;;inc edi		; since we're just deleting it we don't advance in the
				; new string
        inc eax                 ; Increment total character count
        cmp eax,BUFSIZE         ; See if we've filled the buffer to max count
        je .lastnul             ; If so, go add a null to buff & we're done
	jmp stripbad

.firstchar:			; if it's an "-" and the firstchar we replace
	cmp eax,0		; see if it's the first go round 
	je .replace
	jmp .continue

.nreplace:
	cmp byte [noprints],1	; is the noprints flag set?
	je  .continue		; we check this on the usual suspects !$ etc.
	jmp .replace		; if no -n replace those too

.restore:
	cmp byte [restore],1	; is the restore flag set?
	je  .putspacein		; if so, put spaces in
	jmp .continue		; if not, leave them alone

.putspacein: 
	mov byte [edi],20h      ; Replace the underscore with a space
	inc esi			; movsb would do this if it were ordinary mov
	inc edi			; movsb would do this if it were ordinary mov
	jmp .finish

.spaces:
	cmp byte [spaces],1	; is the spaces flag set?
	je  .continue		; if so, leave em be
	jmp .replace		; if not, crush em!

.lastnul: mov byte [edi],0      ; Tuck a null on the end of buff


renamefile:
	cmp byte [testbit],1	; is the spaces flag set?
	jne near compare 	; if so, leave em be

	sys.write BUFSIZE, buff, stdout		; unmodified file name

	sys.write would_len, would_msg, stdout	; would be

	sys.write BUFSIZE, buzz, stdout		; new file name

	sys.write end_len, would_end, stdout	; new line

	jmp abort		; exit

compare:
	; compare new name and old if so, drop out
	cld
	mov ecx, BUFSIZE
	mov esi,buff		; original name
	mov edi,buzz		; new name 
	repe cmpsb		; compare them
	jne doit		; mistmatch, rename

	jmp dont		; they match, just leave	

doit:
	; the renaming bit
	sys.rename buzz, buff	; call the rename macro

dont:
	pop edi			; that bad boy from earlier!
	cmp edi,0		; are we out of args yet?
	je abort 

	; If not, we go up to the top. take it from the top boys.
	jmp near ridjunk

abort:		
        destroy.stack.frame     ; Destroy Stack Frame
        sys.exit                ; Return control to kernel


[SECTION .data]			; Section containing initialised data

	help_msg  db  "Usage: duc [-hsnrt] file [...]",0Ah,0Ah,"Examples:",0Ah," duc la\ la\$\!abc.txt would produce la_la__abc.txt",0Ah," duc -s la\ la\$\!abc.txt would produce la la__abc.txt",0Ah,0Ah," File globbing: Often we need to clean up a file [or group of files]",0Ah," that begin with a non-print character or '-' making it necessary",0Ah," to use * to match.",0Ah," Using duc *.txt will not work, instead use duc *.txt*",0Ah," Try and put as mutch in the match as possible for all file sets.",0Ah," Use *<part_of_filename>.txt* instead of *.txt* when possible.",0Ah,0Ah
	help_msg_len  equ 	$-help_msg

	o_msg       db      "Options:",0Ah," -h or -help: this message",0Ah," -s: don't strip spaces",0Ah," -n: strip only non-printables and spaces (unless -s)",0Ah," -r: restore spaces. change all underscores to spaces",0Ah," -t: test only. show what the new filename would be",0Ah," -d: delete chars, don't replace with underscores",0Ah,0Ah
	o_msg_len  equ 	$-o_msg

	d_msg       db    "Description:",0Ah," duc removes non-printable and other chars",0Ah," that must be escaped from filenames. By Default it removes",0Ah," all of the first 32 non-printable ASCII chars as well as",0Ah," the extended ASCII set, beginning with 7Fh [DEL], all",0Ah," punctuations that require escaping [!'$] and so forth and",0Ah," replaces them with an underscore. It renames the file with",0Ah," the cleaned up name. Don't use on symbolic links, it changes",0Ah," the target name.",0Ah,0Ah," duc is quite useful when dealing with files from mounted",0Ah," drives, from other OSs, character sets etc. that",0Ah," can be wily and annoying to manipulate [e.g. mv cp etc.]",0Ah
	d_msg_len  equ 	$-d_msg

	would_msg db	" would become: ",0
	would_len equ $-would_msg
	would_end db	0Ah,"If names are identical, no change will be made.",0Ah
	end_len  equ  $-would_end

[SECTION .bss]			; Section containing uninitialized data

        BUFSIZE equ     1023    ; length of line buff based on 1023 characters for rename()
        buff resb       BUFSIZE ; reserve space for filename
        buzz resb       BUFSIZE ; reserve space for filename
	spaces resb     1	; flag for spaces option -s
	noprints resb   1	; flag for noprints option -n
	restore resb    1	; flag for restore option -r
	testbit resb    1	; flag for restore option -t
	deletebit resb  1	; flag for delete option -d
;; END QUACK
