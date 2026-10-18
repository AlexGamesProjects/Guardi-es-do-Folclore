# Calibração dos limites de desempenho

Segundo a especificação (seção 5.2), na primeira medição real cada limite é calibrado e o ajuste fica registrado aqui.

| Limite | Original (spec) | Atual | Situação |
|---|---|---|---|
| `download_gz_bytes` | 12000000 | 12000000 | mantido |
| `load_ms` | 5000 | 12000 | calibrado |
| `fights_10k_ms` | 2000 | 2000 | mantido (ainda sem medição) |
| `command_p95_us` | 1000 | 1000 | mantido (ainda sem medição) |

## Medição que justificou
Run 39091420270 da CI: download 10163295 B (gzip -9) e carregamento 10513 ms, no perfil "4G" (9000 kbit/s de download, 1500 kbit/s de upload, 60 ms de latência).

## Motivo
10,16 MB a 9 Mbit/s levam cerca de 9 s só de transferência, então 5000 ms é inatingível com este export. O novo limite é o valor medido mais cerca de 15% de folga. Chegar a 5 s exigiria reduzir o export (o `index.wasm` tem 39,5 MB), o que fica para uma tarefa futura.
