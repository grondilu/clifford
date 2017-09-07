function gcd(a, b) { return b === 0 ? a : gcd(b, a % b); }
function lcm(a, b) { return (a*b) / gcd(a, b); }

let SymbolTable = {};
const _floatingPointValue = Symbol("floating point value");

class MultiVector {
    constructor(name) {
        if (name === undefined) {
            this.symbol = Symbol();
        } else if (typeof(name) === 'string') {
            this.symbol = Symbol.for(name);
        } else if (typeof(name) === 'symbol') {
            this.symbol = name;
        } else { throw new TypeError(); }
    }
    get grade() { return new Grade(this); }
}
class Vector extends MultiVector {
    get grade() { return new Grade(this, 1); }
}
class Vector3D extends Vector {
    constructor(x, y, z, name) {
        super(name);
        this.x = x, this.y = y, this.z = z;
    }
}
class ConformalPoint extends Vector {
    constructor(vector3D, name) {
        if (vector3D instanceof Vector3D) {
            super(name);
            throw new Error('NYI');
            this.vector3D = vector3D;
        }
    }
    get norm() { return new Real(0); }
}
class Real extends MultiVector {
    constructor(x, name) {
        super(name);
        if (!(x === undefined)) this[_floatingPointValue] = x;
    }
    get grade() { return new Grade(this, 0); }
    valueOf() { return this[_floatingPointValue]; }
}
class Fraction extends Real {
    constructor(numerator, denominator = 1, name) {
        if (denominator === 0) {
            throw new EvalError('division by zero');
        }
        super(name);
        this.numerator = numerator;
        this.denominator = denominator;
    }
    get [_floatingPointValue]() { return this.numerator / this.denominator }
    get nude() { return [this.numerator, this.denominator]; }
    simplify() {
        let $gcd = gcd(...this.nude);
        if (this.denominator == $gcd) {
            return new Int(this.numerator / $gcd);
        } else {
            return new Fraction(...this.nude.map(x => x/$gcd));
        }
    }
}
class Int extends Fraction {
    constructor(n, name) { super(n, 1, name); }
}
class Grade extends Int {
    constructor(multivector, grade, name) {
        super(grade, name);
        this.multivector = multivector;
    }
}

class InnerProduct extends Real {
    constructor(a, b, name) {
        if (a instanceof Vector && b instanceof Vector) {
            super(name);
            this.left = a, this.right = b;
        } else {
            throw new TypeError();
        }
    }
}

class BinaryMorphism extends MultiVector {
    constructor(a, b, name) {
        if (a instanceof MultiVector && b instanceof MultiVector) {
            super(name);
            this.left = a, this.right = b;
        } else {
            throw new TypeError();
        }
    }
}
class Addition         extends BinaryMorphism {}
class Subtraction      extends BinaryMorphism {}
class OuterProduct     extends BinaryMorphism {}
class Product          extends BinaryMorphism {}
class Division         extends BinaryMorphism {}
class Exponential      extends BinaryMorphism {}

class Involution extends MultiVector {
    constructor(multivector, name) {
        if (multivector instanceof MultiVector) {
            super(name);
            this.multivector = multivector;
        } else { throw new TyperError(); }
    }
}
class Reversion extends Involution {}
class Dual      extends Involution {}

const grammar = `
{
    let $clifford = require('/usr/local/src/clifford/js/clifford');
}
start
    = statement / expression 

expression
    = additive

statement
    = left:identifier '=' right:additive {
        return $clifford.SymbolTable[left.symbol] = right;
    }

additive
    = left:multiplicative "+" right:additive {
        return new $clifford.Addition(left, right);
    } / left:multiplicative "-" right:additive {
        return new $clifford.Subtraction(left, right);
    } / multiplicative

multiplicative
    = left:divisive "*"? right:multiplicative {
        return new $clifford.Product(left, right);
    } /
    divisive

divisive
    = left: cdot "/" right:divisive {
        return new $clifford.Division(left, right);
    }
    / cdot

cdot
    = left:wedge "·" right:wedge {
        return new $clifford.InnerProduct(left, right);
    } / wedge

wedge
    = left:exponential '∧' right:wedge {
        return new $clifford.OuterProduct(left, right);
    } / exponential

exponential
    =  left:primary '**' right: primary {
        return new $clifford.Exponential(left, right);
    } / primary

primary
    = number
    / name:base_vector { return new $clifford.Vector(name); }
    / identifier
    / "(" additive:additive ")" { return additive; }

base_vector
    = e_n / 'no' / 'ni'

e_n
    = 'e' + digit:[0-9]* { return 'e' + digit; }

number "number"
    = minus? integer frac? {
        let number = Number(text());
        if (Math.round(number) == number) {
            return new $clifford.Int(number);
        } else {
            let factor = Math.pow(10,
                number.toString().split('.').length
            );
            return new $clifford.Fraction(parseInt(number * factor),factor);
        }
    }

decimal_point = "."

digit1_9 = [1-9]

frac = decimal_point DIGIT+

integer = zero / (digit1_9 DIGIT*)

minus = "-"

plus = "+"

zero = "0"

identifier
    = letters:[a-z]+ digits:[0-9]* {
        let name   = letters.concat(digits).join(''),
            value  = $clifford.SymbolTable[Symbol.for(name)];

        if (value === undefined) {
            return new $clifford.Real(undefined, name);
        } else {
            return value;
        }
    }

DIGIT = [0-9]
`;

module.exports = {
    parser: require('pegjs').generate(grammar),
    SymbolTable,
    MultiVector, Vector, Vector3D, ConformalPoint, Real, Fraction, Int, Grade,
    InnerProduct, Addition, Subtraction, OuterProduct,
    Product, Division, Exponential, Involution, Reversion, Dual
}

