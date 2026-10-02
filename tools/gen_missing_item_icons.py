#!/usr/bin/env python3
"""Генератор недостающих иконок предметов в стиле assets/textures/items/*.png.

Повторяет приёмы scripts/tools/_gen_item_sprites.gd: SDF-сглаживание,
вертикальный градиент, светлый блик сверху, тёмный контур.
"""
import math
from PIL import Image

W = 128

# Палитра — 1:1 с _gen_item_sprites.gd
DARK      = (13, 16, 20)
AMBER     = (200, 150, 60)
AMBER_HI  = (232, 192, 106)
CREAM     = (232, 224, 204)
STEEL     = (138, 148, 160)
STEEL_DK  = (83, 90, 100)
RED       = (160, 52, 40)
RED_HI    = (200, 76, 60)
OLIVE     = (74, 90, 56)
GREEN     = (60, 107, 66)
GLASS     = (122, 168, 184)
BROWN     = (107, 74, 46)
COPPER    = (176, 106, 56)
PAPER     = (208, 198, 171)


def mul(c, k):
    return tuple(min(int(v * k), 255) for v in c)


class Canvas:
    def __init__(self):
        self.px = [[(0, 0, 0, 0.0) for _ in range(W)] for _ in range(W)]

    def blend(self, x, y, c, a):
        if a <= 0 or x < 0 or y < 0 or x >= W or y >= W:
            return
        a = min(a, 1.0)
        r, g, b, da = self.px[y][x]
        na = a + da * (1 - a)
        if na <= 0:
            return
        nr = (c[0] * a + r * da * (1 - a)) / na
        ng = (c[1] * a + g * da * (1 - a)) / na
        nb = (c[2] * a + b * da * (1 - a)) / na
        self.px[y][x] = (nr, ng, nb, na)

    def save(self, path):
        im = Image.new("RGBA", (W, W), (0, 0, 0, 0))
        out = []
        for y in range(W):
            for x in range(W):
                r, g, b, a = self.px[y][x]
                out.append((int(r), int(g), int(b), int(round(a * 255))))
        im.putdata(out)
        im.save(path)


def sd_rrect(px, py, hw, hh, r):
    qx = abs(px) - hw + r
    qy = abs(py) - hh + r
    return math.hypot(max(qx, 0), max(qy, 0)) + min(max(qx, qy), 0) - r


def rrect(cv, cx, cy, w, h, rad, ang, base, outline=2.0, grad=0.34, hi=True):
    """Скруглённый прямоугольник: градиент сверху вниз + контур."""
    hw, hh = w / 2.0, h / 2.0
    ca, sa = math.cos(-ang), math.sin(-ang)
    x0, x1 = int(cx - w - 8), int(cx + w + 8)
    y0, y1 = int(cy - h - 8), int(cy + h + 8)
    for y in range(max(0, y0), min(W, y1)):
        for x in range(max(0, x0), min(W, x1)):
            dx, dy = x + 0.5 - cx, y + 0.5 - cy
            px, py = dx * ca - dy * sa, dx * sa + dy * ca
            d = sd_rrect(px, py, hw, hh, rad)
            if d > outline:
                continue
            t = (py + hh) / max(h, 1e-6)
            k = 1.0 + grad * (0.5 - t)
            col = mul(base, k)
            if d <= 0:
                cov = min(-d, 1.0)
                cv.blend(x, y, col, cov)
                if hi and py < -hh * 0.45:
                    cv.blend(x, y, mul(base, 1.35), 0.18 * cov)
            if d > -1.2:
                cv.blend(x, y, DARK, 0.85 * max(0.0, min(1.0, (outline - abs(d)) / outline)))


def circ(cv, cx, cy, r, base, outline=2.0, grad=0.34):
    for y in range(max(0, int(cy - r - 6)), min(W, int(cy + r + 6))):
        for x in range(max(0, int(cx - r - 6)), min(W, int(cx + r + 6))):
            dx, dy = x + 0.5 - cx, y + 0.5 - cy
            d = math.hypot(dx, dy) - r
            if d > outline:
                continue
            t = (dy + r) / max(2 * r, 1e-6)
            col = mul(base, 1.0 + grad * (0.5 - t))
            if d <= 0:
                cv.blend(x, y, col, min(-d, 1.0))
            if d > -1.2 and outline > 0:
                cv.blend(x, y, DARK, 0.85 * max(0.0, min(1.0, (outline - abs(d)) / outline)))


