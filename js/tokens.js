'use strict';

class Token { constructor(pos) { this.pos = pos; } }
class Identifier extends Token {
    constructor(pos, name) { super(pos); this.name = name; }
    toString() { return this.name; }
}
class LiteralNumber extends Token {
    constructor(pos, string) { super(pos); this.string = string; }
}

class Parenthesis extends Token { constructor(pos) { super(pos); } }
class LeftParenthesis  extends Parenthesis { constructor(pos) { super(pos); } }
class RightParenthesis extends Parenthesis { constructor(pos) { super(pos); } }

class Operator extends Token {
    constructor(pos) { super(pos); }
    get size() { 1 }
}
class Addition extends Operator { constructor(pos) { super(pos); } }
class Subtraction extends Operator { constructor(pos) { super(pos); } }
class Multiplication extends Operator { constructor(pos) { super(pos); } }
class Division extends Operator { constructor(pos) { super(pos); } }
class Exponentiation extends Operator {
    constructor(pos) { super(pos); }

    // exponentiation is '**', so two characters instead of 1
    get size() { 2 }
}
class OuterProduct extends Operator { constructor(pos) { super(pos); } }
class InnerProduct extends Operator { constructor(pos) { super(pos); } }
class Equality extends Operator { constructor(pos) { super(pos); } }

const optable = {
    '+'  : Addition,
    '-'  : Subtraction,
    '*'  : Multiplication,
    '∧'  : OuterProduct,
    '·'  : InnerProduct,
    '/'  : Division,
    '**' : Exponentiation,
    '='  : Equality
}
module.exports = {
    optable,
    Token, Operator, Parenthesis,
    LiteralNumber,
    Addition, Subtraction,
    Multiplication, Division,
    Exponentiation,
    LeftParenthesis, RightParenthesis,
    Identifier
}
