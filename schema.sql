-- ============================================================
-- 大模型需求抽取实验 · 台账数据库（SQLite / 也可迁 MySQL）
-- 数据来源：《大语言模型辅助需求分析与文档生成实验报告》表10/11/12/13/18
-- 用途：把手工 Excel 台账变成可查询的库，用 SQL 复现并校验报告口径
-- ============================================================

DROP TABLE IF EXISTS requirement_item;
DROP TABLE IF EXISTS run_note;
DROP TABLE IF EXISTS issue;
DROP TABLE IF EXISTS prompt_iter;
DROP TABLE IF EXISTS exp_run;

-- 1) 每次模型调用 = 一次运行
CREATE TABLE exp_run (
  run_code       TEXT PRIMARY KEY,              -- A / B / C
  model          TEXT NOT NULL,
  run_date       TEXT NOT NULL,
  n_effective    INTEGER NOT NULL,              -- 有效需求条数
  n_polluted     INTEGER NOT NULL DEFAULT 0,    -- 含示例污染的条数
  n_urgent_high  INTEGER NOT NULL,              -- 紧急度判为"高"的条数
  n_traceable    INTEGER NOT NULL               -- 可回查原文的条数
);

-- 2) A 次运行的逐条明细（报告表10 的原始输出，未改写）
CREATE TABLE requirement_item (
  run_code       TEXT NOT NULL REFERENCES exp_run(run_code),
  item_code      TEXT NOT NULL,                 -- D-00 ~ D-14
  title          TEXT NOT NULL,
  kano           TEXT,                          -- 兴奋型 / 期望型 / 基本型
  urgency        TEXT,                          -- 高 / 中 / 低
  traceable      INTEGER NOT NULL,              -- 1=能在访谈原文定位
  source_segment TEXT,                          -- U1..U7 用户 / T1..T8 访谈员
  disposition    TEXT,                          -- 表13 的六类处置
  PRIMARY KEY (run_code, item_code)
);

-- 3) 三次运行之间的差异记录（报告表11，仅记录已留档的事实）
CREATE TABLE run_note (
  run_code   TEXT NOT NULL REFERENCES exp_run(run_code),
  dimension  TEXT NOT NULL,
  detail     TEXT NOT NULL
);

-- 4) 模型输出问题清单（报告表12，F1~F8）
CREATE TABLE issue (
  code        TEXT PRIMARY KEY,
  issue_type  TEXT NOT NULL,
  evidence    TEXT NOT NULL,
  consequence TEXT NOT NULL,
  action      TEXT NOT NULL
);

-- 5) 提示词迭代记录与效果（报告表18 及正文）
CREATE TABLE prompt_iter (
  version        TEXT PRIMARY KEY,
  base_version   TEXT,
  change_summary TEXT NOT NULL,
  target_issue   TEXT NOT NULL,      -- 对应 issue.code
  effect_metric  TEXT NOT NULL,      -- 效果指标名
  effect_before  REAL,
  effect_after   REAL
);