def flat(cv, cx, cy, w, h, rad, ang, col, alpha=1.0):
    """Плоская плашка без контура — для деталей поверх."""
    hw, hh = w / 2.0, h / 2.0
    ca, sa = math.cos(-ang), math.sin(-ang)
    for y in range(max(0, int(cy - h - 6)), min(W, int(cy + h + 6))):
        for x in range(max(0, int(cx - w - 6)), min(W, int(cx + w + 6))):
            dx, dy = x + 0.5 - cx, y + 0.5 - cy
            px, py = dx * ca - dy * sa, dx * sa + dy * ca
            d = sd_rrect(px, py, hw, hh, rad)
            if d <= 0:
                cv.blend(x, y, col, min(-d, 1.0) * alpha)


def caps(cv, x1, y1, x2, y2, r, base, outline=1.9):
    vx, vy = x2 - x1, y2 - y1
    L2 = vx * vx + vy * vy
    lo_x, hi_x = int(min(x1, x2) - r - 6), int(max(x1, x2) + r + 6)
    lo_y, hi_y = int(min(y1, y2) - r - 6), int(max(y1, y2) + r + 6)
    for y in range(max(0, lo_y), min(W, hi_y)):
        for x in range(max(0, lo_x), min(W, hi_x)):
            px, py = x + 0.5 - x1, y + 0.5 - y1
            t = 0.0 if L2 == 0 else max(0.0, min(1.0, (px * vx + py * vy) / L2))
            d = math.hypot(px - vx * t, py - vy * t) - r
            if d > outline:
                continue
            if d <= 0:
                cv.blend(x, y, mul(base, 1.0 + 0.22 * (0.5 - t)), min(-d, 1.0))
            if d > -1.2:
                cv.blend(x, y, DARK, 0.85 * max(0.0, min(1.0, (outline - abs(d)) / outline)))


def ring(cv, cx, cy, r, thick, base, outline=1.9):
    for y in range(max(0, int(cy - r - thick - 6)), min(W, int(cy + r + thick + 6))):
        for x in range(max(0, int(cx - r - thick - 6)), min(W, int(cx + r + thick + 6))):
            dx, dy = x + 0.5 - cx, y + 0.5 - cy
            d = abs(math.hypot(dx, dy) - r) - thick
            if d > outline:
                continue
            if d <= 0:
                cv.blend(x, y, base, min(-d, 1.0))
            if d > -1.2:
                cv.blend(x, y, DARK, 0.8 * max(0.0, min(1.0, (outline - abs(d)) / outline)))


# ------------------------- сами иконки -------------------------

def draw_document():
    cv = Canvas()
    # лист с загнутым уголком
    rrect(cv, 64, 66, 74, 92, 5, 0, PAPER)
    flat(cv, 64, 30, 74, 4, 2, 0, DARK, 0.18)
    # строки текста
    for i in range(6):
        y = 44 + i * 13
        w = 50 if i % 3 != 2 else 34
        flat(cv, 60 - (50 - w) / 2 + (50 - w) / 2, y, w, 4, 2, 0, mul(STEEL_DK, 1.0), 0.55)
    # печать
    ring(cv, 92, 96, 11, 2.2, mul(RED, 1.0))
    return cv


def draw_photo():
    cv = Canvas()
    # polaroid: белая рамка
    rrect(cv, 64, 64, 84, 92, 4, 0, CREAM)
    # снимок
    flat(cv, 64, 55, 68, 64, 2, 0, mul(DARK, 1.7), 1.0)
    # силуэт фонаря на снимке
    flat(cv, 64, 74, 6, 26, 1, 0, mul(AMBER, 0.55), 1.0)
    circ(cv, 64, 44, 9, AMBER_HI, outline=0.0, grad=0.2)
    flat(cv, 64, 44, 26, 3, 1, 0, mul(AMBER_HI, 1.0), 0.35)
    return cv


def draw_audio_log():
    cv = Canvas()
    # корпус диктофона
    rrect(cv, 64, 66, 58, 94, 7, 0, STEEL_DK)
    # окно кассеты
    flat(cv, 64, 44, 44, 30, 3, 0, mul(DARK, 1.5), 1.0)
    circ(cv, 52, 44, 7, AMBER, outline=1.6, grad=0.25)
    circ(cv, 76, 44, 7, AMBER, outline=1.6, grad=0.25)
    # решётка динамика
    for i in range(4):
        flat(cv, 64, 74 + i * 8, 40, 3, 1, 0, mul(DARK, 1.9), 0.85)
    # кнопка записи
    circ(cv, 64, 106, 6, RED_HI, outline=1.6, grad=0.2)
    return cv


