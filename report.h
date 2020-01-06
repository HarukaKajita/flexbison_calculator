#ifndef REPORTHEADER
#define REPORTHEADER
#define SYMBOLNUM 20

typedef enum symbolType{
        undefined,
        numeric,
        boolean,
        characters,
        function
} t_symbolType;

struct symbol{
        char* name;
        t_symbolType type;
        //-------------------
        double (*funcptr)();
        double value;
        char* charPtr;
} symbolTable[SYMBOLNUM];

struct symbol* lookSymbol(char* name);
#endif