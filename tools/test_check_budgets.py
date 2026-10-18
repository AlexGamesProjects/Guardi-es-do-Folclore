"""Testes do check_budgets.py (rodar com: pytest tools/test_check_budgets.py)."""

import json
import subprocess
import sys
from pathlib import Path

AQUI = Path(__file__).resolve().parent
SCRIPT = AQUI / "check_budgets.py"
LIMITES = {
    "download_gz_bytes": 12_000_000,
    "load_ms": 5000,
    "fights_10k_ms": 2000,
    "command_p95_us": 1000,
}


def rodar(tmp_path, metricas, baseline=None):
    (tmp_path / "metrics.json").write_text(json.dumps(metricas))
    (tmp_path / "budgets.json").write_text(json.dumps(LIMITES))
    args = [
        sys.executable,
        str(SCRIPT),
        "--metrics",
        str(tmp_path / "metrics.json"),
        "--budgets",
        str(tmp_path / "budgets.json"),
        "--out",
        str(tmp_path / "report.md"),
    ]
    if baseline is not None:
        (tmp_path / "baseline.json").write_text(json.dumps(baseline))
        args += ["--baseline", str(tmp_path / "baseline.json")]
    proc = subprocess.run(args, capture_output=True, text=True)
    return proc, (tmp_path / "report.md").read_text(encoding="utf-8")


def test_over_budget_exits_1(tmp_path):
    proc, relatorio = rodar(tmp_path, {"download_gz_bytes": 13_000_000})
    assert proc.returncode == 1
    assert "❌" in relatorio


def test_missing_metric_is_dash(tmp_path):
    proc, relatorio = rodar(tmp_path, {"download_gz_bytes": 5_000_000})
    assert proc.returncode == 0
    linha = next(l for l in relatorio.splitlines() if "load_ms" in l)
    assert "—" in linha


def test_table_has_main_and_pr_columns(tmp_path):
    proc, relatorio = rodar(
        tmp_path, {"download_gz_bytes": 5_000_000}, {"download_gz_bytes": 4_000_000}
    )
    assert proc.returncode == 0
    assert "Medida | main | PR | Limite" in relatorio
    assert "✅" in relatorio


def test_missing_baseline_file_is_ok(tmp_path):
    (tmp_path / "metrics.json").write_text(json.dumps({"load_ms": 100}))
    (tmp_path / "budgets.json").write_text(json.dumps(LIMITES))
    proc = subprocess.run(
        [sys.executable, str(SCRIPT), "--metrics", str(tmp_path / "metrics.json"),
         "--baseline", str(tmp_path / "nao_existe.json"),
         "--budgets", str(tmp_path / "budgets.json"),
         "--out", str(tmp_path / "report.md")],
        capture_output=True, text=True,
    )
    assert proc.returncode == 0


def test_mode_label_is_ignored_as_metric(tmp_path):
    metricas = {"download_gz_bytes": 5_000_000, "fights_10k_ms": 100, "mode": "offline"}
    proc, relatorio = rodar(tmp_path, metricas, {"mode": "offline", "load_ms": 200})
    assert proc.returncode == 0, proc.stderr
    assert "❌" not in relatorio
    assert "Modo medido: `offline`." in relatorio
    assert not any(l.startswith("| mode") for l in relatorio.splitlines())


def test_non_numeric_metric_is_dash(tmp_path):
    proc, relatorio = rodar(tmp_path, {"load_ms": "rápido"})
    assert proc.returncode == 0, proc.stderr
    linha = next(l for l in relatorio.splitlines() if "load_ms" in l)
    assert "—" in linha
