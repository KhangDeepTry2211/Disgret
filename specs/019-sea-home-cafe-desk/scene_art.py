"""Generates the scene props for spec 019 in the soft 3D look of the mascots.

Usage (from the app folder):  python -I specs/019-sea-home-cafe-desk/scene_art.py

Reuses the shapes and soft shading of specs/018-mascot-family/mascot_art.py (radial gradients in
userSpaceOnUse, tonal outlines, soft shadows). Desk files share one 312x230 canvas in mascot units
(1 unit = 1 unit of the 240x200 mascot canvas): the desk top is at y 64, which MascotAtDesk lines
up with 0.76 of the mascot's height, so the face stays visible and the props sit on the desk.
"""
import importlib.util
import os

HERE = os.path.dirname(os.path.abspath(__file__))
spec = importlib.util.spec_from_file_location(
    'mascot_art', os.path.join(HERE, '..', '018-mascot-family', 'mascot_art.py'))
art = importlib.util.module_from_spec(spec)
spec.loader.exec_module(art)
E, P, Doc, render = art.E, art.P, art.Doc, art.render
fill, spot, tube, stroke, shine = art.fill, art.spot, art.tube, art.stroke, art.shine
light, shade = art.light, art.shade

OUT = os.path.normpath(os.path.join(HERE, '..', '..', 'assets', 'scene'))
DESK_W, DESK_H = 312, 230
WOOD, WOOD_TOP, WOOD_DARK = '#C98A5A', '#E7B98A', '#A86D40'
ROCK, CORAL, KELP = '#8E9BB5', '#F06A8A', '#3FB37A'


def save(name, doc, width=DESK_W, height=DESK_H):
    defs = f'<defs>{"".join(doc.defs)}</defs>\n' if doc.defs else ''
    text = (f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {width} {height}">\n'
            + defs + '\n'.join(doc.body) + '\n</svg>\n')
    os.makedirs(OUT, exist_ok=True)
    with open(os.path.join(OUT, f'{name}.svg'), 'w', encoding='utf-8', newline='\n') as f:
        f.write(text)


def drawn(parts):
    doc = Doc('soft')
    render(doc, parts)
    return doc


# ---------- desks ----------

def desk_wood():
    return drawn([
        fill(P('M24 92 H288 V150 Q288 160 278 160 H34 Q24 160 24 150 Z'), WOOD),
        stroke(P('M112 106 H200 V130 H112 Z'), WOOD_DARK, 2.5),
        spot(E(156, 118, 4), '#F2D39B'),
        fill(P('M12 72 Q12 62 24 62 H288 Q300 62 300 72 V84 Q300 94 288 94 H24 Q12 94 12 84 Z'),
             WOOD_TOP),
        stroke(P('M30 70 H130 M160 76 H280'), light(WOOD_TOP, 0.4), 2),
    ])


def desk_coral():
    return drawn([
        fill(P('M100 90 Q92 150 66 226 Q156 236 246 226 Q220 150 212 90 Z'), ROCK),
        spot(E(124, 130, 10, 6), shade(ROCK, 0.12)),
        spot(E(190, 176, 12, 7), shade(ROCK, 0.12)),
        spot(E(140, 206, 9, 5), shade(ROCK, 0.12)),
        fill(E(80, 206, 13), CORAL), fill(E(66, 194, 9), CORAL), fill(E(94, 192, 8), CORAL),
        tube(P('M236 226 Q228 196 240 172 Q250 150 238 118'), KELP, 7),
        fill(P('M156 200 l4 -9 4 9 -9 -5 h10 z'), '#FF8A65'),
        fill(P('M10 74 Q16 60 40 62 Q90 56 156 60 Q226 56 272 62 Q298 62 302 76 Q300 92 276 94 '
               'Q156 98 36 94 Q10 92 10 74 Z'), '#B7C2D6'),
        stroke(P('M40 70 Q90 66 130 70 M180 70 Q230 66 268 72'), '#DDE4F0', 2),
        shine(E(60, 66, 14, 3)),
    ])


# ---------- props on the desk ----------

