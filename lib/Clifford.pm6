unit module Clifford;
no precompilation; # see bug #127858
use Clifford::Basis;
use Clifford::MultiVector;

my class MultiVector does Clifford::MultiVector { has MixHash $.blades }
my sub basis(UInt $basis) {
    MultiVector.new: blades => MixHash.new: $basis;
}

our constant @e is export = map { basis(1 +< (2*$_))   }, ^Inf;
our constant @ē is export = map { basis(1 +< (2*$_+1)) }, ^Inf;
our constant no  is export = MultiVector.new: blades => (1 => .5, 2 => 0.5).MixHash;
our constant ni  is export = MultiVector.new: blades => (1 => -1, 2 => 1).MixHash;

# ADDITION
multi infix:<+>(MultiVector $A, MultiVector $B) returns MultiVector is export {
    return MultiVector.new: blades => ($A.pairs, $B.pairs).MixHash;
}
multi infix:<+>(Real $s, MultiVector $A) returns MultiVector is export { $A + $s*basis(0) }
multi infix:<+>(MultiVector $A, Real $s) returns MultiVector is export { $s + $A }

# SCALAR MULTIPLICATION
multi infix:<*>(MultiVector $,  0) is export { 0 }
multi infix:<*>(MultiVector $A, 1) returns MultiVector is export { $A }
multi infix:<*>(MultiVector $A, Real $s) returns MultiVector is export { $s * $A }
multi infix:<*>(Real $s, MultiVector $A) returns MultiVector is export {
    return MultiVector.new: blades => (map { (.key) => $s * .value }, $A.pairs).MixHash;
}
multi infix:</>(MultiVector $A, Real $s) returns MultiVector is export { (1/$s) * $A }

# SUBSTRACTION
multi prefix:<->(MultiVector $A) returns MultiVector is export { return -1 * $A }
multi infix:<->(MultiVector $A, MultiVector $B) returns MultiVector is export { $A + -$B }
multi infix:<->(MultiVector $A, Real $s) returns MultiVector is export { $A + -$s }
multi infix:<->(Real $s, MultiVector $A) returns MultiVector is export { $s + -$A }

# GEOMETRIC PRODUCT
multi infix:<*>(MultiVector $A, MultiVector $B) returns MultiVector is export {
    MultiVector.new: blades => ($A.pairs X* $B.pairs).MixHash;
}

# EXPONENTIATION
multi infix:<**>(MultiVector $ , 0) returns MultiVector is export { return MultiVector.new }
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
