unit module Clifford;
#--- Algebra
role Algebra {

    multi method new(Real $ --> ::?CLASS) {...}

    proto method add($) {*}
    multi method add(Real $x) { self.add(self.new($x)) }
    multi method add(0) { self }
    multi method add(::?CLASS $) {...}

    proto method multiply($) {*}
    multi method multiply(0) { 0 }
    multi method multiply(1) { self }
    multi method multiply(::?CLASS $) {...}
    multi method multiply(Real $x) { self.multiply(self.new($x)) }

}

multi prefix:<->(Algebra $a) is export { (-1)*$a }
multi infix:<+>(Algebra $a) is export { $a }
multi infix:<+>(Algebra $a, Algebra $b) is export { $a.add($b) }
multi infix:<+>(Algebra $a, Real $b) is export { $a.add($b) }
multi infix:<+>(Real $a, Algebra $b) is export { $b.add($a) }
multi infix:<->(Algebra $a, Algebra $b) is export { $a.add($b.multiply(-1)) }

multi infix:<*>(Algebra $a) is export { $a }
multi infix:<*>(Algebra $a, Algebra $b) is export { $a.multiply($b) }
multi infix:<*>(Real $a, Algebra $b) is export { $b.multiply($a) }
multi infix:<*>(Algebra $a, Real $b) is export { $a.multiply($b) }
multi infix:</>(Algebra $a, Real $b) is export { $a.multiply(1/$b) }

multi infix:<**>(Algebra $a, 0) is export { 1 }
multi infix:<**>(Algebra $a, 1) is export { $a }
multi infix:<**>(Algebra $a, UInt $n) is export { ($a*$a)**($n div 2) * $a**($n mod 2) }

#--- Polynomial
class Polynomial does Algebra {
    has Mix $.monomials .= new;
    method degree { max self.monomials.keys».degree }
    my subset Variable of Str where /^^<ident>$$/;
    my class Monomial {
        has Bag $.variables handles <WHICH Bool> .= new;
        submethod TWEAK {
            die "unexpected variable name" unless
            self.variables.keys.all ~~ Variable;
        }
        method CALL-ME(*%args) {
            [*] self.variables.pairs.map:
            { %args{.key} ?? %args{.key}**.value !! 1 }
        }
        method degree { $!variables.total }
        method Str {
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
        method add($a: Monomial $b --> Polynomial) {
            Polynomial.new: :monomials(($a, $b).Mix)
        }
        method multiply($a: Monomial $b --> Monomial) {
            Monomial.new: :variables($a.variables (+) $b.variables)
        }
    }

    multi method closure() {
        my Set $vars = self.monomials.pairs
        .map(*.key.variables.Set)
        .reduce(&[(+)])
        .Set;
        sub (*%args) {
            fail "missing or extraneous arguments"
            unless %args.keys.Set == $vars;
            [+] gather for self.monomials.pairs {
                take .value * .key.(|%args)
            }
        }
    }
    method constant { self.monomials{Monomial.new} }
    submethod TWEAK {
        die "unexpected monomial" unless
        self.monomials.keys.all ~~ Monomial;
    }

    multi method Str {
        if self.degree == 0 { return ~self.constant }
        my Pair ($head, @tail) = self
        .monomials
        .pairs.grep(*.key.degree > 0)
        .sort({.key.Str});

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
        self.constant == 0 ??
        join(
            ' ',
            $head.value < 0 ?? "-$h" !! $h,
            @t
        ) !!
        join(
            ' ',
            self.constant,
            $head.value < 0 ?? "- $h" !! "+ $h",
            @t
        )
    }
    multi method new(Variable $x) {
        self.new: :monomials(
            Monomial.new(:variables($x.Bag)).Mix
        );
    }
    #--- constructor from Real (required by Algebra)
    multi method new(Real $x) {
        self.new: :monomials((Monomial.new => $x).Mix)
    }

    multi method add(Polynomial $b --> Polynomial) {
        self.new: :monomials(self.monomials (+) $b.monomials);
    }
    multi method multiply(Polynomial $b --> Polynomial) {
        self.new :monomials(
            gather for self.monomials.pairs -> $i {
                for $b.monomials.pairs -> $j {
                    take $i.key.multiply($j.key) => $i.value*$j.value
                }
            }.Mix
        );
    }
}

#--- class predeclarations
class Blade {...}
class MultiVector does Algebra {...}
subset Vector of MultiVector where *.grade == 1;

#--- infix operators prototypes
proto infix:<·>(MultiVector $, MultiVector $   --> Real       ) is tighter(&infix:<*>) is tighter(&[*]) is export {*}
proto infix:<∧>(MultiVector $, MultiVector $x? --> MultiVector) is tighter(&infix:<·>) is export {*}

#--- Basis Vector definitions
subset Sign of Int where { $_ ~~ -1|0|1 };
role BasisVector[Sign $square] is export {
    method square { $square }
    method rank(--> Real) {...}
    method Blade(--> Blade) { Blade.new: :frame(self.Set); }
    method MultiVector(--> MultiVector) { self.Blade.MultiVector; }
}
class Euclidean does BasisVector[1] {
    has $.index where UInt|Inf;
    method rank { 1 - 1/(2 + self.index) }
    method Str { "e$!index" }
}
class AntiEuclidean does BasisVector[-1] {
    has $.index where UInt|Inf;
    method rank { 2 + self.index }
    method Str { "ē$!index" }
}
our class No does BasisVector[0] {
    method rank { -1 }
    method Str { "\c[MATHEMATICAL ITALIC SMALL O]" }
}
our class Ni does BasisVector[0] {
    method rank { 0 }
    method Str { "∞" }
}

class Blade {
    has Set $.frame handles <WHICH> .= new;
    method TWEAK {
        fail "wrong frame" unless $!frame.keys.all ~~ BasisVector;
    }
    method Str { self.frame.keys.sort(*.rank).join('∧') }
    method grade(--> UInt) { $!frame ?? $!frame.total !! 0 }

