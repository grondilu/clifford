class MultiVector is Cool does Numeric;
=begin pod

=TITLE
MultiVector ― Geometric Algebra In Perl 6

=for AUTHOR
Lucien Grondin <L<C<grondilu@yahoo.fr>|mailto:grondilu@yahoo.fr>>

=DESCRIPTION
This class is an attempt to implement basic geometric algebra in Perl6.  See
L<http://en.wikipedia.org/wiki/Geometric_algebra> for more information on what
Geometric algebra is about.

=begin SYNOPSIS

    use MultiVector;

    say e(Real);         # The scalar unit seen as a MultiVector
    say e(0);            # The first vector of the orthonormal basis
    say e(1);            # The second vector of the orthonormal basis

    # a linear combination of e(0) and e(1):
    my $a = rand*e(0) + rand*e(1);

    say $a ~~ Blade;     # There is a Blade subset of MultiVector
    say $a ~~ Vector;    # And there is a Vector subset of Blade

    say $a**2 ~~ Real;   # the square of a vector is always a Real

    # A scalar is a Blade
    say rand*e(Real) ~~ Blade;

    # The grade is defined only on blades:
    say $a.grade;         # OK:     1
    say (1 + $a).grade;   # WRONG:  dies with a constraint type check failure

    # Changing to a Lorentzian metric
    @MultiVector::signature[0] = -1;

    say e(0)**2;     # -1

=end SYNOPSIS

=end pod
our @signature = 1 xx *;

subset Blade  of MultiVector is export      where *.grades == 1;
subset Vector of Blade       is export      where *.grade == 1;

method grade(Blade:D:) returns Int { self.grades.pick }

subset PosInt of Int where * >= 0;
class Frame is export {
    has PosInt @.increase;
    method list { [\+] 0, 1 xx * Z+ @!increase }
    multi method new(@index where all(@index) >= 0 && [<] @index) {
	self.new: :increase((@index Z- 0, @index) Z- 0, 1 xx *);
    }
    method WHICH { 'Frame|(' ~ @!increase.join(',') ~ ')' }
}
constant NullFrame = Frame.new;
has Real %.canonical-decomposition{Frame};

multi method new(Real $r) {
    (my Real %canonical-decomposition{Frame}){NullFrame} = $r;
    self.new: :%canonical-decomposition;
}
method reals(MultiVector:D:) { %!canonical-decomposition.values }
method isNaN(MultiVector:D:) { [||] map *.isNaN, self.reals }
method coerce-to-real(MultiVector:D: $exception-target) {
    unless self.grades.max == 0 {
	fail X::Numeric::Real.new(target => $exception-target, reason => "non-scalar part not zero", source => self);
    }
    %!canonical-decomposition{NullFrame} // 0;
}
multi method Real(MultiVector:D:) { self.coerce-to-real(Real); }

# should probably be eventually supplied by role Numeric
method Num(MultiVector:D:) { self.coerce-to-real(Num).Num; }
method Int(MultiVector:D:) { self.coerce-to-real(Int).Int; }
method Rat(MultiVector:D:) { self.coerce-to-real(Rat).Rat; }

multi method Bool(MultiVector:D:) { not self == 0 }
method MultiVector { self }
multi method Str(MultiVector:D:) {
    ! %!canonical-decomposition ?? "MultiVector.new()" !!
    join ' + ', map {
	my $index = .key.list;
	$index ?? (
	    .value == 1 ?? '' !!
	    .value < 0 ?? "({.value})*" !!
	    "{.value}*";
	) ~ (
	    $index == 1 ?? "e$index"
	    !! $index.map({"e($_)"}).join('*')
	) !! .value
    },
    sort *.key.list.elems,
    %!canonical-decomposition.pairs;
}

method floor(MultiVector:D:) {
    my Real %canonical-decomposition{Frame};
    %canonical-decomposition{.key} = .value.floor for %!canonical-decomposition.pairs;
    self.new: :%canonical-decomposition;
}
method ceiling(MultiVector:D:) {
    my Real %canonical-decomposition{Frame};
    %canonical-decomposition{.key} = .value.ceiling for %!canonical-decomposition.pairs;
    self.new: :%canonical-decomposition;
}
method truncate(MultiVector:D:) {
    my Real %canonical-decomposition{Frame};
    %canonical-decomposition{.key} = .value.truncate for %!canonical-decomposition.pairs;
    self.new: :%canonical-decomposition;
}

proto method round(|) {*}
multi method round(MultiVector:D: $scale as Real = 1) {
    my Real %canonical-decomposition{Frame};
    %canonical-decomposition{.key} = .value.round($scale) for %!canonical-decomposition.pairs;
    self.new: :%canonical-decomposition;
}

