unit module Clifford;

# Metric signature
our @signature = 1 xx *;

our class MultiVector {...}

sub e(UInt $n?) returns MultiVector is export {
    $n.defined ?? MultiVector.new(:blades(my Real %{UInt} = (1 +< $n) => 1)) !! MultiVector.new
}

my sub grade(UInt $n) { [+] $n.base(2).comb }
my sub order(UInt:D $i is copy, UInt:D $j) {
    my $n = 0;
    repeat {
	$i +>= 1;
	$n += [+] ($i +& $j).base(2).comb;
    } until $i == 0;
    return $n +& 1 ?? -1 !! 1;
}

sub metric-product(UInt $i, UInt $j) {
    my $r = order($i, $j);
    my $t = $i +& $j;
    my $k = 0;
    while $t !== 0 {
	if $t +& 1 {
	    $r *= @signature[$k];
	}
	$t +>= 1;
	$k++;
    }
    return $r;
}

class MultiVector {
    has Real %.blades{UInt};
    method clean {
	for %!blades {
	    %!blades{.key} :delete unless .value;
	}
    }
    method reals { %!blades.values }
    method max-grade { self.clean(); max map &grade, %!blades.keys }
    method AT-POS($n) {
	MultiVector.new: :blades(my Real %{UInt} = %!blades.grep: *.key.&grade == $n)
    }	
    method narrow {
	self.clean();
	if !%!blades { return 0 }
	elsif self.max-grade == 0 { return %!blades{0} }
	else { return self }
    }
    method round($r) {
	MultiVector.new: :blades(my Real %{UInt} = %!blades.map: { .key => .value.round($r) })
    }
}

multi infix:<+>(MultiVector $A, MultiVector $B) returns MultiVector is export {
    my Real %blades{UInt} = $A.blades.clone;
    for $B.blades {
	%blades{.key} += .value;
	%blades{.key} :delete unless %blades{.key};
    }
    return MultiVector.new: :%blades;
}
multi infix:<+>(Real $s, MultiVector $A) returns MultiVector is export {
    return MultiVector.new(:blades(my Real %{UInt} = 0 => $s)) + $A;
}
multi infix:<+>(MultiVector $A, Real $s) returns MultiVector is export { $s + $A }
multi infix:<*>(MultiVector $A, MultiVector $B) returns MultiVector is export {
    my Real %blades{UInt};
    for $A.blades -> $a {
	for $B.blades -> $b {
	    my $c = $a.key +^ $b.key;
	    %blades{$c} += $a.value * $b.value * metric-product($a.key, $b.key);
	    %blades{$c} :delete unless %blades{$c};
	}
    }
    return MultiVector.new: :%blades;
}
multi infix:<**>(MultiVector $ , 0) returns MultiVector is export { return MultiVector.new }
multi infix:<**>(MultiVector $A, 1) returns MultiVector is export { return $A }
multi infix:<**>(MultiVector $A, 2) returns MultiVector is export { return $A * $A }
multi infix:<**>(MultiVector $A, UInt $n where $n %% 2) returns MultiVector is export {
    return ($A ** ($n div 2)) ** 2;
}
multi infix:<**>(MultiVector $A, UInt $n) returns MultiVector is export {
    return $A * ($A ** ($n div 2)) ** 2;
}

multi infix:<*>(MultiVector $A, Real $s) returns MultiVector is export {
    return MultiVector.new: :blades(my Real %{UInt} = map { .key => $s * .value }, $A.blades);
}
multi infix:<*>(Real $s, MultiVector $A) returns MultiVector is export { $A * $s }
multi infix:</>(MultiVector $A, Real $s) returns MultiVector is export { $A * (1/$s) }
multi prefix:<->(MultiVector $A) returns MultiVector is export { return -1 * $A }
multi infix:<->(MultiVector $A, MultiVector $B) returns MultiVector is export { $A + -$B }
multi infix:<->(MultiVector $A, Real $s) returns MultiVector is export { $A + -$s }
multi infix:<->(Real $s, MultiVector $A) returns MultiVector is export { $s + -$A }

multi infix:<==>(MultiVector $A, MultiVector $B) returns Bool is export { $A - $B == 0 }
multi infix:<==>(MultiVector $A, Real $x) returns Bool is export {
    my $narrowed = $A.narrow;
    $narrowed ~~ Real and $narrowed == $x;
}
