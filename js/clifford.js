'use strict';

// some symbolic names for encapsulation
//
const PLUS     = Symbol('addition');
const MINUS    = Symbol('substraction/negation');
const MULTIPLY = Symbol('multiplication');
const DIVIDE   = Symbol('division');
const POWER    = Symbol('exponentiation');
const L_PAREN  = Symbol('left parenthesis');
const R_PAREN  = Symbol('rigtht parenthesis');
const EQUALS   = Symbol('equality/affectation');

const IDENTIFIER = Symbol('identifier');
const NUMBER     = Symbol('number');
const PAREN      = Symbol('parenthesis');
const OPERATOR   = Symbol('operator');

const _                   = Symbol("underscore");
const _skipnontokens      = Symbol("skip non-tokens");
const _process_digits     = Symbol("process digits");
const _process_number     = Symbol("process number");
const _process_operator   = Symbol("process operator");
const _process_identifier = Symbol("process identifier");

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

    // private functions and attributes
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
    // - type: name of the pattern that this token matched (taken from rules).
    // - value: actual string value of the token.
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
        let tok = {
            type: IDENTIFIER,
            value: this.buf.substring(this.pos, endpos),
            pos: this.pos
        };
        this.pos = endpos;
        return tok;
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
        let tok = {
            type: NUMBER,
            value: this.buf.substring(this.pos, endpos),
            pos: this.pos
        };
        this.pos = endpos;
        return tok;
    }

    [_process_operator]() {
        const optable = {
            '+'  : PLUS,
            '-'  : MINUS,
            '*'  : MULTIPLY,
            '/'  : DIVIDE,
            '**' : POWER,
            '('  : L_PAREN,
            ')'  : R_PAREN,
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
        if (op) {
            let tok = {
                type: op === L_PAREN || op === R_PAREN ? PAREN : OPERATOR,
                value: op,
                pos: this.pos
            }
            this.pos = pos;
            return tok;
        } else { throw new Error(
            `unexpected token at pos ${pos}, substring is "${substring}"`); }
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
    constructor() {
    }

    parse(input) {
        let lexer = new Lexer();
        lexer.input = input;
        let tokens = lexer.input(input);
    }

}
var lexer = new Lexer();
lexer.input = "(foo * bar) ** 2";

for (let token of lexer.tokens()) {
    console.log(token);
}
