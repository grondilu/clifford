unit class MultiVector; 
has Real %.blades{UInt};

# Metric signature
our @signature = 1 xx *;

sub e(UInt $n?) returns MultiVector is export {
    $n.defined ?? MultiVector.new(:blades(my Real %{UInt} = (1 +< $n) => 1)) !! MultiVector.new
}

my sub grade(UInt $n) is cached { [+] $n.base(2).comb }
my sub order(UInt:D $i is copy, UInt:D $j) is cached {
    my $n = 0;
    repeat {
	$i +>= 1;
	$n += [+] ($i +& $j).base(2).comb;
    } until $i == 0;
    return $n +& 1 ?? -1 !! 1;
}

sub metric-product(UInt $i, UInt $j) {
    my $r = order($i, $j);
    my $t = $i +& $j;
    my $k = 0;
    while $t !== 0 {
	if $t +& 1 {
	    $r *= @signature[$k];
	}
	$t +>= 1;
	$k++;
    }
    return $r;
}

method clean {
    for %!blades {
	%!blades{.key} :delete unless .value;
    }
}
multi method gist {
    my sub blade-gist($blade) {
	join(
	    '*',
	    $blade.value,
	    map { "e({$_ - 1})" },
	    grep +*,
	    ($blade.key.base(2).comb.reverse Z* 1 .. *)
	).subst(/<|w>1\*/, '')
    }
    if    %!blades == 0 { return '0' }
    elsif %!blades == 1 {
	given %!blades.pick {
	    if .key == 0 {
		return .value.gist;
	    } else {
		return blade-gist($_);
	    }
	}
    } else {
	return 
	join(
	    ' + ', do for sort *.key, %!blades {
		.key == 0 ?? .value.gist !! blade-gist($_);
	    }
	).subst('+ -','- ', :g);
    }
}
method reals { %!blades.values }
method max-grade { self.clean(); max map &grade, %!blades.keys }
method AT-POS($n) {
    MultiVector.new: :blades(my Real %{UInt} = %!blades.grep: *.key.&grade == $n)
}	
method narrow {
    for %!blades {
	return self if .key > 0 && .value !== 0;
    }
    return %!blades{0} // 0;
}
method reverse {
    [+] do for 0..self.max-grade -> $grade {
	(-1)**($grade*($grade - 1) div 2) * self[$grade];
    }
}


multi infix:<+>(MultiVector $A, MultiVector $B) returns MultiVector is export {
    my Real %blades{UInt} = $A.blades.clone;
    for $B.blades {
	%blades{.key} += .value;
	%blades{.key} :delete unless %blades{.key};
    }
    return MultiVector.new: :%blades;
}
multi infix:<+>(Real $s, MultiVector $A) returns MultiVector is export {
    my Real %blades{UInt} = $A.blades.clone;
    %blades{0} += $s;
    %blades{0} :delete unless %blades{0};
    return MultiVector.new: :%blades;
}
multi infix:<+>(MultiVector $A, Real $s) returns MultiVector is export { $s + $A }
multi infix:<*>(MultiVector $A, MultiVector $B) returns MultiVector is export {
    my Real %blades{UInt};
    for $A.blades -> $a {
	for $B.blades -> $b {
	    my $c = $a.key +^ $b.key;
	    %blades{$c} += $a.value * $b.value * metric-product($a.key, $b.key);
	    %blades{$c} :delete unless %blades{$c};
	}
    }
    return MultiVector.new: :%blades;
}
multi infix:<**>(MultiVector $ , 0) returns MultiVector is export { return MultiVector.new }
multi infix:<**>(MultiVector $A, 1) returns MultiVector is export { return $A }
multi infix:<**>(MultiVector $A, 2) returns MultiVector is export { return $A * $A }
multi infix:<**>(MultiVector $A, UInt $n where $n %% 2) returns MultiVector is export {
    return ($A ** ($n div 2)) ** 2;
}
multi infix:<**>(MultiVector $A, UInt $n) returns MultiVector is export {
    return $A * ($A ** ($n div 2)) ** 2;
}

multi infix:<*>(MultiVector $,  0) returns MultiVector is export { MultiVector.new }
multi infix:<*>(MultiVector $A, 1) returns MultiVector is export { $A }
multi infix:<*>(MultiVector $A, Real $s) returns MultiVector is export {
    return MultiVector.new: :blades(my Real %{UInt} = map { .key => $s * .value }, $A.blades);
}
multi infix:<*>(Real $s, MultiVector $A) returns MultiVector is export { $A * $s }
multi infix:</>(MultiVector $A, Real $s) returns MultiVector is export { $A * (1/$s) }
multi prefix:<->(MultiVector $A) returns MultiVector is export { return -1 * $A }
multi infix:<->(MultiVector $A, MultiVector $B) returns MultiVector is export { $A + -$B }
multi infix:<->(MultiVector $A, Real $s) returns MultiVector is export { $A + -$s }
multi infix:<->(Real $s, MultiVector $A) returns MultiVector is export { $s + -$A }

multi infix:<==>(MultiVector $A, MultiVector $B) returns Bool is export { $A - $B == 0 }
multi infix:<==>(Real $x, MultiVector $A) returns Bool is export { $A == $x }
multi infix:<==>(MultiVector $A, Real $x) returns Bool is export {
    my $narrowed = $A.narrow;
    $narrowed ~~ Real and $narrowed == $x;
}
