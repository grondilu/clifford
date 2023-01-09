use Test;

use MultiVector;

is @e[^10 .pick]², 1, "\@e[i]² == 1";
isnt @e[^10 .pick]², -1, "\@e[i]² != -1";

is @i[^10 .pick]², -1, "\@i[i]² == -1";
isnt @i[^10 .pick]², 1, "\@i[i]² != 1";

is @o[^10 .pick]², 0, "\@o[i]² == 0";

done-testing;

# vi: ft=raku
