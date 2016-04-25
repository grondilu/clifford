unit module Clifford;
no precompilation; # see bug #127858
package Basis {
    our role Index {...}
    grammar Parser {
	token TOP { <scalar> | <blade> }
	token scalar { s }
	token blade  { <unit-vector>+ % '∧' }
	token unit-vector {
	    <euclidean-unit-vector> |
	    <anti-euclidean-unit-vector>
	}
	token euclidean-unit-vector {
	    e<index>   { make 1 +< (2*$<index>) }
	}
	token anti-euclidean-unit-vector {
	    'ē'<index> { make 1 +< (2*$<index> + 1) }
	}
	token index { \d+ }
    }
    our sub parse(Str $blade) returns Index {
	my UInt $result = 0;
	Parser.parse:
	$blade,
	actions => class {
	    method euclidean-unit-vector($/)      { $result += $/.made }
	    method anti-euclidean-unit-vector($/) { $result += $/.made }
	};
	return $result but Index;
    }
    role Index {
	multi method Str(UInt $b is copy:) {
	    return 's' unless $b;
	    my int $n = 0;
	    join '∧',
	    gather while $b > 0 {
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
}
subset Blade of Pair  where { .key ~~ Basis::Index and .value ~~ Real }
sub blade($a, $b = 1) returns Blade { ($a but Basis::Index) => $b }

role MultiVector does Numeric {
    method blades returns MixHash {...}

    multi method gist(MultiVector:D:) {
	return ~self.Real if none(self.blades.keys) > 0;
	(self.blades{0 but Basis::Index} ??
	~self.blades{0 but Basis::Index}~'+' !!
	'') ~
        self.blades.pairs
	.grep(*.key > 0)
	.map({
	    .value == 1 ?? ~.key !!
	    .value == -1 ?? '-'~.key !!
	    (.value ~ '*' ~ .key)
	})
	.join('+')
	.subst(/'+-'/, '-', :g);
    }
    method pairs { self.blades.pairs }
    method keys  { self.blades.keys  }

    method Real {
        if any(self.blades.keys) > 0 {
            fail X::Numeric::Real.new:
            target => Real,
            source => self,
            reason => 'not purely scalar'
            ;
        }
        return self.blades{0 but Basis::Index} // 0;
    }

    method reals { self.blades.values }
    method narrow returns Numeric {
        return 0 if self.blades.pairs == 0;
        for self.blades.pairs {
            return self if .key > 0;
        }
        return self.blades{0 but Basis::Index}.narrow;
    }
    method AT-POS(UInt $n) {
        ::?CLASS.new:
        blades => self.blades.keys.grep({ grade($_) == $n }).MixHash
    }
    method max-grade { self.blades.keys.map(&grade).max }
}
our role MultiVector::Optimized[UInt $key, Str $name] does MultiVector {
    method name returns Str { $name }
    method key  returns UInt { $key }
    method dimension { (unkey $key).elems }
    method coord {...}
    multi method gist { "optimized multivector for key={self.key}" }
    method blades {
        (blade(.value, self.coord[.key]) for (unkey self.key).pairs).MixHash
    }
}

our class Space {
    subset Metric of Array where { .all ~~ Real && .map(&abs).all == 1 }
    has Metric $.metric;
    has Basis::Index @.basis;

    # Each type of multivector will be defined as a class implementing
    # MultiVector::Optimized.
    # We put them all in a public hash attribute, as we shall generate them
    # with EVAL
    has %.classes;

    has %.products;
    has %.subspaces;

    # Conformal variant
    role Conformal {
	submethod BUILD {
	    note "building a conformal space!";
	}
    }

    method vector-dimension returns UInt { $!metric.elems }
    method dimension        returns UInt { 2**self.vector-dimension }

    submethod BUILD(:$metric, :%types, Bool :$conformal) {
        $!metric = $metric;
        @!basis  = self.build-basis;
	self does Conformal if $conformal;

        %!classes  = self.build-classes;
        %!products = self.build-products;
	if %types {
	    for %types {
		die "unreckognized basis <{.value}>" unless .value.all ~~ /<Basis::Parser::TOP>/;
		my $key = key(.value.map(&Basis::parse));
		%!classes{$key} = self.create-class($key) unless %!classes{$key} :exists;
		%!classes{.key} := %!classes{$key};
	    }
	}
	self.build-subspaces;
    }
    method build-basis {
        my @basis = 0;

        # build the coordinate blades (e0, ē0, e1, ē1 ... )
        my $euclidean = 1;
        my $anti-euclidean = 2;
        for @$!metric {
            when * > 0 {
                push @basis, $euclidean;
                $euclidean +<= 2;
            }
            when * < 0 {
                push @basis, $anti-euclidean;
                $anti-euclidean +<= 2;
            }
        }
        # build the bivectors (e12, e23, ...)
        for ^@basis -> $i {
            for $i^..^@basis -> $j {
                my $r = outer(@basis[$i], @basis[$j]);
                push @basis, $r.key unless $r.key == @basis.any;
            }
        }
        return map { $_ but Basis::Index },
	sort { grade($^a) <=> grade($^b) || $^a <=> $^b },
	@basis;
    }
    method build-classes {
	@!basis.map({
	    my $key = 1 +< $_;
	    $key => self.create-class($key);
	}).Hash;
    }
    method build-products {
	my %table;
	for @!basis -> $a {
	    for @!basis -> $b {
		%table<gp>[$a][$b] = $a * $b;
		#%table<ip>[$a][$b] = self.metric-inner($a, $b);
		%table<op>[$a][$b] = outer($a, $b);
	    }
	}
	return %table;
    }
    method build-subspaces {
	constant subspace-names = <Real Vec Biv Tri Quad Penta Hexa Hepta Octo>;
	for @!basis.classify(&grade) {
	    my $key = key(.value);
	    %!classes{$key} = self.create-class: $key unless %!classes{$key} :exists;
	    %!classes{subspace-names[.key]} := %!classes{$key};
	}
    }
    method create-class(UInt $key) {
	use MONKEY-SEE-NO-EVAL;
	my $class-name = "C_{$key.base(36)}";
	my $dimension  = (unkey $key).elems;
	note "building $class-name...";
	return EVAL qq:to /END-CLASS-DEFINITION/;
	class $class-name does MultiVector::Optimized[$key, "$class-name"] \x7B
	    has num \@.coord[$dimension];
	\x7D
	END-CLASS-DEFINITION
    }
}

our constant @e is export = map {
    class :: does MultiVector {
        has MixHash $.blades
    }.new: blades => (blade(1 +< (2*$_)),).MixHash
}, ^Inf;

our constant @ē is export = map {
    class :: does MultiVector {
        has MixHash $.blades
    }.new: blades => (blade(1 +< (2*$_+1)),).MixHash
}, ^Inf;

# &key is a bijection from a list of positive integers to a positive integer.
# It uses bit encoding.
# &unkey is its inverse.
sub key(@i where .all ~~ UInt) returns UInt { [+] map 1 +< *, @i }
sub unkey(UInt $key is copy) {
    my $i = 0;
    gather while $key > 0 {
        take $i if $key +& 1;
        $key +>= 1;
        $i++;
    }
}

our sub grade(UInt $b is copy --> UInt) is export {
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
sub product(UInt $a, UInt $b) returns Blade { blade($a +^ $b, sign($a, $b)) }
sub outer(UInt $a, UInt $b)   returns Blade { $a +& $b ?? blade(0, 0) !! product($a, $b) }
sub involute(UInt $x)         returns Blade { blade($x, (-1)**grade($x)) }
sub reverse(UInt $x)          returns Blade { blade($x, (-1)**($_*($_-1) div 2)) given grade($x) }
sub conjugate(UInt $x)        returns Blade { blade($x, (-1)**($_*($_+1) div 2)) given grade($x) }

sub basisBit(Str $name) returns Basis::Index {
    (
        $name eq 's' ?? 0 !!
        [+] map { 1 +< ($_ - 1) }, $name.comb(/\d/)
    ) but Basis::Index;
}

# ADDITION
multi infix:<+>(MultiVector $A, MultiVector $B) returns MultiVector is export {
    return class :: does MultiVector {
        has MixHash $.blades
    }.new: blades => ($A.pairs, $B.pairs).MixHash;
}
multi infix:<+>(Real $s, MultiVector $A) returns MultiVector is export {
    class :: does MultiVector {
        has MixHash $.blades
    }.new: blades => ($A.pairs, blade(0, $s)).MixHash;
}
multi infix:<+>(MultiVector $A, Real $s) returns MultiVector is export { $s + $A }
multi infix:<+>(MultiVector::Optimized $A, MultiVector::Optimized $B) returns MultiVector::Optimized is export { $A.add($B) }

# SCALAR MULTIPLICATION
multi infix:<*>(MultiVector $,  0) is export { 0 }
multi infix:<*>(MultiVector $A, 1) returns MultiVector is export { $A }
multi infix:<*>(MultiVector $A, Real $s) returns MultiVector is export { $s * $A }
multi infix:<*>(Real $s, MultiVector $A) returns MultiVector is export {
    return class :: does MultiVector {
        has MixHash $.blades
    }.new: blades => (map { blade(.key+0, $s*.value) }, $A.pairs).MixHash;
}
multi infix:<*>(Real $s, MultiVector::Optimized $A) returns MultiVector::Optimized is export { $A.scale($s) }
multi infix:</>(MultiVector $A, Real $s) returns MultiVector is export { (1/$s) * $A }
multi infix:</>(MultiVector::Optimized $A, Real $s) returns MultiVector::Optimized is export { $A.scale(1/$s) }

# SUBSTRACTION
multi prefix:<->(MultiVector $A) returns MultiVector is export { return -1 * $A }
multi infix:<->(MultiVector $A, MultiVector $B) returns MultiVector is export { $A + -$B }
multi infix:<->(MultiVector $A, Real $s) returns MultiVector is export { $A + -$s }
multi infix:<->(Real $s, MultiVector $A) returns MultiVector is export { $s + -$A }

# GEOMETRIC PRODUCT
multi infix:<*>(Blade $a, Blade $b) returns Blade {
    blade(
        $a.key +^ $b.key,
        [*] $a.value, $b.value,
        sign($a.key, $b.key),
        |grep +*, (
            |(1, -1) xx * Z*
            ($a.key +& $b.key).base(2).comb.reverse
        )
    );
}
multi infix:<*>(MultiVector $A, MultiVector $B) returns MultiVector is export {
    class :: does MultiVector {
        has MixHash $.blades
    }.new: blades => ($A.pairs X* $B.pairs).MixHash;
}
multi infix:<*>(MultiVector::Optimized $A, MultiVector::Optimized $B) returns MultiVector::Optimized is export { $A.geometric-product($B) }

# EXPONENTIATION
multi infix:<**>(MultiVector $ , 0) is export { return 1 }
multi infix:<**>(MultiVector $A, 1) returns MultiVector is export { return $A }
multi infix:<**>(MultiVector $A, 2) returns MultiVector is export { return $A * $A }
multi infix:<**>(MultiVector $A, UInt $n where $n %% 2) returns MultiVector is export {
    return ($A ** ($n div 2)) ** 2;
}
multi infix:<**>(MultiVector $A, UInt $n) returns MultiVector is export {
    return $A * ($A ** ($n div 2)) ** 2;
}

# COMPARISON
multi infix:<==>(MultiVector $A, MultiVector $B) returns Bool is export { $A - $B == 0 }
multi infix:<==>(Real $x, MultiVector $A) returns Bool is export { $A == $x }
multi infix:<==>(MultiVector $A, Real $x) returns Bool is export {
    my $narrowed = $A.narrow;
    $narrowed ~~ Real and $narrowed == $x;
}