def notebook():
    return drawn([
        fill(P('M104 88 L108 72 L154 68 L154 84 Z'), '#FFFFFF'),
        fill(P('M158 68 L204 72 L208 88 L158 84 Z'), '#FFFFFF'),
        stroke(P('M114 76 L148 73 M113 80 L148 77 M164 73 L198 76 M164 77 L199 80'), '#9FC4E8', 1.5),
        tube(P('M156 68 V86'), '#F2B88A', 3),
    ])


def pen():
    """A pencil whose tip is at (150, 78): MascotAtDesk slides it along the notebook lines."""
    return drawn([
        fill(P('M150 78 L156 68 L188 40 L196 48 L164 76 Z'), '#FFC93C'),
        fill(P('M150 78 L156 68 L164 76 Z'), '#F2D39B'),
        fill(P('M188 40 L196 48 L201 43 L193 35 Z'), '#FF8FA3'),
    ])


def laptop():
    return drawn([
        fill(P('M196 88 L214 70 L298 70 L284 88 Z'), '#C7D0DE'),
        stroke(P('M210 78 L282 78 M206 83 L278 83'), '#9AA6BA', 2),
        fill(P('M214 70 L222 22 L300 22 L298 70 Z'), '#8E9BB5'),
        spot(E(260, 46, 8, 6), '#DDE4F0'),
    ])


def laptop_keys():
    """Keys that light up while Gret types (blinked on and off)."""
    doc = Doc('soft')
    for x, y in ((222, 78), (240, 78), (258, 83), (232, 83), (270, 78)):
        doc.add(f'<rect x="{x}" y="{y - 2}" width="8" height="3" rx="1.5" fill="#7FE7FF"/>')
    return doc


def book():
    return drawn([
        fill(P('M44 90 L50 70 Q74 64 98 70 L98 90 Q74 84 44 90 Z'), '#FFF7E8'),
        fill(P('M98 70 Q122 64 146 70 L152 90 Q122 84 98 90 Z'), '#FFF7E8'),
        stroke(P('M56 76 Q74 72 92 75 M56 81 Q74 77 92 80 M104 75 Q122 72 140 76'), '#C9B79A', 1.5),
        fill(P('M40 92 L44 90 Q74 84 98 90 Q122 84 152 90 L156 92 Q122 88 98 94 Q74 88 40 92 Z'),
             '#5B8FD6'),
    ])


def book_page():
    """The page that turns, hinged on the spine at x 98."""
    return drawn([fill(P('M98 70 Q122 64 146 70 L152 90 Q122 84 98 90 Z'), '#FFFDF6')])


# ---------- Quán San Hô, cosy (spec 019 user story 2) ----------
# Seats share the desk canvas: the friend sits behind the table (top at y 64), the chair back
# shows around it.

CREAM, TEAL_CUP = '#FFF7E8', '#4CC9F0'


def cafe_chair():
    return drawn([
        fill(P('M58 70 Q58 14 92 12 H220 Q254 14 254 70 Z'), '#B07A4C'),
        spot(P('M74 66 Q74 28 98 26 H214 Q238 28 238 66 Z'), '#C98A5A'),
    ])


def cafe_table():
    return drawn([
        fill(P('M146 92 H166 L170 196 H142 Z'), WOOD_DARK),
        fill(E(156, 206, 46, 9), WOOD_DARK),
        fill(E(156, 78, 98, 18), WOOD_TOP),
        stroke(P('M80 76 Q156 66 232 76'), light(WOOD_TOP, 0.4), 2),
    ])


def cafe_cup():
    """A cup on the right of the table, with steam wisps."""
    return drawn([
        fill(P('M206 54 H232 L229 76 Q219 82 209 76 Z'), CREAM),
        tube(P('M232 60 Q242 62 231 70'), CREAM, 3),
        spot(E(219, 55, 12, 3), '#8B5A3C'),
        stroke(P('M214 46 Q210 38 216 30 M224 46 Q220 36 226 26'), '#FFFFFF', 2.5),
    ])


