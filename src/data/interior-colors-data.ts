export interface InteriorColor {
    code: string;
    material: string;
    colorName: string;
    years: string;
    colorHex: string; // Approximate color for visual display
}

export const interiorColors: InteriorColor[] = [
    // MATERIAŁ (0xx)
    { code: "001", material: "Materiał", colorName: "Czarny", years: "1975-1979", colorHex: "#1a1a1a" },
    { code: "002", material: "Materiał", colorName: "Niebieski", years: "1975-1979", colorHex: "#2c3e50" },
    { code: "003", material: "Materiał", colorName: "Tytoniowy", years: "1975-1979", colorHex: "#6b5b4f" },
    { code: "004", material: "Materiał", colorName: "Szafranowy / Bambusowy", years: "1975-1979", colorHex: "#c4a35a" },
    { code: "005", material: "Materiał", colorName: "Pergaminowy / Grzybowy", years: "1975-1979", colorHex: "#d4c4a8" },
    { code: "006", material: "Materiał", colorName: "Zielony", years: "1975-1979", colorHex: "#4a5d4a" },
    { code: "031", material: "Materiał", colorName: "Czarny", years: "1979-1982", colorHex: "#1a1a1a" },
    { code: "034", material: "Materiał", colorName: "Palomino / Dattel", years: "1979-1982", colorHex: "#a67c52" },
    { code: "037", material: "Materiał", colorName: "Czerwona Sienna", years: "1979-1982", colorHex: "#8b4513" },
    { code: "054", material: "Materiał", colorName: "Palomino / Dattel", years: "1982-1984", colorHex: "#a67c52" },
    { code: "065", material: "Materiał", colorName: "Pergaminowy", years: "1971-1975", colorHex: "#d4c4a8" },
    { code: "075", material: "Materiał", colorName: "Kremowy Beż", years: "1984-1989", colorHex: "#e8dcc8" },
    { code: "077", material: "Materiał", colorName: "Czerwony / Bordeaux", years: "1984-1989", colorHex: "#722f37" },

    // MB-TEX (1xx)
    { code: "101", material: "MB-Tex", colorName: "Czarny", years: "1975-1979", colorHex: "#1a1a1a" },
    { code: "103", material: "MB-Tex", colorName: "Tytoniowy", years: "1975-1979", colorHex: "#6b5b4f" },
    { code: "107", material: "MB-Tex", colorName: "Czerwony", years: "1975-1979", colorHex: "#8b2332" },
    { code: "133", material: "MB-Tex", colorName: "Brazylijski (Brazil)", years: "1979-1982", colorHex: "#5c4033" },
    { code: "134", material: "MB-Tex", colorName: "Palomino", years: "1979-1982", colorHex: "#a67c52" },
    { code: "154", material: "MB-Tex", colorName: "Palomino", years: "1982-1984", colorHex: "#a67c52" },
    { code: "157", material: "MB-Tex", colorName: "Czerwony Henna", years: "1982-1984", colorHex: "#7c3c21" },
    { code: "165", material: "MB-Tex", colorName: "Pergaminowy", years: "1971-1975", colorHex: "#d4c4a8" },
    { code: "167", material: "MB-Tex", colorName: "Bambusowy", years: "1971-1975", colorHex: "#c4a35a" },
    { code: "172", material: "MB-Tex", colorName: "Niebieski", years: "1984-1989", colorHex: "#2c3e50" },
    { code: "174", material: "MB-Tex", colorName: "Palomino / Dattel", years: "1984-1989", colorHex: "#a67c52" },
    { code: "175", material: "MB-Tex", colorName: "Grzybowy / Kremowy Beż", years: "1984-1989", colorHex: "#c9b896" },
    { code: "178", material: "MB-Tex", colorName: "Szary", years: "1984-1989", colorHex: "#6b6b6b" },

    // SKÓRA (2xx)
    { code: "201", material: "Skóra", colorName: "Czarny", years: "1975-1979", colorHex: "#1a1a1a" },
    { code: "205", material: "Skóra", colorName: "Pergaminowy", years: "1975-1979", colorHex: "#d4c4a8" },
    { code: "231", material: "Skóra", colorName: "Czarny", years: "1979-1982", colorHex: "#1a1a1a" },
    { code: "232", material: "Skóra", colorName: "Niebieski", years: "1979-1982", colorHex: "#2c3e50" },
    { code: "233", material: "Skóra", colorName: "Brazylijski (Brazil)", years: "1979-1982", colorHex: "#5c4033" },
    { code: "234", material: "Skóra", colorName: "Szafranowy / Palomino / Dattel", years: "1979-1982", colorHex: "#b8860b" },
    { code: "235", material: "Skóra", colorName: "Grzybowy / Kremowy", years: "1979-1982", colorHex: "#c9b896" },
    { code: "251", material: "Skóra", colorName: "Antracytowy / Czarny", years: "1982-1984", colorHex: "#2a2a2a" },
    { code: "254", material: "Skóra", colorName: "Palomino", years: "1982-1984", colorHex: "#a67c52" },
    { code: "255", material: "Skóra", colorName: "Kremowy", years: "1982-1984", colorHex: "#e8dcc8" },
    { code: "261", material: "Skóra", colorName: "Czarny", years: "1971-1975", colorHex: "#1a1a1a" },
    { code: "265", material: "Skóra", colorName: "Pergaminowy", years: "1971-1975", colorHex: "#d4c4a8" },
    { code: "271", material: "Skóra", colorName: "Czarny", years: "1984-1989", colorHex: "#1a1a1a" },
    { code: "272", material: "Skóra", colorName: "Niebieski", years: "1984-1989", colorHex: "#2c3e50" },
    { code: "274", material: "Skóra", colorName: "Dattel / Palomino", years: "1984-1989", colorHex: "#a67c52" },
    { code: "275", material: "Skóra", colorName: "Grzybowy / Beżowy", years: "1984-1989", colorHex: "#c9b896" },
    { code: "277", material: "Skóra", colorName: "Średnia Czerwień (Medium Red)", years: "1984-1989", colorHex: "#8b2332" },
    { code: "278", material: "Skóra", colorName: "Szary", years: "1984-1989", colorHex: "#6b6b6b" },

    // WELUR (9xx)
    { code: "901", material: "Welur", colorName: "Antracytowy", years: "1975-1979", colorHex: "#2a2a2a" },
    { code: "902", material: "Welur", colorName: "Niebieski", years: "1975", colorHex: "#2c3e50" },
    { code: "904", material: "Welur", colorName: "Bambusowy", years: "1975", colorHex: "#c4a35a" },
    { code: "905", material: "Welur", colorName: "Pergaminowy", years: "1975", colorHex: "#d4c4a8" },
    { code: "931", material: "Welur", colorName: "Czarny (Noir)", years: "1979-1981", colorHex: "#1a1a1a" },
    { code: "961", material: "Welur", colorName: "Antracytowy", years: "1970-1975", colorHex: "#2a2a2a" },
    { code: "965", material: "Welur", colorName: "Pergaminowy / Grzybowy", years: "1971-1975", colorHex: "#c9b896" },
];
