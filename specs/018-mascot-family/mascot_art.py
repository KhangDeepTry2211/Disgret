"""Generates the mascot drawings for spec 018 (three styles, ten species, eleven faces).

Usage (from the app folder):  python -I specs/018-mascot-family/mascot_art.py

Every shape is defined once on the shared 240x200 canvas and rendered in each style:
  classic  flat fills with a darker back copy, no outline (only files that do not exist yet:
           today's hand-made classic drawings are kept)
  flat     warm dark-brown outline, flat fills, bead eyes
  soft     radial shading (userSpaceOnUse, so Android vector drawables can reuse it), an outline
           in a darker shade of the fill, a soft shadow under the body, freckled cheeks and glossy
           bean eyes ("C - Hat dau bong")
The face sits at the same place for every species: eyes (92,104)/(140,104), mouth (116,130),
cheeks (76,124)/(156,124). Gret's body keeps ellipse (115,112) rx72 ry62 so outfits still fit.
"""
import math
import os
import re

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..', 'assets', 'mascot')
HEAD = '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 240 200">'

OUTLINE = '#4A3428'   # flat style outline
FLAT_INK = '#2A1C14'  # flat style eyes and mouth
SOFT_INK = '#0A1633'  # soft style eyes and mouth
CLASSIC_INK = '#0A2A6B'
EYE_L, EYE_R = (92, 104), (140, 104)


# ---------- colours ----------

def rgb(c):
    c = c.lstrip('#')
    return [int(c[i:i + 2], 16) for i in (0, 2, 4)]


def hexc(v):
    return '#' + ''.join(f'{max(0, min(255, round(x))):02X}' for x in v)


def mix(a, b, t):
    return hexc([x + (y - x) * t for x, y in zip(rgb(a), rgb(b))])


def light(c, t=0.5):
    return mix(c, '#FFFFFF', t)


def shade(c, t=0.25):
    return mix(c, '#000000', t)


# ---------- shapes ----------

class Shape:
    """An ellipse (with optional rotation) or a path in absolute coordinates."""

    def __init__(self, tag, attrs, box, rotate=None):
        self.tag, self.attrs, self.box, self.rotate = tag, attrs, box, rotate

    def svg(self, extra):
        attrs = ' '.join(f'{k}="{v:g}"' if isinstance(v, (int, float)) else f'{k}="{v}"'
                         for k, v in self.attrs.items())
        rot = (f' transform="rotate({self.rotate:g} {self.attrs["cx"]:g} {self.attrs["cy"]:g})"'
               if self.rotate else '')
        return f'<{self.tag} {attrs}{rot} {extra}/>'

    def shrunk(self, factor):
        """A copy scaled towards the top-left of its box (the classic two-tone look)."""
        if self.tag != 'ellipse':
            return None
        a = self.attrs
        rx, ry = a['rx'] * factor, a['ry'] * factor
        x0, y0 = a['cx'] - a['rx'], a['cy'] - a['ry']
        return E(x0 + rx, y0 + ry, rx, ry, self.rotate)


def E(cx, cy, rx, ry=None, rotate=None):
    ry = rx if ry is None else ry
    return Shape('ellipse', {'cx': cx, 'cy': cy, 'rx': rx, 'ry': ry},
                 (cx - rx, cy - ry, cx + rx, cy + ry), rotate)


def P(d):
    nums = [float(n) for n in re.findall(r'-?\d+(?:\.\d+)?', d)]
    xs, ys = nums[0::2], nums[1::2]
    return Shape('path', {'d': d}, (min(xs), min(ys), max(xs), max(ys)))


def heart(cx, cy, s):
    return P(f'M{cx:g} {cy + s * 0.9:g} C{cx - s * 1.45:g} {cy + s * 0.05:g} {cx - s * 0.95:g} '
             f'{cy - s * 1.15:g} {cx:g} {cy - s * 0.4:g} C{cx + s * 0.95:g} {cy - s * 1.15:g} '
             f'{cx + s * 1.45:g} {cy + s * 0.05:g} {cx:g} {cy + s * 0.9:g} Z')


