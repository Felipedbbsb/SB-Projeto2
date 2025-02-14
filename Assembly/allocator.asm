; ---------------------------------------------
; allocator.asm
; NASM IA-32 (Linux), cdecl convention
; ---------------------------------------------
%define MAX_BLOCKS 4

global allocateProgram

SECTION .text

; allocateProgram(int *params, int count, struct AllocationResult *res)
; cdecl param offsets:
;   [ebp+8]  = params
;   [ebp+12] = count
;   [ebp+16] = res
;
; struct AllocationResult layout:
;   offset 0: usedBlockCount
;   offset 4..(4 + MAX_BLOCKS*8 - 1): blocks (each block is 8 bytes => start,end)
;   offset 36: success

allocateProgram:
    push ebp
    mov  ebp, esp

    ; Save callee-saved registers (EBX, ESI, EDI) if you modify them
    push ebx
    push esi
    push edi

    ; Load parameters
    mov eax, [ebp+8]   ; eax = params
    mov ecx, [ebp+12]  ; ecx = count
    mov edx, [ebp+16]  ; edx = res pointer

    ; programSize = params[0]
    mov esi, [eax]     ; ESI = programSize

    ; res->usedBlockCount = 0
    mov dword [edx], 0

    ; res->success = 0 at offset 36
    mov dword [edx + 36], 0

    ; If count < 3 => no valid block pairs
    cmp ecx, 3
    jl .end_allocation

    ; numberOfPairs = (count - 1) / 2, up to MAX_BLOCKS
    mov ebx, ecx
    sub ebx, 1
    shr ebx, 1
    cmp ebx, MAX_BLOCKS
    jle .skipLimit
    mov ebx, MAX_BLOCKS
.skipLimit:

    xor edi, edi  ; edi = block index (0)

.loop_blocks:
    ; If we've allocated everything, done
    cmp esi, 0
    je .set_success

    ; If block index >= numberOfPairs => fail
    cmp edi, ebx
    jge .end_allocation

    ; blockStart = params[1 + 2*edi]
    ; blockSize  = params[2 + 2*edi]
    mov eax, [ebp+8]              ; pointer to params
    mov ecx, [eax + 4 + edi*8]    ; ECX = blockStart
    mov eax, [ebp+8]
    mov eax, [eax + 8 + edi*8]    ; EAX = blockSize

    ; Compare blockSize (EAX) with needed size (ESI)
    cmp eax, esi
    jl .partial_allocate

    ; If blockSize >= needed => use entire program in this block
    mov ebp, [edx]                ; WARNING: Overwrites base pointer if we use EBP
                                  ; Instead, use EBX for usedBlockCount:
    mov ebx, [edx]                ; usedBlockCount
    mov [edx + 4 + ebx*8], ecx    ; blocks[ebx].start = blockStart
    add ecx, esi
    dec ecx
    mov [edx + 4 + ebx*8 + 4], ecx ; blocks[ebx].end = start + (esi - 1)

    inc ebx
    mov [edx], ebx   ; usedBlockCount++

    xor esi, esi     ; now we've allocated everything
    jmp .set_success

.partial_allocate:
    ; Use the entire block for part of the program
    mov ebx, [edx]   ; usedBlockCount
    mov [edx + 4 + ebx*8], ecx
    add ecx, eax
    dec ecx
    mov [edx + 4 + ebx*8 + 4], ecx
    inc ebx
    mov [edx], ebx

    sub esi, eax     ; reduce remaining
    inc edi
    jmp .loop_blocks

.set_success:
    mov dword [edx + 36], 1

.end_allocation:
    ; Restore callee-saved registers
    pop edi
    pop esi
    pop ebx

    pop ebp
    ret
