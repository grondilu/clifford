unit module Clifford;

# Metric signature
our @signature = 1 xx *;

our class Basis {...}
our class MultiVector {...}

my sub order(UInt:D $a is copy, UInt:D $b) {
    my $n = 0;
    repeat {
	$a +>= 1;
	$n += [+] ($a +& $b).base(2).comb;
    } until $a == 0;
    return $n +& 1 ?? -1 !! 1;
}

class Basis {
    has UInt $.blade;
    has Real $.weight is rw;
    method grade { [+] $!blade.base(2).comb }
}

multi infix:<*>(Basis $A, Basis $B) returns Basis is export {
    my $r = Basis.new:
    :blade($A.blade +^ $B.blade),
    :weight($A.weight * $B.weight * order($A.blade, $B.blade));
    my $t = $A.blade +& $B.blade;
    my $i = 0;
    while $t !== 0 {
	if $t +& 1 {
	    $r.weight *= @signature[$i];
	}
	$t +>= 1;
	$i++;
    }
    return $r;
}
multi prefix:<->(Basis $A) returns Basis is export {
    return Basis.new:
    :blade($A.blade),
    :weight(-$A.weight);
}

multi infix:<⌋>(Basis $A, Basis $B) returns Basis is export {
    my $r = $A * $B;
    if $A.grade > $B.grade or $r.grade !== $B.grade - $A.grade {
	return Basis;
    } else {
	return $r;
    }
}

multi infix:<∧>(Basis $A, Basis $B) returns Basis is export {
    return $A.grade +& $B.grade ?? Basis !! $A*$B;
}

multi infix:<≌>(Basis $A, Basis $B) returns Bool is export {
    return $A.blade == $B.blade
}

multi infix:<+>(Basis $A, Basis $B) returns MultiVector is export {
    my $C = MultiVector.new: :blades($A, $B);
    $C.compress();
    $C.clean();
    return $C;
}
    
class MultiVector {
    has Basis @.blades;
    method compress {
	my %seen;
	my Basis @blades;
	for @!blades {
	    if %seen{.blade} :exists {
		@blades[%seen{.blade}].weight += .weight;
	    } else {
		@blades.push($_);
		%seen{.blade} = @blades.end;
	    }
	}
	@!blades = @blades;
    }
    method clean { @!blades.=grep(*.weight) }
    method reals { map *.weight, @!blades }
    method max-grade { max @!blades».grade }
    method AT-POS($n) {
	map -> $grade {
	    MultiVector.new: :blades(grep *.grade == $grade, @!blades)
	}, ^self.max-grade;
    }	
    method narrow {
	self.compress();
	self.clean();
	if !@!blades { return 0 }
	elsif self.max-grade == 0 { return @!blades[0].weight }
	else { return self }
    }
}

multi infix:<*>(MultiVector $A, MultiVector $B) returns MultiVector is export {
    my $C = MultiVector.new: :blades($A.blades X* $B.blades);
    $C.compress();
    $C.clean();
    return $C;
}
multi infix:<+>(MultiVector $A, MultiVector $B) returns MultiVector is export {
    my $C = MultiVector.new: :blades(|$A.blades, |$B.blades);
    $C.compress();
    $C.clean();
    return $C;
}
multi prefix:<->(MultiVector $A) returns MultiVector is export {
    return MultiVector.new: :blades(map -*, $A.blades)
}

multi infix:<==>(MultiVector $A, MultiVector $B) returns Bool is export { $A - $B == 0 }
multi infix:<==>(MultiVector $A, Real $x) returns Bool is export {
    my $narrowed = $A.narrowed;
    $narrowed ~~ Real and $narrowed == $x;
}
