module Clifford;
our @signature = 1 xx *;
subset UInt of Int where * >= 0;

#
# PRE-DECLARATIONS AND SUBSETS
#
# The user should never have to instantiate a MultiVector himself.
# Instantiation should always be done via &e and its algebraic combinations.
my class MultiVector is Cool does Numeric {...}
proto e(|) returns MultiVector is export {*}

multi e() { state $ = MultiVector.new: :canonical( 0 => 1 ) }
multi e(UInt $n) { (state @)[$n] //= MultiVector.new: :canonical( (1 +< $n) => 1 ) }

# Canonical is a subset for MultiVectors of the form e(i)*e(j)*e(k)*...
# where i < j < k < ...
# They form the elements of the so-called 'canonical basis', thus the name.
subset Canonical of MultiVector where *.clean-pairs == 1;

# Those canonical elements are identified by a positive integer
# so we need a few functions to quickly get information from them.
my sub grade(UInt $n --> UInt) { (state %){$n} //= $n.base(2).comb(/1/).elems }
my sub sb   (UInt $n) { @((state %){$n} //= $n.base(2).flip.match(/1/, :g)».from) }

# Vector is defined as a subset.
subset Vector of MultiVector where *.clean-pairs».key.map(&grade).all == 1;

# 
# MULTIVECTOR
#
class MultiVector {
    has Real %.canonical{UInt};
    multi method grade(Canonical:) { grade self.clean-pairs[0].key }
    method canonical-decomposition {
	map { MultiVector.new(:canonical($_)) }, self.clean-pairs 
    }
    multi method gist {
	join ' + ', map {
	    grade(.key) == 0 ?? ~.value !! (
		(
		    .value == 1 ?? '' !!
		    .value == -1 ?? '-' !!
		    "{.value}*"
		) ~
		join '*',
		map {"e$_"},
		sb .key
	    )
	},
	sort { grade .key },
	self.clean-pairs
    }
    multi method at_pos(UInt $grade) returns MultiVector {
	MultiVector.new: :canonical(
	    grep { grade(.key) == $grade },
	    self.clean-pairs
	)
    }
    method clean-pairs { grep *.value != 0, %!canonical.pairs }
    method reverse returns MultiVector {
	MultiVector.new: :canonical(
	    map {
		my $grade = grade .key;
		.key => (-1)**($grade * ($grade - 1) div 2) * .value
	    },
	    self.clean-pairs
	)
    }

    # 
    # Methods for the Numeric role
    #
    method reals(MultiVector:) { self.clean-pairs».value }
    method isNaN(MultiVector:) { [||] map *.isNaN, self.reals }
    method coerce-to-real(MultiVector: $exception-target) {
	unless self ~~ Canonical and self.grade == 0 {
	    fail X::Numeric::Real.new(target => $exception-target, reason => "non-scalar part not zero", source => self);
	}
	%!canonical{0};
    }
    multi method Real(MultiVector:) { self.coerce-to-real(Real) }
    method Num { self.coerce-to-real(Num).Num; }
    method Int { self.coerce-to-real(Int).Int; }
    method Rat { self.coerce-to-real(Rat).Rat; }
    multi method Bool { not self == 0 }
    method MultiVector { self }
    method floor    { MultiVector.new: :canonical( map { $^p.key => $p.value.floor}, self.clean-pairs ) }
    method ceiling  { MultiVector.new: :canonical( map { $^p.key => $p.value.ceiling}, self.clean-pairs ) }
    method truncate { MultiVector.new: :canonical( map { $^p.key => $p.value.truncate}, self.clean-pairs ) }
    multi method round($scale as Real = 1) {
	MultiVector.new: :canonical( map { $^p.key => $p.value.round($scale)}, self.clean-pairs );
    }
    method narrow {
	my Real %canonical{UInt} = self.clean-pairs;
	if %canonical.elems == 0 { return 0 }
	elsif %canonical.elems == 1 {
	    given %canonical.pairs.pick {
		return .value if .key == 0;
	    }
	}
	return MultiVector.new: :%canonical;
    }
}

#
# EQUALITY
#
multi infix:<==>(MultiVector $A, MultiVector $B) returns Bool is export { $A - $B == 0 }
multi infix:<==>($A, MultiVector $B) returns Bool is export { $A - $B == 0 }
multi infix:<==>(MultiVector $A, $B) returns Bool is export { $A - $B == 0 }
multi infix:<==>(MultiVector $A, 0) returns Bool is export {
    so all($A.canonical.values) == 0
}

#
# ORDER RELATION
#
multi infix:« < »(MultiVector $A, MultiVector $B) returns Bool is export {
    $A == $B ?? False !! $A.keys».&grade.max < $B.keys».&grade.max
}

#
# ADDITION AND SUBSTRACTION WITH A REAL
#
multi infix:<+>(Real $r, MultiVector $A) returns MultiVector is export { $r*e() + $A }
multi infix:<->(Real $r, MultiVector $A) returns MultiVector is export { $r*e() + -1*$A }
multi infix:<+>(MultiVector $A, Real $r) returns MultiVector is export { $A + $r*e() }
multi infix:<->(MultiVector $A, Real $r) returns MultiVector is export { $A + (-$r)*e() }

#
# ADDITION WITH A NULL MULTIVECTOR
#
multi infix:<+>( $A, MultiVector $B where $B == 0) is export { $A }
multi infix:<+>( MultiVector $A where $A == 0, $B) is export { $B }

#
# GENERIC ADDITION
#
multi infix:<+>(MultiVector $A, MultiVector $B) returns MultiVector is export {
    my Real %canonical{UInt} = $A.clean-pairs;
    for $B.clean-pairs {
	%canonical{.key} += .value;
	%canonical{.key} :delete if %canonical{.key} == 0;
    }
    MultiVector.new: :%canonical;
}

#
# SCALAR MULTIPLICATION
#
multi infix:<*>(Real $r, MultiVector $M) returns MultiVector is export {
    MultiVector.new: canonical =>
    map { $^p.key => $r * $p.value }, $M.clean-pairs;
}
multi infix:<*>(MultiVector $M, Real $r) returns MultiVector is export { $r * $M }

#
# GEOMETRIC PRODUCT
#
multi infix:<*>(MultiVector $A, MultiVector $B) returns MultiVector is export {
    [+] $A.canonical-decomposition X* $B.canonical-decomposition
}
multi infix:<*>(Canonical $A, Canonical $B) returns Canonical is export {
    # we use a cache to memorize orientations
    state %orientation;

    my ($a, $b) = $A.clean-pairs[0], $B.clean-pairs[0];
    if $a.key == $b.key {
	# This case is easy so we treat it separately
	my $grade = grade $a.key;
	return MultiVector.new: :canonical(
	    0 => [*]
	    $a.value, $b.value,
	    (-1)**($grade*($grade - 1) div 2),
	    @signature[sb $a.key]
	)
    }
    elsif $b.key < $a.key { return ($B.reverse * $A.reverse).reverse }
    else {
	return MultiVector.new: :canonical(
	    ($a.key +^ $b.key) => [*]
	    $a.value, $b.value,
	    (
		%orientation{join ':', $a.key, $b.key} //= do {
		    my $orientation = 1;
		    my @a = sb $a.key;
		    my @b = sb $b.key;
		    my @frame = @a, @b;
		    unless [<] @frame {
			for reverse ^@a -> $i {
			    for $i ..^ @frame.end {
				if @frame[$_] == @frame[$_ + 1] {
				    @frame.splice($_);
				    last;
				} elsif @frame[$_] > @frame[$_ + 1] {
				    @frame[$_, $_ + 1].=reverse;
				    $orientation *= -1;
				}
			    }
			}
		    }
		    $orientation;
		}
	    ),
	    @signature[sb $a.key +& $b.key];
	);
    }
}

#
# EXPONENTIONATION
#
multi infix:<**>(Vector $a, 2) returns Real is export { ($a*$a).narrow }
multi infix:<**>(Vector $a, Int $ where -1) returns Vector is export { $a / $a**2 }
multi infix:<**>(Vector $a, Int $n where $n %% 2 && $n > 3) returns Real is export {
    ($a**2)**($n div 2)
}
multi infix:<**>(Vector $a, Int $n where $n % 2 && $n > 2) returns Vector is export {
    ($a**2)**($n div 2) * $a
}
multi infix:<**>(MultiVector $M, 0) returns Real is export { 1 }
multi infix:<**>(MultiVector $M, 1) returns MultiVector is export { $M }
multi infix:<**>(MultiVector $M, 2) returns MultiVector is export { $M * $M }
multi infix:<**>(MultiVector $M, Int $n where $n > 2 && $n %% 2) returns MultiVector is export {
    ($M**($n div 2))**2
}
multi infix:<**>(MultiVector $M, Int $n where $n > 2 && $n % 2) returns MultiVector is export {
    $M**($n - 1) * $M
}

multi prefix:<->(MultiVector $M) returns MultiVector is export { -1 * $M }
multi prefix:<+>(MultiVector $M) returns MultiVector is export { $M }
multi infix:<->(MultiVector $A, MultiVector $B) returns MultiVector is export { $A + -1 * $B }

#
# INNER PRODUCT
#
multi infix:<cdot>(Canonical $A, Canonical $B) returns MultiVector is export {
    ($A*$B)[ ($A.grade - $B.grade).abs ]
}
multi infix:<cdot>(MultiVector $A, MultiVector $B) returns MultiVector is export {
    [+] $A.canonical-decomposition X[cdot] $B.canonical-decomposition
}

#
# OUTER PRODUCT
# 
multi infix:<wedge>(Canonical $A, Canonical $B) returns MultiVector is export {
    ($A*$B)[ $A.grade + $B.grade ]
}
multi infix:<wedge>(MultiVector $A, MultiVector $B) returns MultiVector is export {
    [+] $A.canonical-decomposition X[wedge] $B.canonical-decomposition
}

#
# REVERSION
#
sub postfix:<†>(MultiVector $M) returns MultiVector is export { $M.reverse }


# vim: ft=perl6
