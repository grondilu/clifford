unit module Algebra;
subset Sign of Int where -1|0|1;

role MultiVector is export {}
our proto add      (MultiVector $, MultiVector $ --> MultiVector) {*}
our proto subtract (MultiVector $, MultiVector $ --> MultiVector) {*}
our proto multiply (MultiVector $, MultiVector $ --> MultiVector) {*}
our proto power    (MultiVector $, MultiVector $ --> MultiVector) {*}
our proto cdot     (MultiVector $, MultiVector $ --> MultiVector) {*}
our proto wedge    (MultiVector $, MultiVector $ --> MultiVector) {*}
proto infix:<·>(MultiVector $A, MultiVector $B --> MultiVector) is tighter(&infix:<*>) is export {*}
proto infix:<∧>(MultiVector $A, MultiVector $B --> MultiVector) is tighter(&infix:<*>) is tighter(&infix:<·>) is export {*}

class Monomial          does MultiVector is export {...}
class Polynomial        does MultiVector {...}
class BasisVector       does MultiVector {...}
multi infix:<·>(BasisVector $a, BasisVector $b) {...}

class Monomial {
    has Bag  $.variables;
    submethod TWEAK {
        die "unexpected variable name" unless
        self.variables.keys.all ~~ /^^<ident>$$/;
    }
    method WHICH {
        self.variables
        .pairs
        .sort(*.key)
        .map({
            .key ~
            (
                .value == 1 ?? ""  !!
                .value == 2 ?? "²" !!
                .value == 3 ?? "³" !!
                .value == 4 ?? "⁴" !!
                "**{.value}"
            )
        })
        .join("*")
    }
    method Str { self.WHICH }
}
class Polynomial does Real {
    has Real $.constant = 0;
    has Mix $.monomials;
    method Bridge { $!monomials ?? NaN !! $!constant }
    method constant { $!constant but MultiVector }
    submethod TWEAK {
        die "unexpected monomial" unless
        self.monomials.keys.all ~~ Monomial;
    }
    multi method Str {
        if !$!monomials { return $!constant.Str }
        my Pair ($head, @tail) = self
        .monomials.pairs.sort({.key.Str});

        my $h = $head.value.abs == 1 ?? $head.key !!
        "{$head.value.abs}*{$head.key}";

        my Str @t = @tail.map: {
            .value < 0 && .value !== -1 ??
            "- {.value.abs}*{.key}" !!
            .value == -1 ?? "- {.key}" !!
            .value ==  1 ?? "+ {.key}" !!
            "+ {.value.abs}*{.key}"
        }
        return
            $!constant == 0 ??
            join(' ',
                $head.value < 0 ?? "-$h" !! $h,
                @t
            ) !!
            join(' ',
                $!constant,
                $head.value < 0 ?? "- $h" !! "+ $h",
                @t
            )
    }
}

multi multiply(Real $x, Monomial $m --> Polynomial) {
    Polynomial.new: :monomials(($m => $x).Mix)
}
multi multiply(Monomial $a, Monomial $b --> Monomial) {
    Monomial.new: :variables($a.variables (+) $b.variables)
}

multi subtract(MultiVector $a, MultiVector $b --> MultiVector) {
    add($a, multiply(-1 but MultiVector, $b))
}
multi add(Monomial $a, Monomial $b --> Polynomial) {
    Polynomial.new: :monomials(($a, $b).Mix)
}
multi add(Monomial $a, Polynomial $b --> Polynomial) {
    Polynomial.new:
    :constant($b.constant),
    :monomials(($a => 1, |$b.monomials.pairs).Mix)
}
multi add(Polynomial $a, Monomial $b --> Polynomial) {
    Polynomial.new:
    :constant($a.constant),
    :monomials(($b => 1, |$a.monomials.pairs).Mix)
}
multi add(Polynomial $a, Polynomial $b --> Polynomial) {
    Polynomial.new: :monomials($a.monomials (+) $b.monomials)
}
multi add(Real $x, Polynomial $p --> Polynomial) {
    Polynomial.new: :constant($p.constant + $x), :monomials($p.monomials)
}
multi add(Real $x, Monomial $m --> Polynomial) {
    Polynomial.new: :constant($x), :monomials($m.Mix)
}
multi multiply(Real $x, Polynomial $p --> Polynomial) {
    Polynomial.new: :constant($x*$p.constant),
    :monomials($p.monomials.pairs.map({.key => $x*.value}).Mix)
}

