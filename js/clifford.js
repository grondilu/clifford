'use strict';
// This code is derived from algebra.js (http://algebra.js.org)

/*
 * Helper functions
 *
 */
function gcd(x, y) { return y == 0 ? x : gcd(y, x % y); }
function lcm(x, y) { return (x * y) / gcd(x, y); }
function isInt(thing) {
    return (typeof thing == "number") && (thing % 1 === 0);
}

function round(decimal, places) {
    places = (typeof(places) === "undefined" ? 2 : places);
    var x = Math.pow(10, places);
    return Math.round(parseFloat(decimal) * x) / x;
}

/*
 * some symbolic names
 *
 */
const PLUS   = Symbol('addition');
const MINUS  = Symbol('substraction/negation');
const MULT   = Symbol('multiplication');
const DIVIDE = Symbol('division');
const POWER  = Symbol('exponentiation');
const WEDGE  = Symbol('outer product');
const CDOT   = Symbol('inner product');
const LPAREN = Symbol('left parenthesis');
const RPAREN = Symbol('rigtht parenthesis');
const EQUALS = Symbol('equality/affectation');

const _                    = Symbol("underscore");
const _skipnontokens       = Symbol("skip non-tokens");
const _process_digits      = Symbol("process digits");
const _process_number      = Symbol("process number");
const _process_parenthesis = Symbol("process parenthesis");
const _process_operator    = Symbol("process operator");
const _process_identifier  = Symbol("process identifier");

const ε          = Symbol('epsilon');
const NUMBER     = Symbol('number');
const IDENTIFIER = Symbol('identifier');

/*
 * Token class and its children
 *
 */
class Token { constructor(pos) { this.pos = pos; } }
class Epsilon extends Token {}
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

    // Get tokens from the current buffer.
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
class Parser {

    constructor() { this.lexer = new Lexer(); }
    set input(input) {
        this.lexer.input = input;
        this.tokens = this.lexer.tokens();
        this.token_iteration = null;
    }
    update() { this.token_iteration = this.tokens.next(); }

    match(token_class) {
        // dummy instance just for type checking
        let dummy = new token_class();

        if (!(dummy instanceof Token)) {
            throw new TypeError("Token class was expected");
        } else if (!this.token_iteration) {
            throw new Error("parser is not ready");
        } else if (this.token_iteration.done) {
            return dummy instanceof Epsilon;
        } else {
            return this.token_iteration.value instanceof token_class;
        }
    }

