use Clifford;
use Test;

constant N = 5;
plan 3*N;

sub random {
    (.5 - rand).round(.01) + 
    (.5 - rand).round(.01)*@e[(^5).pick] +
    (.5 - rand).round(.01)*@ē[(^5).pick] +
    (.5 - rand).round(.01)*@ē[(^5).pick]*@e[(^5).pick] +
    (.5 - rand).round(.01)*@e[(^5).pick]*@e[(^5).pick] +
    (.5 - rand).round(.01)*@ē[(^5).pick]*@e[(^5).pick]*@e[(^5).pick] +
    (.5 - rand).round(.01)*@e[(^5).pick]*@e[(^5).pick]*@e[(^5).pick] ;
}

for ^N {
    my ($A, $B, $C) = random() xx 3;

    ok ($A ∧ $B) ∗ $C == $A ∗ ($B ⌋ $C); 
    ok $C ∗ ($B ∧ $A) == ($C ⌊ $B) ∗ $A;
    ok $A⌋$B + $A⌊$B == $A∗$B + $A∙$B;
}

# vim: ft=perl6
