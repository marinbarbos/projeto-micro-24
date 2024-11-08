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
# 0x3F, 0x06, 0x5B, 0x4F, 0x66, 0x6D, 0x7D, 0x07, 0x7F

ARR_DISPLAY:
    # .byte 0x7E, 0x30, 0x6D, 0x79, 0x33, 0x5B, 0x5F, 0x70, 0x7F, 0x7B
    .byte 0x7E, 0x06, 0x5b, 0x4f, 0x66, 0x6d, 0x7d, 0x07, 0x7F, 0x67
    
    
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

/*Sub Rotina - de display */
    .org 0x100    
TIMER_EXEC:
  movia r14, 0x10002000
  stwio r0, (r14)
  stwio  r13, (r15)

  addi r7, r7, 1 /* Precisa de um registrador ou local no stack frame fixo pra guardar*/
  addi r11, r11, 0x270F
  blt r7, r11, CONVERT_DISPLAY:
  mov r7, r0

CONVERT_DISPLAY:
  movi r6, 0
  LOOP_DEC:
    subi r7, r7, 10
    addi r6, r6, 1
    blt r7, 

  # SEGUNDO DISPLAY(0010)
  movia r13, ARR_DISPLAY
  srli r12, r7, 4
  andi r12, r12, 0x0F
  add r13, r13, r12
  ldb r13, (r13)
  stbio r13, 1(r10)
  
  # PRIMEIRO DISPLAY(0001)
  movia r13, ARR_DISPLAY
  andi r12, r7, 0x0F
  add r13, r13, r12
  ldb r13, (r13)
  stbio r13, (r10)

  /*
  # TERCEIRO DISPLAY(0100)
  movia r13, ARR_DISPLAY
  srli r12, r7, 8
  andi r12, r12, 0x0F
  add r13, r13, r12
  ldb r13, (r13)
  stbio r13, 2(r10)

  # QUARTO DISPLAY(1000)
  movia r13, ARR_DISPLAY
  srli r12, r7, 12
  andi r12, r12, 0x0F
  add r13, r13, r12
  ldb r13, (r13)
  stbio r13, 3(r10)    */

  stwio r0, 12(r15)

ret

/*Configura as variaveis */
.global _start
_start:

mov r7, r0/*Variable that acumulates the total */
movia r10, 0x10000020 /* Load 7 segments display address */

movia r15, 0x10001000 /* Load controller address */

/* Start timer interrupt config */
movia r14, 0x10002000

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

