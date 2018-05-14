
/** @license
 *
 *     Colour Palette Generator script.
 *     Copyright (c) 2014 Google Inc.
 *
 *     Licensed under the Apache License, Version 2.0 (the "License"); you may
 *     not use this file except in compliance with the License.  You may
 *     obtain a copy of the License at
 *
 *         http://www.apache.org/licenses/LICENSE-2.0
 *
 *     Unless required by applicable law or agreed to in writing, software
 *     distributed under the License is distributed on an "AS IS" BASIS,
 *     WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or
 *     implied.  See the License for the specific language governing
 *     permissions and limitations under the License.
 *
 * Furthermore, ColorBrewer colour schemes are covered by the following:
 *
 *     Copyright (c) 2002 Cynthia Brewer, Mark Harrower, and
 *                        The Pennsylvania State University.
 *
 *     Licensed under the Apache License, Version 2.0 (the "License"); you may
 *     not use this file except in compliance with the License. You may obtain
 *     a copy of the License at
 *
 *         http://www.apache.org/licenses/LICENSE-2.0
 *
 *     Unless required by applicable law or agreed to in writing, software
 *     distributed under the License is distributed on an "AS IS" BASIS,
 *     WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or
 *     implied. See the License for the specific language governing
 *     permissions and limitations under the License.
 *
 *     Redistribution and use in source and binary forms, with or without
 *     modification, are permitted provided that the following conditions are
 *     met:
 *
 *     1. Redistributions as source code must retain the above copyright
 *     notice, this list of conditions and the following disclaimer.
 *
 *     2. The end-user documentation included with the redistribution, if any,
 *     must include the following acknowledgment: "This product includes color
 *     specifications and designs developed by Cynthia Brewer
 *     (http://colorbrewer.org/)." Alternately, this acknowledgment may appear
 *     in the software itself, if and wherever such third-party
 *     acknowledgments normally appear.
 *
 *     4. The name "ColorBrewer" must not be used to endorse or promote products
 *     derived from this software without prior written permission. For written
 *     permission, please contact Cynthia Brewer at cbrewer@psu.edu.
 *
 *     5. Products derived from this software may not be called "ColorBrewer",
 *     nor may "ColorBrewer" appear in their name, without prior written
 *     permission of Cynthia Brewer.
 *
 * Furthermore, Solarized colour schemes are covered by the following:
 *
 *     Copyright (c) 2011 Ethan Schoonover
 *
 *     Permission is hereby granted, free of charge, to any person obtaining
 *     a copy of this software and associated documentation files (the
 *     "Software"), to deal in the Software without restriction, including
 *     without limitation the rights to use, copy, modify, merge, publish,
 *     distribute, sublicense, and/or sell copies of the Software, and to
 *     permit persons to whom the Software is furnished to do so, subject to
 *     the following conditions:
 *
 *     The above copyright notice and this permission notice shall be included
 *     in all copies or substantial portions of the Software.
 *
 *     THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
 *     OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
 *     MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
 *     NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
 *     LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
 *     OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
 *     WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

'use strict';

var palette = (function() {

    var proto = Array.prototype;
    var slice = function(arr, opt_begin, opt_end) {
        return proto.slice.apply(arr, proto.slice.call(arguments, 1));
    };

    var extend = function(arr, arr2) {
        return proto.push.apply(arr, arr2);
    };

    var function_type = typeof function() {};

    var INF = 1000000000;  // As far as we're concerned, that's infinity. ;)

    var palette = function(scheme, number, opt_index, varargs) {
        number |= 0;
        if (number === 0) {
            return [];
        }

        if (typeof scheme !== function_type) {
            var arr = palette.listSchemes(
                /** @type {string|palette.Palette} */ (scheme), number);
            if (!arr.length) {
                return null;
            }
            scheme = arr[(opt_index || 0) % arr.length];
        }

        var args = slice(arguments, 2);
        args[0] = number;
        return scheme.apply(scheme, args);
    };

    palette.Scheme = function(name, opt_groups) {
        /**
         * A map from a number to a colour palettes with given number of colours.
         * @type {!Object<number, palette.Palette>}
         */
        var palettes = {};

        /**
         * The biggest palette in palettes map.
         * @type {number}
         */
        var palettes_max = 0;

        /**
         * The smallest palette in palettes map.
         * @type {number}
         */
        var palettes_min = INF;

        var makeGenerator = function() {
            if (arguments.length <= 1) {
                return self.color_func.bind(self);
            } else {
                var args = slice(arguments);
                return function(x) {
                    args[0] = x;
                    return self.color_func.apply(self, args);
                };
            }
        };

        var self = function(number, varargs) {
            number |= 0;
            if (!number) {
                return [];
            }

            var _number = number;
            number = Math.abs(number);

            if (number <= palettes_max) {
                var i = Math.max(number, palettes_min);
                var colors = palettes[i];
                if (i > number) {
                    var take_head =
                        'shrinking_takes_head' in colors ?
                            colors.shrinking_takes_head : self.shrinking_takes_head;
                    if (take_head) {
                        colors = colors.slice(0, number);
                        i = number;
                    } else {
                        return palette.generate(
                            function(x) { return colors[Math.round(x)]; },
                            _number, 0, colors.length - 1);
                    }
                }
                colors = colors.slice();
                if (_number < 0) {
                    colors.reverse();
                }
                return colors;

            } else if (self.color_func) {
                return palette.generate(makeGenerator.apply(self, arguments),
                    _number, 0, 1, self.color_func_cyclic);

            } else {
                return null;
            }
        };

        self.scheme_name = name;

        self.groups = opt_groups ?
            typeof opt_groups === 'string' ? [opt_groups] : opt_groups : [];

        self.max = 0;

        self.cbf_max = INF;

        self.addPalette = function(palette, opt_is_cbf) {
            var len = palette.length;
            if (len) {
                palettes[len] = palette;
                palettes_min = Math.min(palettes_min, len);
                palettes_max = Math.max(palettes_max, len);
                self.max = Math.max(self.max, len);
                if (!opt_is_cbf && len != 1) {
                    self.cbf_max = Math.min(self.cbf_max, len - 1);
                }
            }
        };

        self.addPalettes = function(palettes, opt_max, opt_cbf_max) {
            opt_max = opt_max || palettes.length;
            for (var i = 0; i < opt_max; ++i) {
                if (i in palettes) {
                    self.addPalette(palettes[i], true);
                }
            }
            self.cbf_max = Math.min(self.cbf_max, opt_cbf_max || 1);
        };

        self.shrinkByTakingHead = function(enabled, opt_idx) {
            if (opt_idx !== void(0)) {
                if (opt_idx in palettes) {
                    palettes[opt_idx].shrinking_takes_head = !!enabled;
                }
            } else {
                self.shrinking_takes_head = !!enabled;
            }
        };

        self.setColorFunction = function(func, opt_is_cbf, opt_cyclic) {
            self.color_func = func;
            self.color_func_cyclic = !!opt_cyclic;
            self.max = INF;
            if (!opt_is_cbf && self.cbf_max === INF) {
                self.cbf_max = 1;
            }
        };

        self.color = function(x, varargs) {
            if (self.color_func) {
                return self.color_func.apply(this, arguments);
            } else {
                return null;
            }
        };

        return self;
    };

    palette.Scheme.fromPalettes = function(name, groups,
                                           palettes, opt_max, opt_cbf_max) {
        var scheme = palette.Scheme(name, groups);
        scheme.addPalettes.apply(scheme, slice(arguments, 2));
        return scheme;
    };

    palette.Scheme.withColorFunction = function(name, groups,
                                                func, opt_is_cbf, opt_cyclic) {
        var scheme = palette.Scheme(name, groups);
        scheme.setColorFunction.apply(scheme, slice(arguments, 2));
        return scheme;
    };

    var registered_schemes = {};

    palette.register = function(scheme) {
        registered_schemes['n-' + scheme.scheme_name] = [scheme];
        scheme.groups.forEach(function(g) {
            (registered_schemes['g-' + g] =
                registered_schemes['g-' + g] || []).push(scheme);
        });
        (registered_schemes['g-all'] =
            registered_schemes['g-all'] || []).push(scheme);
    };

    palette.listSchemes = function(name, opt_number) {
        if (!opt_number) {
            opt_number = 2;
        } else if (opt_number < 0) {
            opt_number = -opt_number;
        }

        var ret = [];
        (typeof name === 'string' ? [name] : name).forEach(function(n) {
            var cbf = n.substring(n.length - 4) === '-cbf';
            if (cbf) {
                n = n.substring(0, n.length - 4);
            }
            var schemes =
                registered_schemes['g-' + n] ||
                registered_schemes['n-' + n] ||
                [];
            for (var i = 0, scheme; (scheme = schemes[i]); ++i) {
                if ((cbf ? scheme.cbf : scheme.max) >= opt_number) {
                    ret.push(scheme);
                }
            }
        });

        ret.sort(function(a, b) {
            return a.scheme_name >= b.scheme_name ?
                a.scheme_name > b.scheme_name ? 1 : 0 : -1;
        });
        return ret;
    };

    palette.generate = function(color_func, number, opt_start, opt_end,
                                opt_cyclic) {
        if (Math.abs(number) < 1) {
            return [];
        }

        opt_start = opt_start === void(0) ? 0 : opt_start;
        opt_end = opt_end === void(0) ? 1 : opt_end;

        if (Math.abs(number) < 2) {
            return [color_func(opt_start)];
        }

        var i = Math.abs(number);
        var x = opt_start;
        var ret = [];
        var step = (opt_end - opt_start) / (opt_cyclic ? i : (i - 1));

        for (; --i >= 0; x += step) {
            ret.push(color_func(x));
        }
        if (number < 0) {
            ret.reverse();
        }
        return ret;
    };

    var clamp = function(v) {
        return v > 0 ? (v < 1 ? v : 1) : 0;
    };

    palette.rgbColor = function(r, g, b) {
        return [r, g, b].map(function(v) {
            v = Number(Math.round(clamp(v) * 255)).toString(16);
            return v.length == 1 ? '0' + v : v;
        }).join('');
    };

    palette.linearRgbColor = function(r, g, b) {
        // http://www.brucelindbloom.com/index.html?Eqn_XYZ_to_RGB.html
        return [r, g, b].map(function(v) {
            v = clamp(v);
            if (v <= 0.0031308) {
                v = 12.92 * v;
            } else {
                v = 1.055 * Math.pow(v, 1 / 2.4) - 0.055;
            }
            v = Number(Math.round(v * 255)).toString(16);
            return v.length == 1 ? '0' + v : v;
        }).join('');
    };

    palette.hsvColor = function(h, opt_s, opt_v) {
        h *= 6;
        var s = opt_s === void(0) ? 1 : clamp(opt_s);
        var v = opt_v === void(0) ? 1 : clamp(opt_v);
        var x = v * (1 - s * Math.abs(h % 2 - 1));
        var m = v * (1 - s);
        switch (Math.floor(h) % 6) {
            case 0: return palette.rgbColor(v, x, m);
            case 1: return palette.rgbColor(x, v, m);
            case 2: return palette.rgbColor(m, v, x);
            case 3: return palette.rgbColor(m, x, v);
            case 4: return palette.rgbColor(x, m, v);
            default: return palette.rgbColor(v, m, x);
        }
    };

    palette.register(palette.Scheme.withColorFunction(
        'rainbow', 'qualitative', palette.hsvColor, false, true));

    return palette;
})();

var cf = palette.ColorFunction;

var pt = palette.Palette;

var pl = palette.PalettesList;

var st = palette.SchemeType;

if(typeof module === "object" && module.exports) {
    module.exports = palette;
}

mpnPalette(palette);
tolPalette(palette);
solPalette(palette);
cbPalette(palette);