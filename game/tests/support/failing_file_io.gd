class_name FailingFileIO
extends FileIO
## Só para testes: a escrita falha como numa cota cheia. O resto funciona de verdade.

var fail_writes: bool = true
var write_calls: int = 0


func write(path: String, text: String) -> bool:
	write_calls += 1
	if fail_writes:
		return false
	return super.write(path, text)
