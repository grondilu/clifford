use MultiVector::BitEncoded;
unit class MultiVector::BitEncoded::Optimized does MultiVector::BitEncoded;

has UInt @.basis;
has Real @.coeff;
method code returns Str { @!basis.join('|') }

submethod BUILD(:@basis, :@coeff) {
    @!coeff = @coeff;
    @!basis = @basis;

    fail "basis unit multivectors should be given in increasing order"
    unless [<] @!basis;
    fail "basis contains more elements than there are coefficients"
    unless @!basis == @coeff;
}
multi method new(MultiVector::BitEncoded $model) {
    my @pairs = sort *.key, $model.pairs;
    self.bless:
    :basis[@pairs».key],
    :coeff[@pairs».value];
}
method bitEncoding { (@!basis Z=> @!coeff).MixHash }
multi method new(MixHash $bitEncoding where .keys.all ~~ UInt) {
    my @basis = sort $bitEncoding.keys;
    self.new: :@basis, :coeff[$bitEncoding{@basis}];
}

multi method add(::?CLASS $B) {
    self.new: (self.pairs, |$B.pairs).MixHash;
}
multi method add(Real $s) {
    self.new: (0 => $s, |self.pairs).MixHash;
}


multi method scale(Real $s) { self.new: :@!basis, :coeff[@!coeff X* $s] }
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
			"\$x.coeff[$i]*\$y.coeff[$j]";
		    }
		}
	    }
	}
	do for <gp ip op> -> $op {
	    my @basis = sort %instructions{$op}.keys».Int;
	    @basis ?? do {
		my @coeff = %instructions{$op}{@basis};
		$op => EVAL qq:to /STOP/;
		sub (\$x, \$y) \x7b
		MultiVector::BitEncoded::Optimized.new:
		:basis[{@basis.join(',')}],
		:coeff[
		    {@coeff.join(",\n        ")}
		];
		\x7d
		STOP
	    } !! ($op => -> $, $ { 0 })
	}.Hash;
    }
}