def star(cx, cy, r):
    i = r * 0.3
    return P(f'M{cx:g} {cy - r:g} L{cx + i:g} {cy - i:g} L{cx + r:g} {cy:g} L{cx + i:g} {cy + i:g} '
             f'L{cx:g} {cy + r:g} L{cx - i:g} {cy + i:g} L{cx - r:g} {cy:g} L{cx - i:g} {cy - i:g} Z')


# ---------- parts ----------
# fill   : a coloured shape; outlined in flat and soft. main=True gets the classic two-tone look.
# spot   : a patch on the body (belly, spots); never outlined.
# tube   : a thick coloured line (tail, legs, tentacles); outlined as a wider line behind it.
# stroke : a pattern line (shell plates); same in every style, darker in soft.
# round  : a shape whose corners are rounded by a same-colour stroke of width w (the star).
# shine  : a white highlight.

def fill(shape, colour, main=False, outline=True):
    return ('fill', shape, colour, {'main': main, 'outline': outline})


def spot(shape, colour):
    return ('spot', shape, colour, {})


def tube(shape, colour, width):
    return ('tube', shape, colour, {'width': width})


def stroke(shape, colour, width):
    return ('stroke', shape, colour, {'width': width})


def rounded(shape, colour, width):
    return ('round', shape, colour, {'width': width})


def shine(shape, opacity=0.5):
    return ('shine', shape, '#FFFFFF', {'opacity': opacity})


class Doc:
    """One SVG file; collects the gradients it needs."""

    def __init__(self, style):
        self.style, self.defs, self.body = style, [], []

    def gradient(self, box, inner, mid, outer, cx=0.36, cy=0.3, reach=0.85):
        gid = f'g{len(self.defs)}'
        x0, y0, x1, y1 = box
        w, h = x1 - x0, y1 - y0
        stops = (f'<stop offset="0" stop-color="{inner}"/><stop offset="0.45" '
                 f'stop-color="{mid}"/><stop offset="1" stop-color="{outer}"/>')
        self.defs.append(
            f'<radialGradient id="{gid}" gradientUnits="userSpaceOnUse" cx="{x0 + w * cx:.1f}" '
            f'cy="{y0 + h * cy:.1f}" r="{max(w, h) * reach:.1f}">{stops}</radialGradient>')
        return f'url(#{gid})'

    def add(self, element):
        self.body.append(element)

    def text(self):
        defs = f'<defs>{"".join(self.defs)}</defs>\n' if self.defs else ''
        return HEAD + '\n' + defs + '\n'.join(self.body) + '\n</svg>\n'


def tonal(colour):
    return shade(colour, 0.38)


