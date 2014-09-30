module Clifford::Conformal;

class MultiVector is Cool is Numeric {
    # This class is written exactly as Complex is in Rakudo's core,
    # except there are not two member variables, but 32.
    #
    # Why 32?  Because we're in the 5D conformal space, whose dimension is
    # 2**5 = 32.
    has num (
	$.re,
	$.x0, $.x1, $.x2, $.x3, $.x4,
	$.x01, $.x02, $.x03, $.x04, $.x12, $.x13, $.x14, $.x23, $.x24, $.x34,
	$.x012, $.x013, $.x014, $.x023, $.x024, $.x034, $.x123, $.x124, $.x134, $.x234,
	$.x0123, $.x0124, $.x0134, $.x0234, $.x1234,
	$.x01234
    );
    
    #
    # methods for the Numeric role
    #
    multi method new(
	Real \re,
	Real \x0, Real \x1, Real \x2, Real \x3, Real \x4,
	Real \x01, Real \x02, Real \x03, Real \x04, Real \x12, Real \x13, Real \x14, Real \x23, Real \x24, Real \x34,
	Real \x012, Real \x013, Real \x014, Real \x023, Real \x024, Real \x034, Real \x123, Real \x124, Real \x134, Real \x234,
	Real \x0123, Real \x0124, Real \x0134, Real \x0234, Real \x1234,
	Real \x01234
    ) {
        my $new = nqp::create(self);
	$new.BUILD(
	    re.Num,
	    x0.Num, x1.Num, x2.Num, x3.Num, x4.Num,
	    x01.Num, x02.Num, x03.Num, x04.Num, x12.Num, x13.Num, x14.Num, x23.Num, x24.Num, x34.Num,
	    x012.Num, x013.Num, x014.Num, x023.Num, x024.Num, x034.Num, x123.Num, x124.Num, x134.Num, x234.Num,
	    x0123.Num, x0124.Num, x0134.Num, x0234.Num, x1234.Num,
	    x01234.Num
	);
        $new;
    }
    method BUILD(
	Num \re,
	Num \x0, Num \x1, Num \x2, Num \x3, Num \x4,
	Num \x01, Num \x02, Num \x03, Num \x04, Num \x12, Num \x13, Num \x14, Num \x23, Num \x24, Num \x34,
	Num \x012, Num \x013, Num \x014, Num \x023, Num \x024, Num \x034, Num \x123, Num \x124, Num \x134, Num \x234,
	Num \x0123, Num \x0124, Num \x0134, Num \x0234, Num \x1234,
	Num \x01234
    ) {
	$!re = re;
	$!x0 = x0; $!x1 = x1; $!x2 = x2; $!x3 = x3; $!x4 = x4;
	$!x01 = x01; $!x02 = x02; $!x03 = x03; $!x04 = x04; $!x12 = x12; $!x13 = x13; $!x14 = x14; $!x23 = x23; $!x24 = x24; $!x34 = x34;
	$!x012 = x012; $!x013 = x013; $!x014 = x014; $!x023 = x023; $!x024 = x024; $!x034 = x034; $!x123 = x123; $!x124 = x124; $!x134 = x134; $!x234 = x234;
	$!x0123 = x0123; $!x0124 = x0124; $!x0134 = x0134; $!x0234 = x0234; $!x1234 = x1234;
	$!x01234 = x01234;
    }
    method reals(MultiVector:D:) {
	(
	    self.re,
	    self.x0, self.x1, self.x2, self.x3, self.x4,
	    self.x01, self.x02, self.x03, self.x04, self.x12, self.x13, self.x14, self.x23, self.x24, self.x34,
	    self.x012, self.x013, self.x014, self.x023, self.x024, self.x034, self.x123, self.x124, self.x134, self.x234,
	    self.x0123, self.x0124, self.x0134, self.x0234, self.x1234,
	    self.x01234
	);
    }

    method isNaN(MultiVector:D:) {
	[||] self.reals».isNaN;
    }

    method coerce-to-real(MultiVector:D: $exception-target) {
        unless self.reals[1..*].all == 0 { fail X::Numeric::Real.new(target => $exception-target, reason => "imaginary part not zero", source => self);}
        $!re;
    }
    multi method Real(MultiVector:D:) { self.coerce-to-real(Real); }

    # should probably be eventually supplied by role Numeric
    method Num(MultiVector:D:) { self.coerce-to-real(Num).Num; }
    method Int(MultiVector:D:) { self.coerce-to-real(Int).Int; }
    method Rat(MultiVector:D:) { self.coerce-to-real(Rat).Rat; }

    multi method Bool(MultiVector:D:) {
	[||] self.reals X[!=] 0e0; 
    }

    method MultiVector() { self }
    multi method Str(MultiVector:D:) {
	my $re = nqp::p6box_s($!re);
	self.reals[1..*].all == 0e0 ?? $re !!
	join ' + ',
	($re == 0e0 ?? Nil !! $re),
	map -> $x {
	    my $blade = shift state @ = <
		e0 e1 e2 e3 e4
		e01 e02 e03 e04 e12 e13 e14 e23 e24 e34
		e012 e013 e014 e023 e024 e034 e123 e124 e134 e234
		e0123 e0124 e0134 e0234 e1234
		e01234
	    >;
	    my Str $slash = nqp::isnanorinf($x) ?? "\\" !! '';
	    $x == 0e0 ?? Nil !!
	    $x == 1e0 ?? $slash~$blade !!
	    $x < 0e0
	    ?? '-' ~ $x.abs ~ $slash ~ $blade
	    !! "$x$blade"
	}, self.reals[1..*];
    }

    multi method perl(MultiVector:D:) {
        "MultiVector.new({self.reals.join(', ')})";
    }
    method conj(MultiVector:D:) {
	MultiVector.new: |(
	    (1, -1 xx 5, 1 xx 10, -1 xx 10, 1 xx 5, -1) Z* self.reals
	);
    }
    method abs(MultiVector:) {
	my num $sum = 0e0;
	$sum = nqp::add_n( $sum, nqp::mul_n($_, $_) ) for self.reals;
        nqp::p6box_n(nqp::sqrt_n($sum));
    }

    method floor(MultiVector:D:) {
        MultiVector.new( |map *.floor, self.reals );
    }

    method ceiling(MultiVector:D:) {
        MultiVector.new( |map *.ceiling, self.reals );
    }

    proto method round(|) {*}
    multi method round(MultiVector:D: $scale as Real = 1) {
        MultiVector.new( |map *.round($scale), self.reals );
    }

    method truncate(MultiVector:D:) {
        MultiVector.new( |map *.truncate, self.reals );
    }

    method narrow(MultiVector:D:) {
        self.reals[1..*].all == 0e0
            ?? $!re.narrow
            !! self;
    }

}

proto e(Int $n?) returns MultiVector is export {*}
multi e() { MultiVector.new: 1, |(0 xx 31) }
multi e($n where $n ~~ ^5) {
    my @arg = 0, (map { $_ == $n ?? 1 !! 0 }, ^5), 0 xx 26;
    die "unexpected number of arg ({@arg.elems})" unless @arg == 32;
    MultiVector.new: |@arg;
}

# vim: ft=perl6
