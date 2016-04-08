unit module Clifford;
no precompilation; # see bug #127858
our class MultiVector {...}

our constant @e is export = map { MultiVector.new: blades => (my Real %{UInt} = (1 +< (2*$_)) => 1); }, ^Inf;
our constant @ē is export = map { MultiVector.new: blades => (my Real %{UInt} = (1 +< (2*$_+1)) => 1); }, ^Inf;

class MultiVector does Numeric {
    has Real %.blades{UInt};
    method Real {
	if any(self.blades.keys) > 0 {
	    fail X::Numeric::Real.new:
	    target => Real,
	    source => self,
	    reason => 'not purely scalar'
	    ;
	}
	return self.blades{0} // 0;
    }

    method reals { self.blades».value }
    method narrow returns Numeric {
	for self.blades {
	    return self if .key > 0 && .value !== 0;
	}
	return (self.blades.hash{0} // 0).narrow;
    }
    multi method gist {
	my sub blade-gist($blade) {
	    join(
		'*',
		$blade.value,
		gather {
		    my $key = $blade.key;
		    my $i = 0;
		    while $key > 0 {
			take "e$i" if $key +& 1;
			take "ē$i" if $key +& 2;
			$key +>= 2;
			$i++;
		    }
		}
	    ).subst(/<|w>1\*/, '')
	}
	if    self.blades == 0 { return '0' }
	elsif self.blades == 1 {
	    given self.blades.pick {
		if .key == 0 {
		    return .value.gist;
		} else {
		    return blade-gist($_);
		}
	    }
	} else {
	    return 
	    join(
		' + ', do for sort *.key, self.blades {
		    .key == 0 ?? .value.gist !! blade-gist($_);
		}
	    ).subst('+ -','- ', :g);
	}
    }
    method AT-POS(UInt $n) { self.new: :blades(grep { $n == [+] .key.polymod(2 xx *) }, self.blades) }
    method max-grade { %!blades.map({[+] .key.polymod(2 xx *)}).max }
}

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
	    $r *= $k %% 2 ?? +1 !! -1;
	}
	$t +>= 1;
	$k++;
    }
    return $r;
}

# ADDITION
multi infix:<+>(MultiVector $A, MultiVector $B) returns MultiVector is export {
    my Real %blades{UInt} = $A.blades;
    for $B.blades {
	%blades{.key} :delete unless %blades{.key} += .value;
    }
    return MultiVector.new: :%blades;
}
multi infix:<+>(Real $s, MultiVector $A) returns MultiVector is export {
    my Real %blades{UInt} = $A.blades;
    %blades{0} :delete unless %blades{0} += $s;
    return MultiVector.new: :%blades;
}
multi infix:<+>(MultiVector $A, Real $s) returns MultiVector is export { $s + $A }

# GEOMETRIC PRODUCT
multi infix:<*>(MultiVector $A, MultiVector $B) returns MultiVector is export {
    my Real %blades{UInt};
    for $A.blades -> $a {
	for $B.blades -> $b {
	    my $c = $a.key +^ $b.key;
	    %blades{$c} :delete unless
	    %blades{$c} += $a.value * $b.value * metric-product($a.key, $b.key);
	}
    }
    return MultiVector.new: :%blades;
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
multi infix:<*>(Real $s, MultiVector $A) returns MultiVector is export {
    return MultiVector.new: :blades(my Real %{UInt} = map { .key => $s * .value }, $A.blades);
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