def render(doc, parts):
    style = doc.style
    for kind, shape, colour, opt in parts:
        if kind == 'fill':
            if style == 'classic':
                back = shape.shrunk(0.94) if opt['main'] else None
                if back:
                    doc.add(shape.svg(f'fill="{shade(colour, 0.12)}"'))
                    doc.add(back.svg(f'fill="{colour}"'))
                else:
                    doc.add(shape.svg(f'fill="{colour}"'))
            elif style == 'flat':
                line = f' stroke="{OUTLINE}" stroke-width="4" stroke-linejoin="round"' \
                    if opt['outline'] else ''
                doc.add(shape.svg(f'fill="{colour}"{line}'))
            else:
                paint = doc.gradient(shape.box, light(colour, 0.55), colour, shade(colour, 0.22))
                line = f' stroke="{tonal(colour)}" stroke-width="3" stroke-linejoin="round"' \
                    if opt['outline'] else ''
                doc.add(shape.svg(f'fill="{paint}"{line}'))
        elif kind == 'spot':
            if style == 'soft':
                paint = doc.gradient(shape.box, light(colour, 0.6), colour, shade(colour, 0.08),
                                     cx=0.5, cy=0.25, reach=0.9)
                doc.add(shape.svg(f'fill="{paint}"'))
            else:
                doc.add(shape.svg(f'fill="{colour}"'))
        elif kind == 'tube':
            w = opt['width']
            caps = 'fill="none" stroke-linecap="round" stroke-linejoin="round"'
            if style == 'flat':
                doc.add(shape.svg(f'{caps} stroke="{OUTLINE}" stroke-width="{w + 6:g}"'))
            elif style == 'soft':
                doc.add(shape.svg(f'{caps} stroke="{tonal(colour)}" stroke-width="{w + 5:g}"'))
            doc.add(shape.svg(f'{caps} stroke="{colour}" stroke-width="{w:g}"'))
            if style == 'soft':
                doc.add(shape.svg(f'{caps} stroke="{light(colour, 0.45)}" '
                                  f'stroke-width="{max(2, w * 0.3):g}" stroke-opacity="0.7"'))
        elif kind == 'stroke':
            ink = shade(colour, 0.12) if style == 'soft' else colour
            doc.add(shape.svg(f'fill="none" stroke="{ink}" stroke-width="{opt["width"]:g}" '
                              f'stroke-linecap="round" stroke-linejoin="round"'))
        elif kind == 'round':
            w = opt['width']
            join = 'stroke-linejoin="round"'
            if style == 'classic':
                doc.add(shape.svg(f'fill="{colour}" stroke="{colour}" stroke-width="{w}" {join}'))
            elif style == 'flat':
                doc.add(shape.svg(f'fill="{OUTLINE}" stroke="{OUTLINE}" stroke-width="{w + 8}" {join}'))
                doc.add(shape.svg(f'fill="{colour}" stroke="{colour}" stroke-width="{w}" {join}'))
            else:
                doc.add(shape.svg(f'fill="{tonal(colour)}" stroke="{tonal(colour)}" '
                                  f'stroke-width="{w + 6}" {join}'))
                paint = doc.gradient(shape.box, light(colour, 0.55), colour, shade(colour, 0.2))
                doc.add(shape.svg(f'fill="{paint}" stroke="{paint}" stroke-width="{w}" {join}'))
        elif kind == 'shine':
            alpha = opt['opacity'] + (0.1 if style == 'soft' else 0)
            doc.add(shape.svg(f'fill="#FFFFFF" fill-opacity="{alpha:g}"'))


def shadow(doc, cx, width):
    """A soft shadow on the sea floor under the mascot (soft style only)."""
    gid = f'g{len(doc.defs)}'
    doc.defs.append(
        f'<radialGradient id="{gid}" gradientUnits="userSpaceOnUse" cx="{cx}" cy="192" '
        f'r="{width}"><stop offset="0" stop-color="#000000" stop-opacity="0.24"/>'
        f'<stop offset="1" stop-color="#000000" stop-opacity="0"/></radialGradient>')
    doc.add(f'<ellipse cx="{cx}" cy="192" rx="{width}" ry="7" fill="url(#{gid})"/>')


# ---------- species ----------

def gret():
    fin = '#1BB8D4'
    return [
        fill(P('M86 66 Q116 0 150 64 Z'), fin),
        fill(E(115, 112, 72, 62), '#2CCCE6', main=True),
        spot(E(112, 142, 44, 25), '#C6F1FA'),
        fill(P('M146 146 Q170 150 166 172 Q148 166 140 152 Z'), fin),
        shine(E(82, 74, 18, 9, -28)),
        shine(E(64, 90, 4), 0.6),
    ]


def gret_tail():
    return [
        fill(P('M160 112 L222 76 Q210 112 222 148 Z'), '#1BB8D4'),
        stroke(P('M182 112 L212 94 M182 112 L212 130'), '#1597B2', 3),
    ]


def crab():
    leg = '#E8604A'
    claw = '#F26B4F'
    return [
        fill(E(152, 76, 50), '#F7D79B'),
        stroke(P('M118 76 A34 34 0 1 1 186 76 A26 26 0 1 1 134 76 A18 18 0 1 1 170 76 '
                 'A10 10 0 1 1 150 76'), '#C9A06A', 5),
        tube(P('M70 166 L54 188'), leg, 7),
        tube(P('M90 172 L82 192'), leg, 7),
        tube(P('M140 172 L148 192'), leg, 7),
        tube(P('M160 166 L176 188'), leg, 7),
        fill(E(115, 122, 66, 54), '#FF8A65', main=True),
        spot(E(114, 150, 40, 20), '#FFC2A8'),
        fill(P('M50 128 Q20 120 22 98 Q34 108 44 104 Q30 92 40 80 Q60 92 58 118 Z'), claw),
        fill(P('M180 128 Q210 120 208 98 Q196 108 186 104 Q200 92 190 80 Q170 92 172 118 Z'), claw),
        shine(E(84, 86, 14, 7, -24), 0.45),
    ]


