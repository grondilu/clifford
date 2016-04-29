use MultiVector::BitEncoded;
unit class MultiVector::BitEncoded::Optimized does MultiVector::BitEncoded;

has UInt $.basis-code;
has UInt @.basis;
has Real @.coeff;

submethod BUILD(UInt :$basis-code, :@coeff) {
    $!basis-code = $basis-code;
    @!coeff = @coeff;

    # build @!basis
    my $b = $!basis-code;
    my int $i = 0;
    while $b > 0 { 
	push @!basis, $i if $b +& 1;
	$i++; $b +>= 1;
    }
    fail "basis-code contains more elements than there are coefficients"
    unless @!basis == @coeff;
}
multi method new(MultiVector::BitEncoded $model) {
    my UInt $basis-code;
    my @coeff = do for $model.pairs {
	$basis-code +|= (1 +< .key);
	.value;
    }
    self.bless: :$basis-code, :@coeff;
}
method bitEncoding { (@!basis Z=> @!coeff).MixHash }
