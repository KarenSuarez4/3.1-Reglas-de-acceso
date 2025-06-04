/**
 * Analizador Sintáctico con Bison para Reglas de Acceso.
 * Define la gramática para validar reglas de control de acceso
 * utilizadas en sistemas de seguridad.
 */

%{
/**
 * Sección de declaraciones de C.
 * Incluye las librerías necesarias y las declaraciones de funciones externas.
 */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

extern int yylex();
extern int yyparse();
extern FILE* yyin;
void yyerror(const char* s);
%}

/**
 * Definición de tipos de datos para tokens.
 * Especifica los tipos de valores semánticos que pueden tener los tokens.
 */
%union {
    int number;
    char* string;
}

/**
 * Declaración de tokens terminales de la gramática.
 * Define los símbolos terminales reconocidos por el analizador léxico.
 */
%token USER ADMIN GUEST OPERATOR HOUR DAY RESOURCE
%token AND OR NOT
%token EQUAL NOT_EQUAL GREATER LESS GREATER_EQ LESS_EQ
%token LPAREN RPAREN
%token <number> NUMBER
%token <string> STRING IDENTIFIER

/**
 * Declaración de tipos para las reglas no terminales.
 * Asocia tipos de datos a los símbolos no terminales de la gramática.
 */
%type <string> role_type
%type <number> value

/**
 * Precedencia de operadores (de menor a mayor).
 * Define la prioridad de los operadores para resolver ambigüedades.
 */
%left OR
%left AND  
%right NOT

/**
 * Símbolo inicial de la gramática.
 * Indica al parser dónde comenzar el análisis.
 */
%start access_rule

%%

/**
 * Reglas de la gramática.
 * Define la estructura sintáctica de las reglas de acceso.
 */

/**
 * Regla principal que define los tipos de reglas de acceso aceptadas.
 * Puede ser un usuario con condiciones o solo un usuario.
 */
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

/**
 * Define una cláusula de usuario.
 * Consiste en la palabra clave 'user' seguida de un tipo de rol.
 */
user_clause:
    USER role_type                      { printf("Usuario: %s\n", $2); }
    ;

/**
 * Define los tipos de roles disponibles.
 * Cada rol se traduce a su representación en string.
 */
role_type:
    ADMIN                               { $$ = "admin"; }
    | GUEST                             { $$ = "guest"; }
    | OPERATOR                          { $$ = "operator"; }
    ;

/**
 * Define expresiones lógicas que pueden contener operadores OR.
 * Permite conectar múltiples términos lógicos mediante disyunción.
 */
logical_expression:
    logical_term                        
    | logical_expression OR logical_term { printf("Operación OR\n"); }
    ;

/**
 * Define términos lógicos que pueden contener operadores AND.
 * Permite conectar múltiples factores lógicos mediante conjunción.
 */
logical_term:
    logical_factor                      
    | logical_term AND logical_factor   { printf("Operación AND\n"); }
    ;

/**
 * Define factores lógicos que pueden ser condiciones, negaciones o expresiones agrupadas.
 * Los factores son los elementos básicos de las expresiones lógicas.
 */
logical_factor:
    condition                           
    | NOT logical_factor                { printf("Operación NOT\n"); }
    | LPAREN logical_expression RPAREN  { printf("Expresión entre paréntesis\n"); }
    ;

/**
 * Define los tipos de condiciones disponibles.
 * Pueden ser condiciones de tiempo, recurso o personalizadas.
 */
condition:
    time_condition                      
    | resource_condition                
    | custom_condition                  
    ;

/**
 * Define condiciones relacionadas con el tiempo.
 * Permite especificar restricciones de hora o día de la semana.
 */
time_condition:
    HOUR comparison_op NUMBER           { printf("Condición de hora: %d\n", $3); }
    | DAY comparison_op STRING          { printf("Condición de día: %s\n", $3); }
    ;

/**
 * Define condiciones relacionadas con recursos.
 * Permite especificar restricciones sobre los recursos accesibles.
 */
resource_condition:
    RESOURCE comparison_op STRING       { printf("Condición de recurso: %s\n", $3); }
    | RESOURCE comparison_op IDENTIFIER { printf("Condición de recurso: %s\n", $3); }
    ;

/**
 * Define condiciones personalizadas mediante identificadores.
 * Permite crear restricciones específicas no cubiertas por otros tipos.
 */
custom_condition:
    IDENTIFIER comparison_op value      { printf("Condición personalizada: %s\n", $1); }
    ;

/**
 * Define los tipos de valores que pueden aparecer en condiciones.
 * Pueden ser números, cadenas o identificadores.
 */
value:
    NUMBER                              { $$ = $1; }
    | STRING                            { $$ = 0; /* Valor por defecto para strings */ }
    | IDENTIFIER                        { $$ = 0; /* Valor por defecto para identificadores */ }
    ;

/**
 * Define los operadores de comparación disponibles.
 * Incluye igualdad, desigualdad y operadores relacionales.
 */
comparison_op:
    EQUAL                               { printf("Operador: =\n"); }
    | NOT_EQUAL                         { printf("Operador: !=\n"); }
    | GREATER                           { printf("Operador: >\n"); }
    | LESS                              { printf("Operador: <\n"); }
    | GREATER_EQ                        { printf("Operador: >=\n"); }
    | LESS_EQ                           { printf("Operador: <=\n"); }
    ;

%%

/**
 * Función de manejo de errores.
 * Se invoca cuando se detecta un error sintáctico durante el análisis.
 * 
 * Args:
 *     s: Mensaje de error generado por el parser.
 */
void yyerror(const char* s) {
    printf("❌ Error sintáctico: %s\n", s);
    printf("DEBUG: Último token procesado podría ser problemático\n");
}

/**
 * Función para depuración de tokens.
 * Imprime información sobre un token específico durante el análisis.
 * 
 * Args:
 *     token_name: Nombre del token reconocido.
 */
void debug_token(const char* token_name) {
    printf("DEBUG: Token reconocido: %s\n", token_name);
}

/**
 * Función principal del analizador.
 * Inicializa el proceso de análisis y maneja la entrada/salida.
 * 
 * Args:
 *     argc: Número de argumentos de la línea de comandos.
 *     argv: Array de argumentos de la línea de comandos.
 * 
 * Returns:
 *     Código de salida indicando éxito (0) o error (distinto de 0).
 */
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