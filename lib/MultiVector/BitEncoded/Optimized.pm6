use MultiVector::BitEncoded;
use BasisBlade;
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

my enum Product <gp ip op sp lc dp>;
multi method scale(Real $s) { self.new: :@!basis, :reals[@!reals X* $s] }

method gp($A: ::?CLASS $B) { get-block($A, $B, gp)($A, $B) }
method ip($A: ::?CLASS $B) { get-block($A, $B, ip)($A, $B) }
method op($A: ::?CLASS $B) { get-block($A, $B, op)($A, $B) }
method sp($A: ::?CLASS $B) { get-block($A, $B, sp)($A, $B) }
method lc($A: ::?CLASS $B) { get-block($A, $B, lc)($A, $B) }
method dp($A: ::?CLASS $B) { get-block($A, $B, dp)($A, $B) }

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
	my @classif = gather
	for ^$A.basis -> $i {
	    for ^$B.basis -> $j {
		for @(basis-product($A.basis[$i], $B.basis[$j], $op)) {
		    die "unexpected value" unless .value == 1|-1;
		    take (.key) => ( :sign(.value), :$i, :$j ).Hash
		}
	    }
	}.classify(*.key)
	.map({ (.key) => .value».value })
	.sort(*.key);
	if @classif {
	    my @keys = @classif».key;
	    my @values = @classif».value;
	    -> $x, $y {
		$x.new:
		:basis[@keys],
		:reals[
		    @values.map({
			[+] .map({.<sign>*$x.reals[.<i>]*$y.reals[.<j>]});
		    })
		]
	    }
	} else { -> $x, $y { $x.new(0) } }
    }
}

