class_name Textos
extends RefCounted
## Frases em português para os códigos de erro e de aviso: o que aconteceu e o que fazer.

const ERROS: Dictionary[String, String] = {
	"OCUPADO": "Ainda estamos terminando a ação anterior. Espere um instante e toque de novo.",
	"ERRO_EXECUTOR": "Algo deu errado ao processar a ação. Tente de novo.",
	"NAO_ENCONTRADO": "Essa missão não está mais disponível. Escolha outra.",
	"MISSAO_ATIVA": "Já há uma missão em andamento. Conclua essa antes de começar outra.",
	"ENERGIA_INSUFICIENTE": "Energia insuficiente. Espere a energia recarregar e tente de novo.",
	"SEM_MISSAO": "Nenhuma missão em andamento. Comece uma missão primeiro.",
	"MISSAO_EM_ANDAMENTO": "A missão ainda não terminou. Espere o tempo acabar ou acelere.",
	"MUIRAQUITAS_INSUFICIENTES":
	"Faltam muiraquitãs. Suba de nível ou vença chefes para ganhar mais.",
	"ATRIBUTO_INVALIDO": "Esse atributo não existe. Escolha outro treino.",
	"VINTENS_INSUFICIENTES": "Faltam vinténs para o treino. Faça missões para ganhar mais.",
	"FASE_BLOQUEADA": "Essa fase ainda está fechada. Vença a fase anterior primeiro.",
	"NIVEL_INSUFICIENTE": "Seu nível ainda é baixo para essa fase. Faça missões para subir.",
	"EM_RECUPERACAO": "Seu guardião está se recuperando da última derrota. Espere um pouco.",
	"MOCHILA_CHEIA": "A mochila está cheia. Venda ou equipe um item para abrir espaço.",
	"CORAGEM_INSUFICIENTE": "Coragem insuficiente. Espere a coragem recarregar.",
	"JA_CRIADO": "Seu guardião já foi criado.",
	"ORIGEM_INVALIDA": "Escolha uma das origens da lista.",
	"COMANDO_DESCONHECIDO": "Essa ação não existe nesta versão. Atualize o jogo.",
}

## Textos que mudam conforme a tela que mandou o comando (o padrão acima vale para missão e treino).
const ERROS_POR_CONTEXTO: Dictionary[String, Dictionary] = {
	"feira":
	{
		"VINTENS_INSUFICIENTES": "Faltam vinténs para essa compra. Faça missões ou venda itens.",
		"NAO_ENCONTRADO": "Esse item não está mais na feira. Renove a feira para ver outros.",
	},
	"mochila":
	{
		"NAO_ENCONTRADO": "Esse item não está mais na mochila.",
	},
	"arena":
	{
		"NAO_ENCONTRADO": "Esse rival não está mais na roda. Escolha outro.",
	},
}

const AVISOS: Dictionary[String, String] = {
	"SAVE_FALHOU":
	"Não foi possível salvar o progresso neste aparelho. Libere espaço; o jogo tenta de novo sozinho.",
	"RESERVA_USADA":
	"O save principal estava danificado. O progresso foi recuperado da cópia de reserva.",
	"SAVE_RECRIADO":
	"O save estava danificado e não pôde ser recuperado. Um perfil novo foi criado.",
}


static func erro(code: String, contexto: String = "geral") -> String:
	if ERROS_POR_CONTEXTO.has(contexto) and ERROS_POR_CONTEXTO[contexto].has(code):
		return str(ERROS_POR_CONTEXTO[contexto][code])
	if ERROS.has(code):
		return ERROS[code]
	return "Não deu certo (%s). Tente de novo." % code


static func aviso(code: String) -> String:
	if AVISOS.has(code):
		return AVISOS[code]
	return "Aviso do jogo: %s." % code


## Avisos do carregamento que o `Boot` guardou. `RESERVA_USADA` vem de `last_warning`;
## `SAVE_RECRIADO` só conta se estiver em `warnings` (no primeiro perfil não é aviso).
static func avisos_do_boot() -> Array[String]:
	var out: Array[String] = []
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	var boot: Node = tree.root.get_node_or_null("Boot")
	if boot == null:
		return out
	if str(boot.get("last_warning")) == "RESERVA_USADA":
		out.append("RESERVA_USADA")
	var codes: Array[String] = boot.get("warnings")
	for code: String in codes:
		if not out.has(code):
			out.append(code)
	return out


## Tempo em m:ss.
static func relogio(ms: int) -> String:
	var total_s: int = ceili(ms / 1000.0)
	return "%d:%02d" % [floori(total_s / 60.0), total_s % 60]
