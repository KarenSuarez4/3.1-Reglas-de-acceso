/**
 * Analizador Léxico para Reglas de Acceso.
 * Define los tokens y patrones para el análisis de reglas de control de acceso.
 */

%{
/**
 * Sección de declaraciones de C.
 * Incluye las librerías necesarias y las declaraciones de funciones externas.
 */

#include <stdio.h>
#include "parser.tab.h"
%}

/**
 * Definición de patrones regulares utilizados en el léxico.
 * Estos patrones serán referenciados en las reglas de abajo.
 */

LETTER      [a-zA-Z]
DIGIT       [0-9]
IDENTIFIER  {LETTER}({LETTER}|{DIGIT}|_)*
NUMBER      {DIGIT}+
STRING      '([^'])*'
WHITESPACE  [ \t\n]+

/**
 * Reglas de reconocimiento de tokens para los elementos del lenguaje.
 * Cada regla devuelve el token correspondiente al analizador sintáctico.
 * Tokens para elementos de usuario, roles, condiciones temporales, recursos, operadores lógicos, 
 * operadores de comparación 7 simbolos de agrupación, .
 * Definen los diferentes tipos de usuarios y sus permisos.
 * 
 */

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


/** 
 * Función requerida por Flex para determinar el final del análisis.
 * Devuelve 1 para indicar que no hay más archivos a procesar.
 */
int yywrap() {
    return 1;
}