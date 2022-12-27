unit module Clifford;
use MultiVector;

class MV is MultiVector {}  # just an alias
our @e is export = map { MV.new("e$_") }, ^Inf;
our @i is export = map { MV.new("i$_") }, ^Inf;
our @o is export = map { MV.new("o$_") }, ^Inf;

subset Sca of MV is export where *.narrow ~~ Real;
subset Vec of MV is export where *.grades.all == 1;
subset Biv of MV is export where *.grades.all == 2;
subset Tri of MV is export where *.grades.all == 3;

# ADDITION
multi infix:<+>(MV $A, Real $x) returns MV is export { $A.add($x) }
multi infix:<+>(Real $x, MV $B) returns MV is export { $B.add($x) }
multi infix:<+>(MV $A, MV $B) returns MV is export { $A.add($B) }

# MULTIPLICATION
multi infix:<*>(Real $s, MV $A) returns MV is export { $A.scale($s) }
multi infix:<*>(MV $A, Real $s) returns MV is export { $A.scale($s) }
multi infix:<*>(MV $A, MV $B) returns MV is export { $A.geometric-product($B) }
multi infix:</>(MV $A, Real $s) returns MV is export { $A.scale(1/$s) }
multi infix:</>($x, Vec $A) returns MV is export { $x*$A/($A*$A).Real }

# SUBSTRACTION
multi prefix:<->(MV $A) returns MV is export { return -1 * $A }
multi infix:<->(MV $A, MV $B) returns MV is export { $A + -$B }
multi infix:<->(MV $A, Real $s) returns MV is export { $A + -$s }
multi infix:<->(Real $s, MV $A) returns MV is export { $s + -$A }

# EXPONENTIATION
multi infix:<**>(MV $A where $A !== 0, 0) returns MV is export { return $A.new: 1 }
multi infix:<**>(MV $A, 1) returns MV is export { return $A.clone }
multi infix:<**>(MV $A, 2) returns MV is export { return $A * $A }
multi infix:<**>(MV $A, UInt $n where $n %% 2) returns MV is export {
    return ($A ** ($n div 2)) ** 2;
}
multi infix:<**>(MV $A, UInt $n) returns MV is export {
    return $A * ($A ** ($n div 2)) ** 2;
}

# COMPARISON
multi infix:<==>(MV $A, MV $B) returns Bool is export { $A - $B == 0 }
multi infix:<==>(Real $x, MV $A) returns Bool is export { $A == $x }
multi infix:<==>(MV $A, Real $x) returns Bool is export {
    my $narrowed = $A.narrow;
    $narrowed ~~ Real and $narrowed == $x;
}