    method MultiVector(--> MultiVector) {
        MultiVector.new: :blades(self.Mix);
    }
}

proto wedge($a, $b) {*}
multi wedge(BasisVector $a, BasisVector $b where $a.rank < $b.rank --> Blade) {
    Blade.new: :frame(($a, $b).Set);
}
multi wedge(BasisVector $a, BasisVector $b where $a.rank == $b.rank --> Real) { 0 }
multi wedge(BasisVector $a, BasisVector $b where $a.rank > $b.rank --> MultiVector) {
    MultiVector.new: :blades((wedge($b,$a) => -1).Mix)
}

multi wedge(Blade $a, Blade $b where ?($a.frame (&) $b.frame) --> Real) { 0 }
multi wedge(Blade $a, Blade $b where !($a.frame (&) $b.frame) --> MultiVector) {
    MultiVector.new: :blades(
        (
            (Blade.new: :frame($a.frame (|) $b.frame)) =>
            (-1)**(
                [+] gather for $b.frame.keys {
                    take +$a.frame.keys.grep(*.rank > .rank)
                }
            )
        ).Mix
    )
}

proto cdot(BasisVector $a, BasisVector $b --> Real) {*}
multi cdot(Euclidean $, AntiEuclidean $ --> Real) { 0 }
multi cdot(AntiEuclidean $, Euclidean $ --> Real) { 0 }
multi cdot(No $,     Euclidean $ --> Real) { 0 }
multi cdot(Euclidean $,     No $ --> Real) { 0 }
multi cdot(No $, AntiEuclidean $ --> Real) { 0 }
multi cdot(AntiEuclidean $, No $ --> Real) { 0 }
multi cdot(Ni $,     Euclidean $ --> Real) { 0 }
multi cdot(Euclidean $,     Ni $ --> Real) { 0 }
multi cdot(Ni $, AntiEuclidean $ --> Real) { 0 }
multi cdot(AntiEuclidean $, Ni $ --> Real) { 0 }
multi cdot(No $, Ni $ --> Real) { -1 }
multi cdot(Ni $, No $ --> Real) { -1 }
multi cdot(No $, No $ --> Real) { 0 }
multi cdot(Ni $, Ni $ --> Real) { 0 }
multi cdot(BasisVector $a, BasisVector $b --> Real) {
    $a.rank == $b.rank ?? $a.square !! 0
}

proto multiply($a, $b --> MultiVector) {*}
multi multiply(Blade $a, Blade $b --> MultiVector) {
    my Bag $bag = $a.frame (+) $b.frame;
    MultiVector.new: blades =>
    (
        Blade.new(
            :frame($bag.pairs.grep(*.value < 2)».key.Set)
        ) => [*] |(
            $bag
            .pairs
            .grep(*.value == 2)
            .map(*.key.square)
        ),
        (-1)**(
            [+] gather for $b.frame.keys {
                take +$a.frame.keys.grep(*.rank > .rank)
            }
        )
    ).Mix
}

#--- basis vectors arrays
our @e = map {     Euclidean.new(:$^index).MultiVector }, ^Inf;
our @ē = map { AntiEuclidean.new(:$^index).MultiVector }, ^Inf;

#--- Minkowskii space basis vectors
our $eInf =     Euclidean.new(:index(Inf));
our $ēInf = AntiEuclidean.new(:index(Inf));

#--- exported "constants"
sub term:<e0> is export { @e[0] }
sub term:<e1> is export { @e[1] }
sub term:<e2> is export { @e[2] }
sub term:<e3> is export { @e[3] }
sub term:<e4> is export { @e[4] }

sub term:<e∞> { $eInf.MultiVector }
sub term:<ē∞> { $ēInf.MultiVector }

sub term:<ē0> is export { @ē[0] }
sub term:<ē1> is export { @ē[1] }
sub term:<ē2> is export { @ē[2] }
sub term:<ē3> is export { @ē[3] }
sub term:<ē4> is export { @ē[4] }

# ο = (e∞ + ē∞)/2
# ∞ = ē∞ - e∞
#
# e∞ = o - ∞/2
# e∞ = o + ∞/2
sub term:<no> is export { state $ = (e∞ + ē∞)/2 }
sub term:<ni> is export { state $ = ē∞ - e∞ }

#--- MultiVector
class MultiVector {
    subset Homogeneous of MultiVector where {
        .blades
        .map(|*.key)
        .map(|*.frame.keys)
        .map(*.square)
        .any == 0
    }
    subset Heterogeneous of MultiVector where {
        $_ !~~ Homogeneous and
        .blades
        .map(|*.key)
        .map(|*.frame.keys)
        .map(*.index)
        .any == Inf
    }

