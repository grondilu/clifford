unit class Polynomial does Real;
has Mix $.monomials .= new;
method degree { max self.monomials.keys».degree }
my subset Variable of Str where /^^<ident>$$/;
my class Monomial {
    has Bag $.variables handles <WHICH Bool> .= new;
    submethod TWEAK {
        die "unexpected variable name" unless
        self.variables.keys.all ~~ Variable;
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

method constant { self.monomials{Monomial.new} }
submethod TWEAK {
    die "unexpected monomial" unless
    self.monomials.keys.all ~~ Monomial;
}

method Bridge {
    self.monomials.keys.any ??
    NaN !! self.constant
}
multi method Str {
    if self.monomials.none { return ~self.constant }
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
        join(' ',
            $head.value < 0 ?? "-$h" !! $h,
            @t
        ) !!
        join(' ',
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
multi method new(Real $x) {
    self.new: :monomials((Monomial.new => $x).Mix)
}

multi infix:<+>(Polynomial $a, Polynomial $b --> Polynomial) is export {
    Polynomial.new: :monomials($a.monomials (+) $b.monomials);
}
multi infix:<->(Polynomial $a, Polynomial $b --> Polynomial) is export {
    $a + -1*$b
}
multi infix:<*>(Polynomial $a, Polynomial $b --> Polynomial) is export {
    Polynomial.new :monomials(
        gather for $a.monomials.pairs -> $i {
            for $b.monomials.pairs -> $j {
                take $i.key.multiply($j.key) => $i.value*$j.value
            }
        }.Mix
    );
}
multi infix:<*>(Polynomial $a, Real $x --> Polynomial) is export {
    $a * Polynomial.new($x)
}
multi infix:<*>(Real $x, Polynomial $a --> Polynomial) is export {
    $a * Polynomial.new($x)
}
multi infix:</>(Polynomial $a, Real $x --> Polynomial) is export {
    $a * Polynomial.new(1/$x)
}
multi infix:<**>(Polynomial $a, UInt $n --> Polynomial) is export {
    reduce &[*], $a xx $n;
}

multi infix:<+>(Real $x, Polynomial $a --> Polynomial) is export {
    Polynomial.new($x) + $a
}
multi infix:<+>(Polynomial $a, Real $x --> Polynomial) is export {
    Polynomial.new($x) + $a
}
multi infix:<->(Polynomial $a, Real $x --> Polynomial) is export {
    $a - Polynomial.new($x)
}
multi prefix:<->(Polynomial $a --> Polynomial) is export { -1*$a }
multi infix:<->(Real $x, Polynomial $a --> Polynomial) is export {
    $x + -1*$a
}