    parseExpr() { return this.parseExprRest(this.parseTerm); }
    parseTerm() { return this.parseTermRest(this.parseFactor()); }
    parseFactor() {
        if (this.match(LiteralNumber)) {
            return this.parseNumber();
        } else if (this.match(Identifier)) {
            return new Expression(this.token_iteration.value.name);
        }
        this.update();
    }
    parseNumber() {
        let token = this.token_iteration.value,
            intValue = parseInt(token.string);
        //Integer conversion
        if (intValue == token.string) {
            return new Expression(intValue);      
        } else {
            //Split the decimal number to integer and decimal parts
            let splits = token.string.split('.');
            //count the digits of the decimal part
            let decimals = splits[1].length;
            //determine the multiplication factor
            let factor = Math.pow(10,decimals);
            let float_op = parseFloat(token.string);
            //multiply the float with the factor and divide it again afterwards 
            //to create a valid expression object
            return new Expression(parseInt(float_op * factor)).divide(factor);
        }
    }
}
class Expression {
    constructor(variable) {
        this.constants = [];
        if (typeof(variable) === 'string') {
            this.terms = [new Term(new Variable(variable))];
        } else if(isInt(variable)) {
            this.constants = [new Fraction(variable, 1)];
            this.terms = [];
        } else if(variable instanceof Fraction) {
            this.constants = [variable];
            this.terms = [];
        } else if(variable instanceof Term) {
            this.terms = [variable];
        } else if(typeof(variable) === "undefined") {
            this.terms = [];
        } else {
            throw new TypeError("Invalid Argument (" + variable.toString() + "): Argument must be of type String, Integer, Fraction or Term.");
        }
    }
    get constant() {
        return this.constants.reduce((p,c) => p.add(c), new Fraction(0, 1));
    }
    simplify() {
        let copy = this.copy();

        //simplify all terms
        copy.terms = copy.terms.map(t => t.simplify());

        copy._sort();
        copy._combineLikeTerms();
        copy._moveTermsWithDegreeZeroToConstants();
        copy._removeTermsWithCoefficientZero();
        copy.constants =
            copy.constant.valueOf() === 0 ? [] :
            [copy.constant];

        return copy;
    }
    copy() {
        let copy = new Expression();

        //copy all constants
        copy.constants = this.constants.map(c => c.copy());
        //copy all terms
        copy.terms = this.terms.map(t => t.copy());

        return copy;
    }
    add(a, simplify = true) {
        let thisExp = this.copy();
        if (
            typeof(a) === "string" ||
            a instanceof Term ||
            isInt(a) ||
            a instanceof Fraction
        ) {
            return thisExp.add(new Expression(a), simplify);
        } else if (a instanceof Expression) {
            let keepTerms = a.copy().terms;

            thisExp.terms = thisExp.terms.concat(keepTerms);
            thisExp.constants = thisExp.constants.concat(a.constants);
            thisExp._sort();
        } else {
            throw new TypeError(
                "Invalid Argument (" + a.toString() +
                "): Summand must be of type String, Expression, Term, Fraction or Integer.");
        }
        return simplify ? thisExp.simplify() : thisExp;
    }
    subtract(a, simplify = true) {
        return this.add(
            (a instanceof Expression ? a : new Expression(a)).multiply(-1)
            , simplify
        );
    }
    multiply(a, simplify = true) {
        let thisExp = this.copy();
        if (
            typeof(a) === "string" ||
            a instanceof Term ||
            isInt(a) ||
            a instanceof Fraction
        ) { a = new Expression(a); }
        if (a instanceof Expression) {
            let thatExp = a.copy(),
                newTerms = [];

            for (let thisTerm of thisExpr.terms) {
                for (let thatTerm of thatExp.terms) {
                    newTerms.push(thisTerm.multiply(thatTerm, simplify));
                }
                for (let thatConst of thatExp.constants) {
                    newTerms.push(thisTerm.multiply(thatConst, simplify));
                }
            }

            for (let thatTerm of thatExp.terms) {
                for (let thisConst of thisExp.constants) {
                    newTerms.push(thatTerm.multiply(thisConst, simplify));
                }
            }

            var newConstants = [];

            for (let thisConst of thisExp.constants) {
                for (let thatConst of thatExp.constants) {
                    var t = new Term();
                    t = t.multiply(thatConst, false);
                    t = t.multiply(thisConst, false);
                    newTerms.push(t);
                }
            }

            thisExp.constants = newConstants;
            thisExp.terms = newTerms;
            thisExp._sort();
        } else {
            throw new TypeError(
                "Invalid Argument (" + a.toString() +
                "): Multiplicand must be of type String, Expression, Term, Fraction or Integer."
            );
        }

        return simplify ? thisExp.simplify() : thisExp;
    }
    divide(a, simplify = true) {
        if (a instanceof Fraction || isInt(a)) {

            if (a.valueOf() === 0) {
                throw new EvalError("Divide By Zero");
            }

            let copy = this.copy();
            for (let thisTerm of copy.terms) {
                for (var j = 0; j < thisTerm.coefficients.length; j++) {
                    thisTerm.coefficients[j] =
                        thisTerm.coefficients[j].divide(a, simplify);
                }
            }

            //divide every constant by a
            copy.constants =
                copy.constants.map(c => c.divide(a,simplify));

            return copy;
        } else if (a instanceof Expression) {
            //Simplify both expressions
            let numer = this.copy().simplify(),
                denom = a.copy().simplify(),

                //Total amount of terms and constants
                numerTotal = num.terms.length + num.constants.length,
                denomTotal = denom.terms.length + denom.constants.length;

            //Check if both terms are monomial
            if (numerTotal === 1 && denomTotal === 1) {
                //Divide coefficients
                let numerCoef = num.terms[0].coefficients[0],
                    denomCoef = denom.terms[0].coefficients[0];

                //The expressions have just been simplified
                //- only one coefficient per term
                numer.terms[0].coefficients[0] = numerCoef.divide(denomCoef, simplify);
                denom.terms[0].coefficients[0] = new Fraction(1, 1);

                //Cancel variables
                for (let numerVar of numer.terms[0].variables) {
                    for (let denomVar of denom.terms[0].variables) {
                        //Check for equal variables
                        if (numerVar.name === denomVar.name) {
                            //Use the rule for division of powers
                            numerVar.degree -= denomVar.degree;
                            denomVar.degree = 0;
                        }
                    }
                }

                //Invers all degrees of remaining variables
                denom.terms[0].variables.forEach(v => v.degree *= -1);

                //Multiply the inversed variables to the numenator
                numer = numer.multiply(denom, simplify);

                return numer;
            } else {
                throw new TypeError(
                    "Invalid Argument ((" + num.toString() + ")/("+
                    denom.toString() +
                    ")): Only monomial expressions can be divided."
                );
            }
        } else {
            throw new TypeError(
                "Invalid Argument (" + a.toString() +
                "): Divisor must be of type Fraction or Integer."
            );
        }
    }
    pow(n, simplify = true) {
        if (isInt(n)) {
            let copy = this.copy();
            if (n === 0) {
                if (this.valueOf() == 0) {
                    throw new EvalError('zero to the zeroth power');
                } else { return new Expression().add(1); }
            } else if (n === 1) {
                // do nothing
            } else if (n < 0) {
                return new Expression()
                    .add(1)
                    .divide(this.pow(-n, simplify));
            } else if (n > 1) {
                copy = copy.multiply(copy).pow(Math.floor(n/2)) ;
                if (n % 2) { copy = copy.multiply(this.copy()); }
            } else { throw new Error('unreachable'); }
            return simplify ? copy.simplify() : copy._sort();
        } else {
            throw new TypeError(
                "Invalid Argument (" + a.toString() +
                "): Exponent must be of type Integer."
            );
        }
    }
    eval(values, simplify = true) {
        let exp = new Expression();
        exp.constants = simplify ? [this.constant] : this.constants.slice();

        //add all evaluated terms of this to exp
        exp = this.terms
            .reduce(
                (p,c) => p.add(c.eval(values,simplify),simplify),
                exp
            );

        return exp;
    }
    summation(variable, lower, upper, simplify = true) {
        let thisExpr = this.copy(),
            newExpr  = new Expression();
        for(var i = lower; i < (upper + 1); i++) {
            let sub = {};
            sub[variable] = i;
            newExpr = newExpr.add(thisExpr.eval(sub, simplify), simplify);
        }
        return newExpr;
    }
    toString(options = {}) {
        let str = "";

        for (let i = 0; i < this.terms.length; i++) {
            let term = this.terms[i];

            str += (term.coefficients[0].valueOf() < 0 ? " - " : " + ") + term.toString(options);
        }

        for (let i = 0; i < this.constants.length; i++) {
            let constant = this.constants[i];

            str += (constant.valueOf() < 0 ? " - " : " + ") + constant.abs().toString();
        }

        if (str.substring(0, 3) === " - ") {
            return "-" + str.substring(3, str.length);
        } else if (str.substring(0, 3) === " + ") {
            return str.substring(3, str.length);
        } else {
            return "0";
        }
    }
    toTeX(dict = {}) {
        let str = "";

        for (let i = 0; i < this.terms.length; i++) {
            let term = this.terms[i];

            str += (term.coefficients[0].valueOf() < 0 ? " - " : " + ") + term.toTex(dict);
        }

        for (let i = 0; i < this.constants.length; i++) {
            let constant = this.constants[i];

            str += (constant.valueOf() < 0 ? " - " : " + ") + constant.abs().toTex();
        }

        if (str.substring(0, 3) === " - ") {
            return "-" + str.substring(3, str.length);
        } else if (str.substring(0, 3) === " + ") {
            return str.substring(3, str.length);
        } else {
            return "0";
        }
    }
    _removeTermsWithCoefficientZero() {
        this.terms = this.terms
            .filter(t => t.coefficient.reduce().numer !== 0);
        return this;
    }
    _combineLikeTerms() {
        function alreadyEncountered(term, encountered) {
            for (let i = 0; i < encountered.length; i++) {
                if (term.canBeCombinedWith(encountered[i])) {
                    return true;
                }
            }
            return false;
        }

        let newTerms = [], encountered = [];
        for (var i = 0; i < this.terms.length; i++) {
            var thisTerm = this.terms[i];

            if (alreadyEncountered(thisTerm, encountered)) {
                continue;
            } else {
                for (var j = i + 1; j < this.terms.length; j++) {
                    var thatTerm = this.terms[j];

                    if (thisTerm.canBeCombinedWith(thatTerm)) {
                        thisTerm = thisTerm.add(thatTerm);
                    }
                }

                newTerms.push(thisTerm);
                encountered.push(thisTerm);
            }

        }

        this.terms = newTerms;
        return this;
    }
    _moveTermsWithDegreeZeroToConstants() {
        let keepTerms = [],
            constant = new Fraction(0, 1);

        for (let thisTerm of this.terms) {
            if (thisTerm.variables.length === 0) {
                constant = constant.add(thisTerm.coefficient);
            } else {
                keepTerms.push(thisTerm);
            }
        }

        this.constants.push(constant);
        this.terms = keepTerms;
        return this;
    }
    _sort() {
        this.terms = this.terms.sort(
            (a, b) => {
                let x = a.maxDegree(),
                    y = b.maxDegree();
                return x === y ?
                    b.variables.length - a.variables.length :
                    y - x;
            }
        );
        return this;
    }
    _hasVariable(name) {
        for (let term of this.terms) {
            if (term.hasVariable(name)) {
                return true;
            }
        }
        return false;
    }
    _onlyHasVariable(name) {
        for (let term of this.terms) {
            if (!term.onlyHasVariable(name)) {
                return false;
            }
        }
        return true;
    }
    _noCrossProductsWithVariable(name) {
        for (let term of this.terms) {
            if (term.hasVariable(name)  && !term.onlyHasVariable(name)) {
                return false;
            }
        }
        return true;
    }
    _noCrossProducts() {
        for (let term of this.terms) {
            if (term.variables.length > 1) {
                return false;
            }
        }
        return true;
    }
    _maxDegree() {
        return Math.max(1, ...this.terms.map(t => t.maxDegree()));
    }
    _maxDegreeOfVariable(name) {
        return Math.max(
            1, ...this.terms.map(t => t.maxDegreeOfVariable(name))
        );
    }
    _quadraticCoefficients() {
        // This function isn't used until everything has been moved to the LHS
        // in Equation.solve.
        let a, b = new Fraction(0, 1);
        for (let thisTerm of this.terms) {
            a = thisTerm.maxDegree() === 2 ? thisTerm.coefficient.copy() : a;
            b = thisTerm.maxDegree() === 1 ? thisTerm.coefficient.copy() : b;
        }
        let c = this.constant;

        return {a, b, c};
    }
    _cubicCoefficients() {
        // This function isn't used until everything has been moved to the LHS in Equation.solve.
        var a, b = new Fraction(0, 1), c = new Fraction(0, 1);

        for (let thisTerm of this.terms) {
            a = thisTerm.maxDegree() === 3 ? thisTerm.coefficient.copy() : a;
            b = thisTerm.maxDegree() === 2 ? thisTerm.coefficient.copy() : b;
            c = thisTerm.maxDegree() === 1 ? thisTerm.coefficient.copy() : c;
        }

        let d = this.constant;
        return {a, b, c, d};
    }
}
class Variable {
    constructor(name, degree = 1) {
        if (typeof(name) === 'string') {
            this.degree = degree;
            this.name = name;
        } else {
            throw new TypeError(
                `Invalid Argument (${variable.toString()}):`+
                "Variable initalizer must be of type String."
            );
        }
    }
    copy() { return new Variable(this.name, this.degree); }
    toString() {
        let degree = this.degree, name = this.name;

        if (degree === 0) {
            return "";
        } else if (degree === 1) {
            return name;
        } else if (degree > 1 && degree < 10) {
            return name + '²³⁴⁵⁶⁷⁸⁹'.charAt(degree - 2);
        } else if (degree < -1 && degree > -10) {
            return name + '⁻' + '²³⁴⁵⁶⁷⁸⁹'.charAt(-degree - 2);
        } else {
            return name + "^" + degree;
        }
    }
    toTeX() {
        let degree = this.degree, name = this.name;
        if (degree === 0) {
            return "";
        } else if (degree === 1) {
            return name;
        } else {
            return name + "^{" + degree + "}";
        }
    }
}
class Term {
    constructor(variable) {
        if (variable instanceof Variable) {
            this.variables = [variable.copy()];
        } else if (typeof(variable) === "undefined") {
            this.variables = [];
        } else {
            throw new TypeError(
                "Invalid Argument ("
                + variable.toString() +
                "): Term initializer must be of type Variable."
            );
        }
        this.coefficients = [new Fraction(1, 1)];
    }
    get coefficient() {
        return this.coefficients
            .reduce((p,c) => p.multiply(c), new Fraction(1,1));
    }
    simplify() {
        let copy = this.copy();
        copy.coefficients = [this.coefficient];
        copy.combineVars();
        return copy.sort();
    }
    combineVars() {
        let uniqueVars = {};
        for (let v of this.variables) {
            if (v.variable in uniqueVars) {
                uniqueVars[v.variable] += v.degree;
            } else {
                uniqueVars[v.variable] = v.degree;
            }
        }

        let newVars = [];
        for (let v in uniqueVars) {
            let newVar = new Variable(v);
            newVar.degree = uniqueVars[v];
            newVars.push(newVar);
        }
        this.variables = newVars;
        return this;
    }
    copy() {
        let copy = new Term();
        copy.coefficients = this.coefficients.map(c => c.copy());
        copy.variables    = this.variables.map(   v => v.copy());
        return copy;
    }
    add(term) {
        if(term instanceof Term && this.canBeCombinedWith(term)) {
            var copy = this.copy();
            copy.coefficients = [copy.coefficient.add(term.coefficient)];
            return copy;
        } else {
            throw new TypeError(
                "Invalid Argument (" + term.toString() +
                "): Summand must be of type String, Expression, Term, Fraction or Integer."
            );
        }
    }
    subtract(term) {
        if (term instanceof Term && this.canBeCombinedWith(term)) {
            var copy = this.copy();
            copy.coefficients = [copy.coefficient.subtract(term.coefficient)];
            return copy;
        } else {
            throw new TypeError(
                "Invalid Argument (" + term.toString() +
                "): Subtrahend must be of type String, Expression, Term, Fraction or Integer."
            );
        }
    }
    multiply(a, simplify = true) {
        let $term = this.copy();

        if (isInt(a)) {
            return this.multiply(new Fraction(a, 1), simplify);
        } else if (a instanceof Term) {
            $term.variables = $term.variables.concat(a.variables);
            $term.coefficients = a.coefficients.concat($term.coefficients);
        } else if (a instanceof Fraction) {
            if ($term.variables.length === 0) {
                $term.coefficients.push(a);
            } else {
                $term.coefficients.unshift(a);
            }
        } else {
            throw new TypeError(
                "Invalid Argument (" + a.toString() +
                "): Multiplicand must be of type String, Expression, Term, Fraction or Integer."
            );
        }
        return simplify ? $term.simplify() : $term;
    }
    divide(a, simplify = true) {
        // THIS IS DUBIOUS :
        // dividing each coefficients??
        if(isInt(a) || a instanceof Fraction) {
            var $term = this.copy();
            $term.coefficients = $term.coefficients.map(
                c => c.divide(a, simplify)
            );
            return $term;
        } else {
            throw new TypeError(
                "Invalid Argument (" + a.toString() +
                "): Argument must be of type Fraction or Integer."
            );
        }
    }
    eval(values, simplify = true) {
        let copy = this.copy();
        let keys = Object.keys(values);
        let exp = copy.coefficients.reduce(
            (p,c) => p.multiply(c,simplify),
            new Expression(1)
        );

        for(let v of copy.variables) {
            let ev;

            if (v.variable in values) {
                let sub = values[v.variable];

                if(sub instanceof Fraction || sub instanceof Expression) {
                    ev = sub.pow(v.degree);
                } else if(isInt(sub)) {
                    ev = Math.pow(sub, v.degree);
                } else {
                    throw new TypeError("Invalid Argument (" + sub + "): Can only evaluate Expressions or Fractions.");
                }
            } else {
                ev = new Expression(v.variable).pow(v.degree);
            }

            exp = exp.multiply(ev, simplify);
        }

        return exp;
    }
    hasVariable(name) {
        return this.variables.map(v => v.name).includes(name);
    }
    maxDegree() {
        return Math.max(...this.variables.map(v => v.degree));
    }
    maxDegreeOfVariable(name) {
        return this.variables.reduce(
            (p,c) => c.name === name ? Math.max(p,c.degree) : p,
            1 // NOTE: shouldn't it be zero here?
        );
    }
    canBeCombinedWith(term) {
        let thisVars = this.variables,
            thatVars = term.variables;

        if(thisVars.length != thatVars.length) {
            return false;
        }

        let matches = 0;
        for(thisVar of thisVars) {
            for(thatVar of thatVars) {
                if(thisVar.name === thatVar.name && thisVar.degree === thatVar.degree) {
                    matches++;
                }
            }
        }

        return (matches === thisVars.length);
    }
    onlyHasVariable(name) {
        for (variable of this.variables) {
            if (variable.name != name) {
                return false;
            }
        }
        return true;
    }
    sort() {
        this.variables = this.variables.sort(
            (a,b) => b.degree - a.degree
        );
        return this;
    }
    toString(options) {
        let implicit = options && options.implicit,
            str = this.variables
            .reduce(
                (p, c) => {
                    if (implicit && !!p) {
                        var vStr = c.toString();
                        return !!vStr ? p + "*" + vStr : p;
                    } else
                        return p.concat(c.toString());
                },
                this.coefficients
                .filter(
                    c => coef.abs().numer !== 1 || coef.abs().denom !== 1
                )
                .join(' * ')
            );
        str = (str.substring(0, 1) === "-" ? str.substring(1, str.length) : str);

        return str;
    }
    toTeX(dict = {}) {
        dict.multiplication = !("multiplication" in dict) ? "cdot" : dict.multiplication;

        let str = this.variables
            .reduce(
                (p,c) => p.concat(c.toTeX()),
                this.coefficients
                .filter(
                    c => c.abs().numer !== 1 || c.abs().denom !== 1
                )
                .join("\\" + dict.multiplication + " ")
            );

        str = (str.substring(0, 1) === "-" ? str.substring(1, str.length) : str);
        str = (str.substring(0, 7) === "\\frac{-" ? "\\frac{" + str.substring(7, str.length) : str);

        return str;
    }
}
class Fraction {
    constructor(numerator, denominator) {
        if (denominator === 0) {
            throw new EvalError("Divide By Zero");
        } else if (isInt(numerator) && isInt(denominator)) {
            this.numer = numerator;
            this.denom = denominator;
        } else {
            throw new TypeError(
                "Invalid Argument ("+
                numerator.toString()+
                ","+ denominator.toString() +
                "): Divisor and dividend must be of type Integer."
            );
        }
    }

