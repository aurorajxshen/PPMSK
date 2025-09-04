# A brief explanation of the R script and its purpose
# This script processes CFPS survey data to create a panel of participants who
# were continuously surveyed from 2014 to 2022. It then extracts their Gq11 income
# data across all survey waves.

# Install and load necessary packages
if (!require(tidyverse)) install.packages("tidyverse")
if (!require(haven)) install.packages("haven")
if (!require(dplyr)) install.packages("dplyr")

library(tidyverse)
library(haven)
library(dplyr)

# -------------------------------------------------------------------------------------
# 1. 设置数据文件路径和文件名映射
# -------------------------------------------------------------------------------------
# Please make sure this path is correct
file_path <- "/Users/jiaxinshen/Downloads/cfps_person"
demographics_file <- "/Users/jiaxinshen/R/cfps_pid_demographics.csv"
years <- c("2014", "2016", "2018", "2020", "2022")

# Define a mapping from years to your exact file names
file_mapping <- c(
  "2014" = "cfps2014adult_成人库.dta",
  "2016" = "cfps2016adult_成人库.dta",
  "2018" = "cfps2018person_个人库.dta",
  "2020" = "cfps2020person_个人库.dta",
  "2022" = "cfps2022person_202410.dta"
)

# -------------------------------------------------------------------------------------
# 2. 筛选出连续参与者的PID
# -------------------------------------------------------------------------------------
# Create an empty list to store the PIDs from each year's data
all_pids_by_year <- list()

for (year in years) {
  # Construct the full file path
  full_path <- file.path(file_path, file_mapping[year])
  
  # Read the .dta file and extract unique PIDs
  tryCatch({
    df <- read_dta(full_path)
    all_pids_by_year[[year]] <- df %>% pull(pid) %>% unique()
  }, error = function(e) {
    stop(paste("Error reading file for year", year, ":", e$message))
  })
}

# Find the intersection of all PID lists to get continuous participants
continuous_pids <- Reduce(intersect, all_pids_by_year)
cat("Number of continuous participants found:", length(continuous_pids), "\n\n")

# -------------------------------------------------------------------------------------
# 3. 创建包含基础信息和Gq11数据的最终表格
# -------------------------------------------------------------------------------------
# Read the list of continuous PIDs from the CSV file
demographics_df <- read_csv(demographics_file)
# Create a base table with PID, gender, and ibirthy
base_df <- demographics_df %>%
  select(pid, gender, ibirthy) %>%
  # NEW: 统一pid的数据类型以确保正确匹配
  mutate(pid = as.character(pid))

# Create empty columns for Gq11 data for each year
for (year in years) {
  base_df[[paste0("qg11_", year)]] <- NA_real_
}

# -------------------------------------------------------------------------------------
# 4. 循环填充 gq11 数据
# -------------------------------------------------------------------------------------
for (year in years) {
  filename <- file_mapping[year]
  full_path <- file.path(file_path, filename)
  
  # Read the current year's data
  df_year <- tryCatch({
    read_dta(full_path)
  }, error = function(e) {
    warning(paste("Skipping file due to read error:", full_path, ":", e$message))
    return(NULL)
  })
  
  if (is.null(df_year)) next # Skip if file read fails
  
  # 明确地选择和重命名gq11列，并过滤出连续参与者
  df_qg11 <- df_year %>%
    # Conditionally select the correct gq11 column, handling missing or misspelled names
    {
      if ("qg11" %in% names(.)) {
        select(., pid, qg11)
      } else if ("GQ11" %in% names(.)) {
        select(., pid, qg11 = QG11)
      } else {
        # Fallback if neither gq11 nor GQ11 exists
        select(., pid) %>% mutate(qg11 = NA_real_)
      }
    } %>%
    # NEW: 统一pid的数据类型以确保正确匹配
    mutate(pid = as.character(pid)) %>%
    # Filter for the continuous participants
    filter(pid %in% continuous_pids) %>%
    # Treat negative values as missing
    mutate(qg11 = ifelse(qg11 < 0, NA_real_, qg11))
  
  # Merge the extracted gq11 data into the base table
  base_df <- base_df %>%
    left_join(df_qg11, by = "pid") %>%
    # Populate the correct year column with the gq11 data
    mutate(!!paste0("qg11_", year) := qg11) %>%
    select(-qg11) # Remove the temporary gq11 column
}

# -------------------------------------------------------------------------------------
# 5. 完成表格并进行最终整理
# -------------------------------------------------------------------------------------
final_summary_table <- base_df %>%
  # Calculate age range
  mutate(
    min_age = 2014 - as.numeric(ibirthy),
    max_age = 2022 - as.numeric(ibirthy),
    age_range = paste0(min_age, "-", max_age)
  ) %>%
  # Select and reorder the final columns as requested
  select(
    pid, gender, ibirthy, age_range, `qg11_2014`, `qg11_2016`,
    `qg11_2018`, `qg11_2020`, `qg11_2022`
  ) %>%
  distinct()

# -------------------------------------------------------------------------------------
# 6. 显示结果
# -------------------------------------------------------------------------------------
cat("A preview of the final Gq11 summary table:\n")
print(head(final_summary_table))

# You can optionally save this table to a new CSV file
# write_csv(final_summary_table, "cfps_gq11_summary.csv")

# -------------------------------------------------------------------------------------
# 7. 数据清洗：移除 qg11 列中缺失值 >= 4 的行
# -------------------------------------------------------------------------------------
cleaned_summary_table <- final_summary_table %>%
  # NEW: Count the number of NAs in the qg11 columns for each row
  mutate(
    na_count = rowSums(is.na(select(., starts_with("qg11_"))))
  ) %>%
  # Filter to keep only rows with less than 4 NAs
  filter(na_count < 4) %>%
  # Remove the temporary na_count column
  select(-na_count)

# 显示清洗后的表格预览
cat("A preview of the cleaned summary table:\n")
print(head(cleaned_summary_table))

# You can save this cleaned table to a new CSV file if needed
write_csv(cleaned_summary_table, "cfps_gq11_cleaned_summary.csv")