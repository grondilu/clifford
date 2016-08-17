unit module Clifford;
use MultiVector;
use MultiVector::BitEncoded::Default;
use MultiVector::BitEncoded::Optimized;
subset Vector of MultiVector where .grades.all == 1;

class MV is MultiVector::BitEncoded::Optimized {}  # just an alias
our @e is export = map { MV.new("e$_") }, ^Inf;
our @ē is export = map { MV.new("ē$_") }, ^Inf;
our constant no is export = MV.new("no");
our constant ni is export = MV.new("ni");

# ADDITION
multi infix:<+>(MultiVector $A, Real $x) returns MultiVector is export { $A.add($x) }
multi infix:<+>(Real $x, MultiVector $B) returns MultiVector is export { $B.add($x) }
multi infix:<+>(MultiVector $A, MultiVector $B) returns MultiVector is export { $A.add($B) }

# MULTIPLICATION
multi infix:<*>(Real $s, MultiVector $A) returns MultiVector is export { $A.scale($s) }
multi infix:<*>(MultiVector $A, Real $s) returns MultiVector is export { $A.scale($s) }
multi infix:<*>(MultiVector $A, MultiVector $B) returns MultiVector is export { $A.gp($B) }
multi infix:</>(MultiVector $A, Real $s) returns MultiVector is export { $A.scale(1/$s) }
multi infix:</>($x, Vector $A) returns MultiVector is export { $x*$A/($A*$A).Real }

# SUBSTRACTION
multi prefix:<->(MultiVector $A) returns MultiVector is export { return -1 * $A }
multi infix:<->(MultiVector $A, MultiVector $B) returns MultiVector is export { $A + -$B }
multi infix:<->(MultiVector $A, Real $s) returns MultiVector is export { $A + -$s }
multi infix:<->(Real $s, MultiVector $A) returns MultiVector is export { $s + -$A }

# EXPONENTIATION
multi infix:<**>(MultiVector $A where $A !== 0, 0) returns MultiVector is export { return $A.new: 1 }
multi infix:<**>(MultiVector $A, 1) returns MultiVector is export { return $A.clone }
multi infix:<**>(MultiVector $A, 2) returns MultiVector is export { return $A * $A }
multi infix:<**>(MultiVector $A, UInt $n where $n %% 2) returns MultiVector is export {
    return ($A ** ($n div 2)) ** 2;
}
multi infix:<**>(MultiVector $A, UInt $n) returns MultiVector is export {
    return $A * ($A ** ($n div 2)) ** 2;
}
multi infix:<**>(Vector $V, 2) returns Real is export { ($V*$V).narrow }

# COMPARISON
multi infix:<==>(MultiVector $A, MultiVector $B) returns Bool is export { $A - $B == 0 }
multi infix:<==>(Real $x, MultiVector $A) returns Bool is export { $A == $x }
multi infix:<==>(MultiVector $A, Real $x) returns Bool is export {
    my $narrowed = $A.narrow;
    $narrowed ~~ Real and $narrowed == $x;
}

# INVOLUTIONS
sub postfix:<~>(MultiVector $A) returns MultiVector is export { $A.reversion }
sub postfix:<^>(MultiVector $A) returns MultiVector is export { $A.involution }

# DERIVED PRODUCTS
sub infix:<·>(MultiVector $A, MultiVector $B) returns MultiVector is tighter(&infix:<*>) is export { $A.ip($B) }
sub infix:<∧>(MultiVector $A, MultiVector $B) returns MultiVector is tighter(&infix:<*>) is export { $A.op($B) }
sub infix:<⌋>(MultiVector $A, MultiVector $B) returns MultiVector is tighter(&infix:<*>) is export { $A.lc($B) }
sub infix:<⌊>(MultiVector $A, MultiVector $B) returns MultiVector is tighter(&infix:<*>) is export { $A.rc($B) }
sub infix:<∗>(MultiVector $A, MultiVector $B) returns MultiVector is tighter(&infix:<*>) is export { $A.sp($B) }
sub infix:<×>(MultiVector $A, MultiVector $B) returns MultiVector is tighter(&infix:<*>) is export { 1/2*($A*$B - $B*$A) }
sub infix:<∙>(MultiVector $A, MultiVector $B) returns MultiVector is tighter(&infix:<*>) is export { $A.dp($B) }
