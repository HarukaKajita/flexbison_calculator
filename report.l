%{
	#include "y.tab.h"
	#include "report.h"
	#include <math.h>
	#include <stdio.h>
	#include <string.h>
%}

%%

if {
	return IF;
}
endif {
	return ENDIF;
}
true {
	yylval.bval = 1;
	return BOOL;
}
false {
	yylval.bval = 0;
	return BOOL;
}

"<=" {return LEEQ;}
">=" {return GREQ;}
"==" {return EQ;}
"!=" {return NOTEQ;}
"<" {return LESS;}
">" {return GREAT;}

\"[^\"]*\" {
	size_t size = strlen(yytext)-2;//""の分小さく
	const char* charsHead = &yytext[1];
	char* characters = (char*)strndup(charsHead, size);
	yylval.charPtr = characters;
	return CHARACTERS;
}

([0-9]+|([0-9]*\.[0-9]+)([eE][-+]?[0-9]+)?)	{
	yylval.dval = atof(yytext);
	return NUMBER;
}

[ \t] ;

[a-zA-Z][a-zA-Z0-9]*	{
	struct symbol* symbolPtr = lookSymbol(yytext);
	yylval.symbolPtr = symbolPtr;
	switch(symbolPtr->type){
		case numeric:    return NUMERICNAME; 
		case boolean:    return BOOLEANNAME; 
		case characters: return CHARACTERSNAME; 
		case function:   return FUNCNAME;
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