def cafe_maths():
    return drawn([
        fill(P('M104 72 L110 52 H140 L136 72 Z'), '#5B8FD6'),
        spot(P('M114 56 H134 L133 61 H113 Z'), '#DDEBFF'),
        stroke(P('M114 65 h4 M122 65 h4 M130 65 h3 M113 69 h4 M121 69 h4'), '#FFFFFF', 2),
        fill(P('M146 74 L196 66 L198 72 L148 80 Z'), '#FFC93C'),
        stroke(P('M156 76 v-3 M166 74 v-3 M176 73 v-3 M186 71 v-3'), '#B8860B', 1.5),
    ])


def cafe_literature():
    return drawn([
        fill(P('M100 76 L106 60 Q128 56 152 62 L152 78 Q128 72 100 76 Z'), CREAM),
        fill(P('M152 62 Q176 56 198 60 L204 76 Q176 72 152 78 Z'), CREAM),
        stroke(P('M112 66 Q128 63 146 66 M112 70 Q128 67 146 70 M158 65 Q176 62 194 65'),
               '#C9B79A', 1.5),
        fill(P('M96 78 L100 76 Q128 72 152 78 Q176 72 204 76 L208 78 Q176 75 152 81 Q128 75 96 78 Z'),
             '#E85D5D'),
    ])


def cafe_english():
    doc = drawn([
        fill(P('M104 74 L108 52 L136 54 L132 76 Z'), '#FFFFFF'),
        fill(P('M140 76 L146 56 L172 60 L166 80 Z'), '#FFF0B8'),
        fill(P('M176 76 L184 56 L208 62 L200 80 Z'), '#DFF7FC'),
    ])
    for x, y, letter, colour in ((114, 70, 'A', '#E85D5D'), (151, 73, 'B', '#5B8FD6'),
                                 (186, 74, 'C', '#3FB37A')):
        doc.add(f'<text x="{x}" y="{y}" font-family="sans-serif" font-weight="bold" '
                f'font-size="14" fill="{colour}">{letter}</text>')
    return doc


def cafe_biology():
    return drawn([
        fill(P('M140 80 L136 62 H176 L172 80 Z'), '#F2B88A'),
        fill(E(146, 50, 10, 6, -30), KELP), fill(E(166, 48, 10, 6, 30), KELP),
        fill(E(156, 40, 7, 11), '#5BC98A'),
        spot(E(156, 62, 20, 3), '#8B5A3C'),
    ])


def cafe_counter():
    return drawn([
        fill(P('M12 92 H300 V210 Q300 220 290 220 H22 Q12 220 12 210 Z'), WOOD),
        stroke(P('M60 110 V200 M156 110 V200 M252 110 V200'), WOOD_DARK, 2.5),
        fill(P('M4 72 Q4 62 16 62 H296 Q308 62 308 72 V84 Q308 94 296 94 H16 Q4 94 4 84 Z'),
             '#E9D2B5'),
        fill(E(250, 46, 22, 18), '#E85D5D'),
        tube(P('M270 40 Q286 34 284 50'), '#C04769', 4),
        fill(P('M236 30 H264 L260 22 H240 Z'), '#C04769'),
        stroke(P('M244 16 Q240 8 246 0 M256 16 Q252 6 258 -2'), '#FFFFFF', 2.5),
        fill(P('M40 50 H64 L61 72 Q52 77 43 72 Z'), CREAM),
        fill(P('M74 54 H96 L93 72 Q85 76 77 72 Z'), TEAL_CUP),
        fill(P('M150 40 H196 V72 H150 Z'), '#3D4A3F'),
        stroke(P('M158 50 h30 M158 58 h22 M158 66 h26'), '#FFFFFF', 1.5),
    ])


def cafe_curtains():
    """Tied curtains for an arched window (100x270, stretched over the window)."""
    doc = drawn([
        fill(P('M0 20 Q22 18 30 90 Q20 150 4 160 Q0 120 0 20 Z'), '#E8604A'),
        fill(P('M100 20 Q78 18 70 90 Q80 150 96 160 Q100 120 100 20 Z'), '#E8604A'),
        fill(E(20, 112, 9, 5), '#FFC93C'), fill(E(80, 112, 9, 5), '#FFC93C'),
    ])
    return doc


