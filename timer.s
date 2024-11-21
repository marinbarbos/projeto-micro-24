/*
João Pedro Brum Terra
João Vitor Figueredo
Marina Barbosa Américo
*/  

/**************************************************************************/
/* Main Program                                                           */
/*   Determines the maximum number of consecutive 1s in a data word.      */
/*                                                                        */
/* r8   - Contains the switch data                                        */
/* r9   - Switch data sum                                                 */
/* r10  - Slide switch address for use                                    */
/* r11  - Green LED address for use                                       */
/* r12  - Push Button address for use                                     */
/* r13  - Contains Push Button data                                       */
/**************************************************************************/

/*Tratamento da interrupção */ 

.equ SEV_SEG_MASK, 0x0F
.equ SEV_SEG_ADDR, 0x10000020 /* Load 7 segments display address */
.equ LOAD_CONTR_ADDR, 0x10001000 /* Load controller address */
.equ TIMER_ADDR, 0x10002000

ARR_DISPLAY:
    .byte 0x3F, 0x06, 0x5B, 0x4F, 0x66, 0x6D, 0x7D, 0x07, 0x7F, 0x67

.org 0x20
RTI:
    rdctl et, ipending
    beq et, r0, OTHER_EXCEPTIONS
    subi ea, ea, 4    

    andi r12, et, 1
    beq r12, r0, OTHER_EXCEPTIONS
    call TIMER_EXEC

OTHER_EXCEPTIONS:
    eret

/* Sub Rotina - de display */
.org 0x100    
TIMER_EXEC:
    movia r14, 0x10002000
    stwio r0, (r14)
    stwio r13, (r15)

    addi r7, r7, 1  /* Incrementa a unidade */

    /* Verifica se a unidade atingiu dez para incrementar a dezena */
    movi r11, 10
    bge r7, r11, ADD_DEZENA

    /* Exibe os valores nos displays */
    br SHOW_COUNTER

ADD_DEZENA:
    mov r7, r0          /* Reseta a unidade */
    addi r16, r16, 1    /* Incrementa a dezena */

    /* Verifica se a dezena atingiu dez para incrementar a centena */
    bge r16, r11, ADD_CENTENA
    br SHOW_COUNTER

ADD_CENTENA:
    mov r16, r0         /* Reseta a dezena */
    addi r17, r17, 1    /* Incrementa a centena */

    /* Verifica se a centena atingiu dez para incrementar o milhar */
    bge r17, r11, ADD_MILHAR
    br SHOW_COUNTER

ADD_MILHAR:
    mov r17, r0         /* Reseta a centena */
    addi r18, r18, 1    /* Incrementa o milhar */

    /* Verifica se o milhar atingiu dez para zerar o cronômetro */
    bge r18, r11, RESET_COUNTER
    br SHOW_COUNTER

RESET_COUNTER:
    mov r18, r0         /* Reseta o quarto dígito para 0 */

SHOW_COUNTER:
    /* PRIMEIRO DISPLAY - unidade */
    movia r13, ARR_DISPLAY
    andi r12, r7, SEV_SEG_MASK
    add r13, r13, r12
    ldb r13, (r13)
    stbio r13, (r10)

    /* SEGUNDO DISPLAY - dezena */
    movia r13, ARR_DISPLAY
    andi r12, r16, SEV_SEG_MASK
    add r13, r13, r12
    ldb r13, (r13)
    stbio r13, 1(r10)

    /* TERCEIRO DISPLAY - centena */
    movia r13, ARR_DISPLAY
    andi r12, r17, SEV_SEG_MASK
    add r13, r13, r12
    ldb r13, (r13)
    stbio r13, 2(r10)

    /* QUARTO DISPLAY - milhar */
    movia r13, ARR_DISPLAY
    andi r12, r18, SEV_SEG_MASK
    add r13, r13, r12
    ldb r13, (r13)
    stbio r13, 3(r10)  

    ret

/* Configura as variáveis */
.global _start
_start:

mov r7, r0        /* unidade */
mov r16, r0       /* dezena */
mov r17, r0       /* centena */
mov r18, r0       /* milhar */
movia r10, SEV_SEG_ADDR

movia r15, LOAD_CONTR_ADDR

/* Start timer interrupt config */
movia r14, TIMER_ADDR

movia r8, 10000000 /* 200ms */
stwio r8, 8(r14) /* lower counter part */

srli r9, r8, 16 /* higher counter part */
stwio r9, 12(r14) 

movi r11, 0b111
stwio r11, 4(r14) /* init timer */

movi r14, 1  /* timer IRQ is 0 */
wrctl ienable, r14 /*Enable timer */ 

/* idk what is this tbh */
movia r8, 1
wrctl status, r8 

LACO:
  br LACO

.end
