#!/usr/bin/env python3
"""Desenha em pixel art as partes do guardião articulado e os itens que ele veste.

Saída: game/assets/heroi/partes/*.png e game/assets/heroi/itens/*.png (PNG pequenos, sem
suavização). O boneco é montado no Godot (ui/heroi/boneco.gd); cada parte tem o ponto de giro
na junta de cima (membros) ou no centro da base (tronco), conforme PIVOS no boneco.
Rode de novo depois de mudar este arquivo: python3 tools/gen_heroi.py
"""
from pathlib import Path
from PIL import Image

RAIZ = Path(__file__).resolve().parent.parent / "game" / "assets" / "heroi"
CONTORNO = (27, 18, 12, 255)
PELE = (138, 90, 60, 255)
PELE_SOMBRA = (110, 70, 46, 255)
CABELO = (40, 26, 18, 255)
CAMISA = (216, 201, 163, 255)
CAMISA_SOMBRA = (184, 166, 126, 255)
CALCA = (74, 59, 46, 255)
CALCA_SOMBRA = (56, 44, 34, 255)
PE = (52, 36, 26, 255)
OLHO = (20, 14, 10, 255)
T = (0, 0, 0, 0)


def tela(w, h):
    return Image.new("RGBA", (w, h), T)


def retangulo(img, x0, y0, x1, y1, cor):
    for y in range(y0, y1 + 1):
        for x in range(x0, x1 + 1):
            img.putpixel((x, y), cor)


def contornar(img):
    """Contorno de 1 px em volta de tudo que não é transparente."""
    w, h = img.size
    base = img.copy()
    for y in range(h):
        for x in range(w):
            if base.getpixel((x, y))[3] != 0:
                continue
            for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                nx, ny = x + dx, y + dy
                if 0 <= nx < w and 0 <= ny < h and base.getpixel((nx, ny))[3] != 0 and base.getpixel((nx, ny)) != CONTORNO:
                    img.putpixel((x, y), CONTORNO)
                    break
    return img


def membro(w, h, cor, sombra, ponta=None, ponta_h=0):
    img = tela(w + 2, h + 2)
    retangulo(img, 1, 1, w, h, cor)
    retangulo(img, w, 1, w, h, sombra)
    if ponta:
        retangulo(img, 1, h - ponta_h + 1, w, h, ponta)
    return contornar(img)


def salvar(img, pasta, nome):
    (RAIZ / pasta).mkdir(parents=True, exist_ok=True)
    img.save(RAIZ / pasta / f"{nome}.png")


# ---------- corpo base ----------

def cabeca():
    img = tela(14, 14)
    retangulo(img, 2, 3, 11, 12, PELE)
    retangulo(img, 2, 10, 4, 12, PELE_SOMBRA)
    retangulo(img, 2, 2, 11, 4, CABELO)
    retangulo(img, 2, 5, 3, 8, CABELO)
    img.putpixel((9, 7), OLHO)
    img.putpixel((11, 9), PELE_SOMBRA)
    retangulo(img, 8, 10, 10, 10, PELE_SOMBRA)
    return contornar(img)


def tronco(cor=CAMISA, sombra=CAMISA_SOMBRA, detalhe=None):
    img = tela(14, 18)
    retangulo(img, 2, 1, 11, 16, cor)
    retangulo(img, 10, 1, 11, 16, sombra)
    retangulo(img, 5, 1, 8, 2, PELE)
    retangulo(img, 2, 14, 11, 14, (120, 90, 52, 255))  # cinto de corda
    if detalhe:
        detalhe(img)
    return contornar(img)


def salvar_base():
    salvar(cabeca(), "partes", "cabeca")
    salvar(tronco(), "partes", "tronco")
    salvar(membro(4, 9, CAMISA, CAMISA_SOMBRA), "partes", "braco")
    salvar(membro(4, 9, CAMISA, CAMISA_SOMBRA, PELE, 3), "partes", "antebraco")
    salvar(membro(5, 10, CALCA, CALCA_SOMBRA), "partes", "coxa")
    salvar(membro(5, 10, CALCA, CALCA_SOMBRA, PE, 2), "partes", "canela")


