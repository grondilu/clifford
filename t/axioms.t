use MultiVector;
use Test;

sub random($chance-of-ending = 0) returns MultiVector {
  if rand < $chance-of-ending {
    given rand {
      when * < 1/4 { return MultiVector.new: (rand - .5).round(.1) }
      when * < 2/4 { return @e[^10 .pick] }
      when * < 3/4 { return @i[^10 .pick] }
      default      { return @o[^10 .pick] }
    }
  } else {
    my $chance-of-continuing = 1 - $chance-of-ending;
    my $new-chance-of-ending = 1 - .5*$chance-of-continuing;
    my ($a, $b) = random($new-chance-of-ending) xx 2;
    return rand < .5 ?? $a + $b !! $a ⟑ $b;
  }
}

constant N = 1000;
plan N;

for (random() xx 3) xx N -> ($a, $b, $c) {
  subtest "a={$a.gist}, b={$b.gist}, c={$c.gist}", {
    ok ($a⟑$b)⟑$c == $a⟑($b⟑$c), 'associativity';
    ok $a⟑($b + $c) == $a⟑$b + $a⟑$c, 'left distributivity';
    ok ($a + $b)⟑$c == $a⟑$c + $b⟑$c, 'right distributivity';

    my $v = [+] (.5 - rand) xx 10 Z* @e;
    ok $v² ~~ Real, 'contraction';
  }
}

# vi: ft=raku