def octopus():
    arm = '#9A6FE0'
    return [
        fill(P('M62 140 Q50 176 30 186 Q54 192 74 160 Z'), arm),
        fill(P('M88 150 Q84 184 70 196 Q96 196 104 160 Z'), arm),
        fill(P('M128 160 Q134 194 160 196 Q148 180 146 150 Z'), arm),
        fill(P('M168 140 Q182 176 206 184 Q184 190 158 160 Z'), arm),
        fill(E(115, 106, 70, 64), '#B48CF0', main=True),
        spot(E(114, 146, 42, 20), '#D9C6F7'),
        spot(E(72, 70, 6), arm),
        spot(E(160, 66, 8), arm),
        spot(E(146, 48, 4), arm),
        shine(E(86, 66, 15, 8, -28), 0.45),
    ]


def turtle():
    flipper = '#7FCB98'
    return [
        fill(E(54, 176, 24, 13, -20), '#6DBE8C'),
        fill(E(178, 176, 24, 13, 20), '#6DBE8C'),
        fill(E(116, 96, 98, 76), '#3E8E5E'),
        stroke(E(116, 96, 95, 73), '#9BD0A8', 6),
        stroke(P('M116 22 L150 40 L150 76 L116 94 L82 76 L82 40 Z'), '#2F7049', 5),
        stroke(P('M82 40 L40 52 M150 40 L192 52 M82 76 L32 96 M150 76 L200 96'), '#2F7049', 5),
        fill(E(116, 122, 64, 56), '#9ED9A9', main=True),
        spot(E(116, 156, 40, 16), '#CDEFD3'),
        fill(E(44, 148, 22, 12, -35), flipper),
        fill(E(188, 148, 22, 12, 35), flipper),
        shine(E(88, 86, 14, 7, -24), 0.45),
    ]


def starfish():
    points = []
    for i in range(10):
        angle = math.radians(-90 + i * 36)
        r = 92 if i % 2 == 0 else 52
        points.append((116 + r * math.cos(angle), 104 + r * math.sin(angle) * 0.95))
    d = 'M' + ' L'.join(f'{x:.1f} {y:.1f}' for x, y in points) + ' Z'
    dots = []
    for i in range(5):
        angle = math.radians(-90 + i * 72)
        for r, size in ((62, 4), (76, 3)):
            dots.append(spot(E(round(116 + r * math.cos(angle), 1),
                               round(104 + r * math.sin(angle) * 0.95, 1), size), '#FFE0B2'))
    return [
        rounded(P(d), '#FFB74D', 16),
        spot(E(116, 118, 50), '#FFC870'),
        *dots,
        shine(E(88, 84, 13, 7, -24), 0.45),
    ]


def seahorse():
    body, fin = '#FF9AA2', '#FF7F8C'
    return [
        tube(P('M120 158 Q122 188 146 188 Q164 188 164 170 Q164 156 150 156 Q140 158 142 168'),
             body, 16),
        fill(P('M168 90 Q202 92 198 128 Q184 120 166 124 Z'), fin),
        fill(P('M84 70 Q88 40 106 54 Q116 26 128 52 Q144 34 150 68 Z'), fin),
        fill(P('M154 116 Q178 110 198 108 Q208 108 208 117 Q208 126 198 126 Q178 126 154 134 Z'),
             body),
        fill(E(116, 112, 62, 58), body, main=True),
        spot(E(116, 150, 36, 18), '#FFD1DC'),
        shine(E(88, 76, 14, 7, -28)),
    ]