# ---------- roupas (slot corpo): tronco + braço + antebraço ----------

ROUPAS = {
    "gibao_vaqueiro": ((140, 92, 52, 255), (110, 70, 40, 255)),
    "bata_algodao": ((236, 230, 214, 255), (206, 198, 178, 255)),
    "manto_folhas": ((63, 124, 72, 255), (44, 94, 54, 255)),
    "colete_couro": ((96, 60, 36, 255), (74, 46, 28, 255)),
    "poncho_la": ((180, 52, 40, 255), (140, 38, 30, 255)),
}


def detalhe_roupa(nome):
    def franjas(img):
        for x in range(2, 12, 2):
            img.putpixel((x, 16), (90, 58, 32, 255))

    def folhas(img):
        for x, y in ((3, 4), (8, 6), (5, 9), (9, 11), (4, 13)):
            img.putpixel((x, y), (120, 180, 90, 255))

    def colete(img):
        retangulo(img, 5, 3, 8, 13, CAMISA)

    def listras(img):
        for y in (5, 9, 12):
            retangulo(img, 2, y, 11, y, (232, 184, 72, 255))

    return {"gibao_vaqueiro": franjas, "manto_folhas": folhas, "colete_couro": colete,
            "poncho_la": listras}.get(nome)


def salvar_roupas():
    for nome, (cor, sombra) in ROUPAS.items():
        salvar(tronco(cor, sombra, detalhe_roupa(nome)), "itens", f"{nome}_tronco")
        salvar(membro(4, 9, cor, sombra), "itens", f"{nome}_braco")
        salvar(membro(4, 9, cor, sombra, PELE, 3), "itens", f"{nome}_antebraco")


# ---------- cabeça ----------

def chapeu(cor, sombra, aba=9, copa=4, faixa=None):
    img = tela(aba * 2 + 2, copa + 4)
    meio = aba + 1
    retangulo(img, 1, copa + 1, aba * 2, copa + 2, cor)
    retangulo(img, meio - 4, 1, meio + 3, copa + 1, cor)
    retangulo(img, meio + 2, 1, meio + 3, copa + 1, sombra)
    if faixa:
        retangulo(img, meio - 4, copa, meio + 3, copa, faixa)
    return contornar(img)


