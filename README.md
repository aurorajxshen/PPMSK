# PPMSK
The paper data mining &amp; visualization


## 📊 CFPS Data Processing for the “35岁现象”

This repository contains R scripts for processing longitudinal data from the **China Family Panel Studies (CFPS)** survey (2010–2022). The project focuses on exploring the so-called **“35岁现象”** (“age 35 phenomenon”) in China — a widely discussed social issue about career stagnation, economic challenges, and personal development risks individuals often face around the age of 35.

By tracking **continuous survey participants** and extracting those who were surveyed between **ages 33–37**, we aim to study how individuals’ economic status, employment, and personal trajectories evolve across multiple survey waves.

---

### 🔹 Scripts Overview

#### 1. `participant_count.R`

* Loads and merges all CFPS `.dta` files (both *adult* and *person* databases).
* Extracts basic information: respondent ID (`pid`), age, and survey year.
* Counts participation frequency across years for each individual.
* Identifies respondents who were surveyed around age 35 (33–37).
* Outputs two datasets:

  * **`participated_count.csv`** – summary of participation count, years, and age range.
  * **`age_35_respondents.csv`** – subset of respondents surveyed at 35±2 years.
* Provides visualization of **participation frequency distribution**.

#### 2. `cfps_continuous_participants_35age.R`

* Builds upon the merged dataset to **filter continuous participants** (those surveyed in ≥2 consecutive rounds).
* Extracts respondents’ minimum and maximum ages, survey years, and specific years when they were 35±2.
* Ensures data quality (e.g., checks missing age values, consistency of min/max age).
* Outputs **`corrected_continuous_participants_age35.csv`** – the final curated dataset of respondents who continuously participated and reached age 35 during at least one wave.
* Provides visualizations:

  * Scatterplot of **minimum vs. maximum age distribution**.
  * Histogram of **survey participation counts**.

---

### 🔹 Example Results

Screenshot of the processed results in **RStudio**:

<img width="1192" height="849" alt="Screenshot 2025-09-01 at 16 56 47" src="https://github.com/user-attachments/assets/495caf80-4352-410e-b84e-99588460ebc3" />

![5a5af3a0580281330e1b59cfdc89cb56](https://github.com/user-attachments/assets/9c705206-1eff-4160-84b7-e87c89a5d793)

* The **bar chart** shows participation distribution of respondents who reached \~35 years.
* The **final dataset (`final_result`)** includes `pid`, participation count, survey years around age 35, all survey years, and age range.
* Example: some respondents participated in **7 survey waves** and had multiple records at ages 34–36.

---

### 🔹 Research Context

The **“35岁现象”** in China highlights how individuals in their mid-30s often face significant **career bottlenecks**, **employment risks**, and **life transitions**. Using **CFPS longitudinal panel data**, this project allows us to:

* Track **individual life courses** across a decade (2010–2022).
* Compare economic, employment, and social variables between those who **consistently participated** and those with fewer records.
* Analyze **developmental trajectories** before, during, and after age 35.
* Provide empirical insights into the **structural and personal challenges** underlying the “35岁现象”.
