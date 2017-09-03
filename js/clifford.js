'use strict';
// This code is derived from algebra.js (http://algebra.js.org)

// some symbolic names
//
const PLUS   = Symbol('addition');
const MINUS  = Symbol('substraction/negation');
const MULT   = Symbol('multiplication');
const DIVIDE = Symbol('division');
const POWER  = Symbol('exponentiation');
const LPAREN = Symbol('left parenthesis');
const RPAREN = Symbol('rigtht parenthesis');
const EQUALS = Symbol('equality/affectation');

const _                   = Symbol("underscore");
const _skipnontokens      = Symbol("skip non-tokens");
const _process_digits     = Symbol("process digits");
const _process_number     = Symbol("process number");
const _process_operator   = Symbol("process operator");
const _process_identifier = Symbol("process identifier");

const ε          = Symbol('epsilon');
const NUMBER     = Symbol('number');
const IDENTIFIER = Symbol('identifier');

// Token class and its children
//
class Token { constructor(pos) { this.pos = pos; } }
class Identifier extends Token {
    constructor(pos, name) { super(pos); this.name = name; }
}
class LiteralNumber extends Token {
    constructor(pos, string) { super(pos); this.string = string; }
}
class Parenthesis extends Token {
    constructor(pos, symbol) {
        super(pos);
        if (symbol === LPAREN || symbol === RPAREN) {
            this.symbol = symbol;
        } else { throw new Error("unexpected argument type"); }
    }
}
class Operator extends Token {
    constructor(pos, symbol) {
        const operators = [
            PLUS, MINUS, MULT, DIVIDE, POWER, EQUALS
        ];
        super(pos);
        if (operators.map(op => symbol === op).reduce((a,b) => a || b)) {
            this.symbol = symbol;
        } else { throw new Error("unexpected argument type"); }
    }
}

/*
  The lexer module is a slightly modified version of the handwritten lexer by
  Eli Bendersky.  The parts not needed like comments and quotes were deleted
  and some things modified.  Comments are left unchanged, the original lexer
  can be found here:
  http://eli.thegreenplace.net/2013/07/16/hand-written-lexer-in-javascript-compared-to-the-regex-based-ones
*/
class Lexer {
    constructor() {
        this.pos = 0;
        this.buf = null;
        this.buflen = 0;
    }

    // Initialize the Lexer's buffer. This resets the lexer's internal
    // state and subsequent tokens will be returned starting with the
    // beginning of the new buffer.
    set input(input) {
        this.pos = 0;
        this.buf = input;
        this.buflen = input.length;
    }

    // private functions
    static get [_]() {
        return {
            isalpha: c =>
            (c >= 'a' && c <= 'z') ||
            (c >= 'A' && c <= 'Z'),
            isdigit: c =>
            c >= '0' && c <= '9',
            isalphanum: c =>
            (c >= 'a' && c <= 'z') ||
            (c >= 'A' && c <= 'Z') ||
            (c >= '0' && c <= '9')
        }
    }

    // Get tokens from the current buffer. A token is an object with
    // the following properties:
    // - type: symbolic name of the pattern that this token matched (taken from rules).
    // - string: actual string value of the token.
    // - symbol: symbol value if relevant.
    // - pos: offset in the current buffer where the token starts.
    *tokens() {
        for(
            this[_skipnontokens]();
            this.pos < this.buflen;
            this[_skipnontokens]()
        ) {
            // The char at this.pos is part of a real token. Figure out which.
            let c = this.buf.charAt(this.pos);

            if (Lexer[_].isalpha(c)) {
                yield this[_process_identifier]();
            } else if (Lexer[_].isdigit(c)) {
                yield this[_process_number]();
            } else {
                yield this[_process_operator]();
            }
        }
    }

    [_process_identifier]() {
        let endpos = this.pos + 1;
        while (
            endpos < this.buflen &&
            Lexer[_].isalphanum(this.buf.charAt(endpos))
        ) { endpos++; }
        let identifier = new Identifier(
            this.pos,
            this.buf.substring(this.pos, endpos)
        );
        this.pos = endpos;
        return identifier;
    }

    [_process_digits](position) {
        let endpos = position;
        while (endpos < this.buflen &&
            (Lexer[_].isdigit(this.buf.charAt(endpos)))){
            endpos++;
        }
        return endpos;
    }

