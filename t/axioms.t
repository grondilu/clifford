use Clifford;
use Test;

plan 4;

sub random {
    (.5 - rand).round(.01) + 
    (.5 - rand).round(.01)*@e[(^5).pick] +
    (.5 - rand).round(.01)*@ē[(^5).pick] +
    (.5 - rand).round(.01)*@ē[(^5).pick]*@e[(^5).pick] +
    (.5 - rand).round(.01)*@e[(^5).pick]*@e[(^5).pick];
}

my ($a, $b, $c) = random() xx 3;

ok ($a*$b)*$c == $a*($b*$c), 'associativity';
ok $a*($b + $c) == $a*$b + $a*$c, 'left distributivity';
ok ($a + $b)*$c == $a*$c + $b*$c, 'right distributivity';

my @coeff = (.5 - rand) xx 4;
my $v = [+] @coeff Z* @e[^4];
ok ($v**2).narrow ~~ Real, 'contraction';

# vim: ft=perl6
