# 加载必要的包
library(haven)
library(tidyverse)
library(data.table)

# 设置数据文件夹路径
data_folder <- "/Users/jiaxinshen/Downloads/cfps_person"

# 列出所有.dta文件
dta_files <- list.files(path = data_folder, pattern = "\\.dta$", full.names = TRUE)

# 安全读取函数
read_cfps_file <- function(file_path) {
  year <- str_extract(file_path, "cfps(\\d{4})") %>% 
    str_replace("cfps", "") %>% 
    as.numeric()
  
  data <- read_dta(file_path)
  
  # 查找PID和年龄变量
  pid_var <- ifelse("pid" %in% colnames(data), "pid", 
                    ifelse("fid" %in% colnames(data), "fid", NA))
  
  age_vars <- grep("age|年龄", colnames(data), ignore.case = TRUE, value = TRUE)
  age_var <- ifelse(length(age_vars) > 0, age_vars[1], NA)
  
  if (!is.na(pid_var) && !is.na(age_var)) {
    result <- data %>%
      select(pid = all_of(pid_var), age = all_of(age_var)) %>%
      mutate(survey_year = year)
    return(result)
  }
  return(NULL)
}

# 读取所有数据
all_data <- map_df(dta_files, read_cfps_file) %>%
  filter(!is.na(pid), !is.na(age)) %>%
  distinct()

# 1. 首先找出连续参与2轮及以上的受访者
continuous_participants <- all_data %>%
  arrange(pid, survey_year) %>%
  group_by(pid) %>%
  mutate(
    survey_count = n(),
    year_diff = survey_year - lag(survey_year),
    is_continuous = ifelse(is.na(year_diff) | year_diff <= 2, TRUE, FALSE)
  ) %>%
  filter(survey_count >= 2 & all(is_continuous, na.rm = TRUE)) %>%
  ungroup() %>%
  select(pid, survey_count) %>%
  distinct()

# 修正final_result的计算
final_result <- all_data %>%
  inner_join(continuous_participants, by = "pid") %>%
  group_by(pid) %>%
  summarise(
    survey_count = first(survey_count),
    # 年龄在33-37岁时的调查年份
    age_35_years = paste(sort(unique(survey_year[age >= 33 & age <= 37])), collapse = ","),
    # 所有参与调查的年份
    all_survey_years = paste(sort(unique(survey_year)), collapse = ","),
    # 最小年龄
    min_age = min(age, na.rm = TRUE),
    # 最大年龄
    max_age = max(age, na.rm = TRUE)
  ) %>%
  # 只保留确实在35岁左右参与过的受访者
  filter(age_35_years != "") %>%
  arrange(desc(survey_count), pid)

# 输出修正后的结果
cat("=== 修正后的筛选结果 ===\n")
cat("连续参与2轮及以上且在35岁左右参与调查的受访者数量:", nrow(final_result), "\n\n")

cat("前10位受访者的信息:\n")
print(head(final_result, 10))

# 检查数据质量
cat("\n=== 数据质量检查 ===\n")
cat("age_35_years为空的数量:", sum(final_result$age_35_years == ""), "\n")
cat("min_age大于max_age的数量:", sum(final_result$min_age > final_result$max_age), "\n")
cat("年龄范围合理的记录数:", sum(final_result$min_age <= final_result$max_age), "\n")

# 查看具体的年龄分布
cat("\n=== 年龄分布统计 ===\n")
age_stats <- final_result %>%
  summarise(
    avg_min_age = mean(min_age),
    avg_max_age = mean(max_age),
    min_age_overall = min(min_age),
    max_age_overall = max(max_age)
  )
print(age_stats)

# 保存修正后的结果
write_csv(final_result, "/Users/jiaxinshen/R/cfps/corrected_continuous_participants_age35.csv")

# 可视化年龄分布
ggplot(final_result, aes(x = min_age, y = max_age)) +
  geom_point(alpha = 0.6, color = "steelblue") +
  geom_abline(slope = 1, intercept = 0, linetype = "dashed", color = "red") +
  labs(title = "受访者最小vs最大年龄分布",
       x = "最小年龄", y = "最大年龄") +
  theme_minimal()

# 查看参与轮次分布
ggplot(final_result, aes(x = survey_count)) +
  geom_bar(fill = "orange", alpha = 0.8) +
  labs(title = "参与轮次分布",
       x = "参与轮次", y = "人数") +
  theme_minimal()