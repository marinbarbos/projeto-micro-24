/*
João Pedro Brum Terra
João Vitor Figueredo
Marina Barbosa Américo
*/

.include "nios_macros.s"
.include "constants.s"
.extern END_PUT
.extern PUT_JTAG
.extern GET_JTAG

/**************************************************************************
* leds-up-down.s
* Funcionalidade de ligar e desligar um LED especifico ditado pelo usuario
*
****************************************************************************/

.global LEDS_UP_DOWN
/* Função que determina se irá apagar ou acender os LEDs */
LEDS_UP_DOWN:
  ldwio r4, 0(r6)            /* Lê o próximo dado da UART */
  andi r8, r4, 0x8000        /* Verifica se há novos dados pelo RVALID */
  beq r8, r0, LEDS_UP_DOWN   /* Se não houver dados, espera */
  andi r5, r4, 0x00ff        /* Os dados estão no byte menos significativo */
  call PUT_JTAG              /* Escreve o caractere via JTAG */

  movi r10, '0'              /* Verifica se o comando é '0' para acender LEDs */
  beq r5, r10, LEDS_UP
  movi r10, '1'              /* Verifica se o comando é '1' para apagar LEDs */
  beq r5, r10, LEDS_DOWN

/* Inicia o processo de acender os LEDs */
LEDS_UP:
  ldwio r4, 0(r6)            /* Lê o próximo caractere em r4 */
  andi r8, r4, 0x8000        /* Verifica se o bit mais significativo está setado(RVALID) */
  beq r8, r0, LEDS_UP        /* Se não estiver setado, repete a leitura */
  andi r5, r4, 0x00ff        /* Os dados estão no byte menos significativo */
  call PUT_JTAG              /* Envia o valor de r5 via JTAG */

/* Lê o caractere correspondente ao LED a ser aceso */
LEDS_UP2:
  ldwio r4, 0(r6)           /* Lê o próximo caractere em r4 */
  andi r8, r4, 0x8000       /* Verifica se o bit mais significativo está setado(RVALID) */
  beq r8, r0, LEDS_UP2      /* Se não estiver setado, repete a leitura */
  mov r12, r5               /* Salva o dado anterior no r12 */
  andi r5, r4, 0x00ff       /* Os dados estão no byte menos significativo */
  call PUT_JTAG

  /* Converte caracteres ASCII para número e calcula posição do LED */
  subi r12, r12, '0'        /* Volta '0' na tabela ASCII para conversão */
  subi r5, r5, '0'

  slli r13, r12, 3          /* r13 = r12 *  8 (deslocamento de 3 bits) */
  slli r14, r12, 1          /* r14 = r12 *  2 (deslocamento de 1 bit) */

  add r12, r13, r14         /* r12 = r12 * 10 (soma dos dois resultados) */
  add r11, r12, r5          /* r11 o local do LED a ser escrito */

  movi r10, RED_LIMIT
  bgt r11, r10, FIM_LEDS    /* Se r11 for maior que o limite de LEDs acaba o processo */

  /* Configura o LED específico */
  movia r15, RED_ADDRESS
  ldwio r9, 0(r15)
  movi r12, 1
  sll r12, r12, r11         /* Shifta pelo valor em r11 para acertar o LED exato */
  or r9, r9, r12
  stwio r9, 0(r15)
  br FIM_LEDS

/* Inicia o processo de apagar os LEDs */
LEDS_DOWN:
  ldwio r4, 0(r6)
  andi r8, r4, 0x8000
  beq r8, r0, LEDS_DOWN
  andi r5, r4, 0x00ff
  call PUT_JTAG

LEDS_DOWN2:
  ldwio r4, 0(r6)           /* Lê o próximo caractere em r4 */
  andi r8, r4, 0x8000       /* Verifica se o bit mais significativo está setado(RVALID) */
  beq r8, r0, LEDS_DOWN2      /* Se não estiver setado, repete a leitura */
  mov r12, r5               /* Salva o dado anterior no r12 */
  andi r5, r4, 0x00ff       /* Os dados estão no byte menos significativo */
  call PUT_JTAG

  /* Converte caracteres ASCII para número e calcula posição do LED */
  subi r12, r12, '0'        /* Volta '0' na tabela ASCII para conversão */
  subi r5, r5, '0'

  slli r13, r12, 3          /* r13 = r12 *  8 (deslocamento de 3 bits) */
  slli r14, r12, 1          /* r14 = r12 *  2 (deslocamento de 1 bit) */

  add r12, r13, r14         /* r12 = r12 * 10 (soma dos dois resultados) */
  add r11, r12, r5          /* r11 o local do LED a ser escrito */

  movi r10, RED_LIMIT
  bgt r11, r10, FIM_LEDS    /* Se r11 for maior que o limite de LEDs acaba o processo */

  /* Configura o LED específico */
  movia r15, RED_ADDRESS
  ldwio r9, 0(r15)
  movi r12, 1
  sll r12, r12, r11         /* Shifta pelo valor em r11 para acertar o LED exato */
  movi r13, 0xFFFFFFFF
  sub r12, r13, r12         /* Tira r12 de FFFFFFFF para indicar que o LED será apagado */
  and r9, r9, r12
  stwio r9, 0(r15)

/* Insere uma nova linha pela UART */
FIM_LEDS:
  movia r5, BREAK_LINE
  stwio r5, 0(r6)
  br GET_JTAG