    [_process_number]() {
        //Read characters until a non-digit character appears
        let endpos = this[_process_digits](this.pos);
        //If it's a decimal point, continue to read digits
        if(this.buf.charAt(endpos) === '.'){
            endpos = this[_process_digits](endpos + 1);
        }
        //Check if the last read character is a decimal point.
        //If it is, ignore it and proceed
        if(this.buf.charAt(endpos-1) === '.'){
            throw new SyntaxError(
                "Decimal point without decimal digits at position " +
                (endpos-1)
            );
        }
        //construct the NUMBER token
        let number = new LiteralNumber(
            this.pos,
            this.buf.substring(this.pos, endpos)
        );
        this.pos = endpos;
        return number;
    }

    [_process_operator]() {
        const optable = {
            '+'  : PLUS,
            '-'  : MINUS,
            '*'  : MULT,
            '/'  : DIVIDE,
            '**' : POWER,
            '('  : LPAREN,
            ')'  : RPAREN,
            '='  : EQUALS
        }
        let substring = '', op, pos = this.pos;
        while (
            pos < this.buflen && (
                optable[
                    substring += this.buf.charAt(pos)
                ]
            )
        ) { pos++; op = optable[substring]; }
        if (op === LPAREN || op === RPAREN) {
            let paren = new Parenthesis(
                this.pos,
                op
            );
            this.pos = pos;
            return paren;
        } else if (op) {
            let operator = new Operator(
                this.pos,
                op
            );
            this.pos = pos;
            return operator;
        } else {
            throw new Error(
                `unexpected token at pos ${pos}, substring is "${substring}"`
            );
        }
    }

    [_skipnontokens]() {
        while (this.pos < this.buflen) {
            let c = this.buf.charAt(this.pos);
            if (
                c == ' '  ||
                c == '\t' ||
                c == '\r' ||
                c == '\n'
            ) { this.pos++; } else { break; }
        }
    }

}

class Parser {

    parse(input) {
        let lexer = new Lexer();
        lexer.input = input;
        this.tokens = lexer.tokens();
    }
    update() { this.token_iteration = this.tokens.next(); }

    match(symbol) {
        if (this.token_iteration.done) { return symbol === ε; }
        let token = this.token_iteration.value;
        switch (symbol) {
            case PLUS:
                return (token instanceof Operator) && (token.symbol === PLUS);
            case MINUS:
                return (token instanceof Operator) && (token.symbol === MINUS);
            case MULT:
                return (token instanceof Operator) && (token.symbol === MULT);
            case POWER:
                return (token instanceof Operator) && (token.symbol === POWER);
            case DIVIDE:
                return (token instanceof Operator) && (token.symbol === DIVIDE);
            case EQUALS:
                return (token instanceof Operator) && (token.symbol === EQUALS);
            case LPAREN:
                return (token instanceof Parenthesis) && (token.symbol === LPAREN);
            case RPAREN:
                return (token instanceof Parenthesis) && (token.symbol === RPAREN);
            case NUMBER:
                return token instanceof LiteralNumber;
            case IDENTIFIER:
                return token instanceof Identifier;
            default:
                return false;
        }

    }

    parseExpr() { return this.parseExprRest(this.parseTerm); }
    parseTerm() { return this.parseTermRest(this.parseFactor()); }
    parseFactor() {
        if (this.match(NUMBER)) {
            var num = this.parseNumber();
            this.update();
            return num;
        } else if (this.match(IDENTIFIER)) {
            var id = new Expression(this.token_iteration.value.string);
            this.update();
            return id;
        }
    }
}

class Expression {
    constructor(variable) {
        this.constants = [];
        if (typeof(variable) === 'string') {
            this.terms = [new Term(new Variable(variable))];
        }
    }
}

class Variable {
    constructor(variable) {
        if (typeof(variable) === 'string') {
            this.degree = 1;
            this.variable = Symbol.for(variable);
        } else {
            throw new TypeError(
                `Invalid Argument (${variable.toString()}):`+
                "Variable initalizer must be of type String."
            );
        }
    }
}

class Term {
    constructor(variable) {
        if (variable instanceof Variable) {
            this.variables = [variable.copy()];
        } else if (true) {
        }
    }
}


var parser = new Parser();
parser.parse("3.14*(foo + x)");
parser.update();
console.log(parser.match(NUMBER));