method narrow {
    return 0 if self == 0;
    if self.grades.max == 0 {
	if %!canonical-decomposition.values > 1 {
	    die 'unexpected number of entries in canonical decomposition'
	} elsif %!canonical-decomposition.values == 1 {
	    return %!canonical-decomposition.values.pick
	} else { return 0 }
    } else { return self }
}

method clean returns MultiVector {
    for %!canonical-decomposition.pairs {
	next if .key ~~ NullFrame;
	%!canonical-decomposition{.key} :delete if .value == 0;
    }
    %!canonical-decomposition{NullFrame} = 0 if %!canonical-decomposition == 0;
    return self;
}

my multi infix:<*>( Frame $A, Frame $B ) returns Pair {
    my @index = $A.list, $B.list;
    my $end = @index.end;
    my $orientation = 1;
    for reverse ^$A.list -> $i {
	for $i ..^ $end {
	    if @index[$_] == @index[$_ + 1] {
		$orientation *= @signature[@index[$_]];
		@index.splice($_, 2);
		$end = $_ - 1;
		last;
	    } elsif @index[$_] > @index[$_ + 1] {
		@index[$_, $_ + 1] = @index[$_ + 1, $_];
		$orientation *= -1;
	    }
	}
    }
    Frame.new(@index) => $orientation; 
}

proto e(|) returns MultiVector is export {*}
multi e(Real) { e() }
multi e() {
    (my Real %canonical-decomposition{Frame}){NullFrame}++;
    MultiVector.new: :%canonical-decomposition;
}
multi e(Int $n where $n >= 0) {
    (my Real %canonical-decomposition{Frame}){Frame.new([$n,])}++;
    MultiVector.new: :%canonical-decomposition;
}

#
#
# GRADE PROJECTION
#
#
method grades returns List {
    uniq map *.key.list.elems,
    grep { .key ~~ NullFrame or .value != 0 },
    %!canonical-decomposition.pairs;
}
method at_pos(Int $n) returns Blade {
    MultiVector.new(
	:canonical-decomposition(
	    grep {
		.key.list == $n
	    }, %!canonical-decomposition.pairs
	)
    );
}

#
#
#  ADDITION
#
#
multi prefix:<+>(MultiVector $M) returns MultiVector is export { $M.clean }
multi infix:<+>(MultiVector $M) returns MultiVector is export { $M }
multi infix:<+>(MultiVector $M, Real $r) returns MultiVector is export { $r + $M }
multi infix:<+>(      0, MultiVector $M) returns MultiVector is export { $M }
multi infix:<+>(Real $r, MultiVector $M) returns MultiVector is export {
    my Real %canonical-decomposition{Frame};
    %canonical-decomposition{NullFrame} = $r;
    %canonical-decomposition{.key} += .value for $M.canonical-decomposition.pairs;
    MultiVector.new(:%canonical-decomposition).clean;
}
multi infix:<+>(MultiVector $A, MultiVector $B) returns MultiVector is export {
    my Real %canonical-decomposition{Frame};
    for $A.canonical-decomposition.pairs, $B.canonical-decomposition.pairs {
	%canonical-decomposition{.key} += .value;
    }
    MultiVector.new(:%canonical-decomposition).clean;
}

# 
#
# SUBSTRACTION
#
#
multi infix:<->(MultiVector $A, Real $r) returns MultiVector is export { -$r + $A }
multi infix:<->(Real $r, MultiVector $A) returns MultiVector is export { $r + (-1)*$A }
multi infix:<->(MultiVector $A, MultiVector $B) returns MultiVector is export { $A + (-1)*$B }
multi prefix:<->(MultiVector $A) returns MultiVector is export { (-1)*$A }

# 
#
# SCALAR MULTIPLICATION
#
#
# scalar multiplication is commutative so we'll define it from the left by default
multi infix:<*>(MultiVector $M, Real $r) returns MultiVector is export { $r * $M }
multi infix:<*>(      0, MultiVector $M) returns MultiVector is export { MultiVector.new: 0 }
multi infix:<*>(      1, MultiVector $M) returns MultiVector is export { $M }
multi infix:<*>(Real $r, MultiVector $M) returns MultiVector is export {
    my Real %canonical-decomposition{Frame};
    %canonical-decomposition{.key} += .value * $r for $M.canonical-decomposition.pairs;
    MultiVector.new(:%canonical-decomposition).clean;
}

#
#
# GEOMETRIC PRODUCT
#
#
multi infix:<*>(MultiVector $A, MultiVector $B) returns MultiVector is export {
    my Real %canonical-decomposition{Frame};
    for $A.canonical-decomposition.pairs X $B.canonical-decomposition.pairs -> $a, $b {
	my $ab = $a.key * $b.key; 
	%canonical-decomposition{$ab.key} += $a.value * $b.value * $ab.value;
	%canonical-decomposition{$ab.key} :delete if %canonical-decomposition{$ab.key} == 0;
    }
    MultiVector.new(:%canonical-decomposition);
}

