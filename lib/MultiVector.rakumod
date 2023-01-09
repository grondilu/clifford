unit class MultiVector is Mix;

subset Zero       of ::?CLASS is export where *.elems == 0;
subset BasisBlade of ::?CLASS is export where *.elems == 1;
subset Vector     of ::?CLASS is export where *.grades.all == 1;

method Pair (BasisBlade: --> Pair) { self.pairs[0] }
method grade(BasisBlade:)          { self.Pair.key.base(2).comb.sum }

multi method list { self.pairs.map: { self.new-from-pairs: $_ } }

our @e is export = map { ::?CLASS.new("e$_") }, ^Inf;
our @i is export = map { ::?CLASS.new("i$_") }, ^Inf;
our @o is export = map { ::?CLASS.new("o$_") }, ^Inf;

method grades { self.list.map: *.grade }

proto method Real returns Real {*}
multi method Real(Zero:) { 0 }
multi method Real(BasisBlade $ where *.grade == 0:) { self{0} }

method gist {
  self.pairs
  .sort(*.key)
  .map({ .value ~ '*' ~ (
    .key == 0 ?? '1' !!
     ((^Inf XR~ <e i o>) Z=> .key.polymod(2 xx *))
     .grep(+*.value)
     .map(*.key)
     .join('∧')
     .trans(^10 => "₀".."₉")
    )
  })
  .join('+')
  .subst(/'*1'/, '', :g)
  .subst(/<!after \.>1\*/, '', :g)
  .subst(/'+-'/, '-', :g)
  || '0'
}
  
my sub order(UInt:D $i is copy, UInt:D $j) {
  (state %){$i}{$j} //= do {
    my $n = 0;
    repeat {
      $i +>= 1;
      $n += [+] ($i +& $j).polymod(2 xx *);
    } until $i == 0;
    $n +& 1 ?? -1 !! 1;
  }
}

multi method new(Real $r) { self.new-from-pairs: 0 => $r }
multi method new(Str $ where /^^(<[eio]>)(\d+)$$/) { callwith 1 +< (3*$1 + enum <e i o>{$0}) }

multi prefix:<+>(::?CLASS $M)             returns ::?CLASS is export { +$M }
multi infix:<+>(::?CLASS $a, ::?CLASS $b) returns ::?CLASS is export { $a (+) $b }
multi infix:<->(::?CLASS $a, ::?CLASS $b) returns ::?CLASS is export { $a + -1*$b }
multi infix:<+>(::?CLASS $a, Real $r)     returns ::?CLASS is export { samewith $a, $a.new($r) }
multi infix:<+>(Real $r, ::?CLASS $a)     returns ::?CLASS is export { samewith $a, $r }
multi prefix:<->(BasisBlade $blade)       returns BasisBlade    is export { -1 * $blade }

multi infix:<*>(Real $ where * == 0, BasisBlade $) returns Zero is export { ::?CLASS.new }
multi infix:<*>(Real $r, Zero $z) returns Zero is export { $z }
multi infix:<*>(Real $r, BasisBlade $blade) returns BasisBlade    is export {
  $blade.new-from-pairs: $blade.Pair.key => $r*$blade.Pair.value
}

multi infix:<*>(::?CLASS $a, Real $r) returns ::?CLASS is export { callwith $r, $a }
multi infix:<*>(Real $ where * == 0, ::?CLASS $a) returns Zero is export { ::?CLASS.new }
multi infix:<*>(Real $r, ::?CLASS $a) returns ::?CLASS is export { [+] $r X* $a.list }
multi infix:</>(::?CLASS $a, Real $r) returns ::?CLASS is export { (1/$r)*$a }

proto infix:<∧>(::?CLASS, ::?CLASS) is tighter(&[*]) returns ::?CLASS is export {*}
proto infix:<⟑>(::?CLASS, ::?CLASS) is tighter(&[*]) returns ::?CLASS is export {*}

multi infix:</>(::?CLASS $a, BasisBlade $b) returns ::?CLASS is export { $a⟑$b/$b² }

multi infix:<∧>($, Zero $z) { $z }
multi infix:<∧>(Zero $z, $) { $z }
multi infix:<∧>(BasisBlade $A, BasisBlade $B where { $A.Pair.key +& $B.Pair.key }) { $ = ::?CLASS.new-from-pairs: 0 => 0 }
multi infix:<∧>(BasisBlade $A, BasisBlade $B) {
  my ($a, $b) = ($A, $B)».Pair;
  ::?CLASS.new-from-pairs:
    ($a.key +| $b.key) => $a.value*$b.value*order($a.key, $b.key)
}

multi infix:<⟑>(Zero $z, $) { $z }
multi infix:<⟑>($, Zero $z) { $z }
multi infix:<⟑>(BasisBlade $, Zero $z) { $z }
multi infix:<⟑>(BasisBlade $A, BasisBlade $B) {
  my $ab = $A.Pair.key +& $B.Pair.key;
  my $prod =
    [*]
    $ab
    .base(2)
    .comb
    .reverse
    .pairs
    .grep(+*.value)
    .map: {
      given .key % 3 {
	when 0 { +1 }
	when 1 { -1 }
	when 2 {  0 }
      }
    }
  ;
  return $prod * order($A.Pair.key, $B.Pair.key) *
    ::?CLASS.new-from-pairs(($A.Pair.key +^ $B.Pair.key) => $A.Pair.value * $B.Pair.value)
}

multi infix:<∧>(BasisBlade $A where *.Pair == 0, $B) { $A.Real * $B }
multi infix:<∧>($A, BasisBlade $B where *.Pair == 0) { $B.Real * $A }
multi infix:<∧>($A, $B) { [+] $A.list X∧ $B.list }
multi infix:<⟑>($A, $B) { [+] $A.list X⟑ $B.list }

sub infix:<·>(Vector $a, Vector $b) is tighter(&[*]) returns Real is export { (($a⟑$b + $b⟑$a)/2).Real }
multi postfix:<²>(Vector $v) returns Real is export { $v·$v }
multi postfix:<²>(BasisBlade $b) returns Real is export { ($b⟑$b).Real }

multi method AT-POS(UInt $n) {
  ::?CLASS.new-from-pairs: self.pairs.grep: *.key.base(2).comb.sum == $n
}

multi infix:<==>(::?CLASS $A, ::?CLASS $B) { $A (==) $B }
multi infix:<==>(::?CLASS $A, Real $r) { callwith $A, ::?CLASS.new($r) }
multi infix:<==>(Real $r, ::?CLASS $A) { callwith $A, $r }
