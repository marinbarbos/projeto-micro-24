/*
João Pedro Brum Terra
João Vitor Figueredo
Marina Barbosa Américo
*/

.include "nios_macros.s"
.include "constants.s"
.extern PUT_JTAG
.extern GET_JTAG

/**************************************************************************
* timer.s
* Cronometro decimal de 0 ate 9999
*
****************************************************************************/

/* Vetor com os codigos para ativacao das secoes dos displays de 7 segmentos */
ARR_DISPLAY:
    .byte 0x3F, 0x06, 0x5B, 0x4F, 0x66, 0x6D, 0x7D, 0x07, 0x7F, 0x67
    /* 0 1 2 3 4 5 6 7 8 9 */

.global ADD_DEZENA
ADD_DEZENA:
    mov r23, r0          /* Reseta a unidade */
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
    andi r12, r23, SEV_SEG_MASK
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
  mov r16, r0       /* zera dezena */
  mov r17, r0       /* zera centena */
  mov r18, r0       /* zera milhar */
  mov r23, r0       /* zera unidade */
  movi r19, 1       /* inicia contador */
  movia r10, SEV_SEG_ADDR
  movia r15, LOAD_CONTR_ADDR
  movia r20, TIMER_ADDRESS

  /* Configura o stack pointer */
  movia sp, 0x007FFFFC  /* Define o ponteiro de pilha para o endereço mais alto na SDRAM */

  /* Configura o temporizador */
  movia r12, 0x2F4CF90 /* 1s */
  sthio r12, 8(r20) /* Valor baixo do contador*/
  srli r12, r12, 16
  sthio r12, 0xC(r20) /* Valor alto do contador */
  movi r15, 0b0111 /* START = 1, CONT = 1, ITO = 1 */
  sthio r15, 4(r20)

  /* Configura o Push Button 1 */
  movia r15, PUSHBUTTON_ADDR
  movi r7, 0b00010 /* Mascara do Push Button 1 */
  stwio r7, 8(r15) /* Para trabalhar com o botao 1 usamos endereco base + 8 */

  movi r7, 0b011 /* Habilita IRQ0 e IRQ1  para interrupcoes do imer e do push button 1*/
  wrctl ienable, r7

  movi r7, 1
  wrctl status, r7 /* Habilita interrupcoes */
  movi r7, 2
  br GET_JTAG
