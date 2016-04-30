use MultiVector::BitEncoded;
use MultiVector::BitEncoded::BasisBlade;
unit class MultiVector::BitEncoded::Optimized does MultiVector::BitEncoded;

has UInt @.basis;
has Real @.reals;
method reals { @!reals }  # overides any previously defined reals method
method bitEncoding { (@!basis Z=> @!reals).MixHash }

method code returns Str { @!basis.join('|') }

submethod BUILD(:@basis, :@reals) {
    fail "expected strictly increasing order in @basis" unless [<] @basis;
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

multi method add(::?CLASS $B) {
    self.new: (self.pairs, |$B.pairs).MixHash;
}
multi method add(Real $s) {
    self.new: (0 => $s, |self.pairs).MixHash;
}

multi method scale(Real $s) { self.new: :@!basis, :reals[@!reals X* $s] }
multi method gp(::?CLASS $A: ::?CLASS $B) { products($A.code, $B.code)<gp>($A, $B) }
multi method ip(::?CLASS $A: ::?CLASS $B) { products($A.code, $B.code)<ip>($A, $B) }
multi method op(::?CLASS $A: ::?CLASS $B) { products($A.code, $B.code)<op>($A, $B) }

sub basis-product(UInt $a, UInt $b) {
    (state @)[$a][$b] //= do {
	my ($A, $B) = map {
	    use MultiVector::BitEncoded::Default;
	    MultiVector::BitEncoded::Default.new: $^x.MixHash;
	}, $a, $b;
	{
	    gp => $A.gp($B).pairs,
	    ip => $A.ip($B).pairs,
	    op => $A.op($B).pairs,
	}
    }
}
sub products(Str $Acode, Str $Bcode) {
    (state %){$Acode}{$Bcode} //= do {
	use MONKEY-SEE-NO-EVAL;
	#note "generating code! (A.code=$Acode, B.code=$Bcode)";
	my %instructions;
	my @Abasis = $Acode.comb(/\d+/).map(*.Int);
	my @Bbasis = $Bcode.comb(/\d+/).map(*.Int);
	for ^@Abasis -> $i {
	    for ^@Bbasis -> $j {
		my $product = basis-product(@Abasis[$i], @Bbasis[$j]);
		for <gp ip op> -> $op {
		    for @($product{$op}) {
			%instructions{$op}{.key} ~=
			(.value == 1 ?? '+' !! '-')~
			"\$x.reals[$i]*\$y.reals[$j]";
		    }
		}
	    }
	}
	do for <gp ip op> -> $op {
	    my @basis = sort %instructions{$op}.keys».Int;
	    @basis ?? do {
		my @reals = %instructions{$op}{@basis};
		$op => EVAL qq:to /STOP/;
		sub (\$x, \$y) \x7b
		\$x.new:
		:basis[{@basis.join(',')}],
		:reals[
		    {@reals.join(",\n        ")}
		];
		\x7d
		STOP
	    } !! ($op => -> $x, $ { $x.new(0) })
	}.Hash;
    }
}

