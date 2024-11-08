.include "nios_macros.s"
.include "constants.s"
.extern END_PUT
.extern PUT_JTAG
.extern GET_JTAG

.global LEDS_UP_DOWN
LEDS_UP_DOWN:
  /* Função que determina se irá apagar ou acender os LEDs */
  ldwio r4, 0(r6)            /* Lê o próximo dado da UART */
  andi r8, r4, 0x8000        /* Verifica se há novos dados */
  beq r8, r0, LEDS_UP_DOWN   /* Se não houver dados, espera */
  andi r5, r4, 0x00ff        /* Extrai o byte menos significativo */
  call PUT_JTAG              /* Escreve o caractere */

  movi r10, '0'              /* Verifica se o comando é '0' para acender LEDs */
  beq r5, r10, LEDS_UP
  movi r10, '1'              /* Verifica se o comando é '1' para apagar LEDs */
  beq r5, r10, LEDS_DOWN

LEDS_UP:
  ldwio r4, 0(r6)            /* Lê o próximo caractere em r4 */
  andi r8, r4, 0x8000        /* Verifica se o bit mais significativo está setado */
  beq r8, r0, LEDS_UP        /* Se não estiver setado, repete a leitura */
  andi r5, r4, 0x00ff        /* Isola os 8 bits menos significativos */
  call PUT_JTAG              /* Envia o valor de r5 via JTAG */
  
LEDS_UP2:
  /* Lê o caractere correspondente ao LED a ser aceso */
  ldwio r4, 0(r6)
  andi r8, r4, 0x8000
  beq r8, r0, LEDS_UP2
  mov r12, r5
  andi r5, r4, 0x00ff
  call PUT_JTAG

  /* Converte caracteres ASCII para número e calcula posição do LED */
  subi r12, r12, '0'
  subi r5, r5, '0'
  muli r12, r12, 10
  add r11, r12, r5

  /* Configura o LED específico */
  movia r15, RED_ADDRESS
  movi r10, RED_LIMIT
  bgt r11, r10, END_PUT

  ldwio r9, 0(r15)
  movi r12, 1
  sll r12, r12, r11
  or r9, r9, r12
  stwio r9, 0(r15)

  movia r5, BREAK_LINE
  stwio r5, 0(r6)
  br GET_JTAG

LEDS_DOWN:
  /* Lógica para apagar o LED indicado */
  ldwio r4, 0(r6)
  andi r8, r4, 0x8000
  beq r8, r0, LEDS_DOWN
  andi r5, r4, 0x00ff
  call PUT_JTAG

LEDS_DOWN2:
  /* Lê o caractere correspondente ao LED a ser apagado */
  ldwio r4, 0(r6)
  andi r8, r4, 0x8000
  beq r8, r0, LEDS_DOWN2
  mov r12, r5
  andi r5, r4, 0x00ff
  call PUT_JTAG

  /* Converte caracteres ASCII para número e calcula posição do LED */
  subi r12, r12, '0'
  subi r5, r5, '0'
  muli r12, r12, 10
  add r11, r12, r5

  /* Configura o LED específico */
  movia r15, RED_ADDRESS
  movi r10, RED_LIMIT
  bgt r11, r10, END_PUT

  ldwio r9, 0(r15)
  movi r12, 1
  sll r12, r12, r11
  movi r13, 0xFFFFFFFF
  sub r12, r13, r12
  and r9, r9, r12
  stwio r9, 0(r15)

  movia r5, BREAK_LINE
  stwio r5, 0(r6)
  br GET_JTAG