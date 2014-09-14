use MultiVector;
use Test;

plan 4;

sub random {
    my MultiVector $r .= new: (^10).pick - 5;
    $r += ((^10).pick - 5)*e((^4).pick) for ^(^4).pick;
    $r += [*] ((^10).pick - 5), map &e, (^4).pick(2) for ^(^4).pick;
    $r += [*] ((^10).pick - 5), map &e, (^4).pick(3) for ^(^4).pick;
    return $r / 10;
}

my ($a, $b, $c) = random() xx 3;
ok ($a*$b)*$c == $a*($b*$c), 'associativity';
ok $a*($b + $c) == $a*$b + $a*$c, 'left distributivity';
ok ($a + $b)*$c == $a*$c + $b*$c, 'right distributivity';
my @coeff = (.5 - rand) xx 4;
my $v = [+] @coeff Z* map &e, ^4;
ok $v**2 ~~ Real, 'contraction';

# vim: ft=perl6
