#ifndef AST_H
#define AST_H

#include <string>
#include <vector>
#include <memory>

// AST Node Types
enum class NodeType {
    PROGRAM,
    MODULE,
    STATEMENT_LIST,
    ASSIGNMENT,
    COMPOUND_ASSIGNMENT,
    INCREMENT,
    DECREMENT,
    PRINT_STMT,
    INPUT_STMT,
    IF_STMT,
    WHILE_STMT,
    REPEAT_STMT,
    FUNCTION_DEF,
    FUNCTION_CALL,
    RETURN_STMT,
    ARRAY_DECL,
    ARRAY_ACCESS,
    ARRAY_ASSIGNMENT,
    ARRAY_PUSH,
    ARRAY_POP,
    BINARY_OP,
    UNARY_OP,
    LITERAL,
    IDENTIFIER
};

// Base AST Node
class ASTNode {
public:
    NodeType type;
    virtual ~ASTNode() = default;
    
protected:
    ASTNode(NodeType t) : type(t) {}
};

// Literal Node (numbers, strings, etc.)
class LiteralNode : public ASTNode {
public:
    std::string value;
    
    LiteralNode(const std::string& val) 
        : ASTNode(NodeType::LITERAL), value(val) {}
};

// Identifier Node
class IdentifierNode : public ASTNode {
public:
    std::string name;
    
    IdentifierNode(const std::string& n) 
        : ASTNode(NodeType::IDENTIFIER), name(n) {}
};

// Binary Operation Node
class BinaryOpNode : public ASTNode {
public:
    std::string op;
    ASTNode* left;
    ASTNode* right;
    
    BinaryOpNode(const std::string& operation, ASTNode* l, ASTNode* r)
        : ASTNode(NodeType::BINARY_OP), op(operation), left(l), right(r) {}
    
    ~BinaryOpNode() {
        delete left;
        delete right;
    }
};

// Unary Operation Node
class UnaryOpNode : public ASTNode {
public:
    std::string op;
    ASTNode* operand;
    
    UnaryOpNode(const std::string& operation, ASTNode* oper)
        : ASTNode(NodeType::UNARY_OP), op(operation), operand(oper) {}
    
    ~UnaryOpNode() {
        delete operand;
    }
};

// Assignment Node
class AssignmentNode : public ASTNode {
public:
    std::string varName;
    std::string varType;
    ASTNode* value;
    bool inferType;  // true if type should be inferred
    
    AssignmentNode(const std::string& name, const std::string& type, ASTNode* val, bool infer = false)
        : ASTNode(NodeType::ASSIGNMENT), varName(name), varType(type), value(val), inferType(infer) {}
    
    ~AssignmentNode() {
        delete value;
    }
};

// Compound Assignment Node (+=, -=, etc.)
class CompoundAssignmentNode : public ASTNode {
public:
    std::string varName;
    std::string op;
    ASTNode* value;
    
    CompoundAssignmentNode(const std::string& name, const std::string& operation, ASTNode* val)
        : ASTNode(NodeType::COMPOUND_ASSIGNMENT), varName(name), op(operation), value(val) {}
    
    ~CompoundAssignmentNode() {
        delete value;
    }
};

// Increment/Decrement Node
class IncrementNode : public ASTNode {
public:
    std::string varName;
    bool isIncrement;  // true for ++, false for --
    bool isPrefix;     // true for ++x, false for x++
    
    IncrementNode(const std::string& name, bool inc, bool pre)
        : ASTNode(NodeType::INCREMENT), varName(name), isIncrement(inc), isPrefix(pre) {}
};

// Print Statement Node
class PrintNode : public ASTNode {
public:
    ASTNode* expression;
    
    PrintNode(ASTNode* expr)
        : ASTNode(NodeType::PRINT_STMT), expression(expr) {}
    
    ~PrintNode() {
        delete expression;
    }
};

// Statement List Node
class StatementListNode : public ASTNode {
public:
    std::vector<ASTNode*> statements;
    
    StatementListNode()
        : ASTNode(NodeType::STATEMENT_LIST) {}
    
    void addStatement(ASTNode* stmt) {
        statements.push_back(stmt);
    }
    
    ~StatementListNode() {
        for (auto stmt : statements) {
            delete stmt;
        }
    }
};

// Module Node
class ModuleNode : public ASTNode {
public:
    std::string name;
    StatementListNode* statements;
    
    ModuleNode(const std::string& n, StatementListNode* stmts)
        : ASTNode(NodeType::MODULE), name(n), statements(stmts) {}
    
    ~ModuleNode() {
        delete statements;
    }
};

// Program Node (root) - now just holds statements directly
class ProgramNode : public ASTNode {
public:
    StatementListNode* statements;
    
    ProgramNode(StatementListNode* stmts)
        : ASTNode(NodeType::PROGRAM), statements(stmts) {}
    
