.include "nios_macros.s"
.include "constants.s"
.extern PUT_JTAG
.extern GET_JTAG
ARR_DISPLAY:
    .byte 0x3F, 0x06, 0x5B, 0x4F, 0x66, 0x6D, 0x7D, 0x07, 0x7F, 0x67

.global ADD_DEZENA
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

.global SHOW_COUNTER
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
.global LEDS_TIMER
LEDS_TIMER:

mov r7, r0        /* unidade */
mov r16, r0       /* dezena */
mov r17, r0       /* centena */
mov r18, r0       /* milhar */
movia r10, SEV_SEG_ADDR

/* Start timer interrupt config */
movia r14, TIMER_ADDRESS

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

LOOP_TIMER:
    /* Função que determina se irá apagar ou acender os LEDs */
  ldwio r4, 0(r6)            /* Lê o próximo dado da UART */
  andi r8, r4, 0x8000        /* Verifica se há novos dados */
  beq r8, r0, LOOP_TIMER   /* Se não houver dados, espera */
  andi r5, r4, 0x00ff        /* Extrai o byte menos significativo */
  call PUT_JTAG              /* Escreve o caractere */
  movi r10, '1'              /* Verifica se o comando é '1' para apagar LEDs */
  bne r5, r10, LOOP_TIMER
  movi r14, 0  /* timer IRQ is 0 */
  wrctl ienable, r14 /*Desable timer */
  stwio r0, 0(r15) 
  movia r5, BREAK_LINE
  stwio r5, 0(r6)
  br GET_JTAG
