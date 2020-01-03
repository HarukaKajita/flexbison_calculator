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
%}

%union{
  double dval;
  struct symbolTable* symbolPtr;
}

%token <symbolPtr> NAME
%token <dval> NUMBER
%left '+' '-'
%left '*' '/'
%nonassoc UMINUS
%type <dval> expression

%%

statement_list:
  statement
| statement_list statement
| statement_list '\n'
;

statement:
  NAME '=' expression ';'   {$1->value = $3;}
| NAME '=' expression '\n'  {$1->value = $3;}
| expression ';'            {printf("= %g\n", $1);}
| expression '\n'           {printf("= %g\n", $1);}
;

expression_list:
  expression                     {argList[argNum++] = $1;}
| expression_list ',' expression {argList[argNum++] = $3;} 
;

expression: 
  expression '+' expression   {$$ = $1 + $3;}
| expression '-' expression   {$$ = $1 - $3;}
| expression '*' expression   {$$ = $1 * $3;}
| expression '/' expression   {if($3 == 0.0) yyerror("Devide by zero"); else $$ = $1 / $3;}
| '-' expression %prec UMINUS {$$ = -$2;} 
| '(' expression ')'          {$$ = $2;}
| NUMBER                      {$$ = $1;}
| NAME                        {$$ = $1->value;}
| NAME '(' expression_list ')'{
                                if($1 -> funcptr){
                                  //MAXARGNUMがいくつかに依ってここの引数の記述は変わる。
                                  $$ = ($1->funcptr)(argList[0], argList[1], argList[2]);
                                  argNum = 0;
                                }else{
                                  printf("%s not a function.\n", $1->name);
                                }
                              }
;

%%

/*変数名nameの変数をテーブルから取得（無ければ追加）*/
struct symbolTable* lookSymbol(char* name){
  struct symbolTable* ptr;

  for(ptr = symbolTable; ptr < &symbolTable[SYMBOLNUM]; ptr++){
    if(ptr->name && !strcmp(ptr->name, name)) return ptr;

    /*見つからずに末尾まで到達したら追加*/
    if(!ptr->name){
      ptr->name = strdup(name);
      return ptr;
    }
  }

  yyerror("Too many symbols");
  exit(1);
}

void addfunc(char* name, double (*func)()){
  struct symbolTable* ptr = lookSymbol(name);
  ptr->funcptr = func;
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