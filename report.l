%{
	#include "y.tab.h"
	#include "report.h"
	#include <math.h>
%}

%%

([0-9]+|([0-9]*\.[0-9]+)([eE][-+]?[0-9]+)?)	{
	yylval.dval = atof(yytext);
	return NUMBER;
}

[ \t] ;

[a-zA-Z][a-zA-Z0-9]*	{
	struct symbolTable* symbolPtr = lookSymbol(yytext);
	yylval.symbolPtr = symbolPtr;
	return NAME;
}

"$" {return 0;}

\n |
. return yytext[0];

%%

void yyerror(char* errmsg){
	//stderrはエラー出力
	fprintf(stderr, "ERROR: %s at %s\n", errmsg, yytext);
}

/*
\n |
. return yytext[0];

を

\n | . return yytext[0];

にしたらダメ
*/