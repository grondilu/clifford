unit class Polynomial is Mix does Callable;

subset Monomial of ::?CLASS where { .elems == 1 }
subset RealMono of Monomial where { .degree == 0 }

multi method gist($ where *.elems == 0:) { "0" }
multi method gist(RealMono:) { .Real.gist }
multi method gist {
  self.monomials.sort(*.degree)
    .map(
    {
      .degree == 0 ?? ~.Real !!
      (
      (
	.value == 1 ?? '' !!
	.value == -1 ?? '-' !!
	"{.value}*"
      )
      ~ [~]
      .key.pairs.map({ "{.key}{.value == 1 ?? '' !! .value.trans: 0..9 => <¹ ² ³ ⁴ ⁵ ⁶ ⁷ ⁸ ⁹>}" })
      .join('*')
      )
    }
    ).join('+')
    .subst('+-', '-', :g)

}

subset Indeterminate of Pair is export where { .value ~~ Bool }

multi method CALL-ME(Monomial: *%h) returns Real {
  self.value * [*] self.key.pairs.map: { %h{.key}**.value }
}
multi method CALL-ME(*%h) returns Real {
  [+] self.monomials.map: { .(|%h) }
}

multi prefix:<+>(Indeterminate $x) returns Monomial is export { ::?CLASS.new-from-pairs: $x.key.Bag => 1 }
multi prefix:<->(Indeterminate $x) returns Monomial is export { ::?CLASS.new-from-pairs: $x.key.Bag =>-1 }
multi infix:<+>($x, Indeterminate $y) is export { $x + ::?CLASS.new($y) }
multi infix:<->($x, Indeterminate $y) is export { $x - ::?CLASS.new($y) }
multi infix:<+>(Indeterminate $x, $y) is export {  samewith $y, $x }
multi infix:<->(Indeterminate $x, $y) is export { -samewith $y, $x }

method monomials { self.pairs.map: { ::?CLASS.new-from-pairs: $_ } }

multi method key(Monomial:)   returns Bag  { self.pairs[0].key   }
multi method value(Monomial:) returns Real { self.pairs[0].value }

multi infix:<*>(Monomial $a, Monomial $b) returns Monomial is export {
  ::?CLASS.new-from-pairs: ($a.key (+) $b.key) => $a.value*$b.value
}
multi infix:<*>(RealMono $a, ::?CLASS $b) returns ::?CLASS is export { samewith $a.Real, $b }
multi infix:<*>(Real $r, ::?CLASS $b) returns ::?CLASS is export {
  ::?CLASS.new-from-pairs: $b.pairs.map: { .key => .value*$r }
}
multi infix:<*>(::?CLASS $a, ::?CLASS $b) returns ::?CLASS is export {
  [+] $a.monomials X* $b.monomials
}

multi infix:<*>(Monomial $a, Monomial $b) returns Monomial is export {
  ::?CLASS.new-from-pairs: ($a.key (+) $b.key) => $a.value*$b.value;
}
multi infix:<*>(Indeterminate $a, Indeterminate $b) returns Monomial is export {
  ::?CLASS.new-from-pairs: ($a.key (+) $b.key) => 1
}
multi infix:<*>(Indeterminate $b, $x) returns ::?CLASS is export { samewith $x, $b }
multi infix:<*>($x, Indeterminate $b) returns ::?CLASS is export {
  $x * ::?CLASS.new($b)
}

multi method new(Real $r) returns Monomial { ::?CLASS.new-from-pairs: Bag.new => $r }
multi method new(Indeterminate $x) returns Monomial {
  ::?CLASS.new-from-pairs: $x.key.Bag => 1
}
proto method Real returns Real {*}
multi method Real($ where *.elems == 0:) { 0 }
multi method Real($ where *.degree == 0:) { self{Bag.new}.Real }

multi method degree(Monomial:) { self.key.total }
multi method degree { self.monomials.max: *.degree }

multi infix:<+>(Real $r, ::?CLASS $x) returns ::?CLASS is export { samewith $x, $r }
multi infix:<->(Real $r, ::?CLASS $x) returns ::?CLASS is export { $r + -$x }
multi infix:<+>(::?CLASS $x, Real $r) returns ::?CLASS is export { samewith $x, ::?CLASS.new($r) }
multi infix:<+>(::?CLASS $a, ::?CLASS $b) returns ::?CLASS is export { $a (+) $b }
multi prefix:<->(::?CLASS $a)             returns ::?CLASS is export { -1*$a }
multi infix:<->(::?CLASS $a, ::?CLASS $b) returns ::?CLASS is export { $a (+) -$b }

multi postfix:<²>(Indeterminate $a --> ::?CLASS) is export { samewith +$a }
multi postfix:<²>(::?CLASS $a --> ::?CLASS) is export { $a*$a }
multi infix:<==>(::?CLASS $a, ::?CLASS $b) is export { $a (==) $b }
