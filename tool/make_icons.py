#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Иконка и сплэш «Танчиков» из кей-арта (tool/keyart_src.png).

- Иконка: кадрируем на танк (крупно, без титульного текста — он нечитаем в
  мелком размере) -> assets/icon/icon.png (1024x1024).
- Сплэш: полный арт -> assets/icon/splash.png (1080x1080).

Запуск из корня проекта:  python tool/make_icons.py
Координаты кропа заданы для исходника 1254x1254 и масштабируются под фактический
размер. Дальше иконку/сплэш собирают flutter_launcher_icons / flutter_native_splash.
"""
from PIL import Image

SRC = 'tool/keyart_src.png'

# Бокс кропа танка (left, top, right, bottom) в координатах 1254x1254:
# полный танк с запасом по краям, но выше титульного текста.
CROP_1254 = (322, 65, 1022, 765)


def main():
    src = Image.open(SRC).convert('RGB')
    w, h = src.size
    s = w / 1254.0
    box = tuple(int(round(v * s)) for v in CROP_1254)

    icon = src.crop(box).resize((1024, 1024), Image.LANCZOS)
    icon.save('assets/icon/icon.png')

    splash = src.resize((1080, 1080), Image.LANCZOS)
    splash.save('assets/icon/splash.png')

    print(f'src={w}x{h}  crop={box}  icon={icon.size}  splash={splash.size}')


if __name__ == '__main__':
    main()
