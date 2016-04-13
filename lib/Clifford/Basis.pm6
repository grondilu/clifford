unit package Clifford::Basis;

# A basis blade is represented by an unsigned integer.
#
# Its binary decomposition shows the basis vectors used in the outer product.
#
# For instance:
# * e0        ----> 0b0001 = 1
# * e0∧e2     ----> 0b0101 = 5
# * e1∧e3     ----> 0b1010 = 10

our sub format(uint $basis is copy) {
    join '*', gather {
	my $i = 0;
	while $basis > 0 {
	    take "e$i" if $basis +& 1;
	    take "ē$i" if $basis +& 2;
	    $basis +>= 2;
	    $i++;
	}
    }
}

our sub grade(uint $a is copy) {
    my int $c = 0;
    loop (; $a > 0; $a +>= 1) { $c++ if $a +& 1 }
    return $c;
}

# Flip Check when multiplying two blades
our sub signFlip(uint $a, uint $b, int $c = 0) returns Bool {
  return ($a +> 1 ) > 0 ?? 
  signFlip( $a +> 1 , $b, $c + grade( ( $a +> 1 ) +& $b ) ) !! 
  ?( $c +& 1 )
}   

our sub product(uint $a, uint $b) is export {
    state @signature = |(1, -1) xx *;
    [*]
    (signFlip($a, $b) ?? -1 !! +1),
    |grep +*, (
	@signature Z*
	($a +& $b).base(2).comb.reverse
    )
}
