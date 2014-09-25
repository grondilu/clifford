module Clifford;
our @signature = 1 xx *;
subset UInt of Int where * >= 0;

# class pre-declarations
class MultiVector is Cool does Numeric {...}
class CanonicalBlade is MultiVector {...}

subset Vector of MultiVector is export where
*.canonical-decomposition.grep(*.amount != 0)».grade.all == 1;

#
#
# MULTIVECTOR
#
#
class MultiVector {
    has CanonicalBlade @.canonical-decomposition;
    multi method gist {
	join ' + ',
	map *.gist,
	sort *.grade,
	self.canonical-decomposition
    }
    multi method at_pos(UInt $grade) returns MultiVector {
	MultiVector.new: :canonical-decomposition(
	    self.canonical-decomposition.grep(*.grade == $grade) ||
	    CanonicalBlade.new: :frame(0), :amount(0)
	)
    }
    method reverse returns MultiVector {
	MultiVector.new:
	:canonical-decomposition(
	    self.canonical-decomposition».reverse
	)
    }
    multi method new(Real $r) {
	CanonicalBlade.new: :frame(0), :amount($r)
    }
    method reals(MultiVector:D:) { self.canonical-decomposition».amount }
    method isNaN(MultiVector:D:) { [||] map *.isNaN, self.reals }
    method coerce-to-real(MultiVector:D: $exception-target) {
	unless self.canonical-decomposition».grade.max == 0 {
	    fail X::Numeric::Real.new(target => $exception-target, reason => "non-scalar part not zero", source => self);
	}
	die 'unexpected number of elements in decomposition' if self.canonical-decomposition != 1;
	self.canonical-decomposition.pick.amount;
    }
    multi method Real(MultiVector:D:) { self.coerce-to-real(Real) }
    # should probably be eventually supplied by role Numeric
    method Num { self.coerce-to-real(Num).Num; }
    method Int { self.coerce-to-real(Int).Int; }
    method Rat { self.coerce-to-real(Rat).Rat; }
    multi method Bool { not self == 0 }
    method MultiVector { self }
    method floor    { self.new: :canonical-decomposition( self.canonical-decomposition».floor ) }
    method ceiling  { self.new: :canonical-decomposition( self.canonical-decomposition».ceiling ) }
    method truncate { self.new: :canonical-decomposition( self.canonical-decomposition».truncate ) }

    multi method round($scale as Real = 1) {
	self.new:
	:canonical-decomposition( map *.round($scale), self.canonical-decomposition )
    }

    method narrow {
	my $new = MultiVector.new: :canonical-decomposition(
	    grep *.amount != 0,
	    self.canonical-decomposition
	);
	if $new.canonical-decomposition == 0 {
	    return 0
	} elsif $new.canonical-decomposition == 1 {
	    given $new.canonical-decomposition.pick {
		return .frame == 0 ?? .amount !! $new
	    }
	} else { return $new }
    }
}

multi infix:<==>(MultiVector $A, MultiVector $B) returns Bool is export { $A - $B == 0 }
multi infix:<==>($A, MultiVector $B) returns Bool is export { $A - $B == 0 }
multi infix:<==>(MultiVector $A, $B) returns Bool is export { $A - $B == 0 }
multi infix:<==>(MultiVector $A, 0) returns Bool is export {
    so all($A.canonical-decomposition».amount) == 0
}

multi infix:« < »(MultiVector $A, MultiVector $B) returns Bool is export {
    $A == $B ?? False !!
    $A.canonical-decomposition».grade.max < $B.canonical-decomposition».grade.max
}

# addition and substraction with a Real
multi infix:<+>(Real $r, MultiVector $A) returns MultiVector is export { $r*e() + $A }
multi infix:<->(Real $r, MultiVector $A) returns MultiVector is export { $r*e() + -1*$A }
multi infix:<+>(MultiVector $A, Real $r) returns MultiVector is export { $A + $r*e() }
multi infix:<->(MultiVector $A, Real $r) returns MultiVector is export { $A + (-$r)*e() }

# addition with a null multivector
multi infix:<+>( $A, MultiVector $B where $B == 0) is export { $A }
multi infix:<+>( MultiVector $A where $A == 0, $B) is export { $B }

# generic addition
multi infix:<+>(MultiVector $A, MultiVector $B) returns MultiVector is export {
    my CanonicalBlade @blades = $A.canonical-decomposition, $B.canonical-decomposition;
    MultiVector.new: :canonical-decomposition(
	do for @blades.classify(*.frame).pairs { [+] .value[] }
    )
}

# multiplication
multi infix:<*>(MultiVector $A, MultiVector $B) returns MultiVector is export {
    [+] $A.canonical-decomposition X* $B.canonical-decomposition
}
multi infix:<*>(Real $r, MultiVector $M) returns MultiVector is export {
    [+] $r X* $M.canonical-decomposition
}
multi infix:<*>(MultiVector $M, Real $r) returns MultiVector is export {
    $r * $M
}

