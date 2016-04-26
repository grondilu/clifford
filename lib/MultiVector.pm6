unit class MultiVector does Numeric;
use Clifford::BasisBlade;

# This class uses a bit-encoding implementation.  Any derived class can define
# a bitEncoding method as a fallback.
# Ideally we should make this class a role instead so that we can define
# bitEncoding as a stub method but roles have limitations that make it hard.
subset BitEncoding of MixHash where .keys.all ~~ UInt;
has BitEncoding $.bitEncoding;

method pairs  { self.bitEncoding.pairs }
method keys   { self.bitEncoding.keys  }
method values { self.bitEncoding.values }
multi method AT-KEY(UInt $n) { self.bitEncoding{$n} }
method basis-blades { self.pairs.map: { Clifford::BasisBlade.new: $_ } }

multi method new(BitEncoding $bitEncoding) { self.new: :$bitEncoding }
multi method new(Str $blade) {
    self.new: bitEncoding => Clifford::BasisBlade.new($blade).pair.MixHash
}
multi method gist(::?CLASS:D:) {
    !self.bitEncoding ?? '0' !!
    (
	sort {
	    $^a.grade <=> $^b.grade ||
	    $a.bit-encoding <=> $b.bit-encoding
	}, self.basis-blades
    )
    .map(*.gist)
    .join('+')
    .subst(/'+-'/, '-', :g);
}

method Real {
    if any(self.keys) > 0 {
	fail X::Numeric::Real.new:
	target => Real,
	source => self,
	reason => 'not purely scalar'
	;
    }
    return self{0} // 0;
}

method reals { self.values }
method narrow returns Numeric {
    return 0 if self.pairs == 0;
    for self.pairs {
	return self if .key > 0;
    }
    return self{0}.narrow;
}
method AT-POS(UInt $n) {
    ::?CLASS.new:
    bitEncoding => self.pairs.grep(
	{ Clifford::BasisBlade::grade(.key) == $n }
    ).MixHash
}
method max-grade { self.keys.map(&Clifford::BasisBlade::grade).max }

our proto addition($, $) returns MultiVector {*}
multi addition(MultiVector $A, MultiVector $B) {
    MultiVector.new: (flat $A.pairs, $B.pairs).MixHash;
}
multi addition(0, MultiVector $B) { $B }
multi addition(Real $s, MultiVector $B) { MultiVector.new: (0 => $s, $B.pairs).MixHash }
multi addition(MultiVector $A, Real $s) { MultiVector.new: (0 => $s, $A.pairs).MixHash }

our proto product($, $) {*}
multi product(0, MultiVector $) { 0 }
multi product(1, MultiVector $B) returns MultiVector { $B }
multi product(Real $s, MultiVector $B) returns MultiVector { MultiVector.new: (map { (.key) => $s*.value }, $B.pairs).MixHash }
multi product(MultiVector $A, Real $s) returns MultiVector { $s * $A }
multi product(MultiVector $A, MultiVector $B) returns MultiVector {
    my @a = (|.push-to-diagonal-basis for $A.basis-blades);
    my @b = (|.push-to-diagonal-basis for $B.basis-blades);
    my @p;
    for @a -> $a {
	for @b -> $b {
	    push @p, Clifford::BasisBlade::geometric-product($a, $b);
	}
    }
    return MultiVector.new:
    (|Clifford::BasisBlade::pop-from-diagonal-basis($_) for @p).MixHash;
}

our sub outer-product(MultiVector $A, MultiVector $B) returns MultiVector {
    my @a = (|.push-to-diagonal-basis for $A.basis-blades);
    my @b = (|.push-to-diagonal-basis for $B.basis-blades);
    my @p;
    for @a -> $a {
	for @b -> $b {
	    push @p, Clifford::BasisBlade::outer-product($a, $b);
	}
    }
    return MultiVector.new:
    (|Clifford::BasisBlade::pop-from-diagonal-basis($_) for @p).MixHash;
}

our sub inner-product(MultiVector $A, MultiVector $B) returns MultiVector {
    my @a = (|.push-to-diagonal-basis for $A.basis-blades);
    my @b = (|.push-to-diagonal-basis for $B.basis-blades);
    my @p;
    for @a -> $a {
	for @b -> $b {
	    push @p, Clifford::BasisBlade::inner-product($a, $b);
	}
    }
    return MultiVector.new:
    (|Clifford::BasisBlade::pop-from-diagonal-basis($_) for @p).MixHash;
}

