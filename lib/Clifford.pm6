unit module Clifford;
no precompilation; # see bug #127858
use MultiVector;
use MultiVector::BitEncoded;

our constant @e is export = map { MultiVector::BitEncoded.new("e$_") }, ^Inf;
our constant @ē is export = map { MultiVector::BitEncoded.new("ē$_") }, ^Inf;

our constant no is export = MultiVector::BitEncoded.new('no');
our constant ni is export = MultiVector::BitEncoded.new('ni');

# ADDITION
multi infix:<+>(MultiVector $A, Real $x) returns MultiVector is export { $A.add($x) }
multi infix:<+>(Real $x, MultiVector $B) returns MultiVector is export { $B.add($x) }
multi infix:<+>(MultiVector $A, MultiVector $B) returns MultiVector is export { $A.add($B) }

# MULTIPLICATION
multi infix:<*>(Real $s, MultiVector $A) returns MultiVector is export { $A.scale($s) }
multi infix:<*>(MultiVector $A, Real $s) returns MultiVector is export { $A.scale($s) }
multi infix:<*>(MultiVector $A, MultiVector $B) returns MultiVector is export { $A.gp($B) }
multi infix:</>(MultiVector $A, Real $s) returns MultiVector is export { $A.scale(1/$s) }

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
multi infix:<∧>(MultiVector $A, MultiVector $B) returns MultiVector is export { $A.op($B) }