# exponentionation
multi infix:<**>(Vector $a, 2) returns Real is export { ($a*$a).narrow }
multi infix:<**>(Vector $a, Int $ where -1) returns Vector is export { $a / $a**2 }
multi infix:<**>(Vector $a, Int $n where $n %% 2 && $n > 3) returns Real is export {
    ($a**2)**($n div 2)
}
multi infix:<**>(Vector $a, Int $n where $n % 2 && $n > 2) returns Vector is export {
    ($a**2)**($n div 2) * $a
}
multi infix:<**>(MultiVector $M, 0) returns Real is export { 1 }
multi infix:<**>(MultiVector $M, 1) returns MultiVector is export { $M }
multi infix:<**>(MultiVector $M, 2) returns MultiVector is export { $M * $M }
multi infix:<**>(MultiVector $M, Int $n where $n > 2 && $n %% 2) returns MultiVector is export {
    ($M**($n div 2))**2
}
multi infix:<**>(MultiVector $M, Int $n where $n > 2 && $n % 2) returns MultiVector is export {
    $M**($n - 1) * $M
}

multi prefix:<->(MultiVector $M) returns MultiVector is export { -1 * $M }
multi prefix:<+>(MultiVector $M) returns MultiVector is export { $M }
multi infix:<->(MultiVector $A, MultiVector $B) returns MultiVector is export { $A + -1 * $B }

#
#
# CANONICAL BLADE
#
#
class CanonicalBlade {
    has Real $.amount = 1;

    # The frame is encoded in binary.
    # For instance the frame of the trivector e(0)*e(1)*e(4)
    # will be identified by the integer 0b1011 = 19
    #
    # The frame is null for scalars.
    has UInt $.frame = 0;

    our sub zero { CanonicalBlade.new: :frame(0), :amount(0) }
    method list {
	$!frame.base(2).flip.comb.kv.hash.grep(+*.value)».keys
    }
    method canonical-decomposition { self, }
    method grade { self.list.elems }
    method reverse returns CanonicalBlade {
	(-1)**(self.grade*(self.grade - 1) div 2) * self
    }
    method gist {
	$!amount == 0 ?? '0' !!
	$!frame == 0 ?? $!amount.gist !!
	(
	    (
		$!amount == 1 ?? '' !!
		$!amount == -1 ?? '-' !!
		"$!amount*"
	    ) ~
	    join '*',
	    map {"e$_"},
	    self.list
	)
    }
    method floor    { self.new: :$!frame, :amount($!amount.floor) }
    method ceiling  { self.new: :$!frame, :amount($!amount.ceiling) }
    method truncate { self.new: :$!frame, :amount($!amount.truncate) }

    multi method round($scale as Real = 1) {
	self.new: :$!frame, :amount($!amount.round($scale))
    }

}

# addition when operands have the same frame
multi infix:<+>(
    CanonicalBlade $A,
    CanonicalBlade $B where $A.frame == $B.frame
) returns CanonicalBlade is export {
    CanonicalBlade.new: :frame($A.frame), :amount($A.amount + $B.amount)
}

# non trivial addition
multi infix:<+>(
    CanonicalBlade $A where $A.amount != 0,
    CanonicalBlade $B where $B.amount != 0 && $A.frame != $B.frame
) returns MultiVector is export {
    MultiVector.new: :canonical-decomposition($A, $B)
}

# scalar multiplication and division
multi infix:<*>(Real $r, CanonicalBlade $A) returns CanonicalBlade is export {
    CanonicalBlade.new: :frame($A.frame), :amount($r*$A.amount)
}
multi infix:<*>(CanonicalBlade $A, Real $r) returns CanonicalBlade is export {
    $r * $A
}
multi infix:</>(CanonicalBlade $A, Real $r) returns CanonicalBlade is export {
    (1/$r) * $A
}

# Geometric product.  This is arguably the most important function.
multi infix:<*>(CanonicalBlade $A, CanonicalBlade $B) returns CanonicalBlade is export {
    my @index = $A.list, $B.list;
    my $amount = $A.amount * $B.amount;
    unless [<] @index {
	my $end = @index.end;
	for reverse ^$A.list -> $i {
	    for $i ..^ $end {
		if @index[$_] == @index[$_ + 1] {
		    $amount *= @signature[@index[$_]];
		    @index.splice($_, 2);
		    $end = $_ - 1;
		    last;
		} elsif @index[$_] > @index[$_ + 1] {
		    @index[$_, $_ + 1] = @index[$_ + 1, $_];
		    $amount *= -1;
		}
	    }
	}
    }
    CanonicalBlade.new:
    :frame( [+] 1 «+<« @index ), 
    :$amount
}

# Inner product
multi infix:<cdot>(CanonicalBlade $A, CanonicalBlade $B) returns CanonicalBlade is export {
    my $AB = $A*$B;
    $AB.grade == ($A.grade - $B.grade).abs ??
    $AB !!
    CanonicalBlade::zero;
}
multi infix:<cdot>(MultiVector $A, MultiVector $B) returns MultiVector is export {
    [+] $A.canonical-decomposition X[cdot] $B.canonical-decomposition
}

# Outer product
multi infix:<wedge>(CanonicalBlade $A, CanonicalBlade $B) returns CanonicalBlade is export {
    my $AB = $A*$B;
    $AB.grade == $A.grade + $B.grade ??
    $AB !!
    CanonicalBlade::zero;
}
multi infix:<wedge>(MultiVector $A, MultiVector $B) returns MultiVector is export {
    [+] $A.canonical-decomposition X[wedge] $B.canonical-decomposition
}

# Reversion
sub postfix:<†>(MultiVector $M) returns MultiVector is export { $M.reverse }


# The main interface is this simple multi
multi e() returns CanonicalBlade is export {
    CanonicalBlade.new: :frame(0);
}
multi e(UInt $n) returns Vector is export {
    CanonicalBlade.new: :frame(1 +< $n)
}

# vim: ft=perl6
