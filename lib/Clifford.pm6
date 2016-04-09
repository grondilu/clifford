unit module Clifford;
no precompilation; # see bug #127858
use Clifford::Blade;
our class MultiVector {...}

our constant @e is export = map { MultiVector.new: blades => MixHash.new: Clifford::Blade.new: :index(1 +< (2*$_));   }, ^Inf;
our constant @ē is export = map { MultiVector.new: blades => MixHash.new: Clifford::Blade.new: :index(1 +< (2*$_+1)); }, ^Inf;

class MultiVector does Numeric {
    has MixHash $.blades handles <pairs keys>;
    method Real {
	if any($!blades.keys».index) > 0 {
	    fail X::Numeric::Real.new:
	    target => Real,
	    source => self,
	    reason => 'not purely scalar'
	    ;
	}
	return $!blades{0} // 0;
    }

    method reals { $!blades.values }
    method narrow returns Numeric {
	return 0 if $!blades.pairs == 0;
	for $!blades.pairs {
	    return self if .key.index > 0;
	}
	return $!blades{0}.narrow;
    }
    multi method gist {
	if    $!blades == 0 { return '0' }
	elsif $!blades == 1 {
	    given $!blades.pairs.pick {
		warn "unexpected sign" if .key.sign < 0;
		if .key.index == 0 {
		    return .value.gist;
		} else {
		    return (.value.gist ~ "*" ~ .key.gist).subst(/<|w>1\*/,'');
		}
	    }
	} else {
	    return 
	    join(
		' + ', do for sort *.key.index, $!blades.pairs {
		    .key.index == 0 ?? .value.gist !! 
		    (.value.gist ~ "*" ~ .key.gist).subst(/<|w>1\*/,'');
		}
	    ).subst('+ -','- ', :g);
	}
    }
    method AT-POS(UInt $n) {
	::?CLASS.new:
	blades => (grep { .key.grade == $n }, $!blades.pairs).MixHash;
    }
    method max-grade { $!blades.keys».grade.max }
}

# ADDITION
multi infix:<+>(MultiVector $A, MultiVector $B) returns MultiVector is export {
    return MultiVector.new: blades => ($A.pairs, $B.pairs).MixHash;
}
multi infix:<+>(Real $s, MultiVector $A) returns MultiVector is export {
    return MultiVector.new: blades => (
	Clifford::Blade.new(:index(0)) => $s,
	$A.pairs
    ).MixHash;
}
multi infix:<+>(MultiVector $A, Real $s) returns MultiVector is export { $s + $A }

# SCALAR MULTIPLICATION
multi infix:<*>(MultiVector $,  0) is export { MultiVector.new: blades => MixHash.new }
multi infix:<*>(MultiVector $A, 1) is export { $A }
multi infix:<*>(MultiVector $A, Real $s) returns MultiVector is export { $s * $A }
multi infix:<*>(Real $s, MultiVector $A) returns MultiVector is export {
    return MultiVector.new: blades =>
	(map { Clifford::Blade.new(:index(.key.index)) => $s * .value }, $A.pairs).MixHash
    ;
}
multi infix:</>(MultiVector $A, Real $s) is export { (1/$s) * $A }

# SUBSTRACTION
multi prefix:<->(MultiVector $A) returns MultiVector is export { return -1 * $A }
multi infix:<->(MultiVector $A, MultiVector $B) returns MultiVector is export { $A + -$B }
multi infix:<->(MultiVector $A, Real $s) returns MultiVector is export { $A + -$s }
multi infix:<->(Real $s, MultiVector $A) returns MultiVector is export { $s + -$A }

# GEOMETRIC PRODUCT
multi infix:<*>(MultiVector $A, MultiVector $B) returns MultiVector is export {
    my MixHash $blades .= new;
    for $A.pairs -> $a {
	for $B.pairs -> $b {
	    my $c = $a.key * $b.key;
	    $blades{$c.abs} += $a.value * $b.value * $c.sign;
	}
    }
    return MultiVector.new: :$blades;
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
