.org 0x800

# -----------------------------------------------------------------------
# Direttive global e type
# Queste direttive sono utilizzate dal linker per esporre le 
# funzioni al file test.c e consentire l'esecuzione del programma
# -----------------------------------------------------------------------
.globl  my_malloc_init
.type   my_malloc_init, @function
.globl  my_free
.type   my_free, @function
.globl  my_malloc
.type   my_malloc, @function

.section .note.GNU-stack,"",@progbits # Questa direttiva rende lo stack non eseguibile

.data
# -----------------------------------------------------------------------------
# Strutture dati utilizzate per supportare le allocazioni e deallocazioni
# memory_manager: contiene il puntatore corrente e la testa della lista libera
#   0x00 - current_ptr: Puntatore all'area corrente del memory pool
#   0x08 - free_list_head: Puntatore alla testa della lista dei blocchi liberi
# -----------------------------------------------------------------------------
memory_manager: .quad 16

# -----------------------------------------------------------------------------
# memory_pool: buffer di 10 MB utilizzato per le allocazioni di memoria
# -----------------------------------------------------------------------------
.comm   memory_pool, 10485760, 16

.text
# -------------------------------------------------------------------------------------------------
# align: questa istruzione ci permette di allineare blocchi a 16 byte sfruttando la cache della CPU 
# per avere una lettura più veloce. Se la nostra malloc ha quindi una struttura dati perfettamente allineata,
# la CPU impiegherà meno tempo nella lettura dei dati dovendo leggere una sola riga di indirizzi invece di due.
# -------------------------------------------------------------------------------------------------
.align 4
# -------------------------------------------------------------------------------------------------
# Funzione: my_malloc_init
# Descrizione: Inizializza il gestore della memoria impostando il puntatore corrente 
#              all'inizio del pool di memoria e la lista libera a NULL.
# Argomenti: Nessuno
# Restituisce: Nessuno
# Come funziona: Carica gli indirizzi di memory_pool e memory_manager, poi imposta 
#                il puntatore corrente all'inizio del pool e inizializza la lista libera a NULL.
# -------------------------------------------------------------------------------------------------
my_malloc_init:
    lea memory_pool(%rip), %rax           # Carica l'indirizzo di memory_pool
    lea memory_manager(%rip), %rcx        # Carica l'indirizzo di memory_manager
    movq %rax, (%rcx)                     # Imposta current_ptr all'inizio del pool
    xorq %rax, %rax                       # Inizializza free_list_head a NULL
    movq %rax, 8(%rcx)                    # Imposta la lista libera vuota
    retq

.align 4
# ---------------------------------------------------------------------------------------------
# Funzione: my_malloc
# Descrizione: Alloca un blocco di memoria della dimensione richiesta. Se c'è un 
#              blocco libero adatto nella lista libera, lo utilizza, altrimenti 
#              ne alloca uno nuovo dal pool di memoria.
# Argomenti:
#   %rdi - La dimensione richiesta per l'allocazione
# Restituisce:
#   %rax - Indirizzo del blocco allocato o NULL se non c'è spazio
# Come funziona: Verifica se ci sono blocchi liberi nella lista libera. Se sì, utilizza 
#                il primo blocco libero trovato. Altrimenti, calcola e alloca un nuovo 
#                blocco dal pool di memoria.
# ---------------------------------------------------------------------------------------------
my_malloc:
    lea memory_manager(%rip), %rcx        # Carica l'indirizzo di memory_manager
    movq 8(%rcx), %rax                    # Carica la testa della lista libera
    testq %rax, %rax                      # Controlla se la lista è vuota
    jz allocate_new_block                 # Salta se la lista è vuota

.align 4
# ---------------------------------------------------------------------------------------------
# Funzione: find_suitable_block
# Descrizione: Trova un blocco libero adatto dalla lista libera e lo restituisce.
#              Se non ci sono blocchi adatti, passa alla funzione allocate_new_block.
# Argomenti: Nessuno
# Restituisce:
#   %rax - Indirizzo del blocco trovato
# Come funziona: Ottiene il prossimo blocco libero dalla lista e lo rimuove dalla lista 
#                stessa, quindi restituisce l'indirizzo del blocco.
# ---------------------------------------------------------------------------------------------
find_suitable_block:
    movq (%rax), %rdx                     # Ottieni il prossimo blocco libero
    movq %rdx, 8(%rcx)                    # Rimuovi il blocco dalla lista libera
    ret                                   # Restituisci il blocco

