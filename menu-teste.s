/*
João Pedro Brum Terra
João Vitor Figueredo
Marina Barbosa Américo
*/

/********************************************************************************
* This program demonstrates use of the JTAG UART port in the DE2 Media Computer
*
* It performs the following:
* 1. sends a text string to the JTAG UART
* 2. reads character data from the JTAG UART
* 3. echos the character data back to the JTAG UART
********************************************************************************/
.equ RED_LIMIT, 0xF
.equ RED_ADDRESS, 0x10000000
.equ BREAK_LINE, 0x0a
.text /* executable code follows */
.global _start
_start:
  /* set up stack pointer */
  movia sp, 0x007FFFFC /* stack starts from highest memory address in SDRAM */
  movia r6, 0x10001000 /* JTAG UART base address */
  /* print a text string */
  movia r8, TEXT_STRING
  LOOP:
  ldb r5, 0(r8)
  beq r5, zero, GET_JTAG /* string is null-terminated */
  call PUT_JTAG
  addi r8, r8, 1
  br LOOP
GET_JTAG:
  /* read and echo characters */
  ldwio r4, 0(r6) /* read the JTAG UART Data register */
  andi r8, r4, 0x8000 /* check if there is new data */
  beq r8, r0, GET_JTAG /* if no data, wait */
  andi r5, r4, 0x00ff /* the data is in the least significant byte */
  call PUT_JTAG

  movi r10, '0'
  beq r5, r10, LEDS_UP_DOWN
  movi r10, '1'
  beq r5, r10, LEDS_ANIMATION
  movi r10, '2'
  beq r5, r10, LEDS_TIMER
  br GET_JTAG

PUT_JTAG:
  /* save any modified registers */
  subi sp, sp, 4 /* reserve space on the stack */
  stw r4, 0(sp) /* save register */
  ldwio r4, 4(r6) /* read the JTAG UART Control register */
  andhi r4, r4, 0xffff /* check for write space */
  beq r4, r0, END_PUT /* if no space, ignore the character */
  stwio r5, 0(r6) /* send the character */

END_PUT:
  /* restore registers */
  ldw r4, 0(sp)
  addi sp, sp, 4
  ret

LEDS_UP_DOWN:
  /* read and echo characters */
  ldwio r4, 0(r6) /* read the JTAG UART Data register */
  andi r8, r4, 0x8000 /* check if there is new data */
  beq r8, r0, LEDS_UP_DOWN /* if no data, wait */
  andi r5, r4, 0x00ff /* the data is in the least significant byte */
  call PUT_JTAG

  movi r10, '0'
  beq r5, r10, LEDS_UP
  movi r10, '1'
  beq r5, r10, LEDS_DOWN

LEDS_UP:
    ldwio r4, 0(r6) /* read the JTAG UART Data register */
    andi r8, r4, 0x8000 /* check if there is new data */
    beq r8, r0, LEDS_UP /* if no data, wait */
    andi r5, r4, 0x00ff /* the data is in the least significant byte */
    call PUT_JTAG

LEDS_UP2:
    ldwio r4, 0(r6) /* read the JTAG UART Data register */
    andi r8, r4, 0x8000 /* check if there is new data */
    beq r8, r0, LEDS_UP2 /* if no data, wait */
    mov r12, r5
    andi r5, r4, 0x00ff /* the data is in the least significant byte */
    call PUT_JTAG

    subi r12, r12, '0'
    subi r5, r5, '0'
    muli r12, r12, 10
    add r11, r12, r5

    movia r15, RED_ADDRESS     # Endereço base dos LEDs vermelhos
    movi r10, RED_LIMIT       # Limite de LEDs
    bgt r11, r10, END_PUT         # Se r11 > limite, salta para o fim

    # Lê o estado atual dos LEDs
    ldwio r9, 0(r15)

    # Configura o valor para acender o LED indicado em r11 sem apagar os outros
    movi r12, 1               # Inicializa r12 com 1
    sll r12, r12, r11         # Desloca o bit 1 para a posição em r11

    # Faz OR entre o valor atual (r9) e o novo LED (r12) para acender ambos
    or r9, r9, r12
    # Escreve o novo valor em r9 nos LEDs vermelhos
    stwio r9, 0(r15)

    movia r5, BREAK_LINE
    stwio r5, 0(r6) /* send the character */    
    br GET_JTAG
    
LEDS_DOWN:
    ldwio r4, 0(r6) /* read the JTAG UART Data register */
    andi r8, r4, 0x8000 /* check if there is new data */
    beq r8, r0, LEDS_DOWN /* if no data, wait */
    andi r5, r4, 0x00ff /* the data is in the least significant byte */
    call PUT_JTAG

LEDS_DOWN2:
    ldwio r4, 0(r6) /* read the JTAG UART Data register */
    andi r8, r4, 0x8000 /* check if there is new data */
    beq r8, r0, LEDS_DOWN2 /* if no data, wait */
    mov r12, r5
    andi r5, r4, 0x00ff /* the data is in the least significant byte */
    call PUT_JTAG

    subi r12, r12, '0'
    subi r5, r5, '0'
    muli r12, r12, 10
    add r11, r12, r5
    
    movia r15, RED_ADDRESS      # Endereço base dos LEDs vermelhos
    movi r10, RED_LIMIT        # Limite de LEDs
    bgt r11, r10, END_PUT          # Se r11 > limite, salta para o fim

    # Lê o estado atual dos LEDs
    ldwio r9, 0(r15)

    # Configura a máscara para apagar o LED indicado em r11
    movi r12, 1                # Inicializa r12 com 1
    sll r12, r12, r11          # Desloca o bit 1 para a posição em r11
    movi r13, 0xFFFFFFFF       # Máscara de todos os bits 1
    sub r12, r13, r12          # Cria a máscara invertida (todos 1s, exceto o LED a ser apagado)

    # Faz AND entre o valor atual (r9) e a máscara (r12) para apagar o LED desejado
    and r9, r9, r12
    # Escreve o novo valor em r9 nos LEDs vermelhos
    stwio r9, 0(r15)

    movia r5, BREAK_LINE
    stwio r5, 0(r6) /* send the character */
    br GET_JTAG

LEDS_ANIMATION:
  ret
LEDS_TIMER:
  ret

.data /* data follows */
TEXT_STRING:
.asciz "\nEntre com o comando:\n> "
.end
