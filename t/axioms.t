use Clifford;
use Test;

plan 4;

sub random {
    my $r = rand * e();
    $r += rand * e((^5).pick);
    my ($a, $b) = (^5).roll(2);
    my $c = rand * e($a) * e($b);
    $r += $c;
    $r.round(.01);
}

my ($a, $b, $c) = random() xx 3;

ok ($a*$b)*$c == $a*($b*$c), 'associativity';
ok $a*($b + $c) == $a*$b + $a*$c, 'left distributivity';
ok ($a + $b)*$c == $a*$c + $b*$c, 'right distributivity';
my @coeff = (.5 - rand) xx 4;
my $v = [+] @coeff Z* map &e, ^4;
ok ($v**2).narrow ~~ Real, 'contraction';

# vim: ft=perl6
