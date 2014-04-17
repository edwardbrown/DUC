;; DUC
;; Copyright (c) 2004 Edward G. Brown
;; All rights reserved.
;;

;; define some sys calls etc
;; don't edit unless you know what you're doing

%include "EDITME.inc"


%ifdef  LINUX
%include "linux_system.inc"
%include "LINUX_MAC"
%elifdef BSD
%include "bsd_system.inc"
%include "UNIX_MAC"
%elifdef SOLARIS
%include "solaris_system.inc"
%include "UNIX_MAC"
%endif

;; open flags
;%define	O_RDONLY	0
;%define	O_WRONLY	1
;%define	O_RDWR		2

;; for output
;%define	stdin	0
%define	stdout	1
;%define	stderr	2


;; Always need these two Macros to take care of the stack
%macro create.stack.frame 0
                                ; Create Stack Frame:
        push ebp                ; copy address of ebp goes onto stack
        mov ebp,esp             ; esp (stack pointer) is copied to ebp

        push ebx                ; program must preserve ebp, ebx, esi, & edi
        push esi                ; so put them on the stack
        push edi
%endmacro

%macro destroy.stack.frame 0

        pop edi                 ; Restore saved registers
        pop esi
        pop ebx
                                ; Destroy Stack Frame:
        mov esp,ebp             ; copy address from ebp back into esp (stack pointer)
        pop ebp                 ; pop ebp off of stack
%endmacro

;; System call Macros
%macro	system	1
	mov	eax, %1
	call	access.kernel
%endmacro
