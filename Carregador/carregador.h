#ifndef CARREGADOR_H
#define CARREGADOR_H

#define MAX_BLOCKS 4

// Represents one allocated block 
struct BlockUsed {
    int start;
    int end;
};

// Structure used to store the allocation result 
struct AllocationResult {
    int usedBlockCount;               // How many blocks were actually used 
    struct BlockUsed blocks[MAX_BLOCKS];
    int success;                      // 1 = allocated successfully, 0 = failed 
};

// Function declarations (Assembly externs) 
extern void allocateProgram(int *params, int count, struct AllocationResult *res);
extern void printResult(struct AllocationResult *res);

#endif 
