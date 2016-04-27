unit role MultiVector does Numeric;
use Clifford::BasisBlade;

# Any implementation of this role must provide a bit encoding fallback.
my subset BitEncoding of MixHash where .keys.all ~~ UInt;
method bitEncoding returns BitEncoding {...}

method pairs  { self.bitEncoding.pairs }
method keys   { self.bitEncoding.keys  }
method values { self.bitEncoding.values }
multi method AT-KEY(UInt $n) { self.bitEncoding{$n} }
method basis-blades { self.pairs.map: { Clifford::BasisBlade.new: $_ } }

multi method new(BitEncoding $bitEncoding) { self.new: :$bitEncoding }
multi method new(Str $blade) {
    self.new: Clifford::BasisBlade.new($blade).pair.MixHash
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
method AT-POS(UInt $n) returns MultiVector {
    self.new:
    self.pairs.grep(
	{ Clifford::BasisBlade::grade(.key) == $n }
    ).MixHash
}
method max-grade returns UInt { self.keys.map(&Clifford::BasisBlade::grade).max }

proto method add($) returns MultiVector {*}
multi method add(MultiVector $A) { self.new: (flat self.pairs, $A.pairs).MixHash }
multi method add(Real $s) { self.new: (0 => $s, self.pairs).MixHash }

proto method scale(Real $) {*}
multi method scale(0) { 0 }
multi method scale(1) returns MultiVector { self }
multi method scale(Real $s) returns MultiVector { self.new: (map { (.key) => $s*.value }, self.pairs).MixHash }

proto method gp(MultiVector $) returns MultiVector {*};
proto method ip(MultiVector $) returns MultiVector {*};
proto method op(MultiVector $) returns MultiVector {*};

my %product;
multi method gp($A) { %product<gp>(self, $A) }
multi method ip($A) { %product<ip>(self, $A) }
multi method op($A) { %product<op>(self, $A) }

%product = <gp ip op> Z=>
map -> &basis-blade-product {
    sub (MultiVector $A, MultiVector $B) returns MultiVector {
	my @a = (|.push-to-diagonal-basis for $A.basis-blades);
	my @b = (|.push-to-diagonal-basis for $B.basis-blades);
	return $A.new:
	do for @a.race -> $a {
	    |do for @b -> $b {
		&basis-blade-product($a, $b);
	    }
	}.map(&Clifford::BasisBlade::pop-from-diagonal-basis).flat.MixHash;
    }
}, 
# work around #128010
{ Clifford::BasisBlade::geometric-product($^a, $^b) },
{ Clifford::BasisBlade::inner-product($^a, $^b) },
{ Clifford::BasisBlade::outer-product($^a, $^b) };
