unit module Clifford;
use MultiVector;

role Vector does MultiVector does Positional is export {
    method blades { grep *.value, ((1, 2, 4 ... *) Z=> self[]) }
    method AT-KEY(UInt $n) { $n == 1 ?? self !! 0 }
    method norm { sqrt [+] self »**» 2 }
}

class MVector does MultiVector {
    has Real %.blades{UInt};
    method AT-KEY(UInt $n) { self.new: :blades(grep { $n == [+] .key.polymod(2 xx *) }, self.blades) }
}

sub e(UInt:D $n) returns Vector is export { my Real @ does Vector = flat 0 xx $n, 1 }

# Metric signature
our @signature = 1 xx *;

# utilities
my sub order(UInt:D $i is copy, UInt:D $j) {
    my $n = 0;
    repeat {
	$i +>= 1;
	$n += [+] ($i +& $j).polymod(2 xx *);
    } until $i == 0;
    return $n +& 1 ?? -1 !! 1;
}
my sub metric-product(UInt $i, UInt $j) {
    my $r = order($i, $j);
    my $t = $i +& $j;
    my $k = 0;
    while $t !== 0 {
	if $t +& 1 {
	    $r *= @Clifford::signature[$k];
	}
	$t +>= 1;
	$k++;
    }
    return $r;
}

# ADDITION
multi infix:<+>(Vector $a, Vector $b) returns Vector is export {
    return my Real @ does Vector = (($a[$_]//0) + ($b[$_]//0) for ^max($a.elems, $b.elems));
}
multi infix:<+>(MultiVector $A, MultiVector $B) returns MultiVector is export {
    my Real %blades{UInt} = $A.blades;
    for $B.blades {
	%blades{.key} += .value;
	%blades{.key} :delete unless %blades{.key};
    }
    return MVector.new: :%blades;
}
multi infix:<+>(Real $s, MultiVector $A) returns MultiVector is export {
    my Real %blades{UInt} = $A.blades;
    %blades{0} += $s;
    %blades{0} :delete unless %blades{0};
    return MVector.new: :%blades;
}
multi infix:<+>(MultiVector $A, Real $s) returns MultiVector is export { $s + $A }

# GEOMETRIC PRODUCT
multi infix:<*>(MultiVector $A, MultiVector $B) returns MultiVector is export {
    my Real %blades{UInt};
    for $A.blades -> $a {
	for $B.blades -> $b {
	    my $c = $a.key +^ $b.key;
	    %blades{$c} += $a.value * $b.value * metric-product($a.key, $b.key);
	    %blades{$c} :delete unless %blades{$c};
	}
    }
    return MVector.new: :%blades;
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

# SCALAR MULTIPLICATION
multi infix:<*>(MultiVector $,  0) is export { MultiVector.new }
multi infix:<*>(MultiVector $A, 1) is export { $A }
multi infix:<*>(MultiVector $A, Real $s) returns MultiVector is export { $s * $A }
multi infix:<*>(Real $s, Vector $V) returns Vector is export { return my Real @ does Vector = $s X* $V }
multi infix:<*>(Real $s, MultiVector $A) returns MultiVector is export {
    return MVector.new: :blades(my Real %{UInt} = map { .key => $s * .value }, $A.blades);
}
multi infix:</>(MultiVector $A, Real $s) is export { (1/$s) * $A }

# SUBSTRACTION
multi prefix:<->(MultiVector $A) returns MultiVector is export { return -1 * $A }
multi infix:<->(MultiVector $A, MultiVector $B) returns MultiVector is export { $A + -$B }
multi infix:<->(MultiVector $A, Real $s) returns MultiVector is export { $A + -$s }
multi infix:<->(Real $s, MultiVector $A) returns MultiVector is export { $s + -$A }

# COMPARISON
multi infix:<==>(MultiVector $A, MultiVector $B) returns Bool is export { $A - $B == 0 }
multi infix:<==>(Real $x, MultiVector $A) returns Bool is export { $A == $x }
multi infix:<==>(MultiVector $A, Real $x) returns Bool is export {
    my $narrowed = $A.narrow;
    $narrowed ~~ Real and $narrowed == $x;
}

# GRADE PROJECTION

