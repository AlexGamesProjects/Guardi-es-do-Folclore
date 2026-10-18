class_name SystemClock
extends Clock
## Relógio real do aparelho.


func now_ms() -> int:
	return int(Time.get_unix_time_from_system() * 1000.0)
