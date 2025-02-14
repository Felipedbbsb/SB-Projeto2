; Assembly/allocator.asm
; NASM IA-32, cdecl convention
; Implements multi‐block allocation logic as described.
%define MAX_BLOCKS 4

global allocateProgram
SECTION .text
; allocateProgram(int *params, int count, AllocationResult *res)
; Parameters (cdecl):
;   [ebp+8]  : pointer to params array (params[0] = program size,
;             then pairs: params[1] = blockStart, params[2] = blockSize, …)
;   [ebp+12] : count (number of ints in params)
;   [ebp+16] : pointer to AllocationResult (structure layout):
;             offset 0: usedBlockCount (int)
;             offset 4: blocks[0].start, offset 8: blocks[0].end,
;             … (each block takes 8 bytes), offset 36: success (int)
allocateProgram:
    push ebp
    mov  ebp, esp
    sub  esp, 8           ; allocate 8 bytes for locals:
                          ; [ebp-4] = numPairs, [ebp-8] = loopIndex
    push ebx
    push esi
    push edi

    ; --- Load parameters ---
    ; [ebp+8] = pointer to params, [ebp+12] = count, [ebp+16] = result pointer (R)
    mov  eax, [ebp+8]     ; EAX = params pointer
    mov  ecx, [ebp+12]    ; ECX = count
    mov  edx, [ebp+16]    ; EDX = result pointer (R)

    ; Load remaining = program size from params[0]
    mov  esi, [eax]       ; ESI = remaining (program size)

    ; Initialize result: usedBlockCount = 0, success = 0.
    mov  dword [edx], 0
    mov  dword [edx+36], 0

    cmp  ecx, 3
    jl   allocation_end   ; not enough arguments → no blocks provided

    ; --- Compute number of block pairs ---
    ; numPairs = (count - 1) / 2, but limited to MAX_BLOCKS.
    mov  ebx, ecx
    sub  ebx, 1
    shr  ebx, 1
    cmp  ebx, MAX_BLOCKS
    jle  set_num
    mov  ebx, MAX_BLOCKS
set_num:
    mov  [ebp-4], ebx     ; store numPairs in local variable

    ; Initialize loop index to 0 (stored in [ebp-8])
    mov  dword [ebp-8], 0

loop_start:
    ; Load loop index from local variable.
    mov  edi, [ebp-8]     ; EDI = loop index
    ; If remaining (ESI) is 0, allocation is complete.
    cmp  esi, 0
    je   set_success

    ; Load numPairs from local.
    mov  ebx, [ebp-4]     ; EBX = numPairs
    cmp  edi, ebx
    jge  allocation_end   ; no more block pairs available

    ; --- Compute offset for current block pair ---
    ; Each block pair occupies 2 integers.
    ; The first block pair is at index 1 (params[1] & params[2]),
    ; so offset = 4 * (1 + 2*loop_index).
    mov  ecx, edi
    shl  ecx, 1         ; ECX = 2 * loop_index
    add  ecx, 1         ; ECX = 1 + 2 * loop_index
    imul ecx, 4         ; ECX = (1 + 2*loop_index)*4

    ; --- Load blockStart and blockSize from params ---
    mov  eax, [ebp+8]    ; EAX = params pointer
    mov  ebx, [eax+ecx]  ; EBX = blockStart
    add  ecx, 4         ; now offset for blockSize = previous offset + 4
    mov  edx, [eax+ecx]  ; EDX = blockSize

    ; --- Check if this block can hold the remaining program ---
    cmp  edx, esi
    jge  fits_whole    ; if blockSize >= remaining, use part of this block

    ; --- Partial Allocation: use entire block ---
    ; Get result pointer R from [ebp+16]:
    mov  eax, [ebp+16]   ; EAX = R
    ; Get current usedBlockCount from R:
    mov  ecx, [eax]      ; ECX = usedBlockCount
    ; Store blockStart into R->blocks[usedBlockCount].start:
    mov  dword [eax + 4 + ecx*8], ebx

    ; Compute blockEnd = blockStart + blockSize - 1.
    ; Use EAX as scratch: first, preserve R by reloading later.
    push eax             ; save R on stack
    mov  eax, ebx        ; EAX = blockStart
    add  eax, edx        ; EAX = blockStart + blockSize
    dec  eax            ; EAX = blockStart + blockSize - 1
    pop  edi             ; restore R into EDI (now EDI = R)
    ; Store blockEnd into R->blocks[usedBlockCount].end:
    mov  dword [edi + 4 + ecx*8 + 4], eax

    ; Increment usedBlockCount:
    inc  ecx
    mov  [edi], ecx

    ; Subtract blockSize from remaining:
    sub  esi, edx

    ; Increment loop index.
    mov  eax, [ebp-8]
    inc  eax
    mov  [ebp-8], eax

    jmp  loop_start

fits_whole:
    ; This block can hold the remaining part of the program.
    mov  eax, [ebp+16]   ; EAX = R (result pointer)
    mov  ecx, [eax]      ; ECX = usedBlockCount
    ; Store blockStart:
    mov  dword [eax + 4 + ecx*8], ebx
    ; Compute blockEnd = blockStart + remaining - 1.
    mov  edx, esi       ; EDX = remaining
    mov  edi, ebx       ; EDI = blockStart
    add  edi, edx       ; EDI = blockStart + remaining
    dec  edi           ; EDI = blockStart + remaining - 1
    mov  dword [eax + 4 + ecx*8 + 4], edi
    inc  ecx
    mov  [eax], ecx     ; update usedBlockCount
    ; Set remaining to 0.
    xor esi, esi
    jmp  set_success

set_success:
    ; Mark allocation as successful.
    mov  eax, [ebp+16]   ; result pointer R
    mov  dword [eax+36], 1   ; success = 1

allocation_end:
    pop  edi
    pop  esi
    pop  ebx
    add  esp, 8
    pop  ebp
    ret