def draw_tool():
    cv = Canvas()
    # отвёртка по диагонали
    caps(cv, 40, 92, 74, 54, 7, AMBER)          # рукоять
    caps(cv, 74, 54, 96, 32, 3.4, STEEL)        # стержень
    flat(cv, 98, 30, 12, 5, 1, -math.pi / 4, mul(STEEL, 1.2), 1.0)  # жало
    # гаечный ключ по другой диагонали
    caps(cv, 44, 42, 84, 96, 5, STEEL_DK)
    ring(cv, 42, 38, 10, 3.4, STEEL_DK)
    return cv


def draw_transformer():
    cv = Canvas()
    # корпус-бочонок
    rrect(cv, 64, 72, 62, 72, 8, 0, STEEL_DK)
    # рёбра охлаждения
    for i in range(5):
        flat(cv, 64, 48 + i * 13, 70, 5, 2, 0, mul(STEEL, 0.85), 0.9)
    # изоляторы сверху
    for x in (48, 64, 80):
        caps(cv, x, 34, x, 24, 4, COPPER)
        circ(cv, x, 22, 5, AMBER_HI, outline=1.6, grad=0.2)
    # значок высокого напряжения
    flat(cv, 64, 74, 10, 26, 1, 0.35, mul(AMBER, 1.0), 0.95)
    flat(cv, 64, 74, 10, 26, 1, -0.35, mul(AMBER, 1.0), 0.95)
    return cv


def _backpack(level):
    """L1 — компактный ранец, L2 — расширенный: выше, с боковыми карманами
    и второй нашивкой, чтобы уровни различались в инвентаре с одного взгляда."""
    cv = Canvas()
    if level >= 2:
        # боковые карманы расширенной версии
        rrect(cv, 26, 80, 20, 46, 6, 0, mul(OLIVE, 0.7))
        rrect(cv, 102, 80, 20, 46, 6, 0, mul(OLIVE, 0.7))
    # корпус
    body_h = 84 if level < 2 else 96
    rrect(cv, 64, 74, 76, body_h, 12, 0, OLIVE)
    # клапан
    rrect(cv, 64, 46, 70, 34, 10, 0, mul(OLIVE, 1.18))
    # лямки
    caps(cv, 40, 34, 40, 22, 5, BROWN)
    caps(cv, 88, 34, 88, 22, 5, BROWN)
    # передний карман
    rrect(cv, 64, 96, 46, 34, 7, 0, mul(OLIVE, 0.82))
    flat(cv, 64, 80, 52, 5, 2, 0, BROWN, 0.9)
    # пряжка
    flat(cv, 64, 80, 12, 9, 2, 0, AMBER_HI, 1.0)
    # нашивки уровня
    for i in range(level):
        flat(cv, 64 - (level - 1) * 9 + i * 18, 108, 12, 5, 2, 0, AMBER_HI, 1.0)
    return cv


def draw_backpack_l1():
    return _backpack(1)


def draw_backpack_l2():
    return _backpack(2)


def draw_rifle():
    cv = Canvas()
    rrect(cv, 32, 80, 42, 18, 5, -0.15, BROWN)            # приклад
    rrect(cv, 62, 70, 36, 16, 4, 0, STEEL_DK)             # ствольная коробка
    caps(cv, 76, 66, 118, 62, 4, STEEL)                    # ствол
    rrect(cv, 56, 88, 10, 22, 3, 0.2, BROWN)               # рукоять
    flat(cv, 92, 56, 20, 4, 1, 0, mul(STEEL, 1.2), 1.0)    # прицельная планка
    return cv


def draw_shotgun():
    cv = Canvas()
    rrect(cv, 30, 82, 40, 20, 5, -0.2, BROWN)              # приклад
    rrect(cv, 58, 70, 28, 14, 4, 0, STEEL_DK)              # ствольная коробка
    caps(cv, 70, 66, 118, 62, 5, STEEL)                    # ствол
    caps(cv, 72, 75, 108, 72, 4, STEEL_DK)                 # трубчатый магазин
    rrect(cv, 94, 80, 22, 10, 3, 0, BROWN)                 # цевьё
    return cv


