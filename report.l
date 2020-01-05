%{
	#include "y.tab.h"
	#include "report.h"
	#include <math.h>
	#include <stdio.h>
	
%}

%%

if {
	printf("if token\n");
	return IF;
}
endif {
	printf("endif token\n");
	return ENDIF;
}
true {
	printf("true  token\n");
	yylval.bval = 1;
	return BOOL;
}
false {
	printf("falsae token\n");
	yylval.bval = 0;
	return BOOL;
}

"<=" {return LEEQ;}
">=" {return GREQ;}
"==" {return EQ;}
"!=" {return NOTEQ;}
"<" {return LESS;}
">" {return GREAT;}


([0-9]+|([0-9]*\.[0-9]+)([eE][-+]?[0-9]+)?)	{
	printf("num token %g\n", atof(yytext));
	yylval.dval = atof(yytext);
	return NUMBER;
}

[ \t] ;

[a-zA-Z][a-zA-Z0-9]*	{
	printf("symbol token : %s\n", yytext);
	struct symbol* symbolPtr = lookSymbol(yytext);
	yylval.symbolPtr = symbolPtr;
	switch(symbolPtr->type){
		case numeric: return NUMERICNAME; 
		case boolean: return BOOLEANNAME; 
		case function: return FUNCNAME;
		default: return NAME;
	}
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