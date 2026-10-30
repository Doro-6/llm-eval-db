-- ============================================================
-- 5 类分析 SQL：每一条都对应报告里的一个结论
-- 跑法：python run.py
-- ============================================================

-- ---------- Q1 三次运行对比：条数波动 + 可追溯率 ----------
-- 对应报告：表11「有效需求条数 14/12/15」「可追溯比例 10/14、9/12、11/15」
SELECT
  run_code                                  AS 运行,
  n_effective                               AS 有效条数,
  n_polluted                                AS 示例污染,
  n_urgent_high                             AS 紧急度高,
  n_traceable || '/' || n_effective          AS 可追溯,
  ROUND(n_traceable * 100.0 / n_effective, 1) AS 可追溯率
FROM exp_run
ORDER BY run_code;


-- ---------- Q2 口径校验：从明细算出来的可追溯条数，是否等于汇总 ----------
-- 如果两边不一致，说明台账录错了 —— 这一步就是数据质量校验
SELECT
  r.run_code                                            AS 运行,
  r.n_traceable                                         AS 汇总表记录,
  SUM(CASE WHEN i.traceable = 1 THEN 1 ELSE 0 END)       AS 明细算出,
  CASE WHEN r.n_traceable = SUM(CASE WHEN i.traceable = 1 THEN 1 ELSE 0 END)
       THEN '一致' ELSE '不一致，需核查' END              AS 校验结果
FROM exp_run r
JOIN requirement_item i ON i.run_code = r.run_code
WHERE i.item_code <> 'D-00'
GROUP BY r.run_code, r.n_traceable
ORDER BY r.run_code;


-- ---------- Q3 KANO 归类分布（看模型把需求判成什么型） ----------
SELECT
  kano                     AS KANO类型,
  COUNT(*)                 AS 条数,
  ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 1) AS 占比
FROM requirement_item
WHERE item_code <> 'D-00'
GROUP BY kano
ORDER BY 条数 DESC;


-- ---------- Q4 原始条目 → 人工处置的收敛情况 ----------
-- 对应报告：「15 条原始输出 → 8 条被并入/合并/拆分，3 条删除，1 条转待验证…」
SELECT
  disposition                       AS 处置,
  COUNT(*)                          AS 条数,
  GROUP_CONCAT(item_code, ', ')     AS 涉及条目
FROM requirement_item
WHERE item_code <> 'D-00'
GROUP BY disposition
ORDER BY 条数 DESC;


-- ---------- Q5 无原文依据的条目（幻觉的直接证据） ----------
SELECT
  item_code       AS 编号,
  title           AS 内容,
  source_segment  AS 原文来源,
  disposition     AS 处置
FROM requirement_item
WHERE traceable = 0 AND item_code <> 'D-00'
ORDER BY item_code;


-- ---------- Q6 问题类型分布 + 各自处置 ----------
SELECT
  issue_type    AS 问题类型,
  code          AS 编号,
  action        AS 处置
FROM issue
ORDER BY code;


-- ---------- Q7 提示词迭代的效果（改一处，涨多少） ----------
SELECT
  version        AS 版本,
  base_version   AS 基于,
  target_issue   AS 针对问题,
  effect_metric  AS 指标,
  effect_before  AS 改前,
  effect_after   AS 改后,
  (effect_after - effect_before) AS 提升
FROM prompt_iter
ORDER BY version;
