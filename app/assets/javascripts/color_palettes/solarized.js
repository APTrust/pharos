/* Solarized colour schemes start here. *************************************/
/* See http://ethanschoonover.com/solarized */

function solPalette(palette) {
        palette.register(palette.Scheme.fromPalettes('sol-base', 'sequential', [
            ['002b36', '073642', '586e75', '657b83', '839496', '93a1a1', 'eee8d5',
                'fdf6e3']
        ], 1, 8));
        palette.register(palette.Scheme.fromPalettes('sol-accent', 'qualitative', [
            ['b58900', 'cb4b16', 'dc322f', 'd33682', '6c71c4', '268bd2', '2aa198',
                '859900']
        ]));
}