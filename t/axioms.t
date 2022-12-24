use Clifford;
use Test;

sub random($_ = rand) {
  when * < .1 { return (rand - .5).round(.1) }
  when * < .2 { return @e[^10 .pick] }
  when * < .3 { return @i[^10 .pick] }
  when * < .4 { return @o[^10 .pick] }
  when * < .5 { return random($_/2) * random($_/2); }
  default     { return random(4*$_/5) + random(2*$_/3); }
}

constant N = 1000;
plan N;

for ^N {
  my ($a, $b, $c) = random() xx 3;
  subtest "a={$a.gist}, b={$b.gist}, c={$c.gist}", {
    ok ($a*$b)*$c == $a*($b*$c), 'associativity';
    ok $a*($b + $c) == $a*$b + $a*$c, 'left distributivity';
    ok ($a + $b)*$c == $a*$c + $b*$c, 'right distributivity';

    my $v = [+] (.5 - rand) xx 10 Z* @e;
    ok ($v**2).narrow ~~ Real, 'contraction';
  }
}

# vi: ft=raku