    has Mix $.blades;
    submethod TWEAK { fail "unexpected blade" unless $!blades.keys.all ~~ Blade; }

    #--- grade method
    method grade(--> Int) { max 0, |self.blades.keys.map(*.grade) }

    #--- grade projection
    multi method AT-KEY(0 --> Real) { $!blades{Blade.new: :frame(set())} || 0 }
    multi method AT-KEY(UInt $n --> MultiVector) {
        MultiVector.new: :blades(
            $!blades.pairs.grep({ .key.grade == $n })
            .Mix
        );
    }

    multi method add(MultiVector $b --> MultiVector) {
        MultiVector.new: :blades(self.blades (+) $b.blades)
    }
    multi method multiply(Real $a --> MultiVector) {
        MultiVector.new: :blades(
            self.blades.pairs
            .map({ .key => $a*.value })
            .Mix
        );
    }
    multi method multiply(Vector $a, Vector $b --> MultiVector) { $a·$b + $a∧$b }
    multi method multiply(MultiVector $b --> MultiVector) {
        [+] gather for self.blades.pairs -> $i {
            for $b.blades.pairs -> $j {
                take $i.value*$j.value*
                multiply($i.key, $j.key)
            }
        }
    }

    #--- narrowing method
    method narrow { self.rank == 0 ?? self{0}.narrow !! self }

    #--- constructor from Real (required by Algebra)
    multi method new(Real $x) {
        self.new: :blades((Blade.new(:frame(set())) => $x).Mix)
    }

    my $no = No.new.MultiVector;
    my $ni = Ni.new.MultiVector;

    #--- Str method candidates
    multi method Str(Heterogeneous:) {
        ([+] gather for self.blades.pairs {
            my $a = Blade.new(:frame(
                .key.frame.keys.grep(*.square > 0).Set (-) $eInf.Set
            )).MultiVector;
            if $eInf ∈ .key.frame { $a = $a∧($no - $ni/2) }
            $a = $a∧Blade.new(:frame(
                .key.frame.keys.grep(*.square < 0).Set (-) $ēInf.Set
            )).MultiVector;
            if $ēInf ∈ .key.frame { $a = $a∧($no + $ni/2) }
            take .value*$a;
        }).Str;
    }
    multi method Str($self where $self.grade == 0:) { ~self{0} }
    multi method Str($self where $self{0} == 0:) {
        self.blades.pairs
        .sort(*.key.grade)
        .map(
            {
                (.value == -1 ?? "- " !!
                .value == 1  ?? "+ " !!
                .value < 0   ?? "- {.value.abs}*" !!
                "+ {.value}*") ~ .key
            }
        ).join(' ')
        .subst(/^'- '/, '-')
        .subst(/^'+ '/, '')
    }
    multi method Str($self where $self{0} !== 0:) {
        self{0} ~ ' ' ~
        self.blades.pairs
        .grep(*.key.frame)
        .sort(*.key.grade)
        .map(
            {
                (.value == -1 ?? "- " !!
                .value == 1  ?? "+ " !!
                .value < 0   ?? "- {.value.abs}" !!
                "+ {.value}*") ~ .key
            }
        ).join(' ')
    }
}

#--- infix operators
multi infix:<·>(Vector $a, Vector $b --> Real) {
    [+] gather for $a.blades.pairs -> $i {
        for $b.blades.pairs -> $j {
            fail "unexpected blade" unless $i.key.grade == $j.key.grade == 1;
            take $i.value*$j.value* cdot($i.key.frame.keys[0], $j.key.frame.keys[0]);
        }
    }
}
multi infix:<∧>(MultiVector $a --> MultiVector) { $a }
multi infix:<∧>($a, $b --> MultiVector) {
    [+] gather for $a.blades.pairs -> $i {
        for $b.blades.pairs -> $j {
            take $i.value*$j.value*wedge($i.key,$j.key)
        }
    }
}

