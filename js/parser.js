'use strict';
/**
 * Grammar without left recursion
 *
 * eqn         -> expr = expr
 * expr        -> term expr_rest
 * expr_rest   -> + term expr_rest
 *             | - term expr_rest
 *             | ε
 *
 * term        -> factor term_rest
 * term_rest   -> * term term_rest
 *             |   term term_rest
 *             | ^ term term_rest
 *             | / term term_rest
 *             | ε
 *
 * factor      -> (expr)
 *             | num
 *             | id
 *
 **/

let Lexer            = require('./lexer'),

    $tokens          = require('./tokens'),
    LiteralNumber    = $tokens.LiteralNumber,
    Addition         = $tokens.Addition,
    Subtraction      = $tokens.Subtraction,
    Multiplication   = $tokens.Multiplication,
    Division         = $tokens.Division,
    Exponentiation   = $tokens.Exponentiation,
    LeftParenthesis  = $tokens.LeftParenthesis,
    RightParenthesis = $tokens.RightParenthesis,
    Identifier       = $tokens.Identifier,

    $expressions     = require('./expressions'),
    Expression       = $expressions.Expression,

    $helper          = require('./helper'),
    isInt            = $helper.isInt,

    Fraction         = require('./fractions')

;

class Parser {

    constructor() { this.lexer = new Lexer(); }
    set input(input) {
        this.lexer.input = input;
        this.tokens = this.lexer.tokens();
        this._token_iteration = null;
    }
    update() { this._token_iteration = this.tokens.next(); }
    get token() { return this._token_iteration.value; }
    done() { return this._token_iteration.done; }

    parse(string)     {
        this.input = string;
        this.update();
        return this.parseExpr();
    }
    parseExpr() { return this.parseExprRest(this.parseTerm()); }
    parseTerm() { return this.parseTermRest(this.parseFactor()); }
    parseFactor() {
        if (this.token instanceof LiteralNumber) {
            let num = this.parseNumber();
            this.update();
            return num;
        } else if (this.token instanceof Identifier) {
            let identifier = new Expression(this.token.name);
            this.update();
            return identifier;
        } else if (this.token instanceof LeftParenthesis) {
            this.update();
            let expr = this.parseExpr();
            if (this.token instanceof RightParenthesis) {
                this.update();
                return expr;
            } else {
                throw new SyntaxError('Unbalanced Parenthesis');
            }
        } else { return undefined; }
    }
    parseNumber() {
        let intValue = parseInt(this.token.string);
        //Integer conversion
        if (intValue == this.token.string) {
            return new Expression(intValue);      
        } else {
            //Split the decimal number to integer and decimal parts
            let splits = this.token.string.split('.');
            //count the digits of the decimal part
            let decimals = splits[1].length;
            //determine the multiplication factor
            let factor = Math.pow(10,decimals);
            let float_op = parseFloat(this.token.string);
            //multiply the float with the factor and divide it again afterwards 
            //to create a valid expression object
            return new Expression(parseInt(float_op * factor)).divide(factor);
        }
    }
    parseExprRest(term) {
        if (this.token instanceof Addition) {
            this.update();
            let plusterm = this.parseTerm();
            if(term === undefined || plusterm === undefined) throw new SyntaxError('Missing operand');
            return this.parseExprRest(term.add(plusterm));
        } else if (this.token instanceof Subtraction) {
            this.update();
            let minusterm = this.parseTerm();
            //This case is entered when a negative number is parsed e.g. x = -4
            if (term === undefined) {
                return this.parseExprRest(minusterm.multiply(-1));
            } else {
                return this.parseExprRest(term.subtract(minusterm));
            }
        } else {
            return term;
        }
    }
    parseTermRest(factor) {
        if (this.token instanceof Multiplication) {
            this.update();
            let mulfactor = this.parseFactor(),
                termRest  = this.parseTermRest(mulfactor),
                product   = factor.multiply(termRest);
            return product;
        } else if (this.token instanceof Exponentiation) {
            this.update();
            let powfactor = this.parseFactor();
            //WORKAROUND: algebra.js only allows integers and fractions for
            //raising
            return this.parseTermRest(
                factor.pow(parseInt(powfactor.toString()))
            );
        } else if (this.token instanceof Division) {
            this.update();
            let devfactor = this.parseFactor();
            //WORKAROUND: algebra.js only allows integers and fractions for division
            return this.parseTermRest(
                factor.divide(this.convertToFraction(devfactor))
            );
        } else if (this.done()) {
            return factor;
        } else {
            //a missing operator between terms is treated like a multiplier
            let mulfactor2 = this.parseFactor();
            if (mulfactor2 === undefined) {
                return factor;
            } else {
                return factor.multiply(this.parseTermRest(mulfactor2));
            }
        }
    }
    convertToFraction(expression) {
        if(expression.terms.length > 0){
            throw new TypeError(
                'Invalid Argument (' + expression.toString() +
                '): Divisor must be of type Integer or Fraction.'
            );
        } else {
            let c = expression.constants[0];
            return new Fraction(c.numer, c.denom);
        }
    }
}


module.exports = Parser;
