use MultiVector;
use BasisBlade;
unit role MultiVector::BitEncoded does MultiVector;

method bitEncoding returns UIntHash {...}
method pairs  { self.bitEncoding.pairs }
method keys   { self.bitEncoding.keys  }
method values { self.bitEncoding.values }
method reals  { map *.value, sort *.key, self.pairs }

# All implementations should have a constructor taking a MixHash as parameter.
# (provided this MixHash as positive integers as keys)
multi method new(UIntHash $) {...}

# With the requirement above, we can define a constructor
# that takes a string representation of a basis blade.
multi method new(Str $blade) {
    self.new: BasisBlade.new($blade).pair.MixHash
}

# Grade projection
multi method AT-POS(0) {
    self.new: (0 => self.bitEncoding{0}).MixHash
}
multi method AT-POS(UInt $n where $n > 0) {
    self.new:
    self.pairs.grep(
	{ BasisBlade::grade(.key) == $n }
    ).MixHash
}

# list of non-vanishing grades
method grades {
    squish sort
    map &BasisBlade::grade,
    self.keys
}

method basis-blades {
    self.pairs.map:
    { BasisBlade.new: $_ }
}

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

