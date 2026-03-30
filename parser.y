%{
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <iostream>
#include <string>
#include <unordered_map>
#include <unordered_set>

extern int yylineno;  // Line number from lexer
int yylex();
void yyerror(const char* s);
%}

%code requires {
    #include "ast.h"
}

%code {
    FILE* cppFile = NULL;
    ProgramNode* root = nullptr;
    std::unordered_map<std::string, std::string> symbolTypes;
    std::unordered_map<std::string, std::string> arrayElementTypes;
    std::unordered_set<std::string> heteroArrays;

    // Forward declarations for code generation
    void generateCode(ASTNode* node, FILE* out);
    std::string generateExpression(ASTNode* node);
    std::string inferType(ASTNode* node);
    bool isHeterogeneousElementType(const std::string& t);
    bool isArrayDeclaredHeterogeneous(const ArrayDeclNode* arrDecl);
}

%union {
    char* str;
    int num;
    ASTNode* node;
    StatementListNode* stmtList;
    ProgramNode* program;
    std::vector<std::string>* strList;
    std::vector<ASTNode*>* nodeList;
}

%token SET END PRINT
%token TASK IF ELSE WHILE
%token REPEAT FROM TO
%token SWITCH CASE DEFAULT BREAK
%token RETURN READ
%token READ_FILE WRITE_FILE
%token TYPE_NUMBER TYPE_DECIMAL TYPE_LETTER TYPE_TEXT TYPE_BOOL
%token BARAO KOMAO DOT
%token <str> IDENTIFIER NUMBER DECIMAL STRING CHAR BOOLEAN
%token PLUS MINUS MUL DIV MOD POW
%token INC DEC
%token PLUS_ASSIGN MINUS_ASSIGN MUL_ASSIGN DIV_ASSIGN
%token EQ NE GT LT GE LE
%token AND OR NOT
%token ASSIGN COLON SEMICOLON COMMA
%token LPAREN RPAREN LBRACKET RBRACKET LBRACE RBRACE

%type <program> program
%type <stmtList> statements block
%type <node> statement assignment compound_assignment increment_decrement 
%type <node> print_stmt input_stmt if_stmt while_stmt repeat_stmt
%type <node> function_def function_call return_stmt
%type <node> array_decl array_access array_push array_pop expression
%type <strList> param_list
%type <nodeList> arg_list array_values

%left OR
%left AND
%right NOT
%left EQ NE GT LT GE LE
%left PLUS MINUS
%left MUL DIV MOD
%right POW

%%

