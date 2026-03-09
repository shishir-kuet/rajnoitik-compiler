%{
/*
 * lex.l — Rajnoitikscript/JoyBangla Language Lexer
 * A Bangladesh-themed programming language compiler
 */
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include "parser.tab.h"

/* Line counter for error messages (provided by yylineno option) */
%}

%option noyywrap
%option yylineno
%x COMMENT

DIGIT      [0-9]
LETTER     [a-zA-Z_]
ID         {LETTER}({LETTER}|{DIGIT})*

%%

"JoyBanglaSuru"      BEGIN(COMMENT);
<COMMENT>"JoyBanglaSesh"   BEGIN(INITIAL);
<COMMENT>.|\n        ;

"JoyBangla".*        ;

"set"              return SET;
"iHaveAplan"       return TASK;
"BangladeshCore"   return MODULE;

"if"               return IF;
"else"             return ELSE;
"while"            return WHILE;

"repeat"           return REPEAT;
"from"             return FROM;
"to"               return TO;

"switch"           return SWITCH;
"case"             return CASE;
"default"          return DEFAULT;
"break"            return BREAK;

"end"              return END;
"return"           return RETURN;

"chandaDe"         return READ;
"khelaHobe"        return PRINT;

"FileChanda"       return READ_FILE;
"FileKhela"        return WRITE_FILE;

"10percent"        return TYPE_DECIMAL;
"number"           return TYPE_NUMBER;
"letter"           return TYPE_LETTER;
"dhaka8"           return TYPE_TEXT;
"HadiVaiMoreNai"   return TYPE_BOOL;

"insaaf"|"abbas" {
    yylval.str = strdup(yytext);
    return BOOLEAN;
}

{DIGIT}+"."{DIGIT}+ {
    yylval.str = strdup(yytext);
    return DECIMAL;
}

{DIGIT}+ {
    yylval.str = strdup(yytext);
    return NUMBER;
}

\'([^\'\\]|\\.)\'  {
    yylval.str = strdup(yytext);
    return CHAR;
}

\"([^\"\\]|\\.)*\" {
    yylval.str = strdup(yytext);
    return STRING;
}

"&&"    return AND;
"||"    return OR;
"!"     return NOT;

"++"    return INC;
"--"    return DEC;

"+="    return PLUS_ASSIGN;
"-="    return MINUS_ASSIGN;
"*="    return MUL_ASSIGN;
"/="    return DIV_ASSIGN;

"+"     return PLUS;
"-"     return MINUS;
"*"     return MUL;
"/"     return DIV;
"%"     return MOD;
"^"     return POW;

"=="    return EQ;
"!="    return NE;
">="    return GE;
"<="    return LE;
">"     return GT;
"<"     return LT;

"="     return ASSIGN;
":"     return COLON;
";"     return SEMICOLON;
"("     return LPAREN;
")"     return RPAREN;

{ID} {
    yylval.str = strdup(yytext);
    return IDENTIFIER;
}

[ \t\r\n]+   ;

. {
    printf("Line %d: Unknown character: %s\n", yylineno, yytext);
}

%%
