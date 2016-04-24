unit module Clifford;
no precompilation; # see bug #127858
role BasisIndex {
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
subset Blade of Pair  where { .key ~~ BasisIndex and .value ~~ Real }
sub blade($a, $b = 1) returns Blade { ($a but BasisIndex) => $b }

role MultiVector does Numeric {
    method blades returns MixHash {...}

    multi method gist(::?CLASS:D:) {
	return ~self.Real if none(self.blades.keys) > 0;
	(self.blades{0 but BasisIndex} ??
	~self.blades{0 but BasisIndex}~'+' !!
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
        return self.blades{0 but BasisIndex} // 0;
    }

    method reals { self.blades.values }
    method narrow returns Numeric {
        return 0 if self.blades.pairs == 0;
        for self.blades.pairs {
            return self if .key > 0;
        }
        return self.blades{0 but BasisIndex}.narrow;
    }
    method AT-POS(UInt $n) {
        ::?CLASS.new:
        blades => self.blades.keys.grep({ grade($_) == $n }).MixHash
    }
    method max-grade { self.blades.keys.map(&grade).max }
}
our role MultiVector::Optimized[UInt $key] does MultiVector {
    method key { $key }
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
    has BasisIndex @.basis;
    has %.types;

    has %.products;

    method vector-dimension returns UInt { $!metric.elems }
    method dimension        returns UInt { 2**self.vector-dimension }

    submethod BUILD(:$metric, :$types) {
        $!metric = $metric;
        @!basis  = self.build-basis;
        %!types  = self.build-types;
        %!products = self.build-products;
	if $types {
	    self.create-type($_) for $types.pairs;
	}
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
        return map { $_ but BasisIndex },
	sort { grade($^a) <=> grade($^b) || $^a <=> $^b },
	@basis;
    }
    method build-types {
        use MONKEY-SEE-NO-EVAL;
        my @types;
        for @!basis {
            my $class-name = "C_{.base(36)}";
            my $key = $_ + 0;
            my $dimension = unkey($key).elems;
            push @types, ~$_ => qq:to /END-CLASS-DEFINITION/;
            class $class-name does MultiVector::Optimized[$key] \x7B
                method name returns Str \x7B "$class-name" \x7D
                has num \@.coord[$dimension] = 0 xx $dimension; 
            \x7D
            END-CLASS-DEFINITION
        }
        return @types;
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
	@!basis.classify(&grade).map(
	    { subspace-names[.key] => (basis => .value).Hash }
	).Hash
    }
    method create-type(Pair $type) {
    }
}

our constant @e is export= map {
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

sub basisBit(Str $name) returns BasisIndex {
    (
        $name eq 's' ?? 0 !!
        [+] map { 1 +< ($_ - 1) }, $name.comb(/\d/)
    ) but BasisIndex;
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

