'use strict';

function isInt(thing) {
    return (typeof thing == "number") && (thing % 1 === 0);
}

module.exports = {
    isInt
}
