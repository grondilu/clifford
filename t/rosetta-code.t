#!/usr/bin/env raku -Ilib
use Clifford;
use Test;

{
  =for Task
  Find the point of intersection of two lines in 2D. 

# We pick a projective basis,
# and we compute its pseudo-scalar and its square.
  my ($i, $j, $k) = @e;
  my $I = $i∧$j∧$k;

# Homogeneous coordinates of point (X,Y) are (X,Y,1)
  my $A =  4*$i +  0*$j + $k;
  my $B =  6*$i + 10*$j + $k;
  my $C =  0*$i +  3*$j + $k;
  my $D = 10*$i +  7*$j + $k;

# We form lines by joining points
  my $AB = $A∧$B;
  my $CD = $C∧$D;

# The intersection is their meet, which we
# compute by using the De Morgan law
  my $ab = $AB/$I;
  my $cd = $CD/$I;
  my $M = ($ab ∧ $cd)/$I;

# Affine coordinates are (X/Z, Y/Z)
  is ($M / ($M·$k) X· $i, $j), (5, 5), "intersection of two lines";
}

{
  =for Task
  Find the point of intersection for the infinite ray with direction
  (0, -1, -1)   passing through position   (0, 0, 10)   with the infinite plane
  with a normal vector of   (0, 0, 1)   and which passes through [0, 0, 5].

# We pick a projective basis and compute its pseudo-scalar
  my $I = [∧] my ($i, $j, $k, $l) = @e;

# The direction of the line is on the infinite plane (w=0)
  my $direction = -$j - $k;

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
  is ($m/($m·$l) X· $i, $j, $k), (0, -5, 5), "intersection of a line with a plane";

  =for link
  L<https://rosettacode.org/wiki/Find_the_intersection_of_a_line_with_a_plane>

}

done-testing;

# vi: ft=raku
