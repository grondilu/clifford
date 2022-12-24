use Clifford;
use Test;


sub random {
  given rand {
    when * < .2 { return random() * random(); }
    when * < .3 { return random() + random(); }
    when * < .5 { return @e[^10 .pick] }
    when * < .6 { return @ē[^10 .pick] }
    default { return (-2, -1, 1, 2).pick }
  }
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
