use MultiVector::BitEncoded;
use MultiVector::BitEncoded::BasisBlade;
unit class MultiVector::BitEncoded::Default does MultiVector::BitEncoded;

has UIntHash $.bitEncoding;

# Constructors
multi method new(UIntHash $bitEncoding) { self.new: :$bitEncoding }
multi method new(Str $blade) {
    self.new: MultiVector::BitEncoded::BasisBlade.new($blade).pair.MixHash
}

