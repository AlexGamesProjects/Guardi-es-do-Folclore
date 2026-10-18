class_name HeroiPoses
extends RefCounted
## Poses do guardião articulado. Cada animação é uma lista de [pose, duração em s]; a pose dá a
## rotação em graus de cada osso (positivo = horário; com o boneco olhando para a direita, braço
## para a frente é negativo) e o deslocamento do quadril em `x`/`y`. Ossos ausentes voltam ao
## neutro.

const NEUTRO: Dictionary = {
	"x": 0.0,
	"y": 0.0,
	"Tronco": 0.0,
	"Cabeca": 0.0,
	"BracoFrente": 8.0,
	"AntebracoFrente": -12.0,
	"BracoTras": -8.0,
	"AntebracoTras": -6.0,
	"CoxaFrente": -4.0,
	"CanelaFrente": 4.0,
	"CoxaTras": 4.0,
	"CanelaTras": 2.0,
}

const ANIMACOES: Dictionary = {
	"parado": [[{}, 0.5], [{"y": 1.0, "Tronco": 2.0, "Cabeca": -2.0, "BracoFrente": 11.0}, 0.5]],
	"ataque":
	[
		[{"x": -2.0, "Tronco": 6.0, "BracoFrente": 45.0, "AntebracoFrente": -25.0}, 0.12],
		[
			{
				"x": 4.0,
				"Tronco": -10.0,
				"BracoFrente": -95.0,
				"AntebracoFrente": -4.0,
				"CoxaFrente": -22.0,
				"CoxaTras": 14.0
			},
			0.07
		],
		[
			{
				"x": 4.0,
				"Tronco": -10.0,
				"BracoFrente": -95.0,
				"AntebracoFrente": -4.0,
				"CoxaFrente": -22.0,
				"CoxaTras": 14.0
			},
			0.1
		],
		[{}, 0.16],
	],
	"critico":
	[
		[
			{
				"x": -4.0,
				"y": 1.0,
				"Tronco": 14.0,
				"Cabeca": 6.0,
				"BracoFrente": 70.0,
				"AntebracoFrente": -40.0,
				"CoxaFrente": -10.0,
				"CanelaFrente": 20.0
			},
			0.16
		],
		[
			{
				"x": 7.0,
				"y": -2.0,
				"Tronco": -18.0,
				"Cabeca": -10.0,
				"BracoFrente": -120.0,
				"AntebracoFrente": 0.0,
				"CoxaFrente": -35.0,
				"CoxaTras": 25.0
			},
			0.06
		],
		[
			{
				"x": 7.0,
				"y": -2.0,
				"Tronco": -18.0,
				"BracoFrente": -120.0,
				"CoxaFrente": -35.0,
				"CoxaTras": 25.0
			},
			0.14
		],
		[{}, 0.2],
	],
	"golpe":
	[
		[
			{
				"x": -4.0,
				"Tronco": 16.0,
				"Cabeca": 14.0,
				"BracoFrente": 35.0,
				"BracoTras": 30.0,
				"CoxaFrente": 8.0
			},
			0.07
		],
		[{}, 0.22],
	],
	"esquiva":
	[
		[
			{
				"x": -10.0,
				"y": -6.0,
				"Tronco": 20.0,
				"Cabeca": 8.0,
				"CoxaFrente": -35.0,
				"CanelaFrente": 45.0,
				"CoxaTras": 25.0,
				"CanelaTras": 30.0,
				"BracoFrente": 40.0,
				"BracoTras": 40.0
			},
			0.12
		],
		[{"x": -6.0, "Tronco": 8.0}, 0.1],
		[{}, 0.18],
	],
	"derrota":
	[
		[{"x": -4.0, "Tronco": 25.0, "Cabeca": 15.0, "BracoFrente": 40.0}, 0.15],
		[
			{
				"x": -8.0,
				"y": 14.0,
				"Tronco": 82.0,
				"Cabeca": 20.0,
				"BracoFrente": -40.0,
				"BracoTras": 70.0,
				"CoxaFrente": -70.0,
				"CanelaFrente": 10.0,
				"CoxaTras": -55.0
			},
			0.35
		],
	],
	"vitoria":
	[
		[
			{
				"y": -8.0,
				"BracoFrente": -165.0,
				"AntebracoFrente": -15.0,
				"BracoTras": -40.0,
				"CoxaFrente": -15.0,
				"CanelaFrente": 25.0
			},
			0.18
		],
		[{"y": 0.0, "BracoFrente": -165.0, "AntebracoFrente": -15.0}, 0.18],
		[{"y": -6.0, "BracoFrente": -165.0, "AntebracoFrente": -15.0, "BracoTras": -40.0}, 0.18],
		[{"BracoFrente": -165.0, "AntebracoFrente": -15.0}, 0.2],
	],
	"andar":
	[
		[
			{
				"y": -1.0,
				"CoxaFrente": -25.0,
				"CanelaFrente": 10.0,
				"CoxaTras": 25.0,
				"CanelaTras": 25.0,
				"BracoFrente": 25.0,
				"BracoTras": -25.0
			},
			0.2
		],
		[
			{
				"y": 0.0,
				"CoxaFrente": 25.0,
				"CanelaFrente": 25.0,
				"CoxaTras": -25.0,
				"CanelaTras": 10.0,
				"BracoFrente": -15.0,
				"BracoTras": 20.0
			},
			0.2
		],
	],
}


## Lista de [pose completa, duração] da ação, ou [] se a ação não existe.
static func sequencia(acao: String) -> Array:
	if not ANIMACOES.has(acao):
		return []
	var out: Array = []
	for q: Array in ANIMACOES[acao]:
		var pose: Dictionary = NEUTRO.duplicate()
		pose.merge(q[0], true)
		out.append([pose, q[1]])
	return out
