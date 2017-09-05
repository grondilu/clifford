'use strict';

let Fraction = require('./fractions'),
    $helper = require('./helper'),
    isInt = $helper.isInt
;


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

            for (let thisTerm of thisExp.terms) {
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
                `Invalid Argument (${name.toString()}):`+
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
            if (v.name in uniqueVars) {
                uniqueVars[v.name] += v.degree;
            } else {
                uniqueVars[v.name] = v.degree;
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

        if (a instanceof Term) {
            $term.variables = $term.variables.concat(a.variables);
            $term.coefficients = a.coefficients.concat($term.coefficients);
        } else if (isInt(a) || a instanceof Fraction) {
            let $coeff = isInt(a) ? new Fraction(a, 1) : a;
            if ($term.variables.length === 0) {
                $term.coefficients.push($coeff);
            } else {
                $term.coefficients.unshift($coeff);
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

            if (v.name in values) {
                let sub = values[v.name];

                if(sub instanceof Fraction || sub instanceof Expression) {
                    ev = sub.pow(v.degree);
                } else if(isInt(sub)) {
                    ev = Math.pow(sub, v.degree);
                } else {
                    throw new TypeError("Invalid Argument (" + sub + "): Can only evaluate Expressions or Fractions.");
                }
            } else {
                ev = new Expression(v.name).pow(v.degree);
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
        for(let thisVar of thisVars) {
            for(let thatVar of thatVars) {
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
                    c => c.abs().numer !== 1 || c.abs().denom !== 1
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

module.exports = {
    Expression, Variable, Term
}
