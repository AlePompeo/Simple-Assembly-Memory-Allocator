# 🗃️ `malloc` e `free` in Assembly x86-64

> **A from-scratch `malloc`/`free` in x86-64 assembly (AT&T syntax)**: static 10 MB pool, 64/128/256-byte blocks and a free list. University project (Computer Architecture course), Italian documentation.

![Assembly](https://img.shields.io/badge/x86--64-Assembly-6E4C13) ![C](https://img.shields.io/badge/C-A8B9CC?logo=c&logoColor=black) ![License](https://img.shields.io/badge/License-MPL--2.0-orange)


Progetto universitario per il corso di **Calcolatori Elettronici** — implementazione da zero delle funzioni `malloc` e `free` in linguaggio assembly x86-64, senza dipendenze dalla libreria standard.

---

## 📌 Descrizione

L'obiettivo del progetto è implementare un allocatore di memoria personalizzato che opera su un buffer statico da **10 MB** (`memory_pool`), supportando allocazioni di blocchi da **64, 128 e 256 byte** con una strategia di riuso tramite **free list**.

Il codice è scritto interamente in **AT&T syntax x86-64 assembly** ed è compatibile con sistemi **Position-Independent Executable (PIE)**, utilizzando l'indirizzamento RIP-relative per accedere alle variabili globali.

---

## 🧠 Strutture Dati

Il gestore della memoria (`memory_manager`) è un record a 16 byte in memoria statica che contiene:

| Offset | Campo             | Descrizione                                               |
|--------|-------------------|-----------------------------------------------------------|
| `0x00` | `current_ptr`     | Puntatore al prossimo byte libero nel `memory_pool`       |
| `0x08` | `free_list_head`  | Puntatore alla testa della lista singola dei blocchi liberi |

La **free list** è una lista collegata implicita: quando un blocco viene liberato, i suoi primi 8 byte vengono usati per memorizzare il puntatore al blocco libero successivo.

```
memory_manager:
┌──────────────────┬──────────────────────┐
│  current_ptr (8B)│  free_list_head (8B) │
└──────────────────┴──────────────────────┘
                            │
                            ▼
                     ┌─────────────┐
                     │  next (8B)  │  ← primo blocco libero
                     │    ...      │
                     └─────────────┘
                            │
                            ▼
                          NULL
```

---

## ⚙️ Funzioni Implementate

### `my_malloc_init`
Inizializza il gestore impostando `current_ptr` all'inizio di `memory_pool` e `free_list_head` a `NULL`.

### `my_malloc(size_t size)`
1. Se la **free list** non è vuota, restituisce il primo blocco disponibile (rimuovendolo dalla lista).
2. Altrimenti, arrotonda `size` per eccesso a **64, 128 o 256** byte.
3. Verifica che ci sia spazio sufficiente nel pool.
4. Aggiorna `current_ptr` e restituisce l'indirizzo del blocco allocato.
5. Restituisce `NULL` se la memoria è esaurita o se `size > 256`.

### `my_free(void *ptr)`
1. Calcola l'offset del puntatore rispetto all'inizio del `memory_pool`.
2. Allinea l'indirizzo al blocco da 64 byte più vicino.
3. Inserisce il blocco in testa alla **free list**.

---

## 🛠️ Compilazione ed Esecuzione

### Requisiti
- GCC con supporto assembler (`as`) per x86-64
- Sistema Linux 64-bit

### Compilare
```bash
make
```

### Eseguire il test
```bash
./malloc
```

Il `Makefile` ha solo i target `all` e `clean`: `make` produce l'eseguibile `malloc` (test in `test.c` collegato a `malloc.S`).

---

## 📁 Struttura del Repository

```
.
├── malloc.S       # Implementazione assembly dell'allocatore
├── test.c         # Test di correttezza (non modificare)
└── Makefile       # Build system (non modificare)
```

---

## 📝 Note Tecniche

- L'accesso alle variabili globali usa esclusivamente **RIP-relative addressing** per garantire la compatibilità con eseguibili PIE.
- Le **convenzioni di chiamata System V AMD64 ABI** sono rispettate: argomenti in `%rdi`, valore di ritorno in `%rax`, registri caller-saved preservati.
- Le funzioni sono allineate a **16 byte** con `.align 4` per massimizzare l'efficienza del fetch delle istruzioni dalla cache.
- La free list usa i **primi 8 byte del blocco liberato** come puntatore al nodo successivo, senza strutture dati aggiuntive.

---

## ⚠️ Limitazioni

- Allocazioni supportate: solo blocchi fino a **256 byte** (arrotondati a 64, 128 o 256).
- Il pool ha una dimensione fissa di **10 MB** — non è possibile espanderlo a runtime.
- Comportamento indefinito in caso di chiamata a `free` con un puntatore non valido (specifica di progetto).

---

## 📄 Licenza

Mozilla Public License 2.0, vedi [`LICENSE`](LICENSE).
---

*Keywords: assembly, x86-64, memory allocator, malloc, free list, AT&T syntax, position independent executable, computer architecture, university project.*
