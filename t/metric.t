use Test;

use Clifford;

is @e[^10 .pick]**2, 1, "\@e[i]**2 == 1";
isnt @e[^10 .pick]**2, -1, "\@e[i]**2 == -1";

is @i[^10 .pick]**2, -1, "\@i[i]**2 == -1";
isnt @i[^10 .pick]**2, 1, "\@i[i]**2 == 1";

is @o[^10 .pick]**2, 0, "\@o[i]**2 == 0";

done-testing;

# vi: ft=raku
