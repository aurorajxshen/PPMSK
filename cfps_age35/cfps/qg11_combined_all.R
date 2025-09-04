# A brief explanation of the R script and its purpose
# This script assumes 'combined_data' is already loaded in the R environment.
# It processes all data within this dataframe, pivoting it to a wide format
# to create a summary table with demographic and income data.

# Install and load necessary packages
if (!require(tidyverse)) install.packages("tidyverse")
if (!require(haven)) install.packages("haven")
if (!require(dplyr)) install.packages("dplyr")

library(tidyverse)
library(haven)
library(dplyr)

# -------------------------------------------------------------------------------------
# 1. 重塑数据并创建最终表格
# -------------------------------------------------------------------------------------
# 假设 combined_data 已经存在
# (您也可以通过运行我们之前的脚本来创建它)
# 首先，提取并去重人口统计信息，为后续合并做准备
demographics_info <- combined_data %>%
  select(pid, gender, ibirthy) %>%
  distinct() %>%
  # 计算年龄范围
  mutate(
    min_age = 2014 - as.numeric(ibirthy),
    max_age = 2022 - as.numeric(ibirthy),
    age_range = paste0(min_age, "-", max_age)
  )

# 然后，处理并重塑 gq11 数据
qg11_data_wide <- combined_data %>%
  # Handle negative and zero values in gq11
  mutate(gq11 = case_when(
    qg11 < 0 ~ NA_real_,
    qg11 == 0 ~ NA_real_,
    TRUE ~ qg11
  )) %>%
  # Pivot the data from long to wide format
  pivot_wider(
    id_cols = pid,
    names_from = year,
    values_from = qg11,
    names_prefix = "qg11_",
    values_fill = NA_real_
  )

# 最后，合并人口统计信息和 gq11 数据，并整理列顺序
final_summary_table <- left_join(demographics_info, qg11_data_wide, by = "pid") %>%
  # Select and reorder the final columns as requested
  select(
    pid, gender, ibirthy, age_range, `qg11_2014`, `qg11_2016`,
    `qg11_2018`, `qg11_2020`, `qg11_2022`
  ) %>%
  distinct()

# -------------------------------------------------------------------------------------
# 2. 显示结果
# -------------------------------------------------------------------------------------
cat("A preview of the final summary table with all data from combined_data:\n")
print(head(final_summary_table))

# You can save this table to a new CSV file
# write_csv(final_summary_table, "cfps_gq11_summary_all_data.csv")