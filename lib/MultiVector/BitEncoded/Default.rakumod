use MultiVector::BitEncoded;
use BasisBlade;
unit class MultiVector::BitEncoded::Default does MultiVector::BitEncoded;

has UIntHash $.bitEncoding;

# Constructors required by roles
multi method new(Real $s) returns MultiVector { self.new: :bitEncoding((0 => $s).MixHash) }
multi method new(UIntHash $bitEncoding) { self.new: :$bitEncoding }

multi method add(::?CLASS $A) { self.new: (flat self.pairs, $A.pairs).MixHash }
multi method add(Real $s) { self.new: (0 => $s, |self.pairs).MixHash }

multi method scale(Real $s) returns MultiVector {
    self.new: self.pairs.map({ Pair.new: .key, $s*.value }).MixHash
}

my %product;
method gp(::?CLASS $A) { %product<gp>(self, $A) }
method ip(::?CLASS $A) { %product<ip>(self, $A) }
method op(::?CLASS $A) { %product<op>(self, $A) }
method sp(::?CLASS $A) { %product<sp>(self, $A) }
method lc(::?CLASS $A) { %product<lc>(self, $A) }
method dp(::?CLASS $A) { %product<dp>(self, $A) }

%product = <gp> Z=>
map -> &basis-blade-product {
    -> $A, $B {
	my @a = $A.basis-blades;
	my @b = $B.basis-blades;
	$A.new: do for @a -> $a {
	    |do for @b -> $b {
	      note &basis-blade-product($a, $b).raku;
	      &basis-blade-product($a, $b);
	    }
	}
	.flat
	.map(*.pair)
	.MixHash;
    }
}, 
{ $^a.geometric-product($^b) };
