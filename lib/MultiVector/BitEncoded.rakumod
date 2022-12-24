use MultiVector;
use BasisBlade;
unit class MultiVector::BitEncoded does MultiVector;

has UIntMix $.bitEncoding handles <pairs keys values>;

method reals  { map *.value, sort *.key, self.pairs }

multi method new(Real $s) returns ::?CLASS {
  samewith BasisBlade.new: :bit-encoding(0), :weight($s)
}

# All implementations should have a constructor taking a MixHash as parameter.
# (provided this MixHash as positive integers as keys)
multi method new(UIntMix $bitEncoding) { self.bless: :$bitEncoding }

# With the requirement above, we can define a constructor
# that takes a string representation of a basis blade.
multi method new(Str $blade) { samewith BasisBlade.new($blade) }
multi method new(BasisBlade $blade) { samewith $blade.pair.Mix }

multi method geometric-product($A: ::?CLASS $B) {
  $A.new: do for $A.basis-blades -> $a {
      |do for $B.basis-blades -> $b {
	$a.geometric-product($b)
      }
  }.flat
  .map(*.pair)
  .Mix;
}

multi method scale(Real $s) {
  ::?CLASS.new: self.pairs.map({ Pair.new: .key, $s*.value }).Mix
}

multi method add($A: ::?CLASS $B) {
  ::?CLASS.new: (|$A.pairs, |$B.pairs).Mix
}
multi method add(Real $r) {
  ::?CLASS.new: (0 => $r, |self.pairs).Mix
}

# Grade projection
multi method AT-POS(0) {
    self.new: (0 => self.bitEncoding{0}).Mix
}
multi method AT-POS(UInt $n where $n > 0) {
    self.new:
    self.pairs.grep(
	{ BasisBlade::grade(.key) == $n }
    ).Mix
}

method grades { squish sort map &BasisBlade::grade, self.keys }
method basis-blades { self.pairs.map: { BasisBlade.new: $_ } }

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