def pufferfish():
    body, fin = '#FFD45E', '#F2B33D'
    spikes = []
    for deg in range(30, 360, 30):
        a = math.radians(deg)
        b1, b2 = math.radians(deg - 8), math.radians(deg + 8)
        x1, y1 = 116 + 60 * math.cos(b1), 112 + 60 * math.sin(b1)
        x2, y2 = 116 + 60 * math.cos(b2), 112 + 60 * math.sin(b2)
        tx, ty = 116 + 82 * math.cos(a), 112 + 80 * math.sin(a)
        spikes.append(fill(P(f'M{x1:.1f} {y1:.1f} L{tx:.1f} {ty:.1f} L{x2:.1f} {y2:.1f} Z'), fin))
    return [
        fill(P('M170 112 L216 82 Q206 112 216 142 Z'), fin),
        *spikes,
        fill(E(116, 112, 66), body, main=True),
        spot(E(116, 150, 44, 22), '#FFF0B8'),
        spot(E(100, 64, 3.5), '#F2C14E'),
        spot(E(124, 56, 4), '#F2C14E'),
        spot(E(144, 70, 3), '#F2C14E'),
        spot(E(80, 80, 3), '#F2C14E'),
        fill(P('M58 126 Q36 130 40 152 Q56 148 64 136 Z'), fin),
        shine(E(86, 76, 15, 8, -28)),
    ]


def jellyfish():
    arm = '#C9B5FF'
    return [
        tube(P('M78 140 Q70 156 78 168 Q86 180 78 192'), arm, 7),
        tube(P('M98 144 Q92 160 98 172 Q104 184 98 194'), arm, 7),
        tube(P('M134 144 Q140 160 134 172 Q128 184 134 194'), arm, 7),
        tube(P('M154 140 Q162 156 154 168 Q146 180 154 192'), arm, 7),
        tube(P('M116 146 Q108 164 118 178 Q126 190 118 198'), '#B9A3F0', 9),
        fill(P('M48 138 Q42 44 116 42 Q190 44 184 138 Q168 148 150 140 Q133 150 116 142 '
               'Q99 150 82 140 Q64 148 48 138 Z'), '#D9C7FF', main=True),
        spot(E(96, 62, 4), '#C4ACFF'),
        spot(E(140, 58, 5), '#C4ACFF'),
        spot(E(160, 76, 3.5), '#C4ACFF'),
        shine(E(80, 76, 15, 8, -32)),
    ]


def penguin():
    navy, orange = '#3A5A8C', '#F7A541'
    return [
        fill(E(96, 186, 17, 8), orange),
        fill(E(136, 186, 17, 8), orange),
        fill(P('M60 108 Q30 128 38 160 Q56 152 68 130 Z'), '#2F4A7A'),
        fill(P('M172 108 Q202 128 194 160 Q176 152 164 130 Z'), '#2F4A7A'),
        fill(E(116, 112, 62, 70), navy, main=True),
        spot(P('M116 90 Q100 70 80 78 Q60 88 64 112 Q68 142 116 152 Q164 142 168 112 '
               'Q172 88 152 78 Q132 70 116 90 Z'), '#FFFFFF'),
        spot(E(116, 160, 36, 20), '#F4F8FF'),
        fill(P('M70 146 Q116 166 162 146 L160 158 Q116 178 72 158 Z'), '#E85D5D'),
        fill(P('M134 160 Q146 174 144 188 L130 186 Q132 174 126 164 Z'), '#E85D5D'),
        fill(P('M109 114 L123 114 L116 123 Z'), orange),
        shine(E(88, 64, 12, 6, -28), 0.4),
    ]


def whale():
    body, dark, water = '#7FB0F0', '#5B8FD6', '#8FD8FF'
    return [
        tube(P('M112 58 Q104 42 92 38'), water, 6),
        tube(P('M112 58 Q120 40 134 36'), water, 6),
        tube(P('M112 58 L112 34'), water, 6),
        fill(P('M176 118 Q196 110 204 88 Q214 98 232 90 Q228 112 210 120 Q222 130 226 146 '
               'Q206 142 188 132 Z'), dark),
        fill(E(112, 120, 84, 60), body, main=True),
        spot(P('M34 140 Q112 194 192 140 Q188 174 112 180 Q38 176 34 140 Z'), '#DDEBFF'),
        stroke(P('M72 162 Q112 176 152 162'), '#B8D0F5', 3),
        fill(P('M70 150 Q50 168 60 182 Q74 172 84 158 Z'), dark),
        shine(E(74, 88, 16, 8, -28)),
    ]


