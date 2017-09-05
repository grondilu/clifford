'use strict';
let $tokens          = require('./tokens'),
    optable          = $tokens.optable,
    LiteralNumber    = $tokens.LiteralNumber,
    Addition         = $tokens.Addition,
    Subtraction      = $tokens.Subtraction,
    Multiplication   = $tokens.Multiplication,
    Division         = $tokens.Division,
    Exponentiation   = $tokens.Exponentiation,
    LeftParenthesis  = $tokens.LeftParenthesis,
    RightParenthesis = $tokens.RightParenthesis,
    Identifier       = $tokens.Identifier
;

const _                    = Symbol("underscore");
const _skipnontokens       = Symbol("skip non-tokens");
const _process_digits      = Symbol("process digits");
const _process_number      = Symbol("process number");
const _process_parenthesis = Symbol("process parenthesis");
const _process_operator    = Symbol("process operator");
const _process_identifier  = Symbol("process identifier");

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
        this[_skipnontokens]();
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

    // Get tokens from the current buffer.
    *tokens() {
        for(
            ;
            this.pos < this.buflen;
            this[_skipnontokens]()
        ) {
            // The char at this.pos is part of a real token. Figure out which.
            let c = this.buf.charAt(this.pos);

            if (Lexer[_].isalpha(c)) {
                yield this[_process_identifier]();
            } else if (Lexer[_].isdigit(c)) {
                yield this[_process_number]();
            } else if ([')', '('].includes(c)) {
                yield this[_process_parenthesis]();
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
    [_process_parenthesis]() {
        let pos = this.pos++,
            c   = this.buf.charAt(pos);
        if (c === '(') {
            return new LeftParenthesis(pos);
        } else if (c === ')') {
            return new RightParenthesis(pos);
        } else {
            throw new Error('parenthesis was expected');
        }
    }
    [_process_operator]() {
        let substring = '', op, pos = this.pos;
        while (
            pos < this.buflen && (
                substring += this.buf.charAt(pos)
            ) in optable
        ) { pos++; op = optable[substring]; }
        if (op) {
            let operator = new op(this.pos);
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

module.exports = Lexer;
