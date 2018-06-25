/* Paul Tol's schemes start here. *******************************************/
/* See http://www.sron.nl/~pault/ */

function tolPalette(palette) {
        var rgb = palette.rgbColor;

        var poly = function(x, varargs) {
            var i = arguments.length - 1, n = arguments[i];
            while (i > 1) {
                n = n * x + arguments[--i];
            }
            return n;
        };

        var erf = function(x) {
            var y = poly(Math.abs(x), 1, 0.278393, 0.230389, 0.000972, 0.078108);
            y *= y; // y^2
            y *= y; // y^4
            y = 1 - 1 / y;
            return x < 0 ? -y : y;
        };

        palette.register(palette.Scheme.fromPalettes('tol', 'qualitative', [
            ['4477aa'],
            ['4477aa', 'cc6677'],
            ['4477aa', 'ddcc77', 'cc6677'],
            ['4477aa', '117733', 'ddcc77', 'cc6677'],
            ['332288', '88ccee', '117733', 'ddcc77', 'cc6677'],
            ['332288', '88ccee', '117733', 'ddcc77', 'cc6677', 'aa4499'],
            ['332288', '88ccee', '44aa99', '117733', 'ddcc77', 'cc6677', 'aa4499'],
            ['332288', '88ccee', '44aa99', '117733', '999933', 'ddcc77', 'cc6677',
                'aa4499'],
            ['332288', '88ccee', '44aa99', '117733', '999933', 'ddcc77', 'cc6677',
                '882255', 'aa4499'],
            ['332288', '88ccee', '44aa99', '117733', '999933', 'ddcc77', '661100',
                'cc6677', '882255', 'aa4499'],
            ['332288', '6699cc', '88ccee', '44aa99', '117733', '999933', 'ddcc77',
                '661100', 'cc6677', '882255', 'aa4499'],
            ['332288', '6699cc', '88ccee', '44aa99', '117733', '999933', 'ddcc77',
                '661100', 'cc6677', 'aa4466', '882255', 'aa4499']
        ], 12, 12));

        palette.tolSequentialColor = function(x) {
            return rgb(1 - 0.392 * (1 + erf((x - 0.869) / 0.255)),
                1.021 - 0.456 * (1 + erf((x - 0.527) / 0.376)),
                1 - 0.493 * (1 + erf((x - 0.272) / 0.309)));
        };

        palette.register(palette.Scheme.withColorFunction(
            'tol-sq', 'sequential', palette.tolSequentialColor, true));

        palette.tolDivergingColor = function(x) {
            var g = poly(x, 0.572, 1.524, -1.811) / poly(x, 1, -0.291, 0.1574);
            return rgb(poly(x, 0.235, -2.13, 26.92, -65.5, 63.5, -22.36),
                g * g,
                1 / poly(x, 1.579, -4.03, 12.92, -31.4, 48.6, -23.36));
        };

        palette.register(palette.Scheme.withColorFunction(
            'tol-dv', 'diverging', palette.tolDivergingColor, true));

        palette.tolRainbowColor = function(x) {
            return rgb(poly(x, 0.472, -0.567, 4.05) / poly(x, 1, 8.72, -19.17, 14.1),
                poly(x, 0.108932, -1.22635, 27.284, -98.577, 163.3, -131.395,
                    40.634),
                1 / poly(x, 1.97, 3.54, -68.5, 243, -297, 125));
        };

        palette.register(palette.Scheme.withColorFunction(
            'tol-rainbow', 'qualitative', palette.tolRainbowColor, true));
}