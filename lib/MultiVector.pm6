unit role MultiVector does Numeric;

# The grade projection should return a MultiVector
# except for grade zero where it should return a Real.
# This will make it easier to define the Real method.
multi method AT-POS(0) returns Real {...}
multi method AT-POS(UInt $n where $n > 0) returns MultiVector {...}

# The grades method should return a list of grades where
# the grade projection is not null.
# For instance (e0 + e0∧e1).grades should return 1, 2
method grades {...}

# conversion to Real as required by the Numeric role.
method Real {
    if any(self.grades) > 0 {
	fail X::Numeric::Real.new:
	target => Real,
	source => self,
	reason => 'Can not convert to Real: multivector is not purely scalar'
	;
    }
    return self[0] // 0;
}

method narrow returns Numeric {
    if self.grades == 0 { return 0 }
    elsif self.grades.any > 0 { return self }
    else { return self.Real.narrow }
}

proto method add($) returns MultiVector {*}
multi method add(Real $) {...}
multi method add(MultiVector $) {...}

proto method scale(Real $) {*}
multi method scale(0) { 0 }
multi method scale(1) returns MultiVector { self.clone }
multi method scale(Real $) returns MultiVector {...}

proto method gp(MultiVector $) returns MultiVector {*};
multi method gp(MultiVector $) {...};
proto method ip(MultiVector $) returns MultiVector {*};
multi method ip(MultiVector $) {...};
proto method op(MultiVector $) returns MultiVector {*};
multi method op(MultiVector $) {...};

method reversion {
    # the first grade projection may be Real and if so
    # it has no add method.  The solution is to add
    # the first operand to the second, and not the second
    # to the first.
    reduce -> ($a, $b) { $b.add($a) },
    (self[$_].scale((-1)**($_*($_-1) div 2)) for self.grades)
}
method involution {
    reduce -> ($a, $b) { $b.add($a) },
    (self[$_].scale((-1)**$_) for self.grades)
}
method conjugation {
    reduce -> ($a, $b) { $b.add($a) },
    (self[$_].scale((-1)**($_*($_+1) div 2)) for self.grades)
}
