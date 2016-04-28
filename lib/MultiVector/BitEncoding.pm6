use MultiVector;
use MultiVector::BitEncoding::BasisBlade;
unit class MultiVector::BitEncoding does MultiVector;

subset BitEncoding of MixHash where .keys.all ~~ UInt;
has BitEncoding $.bitEncoding handles <pairs keys values>;

# Constructors
multi method new(BitEncoding $bitEncoding) { self.new: :$bitEncoding }
multi method new(Str $blade) {
    self.new: MultiVector::BitEncoding::BasisBlade.new($blade).pair.MixHash
}

# Grade projection
multi method AT-POS(0) { $!bitEncoding{0} }
multi method AT-POS(UInt $n where $n > 0) {
    self.new:
    self.pairs.grep(
	{ MultiVector::BitEncoding::BasisBlade::grade(.key) == $n }
    ).MixHash
}

# list of non-vanishing grades
method grades {
    squish sort
    map &MultiVector::BitEncoding::BasisBlade::grade,
    self.keys
}

method basis-blades { self.pairs.map: { MultiVector::BitEncoding::BasisBlade.new: $_ } }

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

multi method add(MultiVector $A) {...}
multi method add(::?CLASS $A) { self.new: (flat self.pairs, $A.pairs).MixHash }
multi method add(Real $s) { self.new: (0 => $s, self.pairs).MixHash }

multi method scale(Real $s) { self.new: (map { (.key) => $s*.value }, self.pairs).MixHash }

# for now, give up on mixed products
multi method gp(MultiVector $A) {...}
multi method ip(MultiVector $A) {...}
multi method op(MultiVector $A) {...}

my %product;
multi method gp(::?CLASS $A) { %product<gp>(self, $A) }
multi method ip(::?CLASS $A) { %product<ip>(self, $A) }
multi method op(::?CLASS $A) { %product<op>(self, $A) }

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
	}.map(&MultiVector::BitEncoding::BasisBlade::pop-from-diagonal-basis).flat.MixHash;
    }
}, 
&MultiVector::BitEncoding::BasisBlade::geometric-product,
&MultiVector::BitEncoding::BasisBlade::inner-product,
&MultiVector::BitEncoding::BasisBlade::outer-product;

=finish
# work around #128010
{ MultiVector::BitEncoding::BasisBlade::geometric-product($^a, $^b) },
{ MultiVector::BitEncoding::BasisBlade::inner-product($^a, $^b) },
{ MultiVector::BitEncoding::BasisBlade::outer-product($^a, $^b) };
