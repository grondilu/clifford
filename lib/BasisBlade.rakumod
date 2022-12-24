unit class BasisBlade;

has UInt $.bit-encoding;
has Real $.weight = 1;

method gist {
  (
    $!weight == 1 ?? '' !!
    $!weight == -1 ?? '-' !!
    "$!weight*"
  ) ~ join '∧', gather
  loop (my ($b, $n) = $!bit-encoding, 0; $b > 0; $n++, $b +>= 3) {
    take "e$n" if $b +& 1;
    take "i$n" if $b +& 2;
    take "o$n" if $b +& 4;
  }
}
    
method grade returns int { grade($!bit-encoding) }
our sub grade(UInt $b is copy) returns int {
    my int $n = 0;
    while $b > 0 {
        if $b +& 1 { $n++ }
        $b +>= 1;
    }
    return $n;
}
sub sign(UInt $a, UInt $b --> Int) {
    my int $n = $a +> 1;
    my $sum = 0;
    while $n > 0 {
        $sum += grade($n +& $b);
        $n +>= 1;
    }
    return $sum +& 1 ?? -1 !! +1;
}

multi method new(Real $r, Bool :$in-diagonal-basis) {
    self.bless: :bit-encoding(0), :weight($r);
}
multi method new(Str $blade where /^^ (<[eio]>)(\d+) $$/) {
  self.bless: :bit-encoding(1 +< (3*$1 + %(e=>0,i=>1,o=>2){$0}))
}

subset UIntMix of Mix is export where .keys.all ~~ UInt;
subset UIntRealPair of Pair where { .key ~~ UInt and .value ~~ Real }

# This class should easily be converted to and from a Pair object
method pair { $!bit-encoding => $!weight }
multi method new(UIntRealPair $pair) {
    self.new:
    :bit-encoding($pair.key),
    :weight($pair.value)
}

method geometric-product($a: ::?CLASS $b) returns ::?CLASS {
  $a.new:
    :bit-encoding($a.bit-encoding +^ $b.bit-encoding),
    :weight(
	[*] $a.weight, $b.weight,
	sign($a.bit-encoding, $b.bit-encoding),
	|map *.key, grep *.value, (
	    |(1, -1, 0) xx * Z=>
	    map ?*, ($a.bit-encoding +& $b.bit-encoding).polymod(2 xx *)
	)
    );
}

method negation returns ::?CLASS { self.new: :$!bit-encoding, :weight(-$!weight) }
method conjugation returns ::?CLASS {
    self.new:
    :$!bit-encoding,
    :weight($!weight*(-1)**($_*($_+1) div 2))
    given self.grade;
}
method reversion returns ::?CLASS {
    self.new:
    :$!bit-encoding,
    :weight($!weight*(-1)**($_*($_-1) div 2))
    given self.grade;
}
method involution returns ::?CLASS {
    self.new:
    :$!bit-encoding,
    :weight($!weight*(-1)**self.grade);
}
