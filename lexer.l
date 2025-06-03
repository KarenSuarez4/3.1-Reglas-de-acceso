%{
#include <stdio.h>
#include "parser.tab.h"
%}

LETTER      [a-zA-Z]
DIGIT       [0-9]
IDENTIFIER  {LETTER}({LETTER}|{DIGIT}|_)*
NUMBER      {DIGIT}+
STRING      '([^'])*'
WHITESPACE  [ \t\n]+

%%

"user"      { return USER; }
"admin"     { return ADMIN; }
"guest"     { return GUEST; }
"operator"  { return OPERATOR; }
"hour"      { return HOUR; }
"day"       { return DAY; }
"resource"  { return RESOURCE; }
"AND"       { return AND; }
"OR"        { return OR; }
"NOT"       { return NOT; }

">="        { return GREATER_EQ; }
"<="        { return LESS_EQ; }
"!="        { return NOT_EQUAL; }
">"         { return GREATER; }
"<"         { return LESS; }
"="         { return EQUAL; }

"("         { return LPAREN; }
")"         { return RPAREN; }

{NUMBER}    { 
    yylval.number = atoi(yytext); 
    return NUMBER; 
}

{STRING}    { 
    yylval.string = strdup(yytext); 
    return STRING; 
}

{IDENTIFIER} { 
    yylval.string = strdup(yytext); 
    return IDENTIFIER; 
}

{WHITESPACE} { }

.           { return yytext[0]; }

%%

int yywrap() {
    return 1;
}