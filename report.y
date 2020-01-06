%{
#include <stdio.h>
#include <stdlib.h>
#include "report.h"
#include <string.h>
#include <math.h>
extern void yyerror(char* errmsg);

//関数が扱える引数の上限数
#define MAXARGNUM 3
//引数の一時格納用のバッファ
double argList[MAXARGNUM];
//現在詰められている引数の数
short argNum = 0;

/*note
ch3-05系を大きく変えずに実装するなら引数の数には上限を設けざるを得ないという結論に至った。

expression, expression , ...の並びをexpression_list記号として扱い、アクションでargListに各expressionを保存する。
$$ = ($1->func)(arg[0], arg[1], arg[2])のように常にMAXARGNUM個の引数を渡して実行するようにする事で対応する。
この仕組みだといhoge(a, fuga(b));のような入れ子構造のコールに対応出来ない
状態とスタックを組み込んだ設計にすれば入れ子に対応出来る
*/

int statement_state = 1;
%}

%union{
  double dval;
  struct symbol* symbolPtr;
  int bval;
  char* charPtr;
}

%token <symbolPtr> NAME
%token <symbolPtr> BOOLEANNAME
%token <symbolPtr> NUMERICNAME
%token <symbolPtr> CHARACTERSNAME
%token <symbolPtr> FUNCNAME
%token <dval> NUMBER
%token <bval> BOOL
%token <charPtr> CHARACTERS
%token IF ENDIF
%left LESS GREAT LEEQ GREQ EQ NOTEQ
%left '+' '-'
%left '*' '/'
%nonassoc UMINUS
%type <dval> expression
%type <bval> logical_expression
%%

statement_list:
  statement                {printf("statement_list : statement\n");}
| statement_list statement {printf("statement_list : statement_list statement\n");}
| statement_list '\n'      {printf("statement_list : statement_list \\n \n"); statement_state = 1;}
;

statement:
  NAME           '=' expression ';'          {printf("statement : 数値代入\n"); if(statement_state==1){$1->value = $3; $1->type = numeric;}}
| NUMERICNAME    '=' expression ';'          {printf("statement : 数値代入\n"); if(statement_state==1){$1->value = $3; $1->type = numeric;}}
| NAME           '=' logical_expression ';'  {printf("statement : 真偽値代入\n"); if(statement_state==1){$1->value = $3; $1->type = boolean;}}
| BOOLEANNAME    '=' logical_expression ';'  {printf("statement : 真偽値代入\n"); if(statement_state==1){$1->value = $3; $1->type = boolean;}}
| NAME           '=' CHARACTERS ';'          {printf("statement : 文字列代入\n"); if(statement_state==1){$1->charPtr = $3; $1->type = characters;}}
| CHARACTERSNAME '=' CHARACTERS ';'          {printf("statement : 文字列代入\n"); if(statement_state==1){$1->charPtr = $3; $1->type = characters;}}
| CHARACTERSNAME ';'                         {printf("statement : CHARACTERSNAME;の並び\n"); if(statement_state==1){printf("= %s\n", $1->charPtr);}}
| expression ';'                             {printf("statement : expression;の並び\n"); if(statement_state==1){printf("= %g\n", $1);}}
| logical_expression ';'                     {
                                                if(statement_state==1){
                                                  if($1 == 1) printf("statement : true\n");
                                                  else printf("statement : false\n");
                                                }
                                             }
| ifstatement                              {printf("statement : ifstatement");}
| endifstatement                           {printf("statement : endifstatement");}
;

expression_list:
  expression                     {printf("expression to expression_list\n"); if(statement_state==1){argList[argNum++] = $1;}}
| expression_list ',' expression {printf("expression_list , expression\n"); if(statement_state==1){argList[argNum++] = $3;}}
;

endifstatement:
  ENDIF { statement_state = 1;}
;

