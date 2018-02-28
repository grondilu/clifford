use Clifford;
use Test;

my @e = flat no, |@Clifford::e Z ni, |@Clifford::ē;

plan 4;

sub randRat { (0.5 - rand).round(.01) }
sub random($N = 5) {
    my $a = 0;
    $a += randRat if rand < .5;
    $a += randRat() * [∧] @e[^$N].pick($_) for 1..10;
    return $a;
}


my ($a, $b, $c) = random() xx 3;

ok ($a*$b)*$c == $a*($b*$c), 'associativity';
ok $a*($b + $c) == $a*$b + $a*$c, 'left distributivity';
ok ($a + $b)*$c == $a*$c + $b*$c, 'right distributivity';

my @coeff = (.5 - rand) xx 4;
my $v = [+] @coeff Z* @Clifford::e[^4];
ok ($v**2).narrow ~~ Real, 'contraction';

# vim: ft=perl6