multi multiply(Polynomial $a, Polynomial $b --> Polynomial) {
    Polynomial.new:
    :constant($a.constant*$b.constant),
    :monomials(
        gather {
            take multiply($a.constant, $b).monomials.pairs;
            take multiply($b.constant, $a).monomials.pairs;
            for $a.monomials.pairs -> $ip {
                for $b.monomials.pairs -> $jp {
                    take
                    multiply($ip.key, $jp.key)
                    => $ip.value*$jp.value;
                }
            }
        }.Mix
    )
}

class BasisVector {
    method square(--> Sign) {...}
}

class NormalBasisVector      is BasisVector {...}
class MinkowskiBasisVector   is BasisVector {...}


class NormalBasisVector {}
class EuclideanBasisVector     is NormalBasisVector {...}
class AntiEuclideanBasisVector is NormalBasisVector {...}

class EuclideanBasisVector {
    has UInt $.index handles <WHICH>;
    method square(--> Sign) { 1 but MultiVector }
    method Str { "e$!index" }
}
constant @e is export = map { EuclideanBasisVector.new(:index($_)) }, ^Inf;
constant e0 is export = @e[0];
constant e1 is export = @e[1];
constant e2 is export = @e[2];
constant e3 is export = @e[3];
constant e4 is export = @e[4];

class AntiEuclideanBasisVector {
    has UInt $.index handles <WHICH>;
    method square(--> Sign) { -1 but MultiVector }
    method Str { "ē$!index" }
}
constant @ē is export = map { AntiEuclideanBasisVector.new(:index($_)) }, ^Inf;
constant ē0 is export = @ē[0];
constant ē1 is export = @ē[1];
constant ē2 is export = @ē[2];
constant ē3 is export = @ē[3];
constant ē4 is export = @ē[4];

multi multiply(
    NormalBasisVector $a,
    NormalBasisVector $b where $a === $b
) { return $a.square but MultiVector; }


class MinkowskiBasisVector  {
    has Str $.symbol handles <Str>;
    method square { 0 but MultiVector; }
}
constant no is export = MinkowskiBasisVector.new(:symbol("\x1D45C"));
constant ni is export = MinkowskiBasisVector.new(:symbol('∞'));

multi multiply(no, no) { 0 but MultiVector }
multi multiply(ni, ni) { 0 but MultiVector }

multi infix:<·>(EuclideanBasisVector $, AntiEuclideanBasisVector $) { 0 }
multi infix:<·>(AntiEuclideanBasisVector $, EuclideanBasisVector $) { 0 }
multi infix:<·>(MinkowskiBasisVector $, AntiEuclideanBasisVector $) { 0 }
multi infix:<·>(AntiEuclideanBasisVector $, MinkowskiBasisVector $) { 0 }
multi infix:<·>(EuclideanBasisVector $a, EuclideanBasisVector $b) {
    $a.index == $b.index ?? $a.square !! 0
}
multi infix:<·>(AntiEuclideanBasisVector $a, AntiEuclideanBasisVector $b) {
    $a.index == $b.index ?? $a.square !! 0
}
multi infix:<∧>(BasisVector $a, BasisVector $b --> MultiVector) {...}
multi multiply(BasisVector $a, BasisVector $b --> MultiVector) {
    $a·$b + $a∧$b
}