ifstatement:
  IF '(' logical_expression ')' {
                                  printf("logical_statement evaluate : %d\n", $3);
                                  if(statement_state==1){
                                    if($3 == 1) statement_state = 1; else statement_state = 0;
                                  }
                                }
;

logical_expression:
  BOOL                          {printf("BOOL to logical_expression\n"); if(statement_state==1){$$ = $1;}}
| BOOLEANNAME                   {printf("BOOLNAME to logical_expression\n"); if(statement_state==1){$$ = $1->value;}}
| expression LESS expression     { if(statement_state==1){$$ = $1 < $3;}}
| expression GREAT expression    { if(statement_state==1){$$ = $1 > $3;}}
| expression LEEQ expression     { if(statement_state==1){$$ = $1 <= $3;}}
| expression GREQ expression     { if(statement_state==1){$$ = $1 >= $3;}}
| expression EQ expression       { if(statement_state==1){$$ = $1 == $3;}}
| expression NOTEQ expression    { if(statement_state==1){$$ = $1 != $3;}}
;

expression: 
  expression '+' expression   { printf("expression + expression\n"); if(statement_state==1){$$ = $1 + $3;}}
| expression '-' expression   { printf("expression - expression\n"); if(statement_state==1){$$ = $1 - $3;}}
| expression '*' expression   { printf("expression * expression\n"); if(statement_state==1){$$ = $1 * $3;}}
| expression '/' expression   { printf("expression / expression\n"); if(statement_state==1){if($3 == 0.0) yyerror("Devide by zero"); else $$ = $1 / $3;}}
| '-' expression %prec UMINUS { printf("-expression %prec UMINUS\n"); if(statement_state==1){$$ = -$2;}}
| '(' expression ')'          { printf("(expression)\n"); if(statement_state==1){$$ = $2;}}
| NUMBER                      { printf("NUMBER to expression\n"); if(statement_state==1){$$ = $1;}}
| NUMERICNAME                        { printf("NUMERICNAME to expression\n");  if(statement_state==1){$$ = $1->value;}}
| FUNCNAME '(' expression_list ')'{  
                                    if($1 -> funcptr){
                                      //MAXARGNUMがいくつかに依ってここの引数の記述は変わる。
                                      if(statement_state==1){
                                        $$ = ($1->funcptr)(argList[0], argList[1], argList[2]);
                                        argNum = 0;
                                      }
                                    }else{
                                      printf("%s not a function.\n", $1->name);
                                    }
                                  }
;

%%

/*変数名nameの変数をテーブルから取得（無ければ追加）*/
struct symbol* lookSymbol(char* name){
  struct symbol* ptr;

  for(ptr = symbolTable; ptr < &symbolTable[SYMBOLNUM]; ptr++){
    if(ptr->name && !strcmp(ptr->name, name)) return ptr;

    /*見つからずに末尾まで到達したら追加*/
    if(!ptr->name){
      ptr->name = strdup(name);
      ptr->type = undefined;
      return ptr;
    }
  }

  yyerror("Too many symbols");
  exit(1);
}

void addfunc(char* name, double (*func)()){
  struct symbol* ptr = lookSymbol(name);
  ptr->funcptr = func;
  ptr->type = function;
}

double triangle(double a, double h);
double trapezoid(double a, double b, double h);

int main(){
  extern double sqrt(), exp(), log(), sin(), cos(), pow();
  double triangle(), trapezoid();

  addfunc("sqrt", sqrt);
  addfunc("exp",  exp);
  addfunc("log",  log);
  addfunc("sin",  sin);
  addfunc("cos",  cos);
  addfunc("pow",  pow);
  addfunc("triangle",  triangle);
  addfunc("trapezoid",  trapezoid);

  yyparse();
  return 0;
}
double triangle(double a, double h){
  return a*h/2.0;
}
double trapezoid(double a, double b, double h){
  return (a+b)*h/2.0;
}
//strdup忘れてた