SPECIES = {
    'gret': (gret, 115, 70), 'crab': (crab, 115, 70), 'octopus': (octopus, 118, 78),
    'turtle': (turtle, 116, 86), 'starfish': (starfish, 116, 70),
    'seahorse': (seahorse, 130, 54), 'pufferfish': (pufferfish, 120, 66),
    'jellyfish': (jellyfish, 116, 56), 'penguin': (penguin, 116, 56), 'whale': (whale, 122, 82),
}
NEW_SPECIES = ['seahorse', 'pufferfish', 'jellyfish', 'penguin', 'whale']


# ---------- faces ----------

def ink(style):
    return {'classic': CLASSIC_INK, 'flat': FLAT_INK, 'soft': SOFT_INK}[style]


def line(doc, d, width=4):
    doc.add(f'<path d="{d}" fill="none" stroke="{ink(doc.style)}" stroke-width="{width:g}" '
            f'stroke-linecap="round" stroke-linejoin="round"/>')


def open_eye(doc, x, y, dy=0):
    y += dy
    s = doc.style
    if s == 'classic':
        doc.add(f'<circle cx="{x}" cy="{y}" r="17" fill="#FFFFFF"/>')
        doc.add(f'<circle cx="{x + 2}" cy="{y + 3}" r="9" fill="{CLASSIC_INK}"/>')
        doc.add(f'<circle cx="{x + 6}" cy="{y - 2}" r="3.5" fill="#FFFFFF"/>')
        doc.add(f'<circle cx="{x - 1.5}" cy="{y + 6.5}" r="1.6" fill="#FFFFFF" fill-opacity="0.85"/>')
    elif s == 'flat':
        doc.add(f'<circle cx="{x}" cy="{y + 2}" r="8.5" fill="{FLAT_INK}"/>')
        doc.add(f'<circle cx="{x + 2.6}" cy="{y - 1}" r="2.8" fill="#FFFFFF"/>')
    else:
        iris = doc.gradient((x - 10, y - 11.5, x + 10, y + 13.5), '#5A78BE', '#24407E', SOFT_INK,
                            cx=0.38, cy=0.3, reach=0.9)
        doc.add(f'<ellipse cx="{x}" cy="{y + 1}" rx="10" ry="12.5" fill="{iris}"/>')
        doc.add(f'<ellipse cx="{x - 2.6}" cy="{y - 4}" rx="3.8" ry="4.6" fill="#FFFFFF"/>')
        doc.add(f'<circle cx="{x + 3.8}" cy="{y + 6.4}" r="1.8" fill="#FFFFFF" fill-opacity="0.9"/>')


def eyes(style, mood):
    doc = Doc(style)
    (lx, ly), (rx, ry) = EYE_L, EYE_R
    if mood in ('happy', 'neutral'):
        open_eye(doc, lx, ly)
        open_eye(doc, rx, ry)
    elif mood == 'sad':
        open_eye(doc, lx, ly, 3)
        open_eye(doc, rx, ry, 3)
        line(doc, 'M78 90 L102 84 M130 84 L154 90')
    elif mood == 'focused':
        open_eye(doc, lx, ly, 2)
        open_eye(doc, rx, ry, 2)
        line(doc, 'M78 84 L102 91 M130 91 L154 84')
    elif mood == 'sleeping':
        line(doc, 'M80 104 Q92 115 104 104 M128 104 Q140 115 152 104')
    elif mood == 'celebrating':
        line(doc, 'M79 110 Q92 92 105 110 M127 110 Q140 92 153 110', 4.5)
    elif mood == 'blink':
        if style == 'classic':
            line(doc, 'M79 106 L105 106 M127 106 L153 106')
        else:
            line(doc, 'M80 105 Q92 111 104 105 M128 105 Q140 111 152 105')
    elif mood == 'love':
        for x, y in (EYE_L, EYE_R):
            hearts_at(doc, x, y + 1, 12.5)
    elif mood == 'surprised':
        for x, y in (EYE_L, EYE_R):
            rim = '' if style == 'classic' else f' stroke="{ink(style)}" stroke-width="2.5"'
            doc.add(f'<circle cx="{x}" cy="{y}" r="15"  fill="#FFFFFF"{rim}/>')
            doc.add(f'<circle cx="{x}" cy="{y + 1}" r="6.5" fill="{ink(style)}"/>')
            doc.add(f'<circle cx="{x + 2}" cy="{y - 1.5}" r="2" fill="#FFFFFF"/>')
    elif mood == 'proud':
        line(doc, 'M80 108 Q92 96 104 108 M128 108 Q140 96 152 108', 4.5)
    elif mood == 'wink':
        open_eye(doc, lx, ly)
        line(doc, 'M128 106 Q140 96 152 106', 4.5)
    return doc.text()


