%{
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <iostream>
#include <string>
#include "ast.h"

FILE* cppFile = NULL;
ProgramNode* root = nullptr;

int yylex();
void yyerror(const char* s) {
    printf("Parser error: %s\n", s);
}

// Forward declarations for code generation
void generateCode(ASTNode* node, FILE* out);
std::string generateExpression(ASTNode* node);
%}

%union {
    char* str;
    ASTNode* node;
    StatementListNode* stmtList;
    ModuleNode* module;
    ProgramNode* program;
}

%token SET MODULE END PRINT
%token TASK IF ELSE WHILE
%token REPEAT FROM TO
%token SWITCH CASE DEFAULT BREAK
%token RETURN READ
%token READ_FILE WRITE_FILE
%token TYPE_NUMBER TYPE_DECIMAL TYPE_LETTER TYPE_TEXT TYPE_BOOL
%token <str> IDENTIFIER NUMBER DECIMAL STRING CHAR BOOLEAN
%token PLUS MINUS MUL DIV MOD POW
%token INC DEC
%token PLUS_ASSIGN MINUS_ASSIGN MUL_ASSIGN DIV_ASSIGN
%token EQ NE GT LT GE LE
%token AND OR NOT
%token ASSIGN COLON SEMICOLON
%token LPAREN RPAREN

%type <program> program
%type <module> module
%type <stmtList> statements
%type <node> statement assignment compound_assignment increment_decrement print_stmt expression

%left OR
%left AND
%right NOT
%left EQ NE GT LT GE LE
%left PLUS MINUS
%left MUL DIV MOD
%right POW

%%

program
    : module
    {
        $$ = new ProgramNode($1);
        root = $$;
    }
    ;

module
    : MODULE IDENTIFIER statements END
    {
        $$ = new ModuleNode($2, $3);
    }
    ;

statements
    : statement
    {
        $$ = new StatementListNode();
        if ($1) $$->addStatement($1);
    }
    | statements statement
    {
        $$ = $1;
        if ($2) $$->addStatement($2);
    }
    ;

statement
    : assignment        { $$ = $1; }
    | compound_assignment { $$ = $1; }
    | increment_decrement { $$ = $1; }
    | print_stmt        { $$ = $1; }
    | SEMICOLON         { $$ = nullptr; }
    ;

assignment
    : SET IDENTIFIER COLON TYPE_NUMBER ASSIGN expression SEMICOLON
    {
        $$ = new AssignmentNode($2, "int", $6);
    }
    ;

compound_assignment
    : IDENTIFIER PLUS_ASSIGN expression SEMICOLON
    {
        $$ = new CompoundAssignmentNode($1, "+=", $3);
    }
    | IDENTIFIER MINUS_ASSIGN expression SEMICOLON
    {
        $$ = new CompoundAssignmentNode($1, "-=", $3);
    }
    | IDENTIFIER MUL_ASSIGN expression SEMICOLON
    {
        $$ = new CompoundAssignmentNode($1, "*=", $3);
    }
    | IDENTIFIER DIV_ASSIGN expression SEMICOLON
    {
        $$ = new CompoundAssignmentNode($1, "/=", $3);
    }
    ;

increment_decrement
    : IDENTIFIER INC SEMICOLON
    {
        $$ = new IncrementNode($1, true, false);
    }
    | IDENTIFIER DEC SEMICOLON
    {
        $$ = new IncrementNode($1, false, false);
    }
    | INC IDENTIFIER SEMICOLON
    {
        $$ = new IncrementNode($2, true, true);
    }
    | DEC IDENTIFIER SEMICOLON
    {
        $$ = new IncrementNode($2, false, true);
    }
    ;

print_stmt
    : PRINT expression SEMICOLON
    {
        $$ = new PrintNode($2);
    }
    ;

expression
    : expression PLUS expression
    {
        $$ = new BinaryOpNode("+", $1, $3);
    }
    | expression MINUS expression
    {
        $$ = new BinaryOpNode("-", $1, $3);
    }
    | expression MUL expression
    {
        $$ = new BinaryOpNode("*", $1, $3);
    }
    | expression DIV expression
    {
        $$ = new BinaryOpNode("/", $1, $3);
    }
    | expression MOD expression
    {
        $$ = new BinaryOpNode("%", $1, $3);
    }
    | expression POW expression
    {
        $$ = new BinaryOpNode("^", $1, $3);
    }
    | expression EQ expression
    {
        $$ = new BinaryOpNode("==", $1, $3);
    }
    | expression NE expression
    {
        $$ = new BinaryOpNode("!=", $1, $3);
    }
    | expression GT expression
    {
        $$ = new BinaryOpNode(">", $1, $3);
    }
    | expression LT expression
    {
        $$ = new BinaryOpNode("<", $1, $3);
    }
    | expression GE expression
    {
        $$ = new BinaryOpNode(">=", $1, $3);
    }
    | expression LE expression
    {
        $$ = new BinaryOpNode("<=", $1, $3);
    }
    | expression AND expression
    {
        $$ = new BinaryOpNode("&&", $1, $3);
    }
    | expression OR expression
    {
        $$ = new BinaryOpNode("||", $1, $3);
    }
    | NOT expression
    {
        $$ = new UnaryOpNode("!", $2);
    }
    | LPAREN expression RPAREN
    {
        $$ = $2;
    }
    | NUMBER     { $$ = new LiteralNode($1); }
    | DECIMAL    { $$ = new LiteralNode($1); }
    | STRING     { $$ = new LiteralNode($1); }
    | CHAR       { $$ = new LiteralNode($1); }
    | BOOLEAN    { $$ = new LiteralNode($1); }
    | IDENTIFIER { $$ = new IdentifierNode($1); }
    ;

