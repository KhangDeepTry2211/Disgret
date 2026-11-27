"""Converts mascot SVG layers to one Android VectorDrawable (spec 017, spec 018).

Usage (from the app folder):
  python -I specs/018-mascot-family/svg2vector.py <out.xml> <layer.svg> [<layer.svg> ...]

Handles what mascot_art.py writes: path, ellipse and circle; fill, fill-opacity, stroke,
stroke-width, stroke-opacity, stroke-linecap, stroke-linejoin; rotate(a cx cy); and radial gradients
in userSpaceOnUse units (written as aapt:attr gradients, Android 7.0+).
"""
import re
import sys
import xml.etree.ElementTree as ET

NS = '{http://www.w3.org/2000/svg}'


def ellipse_path(cx, cy, rx, ry):
    return (f'M{cx - rx:g},{cy:g} a{rx:g},{ry:g} 0 1,0 {2 * rx:g},0 '
            f'a{rx:g},{ry:g} 0 1,0 {-2 * rx:g},0 Z')


def colour(value, opacity=None):
    value = value.lstrip('#').upper()
    if len(value) == 3:
        value = ''.join(c * 2 for c in value)
    alpha = round(float(opacity) * 255) if opacity is not None else 255
    return f'#{alpha:02X}{value}'


def gradients(root):
    found = {}
    for g in root.iter(f'{NS}radialGradient'):
        a = g.attrib
        assert a.get('gradientUnits') == 'userSpaceOnUse', a.get('id')
        stops = [(s.attrib['offset'], colour(s.attrib['stop-color'], s.attrib.get('stop-opacity')))
                 for s in g.iter(f'{NS}stop')]
        found[a['id']] = (a['cx'], a['cy'], a['r'], stops)
    return found


def gradient_xml(attr, gradient, indent):
    cx, cy, r, stops = gradient
    items = ''.join(f'{indent}    <item android:offset="{o}" android:color="{c}" />\n'
                    for o, c in stops)
    return (f'{indent}<aapt:attr name="android:{attr}">\n'
            f'{indent}  <gradient android:type="radial" android:centerX="{cx}" '
            f'android:centerY="{cy}" android:gradientRadius="{r}">\n{items}'
            f'{indent}  </gradient>\n{indent}</aapt:attr>\n')


def paint(value, grads):
    match = re.match(r'url\(#(\w+)\)', value or '')
    return grads[match.group(1)] if match else None


def convert(paths):
    parts = []
    for path in paths:
        root = ET.parse(path).getroot()
        grads = gradients(root)
        parts.append(f'    <!-- {path.replace(chr(92), "/").split("assets/")[-1]} -->')
        for element in root.iter():
            tag = element.tag.replace(NS, '')
            a = element.attrib
            if tag == 'path':
                d = a['d']
            elif tag == 'ellipse':
                d = ellipse_path(float(a['cx']), float(a['cy']), float(a['rx']), float(a['ry']))
            elif tag == 'circle':
                r = float(a['r'])
                d = ellipse_path(float(a['cx']), float(a['cy']), r, r)
            else:
                continue
            attrs = [f'android:pathData="{d}"']
            children = ''
            fill, stroke = a.get('fill'), a.get('stroke')
            if fill and fill != 'none':
                gradient = paint(fill, grads)
                if gradient:
                    children += gradient_xml('fillColor', gradient, '        ')
                else:
                    attrs.append(f'android:fillColor="{colour(fill, a.get("fill-opacity"))}"')
            if stroke and stroke != 'none':
                gradient = paint(stroke, grads)
                if gradient:
                    children += gradient_xml('strokeColor', gradient, '        ')
                else:
                    attrs.append(
                        f'android:strokeColor="{colour(stroke, a.get("stroke-opacity"))}"')
                attrs.append(f'android:strokeWidth="{a.get("stroke-width", "1")}"')
                for svg_name, android_name in (('stroke-linecap', 'strokeLineCap'),
                                               ('stroke-linejoin', 'strokeLineJoin')):
                    if a.get(svg_name):
                        attrs.append(f'android:{android_name}="{a[svg_name]}"')
            open_tag = '<path ' + ' '.join(attrs)
            xml = f'{open_tag}>\n{children}    </path>' if children else f'{open_tag} />'
            rotate = re.match(r'rotate\(([-\d.]+)[ ,]+([-\d.]+)[ ,]+([-\d.]+)\)',
                              a.get('transform', ''))
            if rotate:
                angle, px, py = rotate.groups()
                xml = (f'<group android:rotation="{angle}" android:pivotX="{px}" '
                       f'android:pivotY="{py}">{xml}</group>')
            parts.append('    ' + xml)
    return parts


def main():
    out, layers = sys.argv[1], sys.argv[2:]
    names = ', '.join('assets/' + p.replace(chr(92), '/').split('assets/')[-1] for p in layers)
    xml = ('<?xml version="1.0" encoding="utf-8"?>\n'
           '<!-- 2.3 Gret for the intervention screen (spec 017, redrawn in 3D mềm by spec 018),\n'
           f'     converted from {names}\n'
           '     by specs/018-mascot-family/svg2vector.py. Regenerate, do not edit. -->\n'
           '<vector xmlns:android="http://schemas.android.com/apk/res/android"\n'
           '    xmlns:aapt="http://schemas.android.com/aapt"\n'
           '    android:width="240dp" android:height="200dp"\n'
           '    android:viewportWidth="240" android:viewportHeight="200">\n'
           + '\n'.join(convert(layers)) + '\n</vector>\n')
    with open(out, 'w', encoding='utf-8', newline='\n') as f:
        f.write(xml)
    print('wrote', out)


if __name__ == '__main__':
    main()
