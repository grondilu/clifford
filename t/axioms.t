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
    return rand < .5 ?? $a + $b !! $a * $b;
  }
}

constant N = 100;
plan 4;

subtest 'associativity',        { for (random() xx 3) xx N -> ($a, $b, $c) { ok ($a*$b)*$c == $a*($b*$c) } }
subtest 'left distributivity',  { for (random() xx 3) xx N -> ($a, $b, $c) { ok $a*($b + $c) == $a*$b + $a*$c } }
subtest 'right distributivity', { for (random() xx 3) xx N -> ($a, $b, $c) { ok ($a + $b)*$c == $a*$c + $b*$c } }
subtest 'contraction',           {
  for ^N {
    my $v = [+] (.5 - rand).round(.1) xx 4 Z* @e;
    ok $v² ~~ Real, "({$v.gist})² ~~ Real";
  }
}

# vi: ft=raku
