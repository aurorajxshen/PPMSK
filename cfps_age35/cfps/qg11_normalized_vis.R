# A brief explanation of the R script and its purpose
# This script standardizes and visualizes income trends from cleaned_summary_table.
# It calculates a weighted QG11 value for each participant, relative to their
# personal maximum income. The final plot shows normalized income trends over age
# to help identify the peak income years.

# Install and load necessary packages
if (!require(tidyverse)) install.packages("tidyverse")
if (!require(ggplot2)) install.packages("ggplot2")

library(tidyverse)
library(ggplot2)
library(dplyr)

# -------------------------------------------------------------------------------------
# 1. 数据准备与加权计算
# -------------------------------------------------------------------------------------

# 首先，将数据从宽格式转换为长格式，方便按pid进行计算
# 我们需要处理 ibirthy 变量，因为 read_dta 可能将其读作 labelled 类型
normalized_data <- cleaned_summary_table %>%
  # 统一 ibirthy 数据类型，确保能进行数学运算
  mutate(ibirthy = as.numeric(ibirthy)) %>%
  # 将 qg11_xxxx 列转换为长格式
  pivot_longer(
    cols = starts_with("qg11_"), 
    names_to = "year_label", 
    values_to = "qg11_value"
  ) %>%
  # 提取年份，并计算每年的年龄
  mutate(
    year = as.numeric(str_extract(year_label, "\\d{4}")),
    age = year - ibirthy
  ) %>%
  # 按 pid 分组，计算每个人的加权 qg11 值
  group_by(pid) %>%
  mutate(
    # 找到每个pid所有年份中的最高qg11值
    max_qg11 = max(qg11_value, na.rm = TRUE),
    # 按照最高qg11值进行加权，最高值为100
    weighted_qg11 = (qg11_value / max_qg11) * 100
  ) %>%
  ungroup() %>%
  # 移除 max_qg11 列，同时移除 qg11_value 为 NA 的行以避免绘图错误
  select(-max_qg11, -year_label) %>%
  drop_na(weighted_qg11)

write_csv(normalized_data, "cfps_qg11_normalized.csv")

# -------------------------------------------------------------------------------------
# 2. 可视化
# -------------------------------------------------------------------------------------

# 使用 ggplot2 绘制每个 pid 的加权 qg11 值随年龄变化的趋势线
income_trend_plot <- ggplot(normalized_data, aes(x = age, y = weighted_qg11, group = pid)) +
  
  # 绘制线条。为了处理大量数据，使用较低的透明度（alpha）
  # 这能让重叠较多的区域更深，帮助我们发现共同的趋势
  geom_line(alpha = 0.1) +
  
  # 添加一条水平线，代表峰值收入（100%）
  geom_hline(yintercept = 100, linetype = "dashed", color = "red", size = 0.8) +
  
  # 添加标签和标题：个体归一化收入趋势随年龄变化,峰值收入被标准化为100%
  labs(
    title = "Individual Normalized Income Over Age",
    subtitle = "peak income is standardized to 100%",
    x = "age",
    y = "Weighted Income (Peak Income = 100%)"
  ) +
  
  # 调整主题，使其看起来更专业
  theme_minimal() +
  
  # 调整y轴的范围，使其看起来更清晰
  scale_y_continuous(limits = c(0, 110), breaks = c(0, 25, 50, 75, 100)) +
  
  # 在100%峰值线旁边添加文本标签
  annotate("text", x = max(normalized_data$age) - 5, y = 105, 
           label = "peak income (100%)", color = "red", hjust = 1)

# 打印并显示图表
print(income_trend_plot)

# 将图表保存到文件
# ggsave("income_trends.png", plot = income_trend_plot, width = 10, height = 8, dpi = 300)