%%

%%

// Code generation functions - traverse AST and generate C++

std::string generateExpression(ASTNode* node) {
    if (!node) return "";
    
    switch (node->type) {
        case NodeType::LITERAL: {
            LiteralNode* lit = static_cast<LiteralNode*>(node);
            return lit->value;
        }
        case NodeType::IDENTIFIER: {
            IdentifierNode* id = static_cast<IdentifierNode*>(node);
            return id->name;
        }
        case NodeType::BINARY_OP: {
            BinaryOpNode* binOp = static_cast<BinaryOpNode*>(node);
            std::string left = generateExpression(binOp->left);
            std::string right = generateExpression(binOp->right);
            
            if (binOp->op == "^") {
                return "pow(" + left + ", " + right + ")";
            } else if (binOp->op == "%") {
                return "(" + left + " % " + right + ")";
            } else {
                return "(" + left + " " + binOp->op + " " + right + ")";
            }
        }
        case NodeType::UNARY_OP: {
            UnaryOpNode* unOp = static_cast<UnaryOpNode*>(node);
            std::string operand = generateExpression(unOp->operand);
            return unOp->op + operand;
        }
        default:
            return "";
    }
}

void generateCode(ASTNode* node, FILE* out) {
    if (!node) return;
    
    switch (node->type) {
        case NodeType::PROGRAM: {
            ProgramNode* prog = static_cast<ProgramNode*>(node);
            fprintf(out, "#include <iostream>\n");
            fprintf(out, "#include <cmath>\n");
            fprintf(out, "using namespace std;\n\n");
            fprintf(out, "int main() {\n");
            generateCode(prog->module, out);
            fprintf(out, "return 0;\n}\n");
            break;
        }
        case NodeType::MODULE: {
            ModuleNode* mod = static_cast<ModuleNode*>(node);
            generateCode(mod->statements, out);
            break;
        }
        case NodeType::STATEMENT_LIST: {
            StatementListNode* stmtList = static_cast<StatementListNode*>(node);
            for (auto stmt : stmtList->statements) {
                generateCode(stmt, out);
            }
            break;
        }
        case NodeType::ASSIGNMENT: {
            AssignmentNode* assign = static_cast<AssignmentNode*>(node);
            std::string value = generateExpression(assign->value);
            fprintf(out, "%s %s = %s;\n", 
                    assign->varType.c_str(), 
                    assign->varName.c_str(), 
                    value.c_str());
            break;
        }
        case NodeType::COMPOUND_ASSIGNMENT: {
            CompoundAssignmentNode* compAssign = static_cast<CompoundAssignmentNode*>(node);
            std::string value = generateExpression(compAssign->value);
            fprintf(out, "%s %s %s;\n", 
                    compAssign->varName.c_str(), 
                    compAssign->op.c_str(), 
                    value.c_str());
            break;
        }
        case NodeType::INCREMENT: {
            IncrementNode* inc = static_cast<IncrementNode*>(node);
            if (inc->isPrefix) {
                fprintf(out, "%s%s;\n", 
                        inc->isIncrement ? "++" : "--", 
                        inc->varName.c_str());
            } else {
                fprintf(out, "%s%s;\n", 
                        inc->varName.c_str(), 
                        inc->isIncrement ? "++" : "--");
            }
            break;
        }
        case NodeType::PRINT_STMT: {
            PrintNode* print = static_cast<PrintNode*>(node);
            std::string expr = generateExpression(print->expression);
            fprintf(out, "cout << %s << endl;\n", expr.c_str());
            break;
        }
        default:
            break;
    }
}

int main(int argc, char** argv) {
    if (argc > 1) {
        FILE* file = fopen(argv[1], "r");
        if (!file) {
            printf("Cannot open source file\n");
            return 1;
        }
        extern FILE* yyin;
        yyin = file;
    }

    // Parse and build AST
    yyparse();

    if (root) {
        // Open output file
        cppFile = fopen("generated.cpp", "w");
        if (!cppFile) {
            printf("Cannot create output file\n");
            return 1;
        }

        // Generate C++ code from AST
        generateCode(root, cppFile);

        fclose(cppFile);
        
        printf("Compilation successful! AST built and C++ code generated.\n");
        
        // Clean up AST
        delete root;
    } else {
        printf("Failed to build AST\n");
        return 1;
    }

    return 0;
}