program
    : statements
    {
        $$ = new ProgramNode($1);
        root = $$;
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
    | input_stmt        { $$ = $1; }
    | if_stmt           { $$ = $1; }
    | while_stmt        { $$ = $1; }
    | repeat_stmt       { $$ = $1; }
    | function_def      { $$ = $1; }
    | function_call SEMICOLON { $$ = $1; }
    | return_stmt       { $$ = $1; }
    | array_decl        { $$ = $1; }
    | array_push        { $$ = $1; }
    | array_pop         { $$ = $1; }
    | array_access ASSIGN expression SEMICOLON 
    {
        $$ = new ArrayAssignmentNode(static_cast<ArrayAccessNode*>($1), $3);
    }
    | SEMICOLON         { $$ = nullptr; }
    | error SEMICOLON   
    { 
        fprintf(stderr, "   Recovering from error...\n");
        $$ = nullptr; 
        yyerrok;
    }
    ;

assignment
    : SET IDENTIFIER ASSIGN expression SEMICOLON
    {
        $$ = new AssignmentNode($2, "", $4, true);
    }
    | SET array_access ASSIGN expression SEMICOLON
    {
        $$ = new ArrayAssignmentNode(static_cast<ArrayAccessNode*>($2), $4);
    }
    | SET IDENTIFIER ASSIGN expression error
    {
        fprintf(stderr, "   Expected ';' after variable assignment\n");
        yyerrok;
        $$ = nullptr;
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
    | PRINT expression error
    {
        fprintf(stderr, "   Expected ';' after print statement\n");
        yyerrok;
        $$ = nullptr;
    }
    ;

input_stmt
    : READ IDENTIFIER SEMICOLON
    {
        $$ = new InputNode($2);
    }
    ;

block
    : LBRACE statements RBRACE
    {
        $$ = $2;
    }
    ;

if_stmt
    : IF LPAREN expression RPAREN block
    {
        $$ = new IfNode($3, $5, nullptr);
    }
    | IF LPAREN expression RPAREN block ELSE block
    {
        $$ = new IfNode($3, $5, $7);
    }
    ;

while_stmt
    : WHILE LPAREN expression RPAREN block
    {
        $$ = new WhileNode($3, $5);
    }
    ;

repeat_stmt
    : REPEAT IDENTIFIER FROM expression TO expression block
    {
        $$ = new RepeatNode($2, $4, $6, $7);
    }
    ;

function_def
    : TASK IDENTIFIER LPAREN RPAREN block
    {
        std::vector<std::string> emptyParams;
        $$ = new FunctionNode($2, emptyParams, $5);
    }
   | TASK IDENTIFIER LPAREN param_list RPAREN block
    {
        $$ = new FunctionNode($2, *$4, $6);
        delete $4;
    }
    ;

param_list
    : IDENTIFIER
    {
        $$ = new std::vector<std::string>();
        $$->push_back($1);
    }
    | param_list COMMA IDENTIFIER
    {
        $$ = $1;
        $$->push_back($3);
    }
    ;

function_call
    : IDENTIFIER LPAREN RPAREN
    {
        std::vector<ASTNode*> emptyArgs;
        $$ = new FunctionCallNode($1, emptyArgs);
    }
    | IDENTIFIER LPAREN arg_list RPAREN
    {
        $$ = new FunctionCallNode($1, *$3);
        delete $3;
    }
    ;

arg_list
    : expression
    {
        $$ = new std::vector<ASTNode*>();
        $$->push_back($1);
    }
    | arg_list COMMA expression
    {
        $$ = $1;
        $$->push_back($3);
    }
    ;

return_stmt
    : RETURN SEMICOLON
    {
        $$ = new ReturnNode(nullptr);
    }
    | RETURN expression SEMICOLON
    {
        $$ = new ReturnNode($2);
    }
    ;

array_decl
    : SET IDENTIFIER LBRACKET NUMBER RBRACKET SEMICOLON
    {
        std::vector<ASTNode*> emptyVals;
        $$ = new ArrayDeclNode($2, atoi($4), emptyVals);
    }
    | SET IDENTIFIER ASSIGN LBRACE array_values RBRACE SEMICOLON
    {
        $$ = new ArrayDeclNode($2, $5->size(), *$5);
        delete $5;
    }
    | SET IDENTIFIER ASSIGN LBRACE RBRACE SEMICOLON
    {
        std::vector<ASTNode*> emptyVals;
        $$ = new ArrayDeclNode($2, 0, emptyVals);
    }
    ;

array_values
    : expression
    {
        $$ = new std::vector<ASTNode*>();
        $$->push_back($1);
    }
    | array_values COMMA expression
    {
        $$ = $1;
        $$->push_back($3);
    }
    ;

array_access
    : IDENTIFIER LBRACKET expression RBRACKET
    {
        $$ = new ArrayAccessNode($1, $3);
    }
    ;

array_push
    : IDENTIFIER DOT BARAO LPAREN expression RPAREN SEMICOLON
    {
        $$ = new ArrayPushNode($1, $5);
    }
    ;

array_pop
    : IDENTIFIER DOT KOMAO LPAREN RPAREN SEMICOLON
    {
        $$ = new ArrayPopNode($1);
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
    | array_access { $$ = $1; }
    | function_call { $$ = $1; }
    | IDENTIFIER { $$ = new IdentifierNode($1); }
    ;

%%

// Error handler
void yyerror(const char* s) {
    fprintf(stderr, "\n[ERROR] Line %d: %s\n", yylineno, s);
    fprintf(stderr, "        Hint: Check if you're missing a semicolon (;)\n");
}

// Code generation functions - traverse AST and generate C++

bool isHeterogeneousElementType(const std::string& t) {
    return t == "RSValue";
}

bool isArrayDeclaredHeterogeneous(const ArrayDeclNode* arrDecl) {
    if (!arrDecl || arrDecl->initialValues.size() <= 1) return false;

    std::string firstType = inferType(arrDecl->initialValues[0]);
    for (size_t i = 1; i < arrDecl->initialValues.size(); i++) {
        if (inferType(arrDecl->initialValues[i]) != firstType) {
            return true;
        }
    }
    return false;
}

// Infer C++ type from AST node
std::string inferType(ASTNode* node) {
    if (!node) return "auto";
    
    switch (node->type) {
        case NodeType::LITERAL: {
            LiteralNode* lit = static_cast<LiteralNode*>(node);
            std::string val = lit->value;
            
            // Check if it's a string (double-quoted)
            if (!val.empty() && val[0] == '"') {
                return "string";
            }
            // Check if it's a char (single-quoted)
            else if (val.size() >= 3 && val.front() == '\'' && val.back() == '\'') {
                return "char";
            }
            // Check if it's a decimal (contains .)
            else if (val.find('.') != std::string::npos) {
                return "double";
            }
            // Check if it's a boolean
            else if (val == "insaaf" || val == "abbas" || val == "true" || val == "false") {
                return "bool";
            }
            // Default to int for numbers
            else {
                return "int";
            }
        }
        case NodeType::BINARY_OP: {
            BinaryOpNode* binOp = static_cast<BinaryOpNode*>(node);
            // For power operator, result is double
            if (binOp->op == "^") {
                return "double";
            }
            // For comparison operators, result is bool
            if (binOp->op == "==" || binOp->op == "!=" || 
                binOp->op == "<" || binOp->op == ">" || 
                binOp->op == "<=" || binOp->op == ">=") {
                return "bool";
            }
            // For arithmetic, infer from left operand
            return inferType(binOp->left);
        }
        case NodeType::ARRAY_ACCESS: {
            ArrayAccessNode* arrAcc = static_cast<ArrayAccessNode*>(node);
            auto it = arrayElementTypes.find(arrAcc->varName);
            if (it != arrayElementTypes.end()) {
                return it->second;
            }
            return "auto";
        }
        case NodeType::FUNCTION_CALL:
            return "auto";
        case NodeType::IDENTIFIER:
        {
            IdentifierNode* id = static_cast<IdentifierNode*>(node);
            auto it = symbolTypes.find(id->name);
            if (it != symbolTypes.end()) {
                return it->second;
            }
            return "auto";
        }
        default:
            return "auto";
    }
}

std::string generateExpression(ASTNode* node) {
    if (!node) return "";
    
    switch (node->type) {
        case NodeType::LITERAL: {
            LiteralNode* lit = static_cast<LiteralNode*>(node);
            if (lit->value == "insaaf") return "true";
            if (lit->value == "abbas") return "false";
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
        case NodeType::ARRAY_ACCESS: {
            ArrayAccessNode* arrAcc = static_cast<ArrayAccessNode*>(node);
            std::string index = generateExpression(arrAcc->index);
            auto typeIt = arrayElementTypes.find(arrAcc->varName);
            if (typeIt != arrayElementTypes.end() && isHeterogeneousElementType(typeIt->second)) {
                return arrAcc->varName + "[" + index + "]";
            }
            return arrAcc->varName + "[" + index + "]";
        }
        case NodeType::FUNCTION_CALL: {
            FunctionCallNode* funcCall = static_cast<FunctionCallNode*>(node);
            std::string result = funcCall->name + "(";
            for (size_t i = 0; i < funcCall->arguments.size(); i++) {
                result += generateExpression(funcCall->arguments[i]);
                if (i < funcCall->arguments.size() - 1) result += ", ";
            }
            result += ")";
            return result;
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
            fprintf(out, "#include <string>\n");
            fprintf(out, "#include <vector>\n");
            fprintf(out, "using namespace std;\n\n");
            fprintf(out, "struct RSValue {\n");
            fprintf(out, "    enum Type { INT_T, DOUBLE_T, STRING_T, CHAR_T, BOOL_T } type;\n");
            fprintf(out, "    int i;\n");
            fprintf(out, "    double d;\n");
            fprintf(out, "    string s;\n");
            fprintf(out, "    char c;\n");
            fprintf(out, "    bool b;\n\n");
            fprintf(out, "    RSValue() : type(INT_T), i(0), d(0.0), s(\"\"), c('\\0'), b(false) {}\n");
            fprintf(out, "    RSValue(int v) : type(INT_T), i(v), d(0.0), s(\"\"), c('\\0'), b(false) {}\n");
            fprintf(out, "    RSValue(double v) : type(DOUBLE_T), i(0), d(v), s(\"\"), c('\\0'), b(false) {}\n");
            fprintf(out, "    RSValue(const string& v) : type(STRING_T), i(0), d(0.0), s(v), c('\\0'), b(false) {}\n");
            fprintf(out, "    RSValue(const char* v) : type(STRING_T), i(0), d(0.0), s(v), c('\\0'), b(false) {}\n");
            fprintf(out, "    RSValue(char v) : type(CHAR_T), i(0), d(0.0), s(\"\"), c(v), b(false) {}\n");
            fprintf(out, "    RSValue(bool v) : type(BOOL_T), i(0), d(0.0), s(\"\"), c('\\0'), b(v) {}\n");
            fprintf(out, "};\n\n");
            fprintf(out, "ostream& operator<<(ostream& os, const RSValue& v) {\n");
            fprintf(out, "    switch (v.type) {\n");
            fprintf(out, "        case RSValue::INT_T: os << v.i; break;\n");
            fprintf(out, "        case RSValue::DOUBLE_T: os << v.d; break;\n");
            fprintf(out, "        case RSValue::STRING_T: os << v.s; break;\n");
            fprintf(out, "        case RSValue::CHAR_T: os << v.c; break;\n");
            fprintf(out, "        case RSValue::BOOL_T: os << (v.b ? \"true\" : \"false\"); break;\n");
            fprintf(out, "    }\n");
            fprintf(out, "    return os;\n");
            fprintf(out, "}\n\n");
            
            StatementListNode* stmts = prog->statements;
            
            // Define functions BEFORE main() (no forward declarations needed)
            for (auto stmt : stmts->statements) {
                if (stmt && stmt->type == NodeType::FUNCTION_DEF) {
                    FunctionNode* func = static_cast<FunctionNode*>(stmt);
                    fprintf(out, "auto %s(", func->name.c_str());
                    for (size_t i = 0; i < func->params.size(); i++) {
                        fprintf(out, "auto %s", func->params[i].c_str());
                        if (i < func->params.size() - 1) fprintf(out, ", ");
                    }
                    fprintf(out, ") {\n");
                    generateCode(func->body, out);
                    fprintf(out, "}\n\n");
                }
            }
            
            fprintf(out, "int main() {\n");
            generateCode(prog->statements, out);
            fprintf(out, "return 0;\n}\n");
            break;
        }
        case NodeType::STATEMENT_LIST: {
            StatementListNode* stmtList = static_cast<StatementListNode*>(node);
            for (auto stmt : stmtList->statements) {
                if (stmt && stmt->type != NodeType::FUNCTION_DEF) {
                    generateCode(stmt, out);
                }
            }
            break;
        }
        case NodeType::ASSIGNMENT: {
            AssignmentNode* assign = static_cast<AssignmentNode*>(node);
            std::string value = generateExpression(assign->value);
            std::string cppType = assign->varType;
            
            // Infer type if needed
            if (assign->inferType) {
                cppType = inferType(assign->value);
            }

            auto it = symbolTypes.find(assign->varName);
            if (it == symbolTypes.end()) {
                fprintf(out, "%s %s = %s;\n",
                        cppType.c_str(),
                        assign->varName.c_str(),
                        value.c_str());
            } else {
                fprintf(out, "%s = %s;\n",
                        assign->varName.c_str(),
                        value.c_str());
            }
            symbolTypes[assign->varName] = cppType;
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
        case NodeType::INPUT_STMT: {
            InputNode* input = static_cast<InputNode*>(node);
            // Auto-declare variable - default to int for numbers, string for text-like names
            std::string varName = input->varName;
            if (varName.find("name") != std::string::npos || 
                varName.find("text") != std::string::npos ||
                varName.find("message") != std::string::npos) {
                fprintf(out, "string %s;\n", input->varName.c_str());
            } else {
                fprintf(out, "int %s;\n", input->varName.c_str());
            }
            fprintf(out, "cin >> %s;\n", input->varName.c_str());
            break;
        }
        case NodeType::IF_STMT: {
            IfNode* ifNode = static_cast<IfNode*>(node);
            std::string cond = generateExpression(ifNode->condition);
            fprintf(out, "if (%s) {\n", cond.c_str());
            generateCode(ifNode->thenBlock, out);
            if (ifNode->elseBlock) {
                fprintf(out, "} else {\n");
                generateCode(ifNode->elseBlock, out);
            }
            fprintf(out, "}\n");
            break;
        }
        case NodeType::WHILE_STMT: {
            WhileNode* whileNode = static_cast<WhileNode*>(node);
            std::string cond = generateExpression(whileNode->condition);
            fprintf(out, "while (%s) {\n", cond.c_str());
            generateCode(whileNode->body, out);
            fprintf(out, "}\n");
            break;
        }
        case NodeType::REPEAT_STMT: {
            RepeatNode* repeatNode = static_cast<RepeatNode*>(node);
            std::string start = generateExpression(repeatNode->start);
            std::string end = generateExpression(repeatNode->end);
            fprintf(out, "for (int %s = %s; %s <= %s; %s++) {\n", 
                    repeatNode->varName.c_str(), start.c_str(),
                    repeatNode->varName.c_str(), end.c_str(),
                    repeatNode->varName.c_str());
            generateCode(repeatNode->body, out);
            fprintf(out, "}\n");
            break;
        }
        case NodeType::RETURN_STMT: {
            ReturnNode* retNode = static_cast<ReturnNode*>(node);
            if (retNode->value) {
                std::string val = generateExpression(retNode->value);
                fprintf(out, "return %s;\n", val.c_str());
            } else {
                fprintf(out, "return;\n");
            }
            break;
        }
        case NodeType::ARRAY_DECL: {
            ArrayDeclNode* arrDecl = static_cast<ArrayDeclNode*>(node);
            if (arrDecl->initialValues.empty()) {
                if (arrDecl->size > 0) {
                    // Fixed-size declaration keeps homogeneous int behavior.
                    fprintf(out, "vector<int> %s(%d);\n", arrDecl->varName.c_str(), arrDecl->size);
                    symbolTypes[arrDecl->varName] = "vector<int>";
                    arrayElementTypes[arrDecl->varName] = "int";
                } else {
                    // Empty brace declaration starts as heterogeneous dynamic array.
                    fprintf(out, "vector<RSValue> %s;\n", arrDecl->varName.c_str());
                    heteroArrays.insert(arrDecl->varName);
                    symbolTypes[arrDecl->varName] = "vector<RSValue>";
                    arrayElementTypes[arrDecl->varName] = "RSValue";
                }
            } else {
                bool isHetero = isArrayDeclaredHeterogeneous(arrDecl);
                if (isHetero) {
                    fprintf(out, "vector<RSValue> %s = {", arrDecl->varName.c_str());
                    heteroArrays.insert(arrDecl->varName);
                    arrayElementTypes[arrDecl->varName] = "RSValue";
                    symbolTypes[arrDecl->varName] = "vector<RSValue>";
                } else {
                    std::string elemType = inferType(arrDecl->initialValues[0]);
                    fprintf(out, "vector<%s> %s = {", elemType.c_str(), arrDecl->varName.c_str());
                    arrayElementTypes[arrDecl->varName] = elemType;
                    symbolTypes[arrDecl->varName] = "vector<" + elemType + ">";
                }
                for (size_t i = 0; i < arrDecl->initialValues.size(); i++) {
                    std::string val = generateExpression(arrDecl->initialValues[i]);
                    fprintf(out, "%s", val.c_str());
                    if (i < arrDecl->initialValues.size() - 1) fprintf(out, ", ");
                }
                fprintf(out, "};\n");
            }
            break;
        }
        case NodeType::ARRAY_ASSIGNMENT: {
            ArrayAssignmentNode* arrAssign = static_cast<ArrayAssignmentNode*>(node);
            std::string index = generateExpression(arrAssign->arrayAccess->index);
            std::string value = generateExpression(arrAssign->value);
            fprintf(out, "%s[%s] = %s;\n", arrAssign->arrayAccess->varName.c_str(), index.c_str(), value.c_str());
            break;
        }
        case NodeType::ARRAY_PUSH: {
            ArrayPushNode* arrPush = static_cast<ArrayPushNode*>(node);
            std::string value = generateExpression(arrPush->value);
            fprintf(out, "%s.push_back(%s);\n", arrPush->varName.c_str(), value.c_str());
            break;
        }
        case NodeType::ARRAY_POP: {
            ArrayPopNode* arrPop = static_cast<ArrayPopNode*>(node);
            fprintf(out, "if (!%s.empty()) %s.pop_back();\n", arrPop->varName.c_str(), arrPop->varName.c_str());
            break;
        }
        case NodeType::FUNCTION_CALL: {
            FunctionCallNode* funcCall = static_cast<FunctionCallNode*>(node);
            fprintf(out, "%s(", funcCall->name.c_str());
            for (size_t i = 0; i < funcCall->arguments.size(); i++) {
                std::string arg = generateExpression(funcCall->arguments[i]);
                fprintf(out, "%s", arg.c_str());
                if (i < funcCall->arguments.size() - 1) fprintf(out, ", ");
            }
            fprintf(out, ");\n");
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
