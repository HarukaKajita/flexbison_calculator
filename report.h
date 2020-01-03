#ifndef REPORTHEADER
#define REPORTHEADER
#define SYMBOLNUM 20

struct symbolTable{
        char* name;
        double (*funcptr)();
        double value;
} symbolTable[SYMBOLNUM];

struct symbolTable* lookSymbol(char* name);
#endif