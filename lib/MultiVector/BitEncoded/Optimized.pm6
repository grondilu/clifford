use MultiVector::BitEncoded;
use MultiVector::BitEncoded::BasisBlade;
unit class MultiVector::BitEncoded::Optimized does MultiVector::BitEncoded;

has UInt @.basis;
has Real @.reals;

# overides any previously defined reals and values methods
method reals  { @!reals }
method values { @!reals }

# required by MultiVector::BitEncoded
method bitEncoding { (@!basis Z=> @!reals).MixHash }

submethod BUILD(:@basis, :@reals) {
    fail "expected strictly increasing basis order" unless [<] @basis;
    fail "unexpected number of coefficients" unless @basis == @reals;
    @!basis = @basis;
    @!reals = @reals;
}

multi method new(Real $s) { self.new: :basis[0], :reals[$s] }
multi method new(UIntHash $ where !*  ) { self.new(0) }
multi method new(UIntHash $bitEncoding) {
    my @basis = sort $bitEncoding.keys;
    self.new: :@basis, :reals[$bitEncoding{@basis}];
}
multi method new(MultiVector::BitEncoded $ where !*) { self.new(0) }
multi method new(MultiVector::BitEncoded $model    ) {
    my @pairs = sort *.key, $model.pairs;
    self.bless:
    :basis[@pairs».key],
    :reals[@pairs».value];
}

method clean {
    self.reals.none == 0 ??
    self !!
    self.new: self.bitEncoding
}

multi method add(::?CLASS $B) {
    self.new: (self.pairs, |$B.pairs).MixHash;
}
multi method add(Real $s) {
    self.new: (0 => $s, |self.pairs).MixHash;
}

my enum Product <gp ip op>;
multi method scale(Real $s) { self.new: :@!basis, :reals[@!reals X* $s] }
multi method gp(::?CLASS $A: ::?CLASS $B) { get-block($A, $B, gp)($A, $B) }
multi method ip(::?CLASS $A: ::?CLASS $B) { get-block($A, $B, ip)($A, $B) }
multi method op(::?CLASS $A: ::?CLASS $B) { get-block($A, $B, op)($A, $B) }

sub basis-product(UInt $a, UInt $b, Product $op) {
    (state %){"$a $op $b"} //= do {
        my ($A, $B) = map {
            use MultiVector::BitEncoded::Default;
            MultiVector::BitEncoded::Default.new: $^x.MixHash;
        }, $a, $b;
        $A."$op"($B).pairs;
    }
}
sub get-block(::?CLASS $A, ::?CLASS $B, Product $op) returns Block {
    use nqp;
    (state %){
	nqp::sha1( "{$A.basis.join(',')} $op {$B.basis.join(',')}" ); 
    } //= do {
	use MONKEY-SEE-NO-EVAL;
	(
	    my @classif = gather
	    for ^$A.basis -> $i {
		for ^$B.basis -> $j {
		    for @(basis-product($A.basis[$i], $B.basis[$j], $op)) {
			die "unexpected value" unless .value == 1|-1;
			take (.key) => 
			(.value == 1 ?? '+' !! '-') ~
			'$x.reals[' ~$i~ ']*$y.reals['~$j~']';
		    }
		}
	    }.classify(*.key)
	    .map({ (.key) => .value».value.join })
	    .sort(*.key);
	) ?? do {
	    my $code = qq:to /STOP/;
	    -> \$x, \$y \x7b
		\$x.new:
		    :basis[{@classif».key.join(',')}],
		    :reals[{@classif».value.join(',')}]
		;
	    \x7d
	    STOP
	    if %*ENV<DEBUG> {
		note "generated code for $op:";
		note $code;
	    }
	    EVAL $code;
	}
	!! -> $x, $ { $x.new(0) }
    }
}