def draw_plank():
    cv = Canvas()
    rrect(cv, 64, 48, 96, 22, 3, 0.05, BROWN)
    rrect(cv, 62, 78, 100, 22, 3, -0.04, mul(BROWN, 1.15))
    for x in (30, 98):
        circ(cv, x, 48, 3, STEEL, outline=1.2, grad=0.2)
        circ(cv, x - 2, 78, 3, STEEL, outline=1.2, grad=0.2)
    return cv


def _battery(cv, cx, cy, mark):
    rrect(cv, cx, cy, 46, 72, 7, 0, GREEN)
    flat(cv, cx, cy - 42, 18, 8, 2, 0, STEEL, 1.0)
    if mark == "plus":
        flat(cv, cx, cy, 24, 7, 2, 0, AMBER_HI, 1.0)
        flat(cv, cx, cy, 7, 24, 2, 0, AMBER_HI, 1.0)
    else:
        for i in range(2):
            flat(cv, cx - 8 + i * 16, cy, 7, 30, 2, 0, AMBER_HI, 1.0)


def draw_enhanced_battery():
    cv = Canvas()
    _battery(cv, 64, 70, "plus")
    return cv


def draw_battery_l2():
    cv = Canvas()
    _battery(cv, 64, 70, "bars")
    return cv


def _sheet():
    cv = Canvas()
    rrect(cv, 64, 64, 88, 100, 4, 0, mul(GLASS, 0.55))
    for i in range(5):
        flat(cv, 64, 28 + i * 18, 80, 1.5, 0, 0, mul(CREAM, 1.0), 0.28)
    return cv


def draw_blueprint_enhanced_battery():
    cv = _sheet()
    _battery(cv, 64, 66, "plus")
    return cv


def draw_blueprint_battery_l2():
    cv = _sheet()
    _battery(cv, 64, 66, "bars")
    return cv


def draw_blueprint_uv_flashlight():
    cv = _sheet()
    violet = (120, 104, 168)
    circ(cv, 64, 64, 14, violet, outline=2.0, grad=0.2)
    for k in range(8):
        a = k * math.pi / 4
        caps(cv, 64 + math.cos(a) * 22, 64 + math.sin(a) * 22, 64 + math.cos(a) * 32, 64 + math.sin(a) * 32, 2.6, violet)
    return cv


def draw_blueprint_strobe_flashlight():
    cv = _sheet()
    caps(cv, 70, 34, 52, 66, 4, AMBER_HI)
    caps(cv, 52, 66, 76, 66, 4, AMBER_HI)
    caps(cv, 76, 66, 58, 98, 4, AMBER_HI)
    return cv


def draw_blueprint_portable_workbench():
    cv = _sheet()
    rrect(cv, 64, 58, 62, 12, 3, 0, BROWN)
    for x in (42, 86):
        caps(cv, x, 64, x, 92, 3.2, BROWN)
    flat(cv, 64, 80, 52, 4, 1, 0, STEEL_DK, 1.0)
    return cv


TARGETS = {
    "document": draw_document,
    "photo": draw_photo,
    "audio_log": draw_audio_log,
    "tool": draw_tool,
    "transformer": draw_transformer,
    "backpack_l1": draw_backpack_l1,
    "backpack_l2": draw_backpack_l2,
    "rifle": draw_rifle,
    "shotgun": draw_shotgun,
    "plank": draw_plank,
    "enhanced_battery": draw_enhanced_battery,
    "battery_l2": draw_battery_l2,
    "blueprint_enhanced_battery": draw_blueprint_enhanced_battery,
    "blueprint_battery_l2": draw_blueprint_battery_l2,
    "blueprint_uv_flashlight": draw_blueprint_uv_flashlight,
    "blueprint_strobe_flashlight": draw_blueprint_strobe_flashlight,
    "blueprint_portable_workbench": draw_blueprint_portable_workbench,
}

if __name__ == "__main__":
    import sys
    outdir = sys.argv[1] if len(sys.argv) > 1 else "assets/textures/items"
    only = sys.argv[2:]
    for name, fn in TARGETS.items():
        if only and name not in only:
            continue
        cv = fn()
        path = f"{outdir}/{name}.png"
        cv.save(path)
        print("ok:", path)
