%{
#include <stdio.h>
#include <stdlib.h>
#include "ch3-05.h"
#include <string.h>
#include <math.h>
extern void yyerror(char *errmsg);
%}

%union {
	double dval;
	struct symtab *symp;
}

%token <symp> NAME
%token <dval> NUMBER
%left '+' '-'
%left '*' '/'
%nonassoc UMINUS

%type <dval> expression
%%

statement_list:	statement '\n'
	|	statement_list statement '\n'
	;

statement:	NAME '=' expression	{ $1->value = $3; }
	|	expression		{ printf("= %g\n", $1); }
	;

expression:
		expression '+' expression		{ $$ = $1 + $3; }
|   expression '-' expression		{ $$ = $1 - $3; }
|   expression '*' expression		{ $$ = $1 * $3; }
|   expression '/' expression		{ if($3==0.0) yyerror("Divide by Zero"); else $$ = $1 / $3;  }
|   '-' expression %prec UMINUS	{ $$ = -$2; }
|   '(' expression ')'					{ $$ = $2; }
|   NUMBER											{ $$ = $1; }
|   NAME												{ $$ = $1->value; }
|   NAME '(' expression ')'			{ 
																	if( $1->funcptr ) $$ = ($1->funcptr)($3);
																	else {
																		printf("%s not a function.\n", $1->name);
																	}
																}
;

%%

/* look up a symbol table entry, add if not present */
struct symtab *symlook(char *s)
{
	struct symtab *sp;

	for(sp=symtab; sp<&symtab[NSYMS]; sp++) {
		/* is it already here? */
		if( sp->name && !strcmp(sp->name, s) )  return sp;

		/* is it free */
		if( !sp->name ) {
			sp->name = strdup(s);
			return sp;
		}
		
		/* otherwise continue to next */
	}
	yyerror("Too many symbols");
	exit(1);   /* cannot continue */
} /* end of symlook */

void addfunc(char *name, double (*func)())
{
	struct symtab *sp = symlook(name);
	sp->funcptr = func;
}

int main()
{
	extern double sqrt(), exp(), log(), sin(), cos();

	addfunc("sqrt", sqrt);
	addfunc("exp",  exp);
	addfunc("log",  log);
	addfunc("sin",  sin);
	addfunc("cos",  cos);

	yyparse();

        return 0;
}
