module Clifford;

# Metric signature
our @signature = 1 xx *;

#
# PRE-DECLARATIONS AND SUBSETS
#
subset UInt of Int where * >= 0;
subset NonZeroReal of Real where * != 0;

# The user should never have to instantiate a MultiVector himself.
# Instantiation should always be done via &e and its algebraic combinations.
my class MultiVector is Cool does Numeric {...}
proto e(|) returns MultiVector is export {*}

# Canonical is a subset for MultiVectors of the form e(i)*e(j)*e(k)*...
# where i < j < k < ...
# They form the elements of the so-called 'canonical basis', thus the name.
my subset Canonical of MultiVector where *.pairs.elems == 1;
my subset Zero      of MultiVector where *.pairs.elems == 0;

# Those canonical elements are identified by a positive integer
# so we need a few functions to quickly get information from them.
my sub grade(UInt $n --> UInt) { (state %){$n} //= $n.base(2).comb(/1/).elems }
my sub sb   (UInt $n) { @((state %){$n} //= $n.base(2).flip.match(/1/, :g)».from) }
my proto orientation(UInt $a, UInt $b) is export returns Int {*}
multi orientation($a, $b where $a|$b == 0) { 1 }
multi orientation($a, $b where $a == $b) { (-1)**(grade($a)*(grade($a)-1) div 2) }
multi orientation($a, $b where $a.msb < $b.lsb) { 1 }
multi orientation($a, $b) {
    (state %){"$a|$b"} //= do {
	my @ab = map &sb, $a, $b;
	my Bool $orientation = True;
	while defined my $index = first { @ab[$_] >= @ab[$_ + 1] }, ^@ab.end {
	    if @ab[$index] == @ab[$index + 1] { @ab.splice($index, 2) }
	    else {
		@ab[$index, $index + 1].=reverse;
		$orientation ?^= True;
	    }
	}
	$orientation ?? 1 !! -1;
    }
}

# Vector is defined as a subset.  It is exported.
subset Vector of MultiVector is export where *.keys.map(&grade).all == 1;

# 
# MULTIVECTOR
#
class MultiVector {
    has NonZeroReal %.canonical{UInt} handles <pairs keys values>;
    multi method grade(Canonical:) returns Int {
	self == 0 ?? 0 !! grade self.pairs[0].key
    }
    method canonical-decomposition {
	map { MultiVector.new(:canonical($_)) },
	self.pairs;
    }
    multi method gist {
	self ~~ Zero ?? '0' !!
	join ' + ', map {
	    grade(.key) == 0 ?? ~.value !! (
		(
		    .value == 1 ?? '' !!
		    .value == -1 ?? '-' !!
		    "{.value}*"
		) ~
		join '',
		map {"e$_"},
		sb .key
	    )
	},
	sort { grade .key },
	self.pairs
    }
    multi method at_pos(UInt $grade) returns MultiVector {
	MultiVector.new: :canonical( grep { grade(.key) == $grade }, self.pairs )
    }
    method reverse returns MultiVector {
	MultiVector.new: :canonical(
	    map {
		my $grade = grade .key;
		.key => (-1)**($grade * ($grade - 1) div 2) * .value
	    },
	    self.pairs
	)
    }

    # 
    # Methods for the Numeric role
    #
    method reals(MultiVector:) { self.values || 0 }
    method isNaN(MultiVector:) { [||] map *.isNaN, self.reals }
    method coerce-to-real(MultiVector: $exception-target) {
	unless self ~~ Canonical and self.grade == 0 {
	    fail X::Numeric::Real.new(target => $exception-target, reason => "non-scalar part not zero", source => self);
	}
	%!canonical{0} // 0;
    }
    multi method Real(MultiVector:) { self.coerce-to-real(Real) }
    method Num { self.coerce-to-real(Num).Num; }
    method Int { self.coerce-to-real(Int).Int; }
    method Rat { self.coerce-to-real(Rat).Rat; }
    multi method Bool { not self == 0 }
    method MultiVector { self }
    method floor    { MultiVector.new: :canonical( map { $^p.key => $p.value.floor }, self.pairs ) }
    method ceiling  { MultiVector.new: :canonical( map { $^p.key => $p.value.ceiling }, self.pairs ) }
    method truncate { MultiVector.new: :canonical( map { $^p.key => $p.value.truncate }, self.pairs ) }
    multi method round($scale as Real = 1) {
	MultiVector.new: :canonical(
	    map { $^p.key => $p.value.round($scale) }, self.pairs
	);
    }
    method narrow {
	self ~~ Zero ?? 0 !!
	self.pairs == 1 && self.pairs[0].key == 0 ?? self.pairs[0].value.narrow !!
	self
    }
}

#
# EQUALITY
#
multi infix:<==>(MultiVector $A, MultiVector $B) returns Bool is export { $A - $B == 0 }
multi infix:<==>($A, MultiVector $B) returns Bool is export { $A - $B == 0 }
multi infix:<==>(MultiVector $A, $B) returns Bool is export { $A - $B == 0 }
multi infix:<==>(MultiVector $A, 0) returns Bool is export { $A ~~ Zero }

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
# ADDITION AND SUBSTRACTION WITH A NULL MULTIVECTOR
#
multi infix:<+>( $A, Zero ) is export { $A }
multi infix:<+>( Zero, $B ) is export { $B }

#
# GENERIC ADDITION
#
multi infix:<+>(MultiVector $A, MultiVector $B) returns MultiVector is export {
    MultiVector.new: canonical =>
    gather for uniq $A.keys, $B.keys {
	my $sum = ($A.canonical{$_}//0) + ($B.canonical{$_}//0);
	take $_ => $sum if $sum != 0;
    }
}
multi prefix:<->(MultiVector $M) returns MultiVector is export { -1 * $M }
multi prefix:<+>(MultiVector $M) returns MultiVector is export { $M }
multi infix:<->(MultiVector $A, MultiVector $B) returns MultiVector is export { $A + -1 * $B }


#
# SCALAR MULTIPLICATION
#
multi infix:<*>(Real $r, MultiVector $M) returns MultiVector is export {
    $r == 0 ?? MultiVector.new !!
    MultiVector.new: canonical =>
    map { $^p.key => $r * $p.value }, $M.pairs;
}
multi infix:<*>(MultiVector $M, Real $r) returns MultiVector is export { $r * $M }

#
# GEOMETRIC PRODUCT
#
multi infix:<*>(Zero $ , MultiVector $) returns MultiVector is export { 0 }
multi infix:<*>(MultiVector $ , Zero $) returns MultiVector is export { 0 }
multi infix:<*>(MultiVector $A, MultiVector $B) returns MultiVector is export {
    [+] $A.canonical-decomposition X* $B.canonical-decomposition
}
multi infix:<*>(Canonical $A, Canonical $B) returns Canonical is export {
    my ($a, $b) = $A.pairs[0], $B.pairs[0];
    return MultiVector.new: :canonical(
	($a.key +^ $b.key) => [*]
	$a.value, $b.value,
	orientation($a.key, $b.key),
	@signature[sb $a.key +& $b.key];
    );
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
multi infix:<**>(Zero $ , UInt $ ) returns Real is export { 0 }
multi infix:<**>(MultiVector $M, 0) returns Real is export { 1 }
multi infix:<**>(MultiVector $M, 1) returns MultiVector is export { $M }
multi infix:<**>(MultiVector $M, 2) returns MultiVector is export { $M * $M }
multi infix:<**>(MultiVector $M, Int $n where $n > 2 && $n %% 2) returns MultiVector is export {
    ($M**($n div 2))**2
}
multi infix:<**>(MultiVector $M, Int $n where $n > 2 && $n % 2) returns MultiVector is export {
    $M**($n - 1) * $M
}

#
#
# Metric products
#
# 
# Hestenes's inner product
multi infix:<cdot>(Canonical $A, Canonical $B) returns MultiVector is export {
    ($A*$B)[ ($A.grade - $B.grade).abs ]
}
multi infix:<cdot>(MultiVector $A, MultiVector $B) returns MultiVector is export {
    [+] $A.canonical-decomposition X[cdot] $B.canonical-decomposition
}
# Left contraction
multi infix:<⌋>(Canonical $A, Canonical $B) returns MultiVector is export {
    $B.grade < $A.grade ?? 0*e() !!
    ($A*$B)[ $B.grade - $A.grade ]
}
multi infix:<⌋>(MultiVector $A, MultiVector $B) returns MultiVector is export {
    [+] $A.canonical-decomposition X[⌋] $B.canonical-decomposition
}
# Right contraction
multi infix:<⌊>(Canonical $A, Canonical $B) returns MultiVector is export {
    $B.grade > $A.grade ?? 0*e() !!
    ($A*$B)[ $A.grade - $B.grade ]
}
multi infix:<⌊>(MultiVector $A, MultiVector $B) returns MultiVector is export {
    [+] $A.canonical-decomposition X[⌊] $B.canonical-decomposition
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

#
# main interface
#
multi e() { state $ = MultiVector.new: :canonical( 0 => 1 ) }
multi e(UInt $n) { (state @)[$n] //= MultiVector.new: :canonical( (1 +< $n) => 1 ) }
multi e(Whatever) { map { MultiVector.new: :canonical($_ => 1) }, 0 .. * }

# vim: syntax=off
