use MultiVector;
use MultiVector::BitEncoded::BasisBlade;
unit role MultiVector::BitEncoded does MultiVector;

method bitEncoding returns UIntHash {...}
method pairs  { self.bitEncoding.pairs }
method keys   { self.bitEncoding.keys  }
method values { self.bitEncoding.values }

# Grade projection
multi method AT-POS(0) { self.bitEncoding{0} }
multi method AT-POS(UInt $n where $n > 0) {
    self.new:
    self.pairs.grep(
	{ MultiVector::BitEncoded::BasisBlade::grade(.key) == $n }
    ).MixHash
}

# list of non-vanishing grades
method grades {
    squish sort
    map &MultiVector::BitEncoded::BasisBlade::grade,
    self.keys
}

method basis-blades { self.pairs.map: { MultiVector::BitEncoded::BasisBlade.new: $_ } }

multi method gist(MultiVector::BitEncoded:D:) {
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

multi method add(MultiVector::BitEncoded $A) { self.new: (flat self.pairs, $A.pairs).MixHash }
multi method add(Real $s) { self.new: (0 => $s, self.pairs).MixHash }

multi method scale(Real $s) { self.new: (map { (.key) => $s*.value }, self.pairs).MixHash }

# for now, give up on mixed products
#multi method gp(MultiVector $A) {...}
#multi method ip(MultiVector $A) {...}
#multi method op(MultiVector $A) {...}

my %product;
multi method gp(MultiVector::BitEncoded $A) { %product<gp>(self, $A) }
multi method ip(MultiVector::BitEncoded $A) { %product<ip>(self, $A) }
multi method op(MultiVector::BitEncoded $A) { %product<op>(self, $A) }

%product = <gp ip op> Z=>
map -> &basis-blade-product {
    sub ($A, $B) {
	my @a = (|.push-to-diagonal-basis for $A.basis-blades);
	my @b = (|.push-to-diagonal-basis for $B.basis-blades);
	return $A.new:
	do for @a.race -> $a {
	    |do for @b -> $b {
		&basis-blade-product($a, $b);
	    }
	}.map(&MultiVector::BitEncoded::BasisBlade::pop-from-diagonal-basis).flat.MixHash;
    }
}, 
# work around #128010
{ MultiVector::BitEncoded::BasisBlade::geometric-product($^a, $^b) },
{ MultiVector::BitEncoded::BasisBlade::inner-product($^a, $^b) },
{ MultiVector::BitEncoded::BasisBlade::outer-product($^a, $^b) };