# 
#
# DIVISION
#
#
multi infix:</>(MultiVector $M, Real $r)    returns MultiVector is export { (1/$r) * $M }
multi infix:</>(MultiVector $M, Vector $a) returns MultiVector is export { $M * $a**-1 }

#
#
# EXPONENTIATION
#
#
multi infix:<**>(MultiVector $M, 0) returns Real is export { 1 }
multi infix:<**>(MultiVector $M, 1) returns MultiVector is export { $M }
multi infix:<**>(MultiVector $M, 2) returns MultiVector is export { $M * $M }
multi infix:<**>(MultiVector $M, Int $n where $n > 2 && $n %% 2) returns MultiVector is export {
    ($M**($n div 2))**2
}
multi infix:<**>(MultiVector $M, Int $n where $n > 2 && $n % 2) returns MultiVector is export {
    $M**($n - 1) * $M
}
# Nb. for some reason rakudo does not accept a -1 literal as a parameter??
multi infix:<**>(Vector $a, 2) returns Real is export { ($a*$a).Real }
multi infix:<**>(Vector $a, Int $ where -1) returns Vector is export { $a / ($a**2) }
multi infix:<**>(Vector $a, Int $n where $n %% 2 && $n > 3) returns Real is export {
    ($a**2)**($n div 2)
}
multi infix:<**>(Vector $a, Int $n where $n % 2 && $n > 2) returns Vector is export {
    ($a**2)**($n div 2) * $a
}

#
#
#  INNER PRODUCT
#
#
multi innner-product(Vector $a, Vector $b) returns Real is export { 1/2*($a*$b + $b*$a).Real }
multi innner-product(Blade $A, Blade $B) returns Blade is export { ($A*$B)[abs($A.grade - $B.grade)] }
multi infix:<⋅>(Vector $a, Vector $b) returns Real is export { innner-product $a, $b }
multi infix:<cdot>(Vector $a, Vector $b) returns Real is export { innner-product $a, $b }

#
#
#  OUTER PRODUCT
#
#
multi outer-product(Vector $a, Vector $b) returns Blade is export { 1/2*($a*$b - $b*$a) }
multi outer-product(Blade $A, Blade $B) returns Blade is export { ($A*$B)[$A.grade + $B.grade] }
multi infix:<∧>(Vector $a, Vector $b) returns Blade is export { outer-product $a, $b }
multi infix:<wedge>(Blade $a, Blade $b) returns Blade is export { outer-product $a, $b }

#
#
#  REVERSION
#
#
method reverse returns MultiVector {
    [+] map { (-1)**($_*($_ - 1) div 2) * self[$_] }, self.grades
}
sub postfix:<†>(MultiVector $M) returns MultiVector is export { $M.reverse }

#
#
# CONJUGATION
#
#
method conj returns MultiVector {
    [+] map { (-1)**$_ * self[$_] }, self.grades
}
sub postfix:<∗>(MultiVector $M) returns MultiVector is export { $M.conj }

#
#
# COMMUTATOR
#
#
sub commutator(MultiVector $A, MultiVector $B) returns MultiVector is export {
    1/2 * ($A*$B - $B*$A)
}
multi infix:<×>(MultiVector $A, MultiVector $B) returns MultiVector is export {
    commutator $A, $B
}

#
#
# SIGNATURE
#
#
method signature(Vector $a:) returns Real { sign $a**2 }


#
#
# MAGNITUDE, ABS, NORM
#
#
multi method magnitude(Vector $a:) returns Real { sqrt ($a**2).Real.abs }
multi method magnitude returns Real {
    sqrt [+] self.canonical-decomposition.values X** 2;
}
method abs returns Real { self.magnitude }
method norm returns Real { self.magnitude }

#
#
# EQUALITY
#
#
multi infix:<==>(MultiVector $A, MultiVector $B) returns Bool is export { $A - $B == 0 }
multi infix:<==>($A, MultiVector $B) returns Bool is export { $A - $B == 0 }
multi infix:<==>(MultiVector $A, $B) returns Bool is export { $A - $B == 0 }
multi infix:<==>(MultiVector $A, 0) returns Bool is export {
    so all($A.canonical-decomposition.values) == 0
}

#
#
# INEQUALITY
#
#
multi infix:« < »(MultiVector $A, MultiVector $B) returns Bool is export {
    return False if $A == $B;
    return True if $A.grades.max < $B.grades.max;
    $A[$A.grades.max] < $B[$B.grades.max];
}

# vim: ft=perl6
