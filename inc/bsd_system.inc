;; DUC
;; Copyright (c) 2004 Edward G. Brown
;; All rights reserved.
;;

;; define some sys calls etc
;; do not edit unless you know what you're doing

;; some system calls
%define	SYS_syscall	0
%define	SYS_exit	1
%define	SYS_read	3
%define	SYS_write	4
%define	SYS_open	5		
%define	SYS_close	6		
%define SYS_rename	128

;; these two go together and call the kernel
;; kernel kernel, oh where art thou kernel?

[SECTION .text]

align 4
access.kernel:
	int	80h
	ret



