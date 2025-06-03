/* Analizador Sintáctico con Bison para Reglas de Acceso */

%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

extern int yylex();
extern int yyparse();
extern FILE* yyin;
void yyerror(const char* s);
%}

/* Definición de tipos de datos para tokens */
%union {
    int number;
    char* string;
}

/* Declaración de tokens */
%token USER ADMIN GUEST OPERATOR HOUR DAY RESOURCE
%token AND OR NOT
%token EQUAL NOT_EQUAL GREATER LESS GREATER_EQ LESS_EQ
%token LPAREN RPAREN
%token <number> NUMBER
%token <string> STRING IDENTIFIER

/* Declaración de tipos para las reglas no terminales */
%type <string> role_type
%type <number> value

/* Precedencia de operadores (menor a mayor) */
%left OR
%left AND  
%right NOT

/* Símbolo inicial */
%start access_rule

%%

/* Reglas de la gramática */
access_rule:
    user_clause AND logical_expression  { 
        printf("✅ Tipo: Usuario con condiciones\n");
        printf("✅ Regla válida\n"); 
    }
    | user_clause                       { 
        printf("✅ Tipo: Solo usuario\n");
        printf("✅ Regla válida\n"); 
    }
    ;

user_clause:
    USER role_type                      { printf("Usuario: %s\n", $2); }
    ;

role_type:
    ADMIN                               { $$ = "admin"; }
    | GUEST                             { $$ = "guest"; }
    | OPERATOR                          { $$ = "operator"; }
    ;

logical_expression:
    logical_term                        
    | logical_expression OR logical_term { printf("Operación OR\n"); }
    ;

logical_term:
    logical_factor                      
    | logical_term AND logical_factor   { printf("Operación AND\n"); }
    ;

logical_factor:
    condition                           
    | NOT logical_factor                { printf("Operación NOT\n"); }
    | LPAREN logical_expression RPAREN  { printf("Expresión entre paréntesis\n"); }
    ;

condition:
    time_condition                      
    | resource_condition                
    | custom_condition                  
    ;

time_condition:
    HOUR comparison_op NUMBER           { printf("Condición de hora: %d\n", $3); }
    | DAY comparison_op STRING          { printf("Condición de día: %s\n", $3); }
    ;

resource_condition:
    RESOURCE comparison_op STRING       { printf("Condición de recurso: %s\n", $3); }
    | RESOURCE comparison_op IDENTIFIER { printf("Condición de recurso: %s\n", $3); }
    ;

custom_condition:
    IDENTIFIER comparison_op value      { printf("Condición personalizada: %s\n", $1); }
    ;

value:
    NUMBER                              { $$ = $1; }
    | STRING                            { $$ = 0; /* Valor por defecto para strings */ }
    | IDENTIFIER                        { $$ = 0; /* Valor por defecto para identificadores */ }
    ;

comparison_op:
    EQUAL                               { printf("Operador: =\n"); }
    | NOT_EQUAL                         { printf("Operador: !=\n"); }
    | GREATER                           { printf("Operador: >\n"); }
    | LESS                              { printf("Operador: <\n"); }
    | GREATER_EQ                        { printf("Operador: >=\n"); }
    | LESS_EQ                           { printf("Operador: <=\n"); }
    ;

%%

/* Función de manejo de errores */
void yyerror(const char* s) {
    printf("❌ Error sintáctico: %s\n", s);
    printf("DEBUG: Último token procesado podría ser problemático\n");
}

/* Debug function */
void debug_token(const char* token_name) {
    printf("DEBUG: Token reconocido: %s\n", token_name);
}

/* Función principal */
int main(int argc, char** argv) {
    printf("🚀 Analizador de Reglas de Acceso\n");
    printf("==================================\n");
    
    if (argc > 1) {
        FILE* file = fopen(argv[1], "r");
        if (!file) {
            printf("Error: No se puede abrir el archivo %s\n", argv[1]);
            return 1;
        }
        yyin = file;
        printf("📁 Procesando archivo: %s\n", argv[1]);
    } else {
        printf("📝 Ingrese reglas de acceso (Enter y luego Ctrl+D para terminar):\n");
        yyin = stdin;
    }
    
    printf("-----------------------------------\n");
    
    // Ejecutar el analizador
    int result = yyparse();
    
    if (result == 0) {
        printf("-----------------------------------\n");
        printf("🎉 ¡Análisis completado exitosamente!\n");
    } else {
        printf("-----------------------------------\n");
        printf("💥 Se encontraron errores en el análisis\n");
    }
    
    if (argc > 1) {
        fclose(yyin);
    }
    
    return result;
}