    copy() { return new Fraction(this.numer, this.denom); }
    get nude() { return [this.numer, this.denom]; }
    reduce() {
        let
        $gcd  = gcd(this.numer, this.denom),
            numer = this.numer / $gcd,
            denom = this.denom / $gcd;
        if (Math.sign(denom) == -1 && Math.sign(numer) == 1) {
            numer *= -1;
            denom *= -1;
        }
        return new Fraction(numer, denom);
    }
    equalTo(that) {
        if(that instanceof Fraction) {
            let $this = this.reduce(), $that = that.reduce();
            return $this.numer === $that.numer && $this.denom === $that.denom;
        } else { return false; }
    }
    add(f, simplify = true) {
        let a, b;

        if (f instanceof Fraction) {
            a = f.numer, b = f.denom;
        } else if (isInt(f)) {
            a = f, b = 1;
        } else {
            throw new TypeError(
                "Invalid Argument (" + f.toString() +
                "): Summand must be of type Fraction or Integer."
            );
        }

        let copy = this.copy();
        if (this.denom == b) {
            copy.numer += a;
        } else {
            let m = lcm(copy.denom, b),
                thisM = m / copy.denom,
                otherM = m / b;

            copy.numer *= thisM;
            copy.denom *= thisM;

            a *= otherM;

            copy.numer += a;
        }

        return simplify ? copy.reduce() : copy;
    }
    subtract(f, simplify = true) {
        let $f = f.reduce();
        $f.numer *= -1;
        return this.add($f, simplify);
    }
    multiply(f, simplify = true) {

        let a, b;
        if (f instanceof Fraction) { a = f.numer, b = f.denom; }
        else if (isInt(f) && f)    { a = f, b = 1; }
        else if (f === 0)          { a = 0, b = 1; }
        else {
            throw new TypeError(
                "Invalid Argument (" +
                f.toString() +
                "): Multiplicand must be of type Fraction or Integer."
            );
        }

        let copy = this.copy();

        copy.numer *= a;
        copy.denom *= b;

        return simplify ? copy.reduce() : copy;
    }
    divide(f, simplify = true) {

        if (f.valueOf() === 0) {
            throw new EvalError("Divide By Zero");
        }

        let copy = this.copy();

        if (f instanceof Fraction) {
            return copy.multiply(new Fraction(f.denom, f.numer), simplify);
        } else if (isInt(f)) {
            return copy.multiply(new Fraction(1, f), simplify);
        } else {
            throw new TypeError(
                "Invalid Argument (" + f.toString() +
                "): Divisor must be of type Fraction or Integer."
            );
        }
    }
    pow(n, simplify = true) {

        if (n >= 0) {
            let numer = Math.pow(this.numer, n),
                denom = Math.pow(this.denom, n),
                $pow  = new Fraction(numer, denom);
            return simplify ? $pow.reduce() : $pow;
        } else if (n < 0) {
            let $pow = this.pow(Math.abs(n), simplify);

            //Switch numerator and denominator (swap signs if necessary)
            [ $pow.numer, $pow.denom ] = [
                Math.sign($pow.numer) * $pow.denom,
                Math.abs($pow.numer)
            ];
            return $pow;
        }
    }
    abs() { return new Fraction(...this.nude.map(Math.abs)); }
    valueOf() { return this.numer/this.denom; }
    toString() {
        return this.numer === 0 ? '0' :
            this.denom === 1 ? this.numer.toString() :
            this.denom === -1 ? (-this.numer).toString() :
            this.numer + '/' + this.denom;
    }
    toTeX() {
        return this.numer === 0 ? '0' :
            this.denom === 1 ? this.numer.toString() :
            this.denom === -1 ? (-this.numer).toString() :
        `\\frac\{${this.numer}\}\{${this.denom}\}`
    }
    _squareRootIsRational() {
        if (this.valueOf() === 0) { return true; }
        return this.nude
            .map(x => isInt(Math.sqrt(x)))
            .reduce((a,b) => a && b);
    }
    _cubeRootIsRational() {
        if (this.valueOf() === 0) { return true; }
        return this.nude
            .map(x => isInt(Math.cbrt(x)))
            .reduce((a,b) => a && b);
    }

}

var parser = new Parser();
parser.input = "3.14*(foo + x∧y)";
// for (let token of parser.tokens) { console.log(token); }
parser.update();
console.log(parser.parseNumber());

