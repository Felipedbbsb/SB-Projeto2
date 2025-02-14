; Assembly/allocator.asm
; NASM IA-32, cdecl convention
%define MAX_BLOCKS 4

global allocateProgram
SECTION .text
allocateProgram:
    push ebp
    mov  ebp, esp
    ; Reserve space for three locals:
    ; [ebp-4]  : numPairs (number of block pairs available)
    ; [ebp-8]  : loop index
    ; [ebp-12] : remaining (program size remaining to allocate)
    sub  esp, 12

    push ebx
    push esi
    push edi

    ; --- Load parameters ---
    ; [ebp+8]  = pointer to params array
    ; [ebp+12] = count (number of ints in params)
    ; [ebp+16] = pointer to AllocationResult (result)
    mov  eax, [ebp+8]     ; EAX = params pointer
    mov  ecx, [ebp+12]    ; ECX = count
    mov  edx, [ebp+16]    ; EDX = result pointer (R)

    ; remaining = program size = params[0]
    mov  esi, [eax]       ; ESI = program size
    mov  dword [ebp-12], esi  ; remaining = program size

    ; Initialize result: usedBlockCount = 0, success = 0.
    mov  dword [edx], 0
    mov  dword [edx+36], 0

    cmp  ecx, 3
    jl   done_alloc       ; not enough arguments

    ; --- Compute number of block pairs ---
    ; numPairs = (count - 1) / 2, limited to MAX_BLOCKS.
    mov  ebx, ecx
    sub  ebx, 1
    shr  ebx, 1
    cmp  ebx, MAX_BLOCKS
    jle  set_num
    mov  ebx, MAX_BLOCKS
set_num:
    mov  dword [ebp-4], ebx   ; store numPairs in [ebp-4]

    ; === Phase 1: Search for a block that can hold the entire program ===
    mov  dword [ebp-8], 0     ; loop index = 0
search_loop:
    mov  eax, [ebp-4]     ; numPairs
    mov  ebx, [ebp-8]     ; current index
    cmp  ebx, eax
    jge  no_fit_found     ; reached end without finding a fitting block

    ; Compute offset = 4*(1 + 2*loop_index)
    mov  ecx, ebx
    shl  ecx, 1         ; ecx = 2*loop_index
    add  ecx, 1         ; ecx = 1 + 2*loop_index
    imul ecx, 4         ; ecx = 4*(1+2*loop_index)
    ; Load blockSize = params[offset + 4]
    mov  eax, [ebp+8]   ; pointer to params
    mov  edi, [eax+ecx+4]  ; edi = blockSize
    cmp  edi, esi       ; compare blockSize with program size (in esi)
    jl   next_search   ; if blockSize < program size, continue
    ; Found a block that fits entirely.
    ; Load blockStart = params[offset]
    mov  edi, [eax+ecx] ; edi = blockStart
    ; Record in result: blocks[0].start = edi
    mov  dword [edx+4], edi
    ; Compute end = blockStart + program size - 1
    mov  eax, edi
    add  eax, esi
    dec  eax
    mov  dword [edx+8], eax
    ; Set usedBlockCount = 1 and success = 1.
    mov  dword [edx], 1
    mov  dword [edx+36], 1
    jmp  done_alloc
next_search:
    inc  dword [ebp-8]
    jmp  search_loop

no_fit_found:
    ; === Phase 2: Splitting Allocation ===
    ; Reset loop index to 0.
    mov  dword [ebp-8], 0
split_loop:
    ; If remaining == 0, allocation is complete.
    mov  eax, [ebp-12]
    cmp  eax, 0
    je   set_success_split
    ; Check if we still have block pairs available.
    mov  eax, [ebp-4]    ; numPairs
    mov  ebx, [ebp-8]    ; current index
    cmp  ebx, eax
    jge  allocation_end_split  ; no more blocks; allocation fails (success remains 0)
    ; Compute offset = 4*(1 + 2*loop_index)
    mov  ecx, ebx
    shl  ecx, 1
    add  ecx, 1
    imul ecx, 4         ; ecx = offset in bytes
    mov  eax, [ebp+8]    ; pointer to params
    ; Load blockStart into esi.
    mov  esi, [eax+ecx]  ; esi = blockStart
    ; Load blockSize into edi.
    mov  edi, [eax+ecx+4]  ; edi = blockSize
    ; Compare blockSize (edi) with remaining (stored at [ebp-12])
    mov  eax, [ebp-12]   ; eax = remaining
    cmp  edi, eax
    jle  full_alloc_block  ; if blockSize <= remaining, allocate full block
    ; Else, allocate partially.
    mov  eax, [ebp+16]   ; result pointer R
    ; Get current usedBlockCount from R.
    mov  ecx, [eax]
    ; Record block: start = blockStart (in esi)
    mov  dword [eax+4+ecx*8], esi
    ; Compute allocated end = blockStart + remaining - 1.
    mov  ebx, [ebp-12]   ; remaining in ebx
    mov  edi, esi        ; edi = blockStart
    add  edi, ebx
    dec  edi            ; allocated end = blockStart + remaining - 1
    mov  dword [eax+4+ecx*8+4], edi
    inc  ecx
    mov  [eax], ecx      ; update usedBlockCount
    ; Set remaining to 0.
    mov  dword [ebp-12], 0
    jmp  next_split

full_alloc_block:
    ; Allocate full block.
    mov  eax, [ebp+16]   ; result pointer R
    mov  ecx, [eax]      ; usedBlockCount
    mov  dword [eax+4+ecx*8], esi   ; record start = blockStart
    ; Compute end = blockStart + blockSize - 1 (blockSize in edi)
    mov  ebx, esi
    add  ebx, edi
    dec  ebx
    mov  dword [eax+4+ecx*8+4], ebx
    inc  ecx
    mov  [eax], ecx     ; update usedBlockCount
    ; Subtract blockSize from remaining.
    mov  eax, [ebp-12]
    sub  eax, edi
    mov  [ebp-12], eax

next_split:
    inc  dword [ebp-8]
    jmp  split_loop

set_success_split:
    mov  eax, [ebp+16]  ; result pointer R
    mov  dword [eax+36], 1  ; success = 1

allocation_end_split:
done_alloc:
    pop edi
    pop esi
    pop ebx
    add esp, 12
    pop ebp
    ret
