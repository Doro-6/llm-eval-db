#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""一键重建台账库并跑完全部分析 SQL。

用法：
    python run.py                 # 建库 + 灌数据 + 跑全部查询
    企业环境换 MySQL：把 schema.sql / seed.sql 里的 SQLite 写法改掉，
    再改写下面的 connect()，其余分析 SQL 基本不用动。
"""

from __future__ import annotations

import sqlite3
import sys
from pathlib import Path

BASE = Path(__file__).resolve().parent
DB = BASE / "ledger.db"

for _s in (sys.stdout, sys.stderr):
    try:
        _s.reconfigure(encoding="utf-8")
    except (AttributeError, ValueError):
        pass


def run_script(conn: sqlite3.Connection, path: Path) -> None:
    conn.executescript(path.read_text(encoding="utf-8"))
    conn.commit()


def split_statements(sql: str) -> list[str]:
    """按分号切；跳过纯注释块。"""
    out, buf = [], []
    for line in sql.splitlines():
        if line.strip().startswith("--"):
            continue
        buf.append(line)
        if line.rstrip().endswith(";"):
            stmt = "\n".join(buf).strip()
            if stmt and stmt != ";":
                out.append(stmt)
            buf = []
    return out


def main() -> int:
    if DB.exists():
        DB.unlink()
    conn = sqlite3.connect(DB)
    conn.row_factory = sqlite3.Row

    run_script(conn, BASE / "schema.sql")
    run_script(conn, BASE / "seed.sql")
    print(f"✓ 建库完成：{DB.name}")

    sql = (BASE / "queries.sql").read_text(encoding="utf-8")
    for i, stmt in enumerate(split_statements(sql), 1):
        rows = conn.execute(stmt).fetchall()
        print(f"\n{'='*72}\nQ{i}  返回 {len(rows)} 行\n{'-'*72}")
        if not rows:
            print("(空)")
            continue
        headers = rows[0].keys()
        widths = [max(_w(str(r[h])) for r in rows + [dict.fromkeys(headers, h)]) for h in headers]
        print(" | ".join(str(h).ljust(w) for h, w in zip(headers, widths)))
        print("-+-".join("-" * w for w in widths))
        for r in rows:
            print(" | ".join(str(r[h]).ljust(w) for h, w in zip(headers, widths)))

    conn.close()
    print(f"\n完成。数据库文件：{DB}")
    return 0


def _w(s: str) -> int:
    """中文按 2 个宽度算，保证表格对齐。"""
    return sum(2 if ord(c) > 0x2E80 else 1 for c in s)


if __name__ == "__main__":
    raise SystemExit(main())