def hearts_at(doc, x, y, size):
    shape = heart(x, y, size)
    if doc.style == 'classic':
        doc.add(shape.svg('fill="#FF5C7A"'))
    elif doc.style == 'flat':
        doc.add(shape.svg(f'fill="#FF5C7A" stroke="{OUTLINE}" stroke-width="2.5" '
                          'stroke-linejoin="round"'))
    else:
        paint = doc.gradient(shape.box, '#FFB3C2', '#FF5C7A', '#D93A5C')
        doc.add(shape.svg(f'fill="{paint}" stroke="#B8324F" stroke-width="2" '
                          'stroke-linejoin="round"'))
    doc.add(f'<ellipse cx="{x - size * 0.45:g}" cy="{y - size * 0.35:g}" rx="{size * 0.2:g}" '
            f'ry="{size * 0.14:g}" fill="#FFFFFF" fill-opacity="0.8"/>')


def mouth(style, mood):
    doc = Doc(style)
    dark = ink(style)
    if mood == 'happy':
        doc.add(f'<path d="M102 127 Q116 144 130 127 Z" fill="{dark}" stroke="{dark}" '
                'stroke-width="2" stroke-linejoin="round"/>')
        doc.add('<ellipse cx="116" cy="135.5" rx="5.5" ry="3.2" fill="#FF8FA3"/>')
    elif mood == 'neutral':
        line(doc, 'M106 130 Q116 137 126 130', 3.5)
    elif mood == 'sad':
        line(doc, 'M106 137 Q116 129 126 137', 3.5)
    elif mood == 'focused':
        line(doc, 'M108 133 L124 133', 3.5)
    elif mood == 'sleeping':
        doc.add(f'<ellipse cx="116" cy="134" rx="4" ry="5" fill="{dark}"/>')
    elif mood == 'celebrating':
        doc.add(f'<path d="M97 125 Q116 154 135 125 Z" fill="{dark}" stroke="{dark}" '
                'stroke-width="2" stroke-linejoin="round"/>')
        doc.add('<ellipse cx="116" cy="140" rx="8" ry="4.5" fill="#FF8FA3"/>')
    elif mood == 'love':
        line(doc, 'M105 129 Q110.5 136 116 130 Q121.5 136 127 129', 3.5)
    elif mood == 'surprised':
        doc.add(f'<ellipse cx="116" cy="135" rx="6.5" ry="8.5" fill="{dark}"/>')
        doc.add('<ellipse cx="116" cy="139" rx="3.5" ry="2.5" fill="#FF8FA3"/>')
    elif mood == 'proud':
        line(doc, 'M101 128 Q116 143 131 128', 4)
    elif mood == 'wink':
        line(doc, 'M104 132 Q118 141 129 126', 3.5)
    return doc.text()


def cheeks(style):
    doc = Doc(style)
    for x in (76, 156):
        if style == 'flat':
            doc.add(f'<ellipse cx="{x}" cy="124" rx="10" ry="6" fill="#FFB3C7"/>')
        else:
            doc.add(f'<ellipse cx="{x}" cy="123" rx="11" ry="6.5" fill="#FF9DB8" fill-opacity="0.7"/>')
            for dx, dy in ((-5, 4), (1, 6), (6, 3)):
                doc.add(f'<circle cx="{x + dx}" cy="{123 + dy}" r="1.4" fill="#E8768F"/>')
    return doc.text()


