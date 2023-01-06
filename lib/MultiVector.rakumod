unit class MultiVector;

method gist {
  self.mix.pairs
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
  
# L<https://github.com/rakudo/rakudo/issues/2544>
#has Mix[Int] $.mix = (1, 2);
has Mix $.mix;

method grades { self.mix.keys.map(*.base(2).comb.sum) // 0 }

method list { self.mix.pairs.map: { ::?CLASS.new: mix => .Mix } }

# maybe .Real should fail unless .grades.max == 0??
method Real { $!mix{0} // 0 }

method narrow { self.grades.max ≤ 0 ?? self.Real.narrow !! self }

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

multi method new(Real $r) { samewith mix => (0 => $r).Mix }
multi method new(Str $ where /^^(<[eio]>)(\d+)$$/) {
  ::?CLASS.new(mix => (1 +< (3*$1 + enum <e i o>{$0})  => 1).Mix)
}

multi method add($a: ::?CLASS $b) returns ::?CLASS {
  ::?CLASS.new: mix => ($a.mix.pairs, $b.mix.pairs).flat.Mix
}
multi method add(Real $r)          returns ::?CLASS { samewith ::?CLASS.new: $r }
multi method negate                returns ::?CLASS { samewith self.scale: -1 }
multi method subtract(::?CLASS $b) returns ::?CLASS { self.add: $b.negate }

multi method divide(Real $r) returns ::?CLASS { self.scale: 1/$r }
multi method scale(Real $r) returns ::?CLASS {
  ::?CLASS.new: mix => self.mix.pairs.map({ .key => $r*.value }).Mix
}
multi method geometric-product($A: ::?CLASS $B) returns ::?CLASS {
  ::?CLASS.new: mix => do for $A.mix.keys X $B.mix.keys -> ($a, $b) {
    ($a +^ $b) => [*]
    $A.mix{$a}, $B.mix{$b},
    order($a, $b),
    (|(1,-1,0) xx * Z=> ($a +& $b).polymod(2 xx *))
    .grep(*.value)
    .map(*.key)
    .Slip
  }.Mix
}
multi method outer-product($A: ::?CLASS $B) returns ::?CLASS {
  ::?CLASS.new: mix => do for $A.mix.keys X $B.mix.keys -> ($a, $b) {
    next if $a +& $b;
    ($a +^ $b) => [*]
    $A.mix{$a}, $B.mix{$b},
    order($a, $b)
  }.Mix
}

multi method AT-POS(UInt $n) {
  ::?CLASS.new: mix => ($!mix.pairs.grep(*.key.base(2).comb.sum == $n)).Mix
}

multi method Str($ where *.grades.max ≤ 0:) { self.narrow.Str }