def gorro():
    img = tela(14, 14)
    pontos = [(2, 12), (11, 12)]
    for y in range(3, 13):
        x0 = 2 + max(0, (12 - y) // 3)
        retangulo(img, x0, y, 11, y, (196, 40, 36, 255))
    retangulo(img, 9, 1, 12, 3, (196, 40, 36, 255))
    return contornar(img)


def cocar():
    img = tela(16, 12)
    cores = [(214, 60, 40, 255), (240, 190, 60, 255), (60, 140, 90, 255), (40, 100, 170, 255)]
    for i, x in enumerate(range(2, 14, 2)):
        retangulo(img, x, 2 + (i % 2), x, 8, cores[i % 4])
    retangulo(img, 1, 8, 14, 10, (150, 96, 50, 255))
    return contornar(img)


def lenco():
    img = tela(14, 7)
    retangulo(img, 1, 1, 12, 4, (210, 60, 90, 255))
    for x in range(2, 12, 3):
        img.putpixel((x, 2), (250, 220, 90, 255))
        img.putpixel((x + 1, 3), (90, 170, 120, 255))
    retangulo(img, 1, 4, 3, 6, (210, 60, 90, 255))
    return contornar(img)


def salvar_cabeca():
    salvar(chapeu((122, 78, 44, 255), (96, 60, 34, 255), faixa=(60, 38, 22, 255)), "itens", "chapeu_couro")
    salvar(gorro(), "itens", "gorro_vermelho")
    salvar(cocar(), "itens", "cocar_penas")
    salvar(chapeu((222, 186, 96, 255), (190, 152, 70, 255), aba=10, faixa=(150, 60, 40, 255)), "itens", "chapeu_palha")
    salvar(lenco(), "itens", "lenco_chita")


# ---------- armas (presas na mão, apontando para a frente/baixo) ----------

def arma(desenho, w, h):
    img = tela(w, h)
    desenho(img)
    return contornar(img)


MADEIRA = (128, 86, 48, 255)
METAL = (196, 200, 204, 255)
METAL_SOMBRA = (140, 146, 152, 255)


def salvar_armas():
    salvar(arma(lambda i: (retangulo(i, 1, 3, 4, 4, MADEIRA), retangulo(i, 5, 3, 14, 4, METAL),
                           retangulo(i, 5, 4, 13, 4, METAL_SOMBRA)), 16, 8), "itens", "peixeira")
    salvar(arma(lambda i: (retangulo(i, 2, 5, 3, 11, MADEIRA), retangulo(i, 1, 2, 2, 5, MADEIRA),
                           retangulo(i, 4, 2, 5, 5, MADEIRA), retangulo(i, 2, 2, 4, 2, (200, 120, 90, 255))), 7, 13),
           "itens", "estilingue")
    salvar(arma(lambda i: (retangulo(i, 1, 3, 20, 4, (110, 140, 70, 255)),
                           retangulo(i, 1, 4, 20, 4, (80, 104, 50, 255))), 22, 8), "itens", "zarabatana")
    salvar(arma(lambda i: (retangulo(i, 2, 1, 3, 26, MADEIRA), retangulo(i, 1, 1, 4, 3, (96, 62, 34, 255))), 6, 28),
           "itens", "cajado_jatoba")
    salvar(arma(lambda i: (retangulo(i, 1, 3, 4, 4, MADEIRA), retangulo(i, 5, 2, 16, 5, METAL),
                           retangulo(i, 5, 5, 15, 5, METAL_SOMBRA)), 18, 8), "itens", "facao")
    def arco(i):
        for y in range(1, 21):
            x = 2 + abs(10 - y) // 3
            i.putpixel((x, y), MADEIRA)
            i.putpixel((x + 1, y), MADEIRA)
        retangulo(i, 7, 1, 7, 20, (230, 224, 200, 255))
    salvar(arma(arco, 10, 22), "itens", "arco_pau_darco")
    def laco(i):
        for (x, y) in ((3, 2), (4, 1), (6, 1), (7, 2), (8, 4), (7, 6), (6, 7), (4, 7), (3, 6), (2, 4)):
            i.putpixel((x, y), (200, 168, 110, 255))
        retangulo(i, 8, 5, 12, 5, (200, 168, 110, 255))
    salvar(arma(laco, 14, 9), "itens", "laco_trancado")


# ---------- amuletos (no peito) ----------

def salvar_amuletos():
    def pingente(cor, w=5, h=6, extra=None):
        img = tela(w + 2, h + 4)
        retangulo(img, (w + 2) // 2, 1, (w + 2) // 2, 2, (150, 110, 60, 255))
        retangulo(img, 1, 3, w, h + 2, cor)
        if extra:
            extra(img)
        return contornar(img)
    salvar(pingente((60, 120, 60, 255)), "itens", "figa_arruda")
    salvar(pingente((170, 110, 60, 255), 6, 5), "itens", "patua")
    salvar(pingente((230, 60, 60, 255), 3, 7, lambda i: retangulo(i, 2, 7, 3, 9, (250, 210, 60, 255))), "itens", "fita_bonfim")
    salvar(pingente((230, 224, 210, 255), 3, 7, lambda i: retangulo(i, 2, 4, 2, 9, (120, 100, 80, 255))), "itens", "pena_gaviao")
    salvar(pingente((60, 170, 130, 255), 6, 5), "itens", "muiraquita_barro")
    salvar(pingente((236, 230, 210, 255), 3, 6), "itens", "dente_onca")


if __name__ == "__main__":
    salvar_base()
    salvar_roupas()
    salvar_cabeca()
    salvar_armas()
    salvar_amuletos()
    for p in sorted(RAIZ.rglob("*.png")):
        print(p.relative_to(RAIZ), Image.open(p).size)
