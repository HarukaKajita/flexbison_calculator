#ifndef REPORTHEADER
#define REPORTHEADER
#define SYMBOLNUM 20

typedef enum symbolType{
        undefined,
        numeric,
        boolean,
        function
} t_symbolType;

struct symbol{
        char* name;
        t_symbolType type;
        //-------------------
        double (*funcptr)();
        double value;
} symbolTable[SYMBOLNUM];

struct symbol* lookSymbol(char* name);
#endif