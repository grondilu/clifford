'use strict';

function gcd(x, y) { return y == 0 ? x : gcd(y, x % y); }
function lcm(x, y) { return (x * y) / gcd(x, y); }

let isInt = require('./helper').isInt;

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

module.exports = Fraction;