def outlined(doc, shape, colour, soft_line):
    if doc.style == 'classic':
        doc.add(shape.svg(f'fill="{colour}"'))
    elif doc.style == 'flat':
        doc.add(shape.svg(f'fill="{colour}" stroke="{OUTLINE}" stroke-width="2.5" '
                          'stroke-linejoin="round"'))
    else:
        paint = doc.gradient(shape.box, light(colour, 0.6), colour, shade(colour, 0.15))
        doc.add(shape.svg(f'fill="{paint}" stroke="{soft_line}" stroke-width="2" '
                          'stroke-linejoin="round"'))


def extra(style, name):
    doc = Doc(style)
    if name == 'hearts':
        hearts_at(doc, 192, 52, 11)
        hearts_at(doc, 212, 30, 7)
    elif name == 'sparkle':
        outlined(doc, star(196, 48, 15), '#FFC93C', '#D99A00')
        outlined(doc, star(214, 74, 7), '#FFE08A', '#D99A00')
    elif name == 'burst':
        d = 'M180 52 L194 38 M190 66 L208 62 M170 42 L174 24'
        if style == 'flat':
            doc.add(f'<path d="{d}" stroke="{OUTLINE}" stroke-width="9" stroke-linecap="round"/>')
        doc.add(f'<path d="{d}" stroke="#FFC93C" stroke-width="4.5" stroke-linecap="round"/>')
    elif name == 'sparkles':
        for x, y, size, colour in ((34, 58, 11, '#FFC93C'), (200, 36, 9, '#FFC93C'),
                                   (214, 160, 8, '#FBD5E3'), (22, 150, 7, '#FFFFFF')):
            outlined(doc, star(x, y, size), colour, '#D99A00')
    elif name == 'zzz':
        colour = {'classic': CLASSIC_INK, 'flat': OUTLINE, 'soft': '#3E5C9E'}[style]
        for d, width, alpha in (('M160 50 H176 L160 66 H176', 3.5, 1),
                                ('M184 28 H195 L184 39 H195', 3, 0.75),
                                ('M200 10 H207 L200 17 H207', 2.5, 0.5)):
            doc.add(f'<path d="{d}" stroke="{colour}" stroke-width="{width}" stroke-linecap="round" '
                    f'stroke-linejoin="round" fill="none" stroke-opacity="{alpha}"/>')
    return doc.text()


MOODS = ['happy', 'neutral', 'sad', 'focused', 'sleeping', 'celebrating',
         'love', 'surprised', 'proud', 'wink']
NEW_MOODS = ['love', 'surprised', 'proud', 'wink']
EXTRAS = ['hearts', 'sparkle', 'burst', 'sparkles', 'zzz']


def body(style, name):
    make, cx, width = SPECIES[name]
    doc = Doc(style)
    if style == 'soft':
        shadow(doc, cx, width)
    render(doc, make())
    return doc.text()


def tail(style):
    doc = Doc(style)
    render(doc, gret_tail())
    return doc.text()


def write(path, text, keep=False):
    path = os.path.normpath(os.path.join(ROOT, path))
    if keep and os.path.exists(path):
        return 0
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, 'w', encoding='utf-8', newline='\n') as f:
        f.write(text)
    return 1


def main():
    count = 0
    for style in ('flat', 'soft'):
        for name in SPECIES:
            count += write(f'{style}/body_{name}.svg', body(style, name))
        count += write(f'{style}/tail.svg', tail(style))
        count += write(f'{style}/cheeks.svg', cheeks(style))
        for mood in MOODS + ['blink']:
            count += write(f'{style}/eyes_{mood}.svg', eyes(style, mood))
        for mood in MOODS:
            count += write(f'{style}/mouth_{mood}.svg', mouth(style, mood))
        for name in EXTRAS:
            count += write(f'{style}/{name}.svg', extra(style, name))
    # Classic: only what does not exist yet (today's drawings stay as they are).
    for name in NEW_SPECIES:
        count += write(f'{name}/body.svg', body('classic', name), keep=True)
    for mood in NEW_MOODS:
        count += write(f'gret/eyes_{mood}.svg', eyes('classic', mood), keep=True)
        count += write(f'gret/mouth_{mood}.svg', mouth('classic', mood), keep=True)
    for name in ('hearts', 'sparkle', 'burst'):
        count += write(f'gret/{name}.svg', extra('classic', name), keep=True)
    print('wrote', count, 'files')


if __name__ == '__main__':
    main()
