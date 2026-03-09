# Rajnoitikscript

A Bangladesh-themed programming language that transpiles to C++. Rajnoitikscript combines Bengali cultural elements with modern programming constructs, making coding more engaging and culturally relevant.

![Language](https://img.shields.io/badge/language-C%2B%2B-blue)
![Build Tool](https://img.shields.io/badge/build-Flex%20%2B%20Bison-green)
![Status](https://img.shields.io/badge/status-active-success)

## 🌟 Features

- **Python-style variable declarations** with automatic type inference
- **Bangladesh-themed keywords** (JoyBangla, khelaHobe, chandaDe, iHaveAplan)
- **Complete programming constructs**: variables, functions, loops, conditionals, arrays
- **Transpiles to C++** for high performance
- **Interactive input/output** support
- **Mathematical operations** including power operator (^)
- **Array manipulation** with initialization and element access
- **Function definitions** with parameters and return values

## 📋 Requirements

- **Flex** (Fast Lexical Analyzer) 2.x or higher
- **Bison** (GNU Parser Generator) 3.x or higher
- **G++** (GNU C++ Compiler) with C++11 support
- **Windows** (tested on Windows, adaptable to Linux/Mac)

## 🚀 Quick Start

### Building the Compiler

```powershell
flex lex.l
bison -d parser.y
g++ -std=c++11 -Wno-write-strings lex.yy.c parser.tab.c -o compiler.exe
```

### Compiling a Rajnoitikscript Program

```powershell
# Step 1: Compile .rs file to C++
.\compiler.exe yourprogram.rs

# Step 2: Compile generated C++ code
g++ generated.cpp -o program.exe

# Step 3: Run the executable
.\program.exe
```

## 📖 Language Syntax

### Comments
```rajnoitik
JoyBangla This is a single-line comment

JoyBanglaSuru
This is a
multi-line comment
JoyBanglaSesh
```

### Variables (Python-style)
```rajnoitik
set x = 10;
set name = "Bangladesh";
set pi = 3.14;
set isTrue = true;
```

### Arrays
```rajnoitik
set arr[10];                      JoyBangla declare array
set nums = {1, 2, 3, 4, 5};      JoyBangla with initialization
set value = nums[0];              JoyBangla access element
nums[2] = 99;                     JoyBangla modify element
```

### Input/Output
```rajnoitik
khelaHobe "Hello World";          JoyBangla print output
chandaDe username;                JoyBangla read input
```

### Conditionals
```rajnoitik
if (x > 5) {
    khelaHobe "Greater than 5";
} else {
    khelaHobe "Less than or equal to 5";
}
```

### Loops
```rajnoitik
JoyBangla While loop
while (x < 10) {
    khelaHobe x;
    x++;
}

JoyBangla For loop (repeat)
repeat i from 1 to 10 {
    khelaHobe i;
}
```

### Functions
```rajnoitik
iHaveAplan add(a, b) {
    return a + b;
}

iHaveAplan factorial(n) {
    if (n <= 1) {
        return 1;
    }
    return n * factorial(n - 1);
}
```

### Operators

**Arithmetic:** `+` `-` `*` `/` `%` `^` (power)  
**Comparison:** `==` `!=` `<` `>` `<=` `>=`  
**Logical:** `&&` `||` `!`  
**Assignment:** `=` `+=` `-=` `*=` `/=`  
**Increment/Decrement:** `++` `--`

## 💡 Example Programs

### Hello World
```rajnoitik
khelaHobe "Hello, Bangladesh!";
```

### Prime Number Checker
```rajnoitik
JoyBangla Check if a number is prime

iHaveAplan isPrime(n) {
    if (n <= 1) {
        return 0;
    }
    
    set i = 2;
    while (i * i <= n) {
        if (n % i == 0) {
            return 0;
        }
        i++;
    }
    return 1;
}

set num = 17;
if (isPrime(num) == 1) {
    khelaHobe "Prime number";
} else {
    khelaHobe "Not prime";
}
```

### Interactive Calculator
```rajnoitik
khelaHobe "Enter first number:";
chandaDe a;

khelaHobe "Enter second number:";
chandaDe b;

set sum = a + b;
set product = a * b;

khelaHobe "Sum:";
khelaHobe sum;

khelaHobe "Product:";
khelaHobe product;
```

### Fibonacci Sequence
```rajnoitik
set fib[15];
fib[0] = 0;
fib[1] = 1;

khelaHobe fib[0];
khelaHobe fib[1];

repeat i from 2 to 14 {
    fib[i] = fib[i - 1] + fib[i - 2];
    khelaHobe fib[i];
}
```

> **More examples available in [EXAMPLES.txt](EXAMPLES.txt)**

## 🏗️ Project Structure

```
Rajnoitikscript/
├── lex.l              # Lexer specification (Flex)
├── parser.y           # Parser grammar (Bison)
├── ast.h              # Abstract Syntax Tree node definitions
├── compiler.exe       # Compiled compiler executable
├── *.rs               # Rajnoitikscript source files
├── generated.cpp      # Generated C++ code (output)
├── EXAMPLES.txt       # Comprehensive example programs
└── README.md          # This file
```

## 🔧 Technical Details

### Compilation Pipeline

```
Rajnoitikscript (.rs)
        ↓
    [Lexer (Flex)]
        ↓
      Tokens
        ↓
   [Parser (Bison)]
        ↓
   Abstract Syntax Tree
        ↓
   [Code Generator]
        ↓
    C++ Code (.cpp)
        ↓
    [G++ Compiler]
        ↓
   Executable (.exe)
```

### Type Inference

Variables declared with `set` or `chandaDe` automatically infer types:
- **Integer literals** → `int`
- **Floating-point literals** → `double`
- **String literals** → `std::string`
- **Boolean literals** → `bool`
- **Variable names with "name", "text", "message"** → `std::string` (for chandaDe)
- **Expressions** → type based on operands

### AST-Based Code Generation

The compiler builds a complete Abstract Syntax Tree before generating C++ code, enabling:
- Better error detection
- Optimization opportunities
- Clean separation of parsing and code generation
- Support for complex language features

## 🎓 Keywords Reference

| Rajnoitikscript | English Equivalent | Usage |
|-----------------|-------------------|-------|
| `JoyBangla` | Comment | Single-line comment |
| `JoyBanglaSuru...JoyBanglaSesh` | Multi-line comment | Block comment |
| `khelaHobe` | Print | Output statement |
| `chandaDe` | Input | Read user input |
| `set` | Declare | Variable declaration |
| `iHaveAplan` | Function | Function definition |
| `repeat...from...to` | For loop | Range-based loop |
| `if...else` | If...else | Conditional statement |
| `while` | While | While loop |
| `return` | Return | Function return |

## 🐛 Known Limitations

- **String manipulation** is limited (uses C++ string operations)
- **No classes/objects** (procedural programming only)
- **Basic error messages** (line numbers provided)
- **Shift/reduce conflict** in grammar (resolved automatically)
- **Function forward references** require definition before use

## 🤝 Contributing

Contributions are welcome! Areas for improvement:
- Enhanced error messages with suggestions
- More data types (float, char, long)
- Object-oriented programming support
- Standard library functions
- Better string manipulation
- Debugger integration

## 📜 License

This project is open-source and available for educational purposes.

## 👨‍💻 Author

Created with passion for Bangladesh and programming education.

---

**Made with ❤️ in Bangladesh**

*"Joy Bangla! - Victory to Bangladesh!"*