def cafe_plant_hanging():
    """A pot hanging from the ceiling (80x140)."""
    return drawn([
        stroke(P('M40 0 V40 M40 40 L22 64 M40 40 L58 64'), '#8B6B4C', 2),
        fill(P('M18 62 H62 L56 88 Q40 94 24 88 Z'), '#F2B88A'),
        tube(P('M26 70 Q16 96 22 122'), KELP, 6),
        tube(P('M40 72 Q42 104 36 136'), '#5BC98A', 6),
        tube(P('M54 70 Q66 94 60 116'), KELP, 6),
        fill(E(30, 66, 10, 6, -20), '#5BC98A'), fill(E(50, 66, 10, 6, 20), KELP),
    ])


def cafe_plant_pot():
    """A big potted plant for a floor corner (120x160)."""
    return drawn([
        fill(E(40, 56, 22, 34, -25), KELP), fill(E(82, 52, 22, 34, 25), '#5BC98A'),
        fill(E(60, 40, 18, 32), KELP), fill(E(28, 92, 18, 12, -40), '#5BC98A'),
        fill(E(94, 90, 18, 12, 40), KELP),
        fill(P('M30 100 H90 L82 152 Q60 160 38 152 Z'), '#E8604A'),
        stroke(P('M34 112 H86'), '#C04769', 3),
    ])


# ---------- Gret's home (spec 019 user story 5) ----------
# Two rock ledges beside Gret (220x160, ledge top at y 112): the right one carries the shell house
# and one decoration spot, the left one two spots. Decorations are 80x80 and stand at y 76.

def home_ledge():
    return drawn([
        fill(P('M6 116 Q10 104 40 106 Q110 100 180 106 Q214 106 214 118 Q210 140 180 150 '
               'Q110 162 40 152 Q8 144 6 116 Z'), ROCK),
        spot(E(60, 138, 14, 6), shade(ROCK, 0.12)),
        spot(E(160, 142, 12, 5), shade(ROCK, 0.12)),
        fill(P('M14 112 Q40 100 110 104 Q180 100 206 112 Q180 120 110 118 Q40 122 14 112 Z'),
             '#FBE3B0'),
        fill(E(30, 140, 9), CORAL), fill(E(42, 148, 6), CORAL),
        tube(P('M196 150 Q202 132 194 118'), KELP, 5),
    ])


def home_house():
    doc = drawn([
        fill(P('M96 112 Q90 60 130 34 Q150 20 168 40 Q206 72 202 112 Z'), '#FFF1E0'),
        stroke(P('M110 108 Q112 70 140 48 M140 48 Q170 70 186 108 M126 50 Q150 30 168 46'),
               '#E2B38A', 3),
        fill(P('M134 112 V88 Q146 74 158 88 V112 Z'), '#7A4E2D'),
        fill(E(166, 70, 8), '#FFE58A'),
        fill(P('M118 84 H152 V96 H118 Z'), '#C98A5A'),
        tube(P('M196 60 Q206 62 204 74'), '#8B6B4C', 2),
        fill(E(204, 82, 6, 8), '#FFC93C'),
        shine(E(118, 56, 10, 5, -30)),
    ])
    doc.add('<text x="135" y="94" text-anchor="middle" font-family="sans-serif" '
            'font-weight="bold" font-size="9" fill="#FFF7E8">Gret</text>')
    return doc


def deco_spot():
    doc = Doc('soft')
    doc.add('<ellipse cx="40" cy="74" rx="26" ry="7" fill="none" stroke="#FFFFFF" '
            'stroke-opacity="0.7" stroke-width="2" stroke-dasharray="5 4"/>')
    return doc


def deco_jelly_lantern():
    return drawn([
        tube(P('M40 74 V44'), '#8B6B4C', 3),
        fill(P('M22 40 Q22 14 40 14 Q58 14 58 40 Q49 44 40 40 Q31 44 22 40 Z'), '#D9C7FF'),
        spot(E(40, 30, 8), '#FFF6C8'),
        tube(P('M28 42 Q26 52 30 60 M52 42 Q54 52 50 60'), '#C9B5FF', 3),
    ])


