unit class MultiVector does Numeric;

#--- conversion to Numeric
multi method Numeric(MultiVector:D:) { self.grade == 0 ?? self{0} !! NaN }

#---Basis Vector definitions
subset Sign of Int where { $_ ~~ -1|0|1};
role BasisVector[Sign $square] is export {
    method square { $square }
    method rank(--> Real) {...}
}
class Euclidean does BasisVector[1] {
    has UInt $.index;
    method rank { 2 - 1/(2 + self.index) }
    method Str { "e$!index" }
}
class AntiEuclidean does BasisVector[-1] {
    has UInt $.index;
    method rank { 2 + self.index }
    method Str { "ē$!index" }
}
class No does BasisVector[0] {
    method rank { 0 }
    method Str { "\c[MATHEMATICAL ITALIC SMALL O]" }
}
class Ni does BasisVector[0] {
    method rank { 1 }
    method Str { "∞" }
}

constant @e is export = map { Euclidean    .new: :index($_) }, ^Inf;
constant @ē is export = map { AntiEuclidean.new: :index($_) }, ^Inf;

constant e0 is export = @e[0]; constant ē0 is export = @ē[0];
constant e1 is export = @e[1]; constant ē1 is export = @ē[1];
constant e2 is export = @e[2]; constant ē2 is export = @ē[2];
constant e3 is export = @e[3]; constant ē3 is export = @ē[3];
constant e4 is export = @e[4]; constant ē4 is export = @ē[4];

constant no is export = No.new;
constant ni is export = Ni.new;

class Blade {
    has Set $.frame handles <WHICH> .= new;
    method TWEAK {
        fail "wrong frame" unless $!frame.keys.all ~~ BasisVector;
    }
    method Str { self.frame.keys.sort(*.rank).join('∧') }
    method grade(--> UInt) { $!frame ?? $!frame.total !! 0 }
}

proto wedge($a, $b) is export {*}
multi wedge(BasisVector $a, BasisVector $b where $a.rank < $b.rank --> Blade) {
    Blade.new: :frame(($a, $b).Set)
}
multi wedge(BasisVector $a, BasisVector $b where $a.rank == $b.rank --> Real) { 0 }
multi wedge(BasisVector $a, BasisVector $b where $a.rank > $b.rank --> MultiVector) {
    MultiVector.new: :blades((wedge($b,$a) => -1).Mix)
}

multi wedge(Blade $a, BasisVector $b) {...}

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

#--- Str method candidates
multi method Str($self where $self.grade == 0:) { ~self{0} }
multi method Str($self where $self{0} == 0:) {
    self.blades.pairs
    .sort(*.key.grade)
    .map(
        {
            (.value == -1 ?? "- " !!
            .value == 1  ?? "+ " !!
            .value < 0   ?? "- {.value.abs}" !!
            "+ {.value}*") ~ .key
        }
    ).join(' ')
    .subst(/^'- '/, '-')
    .subst(/^'+ '/, '')
}
multi method Str($self where $self !== 0:) {
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

#--- infix operators
proto infix:<·>(MultiVector $, MultiVector $ --> Real)    is tighter(&infix:<*>) is export {*}
proto infix:<∧>(MultiVector $, MultiVector $ --> Numeric) is tighter(&infix:<·>) is export {*}
multi infix:<+>(MultiVector $a, MultiVector $b --> MultiVector) is export {
    MultiVector.new: :blades($a.blades (+) $b.blades)
}
multi infix:<+>(0, MultiVector $a --> Real) is export { 0 }
multi infix:<+>(1, MultiVector $a --> MultiVector) is export { $a }
multi infix:<+>(Real $a, Blade $b --> MultiVector) is export {
    $a + MultiVector.new: :blades($b.Mix)
}
multi infix:<+>(Real $a, MultiVector $b --> MultiVector) is export {
    MultiVector.new: :blades(
        $b.blades (+)
        (Blade.new => $a).Mix
    );
}
multi prefix:<->(MultiVector $a --> MultiVector) is export { (-1)*$a }
multi infix:</>(MultiVector $a, Real $b --> MultiVector) is export { (1/$b)*$a }
multi infix:<->(MultiVector $a, MultiVector $b --> MultiVector) is export { $a+(-1)*$b }
multi infix:<*>(MultiVector $a, Real $b --> MultiVector) is export { $b*$a }
multi infix:<*>(Real $a, MultiVector $b --> MultiVector) is export {
    MultiVector.new: :blades(
        $b.blades.pairs.map({ .key => .value*$a }).Mix
    )
}

#--- constructor from Real
multi method new(Real $x) {
    self.new:
    :blades((Blade.new(:frame(set())) => $x).Mix)
}

=finish
=END


    multi method multiply($a: MultiVector $b --> MultiVector) {
        MultiVector.new: blades => gather
        for $a.blades.pairs -> $i {
            for $b.blades.pairs -> $j {
                ...
            }
        }
    }

    method Str {
        if self.grade == 0 { return $!blades ?? ~$!blades{Blade.new} !! "0" }
        return self.WHICH;
    }

    multi infix:<+>(MultiVector $a, MultiVector $b --> MultiVector) is export { $b+$a }

    multi infix:<∧>(BasisVector $a, BasisVector $b --> MultiVector) {
        MultiVector.new: :blades(
            (
                (Blade.new: :frame(($a, $b).Set)) =>
                do given $a cmp $b {
                    when Less { 1 }
                    when More { -1 }
                    when Same { 0 }
                    default { !!! }
                }
            ).Mix
        )
    }
