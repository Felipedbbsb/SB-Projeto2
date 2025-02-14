#include <stdio.h>
#include <stdlib.h>
#include "carregador.h"

int main(int argc, char *argv[])
{
    /*
        ./carregador 125 100 500 4000 300 20000 125 30000 345
       Where:
         - argv[1] = size of the fictitious program (125)
         - Next pairs = (startAddress, sizeOfBlock)
         - Up to 4 pairs (8 integers) + 1 for program size => up to 9 total.
    */

    if (argc < 2) {
        printf("Usage: %s <program_size> [<blockStart1> <blockSize1>] ...\n", argv[0]);
        return 1;
    }

    // Prepare a local array to store command-line parameters (not global
    int params[9];
    int count = argc - 1;
    if (count > 9) {
        count = 9; // limit to 9 integers (4 pairs + 1)
    }

    for (int i = 0; i < count; i++) {
        params[i] = atoi(argv[i + 1]);
    }

    // Structure to store the allocation result (local, not global) 
    struct AllocationResult result;

    // Call the Assembly function that handles allocation logic 
    allocateProgram(params, count, &result);

    // test
    printf("TEST: usedBlockCount = %d\n", result.usedBlockCount);
    printf("TEST: success = %d\n", result.success);

    for (int i = 0; i < result.usedBlockCount; i++) {
        printf("TEST: Block %d => start=%d, end=%d\n",
               i, result.blocks[i].start, result.blocks[i].end);
    }
    // make
    // ./carregador 125 100 500 4000 300 20000 125 30000 345
    // The program in te example has size 125, so if it starts at 100, it ends at address 224 (because 224 − 100 + 1 = 125).
    // Call the Assembly function that prints the results 
    // printResult(&result);

    return 0;
}