.align 4
# ---------------------------------------------------------------------------------------------
# Funzione: allocate_new_block
# Descrizione: Alloca un nuovo blocco di memoria dal pool. Arrotonda la dimensione 
#              richiesta a 64, 128 o 256 byte e verifica se c'è spazio disponibile.
#              Se c'è spazio, restituisce l'indirizzo del nuovo blocco, altrimenti 
#              restituisce NULL.
# Argomenti:
#   %rdi - La dimensione richiesta per l'allocazione
# Come funziona: Arrotonda la dimensione richiesta a una delle dimensioni standard 
#                (64, 128 o 256 byte), quindi verifica se c'è abbastanza spazio nel 
#                pool di memoria per allocare il blocco. Se sì, aggiorna il puntatore 
#                corrente e restituisce l'indirizzo del blocco, altrimenti restituisce NULL.
# ----------------------------------------------------------------------------------------------
allocate_new_block:
    # Arrotonda la dimensione richiesta a 64, 128 o 256 byte
    movq %rdi, %rdx                       # Copia la dimensione richiesta
    cmpq $64, %rdx                        # Confronta con 64
    jle allocate_64
    cmpq $128, %rdx                       # Confronta con 128
    jle allocate_128
    movq $256, %rdx                       # Altrimenti, usa 256
    jmp allocate_blocks

.align 4
# ----------------------------------------------------------------------------------------------
# Funzione: allocate_64
# Descrizione: Arrotonda la dimensione richiesta a 64 byte.
# Argomenti: Nessuno
# Come funziona: Imposta la dimensione richiesta a 64 byte e passa alla funzione 
#                allocate_blocks per procedere con l'allocazione.
# ----------------------------------------------------------------------------------------------
allocate_64:
    movq $64, %rdx
    jmp allocate_blocks

.align 4
# ----------------------------------------------------------------------------------------------
# Funzione: allocate_128
# Descrizione: Arrotonda la dimensione richiesta a 128 byte.
# Argomenti: Nessuno
# Come funziona: Imposta la dimensione richiesta a 128 byte e passa alla funzione 
#                allocate_blocks per procedere con l'allocazione.
# ----------------------------------------------------------------------------------------------
allocate_128:
    movq $128, %rdx

.align 4
# ----------------------------------------------------------------------------------------------
# Funzione: allocate_blocks
# Descrizione: Alloca un blocco di memoria della dimensione specificata. 
#              Aggiorna il puntatore corrente nel memory_manager.
# Argomenti: Nessuno
# Come funziona: Calcola il nuovo puntatore aggiungendo la dimensione richiesta 
#                al puntatore corrente. Verifica se c'è abbastanza spazio nel pool 
#                di memoria. Se sì, aggiorna il puntatore corrente e restituisce 
#                l'indirizzo del blocco, altrimenti passa alla funzione no_memory.
# ----------------------------------------------------------------------------------------------
allocate_blocks:
    movq (%rcx), %rax                     # Carica il puntatore corrente
    addq %rdx, %rax                       # Calcola il nuovo puntatore
    lea memory_pool + 10485760(%rip), %rsi # Fine del pool
    cmpq %rsi, %rax                       # Controlla se c'è spazio
    ja no_memory                          # Se non c'è spazio, restituisci NULL

    movq %rax, (%rcx)                     # Aggiorna il puntatore corrente
    subq %rdx, %rax                       # Calcola l'indirizzo iniziale del blocco
    ret                                   # Restituisci l'indirizzo del blocco

.align 4
# ----------------------------------------------------------------------------------------------
# Funzione: no_memory
# Descrizione: Gestisce il caso in cui non c'è abbastanza memoria disponibile nel pool.
#              Restituisce NULL.
# Argomenti: Nessuno
# Come funziona: Imposta il registro %rax a 0 (NULL) e ritorna.
# ----------------------------------------------------------------------------------------------
no_memory:
    xorq %rax, %rax                       # Restituisci NULL
    ret

.align 4
# ----------------------------------------------------------------------------------------------
# Funzione: my_free
# Descrizione: Libera un blocco di memoria e lo aggiunge alla lista libera.
# Argomenti:
#   %rdi - Il puntatore al blocco di memoria da liberare
# Come funziona: Calcola l'offset nel pool di memoria del puntatore da liberare, 
#                quindi lo aggiunge alla testa della lista libera.
# ----------------------------------------------------------------------------------------------
my_free:
    lea memory_manager(%rip), %rcx        # Carica l'indirizzo di memory_manager
    movq %rdi, %rax                       # Carica il puntatore da liberare
    subq memory_pool(%rip), %rax          # Calcola l'offset nel pool
    shrq $6, %rax                         # Dividi per 64 per ottenere l'indice del blocco
    shlq $6, %rax                         # Moltiplica per 64 per ottenere l'indirizzo del blocco
    addq memory_pool(%rip), %rax          # Calcola l'indirizzo del blocco nel pool

    # Aggiungi il blocco alla lista libera
    movq 8(%rcx), %rdx                    # Carica la testa della lista libera
    movq %rdx, (%rax)                     # Imposta il prossimo blocco libero
    movq %rax, 8(%rcx)                    # Aggiorna la testa della lista libera

    ret

.align 4
# -----------------------------------------------------------------------------------------
# Funzione: invalid_free
# Descrizione: Gestisce il caso di una free non valida. Al momento non fa nulla.
# Argomenti: Nessuno
# Come funziona: Ritorna immediatamente senza fare nulla.
# -----------------------------------------------------------------------------------------
invalid_free:
    # Gestione del caso di free non valido
    ret