def deco_sand_castle():
    return drawn([
        fill(P('M12 76 V46 H22 V40 H30 V46 H50 V40 H58 V46 H68 V76 Z'), '#F2D39B'),
        fill(P('M28 46 V24 H52 V46 Z'), '#F7DFA9'),
        fill(P('M28 24 L40 10 L52 24 Z'), '#E8604A'),
        fill(P('M34 76 V62 Q40 54 46 62 V76 Z'), '#C98A5A'),
    ])


def deco_mailbox():
    return drawn([
        tube(P('M40 76 V48'), '#8B6B4C', 5),
        fill(P('M18 48 V30 Q18 18 40 18 Q62 18 62 30 V48 Z'), '#F06A8A'),
        stroke(P('M24 34 H56'), '#C04769', 2),
        fill(P('M60 22 V8 L72 12 L60 16'), '#FFC93C'),
    ])


def deco_kelp_swing():
    return drawn([
        tube(P('M18 76 Q14 40 26 6'), KELP, 6),
        tube(P('M62 76 Q66 40 54 6'), KELP, 6),
        stroke(P('M30 12 V50 M50 12 V50'), '#8B6B4C', 2),
        fill(P('M24 50 H56 V56 H24 Z'), WOOD_TOP),
    ])


def deco_coral_garden():
    return drawn([
        fill(E(22, 60, 12), CORAL), fill(E(14, 50, 8), CORAL),
        fill(E(42, 50, 14), '#FFB74D'), fill(E(36, 36, 8), '#FFB74D'),
        fill(E(62, 60, 11), '#B48CF0'), fill(E(66, 48, 7), '#B48CF0'),
        spot(E(40, 74, 32, 4), '#FBE3B0'),
    ])


def deco_treasure_chest():
    return drawn([
        fill(P('M12 74 V46 H68 V74 Z'), WOOD),
        fill(P('M12 46 Q12 26 40 26 Q68 26 68 46 Z'), WOOD_TOP),
        stroke(P('M12 46 H68 M24 30 V74 M56 30 V74'), '#FFC93C', 3),
        fill(P('M36 44 H44 V54 H36 Z'), '#FFC93C'),
        fill(E(28, 22, 4), '#FFE58A'), fill(E(50, 20, 3), '#FFE58A'),
    ])


def main():
    for name, doc in (('desk_wood', desk_wood()), ('desk_coral', desk_coral()),
                      ('notebook', notebook()), ('pen', pen()), ('laptop', laptop()),
                      ('laptop_keys', laptop_keys()), ('book', book()),
                      ('book_page', book_page()), ('cafe_chair', cafe_chair()),
                      ('cafe_table', cafe_table()), ('cafe_cup', cafe_cup()),
                      ('cafe_maths', cafe_maths()), ('cafe_literature', cafe_literature()),
                      ('cafe_english', cafe_english()), ('cafe_biology', cafe_biology()),
                      ('cafe_counter', cafe_counter())):
        save(name, doc)
    save('cafe_curtains', cafe_curtains(), 100, 270)
    save('cafe_plant_hanging', cafe_plant_hanging(), 80, 140)
    save('cafe_plant_pot', cafe_plant_pot(), 120, 160)
    save('home_ledge', home_ledge(), 220, 160)
    save('home_house', home_house(), 220, 160)
    for name, make in (('deco_spot', deco_spot), ('deco_jelly_lantern', deco_jelly_lantern),
                       ('deco_sand_castle', deco_sand_castle), ('deco_mailbox', deco_mailbox),
                       ('deco_kelp_swing', deco_kelp_swing),
                       ('deco_coral_garden', deco_coral_garden),
                       ('deco_treasure_chest', deco_treasure_chest)):
        save(name, make(), 80, 80)
    print('wrote', len(os.listdir(OUT)), 'files in', OUT)


if __name__ == '__main__':
    main()
