# Makefile para compilar el analizador de reglas de acceso
CC = gcc
CFLAGS = -Wall -g

# Archivos fuente
LEX_FILE = lexer.l
YACC_FILE = parser.y
EXECUTABLE = access_analyzer

# Reglas de compilación
all: $(EXECUTABLE)

$(EXECUTABLE): lex.yy.c parser.tab.c
	$(CC) $(CFLAGS) -o $@ lex.yy.c parser.tab.c -lfl

lex.yy.c: $(LEX_FILE) parser.tab.h
	flex $(LEX_FILE)

parser.tab.c parser.tab.h: $(YACC_FILE)
	bison -d $(YACC_FILE)

# Limpiar archivos generados
clean:
	rm -f lex.yy.c parser.tab.c parser.tab.h $(EXECUTABLE)

# Ejemplos de prueba
test: $(EXECUTABLE)
	@echo "=== Probando reglas válidas ==="
	@echo "user admin AND hour >= 9" | ./$(EXECUTABLE)
	@echo ""
	@echo "user guest AND NOT resource = 'config.xml'" | ./$(EXECUTABLE)
	@echo ""
	@echo "user operator AND day = 'Monday'" | ./$(EXECUTABLE)

.PHONY: all clean test