unit module Clifford;
use MultiVector;

our @e is export = map { MultiVector.new("e$_") }, ^Inf;
our @i is export = map { MultiVector.new("i$_") }, ^Inf;
our @o is export = map { MultiVector.new("o$_") }, ^Inf;

subset Vector of MultiVector where *.grades.all == 1;

# ADDITION
multi infix:<+>(MultiVector $A, Real $x) is export { $A.add($x) }
multi infix:<+>(Real $x, MultiVector $B) is export { $B.add($x) }
multi infix:<+>(MultiVector $A, MultiVector $B)   is export { $A.add($B) }

# MULTIPLICATION
multi infix:<*>(Real $s, MultiVector $A) is export { $A.scale($s) }
multi infix:<*>(MultiVector $A, Real $s) is export { $A.scale($s) }
multi infix:<*>(MultiVector $A, MultiVector $B)   is export { $A.geometric-product($B) }
multi infix:</>(MultiVector $A, Real $s) is export { $A.scale(1/$s) }

# SUBSTRACTION
multi prefix:<->(MultiVector $A) is export { return -1 * $A }
multi infix:<->(MultiVector $A, MultiVector $B) is export { $A + -$B }
multi infix:<->(MultiVector $A, Real $s) is export { $A + -$s }
multi infix:<->(Real $s, MultiVector $A) is export { $s + -$A }

# EXPONENTIATION
multi infix:<**>(MultiVector $A where $A !== 0, 0) returns MultiVector is export { return $A.new: 1 }
multi infix:<**>(MultiVector $A, 1) is export { return $A.clone }
multi infix:<**>(MultiVector $A, 2) is export { return $A * $A }
multi infix:<**>(     Vector $v, 2) is export { callsame().narrow }
multi infix:<**>(MultiVector $A, UInt $n where $n %% 2) is export {
    return ($A ** ($n div 2)) ** 2;
}
multi infix:<**>(MultiVector $A, UInt $n) is export {
    return $A * ($A ** ($n div 2)) ** 2;
}

# COMPARISON
multi infix:<==>(MultiVector $A, MultiVector $B) returns Bool is export { $A - $B == 0 }
multi infix:<==>(Real $x, MultiVector $A) returns Bool is export { $A == $x }
multi infix:<==>(MultiVector $A, Real $x) returns Bool is export {
    my $narrowed = $A.narrow;
    $narrowed ~~ Real and $narrowed == $x;
}


multi infix:<∧>(MultiVector $A, MultiVector $B) is export { $A.outer-product($B) }
multi infix:<·>(Vector $u, Vector $v) returns Real is export { (($u*$v+$v*$u)/2).narrow }
multi infix:</>($A, MultiVector $B where *.mix.elems == 1) is export { $A*$B/($B**2).narrow }
