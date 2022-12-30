use Clifford;

{
  # L<https://rosettacode.org/wiki/Find_the_intersection_of_a_line_with_a_plane>
  # We pick a projective basis and compute its pseudo-scalar
  my $I = [∧] my ($i, $j, $k, $l) = @e;

  my $direction = -$j - $k;
  $direction /= sqrt($direction**2);

  # Homogeneous coordinate of (X, Y, Z) are (X, Y, Z, 1)
  my $point = 10*$k + $l;

  # A line is a bivector
  my $line = $direction ∧ $point;

  # A plane is a trivector
  my $plane = (5*$k + $l) ∧ ($k/($i∧$j∧$k));

  # In dual space, the intersection is the join
  my $LINE = $line/$I;
  my $PLANE = $plane/$I;
  my $M = $LINE∧$PLANE;

  # switching back to normal space
  my $m = $M/$I;

  # Affine coordinates of (X, Y, Z, W) are (X/W, Y/W, Z/W)
  use Test;
  is ($m/($m·$l) X· $i, $j, $k), (0, -5, 5), "intersection of a line with a plane";
}

done-testing;

# vi: ft=raku
