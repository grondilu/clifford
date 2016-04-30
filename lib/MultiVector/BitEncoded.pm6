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

