unit class BasisBlade;

has UInt $.bit-encoding;
has Real $.weight = 1;
my role InDiagonalBasis {...}

submethod BUILD(:$bit-encoding, :$weight = 1, :$in-diagonal-basis) {
    $!bit-encoding = $bit-encoding;
    $!weight = $weight;
    self does InDiagonalBasis if $in-diagonal-basis
}

multi method new(Real $r, Bool :$in-diagonal-basis) {
    ::?CLASS.bless: :bit-encoding(0), :weight($r), :$in-diagonal-basis
}
multi method new(Str $blade where /^^ e(\d+) $$/) { ::?CLASS.bless: :bit-encoding(1 +< (2*$0 + 2)) }
multi method new(Str $blade where /^^ ē(\d+) $$/) { ::?CLASS.bless: :bit-encoding(1 +< (2*$0 + 3)) }
multi method new('no') { ::?CLASS.bless: :bit-encoding(0b01) }
multi method new('ni') { ::?CLASS.bless: :bit-encoding(0b10) }


subset UIntHash of MixHash is export where .keys.all ~~ UInt;
subset UIntRealPair of Pair where { .key ~~ UInt and .value ~~ Real }

# This class should easily be converted to and from a Pair object
method pair { $!bit-encoding => $!weight }
multi method new(UIntRealPair $pair, Bool :$in-diagonal-basis) {
    self.new:
    :bit-encoding($pair.key),
    :weight($pair.value),
    :$in-diagonal-basis
}

# Some constants related to the Minkowski plane
constant eplane = 0b11;
constant eplus  = 0b01;
constant eminus = 0b10;

constant oriinf   = 0b11;
constant origin   = 0b01;
constant infinity = 0b10;

multi method gist($self where $self !~~ InDiagonalBasis:) {
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

method push-to-diagonal-basis($self where $self !~~ InDiagonalBasis:) {
    if $!bit-encoding +& oriinf == 0|oriinf {
	return self.new(:$!bit-encoding, :$!weight, :in-diagonal-basis);
    } elsif $!bit-encoding +& origin {
	my $b = $!bit-encoding +^ origin;
	return
	self.new(:bit-encoding($b +^ eplus),  :weight($!weight/2), :in-diagonal-basis),
	self.new(:bit-encoding($b +^ eminus), :weight($!weight/2), :in-diagonal-basis);
    } elsif $!bit-encoding +& infinity {
	my $b = $!bit-encoding +^ infinity;
	return
	self.new(:bit-encoding($b +^ eplus),  :weight(-$!weight), :in-diagonal-basis),
	self.new(:bit-encoding($b +^ eminus), :weight(+$!weight), :in-diagonal-basis);
    } else { die "unexpected case" }
}

role InDiagonalBasis {
    method pop-from-diagonal-basis {
	if self.bit-encoding +& eplane == 0|eplane {
	    return self.new(:bit-encoding(self.bit-encoding), :weight(self.weight));
	} elsif self.bit-encoding +& eplus {
	    my $b = self.bit-encoding +^ eplus;
	    return
	    self.new(:bit-encoding($b +^ origin),  :weight(self.weight)),
	    self.new(:bit-encoding($b +^ infinity), :weight(-self.weight/2));
	} elsif self.bit-encoding +& eminus {
	    my $b = self.bit-encoding +^ eminus;
	    return
	    self.new(:bit-encoding($b +^ origin),  :weight(self.weight)),
	    self.new(:bit-encoding($b +^ infinity), :weight(self.weight/2));
	} else { die "unexpected case" }
    }
    method geometric-product($a: InDiagonalBasis $b) returns InDiagonalBasis {
	$a.new:
	:bit-encoding($a.bit-encoding +^ $b.bit-encoding),
	:weight(
	    [*] $a.weight, $b.weight,
	    sign($a.bit-encoding, $b.bit-encoding),
	    |grep +*, (
		|(1, -1) xx * Z*
		($a.bit-encoding +& $b.bit-encoding).polymod(2 xx *)
	    )
	),
	:in-diagonal-basis;
    }
    method outer-product($a: InDiagonalBasis $b) returns InDiagonalBasis {
	$a.bit-encoding +& $b.bit-encoding ??
	$a.new(0, :in-diagonal-basis) !!
	$a.geometric-product($b);
    }
    method inner-product($a: InDiagonalBasis $b) returns InDiagonalBasis {
	my $r = $a.geometric-product($b);
	my ($ga, $gb, $gr) = map { grade(.bit-encoding) }, $a, $b, $r;
	if $ga|$gb == 0 or $gr !== abs($ga - $gb) {
	    return $a.new(0, :in-diagonal-basis)
	} else {
	    return $r;
	}
    }
    method left-contraction($a: InDiagonalBasis $b) returns InDiagonalBasis {
	my $r = $a.geometric-product($b);
	my ($ga, $gb, $gr) = map { grade(.bit-encoding) }, $a, $b, $r;
	if $ga > $gb or $gr !== $gb - $ga {
	    return $a.new(0, :in-diagonal-basis);
	} else {
	    return $r;
	}
    }
    method scalar-product($a: InDiagonalBasis $b) returns InDiagonalBasis {
	my $r = $a.geometric-product($b);
	if $r.grade == 0 {
	    return $r;
	} else {
	    return $a.new(0, :in-diagonal-basis);
	}
    }
    method dot-product($a: InDiagonalBasis $b) returns InDiagonalBasis {
	my $r = $a.geometric-product($b);
	my ($ga, $gb, $gr) = map { grade(.bit-encoding) }, $a, $b, $r;
	if $gr !== abs($gb - $ga) {
	    return $a.new(0, :in-diagonal-basis);
	} else {
	    return $r;
	}
    }
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
