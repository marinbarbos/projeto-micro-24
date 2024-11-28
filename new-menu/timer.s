.include "nios_macros.s"
.include "constants.s"
.extern PUT_JTAG
.extern GET_JTAG
ARR_DISPLAY:
    .byte 0x3F, 0x06, 0x5B, 0x4F, 0x66, 0x6D, 0x7D, 0x07, 0x7F, 0x67

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
  /* set up stack pointer */
  mov r23, r0        /* unidade */
  mov r16, r0       /* dezena */
  mov r17, r0       /* centena */
  mov r18, r0       /* milhar */
  movia r10, SEV_SEG_ADDR
  movia r15, LOAD_CONTR_ADDR
  movi r19, 1       /* contador */

  movia sp, 0x007FFFFC /* stack starts from highest memory address in SDRAM */
  movia r20, 0x10002000 /* internal timer base address */
  /* set the interval timer period for scrolling the HEX displays */
  movia r12, 0x2F4CF90 /* 1s */
  sthio r12, 8(r20) /* store the low halfword of counter start value */
  srli r12, r12, 16
  sthio r12, 0xC(r20) /* high halfword of counter start value */
  /* start interval timer, enable its interrupts */
  movi r15, 0b0111 /* START = 1, CONT = 1, ITO = 1 */
  sthio r15, 4(r20)
  /* write to the pushbutton port interrupt mask register */
  movia r15, 0x10000050 /* pushbutton key base address */
  movi r7, 0b00010 /* set 3 interrupt mask bits (bit 0 is Nios II reset) */
  stwio r7, 8(r15) /* interrupt mask register is (base + 8) */
  /* enable Nios II processor interrupts */
  movi r7, 0b011 /* set interrupt mask bits for levels 0 (interval */
  wrctl ienable, r7 /* timer) and level 1 (pushbuttons) */
  movi r7, 1
  wrctl status, r7 /* turn on Nios II interrupt processing */
  movi r7, 2
  br GET_JTAG
  