class Blade does MultiVector {
    has Set $.frame;
    submethod TWEAK {
        die "unexpected element in frame"
        unless self.frame.keys.all ~~ BasisVector;
    }
    method WHICH { self.frame.keys».Str.sort.join('∧') }
    method Str { self.WHICH }
}

multi infix:<∧>(
    BasisVector $a,
    BasisVector $b where $a leg $b ~~ Less
) { Blade.new: :frame(($a, $b).Set) }
multi infix:<∧>(
    BasisVector $a,
    BasisVector $b where $a leg $b ~~ Same
) { 0 but MultiVector }

class PolyBlade does MultiVector {
    has Real $.constant = 0;
    has Mix $.blades;
    submethod TWEAK {
        die "polyblades should only mix blades"
        unless $!blades.keys.all ~~ Blade;
    }
    method Str {
        my Pair ($head, @tail) = self.blades.pairs;

        my Str $h =
        $head.value ==  1 ?? "{$head.key}" !!
        $head.value == -1 ?? "-{$head.key}" !!
        "{$head.value}*{$head.key}";

        my Str @t = @tail.map: {
            .value < 0 && .value !== -1 ??
            "- {.value.abs}*{.key}" !!
            .value == -1 ?? "- {.key}" !!
            .value ==  1 ?? "+ {.key}" !!
            "+ {.value.abs}*{.key}"
        }
        my Str $ht = join(' ', $h, |@t);
        return $!constant == 0 ?? $ht !!
        "$!constant + $ht";
    }
}
multi infix:<∧>(
    BasisVector $a,
    BasisVector $b where $a leg $b ~~ More
) { PolyBlade.new: :blades(($b∧$a => -1).Mix) }


multi infix:<+>(MultiVector $a, MultiVector $b --> MultiVector) is export { add($a, $b); }
multi infix:<->(MultiVector $a, MultiVector $b --> MultiVector) is export { subtract($a, $b); }
multi infix:<*>(MultiVector $a, MultiVector $b --> MultiVector) is export { multiply($a, $b); }
multi prefix:<->(MultiVector $M --> MultiVector) is export { -1*$M }
multi prefix:<+>(MultiVector $M --> MultiVector) is export { $M }
multi infix:<+>(0, MultiVector $M --> MultiVector) is export { $M }
multi infix:<+>(MultiVector $M, 0 --> MultiVector) is export { $M }
multi infix:<->(MultiVector $M, 0 --> MultiVector) is export { $M }
multi infix:<->(0, MultiVector $M --> MultiVector) is export { -1*$M }
multi infix:<*>(1, MultiVector $M --> MultiVector) is export { $M }
multi infix:<*>(MultiVector $M, 1 --> MultiVector) is export { $M }
multi infix:<*>(0, MultiVector $M) is export { 0 }
multi infix:<*>(Real $x, MultiVector $M --> MultiVector) is export {
    multiply($x but MultiVector, $M);
}
multi infix:<*>(MultiVector $M, Real $x --> MultiVector) is export {
    multiply($x but MultiVector, $M);
}
multi infix:</>(MultiVector $M, Real $x --> MultiVector) is export {
    multiply(1/$x but MultiVector, $M);
}
multi infix:<**>(MultiVector $M, UInt $n --> MultiVector) is export {
    reduce(&multiply, $M xx $n);
}

multi infix:<+>(Real $constant, Monomial $b --> Polynomial) is export {
    Polynomial.new: :$constant, :monomials($b.Mix)
}
multi infix:<->(Monomial $b, Real $constant --> Polynomial) is export {
    Polynomial.new: :constant(-$constant), :monomials($b.Mix)
}
multi infix:<->(Real $constant, Monomial $b --> Polynomial) is export {
    Polynomial.new: :$constant, :monomials(($b => -1).Mix)
}
sub prefix:<v>(Pair $p where $p.value === True --> Monomial) is export {
    Monomial.new: :variables($p.key.Bag)
}
