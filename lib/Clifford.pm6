unit module Clifford;
no precompilation; # see bug #127858
use MultiVector;

our constant @e is export = map { MultiVector.new("e$_") }, ^Inf;
our constant @ē is export = map { MultiVector.new("ē$_") }, ^Inf;

our constant no is export = MultiVector.new('no');
our constant ni is export = MultiVector.new('ni');

# ADDITION
multi infix:<+>(MultiVector $A, Real $x) returns MultiVector is export { MultiVector::addition($A, $x) }
multi infix:<+>(Real $x, MultiVector $B) returns MultiVector is export { MultiVector::addition($x, $B) }
multi infix:<+>(MultiVector $A, MultiVector $B) returns MultiVector is export { MultiVector::addition($A, $B) }

# MULTIPLICATION
multi infix:<*>(Real $x, MultiVector $A) returns MultiVector is export { MultiVector::product($x, $A) }
multi infix:<*>(MultiVector $A, Real $x) returns MultiVector is export { MultiVector::product($A, $x) }
multi infix:<*>(MultiVector $A, MultiVector $B) returns MultiVector is export { &MultiVector::geometric-product($A, $B) }
multi infix:</>(MultiVector $A, Real $s) returns MultiVector is export { (1/$s) * $A }

# SUBSTRACTION
multi prefix:<->(MultiVector $A) returns MultiVector is export { return -1 * $A }
multi infix:<->(MultiVector $A, MultiVector $B) returns MultiVector is export { $A + -$B }
multi infix:<->(MultiVector $A, Real $s) returns MultiVector is export { $A + -$s }
multi infix:<->(Real $s, MultiVector $A) returns MultiVector is export { $s + -$A }

# EXPONENTIATION
multi infix:<**>(MultiVector $ , 0) is export { return 1 }
multi infix:<**>(MultiVector $A, 1) returns MultiVector is export { return $A }
multi infix:<**>(MultiVector $A, 2) returns MultiVector is export { return $A * $A }
multi infix:<**>(MultiVector $A, UInt $n where $n %% 2) returns MultiVector is export {
    return ($A ** ($n div 2)) ** 2;
}
multi infix:<**>(MultiVector $A, UInt $n) returns MultiVector is export {
    return $A * ($A ** ($n div 2)) ** 2;
}

# COMPARISON
multi infix:<==>(MultiVector $A, MultiVector $B) returns Bool is export { $A - $B == 0 }
multi infix:<==>(Real $x, MultiVector $A) returns Bool is export { $A == $x }
multi infix:<==>(MultiVector $A, Real $x) returns Bool is export {
    my $narrowed = $A.narrow;
    $narrowed ~~ Real and $narrowed == $x;
}

# OUTER PRODUCT
multi infix:<∧>(MultiVector $A, MultiVector $B) returns MultiVector is export { &MultiVector::outer-product($A, $B) }
