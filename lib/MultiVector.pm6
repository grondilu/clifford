class MultiVector;
our @signature = 1 xx *;

my subset Index of Int where * >= 0;
my subset RightFrame of Parcel where { !$_ or [and] @$_ »~~» Index, [<] @$_ }
has Real %.canonical-decomposition{RightFrame};

method clean {
    for %!canonical-decomposition.pairs {
	%!canonical-decomposition{$(+«.key)} :delete if .value == 0;
    }
}
method grades {
    uniq 
    map *.key.elems,
    grep *.value != 0,
    %!canonical-decomposition.pairs;
}

method gist {
    ! %!canonical-decomposition ?? "0" !!
    join ' + ', map {
	.key ?? (
	    .value == 1 ?? '' !!
	    .value < 0 ?? "({.value})*" !!
	    "{.value}*";
	) ~ (
	    .key == 1 ?? "e{.key}"
	    !! "e[{.key.join(',')}]"
	) !! .value
    },
    sort *.key.elems,
    %!canonical-decomposition.pairs;
}
method narrow {
    return 0 unless %!canonical-decomposition;
    if none(self.grades) > 0 {
	# normally there is only entry here
	# but we'll sum all possibilities just in case
	return [+] %!canonical-decomposition.values
    } else { return self }
}

role Frame { has $.orientation = +1 }
my multi infix:<*>( Frame $A, Frame $B ) returns Frame {
    my @A = $A.flat;
    my @B = $B.flat;
    my @index = @A, @B;
    my $end = @index.end;
    my $orientation = $A.orientation * $B.orientation;
    for reverse ^@A -> $i {
	for $i ..^ $end {
	    if @index[$_] == @index[$_ + 1] {
		$orientation *= @signature[@index[$_]];
		@index.splice($_, 2);
		$end = $_;
		last;
	    } elsif @index[$_] > @index[$_ + 1] {
		@index[$_, $_ + 1] = @index[$_ + 1, $_];
		$orientation *= -1;
	    }
	}
    }
    $@index but Frame($orientation);
}

proto e($) returns MultiVector is export {
    MultiVector.new: :canonical-decomposition({*})
}
multi e(Real) {
    (my Real %canonical-decomposition{RightFrame}){().Parcel.item}++;
    %canonical-decomposition;
}

multi e(Int $n where $n >= 0) {
    (my Real %canonical-decomposition{RightFrame}){$(+$n,)}++;
    %canonical-decomposition;
}

#
#
# GRADE PROJECTION
#
#
method at_pos(Int $n) returns MultiVector {
    my Real %canonical-decomposition{RightFrame};
    %canonical-decomposition{$(+«.key)} = .value for
    grep *.key == $n, %!canonical-decomposition.pairs;
    MultiVector.new: :%canonical-decomposition;
}

#
#
#  ADDITION
#
#
multi prefix:<+>(MultiVector $M) is export { $M.narrow }
multi infix:<+>(MultiVector $M) returns MultiVector is export { $M }
multi infix:<+>(MultiVector $M, Real $r) returns MultiVector is export { $r + $M }
multi infix:<+>(      0, MultiVector $M) returns MultiVector is export { $M }
multi infix:<+>(Real $r, MultiVector $M) returns MultiVector is export {
    my Real %canonical-decomposition{RightFrame};
    %canonical-decomposition{().Parcel.item} += $r;
    %canonical-decomposition{$(+«.key)} += .value for $M.canonical-decomposition.pairs;
    MultiVector.new: :%canonical-decomposition;
}
multi infix:<+>(MultiVector $A, MultiVector $B) returns MultiVector is export {
    my Real %canonical-decomposition{RightFrame};
    for $A.canonical-decomposition.pairs, $B.canonical-decomposition.pairs {
	%canonical-decomposition{$(+«.key)} += .value;
    }
    MultiVector.new: :%canonical-decomposition;
}

# 
#
# SOUSTRACTION
#
#
multi infix:<->(MultiVector $A, Real $r) returns MultiVector is export { -$r + $A }
multi infix:<->(Real $r, MultiVector $A) returns MultiVector is export { $r + (-1)*$A }
multi infix:<->(MultiVector $A, MultiVector $B) returns MultiVector is export { $A + (-1)*$B }
multi prefix:<->(MultiVector $A) returns MultiVector is export { (-1)*$A }

# 
#
# MULTIPLICATION
#
#
# scalar multiplication is commutative so we'll define it from the left by default
multi infix:<*>(MultiVector $M, Real $r) returns MultiVector is export { $r * $M }
multi infix:<*>(      0, MultiVector $M) returns Real is export { 0 }
multi infix:<*>(      1, MultiVector $M) returns MultiVector is export { $M }
multi infix:<*>(Real $r, MultiVector $M) returns MultiVector is export {
    my Real %canonical-decomposition{RightFrame};
    %canonical-decomposition{$(+«.key)} = .value * $r for $M.canonical-decomposition.pairs;
    MultiVector.new: :%canonical-decomposition;
}
multi infix:<*>(MultiVector $A, MultiVector $B) returns MultiVector is export {
    my Real %canonical-decomposition{RightFrame};
    for $A.canonical-decomposition.pairs X $B.canonical-decomposition.pairs -> $a, $b {
	my $ab = ($a.key but Frame) * ($b.key but Frame);
	%canonical-decomposition{$ab.Parcel.item} = $a.value * $b.value * $ab.orientation;
    }
    MultiVector.new: :%canonical-decomposition;
}

#
#
# EXPONENTIATION
#
#
multi infix:<**>(MultiVector $M, 0) returns Real is export { 1 }
multi infix:<**>(MultiVector $M, 1) returns MultiVector is export { $M }
multi infix:<**>(MultiVector $M, Int $n where $n > 1) returns MultiVector is export {
    [*] $M xx $n
}

method reverse returns MultiVector {
    [+] map { (-1)**($_*($_ - 1) div 2) * self[$_] }, self.grades
}
method conj returns MultiVector {
    [+] map { (-1)**$_ * self[$_] }, self.grades
}
sub postfix:<†>(MultiVector $M) returns MultiVector is export { $M.reverse }

sub commutator(MultiVector $A, MultiVector $B) returns MultiVector is export {
    1/2 * ($A*$B - $B*$A)
}
multi infix:<×>(MultiVector $A, MultiVector $B) returns MultiVector is export {
    commutator $A, $B
}
=finish

multi infix:<==>(MultiVector $A, MultiVector $B) returns Bool is export { $A - $B == 0 }
multi infix:<==>(MultiVector $A, 0) returns Bool is export {...}

multi inner-product(MultiVector $A, MultiVector $B) is export {...}
multi outer-product(MultiVector $A, MultiVector $B) is export {...}

multi infix:<*>(MultiVector $, MultiVector $) returns MultiVector is export {...}
proto infix:<·>(MultiVector $, MultiVector $) is export {*}

#sub postfix:<*>(MultiVector $M) returns MultiVector is export { $M.conj }


# vim: syntax=off
