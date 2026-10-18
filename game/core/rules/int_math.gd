class_name IntMath
extends RefCounted
## Aritmética inteira compartilhada pelas regras.


## Divisão arredondada para o inteiro mais próximo (metade para cima).
## Só vale para num >= 0 e den > 0.
static func div_round(num: int, den: int) -> int:
	return (num + den / 2) / den
