use MultiVector::BitEncoded;
use MultiVector::BitEncoded::BasisBlade;
unit class MultiVector::BitEncoded::Default does MultiVector::BitEncoded;

has UIntHash $.bitEncoding;

# Constructors required by roles
multi method new(Real $s) { self.new: :bitEncoding((0 => $s).MixHash) }
multi method new(UIntHash $bitEncoding) { self.new: :$bitEncoding }

multi method add(::?CLASS $A) { self.new: (flat self.pairs, $A.pairs).MixHash }
multi method add(Real $s) { self.new: (0 => $s, |self.pairs).MixHash }

multi method scale(Real $s) {
    self.new: self.pairs.map({ Pair.new: .key, $s*.value }).MixHash
}

my %product;
method gp(::?CLASS $A) { %product<gp>(self, $A) }
method ip(::?CLASS $A) { %product<ip>(self, $A) }
method op(::?CLASS $A) { %product<op>(self, $A) }

%product = <gp ip op> Z=>
map -> &basis-blade-product {
    -> $A, $B {
	my @a = (|.push-to-diagonal-basis for $A.basis-blades);
	my @b = (|.push-to-diagonal-basis for $B.basis-blades);
	$A.new: do for @a -> $a {
	    |do for @b -> $b {
		&basis-blade-product($a, $b);
	    }
	}.map(&MultiVector::BitEncoded::BasisBlade::pop-from-diagonal-basis).flat.MixHash;
    }
}, 
# work around #128010
{ MultiVector::BitEncoded::BasisBlade::geometric-product($^a, $^b) },
{ MultiVector::BitEncoded::BasisBlade::inner-product($^a, $^b) },
{ MultiVector::BitEncoded::BasisBlade::outer-product($^a, $^b) };
