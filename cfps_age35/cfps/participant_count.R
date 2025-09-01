# 安装包（若未安装，取消注释运行）
# install.packages(c("haven", "tidyverse", "data.table"))

# 加载包
library(haven)
library(tidyverse)
library(data.table)

# 设置数据文件夹路径
data_folder <- "/Users/jiaxinshen/Downloads/cfps_person"  

# 列出文件夹内所有 .dta 文件
dta_files <- list.files(
  path = data_folder, 
  pattern = "\\.dta$",
  full.names = TRUE
)

# 先简单检查每个文件的基本信息
cat("找到的文件列表:\n")
print(basename(dta_files))

# 分开处理成人库和个人库
adult_files <- dta_files[grepl("adult", dta_files)]
person_files <- dta_files[grepl("person", dta_files)]

cat("\n成人库文件:", length(adult_files), "个\n")
cat("个人库文件:", length(person_files), "个\n")

# 更安全的数据读取函数
read_cfps_file <- function(file_path) {
  year <- str_extract(file_path, "cfps(\\d{4})") %>% 
    str_replace("cfps", "") %>% 
    as.numeric()
  
  data <- read_dta(file_path)
  
  # 检查并获取正确的变量名
  pid_var <- ifelse("pid" %in% colnames(data), "pid", 
                    ifelse("fid" %in% colnames(data), "fid", NA))
  
  # 查找年龄变量
  age_vars <- grep("age|年龄", colnames(data), ignore.case = TRUE, value = TRUE)
  age_var <- ifelse(length(age_vars) > 0, age_vars[1], NA)
  
  if (!is.na(pid_var) && !is.na(age_var)) {
    result <- data %>%
      select(pid = all_of(pid_var), age = all_of(age_var)) %>%
      mutate(survey_year = year)
    return(result)
  } else {
    cat("警告: 文件", basename(file_path), "中找不到pid或年龄变量\n")
    return(NULL)
  }
}

# 读取成人库数据
adult_data <- map_df(adult_files, read_cfps_file)

# 读取个人库数据
person_data <- map_df(person_files, read_cfps_file)

# 合并所有数据
all_data <- bind_rows(adult_data, person_data) %>%
  filter(!is.na(pid), !is.na(age)) %>%
  distinct()  # 去除重复记录

# 查看数据结构
cat("\n=== 数据概览 ===\n")
glimpse(all_data)
cat("总记录数:", nrow(all_data), "\n")
cat("唯一受访者数:", n_distinct(all_data$pid), "\n")
cat("调查年份:", paste(sort(unique(all_data$survey_year)), collapse = ", "), "\n")

# 统计参与次数
participated_count <- all_data %>%
  group_by(pid) %>%
  summarise(
    num_surveys = n(),
    survey_years = paste(sort(unique(survey_year)), collapse = ","),
    first_year = min(survey_year),
    last_year = max(survey_year),
    age_range = paste(min(age), "-", max(age))
  ) %>%
  arrange(desc(num_surveys))

# 筛选35岁左右的受访者
age_35_data <- all_data %>%
  filter(age >= 33 & age <= 37) %>%
  arrange(pid, survey_year)

# 输出结果
cat("\n=== 分析结果 ===\n")
cat("总受访者:", n_distinct(all_data$pid), "\n")
cat("参与多次调查的受访者:", sum(participated_count$num_surveys > 1), "\n")
cat("曾在35岁左右参与调查的受访者:", n_distinct(age_35_data$pid), "\n")

# 查看具体结果
cat("\n参与次数最多的前10位受访者:\n")
print(head(participated_count, 10))

cat("\n部分35岁左右的受访者记录:\n")
print(head(age_35_data, 10))

# 可视化参与次数分布
if (nrow(participated_count) > 0) {
  ggplot(participated_count, aes(x = num_surveys)) +
    geom_bar(fill = "steelblue", alpha = 0.8) +
    labs(title = "participation frequency",
         x = "particiaption", y = "num of participant") +
    theme_minimal()
}

# 保存结果（可选）
write_csv(participated_count, "participated_count.csv")
write_csv(age_35_data, "age_35_respondents.csv")
