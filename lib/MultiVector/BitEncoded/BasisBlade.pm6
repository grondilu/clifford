unit class MultiVector::BitEncoded::BasisBlade;

has UInt $.bit-encoding;
has Real $.weight = 1;

subset UIntHash of MixHash is export where .keys.all ~~ UInt;
subset UIntRealPair of Pair where { .key ~~ UInt and .value ~~ Real }

# This class should easily be converted to and from a Pair object
method pair { $!bit-encoding => $!weight }
multi method new(UIntRealPair $pair) {
    self.new: :bit-encoding($pair.key), :weight($pair.value)
}

# Some constants related to the Minkowski plane
constant eplane = 0b11;
constant eplus  = 0b01;
constant eminus = 0b10;

constant oriinf   = 0b11;
constant origin   = 0b01;
constant infinity = 0b10;

our grammar Parser {
    token TOP  { <basis-vector>+ % '∧' }
    token basis-vector {
	| <null-vector>
	| <euclidean-unit-vector>
	| <anti-euclidean-unit-vector>
    }
    token null-vector { <origin> | <infinity> }
    token origin { no | o | '𝑜' }
    token infinity { ni | '∞' }
    token euclidean-unit-vector { e<index> }
    token anti-euclidean-unit-vector { 'ē'<index> }
    token index { \d+ }
}

multi method new(Str $blade where /^^<Parser::TOP>$$/) {
    my UInt $bit-encoding = 0;
    Parser.parse: $blade,
    actions => class {
	method euclidean-unit-vector($/)      { $bit-encoding += 1 +< (2*$/<index> + 2) }
	method anti-euclidean-unit-vector($/) { $bit-encoding += 1 +< (2*$/<index> + 3) }
	method origin($/)   { $bit-encoding += 1 }
	method infinity($/) { $bit-encoding += 2 }
    };
    return ::?CLASS.bless(:$bit-encoding);
}

multi method gist {
    my $b = $!bit-encoding;
    my int $n = 0;
    return $!bit-encoding == 0 ?? ~$!weight !!
    (
	$!weight == 1 ?? '' !!
	$!weight == -1 ?? '-' !!
	"$!weight*"
    ) ~ join '∧',
    gather {
	take '𝑜' if $b +& origin;
	take '∞' if $b +& infinity;
	$b +>= 2;
	while $b > 0 {
	    $n++;
	    if $b +& 1 {
		take ($n % 2) ??
		"e{($n-1) div 2}" !!
		"ē{($n div 2)-1}"
	    }
	    $b +>= 1;
	}
    }
}

our sub grade(UInt $b is copy) returns int {
    my int $n = 0;
    while $b > 0 {
        if $b +& 1 { $n++ }
        $b +>= 1;
    }
    return $n;
}
method grade returns int { grade($!bit-encoding) }

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

method push-to-diagonal-basis {
    if $!bit-encoding +& oriinf == 0|oriinf {
	return self.pair;
    } elsif $!bit-encoding +& origin {
	my $b = $!bit-encoding +^ origin;
	return
	($b +^ eplus)  => $!weight/2,
	($b +^ eminus) => $!weight/2;
    } elsif $!bit-encoding +& infinity {
	my $b = $!bit-encoding +^ infinity;
	return
	($b +^ eplus)  => -$!weight,
	($b +^ eminus) =>  $!weight;
    } else { die "unexpected case" }
}

our sub pop-from-diagonal-basis(UIntRealPair $p) {
    my $bit-encoding = $p.key;
    my $weight = $p.value;
    if $bit-encoding +& eplane == 0|eplane {
	return $p;
    } elsif $bit-encoding +& eplus {
	my $b = $bit-encoding +^ eplus;
	return
	($b +^ origin)   => $weight,
	($b +^ infinity) => -$weight/2;
    } elsif $bit-encoding +& eminus {
	my $b = $bit-encoding +^ eminus;
	return
	($b +^ origin)   => $weight,
	($b +^ infinity) => $weight/2;
    } else { die "unexpected case" }
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
our sub geometric-product(UIntRealPair $a, UIntRealPair $b --> UIntRealPair) {
    ($a.key +^ $b.key) =>
    [*] $a.value, $b.value,
    sign($a.key, $b.key),
    |grep +*, (
	|(1, -1) xx * Z*
	($a.key +& $b.key).polymod(2 xx *)
    )
}
our sub inner-product(UIntRealPair $a, UIntRealPair $b --> UIntRealPair) {
    my $r = geometric-product($a, $b);
    my ($ga, $gb, $gr) = map { grade(.key) }, $a, $b, $r;
    if $ga > $gb or $gr !== $gb - $ga {
	return 0 => 0;
    } else {
	return $r;
    }
}
our sub outer-product(UIntRealPair $a, UIntRealPair $b --> UIntRealPair) {
    $a.key +& $b.key ?? (0 => 0) !!
    geometric-product($a, $b);
}
