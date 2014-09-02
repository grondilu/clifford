module Clifford;

# Class predeclarations
class Blade {...}
class MultiVector {...}
subset UnitBlade of Blade where *.magnitude == 1;

# metric signature.  Euclidean by default.
our @signature = 1 xx *;

subset Index of Int where * >= 0;
subset Frame of Parcel where { [and] @$_ »~~» Index, [<] @$_ }
    
class MultiVector {
    has Blade @.blades;
    method gist { join ' + ', map *.gist, sort *.grade, @!blades }
    method Str { self.gist }
    method grade-projection(Int $n) {
	self.new: :blades(grep *.grade == $n, @!blades)
    }
    method reverse {
	self.new: :blades(
	    map {
		Blade.new: :frame(.frame),
		:magnitude(
		    (-1)**(.grade*(.grade - 1)/2) * .magnitude
		)
	    }, @!blades
	)
    }
    method narrow {
	@!blades».grade.max == 0 ??
	([+] @!blades».magnitude) !!
	self
    }
}

class Blade {
    has Frame $.frame;
    has Real  $.magnitude = 1;
    method grade { +$!frame }
    method gist {
	if +$!frame {
	    (
		$!magnitude  < 0 ?? "($!magnitude)*" !!
		$!magnitude == 1 ?? "" !! "$!magnitude*"
	    ) ~ <e[ ]>.join: $!frame.join(",")
	} else { ~$!magnitude }
    }
}

multi postcircumfix:<{ }>(MultiVector $M, Int $n) returns MultiVector is export { $M.grade-projection($n) }
sub postfix:<†>(MultiVector $M) returns MultiVector is export { $M.reverse }

proto circumfix:<e[ ]>($?) returns MultiVector is export { MultiVector.new: :blades({*}) }
multi circumfix:<e[ ]>(Int $n)       { Blade.new: :frame($n,) }
multi circumfix:<e[ ]>(Frame $frame) { Blade.new: :$frame }
multi circumfix:<e[ ]>(Range $range) { Blade.new: :frame((+«$range).Parcel) }

# This is the most important function because it does most of the heavy
# lifting.  Yet, it is not exported because it operates only on Blades, which
# are not supposed to be used directly.
my multi infix:<*>( Blade $A, Blade $B ) returns Blade {
    state %cache{Str}{Frame}{Frame};
    my $signature = @signature[0 .. max($A.frame, $B.frame)];
    my $unit = %cache{$signature.join('|')}{$A.frame}{$B.frame} //= do {
	my @frame = ($A, $B)».frame».flat;
	my $end = @frame.end;
	my $sign = 1;
	for reverse ^$A.frame -> $i {
	    for $i ..^ $end {
		if @frame[$_] == @frame[$_ + 1] {
		    #note "entering signature check:";
		    #note $_, ", ", @frame[$_], ", ", @signature[@frame[$_]];
		    $sign *= @signature[@frame[$_]];
		    @frame.splice($_, 2);
		    $end = $_;
		    last;
		} elsif @frame[$_] > @frame[$_ + 1] {
		    @frame[$_, $_ + 1] = @frame[$_ + 1, $_];
		    $sign *= -1;
		}
	    }
	}
	Blade.new: :frame((+«@frame).Parcel), :magnitude($sign);
    };
    Blade.new:
    :frame($unit.frame),
    :magnitude($unit.magnitude * $A.magnitude * $B.magnitude);
}

multi infix:<*>(0, MultiVector $) is export { 0 }
multi infix:<*>(MultiVector $, 0) is export { 0 }
multi infix:<*>(1, MultiVector $M) is export { $M }
multi infix:<*>(MultiVector $M, 1) is export { $M }
multi infix:<*>(MultiVector $M, Real $r) returns MultiVector is export { $r * $M }
multi infix:<*>(Real $r, MultiVector $M) returns MultiVector is export {
    MultiVector.new: :blades(
	map {
	    Blade.new: :frame(.frame), :magnitude(.magnitude * $r)
	}, $M.blades
    )
}

multi prefix:<+>(MultiVector $M) returns MultiVector is export {
    my %M{Frame};
    %M{.frame} += .magnitude for $M.blades;
    my Blade @blades = map {
	Blade.new: :frame(.key), :magnitude(.value)
    }, grep *.value != 0, %M.pairs;
    MultiVector.new: :@blades;
}

multi infix:<+>(Real $r, MultiVector $M) returns MultiVector is export { $r * e[] + $M }
multi infix:<+>(MultiVector $M, Real $r) returns MultiVector is export { $r * e[] + $M }
multi infix:<->(Real $r, MultiVector $M) returns MultiVector is export { $r * e[] + (-1) * $M }
multi infix:<->(MultiVector $M, Real $r) returns MultiVector is export { $M + (-1) * $r *e[] }

multi infix:<->(MultiVector $P, MultiVector $Q) returns MultiVector is export { $P + (-1) * $Q }
multi infix:<+>(MultiVector $P, MultiVector $Q) returns MultiVector is export {
    +MultiVector.new: :blades($P.blades, $Q.blades);
}

multi infix:<*>(MultiVector $P, MultiVector $Q) returns MultiVector is export {
    +MultiVector.new: :blades( $P.blades X* $Q.blades )
}

multi infix:<**>(MultiVector $M, Int $n where $n > 0) returns MultiVector is export {
    [*] $M xx $n;
}

# vim: syntax=off
