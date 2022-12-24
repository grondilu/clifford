use Test;

use Clifford;

is @e[^10 .pick]**2, 1, "\@e[i]**2 == 1";
isnt @e[^10 .pick]**2, -1, "\@e[i]**2 == -1";

is @ē[^10 .pick]**2, -1, "\@ē[i]**2 == -1";
isnt @ē[^10 .pick]**2, 1, "\@ē[i]**2 == 1";

#is @o[^10 .pick]**2, 0, "\@o[i]**2 == 0";
done-testing;
# vi: ft=raku