    ~ProgramNode() {
        delete statements;
    }
};

// Input Statement Node
class InputNode : public ASTNode {
public:
    std::string varName;
    
    InputNode(const std::string& name)
        : ASTNode(NodeType::INPUT_STMT), varName(name) {}
};

// If Statement Node
class IfNode : public ASTNode {
public:
    ASTNode* condition;
    StatementListNode* thenBlock;
    StatementListNode* elseBlock;  // can be nullptr
    
    IfNode(ASTNode* cond, StatementListNode* thenB, StatementListNode* elseB = nullptr)
        : ASTNode(NodeType::IF_STMT), condition(cond), thenBlock(thenB), elseBlock(elseB) {}
    
    ~IfNode() {
        delete condition;
        delete thenBlock;
        if (elseBlock) delete elseBlock;
    }
};

// While Loop Node
class WhileNode : public ASTNode {
public:
    ASTNode* condition;
    StatementListNode* body;
    
    WhileNode(ASTNode* cond, StatementListNode* b)
        : ASTNode(NodeType::WHILE_STMT), condition(cond), body(b) {}
    
    ~WhileNode() {
        delete condition;
        delete body;
    }
};

// Repeat Loop Node (for loop)
class RepeatNode : public ASTNode {
public:
    std::string varName;
    ASTNode* start;
    ASTNode* end;
    StatementListNode* body;
    
    RepeatNode(const std::string& var, ASTNode* s, ASTNode* e, StatementListNode* b)
        : ASTNode(NodeType::REPEAT_STMT), varName(var), start(s), end(e), body(b) {}
    
    ~RepeatNode() {
        delete start;
        delete end;
        delete body;
    }
};

// Function Definition Node
class FunctionNode : public ASTNode {
public:
    std::string name;
    std::vector<std::string> params;
    StatementListNode* body;
    
    FunctionNode(const std::string& n, const std::vector<std::string>& p, StatementListNode* b)
        : ASTNode(NodeType::FUNCTION_DEF), name(n), params(p), body(b) {}
    
    ~FunctionNode() {
        delete body;
    }
};

// Function Call Node
class FunctionCallNode : public ASTNode {
public:
    std::string name;
    std::vector<ASTNode*> arguments;
    
    FunctionCallNode(const std::string& n, const std::vector<ASTNode*>& args)
        : ASTNode(NodeType::FUNCTION_CALL), name(n), arguments(args) {}
    
    ~FunctionCallNode() {
        for (auto arg : arguments) {
            delete arg;
        }
    }
};

// Return Statement Node
class ReturnNode : public ASTNode {
public:
    ASTNode* value;  // can be nullptr for empty return
    
    ReturnNode(ASTNode* val = nullptr)
        : ASTNode(NodeType::RETURN_STMT), value(val) {}
    
    ~ReturnNode() {
        if (value) delete value;
    }
};

// Array Declaration Node
class ArrayDeclNode : public ASTNode {
public:
    std::string varName;
    int size;
    std::vector<ASTNode*> initialValues;  // can be empty
    
    ArrayDeclNode(const std::string& name, int sz, const std::vector<ASTNode*>& vals = {})
        : ASTNode(NodeType::ARRAY_DECL), varName(name), size(sz), initialValues(vals) {}
    
    ~ArrayDeclNode() {
        for (auto val : initialValues) {
            delete val;
        }
    }
};

// Array Access Node
class ArrayAccessNode : public ASTNode {
public:
    std::string varName;
    ASTNode* index;
    
    ArrayAccessNode(const std::string& name, ASTNode* idx)
        : ASTNode(NodeType::ARRAY_ACCESS), varName(name), index(idx) {}
    
    ~ArrayAccessNode() {
        delete index;
    }
};

// Array Assignment Node (for assigning to array elements)
class ArrayAssignmentNode : public ASTNode {
public:
    ArrayAccessNode* arrayAccess;
    ASTNode* value;
    
    ArrayAssignmentNode(ArrayAccessNode* access, ASTNode* val)
        : ASTNode(NodeType::ARRAY_ASSIGNMENT), arrayAccess(access), value(val) {}
    
    ~ArrayAssignmentNode() {
        delete arrayAccess;
        delete value;
    }
};

// Array Push Node (arr.barao(value);)
class ArrayPushNode : public ASTNode {
public:
    std::string varName;
    ASTNode* value;

    ArrayPushNode(const std::string& name, ASTNode* val)
        : ASTNode(NodeType::ARRAY_PUSH), varName(name), value(val) {}

    ~ArrayPushNode() {
        delete value;
    }
};

// Array Pop Node (arr.komao();)
class ArrayPopNode : public ASTNode {
public:
    std::string varName;

    ArrayPopNode(const std::string& name)
        : ASTNode(NodeType::ARRAY_POP), varName(name) {}
};

#endif // AST_H
