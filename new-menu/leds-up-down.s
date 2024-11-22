.include "nios_macros.s"
.include "constants.s"
.extern END_PUT
.extern PUT_JTAG
.extern GET_JTAG

/* Funcao que determina se ira apagar ou acender os LEDs */
.global LEDS_UP_DOWN
LEDS_UP_DOWN: /* Comunicacao na UART para indicar quais LEDs acender/apagar */
  ldwio r4, 0(r6)            /* Le o proximo dado da UART */
  andi r8, r4, 0x8000        /* Verifica se ha novos dados */
  beq r8, r0, LEDS_UP_DOWN   /* Se nao houver dados, espera */
  andi r5, r4, 0x00ff        /* Extrai o byte menos significativo */
  call PUT_JTAG              /* Escreve o caractere no terminal */

  movi r10, '0'              /* Verifica se o comando e '0' para acender LEDs */
  beq r5, r10, LEDS_UP
  movi r10, '1'              /* Verifica se o comando e '1' para apagar LEDs */
  beq r5, r10, LEDS_DOWN

LEDS_UP:
  ldwio r4, 0(r6)            /* Carrega o proximo caractere em r4 */
  andi r8, r4, 0x8000        /* Verifica se o bit mais significativo esta setado(existem dados) */
  beq r8, r0, LEDS_UP        /* Se nao houver dados, repete a leitura */
  andi r5, r4, 0x00ff        /* Isola os 8 bits menos significativos(os dados relevantes) */
  call PUT_JTAG              /* Envia o valor de r5 via JTAG */
  
LEDS_UP2:
  /* Le o caractere correspondente ao LED a ser aceso */
  ldwio r4, 0(r6)           /* Carrega o proximo caractere em r4 */
  andi r8, r4, 0x8000       /* Verifica se o bit mais significativo esta setado(existem dados) */
  beq r8, r0, LEDS_UP2      /* Se nao houver dados, repete a leitura */
  mov r12, r5               /* Guarda os dados anteriores(dezena) em r12 */
  andi r5, r4, 0x00ff       /* Carrega os novos dados(unidade) em r5 */
  call PUT_JTAG

  /* Converte caracteres ASCII para número e calcula posicao do LED */
  subi r12, r12, '0'
  subi r5, r5, '0'
  slli r13, r12, 3   /* r13 = r12 * 8 (deslocamento de 3 bits) */
  slli r14, r12, 1   /* r14 = r12 * 2 (deslocamento de 1 bit) */
  add r12, r13, r14  /* r12 = r12 * 10 (soma dos dois resultados) */
  add r11, r12, r5   

  /* Configura o LED específico */
  movia r15, RED_ADDRESS
  movi r10, RED_LIMIT
  bgt r11, r10, FIM_UP  /* se o valor em r11 */

  ldwio r9, 0(r15)
  movi r12, 1
  sll r12, r12, r11
  or r9, r9, r12
  stwio r9, 0(r15)

FIM_UP:
  movia r5, BREAK_LINE
  stwio r5, 0(r6)
  br GET_JTAG

LEDS_DOWN:
  /* Logica para apagar o LED indicado */
  ldwio r4, 0(r6)
  andi r8, r4, 0x8000
  beq r8, r0, LEDS_DOWN
  andi r5, r4, 0x00ff
  call PUT_JTAG

LEDS_DOWN2:
  /* Le o caractere correspondente ao LED a ser apagado */
  ldwio r4, 0(r6)
  andi r8, r4, 0x8000
  beq r8, r0, LEDS_DOWN2
  mov r12, r5
  andi r5, r4, 0x00ff
  call PUT_JTAG

  /* Converte caracteres ASCII para número e calcula posicao do LED */
  subi r12, r12, '0'
  subi r5, r5, '0'
  slli r13, r12, 3            /* r13 = r12 * 8 (deslocamento de 3 bits) */
  slli r14, r12, 1            /* r14 = r12 * 2 (deslocamento de 1 bit) */
  add r12, r13, r14          /* r12 = r12 * 10 (soma dos dois resultados) */
  add r11, r12, r5

  /* Configura o LED específico */
  movia r15, RED_ADDRESS
  movi r10, RED_LIMIT
  bgt r11, r10, FIM_DOWN

  ldwio r9, 0(r15)
  movi r12, 1
  sll r12, r12, r11
  movi r13, 0xFFFFFFFF
  sub r12, r13, r12
  and r9, r9, r12
  stwio r9, 0(r15)

FIM_DOWN:
  movia r5, BREAK_LINE
  stwio r5, 0(r6)
  br GET_JTAG