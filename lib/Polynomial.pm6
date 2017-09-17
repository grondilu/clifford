unit class Polynomial;
has Real $.constant = 0;
has Mix $.monomials;

my subset Variable of Str where /^^<ident>$$/;
my class Monomial {
    has Bag  $.variables;
    submethod TWEAK {
        die "unexpected variable name" unless
        self.variables.keys.all ~~ Variable;
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
    method add($a: Monomial $b --> Polynomial) {
        Polynomial.new: :monomials(($a, $b).Mix)
    }
    method multiply($a: Monomial $b --> Monomial) {
        Monomial.new: :variables($a.variables (+) $b.variables)
    }
}

method Bridge { $!monomials ?? NaN !! $!constant }
method constant { $!constant }
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
multi method new(Variable $x) {
    self.new: :monomials(
        Monomial.new(:variables($x.Bag)).Mix
    );
}

method add($a: Polynomial $b --> Polynomial) {
    self.new:
    :constant($a.constant + $b.constant),
    :monomials($a.monomials (+) $b.monomials)
}
multi method multiply(Real $x --> Polynomial) {
    self.new:
    :constant($!constant * $x),
    :monomials($!monomials.pairs.map({.key => $x*.value}).Mix)
}

multi method multiply($a: Polynomial $b --> Polynomial) {
    Polynomial.new:
    :constant($a.constant*$b.constant),
    :monomials(
        gather {
            take $b.multiply($a.constant).monomials.pairs;
            take $a.multiply($b.constant).monomials.pairs;
            for $a.monomials.pairs -> $ip {
                for $b.monomials.pairs -> $jp {
                    take
                    $ip.key.multiply($jp.key)
                    => $ip.value*$jp.value;
                }
            }
        }.Mix
    )
}

multi infix:<+>(Polynomial $a, Polynomial $b --> Polynomial) is export {
    $a.add($b);
}
multi infix:<->(Polynomial $a, Polynomial $b --> Polynomial) is export {
    $a.add($b.multiply(-1));
}
multi infix:<*>(Polynomial $a, Polynomial $b --> Polynomial) is export {
    $a.multiply($b);
}
multi infix:<*>(Polynomial $a, Real $x --> Polynomial) is export {
    $a.multiply($x);
}
multi infix:<*>(Real $x, Polynomial $a --> Polynomial) is export {
    $a.multiply($x);
}
multi infix:</>(Polynomial $a, Real $x --> Polynomial) is export {
    $a.multiply(1/$x);
}
multi infix:<**>(Polynomial $a, UInt $n --> Polynomial) is export {
    reduce { $^a.multiply($^b) }, $a xx $n;
}

multi infix:<+>(Real $x, Polynomial $a --> Polynomial) is export {
    Polynomial.new:
    :constant($a.constant + $x),
    :monomials($a.monomials);
}
multi infix:<+>(Polynomial $a, Real $x --> Polynomial) is export {
    Polynomial.new:
    :constant($a.constant + $x),
    :monomials($a.monomials);
}
multi infix:<->(Polynomial $a, Real $x --> Polynomial) is export {
    Polynomial.new:
    :constant($a.constant - $x),
    :monomials($a.monomials);
}
multi prefix:<->(Polynomial $a --> Polynomial) is export { -1*$a }
multi infix:<->(Real $x, Polynomial $a --> Polynomial) is export {
    $x + -1*$a
}
