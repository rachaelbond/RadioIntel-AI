# Radio Station Listener Analysis Script v:3.8
# Comprehensive analysis of online listener data with new SQL structure
# (c) Rachael Bond, 2025
# contact: radioanalytics.mjfiz@rlb.me
#
# Released under GPL 3.0 :)
#
#   GPL 3.0 License:
# 
#   This program is free software: you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by
#   the Free Software Foundation, either version 3 of the License, or
#   any later version.
#
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
#   GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License
#   along with this program. If not, see https://www.gnu.org/licenses/


# Clear the environment of any old data
rm(list = ls())
options(warn = 1)  # Show warnings immediately
gc(reset = TRUE)  # Initial cleanup

# Prevent R from hoarding memory
options(expressions = 5000)  # Reduce expression memory
Sys.setenv("R_GC_MEM_GROW" = "1")  # More aggressive garbage collection
Sys.setenv("R_MAX_VSIZE" = "4Gb")  # Limit R's memory hunger

# =============================================================================
# USER CONFIGURATION - EDIT THESE SETTINGS
# =============================================================================

# REPORT TYPE: Choose what data to analyze
# Option 1: "ALL" - Use all available data (cumulative report)
# Option 2: Specific month - Use format "YYYY-MM" (e.g., "2025-01", "2024-12")
REPORT_TYPE <- "ALL"  # Change this to "2025-01" for January 2025 only, etc.
# REPORT_TYPE <- "2025-07"

# Alternative: Set specific date range (leave as NULL to use REPORT_TYPE above)
# Use format "YYYY-MM-DD"
START_DATE <- NULL  # e.g., "2025-01-01" 
END_DATE <- NULL    # e.g., "2025-01-31"
# START_DATE <- "2025-07-01"  # e.g., "2025-01-01" 
# END_DATE <- "2025-07-02"    # e.g., "2025-01-31"

# Database connection details
DB_HOST <- ""
DB_PORT <- 3306
DB_USER <- ""
DB_PASSWORD <- ""
DB_NAME <- ""
DB_TABLE <- "analytics"

YOUR_NAME <- ""
YOUR_EMAIL <- ""

MAIN_STATION_NAME <- ""
SECOND_STATION_NAME <- ""
COMPARISON_STATION_NAME <- ""

MAIN_FEATURED_SHOW <- ""
SECOND_FEATURED_SHOW <- ""
COMPARISON_FEATURED_SHOW <- ""

ANALYSE_SECOND_STATION <- "Y"
ANALYSE_COMPARISON_STATION <- "Y"
ANALYSE_WEATHER <- "Y"

EXCLUDE_TERMS <- c("")

DATA_COLLECTION <- 5 # How often the data is collected by the PHP script in minutes

DEBUG_TO_CONSOLE <- "Y"

# =============================================================================
# END USER CONFIGURATION - DON'T EDIT BELOW THIS LINE
# =============================================================================

# Install required packages if not already installed
required_packages <- c("DBI", "RMariaDB", "dplyr", "ggplot2", "kableExtra", 
                       "lubridate", "tidyr", "scales", "gridExtra", "corrplot", 
                       "forecast", "stringr", "knitr", "rmarkdown", "glue", "jsonlite")

for(pkg in required_packages) {
  if(!require(pkg, character.only = TRUE)) {
    install.packages(pkg)
    library(pkg, character.only = TRUE)
  }
}

# Load required libraries
library(DBI)
library(RMariaDB)
library(dplyr)
library(ggplot2)
library(kableExtra)
library(lubridate)
library(tidyr)
library(scales)
library(gridExtra)
library(corrplot)
library(forecast)
library(stringr)
library(knitr)
library(rmarkdown)
library(glue)
library(jsonlite)

# Connect to MariaDB database
con <- dbConnect(RMariaDB::MariaDB(),
                 host = DB_HOST,
                 port = DB_PORT,
                 user = DB_USER,
                 password = DB_PASSWORD,
                 dbname = DB_NAME)

# Test connection
if (dbIsValid(con)) {
  cat("Successfully connected to MariaDB database!\n")
} else {
  stop("Failed to connect to database. Please check your connection details.")
}

# Build SQL query based on user settings
base_query <- paste0("SELECT * FROM ", DB_TABLE)

# Determine date filtering
if (!is.null(START_DATE) && !is.null(END_DATE)) {
  # Use specific date range
  where_clause <- paste0(" WHERE date >= '", START_DATE, "' AND date <= '", END_DATE, "'")
  report_description <- paste("from", START_DATE, "to", END_DATE)
  cat("Generating report for custom date range:", START_DATE, "to", END_DATE, "\n")
} else if (REPORT_TYPE != "ALL") {
  # Use specific month
  if (grepl("^\\d{4}-\\d{2}$", REPORT_TYPE)) {
    where_clause <- paste0(" WHERE date >= '", REPORT_TYPE, "-01' AND date < DATE_ADD('", REPORT_TYPE, "-01', INTERVAL 1 MONTH)")
    report_description <- paste("for", format(as.Date(paste0(REPORT_TYPE, "-01")), "%B %Y"))
    cat("Generating report for month:", REPORT_TYPE, "\n")
  } else {
    stop("Invalid REPORT_TYPE format. Use 'ALL' or 'YYYY-MM' format (e.g., '2025-01')")
  }
} else {
  # Use all data
  where_clause <- ""
  report_description <- "for all available data"
  cat("Generating cumulative report for all available data\n")
}

# Complete query
query <- paste0(base_query, where_clause, " ORDER BY date, time")

# Load data from database
cat("Loading data from database...\n")
data <- dbGetQuery(con, query)

# Close database connection
dbDisconnect(con)

# Check data loaded successfully
if (nrow(data) == 0) {
  stop(paste("No data retrieved from database", report_description, ". Please check your date range and data availability."))
}

cat("Data loaded successfully!\n")

if (DEBUG_TO_CONSOLE == "Y") {
  cat("Rows:", nrow(data), "\n")
  cat("Columns:", ncol(data), "\n")
  cat("Date range:", min(as.Date(data$date)), "to", max(as.Date(data$date)), "\n\n")
  cat("Preprocessing data...\n")
}

data <- data %>%
  mutate(
    datetime = as.POSIXct(paste(date, time), format = "%Y-%m-%d %H:%M", tz = "UTC"),
    date = as.Date(date),
    hour = hour(datetime),
    minute = minute(datetime),
    weekday = weekdays(date),
    month = format(date, "%Y-%m"),
    main_total_listeners = main_stream1 + main_stream2,
    second_total_listeners = second_stream1 + second_stream2,
    comparison_total_listeners = comparison_stream,
    time_slot = case_when(
      hour >= 6 & hour < 10 ~ "Morning (6-10)",
      hour >= 10 & hour < 14 ~ "Midday (10-14)",
      hour >= 14 & hour < 18 ~ "Afternoon (14-18)",
      hour >= 18 & hour < 22 ~ "Evening (18-22)",
      TRUE ~ "Night (22-6)"
    ),
    # Clean main station show and presenter names
    main_showname = str_trim(main_showname),
    main_presenter = str_trim(main_presenter),
    
    # Create main station live/recorded factor
    main_live_recorded = case_when(
      main_recorded == 0 ~ "Live",
      main_recorded == 1 ~ "Pre-recorded",
      TRUE ~ "Unknown"
    ),
    
    # Clean second station show and presenter names
    second_showname = str_trim(second_showname),
    second_presenter = str_trim(second_presenter),
    
    # Create second station live/recorded factor
    second_live_recorded = case_when(
      second_recorded == 0 ~ "Live",
      second_recorded == 1 ~ "Pre-recorded",
      TRUE ~ "Unknown"
    ),
    
    # Clean comparison station show and presenter names
    comparison_showname = str_trim(comparison_showname),
    comparison_presenter = str_trim(comparison_presenter),

    # Create comparison station live/recorded factor
    comparison_live_recorded = case_when(
      comparison_recorded == 0 ~ "Live",
      comparison_recorded == 1 ~ "Pre-recorded",
      TRUE ~ "Unknown"
    ),
    
    # Weekend/weekday classification
    day_type = case_when(
      weekday %in% c("Saturday", "Sunday") ~ "Weekend",
      TRUE ~ "Weekday"
    )
  ) %>%
  filter(!is.na(main_total_listeners), main_total_listeners >= 0, !is.na(hour)) %>%
  arrange(datetime)

# Set weekday order
data$weekday <- factor(data$weekday, levels = c("Monday", "Tuesday", "Wednesday", 
                                                "Thursday", "Friday", "Saturday", "Sunday"))

# Update date_range for report title
if (!is.null(START_DATE) && !is.null(END_DATE)) {
  date_range <- if (format(as.Date(START_DATE), "%B %Y") == format(as.Date(END_DATE), "%B %Y")) {
    format(as.Date(START_DATE), "%B %Y")
  } else {
    paste(format(as.Date(START_DATE), "%B %Y"), "\u2013", format(as.Date(END_DATE), "%B %Y"))
  }
} else if (REPORT_TYPE != "ALL") {
  date_range <- format(as.Date(paste0(REPORT_TYPE, "-01")), "%B %Y")
} else {
  date_range <- if (format(min(data$date), "%B %Y") == format(max(data$date), "%B %Y")) {
    format(min(data$date), "%B %Y")
  } else {
    paste(format(min(data$date), "%B %Y"), "\u2013", format(max(data$date), "%B %Y"))
  }
}

HOUR_NORMALISATION <- 60 / DATA_COLLECTION

if (DEBUG_TO_CONSOLE == "Y") {
  cat("Data preprocessing complete!\n")
  cat("Final dataset:", nrow(data), "observations\n")
  cat("Report will be titled:", date_range, "\n\n")
}

# =============================================================================
# ANALYSIS 1: DAILY PATTERNS & BASIC SHOW ANALYSIS
# =============================================================================
# This analysis provides:
# 1. Day of week patterns (for daily pattern charts)
# 2. Basic show analysis (for absolute listener charts)
# 3. Hourly baselines (foundation for all performance calculations)

cat("Running Analysis 1: Daily Patterns & Basic Show Analysis...\n")

# =============================================================================
# PART 1A: DAY OF WEEK PATTERNS - MAIN STATION
# =============================================================================

# Calculate day of week patterns for main station
main_dow_analysis <- data %>%
  group_by(weekday, hour) %>%
  summarise(
    main_avg_listeners = mean(main_total_listeners, na.rm = TRUE),
    main_avg_stream1 = mean(main_stream1, na.rm = TRUE),
    main_avg_stream2 = mean(main_stream2, na.rm = TRUE),
    .groups = 'drop'
  )

# Calculate hourly averages for percentage comparisons
main_hourly_avg <- data %>%
  group_by(hour) %>%
  summarise(main_overall_avg = mean(main_total_listeners, na.rm = TRUE), .groups = 'drop')

# Create percentage difference data for day of week patterns
main_dow_comparison <- main_dow_analysis %>%
  left_join(main_hourly_avg, by = "hour") %>%
  mutate(pct_diff = ((main_avg_listeners - main_overall_avg) / main_overall_avg) * 100)

# Clean data for plotting
main_dow_comparison_clean <- main_dow_comparison %>%
  filter(!is.na(pct_diff), !is.infinite(pct_diff), !is.na(hour), !is.na(weekday))

# Prepare data for line charts
main_dow_comparison_line_chart <- main_dow_comparison_clean %>%
  mutate(weekday = factor(weekday, levels = c("Monday", "Tuesday", "Wednesday", 
                                              "Thursday", "Friday", "Saturday", "Sunday")))

# Prepare data for heatmaps
main_dow_analysis_clean <- main_dow_analysis %>%
  filter(!is.na(main_avg_listeners), !is.infinite(main_avg_listeners), !is.na(hour), !is.na(weekday))

# Set factor levels for heatmap display (reversed for proper ordering)
main_dow_comparison_clean$weekday <- factor(main_dow_comparison_clean$weekday, 
                                            levels = rev(levels(main_dow_comparison_line_chart$weekday)))

main_dow_analysis_clean$weekday <- factor(main_dow_analysis_clean$weekday, 
                                          levels = rev(levels(main_dow_comparison_line_chart$weekday)))

# =============================================================================
# PART 1B: BASIC SHOW ANALYSIS - MAIN STATION
# =============================================================================

# Basic show analysis with hourly baseline comparison
main_show_hourly_analysis <- data %>%
  filter(!is.na(main_showname), main_showname != "", main_showname != "Unknown", main_stand_in != 1) %>%
  group_by(main_showname, main_presenter, main_stand_in, hour, day_type) %>%
  summarise(
    main_avg_listeners = mean(main_total_listeners, na.rm = TRUE),
    main_sessions = n(),
    .groups = 'drop'
  ) %>%
  filter(main_sessions >= 3)

# Calculate hourly baselines for show performance (by day type)
main_hourly_baseline <- data %>%
  group_by(hour, day_type) %>%
  summarise(main_hour_avg = mean(main_total_listeners, na.rm = TRUE), .groups = 'drop')

# Calculate show performance vs hourly average
main_show_hourly_performance <- main_show_hourly_analysis %>%
  left_join(main_hourly_baseline, by = c("hour", "day_type")) %>%
  mutate(
    main_pct_vs_hour = ((main_avg_listeners - main_hour_avg) / main_hour_avg) * 100
  ) %>%
  arrange(desc(main_pct_vs_hour))

# =============================================================================
# PART 1C: SECOND STATION (IF ENABLED)
# =============================================================================

if (ANALYSE_SECOND_STATION == "Y") {
  
  # Day of week patterns for second station
  second_dow_analysis <- data %>%
    group_by(weekday, hour) %>%
    summarise(
      second_avg_listeners = mean(second_total_listeners, na.rm = TRUE),
      .groups = 'drop'
    )
  
  second_hourly_avg <- data %>%
    group_by(hour) %>%
    summarise(second_overall_avg = mean(second_total_listeners, na.rm = TRUE), .groups = 'drop')
  
  second_dow_comparison <- second_dow_analysis %>%
    left_join(second_hourly_avg, by = "hour") %>%
    mutate(pct_diff = ((second_avg_listeners - second_overall_avg) / second_overall_avg) * 100)
  
  second_dow_comparison_clean <- second_dow_comparison %>%
    filter(!is.na(pct_diff), !is.infinite(pct_diff), !is.na(hour), !is.na(weekday))
  
  second_dow_comparison_line_chart <- second_dow_comparison_clean %>%
    mutate(weekday = factor(weekday, levels = c("Monday", "Tuesday", "Wednesday", 
                                                "Thursday", "Friday", "Saturday", "Sunday")))
  
  second_dow_analysis_clean <- second_dow_analysis %>%
    filter(!is.na(second_avg_listeners), !is.infinite(second_avg_listeners), !is.na(hour), !is.na(weekday))
  
  second_dow_comparison_clean$weekday <- factor(second_dow_comparison_clean$weekday, 
                                                levels = rev(levels(second_dow_comparison_clean$weekday)))
  
  second_dow_analysis_clean$weekday <- factor(second_dow_analysis_clean$weekday, 
                                              levels = rev(levels(second_dow_analysis_clean$weekday)))
  
  # Basic show analysis for second station
  second_show_hourly_analysis <- data %>%
    filter(!is.na(second_showname), second_showname != "", second_showname != "Unknown", second_stand_in != 1) %>%
    group_by(second_showname, second_presenter, second_stand_in, hour, day_type) %>%
    summarise(
      second_avg_listeners = mean(second_total_listeners, na.rm = TRUE),
      second_sessions = n(),
      .groups = 'drop'
    ) %>%
    filter(second_sessions >= 3)
  
  second_hourly_baseline <- data %>%
    group_by(hour, day_type) %>%
    summarise(second_hour_avg = mean(second_total_listeners, na.rm = TRUE), .groups = 'drop')
  
  second_show_hourly_performance <- second_show_hourly_analysis %>%
    left_join(second_hourly_baseline, by = c("hour", "day_type")) %>%
    mutate(
      second_pct_vs_hour = ((second_avg_listeners - second_hour_avg) / second_hour_avg) * 100
    ) %>%
    arrange(desc(second_pct_vs_hour))
}

# =============================================================================
# PART 1D: COMPARISON STATION (IF ENABLED)
# =============================================================================

if (ANALYSE_COMPARISON_STATION == "Y") {
  
  # Day of week patterns for comparison station
  comparison_dow_analysis <- data %>%
    group_by(weekday, hour) %>%
    summarise(
      comparison_avg_listeners = mean(comparison_total_listeners, na.rm = TRUE),
      .groups = 'drop'
    )
  
  comparison_hourly_avg <- data %>%
    group_by(hour) %>%
    summarise(comparison_overall_avg = mean(comparison_total_listeners, na.rm = TRUE), .groups = 'drop')
  
  comparison_dow_comparison <- comparison_dow_analysis %>%
    left_join(comparison_hourly_avg, by = "hour") %>%
    mutate(pct_diff = ((comparison_avg_listeners - comparison_overall_avg) / comparison_overall_avg) * 100)
  
  comparison_dow_comparison_clean <- comparison_dow_comparison %>%
    filter(!is.na(pct_diff), !is.infinite(pct_diff), !is.na(hour), !is.na(weekday))
  
  comparison_dow_comparison_line_chart <- comparison_dow_comparison_clean %>%
    mutate(weekday = factor(weekday, levels = c("Monday", "Tuesday", "Wednesday", 
                                                "Thursday", "Friday", "Saturday", "Sunday")))
  
  comparison_dow_analysis_clean <- comparison_dow_analysis %>%
    filter(!is.na(comparison_avg_listeners), !is.infinite(comparison_avg_listeners), !is.na(hour), !is.na(weekday))
  
  comparison_dow_comparison_clean$weekday <- factor(comparison_dow_comparison_clean$weekday, 
                                                    levels = rev(levels(comparison_dow_comparison_clean$weekday)))
  
  comparison_dow_analysis_clean$weekday <- factor(comparison_dow_analysis_clean$weekday, 
                                                  levels = rev(levels(comparison_dow_analysis_clean$weekday)))
  
  # Basic show analysis for comparison station
  comparison_show_hourly_analysis <- data %>%
    filter(!is.na(comparison_showname), comparison_showname != "", comparison_showname != "Unknown", comparison_stand_in != 1) %>%
    group_by(comparison_showname, comparison_presenter, comparison_stand_in, hour, day_type) %>%
    summarise(
      comparison_avg_listeners = mean(comparison_total_listeners, na.rm = TRUE),
      comparison_sessions = n(),
      .groups = 'drop'
    ) %>%
    filter(comparison_sessions >= 3)
  
  comparison_hourly_baseline <- data %>%
    group_by(hour, day_type) %>%
    summarise(comparison_hour_avg = mean(comparison_total_listeners, na.rm = TRUE), .groups = 'drop')
  
  comparison_show_hourly_performance <- comparison_show_hourly_analysis %>%
    left_join(comparison_hourly_baseline, by = c("hour", "day_type")) %>%
    mutate(
      comparison_pct_vs_hour = ((comparison_avg_listeners - comparison_hour_avg) / comparison_hour_avg) * 100
    ) %>%
    arrange(desc(comparison_pct_vs_hour))
}

# =============================================================================
# PART 1E: CREATE HEATMAP DATA FOR SHOWS IN MULTIPLE TIME SLOTS
# =============================================================================

cat("Creating hourly performance heatmap data...\n")

# =============================================================================
# MAIN STATION PERFORMANCE HEATMAPS
# =============================================================================

if (exists("main_show_hourly_performance") && nrow(main_show_hourly_performance) > 0) {
  
  # Weekday shows performance heatmap data
  main_weekday_heatmap_data <- main_show_hourly_performance %>%
    filter(day_type == "Weekday") %>%
    filter(!grepl(paste(EXCLUDE_TERMS, collapse = "|"), main_showname, ignore.case = TRUE)) %>%
    filter(main_stand_in != 1) %>%
    # IMPROVED: Better filtering for shows with meaningful multiple time slots
    group_by(main_showname) %>%
    mutate(
      distinct_hours = n_distinct(hour),
      total_sessions = sum(main_sessions),
      avg_sessions_per_hour = total_sessions / distinct_hours
    ) %>%
    # Only include shows that truly broadcast in multiple time slots with sufficient data
    filter(
      distinct_hours >= 2,  # Must appear in at least 2 different hours
      total_sessions >= 15,  # Must have reasonable amount of data overall
      avg_sessions_per_hour >= 5  # Must have decent coverage in each hour (not just missing data)
    ) %>%
    ungroup()
  
  # IMPROVED: Find primary hour more robustly (hour with most sessions AND best data coverage)
  main_primary_hours <- main_weekday_heatmap_data %>%
    group_by(main_showname, hour) %>%
    summarise(
      hour_sessions = sum(main_sessions),
      hour_coverage = n(),  # How many different episodes in this hour
      .groups = 'drop'
    ) %>%
    group_by(main_showname) %>%
    # Primary hour = hour with most total sessions AND reasonable coverage
    filter(hour_sessions >= 5) %>%  # Must have decent data in the hour
    arrange(desc(hour_sessions)) %>%
    slice(1) %>%
    ungroup() %>%
    select(main_showname, primary_hour = hour)
  
  # Create final heatmap data with time slot ordering
  main_weekday_heatmap_data <- main_weekday_heatmap_data %>%
    left_join(main_primary_hours, by = "main_showname") %>%
    # Only keep shows that have a valid primary hour
    filter(!is.na(primary_hour)) %>%
    arrange(primary_hour, main_showname) %>%
    select(main_showname, hour, main_pct_vs_hour) %>%
    mutate(main_showname = factor(main_showname, levels = rev(unique(main_showname))))
  
  # Weekend shows performance heatmap data  
  main_weekend_heatmap_data <- main_show_hourly_performance %>%
    filter(day_type == "Weekend") %>%
    filter(!grepl(paste(EXCLUDE_TERMS, collapse = "|"), main_showname, ignore.case = TRUE)) %>%
    filter(main_stand_in != 1) %>%
    # IMPROVED: Better filtering for shows with meaningful multiple time slots
    group_by(main_showname) %>%
    mutate(
      distinct_hours = n_distinct(hour),
      total_sessions = sum(main_sessions),
      avg_sessions_per_hour = total_sessions / distinct_hours
    ) %>%
    # Only include shows that truly broadcast in multiple time slots with sufficient data
    filter(
      distinct_hours >= 2,  # Must appear in at least 2 different hours
      total_sessions >= 15,  # Must have reasonable amount of data overall
      avg_sessions_per_hour >= 5  # Must have decent coverage in each hour
    ) %>%
    ungroup()
  
  # Find primary hours for weekend shows
  main_weekend_primary_hours <- main_weekend_heatmap_data %>%
    group_by(main_showname, hour) %>%
    summarise(
      hour_sessions = sum(main_sessions),
      hour_coverage = n(),
      .groups = 'drop'
    ) %>%
    group_by(main_showname) %>%
    filter(hour_sessions >= 5) %>%
    arrange(desc(hour_sessions)) %>%
    slice(1) %>%
    ungroup() %>%
    select(main_showname, primary_hour = hour)
  
  # Create final weekend heatmap data
  main_weekend_heatmap_data <- main_weekend_heatmap_data %>%
    left_join(main_weekend_primary_hours, by = "main_showname") %>%
    filter(!is.na(primary_hour)) %>%
    arrange(primary_hour, main_showname) %>%
    select(main_showname, hour, main_pct_vs_hour) %>%
    mutate(main_showname = factor(main_showname, levels = rev(unique(main_showname))))
  
  cat("Main station heatmap data created:", nrow(main_weekday_heatmap_data), "weekday,", nrow(main_weekend_heatmap_data), "weekend data points\n")
  
} else {
  main_weekday_heatmap_data <- data.frame()
  main_weekend_heatmap_data <- data.frame()
}

# =============================================================================
# SECOND STATION PERFORMANCE HEATMAPS (IF ENABLED)
# =============================================================================

if (ANALYSE_SECOND_STATION == "Y" && exists("second_show_hourly_performance") && nrow(second_show_hourly_performance) > 0) {
  
  # Weekday shows performance heatmap data for second station
  second_weekday_heatmap_data <- second_show_hourly_performance %>%
    filter(day_type == "Weekday") %>%
    filter(!grepl(paste(EXCLUDE_TERMS, collapse = "|"), second_showname, ignore.case = TRUE)) %>%
    filter(second_stand_in != 1) %>%
    group_by(second_showname) %>%
    mutate(
      distinct_hours = n_distinct(hour),
      total_sessions = sum(second_sessions),
      avg_sessions_per_hour = total_sessions / distinct_hours
    ) %>%
    filter(
      distinct_hours >= 2,
      total_sessions >= 15,
      avg_sessions_per_hour >= 5
    ) %>%
    ungroup()
  
  # Find primary hours for second station weekday shows
  second_primary_hours <- second_weekday_heatmap_data %>%
    group_by(second_showname, hour) %>%
    summarise(
      hour_sessions = sum(second_sessions),
      hour_coverage = n(),
      .groups = 'drop'
    ) %>%
    group_by(second_showname) %>%
    filter(hour_sessions >= 5) %>%
    arrange(desc(hour_sessions)) %>%
    slice(1) %>%
    ungroup() %>%
    select(second_showname, primary_hour = hour)
  
  # Create final second station weekday heatmap data
  second_weekday_heatmap_data <- second_weekday_heatmap_data %>%
    left_join(second_primary_hours, by = "second_showname") %>%
    filter(!is.na(primary_hour)) %>%
    arrange(primary_hour, second_showname) %>%
    select(second_showname, hour, second_pct_vs_hour) %>%
    mutate(second_showname = factor(second_showname, levels = rev(unique(second_showname))))
  
  # Weekend shows for second station
  second_weekend_heatmap_data <- second_show_hourly_performance %>%
    filter(day_type == "Weekend") %>%
    filter(!grepl(paste(EXCLUDE_TERMS, collapse = "|"), second_showname, ignore.case = TRUE)) %>%
    filter(second_stand_in != 1) %>%
    group_by(second_showname) %>%
    mutate(
      distinct_hours = n_distinct(hour),
      total_sessions = sum(second_sessions),
      avg_sessions_per_hour = total_sessions / distinct_hours
    ) %>%
    filter(
      distinct_hours >= 2,
      total_sessions >= 15,
      avg_sessions_per_hour >= 5
    ) %>%
    ungroup()
  
  # Find primary hours for second station weekend shows
  second_weekend_primary_hours <- second_weekend_heatmap_data %>%
    group_by(second_showname, hour) %>%
    summarise(
      hour_sessions = sum(second_sessions),
      hour_coverage = n(),
      .groups = 'drop'
    ) %>%
    group_by(second_showname) %>%
    filter(hour_sessions >= 5) %>%
    arrange(desc(hour_sessions)) %>%
    slice(1) %>%
    ungroup() %>%
    select(second_showname, primary_hour = hour)
  
  # Create final second station weekend heatmap data
  second_weekend_heatmap_data <- second_weekend_heatmap_data %>%
    left_join(second_weekend_primary_hours, by = "second_showname") %>%
    filter(!is.na(primary_hour)) %>%
    arrange(primary_hour, second_showname) %>%
    select(second_showname, hour, second_pct_vs_hour) %>%
    mutate(second_showname = factor(second_showname, levels = rev(unique(second_showname))))
  
  cat("Second station heatmap data created:", nrow(second_weekday_heatmap_data), "weekday,", nrow(second_weekend_heatmap_data), "weekend data points\n")
  
} else {
  second_weekday_heatmap_data <- data.frame()
  second_weekend_heatmap_data <- data.frame()
}

cat("Hourly performance heatmap data generation complete!\n")

# =============================================================================
# ANALYSIS 1 COMPLETE
# =============================================================================

cat("Analysis 1 complete! Created data for:\n")
cat("- Daily listener patterns (line charts and heatmaps)\n")
cat("- Basic show analysis (foundation for absolute listener charts)\n")
cat("- Hourly baselines (foundation for all performance calculations)\n")

if (DEBUG_TO_CONSOLE == "Y") {
  cat("\nData objects created:\n")
  cat("Main station:\n")
  cat("  - main_dow_analysis_clean (", nrow(main_dow_analysis_clean), " rows)\n")
  cat("  - main_dow_comparison_clean (", nrow(main_dow_comparison_clean), " rows)\n")
  cat("  - main_show_hourly_analysis (", nrow(main_show_hourly_analysis), " rows)\n")
  cat("  - main_show_hourly_performance (", nrow(main_show_hourly_performance), " rows)\n")
  
  if (ANALYSE_SECOND_STATION == "Y") {
    cat("Second station:\n")
    cat("  - second_show_hourly_analysis (", nrow(second_show_hourly_analysis), " rows)\n")
  }
  
  if (ANALYSE_COMPARISON_STATION == "Y") {
    cat("Comparison station:\n")
    cat("  - comparison_show_hourly_analysis (", nrow(comparison_show_hourly_analysis), " rows)\n")
  }
}

# =============================================================================
# ANALYSIS 1: MISSING DATA HANDLING
# =============================================================================
# Add this section to Analysis 1 to improve the baseline calculations

# IMPROVED: Add data quality check before baseline calculations
cat("Checking data quality for baseline calculations...\n")

# Check for shows with incomplete hour coverage
incomplete_coverage_check <- data %>%
  filter(!is.na(main_showname), main_showname != "", main_showname != "Unknown") %>%
  group_by(main_showname, hour, day_type, date) %>%
  summarise(
    sessions_in_hour = n(),
    expected_sessions = 60 / DATA_COLLECTION,  # 60 minutes / x minute intervals
    coverage_pct = (sessions_in_hour / expected_sessions) * 100,
    .groups = 'drop'
  ) %>%
  group_by(main_showname, hour, day_type) %>%
  summarise(
    episodes = n(),
    avg_coverage = mean(coverage_pct),
    min_coverage = min(coverage_pct),
    .groups = 'drop'
  ) %>%
  filter(avg_coverage < 80)  # Shows with less than 80% average coverage

if (nrow(incomplete_coverage_check) > 0 && DEBUG_TO_CONSOLE == "Y") {
  cat("Found shows with incomplete hour coverage:\n")
  print(incomplete_coverage_check %>% head(10))
}

# IMPROVED: Create robust baseline calculations that account for missing data
# Only include shows with good data coverage for baseline calculations
robust_hourly_baseline <- data %>%
  # Add episode completeness check
  group_by(date, hour, main_showname) %>%
  mutate(
    episode_sessions = n(),
    episode_coverage = (episode_sessions / 12) * 100  # 12 = expected sessions per hour
  ) %>%
  ungroup() %>%
  # Only include episodes with decent coverage for baseline
  filter(episode_coverage >= 66.7) %>%  # At least 2/3 coverage (8+ sessions out of 12)
  group_by(hour, day_type) %>%
  summarise(
    main_hour_avg = mean(main_total_listeners, na.rm = TRUE),
    episodes_used = n(),
    .groups = 'drop'
  )

# Optional: Replace the original baseline if we have enough robust data
if (nrow(robust_hourly_baseline) >= nrow(main_hourly_baseline) * 0.8) {
  cat("Using robust baseline with", nrow(robust_hourly_baseline), "data points\n")
  main_hourly_baseline <- robust_hourly_baseline
} else {
  cat("Keeping original baseline - insufficient robust data\n")
}

# IMPROVED: Add data quality flags to show performance data
if (exists("main_show_hourly_performance")) {
  main_show_hourly_performance <- main_show_hourly_performance %>%
    # Add data quality indicators
    mutate(
      sessions_flag = case_when(
        main_sessions < 5 ~ "Low Data",
        main_sessions < 10 ~ "Moderate Data", 
        TRUE ~ "Good Data"
      ),
      # Flag shows that might be affected by missing data
      coverage_concern = main_sessions < 8  # Less than 2/3 of expected sessions
    )
}

cat("Data quality checks complete\n")

# =============================================================================
# ANALYSIS 2: ABSOLUTE LISTENER TABLES
# =============================================================================
# This analysis creates ranked tables of shows by absolute listener numbers
# Uses foundation data from Analysis 1 (show_hourly_analysis objects)

cat("Running Analysis 2: Absolute Listener Tables...\n")

# =============================================================================
# PART 2A: MAIN STATION ABSOLUTE LISTENER PERFORMANCE
# =============================================================================

# Calculate average absolute listeners for each show by day type
main_absolute_performance <- main_show_hourly_analysis %>%
  group_by(main_showname, day_type) %>%
  summarise(
    main_avg_absolute_listeners = mean(main_avg_listeners, na.rm = TRUE),
    main_total_sessions = sum(main_sessions),
    .groups = 'drop'
  ) %>%
  # Add performance data from the hourly performance analysis
  left_join(
    main_show_hourly_performance %>%
      group_by(main_showname, day_type) %>%
      summarise(main_avg_performance = mean(main_pct_vs_hour, na.rm = TRUE), .groups = 'drop'),
    by = c("main_showname", "day_type")
  ) %>%
  mutate(main_avg_absolute_listeners = round(main_avg_absolute_listeners, 0)) %>%
  select(main_showname, day_type, main_avg_absolute_listeners, main_total_sessions, main_avg_performance) %>%
  arrange(day_type, desc(main_avg_absolute_listeners))

# =============================================================================
# PART 2B: SECOND STATION (IF ENABLED)
# =============================================================================

if (ANALYSE_SECOND_STATION == "Y") {
  
  second_absolute_performance <- second_show_hourly_analysis %>%
    group_by(second_showname, day_type) %>%
    summarise(
      second_avg_absolute_listeners = mean(second_avg_listeners, na.rm = TRUE),
      second_total_sessions = sum(second_sessions),
      .groups = 'drop'
    ) %>%
    left_join(
      second_show_hourly_performance %>%
        group_by(second_showname, day_type) %>%
        summarise(second_avg_performance = mean(second_pct_vs_hour, na.rm = TRUE), .groups = 'drop'),
      by = c("second_showname", "day_type")
    ) %>%
    mutate(second_avg_absolute_listeners = round(second_avg_absolute_listeners, 0)) %>%
    select(second_showname, day_type, second_avg_absolute_listeners, second_total_sessions, second_avg_performance) %>%
    arrange(day_type, desc(second_avg_absolute_listeners))
  
}

# =============================================================================
# PART 2C: COMPARISON STATION (IF ENABLED)
# =============================================================================

if (ANALYSE_COMPARISON_STATION == "Y") {
  
  comparison_absolute_performance <- comparison_show_hourly_analysis %>%
    group_by(comparison_showname, day_type) %>%
    summarise(
      comparison_avg_absolute_listeners = mean(comparison_avg_listeners, na.rm = TRUE),
      comparison_total_sessions = sum(comparison_sessions),
      .groups = 'drop'
    ) %>%
    left_join(
      comparison_show_hourly_performance %>%
        group_by(comparison_showname, day_type) %>%
        summarise(comparison_avg_performance = mean(comparison_pct_vs_hour, na.rm = TRUE), .groups = 'drop'),
      by = c("comparison_showname", "day_type")
    ) %>%
    mutate(comparison_avg_absolute_listeners = round(comparison_avg_absolute_listeners, 0)) %>%
    select(comparison_showname, day_type, comparison_avg_absolute_listeners, comparison_total_sessions, comparison_avg_performance) %>%
    arrange(day_type, desc(comparison_avg_absolute_listeners))
  
}

# =============================================================================
# PART 2D: CREATE FILTERED DATASETS FOR CHARTS
# =============================================================================

# Main station - filtered datasets for plotting
if (exists("main_absolute_performance")) {
  
  # Weekday absolute listeners (for charts)
  main_weekday_absolute <- main_absolute_performance %>%
    filter(day_type == "Weekday") %>%
    filter(!grepl(paste(EXCLUDE_TERMS, collapse = "|"), main_showname, ignore.case = TRUE)) %>%
    head(100)  # Limit for chart readability
  
  # Weekend absolute listeners (for charts)
  main_weekend_absolute <- main_absolute_performance %>%
    filter(day_type == "Weekend") %>%
    filter(!grepl(paste(EXCLUDE_TERMS, collapse = "|"), main_showname, ignore.case = TRUE)) %>%
    head(100)  # Limit for chart readability
  
}

# Second station - filtered datasets (if enabled)
if (ANALYSE_SECOND_STATION == "Y" && exists("second_absolute_performance")) {
  
  second_weekday_absolute <- second_absolute_performance %>%
    filter(day_type == "Weekday") %>%
    filter(!grepl(paste(EXCLUDE_TERMS, collapse = "|"), second_showname, ignore.case = TRUE)) %>%
    head(100)
  
  second_weekend_absolute <- second_absolute_performance %>%
    filter(day_type == "Weekend") %>%
    filter(!grepl(paste(EXCLUDE_TERMS, collapse = "|"), second_showname, ignore.case = TRUE)) %>%
    head(100)
  
}

# Comparison station - filtered datasets (if enabled)
if (ANALYSE_COMPARISON_STATION == "Y" && exists("comparison_absolute_performance")) {
  
  comparison_weekday_absolute <- comparison_absolute_performance %>%
    filter(day_type == "Weekday") %>%
    filter(!grepl(paste(EXCLUDE_TERMS, collapse = "|"), comparison_showname, ignore.case = TRUE)) %>%
    head(100)
  
  comparison_weekend_absolute <- comparison_absolute_performance %>%
    filter(day_type == "Weekend") %>%
    filter(!grepl(paste(EXCLUDE_TERMS, collapse = "|"), comparison_showname, ignore.case = TRUE)) %>%
    head(100)
  
}

# =============================================================================
# ANALYSIS 2 COMPLETE
# =============================================================================

cat("Analysis 2 complete! Created absolute listener ranking tables:\n")

if (DEBUG_TO_CONSOLE == "Y") {
  cat("Main station:\n")
  if (exists("main_absolute_performance")) {
    cat("  - main_absolute_performance (", nrow(main_absolute_performance), " shows)\n")
    cat("  - main_weekday_absolute (", ifelse(exists("main_weekday_absolute"), nrow(main_weekday_absolute), 0), " shows)\n")
    cat("  - main_weekend_absolute (", ifelse(exists("main_weekend_absolute"), nrow(main_weekend_absolute), 0), " shows)\n")
  }
  
  if (ANALYSE_SECOND_STATION == "Y") {
    cat("Second station:\n")
    if (exists("second_absolute_performance")) {
      cat("  - second_absolute_performance (", nrow(second_absolute_performance), " shows)\n")
    }
  }
  
  if (ANALYSE_COMPARISON_STATION == "Y") {
    cat("Comparison station:\n") 
    if (exists("comparison_absolute_performance")) {
      cat("  - comparison_absolute_performance (", nrow(comparison_absolute_performance), " shows)\n")
    }
  }
  
  # Show top 5 weekend shows as example
  if (exists("main_weekend_absolute") && nrow(main_weekend_absolute) > 0) {
    cat("\nTop 5 weekend shows by absolute listeners:\n")
    top_shows <- main_weekend_absolute %>% head(5)
    for (i in 1:nrow(top_shows)) {
      cat("  ", i, ". ", top_shows$main_showname[i], " (", top_shows$main_avg_absolute_listeners[i], " listeners)\n")
    }
  }
}


# =============================================================================
# ANALYSIS 3: DJ/SHOW PERFORMANCE
# =============================================================================
# This analysis creates show summaries and performance rankings
# Uses foundation data from Analysis 1 (show_hourly_performance objects)
# EXCLUDES consistency analysis and retention analysis (those are separate)

cat("Running Analysis 3: DJ/Show Performance...\n")

# =============================================================================
# PART 3A: MAIN STATION SHOW SUMMARIES
# =============================================================================

# Create show summaries with safe aggregation
main_show_summary <- main_show_hourly_performance %>%
  group_by(main_showname, main_stand_in, day_type) %>%
  summarise(
    main_avg_performance = mean(main_pct_vs_hour, na.rm = TRUE),
    main_total_sessions = sum(main_sessions),
    main_hours_worked = n(),
    # Safe best hour calculation
    main_best_hour = if(any(!is.na(main_pct_vs_hour) & is.finite(main_pct_vs_hour))) {
      hour[which.max(main_pct_vs_hour)][1]  # [1] ensures single value
    } else {
      NA_integer_
    },
    # Safe best hour performance calculation
    main_best_hour_performance = if(any(!is.na(main_pct_vs_hour) & is.finite(main_pct_vs_hour))) {
      max(main_pct_vs_hour, na.rm = TRUE)
    } else {
      NA_real_
    },
    # Safe worst hour calculation
    main_worst_hour = if(any(!is.na(main_pct_vs_hour) & is.finite(main_pct_vs_hour))) {
      hour[which.min(main_pct_vs_hour)][1]  # [1] ensures single value
    } else {
      NA_integer_
    },
    # Safe worst hour performance calculation
    main_worst_hour_performance = if(any(!is.na(main_pct_vs_hour) & is.finite(main_pct_vs_hour))) {
      min(main_pct_vs_hour, na.rm = TRUE)
    } else {
      NA_real_
    },
    .groups = 'drop'
  ) %>%
  filter(main_total_sessions >= 10) %>%  # Minimum sessions for reliable analysis
  arrange(day_type, desc(main_avg_performance))

# =============================================================================
# PART 3B: CREATE PERFORMANCE RANKING TABLES
# =============================================================================

# Best performing weekday shows (for summary tables)
main_best_weekday_shows <- main_show_summary %>%
  filter(day_type == "Weekday") %>%
  filter(!grepl(paste(EXCLUDE_TERMS, collapse = "|"), main_showname, ignore.case = TRUE)) %>%
  filter(main_stand_in != 1) %>%
  arrange(desc(main_avg_performance)) %>%
  head(10) %>%
  mutate(
    main_avg_performance = round(main_avg_performance, 1),
    main_airtime_hours = round(main_total_sessions / HOUR_NORMALISATION, 0)
  ) %>%
  select(main_showname, main_avg_performance, main_airtime_hours)

# Best performing weekend shows (for summary tables)
main_best_weekend_shows <- main_show_summary %>%
  filter(day_type == "Weekend") %>%
  filter(!grepl(paste(EXCLUDE_TERMS, collapse = "|"), main_showname, ignore.case = TRUE)) %>%
  filter(main_stand_in != 1) %>%
  arrange(desc(main_avg_performance)) %>%
  head(10) %>%
  mutate(
    main_avg_performance = round(main_avg_performance, 1),
    main_airtime_hours = round(main_total_sessions / HOUR_NORMALISATION, 0)
  ) %>%
  select(main_showname, main_avg_performance, main_airtime_hours)

# All shows performance (for detailed charts)
main_all_weekday_shows <- main_show_summary %>%
  filter(day_type == "Weekday") %>%
  filter(!grepl(paste(EXCLUDE_TERMS, collapse = "|"), main_showname, ignore.case = TRUE)) %>%
  filter(main_stand_in != 1) %>%
  arrange(desc(main_avg_performance))

main_all_weekend_shows <- main_show_summary %>%
  filter(day_type == "Weekend") %>%
  filter(!grepl(paste(EXCLUDE_TERMS, collapse = "|"), main_showname, ignore.case = TRUE)) %>%
  filter(main_stand_in != 1) %>%
  arrange(desc(main_avg_performance))


# =============================================================================
# PART 3C: DJ PERFORMANCE ANALYSIS (Z-SCORE BASED)
# =============================================================================

# Calculate hourly baseline statistics (mean and standard deviation)
main_hourly_baseline_stats <- data %>%
  group_by(hour, day_type) %>%
  summarise(
    main_hour_mean = mean(main_total_listeners, na.rm = TRUE),
    main_hour_sd = sd(main_total_listeners, na.rm = TRUE),
    main_hour_n = n(),
    .groups = 'drop'
  ) %>%
  # Filter out hours with insufficient data or zero variance
  filter(main_hour_n >= 10, main_hour_sd > 0)

if (exists("main_hourly_baseline_stats") && nrow(main_hourly_baseline_stats) > 0) {
  
  cat("Running z-score based DJ performance analysis for main station...\n")
  
  # Calculate z-scores for DJ performance
  main_dj_performance_zscore <- data %>%
    filter(!is.na(main_presenter), main_presenter != "", main_presenter != "Unknown",
           !is.na(main_showname), main_showname != "",
           main_stand_in != 1) %>%  # Exclude sitting-in DJs
    filter(!grepl(paste(EXCLUDE_TERMS, collapse = "|"), main_showname, ignore.case = TRUE)) %>%
    # Join with baseline statistics
    left_join(main_hourly_baseline_stats, by = c("hour", "day_type")) %>%
    # Only include observations where we have baseline stats
    filter(!is.na(main_hour_mean), !is.na(main_hour_sd), main_hour_sd > 0) %>%
    # Calculate z-score for each observation
    mutate(
      main_listener_zscore = (main_total_listeners - main_hour_mean) / main_hour_sd
    ) %>%
    # Group by DJ and calculate performance metrics
    group_by(main_presenter) %>%
    summarise(
      main_sessions = n(),
      main_avg_zscore_performance = mean(main_listener_zscore, na.rm = TRUE),
      main_zscore_consistency = sd(main_listener_zscore, na.rm = TRUE),
      main_avg_listeners = mean(main_total_listeners, na.rm = TRUE),
      main_shows_presented = round(main_sessions / HOUR_NORMALISATION, 0),
      .groups = 'drop'
    ) %>%
    # Filter for DJs with sufficient data
    filter(main_sessions >= 12) %>%  # At least 12 sessions (2+ hours of content)
    # Round for display
    mutate(
      main_avg_zscore_performance = round(main_avg_zscore_performance, 2),
      main_zscore_consistency = round(main_zscore_consistency, 2),
      main_avg_listeners = round(main_avg_listeners, 0)
    ) %>%
    arrange(desc(main_avg_zscore_performance))
  
  if (nrow(main_dj_performance_zscore) > 0) {
    
    # Top performing DJs
    main_top_djs_zscore <- main_dj_performance_zscore %>%
      filter(main_avg_zscore_performance > 0) %>%
      head(15)
    
    # Underperforming DJs
    main_bottom_djs_zscore <- main_dj_performance_zscore %>%
      filter(main_avg_zscore_performance < 0) %>%
      tail(10) %>%
      arrange(main_avg_zscore_performance)
    
    cat("✓ Z-score DJ performance analysis completed\n")
    cat("  - DJs analyzed:", nrow(main_dj_performance_zscore), "\n")
    cat("  - Top performers:", nrow(main_top_djs_zscore), "\n")
    
  } else {
    main_top_djs_zscore <- data.frame()
    main_bottom_djs_zscore <- data.frame()
  }
  
} else {
  main_dj_performance_zscore <- data.frame()
  main_top_djs_zscore <- data.frame()
  main_bottom_djs_zscore <- data.frame()
}

# =============================================================================
# PART 3D: SHOW PERFORMANCE ANALYSIS (Z-SCORE BASED)
# =============================================================================

if (exists("main_hourly_baseline_stats") && nrow(main_hourly_baseline_stats) > 0) {
  
  cat("Running z-score based show performance analysis for main station...\n")
  
  # Calculate z-scores for show performance
  main_show_performance_zscore <- data %>%
    filter(!is.na(main_showname), main_showname != "", main_showname != "Unknown",
           main_stand_in != 1) %>%  # Exclude sitting-in shows
    filter(!grepl(paste(EXCLUDE_TERMS, collapse = "|"), main_showname, ignore.case = TRUE)) %>%
    # Join with baseline statistics
    left_join(main_hourly_baseline_stats, by = c("hour", "day_type")) %>%
    # Only include observations where we have baseline stats
    filter(!is.na(main_hour_mean), !is.na(main_hour_sd), main_hour_sd > 0) %>%
    # Calculate z-score for each observation
    mutate(
      main_listener_zscore = (main_total_listeners - main_hour_mean) / main_hour_sd
    ) %>%
    # Group by show and day type for fair comparison
    group_by(main_showname, day_type) %>%
    summarise(
      main_sessions = n(),
      main_avg_zscore_performance = mean(main_listener_zscore, na.rm = TRUE),
      main_zscore_consistency = sd(main_listener_zscore, na.rm = TRUE),
      main_avg_listeners = mean(main_total_listeners, na.rm = TRUE),
      main_airtime_hours = round(main_sessions / HOUR_NORMALISATION, 0),
      .groups = 'drop'
    ) %>%
    # Filter for shows with sufficient data
    filter(main_sessions >= 6) %>%  # At least 6 sessions (1+ hour of content)
    # Round for display
    mutate(
      main_avg_zscore_performance = round(main_avg_zscore_performance, 2),
      main_zscore_consistency = round(main_zscore_consistency, 2),
      main_avg_listeners = round(main_avg_listeners, 0)
    ) %>%
    arrange(desc(main_avg_zscore_performance))
  
  if (nrow(main_show_performance_zscore) > 0) {
    
    # Top performing shows
    main_top_shows_zscore <- main_show_performance_zscore %>%
      filter(main_avg_zscore_performance > 0) %>%
      head(15)
    
    # Underperforming shows
    main_bottom_shows_zscore <- main_show_performance_zscore %>%
      filter(main_avg_zscore_performance < 0) %>%
      tail(10) %>%
      arrange(main_avg_zscore_performance)
    
    cat("✓ Z-score show performance analysis completed\n")
    cat("  - Shows analyzed:", nrow(main_show_performance_zscore), "\n")
    cat("  - Top performers:", nrow(main_top_shows_zscore), "\n")
    
  } else {
    main_top_shows_zscore <- data.frame()
    main_bottom_shows_zscore <- data.frame()
  }
  
} else {
  main_show_performance_zscore <- data.frame()
  main_top_shows_zscore <- data.frame()
  main_bottom_shows_zscore <- data.frame()
}

# =============================================================================
# PART 3E: WEEKDAY AND WEEKEND HEATMAPS (Z-SCORE BASED)
# =============================================================================

if (exists("main_hourly_baseline_stats") && nrow(main_hourly_baseline_stats) > 0) {
  
  cat("Creating z-score based weekday and weekend heatmaps for main station...\n")
  
  # Calculate z-scores for all shows by hour and day type
  main_show_heatmap_zscore <- data %>%
    filter(!is.na(main_showname), main_showname != "", main_showname != "Unknown",
           main_stand_in != 1) %>%  # Exclude sitting-in shows
    filter(!grepl(paste(EXCLUDE_TERMS, collapse = "|"), main_showname, ignore.case = TRUE)) %>%
    # Join with baseline statistics
    left_join(main_hourly_baseline_stats, by = c("hour", "day_type")) %>%
    # Only include observations where we have baseline stats
    filter(!is.na(main_hour_mean), !is.na(main_hour_sd), main_hour_sd > 0) %>%
    # Calculate z-score for each observation
    mutate(
      main_listener_zscore = (main_total_listeners - main_hour_mean) / main_hour_sd
    ) %>%
    # Group by show, hour, and day type
    group_by(hour, main_showname, day_type) %>%
    summarise(
      main_sessions = n(),
      main_avg_zscore_performance = mean(main_listener_zscore, na.rm = TRUE),
      main_avg_listeners = mean(main_total_listeners, na.rm = TRUE),
      .groups = 'drop'
    ) %>%
    # Arrange by hour descending:
    arrange(desc(hour)) %>%
    # Filter for combinations with sufficient data
    filter(main_sessions >= 3) %>%
    # Round for display
    mutate(main_avg_zscore_performance = round(main_avg_zscore_performance, 2)) %>%
    # Ensure reasonable hour range
    filter(hour >= 0, hour <= 24)
  
  # Create separate datasets for weekday and weekend
  main_weekday_heatmap_zscore <- main_show_heatmap_zscore %>%
    filter(day_type == "Weekday")
  
  main_weekend_heatmap_zscore <- main_show_heatmap_zscore %>%
    filter(day_type == "Weekend")
  
  if (nrow(main_weekday_heatmap_zscore) > 0) {
    cat("✓ Weekday heatmap data created:", nrow(main_weekday_heatmap_zscore), "show-hour combinations\n")
  }
  
  if (nrow(main_weekend_heatmap_zscore) > 0) {
    cat("✓ Weekend heatmap data created:", nrow(main_weekend_heatmap_zscore), "show-hour combinations\n")
  }
  
} else {
  main_weekday_heatmap_zscore <- data.frame()
  main_weekend_heatmap_zscore <- data.frame()
}

# =============================================================================
# PART 3F: SECOND STATION SHOW SUMMARIES (IF ENABLED)
# =============================================================================

if (ANALYSE_SECOND_STATION == "Y") {
  
  # Create show summaries with safe aggregation
  second_show_summary <- second_show_hourly_performance %>%
    group_by(second_showname, second_stand_in, day_type) %>%
    summarise(
      second_avg_performance = mean(second_pct_vs_hour, na.rm = TRUE),
      second_total_sessions = sum(second_sessions),
      second_hours_worked = n(),
      # Safe best hour calculation
      second_best_hour = if(any(!is.na(second_pct_vs_hour) & is.finite(second_pct_vs_hour))) {
        hour[which.max(second_pct_vs_hour)][1]  # [1] ensures single value
      } else {
        NA_integer_
      },
      # Safe best hour performance calculation
      second_best_hour_performance = if(any(!is.na(second_pct_vs_hour) & is.finite(second_pct_vs_hour))) {
        max(second_pct_vs_hour, na.rm = TRUE)
      } else {
        NA_real_
      },
      # Safe worst hour calculation
      second_worst_hour = if(any(!is.na(second_pct_vs_hour) & is.finite(second_pct_vs_hour))) {
        hour[which.min(second_pct_vs_hour)][1]  # [1] ensures single value
      } else {
        NA_integer_
      },
      # Safe worst hour performance calculation
      second_worst_hour_performance = if(any(!is.na(second_pct_vs_hour) & is.finite(second_pct_vs_hour))) {
        min(second_pct_vs_hour, na.rm = TRUE)
      } else {
        NA_real_
      },
      .groups = 'drop'
    ) %>%
    filter(second_total_sessions >= 10) %>%  # Minimum sessions for reliable analysis
    arrange(day_type, desc(second_avg_performance))
  
  # =============================================================================
  # PART 3G: SECOND STATION: CREATE PERFORMANCE RANKING TABLES (IF ENABLED)
  # =============================================================================

  # Best performing weekday shows (for summary tables)
  second_best_weekday_shows <- second_show_summary %>%
    filter(day_type == "Weekday") %>%
    filter(!grepl(paste(EXCLUDE_TERMS, collapse = "|"), second_showname, ignore.case = TRUE)) %>%
    filter(second_stand_in != 1) %>%
    arrange(desc(second_avg_performance)) %>%
    head(10) %>%
    mutate(
      second_avg_performance = round(second_avg_performance, 1),
      second_airtime_hours = round(second_total_sessions / HOUR_NORMALISATION, 0)
    ) %>%
    select(second_showname, second_avg_performance, second_airtime_hours)
  
  # Best performing weekend shows (for summary tables)
  second_best_weekend_shows <- second_show_summary %>%
    filter(day_type == "Weekend") %>%
    filter(!grepl(paste(EXCLUDE_TERMS, collapse = "|"), second_showname, ignore.case = TRUE)) %>%
    filter(second_stand_in != 1) %>%
    arrange(desc(second_avg_performance)) %>%
    head(10) %>%
    mutate(
      second_avg_performance = round(second_avg_performance, 1),
      second_airtime_hours = round(second_total_sessions / HOUR_NORMALISATION, 0)
    ) %>%
    select(second_showname, second_avg_performance, second_airtime_hours)
  
  # All shows performance (for detailed charts)
  second_all_weekday_shows <- second_show_summary %>%
    filter(day_type == "Weekday") %>%
    filter(!grepl(paste(EXCLUDE_TERMS, collapse = "|"), second_showname, ignore.case = TRUE)) %>%
    filter(second_stand_in != 1) %>%
    arrange(desc(second_avg_performance))
  
  second_all_weekend_shows <- second_show_summary %>%
    filter(day_type == "Weekend") %>%
    filter(!grepl(paste(EXCLUDE_TERMS, collapse = "|"), second_showname, ignore.case = TRUE)) %>%
    filter(second_stand_in != 1) %>%
    arrange(desc(second_avg_performance))

  # =============================================================================
  # PART 3H: SECOND STAION DJ PERFORMANCE ANALYSIS (Z-SCORE BASED) (If ENABLED)
  # =============================================================================
  
  # Calculate hourly baseline statistics (mean and standard deviation)
  second_hourly_baseline_stats <- data %>%
    group_by(hour, day_type) %>%
    summarise(
      second_hour_mean = mean(second_total_listeners, na.rm = TRUE),
      second_hour_sd = sd(second_total_listeners, na.rm = TRUE),
      second_hour_n = n(),
      .groups = 'drop'
    ) %>%
    # Filter out hours with insufficient data or zero variance
    filter(second_hour_n >= 10, second_hour_sd > 0)
  
  if (exists("second_hourly_baseline_stats") && nrow(second_hourly_baseline_stats) > 0) {
    
    cat("Running z-score based DJ performance analysis for second station...\n")
    
    # Calculate z-scores for DJ performance
    second_dj_performance_zscore <- data %>%
      filter(!is.na(second_presenter), second_presenter != "", second_presenter != "Unknown",
             !is.na(second_showname), second_showname != "",
             second_stand_in != 1) %>%  # Exclude sitting-in DJs
      filter(!grepl(paste(EXCLUDE_TERMS, collapse = "|"), second_showname, ignore.case = TRUE)) %>%
      # Join with baseline statistics
      left_join(second_hourly_baseline_stats, by = c("hour", "day_type")) %>%
      # Only include observations where we have baseline stats
      filter(!is.na(second_hour_mean), !is.na(second_hour_sd), second_hour_sd > 0) %>%
      # Calculate z-score for each observation
      mutate(
        second_listener_zscore = (second_total_listeners - second_hour_mean) / second_hour_sd
      ) %>%
      # Group by DJ and calculate performance metrics
      group_by(second_presenter) %>%
      summarise(
        second_sessions = n(),
        second_avg_zscore_performance = mean(second_listener_zscore, na.rm = TRUE),
        second_zscore_consistency = sd(second_listener_zscore, na.rm = TRUE),
        second_avg_listeners = mean(second_total_listeners, na.rm = TRUE),
        second_shows_presented = round(second_sessions / HOUR_NORMALISATION, 0),
        .groups = 'drop'
      ) %>%
      # Filter for DJs with sufficient data
      filter(second_sessions >= 12) %>%  # At least 12 sessions (2+ hours of content)
      # Round for display
      mutate(
        second_avg_zscore_performance = round(second_avg_zscore_performance, 2),
        second_zscore_consistency = round(second_zscore_consistency, 2),
        second_avg_listeners = round(second_avg_listeners, 0)
      ) %>%
      arrange(desc(second_avg_zscore_performance))
    
    if (nrow(second_dj_performance_zscore) > 0) {
      
      # Top performing DJs
      second_top_djs_zscore <- second_dj_performance_zscore %>%
        filter(second_avg_zscore_performance > 0) %>%
        head(15)
      
      # Underperforming DJs
      second_bottom_djs_zscore <- second_dj_performance_zscore %>%
        filter(second_avg_zscore_performance < 0) %>%
        tail(10) %>%
        arrange(second_avg_zscore_performance)
      
      cat("✓ Z-score DJ performance analysis completed\n")
      cat("  - DJs analyzed:", nrow(second_dj_performance_zscore), "\n")
      cat("  - Top performers:", nrow(second_top_djs_zscore), "\n")
      
    } else {
      second_top_djs_zscore <- data.frame()
      second_bottom_djs_zscore <- data.frame()
    }
    
  } else {
    second_dj_performance_zscore <- data.frame()
    second_top_djs_zscore <- data.frame()
    second_bottom_djs_zscore <- data.frame()
  }
  
  # =============================================================================
  # PART 3I: SECOND STATION SHOW PERFORMANCE ANALYSIS (Z-SCORE BASED) (IF ENABLED)
  # =============================================================================
  
  if (exists("second_hourly_baseline_stats") && nrow(second_hourly_baseline_stats) > 0) {
    
    cat("Running z-score based show performance analysis for second station...\n")
    
    # Calculate z-scores for show performance
    second_show_performance_zscore <- data %>%
      filter(!is.na(second_showname), second_showname != "", second_showname != "Unknown",
             second_stand_in != 1) %>%  # Exclude sitting-in shows
      filter(!grepl(paste(EXCLUDE_TERMS, collapse = "|"), second_showname, ignore.case = TRUE)) %>%
      # Join with baseline statistics
      left_join(second_hourly_baseline_stats, by = c("hour", "day_type")) %>%
      # Only include observations where we have baseline stats
      filter(!is.na(second_hour_mean), !is.na(second_hour_sd), second_hour_sd > 0) %>%
      # Calculate z-score for each observation
      mutate(
        second_listener_zscore = (second_total_listeners - second_hour_mean) / second_hour_sd
      ) %>%
      # Group by show and day type for fair comparison
      group_by(second_showname, day_type) %>%
      summarise(
        second_sessions = n(),
        second_avg_zscore_performance = mean(second_listener_zscore, na.rm = TRUE),
        second_zscore_consistency = sd(second_listener_zscore, na.rm = TRUE),
        second_avg_listeners = mean(second_total_listeners, na.rm = TRUE),
        second_airtime_hours = round(second_sessions / HOUR_NORMALISATION, 0),
        .groups = 'drop'
      ) %>%
      # Filter for shows with sufficient data
      filter(second_sessions >= 6) %>%  # At least 6 sessions (1+ hour of content)
      # Round for display
      mutate(
        second_avg_zscore_performance = round(second_avg_zscore_performance, 2),
        second_zscore_consistency = round(second_zscore_consistency, 2),
        second_avg_listeners = round(second_avg_listeners, 0)
      ) %>%
      arrange(desc(second_avg_zscore_performance))
    
    if (nrow(second_show_performance_zscore) > 0) {
      
      # Top performing shows
      second_top_shows_zscore <- second_show_performance_zscore %>%
        filter(second_avg_zscore_performance > 0) %>%
        head(15)
      
      # Underperforming shows
      second_bottom_shows_zscore <- second_show_performance_zscore %>%
        filter(second_avg_zscore_performance < 0) %>%
        tail(10) %>%
        arrange(second_avg_zscore_performance)
      
      cat("✓ Z-score show performance analysis completed\n")
      cat("  - Shows analyzed:", nrow(second_show_performance_zscore), "\n")
      cat("  - Top performers:", nrow(second_top_shows_zscore), "\n")
      
    } else {
      second_top_shows_zscore <- data.frame()
      second_bottom_shows_zscore <- data.frame()
    }
    
  } else {
    second_show_performance_zscore <- data.frame()
    second_top_shows_zscore <- data.frame()
    second_bottom_shows_zscore <- data.frame()
  }
  
  # =============================================================================
  # PART 3J: SECOND STATION WEEKDAY AND WEEKEND HEATMAPS (Z-SCORE BASED) (IF ENABLED)
  # =============================================================================
  
  if (exists("second_hourly_baseline_stats") && nrow(second_hourly_baseline_stats) > 0) {
    
    cat("Creating z-score based weekday and weekend heatmaps for second station...\n")
    
    # Calculate z-scores for all shows by hour and day type
    second_show_heatmap_zscore <- data %>%
      filter(!is.na(second_showname), second_showname != "", second_showname != "Unknown",
             second_stand_in != 1) %>%  # Exclude sitting-in shows
      filter(!grepl(paste(EXCLUDE_TERMS, collapse = "|"), second_showname, ignore.case = TRUE)) %>%
      # Join with baseline statistics
      left_join(second_hourly_baseline_stats, by = c("hour", "day_type")) %>%
      # Only include observations where we have baseline stats
      filter(!is.na(second_hour_mean), !is.na(second_hour_sd), second_hour_sd > 0) %>%
      # Calculate z-score for each observation
      mutate(
        second_listener_zscore = (second_total_listeners - second_hour_mean) / second_hour_sd
      ) %>%
      # Group by show, hour, and day type
      group_by(hour, second_showname, day_type) %>%
      summarise(
        second_sessions = n(),
        second_avg_zscore_performance = mean(second_listener_zscore, na.rm = TRUE),
        second_avg_listeners = mean(second_total_listeners, na.rm = TRUE),
        .groups = 'drop'
      ) %>%
      # Arrange by hour descending:
      arrange(desc(hour)) %>%
      # Filter for combinations with sufficient data
      filter(second_sessions >= 3) %>%
      # Round for display
      mutate(second_avg_zscore_performance = round(second_avg_zscore_performance, 2)) %>%
      # Ensure reasonable hour range
      filter(hour >= 0, hour <= 24)
    
    # Create separate datasets for weekday and weekend
    second_weekday_heatmap_zscore <- second_show_heatmap_zscore %>%
      filter(day_type == "Weekday")
    
    second_weekend_heatmap_zscore <- second_show_heatmap_zscore %>%
      filter(day_type == "Weekend")
    
    if (nrow(second_weekday_heatmap_zscore) > 0) {
      cat("✓ Weekday heatmap data created:", nrow(second_weekday_heatmap_zscore), "show-hour combinations\n")
    }
    
    if (nrow(second_weekend_heatmap_zscore) > 0) {
      cat("✓ Weekend heatmap data created:", nrow(second_weekend_heatmap_zscore), "show-hour combinations\n")
    }
    
  } else {
    second_weekday_heatmap_zscore <- data.frame()
    second_weekend_heatmap_zscore <- data.frame()
  }
  
}

# =============================================================================
# PART 3K: COMPARISON STATION SHOW SUMMARIES (IF ENABLED)
# =============================================================================

if (ANALYSE_COMPARISON_STATION == "Y") {
  
  # Comparison station show summaries
  comparison_show_summary <- comparison_show_hourly_performance %>%
    group_by(comparison_showname, comparison_stand_in, day_type) %>%
    summarise(
      comparison_avg_performance = mean(comparison_pct_vs_hour, na.rm = TRUE),
      comparison_total_sessions = sum(comparison_sessions),
      comparison_hours_worked = n(),
      comparison_best_hour = if(any(!is.na(comparison_pct_vs_hour) & is.finite(comparison_pct_vs_hour))) {
        hour[which.max(comparison_pct_vs_hour)][1]
      } else {
        NA_integer_
      },
      comparison_best_hour_performance = if(any(!is.na(comparison_pct_vs_hour) & is.finite(comparison_pct_vs_hour))) {
        max(comparison_pct_vs_hour, na.rm = TRUE)
      } else {
        NA_real_
      },
      comparison_worst_hour = if(any(!is.na(comparison_pct_vs_hour) & is.finite(comparison_pct_vs_hour))) {
        hour[which.min(comparison_pct_vs_hour)][1]
      } else {
        NA_integer_
      },
      comparison_worst_hour_performance = if(any(!is.na(comparison_pct_vs_hour) & is.finite(comparison_pct_vs_hour))) {
        min(comparison_pct_vs_hour, na.rm = TRUE)
      } else {
        NA_real_
      },
      .groups = 'drop'
    ) %>%
    filter(comparison_total_sessions >= 10) %>%
    arrange(day_type, desc(comparison_avg_performance))
  
  # =============================================================================
  # PART 3L: COMPARISON STATION: CREATE PERFORMANCE RANKING TABLES (IF ENABLED)
  # =============================================================================
  
  # Comparison station performance tables
  comparison_best_weekday_shows <- comparison_show_summary %>%
    filter(day_type == "Weekday") %>%
    filter(!grepl(paste(EXCLUDE_TERMS, collapse = "|"), comparison_showname, ignore.case = TRUE)) %>%
    filter(comparison_stand_in != 1) %>%
    arrange(desc(comparison_avg_performance)) %>%
    head(10) %>%
    mutate(
      comparison_avg_performance = round(comparison_avg_performance, 1),
      comparison_airtime_hours = round(comparison_total_sessions / HOUR_NORMALISATION, 0)
    ) %>%
    select(comparison_showname, comparison_avg_performance, comparison_airtime_hours)
  
  comparison_best_weekend_shows <- comparison_show_summary %>%
    filter(day_type == "Weekend") %>%
    filter(!grepl(paste(EXCLUDE_TERMS, collapse = "|"), comparison_showname, ignore.case = TRUE)) %>%
    filter(comparison_stand_in != 1) %>%
    arrange(desc(comparison_avg_performance)) %>%
    head(10) %>%
    mutate(
      comparison_avg_performance = round(comparison_avg_performance, 1),
      comparison_airtime_hours = round(comparison_total_sessions / HOUR_NORMALISATION, 0)
    ) %>%
    select(comparison_showname, comparison_avg_performance, comparison_airtime_hours)
  
  # =============================================================================
  # PART 3M: SECOND STAION DJ PERFORMANCE ANALYSIS (Z-SCORE BASED) (If ENABLED)
  # =============================================================================
  
  # Calculate hourly baseline statistics (mean and standard deviation)
  comparison_hourly_baseline_stats <- data %>%
    group_by(hour, day_type) %>%
    summarise(
      comparison_hour_mean = mean(comparison_total_listeners, na.rm = TRUE),
      comparison_hour_sd = sd(comparison_total_listeners, na.rm = TRUE),
      comparison_hour_n = n(),
      .groups = 'drop'
    ) %>%
    # Filter out hours with insufficient data or zero variance
    filter(comparison_hour_n >= 10, comparison_hour_sd > 0)
  
  if (exists("comparison_hourly_baseline_stats") && nrow(comparison_hourly_baseline_stats) > 0) {
    
    cat("Running z-score based DJ performance analysis for comparison station...\n")
    
    # Calculate z-scores for DJ performance
    comparison_dj_performance_zscore <- data %>%
      filter(!is.na(comparison_presenter), comparison_presenter != "", comparison_presenter != "Unknown",
             !is.na(comparison_showname), comparison_showname != "",
             comparison_stand_in != 1) %>%  # Exclude sitting-in DJs
      filter(!grepl(paste(EXCLUDE_TERMS, collapse = "|"), comparison_showname, ignore.case = TRUE)) %>%
      # Join with baseline statistics
      left_join(comparison_hourly_baseline_stats, by = c("hour", "day_type")) %>%
      # Only include observations where we have baseline stats
      filter(!is.na(comparison_hour_mean), !is.na(comparison_hour_sd), comparison_hour_sd > 0) %>%
      # Calculate z-score for each observation
      mutate(
        comparison_listener_zscore = (comparison_total_listeners - comparison_hour_mean) / comparison_hour_sd
      ) %>%
      # Group by DJ and calculate performance metrics
      group_by(comparison_presenter) %>%
      summarise(
        comparison_sessions = n(),
        comparison_avg_zscore_performance = mean(comparison_listener_zscore, na.rm = TRUE),
        comparison_zscore_consistency = sd(comparison_listener_zscore, na.rm = TRUE),
        comparison_avg_listeners = mean(comparison_total_listeners, na.rm = TRUE),
        comparison_shows_presented = round(comparison_sessions / HOUR_NORMALISATION, 0),
        .groups = 'drop'
      ) %>%
      # Filter for DJs with sufficient data
      filter(comparison_sessions >= 12) %>%  # At least 12 sessions (2+ hours of content)
      # Round for display
      mutate(
        comparison_avg_zscore_performance = round(comparison_avg_zscore_performance, 2),
        comparison_zscore_consistency = round(comparison_zscore_consistency, 2),
        comparison_avg_listeners = round(comparison_avg_listeners, 0)
      ) %>%
      arrange(desc(comparison_avg_zscore_performance))
    
    if (nrow(comparison_dj_performance_zscore) > 0) {
      
      # Top performing DJs
      comparison_top_djs_zscore <- comparison_dj_performance_zscore %>%
        filter(comparison_avg_zscore_performance > 0) %>%
        head(15)
      
      # Underperforming DJs
      comparison_bottom_djs_zscore <- comparison_dj_performance_zscore %>%
        filter(comparison_avg_zscore_performance < 0) %>%
        tail(10) %>%
        arrange(comparison_avg_zscore_performance)
      
      cat("✓ Z-score DJ performance analysis completed\n")
      cat("  - DJs analyzed:", nrow(comparison_dj_performance_zscore), "\n")
      cat("  - Top performers:", nrow(comparison_top_djs_zscore), "\n")
      
    } else {
      comparison_top_djs_zscore <- data.frame()
      comparison_bottom_djs_zscore <- data.frame()
    }
    
  } else {
    comparison_dj_performance_zscore <- data.frame()
    comparison_top_djs_zscore <- data.frame()
    comparison_bottom_djs_zscore <- data.frame()
  }
  
  # =============================================================================
  # PART 3N: COMPARISON STATION SHOW PERFORMANCE ANALYSIS (Z-SCORE BASED) (IF ENABLED)
  # =============================================================================
  
  if (exists("comparison_hourly_baseline_stats") && nrow(comparison_hourly_baseline_stats) > 0) {
    
    cat("Running z-score based show performance analysis for comparison station...\n")
    
    # Calculate z-scores for show performance
    comparison_show_performance_zscore <- data %>%
      filter(!is.na(comparison_showname), comparison_showname != "", comparison_showname != "Unknown",
             comparison_stand_in != 1) %>%  # Exclude sitting-in shows
      filter(!grepl(paste(EXCLUDE_TERMS, collapse = "|"), comparison_showname, ignore.case = TRUE)) %>%
      # Join with baseline statistics
      left_join(comparison_hourly_baseline_stats, by = c("hour", "day_type")) %>%
      # Only include observations where we have baseline stats
      filter(!is.na(comparison_hour_mean), !is.na(comparison_hour_sd), comparison_hour_sd > 0) %>%
      # Calculate z-score for each observation
      mutate(
        comparison_listener_zscore = (comparison_total_listeners - comparison_hour_mean) / comparison_hour_sd
      ) %>%
      # Group by show and day type for fair comparison
      group_by(comparison_showname, day_type) %>%
      summarise(
        comparison_sessions = n(),
        comparison_avg_zscore_performance = mean(comparison_listener_zscore, na.rm = TRUE),
        comparison_zscore_consistency = sd(comparison_listener_zscore, na.rm = TRUE),
        comparison_avg_listeners = mean(comparison_total_listeners, na.rm = TRUE),
        comparison_airtime_hours = round(comparison_sessions / HOUR_NORMALISATION, 0),
        .groups = 'drop'
      ) %>%
      # Filter for shows with sufficient data
      filter(comparison_sessions >= 6) %>%  # At least 6 sessions (1+ hour of content)
      # Round for display
      mutate(
        comparison_avg_zscore_performance = round(comparison_avg_zscore_performance, 2),
        comparison_zscore_consistency = round(comparison_zscore_consistency, 2),
        comparison_avg_listeners = round(comparison_avg_listeners, 0)
      ) %>%
      arrange(desc(comparison_avg_zscore_performance))
    
    if (nrow(comparison_show_performance_zscore) > 0) {
      
      # Top performing shows
      comparison_top_shows_zscore <- comparison_show_performance_zscore %>%
        filter(comparison_avg_zscore_performance > 0) %>%
        head(15)
      
      # Underperforming shows
      comparison_bottom_shows_zscore <- comparison_show_performance_zscore %>%
        filter(comparison_avg_zscore_performance < 0) %>%
        tail(10) %>%
        arrange(comparison_avg_zscore_performance)
      
      cat("✓ Z-score show performance analysis completed\n")
      cat("  - Shows analyzed:", nrow(comparison_show_performance_zscore), "\n")
      cat("  - Top performers:", nrow(comparison_top_shows_zscore), "\n")
      
    } else {
      comparison_top_shows_zscore <- data.frame()
      comparison_bottom_shows_zscore <- data.frame()
    }
    
  } else {
    comparison_show_performance_zscore <- data.frame()
    comparison_top_shows_zscore <- data.frame()
    comparison_bottom_shows_zscore <- data.frame()
  }
  
  # =============================================================================
  # PART 3O: COMPARISON STATION WEEKDAY AND WEEKEND HEATMAPS (Z-SCORE BASED) (IF ENABLED)
  # =============================================================================
  
  if (exists("comparison_hourly_baseline_stats") && nrow(comparison_hourly_baseline_stats) > 0) {
    
    cat("Creating z-score based weekday and weekend heatmaps for comparison station...\n")
    
    # Calculate z-scores for all shows by hour and day type
    comparison_show_heatmap_zscore <- data %>%
      filter(!is.na(comparison_showname), comparison_showname != "", comparison_showname != "Unknown",
             comparison_stand_in != 1) %>%  # Exclude sitting-in shows
      filter(!grepl(paste(EXCLUDE_TERMS, collapse = "|"), comparison_showname, ignore.case = TRUE)) %>%
      # Join with baseline statistics
      left_join(comparison_hourly_baseline_stats, by = c("hour", "day_type")) %>%
      # Only include observations where we have baseline stats
      filter(!is.na(comparison_hour_mean), !is.na(comparison_hour_sd), comparison_hour_sd > 0) %>%
      # Calculate z-score for each observation
      mutate(
        comparison_listener_zscore = (comparison_total_listeners - comparison_hour_mean) / comparison_hour_sd
      ) %>%
      # Group by show, hour, and day type
      group_by(hour, comparison_showname, day_type) %>%
      summarise(
        comparison_sessions = n(),
        comparison_avg_zscore_performance = mean(comparison_listener_zscore, na.rm = TRUE),
        comparison_avg_listeners = mean(comparison_total_listeners, na.rm = TRUE),
        .groups = 'drop'
      ) %>%
      # Arrange by hour descending:
      arrange(desc(hour)) %>%
      # Filter for combinations with sufficient data
      filter(comparison_sessions >= 3) %>%
      # Round for display
      mutate(comparison_avg_zscore_performance = round(comparison_avg_zscore_performance, 2)) %>%
      # Ensure reasonable hour range
      filter(hour >= 0, hour <= 24)
    
    # Create separate datasets for weekday and weekend
    comparison_weekday_heatmap_zscore <- comparison_show_heatmap_zscore %>%
      filter(day_type == "Weekday")
    
    comparison_weekend_heatmap_zscore <- comparison_show_heatmap_zscore %>%
      filter(day_type == "Weekend")
    
    if (nrow(comparison_weekday_heatmap_zscore) > 0) {
      cat("✓ Weekday heatmap data created:", nrow(comparison_weekday_heatmap_zscore), "show-hour combinations\n")
    }
    
    if (nrow(comparison_weekend_heatmap_zscore) > 0) {
      cat("✓ Weekend heatmap data created:", nrow(comparison_weekend_heatmap_zscore), "show-hour combinations\n")
    }
    
  } else {
    comparison_weekday_heatmap_zscore <- data.frame()
    comparison_weekend_heatmap_zscore <- data.frame()
  }
  
}

# =============================================================================
# ANALYSIS 3 COMPLETE
# =============================================================================

cat("Analysis 3 complete! Created show performance summaries and rankings:\n")

if (DEBUG_TO_CONSOLE == "Y") {
  cat("Main station:\n")
  cat("  - main_show_summary (", nrow(main_show_summary), " shows)\n")
  cat("  - main_best_weekday_shows (", nrow(main_best_weekday_shows), " shows)\n")
  cat("  - main_best_weekend_shows (", nrow(main_best_weekend_shows), " shows)\n")
  
  if (ANALYSE_SECOND_STATION == "Y") {
    cat("Second station:\n")
    cat("  - second_show_summary (", nrow(second_show_summary), " shows)\n")
  }
  
  if (ANALYSE_COMPARISON_STATION == "Y") {
    cat("Comparison station:\n")
    cat("  - comparison_show_summary (", nrow(comparison_show_summary), " shows)\n")
  }
  
  # Show top 3 weekend performers as example
  if (nrow(main_best_weekend_shows) > 0) {
    cat("\nTop 3 weekend performers:\n")
    top_3 <- main_best_weekend_shows %>% head(3)
    for (i in 1:nrow(top_3)) {
      cat("  ", i, ". ", top_3$main_showname[i], " (", top_3$main_avg_performance[i], "% vs hour avg)\n")
    }
  }
}


# =============================================================================
# ANALYSIS 4: SHOW CONSISTENCY ANALYSIS (FIXED VERSION)
# =============================================================================
# This analysis calculates how consistent shows are in their performance
# Uses standard deviation of performance across multiple episodes
# Creates percentile-based categories: Very Consistent, Consistent, Variable, Highly Variable
# Does NOT assume shows are exactly 1 hour or start on the hour

cat("Running Analysis 4: Show Consistency Analysis...\n")

# =============================================================================
# PART 4A: CREATE EPISODE-LEVEL DATA FOR CONSISTENCY ANALYSIS
# =============================================================================

# The key insight: We need to work with individual EPISODES, not pre-aggregated hours
# Each episode = a specific broadcast date + hour + show combination

# Step 1: Create episode-level performance data
main_episode_performance <- data %>%
  filter(!is.na(main_showname), main_showname != "", main_showname != "Unknown") %>%
  filter(main_stand_in != 1) %>%  # Exclude stand-ins
  # Group by episode (date + hour + show) to get episode averages
  group_by(date, hour, main_showname, main_presenter, day_type) %>%
  summarise(
    main_episode_avg_listeners = mean(main_total_listeners, na.rm = TRUE),
    main_sessions_in_episode = n(),
    .groups = 'drop'
  ) %>%
  # Only include episodes with reasonable data coverage
  filter(main_sessions_in_episode >= 3) %>%  # At least 3 data points per episode
  # Join with hourly baseline to calculate performance vs hour average
  left_join(main_hourly_baseline, by = c("hour", "day_type")) %>%
  mutate(
    main_pct_vs_hour = ((main_episode_avg_listeners - main_hour_avg) / main_hour_avg) * 100
  )

# Step 2: Calculate consistency for shows with multiple episodes
main_show_consistency <- main_episode_performance %>%
  # Filter out excluded show types
  filter(!grepl(paste(EXCLUDE_TERMS, collapse = "|"), main_showname, ignore.case = TRUE)) %>%
  # Group by show+presenter+hour combination to check for multiple episodes
  group_by(main_showname, main_presenter, hour, day_type) %>%
  # Only include time slots where we have multiple episodes of the same show
  filter(n() >= 2) %>%  # Need at least 2 episodes for consistency calculation
  summarise(
    main_avg_performance = mean(main_pct_vs_hour, na.rm = TRUE),
    main_performance_sd = sd(main_pct_vs_hour, na.rm = TRUE),
    main_episodes = n(),
    main_total_sessions = sum(main_sessions_in_episode),
    .groups = "drop"
  ) %>%
  # Group by show+presenter combination for overall consistency score
  group_by(main_showname, main_presenter, day_type) %>%
  summarise(
    main_avg_performance = mean(main_avg_performance, na.rm = TRUE),
    main_performance_sd = mean(main_performance_sd, na.rm = TRUE),  # Average SD across time slots
    main_total_episodes = sum(main_episodes),
    main_total_sessions = sum(main_total_sessions),
    main_time_slots = n(),  # Number of different time slots this show appears in
    .groups = "drop"
  ) %>%
  # Calculate consistency score
  mutate(
    main_consistency_score = case_when(
      is.na(main_performance_sd) | main_performance_sd == 0 ~ main_avg_performance,
      main_avg_performance >= 0 ~ main_avg_performance / (main_performance_sd + 1),
      TRUE ~ main_avg_performance - main_performance_sd
    )
  ) %>%
  arrange(desc(main_consistency_score))

# =============================================================================
# PART 4B: CALCULATE PERCENTILE-BASED CONSISTENCY THRESHOLDS
# =============================================================================

if (nrow(main_show_consistency) > 0) {
  
  # Calculate percentile thresholds for consistency categories
  # Based on standard deviation values across all shows
  consistency_thresholds <- list(
    very_consistent = quantile(main_show_consistency$main_performance_sd, 0.25, na.rm = TRUE),  # Top 25%
    consistent = quantile(main_show_consistency$main_performance_sd, 0.50, na.rm = TRUE),        # Top 50%
    variable = quantile(main_show_consistency$main_performance_sd, 0.75, na.rm = TRUE)           # Top 75%
    # Highly variable = above 75th percentile
  )
  
  # Add consistency categories to the data
  main_show_consistency <- main_show_consistency %>%
    mutate(
      main_consistency_category = case_when(
        main_performance_sd <= consistency_thresholds$very_consistent ~ "Very Consistent",
        main_performance_sd <= consistency_thresholds$consistent ~ "Consistent", 
        main_performance_sd <= consistency_thresholds$variable ~ "Variable",
        TRUE ~ "Highly Variable"
      ),
      # Create factor for ordered display
      main_consistency_factor = factor(main_consistency_category, 
                                       levels = c("Very Consistent", "Consistent", "Variable", "Highly Variable"))
    )
  
  cat("Consistency analysis complete!\n")
  cat("Shows analyzed:", nrow(main_show_consistency), "\n")
  cat("Total episodes analyzed:", sum(main_show_consistency$main_total_episodes), "\n")
  
} else {
  cat("Warning: No shows found with multiple episodes for consistency analysis\n")
  cat("This could be because:\n")
  cat("1. Not enough data has been collected yet\n")
  cat("2. Shows don't repeat in the same time slots\n")
  cat("3. Data filtering is too strict\n")
}

# =============================================================================
# PART 4C: CREATE CONSISTENCY DATASETS FOR CHARTS (IF DATA EXISTS)
# =============================================================================

if (nrow(main_show_consistency) > 0) {
  
  # Weekday consistency data (for charts)
  main_weekday_consistency <- main_show_consistency %>%
    filter(day_type == "Weekday", !is.na(main_consistency_score)) %>%
    arrange(desc(main_consistency_score)) %>%
    head(100) %>%  # Limit for chart readability
    mutate(main_showname_factor = factor(paste(main_showname), 
                                         levels = rev(paste(main_showname))))
  
  # Weekend consistency data (for charts)  
  main_weekend_consistency <- main_show_consistency %>%
    filter(day_type == "Weekend", !is.na(main_consistency_score)) %>%
    arrange(desc(main_consistency_score)) %>%
    head(100) %>%
    mutate(main_showname_factor = factor(paste(main_showname), 
                                         levels = rev(paste(main_showname))))
  
  # Calculate summary statistics
  main_consistency_summary_stats <- list(
    main_total_shows_analyzed = nrow(main_show_consistency),
    main_total_episodes_analyzed = sum(main_show_consistency$main_total_episodes),
    main_avg_consistency_score = round(mean(main_show_consistency$main_consistency_score, na.rm = TRUE), 1),
    main_most_consistent_show = main_show_consistency %>% 
      filter(main_consistency_score == max(main_consistency_score, na.rm = TRUE)) %>% 
      slice(1) %>% 
      unite(show_presenter, main_showname, main_presenter, sep = " - ") %>%
      pull(show_presenter),
    main_best_consistency_score = round(max(main_show_consistency$main_consistency_score, na.rm = TRUE), 1),
    main_least_consistent_show = main_show_consistency %>% 
      filter(main_consistency_score == min(main_consistency_score, na.rm = TRUE)) %>% 
      slice(1) %>% 
      unite(show_presenter, main_showname, main_presenter, sep = " - ") %>%
      pull(show_presenter),
    main_worst_consistency_score = round(min(main_show_consistency$main_consistency_score, na.rm = TRUE), 1),
    main_shows_above_avg_performance = sum(main_show_consistency$main_avg_performance > 0, na.rm = TRUE),
    main_shows_below_avg_performance = sum(main_show_consistency$main_avg_performance <= 0, na.rm = TRUE)
  )
  
} else {
  # Create empty objects if no data
  main_weekday_consistency <- data.frame()
  main_weekend_consistency <- data.frame()
  main_consistency_summary_stats <- list(
    main_total_shows_analyzed = 0,
    main_total_episodes_analyzed = 0,
    main_avg_consistency_score = 0,
    main_most_consistent_show = "No data",
    main_best_consistency_score = 0,
    main_least_consistent_show = "No data", 
    main_worst_consistency_score = 0,
    main_shows_above_avg_performance = 0,
    main_shows_below_avg_performance = 0
  )
}

# =============================================================================
# PART 4D: SECOND STATION (IF ENABLED)
# =============================================================================

if (ANALYSE_SECOND_STATION == "Y") {
  
  # The key insight: We need to work with individual EPISODES, not pre-aggregated hours
  # Each episode = a specific broadcast date + hour + show combination
  
  # Step 1: Create episode-level performance data
  second_episode_performance <- data %>%
    filter(!is.na(second_showname), second_showname != "", second_showname != "Unknown") %>%
    filter(second_stand_in != 1) %>%  # Exclude stand-ins
    # Group by episode (date + hour + show) to get episode averages
    group_by(date, hour, second_showname, second_presenter, day_type) %>%
    summarise(
      second_episode_avg_listeners = mean(second_total_listeners, na.rm = TRUE),
      second_sessions_in_episode = n(),
      .groups = 'drop'
    ) %>%
    # Only include episodes with reasonable data coverage
    filter(second_sessions_in_episode >= 3) %>%  # At least 3 data points per episode
    # Join with hourly baseline to calculate performance vs hour average
    left_join(second_hourly_baseline, by = c("hour", "day_type")) %>%
    mutate(
      second_pct_vs_hour = ((second_episode_avg_listeners - second_hour_avg) / second_hour_avg) * 100
    )
  
  # Step 2: Calculate consistency for shows with multiple episodes
  second_show_consistency <- second_episode_performance %>%
    # Filter out excluded show types
    filter(!grepl(paste(EXCLUDE_TERMS, collapse = "|"), second_showname, ignore.case = TRUE)) %>%
    # Group by show+presenter+hour combination to check for multiple episodes
    group_by(second_showname, second_presenter, hour, day_type) %>%
    # Only include time slots where we have multiple episodes of the same show
    filter(n() >= 2) %>%  # Need at least 2 episodes for consistency calculation
    summarise(
      second_avg_performance = mean(second_pct_vs_hour, na.rm = TRUE),
      second_performance_sd = sd(second_pct_vs_hour, na.rm = TRUE),
      second_episodes = n(),
      second_total_sessions = sum(second_sessions_in_episode),
      .groups = "drop"
    ) %>%
    # Group by show+presenter combination for overall consistency score
    group_by(second_showname, second_presenter, day_type) %>%
    summarise(
      second_avg_performance = mean(second_avg_performance, na.rm = TRUE),
      second_performance_sd = mean(second_performance_sd, na.rm = TRUE),  # Average SD across time slots
      second_total_episodes = sum(second_episodes),
      second_total_sessions = sum(second_total_sessions),
      second_time_slots = n(),  # Number of different time slots this show appears in
      .groups = "drop"
    ) %>%
    # Calculate consistency score
    mutate(
      second_consistency_score = case_when(
        is.na(second_performance_sd) | second_performance_sd == 0 ~ second_avg_performance,
        second_avg_performance >= 0 ~ second_avg_performance / (second_performance_sd + 1),
        TRUE ~ second_avg_performance - second_performance_sd
      )
    ) %>%
    arrange(desc(second_consistency_score))
  
  if (nrow(second_show_consistency) > 0) {
    
    # Calculate percentile thresholds for consistency categories
    # Based on standard deviation values across all shows
    consistency_thresholds <- list(
      very_consistent = quantile(second_show_consistency$second_performance_sd, 0.25, na.rm = TRUE),  # Top 25%
      consistent = quantile(second_show_consistency$second_performance_sd, 0.50, na.rm = TRUE),        # Top 50%
      variable = quantile(second_show_consistency$second_performance_sd, 0.75, na.rm = TRUE)           # Top 75%
      # Highly variable = above 75th percentile
    )
    
    # Add consistency categories to the data
    second_show_consistency <- second_show_consistency %>%
      mutate(
        second_consistency_category = case_when(
          second_performance_sd <= consistency_thresholds$very_consistent ~ "Very Consistent",
          second_performance_sd <= consistency_thresholds$consistent ~ "Consistent", 
          second_performance_sd <= consistency_thresholds$variable ~ "Variable",
          TRUE ~ "Highly Variable"
        ),
        # Create factor for ordered display
        second_consistency_factor = factor(second_consistency_category, 
                                         levels = c("Very Consistent", "Consistent", "Variable", "Highly Variable"))
      )
    
    cat("Consistency analysis complete!\n")
    cat("Shows analyzed:", nrow(second_show_consistency), "\n")
    cat("Total episodes analyzed:", sum(second_show_consistency$second_total_episodes), "\n")
    
  } else {
    cat("Warning: No shows found with multiple episodes for consistency analysis\n")
    cat("This could be because:\n")
    cat("1. Not enough data has been collected yet\n")
    cat("2. Shows don't repeat in the same time slots\n")
    cat("3. Data filtering is too strict\n")
  }
  
  if (nrow(second_show_consistency) > 0) {
    
    # Weekday consistency data (for charts)
    second_weekday_consistency <- second_show_consistency %>%
      filter(day_type == "Weekday", !is.na(second_consistency_score)) %>%
      arrange(desc(second_consistency_score)) %>%
      head(100) %>%  # Limit for chart readability
      mutate(second_showname_factor = factor(paste(second_showname), 
                                           levels = rev(paste(second_showname))))
    
    # Weekend consistency data (for charts)  
    second_weekend_consistency <- second_show_consistency %>%
      filter(day_type == "Weekend", !is.na(second_consistency_score)) %>%
      arrange(desc(second_consistency_score)) %>%
      head(100) %>%
      mutate(second_showname_factor = factor(paste(second_showname), 
                                           levels = rev(paste(second_showname))))
    
    # Calculate summary statistics
    second_consistency_summary_stats <- list(
      second_total_shows_analyzed = nrow(second_show_consistency),
      second_total_episodes_analyzed = sum(second_show_consistency$second_total_episodes),
      second_avg_consistency_score = round(mean(second_show_consistency$second_consistency_score, na.rm = TRUE), 1),
      second_most_consistent_show = second_show_consistency %>% 
        filter(second_consistency_score == max(second_consistency_score, na.rm = TRUE)) %>% 
        slice(1) %>% 
        unite(show_presenter, second_showname, second_presenter, sep = " - ") %>%
        pull(show_presenter),
      second_best_consistency_score = round(max(second_show_consistency$second_consistency_score, na.rm = TRUE), 1),
      second_least_consistent_show = second_show_consistency %>% 
        filter(second_consistency_score == min(second_consistency_score, na.rm = TRUE)) %>% 
        slice(1) %>% 
        unite(show_presenter, second_showname, second_presenter, sep = " - ") %>%
        pull(show_presenter),
      second_worst_consistency_score = round(min(second_show_consistency$second_consistency_score, na.rm = TRUE), 1),
      second_shows_above_avg_performance = sum(second_show_consistency$second_avg_performance > 0, na.rm = TRUE),
      second_shows_below_avg_performance = sum(second_show_consistency$second_avg_performance <= 0, na.rm = TRUE)
    )
    
  } else {
    # Create empty objects if no data
    second_weekday_consistency <- data.frame()
    second_weekend_consistency <- data.frame()
    second_consistency_summary_stats <- list(
      second_total_shows_analyzed = 0,
      second_total_episodes_analyzed = 0,
      second_avg_consistency_score = 0,
      second_most_consistent_show = "No data",
      second_best_consistency_score = 0,
      second_least_consistent_show = "No data", 
      second_worst_consistency_score = 0,
      second_shows_above_avg_performance = 0,
      second_shows_below_avg_performance = 0
    )
  }

}

# =============================================================================
# PART 4E: COMPARISON STATION (IF ENABLED)
# =============================================================================

if (ANALYSE_COMPARISON_STATION == "Y") {
  
  # Create episode-level data for comparison station
  comparison_episode_performance <- data %>%
    filter(!is.na(comparison_showname), comparison_showname != "", comparison_showname != "Unknown") %>%
    filter(comparison_stand_in != 1) %>%
    group_by(date, hour, comparison_showname, comparison_presenter, day_type) %>%
    summarise(
      comparison_episode_avg_listeners = mean(comparison_total_listeners, na.rm = TRUE),
      comparison_sessions_in_episode = n(),
      .groups = 'drop'
    ) %>%
    filter(comparison_sessions_in_episode >= 3) %>%
    left_join(comparison_hourly_baseline, by = c("hour", "day_type")) %>%
    mutate(
      comparison_pct_vs_hour = ((comparison_episode_avg_listeners - comparison_hour_avg) / comparison_hour_avg) * 100
    )
  
  # Calculate consistency for comparison station
  comparison_show_consistency <- comparison_episode_performance %>%
    filter(!grepl(paste(EXCLUDE_TERMS, collapse = "|"), comparison_showname, ignore.case = TRUE)) %>%
    group_by(comparison_showname, comparison_presenter, hour, day_type) %>%
    filter(n() >= 2) %>%
    summarise(
      comparison_avg_performance = mean(comparison_pct_vs_hour, na.rm = TRUE),
      comparison_performance_sd = sd(comparison_pct_vs_hour, na.rm = TRUE),
      comparison_episodes = n(),
      comparison_total_sessions = sum(comparison_sessions_in_episode),
      .groups = "drop"
    ) %>%
    group_by(comparison_showname, comparison_presenter, day_type) %>%
    summarise(
      comparison_avg_performance = mean(comparison_avg_performance, na.rm = TRUE),
      comparison_performance_sd = mean(comparison_performance_sd, na.rm = TRUE),
      comparison_total_episodes = sum(comparison_episodes),
      comparison_total_sessions = sum(comparison_total_sessions),
      comparison_time_slots = n(),
      .groups = "drop"
    ) %>%
    mutate(
      comparison_consistency_score = case_when(
        is.na(comparison_performance_sd) | comparison_performance_sd == 0 ~ comparison_avg_performance,
        comparison_avg_performance >= 0 ~ comparison_avg_performance / (comparison_performance_sd + 1),
        TRUE ~ comparison_avg_performance - comparison_performance_sd
      )
    ) %>%
    arrange(desc(comparison_consistency_score))
  
  # Add consistency categories using same thresholds
  if (nrow(comparison_show_consistency) > 0) {
    comparison_show_consistency <- comparison_show_consistency %>%
      mutate(
        comparison_consistency_category = case_when(
          comparison_performance_sd <= consistency_thresholds$very_consistent ~ "Very Consistent",
          comparison_performance_sd <= consistency_thresholds$consistent ~ "Consistent",
          comparison_performance_sd <= consistency_thresholds$variable ~ "Variable",
          TRUE ~ "Highly Variable"
        )
      )
  }
}

# =============================================================================
# ANALYSIS 4 COMPLETE
# =============================================================================

cat("Analysis 4 complete!\n")


# =============================================================================
# ANALYSIS 5: AUDIENCE RETENTION ANALYSIS
# =============================================================================
# This analysis measures how well shows hold their audience during episodes
# Compares start-of-episode vs end-of-episode listener counts
# Measures retention performance vs other shows in same time slots
# Completely separate from consistency analysis

cat("Running Analysis 5: Audience Retention Analysis...\n")

# =============================================================================
# PART 5A: CALCULATE EPISODE-LEVEL RETENTION - MAIN STATION
# =============================================================================

# Calculate within-episode retention for each individual episode
main_episode_retention_raw <- data %>%
  # Group by individual episodes (same show on same date/hour)
  group_by(date, hour, main_showname, main_presenter, main_stand_in, day_type) %>%
  arrange(datetime) %>%
  # Only analyze "complete" episodes with sufficient data points
  filter(n() >= 8) %>%  # At least 8 data points (40 minutes if 5-min intervals)
  filter(main_stand_in != 1) %>%  # Exclude sitting-in presenters
  summarise(
    main_episode_start = first(main_total_listeners),  # Start of episode
    main_episode_end = last(main_total_listeners),     # End of episode  
    main_episode_peak = max(main_total_listeners, na.rm = TRUE),    # Peak during episode
    main_episode_min = min(main_total_listeners, na.rm = TRUE),     # Lowest point
    main_episode_avg = mean(main_total_listeners, na.rm = TRUE),    # Average during episode
    main_data_points = n(),
    main_duration_minutes = main_data_points * DATA_COLLECTION,  # Actual episode duration
    .groups = 'drop'
  ) %>%
  filter(main_episode_start > 0) %>%  # Avoid division by zero
  mutate(
    # Calculate retention metrics
    main_retention_rate = ((main_episode_end - main_episode_start) / main_episode_start) * 100,
    main_peak_gain = ((main_episode_peak - main_episode_start) / main_episode_start) * 100,
    main_worst_drop = ((main_episode_min - main_episode_start) / main_episode_start) * 100,
    main_volatility = main_episode_peak - main_episode_min
  )

# =============================================================================
# PART 5B: CALCULATE TIME SLOT BASELINES
# =============================================================================

# Calculate hourly baselines to compare retention against
main_retention_hourly_baseline <- main_episode_retention_raw %>%
  group_by(hour, day_type) %>%
  summarise(
    main_slot_avg_retention = mean(main_retention_rate, na.rm = TRUE),
    main_slot_avg_peak_gain = mean(main_peak_gain, na.rm = TRUE),
    main_slot_avg_volatility = mean(main_volatility, na.rm = TRUE),
    main_episodes_in_slot = n(),
    .groups = 'drop'
  )

# =============================================================================
# PART 5C: CALCULATE RETENTION VS SLOT PERFORMANCE
# =============================================================================

# Compare each episode's retention to its time slot average
main_episode_retention_performance <- main_episode_retention_raw %>%
  left_join(main_retention_hourly_baseline, by = c("hour", "day_type")) %>%
  mutate(
    main_retention_vs_slot = main_retention_rate - main_slot_avg_retention,
    main_peak_gain_vs_slot = main_peak_gain - main_slot_avg_peak_gain,
    main_volatility_vs_slot = main_volatility - main_slot_avg_volatility
  )

# =============================================================================
# PART 5D: SUMMARIZE RETENTION BY SHOW
# =============================================================================

# Summarize retention performance by show across all episodes
main_show_retention_summary <- main_episode_retention_performance %>%
  filter(!is.na(main_showname), main_showname != "", main_showname != "Unknown") %>%
  # Filter out excluded show types
  filter(!grepl(paste(EXCLUDE_TERMS, collapse = "|"), main_showname, ignore.case = TRUE)) %>%
  filter(main_stand_in != 1) %>%
  group_by(main_showname, day_type) %>%
  summarise(
    main_broadcast_hours = n(),  # Number of episodes analyzed
    main_avg_retention_rate = mean(main_retention_rate, na.rm = TRUE),
    main_avg_retention_vs_slot = mean(main_retention_vs_slot, na.rm = TRUE),
    main_retention_consistency = sd(main_retention_rate, na.rm = TRUE),  # How consistent is retention?
    main_avg_peak_gain = mean(main_peak_gain, na.rm = TRUE),
    main_avg_volatility = mean(main_volatility, na.rm = TRUE),
    main_best_retention = max(main_retention_rate, na.rm = TRUE),
    main_worst_retention = min(main_retention_rate, na.rm = TRUE),
    .groups = 'drop'
  ) %>%
  filter(main_broadcast_hours >= 2) %>%  # Need at least 2 episodes for reliable analysis
  arrange(day_type, desc(main_avg_retention_vs_slot))

# =============================================================================
# PART 5E: CREATE PERCENTILE-BASED RETENTION CATEGORIES
# =============================================================================

if (nrow(main_show_retention_summary) > 0) {
  
  # Calculate percentile thresholds for retention performance
  retention_thresholds <- list(
    excellent = quantile(main_show_retention_summary$main_avg_retention_vs_slot, 0.85, na.rm = TRUE),  # Top 15%
    good = quantile(main_show_retention_summary$main_avg_retention_vs_slot, 0.65, na.rm = TRUE),       # Top 35%
    average = quantile(main_show_retention_summary$main_avg_retention_vs_slot, 0.15, na.rm = TRUE)     # Bottom 15%
    # Poor = below 15th percentile
  )
  
  # Calculate percentile thresholds for retention consistency (using retention_consistency SD)
  retention_consistency_thresholds <- list(
    very_consistent = quantile(main_show_retention_summary$main_retention_consistency, 0.25, na.rm = TRUE),
    consistent = quantile(main_show_retention_summary$main_retention_consistency, 0.50, na.rm = TRUE),
    variable = quantile(main_show_retention_summary$main_retention_consistency, 0.75, na.rm = TRUE)
  )
  
  # Add retention categories
  main_show_retention_summary <- main_show_retention_summary %>%
    mutate(
      main_retention_grade = case_when(
        main_avg_retention_vs_slot > retention_thresholds$excellent ~ "Excellent Retention",
        main_avg_retention_vs_slot > retention_thresholds$good ~ "Good Retention",
        main_avg_retention_vs_slot > retention_thresholds$average ~ "Average Retention",
        TRUE ~ "Poor Retention"
      ),
      main_retention_consistency_grade = case_when(
        is.na(main_retention_consistency) | main_retention_consistency <= retention_consistency_thresholds$very_consistent ~ "Very Consistent",
        main_retention_consistency <= retention_consistency_thresholds$consistent ~ "Consistent",
        main_retention_consistency <= retention_consistency_thresholds$variable ~ "Variable",
        TRUE ~ "Highly Variable"
      )
    )
}

# =============================================================================
# PART 5F: CREATE RETENTION DATASETS FOR CHARTS
# =============================================================================

if (nrow(main_show_retention_summary) > 0) {
  
  # Weekday retention data (for charts)
  main_weekday_retention <- main_show_retention_summary %>%
    filter(day_type == "Weekday") %>%
    arrange(desc(main_avg_retention_vs_slot)) %>%
    head(25) %>%  # Top 25 for chart readability
    mutate(main_showname_factor = factor(main_showname, levels = rev(main_showname)))
  
  # Weekend retention data (for charts)
  main_weekend_retention <- main_show_retention_summary %>%
    filter(day_type == "Weekend") %>%
    arrange(desc(main_avg_retention_vs_slot)) %>%
    head(25) %>%
    mutate(main_showname_factor = factor(main_showname, levels = rev(main_showname)))
  
  # Calculate summary statistics
  main_retention_summary_stats <- list(
    main_total_shows_analyzed = nrow(main_show_retention_summary),
    main_total_episodes_analyzed = sum(main_show_retention_summary$main_broadcast_hours),
    main_avg_retention_rate = round(mean(main_show_retention_summary$main_avg_retention_rate, na.rm = TRUE), 1),
    main_avg_retention_vs_slot = round(mean(main_show_retention_summary$main_avg_retention_vs_slot, na.rm = TRUE), 1),
    main_best_retainer = main_show_retention_summary %>% 
      filter(main_avg_retention_vs_slot == max(main_avg_retention_vs_slot, na.rm = TRUE)) %>% 
      slice(1) %>% 
      pull(main_showname),
    main_best_retention_score = round(max(main_show_retention_summary$main_avg_retention_vs_slot, na.rm = TRUE), 1),
    main_worst_retainer = main_show_retention_summary %>% 
      filter(main_avg_retention_vs_slot == min(main_avg_retention_vs_slot, na.rm = TRUE)) %>% 
      slice(1) %>% 
      pull(main_showname),
    main_worst_retention_score = round(min(main_show_retention_summary$main_avg_retention_vs_slot, na.rm = TRUE), 1)
  )
  
} else {
  main_retention_summary_stats <- list(
    main_total_shows_analyzed = 0,
    main_total_episodes_analyzed = 0,
    main_avg_retention_rate = 0,
    main_avg_retention_vs_slot = 0,
    main_best_retainer = "No data",
    main_best_retention_score = 0,
    main_worst_retainer = "No data",
    main_worst_retention_score = 0
  )
}

# =============================================================================
# PART 5G: CREATE RETENTION HEATMAPS
# =============================================================================

# Create retention heatmap data for shows that broadcast in multiple hours
if (exists("main_episode_retention_performance") && nrow(main_episode_retention_performance) > 0) {
  
  main_retention_heatmap_data <- main_episode_retention_performance %>%
    filter(!is.na(main_showname), main_showname != "", main_showname != "Unknown") %>%
    filter(!grepl(paste(EXCLUDE_TERMS, collapse = "|"), main_showname, ignore.case = TRUE)) %>%
    filter(main_stand_in != 1) %>%
    # Group by show+hour+day_type to get average retention for each time slot
    group_by(main_showname, main_presenter, hour, day_type) %>%
    summarise(
      main_avg_retention_vs_slot = mean(main_retention_vs_slot, na.rm = TRUE),
      main_episodes = n(),
      .groups = 'drop'
    ) %>%
    filter(main_episodes >= 1) %>%  # Even single episodes for hourly patterns
    # Only include shows that appear in multiple hours (for meaningful heatmap)
    group_by(main_showname, main_presenter, day_type) %>%
    filter(n() > 1) %>%  # Must broadcast in multiple different hours
    ungroup() %>%
    # Order shows by their average retention performance for better visualization
    group_by(main_showname, main_presenter, day_type) %>%
    mutate(show_avg_retention = mean(main_avg_retention_vs_slot, na.rm = TRUE)) %>%
    ungroup()
  
  # Create weekday retention heatmap
  main_weekday_retention_heatmap_data <- main_retention_heatmap_data %>% 
    filter(day_type == "Weekday")
  
  if (nrow(main_weekday_retention_heatmap_data) > 0) {
    # Order shows by average retention performance
    main_weekday_retention_heatmap_data <- main_weekday_retention_heatmap_data %>%
      arrange(desc(hour), main_showname) %>%
      mutate(
        show_label = paste(main_showname),
        show_factor = factor(show_label, levels = unique(show_label))
      )
    
    main_weekday_retention_heatmap <- ggplot(main_weekday_retention_heatmap_data, 
                                             aes(x = hour, y = show_factor, fill = main_avg_retention_vs_slot)) +
      geom_tile(color = "grey60", linewidth = 0.1) +
      scale_fill_gradient2(low = "red", mid = "white", high = "blue", midpoint = 0,
                           name = "Retention\nvs Slot Avg") +
      labs(title = "Weekday Shows: Retention Performance by Hour",
           subtitle = "Shows that broadcast in multiple weekday time slots",
           x = "Hour", y = "") +
      theme_minimal() +
      theme(axis.text.y = element_text(size = 8),
            legend.title = element_text(size = 9)) +
      scale_x_continuous(breaks = seq(0, 23, 4))
  } else {
    main_weekday_retention_heatmap <- ggplot() + 
      labs(title = "No weekday multi-hour show data available") + 
      theme_void()
  }
  
  # Create weekend retention heatmap  
  main_weekend_retention_heatmap_data <- main_retention_heatmap_data %>% 
    filter(day_type == "Weekend")
  
  if (nrow(main_weekend_retention_heatmap_data) > 0) {
    # Order shows by average retention performance
    main_weekend_retention_heatmap_data <- main_weekend_retention_heatmap_data %>%
      arrange(desc(hour), main_showname) %>%
      mutate(
        show_label = paste(main_showname),
        show_factor = factor(show_label, levels = unique(show_label))
      )
    
    main_weekend_retention_heatmap <- ggplot(main_weekend_retention_heatmap_data, 
                                             aes(x = hour, y = show_factor, fill = main_avg_retention_vs_slot)) +
      geom_tile(color = "grey60", linewidth = 0.1) +
      scale_fill_gradient2(low = "red", mid = "white", high = "blue", midpoint = 0,
                           name = "Retention\nvs Slot Avg") +
      labs(title = "Weekend Shows: Retention Performance by Hour",
           subtitle = "Shows that broadcast in multiple weekend time slots",
           x = "Hour", y = "") +
      theme_minimal() +
      theme(axis.text.y = element_text(size = 8),
            legend.title = element_text(size = 9)) +
      scale_x_continuous(breaks = seq(0, 23, 4))
  } else {
    main_weekend_retention_heatmap <- ggplot() + 
      labs(title = "No weekend multi-hour show data available") + 
      theme_void()
  }
  
  cat("Retention heatmaps created!\n")
  if (DEBUG_TO_CONSOLE == "Y") {
    cat("- Weekday heatmap shows:", nrow(main_weekday_retention_heatmap_data), "show-hour combinations\n")
    cat("- Weekend heatmap shows:", nrow(main_weekend_retention_heatmap_data), "show-hour combinations\n")
  }
  
} else {
  # Create empty plots if no retention data exists
  main_weekday_retention_heatmap <- ggplot() + 
    labs(title = "Retention data not available") + 
    theme_void()
  main_weekend_retention_heatmap <- ggplot() + 
    labs(title = "Retention data not available") + 
    theme_void()
}

# =============================================================================
# PART 5H: RETENTION PERFORMANCE TABLES
# =============================================================================

# Create enhanced retention tables with percentile-based grades
if (exists("main_show_retention_summary") && nrow(main_show_retention_summary) > 0) {
  
  # Calculate data-driven thresholds for retention performance
  # These thresholds are calculated from ALL shows (weekday + weekend) for consistency
  main_retention_thresholds <- list(
    excellent = quantile(main_show_retention_summary$main_avg_retention_vs_slot, 0.85, na.rm = TRUE),  # Top 15%
    good = quantile(main_show_retention_summary$main_avg_retention_vs_slot, 0.65, na.rm = TRUE),       # Top 35% 
    average = quantile(main_show_retention_summary$main_avg_retention_vs_slot, 0.35, na.rm = TRUE)     # Bottom 35%
    # Poor = below 35th percentile
  )
  
  # Calculate data-driven thresholds for consistency (lower standard deviation = more consistent)
  main_consistency_thresholds <- list(
    very_consistent = quantile(main_show_retention_summary$main_retention_consistency, 0.25, na.rm = TRUE),  # Top 25%
    consistent = quantile(main_show_retention_summary$main_retention_consistency, 0.5, na.rm = TRUE),        # Top 50%
    variable = quantile(main_show_retention_summary$main_retention_consistency, 0.75, na.rm = TRUE)          # Top 75%
    # Highly Variable = above 75th percentile
  )
  
  cat("Retention performance thresholds calculated:\n")
  cat("- Excellent retention: >", round(main_retention_thresholds$excellent, 1), "% vs slot avg\n")
  cat("- Good retention: >", round(main_retention_thresholds$good, 1), "% vs slot avg\n")
  cat("- Average retention:", round(main_retention_thresholds$average, 1), "% to", round(main_retention_thresholds$good, 1), "% vs slot avg\n")
  cat("- Poor retention: <", round(main_retention_thresholds$average, 1), "% vs slot avg\n")
  
} else {
  cat("Warning: main_show_retention_summary not available for threshold calculation\n")
  # Create default thresholds
  main_retention_thresholds <- list(excellent = 2, good = 0, average = -2)
  main_consistency_thresholds <- list(very_consistent = 2, consistent = 4, variable = 6)
}

#Weekdays Retention Performace Table
create_weekday_retention_table <- function() {
  if (exists("main_show_retention_summary") && nrow(main_show_retention_summary) > 0) {
    
    # Filter for weekday shows
    main_weekday_retention_data <- main_show_retention_summary %>%
      filter(day_type == "Weekday") %>%
      filter(!grepl(paste(EXCLUDE_TERMS, collapse = "|"), main_showname, ignore.case = TRUE))
      # filter(main_stand_in != 1)
    
    if (nrow(main_weekday_retention_data) > 0) {
      
      # Create the enhanced table with grades
      main_weekday_retention_table <- main_weekday_retention_data %>%
        mutate(
          # Retention level based on performance vs slot average
          main_retention_grade = case_when(
            main_avg_retention_vs_slot >= main_retention_thresholds$excellent ~ "Excellent",
            main_avg_retention_vs_slot >= main_retention_thresholds$good ~ "Good", 
            main_avg_retention_vs_slot >= main_retention_thresholds$average ~ "Average",
            TRUE ~ "Poor"
          ),
          # Consistency grade based on standard deviation (lower = better)
          main_consistency_grade = case_when(
            main_retention_consistency <= main_consistency_thresholds$very_consistent ~ "Very&nbsp;Consistent",
            main_retention_consistency <= main_consistency_thresholds$consistent ~ "Consistent",
            main_retention_consistency <= main_consistency_thresholds$variable ~ "Variable", 
            TRUE ~ "Highly&nbsp;Variable"
          )
        ) %>%
        arrange(desc(main_avg_retention_vs_slot)) %>%
        mutate(
          main_avg_retention_vs_slot = round(main_avg_retention_vs_slot, 1),
          main_avg_retention_rate = round(main_avg_retention_rate, 1),
          main_retention_consistency = round(main_retention_consistency, 1)
        ) %>%
        select(main_showname, main_broadcast_hours, main_avg_retention_rate, 
               main_avg_retention_vs_slot, main_retention_grade, main_consistency_grade)
      
      return(main_weekday_retention_table)
    }
  }
  return(data.frame())
}

#Weekend Retention Performance Table
create_weekend_retention_table <- function() {
  if (exists("main_show_retention_summary") && nrow(main_show_retention_summary) > 0) {
    
    # Filter for weekend shows
    main_weekend_retention_data <- main_show_retention_summary %>%
      filter(day_type == "Weekend") %>%
      filter(!grepl(paste(EXCLUDE_TERMS, collapse = "|"), main_showname, ignore.case = TRUE))
      # filter(main_stand_in != 1)
    
    if (nrow(main_weekend_retention_data) > 0) {
      
      # Create the enhanced table with grades (using same thresholds as weekday)
      main_weekend_retention_table <- main_weekend_retention_data %>%
        mutate(
          # Retention level based on performance vs slot average
          main_retention_grade = case_when(
            main_avg_retention_vs_slot >= main_retention_thresholds$excellent ~ "Excellent",
            main_avg_retention_vs_slot >= main_retention_thresholds$good ~ "Good", 
            main_avg_retention_vs_slot >= main_retention_thresholds$average ~ "Average",
            TRUE ~ "Poor"
          ),
          # Consistency grade based on standard deviation (lower = better)
          main_consistency_grade = case_when(
            main_retention_consistency <= main_consistency_thresholds$very_consistent ~ "Very&nbsp;Consistent",
            main_retention_consistency <= main_consistency_thresholds$consistent ~ "Consistent",
            main_retention_consistency <= main_consistency_thresholds$variable ~ "Variable", 
            TRUE ~ "Highly&nbsp;Variable"
          )
        ) %>%
        arrange(desc(main_avg_retention_vs_slot)) %>%
        mutate(
          main_avg_retention_vs_slot = round(main_avg_retention_vs_slot, 1),
          main_avg_retention_rate = round(main_avg_retention_rate, 1),
          main_retention_consistency = round(main_retention_consistency, 1)
        ) %>%
        select(main_showname, main_broadcast_hours, main_avg_retention_rate, 
               main_avg_retention_vs_slot, main_retention_grade, main_consistency_grade)
      
      return(main_weekend_retention_table)
    }
  }
  return(data.frame())
}

# Create the tables
main_weekday_retention_table <- create_weekday_retention_table()
main_weekend_retention_table <- create_weekend_retention_table()

cat("Retention performance tables created!\n")
if (DEBUG_TO_CONSOLE == "Y") {
  cat("- Weekday retention table: ", nrow(main_weekday_retention_table), " shows\n")
  cat("- Weekend retention table: ", nrow(main_weekend_retention_table), " shows\n")
}

# =============================================================================
# PART 5I: CALCULATE HOURLY RETENTION PATTERNS
# =============================================================================

# Calculate hourly retention patterns across the day
if (exists("main_episode_retention_performance") && nrow(main_episode_retention_performance) > 0) {
  
  main_hourly_retention_patterns <- main_episode_retention_performance %>%
    group_by(hour, day_type) %>%
    summarise(
      main_avg_retention = mean(main_retention_rate, na.rm = TRUE),
      main_avg_peak_gain = mean(main_peak_gain, na.rm = TRUE),
      main_episodes = n(),
      .groups = 'drop'
    ) %>%
    filter(main_episodes >= 2)  # Need at least 2 episodes per hour for meaningful average
  
  # Create the hourly retention patterns chart
  if (nrow(main_hourly_retention_patterns) > 0) {
    main_hourly_retention_chart <- ggplot(main_hourly_retention_patterns, 
                                          aes(x = hour, y = main_avg_retention, color = day_type)) +
      geom_line(linewidth = 1.2) +
      geom_point(size = 2) +
      geom_hline(yintercept = 0, linetype = "dashed", alpha = 0.5) +
      scale_color_manual(values = c("Weekday" = "blue", "Weekend" = "red")) +
      labs(title = "Hourly Audience Retention Patterns",
           subtitle = "Average audience gain/loss during episodes by time of day",
           x = "Hour", y = "Average Retention Rate (%)",
           color = "Day Type") +
      theme_minimal() +
      theme(legend.position = "bottom") +
      scale_x_continuous(breaks = seq(0, 23, 4))
  } else {
    main_hourly_retention_chart <- ggplot() + 
      labs(title = "No hourly retention data available") + 
      theme_void()
  }
  
} else {
  main_hourly_retention_chart <- ggplot() + 
    labs(title = "Retention data not available") + 
    theme_void()
}

# =============================================================================
# PART 5J: RETENTION PERFORMANCE vs VARIABILITY SCATTER PLOT
# =============================================================================

# Create the retention performance vs variability scatter plot
if (exists("main_show_retention_summary") && nrow(main_show_retention_summary) > 0) {
  
  main_retention_consistency_chart <- ggplot(main_show_retention_summary, 
                                             aes(x = main_avg_retention_vs_slot, y = main_retention_consistency)) +
    geom_point(aes(color = day_type, size = main_broadcast_hours), alpha = 0.7) +
    geom_vline(xintercept = 0, linetype = "dashed", alpha = 0.5) +
    scale_color_manual(values = c("Weekday" = "blue", "Weekend" = "red")) +
    scale_size_continuous(range = c(2, 6), name = "Airtime Hours") +
    labs(title = "Audience Retention: Performance vs Variability",
         subtitle = "Top right = good, but variable, retention; Bottom right = good, consistent retention",
         x = "Average Retention vs Time Slot (%)", 
         y = "Retention Variability (Lower = More Consistent)",
         color = "Day Type") +
    theme_minimal() +
    guides(color = guide_legend(nrow = 1, byrow = TRUE),
           size = guide_legend(nrow = 1, byrow = TRUE)) +
    theme(legend.position = "bottom",
          legend.box = "vertical",
          legend.text = element_text(size = 8),
          legend.title = element_text(size = 9))
  
} else {
  main_retention_consistency_chart <- ggplot() + 
    labs(title = "No retention data available") + 
    theme_void()
}

cat("Retention analysis plots created!\n")
if (DEBUG_TO_CONSOLE == "Y") {
  if (exists("main_hourly_retention_patterns")) {
    cat("- Hourly patterns: ", nrow(main_hourly_retention_patterns), " hour-daytype combinations\n")
  }
  if (exists("main_show_retention_summary")) {
    cat("- Performance vs variability: ", nrow(main_show_retention_summary), " shows\n")
  }
}

# =============================================================================
# PART 5K: CREATE CONSISTENCY & RETENTION SUMMARY STATS
# =============================================================================
# Add this after the consistency and retention analyses are complete

cat("Creating consistency and retention summary statistics...\n")

# =============================================================================
# MAIN STATION CONSISTENCY SUMMARY STATS
# =============================================================================

if (exists("main_show_consistency") && nrow(main_show_consistency) > 0) {
  
  main_consistency_summary_stats <- list()
  
  # Basic statistics
  main_consistency_summary_stats$total_shows_analyzed <- nrow(main_show_consistency)
  main_consistency_summary_stats$total_sessions_analyzed <- sum(main_show_consistency$main_total_sessions, na.rm = TRUE)
  main_consistency_summary_stats$avg_consistency_score <- round(mean(main_show_consistency$main_consistency_score, na.rm = TRUE), 2)
  
  # Best and worst performers
  best_show <- main_show_consistency %>% 
    arrange(desc(main_consistency_score)) %>% 
    slice(1)
  
  worst_show <- main_show_consistency %>% 
    arrange(main_consistency_score) %>% 
    slice(1)
  
  main_consistency_summary_stats$most_consistent_show <- best_show$main_showname[1]
  main_consistency_summary_stats$best_consistency_score <- round(best_show$main_consistency_score[1], 2)
  main_consistency_summary_stats$least_consistent_show <- worst_show$main_showname[1]
  main_consistency_summary_stats$worst_consistency_score <- round(worst_show$main_consistency_score[1], 2)
  
  # Shows above average performance
  main_consistency_summary_stats$shows_above_avg_performance <- sum(main_show_consistency$main_avg_performance > 0, na.rm = TRUE)
  
  cat("Main station consistency summary stats created\n")
  
} else {
  main_consistency_summary_stats <- list(
    total_shows_analyzed = 0,
    total_sessions_analyzed = 0,
    avg_consistency_score = 0,
    most_consistent_show = "No data",
    best_consistency_score = 0,
    least_consistent_show = "No data", 
    worst_consistency_score = 0,
    shows_above_avg_performance = 0
  )
  cat("Main station consistency data not available\n")
}

# =============================================================================
# MAIN STATION RETENTION SUMMARY STATS
# =============================================================================

if (exists("main_show_retention_summary") && nrow(main_show_retention_summary) > 0) {
  
  main_retention_summary_stats <- list()
  
  # Basic statistics
  main_retention_summary_stats$total_shows_analyzed <- nrow(main_show_retention_summary)
  main_retention_summary_stats$total_broadcast_hours <- sum(main_show_retention_summary$main_broadcast_hours, na.rm = TRUE)
  main_retention_summary_stats$avg_retention_rate <- round(mean(main_show_retention_summary$main_avg_retention_rate, na.rm = TRUE), 1)
  
  # Best and worst retainers
  best_retainer <- main_show_retention_summary %>% 
    arrange(desc(main_avg_retention_vs_slot)) %>% 
    slice(1)
  
  worst_retainer <- main_show_retention_summary %>% 
    arrange(main_avg_retention_vs_slot) %>% 
    slice(1)
  
  main_retention_summary_stats$best_retainer <- best_retainer$main_showname[1]
  main_retention_summary_stats$best_retention_score <- round(best_retainer$main_avg_retention_vs_slot[1], 1)
  main_retention_summary_stats$worst_retainer <- worst_retainer$main_showname[1]
  main_retention_summary_stats$worst_retention_score <- round(worst_retainer$main_avg_retention_vs_slot[1], 1)
  
  cat("Main station retention summary stats created\n")
  
} else {
  main_retention_summary_stats <- list(
    total_shows_analyzed = 0,
    total_broadcast_hours = 0,
    avg_retention_rate = 0,
    best_retainer = "No data",
    best_retention_score = 0,
    worst_retainer = "No data",
    worst_retention_score = 0
  )
  cat("Main station retention data not available\n")
}

# =============================================================================
# PART 5L: SECOND STATION (IF ENABLED)
# =============================================================================

if (ANALYSE_SECOND_STATION == "Y") {
  
  # Calculate within-episode retention for each individual episode
  second_episode_retention_raw <- data %>%
    # Group by individual episodes (same show on same date/hour)
    group_by(date, hour, second_showname, second_presenter, second_stand_in, day_type) %>%
    arrange(datetime) %>%
    # Only analyze "complete" episodes with sufficient data points
    filter(n() >= 8) %>%  # At least 8 data points (40 minutes if 5-min intervals)
    filter(second_stand_in != 1) %>%  # Exclude sitting-in presenters
    summarise(
      second_episode_start = first(second_total_listeners),  # Start of episode
      second_episode_end = last(second_total_listeners),     # End of episode  
      second_episode_peak = max(second_total_listeners, na.rm = TRUE),    # Peak during episode
      second_episode_min = min(second_total_listeners, na.rm = TRUE),     # Lowest point
      second_episode_avg = mean(second_total_listeners, na.rm = TRUE),    # Average during episode
      second_data_points = n(),
      second_duration_minutes = second_data_points * DATA_COLLECTION,  # Actual episode duration
      .groups = 'drop'
    ) %>%
    filter(second_episode_start > 0) %>%  # Avoid division by zero
    mutate(
      # Calculate retention metrics
      second_retention_rate = ((second_episode_end - second_episode_start) / second_episode_start) * 100,
      second_peak_gain = ((second_episode_peak - second_episode_start) / second_episode_start) * 100,
      second_worst_drop = ((second_episode_min - second_episode_start) / second_episode_start) * 100,
      second_volatility = second_episode_peak - second_episode_min
    )
  
  # Calculate hourly baselines to compare retention against
  second_retention_hourly_baseline <- second_episode_retention_raw %>%
    group_by(hour, day_type) %>%
    summarise(
      second_slot_avg_retention = mean(second_retention_rate, na.rm = TRUE),
      second_slot_avg_peak_gain = mean(second_peak_gain, na.rm = TRUE),
      second_slot_avg_volatility = mean(second_volatility, na.rm = TRUE),
      second_episodes_in_slot = n(),
      .groups = 'drop'
    )
  
  # Compare each episode's retention to its time slot average
  second_episode_retention_performance <- second_episode_retention_raw %>%
    left_join(second_retention_hourly_baseline, by = c("hour", "day_type")) %>%
    mutate(
      second_retention_vs_slot = second_retention_rate - second_slot_avg_retention,
      second_peak_gain_vs_slot = second_peak_gain - second_slot_avg_peak_gain,
      second_volatility_vs_slot = second_volatility - second_slot_avg_volatility
    )
  
  # Summarize retention performance by show across all episodes
  second_show_retention_summary <- second_episode_retention_performance %>%
    filter(!is.na(second_showname), second_showname != "", second_showname != "Unknown") %>%
    # Filter out excluded show types
    filter(!grepl(paste(EXCLUDE_TERMS, collapse = "|"), second_showname, ignore.case = TRUE)) %>%
    filter(second_stand_in != 1) %>%
    group_by(second_showname, day_type) %>%
    summarise(
      second_broadcast_hours = n(),  # Number of episodes analyzed
      second_avg_retention_rate = mean(second_retention_rate, na.rm = TRUE),
      second_avg_retention_vs_slot = mean(second_retention_vs_slot, na.rm = TRUE),
      second_retention_consistency = sd(second_retention_rate, na.rm = TRUE),  # How consistent is retention?
      second_avg_peak_gain = mean(second_peak_gain, na.rm = TRUE),
      second_avg_volatility = mean(second_volatility, na.rm = TRUE),
      second_best_retention = max(second_retention_rate, na.rm = TRUE),
      second_worst_retention = min(second_retention_rate, na.rm = TRUE),
      .groups = 'drop'
    ) %>%
    filter(second_broadcast_hours >= 2) %>%  # Need at least 2 episodes for reliable analysis
    arrange(day_type, desc(second_avg_retention_vs_slot))
  
  if (nrow(second_show_retention_summary) > 0) {
    
    # Calculate percentile thresholds for retention performance
    retention_thresholds <- list(
      excellent = quantile(second_show_retention_summary$second_avg_retention_vs_slot, 0.85, na.rm = TRUE),  # Top 15%
      good = quantile(second_show_retention_summary$second_avg_retention_vs_slot, 0.65, na.rm = TRUE),       # Top 35%
      average = quantile(second_show_retention_summary$second_avg_retention_vs_slot, 0.15, na.rm = TRUE)     # Bottom 15%
      # Poor = below 15th percentile
    )
    
    # Calculate percentile thresholds for retention consistency (using retention_consistency SD)
    retention_consistency_thresholds <- list(
      very_consistent = quantile(second_show_retention_summary$second_retention_consistency, 0.25, na.rm = TRUE),
      consistent = quantile(second_show_retention_summary$second_retention_consistency, 0.50, na.rm = TRUE),
      variable = quantile(second_show_retention_summary$second_retention_consistency, 0.75, na.rm = TRUE)
    )
    
    # Add retention categories
    second_show_retention_summary <- second_show_retention_summary %>%
      mutate(
        second_retention_grade = case_when(
          second_avg_retention_vs_slot > retention_thresholds$excellent ~ "Excellent Retention",
          second_avg_retention_vs_slot > retention_thresholds$good ~ "Good Retention",
          second_avg_retention_vs_slot > retention_thresholds$average ~ "Average Retention",
          TRUE ~ "Poor Retention"
        ),
        second_retention_consistency_grade = case_when(
          is.na(second_retention_consistency) | second_retention_consistency <= retention_consistency_thresholds$very_consistent ~ "Very Consistent",
          second_retention_consistency <= retention_consistency_thresholds$consistent ~ "Consistent",
          second_retention_consistency <= retention_consistency_thresholds$variable ~ "Variable",
          TRUE ~ "Highly Variable"
        )
      )
  }

  if (nrow(second_show_retention_summary) > 0) {
    
    # Weekday retention data (for charts)
    second_weekday_retention <- second_show_retention_summary %>%
      filter(day_type == "Weekday") %>%
      arrange(desc(second_avg_retention_vs_slot)) %>%
      head(25) %>%  # Top 25 for chart readability
      mutate(second_showname_factor = factor(second_showname, levels = rev(second_showname)))
    
    # Weekend retention data (for charts)
    second_weekend_retention <- second_show_retention_summary %>%
      filter(day_type == "Weekend") %>%
      arrange(desc(second_avg_retention_vs_slot)) %>%
      head(25) %>%
      mutate(second_showname_factor = factor(second_showname, levels = rev(second_showname)))
    
    # Calculate summary statistics
    second_retention_summary_stats <- list(
      second_total_shows_analyzed = nrow(second_show_retention_summary),
      second_total_episodes_analyzed = sum(second_show_retention_summary$second_broadcast_hours),
      second_avg_retention_rate = round(mean(second_show_retention_summary$second_avg_retention_rate, na.rm = TRUE), 1),
      second_avg_retention_vs_slot = round(mean(second_show_retention_summary$second_avg_retention_vs_slot, na.rm = TRUE), 1),
      second_best_retainer = second_show_retention_summary %>% 
        filter(second_avg_retention_vs_slot == max(second_avg_retention_vs_slot, na.rm = TRUE)) %>% 
        slice(1) %>% 
        pull(second_showname),
      second_best_retention_score = round(max(second_show_retention_summary$second_avg_retention_vs_slot, na.rm = TRUE), 1),
      second_worst_retainer = second_show_retention_summary %>% 
        filter(second_avg_retention_vs_slot == min(second_avg_retention_vs_slot, na.rm = TRUE)) %>% 
        slice(1) %>% 
        pull(second_showname),
      second_worst_retention_score = round(min(second_show_retention_summary$second_avg_retention_vs_slot, na.rm = TRUE), 1)
    )
    
  } else {
    second_retention_summary_stats <- list(
      second_total_shows_analyzed = 0,
      second_total_episodes_analyzed = 0,
      second_avg_retention_rate = 0,
      second_avg_retention_vs_slot = 0,
      second_best_retainer = "No data",
      second_best_retention_score = 0,
      second_worst_retainer = "No data",
      second_worst_retention_score = 0
    )
  }

  # Create retention heatmap data for shows that broadcast in multiple hours
  if (exists("second_episode_retention_performance") && nrow(second_episode_retention_performance) > 0) {
    
    second_retention_heatmap_data <- second_episode_retention_performance %>%
      filter(!is.na(second_showname), second_showname != "", second_showname != "Unknown") %>%
      filter(!grepl(paste(EXCLUDE_TERMS, collapse = "|"), second_showname, ignore.case = TRUE)) %>%
      filter(second_stand_in != 1) %>%
      # Group by show+hour+day_type to get average retention for each time slot
      group_by(second_showname, second_presenter, hour, day_type) %>%
      summarise(
        second_avg_retention_vs_slot = mean(second_retention_vs_slot, na.rm = TRUE),
        second_episodes = n(),
        .groups = 'drop'
      ) %>%
      filter(second_episodes >= 1) %>%  # Even single episodes for hourly patterns
      # Only include shows that appear in multiple hours (for meaningful heatmap)
      group_by(second_showname, second_presenter, day_type) %>%
      filter(n() > 1) %>%  # Must broadcast in multiple different hours
      ungroup() %>%
      # Order shows by their average retention performance for better visualization
      group_by(second_showname, second_presenter, day_type) %>%
      mutate(show_avg_retention = mean(second_avg_retention_vs_slot, na.rm = TRUE)) %>%
      ungroup()
    
    # Create weekday retention heatmap
    second_weekday_retention_heatmap_data <- second_retention_heatmap_data %>% 
      filter(day_type == "Weekday")
    
    if (nrow(second_weekday_retention_heatmap_data) > 0) {
      # Order shows by average retention performance
      second_weekday_retention_heatmap_data <- second_weekday_retention_heatmap_data %>%
        arrange(desc(hour), second_showname) %>%
        mutate(
          show_label = paste(second_showname),
          show_factor = factor(show_label, levels = unique(show_label))
        )
      
      second_weekday_retention_heatmap <- ggplot(second_weekday_retention_heatmap_data, 
                                               aes(x = hour, y = show_factor, fill = second_avg_retention_vs_slot)) +
        geom_tile(color = "grey60", linewidth = 0.1) +
        scale_fill_gradient2(low = "red", mid = "white", high = "blue", midpoint = 0,
                             name = "Retention\nvs Slot Avg") +
        labs(title = "Weekday Shows: Retention Performance by Hour",
             subtitle = "Shows that broadcast in multiple weekday time slots",
             x = "Hour", y = "") +
        theme_minimal() +
        theme(axis.text.y = element_text(size = 8),
              legend.title = element_text(size = 9)) +
        scale_x_continuous(breaks = seq(0, 23, 4))
    } else {
      second_weekday_retention_heatmap <- ggplot() + 
        labs(title = "No weekday multi-hour show data available") + 
        theme_void()
    }
    
    # Create weekend retention heatmap  
    second_weekend_retention_heatmap_data <- second_retention_heatmap_data %>% 
      filter(day_type == "Weekend")
    
    if (nrow(second_weekend_retention_heatmap_data) > 0) {
      # Order shows by average retention performance
      second_weekend_retention_heatmap_data <- second_weekend_retention_heatmap_data %>%
        arrange(desc(hour), second_showname) %>%
        mutate(
          show_label = paste(second_showname),
          show_factor = factor(show_label, levels = unique(show_label))
        )
      
      second_weekend_retention_heatmap <- ggplot(second_weekend_retention_heatmap_data, 
                                               aes(x = hour, y = show_factor, fill = second_avg_retention_vs_slot)) +
        geom_tile(color = "grey60", linewidth = 0.1) +
        scale_fill_gradient2(low = "red", mid = "white", high = "blue", midpoint = 0,
                             name = "Retention\nvs Slot Avg") +
        labs(title = "Weekend Shows: Retention Performance by Hour",
             subtitle = "Shows that broadcast in multiple weekend time slots",
             x = "Hour", y = "") +
        theme_minimal() +
        theme(axis.text.y = element_text(size = 8),
              legend.title = element_text(size = 9)) +
        scale_x_continuous(breaks = seq(0, 23, 4))
    } else {
      second_weekend_retention_heatmap <- ggplot() + 
        labs(title = "No weekend multi-hour show data available") + 
        theme_void()
    }
    
    cat("Retention heatmaps created!\n")
    if (DEBUG_TO_CONSOLE == "Y") {
      cat("- Weekday heatmap shows:", nrow(second_weekday_retention_heatmap_data), "show-hour combinations\n")
      cat("- Weekend heatmap shows:", nrow(second_weekend_retention_heatmap_data), "show-hour combinations\n")
    }
    
  } else {
    # Create empty plots if no retention data exists
    second_weekday_retention_heatmap <- ggplot() + 
      labs(title = "Retention data not available") + 
      theme_void()
    second_weekend_retention_heatmap <- ggplot() + 
      labs(title = "Retention data not available") + 
      theme_void()
  }
  
  # Create enhanced retention tables with percentile-based grades
  if (exists("second_show_retention_summary") && nrow(second_show_retention_summary) > 0) {
    
    # Calculate data-driven thresholds for retention performance
    # These thresholds are calculated from ALL shows (weekday + weekend) for consistency
    second_retention_thresholds <- list(
      excellent = quantile(second_show_retention_summary$second_avg_retention_vs_slot, 0.85, na.rm = TRUE),  # Top 15%
      good = quantile(second_show_retention_summary$second_avg_retention_vs_slot, 0.65, na.rm = TRUE),       # Top 35% 
      average = quantile(second_show_retention_summary$second_avg_retention_vs_slot, 0.35, na.rm = TRUE)     # Bottom 35%
      # Poor = below 35th percentile
    )
    
    # Calculate data-driven thresholds for consistency (lower standard deviation = more consistent)
    second_consistency_thresholds <- list(
      very_consistent = quantile(second_show_retention_summary$second_retention_consistency, 0.25, na.rm = TRUE),  # Top 25%
      consistent = quantile(second_show_retention_summary$second_retention_consistency, 0.5, na.rm = TRUE),        # Top 50%
      variable = quantile(second_show_retention_summary$second_retention_consistency, 0.75, na.rm = TRUE)          # Top 75%
      # Highly Variable = above 75th percentile
    )
    
    cat("Retention performance thresholds calculated:\n")
    cat("- Excellent retention: >", round(second_retention_thresholds$excellent, 1), "% vs slot avg\n")
    cat("- Good retention: >", round(second_retention_thresholds$good, 1), "% vs slot avg\n")
    cat("- Average retention:", round(second_retention_thresholds$average, 1), "% to", round(second_retention_thresholds$good, 1), "% vs slot avg\n")
    cat("- Poor retention: <", round(second_retention_thresholds$average, 1), "% vs slot avg\n")
    
  } else {
    cat("Warning: second_show_retention_summary not available for threshold calculation\n")
    # Create default thresholds
    second_retention_thresholds <- list(excellent = 2, good = 0, average = -2)
    second_consistency_thresholds <- list(very_consistent = 2, consistent = 4, variable = 6)
  }
  
  #Weekdays Retention Performace Table
  create_weekday_retention_table <- function() {
    if (exists("second_show_retention_summary") && nrow(second_show_retention_summary) > 0) {
      
      # Filter for weekday shows
      second_weekday_retention_data <- second_show_retention_summary %>%
        filter(day_type == "Weekday") %>%
        filter(!grepl(paste(EXCLUDE_TERMS, collapse = "|"), second_showname, ignore.case = TRUE))
      # filter(second_stand_in != 1)
      
      if (nrow(second_weekday_retention_data) > 0) {
        
        # Create the enhanced table with grades
        second_weekday_retention_table <- second_weekday_retention_data %>%
          mutate(
            # Retention level based on performance vs slot average
            second_retention_grade = case_when(
              second_avg_retention_vs_slot >= second_retention_thresholds$excellent ~ "Excellent",
              second_avg_retention_vs_slot >= second_retention_thresholds$good ~ "Good", 
              second_avg_retention_vs_slot >= second_retention_thresholds$average ~ "Average",
              TRUE ~ "Poor"
            ),
            # Consistency grade based on standard deviation (lower = better)
            second_consistency_grade = case_when(
              second_retention_consistency <= second_consistency_thresholds$very_consistent ~ "Very&nbsp;Consistent",
              second_retention_consistency <= second_consistency_thresholds$consistent ~ "Consistent",
              second_retention_consistency <= second_consistency_thresholds$variable ~ "Variable", 
              TRUE ~ "Highly&nbsp;Variable"
            )
          ) %>%
          arrange(desc(second_avg_retention_vs_slot)) %>%
          mutate(
            second_avg_retention_vs_slot = round(second_avg_retention_vs_slot, 1),
            second_avg_retention_rate = round(second_avg_retention_rate, 1),
            second_retention_consistency = round(second_retention_consistency, 1)
          ) %>%
          select(second_showname, second_broadcast_hours, second_avg_retention_rate, 
                 second_avg_retention_vs_slot, second_retention_grade, second_consistency_grade)
        
        return(second_weekday_retention_table)
      }
    }
    return(data.frame())
  }
  
  #Weekend Retention Performance Table
  create_weekend_retention_table <- function() {
    if (exists("second_show_retention_summary") && nrow(second_show_retention_summary) > 0) {
      
      # Filter for weekend shows
      second_weekend_retention_data <- second_show_retention_summary %>%
        filter(day_type == "Weekend") %>%
        filter(!grepl(paste(EXCLUDE_TERMS, collapse = "|"), second_showname, ignore.case = TRUE))
      # filter(second_stand_in != 1)
      
      if (nrow(second_weekend_retention_data) > 0) {
        
        # Create the enhanced table with grades (using same thresholds as weekday)
        second_weekend_retention_table <- second_weekend_retention_data %>%
          mutate(
            # Retention level based on performance vs slot average
            second_retention_grade = case_when(
              second_avg_retention_vs_slot >= second_retention_thresholds$excellent ~ "Excellent",
              second_avg_retention_vs_slot >= second_retention_thresholds$good ~ "Good", 
              second_avg_retention_vs_slot >= second_retention_thresholds$average ~ "Average",
              TRUE ~ "Poor"
            ),
            # Consistency grade based on standard deviation (lower = better)
            second_consistency_grade = case_when(
              second_retention_consistency <= second_consistency_thresholds$very_consistent ~ "Very&nbsp;Consistent",
              second_retention_consistency <= second_consistency_thresholds$consistent ~ "Consistent",
              second_retention_consistency <= second_consistency_thresholds$variable ~ "Variable", 
              TRUE ~ "Highly&nbsp;Variable"
            )
          ) %>%
          arrange(desc(second_avg_retention_vs_slot)) %>%
          mutate(
            second_avg_retention_vs_slot = round(second_avg_retention_vs_slot, 1),
            second_avg_retention_rate = round(second_avg_retention_rate, 1),
            second_retention_consistency = round(second_retention_consistency, 1)
          ) %>%
          select(second_showname, second_broadcast_hours, second_avg_retention_rate, 
                 second_avg_retention_vs_slot, second_retention_grade, second_consistency_grade)
        
        return(second_weekend_retention_table)
      }
    }
    return(data.frame())
  }
  
  # Create the tables
  second_weekday_retention_table <- create_weekday_retention_table()
  second_weekend_retention_table <- create_weekend_retention_table()
  
  cat("Retention performance tables created!\n")
  if (DEBUG_TO_CONSOLE == "Y") {
    cat("- Weekday retention table: ", nrow(second_weekday_retention_table), " shows\n")
    cat("- Weekend retention table: ", nrow(second_weekend_retention_table), " shows\n")
  }

  # Calculate hourly retention patterns across the day
  if (exists("second_episode_retention_performance") && nrow(second_episode_retention_performance) > 0) {
    
    second_hourly_retention_patterns <- second_episode_retention_performance %>%
      group_by(hour, day_type) %>%
      summarise(
        second_avg_retention = mean(second_retention_rate, na.rm = TRUE),
        second_avg_peak_gain = mean(second_peak_gain, na.rm = TRUE),
        second_episodes = n(),
        .groups = 'drop'
      ) %>%
      filter(second_episodes >= 2)  # Need at least 2 episodes per hour for meaningful average
    
    # Create the hourly retention patterns chart
    if (nrow(second_hourly_retention_patterns) > 0) {
      second_hourly_retention_chart <- ggplot(second_hourly_retention_patterns, 
                                            aes(x = hour, y = second_avg_retention, color = day_type)) +
        geom_line(linewidth = 1.2) +
        geom_point(size = 2) +
        geom_hline(yintercept = 0, linetype = "dashed", alpha = 0.5) +
        scale_color_manual(values = c("Weekday" = "blue", "Weekend" = "red")) +
        labs(title = "Hourly Audience Retention Patterns",
             subtitle = "Average audience gain/loss during episodes by time of day",
             x = "Hour", y = "Average Retention Rate (%)",
             color = "Day Type") +
        theme_minimal() +
        theme(legend.position = "bottom") +
        scale_x_continuous(breaks = seq(0, 23, 4))
    } else {
      second_hourly_retention_chart <- ggplot() + 
        labs(title = "No hourly retention data available") + 
        theme_void()
    }
    
  } else {
    second_hourly_retention_chart <- ggplot() + 
      labs(title = "Retention data not available") + 
      theme_void()
  }
  
  # Create the retention performance vs variability scatter plot
  if (exists("second_show_retention_summary") && nrow(second_show_retention_summary) > 0) {
    
    second_retention_consistency_chart <- ggplot(second_show_retention_summary, 
                                               aes(x = second_avg_retention_vs_slot, y = second_retention_consistency)) +
      geom_point(aes(color = day_type, size = second_broadcast_hours), alpha = 0.7) +
      geom_vline(xintercept = 0, linetype = "dashed", alpha = 0.5) +
      scale_color_manual(values = c("Weekday" = "blue", "Weekend" = "red")) +
      scale_size_continuous(range = c(2, 6), name = "Airtime Hours") +
      labs(title = "Audience Retention: Performance vs Variability",
           subtitle = "Top right = good, but variable, retention; Bottom right = good, consistent retention",
           x = "Average Retention vs Time Slot (%)", 
           y = "Retention Variability (Lower = More Consistent)",
           color = "Day Type") +
      theme_minimal() +
      guides(color = guide_legend(nrow = 1, byrow = TRUE),
             size = guide_legend(nrow = 1, byrow = TRUE)) +
      theme(legend.position = "bottom",
            legend.box = "vertical",
            legend.text = element_text(size = 8),
            legend.title = element_text(size = 9))
    
  } else {
    second_retention_consistency_chart <- ggplot() + 
      labs(title = "No retention data available") + 
      theme_void()
  }
  
  cat("Retention analysis plots created!\n")
  if (DEBUG_TO_CONSOLE == "Y") {
    if (exists("second_hourly_retention_patterns")) {
      cat("- Hourly patterns: ", nrow(second_hourly_retention_patterns), " hour-daytype combinations\n")
    }
    if (exists("second_show_retention_summary")) {
      cat("- Performance vs variability: ", nrow(second_show_retention_summary), " shows\n")
    }
  }
  
  cat("Creating consistency and retention summary statistics...\n")

  if (exists("second_show_consistency") && nrow(second_show_consistency) > 0) {
    
    second_consistency_summary_stats <- list()
    
    # Basic statistics
    second_consistency_summary_stats$total_shows_analyzed <- nrow(second_show_consistency)
    second_consistency_summary_stats$total_sessions_analyzed <- sum(second_show_consistency$second_total_sessions, na.rm = TRUE)
    second_consistency_summary_stats$avg_consistency_score <- round(mean(second_show_consistency$second_consistency_score, na.rm = TRUE), 2)
    
    # Best and worst performers
    best_show <- second_show_consistency %>% 
      arrange(desc(second_consistency_score)) %>% 
      slice(1)
    
    worst_show <- second_show_consistency %>% 
      arrange(second_consistency_score) %>% 
      slice(1)
    
    second_consistency_summary_stats$most_consistent_show <- best_show$second_showname[1]
    second_consistency_summary_stats$best_consistency_score <- round(best_show$second_consistency_score[1], 2)
    second_consistency_summary_stats$least_consistent_show <- worst_show$second_showname[1]
    second_consistency_summary_stats$worst_consistency_score <- round(worst_show$second_consistency_score[1], 2)
    
    # Shows above average performance
    second_consistency_summary_stats$shows_above_avg_performance <- sum(second_show_consistency$second_avg_performance > 0, na.rm = TRUE)
    
    cat("Second station consistency summary stats created\n")
    
  } else {
    second_consistency_summary_stats <- list(
      total_shows_analyzed = 0,
      total_sessions_analyzed = 0,
      avg_consistency_score = 0,
      most_consistent_show = "No data",
      best_consistency_score = 0,
      least_consistent_show = "No data", 
      worst_consistency_score = 0,
      shows_above_avg_performance = 0
    )
    cat("Second station consistency data not available\n")
  }

  if (exists("second_show_retention_summary") && nrow(second_show_retention_summary) > 0) {
    
    second_retention_summary_stats <- list()
    
    # Basic statistics
    second_retention_summary_stats$total_shows_analyzed <- nrow(second_show_retention_summary)
    second_retention_summary_stats$total_broadcast_hours <- sum(second_show_retention_summary$second_broadcast_hours, na.rm = TRUE)
    second_retention_summary_stats$avg_retention_rate <- round(mean(second_show_retention_summary$second_avg_retention_rate, na.rm = TRUE), 1)
    
    # Best and worst retainers
    best_retainer <- second_show_retention_summary %>% 
      arrange(desc(second_avg_retention_vs_slot)) %>% 
      slice(1)
    
    worst_retainer <- second_show_retention_summary %>% 
      arrange(second_avg_retention_vs_slot) %>% 
      slice(1)
    
    second_retention_summary_stats$best_retainer <- best_retainer$second_showname[1]
    second_retention_summary_stats$best_retention_score <- round(best_retainer$second_avg_retention_vs_slot[1], 1)
    second_retention_summary_stats$worst_retainer <- worst_retainer$second_showname[1]
    second_retention_summary_stats$worst_retention_score <- round(worst_retainer$second_avg_retention_vs_slot[1], 1)
    
    cat("Second station retention summary stats created\n")
    
  } else {
    second_retention_summary_stats <- list(
      total_shows_analyzed = 0,
      total_broadcast_hours = 0,
      avg_retention_rate = 0,
      best_retainer = "No data",
      best_retention_score = 0,
      worst_retainer = "No data",
      worst_retention_score = 0
    )
    cat("Second station retention data not available\n")
  }
  
}

# =============================================================================
# PART 5M: COMPARISON STATION (IF ENABLED)
# =============================================================================

if (ANALYSE_COMPARISON_STATION == "Y") {
  
  # Comparison station episode retention (same logic as main station)
  comparison_episode_retention_raw <- data %>%
    group_by(date, hour, comparison_showname, comparison_stand_in, day_type) %>%
    arrange(datetime) %>%
    filter(n() >= 8) %>%
    filter(comparison_stand_in != 1) %>%
    summarise(
      comparison_episode_start = first(comparison_total_listeners),
      comparison_episode_end = last(comparison_total_listeners),
      comparison_episode_peak = max(comparison_total_listeners, na.rm = TRUE),
      comparison_episode_min = min(comparison_total_listeners, na.rm = TRUE),
      comparison_episode_avg = mean(comparison_total_listeners, na.rm = TRUE),
      comparison_data_points = n(),
      comparison_duration_minutes = comparison_data_points * DATA_COLLECTION,
      .groups = 'drop'
    ) %>%
    filter(comparison_episode_start > 0) %>%
    mutate(
      comparison_retention_rate = ((comparison_episode_end - comparison_episode_start) / comparison_episode_start) * 100,
      comparison_peak_gain = ((comparison_episode_peak - comparison_episode_start) / comparison_episode_start) * 100,
      comparison_worst_drop = ((comparison_episode_min - comparison_episode_start) / comparison_episode_start) * 100,
      comparison_volatility = comparison_episode_peak - comparison_episode_min
    )

  # Calculate hourly baselines to compare retention against
  comparison_retention_hourly_baseline <- comparison_episode_retention_raw %>%
    group_by(hour, day_type) %>%
    summarise(
      comparison_slot_avg_retention = mean(comparison_retention_rate, na.rm = TRUE),
      comparison_slot_avg_peak_gain = mean(comparison_peak_gain, na.rm = TRUE),
      comparison_slot_avg_volatility = mean(comparison_volatility, na.rm = TRUE),
      comparison_episodes_in_slot = n(),
      .groups = 'drop'
    )
  
  # Compare each episode's retention to its time slot average
  comparison_episode_retention_performance <- comparison_episode_retention_raw %>%
    left_join(comparison_retention_hourly_baseline, by = c("hour", "day_type")) %>%
    mutate(
      comparison_retention_vs_slot = comparison_retention_rate - comparison_slot_avg_retention,
      comparison_peak_gain_vs_slot = comparison_peak_gain - comparison_slot_avg_peak_gain,
      comparison_volatility_vs_slot = comparison_volatility - comparison_slot_avg_volatility
    )
  
  # Summarize retention performance by show across all episodes
  comparison_show_retention_summary <- comparison_episode_retention_performance %>%
    filter(!is.na(comparison_showname), comparison_showname != "", comparison_showname != "Unknown") %>%
    # Filter out excluded show types
    filter(!grepl(paste(EXCLUDE_TERMS, collapse = "|"), comparison_showname, ignore.case = TRUE)) %>%
    filter(comparison_stand_in != 1) %>%
    group_by(comparison_showname, day_type) %>%
    summarise(
      comparison_broadcast_hours = n(),  # Number of episodes analyzed
      comparison_avg_retention_rate = mean(comparison_retention_rate, na.rm = TRUE),
      comparison_avg_retention_vs_slot = mean(comparison_retention_vs_slot, na.rm = TRUE),
      comparison_retention_consistency = sd(comparison_retention_rate, na.rm = TRUE),  # How consistent is retention?
      comparison_avg_peak_gain = mean(comparison_peak_gain, na.rm = TRUE),
      comparison_avg_volatility = mean(comparison_volatility, na.rm = TRUE),
      .groups = 'drop'
    ) %>%
    filter(comparison_broadcast_hours >= 2) %>%  # Need at least 2 episodes for meaningful analysis
    arrange(desc(comparison_avg_retention_vs_slot))
  
  # Calculate summary statistics for comparison station retention
  if (exists("comparison_show_retention_summary") && nrow(comparison_show_retention_summary) > 0) {
    comparison_retention_summary_stats <- list(
      comparison_total_shows_analyzed = nrow(comparison_show_retention_summary),
      comparison_total_episodes_analyzed = sum(comparison_show_retention_summary$comparison_broadcast_hours),
      comparison_avg_retention_rate = round(mean(comparison_show_retention_summary$comparison_avg_retention_rate, na.rm = TRUE), 1),
      comparison_best_retainer = comparison_show_retention_summary$comparison_showname[which.max(comparison_show_retention_summary$comparison_avg_retention_vs_slot)],
      comparison_best_retention_score = round(max(comparison_show_retention_summary$comparison_avg_retention_vs_slot, na.rm = TRUE), 1),
      comparison_worst_retainer = comparison_show_retention_summary$comparison_showname[which.min(comparison_show_retention_summary$comparison_avg_retention_vs_slot)],
      comparison_worst_retention_score = round(min(comparison_show_retention_summary$comparison_avg_retention_vs_slot, na.rm = TRUE), 1)
    )
  } else {
    comparison_retention_summary_stats <- list(
      comparison_total_shows_analyzed = 0,
      comparison_total_episodes_analyzed = 0,
      comparison_avg_retention_rate = 0,
      comparison_best_retainer = "No data",
      comparison_best_retention_score = 0,
      comparison_worst_retainer = "No data",
      comparison_worst_retention_score = 0
    )
  }
  
  # Calculate hourly retention patterns across the day
  if (exists("comparison_episode_retention_performance") && nrow(comparison_episode_retention_performance) > 0) {
    
    comparison_hourly_retention_patterns <- comparison_episode_retention_performance %>%
      group_by(hour, day_type) %>%
      summarise(
        comparison_avg_retention = mean(comparison_retention_rate, na.rm = TRUE),
        comparison_avg_peak_gain = mean(comparison_peak_gain, na.rm = TRUE),
        comparison_episodes = n(),
        .groups = 'drop'
      ) %>%
      filter(comparison_episodes >= 2)  # Need at least 2 episodes per hour for meaningful average
    
    # Create the hourly retention patterns chart
    if (nrow(comparison_hourly_retention_patterns) > 0) {
      comparison_hourly_retention_chart <- ggplot(comparison_hourly_retention_patterns, 
                                                  aes(x = hour, y = comparison_avg_retention, color = day_type)) +
        geom_line(linewidth = 1.2) +
        geom_point(size = 2) +
        geom_hline(yintercept = 0, linetype = "dashed", alpha = 0.5) +
        scale_color_manual(values = c("Weekday" = "blue", "Weekend" = "red")) +
        labs(title = paste("Comparison Station: Hourly Audience Retention Patterns"),
             subtitle = "Average audience gain/loss during episodes by time of day",
             x = "Hour", y = "Average Retention Rate (%)",
             color = "Day Type") +
        theme_minimal() +
        theme(legend.position = "bottom") +
        scale_x_continuous(breaks = seq(0, 23, 4))
    } else {
      comparison_hourly_retention_chart <- ggplot() + 
        labs(title = "No hourly retention data available") + 
        theme_void()
    }
    
  } else {
    comparison_hourly_retention_chart <- ggplot() + 
      labs(title = "Retention data not available") + 
      theme_void()
  }
  
  # Create the retention performance vs variability scatter plot
  if (exists("comparison_show_retention_summary") && nrow(comparison_show_retention_summary) > 0) {
    
    comparison_retention_consistency_chart <- ggplot(comparison_show_retention_summary, 
                                                     aes(x = comparison_avg_retention_vs_slot, y = comparison_retention_consistency)) +
      geom_point(aes(color = day_type, size = comparison_broadcast_hours), alpha = 0.7) +
      geom_vline(xintercept = 0, linetype = "dashed", alpha = 0.5) +
      scale_color_manual(values = c("Weekday" = "blue", "Weekend" = "red")) +
      scale_size_continuous(range = c(2, 6), name = "Airtime Hours") +
      labs(title = paste("Comparison Station: Audience Retention Performance vs Variability"),
           subtitle = "Top right = good, but variable, retention; Bottom right = good, consistent retention",
           x = "Average Retention vs Time Slot (%)", 
           y = "Retention Variability (Lower = More Consistent)",
           color = "Day Type") +
      theme_minimal() +
      guides(color = guide_legend(nrow = 1, byrow = TRUE),
             size = guide_legend(nrow = 1, byrow = TRUE)) +
      theme(legend.position = "bottom",
            legend.box = "vertical",
            legend.text = element_text(size = 8),
            legend.title = element_text(size = 9))
    
  } else {
    comparison_retention_consistency_chart <- ggplot() + 
      labs(title = "No retention data available") + 
      theme_void()
  }
  
  cat("Comparison station retention analysis completed!\n")
  if (DEBUG_TO_CONSOLE == "Y") {
    cat("Comparison station retention:\n")
    cat("  - Shows analyzed:", comparison_retention_summary_stats$comparison_total_shows_analyzed, "\n")
    cat("  - Episodes analyzed:", comparison_retention_summary_stats$comparison_total_episodes_analyzed, "\n")
    cat("  - Average retention rate:", comparison_retention_summary_stats$comparison_avg_retention_rate, "%\n")
    cat("  - Best retainer:", comparison_retention_summary_stats$comparison_best_retainer, 
        "(", comparison_retention_summary_stats$comparison_best_retention_score, "% vs slot)\n")
    cat("  - Worst retainer:", comparison_retention_summary_stats$comparison_worst_retainer, 
        "(", comparison_retention_summary_stats$comparison_worst_retention_score, "% vs slot)\n")
  }
}

# =============================================================================
# ANALYSIS 5 COMPLETE
# =============================================================================

cat("Analysis 5 complete! Created audience retention analysis:\n")

if (DEBUG_TO_CONSOLE == "Y") {
  cat("Retention thresholds (% vs slot average):\n")
  if (exists("retention_thresholds")) {
    cat("  - Excellent Retention: >", round(retention_thresholds$excellent, 1), "% (top 15%)\n")
    cat("  - Good Retention: >", round(retention_thresholds$good, 1), "% (top 35%)\n")
    cat("  - Average Retention: >", round(retention_thresholds$average, 1), "%\n")
    cat("  - Poor Retention: ≤", round(retention_thresholds$average, 1), "% (bottom 15%)\n")
  }
  
  cat("\nMain station retention analysis:\n")
  if (exists("main_show_retention_summary") && nrow(main_show_retention_summary) > 0) {
    cat("  - Shows analyzed:", main_retention_summary_stats$main_total_shows_analyzed, "\n")
    cat("  - Episodes analyzed:", main_retention_summary_stats$main_total_episodes_analyzed, "\n")
    cat("  - Average retention rate:", main_retention_summary_stats$main_avg_retention_rate, "%\n")
    cat("  - Best retainer:", main_retention_summary_stats$main_best_retainer, 
        "(", main_retention_summary_stats$main_best_retention_score, "% vs slot)\n")
    cat("  - Worst retainer:", main_retention_summary_stats$main_worst_retainer, 
        "(", main_retention_summary_stats$main_worst_retention_score, "% vs slot)\n")
    
    # Show retention grade distribution
    if (exists("main_show_retention_summary")) {
      retention_dist <- table(main_show_retention_summary$main_retention_grade)
      cat("  - Retention grade distribution:\n")
      for (grade_name in names(retention_dist)) {
        cat("    *", grade_name, ":", retention_dist[grade_name], "shows\n")
      }
    }
  } else {
    cat("  - No retention data (need episodes with >=8 data points)\n")
  }
}


# =============================================================================
# ANALYSIS 6: DJ/GENRE ANALYSIS
# =============================================================================
# This analysis examines DJ genre preferences, diversity, and links to retention
# Creates the "Genre Strategy vs Retention Performance" table
# Completely separate from previous analyses

cat("Running Analysis 6: DJ/Genre Analysis...\n")

# =============================================================================
# PART 6A: CALCULATE STATION GENRE DISTRIBUTION BASELINE
# =============================================================================

# Calculate overall station genre distribution (excluding special shows)
main_station_genre_distribution <- data %>%
  filter(!is.na(main_genre), main_genre != "", main_genre != "-", main_genre != "Unknown") %>%
  # Exclude special programming from baseline
  filter(!grepl(paste(EXCLUDE_TERMS, collapse = "|"), main_showname, ignore.case = TRUE)) %>%
  count(main_genre) %>%
  mutate(
    main_station_pct = (n / sum(n)) * 100
  ) %>%
  arrange(desc(main_station_pct))

# =============================================================================
# PART 6B: CALCULATE DJ GENRE PREFERENCES
# =============================================================================

# Calculate DJ genre distributions
main_dj_genre_analysis <- data %>%
  filter(!is.na(main_genre), main_genre != "", main_genre != "-", main_genre != "Unknown") %>%
  filter(!is.na(main_presenter), main_presenter != "", main_presenter != "Unknown") %>%
  # Exclude special programming
  filter(!grepl(paste(EXCLUDE_TERMS, collapse = "|"), main_showname, ignore.case = TRUE)) %>%
  filter(main_stand_in != 1) %>%  # Exclude sitting-in presenters
  group_by(main_presenter, main_genre) %>%
  summarise(main_tracks_played = n(), .groups = 'drop') %>%
  # Calculate percentages for each DJ
  group_by(main_presenter) %>%
  mutate(
    main_total_tracks = sum(main_tracks_played),
    main_dj_pct = (main_tracks_played / main_total_tracks) * 100
  ) %>%
  ungroup() %>%
  # Only include DJs with sufficient data
  filter(main_total_tracks >= 20) %>%  # Minimum tracks for meaningful analysis
  # Add station percentages for comparison
  left_join(main_station_genre_distribution %>% select(main_genre, main_station_pct), by = "main_genre") %>%
  mutate(
    main_station_pct = ifelse(is.na(main_station_pct), 0, main_station_pct),
    # Calculate how much this DJ over/under-represents this genre
    main_genre_bias = main_dj_pct - main_station_pct
  )

# =============================================================================
# PART 6C: CALCULATE DJ GENRE DIVERSITY & SIMILARITY
# =============================================================================

# Calculate DJ-level summary statistics
main_dj_genre_summary <- main_dj_genre_analysis %>%
  group_by(main_presenter) %>%
  summarise(
    main_total_tracks = first(main_total_tracks),
    main_unique_genres = n_distinct(main_genre),
    main_top_genre = main_genre[which.max(main_tracks_played)],
    main_top_genre_tracks = max(main_tracks_played, na.rm = TRUE),
    main_top_genre_percentage = round((max(main_tracks_played, na.rm = TRUE) / first(main_total_tracks)) * 100, 1),
    # Calculate genre diversity using Herfindahl-Hirschman Index (1 - HHI)
    # 0 = very focused (one genre), 1 = very diverse (equal genres)
    main_genre_diversity_ratio = round(1 - sum((main_tracks_played / first(main_total_tracks))^2, na.rm = TRUE), 3),
    # Calculate similarity to station average (lower = more similar)
    main_similarity_score = round(100 - (sum(abs(main_genre_bias), na.rm = TRUE) / 2), 1),
    .groups = "drop"
  ) %>%
  arrange(desc(main_similarity_score))

# Create the summary table (add this after main_dj_genre_summary is created)
if (exists("main_dj_genre_summary") && nrow(main_dj_genre_summary) > 0) {
  
  main_dj_summary_table <- main_dj_genre_summary %>%
    filter(main_total_tracks >= 20) %>%  # Only DJs with sufficient data
    arrange(desc(main_similarity_score)) %>%
    mutate(
      main_similarity_score = round(main_similarity_score, 1),
      main_top_genre_percentage = round(main_top_genre_percentage, 1)
    ) %>%
    select(main_presenter, main_similarity_score, main_total_tracks, main_top_genre, 
           main_top_genre_percentage, main_unique_genres) %>%
    # Rename for cleaner table display
    rename(
      main_genres_played = main_unique_genres,
      main_top_genre_pct = main_top_genre_percentage
    )
  
  cat("DJ summary table created with", nrow(main_dj_summary_table), "DJs\n")
} else {
  main_dj_summary_table <- data.frame()
  cat("No DJ genre data available for summary table\n")
}

# =============================================================================
# PART 6D: LINK DJ GENRE ANALYSIS TO RETENTION PERFORMANCE
# =============================================================================

if (exists("main_show_retention_summary") && nrow(main_show_retention_summary) > 0) {
  
  # Create DJ-to-show mapping to link genre analysis with retention data
  # This handles cases where DJ names might be in show names or presenter fields
  main_dj_show_mapping <- main_show_retention_summary %>%
    filter(!grepl(paste(EXCLUDE_TERMS, collapse = "|"), main_showname, ignore.case = TRUE)) %>%
    mutate(
      # Extract DJ name - this might need customization based on your data
      main_dj_name = main_showname
    ) %>%
    group_by(main_dj_name) %>%
    summarise(
      main_shows_analyzed = n(),
      main_total_broadcast_hours = sum(main_broadcast_hours),
      main_avg_retention_rate = mean(main_avg_retention_rate, na.rm = TRUE),
      main_avg_retention_vs_slot = mean(main_avg_retention_vs_slot, na.rm = TRUE),
      main_retention_category = first(main_retention_grade),  # Take first category if multiple shows
      .groups = "drop"
    ) %>%
    filter(main_total_broadcast_hours >= 2)  # Minimum broadcast time for retention analysis
  
  # Combine DJ genre analysis with retention performance
  main_dj_genre_retention <- main_dj_genre_summary %>%
    inner_join(main_dj_show_mapping, by = c("main_presenter" = "main_dj_name")) %>%
    mutate(
      # Round for display
      main_avg_retention_vs_slot = round(main_avg_retention_vs_slot, 1),
      main_total_broadcast_hours = round(main_total_broadcast_hours, 0)
    ) %>%
    arrange(desc(main_avg_retention_vs_slot))
  
} else {
  # Create empty dataset if retention data not available
  main_dj_genre_retention <- data.frame()
}

# Create the Genre Strategy vs Retention Performance table
if (exists("main_dj_genre_retention") && nrow(main_dj_genre_retention) > 0) {
  
  # Create the summary table for Genre Strategy vs Retention Performance
  main_genre_strategy_retention_table <- main_dj_genre_retention %>%
    arrange(desc(main_avg_retention_vs_slot)) %>%
    mutate(
      # Round values for display
      main_top_genre_percentage = round(main_top_genre_percentage, 1),
      main_genre_diversity_ratio = round(main_genre_diversity_ratio, 3),
      main_avg_retention_vs_slot = round(main_avg_retention_vs_slot, 1),
      main_total_broadcast_hours = round(main_total_broadcast_hours, 0),
      # Create shorter retention level names
      main_retention_level = case_when(
        main_retention_category == "Excellent Retention" ~ "Excellent",
        main_retention_category == "Good Retention" ~ "Good",
        main_retention_category == "Average Retention" ~ "Average", 
        main_retention_category == "Poor Retention" ~ "Poor",
        TRUE ~ "Unknown"
      )
    ) %>%
    # Select and rename columns for the table
    select(
      main_presenter, 
      main_top_genre, 
      main_top_genre_percentage, 
      main_genre_diversity_ratio, 
      main_avg_retention_vs_slot, 
      main_total_broadcast_hours, 
      main_retention_level
    )
  
  cat("Genre Strategy vs Retention table created with", nrow(main_genre_strategy_retention_table), "DJs\n")
  
} else {
  main_genre_strategy_retention_table <- data.frame()
  cat("No DJ genre-retention data available for strategy table\n")
}

# =============================================================================
# PART 6E: CREATE CHART-READY DATASETS
# =============================================================================

# Prepare data for genre heatmaps (top genres and DJs)
main_top_genres <- main_station_genre_distribution %>%
  head(30) %>%  # Top 30 genres for chart readability
  pull(main_genre)

# DJ genre data for plotting (including station baseline)
main_dj_genre_plot_data <- main_dj_genre_analysis %>%
  filter(main_genre %in% main_top_genres) %>%
  # Only include DJs with sufficient data
  filter(main_presenter %in% (main_dj_genre_summary %>% filter(main_total_tracks >= 20) %>% pull(main_presenter))) %>%
  # Add station baseline for comparison
  bind_rows(
    main_station_genre_distribution %>%
      filter(main_genre %in% main_top_genres) %>%
      mutate(
        main_presenter = "STATION OVERALL",
        main_tracks_played = n,
        main_total_tracks = sum(n),
        main_dj_pct = main_station_pct,
        main_genre_bias = 0
      ) %>%
      select(main_presenter, main_genre, main_tracks_played, main_total_tracks, main_dj_pct, main_station_pct, main_genre_bias)
  ) %>%
  # Order DJs for display (alphabetical with station overall at bottom)
  mutate(
    main_presenter = factor(main_presenter, 
                            levels = c(sort(unique(main_presenter[main_presenter != "STATION OVERALL"]), decreasing = TRUE), 
                                       "STATION OVERALL"))
  )

# =============================================================================
# PART 6F: SECOND STATION (IF ENABLED)
# =============================================================================

if (ANALYSE_SECOND_STATION == "Y") {

  # Calculate overall station genre distribution (excluding special shows)
  second_station_genre_distribution <- data %>%
    filter(!is.na(second_genre), second_genre != "", second_genre != "-", second_genre != "Unknown") %>%
    # Exclude special programming from baseline
    filter(!grepl(paste(EXCLUDE_TERMS, collapse = "|"), second_showname, ignore.case = TRUE)) %>%
    count(second_genre) %>%
    mutate(
      second_station_pct = (n / sum(n)) * 100
    ) %>%
    arrange(desc(second_station_pct))
  
  # Calculate DJ genre distributions
  second_dj_genre_analysis <- data %>%
    filter(!is.na(second_genre), second_genre != "", second_genre != "-", second_genre != "Unknown") %>%
    filter(!is.na(second_presenter), second_presenter != "", second_presenter != "Unknown") %>%
    # Exclude special programming
    filter(!grepl(paste(EXCLUDE_TERMS, collapse = "|"), second_showname, ignore.case = TRUE)) %>%
    filter(second_stand_in != 1) %>%  # Exclude sitting-in presenters
    group_by(second_presenter, second_genre) %>%
    summarise(second_tracks_played = n(), .groups = 'drop') %>%
    # Calculate percentages for each DJ
    group_by(second_presenter) %>%
    mutate(
      second_total_tracks = sum(second_tracks_played),
      second_dj_pct = (second_tracks_played / second_total_tracks) * 100
    ) %>%
    ungroup() %>%
    # Only include DJs with sufficient data
    filter(second_total_tracks >= 20) %>%  # Minimum tracks for meaningful analysis
    # Add station percentages for comparison
    left_join(second_station_genre_distribution %>% select(second_genre, second_station_pct), by = "second_genre") %>%
    mutate(
      second_station_pct = ifelse(is.na(second_station_pct), 0, second_station_pct),
      # Calculate how much this DJ over/under-represents this genre
      second_genre_bias = second_dj_pct - second_station_pct
    )

  # Calculate DJ-level summary statistics
  second_dj_genre_summary <- second_dj_genre_analysis %>%
    group_by(second_presenter) %>%
    summarise(
      second_total_tracks = first(second_total_tracks),
      second_unique_genres = n_distinct(second_genre),
      second_top_genre = second_genre[which.max(second_tracks_played)],
      second_top_genre_tracks = max(second_tracks_played, na.rm = TRUE),
      second_top_genre_percentage = round((max(second_tracks_played, na.rm = TRUE) / first(second_total_tracks)) * 100, 1),
      # Calculate genre diversity using Herfindahl-Hirschman Index (1 - HHI)
      # 0 = very focused (one genre), 1 = very diverse (equal genres)
      second_genre_diversity_ratio = round(1 - sum((second_tracks_played / first(second_total_tracks))^2, na.rm = TRUE), 3),
      # Calculate similarity to station average (lower = more similar)
      second_similarity_score = round(100 - (sum(abs(second_genre_bias), na.rm = TRUE) / 2), 1),
      .groups = "drop"
    ) %>%
    arrange(desc(second_similarity_score))
  
  # Create the summary table (add this after second_dj_genre_summary is created)
  if (exists("second_dj_genre_summary") && nrow(second_dj_genre_summary) > 0) {
    
    second_dj_summary_table <- second_dj_genre_summary %>%
      filter(second_total_tracks >= 20) %>%  # Only DJs with sufficient data
      arrange(desc(second_similarity_score)) %>%
      mutate(
        second_similarity_score = round(second_similarity_score, 1),
        second_top_genre_percentage = round(second_top_genre_percentage, 1)
      ) %>%
      select(second_presenter, second_similarity_score, second_total_tracks, second_top_genre, 
             second_top_genre_percentage, second_unique_genres) %>%
      # Rename for cleaner table display
      rename(
        second_genres_played = second_unique_genres,
        second_top_genre_pct = second_top_genre_percentage
      )
    
    cat("DJ summary table created with", nrow(second_dj_summary_table), "DJs\n")
  } else {
    second_dj_summary_table <- data.frame()
    cat("No DJ genre data available for summary table\n")
  }
  
  if (exists("second_show_retention_summary") && nrow(second_show_retention_summary) > 0) {
    
    # Create DJ-to-show mapping to link genre analysis with retention data
    # This handles cases where DJ names might be in show names or presenter fields
    second_dj_show_mapping <- second_show_retention_summary %>%
      filter(!grepl(paste(EXCLUDE_TERMS, collapse = "|"), second_showname, ignore.case = TRUE)) %>%
      mutate(
        # Extract DJ name - this might need customization based on your data
        second_dj_name = second_showname
      ) %>%
      group_by(second_dj_name) %>%
      summarise(
        second_shows_analyzed = n(),
        second_total_broadcast_hours = sum(second_broadcast_hours),
        second_avg_retention_rate = mean(second_avg_retention_rate, na.rm = TRUE),
        second_avg_retention_vs_slot = mean(second_avg_retention_vs_slot, na.rm = TRUE),
        second_retention_category = first(second_retention_grade),  # Take first category if multiple shows
        .groups = "drop"
      ) %>%
      filter(second_total_broadcast_hours >= 2)  # Minimum broadcast time for retention analysis
    
    # Combine DJ genre analysis with retention performance
    second_dj_genre_retention <- second_dj_genre_summary %>%
      inner_join(second_dj_show_mapping, by = c("second_presenter" = "second_dj_name")) %>%
      mutate(
        # Round for display
        second_avg_retention_vs_slot = round(second_avg_retention_vs_slot, 1),
        second_total_broadcast_hours = round(second_total_broadcast_hours, 0)
      ) %>%
      arrange(desc(second_avg_retention_vs_slot))
    
  } else {
    # Create empty dataset if retention data not available
    second_dj_genre_retention <- data.frame()
  }
  
  # Create the Genre Strategy vs Retention Performance table
  if (exists("second_dj_genre_retention") && nrow(second_dj_genre_retention) > 0) {
    
    # Create the summary table for Genre Strategy vs Retention Performance
    second_genre_strategy_retention_table <- second_dj_genre_retention %>%
      arrange(desc(second_avg_retention_vs_slot)) %>%
      mutate(
        # Round values for display
        second_top_genre_percentage = round(second_top_genre_percentage, 1),
        second_genre_diversity_ratio = round(second_genre_diversity_ratio, 3),
        second_avg_retention_vs_slot = round(second_avg_retention_vs_slot, 1),
        second_total_broadcast_hours = round(second_total_broadcast_hours, 0),
        # Create shorter retention level names
        second_retention_level = case_when(
          second_retention_category == "Excellent Retention" ~ "Excellent",
          second_retention_category == "Good Retention" ~ "Good",
          second_retention_category == "Average Retention" ~ "Average", 
          second_retention_category == "Poor Retention" ~ "Poor",
          TRUE ~ "Unknown"
        )
      ) %>%
      # Select and rename columns for the table
      select(
        second_presenter, 
        second_top_genre, 
        second_top_genre_percentage, 
        second_genre_diversity_ratio, 
        second_avg_retention_vs_slot, 
        second_total_broadcast_hours, 
        second_retention_level
      )
    
    cat("Genre Strategy vs Retention table created with", nrow(second_genre_strategy_retention_table), "DJs\n")
    
  } else {
    second_genre_strategy_retention_table <- data.frame()
    cat("No DJ genre-retention data available for strategy table\n")
  }
  
  # Prepare data for genre heatmaps (top genres and DJs)
  second_top_genres <- second_station_genre_distribution %>%
    head(30) %>%  # Top 30 genres for chart readability
    pull(second_genre)
  
  # DJ genre data for plotting (including station baseline)
  second_dj_genre_plot_data <- second_dj_genre_analysis %>%
    filter(second_genre %in% second_top_genres) %>%
    # Only include DJs with sufficient data
    filter(second_presenter %in% (second_dj_genre_summary %>% filter(second_total_tracks >= 20) %>% pull(second_presenter))) %>%
    # Add station baseline for comparison
    bind_rows(
      second_station_genre_distribution %>%
        filter(second_genre %in% second_top_genres) %>%
        mutate(
          second_presenter = "STATION OVERALL",
          second_tracks_played = n,
          second_total_tracks = sum(n),
          second_dj_pct = second_station_pct,
          second_genre_bias = 0
        ) %>%
        select(second_presenter, second_genre, second_tracks_played, second_total_tracks, second_dj_pct, second_station_pct, second_genre_bias)
    ) %>%
    # Order DJs for display (alphabetical with station overall at bottom)
    mutate(
      second_presenter = factor(second_presenter, 
                              levels = c(sort(unique(second_presenter[second_presenter != "STATION OVERALL"]), decreasing = TRUE), 
                                         "STATION OVERALL"))
    )

}

# =============================================================================
# PART 6G: COMPARISON STATION (IF ENABLED)
# =============================================================================

if (ANALYSE_COMPARISON_STATION == "Y") {
  
  # Comparison station genre analysis (similar structure)
  comparison_station_genre_distribution <- data %>%
    filter(!is.na(comparison_genre), comparison_genre != "", comparison_genre != "-", comparison_genre != "Unknown") %>%
    filter(!grepl("Continuous", comparison_showname, ignore.case = TRUE)) %>%
    filter(!grepl("Replay", comparison_showname, ignore.case = TRUE)) %>%
    count(comparison_genre) %>%
    mutate(comparison_station_pct = (n / sum(n)) * 100) %>%
    arrange(desc(comparison_station_pct))
}

# =============================================================================
# ANALYSIS 6 COMPLETE
# =============================================================================

cat("Analysis 6 complete! Created DJ/Genre analysis:\n")

if (DEBUG_TO_CONSOLE == "Y") {
  cat("Main station genre analysis:\n")
  if (exists("main_dj_genre_summary") && nrow(main_dj_genre_summary) > 0) {
    cat("  - DJs analyzed:", nrow(main_dj_genre_summary), "\n")
    cat("  - Total genres found:", nrow(main_station_genre_distribution), "\n")
    cat("  - DJs with retention data:", ifelse(exists("main_dj_genre_retention"), nrow(main_dj_genre_retention), 0), "\n")
    
    # Show genre diversity distribution
    diversity_stats <- summary(main_dj_genre_summary$main_genre_diversity_ratio)
    cat("  - Genre diversity range:", round(diversity_stats["Min."], 3), "to", round(diversity_stats["Max."], 3), "\n")
    
    # Show top 3 most similar DJs to station average
    if (nrow(main_dj_genre_summary) >= 3) {
      top_similar <- main_dj_genre_summary %>% head(3)
      cat("  - Most similar to station average:\n")
      for (i in 1:nrow(top_similar)) {
        cat("    ", i, ". ", top_similar$main_presenter[i], " (", top_similar$main_similarity_score[i], "% similar)\n")
      }
    }
  } else {
    cat("  - No DJ genre data (need >=20 tracks per DJ)\n")
  }
  
  if (exists("main_dj_genre_retention") && nrow(main_dj_genre_retention) > 0) {
    cat("Genre strategy vs retention table ready for:", nrow(main_dj_genre_retention), "DJs\n")
  }
}

# =============================================================================
# ANALYSIS 7: FEATURED SHOW ANALYSIS
# =============================================================================
# This analysis provides detailed analysis of a specific flagship/featured show
# Uses configurable variables: MAIN_FEATURED_SHOW, SECOND_FEATURED_SHOW, COMPARISON_FEATURED_SHOW

cat("Running Analysis 7: Featured Show Analysis...\n")

# =============================================================================
# PART 7A: CHECK FEATURED SHOW CONFIGURATION
# =============================================================================

# Check if featured show variables are defined, if not set defaults
if (!exists("MAIN_FEATURED_SHOW")) {
  MAIN_FEATURED_SHOW <- NULL  # No default - must be explicitly set
  cat("MAIN_FEATURED_SHOW not set for main station analysis\n")
}

if (ANALYSE_SECOND_STATION == "Y" && !exists("SECOND_FEATURED_SHOW")) {
  SECOND_FEATURED_SHOW <- NULL  # No default - must be explicitly set
  cat("SECOND_FEATURED_SHOW not set for second station analysis\n")
}

if (ANALYSE_COMPARISON_STATION == "Y" && !exists("COMPARISON_FEATURED_SHOW")) {
  COMPARISON_FEATURED_SHOW <- NULL  # No default - must be explicitly set
  cat("COMPARISON_FEATURED_SHOW not set for comparison station analysis\n")
}

# =============================================================================
# PART 7B: MAIN STATION FEATURED SHOW ANALYSIS
# =============================================================================

if (!is.null(MAIN_FEATURED_SHOW)) {
  
  cat("Analyzing main station featured show:", MAIN_FEATURED_SHOW, "\n")
  
  # Extract featured show data
  main_featured_data <- data %>%
    filter(main_showname == MAIN_FEATURED_SHOW, ignore.case = TRUE) %>%

        filter(!is.na(main_presenter), main_presenter != "", main_presenter != "Unknown")
  
  if (nrow(main_featured_data) > 0) {
    
    # Overall performance by 5-minute intervals and weekday
    main_featured_overall_performance <- main_featured_data %>%
      mutate(
        # Create time point within the hour (e.g., 9.00, 9.08, 9.17, etc.)
        time_in_hour = hour + (minute / 60)
      ) %>%
      group_by(weekday, time_in_hour) %>%
      summarise(
        main_avg_listeners = mean(main_total_listeners, na.rm = TRUE),
        main_sessions = n(),
        .groups = 'drop'
      ) %>%
      filter(main_sessions >= 1) %>%  # Include all available data points
      mutate(
        weekday = factor(weekday, levels = c("Monday", "Tuesday", "Wednesday", 
                                             "Thursday", "Friday", "Saturday", "Sunday"))
      )
    
    # DJ/Presenter Performance Analysis
    main_featured_dj_performance <- main_featured_data %>%
      group_by(main_presenter) %>%
      summarise(
        main_avg_listeners = mean(main_total_listeners, na.rm = TRUE),
        main_sessions = n(),
        .groups = 'drop'
      ) %>%
      filter(main_sessions >= 5) %>%  # Minimum appearances for reliable analysis
      # Calculate vs overall featured show average
      mutate(
        main_featured_baseline = mean(main_featured_data$main_total_listeners, na.rm = TRUE),
        main_pct_vs_featured_avg = ((main_avg_listeners - main_featured_baseline) / main_featured_baseline) * 100
      ) %>%
      arrange(desc(main_avg_listeners))
    
    # Day-of-week patterns for featured show
    main_featured_dow_patterns <- main_featured_data %>%
      group_by(weekday) %>%
      summarise(
        main_avg_listeners = mean(main_total_listeners, na.rm = TRUE),
        main_sessions = n(),
        .groups = 'drop'
      ) %>%
      mutate(
        main_baseline = mean(main_avg_listeners),
        main_pct_vs_avg = ((main_avg_listeners - main_baseline) / main_baseline) * 100,
        weekday = factor(weekday, levels = c("Monday", "Tuesday", "Wednesday", 
                                             "Thursday", "Friday", "Saturday", "Sunday"))
      )
    
    # Time trends within the featured show hour (if it's regular hourly show)
    # This assumes most featured shows run for an hour with 5-minute data points
    main_featured_time_trends <- main_featured_data %>%
      mutate(
        time_segment = case_when(
          minute >= 0 & minute < 15 ~ paste0(hour, ":00-", hour, ":15"),
          minute >= 15 & minute < 30 ~ paste0(hour, ":15-", hour, ":30"), 
          minute >= 30 & minute < 45 ~ paste0(hour, ":30-", hour, ":45"),
          minute >= 45 ~ paste0(hour, ":45-", hour + 1, ":00")
        )
      ) %>%
      group_by(time_segment) %>%
      summarise(
        main_avg_listeners = mean(main_total_listeners, na.rm = TRUE),
        main_sessions = n(),
        .groups = 'drop'
      ) %>%
      filter(!is.na(time_segment)) %>%
      mutate(
        main_baseline = mean(main_avg_listeners),
        main_pct_vs_avg = ((main_avg_listeners - main_baseline) / main_baseline) * 100
      )
    
    # Genre diversity analysis (if genre data available)
    if ("main_genre" %in% names(main_featured_data)) {
      main_featured_genre_diversity <- main_featured_data %>%
        filter(!is.na(main_genre), main_genre != "", main_genre != "Unknown") %>%
        group_by(date) %>%
        summarise(
          main_total_tracks = n(),
          main_unique_genres = n_distinct(main_genre),
          main_genre_diversity_ratio = main_unique_genres / main_total_tracks,
          .groups = 'drop'
        ) %>%
        filter(main_total_tracks >= 5)  # Only days with meaningful track counts
    } else {
      main_featured_genre_diversity <- data.frame()
    }
    
    # Featured show summary stats
    main_featured_summary_stats <- list(
      show_name = MAIN_FEATURED_SHOW,
      total_episodes = length(unique(paste(main_featured_data$date, main_featured_data$hour))),
      total_sessions = nrow(main_featured_data),
      date_range = paste(min(main_featured_data$date), "to", max(main_featured_data$date)),
      avg_listeners = round(mean(main_featured_data$main_total_listeners, na.rm = TRUE), 0),
      peak_listeners = max(main_featured_data$main_total_listeners, na.rm = TRUE),
      presenters_analyzed = nrow(main_featured_dj_performance),
      best_presenter = if(nrow(main_featured_dj_performance) > 0) main_featured_dj_performance$main_presenter[1] else "None",
      best_presenter_avg = if(nrow(main_featured_dj_performance) > 0) round(main_featured_dj_performance$main_avg_listeners[1], 0) else 0
    )
    
  } else {
    cat("No data found for main station featured show:", MAIN_FEATURED_SHOW, "\n")
    main_featured_summary_stats <- list(show_name = MAIN_FEATURED_SHOW, message = "No data available")
  }
  
  # Featured show genre analysis
  main_featured_genre_analysis <- main_featured_data %>%
    filter(!is.na(main_genre), main_genre != "", main_genre != "Unknown", main_genre != "-") %>%
    group_by(main_genre) %>%
    summarise(
      main_plays = n(),
      main_avg_listeners = mean(main_total_listeners, na.rm = TRUE),
      .groups = 'drop'
    ) %>%
    filter(main_plays >= 2) %>%
    mutate(
      main_baseline = mean(main_featured_data$main_total_listeners, na.rm = TRUE),
      main_listener_impact = main_avg_listeners - main_baseline
    ) %>%
    arrange(desc(main_plays))
  
  # Featured show track analysis  
  main_featured_track_analysis <- main_featured_data %>%
    filter(!is.na(main_artist), !is.na(main_song), main_artist != "", main_song != "", 
           main_artist != "Unknown Artist", main_song != "Unknown") %>%
    group_by(main_artist, main_song) %>%
    summarise(
      main_requests = n(),
      main_avg_listeners = mean(main_total_listeners, na.rm = TRUE),
      .groups = 'drop'
    ) %>%
    filter(main_requests >= 2) %>%
    mutate(
      main_baseline = mean(main_featured_data$main_total_listeners, na.rm = TRUE),
      main_listener_impact = main_avg_listeners - main_baseline
    ) %>%
    arrange(desc(main_requests))
  
} else {
  cat("No main station featured show specified\n")
}

# =============================================================================
# PART 7C: SECOND STATION FEATURED SHOW (IF ENABLED)
# =============================================================================

if (ANALYSE_SECOND_STATION == "Y" && !is.null(SECOND_FEATURED_SHOW)) {
  
    cat("Analyzing main station featured show:", SECOND_FEATURED_SHOW, "\n")
    
    # Extract featured show data
    second_featured_data <- data %>%
      filter(second_showname == SECOND_FEATURED_SHOW, ignore.case = TRUE) %>%
      
      filter(!is.na(second_presenter), second_presenter != "", second_presenter != "Unknown")
    
    if (nrow(second_featured_data) > 0) {
      
      # Overall performance by 5-minute intervals and weekday
      second_featured_overall_performance <- second_featured_data %>%
        mutate(
          # Create time point within the hour (e.g., 9.00, 9.08, 9.17, etc.)
          time_in_hour = hour + (minute / 60)
        ) %>%
        group_by(weekday, time_in_hour) %>%
        summarise(
          second_avg_listeners = mean(second_total_listeners, na.rm = TRUE),
          second_sessions = n(),
          .groups = 'drop'
        ) %>%
        filter(second_sessions >= 1) %>%  # Include all available data points
        mutate(
          weekday = factor(weekday, levels = c("Monday", "Tuesday", "Wednesday", 
                                               "Thursday", "Friday", "Saturday", "Sunday"))
        )
      
      # DJ/Presenter Performance Analysis
      second_featured_dj_performance <- second_featured_data %>%
        group_by(second_presenter) %>%
        summarise(
          second_avg_listeners = mean(second_total_listeners, na.rm = TRUE),
          second_sessions = n(),
          .groups = 'drop'
        ) %>%
        filter(second_sessions >= 5) %>%  # Minimum appearances for reliable analysis
        # Calculate vs overall featured show average
        mutate(
          second_featured_baseline = mean(second_featured_data$second_total_listeners, na.rm = TRUE),
          second_pct_vs_featured_avg = ((second_avg_listeners - second_featured_baseline) / second_featured_baseline) * 100
        ) %>%
        arrange(desc(second_avg_listeners))
      
      # Day-of-week patterns for featured show
      second_featured_dow_patterns <- second_featured_data %>%
        group_by(weekday) %>%
        summarise(
          second_avg_listeners = mean(second_total_listeners, na.rm = TRUE),
          second_sessions = n(),
          .groups = 'drop'
        ) %>%
        mutate(
          second_baseline = mean(second_avg_listeners),
          second_pct_vs_avg = ((second_avg_listeners - second_baseline) / second_baseline) * 100,
          weekday = factor(weekday, levels = c("Monday", "Tuesday", "Wednesday", 
                                               "Thursday", "Friday", "Saturday", "Sunday"))
        )
      
      # Time trends within the featured show hour (if it's regular hourly show)
      # This assumes most featured shows run for an hour with 5-minute data points
      second_featured_time_trends <- second_featured_data %>%
        mutate(
          time_segment = case_when(
            minute >= 0 & minute < 15 ~ paste0(hour, ":00-", hour, ":15"),
            minute >= 15 & minute < 30 ~ paste0(hour, ":15-", hour, ":30"), 
            minute >= 30 & minute < 45 ~ paste0(hour, ":30-", hour, ":45"),
            minute >= 45 ~ paste0(hour, ":45-", hour + 1, ":00")
          )
        ) %>%
        group_by(time_segment) %>%
        summarise(
          second_avg_listeners = mean(second_total_listeners, na.rm = TRUE),
          second_sessions = n(),
          .groups = 'drop'
        ) %>%
        filter(!is.na(time_segment)) %>%
        mutate(
          second_baseline = mean(second_avg_listeners),
          second_pct_vs_avg = ((second_avg_listeners - second_baseline) / second_baseline) * 100
        )
      
      # Genre diversity analysis (if genre data available)
      if ("second_genre" %in% names(second_featured_data)) {
        second_featured_genre_diversity <- second_featured_data %>%
          filter(!is.na(second_genre), second_genre != "", second_genre != "Unknown") %>%
          group_by(date) %>%
          summarise(
            second_total_tracks = n(),
            second_unique_genres = n_distinct(second_genre),
            second_genre_diversity_ratio = second_unique_genres / second_total_tracks,
            .groups = 'drop'
          ) %>%
          filter(second_total_tracks >= 5)  # Only days with meaningful track counts
      } else {
        second_featured_genre_diversity <- data.frame()
      }
      
      # Featured show summary stats
      second_featured_summary_stats <- list(
        show_name = SECOND_FEATURED_SHOW,
        total_episodes = length(unique(paste(second_featured_data$date, second_featured_data$hour))),
        total_sessions = nrow(second_featured_data),
        date_range = paste(min(second_featured_data$date), "to", max(second_featured_data$date)),
        avg_listeners = round(mean(second_featured_data$second_total_listeners, na.rm = TRUE), 0),
        peak_listeners = max(second_featured_data$second_total_listeners, na.rm = TRUE),
        presenters_analyzed = nrow(second_featured_dj_performance),
        best_presenter = if(nrow(second_featured_dj_performance) > 0) second_featured_dj_performance$second_presenter[1] else "None",
        best_presenter_avg = if(nrow(second_featured_dj_performance) > 0) round(second_featured_dj_performance$second_avg_listeners[1], 0) else 0
      )
      
    } else {
      cat("No data found for second station featured show:", SECOND_FEATURED_SHOW, "\n")
      second_featured_summary_stats <- list(show_name = SECOND_FEATURED_SHOW, message = "No data available")
    }
    
    # Featured show genre analysis
    second_featured_genre_analysis <- second_featured_data %>%
      filter(!is.na(second_genre), second_genre != "", second_genre != "Unknown", second_genre != "-") %>%
      group_by(second_genre) %>%
      summarise(
        second_plays = n(),
        second_avg_listeners = mean(second_total_listeners, na.rm = TRUE),
        .groups = 'drop'
      ) %>%
      filter(second_plays >= 2) %>%
      mutate(
        second_baseline = mean(second_featured_data$second_total_listeners, na.rm = TRUE),
        second_listener_impact = second_avg_listeners - second_baseline
      ) %>%
      arrange(desc(second_plays))
    
    # Featured show track analysis  
    second_featured_track_analysis <- second_featured_data %>%
      filter(!is.na(second_artist), !is.na(second_song), second_artist != "", second_song != "", 
             second_artist != "Unknown Artist", second_song != "Unknown") %>%
      group_by(second_artist, second_song) %>%
      summarise(
        second_requests = n(),
        second_avg_listeners = mean(second_total_listeners, na.rm = TRUE),
        .groups = 'drop'
      ) %>%
      filter(second_requests >= 2) %>%
      mutate(
        second_baseline = mean(second_featured_data$second_total_listeners, na.rm = TRUE),
        second_listener_impact = second_avg_listeners - second_baseline
      ) %>%
      arrange(desc(second_requests))
    
  } else {
    cat("No second station featured show specified\n")
  }


# =============================================================================
# PART 7D: COMPARISON STATION FEATURED SHOW (IF ENABLED)
# =============================================================================

if (ANALYSE_COMPARISON_STATION == "Y" && !is.null(COMPARISON_FEATURED_SHOW)) {
  
  cat("Analyzing comparison station featured show:", COMPARISON_FEATURED_SHOW, "\n")
  
  # Extract comparison station featured show data
  comparison_featured_data <- data %>%
    filter(comparison_showname == COMPARISON_FEATURED_SHOW | grepl(COMPARISON_FEATURED_SHOW, comparison_showname, ignore.case = TRUE)) %>%
    filter(!is.na(comparison_presenter), comparison_presenter != "", comparison_presenter != "Unknown")
  
  if (nrow(comparison_featured_data) > 0) {
    
    # Comparison station featured show analysis (similar structure)
    comparison_featured_overall_performance <- comparison_featured_data %>%
      mutate(time_in_hour = hour + (minute / 60)) %>%
      group_by(weekday, time_in_hour) %>%
      summarise(
        comparison_avg_listeners = mean(comparison_total_listeners, na.rm = TRUE),
        comparison_sessions = n(),
        .groups = 'drop'
      ) %>%
      filter(comparison_sessions >= 1) %>%
      mutate(weekday = factor(weekday, levels = c("Monday", "Tuesday", "Wednesday", 
                                                  "Thursday", "Friday", "Saturday", "Sunday")))
    
    comparison_featured_dj_performance <- comparison_featured_data %>%
      group_by(comparison_presenter) %>%
      summarise(
        comparison_avg_listeners = mean(comparison_total_listeners, na.rm = TRUE),
        comparison_sessions = n(),
        .groups = 'drop'
      ) %>%
      filter(comparison_sessions >= 5) %>%
      mutate(
        comparison_featured_baseline = mean(comparison_featured_data$comparison_total_listeners, na.rm = TRUE),
        comparison_pct_vs_featured_avg = ((comparison_avg_listeners - comparison_featured_baseline) / comparison_featured_baseline) * 100
      ) %>%
      arrange(desc(comparison_avg_listeners))
  }
}

# =============================================================================
# ANALYSIS 7 COMPLETE
# =============================================================================

cat("Analysis 7 complete! Featured show analysis created:\n")

if (DEBUG_TO_CONSOLE == "Y") {
  if (exists("main_featured_summary_stats")) {
    cat("Main station featured show (", MAIN_FEATURED_SHOW, "):\n")
    if ("message" %in% names(main_featured_summary_stats)) {
      cat("  -", main_featured_summary_stats$message, "\n")
    } else {
      cat("  - Episodes analyzed:", main_featured_summary_stats$total_episodes, "\n")
      cat("  - Sessions analyzed:", main_featured_summary_stats$total_sessions, "\n")
      cat("  - Average listeners:", main_featured_summary_stats$avg_listeners, "\n")
      cat("  - Peak listeners:", main_featured_summary_stats$peak_listeners, "\n")
      cat("  - Presenters analyzed:", main_featured_summary_stats$presenters_analyzed, "\n")
      if (main_featured_summary_stats$presenters_analyzed > 0) {
        cat("  - Best presenter:", main_featured_summary_stats$best_presenter, 
            "(", main_featured_summary_stats$best_presenter_avg, "avg listeners)\n")
      }
    }
  }
  
  if (ANALYSE_SECOND_STATION == "Y" && exists("second_featured_data")) {
    cat("Second station featured show (", SECOND_FEATURED_SHOW, "):", nrow(second_featured_data), "sessions\n")
  }
  
  if (ANALYSE_COMPARISON_STATION == "Y" && exists("comparison_featured_data")) {
    cat("Comparison station featured show (", COMPARISON_FEATURED_SHOW, "):", nrow(comparison_featured_data), "sessions\n")
  }
}


# =============================================================================
# ANALYSIS 8: IMPACT ANALYSES
# =============================================================================
# This analysis examines various factors that impact listener numbers:
# 1) Most played tracks, 2) Artist impact, 3) Genre impact, 4) Genre by hour
# 5) Sitting-in vs Regular DJ, 6) Live vs Pre-recorded, 7) Public holidays

cat("Running Analysis 8: Impact Analyses...\n")

# =============================================================================
# PART 8A: MOST PLAYED TRACKS IMPACT ANALYSIS
# =============================================================================

if (exists("data") && nrow(data) > 0) {
  
  cat("Running z-score based track impact analysis for main station...\n")
  
  # Step 1: Calculate z-scores for track impact
  main_track_impact_zscore <- data %>%
    filter(!is.na(main_artist), main_artist != "", main_artist != "Unknown") %>%
    filter(!is.na(main_song), main_song != "", main_song != "Unknown") %>%
    # Join with baseline statistics
    left_join(main_hourly_baseline_stats, by = c("hour", "day_type")) %>%
    # Only include observations where we have baseline stats
    filter(!is.na(main_hour_mean), !is.na(main_hour_sd), main_hour_sd > 0) %>%
    # Calculate z-score for each observation
    mutate(
      main_listener_zscore = (main_total_listeners - main_hour_mean) / main_hour_sd
    ) %>%
    # Group by track and calculate average impact
    group_by(main_artist, main_song) %>%
    summarise(
      main_plays = n(),
      main_avg_zscore_impact = mean(main_listener_zscore, na.rm = TRUE),
      main_avg_listeners = mean(main_total_listeners, na.rm = TRUE),
      main_zscore_consistency = sd(main_listener_zscore, na.rm = TRUE),
      .groups = 'drop'
    ) %>%
    # Filter for tracks with sufficient plays
    filter(main_plays >= 3) %>%
    # Create track identifier
    mutate(
      main_track = paste(main_artist, "-", main_song),
      # Categorize impact
      main_zscore_impact_category = case_when(
        main_avg_zscore_impact > 1.0 ~ "High Positive Impact",
        main_avg_zscore_impact > 0.5 ~ "Moderate Positive Impact", 
        main_avg_zscore_impact > -0.5 ~ "Neutral Impact",
        main_avg_zscore_impact > -1.0 ~ "Moderate Negative Impact",
        TRUE ~ "High Negative Impact"
      )
    ) %>%
    arrange(desc(main_avg_zscore_impact))
  
  # Step 2: Create summary for most/least impactful tracks
  if (nrow(main_track_impact_zscore) > 0) {
    
    # Top 15 most positive impact tracks
    main_top_tracks_zscore <- main_track_impact_zscore %>%
      filter(main_avg_zscore_impact > 0) %>%
      head(15) %>%
      mutate(
        main_avg_zscore_impact = round(main_avg_zscore_impact, 2),
        main_avg_listeners = round(main_avg_listeners, 0),
        main_zscore_consistency = round(main_zscore_consistency, 2)
      )
    
    # Bottom 15 most negative impact tracks  
    main_bottom_tracks_zscore <- main_track_impact_zscore %>%
      filter(main_avg_zscore_impact < 0) %>%
      tail(15) %>%
      arrange(main_avg_zscore_impact) %>%
      mutate(
        main_avg_zscore_impact = round(main_avg_zscore_impact, 2),
        main_avg_listeners = round(main_avg_listeners, 0),
        main_zscore_consistency = round(main_zscore_consistency, 2)
      )
    
    # Extract 30 most played tracks from z-score analysis
    if (exists("main_track_impact_zscore") && nrow(main_track_impact_zscore) > 0) {
      
      main_most_played_tracks_zscore <- main_track_impact_zscore %>%
        arrange(desc(main_plays)) %>%
        head(30) %>%
        mutate(
          main_avg_zscore_impact = round(main_avg_zscore_impact, 2),
          main_avg_listeners = round(main_avg_listeners, 0),
          main_zscore_consistency = round(main_zscore_consistency, 2),
          # Add rank for display
          main_play_rank = row_number()
        ) %>%
        select(main_play_rank, main_track, main_plays, main_avg_zscore_impact, 
               main_avg_listeners, main_zscore_consistency, main_zscore_impact_category)
      
      cat("✓ Most played tracks (z-score analysis) extracted:", nrow(main_most_played_tracks_zscore), "tracks\n")
      
    } else {
      main_most_played_tracks_zscore <- data.frame()
      cat("❌ No z-score track data available for most played analysis\n")
    }
    
    cat("✓ Z-score track impact analysis completed\n")
    cat("  - Tracks analyzed:", nrow(main_track_impact_zscore), "\n")
    cat("  - Positive impact tracks:", sum(main_track_impact_zscore$main_avg_zscore_impact > 0), "\n")
    cat("  - Negative impact tracks:", sum(main_track_impact_zscore$main_avg_zscore_impact < 0), "\n")
    
  } else {
    cat("❌ Insufficient data for z-score track impact analysis\n")
    main_top_tracks_zscore <- data.frame()
    main_bottom_tracks_zscore <- data.frame()
  }
  
} else {
  cat("❌ No data available for z-score track impact analysis\n")
  main_track_impact_zscore <- data.frame()
  main_top_tracks_zscore <- data.frame()
  main_bottom_tracks_zscore <- data.frame()
}

# =============================================================================
# PART 8B: ARTIST IMPACT ANALYSIS
# =============================================================================

if (exists("main_hourly_baseline_stats") && nrow(main_hourly_baseline_stats) > 0) {
  
  cat("Running z-score based artist impact analysis for main station...\n")
  
  # Calculate z-scores for artist impact
  main_artist_impact_zscore <- data %>%
    filter(!is.na(main_artist), main_artist != "", 
           main_artist != "Unknown", main_artist != "Unknown Artist", main_artist != "-") %>%
    # Join with baseline statistics
    left_join(main_hourly_baseline_stats, by = c("hour", "day_type")) %>%
    # Only include observations where we have baseline stats
    filter(!is.na(main_hour_mean), !is.na(main_hour_sd), main_hour_sd > 0) %>%
    # Calculate z-score for each observation
    mutate(
      main_listener_zscore = (main_total_listeners - main_hour_mean) / main_hour_sd
    ) %>%
    # Group by artist and calculate average impact
    group_by(main_artist) %>%
    summarise(
      main_plays = n(),
      main_avg_zscore_impact = mean(main_listener_zscore, na.rm = TRUE),
      main_avg_listeners = mean(main_total_listeners, na.rm = TRUE),
      main_zscore_consistency = sd(main_listener_zscore, na.rm = TRUE),
      .groups = 'drop'
    ) %>%
    # Filter for artists with sufficient plays
    filter(main_plays >= 5) %>%
    # Categorize impact
    mutate(
      main_zscore_impact_category = case_when(
        main_avg_zscore_impact > 1.0 ~ "High Positive Impact",
        main_avg_zscore_impact > 0.5 ~ "Moderate Positive Impact", 
        main_avg_zscore_impact > -0.5 ~ "Neutral Impact",
        main_avg_zscore_impact > -1.0 ~ "Moderate Negative Impact",
        TRUE ~ "High Negative Impact"
      )
    ) %>%
    arrange(desc(main_avg_zscore_impact))
  
  # Top and bottom artists
  if (nrow(main_artist_impact_zscore) > 0) {
    main_top_artists_zscore <- main_artist_impact_zscore %>%
      filter(main_avg_zscore_impact > 0) %>%
      head(15) %>%
      mutate(
        main_avg_zscore_impact = round(main_avg_zscore_impact, 2),
        main_avg_listeners = round(main_avg_listeners, 0)
      )
    
    main_bottom_artists_zscore <- main_artist_impact_zscore %>%
      filter(main_avg_zscore_impact < 0) %>%
      tail(15) %>%
      arrange(main_avg_zscore_impact) %>%
      mutate(
        main_avg_zscore_impact = round(main_avg_zscore_impact, 2),
        main_avg_listeners = round(main_avg_listeners, 0)
      )
    
    cat("✓ Z-score artist impact analysis completed\n")
    cat("  - Artists analyzed:", nrow(main_artist_impact_zscore), "\n")
    
  } else {
    main_top_artists_zscore <- data.frame()
    main_bottom_artists_zscore <- data.frame()
  }
  
} else {
  main_artist_impact_zscore <- data.frame()
  main_top_artists_zscore <- data.frame()
  main_bottom_artists_zscore <- data.frame()
}

# =============================================================================
# PART 8C: GENRE IMPACT ANALYSIS
# =============================================================================

if (exists("main_hourly_baseline_stats") && nrow(main_hourly_baseline_stats) > 0) {
  
  cat("Running z-score based genre impact analysis for main station...\n")
  
  # Calculate z-scores for genre impact
  main_genre_impact_zscore <- data %>%
    filter(!is.na(main_genre), main_genre != "", main_genre != "-") %>%
    # Join with baseline statistics
    left_join(main_hourly_baseline_stats, by = c("hour", "day_type")) %>%
    # Only include observations where we have baseline stats
    filter(!is.na(main_hour_mean), !is.na(main_hour_sd), main_hour_sd > 0) %>%
    # Calculate z-score for each observation
    mutate(
      main_listener_zscore = (main_total_listeners - main_hour_mean) / main_hour_sd
    ) %>%
    # Group by genre and calculate average impact
    group_by(main_genre) %>%
    summarise(
      main_plays = n(),
      main_avg_zscore_impact = mean(main_listener_zscore, na.rm = TRUE),
      main_avg_listeners = mean(main_total_listeners, na.rm = TRUE),
      main_zscore_consistency = sd(main_listener_zscore, na.rm = TRUE),
      .groups = 'drop'
    ) %>%
    # Filter for genres with sufficient plays
    filter(main_plays >= 10) %>%
    arrange(desc(main_avg_zscore_impact))
  
  # Top and bottom genres
  if (nrow(main_genre_impact_zscore) > 0) {
    main_top_genres_zscore <- main_genre_impact_zscore %>%
      filter(main_avg_zscore_impact > 0) %>%
      head(10) %>%
      mutate(
        main_avg_zscore_impact = round(main_avg_zscore_impact, 2),
        main_avg_listeners = round(main_avg_listeners, 0)
      )
    
    main_bottom_genres_zscore <- main_genre_impact_zscore %>%
      filter(main_avg_zscore_impact < 0) %>%
      tail(10) %>%
      arrange(main_avg_zscore_impact) %>%
      mutate(
        main_avg_zscore_impact = round(main_avg_zscore_impact, 2),
        main_avg_listeners = round(main_avg_listeners, 0)
      )
    
    cat("✓ Z-score genre impact analysis completed\n")
    cat("  - Genres analyzed:", nrow(main_genre_impact_zscore), "\n")
    
  } else {
    main_top_genres_zscore <- data.frame()
    main_bottom_genres_zscore <- data.frame()
  }
  
} else {
  main_genre_impact_zscore <- data.frame()
  main_top_genres_zscore <- data.frame()
  main_bottom_genres_zscore <- data.frame()
}

# =============================================================================
# PART 8D: BEST & WORST PERFORMING GENRES BY HOUR
# =============================================================================

if (exists("main_hourly_baseline_stats") && nrow(main_hourly_baseline_stats) > 0) {
  
  cat("Running z-score based hourly genre performance analysis for main station...\n")
  
  # Calculate z-scores for genre performance by hour
  main_hourly_genre_zscore <- data %>%
    filter(!is.na(main_genre), main_genre != "", main_genre != "-") %>%
    # Join with baseline statistics
    left_join(main_hourly_baseline_stats, by = c("hour", "day_type")) %>%
    # Only include observations where we have baseline stats
    filter(!is.na(main_hour_mean), !is.na(main_hour_sd), main_hour_sd > 0) %>%
    # Calculate z-score for each observation
    mutate(
      main_listener_zscore = (main_total_listeners - main_hour_mean) / main_hour_sd
    ) %>%
    # Group by hour and genre
    group_by(hour, main_genre) %>%
    summarise(
      main_plays = n(),
      main_avg_zscore_impact = mean(main_listener_zscore, na.rm = TRUE),
      main_avg_listeners = mean(main_total_listeners, na.rm = TRUE),
      .groups = 'drop'
    ) %>%
    # Filter for genre-hour combinations with sufficient data
    filter(main_plays >= 5) %>%
    # For each hour, find best and worst genres
    group_by(hour) %>%
    arrange(desc(main_avg_zscore_impact)) %>%
    mutate(
      main_genre_rank = row_number(),
      main_total_genres = n()
    ) %>%
    ungroup() %>%
    # Extract best and worst for each hour (if we have enough genres)
    filter((main_genre_rank == 1 | main_genre_rank == main_total_genres) & main_total_genres >= 3) %>%
    mutate(
      main_performance_type = ifelse(main_genre_rank == 1, "Best", "Worst"),
      main_avg_zscore_impact = round(main_avg_zscore_impact, 2)
    ) %>%
    arrange(hour, main_performance_type)
  
  if (nrow(main_hourly_genre_zscore) > 0) {
    cat("✓ Z-score hourly genre performance analysis completed\n")
    cat("  - Hour-genre combinations analyzed:", nrow(main_hourly_genre_zscore), "\n")
  } else {
    cat("❌ Insufficient data for hourly genre performance analysis\n")
  }
  
} else {
  main_hourly_genre_zscore <- data.frame()
}

if (exists("main_hourly_baseline_stats") && nrow(main_hourly_baseline_stats) > 0) {
  
  cat("Running z-score based hourly genre heatmap analysis for main station...\n")
  
  # Calculate z-scores for ALL genre-hour combinations for heatmap
  main_genre_hour_heatmap_zscore <- data %>%
    filter(!is.na(main_genre), main_genre != "", main_genre != "-") %>%
    # Join with baseline statistics
    left_join(main_hourly_baseline_stats, by = c("hour", "day_type")) %>%
    # Only include observations where we have baseline stats
    filter(!is.na(main_hour_mean), !is.na(main_hour_sd), main_hour_sd > 0) %>%
    # Calculate z-score for each observation
    mutate(
      main_listener_zscore = (main_total_listeners - main_hour_mean) / main_hour_sd
    ) %>%
    # Group by hour and genre
    group_by(hour, main_genre) %>%
    summarise(
      main_plays = n(),
      main_avg_zscore_impact = mean(main_listener_zscore, na.rm = TRUE),
      .groups = 'drop'
    ) %>%
    # Filter for combinations with sufficient data
    filter(main_plays >= 3)
  
  # Get the top 15 genres by total plays
  top_genres <- main_genre_hour_heatmap_zscore %>%
    group_by(main_genre) %>%
    summarise(total_plays = sum(main_plays), .groups = 'drop') %>%
    arrange(desc(total_plays)) %>%
    head(15) %>%
    pull(main_genre)
  
  # Filter for top genres and reasonable hours
  main_genre_hour_heatmap_zscore <- main_genre_hour_heatmap_zscore %>%
    filter(main_genre %in% top_genres,
           hour >= 0, hour <= 24) %>%
    # Round for display
    mutate(main_avg_zscore_impact = round(main_avg_zscore_impact, 2))
  
  if (nrow(main_genre_hour_heatmap_zscore) > 0) {
    cat("✓ Z-score genre-hour heatmap data created\n")
    cat("  - Genre-hour combinations:", nrow(main_genre_hour_heatmap_zscore), "\n")
    cat("  - Genres included:", length(unique(main_genre_hour_heatmap_zscore$main_genre)), "\n")
  } else {
    cat("❌ Insufficient data for genre-hour heatmap\n")
  }
  
} else {
  main_genre_hour_heatmap_zscore <- data.frame()
}

# =============================================================================
# PART 8E: SITTING-IN VS REGULAR DJ ANALYSIS
# =============================================================================

# Step 1: Identify sitting-in presenters using the stand_in column
main_sitting_in_data <- data %>%
  filter(!is.na(main_showname), main_showname != "", main_stand_in == 1) %>%
  filter(!grepl(paste(EXCLUDE_TERMS, collapse = "|"), main_showname, ignore.case = TRUE)) %>%
  select(date, hour, minute, main_showname, main_presenter, main_total_listeners, weekday, day_type) %>%
  mutate(
    # Create unique time slot identifier (date + hour + minute for precision)
    timeslot_key = paste(weekday, hour, minute, sep = "_"),
    sitting_in_presenter = main_presenter
  )

if (nrow(main_sitting_in_data) > 0) {
  
  # Step 2: Find regular shows that normally run at the same time slots
  main_regular_shows_lookup <- data %>%
    filter(!is.na(main_showname), main_showname != "", main_stand_in != 1) %>%
    filter(!grepl(paste(EXCLUDE_TERMS, collapse = "|"), main_showname, ignore.case = TRUE)) %>%
    mutate(timeslot_key = paste(weekday, hour, minute, sep = "_")) %>%
    # Only look at time slots where we have sitting-in shows
    filter(timeslot_key %in% main_sitting_in_data$timeslot_key) %>%
    group_by(timeslot_key, weekday, hour, minute, main_showname, main_presenter) %>%
    summarise(
      main_appearances = n(),
      main_avg_listeners = mean(main_total_listeners, na.rm = TRUE),
      .groups = "drop"
    ) %>%
    # For each time slot, find the most common regular show/presenter combination
    group_by(timeslot_key) %>%
    filter(main_appearances == max(main_appearances)) %>%
    slice(1) %>%  # Take first if tied
    ungroup() %>%
    select(timeslot_key, weekday, hour, minute, 
           regular_showname = main_showname, regular_presenter = main_presenter, 
           regular_appearances = main_appearances, regular_avg_listeners = main_avg_listeners)
  
  # Step 3: Create sitting-in vs regular comparisons
  main_sitting_in_comparisons <- main_sitting_in_data %>%
    inner_join(main_regular_shows_lookup, by = "timeslot_key") %>%
    filter(sitting_in_presenter != regular_presenter) %>%  # Ensure different presenters
    filter(regular_appearances >= 1) %>%  # Regular show must have appeared multiple times
    mutate(
      main_pct_difference = ((main_total_listeners - regular_avg_listeners) / regular_avg_listeners) * 100
    )
  
  # Step 4: Summarize sitting-in performance by show
  if (nrow(main_sitting_in_comparisons) > 0) {
    main_sitting_in_show_summary <- main_sitting_in_comparisons %>%
      group_by(regular_showname, regular_presenter, sitting_in_presenter) %>%
      summarise(
        main_episodes_compared = n(),  # This is "timeslots_compared" equivalent
        main_avg_pct_difference = mean(main_pct_difference, na.rm = TRUE),
        main_median_pct_difference = median(main_pct_difference, na.rm = TRUE),
        main_best_performance = max(main_pct_difference, na.rm = TRUE),
        main_worst_performance = min(main_pct_difference, na.rm = TRUE),
        main_sitting_in_wins = sum(main_pct_difference > 0),
        main_regular_wins = sum(main_pct_difference < 0),
        main_ties = sum(main_pct_difference == 0),
        main_weekdays_analyzed = paste(sort(unique(weekday.x)), collapse = ", "),
        main_avg_sitting_in_listeners = mean(main_total_listeners, na.rm = TRUE),
        .groups = "drop"
      ) %>%
      mutate(
        # Calculate performance summary after grouping
        main_performance_summary = case_when(
          main_avg_pct_difference > 5 ~ "Sitting-in Much Better (+5%)",
          main_avg_pct_difference > 0 ~ "Sitting-in Slightly Better",
          main_avg_pct_difference > -5 ~ "Regular Slightly Better", 
          TRUE ~ "Regular Much Better (-5%)"
        )
      ) %>%
      filter(main_episodes_compared >= 2) %>%  # Need multiple episodes for comparison
      arrange(desc(main_avg_pct_difference))
  } else {
    main_sitting_in_show_summary <- data.frame()
  }
} else {
  main_sitting_in_comparisons <- data.frame()
  main_sitting_in_show_summary <- data.frame()
}

if (exists("main_sitting_in_show_summary") && 
    is.data.frame(main_sitting_in_show_summary) && 
    nrow(main_sitting_in_show_summary) > 0) {
  MAIN_SITTING_IN_EXISTS <- TRUE
  cat("✓ Main station sitting-in vs regular analysis results available for report\n")
} else {
  MAIN_SITTING_IN_EXISTS <- FALSE
  cat("❌ Main station sitting-in vs regular analysis - no results for report\n")
}

# =============================================================================
# PART 8F: LIVE VS PRE-RECORDED IMPACT ANALYSIS
# =============================================================================

# Step 1: Filter to time slots that have BOTH live and recorded shows with sufficient data
main_valid_timeslots <- data %>%
  filter(!is.na(main_recorded), main_recorded %in% c(0, 1)) %>%
  group_by(hour, day_type, main_live_recorded) %>%
  summarise(main_sessions = n(), .groups = "drop") %>%
  # Only keep time slots where BOTH live and pre-recorded have ≥3 sessions
  group_by(hour, day_type) %>%
  filter(n() == 2, all(main_sessions >= 3)) %>%  # Must have exactly 2 types (Live + Pre-recorded), both with ≥3 sessions
  select(hour, day_type) %>%
  distinct()

# Step 2: Calculate live vs recorded performance for valid time slots only
main_live_recorded_analysis <- data %>%
  filter(!is.na(main_recorded), main_recorded %in% c(0, 1)) %>%
  inner_join(main_valid_timeslots, by = c("hour", "day_type")) %>%
  group_by(main_live_recorded, hour, day_type) %>%
  summarise(
    main_avg_listeners = mean(main_total_listeners, na.rm = TRUE),
    main_sessions = n(),
    .groups = 'drop'
  )

# Step 3: Calculate baseline and performance
if (nrow(main_live_recorded_analysis) > 0) {
  main_lr_hourly_baseline <- main_live_recorded_analysis %>%
    group_by(hour, day_type) %>%
    summarise(
      main_hour_avg = mean(main_avg_listeners),  # Simple average of live and pre-recorded
      .groups = 'drop'
    )
  
  main_live_recorded_performance <- main_live_recorded_analysis %>%
    left_join(main_lr_hourly_baseline, by = c("hour", "day_type")) %>%
    mutate(
      main_pct_vs_hour = ((main_avg_listeners - main_hour_avg) / main_hour_avg) * 100
    )
  
  # Summary statistics
  main_live_recorded_summary <- main_live_recorded_performance %>%
    group_by(main_live_recorded, day_type) %>%
    summarise(
      main_avg_performance = mean(main_pct_vs_hour, na.rm = TRUE),
      main_total_sessions = sum(main_sessions),
      main_avg_listeners = mean(main_avg_listeners, na.rm = TRUE),
      main_time_slots = n(),
      .groups = 'drop'
    ) %>%
    mutate(
      main_airtime_hours = round(main_total_sessions / HOUR_NORMALISATION, 0)
    ) %>%
    arrange(day_type, desc(main_avg_performance))
} else {
  main_live_recorded_summary <- data.frame()
}

# Set flag based on results for main station
if (exists("main_live_recorded_summary") && 
    is.data.frame(main_live_recorded_summary) && 
    nrow(main_live_recorded_summary) > 0) {
  MAIN_LIVE_RECORDED_EXISTS <- TRUE
  cat("✓ Main station live vs pre-recorded analysis results available for report\n")
} else {
  MAIN_LIVE_RECORDED_EXISTS <- FALSE
  cat("❌ Main station live vs pre-recorded analysis - no results for report\n")
}

# =============================================================================
# PART 8G: GENERALIZED IMPACT ANALYSIS FRAMEWORK
# =============================================================================

# This framework can be used for any binary condition (e.g., Public Holiday)
create_impact_analysis <- function(data_df, condition_column, condition_value, condition_name, station_prefix = "main") {
  
  # Create column names dynamically
  total_listeners_col <- paste0(station_prefix, "_total_listeners")
  
  # Check if condition column exists
  if (!condition_column %in% names(data_df)) {
    cat("Warning: Column", condition_column, "not found. Skipping", condition_name, "analysis.\n")
    return(data.frame())
  }
  
  # Filter and analyze
  impact_data <- data_df %>%
    filter(!is.na(.data[[condition_column]])) %>%
    mutate(
      condition_active = .data[[condition_column]] == condition_value,
      condition_type = ifelse(condition_active, condition_name, paste("Non", condition_name))
    ) %>%
    group_by(condition_type, hour, day_type) %>%
    summarise(
      avg_listeners = mean(.data[[total_listeners_col]], na.rm = TRUE),
      sessions = n(),
      .groups = 'drop'
    ) %>%
    filter(sessions >= 3) %>%  # Minimum sessions for reliability
    group_by(hour, day_type) %>%
    # Only analyze hours that have both condition and non-condition data
    filter(n() == 2) %>%
    mutate(
      hour_baseline = mean(avg_listeners),
      pct_vs_baseline = ((avg_listeners - hour_baseline) / hour_baseline) * 100
    ) %>%
    ungroup()
  
  if (nrow(impact_data) > 0) {
    # Summary by condition and day type
    impact_summary <- impact_data %>%
      group_by(condition_type, day_type) %>%
      summarise(
        avg_performance = mean(pct_vs_baseline, na.rm = TRUE),
        total_sessions = sum(sessions),
        avg_listeners = mean(avg_listeners, na.rm = TRUE),
        time_slots = n(),
        .groups = 'drop'
      ) %>%
      mutate(
        airtime_hours = round(total_sessions / HOUR_NORMALISATION, 0)
      ) %>%
      arrange(day_type, desc(avg_performance))
    
    return(list(
      analysis = impact_data,
      summary = impact_summary,
      condition_name = condition_name
    ))
  } else {
    return(data.frame())
  }
}

# =============================================================================
# PART 8H: DJ LIVE VS PRE-RECORDED INDIVIDUAL ANALYSIS
# =============================================================================
  # Filter for main station data and get valid time slots
cat("Checking main station live vs pre-recorded data availability...\n")

# Check data availability upfront
main_available_types <- data %>%
  filter(!is.na(main_recorded), main_recorded %in% c(0, 1)) %>%
  distinct(main_live_recorded) %>%
  pull(main_live_recorded)

if (length(main_available_types) < 2) {
  cat("Main station: Live vs Pre-recorded analysis skipped - only", 
      paste(main_available_types, collapse = ", "), "shows available\n")
  main_dj_live_recorded_analysis <- data.frame()
  MAIN_DJ_LIVE_RECORDED_EXISTS <- FALSE
} else {
  cat("Main station: Both live and pre-recorded shows available - proceeding with analysis\n")
  
  # Filter for main station data and get valid time slots
  main_dj_live_recorded_analysis <- data %>%
    filter(!is.na(main_recorded), main_recorded %in% c(0, 1), 
           !is.na(main_presenter), main_presenter != "", main_presenter != "Unknown",
           !is.na(main_showname), main_showname != "",
           main_stand_in != 1) %>%  # Exclude sitting-in DJs
    filter(!grepl(paste(EXCLUDE_TERMS, collapse = "|"), main_showname, ignore.case = TRUE)) %>%
    # Only include time slots that have both live and pre-recorded shows
    group_by(hour, day_type) %>%
    filter(n_distinct(main_live_recorded) == 2) %>%  # Must have both Live and Pre-recorded
    ungroup() %>%
    # Calculate hourly baselines for fair comparison
    group_by(hour, day_type) %>%
    mutate(main_hour_baseline = mean(main_total_listeners, na.rm = TRUE)) %>%
    ungroup() %>%
    # Calculate performance vs hourly average for each session
    mutate(main_pct_vs_hour = ((main_total_listeners - main_hour_baseline) / main_hour_baseline) * 100) %>%
    # Group by presenter and live_recorded status
    group_by(main_presenter, main_live_recorded) %>%
    summarise(
      main_avg_listeners = mean(main_total_listeners, na.rm = TRUE),
      main_avg_performance = mean(main_pct_vs_hour, na.rm = TRUE),
      main_sessions = n(),
      .groups = "drop"
    ) %>%
    # Only keep DJs with sufficient data for both types
    filter(main_sessions >= 3) %>%
    # Check which DJs have both live and pre-recorded data
    group_by(main_presenter) %>%
    filter(n() == 2) %>%  # Must have exactly 2 rows (Live and Pre-recorded)
    ungroup() %>%
    # Reshape to compare live vs pre-recorded for each DJ
    pivot_wider(
      names_from = main_live_recorded,
      values_from = c(main_avg_listeners, main_avg_performance, main_sessions),
      names_sep = "_"
    ) %>%
    # Calculate the difference between live and pre-recorded
    mutate(
      main_performance_difference = `main_avg_performance_Live` - `main_avg_performance_Pre-recorded`,
      main_listener_difference = `main_avg_listeners_Live` - `main_avg_listeners_Pre-recorded`,
      main_total_sessions = `main_sessions_Live` + `main_sessions_Pre-recorded`,
      main_better_when = case_when(
        main_performance_difference > 1 ~ "Live",
        main_performance_difference < -1 ~ "Pre-recorded", 
        TRUE ~ "Similar"
      )
    ) %>%
    # Sort by biggest performance difference
    arrange(desc(abs(main_performance_difference))) %>%
    # Round numbers for display
    mutate(
      `main_avg_performance_Live` = round(`main_avg_performance_Live`, 1),
      `main_avg_performance_Pre-recorded` = round(`main_avg_performance_Pre-recorded`, 1),
      main_performance_difference = round(main_performance_difference, 1),
      `main_avg_listeners_Live` = round(`main_avg_listeners_Live`, 0),
      `main_avg_listeners_Pre-recorded` = round(`main_avg_listeners_Pre-recorded`, 0)
    ) %>%
    # Select columns for the table
    select(main_presenter, `main_sessions_Live`, `main_sessions_Pre-recorded`, 
           `main_avg_performance_Live`, `main_avg_performance_Pre-recorded`, main_performance_difference,
           `main_avg_listeners_Live`, `main_avg_listeners_Pre-recorded`, main_better_when)
  
  # Set flag based on results
  if (exists("main_dj_live_recorded_analysis") && 
      is.data.frame(main_dj_live_recorded_analysis) && 
      nrow(main_dj_live_recorded_analysis) > 0) {
    MAIN_DJ_LIVE_RECORDED_EXISTS <- TRUE
    cat("✓ Main station DJ live vs pre-recorded analysis results available for report\n")
  } else {
    MAIN_DJ_LIVE_RECORDED_EXISTS <- FALSE
    cat("❌ Main station DJ live vs pre-recorded analysis - no results for report\n")
  }
}

if (DEBUG_TO_CONSOLE == "Y") {
  cat("Main station DJ live vs pre-recorded report flag:\n")
  cat("  - MAIN_DJ_LIVE_RECORDED_EXISTS:", MAIN_DJ_LIVE_RECORDED_EXISTS, "\n")
  if (MAIN_DJ_LIVE_RECORDED_EXISTS) {
    cat("  - Number of DJs analyzed:", nrow(main_dj_live_recorded_analysis), "\n")
  }
}

# =============================================================================
# PART 8I: PUBLIC HOLIDAY IMPACT
# =============================================================================

main_public_holiday_impact <- create_impact_analysis(
  data, 
  "public_holiday", 
  1, 
  "Public Holiday",
  "main"
)
  
  PUBLIC_HOLIDAY_IMPACT_EXISTS <- FALSE
  
  # Check if Public Holiday impact analysis has results
  if (exists("main_public_holiday_impact") && 
      is.list(main_public_holiday_impact) && 
      "summary" %in% names(main_public_holiday_impact) && 
      nrow(main_public_holiday_impact$summary) > 0) {
    PUBLIC_HOLIDAY_IMPACT_EXISTS <- TRUE
    cat("✓ Public Holiday impact analysis results available for report\n")
  } else {
    cat("❌ Public Holiday impact analysis - no results for report\n")
  }
  
  if (DEBUG_TO_CONSOLE == "Y") {
    cat("Public Holiday report flag:\n")
    cat("  - PUBLIC_HOLIDAY_IMPACT_EXISTS:", PUBLIC_HOLIDAY_IMPACT_EXISTS, "\n")
  }

# =============================================================================
# PART 8J: SECOND STATION IMPACT ANALYSES (IF ENABLED)
# =============================================================================

if (ANALYSE_SECOND_STATION == "Y") {

  if (exists("data") && nrow(data) > 0) {
    
    cat("Running z-score based track impact analysis for second station...\n")
    
    # Step 1: Calculate z-scores for track impact
    second_track_impact_zscore <- data %>%
      filter(!is.na(second_artist), second_artist != "", second_artist != "Unknown") %>%
      filter(!is.na(second_song), second_song != "", second_song != "Unknown") %>%
      # Join with baseline statistics
      left_join(second_hourly_baseline_stats, by = c("hour", "day_type")) %>%
      # Only include observations where we have baseline stats
      filter(!is.na(second_hour_mean), !is.na(second_hour_sd), second_hour_sd > 0) %>%
      # Calculate z-score for each observation
      mutate(
        second_listener_zscore = (second_total_listeners - second_hour_mean) / second_hour_sd
      ) %>%
      # Group by track and calculate average impact
      group_by(second_artist, second_song) %>%
      summarise(
        second_plays = n(),
        second_avg_zscore_impact = mean(second_listener_zscore, na.rm = TRUE),
        second_avg_listeners = mean(second_total_listeners, na.rm = TRUE),
        second_zscore_consistency = sd(second_listener_zscore, na.rm = TRUE),
        .groups = 'drop'
      ) %>%
      # Filter for tracks with sufficient plays
      filter(second_plays >= 3) %>%
      # Create track identifier
      mutate(
        second_track = paste(second_artist, "-", second_song),
        # Categorize impact
        second_zscore_impact_category = case_when(
          second_avg_zscore_impact > 1.0 ~ "High Positive Impact",
          second_avg_zscore_impact > 0.5 ~ "Moderate Positive Impact", 
          second_avg_zscore_impact > -0.5 ~ "Neutral Impact",
          second_avg_zscore_impact > -1.0 ~ "Moderate Negative Impact",
          TRUE ~ "High Negative Impact"
        )
      ) %>%
      arrange(desc(second_avg_zscore_impact))
    
    # Step 2: Create summary for most/least impactful tracks
    if (nrow(second_track_impact_zscore) > 0) {
      
      # Top 15 most positive impact tracks
      second_top_tracks_zscore <- second_track_impact_zscore %>%
        filter(second_avg_zscore_impact > 0) %>%
        head(15) %>%
        mutate(
          second_avg_zscore_impact = round(second_avg_zscore_impact, 2),
          second_avg_listeners = round(second_avg_listeners, 0),
          second_zscore_consistency = round(second_zscore_consistency, 2)
        )
      
      # Bottom 15 most negative impact tracks  
      second_bottom_tracks_zscore <- second_track_impact_zscore %>%
        filter(second_avg_zscore_impact < 0) %>%
        tail(15) %>%
        arrange(second_avg_zscore_impact) %>%
        mutate(
          second_avg_zscore_impact = round(second_avg_zscore_impact, 2),
          second_avg_listeners = round(second_avg_listeners, 0),
          second_zscore_consistency = round(second_zscore_consistency, 2)
        )
      
      # Extract 30 most played tracks from z-score analysis
      if (exists("second_track_impact_zscore") && nrow(second_track_impact_zscore) > 0) {
        
        second_most_played_tracks_zscore <- second_track_impact_zscore %>%
          arrange(desc(second_plays)) %>%
          head(30) %>%
          mutate(
            second_avg_zscore_impact = round(second_avg_zscore_impact, 2),
            second_avg_listeners = round(second_avg_listeners, 0),
            second_zscore_consistency = round(second_zscore_consistency, 2),
            # Add rank for display
            second_play_rank = row_number()
          ) %>%
          select(second_play_rank, second_track, second_plays, second_avg_zscore_impact, 
                 second_avg_listeners, second_zscore_consistency, second_zscore_impact_category)
        
        cat("✓ Most played tracks (z-score analysis) extracted:", nrow(second_most_played_tracks_zscore), "tracks\n")
        
      } else {
        second_most_played_tracks_zscore <- data.frame()
        cat("❌ No z-score track data available for most played analysis\n")
      }
      
      cat("✓ Z-score track impact analysis completed\n")
      cat("  - Tracks analyzed:", nrow(second_track_impact_zscore), "\n")
      cat("  - Positive impact tracks:", sum(second_track_impact_zscore$second_avg_zscore_impact > 0), "\n")
      cat("  - Negative impact tracks:", sum(second_track_impact_zscore$second_avg_zscore_impact < 0), "\n")
      
    } else {
      cat("❌ Insufficient data for z-score track impact analysis\n")
      second_top_tracks_zscore <- data.frame()
      second_bottom_tracks_zscore <- data.frame()
    }
    
  } else {
    cat("❌ No data available for z-score track impact analysis\n")
    second_track_impact_zscore <- data.frame()
    second_top_tracks_zscore <- data.frame()
    second_bottom_tracks_zscore <- data.frame()
  }

  if (exists("second_hourly_baseline_stats") && nrow(second_hourly_baseline_stats) > 0) {
    
    cat("Running z-score based artist impact analysis for second station...\n")
    
    # Calculate z-scores for artist impact
    second_artist_impact_zscore <- data %>%
      filter(!is.na(second_artist), second_artist != "", 
             second_artist != "Unknown", second_artist != "Unknown Artist", second_artist != "-") %>%
      # Join with baseline statistics
      left_join(second_hourly_baseline_stats, by = c("hour", "day_type")) %>%
      # Only include observations where we have baseline stats
      filter(!is.na(second_hour_mean), !is.na(second_hour_sd), second_hour_sd > 0) %>%
      # Calculate z-score for each observation
      mutate(
        second_listener_zscore = (second_total_listeners - second_hour_mean) / second_hour_sd
      ) %>%
      # Group by artist and calculate average impact
      group_by(second_artist) %>%
      summarise(
        second_plays = n(),
        second_avg_zscore_impact = mean(second_listener_zscore, na.rm = TRUE),
        second_avg_listeners = mean(second_total_listeners, na.rm = TRUE),
        second_zscore_consistency = sd(second_listener_zscore, na.rm = TRUE),
        .groups = 'drop'
      ) %>%
      # Filter for artists with sufficient plays
      filter(second_plays >= 5) %>%
      # Categorize impact
      mutate(
        second_zscore_impact_category = case_when(
          second_avg_zscore_impact > 1.0 ~ "High Positive Impact",
          second_avg_zscore_impact > 0.5 ~ "Moderate Positive Impact", 
          second_avg_zscore_impact > -0.5 ~ "Neutral Impact",
          second_avg_zscore_impact > -1.0 ~ "Moderate Negative Impact",
          TRUE ~ "High Negative Impact"
        )
      ) %>%
      arrange(desc(second_avg_zscore_impact))
    
    # Top and bottom artists
    if (nrow(second_artist_impact_zscore) > 0) {
      second_top_artists_zscore <- second_artist_impact_zscore %>%
        filter(second_avg_zscore_impact > 0) %>%
        head(15) %>%
        mutate(
          second_avg_zscore_impact = round(second_avg_zscore_impact, 2),
          second_avg_listeners = round(second_avg_listeners, 0)
        )
      
      second_bottom_artists_zscore <- second_artist_impact_zscore %>%
        filter(second_avg_zscore_impact < 0) %>%
        tail(15) %>%
        arrange(second_avg_zscore_impact) %>%
        mutate(
          second_avg_zscore_impact = round(second_avg_zscore_impact, 2),
          second_avg_listeners = round(second_avg_listeners, 0)
        )
      
      cat("✓ Z-score artist impact analysis completed\n")
      cat("  - Artists analyzed:", nrow(second_artist_impact_zscore), "\n")
      
    } else {
      second_top_artists_zscore <- data.frame()
      second_bottom_artists_zscore <- data.frame()
    }
    
  } else {
    second_artist_impact_zscore <- data.frame()
    second_top_artists_zscore <- data.frame()
    second_bottom_artists_zscore <- data.frame()
  }
  
  if (exists("second_hourly_baseline_stats") && nrow(second_hourly_baseline_stats) > 0) {
    
    cat("Running z-score based genre impact analysis for second station...\n")
    
    # Calculate z-scores for genre impact
    second_genre_impact_zscore <- data %>%
      filter(!is.na(second_genre), second_genre != "", second_genre != "-") %>%
      # Join with baseline statistics
      left_join(second_hourly_baseline_stats, by = c("hour", "day_type")) %>%
      # Only include observations where we have baseline stats
      filter(!is.na(second_hour_mean), !is.na(second_hour_sd), second_hour_sd > 0) %>%
      # Calculate z-score for each observation
      mutate(
        second_listener_zscore = (second_total_listeners - second_hour_mean) / second_hour_sd
      ) %>%
      # Group by genre and calculate average impact
      group_by(second_genre) %>%
      summarise(
        second_plays = n(),
        second_avg_zscore_impact = mean(second_listener_zscore, na.rm = TRUE),
        second_avg_listeners = mean(second_total_listeners, na.rm = TRUE),
        second_zscore_consistency = sd(second_listener_zscore, na.rm = TRUE),
        .groups = 'drop'
      ) %>%
      # Filter for genres with sufficient plays
      filter(second_plays >= 10) %>%
      arrange(desc(second_avg_zscore_impact))
    
    # Top and bottom genres
    if (nrow(second_genre_impact_zscore) > 0) {
      second_top_genres_zscore <- second_genre_impact_zscore %>%
        filter(second_avg_zscore_impact > 0) %>%
        head(10) %>%
        mutate(
          second_avg_zscore_impact = round(second_avg_zscore_impact, 2),
          second_avg_listeners = round(second_avg_listeners, 0)
        )
      
      second_bottom_genres_zscore <- second_genre_impact_zscore %>%
        filter(second_avg_zscore_impact < 0) %>%
        tail(10) %>%
        arrange(second_avg_zscore_impact) %>%
        mutate(
          second_avg_zscore_impact = round(second_avg_zscore_impact, 2),
          second_avg_listeners = round(second_avg_listeners, 0)
        )
      
      cat("✓ Z-score genre impact analysis completed\n")
      cat("  - Genres analyzed:", nrow(second_genre_impact_zscore), "\n")
      
    } else {
      second_top_genres_zscore <- data.frame()
      second_bottom_genres_zscore <- data.frame()
    }
    
  } else {
    second_genre_impact_zscore <- data.frame()
    second_top_genres_zscore <- data.frame()
    second_bottom_genres_zscore <- data.frame()
  }
  
  if (exists("second_hourly_baseline_stats") && nrow(second_hourly_baseline_stats) > 0) {
    
    cat("Running z-score based hourly genre performance analysis for second station...\n")
    
    # Calculate z-scores for genre performance by hour
    second_hourly_genre_zscore <- data %>%
      filter(!is.na(second_genre), second_genre != "", second_genre != "-") %>%
      # Join with baseline statistics
      left_join(second_hourly_baseline_stats, by = c("hour", "day_type")) %>%
      # Only include observations where we have baseline stats
      filter(!is.na(second_hour_mean), !is.na(second_hour_sd), second_hour_sd > 0) %>%
      # Calculate z-score for each observation
      mutate(
        second_listener_zscore = (second_total_listeners - second_hour_mean) / second_hour_sd
      ) %>%
      # Group by hour and genre
      group_by(hour, second_genre) %>%
      summarise(
        second_plays = n(),
        second_avg_zscore_impact = mean(second_listener_zscore, na.rm = TRUE),
        second_avg_listeners = mean(second_total_listeners, na.rm = TRUE),
        .groups = 'drop'
      ) %>%
      # Filter for genre-hour combinations with sufficient data
      filter(second_plays >= 5) %>%
      # For each hour, find best and worst genres
      group_by(hour) %>%
      arrange(desc(second_avg_zscore_impact)) %>%
      mutate(
        second_genre_rank = row_number(),
        second_total_genres = n()
      ) %>%
      ungroup() %>%
      # Extract best and worst for each hour (if we have enough genres)
      filter((second_genre_rank == 1 | second_genre_rank == second_total_genres) & second_total_genres >= 3) %>%
      mutate(
        second_performance_type = ifelse(second_genre_rank == 1, "Best", "Worst"),
        second_avg_zscore_impact = round(second_avg_zscore_impact, 2)
      ) %>%
      arrange(hour, second_performance_type)
    
    if (nrow(second_hourly_genre_zscore) > 0) {
      cat("✓ Z-score hourly genre performance analysis completed\n")
      cat("  - Hour-genre combinations analyzed:", nrow(second_hourly_genre_zscore), "\n")
    } else {
      cat("❌ Insufficient data for hourly genre performance analysis\n")
    }
    
  } else {
    second_hourly_genre_zscore <- data.frame()
  }
  
  if (exists("second_hourly_baseline_stats") && nrow(second_hourly_baseline_stats) > 0) {
    
    cat("Running z-score based hourly genre heatmap analysis for second station...\n")
    
    # Calculate z-scores for ALL genre-hour combinations for heatmap
    second_genre_hour_heatmap_zscore <- data %>%
      filter(!is.na(second_genre), second_genre != "", second_genre != "-") %>%
      # Join with baseline statistics
      left_join(second_hourly_baseline_stats, by = c("hour", "day_type")) %>%
      # Only include observations where we have baseline stats
      filter(!is.na(second_hour_mean), !is.na(second_hour_sd), second_hour_sd > 0) %>%
      # Calculate z-score for each observation
      mutate(
        second_listener_zscore = (second_total_listeners - second_hour_mean) / second_hour_sd
      ) %>%
      # Group by hour and genre
      group_by(hour, second_genre) %>%
      summarise(
        second_plays = n(),
        second_avg_zscore_impact = mean(second_listener_zscore, na.rm = TRUE),
        .groups = 'drop'
      ) %>%
      # Filter for combinations with sufficient data
      filter(second_plays >= 3)
    
    # Get the top 15 genres by total plays
    top_genres <- second_genre_hour_heatmap_zscore %>%
      group_by(second_genre) %>%
      summarise(total_plays = sum(second_plays), .groups = 'drop') %>%
      arrange(desc(total_plays)) %>%
      head(15) %>%
      pull(second_genre)
    
    # Filter for top genres and reasonable hours
    second_genre_hour_heatmap_zscore <- second_genre_hour_heatmap_zscore %>%
      filter(second_genre %in% top_genres,
             hour >= 0, hour <= 24) %>%
      # Round for display
      mutate(second_avg_zscore_impact = round(second_avg_zscore_impact, 2))
    
    if (nrow(second_genre_hour_heatmap_zscore) > 0) {
      cat("✓ Z-score genre-hour heatmap data created\n")
      cat("  - Genre-hour combinations:", nrow(second_genre_hour_heatmap_zscore), "\n")
      cat("  - Genres included:", length(unique(second_genre_hour_heatmap_zscore$second_genre)), "\n")
    } else {
      cat("❌ Insufficient data for genre-hour heatmap\n")
    }
    
  } else {
    second_genre_hour_heatmap_zscore <- data.frame()
  }

  # Step 1: Identify sitting-in presenters using the stand_in column
  second_sitting_in_data <- data %>%
    filter(!is.na(second_showname), second_showname != "", second_stand_in == 1) %>%
    filter(!grepl(paste(EXCLUDE_TERMS, collapse = "|"), second_showname, ignore.case = TRUE)) %>%
    select(date, hour, minute, second_showname, second_presenter, second_total_listeners, weekday, day_type) %>%
    mutate(
      # Create unique time slot identifier (date + hour + minute for precision)
      timeslot_key = paste(weekday, hour, minute, sep = "_"),
      sitting_in_presenter = second_presenter
    )
  
  if (nrow(second_sitting_in_data) > 0) {
    
    # Step 2: Find regular shows that normally run at the same time slots
    second_regular_shows_lookup <- data %>%
      filter(!is.na(second_showname), second_showname != "", second_stand_in != 1) %>%
      filter(!grepl(paste(EXCLUDE_TERMS, collapse = "|"), second_showname, ignore.case = TRUE)) %>%
      mutate(timeslot_key = paste(weekday, hour, minute, sep = "_")) %>%
      # Only look at time slots where we have sitting-in shows
      filter(timeslot_key %in% second_sitting_in_data$timeslot_key) %>%
      group_by(timeslot_key, weekday, hour, minute, second_showname, second_presenter) %>%
      summarise(
        second_appearances = n(),
        second_avg_listeners = mean(second_total_listeners, na.rm = TRUE),
        .groups = "drop"
      ) %>%
      # For each time slot, find the most common regular show/presenter combination
      group_by(timeslot_key) %>%
      filter(second_appearances == max(second_appearances)) %>%
      slice(1) %>%  # Take first if tied
      ungroup() %>%
      select(timeslot_key, weekday, hour, minute, 
             regular_showname = second_showname, regular_presenter = second_presenter, 
             regular_appearances = second_appearances, regular_avg_listeners = second_avg_listeners)
    
    # Step 3: Create sitting-in vs regular comparisons
    second_sitting_in_comparisons <- second_sitting_in_data %>%
      inner_join(second_regular_shows_lookup, by = "timeslot_key") %>%
      filter(sitting_in_presenter != regular_presenter) %>%  # Ensure different presenters
      filter(regular_appearances >= 1) %>%  # Regular show must have appeared multiple times
      mutate(
        second_pct_difference = ((second_total_listeners - regular_avg_listeners) / regular_avg_listeners) * 100
      )
    
    # Step 4: Summarize sitting-in performance by show
    if (nrow(second_sitting_in_comparisons) > 0) {
      second_sitting_in_show_summary <- second_sitting_in_comparisons %>%
        group_by(regular_showname, regular_presenter, sitting_in_presenter) %>%
        summarise(
          second_episodes_compared = n(),  # This is "timeslots_compared" equivalent
          second_avg_pct_difference = mean(second_pct_difference, na.rm = TRUE),
          second_median_pct_difference = median(second_pct_difference, na.rm = TRUE),
          second_best_performance = max(second_pct_difference, na.rm = TRUE),
          second_worst_performance = min(second_pct_difference, na.rm = TRUE),
          second_sitting_in_wins = sum(second_pct_difference > 0),
          second_regular_wins = sum(second_pct_difference < 0),
          second_ties = sum(second_pct_difference == 0),
          second_weekdays_analyzed = paste(sort(unique(weekday.x)), collapse = ", "),
          second_avg_sitting_in_listeners = mean(second_total_listeners, na.rm = TRUE),
          .groups = "drop"
        ) %>%
        mutate(
          # Calculate performance summary after grouping
          second_performance_summary = case_when(
            second_avg_pct_difference > 5 ~ "Sitting-in Much Better (+5%)",
            second_avg_pct_difference > 0 ~ "Sitting-in Slightly Better",
            second_avg_pct_difference > -5 ~ "Regular Slightly Better", 
            TRUE ~ "Regular Much Better (-5%)"
          )
        ) %>%
        filter(second_episodes_compared >= 2) %>%  # Need multiple episodes for comparison
        arrange(desc(second_avg_pct_difference))
    } else {
      second_sitting_in_show_summary <- data.frame()
    }
  } else {
    second_sitting_in_comparisons <- data.frame()
    second_sitting_in_show_summary <- data.frame()
  }
  
  if (ANALYSE_SECOND_STATION == "Y") {
    if (exists("second_sitting_in_show_summary") && 
        is.data.frame(second_sitting_in_show_summary) && 
        nrow(second_sitting_in_show_summary) > 0) {
      SECOND_SITTING_IN_EXISTS <- TRUE
      cat("✓ Second station sitting-in vs regular analysis results available for report\n")
    } else {
      SECOND_SITTING_IN_EXISTS <- FALSE
      cat("❌ Second station sitting-in vs regular analysis - no results for report\n")
    }
  } else {
    SECOND_SITTING_IN_EXISTS <- FALSE
  }
  
  if (DEBUG_TO_CONSOLE == "Y") {
    cat("Sitting-in analysis report flags:\n")
    cat("  - MAIN_SITTING_IN_EXISTS:", MAIN_SITTING_IN_EXISTS, "\n")
    if (ANALYSE_SECOND_STATION == "Y") {
      cat("  - SECOND_SITTING_IN_EXISTS:", SECOND_SITTING_IN_EXISTS, "\n")
    }
  }
  
  # Step 1: Filter to time slots that have BOTH live and recorded shows with sufficient data
  second_valid_timeslots <- data %>%
    filter(!is.na(second_recorded), second_recorded %in% c(0, 1)) %>%
    group_by(hour, day_type, second_live_recorded) %>%
    summarise(second_sessions = n(), .groups = "drop") %>%
    # Only keep time slots where BOTH live and pre-recorded have ≥3 sessions
    group_by(hour, day_type) %>%
    filter(n() == 2, all(second_sessions >= 3)) %>%  # Must have exactly 2 types (Live + Pre-recorded), both with ≥3 sessions
    select(hour, day_type) %>%
    distinct()
  
  # Step 2: Calculate live vs recorded performance for valid time slots only
  second_live_recorded_analysis <- data %>%
    filter(!is.na(second_recorded), second_recorded %in% c(0, 1)) %>%
    inner_join(second_valid_timeslots, by = c("hour", "day_type")) %>%
    group_by(second_live_recorded, hour, day_type) %>%
    summarise(
      second_avg_listeners = mean(second_total_listeners, na.rm = TRUE),
      second_sessions = n(),
      .groups = 'drop'
    )
  
  # Step 3: Calculate baseline and performance
  if (nrow(second_live_recorded_analysis) > 0) {
    second_lr_hourly_baseline <- second_live_recorded_analysis %>%
      group_by(hour, day_type) %>%
      summarise(
        second_hour_avg = mean(second_avg_listeners),  # Simple average of live and pre-recorded
        .groups = 'drop'
      )
    
    second_live_recorded_performance <- second_live_recorded_analysis %>%
      left_join(second_lr_hourly_baseline, by = c("hour", "day_type")) %>%
      mutate(
        second_pct_vs_hour = ((second_avg_listeners - second_hour_avg) / second_hour_avg) * 100
      )
    
    # Summary statistics
    second_live_recorded_summary <- second_live_recorded_performance %>%
      group_by(second_live_recorded, day_type) %>%
      summarise(
        second_avg_performance = mean(second_pct_vs_hour, na.rm = TRUE),
        second_total_sessions = sum(second_sessions),
        second_avg_listeners = mean(second_avg_listeners, na.rm = TRUE),
        second_time_slots = n(),
        .groups = 'drop'
      ) %>%
      mutate(
        second_airtime_hours = round(second_total_sessions / HOUR_NORMALISATION, 0)
      ) %>%
      arrange(day_type, desc(second_avg_performance))
  } else {
    second_live_recorded_summary <- data.frame()
  }
  
  if (ANALYSE_SECOND_STATION == "Y") {
    if (exists("second_live_recorded_summary") && 
        is.data.frame(second_live_recorded_summary) && 
        nrow(second_live_recorded_summary) > 0) {
      SECOND_LIVE_RECORDED_EXISTS <- TRUE
      cat("✓ Second station live vs pre-recorded analysis results available for report\n")
    } else {
      SECOND_LIVE_RECORDED_EXISTS <- FALSE
      cat("❌ Second station live vs pre-recorded analysis - no results for report\n")
    }
  } else {
    SECOND_LIVE_RECORDED_EXISTS <- FALSE
  }
  
  if (DEBUG_TO_CONSOLE == "Y") {
    cat("Live vs pre-recorded analysis report flags:\n")
    cat("  - MAIN_LIVE_RECORDED_EXISTS:", MAIN_LIVE_RECORDED_EXISTS, "\n")
    if (ANALYSE_SECOND_STATION == "Y") {
      cat("  - SECOND_LIVE_RECORDED_EXISTS:", SECOND_LIVE_RECORDED_EXISTS, "\n")
    }
  }
  
  # This framework can be used for any binary condition (e.g., Public Holiday)
  create_impact_analysis <- function(data_df, condition_column, condition_value, condition_name, station_prefix = "second") {
    
    # Create column names dynamically
    total_listeners_col <- paste0(station_prefix, "_total_listeners")
    
    # Check if condition column exists
    if (!condition_column %in% names(data_df)) {
      cat("Warning: Column", condition_column, "not found. Skipping", condition_name, "analysis.\n")
      return(data.frame())
    }
    
    # Filter and analyze
    impact_data <- data_df %>%
      filter(!is.na(.data[[condition_column]])) %>%
      mutate(
        condition_active = .data[[condition_column]] == condition_value,
        condition_type = ifelse(condition_active, condition_name, paste("Non", condition_name))
      ) %>%
      group_by(condition_type, hour, day_type) %>%
      summarise(
        avg_listeners = mean(.data[[total_listeners_col]], na.rm = TRUE),
        sessions = n(),
        .groups = 'drop'
      ) %>%
      filter(sessions >= 3) %>%  # Minimum sessions for reliability
      group_by(hour, day_type) %>%
      # Only analyze hours that have both condition and non-condition data
      filter(n() == 2) %>%
      mutate(
        hour_baseline = mean(avg_listeners),
        pct_vs_baseline = ((avg_listeners - hour_baseline) / hour_baseline) * 100
      ) %>%
      ungroup()
    
    if (nrow(impact_data) > 0) {
      # Summary by condition and day type
      impact_summary <- impact_data %>%
        group_by(condition_type, day_type) %>%
        summarise(
          avg_performance = mean(pct_vs_baseline, na.rm = TRUE),
          total_sessions = sum(sessions),
          avg_listeners = mean(avg_listeners, na.rm = TRUE),
          time_slots = n(),
          .groups = 'drop'
        ) %>%
        mutate(
          airtime_hours = round(total_sessions / HOUR_NORMALISATION, 0)
        ) %>%
        arrange(day_type, desc(avg_performance))
      
      return(list(
        analysis = impact_data,
        summary = impact_summary,
        condition_name = condition_name
      ))
    } else {
      return(data.frame())
    }
  }
  
  # DJ LIVE VS PRE-RECORDED INDIVIDUAL ANALYSIS
  # Filter for second station data and get valid time slots
  
  cat("Checking second station live vs pre-recorded data availability...\n")
  
  # Check data availability upfront
  second_available_types <- data %>%
    filter(!is.na(second_recorded), second_recorded %in% c(0, 1)) %>%
    distinct(second_live_recorded) %>%
    pull(second_live_recorded)
  
  if (length(second_available_types) < 2) {
    cat("Second station: Live vs Pre-recorded analysis skipped - only", 
        paste(second_available_types, collapse = ", "), "shows available\n")
    second_dj_live_recorded_analysis <- data.frame()
    SECOND_DJ_LIVE_RECORDED_EXISTS <- FALSE
  } else {
    cat("Second station: Both live and pre-recorded shows available - proceeding with analysis\n")
    
    # Filter for second station data and get valid time slots
    second_dj_live_recorded_analysis <- data %>%
      filter(!is.na(second_recorded), second_recorded %in% c(0, 1), 
             !is.na(second_presenter), second_presenter != "", second_presenter != "Unknown",
             !is.na(second_showname), second_showname != "",
             second_stand_in != 1) %>%  # Exclude sitting-in DJs
      filter(!grepl(paste(EXCLUDE_TERMS, collapse = "|"), second_showname, ignore.case = TRUE)) %>%
      # Only include time slots that have both live and pre-recorded shows
      group_by(hour, day_type) %>%
      filter(n_distinct(second_live_recorded) == 2) %>%  # Must have both Live and Pre-recorded
      ungroup() %>%
      # Calculate hourly baselines for fair comparison
      group_by(hour, day_type) %>%
      mutate(second_hour_baseline = mean(second_total_listeners, na.rm = TRUE)) %>%
      ungroup() %>%
      # Calculate performance vs hourly average for each session
      mutate(second_pct_vs_hour = ((second_total_listeners - second_hour_baseline) / second_hour_baseline) * 100) %>%
      # Group by presenter and live_recorded status
      group_by(second_presenter, second_live_recorded) %>%
      summarise(
        second_avg_listeners = mean(second_total_listeners, na.rm = TRUE),
        second_avg_performance = mean(second_pct_vs_hour, na.rm = TRUE),
        second_sessions = n(),
        .groups = "drop"
      ) %>%
      # Only keep DJs with sufficient data for both types
      filter(second_sessions >= 3) %>%
      # Check which DJs have both live and pre-recorded data
      group_by(second_presenter) %>%
      filter(n() == 2) %>%  # Must have exactly 2 rows (Live and Pre-recorded)
      ungroup() %>%
      # Reshape to compare live vs pre-recorded for each DJ
      pivot_wider(
        names_from = second_live_recorded,
        values_from = c(second_avg_listeners, second_avg_performance, second_sessions),
        names_sep = "_"
      ) %>%
      # Calculate the difference between live and pre-recorded
      mutate(
        second_performance_difference = `second_avg_performance_Live` - `second_avg_performance_Pre-recorded`,
        second_listener_difference = `second_avg_listeners_Live` - `second_avg_listeners_Pre-recorded`,
        second_total_sessions = `second_sessions_Live` + `second_sessions_Pre-recorded`,
        second_better_when = case_when(
          second_performance_difference > 1 ~ "Live",
          second_performance_difference < -1 ~ "Pre-recorded", 
          TRUE ~ "Similar"
        )
      ) %>%
      # Sort by biggest performance difference
      arrange(desc(abs(second_performance_difference))) %>%
      # Round numbers for display
      mutate(
        `second_avg_performance_Live` = round(`second_avg_performance_Live`, 1),
        `second_avg_performance_Pre-recorded` = round(`second_avg_performance_Pre-recorded`, 1),
        second_performance_difference = round(second_performance_difference, 1),
        `second_avg_listeners_Live` = round(`second_avg_listeners_Live`, 0),
        `second_avg_listeners_Pre-recorded` = round(`second_avg_listeners_Pre-recorded`, 0)
      ) %>%
      # Select columns for the table
      select(second_presenter, `second_sessions_Live`, `second_sessions_Pre-recorded`, 
             `second_avg_performance_Live`, `second_avg_performance_Pre-recorded`, second_performance_difference,
             `second_avg_listeners_Live`, `second_avg_listeners_Pre-recorded`, second_better_when)
    
    # Set flag based on results
    if (exists("second_dj_live_recorded_analysis") && 
        is.data.frame(second_dj_live_recorded_analysis) && 
        nrow(second_dj_live_recorded_analysis) > 0) {
      SECOND_DJ_LIVE_RECORDED_EXISTS <- TRUE
      cat("✓ Second station DJ live vs pre-recorded analysis results available for report\n")
    } else {
      SECOND_DJ_LIVE_RECORDED_EXISTS <- FALSE
      cat("❌ Second station DJ live vs pre-recorded analysis - no results for report\n")
    }
  }
  
  if (DEBUG_TO_CONSOLE == "Y") {
    cat("Second station DJ live vs pre-recorded report flag:\n")
    cat("  - SECOND_DJ_LIVE_RECORDED_EXISTS:", SECOND_DJ_LIVE_RECORDED_EXISTS, "\n")
    if (SECOND_DJ_LIVE_RECORDED_EXISTS) {
      cat("  - Number of DJs analyzed:", nrow(second_dj_live_recorded_analysis), "\n")
    }
  }
  
  cat("Analyzing second station public holiday impact...\n")
  
  # Use the generic function for second station public holiday analysis
  second_public_holiday_impact <- create_impact_analysis(
    data_df = data, 
    condition_column = "public_holiday", 
    condition_value = 1, 
    condition_name = "Public Holiday",
    station_prefix = "second"
  )
  
  # Set flag for report generation
  if (exists("second_public_holiday_impact") && 
      is.list(second_public_holiday_impact) && 
      "summary" %in% names(second_public_holiday_impact) && 
      nrow(second_public_holiday_impact$summary) > 0) {
    SECOND_PUBLIC_HOLIDAY_IMPACT_EXISTS <- TRUE
    cat("✓ Second station public holiday impact analysis results available for report\n")
  } else {
    SECOND_PUBLIC_HOLIDAY_IMPACT_EXISTS <- FALSE
    cat("❌ Second station public holiday impact analysis - no results for report\n")
  }
  
  if (DEBUG_TO_CONSOLE == "Y") {
    cat("Second station public holiday report flag:\n")
    cat("  - SECOND_PUBLIC_HOLIDAY_IMPACT_EXISTS:", SECOND_PUBLIC_HOLIDAY_IMPACT_EXISTS, "\n")
    if (SECOND_PUBLIC_HOLIDAY_IMPACT_EXISTS) {
      cat("  - Number of time slots analyzed:", nrow(second_public_holiday_impact$summary), "\n")
    }
  }

}

# =============================================================================
# PART 8K: COMPLETE GENRE-ARTIST CLASSIFICATION ANALYSIS
# =============================================================================
  
cat("Running Genre-Artist Classification Analysis...\n")
  
# =============================================================================
# MAIN STATION GENRE-ARTIST ANALYSIS
# =============================================================================
  
if ("main_genre" %in% names(data) && "main_artist" %in% names(data)) {
    
  main_genre_artist_analysis <- data %>%
    filter(!is.na(main_genre), main_genre != "", main_genre != "Unknown", main_genre != "-") %>%
    filter(!is.na(main_artist), main_artist != "", main_artist != "Unknown") %>%
    group_by(main_genre, main_artist) %>%
    summarise(
      main_plays = n(),
      main_avg_listeners = mean(main_total_listeners, na.rm = TRUE),
      .groups = 'drop'
    ) %>%
    # Keep only artists with at least 2 plays in each genre
    filter(main_plays >= 2) %>%
    # Create rankings within each genre
    group_by(main_genre) %>%
    arrange(desc(main_plays), desc(main_avg_listeners)) %>%
    mutate(
      main_artist_rank = row_number(),
      main_genre_total_plays = sum(main_plays)
    ) %>%
    ungroup()
    
    # Create summary table with top 5 artists per genre
    main_genre_artist_summary <- main_genre_artist_analysis %>%
      filter(main_artist_rank <= 5) %>%  # Top 5 artists per genre
      group_by(main_genre) %>%
      arrange(main_artist_rank) %>%
      summarise(
        main_total_plays = first(main_genre_total_plays),
        main_top_artists = paste(paste0(main_artist, " (", main_plays, ")"), collapse = ", "),
        main_unique_artists = n(),
        .groups = 'drop'
      ) %>%
      arrange(desc(main_total_plays)) %>%
      # Add ranking for genres by total plays
      mutate(main_genre_rank = row_number())
    
    cat("Main station: Created genre-artist analysis for", nrow(main_genre_artist_summary), "genres\n")
    
  } else {
    main_genre_artist_summary <- data.frame()
    cat("Main station: No genre/artist data available\n")
  }
  
  # =============================================================================
  # SECOND STATION GENRE-ARTIST ANALYSIS (IF ENABLED)
  # =============================================================================
  
  if (ANALYSE_SECOND_STATION == "Y" && "second_genre" %in% names(data) && "second_artist" %in% names(data)) {
    
    second_genre_artist_analysis <- data %>%
      filter(!is.na(second_genre), second_genre != "", second_genre != "Unknown", second_genre != "-") %>%
      filter(!is.na(second_artist), second_artist != "", second_artist != "Unknown") %>%
      group_by(second_genre, second_artist) %>%
      summarise(
        second_plays = n(),
        second_avg_listeners = mean(second_total_listeners, na.rm = TRUE),
        .groups = 'drop'
      ) %>%
      # Keep only artists with at least 2 plays in each genre
      filter(second_plays >= 2) %>%
      # Create rankings within each genre
      group_by(second_genre) %>%
      arrange(desc(second_plays), desc(second_avg_listeners)) %>%
      mutate(
        second_artist_rank = row_number(),
        second_genre_total_plays = sum(second_plays)
      ) %>%
      ungroup()
    
    # Create summary table with top 5 artists per genre
    second_genre_artist_summary <- second_genre_artist_analysis %>%
      filter(second_artist_rank <= 5) %>%  # Top 5 artists per genre
      group_by(second_genre) %>%
      arrange(second_artist_rank) %>%
      summarise(
        second_total_plays = first(second_genre_total_plays),
        second_top_artists = paste(paste0(second_artist, " (", second_plays, ")"), collapse = ", "),
        second_unique_artists = n(),
        .groups = 'drop'
      ) %>%
      arrange(desc(second_total_plays)) %>%
      # Add ranking for genres by total plays
      mutate(second_genre_rank = row_number())

    cat("Second station: Created genre-artist analysis for", nrow(second_genre_artist_summary), "genres\n")
    
  } else {
    second_genre_artist_summary <- data.frame()
    if (ANALYSE_SECOND_STATION == "Y") {
      cat("Second station: No genre/artist data available\n")
    }
  }
  
  # =============================================================================
  # COMPARISON STATION GENRE-ARTIST ANALYSIS (IF ENABLED)
  # =============================================================================
  
  if (ANALYSE_COMPARISON_STATION == "Y" && "comparison_genre" %in% names(data) && "comparison_artist" %in% names(data)) {
    
    comparison_genre_artist_analysis <- data %>%
      filter(!is.na(comparison_genre), comparison_genre != "", comparison_genre != "Unknown", comparison_genre != "-") %>%
      filter(!is.na(comparison_artist), comparison_artist != "", comparison_artist != "Unknown") %>%
      group_by(comparison_genre, comparison_artist) %>%
      summarise(
        comparison_plays = n(),
        comparison_avg_listeners = mean(comparison_total_listeners, na.rm = TRUE),
        .groups = 'drop'
      ) %>%
      filter(comparison_plays >= 2) %>%
      group_by(comparison_genre) %>%
      arrange(desc(comparison_plays), desc(comparison_avg_listeners)) %>%
      mutate(
        comparison_artist_rank = row_number(),
        comparison_genre_total_plays = sum(comparison_plays)
      ) %>%
      ungroup()
    
    comparison_genre_artist_summary <- comparison_genre_artist_analysis %>%
      filter(comparison_artist_rank <= 5) %>%
      group_by(comparison_genre) %>%
      arrange(comparison_artist_rank) %>%
      summarise(
        comparison_total_plays = first(comparison_genre_total_plays),
        comparison_top_artists = paste(paste0(comparison_artist, " (", comparison_plays, ")"), collapse = ", "),
        comparison_unique_artists = n(),
        .groups = 'drop'
      ) %>%
      arrange(desc(comparison_total_plays)) %>%
      mutate(comparison_genre_rank = row_number())
    
    cat("Comparison station: Created genre-artist analysis for", nrow(comparison_genre_artist_summary), "genres\n")
    
  } else {
    comparison_genre_artist_summary <- data.frame()
    if (ANALYSE_COMPARISON_STATION == "Y") {
      cat("Comparison station: No genre/artist data available\n")
    }
  }
  
  cat("Genre-Artist classification analysis complete!\n")

# =============================================================================
# ANALYSIS 8 COMPLETE
# =============================================================================

cat("Analysis 8 complete! Created impact analyses:\n")

if (DEBUG_TO_CONSOLE == "Y") {
  cat("Main station impact analyses:\n")
  
  if (exists("main_track_impact") && nrow(main_track_impact) > 0) {
    cat("  - Track impact: ", nrow(main_track_impact), " tracks analyzed\n")
  }
  
  if (exists("main_artist_impact") && nrow(main_artist_impact) > 0) {
    cat("  - Artist impact: ", nrow(main_artist_impact), " artists analyzed\n")
  }
  
  if (exists("main_genre_impact") && nrow(main_genre_impact) > 0) {
    cat("  - Genre impact: ", nrow(main_genre_impact), " genres analyzed\n")
  }
  
  if (exists("main_sitting_in_show_summary") && nrow(main_sitting_in_show_summary) > 0) {
    cat("  - Sitting-in analysis: ", nrow(main_sitting_in_show_summary), " comparisons found\n")
  } else {
    cat("  - Sitting-in analysis: No valid comparisons found\n")
  }
  
  if (exists("main_live_recorded_summary") && nrow(main_live_recorded_summary) > 0) {
    cat("  - Live vs recorded: ", nrow(main_live_recorded_summary), " conditions analyzed\n")
  }
  
  if (is.list(main_public_holiday_impact) && "summary" %in% names(main_public_holiday_impact)) {
    cat("  - Public holiday impact: Analysis completed\n")
  } else {
    cat("  - Public holiday impact: No data or insufficient data\n")
  }
}

# =============================================================================
# ANALYSIS 9: WEATHER IMPACT ANALYSIS (HIGHLY SPECULATIVE! 🌦️)
# =============================================================================
# This exploratory analysis examines whether weather conditions affect radio listening behaviour
# It's a "shot-in-the-dark" investigation into environmental influences on audience engagement
# These findings should be interpreted VERY cautiously! 
# Environmental factors may correlate with other variables (holidays, programming, etc.)
# rather than directly causing listener behaviour changes

cat("Running Analysis 9: Weather Impact Analysis (Highly Speculative!)...\n")
cat("⚠️  REMEMBER: Correlation ≠ Causation! Weather effects are likely coincidental! ⚠️\n")

# =============================================================================
# PART 9A: CHECK WEATHER DATA AVAILABILITY
# =============================================================================

# Check if weather columns exist in the data
weather_columns <- c("weather_temp", "weather_condition", "weather_rain", "sunrise_time", "sunset_time")
missing_columns <- weather_columns[!weather_columns %in% names(data)]

if (length(missing_columns) > 0) {
  cat("Warning: Missing weather columns:", paste(missing_columns, collapse = ", "), "\n")
  cat("Weather analysis will be limited or skipped.\n")
  
  # Create empty results for missing data
  main_weather_summary_stats <- list(
    analysis_available = FALSE,
    missing_columns = missing_columns,
    message = "Weather data not available in dataset"
  )
  
} else {
  
  # =============================================================================
  # PART 9B: PREPARE WEATHER DATA
  # =============================================================================
  
  # Clean and prepare weather data
  main_weather_data <- data %>%
    filter(!is.na(weather_temp)) %>%  # Remove temperature requirement temporarily
    filter(!is.na(sunrise_time), !is.na(sunset_time)) %>%
    mutate(
      # Enhanced weather categorization with better N/A handling
      weather_category = case_when(
        # Handle missing/null weather conditions first
        is.na(weather_condition) | weather_condition == "" | weather_condition == "NULL" ~ "Unknown",
        
        # Clear conditions (multiple variations)
        grepl("clear|sun|bright", weather_condition, ignore.case = TRUE) ~ "Clear/Sunny",
        
        # Cloudy conditions
        grepl("partly.*cloud|few.*cloud|scattered.*cloud", weather_condition, ignore.case = TRUE) ~ "Partly Cloudy",
        grepl("cloud|overcast|grey|gray", weather_condition, ignore.case = TRUE) ~ "Cloudy/Overcast",
        
        # Rain conditions
        grepl("drizzle|light.*rain|sprinkle", weather_condition, ignore.case = TRUE) ~ "Light Rain",
        grepl("rain|shower|precipitation", weather_condition, ignore.case = TRUE) ~ "Rain",
        grepl("heavy.*rain|downpour|torrent", weather_condition, ignore.case = TRUE) ~ "Heavy Rain",
        
        # Storm conditions
        grepl("storm|thunder|lightning", weather_condition, ignore.case = TRUE) ~ "Thunderstorm",
        
        # Winter conditions
        grepl("snow|sleet|ice|freeze|frost", weather_condition, ignore.case = TRUE) ~ "Snow/Ice",
        
        # Visibility conditions
        grepl("fog|mist|haze", weather_condition, ignore.case = TRUE) ~ "Fog/Mist",
        
        # Windy conditions
        grepl("wind|gust|breez", weather_condition, ignore.case = TRUE) ~ "Windy",
        
        # Hot conditions
        grepl("hot|heat|scorch", weather_condition, ignore.case = TRUE) ~ "Hot",
        
        # Default for anything else
        TRUE ~ "Other"
      ),
      
      # Calculate daylight hours with error handling
      sunrise_time_num = case_when(
        is.na(sunrise_time) ~ NA_real_,
        TRUE ~ as.numeric(hms(sunrise_time)) / 3600
      ),
      sunset_time_num = case_when(
        is.na(sunset_time) ~ NA_real_,
        TRUE ~ as.numeric(hms(sunset_time)) / 3600
      ),
      daylight_hours = case_when(
        is.na(sunrise_time_num) | is.na(sunset_time_num) ~ NA_real_,
        TRUE ~ sunset_time_num - sunrise_time_num
      ),
      
      # Temperature categories with better handling
      temp_category = case_when(
        is.na(weather_temp) ~ "Unknown Temperature",
        weather_temp < 5 ~ "Very Cold (< 5°C)",
        weather_temp < 10 ~ "Cold (5-10°C)", 
        weather_temp < 15 ~ "Cool (10-15°C)",
        weather_temp < 20 ~ "Mild (15-20°C)",
        weather_temp < 25 ~ "Warm (20-25°C)",
        weather_temp < 30 ~ "Hot (25-30°C)",
        TRUE ~ "Very Hot (> 30°C)"
      ),
      
      # Determine if current time is daylight with error handling
      current_hour_num = hour + minute/60,
      is_daylight = case_when(
        is.na(sunrise_time_num) | is.na(sunset_time_num) ~ NA,
        TRUE ~ current_hour_num >= sunrise_time_num & current_hour_num <= sunset_time_num
      ),
      
      # Rain categories with better N/A handling
      rain_category = case_when(
        is.na(weather_rain) ~ "Unknown Rain",
        weather_rain <= 0 ~ "No Rain",
        weather_rain <= 1 ~ "Light Rain (< 1mm)",
        weather_rain <= 5 ~ "Moderate Rain (1-5mm)",
        weather_rain <= 10 ~ "Heavy Rain (5-10mm)",
        TRUE ~ "Very Heavy Rain (> 10mm)"
      )
    )

  # =============================================================================
  # PART 9C: WEATHER CONDITIONS IMPACT
  # =============================================================================
  
  # Overall weather condition impact summary
  main_weather_summary <- main_weather_data %>%
    group_by(weather_category) %>%
    summarise(
      main_avg_listeners = mean(main_total_listeners, na.rm = TRUE),
      second_avg_listeners = if(ANALYSE_SECOND_STATION == "Y") mean(second_total_listeners, na.rm = TRUE) else NA,
      main_avg_temp = mean(weather_temp, na.rm = TRUE),
      main_days = n_distinct(date),
      main_observations = n(),
      .groups = 'drop'
    ) %>%
    filter(main_observations >= 50) %>%  # Only weather types with sufficient data
    mutate(
      # Calculate vs overall baseline
      main_overall_baseline = mean(main_weather_data$main_total_listeners, na.rm = TRUE),
      main_vs_baseline = ((main_avg_listeners - main_overall_baseline) / main_overall_baseline) * 100
    )
  
  # Add second station if enabled
  if (ANALYSE_SECOND_STATION == "Y") {
    main_weather_summary <- main_weather_summary %>%
      mutate(
        second_overall_baseline = mean(main_weather_data$second_total_listeners, na.rm = TRUE),
        second_vs_baseline = ((second_avg_listeners - second_overall_baseline) / second_overall_baseline) * 100
      )
  }
  
  # =============================================================================
  # PART 9D: TEMPERATURE IMPACT ANALYSIS
  # =============================================================================
  
  main_temperature_impact <- main_weather_data %>%
    group_by(temp_category, day_type) %>%
    summarise(
      main_avg_listeners = mean(main_total_listeners, na.rm = TRUE),
      main_avg_temp = mean(weather_temp, na.rm = TRUE),
      main_observations = n(),
      .groups = 'drop'
    ) %>%
    filter(main_observations >= 20) %>%  # Minimum observations for reliability
    group_by(day_type) %>%
    mutate(
      main_baseline = mean(main_avg_listeners),
      main_temp_impact = ((main_avg_listeners - main_baseline) / main_baseline) * 100
    ) %>%
    ungroup() %>%
    arrange(day_type, main_avg_temp)
  
  # =============================================================================
  # PART 9E: WEEKEND WEATHER THEORY TEST (Outdoor Activity Hypothesis)
  # =============================================================================
  
  # Theory: Good weather drives people outdoors, reducing indoor radio listening
  main_weekend_weather <- main_weather_data %>%
    filter(day_type == "Weekend") %>%
    # Focus on peak listening hours when outdoor activities compete
    filter(hour >= 10 & hour <= 18) %>%  # 10am-6pm peak outdoor activity hours
    mutate(
      weather_appeal = case_when(
        weather_category == "Clear" & weather_temp >= 15 & weather_temp <= 25 ~ "Good Weather (15-25°C, Clear)",
        weather_category %in% c("Rain", "Thunderstorm") ~ "Wet Weather",
        weather_temp < 10 ~ "Cold Weather (< 10°C)",
        weather_temp > 25 ~ "Hot Weather (> 25°C)",
        weather_temp >= 10 & weather_temp <= 15 ~ "Cool Weather (10-15°C)",
        TRUE ~ "Moderate Weather"
      )
    ) %>%
    group_by(weather_appeal) %>%
    summarise(
      main_avg_listeners = mean(main_total_listeners, na.rm = TRUE),
      second_avg_listeners = if(ANALYSE_SECOND_STATION == "Y") mean(second_total_listeners, na.rm = TRUE) else NA,
      main_observations = n(),
      .groups = 'drop'
    ) %>%
    filter(main_observations >= 10) %>%  # Minimum observations
    mutate(
      # Calculate vs weekend baseline
      main_weekend_baseline = mean(main_avg_listeners),
      main_weekend_impact = ((main_avg_listeners - main_weekend_baseline) / main_weekend_baseline) * 100
    )
  
  # Add second station weekend impact if enabled
  if (ANALYSE_SECOND_STATION == "Y") {
    main_weekend_weather <- main_weekend_weather %>%
      mutate(
        second_weekend_baseline = mean(second_avg_listeners, na.rm = TRUE),
        second_weekend_impact = ((second_avg_listeners - second_weekend_baseline) / second_weekend_baseline) * 100
      )
  }
  
  # =============================================================================
  # PART 9F: DAYLIGHT VS DARKNESS LISTENING
  # =============================================================================
  
  main_daylight_analysis <- main_weather_data %>%
    group_by(is_daylight, hour, day_type) %>%
    summarise(
      main_avg_listeners = mean(main_total_listeners, na.rm = TRUE),
      main_observations = n(),
      .groups = 'drop'
    ) %>%
    filter(main_observations >= 10) %>%
    mutate(
      light_condition = if_else(is_daylight, "Daylight", "Darkness")
    )
  
  # =============================================================================
  # PART 9G: RAIN IMPACT ANALYSIS
  # =============================================================================
  
  main_rain_impact <- main_weather_data %>%
    group_by(rain_category, day_type) %>%
    summarise(
      main_avg_listeners = mean(main_total_listeners, na.rm = TRUE),
      main_avg_rain = mean(weather_rain, na.rm = TRUE),
      main_observations = n(),
      .groups = 'drop'
    ) %>%
    filter(main_observations >= 20) %>%
    group_by(day_type) %>%
    mutate(
      main_baseline = mean(main_avg_listeners),
      main_rain_impact = ((main_avg_listeners - main_baseline) / main_baseline) * 100
    ) %>%
    ungroup()
  
  # =============================================================================
  # PART 9H: SEASONAL/DAYLIGHT DURATION ANALYSIS
  # =============================================================================
  
  main_seasonal_trends <- main_weather_data %>%
    group_by(date) %>%
    summarise(
      main_daylight_hours = first(daylight_hours),
      main_daily_listeners = mean(main_total_listeners, na.rm = TRUE),
      second_daily_listeners = if(ANALYSE_SECOND_STATION == "Y") mean(second_total_listeners, na.rm = TRUE) else NA,
      main_daily_temp = mean(weather_temp, na.rm = TRUE),
      .groups = 'drop'
    ) %>%
    arrange(date) %>%
    mutate(
      main_day_of_year = yday(date),
      main_month = format(date, "%B")
    )
  
  # =============================================================================
  # PART 9I: WEATHER ANALYSIS SUMMARY STATISTICS
  # =============================================================================
  
  main_weather_summary_stats <- list(
    analysis_available = TRUE,
    analysis_period = paste(min(main_weather_data$date), "to", max(main_weather_data$date)),
    total_observations = nrow(main_weather_data),
    weather_conditions_tracked = length(unique(main_weather_data$weather_category)),
    temperature_range = paste(round(min(main_weather_data$weather_temp, na.rm = TRUE), 1), "to", 
                              round(max(main_weather_data$weather_temp, na.rm = TRUE), 1), "°C"),
    daylight_variation = paste(round(min(main_weather_data$daylight_hours, na.rm = TRUE), 1), "to", 
                               round(max(main_weather_data$daylight_hours, na.rm = TRUE), 1), "hours"),
    days_analyzed = length(unique(main_weather_data$date)),
    weather_types = unique(main_weather_data$weather_category),
    avg_daily_temp = round(mean(main_weather_data$weather_temp, na.rm = TRUE), 1),
    total_rain_days = sum(!is.na(main_weather_data$weather_rain) & main_weather_data$weather_rain > 0, na.rm = TRUE)
  )
  
  cat("Weather analysis completed with", main_weather_summary_stats$total_observations, "observations\n")
}

# =============================================================================
# PART 9J: SECOND STATION WEATHER ANALYSIS (IF ENABLED)
# =============================================================================

if (ANALYSE_SECOND_STATION == "Y" && exists("main_weather_data")) {
  
  # Second station weather analysis follows same patterns
  second_weather_summary <- main_weather_data %>%
    group_by(weather_category) %>%
    summarise(
      second_avg_listeners = mean(second_total_listeners, na.rm = TRUE),
      second_observations = n(),
      .groups = 'drop'
    ) %>%
    filter(second_observations >= 50) %>%
    mutate(
      second_overall_baseline = mean(main_weather_data$second_total_listeners, na.rm = TRUE),
      second_vs_baseline = ((second_avg_listeners - second_overall_baseline) / second_overall_baseline) * 100
    )
}

# =============================================================================
# PART 9K: COMPARISON STATION WEATHER ANALYSIS (IF ENABLED)  
# =============================================================================

if (ANALYSE_COMPARISON_STATION == "Y" && exists("main_weather_data")) {
  
  comparison_weather_summary <- main_weather_data %>%
    group_by(weather_category) %>%
    summarise(
      comparison_avg_listeners = mean(comparison_total_listeners, na.rm = TRUE),
      comparison_observations = n(),
      .groups = 'drop'
    ) %>%
    filter(comparison_observations >= 50) %>%
    mutate(
      comparison_overall_baseline = mean(main_weather_data$comparison_total_listeners, na.rm = TRUE),
      comparison_vs_baseline = ((comparison_avg_listeners - comparison_overall_baseline) / comparison_overall_baseline) * 100
    )
}

# =============================================================================
# PART 9L: COMBINED WEATHER IMPACT CHARTS (ALL ENABLED STATIONS)
# =============================================================================

if (exists("main_weather_summary") && nrow(main_weather_summary) > 0) {
  
  # Create combined weather impact summary from the main_weather_summary
  # (which already contains all station data in one dataframe)
  combined_weather_summary <- data.frame()
  
  # Main station data (always included)
  main_for_combined <- main_weather_summary %>%
    filter(!is.na(weather_category)) %>%
    select(weather_category, main_avg_listeners, main_vs_baseline, main_observations) %>%
    rename(avg_listeners = main_avg_listeners, 
           vs_baseline = main_vs_baseline,
           observations = main_observations) %>%
    mutate(station = MAIN_STATION_NAME)
  
  combined_weather_summary <- rbind(combined_weather_summary, main_for_combined)
  
  # Second station data (if enabled) - get from main_weather_summary, not second_weather_summary
  if (ANALYSE_SECOND_STATION == "Y" && "second_avg_listeners" %in% names(main_weather_summary)) {
    second_for_combined <- main_weather_summary %>%
      filter(!is.na(weather_category), !is.na(second_avg_listeners)) %>%
      select(weather_category, second_avg_listeners, second_vs_baseline, main_observations) %>%
      rename(avg_listeners = second_avg_listeners, 
             vs_baseline = second_vs_baseline,
             observations = main_observations) %>%  # Use same observations count
      mutate(station = SECOND_STATION_NAME)
    
    combined_weather_summary <- rbind(combined_weather_summary, second_for_combined)
  }
  
  # Comparison station data (if enabled and exists as separate summary)
  # Comparison station data (if enabled and exists as separate summary)
  if (ANALYSE_COMPARISON_STATION == "Y" && exists("comparison_weather_summary") && nrow(comparison_weather_summary) > 0) {
    comparison_filtered <- comparison_weather_summary %>%
      filter(!is.na(weather_category))

    comparison_for_combined <- comparison_filtered %>%
      select(weather_category, comparison_avg_listeners, comparison_vs_baseline, comparison_observations) %>%
      rename(avg_listeners = comparison_avg_listeners, 
             vs_baseline = comparison_vs_baseline,
             observations = comparison_observations) %>%
      mutate(station = COMPARISON_STATION_NAME)
    
    combined_weather_summary <- rbind(combined_weather_summary, comparison_for_combined)
  }
  
  # Then continue with the final cleanup section...
  # Final cleanup
  combined_weather_summary <- combined_weather_summary %>%
    filter(!is.na(weather_category),     # Remove any remaining NAs
           !is.na(vs_baseline),          # Remove NAs in the impact calculations
           !is.na(avg_listeners),        # Remove NAs in listener data
           weather_category != "",        # Remove empty categories
           observations >= 50)            # Ensure sufficient data
  
  # Final cleanup
  combined_weather_summary <- combined_weather_summary %>%
    filter(!is.na(weather_category),     # Remove any remaining NAs
           !is.na(vs_baseline),          # Remove NAs in the impact calculations
           !is.na(avg_listeners),        # Remove NAs in listener data
           weather_category != "",        # Remove empty categories
           observations >= 50)            # Ensure sufficient data
  
  # Create combined temperature analysis for all enabled stations
  combined_temp_analysis <- data.frame()
  
  if (exists("main_weather_data")) {
    # Main station temperature data
    main_temp_data <- main_weather_data %>%
      select(temp_category, main_total_listeners) %>%
      rename(total_listeners = main_total_listeners) %>%
      mutate(station = MAIN_STATION_NAME) %>%
      filter(!is.na(total_listeners))
    
    combined_temp_analysis <- rbind(combined_temp_analysis, main_temp_data)
    
    # Add second station if enabled
    if (ANALYSE_SECOND_STATION == "Y" && "second_total_listeners" %in% names(main_weather_data)) {
      second_temp_data <- main_weather_data %>%
        select(temp_category, second_total_listeners) %>%
        rename(total_listeners = second_total_listeners) %>%
        mutate(station = SECOND_STATION_NAME) %>%
        filter(!is.na(total_listeners))
      
      combined_temp_analysis <- rbind(combined_temp_analysis, second_temp_data)
    }
    
    # Add comparison station if enabled
    if (ANALYSE_COMPARISON_STATION == "Y" && "comparison_total_listeners" %in% names(main_weather_data)) {
      comparison_temp_data <- main_weather_data %>%
        select(temp_category, comparison_total_listeners) %>%
        rename(total_listeners = comparison_total_listeners) %>%
        mutate(station = COMPARISON_STATION_NAME) %>%
        filter(!is.na(total_listeners))
      
      combined_temp_analysis <- rbind(combined_temp_analysis, comparison_temp_data)
    }
  }
  
  # Create combined rain analysis for all enabled stations
  combined_rain_analysis <- data.frame()
  
  if (exists("main_rain_impact")) {
    # Main station rain data
    main_rain_data <- main_rain_impact %>%
      select(rain_category, day_type, main_avg_listeners, main_observations) %>%
      rename(avg_listeners = main_avg_listeners, observations = main_observations) %>%
      mutate(station = MAIN_STATION_NAME)
    
    combined_rain_analysis <- rbind(combined_rain_analysis, main_rain_data)
  }
  
  # Add second station rain data if available - calculate from main_weather_data
  if (ANALYSE_SECOND_STATION == "Y" && exists("main_weather_data") && "second_total_listeners" %in% names(main_weather_data)) {
    second_rain_impact <- main_weather_data %>%
      group_by(rain_category, day_type) %>%
      summarise(
        avg_listeners = mean(second_total_listeners, na.rm = TRUE),
        observations = n(),
        .groups = 'drop'
      ) %>%
      filter(observations >= 20) %>%
      mutate(station = SECOND_STATION_NAME)
    
    combined_rain_analysis <- rbind(combined_rain_analysis, second_rain_impact)
  }
  
  # Add comparison station rain data if available
  if (ANALYSE_COMPARISON_STATION == "Y" && exists("main_weather_data") && "comparison_total_listeners" %in% names(main_weather_data)) {
    comparison_rain_impact <- main_weather_data %>%
      group_by(rain_category, day_type) %>%
      summarise(
        avg_listeners = mean(comparison_total_listeners, na.rm = TRUE),
        observations = n(),
        .groups = 'drop'
      ) %>%
      filter(observations >= 20) %>%
      mutate(station = COMPARISON_STATION_NAME)
    
    combined_rain_analysis <- rbind(combined_rain_analysis, comparison_rain_impact)
  }
  
  # Create combined daylight analysis for all enabled stations
  combined_daylight_analysis <- data.frame()
  
  if (exists("main_daylight_analysis")) {
    # Main station daylight data
    main_daylight_data <- main_daylight_analysis %>%
      select(light_condition, hour, day_type, main_avg_listeners, main_observations) %>%
      rename(avg_listeners = main_avg_listeners, observations = main_observations) %>%
      mutate(station = MAIN_STATION_NAME)
    
    combined_daylight_analysis <- rbind(combined_daylight_analysis, main_daylight_data)
  }
  
  # Add second station daylight data if available
  if (ANALYSE_SECOND_STATION == "Y" && exists("main_weather_data") && "second_total_listeners" %in% names(main_weather_data)) {
    second_daylight_analysis <- main_weather_data %>%
      group_by(is_daylight, hour, day_type) %>%
      summarise(
        avg_listeners = mean(second_total_listeners, na.rm = TRUE),
        observations = n(),
        .groups = 'drop'
      ) %>%
      filter(observations >= 10) %>%
      mutate(
        light_condition = if_else(is_daylight, "Daylight", "Darkness"),
        station = SECOND_STATION_NAME
      ) %>%
      select(light_condition, hour, day_type, avg_listeners, observations, station)
    
    combined_daylight_analysis <- rbind(combined_daylight_analysis, second_daylight_analysis)
  }
  
  # Add comparison station daylight data if available
  if (ANALYSE_COMPARISON_STATION == "Y" && exists("main_weather_data") && "comparison_total_listeners" %in% names(main_weather_data)) {
    comparison_daylight_analysis <- main_weather_data %>%
      group_by(is_daylight, hour, day_type) %>%
      summarise(
        avg_listeners = mean(comparison_total_listeners, na.rm = TRUE),
        observations = n(),
        .groups = 'drop'
      ) %>%
      filter(observations >= 10) %>%
      mutate(
        light_condition = if_else(is_daylight, "Daylight", "Darkness"),
        station = COMPARISON_STATION_NAME
      ) %>%
      select(light_condition, hour, day_type, avg_listeners, observations, station)
    
    combined_daylight_analysis <- rbind(combined_daylight_analysis, comparison_daylight_analysis)
  }
  
  cat("Combined weather analysis completed for", length(unique(combined_weather_summary$station)), "stations\n")
}

# =============================================================================
# ANALYSIS 9 COMPLETE
# =============================================================================

cat("Analysis 9 complete! Weather impact analysis finished:\n")
cat("⚠️  REMEMBER: These are exploratory findings - correlation does not imply causation! ⚠️\n")

if (DEBUG_TO_CONSOLE == "Y") {
  if (main_weather_summary_stats$analysis_available) {
    cat("Weather analysis summary:\n")
    cat("  - Analysis period:", main_weather_summary_stats$analysis_period, "\n")
    cat("  - Days analyzed:", main_weather_summary_stats$days_analyzed, "\n")
    cat("  - Weather conditions:", main_weather_summary_stats$weather_conditions_tracked, "types\n")
    cat("  - Temperature range:", main_weather_summary_stats$temperature_range, "\n")
    cat("  - Daylight variation:", main_weather_summary_stats$daylight_variation, "\n")
    cat("  - Weather types found:", paste(main_weather_summary_stats$weather_types, collapse = ", "), "\n")
    
    if (exists("main_weekend_weather") && nrow(main_weekend_weather) > 0) {
      cat("  - Weekend weather theory: ", nrow(main_weekend_weather), "conditions tested\n")
    }
  } else {
    cat("Weather analysis: ", main_weather_summary_stats$message, "\n")
  }
}

# =============================================================================
# ANALYSIS 10: STATION COMPARISON ANALYSIS
# =============================================================================
# This analysis creates data for comparing performance patterns across stations
# Shows hourly performance vs each station's daily average (not vs each other)
# Enables Figure 48: "Hourly performance comparison" chart

cat("Running Analysis 10: Station Comparison Analysis...\n")

# =============================================================================
# PART 10A: MAIN STATION HOURLY PERFORMANCE VS DAILY AVERAGE
# =============================================================================

# Calculate main station's hourly performance vs its own daily average
main_station_hourly_comparison <- data %>%
  group_by(hour) %>%
  summarise(
    main_hourly_avg = mean(main_total_listeners, na.rm = TRUE),
    main_sessions = n(),
    .groups = 'drop'
  ) %>%
  filter(main_sessions >= 5) %>%  # Minimum sessions per hour
  mutate(
    main_daily_baseline = mean(main_hourly_avg),
    main_pct_change = ((main_hourly_avg - main_daily_baseline) / main_daily_baseline) * 100,
    station = MAIN_STATION_NAME  # For chart labeling
  ) %>%
  select(hour, main_pct_change, station) %>%
  rename(pct_change = main_pct_change)

# =============================================================================
# PART 10B: SECOND STATION HOURLY COMPARISON (IF ENABLED)
# =============================================================================

if (ANALYSE_SECOND_STATION == "Y") {
  
  second_station_hourly_comparison <- data %>%
    group_by(hour) %>%
    summarise(
      second_hourly_avg = mean(second_total_listeners, na.rm = TRUE),
      second_sessions = n(),
      .groups = 'drop'
    ) %>%
    filter(second_sessions >= 5) %>%
    mutate(
      second_daily_baseline = mean(second_hourly_avg),
      second_pct_change = ((second_hourly_avg - second_daily_baseline) / second_daily_baseline) * 100,
      station = SECOND_STATION_NAME  # Use configurable name
    ) %>%
    select(hour, second_pct_change, station) %>%
    rename(pct_change = second_pct_change)
  
} else {
  second_station_hourly_comparison <- data.frame()
}

# =============================================================================
# PART 10C: COMPARISON STATION HOURLY COMPARISON (IF ENABLED)
# =============================================================================

if (ANALYSE_COMPARISON_STATION == "Y") {
  
  comparison_station_hourly_comparison <- data %>%
    group_by(hour) %>%
    summarise(
      comparison_hourly_avg = mean(comparison_total_listeners, na.rm = TRUE),
      comparison_sessions = n(),
      .groups = 'drop'
    ) %>%
    filter(comparison_sessions >= 5) %>%
    mutate(
      comparison_daily_baseline = mean(comparison_hourly_avg),
      comparison_pct_change = ((comparison_hourly_avg - comparison_daily_baseline) / comparison_daily_baseline) * 100,
      station = COMPARISON_STATION_NAME  # Use configurable name
    ) %>%
    select(hour, comparison_pct_change, station) %>%
    rename(pct_change = comparison_pct_change)
  
} else {
  comparison_station_hourly_comparison <- data.frame()
}

# =============================================================================
# PART 10D: COMBINE ALL STATION COMPARISONS
# =============================================================================

# Combine all available stations into one dataset for plotting
hourly_changes_long <- bind_rows(
  main_station_hourly_comparison,
  second_station_hourly_comparison,
  comparison_station_hourly_comparison
) %>%
  filter(!is.na(pct_change), is.finite(pct_change)) %>%
  arrange(station, hour)

# =============================================================================
# PART 10E: CREATE STATION PERFORMANCE SUMMARY
# =============================================================================

# Summary statistics for each station
station_comparison_summary <- hourly_changes_long %>%
  group_by(station) %>%
  summarise(
    avg_hourly_variation = mean(abs(pct_change), na.rm = TRUE),
    peak_hour = hour[which.max(pct_change)],
    peak_performance = max(pct_change, na.rm = TRUE),
    lowest_hour = hour[which.min(pct_change)],
    lowest_performance = min(pct_change, na.rm = TRUE),
    total_variation = max(pct_change, na.rm = TRUE) - min(pct_change, na.rm = TRUE),
    hours_analyzed = n(),
    .groups = 'drop'
  ) %>%
  arrange(desc(avg_hourly_variation))

# =============================================================================
# PART 10F: PEAK HOURS ANALYSIS
# =============================================================================

# Identify when each station performs best/worst
peak_hours_analysis <- hourly_changes_long %>%
  group_by(hour) %>%
  summarise(
    stations_above_average = sum(pct_change > 0),
    stations_below_average = sum(pct_change <= 0),
    avg_performance_all_stations = mean(pct_change, na.rm = TRUE),
    best_performing_station = station[which.max(pct_change)],
    best_station_performance = max(pct_change, na.rm = TRUE),
    worst_performing_station = station[which.min(pct_change)],
    worst_station_performance = min(pct_change, na.rm = TRUE),
    .groups = 'drop'
  ) %>%
  arrange(hour)

# =============================================================================
# PART 10G: COMPETITIVE ANALYSIS (IF MULTIPLE STATIONS)
# =============================================================================

if (nrow(hourly_changes_long) > 24) {  # More than one station's worth of hours
  
  # Hour-by-hour competitive comparison
  competitive_analysis <- hourly_changes_long %>%
    pivot_wider(names_from = station, values_from = pct_change, names_prefix = "station_") %>%
    # Calculate which station wins each hour
    rowwise() %>%
    mutate(
      leading_station = {
        station_cols <- select(., starts_with("station_"))
        station_names <- gsub("station_", "", names(station_cols))
        station_names[which.max(unlist(station_cols))]
      },
      leading_performance = max(c_across(starts_with("station_")), na.rm = TRUE)
    ) %>%
    ungroup()
  
  # Summary of competitive performance
  competitive_summary <- competitive_analysis %>%
    count(leading_station, name = "hours_leading") %>%
    mutate(
      pct_hours_leading = (hours_leading / sum(hours_leading)) * 100
    ) %>%
    arrange(desc(hours_leading))
  
} else {
  competitive_analysis <- data.frame()
  competitive_summary <- data.frame()
}

# =============================================================================
# PART 10H: CROSS-STATION GENRE COMPARISON
# =============================================================================

# Create genre comparison data (add this to your YAML processing)
if ((ANALYSE_SECOND_STATION == "Y" | ANALYSE_COMPARISON_STATION == "Y")) {
  
  # Main station genre distribution
  main_genre_comparison <- data %>%
    filter(!is.na(main_genre), main_genre != "", main_genre != "-", main_genre != "Unknown") %>%
    filter(!grepl(paste(EXCLUDE_TERMS, collapse = "|"), main_showname, ignore.case = TRUE)) %>%
    count(main_genre, name = "main_plays") %>%
    mutate(
      main_pct = (main_plays / sum(main_plays)) * 100,
      station = MAIN_STATION_NAME
    ) %>%
    rename(genre = main_genre, plays = main_plays, pct = main_pct)
  
  # Second station genre distribution (if enabled)
  if (ANALYSE_SECOND_STATION == "Y") {
    second_genre_comparison <- data %>%
      filter(!is.na(second_genre), second_genre != "", second_genre != "-", second_genre != "Unknown") %>%
      filter(!grepl(paste(EXCLUDE_TERMS, collapse = "|"), second_showname, ignore.case = TRUE)) %>%
      count(second_genre, name = "second_plays") %>%
      mutate(
        second_pct = (second_plays / sum(second_plays)) * 100,
        station = SECOND_STATION_NAME
      ) %>%
      rename(genre = second_genre, plays = second_plays, pct = second_pct)
  } else {
    second_genre_comparison <- data.frame()
  }
  
  # Comparison station genre distribution (if enabled)
  if (ANALYSE_COMPARISON_STATION == "Y") {
    comparison_genre_comparison <- data %>%
      filter(!is.na(comparison_genre), comparison_genre != "", comparison_genre != "-", comparison_genre != "Unknown") %>%
      filter(!grepl(paste(EXCLUDE_TERMS, collapse = "|"), comparison_showname, ignore.case = TRUE)) %>%
      count(comparison_genre, name = "comparison_plays") %>%
      mutate(
        comparison_pct = (comparison_plays / sum(comparison_plays)) * 100,
        station = COMPARISON_STATION_NAME
      ) %>%
      rename(genre = comparison_genre, plays = comparison_plays, pct = comparison_pct)
  } else {
    comparison_genre_comparison <- data.frame()
  }
  
  # Combine all stations
  cross_station_genre_data <- bind_rows(
    main_genre_comparison,
    second_genre_comparison,
    comparison_genre_comparison
  ) %>%
    filter(pct >= 1) %>%  # Only show genres that are >1% of station's output
    arrange(desc(pct))
  
  # Get top genres across all stations for focused comparison
  top_cross_genres <- cross_station_genre_data %>%
    group_by(genre) %>%
    summarise(max_pct = max(pct, na.rm = TRUE), .groups = "drop") %>%
    arrange(desc(max_pct)) %>%
    head(15) %>%
    pull(genre)
  
  # Filtered data for the main chart
  cross_station_genre_focused <- cross_station_genre_data %>%
    filter(genre %in% top_cross_genres)
}

# =============================================================================
# ANALYSIS 10 COMPLETE
# =============================================================================

cat("Analysis 10 complete! Station comparison analysis ready:\n")

if (DEBUG_TO_CONSOLE == "Y") {
  cat("Station comparison data:\n")
  cat("  - Stations analyzed:", length(unique(hourly_changes_long$station)), "\n")
  cat("  - Hours with data:", nrow(hourly_changes_long), "\n")
  
  if (nrow(station_comparison_summary) > 0) {
    cat("  - Station performance summary:\n")
    for (i in 1:nrow(station_comparison_summary)) {
      station_data <- station_comparison_summary[i, ]
      cat("    *", station_data$station, ": Peak at", station_data$peak_hour, ":00 (+", 
          round(station_data$peak_performance, 1), "%), Low at", station_data$lowest_hour, ":00 (", 
          round(station_data$lowest_performance, 1), "%)\n")
    }
  }
  
  if (nrow(competitive_summary) > 0) {
    cat("  - Competitive analysis:\n")
    for (i in 1:nrow(competitive_summary)) {
      comp_data <- competitive_summary[i, ]
      cat("    *", comp_data$leading_station, "leads", comp_data$hours_leading, "hours (", 
          round(comp_data$pct_hours_leading, 1), "%)\n")
    }
  }
  
  # Show peak listening hour across all stations
  if (nrow(peak_hours_analysis) > 0) {
    best_overall_hour <- peak_hours_analysis[which.max(peak_hours_analysis$avg_performance_all_stations), ]
    cat("  - Best overall hour:", best_overall_hour$hour, ":00 (avg +", 
        round(best_overall_hour$avg_performance_all_stations, 1), "% across all stations)\n")
  }
}


# =============================================================================
# ANALYSIS 11: MONTHLY TRENDS ANALYSIS
# =============================================================================
# This analysis creates monthly performance trends for all stations
# Consolidates and cleans up the existing monthly trends logic
# Enables Figure 49: "Monthly performance trends" chart

cat("Running Analysis 11: Monthly Trends Analysis...\n")

# =============================================================================
# PART 11A: DETERMINE ANALYSIS TYPE
# =============================================================================

# Check what type of report we're generating
is_single_month_report <- REPORT_TYPE != "ALL" && grepl("^\\d{4}-\\d{2}$", REPORT_TYPE)
is_date_range_report <- !is.null(START_DATE) && !is.null(END_DATE)
is_cumulative_report <- REPORT_TYPE == "ALL"

cat("Monthly trends analysis type:", 
    ifelse(is_single_month_report, "Single month with context", 
           ifelse(is_date_range_report, "Date range", "Cumulative")), "\n")

# =============================================================================
# PART 11B: MAIN MONTHLY TRENDS CALCULATION
# =============================================================================

if (is_single_month_report) {
  
  # For single-month reports, try to get neighboring months for context
  report_date <- as.Date(paste0(REPORT_TYPE, "-01"))
  context_start <- report_date - months(2)  # 2 months before
  context_end <- report_date + months(2)    # 2 months after (or to current date)
  
  cat("Attempting to retrieve context data for", REPORT_TYPE, "from", context_start, "to", context_end, "\n")
  
  # Try to connect to database for additional context (if database access available)
  tryCatch({
    if (exists("DATABASE_HOST") && exists("con")) {
      
      # Build context query
      context_query <- paste0(
        "SELECT * FROM ", DB_TABLE, " WHERE date >= '", context_start, 
        "' AND date <= '", context_end, "' ORDER BY date, time"
      )
      
      context_data <- dbGetQuery(con, context_query)
      
      if (nrow(context_data) > 0) {
        # Process context data similar to main data processing
        context_data <- context_data %>%
          mutate(
            date = as.Date(date),
            main_total_listeners = main_stream1 + main_stream2,
            second_total_listeners = second_stream1 + second_stream2,
            comparison_total_listeners = comparison_stream,
            month = format(date, "%Y-%m")
          )
        
        # Create monthly comparison from context data
        monthly_comparison <- context_data %>%
          group_by(month) %>%
          summarise(
            avg_listeners = mean(main_total_listeners, na.rm = TRUE),
            avg_second = if(ANALYSE_SECOND_STATION == "Y") mean(second_total_listeners, na.rm = TRUE) else NA,
            avg_comparison = if(ANALYSE_COMPARISON_STATION == "Y") mean(comparison_total_listeners, na.rm = TRUE) else NA,
            total_observations = n(),
            .groups = 'drop'
          ) %>%
          arrange(month) %>%
          mutate(
            mom_change = (avg_listeners - lag(avg_listeners)) / lag(avg_listeners) * 100,
            is_report_month = month == REPORT_TYPE
          )
        
        monthly_trends_available <- TRUE
        monthly_trends_type <- "expanded"
        
        cat("Retrieved", nrow(monthly_comparison), "months of context data\n")
        
      } else {
        monthly_trends_available <- FALSE
        monthly_trends_type <- "no_data"
      }
      
    } else {
      monthly_trends_available <- FALSE
      monthly_trends_type <- "no_database_access"
    }
    
  }, error = function(e) {
    cat("Database context retrieval failed:", e$message, "\n")
    monthly_trends_available <- FALSE
    monthly_trends_type <- "error"
  })
  
} else {
  
  # For multi-month or cumulative reports, use existing data
  if (nrow(data) > 0) {
    
    monthly_comparison <- data %>%
      mutate(month = format(date, "%Y-%m")) %>%
      group_by(month) %>%
      summarise(
        avg_listeners = mean(main_total_listeners, na.rm = TRUE),
        avg_second = if(ANALYSE_SECOND_STATION == "Y") mean(second_total_listeners, na.rm = TRUE) else NA,
        avg_comparison = if(ANALYSE_COMPARISON_STATION == "Y") mean(comparison_total_listeners, na.rm = TRUE) else NA,
        total_observations = n(),
        .groups = 'drop'
      ) %>%
      arrange(month) %>%
      mutate(
        mom_change = (avg_listeners - lag(avg_listeners)) / lag(avg_listeners) * 100
      )
    
    if (nrow(monthly_comparison) > 1) {
      monthly_trends_available <- TRUE
      monthly_trends_type <- "normal"
    } else {
      monthly_trends_available <- FALSE
      monthly_trends_type <- "insufficient"
    }
    
  } else {
    monthly_trends_available <- FALSE
    monthly_trends_type <- "no_data"
  }
}

# =============================================================================
# PART 11C: CREATE TREND MESSAGE FOR REPORTS
# =============================================================================

if (is_single_month_report) {
  trend_message <- case_when(
    monthly_trends_type == "expanded" ~ paste0("Monthly trends shown for ", REPORT_TYPE, " (report focus) and neighboring months for context"),
    monthly_trends_type == "no_data" ~ paste0("No monthly trend data available for ", REPORT_TYPE, " or neighboring months"),
    monthly_trends_type == "no_database_access" ~ "Single-month report: Extended trends require database access",
    monthly_trends_type == "error" ~ "Unable to retrieve monthly trend data"
  )
} else {
  trend_message <- ""
}

# =============================================================================
# PART 11D: MONTHLY TRENDS ANALYSIS (IF AVAILABLE)
# =============================================================================

if (monthly_trends_available && exists("monthly_comparison") && nrow(monthly_comparison) > 1) {
  
  # Clean monthly data for visualization
  monthly_trends_clean <- monthly_comparison %>%
    filter(is.finite(avg_listeners), !is.na(avg_listeners)) %>%
    mutate(
      # Format month for display
      month_display = format(as.Date(paste0(month, "-01")), "%b %Y"),
      # Create point size for highlighting (if single-month report)
      point_size = ifelse(exists("is_report_month") && is_report_month == TRUE, 4, 2),
      point_alpha = ifelse(exists("is_report_month") && is_report_month == TRUE, 1, 0.7)
    )
  
  # Calculate month-over-month growth rates
  monthly_growth_analysis <- monthly_trends_clean %>%
    mutate(
      main_growth_rate = mom_change,
      second_growth_rate = if(ANALYSE_SECOND_STATION == "Y") {
        (avg_second - lag(avg_second)) / lag(avg_second) * 100
      } else NA,
      comparison_growth_rate = if(ANALYSE_COMPARISON_STATION == "Y") {
        (avg_comparison - lag(avg_comparison)) / lag(avg_comparison) * 100
      } else NA
    ) %>%
    filter(!is.na(main_growth_rate))  # Remove first month (no previous month for comparison)
  
  # Monthly trends summary statistics
  monthly_trends_summary <- list(
    months_analyzed = nrow(monthly_trends_clean),
    date_range = paste(min(monthly_trends_clean$month), "to", max(monthly_trends_clean$month)),
    main_avg_monthly_listeners = round(mean(monthly_trends_clean$avg_listeners, na.rm = TRUE), 0),
    main_best_month = monthly_trends_clean$month[which.max(monthly_trends_clean$avg_listeners)],
    main_best_month_listeners = round(max(monthly_trends_clean$avg_listeners, na.rm = TRUE), 0),
    main_worst_month = monthly_trends_clean$month[which.min(monthly_trends_clean$avg_listeners)],
    main_worst_month_listeners = round(min(monthly_trends_clean$avg_listeners, na.rm = TRUE), 0),
    main_total_variation = round(max(monthly_trends_clean$avg_listeners, na.rm = TRUE) - 
                                   min(monthly_trends_clean$avg_listeners, na.rm = TRUE), 0)
  )
  
  # Add growth statistics if available
  if (nrow(monthly_growth_analysis) > 0) {
    monthly_trends_summary$main_avg_growth_rate <- round(mean(monthly_growth_analysis$main_growth_rate, na.rm = TRUE), 1)
    monthly_trends_summary$main_best_growth_month <- monthly_growth_analysis$month[which.max(monthly_growth_analysis$main_growth_rate)]
    monthly_trends_summary$main_best_growth_rate <- round(max(monthly_growth_analysis$main_growth_rate, na.rm = TRUE), 1)
  }
  
} else {
  monthly_trends_clean <- data.frame()
  monthly_growth_analysis <- data.frame()
  monthly_trends_summary <- list(
    months_analyzed = 0,
    message = case_when(
      monthly_trends_type == "insufficient" ~ "Insufficient data (need multiple months)",
      monthly_trends_type == "no_data" ~ "No monthly data available",
      monthly_trends_type == "error" ~ "Error retrieving monthly data",
      TRUE ~ "Monthly trends not available"
    )
  )
}

# =============================================================================
# PART 11E: SEASONAL ANALYSIS (IF SUFFICIENT DATA)
# =============================================================================

if (monthly_trends_available && nrow(monthly_trends_clean) >= 6) {
  
  # Add seasonal indicators
  monthly_seasonal_analysis <- monthly_trends_clean %>%
    mutate(
      month_num = as.numeric(format(as.Date(paste0(month, "-01")), "%m")),
      season = case_when(
        month_num %in% c(12, 1, 2) ~ "Winter",
        month_num %in% c(3, 4, 5) ~ "Spring", 
        month_num %in% c(6, 7, 8) ~ "Summer",
        month_num %in% c(9, 10, 11) ~ "Autumn"
      ),
      quarter = paste0("Q", ceiling(month_num / 3))
    )
  
  # Seasonal performance summary
  seasonal_summary <- monthly_seasonal_analysis %>%
    group_by(season) %>%
    summarise(
      avg_listeners = mean(avg_listeners, na.rm = TRUE),
      months_in_season = n(),
      .groups = 'drop'
    ) %>%
    arrange(desc(avg_listeners))
  
} else {
  monthly_seasonal_analysis <- data.frame()
  seasonal_summary <- data.frame()
}

# =============================================================================
# ANALYSIS 11 COMPLETE
# =============================================================================

cat("Analysis 11 complete! Monthly trends analysis ready:\n")

if (DEBUG_TO_CONSOLE == "Y") {
  cat("Monthly trends status:\n")
  cat("  - Trends available:", monthly_trends_available, "\n")
  cat("  - Analysis type:", monthly_trends_type, "\n")
  
  if (!is.null(trend_message) && trend_message != "") {
    cat("  - Trend message:", trend_message, "\n")
  }
  
  if (exists("monthly_trends_summary") && "months_analyzed" %in% names(monthly_trends_summary)) {
    if (monthly_trends_summary$months_analyzed > 0) {
      cat("  - Months analyzed:", monthly_trends_summary$months_analyzed, "\n")
      cat("  - Date range:", monthly_trends_summary$date_range, "\n")
      cat("  - Best month:", monthly_trends_summary$main_best_month, 
          "(", monthly_trends_summary$main_best_month_listeners, "listeners)\n")
      cat("  - Worst month:", monthly_trends_summary$main_worst_month,
          "(", monthly_trends_summary$main_worst_month_listeners, "listeners)\n")
      
      if ("main_avg_growth_rate" %in% names(monthly_trends_summary)) {
        cat("  - Average monthly growth:", monthly_trends_summary$main_avg_growth_rate, "%\n")
      }
    } else {
      cat("  - Status:", monthly_trends_summary$message, "\n")
    }
  }
  
  if (nrow(seasonal_summary) > 0) {
    cat("  - Seasonal analysis: Available (", nrow(seasonal_summary), "seasons)\n")
  }
}

# =============================================================================
# CREATE SUMMARY STATS FROM EXISTING ANALYSIS OBJECTS
# =============================================================================
# Add this after all analyses are complete (after Analysis 11)

cat("Creating summary statistics from analysis objects...\n")

# =============================================================================
# MAIN STATION SUMMARY STATS
# =============================================================================

main_summary_stats <- list()

# Basic listener statistics
main_summary_stats$avg_daily_listeners <- mean(data$main_total_listeners, na.rm = TRUE)
main_summary_stats$max_listeners <- max(data$main_total_listeners, na.rm = TRUE)
main_summary_stats$min_listeners <- min(data$main_total_listeners, na.rm = TRUE)

# Peak hour analysis - extract from existing hourly analysis
if (exists("main_hourly_listening") && nrow(main_hourly_listening) > 0) {
  peak_hour_data <- main_hourly_listening %>%
    arrange(desc(main_avg_listeners))
  
  main_summary_stats$peak_hour <- peak_hour_data$hour[1]
  main_summary_stats$peak_listeners <- peak_hour_data$main_avg_listeners[1]
} else {
  # Fallback calculation if hourly analysis doesn't exist
  peak_hour_data <- data %>%
    group_by(hour) %>%
    summarise(avg_listeners = mean(main_total_listeners, na.rm = TRUE), .groups = 'drop') %>%
    arrange(desc(avg_listeners))
  
  main_summary_stats$peak_hour <- peak_hour_data$hour[1]
  main_summary_stats$peak_listeners <- peak_hour_data$avg_listeners[1]
}

# Best day analysis - extract from existing daily analysis
if (exists("main_daily_listening") && nrow(main_daily_listening) > 0) {
  best_day_data <- main_daily_listening %>%
    arrange(desc(main_avg_listeners))
  
  main_summary_stats$best_day <- best_day_data$weekday[1]
  main_summary_stats$best_day_avg <- best_day_data$main_avg_listeners[1]
} else {
  # Fallback calculation
  best_day_data <- data %>%
    mutate(weekday_name = case_when(
      weekday == "Monday" | weekday == 1 | weekday == "1" ~ "Monday",
      weekday == "Tuesday" | weekday == 2 | weekday == "2" ~ "Tuesday", 
      weekday == "Wednesday" | weekday == 3 | weekday == "3" ~ "Wednesday",
      weekday == "Thursday" | weekday == 4 | weekday == "4" ~ "Thursday",
      weekday == "Friday" | weekday == 5 | weekday == "5" ~ "Friday",
      weekday == "Saturday" | weekday == 6 | weekday == "6" ~ "Saturday",
      weekday == "Sunday" | weekday == 7 | weekday == "7" ~ "Sunday",
      TRUE ~ as.character(weekday)
    )) %>%
    group_by(weekday_name) %>%
    summarise(avg_listeners = mean(main_total_listeners, na.rm = TRUE), .groups = 'drop') %>%
    arrange(desc(avg_listeners))
  
  main_summary_stats$best_day <- best_day_data$weekday_name[1]
  main_summary_stats$best_day_avg <- best_day_data$avg_listeners[1]
}

# Date range and observation counts
main_summary_stats$start_date <- min(data$date)
main_summary_stats$end_date <- max(data$date)
main_summary_stats$total_days <- length(unique(data$date))
main_summary_stats$total_observations <- nrow(data[!is.na(data$main_total_listeners),])

# Show statistics - extract from existing show summaries
if (exists("main_show_summary")) {
  main_summary_stats$total_shows_analyzed <- nrow(main_show_summary)
  main_summary_stats$avg_shows_per_day <- main_summary_stats$total_shows_analyzed / main_summary_stats$total_days
}

# Music statistics (if available)
if ("main_artist" %in% names(data)) {
  music_data <- data %>% filter(!is.na(main_artist), main_artist != "", main_artist != "Unknown")
  if (nrow(music_data) > 0) {
    main_summary_stats$total_tracks_played <- nrow(music_data)
    main_summary_stats$unique_artists <- length(unique(music_data$main_artist))
    main_summary_stats$unique_tracks <- length(unique(paste(music_data$main_artist, music_data$main_song)))
    main_summary_stats$music_coverage_pct <- (nrow(music_data) / nrow(data)) * 100
  }
}

if (exists("main_show_performance_zscore") && nrow(main_show_performance_zscore) > 0) {
  
  main_top_shows_by_category_zscore <- main_show_performance_zscore %>%
    group_by(day_type) %>%
    arrange(desc(main_avg_zscore_performance)) %>%
    slice_head(n = 5) %>%  # Top 5 per category
    ungroup() %>%
    mutate(
      main_avg_zscore_performance = round(main_avg_zscore_performance, 2),
      main_avg_listeners = round(main_avg_listeners, 0)
    ) %>%
    select(day_type, main_showname, main_avg_zscore_performance, main_avg_listeners, main_airtime_hours) %>%
    arrange(day_type, desc(main_avg_zscore_performance))
  
  cat("✓ Main station top shows by category (z-score) created\n")
} else {
  main_top_shows_by_category_zscore <- data.frame()
}

if (exists("main_artist_impact_zscore") && nrow(main_artist_impact_zscore) > 0) {
  
  # Best impactful artists
  main_best_artists_zscore <- main_artist_impact_zscore %>%
    filter(main_avg_zscore_impact > 0) %>%
    arrange(desc(main_avg_zscore_impact)) %>%
    head(10) %>%
    mutate(
      main_avg_zscore_impact = round(main_avg_zscore_impact, 2),
      main_avg_listeners = round(main_avg_listeners, 0)
    ) %>%
    select(main_artist, main_avg_zscore_impact, main_plays, main_avg_listeners)
  
  # Worst impactful artists
  main_worst_artists_zscore <- main_artist_impact_zscore %>%
    filter(main_avg_zscore_impact < 0) %>%
    arrange(main_avg_zscore_impact) %>%
    head(10) %>%
    mutate(
      main_avg_zscore_impact = round(main_avg_zscore_impact, 2),
      main_avg_listeners = round(main_avg_listeners, 0)
    ) %>%
    select(main_artist, main_avg_zscore_impact, main_plays, main_avg_listeners)
  
  cat("✓ Main station best/worst artists (z-score) created\n")
} else {
  main_best_artists_zscore <- data.frame()
  main_worst_artists_zscore <- data.frame()
}
if (exists("main_genre_impact_zscore") && nrow(main_genre_impact_zscore) > 0) {
  
  # Best performing genres
  main_best_genres_zscore <- main_genre_impact_zscore %>%
    filter(main_avg_zscore_impact > 0) %>%
    arrange(desc(main_avg_zscore_impact)) %>%
    head(10) %>%
    mutate(
      main_avg_zscore_impact = round(main_avg_zscore_impact, 2),
      main_avg_listeners = round(main_avg_listeners, 0)
    ) %>%
    select(main_genre, main_avg_zscore_impact, main_plays, main_avg_listeners)
  
  # Worst performing genres
  main_worst_genres_zscore <- main_genre_impact_zscore %>%
    filter(main_avg_zscore_impact < 0) %>%
    arrange(main_avg_zscore_impact) %>%
    head(10) %>%
    mutate(
      main_avg_zscore_impact = round(main_avg_zscore_impact, 2),
      main_avg_listeners = round(main_avg_listeners, 0)
    ) %>%
    select(main_genre, main_avg_zscore_impact, main_plays, main_avg_listeners)
  
  cat("✓ Main station best/worst genres (z-score) created\n")
} else {
  main_best_genres_zscore <- data.frame()
  main_worst_genres_zscore <- data.frame()
}

cat("Main station summary stats created\n")

# =============================================================================
# SECOND STATION SUMMARY STATS (IF ENABLED)
# =============================================================================

if (ANALYSE_SECOND_STATION == "Y") {
  
  second_summary_stats <- list()
  
  # Basic listener statistics
  second_summary_stats$avg_daily_listeners <- mean(data$second_total_listeners, na.rm = TRUE)
  second_summary_stats$max_listeners <- max(data$second_total_listeners, na.rm = TRUE)
  second_summary_stats$min_listeners <- min(data$second_total_listeners, na.rm = TRUE)
  
  # Peak hour analysis
  if (exists("second_hourly_listening") && nrow(second_hourly_listening) > 0) {
    peak_hour_data <- second_hourly_listening %>%
      arrange(desc(second_avg_listeners))
    
    second_summary_stats$peak_hour <- peak_hour_data$hour[1]
    second_summary_stats$peak_listeners <- peak_hour_data$second_avg_listeners[1]
  } else {
    # Fallback calculation
    peak_hour_data <- data %>%
      group_by(hour) %>%
      summarise(avg_listeners = mean(second_total_listeners, na.rm = TRUE), .groups = 'drop') %>%
      arrange(desc(avg_listeners))
    
    second_summary_stats$peak_hour <- peak_hour_data$hour[1]
    second_summary_stats$peak_listeners <- peak_hour_data$avg_listeners[1]
  }
  
  # Best day analysis
  if (exists("second_daily_listening") && nrow(second_daily_listening) > 0) {
    best_day_data <- second_daily_listening %>%
      arrange(desc(second_avg_listeners))
    
    second_summary_stats$best_day <- best_day_data$weekday[1]
    second_summary_stats$best_day_avg <- best_day_data$second_avg_listeners[1]
  } else {
    # Fallback calculation
    best_day_data <- data %>%
      mutate(weekday_name = case_when(
        weekday == "Monday" | weekday == 1 | weekday == "1" ~ "Monday",
        weekday == "Tuesday" | weekday == 2 | weekday == "2" ~ "Tuesday", 
        weekday == "Wednesday" | weekday == 3 | weekday == "3" ~ "Wednesday",
        weekday == "Thursday" | weekday == 4 | weekday == "4" ~ "Thursday",
        weekday == "Friday" | weekday == 5 | weekday == "5" ~ "Friday",
        weekday == "Saturday" | weekday == 6 | weekday == "6" ~ "Saturday",
        weekday == "Sunday" | weekday == 7 | weekday == "7" ~ "Sunday",
        TRUE ~ as.character(weekday)
      )) %>%
      group_by(weekday_name) %>%
      summarise(avg_listeners = mean(second_total_listeners, na.rm = TRUE), .groups = 'drop') %>%
      arrange(desc(avg_listeners))
    
    second_summary_stats$best_day <- best_day_data$weekday_name[1]
    second_summary_stats$best_day_avg <- best_day_data$avg_listeners[1]
  }
  
  # Date range and observation counts
  second_summary_stats$start_date <- min(data$date)
  second_summary_stats$end_date <- max(data$date)
  second_summary_stats$total_observations <- nrow(data[!is.na(data$second_total_listeners),])
  
  # Show statistics
  if (exists("second_show_summary")) {
    second_summary_stats$total_shows_analyzed <- nrow(second_show_summary)
  }
  
  # Music statistics (if available)
  if ("second_artist" %in% names(data)) {
    music_data <- data %>% filter(!is.na(second_artist), second_artist != "", second_artist != "Unknown")
    if (nrow(music_data) > 0) {
      second_summary_stats$total_tracks_played <- nrow(music_data)
      second_summary_stats$unique_artists <- length(unique(music_data$second_artist))
      second_summary_stats$unique_tracks <- length(unique(paste(music_data$second_artist, music_data$second_song)))
      second_summary_stats$music_coverage_pct <- (nrow(music_data) / nrow(data)) * 100
    }
  }
  
  if (exists("second_show_performance_zscore") && nrow(second_show_performance_zscore) > 0) {
    
    second_top_shows_by_category_zscore <- second_show_performance_zscore %>%
      group_by(day_type) %>%
      arrange(desc(second_avg_zscore_performance)) %>%
      slice_head(n = 5) %>%  # Top 5 per category
      ungroup() %>%
      mutate(
        second_avg_zscore_performance = round(second_avg_zscore_performance, 2),
        second_avg_listeners = round(second_avg_listeners, 0)
      ) %>%
      select(day_type, second_showname, second_avg_zscore_performance, second_avg_listeners, second_airtime_hours) %>%
      arrange(day_type, desc(second_avg_zscore_performance))
    
    cat("✓ Second station top shows by category (z-score) created\n")
  } else {
    second_top_shows_by_category_zscore <- data.frame()
  }
  
  if (exists("second_artist_impact_zscore") && nrow(second_artist_impact_zscore) > 0) {
    
    # Best impactful artists
    second_best_artists_zscore <- second_artist_impact_zscore %>%
      filter(second_avg_zscore_impact > 0) %>%
      arrange(desc(second_avg_zscore_impact)) %>%
      head(10) %>%
      mutate(
        second_avg_zscore_impact = round(second_avg_zscore_impact, 2),
        second_avg_listeners = round(second_avg_listeners, 0)
      ) %>%
      select(second_artist, second_avg_zscore_impact, second_plays, second_avg_listeners)
    
    # Worst impactful artists
    second_worst_artists_zscore <- second_artist_impact_zscore %>%
      filter(second_avg_zscore_impact < 0) %>%
      arrange(second_avg_zscore_impact) %>%
      head(10) %>%
      mutate(
        second_avg_zscore_impact = round(second_avg_zscore_impact, 2),
        second_avg_listeners = round(second_avg_listeners, 0)
      ) %>%
      select(second_artist, second_avg_zscore_impact, second_plays, second_avg_listeners)
    
    cat("✓ Second station best/worst artists (z-score) created\n")
  } else {
    second_best_artists_zscore <- data.frame()
    second_worst_artists_zscore <- data.frame()
  }
  
  if (exists("second_genre_impact_zscore") && nrow(second_genre_impact_zscore) > 0) {
    
    # Best performing genres
    second_best_genres_zscore <- second_genre_impact_zscore %>%
      filter(second_avg_zscore_impact > 0) %>%
      arrange(desc(second_avg_zscore_impact)) %>%
      head(10) %>%
      mutate(
        second_avg_zscore_impact = round(second_avg_zscore_impact, 2),
        second_avg_listeners = round(second_avg_listeners, 0)
      ) %>%
      select(second_genre, second_avg_zscore_impact, second_plays, second_avg_listeners)
    
    # Worst performing genres
    second_worst_genres_zscore <- second_genre_impact_zscore %>%
      filter(second_avg_zscore_impact < 0) %>%
      arrange(second_avg_zscore_impact) %>%
      head(10) %>%
      mutate(
        second_avg_zscore_impact = round(second_avg_zscore_impact, 2),
        second_avg_listeners = round(second_avg_listeners, 0)
      ) %>%
      select(second_genre, second_avg_zscore_impact, second_plays, second_avg_listeners)
    
    cat("✓ Second station best/worst genres (z-score) created\n")
  } else {
    second_best_genres_zscore <- data.frame()
    second_worst_genres_zscore <- data.frame()
  }
  
  cat("Second station summary stats created\n")
}

# =============================================================================
# COMPARISON STATION SUMMARY STATS (IF ENABLED)
# =============================================================================

if (ANALYSE_COMPARISON_STATION == "Y") {
  
  comparison_summary_stats <- list()
  
  # Basic listener statistics
  comparison_summary_stats$avg_daily_listeners <- mean(data$comparison_total_listeners, na.rm = TRUE)
  comparison_summary_stats$max_listeners <- max(data$comparison_total_listeners, na.rm = TRUE)
  comparison_summary_stats$min_listeners <- min(data$comparison_total_listeners, na.rm = TRUE)
  
  # Peak hour analysis
  if (exists("comparison_hourly_listening") && nrow(comparison_hourly_listening) > 0) {
    peak_hour_data <- comparison_hourly_listening %>%
      arrange(desc(comparison_avg_listeners))
    
    comparison_summary_stats$peak_hour <- peak_hour_data$hour[1]
    comparison_summary_stats$peak_listeners <- peak_hour_data$comparison_avg_listeners[1]
  } else {
    # Fallback calculation
    peak_hour_data <- data %>%
      group_by(hour) %>%
      summarise(avg_listeners = mean(comparison_total_listeners, na.rm = TRUE), .groups = 'drop') %>%
      arrange(desc(avg_listeners))
    
    comparison_summary_stats$peak_hour <- peak_hour_data$hour[1]
    comparison_summary_stats$peak_listeners <- peak_hour_data$avg_listeners[1]
  }
  
  # Best day analysis
  if (exists("comparison_daily_listening") && nrow(comparison_daily_listening) > 0) {
    best_day_data <- comparison_daily_listening %>%
      arrange(desc(comparison_avg_listeners))
    
    comparison_summary_stats$best_day <- best_day_data$weekday[1]
    comparison_summary_stats$best_day_avg <- best_day_data$comparison_avg_listeners[1]
  } else {
    # Fallback calculation
    best_day_data <- data %>%
      mutate(weekday_name = case_when(
        weekday == "Monday" | weekday == 1 | weekday == "1" ~ "Monday",
        weekday == "Tuesday" | weekday == 2 | weekday == "2" ~ "Tuesday", 
        weekday == "Wednesday" | weekday == 3 | weekday == "3" ~ "Wednesday",
        weekday == "Thursday" | weekday == 4 | weekday == "4" ~ "Thursday",
        weekday == "Friday" | weekday == 5 | weekday == "5" ~ "Friday",
        weekday == "Saturday" | weekday == 6 | weekday == "6" ~ "Saturday",
        weekday == "Sunday" | weekday == 7 | weekday == "7" ~ "Sunday",
        TRUE ~ as.character(weekday)
      )) %>%
      group_by(weekday_name) %>%
      summarise(avg_listeners = mean(comparison_total_listeners, na.rm = TRUE), .groups = 'drop') %>%
      arrange(desc(avg_listeners))
    
    comparison_summary_stats$best_day <- best_day_data$weekday_name[1]
    comparison_summary_stats$best_day_avg <- best_day_data$avg_listeners[1]
  }
  
  # Date range and observation counts
  comparison_summary_stats$start_date <- min(data$date)
  comparison_summary_stats$end_date <- max(data$date)
  comparison_summary_stats$total_observations <- nrow(data[!is.na(data$comparison_total_listeners),])
  
  # Show statistics
  if (exists("comparison_show_summary")) {
    comparison_summary_stats$total_shows_analyzed <- nrow(comparison_show_summary)
  }
  
  # Music statistics (if available)
  if ("comparison_artist" %in% names(data)) {
    music_data <- data %>% filter(!is.na(comparison_artist), comparison_artist != "", comparison_artist != "Unknown")
    if (nrow(music_data) > 0) {
      comparison_summary_stats$total_tracks_played <- nrow(music_data)
      comparison_summary_stats$unique_artists <- length(unique(music_data$comparison_artist))
      comparison_summary_stats$unique_tracks <- length(unique(paste(music_data$comparison_artist, music_data$comparison_song)))
      comparison_summary_stats$music_coverage_pct <- (nrow(music_data) / nrow(data)) * 100
    }
  }
  
  cat("Comparison station summary stats created\n")
}

# =============================================================================
# ADDITIONAL SUMMARY CALCULATIONS
# =============================================================================

# Calculate date range string for report title
if (exists("main_summary_stats")) {
  # Check if start and end dates are in the same month AND year
  same_month <- format(main_summary_stats$start_date, "%Y-%m") == format(main_summary_stats$end_date, "%Y-%m")
  
  date_range <- if (same_month) {
    format(main_summary_stats$start_date, "%B %Y")
  } else {
    paste(format(main_summary_stats$start_date, "%B %Y"), "-", format(main_summary_stats$end_date, "%B %Y"))
  }
}

# Monthly trends availability flag
monthly_trends_available <- exists("monthly_trends_clean") && nrow(monthly_trends_clean) > 1

cat("Summary statistics generation complete!\n")

if (DEBUG_TO_CONSOLE == "Y") {
  cat("\nSummary Statistics Created:\n")
  cat("- main_summary_stats: ", length(main_summary_stats), " metrics\n")
  if (ANALYSE_SECOND_STATION == "Y") {
    cat("- second_summary_stats: ", length(second_summary_stats), " metrics\n")
  }
  cat("- date_range: ", date_range, "\n")
  cat("- monthly_trends_available: ", monthly_trends_available, "\n")
}

# =============================================================================
# PDF REPORT GENERATION - COMPLETE GENERALIZED RMD CONTENT
# =============================================================================

# Create R Markdown content for the report
rmd_content <- '
---
title: "PRIVATE AND CONFIDENTIAL
\n
`r MAIN_STATION_NAME` Listener Analysis Report, `r date_range`"
subtitle: "Comprehensive Analysis of Online Streaming Data Including Show Performance, Presenter Analysis, and Live vs Pre-recorded Comparison
\n
Compiled by `r YOUR_NAME`
\n
email: `r YOUR_EMAIL`"

date: "`r format(Sys.Date(), \'%B %d, %Y\')`"
output: 
  pdf_document:
    toc: true
    toc_depth: 3
    number_sections: true
    fig_width: 7
    fig_height: 4.5
geometry: margin=0.8in
header-includes:
  - \\usepackage{booktabs}
  - \\usepackage{longtable}
---

```{r setup, include=FALSE}
knitr::opts_chunk$set(echo = FALSE, warning = FALSE, message = FALSE, 
                      fig.align = "center", fig.width = 7, fig.height = 4.5,
                      out.width = "100%")
library(knitr)
library(dplyr)
library(ggplot2)
library(scales)
library(kableExtra)
```

\\newpage
# Executive Summary

This report analyzes online streaming data for `r MAIN_STATION_NAME`, covering the period from **`r min(data$date)`** to **`r max(data$date)`** with **`r format(nrow(data), big.mark = ",")`** observations collected every `r DATA_COLLECTION` minutes.

```{r comparison-context, results="asis", eval=ANALYSE_COMPARISON_STATION == "Y"}
cat("For context, a comparison with", paste0(COMPARISON_STATION_NAME), "is provided.\\n\\n")
```

```{r second-station-context, results="asis", eval=ANALYSE_SECOND_STATION == "Y"}
cat("Analysis also includes", paste0(SECOND_STATION_NAME), "performance data.\\n\\n")
```

All times are local UK time.

## Key Findings for `r MAIN_STATION_NAME`

```{r main-summary-stats, results="asis"}
if (exists("main_summary_stats")) {
  cat("- **Average Daily Listeners**: ",format(round(main_summary_stats$avg_daily_listeners), big.mark = ",", trim = TRUE), "\\n\\n ")
  cat(glue(
  "- **Peak Hour**: {main_summary_stats$peak_hour}:00 - {main_summary_stats$peak_hour + 1}:00 (",
  format(round(main_summary_stats$peak_listeners), big.mark = ",", trim = TRUE), " listeners)\\n\\n"
  ))
  cat(glue("- **Best Day**: ", main_summary_stats$best_day, " (", format(round(main_summary_stats$best_day_avg), big.mark = ","), " listeners) \\n\\n "))
}
```

```{r programming-summary, results="asis"}
if (exists("main_best_weekday_shows") && nrow(main_best_weekday_shows) > 0) {
  best_weekday <- main_best_weekday_shows[1,]
  cat(glue("- **Best Weekday Show**: ", best_weekday$main_showname, " (+", best_weekday$main_avg_performance, "% vs hour average)\\n\\n "))
}

if (exists("main_best_weekend_shows") && nrow(main_best_weekend_shows) > 0) {
  best_weekend <- main_best_weekend_shows[1,]
  cat(glue("- **Best Weekend Show**: ", best_weekend$main_showname, " (+", best_weekend$main_avg_performance, "% vs hour average)\\n\\n "))
}
```

```{r featured-show-summary, results="asis"}
if (exists("main_featured_summary_stats")) {
  if ("message" %in% names(main_featured_summary_stats)) {
    cat(glue("- **", MAIN_FEATURED_SHOW, "**: ", main_featured_summary_stats$message, "\\n"))
  } else {
    cat(glue("- **", MAIN_FEATURED_SHOW, "**: ", main_featured_summary_stats$total_episodes, " episodes analyzed, "))
    cat(glue("averaging ", format(round(main_featured_summary_stats$avg_listeners), big.mark = ","), " listeners\\n\\n "))
    if (main_featured_summary_stats$presenters_analyzed > 0) {
      cat("   - Top presenter: ", glue(main_featured_summary_stats$best_presenter, " (", format(round(main_featured_summary_stats$best_presenter_avg), big.mark = ","), " average listeners)\\n"))
    }
  }
}
```

```{r second-summary-stats, results="asis", eval=ANALYSE_SECOND_STATION == "Y"}
if (exists("second_summary_stats")) {
  cat("\\n## Key Findings for ", SECOND_STATION_NAME, "\\n\\n")
  cat("- **Average Daily Listeners**: ", glue(format(round(second_summary_stats$avg_daily_listeners), big.mark = ",")), "\\n\\n ")
  cat("- **Peak Hour**: ", glue(second_summary_stats$peak_hour, ":00 - {second_summary_stats$peak_hour + 1}:00 (", format(round(second_summary_stats$peak_listeners), big.mark = ",")), " listeners)\\n\\n ")
  cat("- **Best Day**: ", glue(second_summary_stats$best_day, " (", format(round(second_summary_stats$best_day_avg), big.mark = ",")), " listeners) \\n\\n ")
}
```

# General Observations

- This analysis is intended to aid both the station and the DJs without turning things into a corporate playlist robot - something that tends to define data-driven media outlets. \n
- `r MAIN_STATION_NAME`\'s ShoutCast server page provides data for both the absolute number of listeners, and the number of unique listeners. The data collected is for the number of unique listeners, i.e. the number of ShoutCast connections from unique IP addresses. \n
- While it might seem reasonable to assume that 648MW and DAB listeners will follow similar listening patterns to the online audience, this might not necessarily be the case. \n
- All performance metrics use percentage comparisons rather than absolute numbers to account for natural variations in listening patterns throughout the day. DJ performance is measured against the average for their specific time slots, ensuring fair comparison between peak and off-peak presenters. \n
- However, percentage-based comparisons can look far more dramatic than they actually are in terms of real listener numbers.
- A show performing at "average" levels is still successfully serving its audience - these measurements simply help identify opportunities for improvement or replication of successful approaches. \n
- Any perceived issues that arise from this analysis are just that - "perceived". They are only a problem if deemed a problem. The reality is that `r MAIN_STATION_NAME`\'s listener base is growing over time, so something must be going right! Of course, that isn\'t quite the same as saying that there\'s no room for improvement either... \n
- **PLEASE REFER TO THE GLOSSARY FOR EXPLANATIONS OF THE TERMS USED THROUGHOUT THIS REPORT.** \n

\\newpage
# Data Collection Methodology

Data was collected every `r DATA_COLLECTION` minutes, 24 hours a day, measuring:

- The number of listeners on multiple streams
- DJ/Show name
- Whether the show was live or pre-recorded
- Currently playing track
- Currently playing track genre, harvested from either MusicBrainz, last.fm, or Wikipedia

```{r second-station-methodology, results="asis", eval=ANALYSE_SECOND_STATION == "Y"}
cat("- ", paste0(SECOND_STATION_NAME), " listeners\\n")
cat("- ", paste0(SECOND_STATION_NAME), " DJ/Show name\\n")
```

```{r comparison-methodology, results="asis", eval=ANALYSE_COMPARISON_STATION == "Y"}
cat("- ", paste0(COMPARISON_STATION_NAME), " listeners (The comparison station)\\n")
```

- Public Holiday information
- The weather conditions, and daylight hours, at `r MAIN_STATION_NAME`\'s studios

\\newpage
# `r MAIN_STATION_NAME` Analyses

## Daily Listener Patterns

```{r main_dow-analysis, fig.cap=paste(paste0(MAIN_STATION_NAME), "daily listener patterns as deviation from hourly average"), fig.width=7, fig.height=4}
if (exists("main_dow_comparison_line_chart") && nrow(main_dow_comparison_line_chart) > 0) {
  ggplot(main_dow_comparison_line_chart, aes(x = hour, y = pct_diff, color = weekday)) +
    geom_line(linewidth = 1) +
    geom_hline(yintercept = 0, linetype = "dashed", alpha = 0.5) +
    labs(title = "Daily Listener Patterns Against Average for Each Hour",
         x = "Time", y = "% Difference from Average for Each Hour",
         color = "Day") +
    theme_minimal() +
    theme(legend.position = "bottom", legend.title = element_text(size = 9),
          legend.text = element_text(size = 8)) +
    scale_x_continuous(breaks = seq(0, 23, 4)) +
    guides(color = guide_legend(nrow = 1))
}
```

The day-of-week analysis reveals distinct listening patterns:

- **Peak Performance Days**: Show consistently higher listener numbers across most hours \n
- **Underperforming Days**: May indicate need for programming adjustments \n
- **Time-Specific Patterns**: Some days perform better during specific hours \n
- **Weekend vs Weekday**: Clear behavioural differences between work days and leisure time \n

**NOTE**: Listening figures for Mondays may be negatively impacted by Public Holidays

\\newpage
## Daily Listener Heatmap

```{r main_heatmap-absolute, fig.cap=paste(paste0(MAIN_STATION_NAME), "absolute listener heatmap by day and hour"), fig.width=8, fig.height=5}
if (exists("main_dow_analysis_clean") && nrow(main_dow_analysis_clean) > 0) {
  ggplot(main_dow_analysis_clean, aes(x = hour, y = weekday, fill = main_avg_listeners)) +
    geom_tile(color = "grey60", linewidth = 0.1) +
    scale_fill_gradient2(low = "red", mid = "white", high = "blue", 
                        midpoint = round(mean(data$main_total_listeners, na.rm = TRUE), 0),
                        name = "Avg\\nListeners") +
    labs(title = "Daily Listener Heatmap",
         x = "Hour", y = "Day of Week") +
    theme_minimal() +
    theme(legend.title = element_text(size = 9),
          axis.text.y = element_text(size = 8)) +
    scale_x_continuous(breaks = seq(0, 23, 4))
}
```

**NOTES**: \n
- **Darker red**: Fewer listeners \n
- **Darker blue**: More listeners \n

\\newpage
## Daily Percentage Change Heatmap

```{r main_heatmap-percentage, fig.cap=paste(paste0(MAIN_STATION_NAME), "percentage change heatmap shows relative performance patterns"), fig.width=8, fig.height=5}
if (exists("main_dow_comparison_clean") && nrow(main_dow_comparison_clean) > 0) {
  ggplot(main_dow_comparison_clean, aes(x = hour, y = weekday, fill = pct_diff)) +
    geom_tile(color = "grey60", linewidth = 0.1) +
    scale_fill_gradient2(low = "red", mid = "white", high = "blue", 
                        midpoint = 0, name = "% Diff\\nvs Avg") +
    labs(title = "Daily Percentage Change Heatmap",
         x = "Hour", y = "Day of Week") +
    theme_minimal() +
    theme(legend.title = element_text(size = 9),
          axis.text.y = element_text(size = 8)) +
    scale_x_continuous(breaks = seq(0, 23, 4))
}
```

**NOTES**: \n
- **Blue areas**: Times when specific days significantly outperform the average \n
- **Red areas**: Times when specific days underperform relative to expectations \n
- **White areas**: Performance close to the overall average \n

\\newpage
## Weekday Shows - Absolute Listener Numbers

```{r main-weekday-absolute, fig.cap=paste(paste0(MAIN_STATION_NAME), "weekday shows by absolute listener numbers"), fig.width=7, fig.height=6}
if (exists("main_weekday_absolute") && nrow(main_weekday_absolute) > 0) {
  chart_data <- main_weekday_absolute %>%
    head(100) %>%
    mutate(main_showname_factor = factor(main_showname, levels = rev(main_showname)))
  
  ggplot(chart_data, aes(x = main_avg_absolute_listeners, y = main_showname_factor)) +
    geom_col(fill = "steelblue") +
    labs(title = "Weekday Shows - Absolute Listener Numbers",
         x = "Average Listeners", y = "") +
    theme_minimal()
}
```

\\newpage
## Weekday Shows - Performance

```{r main_show-performance-zscore-weekday-chart, eval=exists("main_show_performance_zscore") && nrow(main_show_performance_zscore) > 0, fig.cap=paste(paste0(MAIN_STATION_NAME), "complete weekday show performance"), fig.width=7, fig.height=6}
if (exists("main_show_performance_zscore") && nrow(main_show_performance_zscore) > 0) {
  
  # Weekday shows only
  weekday_data <- main_show_performance_zscore %>%
    filter(day_type == "Weekday") %>%
    arrange(desc(main_avg_zscore_performance)) %>%
    mutate(main_impact_color = ifelse(main_avg_zscore_performance > 0, "Positive", "Negative"))
  
  if (nrow(weekday_data) > 0) {
    # Take top and bottom performers
    plot_data <- bind_rows(
      weekday_data %>% head(15),
      weekday_data %>% tail(10)
    ) %>% distinct()
    
    ggplot(plot_data, aes(x = main_avg_zscore_performance, y = reorder(main_showname, main_avg_zscore_performance))) +
      geom_col(aes(fill = main_impact_color), alpha = 0.8) +
      geom_vline(xintercept = 0, linetype = "dashed", color = "gray50") +
      scale_fill_manual(values = c("Positive" = "steelblue", "Negative" = "red")) +
      labs(title = paste("Weekday Shows Performance (Z-Score Based)"),
           subtitle = "Performance vs expected listening for weekday time slots",
           x = "Performance Score (Standard Deviations)", 
           y = "",
           fill = "Performance") +
      theme_minimal() +
      theme(legend.position = "bottom", axis.text.y = element_text(size = 8)) +
      scale_x_continuous(breaks = seq(-2, 2, 0.5))
  }
}
```

\\newpage
## Weekday Shows - Hourly Performance Heatmap

```{r main_weekday-heatmap-zscore, eval=exists("main_weekday_heatmap_zscore") && nrow(main_weekday_heatmap_zscore) > 0, fig.cap=paste(paste0(MAIN_STATION_NAME), "weekday shows hourly performance heatmap"), fig.width=8, fig.height=7}
if (exists("main_weekday_heatmap_zscore") && nrow(main_weekday_heatmap_zscore) > 0) {
  
  # Calculate the primary hour for each show (for grouping)
  show_primary_hour <- main_weekday_heatmap_zscore %>%
    group_by(main_showname) %>%
    summarise(primary_hour = min(hour), .groups = "drop")
  
  # Join back to get ordering
  plot_data <- main_weekday_heatmap_zscore %>%
    left_join(show_primary_hour, by = "main_showname")
  
  ggplot(plot_data, aes(x = hour, y = reorder(main_showname, desc(primary_hour)), fill = main_avg_zscore_performance)) +
    geom_tile(color = "grey60", linewidth = 0.1, width = 1.0, height = 1.0) +
    scale_fill_gradient2(
      low = "red", 
      mid = "white", 
      high = "blue",
      midpoint = 0,
      name = "Performance\nScore",
      breaks = seq(-2, 2, 0.5),
      limits = c(-2, 2)
    ) +
    scale_x_continuous(
      limits = c(-0.5, 23.5),              # Forces 0-23 range with padding
      breaks = seq(0, 23, 2),              # Labels every 2 hours  
      minor_breaks = 0:23,                 # Grid lines every hour
      labels = paste0(seq(0, 23, 2), ":00"),
      expand = c(0, 0)
    ) +
    labs(title = paste("Weekday Show Performance by Hour (Z-Score Based)"),
         subtitle = "Performance score shows how shows perform vs expected listening for each hour",
         x = "Hour of Day", 
         y = "") +
    theme_minimal() +
    theme(
      axis.text.x = element_text(size = 8, angle = 45, hjust = 1),
      axis.text.y = element_text(size = 8),
      legend.position = "right",
      panel.grid.minor.x = element_line(color = "grey90", linewidth = 0.2),  # Hour grid lines
      panel.grid.major.x = element_line(color = "grey90", linewidth = 0.4),  # 2-hour grid lines  
      panel.grid.major.y = element_line(color = "grey90", linewidth = 0.2),  # Horizontal grid
      panel.grid.minor.y = element_blank(),                                  # No minor horizontal grid
      plot.margin = margin(10, 10, 10, 10)
    )

} else {
  plot.new()
  text(0.5, 0.5, "No weekday heatmap data available", cex = 1.5)
}
```

\\newpage
## Weekend Shows - Absolute Listener Numbers

```{r main_weekend-absolute, fig.cap=paste(paste0(MAIN_STATION_NAME), "weekend shows by absolute listener numbers"), fig.width=7, fig.height=6}
if (exists("main_weekend_absolute") && nrow(main_weekend_absolute) > 0) {
  chart_data <- main_weekend_absolute %>%
    head(100) %>%
    mutate(main_showname_factor = factor(main_showname, levels = rev(main_showname)))
  
  ggplot(chart_data, aes(x = main_avg_absolute_listeners, y = main_showname_factor)) +
    geom_col(fill = "steelblue") +
    labs(title = "Weekend Shows - Absolute Listener Numbers",
         x = "Average Listeners", y = "") +
    theme_minimal()
}
```

\\newpage
## Weekend Shows - Performance

```{r main_show-performance-zscore-weekend-chart, eval=exists("main_show_performance_zscore") && nrow(main_show_performance_zscore) > 0, fig.cap=paste(paste0(MAIN_STATION_NAME), "complete weekend show performance"), fig.width=7, fig.height=6}
if (exists("main_show_performance_zscore") && nrow(main_show_performance_zscore) > 0) {
  
  # Weekend shows only
  weekend_data <- main_show_performance_zscore %>%
    filter(day_type == "Weekend") %>%
    arrange(desc(main_avg_zscore_performance)) %>%
    mutate(main_impact_color = ifelse(main_avg_zscore_performance > 0, "Positive", "Negative"))
  
  if (nrow(weekend_data) > 0) {
    # Take top and bottom performers
    plot_data <- bind_rows(
      weekend_data %>% head(15),
      weekend_data %>% tail(10)
    ) %>% distinct()
    
    ggplot(plot_data, aes(x = main_avg_zscore_performance, y = reorder(main_showname, main_avg_zscore_performance))) +
      geom_col(aes(fill = main_impact_color), alpha = 0.8) +
      geom_vline(xintercept = 0, linetype = "dashed", color = "gray50") +
      scale_fill_manual(values = c("Positive" = "steelblue", "Negative" = "red")) +
      labs(title = paste("Weekend Shows Performance (Z-Score Based)"),
           subtitle = "Performance vs expected listening for weekend time slots",
           x = "Performance Score (Standard Deviations)", 
           y = "",
           fill = "Performance") +
      theme_minimal() +
      theme(legend.position = "bottom", axis.text.y = element_text(size = 8)) +
      scale_x_continuous(breaks = seq(-2, 2, 0.5))
  }
}
```

\\newpage
## Weekend Shows - Hourly Performance Heatmap

```{r main_weekend-heatmap-zscore, eval=exists("main_weekend_heatmap_zscore") && nrow(main_weekend_heatmap_zscore) > 0, fig.cap=paste(paste0(MAIN_STATION_NAME), "weekend shows hourly performance heatmap"), fig.width=8, fig.height=7}
if (exists("main_weekend_heatmap_zscore") && nrow(main_weekend_heatmap_zscore) > 0) {
  
  # Calculate the primary hour for each show (for grouping)
  show_primary_hour <- main_weekend_heatmap_zscore %>%
    group_by(main_showname) %>%
    summarise(primary_hour = min(hour), .groups = "drop")
  
  # Join back to get ordering
  plot_data <- main_weekend_heatmap_zscore %>%
    left_join(show_primary_hour, by = "main_showname")
  
  ggplot(plot_data, aes(x = hour, y = reorder(main_showname, desc(primary_hour)), fill = main_avg_zscore_performance)) +
    geom_tile(color = "grey60", linewidth = 0.1, width = 1.0, height = 1.0) +
    scale_fill_gradient2(
      low = "red", 
      mid = "white", 
      high = "blue",
      midpoint = 0,
      name = "Performance\nScore",
      breaks = seq(-2, 2, 0.5),
      limits = c(-2, 2)
    ) +
    scale_x_continuous(
      limits = c(-0.5, 23.5),              # Forces 0-23 range with padding
      breaks = seq(0, 23, 2),              # Labels every 2 hours  
      minor_breaks = 0:23,                 # Grid lines every hour
      labels = paste0(seq(0, 23, 2), ":00"),
      expand = c(0, 0)
    ) +
    labs(title = paste("Weekend Show Performance by Hour (Z-Score Based)"),
         subtitle = "Performance score shows how shows perform vs expected listening for each hour",
         x = "Hour of Day", 
         y = "") +
    theme_minimal() +
    theme(
      axis.text.x = element_text(size = 8, angle = 45, hjust = 1),
      axis.text.y = element_text(size = 8),
      legend.position = "right",
      panel.grid.minor.x = element_line(color = "grey90", linewidth = 0.2),  # Hour grid lines
      panel.grid.major.x = element_line(color = "grey90", linewidth = 0.4),  # 2-hour grid lines  
      panel.grid.major.y = element_line(color = "grey90", linewidth = 0.2),  # Horizontal grid
      panel.grid.minor.y = element_blank(),                                  # No minor horizontal grid
      plot.margin = margin(10, 10, 10, 10)
    )

} else {
  plot.new()
  text(0.5, 0.5, "No weekend heatmap data available", cex = 1.5)
}
```

\\newpage
## Consistency & Listener Retention Analyses

These complementary analyses provide a comprehensive view of show quality and audience engagement:

**Performance Consistency Analysis**:

- Measures how reliably each show performs relative to its time slot average across multiple episodes
- Combines average performance with consistency penalties for shows with highly variable listener numbers
- A show that performs +10% one week and -5% the next is less valuable than one that consistently performs +2%
- Helps identify shows that can be relied upon for stable audience delivery, without judging show quality.

**Listener Retention Analysis**:

- Tracks audience behavior during individual episodes by comparing start-of-show vs end-of-show listener counts
- Measures whether a show successfully holds its audience throughout the broadcast
- Compares retention performance against other shows in the same time slot to control for natural hourly variations
- Identifies shows that genuinely engage listeners versus those that may initially attract but then lose audience

**Why Both Matter**:

- **Consistency** answers: "Can we depend on this show to deliver predictable results?"
- **Retention** answers: "Does this show genuinely engage its audience once they tune in?"
- Together they distinguish between shows that are reliably good versus occasionally lucky, and between shows that attract listeners versus those that truly hold their attention

```{r main_consistency-retention-summary-stats, results="asis"}
# Display both sets of summary statistics
if(exists("main_consistency_summary_stats")) {
  cat("**Performance Consistency Summary**:\\n\\n")
  cat("- Shows analyzed:", main_consistency_summary_stats$total_shows_analyzed, "\\n")
  cat("- Broadcast hours analyzed:", format(main_consistency_summary_stats$total_sessions_analyzed, big.mark = ","), "\\n")
  cat("- Average consistency score:", main_consistency_summary_stats$avg_consistency_score, "\\n")
  cat("- Most consistent show:", main_consistency_summary_stats$most_consistent_show, 
      "(", main_consistency_summary_stats$best_consistency_score, " consistency score)\\n")
  cat("- Least consistent show:", main_consistency_summary_stats$least_consistent_show,
      "(", main_consistency_summary_stats$worst_consistency_score, " consistency score)\\n")
  cat("- Shows above time-slot average:", main_consistency_summary_stats$shows_above_avg_performance, 
      "of", main_consistency_summary_stats$total_shows_analyzed, "\\n\\n")
}

if(exists("main_retention_summary_stats")) {
  cat("**Listener Retention Summary**:\\n\\n")
  cat("- Shows analyzed:", main_retention_summary_stats$total_shows_analyzed, "\\n")
  cat("- Broadcast hours analyzed:", format(main_retention_summary_stats$total_broadcast_hours, big.mark = ","), "\\n") 
  cat("- Average retention rate:", main_retention_summary_stats$avg_retention_rate, "%\\n")
  cat("- Best audience retainer:", main_retention_summary_stats$best_retainer, 
      "(", main_retention_summary_stats$best_retention_score, "% vs slot average)\\n")
  cat("- Worst audience retainer:", main_retention_summary_stats$worst_retainer,
      "(", main_retention_summary_stats$worst_retention_score, "% vs slot average)\\n\\n")
}
```

\\newpage
### Weekday Shows - Programme Consistency
```{r main_consistency-weekday-chart, fig.cap=paste("Weekday programme consistency on", paste0(MAIN_STATION_NAME)), fig.width=7, fig.height=6, results="asis"}
if (exists("main_weekday_consistency") && nrow(main_weekday_consistency) > 0) {
  ggplot(main_weekday_consistency, aes(x = main_consistency_score, y = main_showname_factor)) +
    geom_col(aes(fill = main_consistency_score > 0)) +
    geom_vline(xintercept = 0, linetype = "dashed", alpha = 0.7) +
    scale_fill_manual(values = c("red", "steelblue"), 
                      labels = c("Poor/Inconsistent", "Good/Consistent"),
                      name = "Performance") +
    labs(title = "Weekday Programme Consistency",
         x = "Consistency Score", y = "") +
    theme_minimal() +
    theme(legend.position = "bottom")
} else {
  cat("Weekday consistency data not available.\\n")
}
```

\\newpage
### Weekday Shows - Audience Retention

```{r main_retention-weekday-chart, fig.cap=paste("Weekday audience retention performance on", paste0(MAIN_STATION_NAME)), fig.width=7, fig.height=6}
if (exists("main_weekday_retention") && nrow(main_weekday_retention) > 0) {
  ggplot(main_weekday_retention, aes(x = main_avg_retention_vs_slot, y = main_showname_factor)) +
    geom_col(aes(fill = main_avg_retention_vs_slot > 0)) +
    geom_vline(xintercept = 0, linetype = "dashed", alpha = 0.7) +
    scale_fill_manual(values = c("red", "steelblue"), 
                      labels = c("Below Average", "Above Average"),
                      name = "Retention") +
    labs(title = "Weekday Audience Retention Performance",
         x = "% Retention vs Time Slot Average", y = "") +
    theme_minimal() +
    theme(legend.position = "bottom")
}
```

\\newpage
### Weekday Shows - Hourly Retention Patterns

```{r main_retention-heatmap-weekday, fig.cap=paste("Weekday shows: retention performance across different hours on", paste0(MAIN_STATION_NAME)), fig.width=7, fig.height=5}
if (exists("main_weekday_retention_heatmap")) {
  print(main_weekday_retention_heatmap)
} else {
  cat("Weekday retention heatmap not available.\\n")
}
```

**NOTE**: This heatmap shows shows that broadcast in multiple different weekday time slots. With limited data, these visualizations may not be available until more data is collected.

\\newpage
### Weekday Shows - Audience Retention Performance

```{r main_retention-summary-table-weekday-enhanced, results = "asis"}
# Enhanced weekday retention table with percentile-based grades
if (exists("main_weekday_retention_table") && nrow(main_weekday_retention_table) > 0) {
  
  # Print the table
  print(kable(main_weekday_retention_table,
        caption = paste("Weekday Shows: Audience Retention Performance on", paste0(MAIN_STATION_NAME)),
        col.names = c("Show", "Hours Analyzed", "Avg Retention %", 
                     "vs Slot Avg", "Retention Level", "Consistency"),
        escape = FALSE))
        
  # Show the thresholds for transparency
  cat("\\n**NOTE**: This table uses percentiles to classify Retention Level and Consistency based on all shows (weekday and weekend combined) to ensure consistent grading across the entire schedule. This means apparent inconsistencies may exist with other analyses that either separate weekday/weekend data or use absolute metrics.\\n\\n")
  cat("\\n**Grading Thresholds**\\n\\n")
  cat("- Excellent Retention: >", round(main_retention_thresholds$excellent, 1), "% vs slot avg (top 15%)\\n")
  cat("- Good Retention: >", round(main_retention_thresholds$good, 1), "% vs slot avg (top 35%)\\n") 
  cat("- Average Retention:", round(main_retention_thresholds$average, 1), "% to", round(main_retention_thresholds$good, 1), "% vs slot avg\\n")
  cat("- Poor Retention: <", round(main_retention_thresholds$average, 1), "% vs slot avg (bottom 15%)\\n\\n")
  
  cat("**Consistency Thresholds**\\n\\n")
  cat("- Very Consistent: <", round(main_consistency_thresholds$very_consistent, 1), " standard deviations (top 25%)\\n")
  cat("- Consistent: <", round(main_consistency_thresholds$consistent, 1), " standard deviations (top 50%)\\n")
  cat("- Variable: <", round(main_consistency_thresholds$variable, 1), " standard deviations (top 75%)\\n")
  cat("- Highly Variable: >", round(main_consistency_thresholds$variable, 1), " standard deviations (bottom 25%)")
} else {
  cat("No weekday retention data available after applying filters.\\n")
}
```

\\newpage
### Weekend Shows - Programme Consistency
```{r main_consistency-weekend-chart, fig.cap=paste("Weekend programme consistency on", paste0(MAIN_STATION_NAME)), fig.width=7, fig.height=6, results="asis"}
if (exists("main_weekend_consistency") && nrow(main_weekend_consistency) > 0) {
  ggplot(main_weekend_consistency, aes(x = main_consistency_score, y = main_showname_factor)) +
    geom_col(aes(fill = main_consistency_score > 0)) +
    geom_vline(xintercept = 0, linetype = "dashed", alpha = 0.7) +
    scale_fill_manual(values = c("red", "steelblue"), 
                      labels = c("Poor/Inconsistent", "Good/Consistent"),
                      name = "Performance") +
    labs(title = "Weekend Programme Consistency",
         x = "Consistency Score", y = "") +
    theme_minimal() +
    theme(legend.position = "bottom")
} else {
  cat("Weekend consistency data not available.\\n")
}
```

\\newpage
### Weekend Shows - Audience Retention
```{r main_retention-weekend-chart, fig.cap=paste("Weekend audience retention performance on", paste0(MAIN_STATION_NAME)), fig.width=7, fig.height=6}
if (exists("main_weekend_retention") && nrow(main_weekend_retention) > 0) {
  ggplot(main_weekend_retention, aes(x = main_avg_retention_vs_slot, y = main_showname_factor)) +
    geom_col(aes(fill = main_avg_retention_vs_slot > 0)) +
    geom_vline(xintercept = 0, linetype = "dashed", alpha = 0.7) +
    scale_fill_manual(values = c("red", "steelblue"), 
                      labels = c("Below Avg", "Above Avg"),
                      name = "Retention") +
    labs(title = "Weekend Audience Retention Performance",
         x = "% Retention vs Time Slot Average", y = "") +
    theme_minimal() +
    theme(legend.position = "bottom")
}
```

\\newpage
### Weekend Shows - Hourly Retention Heatmap

```{r main_retention-heatmap-weekend, fig.cap=paste("Weekend shows: retention performance across different hours on", paste0(MAIN_STATION_NAME)), fig.width=7, fig.height=5}
if (exists("main_weekend_retention_heatmap")) {
  print(main_weekend_retention_heatmap)
} else {
  cat("Weekend retention heatmap not available.\\n")
}
```

**NOTE**: This heatmap shows shows that broadcast in multiple different weekend time slots. With limited data, these visualizations may not be available until more data is collected.

\\newpage
### Weekend Shows - Audience Retention Performance

```{r main_retention-summary-table-weekend-enhanced, results = "asis"}
# Enhanced weekend retention table with percentile-based grades
if (exists("main_weekend_retention_table") && nrow(main_weekend_retention_table) > 0) {
  
  # Print the table
  print(kable(main_weekend_retention_table,
        caption = paste("Weekend Shows: Audience Retention Performance on", paste0(MAIN_STATION_NAME)),
        col.names = c("Show", "Hours Analyzed", "Avg Retention %", 
                     "vs Slot Avg", "Retention Level", "Consistency"),
        escape = FALSE))
  
  # Show the thresholds for transparency (same values as weekday for consistency)
  cat("\\n**NOTE**: This table uses percentiles to classify Retention Level and Consistency based on all shows (weekday and weekend combined) to ensure consistent grading across the entire schedule. This means apparent inconsistencies may exist with other analyses that either separate weekday/weekend data or use absolute metrics.\\n\\n")
  cat("\\n**Grading Thresholds**\\n\\n")
  cat("- Excellent Retention: >", round(main_retention_thresholds$excellent, 1), "% vs slot avg (top 15%)\\n")
  cat("- Good Retention: >", round(main_retention_thresholds$good, 1), "% vs slot avg (top 35%)\\n") 
  cat("- Average Retention:", round(main_retention_thresholds$average, 1), "% to", round(main_retention_thresholds$good, 1), "% vs slot avg\\n")
  cat("- Poor Retention: <", round(main_retention_thresholds$average, 1), "% vs slot avg (bottom 15%)\\n\\n")
  
  cat("**Consistency Thresholds**\\n\\n")
  cat("- Very Consistent: <", round(main_consistency_thresholds$very_consistent, 1), " standard deviations (top 25%)\\n")
  cat("- Consistent: <", round(main_consistency_thresholds$consistent, 1), " standard deviations (top 50%)\\n")
  cat("- Variable: <", round(main_consistency_thresholds$variable, 1), " standard deviations (top 75%)\\n")
  cat("- Highly Variable: >", round(main_consistency_thresholds$variable, 1), " standard deviations (bottom 25%)")
} else {
  cat("No weekend retention data available after applying filters.\\n")
}
```

\\newpage
### Hourly Retention Patterns

```{r main_hourly-retention, fig.cap=paste("Average audience retention by hour of day on", paste0(MAIN_STATION_NAME)), fig.width=7, fig.height=5}
if (exists("main_hourly_retention_chart")) {
  print(main_hourly_retention_chart)
} else {
  cat("Hourly retention pattern data not available.\\n")
}
```

**NOTE**: Hourly patterns require multiple episodes across different hours. With limited data, this may show partial patterns.

\\newpage
### Retention Performance vs Variability

```{r main_retention-consistency, fig.cap=paste("Programming overview: retention performance vs variability shows the distribution of", paste0(MAIN_STATION_NAME), "show types"), fig.width=7, fig.height=4.5}
if (exists("main_retention_consistency_chart")) {
  print(main_retention_consistency_chart)
}
```

This scatter plot provides an overview of `r MAIN_STATION_NAME`\'s programming by plotting each show\'s retention performance against retention variability. It reveals the overall distribution and balance of the output.

**Why This Analysis Matters**:

- Shows the diversity of programming performance across the station
- Reveals whether `r MAIN_STATION_NAME` has a balanced mix of reliable vs riskier shows
- Helps assess the station\'s programming risk profile

**Overall Scatter Distribution**:

- **Tight clustering**: Indicates consistent programming approaches across the station
- **Wide scatter**: Suggests diverse programming styles with varying levels of success and predictability
- **Point density concentrations**: Reveals where the majority of the station\'s programming output falls on the performance/variability spectrum

**Programming Profile**:

- **Bottom-Right concentration**: More reliable, consistent audience retention
- **Top-Right spread**: Some programming achieves good retention, but with higher episode-to-episode variation
- **Bottom-Left presence**: Portion of programming that shows predictable, but modest, retention performance
- **Top-Left distribution**: Some programming exhibits both poor retention and high variability



\\newpage
# Who Plays What on `r MAIN_STATION_NAME`?

## DJ Genre Choices

```{r main_dj-genre-heatmap, fig.cap=paste("DJ genre preferences on", paste0(MAIN_STATION_NAME), ". Darker colors indicate higher percentages of that genre"), fig.width=9, fig.height=7}
if (exists("main_dj_genre_plot_data") && nrow(main_dj_genre_plot_data) > 0) {
  ggplot(main_dj_genre_plot_data, aes(x = main_genre, y = main_presenter, fill = main_dj_pct)) +
    geom_tile(color = "grey60", linewidth = 0.1) +
    scale_fill_gradient2(low = "white", mid = "lightblue", high = "darkblue", name = "% of\\nTracks") +
    labs(title = paste("DJ Genre Preferences on", paste0(MAIN_STATION_NAME)),
         x = "Genre (30 most common)", y = "") +
    theme_minimal() +
    theme(axis.text.x = element_text(angle = 45, hjust = 1),
          axis.text.y = element_text(size = 8))
}
```

\\newpage
## DJ Genre Bias Compared to `r MAIN_STATION_NAME` Average

```{r main_dj-genre-bias, fig.cap=paste("DJ genre bias compared to", paste0(MAIN_STATION_NAME), "average. Blue = above average, Red = below average"), fig.width=9, fig.height=7}
if (exists("main_dj_genre_plot_data") && nrow(main_dj_genre_plot_data) > 0) {
  # Filter out STATION OVERALL for bias chart and check for valid data
  bias_data <- main_dj_genre_plot_data %>% 
    filter(main_presenter != "STATION OVERALL") %>%
    filter(!is.na(main_genre_bias), !is.na(main_genre), !is.na(main_presenter))
  
  if (nrow(bias_data) > 0) {
    ggplot(bias_data, aes(x = main_genre, y = main_presenter, fill = main_genre_bias)) +
      geom_tile(color = "grey60", linewidth = 0.1) +
      scale_fill_gradient2(low = "red", mid = "white", high = "blue", 
                          midpoint = 0, name = "% Diff\\nvs Station\\nAverage") +
      labs(title = paste("DJ Genre Bias Compared to", paste0(MAIN_STATION_NAME), "Average"),
           x = "Genre (30 most common)", y = "") +
      theme_minimal() +
      theme(axis.text.x = element_text(angle = 45, hjust = 1),
            axis.text.y = element_text(size = 8))
  } else {
    plot.new()
    text(0.5, 0.5, "Insufficient data for DJ genre bias analysis", cex = 1.5)
  }
} else {
  plot.new()
  text(0.5, 0.5, "No DJ genre data available", cex = 1.5)
}
```

**NOTES**:

- The analysis excludes `r MAIN_FEATURED_SHOW` shows, Continuous music, and Replays.

\\newpage
## DJ Similarity to `r MAIN_STATION_NAME` Average

```{r main_dj-similarity-chart, fig.cap=paste("DJ similarity to", paste0(MAIN_STATION_NAME), "overall genre distribution"), fig.width=8, fig.height=7}
if (exists("main_dj_summary_table") && nrow(main_dj_summary_table) > 0) {
  # Filter for valid data
  similarity_data <- main_dj_summary_table %>%
    filter(!is.na(main_similarity_score), !is.na(main_presenter))
  
  if (nrow(similarity_data) > 0) {
    ggplot(similarity_data, aes(x = reorder(main_presenter, main_similarity_score), y = main_similarity_score)) +
      geom_col(fill = "steelblue") +
      coord_flip() +
      labs(title = paste("DJ Similarity to", paste0(MAIN_STATION_NAME), "Average"), 
           x = "", y = "Similarity Score (100 = identical to station average)",
           subtitle = "Higher scores indicate genre preferences closer to station average") +
      theme_minimal() +
      theme(axis.text.y = element_text(size = 9))
  } else {
    plot.new()
    text(0.5, 0.5, "Insufficient data for DJ similarity analysis", cex = 1.5)
  }
} else {
  plot.new()
  text(0.5, 0.5, "No DJ similarity data available", cex = 1.5)
}
```

**NOTES**:

- The analysis excludes `r if(exists("EXCLUDE_TERMS")) paste(EXCLUDE_TERMS, collapse = ", ") else "special programming"` shows

\\newpage
## DJ Genre Analysis Summary

```{r main_dj-summary-table}
if (exists("main_dj_summary_table") && nrow(main_dj_summary_table) > 0) {
  
  # Display top 20 DJs for readability
  summary_display <- main_dj_summary_table %>%
    head(20)
  
  kable(summary_display,
        caption = paste("DJ Genre Analysis Summary for", paste0(MAIN_STATION_NAME)),
        col.names = c("DJ/Presenter", "Similarity Score", "Total Tracks", "Top Genre", "Top Genre %", "Genres Played"))
} else {
  cat("No DJ genre data available for summary table.\\n")
}
```

**NOTES**:

- **Similarity Score**: How closely the DJ\'s genre mix matches the station average (0-100, higher = more similar) \n
- **Top Genre %**: Percentage of the DJ\'s tracks that are their most-played genre \n
- **Genres Played**: Number of different genres the DJ has played \n
- **Only includes**: DJs with 20+ tracked songs for statistical reliability \n

**This analysis excludes**: \n

- `r if(exists("EXCLUDE_TERMS")) paste(EXCLUDE_TERMS, collapse = ", ") else "Special programming"` shows \n
- Stand-in presenters \n
- Shows with insufficient data \n

\\newpage
## Genre Diversity vs Performance

```{r main_genre-diversity-performance, eval=exists("main_dj_genre_retention") && nrow(main_dj_genre_retention) > 0, fig.cap=paste("Genre diversity vs retention performance for", paste0(MAIN_STATION_NAME), "DJs"), fig.width=7, fig.height=4}
if (exists("main_dj_genre_retention") && nrow(main_dj_genre_retention) > 0) {
  ggplot(main_dj_genre_retention, aes(x = main_genre_diversity_ratio, y = main_avg_retention_vs_slot)) +
    geom_point(aes(size = main_total_broadcast_hours, color = main_retention_category), alpha = 0.7) +
    geom_smooth(method = "lm", se = TRUE, alpha = 0.2) +
    labs(title = "Genre Diversity vs Retention Performance",
         x = "Genre Diversity Ratio",
         y = "Average Retention vs Time Slot (%)",
         size = "Broadcast\\nHours",
         color = "Retention\\nCategory") +
    theme_minimal() +
    guides(color = guide_legend(nrow = 1, byrow = TRUE),
    size = guide_legend(nrow = 1, byrow = TRUE)) +
    theme(legend.position = "bottom",
            legend.box = "vertical",
            legend.text = element_text(size = 8),
            legend.title = element_text(size = 9)) +
    geom_hline(yintercept = 0, linetype = "dashed", alpha = 0.5)
}
```

**Understanding This Chart**:

This scatter plot helps answer the question: "Should DJs play a wide variety of music, or focus on what they do best?"

It shows the relationship between how musically diverse a DJ is (horizontal axis) and how well they retain listeners compared to other shows in the same time slot (vertical axis). Each dot represents one DJ, with larger dots indicating DJs who have more broadcast hours analyzed.

The blue line is a "trend line" that shows the overall pattern across all DJs. Think of it as the average relationship between diversity and retention:

- If the line slopes upward (left to right), it suggests that DJs with more diverse music choices tend to retain listeners better \n
- If the line slopes downward, it suggests that DJs who focus on fewer genres tend to perform better \n
- If the line is roughly flat, it means genre diversity doesn\'t seem to affect listener retention much either way \n

The shaded area around the blue line shows how confident we can be in this trend - a narrower band means we\'re more certain about the relationship.

**What the numbers mean**:

Genre Diversity Ratio:

- 0 = very focused (plays mostly one genre) \n
- 1 = very diverse (plays many genres equally) \n

Retention vs Slot Average:

- Positive numbers mean the DJ retains listeners better than average for their time slot \n
- Negative numbers mean below average listener retention for the time slot \n

\\newpage
## Genre Strategy vs Retention Performance

```{r main_genre-strategy-retention-table}
if (exists("main_genre_strategy_retention_table") && nrow(main_genre_strategy_retention_table) > 0) {
  
  # Display top performers (arranged by retention performance)
  strategy_display <- main_genre_strategy_retention_table %>%
    head(30)  # Show top 30 for readability
  
  kable(strategy_display,
        caption = paste("Genre Strategy vs Retention Performance for", paste0(MAIN_STATION_NAME)),
        col.names = c("DJ", "Primary Genre", "Primary %", "Diversity Ratio", 
                     "Retention vs Slot", "Hours Analyzed", "Retention Level"))
} else {
  cat("No DJ genre-retention data available for strategy analysis.\\n")
}
```

```{r main_genre-strategy-thresholds, results = "asis"}
if (exists("main_retention_thresholds") && exists("main_genre_strategy_retention_table") && nrow(main_genre_strategy_retention_table) > 0) {
  cat("\\n**NOTES**:\\n\\n")
  cat("- This table uses percentiles to classify Retention Level based on all shows (weekday and weekend combined) to ensure consistent grading across the entire schedule. This means apparent inconsistencies may exist with other analyses that either separate weekday/weekend data or use absolute metrics.\\n\\n")
  cat("- This analysis combines DJ genre strategy with audience retention performance\\n\\n")
  cat("- Shows whether focused vs diverse music programming correlates with listener retention\\n\\n")
  cat("- Only includes DJs with sufficient data for both genre analysis and retention measurement\\n\\n")
  cat("- The analysis excludes special programming, stand-ins, and shows with insufficient data\\n\\n")

  cat("**Retention Level Thresholds**\\n\\n")
  cat("- Excellent Retention: Retention vs Slot Average >", round(main_retention_thresholds$excellent, 1), "% (top 15%)\\n\\n")
  cat("- Good Retention: Retention vs Slot Average >", round(main_retention_thresholds$good, 1), "% (top 35%)\\n\\n") 
  cat("- Average Retention: Retention vs Slot Average between", round(main_retention_thresholds$average, 1), "% and", round(main_retention_thresholds$good, 1), "%\\n\\n")
  cat("- Poor Retention: Retention vs Slot Average <", round(main_retention_thresholds$average, 1), "% (bottom 15%)\\n\\n")
}
```

\\newpage
# `r MAIN_STATION_NAME` Impact Analyses

## Most Played Tracks Impact Analysis

```{r main_top-30-tracks-zscore, eval=exists("main_most_played_tracks_zscore") && nrow(main_most_played_tracks_zscore) > 0, fig.cap=paste("Impact of the 30 most played tracks on", paste0(MAIN_STATION_NAME)), fig.width=8, fig.height=8}
if (exists("main_most_played_tracks_zscore") && nrow(main_most_played_tracks_zscore) > 0) {
  
  # Prepare data for plotting - top 30 most played
  plot_data <- main_most_played_tracks_zscore %>%
    head(30) %>%
    mutate(
      main_track_short = str_trunc(main_track, 40),
      main_impact_color = ifelse(main_avg_zscore_impact > 0, "Positive", "Negative")
    )
  
  ggplot(plot_data, aes(x = main_avg_zscore_impact, y = reorder(main_track_short, main_plays))) +
    geom_col(aes(fill = main_impact_color), alpha = 0.8) +
    geom_vline(xintercept = 0, linetype = "dashed", color = "gray50") +
    scale_fill_manual(values = c("Positive" = "steelblue", "Negative" = "red")) +
    labs(title = paste("30 Most Played Tracks Impact Analysis (Z-Score Based)"),
         subtitle = "Impact score represents how much tracks deviate from expected listening patterns for their time slot",
         x = "Impact Score (Standard Deviations)", 
         y = "",
         fill = "Impact Type") +
    theme_minimal() +
    theme(legend.position = "bottom",
          axis.text.y = element_text(size = 8)) +
    scale_x_continuous(breaks = seq(-3, 3, 0.5))

} else {
  plot.new()
  text(0.5, 0.5, "No data available for most played tracks", cex = 1.5)
}
```

\\newpage
## Tracks with the Best and Worst Impact

```{r main_track-impact-zscore-chart, eval=exists("main_track_impact_zscore") && nrow(main_track_impact_zscore) > 0, fig.cap=paste("The best and worst performing tracks played on", paste0(MAIN_STATION_NAME)), fig.width=8, fig.height=8}
if (exists("main_track_impact_zscore") && nrow(main_track_impact_zscore) > 0) {
  
  # Prepare data for plotting - top and bottom 20 tracks
  plot_data <- bind_rows(
    main_track_impact_zscore %>% 
      arrange(desc(main_avg_zscore_impact)) %>% 
      head(20),
    main_track_impact_zscore %>% 
      arrange(main_avg_zscore_impact) %>% 
      head(20)
  ) %>%
  distinct() %>%
  mutate(
    main_track_short = str_trunc(main_track, 40),
    main_impact_color = ifelse(main_avg_zscore_impact > 0, "Positive", "Negative")
  )
  
  ggplot(plot_data, aes(x = main_avg_zscore_impact, y = reorder(main_track_short, main_avg_zscore_impact))) +
    geom_col(aes(fill = main_impact_color), alpha = 0.8) +
    geom_vline(xintercept = 0, linetype = "dashed", color = "gray50") +
    scale_fill_manual(values = c("Positive" = "steelblue", "Negative" = "red")) +
    labs(title = paste("Best and Worst Tracks for Impact (Z-Score Based)"),
         subtitle = "Impact score represents how much tracks deviate from expected listening patterns for their time slot",
         x = "Impact Score (Standard Deviations)", 
         y = "",
         fill = "Impact Type") +
    theme_minimal() +
    theme(legend.position = "bottom",
          axis.text.y = element_text(size = 8)) +
    scale_x_continuous(breaks = seq(-3, 3, 0.5))

} else {
  plot.new()
  text(0.5, 0.5, "Insufficient data for z-score track impact analysis", cex = 1.5)
}
```

\\newpage
## Artist Impact Analysis

```{r main_artist-impact-zscore-chart, eval=exists("main_artist_impact_zscore") && nrow(main_artist_impact_zscore) > 0, fig.cap=paste("Artist impact on listener numbers on", paste0(MAIN_STATION_NAME)), fig.width=8, fig.height=8}
if (exists("main_artist_impact_zscore") && nrow(main_artist_impact_zscore) > 0) {
  
  # Top and bottom 15 artists
  plot_data <- bind_rows(
    main_artist_impact_zscore %>% head(15),
    main_artist_impact_zscore %>% tail(15)
  ) %>%
  distinct() %>%
  mutate(
    main_impact_color = ifelse(main_avg_zscore_impact > 0, "Positive", "Negative")
  )
  
  ggplot(plot_data, aes(x = main_avg_zscore_impact, y = reorder(main_artist, main_avg_zscore_impact))) +
    geom_col(aes(fill = main_impact_color), alpha = 0.8) +
    geom_vline(xintercept = 0, linetype = "dashed", color = "gray50") +
    scale_fill_manual(values = c("Positive" = "steelblue", "Negative" = "red")) +
    labs(title = paste("Artist Impact Analysis (Z-Score Based)"),
         subtitle = "Impact score represents how much artists deviate from expected listening patterns",
         x = "Impact Score (Standard Deviations)", 
         y = "",
         fill = "Impact Type") +
    theme_minimal() +
    theme(legend.position = "bottom",
          axis.text.y = element_text(size = 8)) +
    scale_x_continuous(breaks = seq(-3, 3, 0.5))
}
```

\\newpage
## Genre Impact Analysis

### Overall genre impact on listener numbers
```{r main_genre-impact-chart-z-score, fig.cap=paste("Genre impact on listener numbers on", paste0(MAIN_STATION_NAME), "(The top 15 best genres, and the worst 15)"), fig.width=8, fig.height=8}
if (exists("main_genre_impact_zscore") && nrow(main_genre_impact_zscore) > 0) {
  
  plot_data <- main_genre_impact_zscore %>%
    mutate(
      main_impact_color = ifelse(main_avg_zscore_impact > 0, "Positive", "Negative")
    )
  
  ggplot(plot_data, aes(x = main_avg_zscore_impact, y = reorder(main_genre, main_avg_zscore_impact))) +
    geom_col(aes(fill = main_impact_color), alpha = 0.8) +
    geom_vline(xintercept = 0, linetype = "dashed", color = "gray50") +
    scale_fill_manual(values = c("Positive" = "steelblue", "Negative" = "red")) +
    labs(title = paste("Genre Impact Analysis (Z-Score Based)"),
         subtitle = "Impact score represents how much genres deviate from expected listening patterns",
         x = "Impact Score (Standard Deviations)", 
         y = "",
         fill = "Impact Type") +
    theme_minimal() +
    theme(legend.position = "bottom") +
    scale_x_continuous(breaks = seq(-3, 3, 0.5))
}
```

\\newpage
### Best and worst performing genres by hour
```{r main_genre-impact-by-hour-chart-z-score, eval=exists("main_genre_hour_heatmap_zscore") && nrow(main_genre_hour_heatmap_zscore) > 0, fig.cap=paste("Best and worst genre impacts on listener numbers by hour on", paste0(MAIN_STATION_NAME)), fig.width=7, fig.height=7}
if (exists("main_genre_hour_heatmap_zscore") && nrow(main_genre_hour_heatmap_zscore) > 0) {
  
  ggplot(main_genre_hour_heatmap_zscore, aes(x = hour, y = main_genre, fill = main_avg_zscore_impact)) +
    geom_tile(color = "grey60", linewidth = 0.1, width = 1.0, height = 1.0) +
    scale_fill_gradient2(
      low = "red", 
      mid = "white", 
      high = "blue",
      midpoint = 0,
      name = "Impact\nScore",
      breaks = seq(-2, 2, 0.5),
      limits = c(-2, 2)
    ) +
    scale_x_continuous(
      limits = c(-0.5, 23.5),              # Forces 0-23 range with padding
      breaks = seq(0, 23, 2),              # Labels every 2 hours starting from 6
      minor_breaks = 0:23,                 # Grid lines every hour
      labels = paste0(seq(0, 23, 2), ":00"),
      expand = c(0, 0)
    ) +
    labs(title = paste("Genre Performance by Hour (Z-Score Based)"),
         subtitle = "Impact score shows how genres perform vs expected listening for each time slot",
         x = "Hour of Day", 
         y = "") +
    theme_minimal() +
    theme(
      axis.text.x = element_text(size = 10, angle = 45, hjust = 1),
      axis.text.y = element_text(size = 9),
      legend.position = "right",
      panel.grid.minor.x = element_line(color = "grey90", linewidth = 0.2),  # Hour grid lines
      panel.grid.major.x = element_line(color = "grey90", linewidth = 0.4),  # 2-hour grid lines  
      panel.grid.major.y = element_line(color = "grey90", linewidth = 0.2),  # Horizontal grid
      panel.grid.minor.y = element_blank()                                   # No minor horizontal grid
    )
} else {
  plot.new()
  text(0.5, 0.5, "Insufficient data for genre-hour heatmap", cex = 1.5)
}
```

```{r main_sitting-in-chart, eval=MAIN_SITTING_IN_EXISTS, fig.cap=paste("Performance comparison between sitting-in and regular presenters for identical time slots on", paste0(MAIN_STATION_NAME)), fig.width=7, fig.height=5, results="asis"}
cat("\\\\newpage\\n\\n")
cat("## Sitting-in vs Regular DJ Analysis\\n\\n")
if (exists("main_sitting_in_show_summary") && nrow(main_sitting_in_show_summary) > 0) {
  
  # Create chart data
  sitting_in_chart_data <- main_sitting_in_show_summary %>%
    arrange(desc(main_avg_pct_difference)) %>%
    head(15) %>%  # Top 15 for readability
    mutate(
      comparison_label = paste(sitting_in_presenter, "vs", regular_presenter),
      comparison_factor = reorder(comparison_label, main_avg_pct_difference)
    )
  
  ggplot(sitting_in_chart_data, aes(x = main_avg_pct_difference, y = comparison_factor)) +
    geom_col(aes(fill = main_avg_pct_difference > 0)) +
    geom_vline(xintercept = 0, linetype = "dashed", alpha = 0.7) +
    scale_fill_manual(values = c("red", "steelblue"), 
                      labels = c("Sitting-in Worse", "Sitting-in Better"),
                      name = "Performance") +
    labs(title = "Sitting-in vs Regular DJ Performance",
         x = "% Difference in Listeners", y = "") +
    theme_minimal() +
    theme(legend.position = "bottom",
          axis.text.y = element_text(size = 8))
          
} else {
  plot.new()
  text(0.5, 0.5, "No sitting-in data available for comparison", cex = 1.5)
}
```

```{r main_sitting-in-table, eval=MAIN_SITTING_IN_EXISTS, results="asis"}
if (exists("main_sitting_in_show_summary") && nrow(main_sitting_in_show_summary) > 0) {
  
  sitting_in_table <- main_sitting_in_show_summary %>%
    arrange(desc(main_avg_pct_difference)) %>%
    head(10) %>%
    mutate(
      main_avg_pct_difference = round(main_avg_pct_difference, 1),
      main_sitting_in_win_rate = round(main_sitting_in_wins / main_episodes_compared * 100, 1),
      # Replace commas with spaces for better wrapping in Days column
      main_weekdays_analyzed = str_replace_all(main_weekdays_analyzed, ", ", " ")
    ) %>%
    select(regular_presenter, sitting_in_presenter, main_episodes_compared, 
           main_avg_pct_difference, main_sitting_in_wins, main_regular_wins, 
           main_weekdays_analyzed, main_performance_summary)
  
  print(kable(sitting_in_table,
        caption = "Sitting-in vs Regular Performance by Presenter Pair",
        col.names = c("Regular Presenter", "Sitting-in Presenter", "Hours", 
                     "% Diff", "Sitting-in Wins", "Regular Wins", 
                     "Days", "Summary")) %>%
    column_spec(5, width = "1.2cm") %>%  # Narrow "Sitting-in Wins" column
    column_spec(6, width = "1.2cm") %>%  # Also narrow "Regular Wins" for symmetry  
    column_spec(7, width = "1.5cm"))    # Set fixed width for Days column
        
  cat("\\n**Note**: Positive percentages indicate the sitting-in presenter performed better than the regular presenter.\\n")
} else {
  cat("No sitting-in comparison data available.\\n")
}
```

```{r main_live-recorded-chart, eval=MAIN_LIVE_RECORDED_EXISTS, fig.cap=paste("Live vs pre-recorded programming performance on", paste0(MAIN_STATION_NAME)), fig.width=7, fig.height=5, results="asis"}
cat("\\\\newpage\\n\\n")
cat("## Live vs Pre-recorded Impact Analysis\\n\\n")
if (exists("main_live_recorded_summary") && nrow(main_live_recorded_summary) > 0) {
  
  ggplot(main_live_recorded_summary, aes(x = interaction(main_live_recorded, day_type), y = main_avg_performance)) +
    geom_col(aes(fill = main_avg_performance > 0), width = 0.7) +
    geom_hline(yintercept = 0, linetype = "dashed", alpha = 0.7) +
    scale_fill_manual(values = c("red", "steelblue"), 
                      labels = c("Below Average", "Above Average"),
                      name = "Performance") +
    labs(title = "Live vs Pre-recorded Programming Impact",
         subtitle = "Performance vs time slot average",
         x = "", y = "% Performance vs Time Slot Average") +
    theme_minimal() +
    theme(legend.position = "bottom",
          axis.text.x = element_text(angle = 45, hjust = 1)) +
    scale_x_discrete(labels = c("Live.Weekday" = "Live\nWeekday",
                               "Pre-recorded.Weekday" = "Pre-recorded\nWeekday",
                               "Live.Weekend" = "Live\nWeekend", 
                               "Pre-recorded.Weekend" = "Pre-recorded\nWeekend"))
                               
} else {
  plot.new()
  text(0.5, 0.5, "No live vs pre-recorded data available", cex = 1.5)
}
```

```{r main_dj-live-vs-prerecorded-table, eval=MAIN_LIVE_RECORDED_EXISTS, results="asis"}
if (exists("main_dj_live_recorded_summary") && nrow(main_dj_live_recorded_summary) > 0) {
      print(kable(main_dj_live_recorded_analysis,
          caption = paste("DJ Performance: Live vs Pre-recorded Shows on", paste0(MAIN_STATION_NAME)),
          col.names = c("DJ", "Live Shows", "Pre-rec Shows", 
                       "Live % vs Avg", "Pre-rec % vs Avg", "Difference",
                       "Live Listeners", "Pre-rec Listeners", "Better When")) %>%
      column_spec(2, width = "1.2cm") %>%  # Narrow session count columns
      column_spec(3, width = "1.2cm") %>%
      column_spec(7, width = "1.3cm") %>%  # Narrow listener count columns  
      column_spec(8, width = "1.3cm"))
      
    cat("\\n**Analysis Notes**:\\n")
    cat("- Performance measured against time slot average\\n")
    cat("- Positive difference means DJ performs better when live\\n")
    cat("- Only time slots with both live and pre-recorded shows included\\n\\n")
} else {
  cat("No DJ live vs pre-recorded data available.")
}
```

```{r main_public-holiday-chart, eval=PUBLIC_HOLIDAY_IMPACT_EXISTS, fig.cap=paste("Public holiday impact on", paste0(MAIN_STATION_NAME), "listening patterns"), fig.width=7, fig.height=5, results="asis"}
cat("\\\\newpage\\n")
cat("## Public Holiday Impact Analysis\\n\\n")
if (is.list(main_public_holiday_impact) && "summary" %in% names(main_public_holiday_impact) && 
    nrow(main_public_holiday_impact$summary) > 0) {
  
  ggplot(main_public_holiday_impact$summary, aes(x = interaction(condition_type, day_type), y = avg_performance)) +
    geom_col(aes(fill = avg_performance > 0), width = 0.7) +
    geom_hline(yintercept = 0, linetype = "dashed", alpha = 0.7) +
    scale_fill_manual(values = c("red", "steelblue"), 
                      labels = c("Below Average", "Above Average"),
                      name = "Performance") +
    labs(title = "Public Holiday Impact Analysis",
         subtitle = "Listening behavior on public holidays vs regular days",
         x = "", y = "% Performance vs Baseline") +
    theme_minimal() +
    theme(legend.position = "bottom",
          axis.text.x = element_text(angle = 45, hjust = 1))
          
} else {
  plot.new()
  text(0.5, 0.5, "No public holiday data available for this period", cex = 1.5)
}
```

```{r main_public-holiday-table, eval=PUBLIC_HOLIDAY_IMPACT_EXISTS, results="asis"}
if (is.list(main_public_holiday_impact) && "summary" %in% names(main_public_holiday_impact) && 
    nrow(main_public_holiday_impact$summary) > 0) {
  
  public_holiday_table <- main_public_holiday_impact$summary %>%
    mutate(
      avg_performance = round(avg_performance, 1),
      avg_listeners = round(avg_listeners, 0)
    ) %>%
    select(condition_type, day_type, avg_performance, avg_listeners, time_slots, airtime_hours)
  
  print(kable(public_holiday_table,
        caption = paste("Public Holiday Impact on", paste0(MAIN_STATION_NAME)),
        col.names = c("Condition", "Day Type", "Performance %", "Avg Listeners", "Time Slots", "Airtime Hours")))
        
  cat("\\n**Analysis**: Compares listening patterns on public holidays vs regular days of the same type.\\n")
} else {
  cat("No public holiday impact data available for this period.\\n")
}
```

```{r main_featured-show-overall-performance, eval=(MAIN_FEATURED_SHOW != "" && exists("main_featured_overall_performance")) && nrow(main_featured_overall_performance) > 0, fig.width=7, fig.height=3.75, results="asis"}
cat("\\\\newpage\\n\\n")
cat(paste("# ", MAIN_STATION_NAME, "Featured Show Analyses:", MAIN_FEATURED_SHOW, "\\n\\n"))
cat("## Overall Performance \\n\\n")

if (exists("main_featured_overall_performance") && nrow(main_featured_overall_performance) > 0) {

  # Calculate the hour range for better axis labels
  min_hour <- floor(min(main_featured_overall_performance$time_in_hour))
  max_hour <- ceiling(max(main_featured_overall_performance$time_in_hour))
  
  ggplot(main_featured_overall_performance, aes(x = time_in_hour, y = main_avg_listeners, color = weekday)) +
    geom_line(linewidth = 1.2) +
    geom_point(size = 1.5) +
    labs(title = paste(paste0(MAIN_FEATURED_SHOW), "Overall Performance"), 
         x = paste0("Time (", min_hour, ":00-", max_hour, ":00)"), 
         y = "Average Listeners", 
         color = "Day") +
    theme_minimal() +
    theme(legend.position = "bottom", legend.title = element_text(size = 9),
          legend.text = element_text(size = 8)) +
    scale_x_continuous(breaks = seq(min_hour, max_hour, 0.25), 
                      labels = function(x) paste0(floor(x), ":", sprintf("%02d", (x %% 1) * 60))) +
    scale_y_continuous(labels = scales::comma) +
    guides(color = guide_legend(nrow = 1))
}
```

```{r main_featured-show-dow-patterns, eval=(MAIN_FEATURED_SHOW != "" && exists("main_featured_dow_patterns")) && nrow(main_featured_dow_patterns) > 0, fig.cap=paste(paste0(MAIN_FEATURED_SHOW), "performance by day of week"), fig.width=7, fig.height=2.5, results="asis"}
cat("## Daily Audience Patterns\\n\\n")
if (exists("main_featured_dow_patterns") && nrow(main_featured_dow_patterns) > 0) {
  ggplot(main_featured_dow_patterns, aes(x = weekday, y = main_avg_listeners)) +
    geom_col(fill = "navy", alpha = 0.8) +
    labs(title = paste0(MAIN_FEATURED_SHOW, " Day-of-Week Patterns"), 
         x = "", y = "Average Listeners") +
    theme_minimal() +
    theme(axis.text.x = element_text(angle = 45, hjust = 1)) +
    scale_y_continuous(labels = scales::comma)
}
```

```{r main_featured-show-dj-performance, eval=(MAIN_FEATURED_SHOW != "" && exists("main_featured_dj_performance")) && nrow(main_featured_dj_performance) > 0, fig.cap=paste(paste0(MAIN_FEATURED_SHOW), "presenter performance comparison"), fig.width=7, fig.height=2, results="asis"}
cat("\\\\newpage\\n\\n")
cat("## DJ Performance Analysis\\n\\n")
if (exists("main_featured_dj_performance") && nrow(main_featured_dj_performance) > 0) {
  chart_data <- main_featured_dj_performance %>%
    arrange(desc(main_avg_listeners)) %>%
    head(10) %>%
    mutate(main_presenter_factor = factor(main_presenter, levels = rev(main_presenter)))
  
  ggplot(chart_data, aes(x = main_presenter_factor, y = main_avg_listeners)) +
    geom_col(fill = "darkblue", alpha = 0.8) +
    coord_flip() +
    labs(title = paste0(MAIN_FEATURED_SHOW, " DJ Performance Analysis"), 
         x = "", y = "Average Listeners") +
    theme_minimal() +
    scale_y_continuous(labels = scales::comma)
}
```

```{r main_featured-show-dj-table, eval=(MAIN_FEATURED_SHOW != ""), results="asis"}
if (exists("main_featured_dj_performance") && nrow(main_featured_dj_performance) > 0) {
  dj_table <- main_featured_dj_performance %>%
    mutate(
      main_avg_listeners = round(main_avg_listeners, 0),
      main_pct_vs_featured_avg = round(main_pct_vs_featured_avg, 1),
      main_shows_presented = round(main_sessions / HOUR_NORMALISATION, 0)
    ) %>%
    select(main_presenter, main_avg_listeners, main_shows_presented, main_pct_vs_featured_avg)
  
  print(kable(dj_table,
        caption = paste(paste0(MAIN_FEATURED_SHOW, " Presenter Performance Summary")),
        col.names = c("Presenter", "Avg Listeners", "Shows", "% vs Show Avg")))
}
```

```{r main_featured-show-genre-diversity, eval=(MAIN_FEATURED_SHOW != "" && exists("main_featured_genre_diversity")) && nrow(main_featured_genre_diversity) > 0, fig.cap=paste("Genre diversity in", paste0(MAIN_FEATURED_SHOW), "listener choices"), fig.width=7, fig.height=2.5, results="asis"}
cat("## Genre Diversity Analysis\\n\\n")
if (exists("main_featured_genre_diversity") && nrow(main_featured_genre_diversity) > 0) {
  ggplot(main_featured_genre_diversity, aes(x = main_genre_diversity_ratio)) +
    geom_histogram(bins = 20, fill = "purple", alpha = 0.7, color = "white", linewidth = 0.3) +
    labs(title = paste0(MAIN_FEATURED_SHOW, " Genre Diversity Analysis"), 
         x = "Genre Diversity Ratio (Unique Genres / Total Tracks)", 
         y = "Number of Days") +
    theme_minimal()
}
```

```{r main_featured-show-diversity-summary, eval=(MAIN_FEATURED_SHOW != "" && exists("main_featured_genre_diversity")) && nrow(main_featured_genre_diversity) > 0, results="asis"}
if (exists("main_featured_genre_diversity") && nrow(main_featured_genre_diversity) > 0) {
  diversity_summary <- main_featured_genre_diversity %>%
    summarise(
      avg_diversity = round(mean(main_genre_diversity_ratio, na.rm = TRUE), 3),
      min_diversity = round(min(main_genre_diversity_ratio, na.rm = TRUE), 3),
      max_diversity = round(max(main_genre_diversity_ratio, na.rm = TRUE), 3),
      .groups = "drop"
    )
  
  cat("**Genre Diversity Summary**:\\n\\n")
  cat("- Average diversity ratio:", diversity_summary$avg_diversity, "\\n\\n")
  cat("- Most focused day:", diversity_summary$min_diversity, "\\n\\n")
  cat("- Most diverse day:", diversity_summary$max_diversity, "\\n\\n")
  cat("\\n**Analysis**: This shows the randomness of individual listener choices. A ratio close to 1.0 means a very diverse genre selection, while lower ratios indicate more focused musical tastes.\\n\\n")
}
```

```{r main_featured-show-genre-table, eval=(MAIN_FEATURED_SHOW != ""), results="asis"}
cat("\\\\newpage\\n\\n")
if (exists("main_featured_genre_analysis") && nrow(main_featured_genre_analysis) > 0) {
  top_genres_table <- main_featured_genre_analysis %>%
    head(15) %>%
    mutate(
      main_avg_listeners = round(main_avg_listeners, 0),
      main_listener_impact = round(main_listener_impact, 0)
    ) %>%
    select(main_genre, main_plays, main_avg_listeners, main_listener_impact)
  
  print(kable(top_genres_table,
        caption = paste(paste0(MAIN_FEATURED_SHOW, " Most Requested Genres")),
        col.names = c("Genre", "Requests", "Avg Listeners", "Listener Impact")))
}
```

```{r main_featured-show-tracks-table, eval=(MAIN_FEATURED_SHOW != ""), results="asis"}
if (exists("main_featured_track_analysis") && nrow(main_featured_track_analysis) > 0) {
  top_tracks_table <- main_featured_track_analysis %>%
    filter(!grepl(paste(EXCLUDE_TERMS, collapse = "|"), main_artist, ignore.case = TRUE)) %>%
    filter(!grepl(paste(EXCLUDE_TERMS, collapse = "|"), main_song, ignore.case = TRUE)) %>%
    head(20) %>%
    mutate(
      track = paste(main_artist, "-", main_song),
      main_avg_listeners = round(main_avg_listeners, 0),
      main_listener_impact = round(main_listener_impact, 0)
    ) %>%
    select(track, main_requests, main_avg_listeners, main_listener_impact)
  
  print(kable(top_tracks_table,
        caption = paste(paste0(MAIN_FEATURED_SHOW, " Most Requested Tracks")),
        col.names = c("Track", "Requests", "Avg Listeners", "Listener Impact")))
        
  cat("\\n**NOTE**: If no tracks have been requested more than once in the report period, then this table will be empty.\\n")
}
```

```{r second_dow-analysis, eval=(ANALYSE_SECOND_STATION == "Y"), fig.cap=paste(paste0(SECOND_STATION_NAME), "daily listener patterns as deviation from hourly average"), fig.width=7, fig.height=4, results="asis"}
cat("\\\\newpage\\n\\n")
cat(glue("# ", paste0(SECOND_STATION_NAME), " Analyses\\n\\n"))
cat("## Daily Listener Patterns\\n\\n")

if (exists("second_dow_comparison_line_chart") && nrow(second_dow_comparison_line_chart) > 0) {
  ggplot(second_dow_comparison_line_chart, aes(x = hour, y = pct_diff, color = weekday)) +
    geom_line(linewidth = 1) +
    geom_hline(yintercept = 0, linetype = "dashed", alpha = 0.5) +
    labs(title = "Daily Listener Patterns Against Average for Each Hour",
         x = "Time", y = "% Difference from Average for Each Hour",
         color = "Day") +
    theme_minimal() +
    theme(legend.position = "bottom", legend.title = element_text(size = 9),
          legend.text = element_text(size = 8)) +
    scale_x_continuous(breaks = seq(0, 23, 4)) +
    guides(color = guide_legend(nrow = 1))
}

cat("The day-of-week analysis reveals distinct listening patterns:\\n\\n")

cat("- **Peak Performance Days**: Show consistently higher listener numbers across most hours \\n\\n")
cat("- **Underperforming Days**: May indicate need for programming adjustments \\n\\n")
cat("- **Time-Specific Patterns**: Some days perform better during specific hours \\n\\n")
cat("- **Weekend vs Weekday**: Clear behavioural differences between work days and leisure time \\n\\n")

cat("**NOTE**: Listening figures for Mondays may be negatively impacted by Public Holidays\\n\\n")
```

```{r second_heatmap-absolute, eval=(ANALYSE_SECOND_STATION == "Y"), fig.cap=paste(paste0(SECOND_STATION_NAME), "absolute listener heatmap by day and hour"), fig.width=8, fig.height=5, results="asis"}
cat("\\\\newpage\\n\\n")
cat("## Daily Listener Heatmap\\n\\n")

if (exists("second_dow_analysis_clean") && nrow(second_dow_analysis_clean) > 0) {
  ggplot(second_dow_analysis_clean, aes(x = hour, y = weekday, fill = second_avg_listeners)) +
    geom_tile(color = "grey60", linewidth = 0.1) +
    scale_fill_gradient2(low = "red", mid = "white", high = "blue", 
                        midpoint = round(mean(data$second_total_listeners, na.rm = TRUE), 0),
                        name = "Avg\\nListeners") +
    labs(title = "Daily Listener Heatmap",
         x = "Hour", y = "Day of Week") +
    theme_minimal() +
    theme(legend.title = element_text(size = 9),
          axis.text.y = element_text(size = 8)) +
    scale_x_continuous(breaks = seq(0, 23, 4))
}

cat ("**NOTES**: \\n\\n")
cat ("- **Darker red**: Fewer listeners \\n\\n")
cat ("- **Darker blue**: More listeners \\n\\n")
```

```{r second_heatmap-percentage, eval=(ANALYSE_SECOND_STATION == "Y"), fig.cap=paste(paste0(SECOND_STATION_NAME), "percentage change heatmap shows relative performance patterns"), fig.width=8, fig.height=5, results="asis"}
cat("\\\\newpage\\n\\n")
cat("## Daily Percentage Change Heatmap\\n\\n")

if (exists("second_dow_comparison_clean") && nrow(second_dow_comparison_clean) > 0) {
  ggplot(second_dow_comparison_clean, aes(x = hour, y = weekday, fill = pct_diff)) +
    geom_tile(color = "grey60", linewidth = 0.1) +
    scale_fill_gradient2(low = "red", mid = "white", high = "blue", 
                        midpoint = 0, name = "% Diff\\nvs Avg") +
    labs(title = "Daily Percentage Change Heatmap",
         x = "Hour", y = "Day of Week") +
    theme_minimal() +
    theme(legend.title = element_text(size = 9),
          axis.text.y = element_text(size = 8)) +
    scale_x_continuous(breaks = seq(0, 23, 4))
}

cat("**NOTES**: \\n\\n")
cat("- **Blue areas**: Times when specific days significantly outperform the average \\n\\n")
cat("- **Red areas**: Times when specific days underperform relative to expectations \\n\\n")
cat("- **White areas**: Performance close to the overall average \\n\\n")
```

```{r second-weekday-absolute, eval=(ANALYSE_SECOND_STATION == "Y"), fig.cap=paste(paste0(SECOND_STATION_NAME), "weekday shows by absolute listener numbers"), fig.width=7, fig.height=6, results="asis"}
cat("\\\\newpage\\n\\n")
cat("## Weekday Shows – Absolute Listener Numbers\\n\\n")
if (exists("second_weekday_absolute") && nrow(second_weekday_absolute) > 0) {
  chart_data <- second_weekday_absolute %>%
    head(100) %>%
    mutate(second_showname_factor = factor(second_showname, levels = rev(second_showname)))
  
  ggplot(chart_data, aes(x = second_avg_absolute_listeners, y = second_showname_factor)) +
    geom_col(fill = "steelblue") +
    labs(title = "Weekday Shows - Absolute Listener Numbers",
         x = "Average Listeners", y = "") +
    theme_minimal()
}
```

```{r second_show-performance-zscore-weekday-chart, eval=(ANALYSE_SECOND_STATION == "Y") && exists("second_show_performance_zscore") && nrow(second_show_performance_zscore) > 0, fig.cap=paste(paste0(SECOND_STATION_NAME), "complete weekday show performance"), fig.width=7, fig.height=6, results="asis"}
cat("\\\\newpage\\n\\n")
cat("## Weekday Shows - Performance\\n\\n")
if (exists("second_show_performance_zscore") && nrow(second_show_performance_zscore) > 0) {
  
  # Weekday shows only
  weekday_data <- second_show_performance_zscore %>%
    filter(day_type == "Weekday") %>%
    arrange(desc(second_avg_zscore_performance)) %>%
    mutate(second_impact_color = ifelse(second_avg_zscore_performance > 0, "Positive", "Negative"))
  
  if (nrow(weekday_data) > 0) {
    # Take top and bottom performers
    plot_data <- bind_rows(
      weekday_data %>% head(15),
      weekday_data %>% tail(10)
    ) %>% distinct()
    
    ggplot(plot_data, aes(x = second_avg_zscore_performance, y = reorder(second_showname, second_avg_zscore_performance))) +
      geom_col(aes(fill = second_impact_color), alpha = 0.8) +
      geom_vline(xintercept = 0, linetype = "dashed", color = "gray50") +
      scale_fill_manual(values = c("Positive" = "steelblue", "Negative" = "red")) +
      labs(title = paste("Weekday Shows Performance (Z-Score Based)"),
           subtitle = "Performance vs expected listening for weekday time slots",
           x = "Performance Score (Standard Deviations)", 
           y = "",
           fill = "Performance") +
      theme_minimal() +
      theme(legend.position = "bottom", axis.text.y = element_text(size = 8)) +
      scale_x_continuous(breaks = seq(-2, 2, 0.5))
  }
}
```

```{r second_weekday-heatmap-zscore, eval=(ANALYSE_SECOND_STATION == "Y") && exists("second_weekday_heatmap_zscore") && nrow(second_weekday_heatmap_zscore) > 0, fig.cap=paste(paste0(SECOND_STATION_NAME), "weekday shows hourly performance heatmap"), fig.width=8, fig.height=7, results="asis"}
cat("\\\\newpage\\n\\n")
cat("## Weekday Shows - Hourly Performance Heatmap\\n\\n")
if (exists("second_weekday_heatmap_zscore") && nrow(second_weekday_heatmap_zscore) > 0) {
  
  # Calculate the primary hour for each show (for grouping)
  show_primary_hour <- second_weekday_heatmap_zscore %>%
    group_by(second_showname) %>%
    summarise(primary_hour = min(hour), .groups = "drop")
  
  # Join back to get ordering
  plot_data <- second_weekday_heatmap_zscore %>%
    left_join(show_primary_hour, by = "second_showname")
  
  ggplot(plot_data, aes(x = hour, y = reorder(second_showname, desc(primary_hour)), fill = second_avg_zscore_performance)) +
    geom_tile(color = "grey60", linewidth = 0.1, width = 1.0, height = 1.0) +
    scale_fill_gradient2(
      low = "red", 
      mid = "white", 
      high = "blue",
      midpoint = 0,
      name = "Performance\nScore",
      breaks = seq(-2, 2, 0.5),
      limits = c(-2, 2)
    ) +
    scale_x_continuous(
      limits = c(-0.5, 23.5),              # Forces 0-23 range with padding
      breaks = seq(0, 23, 2),              # Labels every 2 hours  
      minor_breaks = 0:23,                 # Grid lines every hour
      labels = paste0(seq(0, 23, 2), ":00"),
      expand = c(0, 0)
    ) +
    labs(title = paste("Weekday Show Performance by Hour (Z-Score Based)"),
         subtitle = "Performance score shows how shows perform vs expected listening for each hour",
         x = "Hour of Day", 
         y = "") +
    theme_minimal() +
    theme(
      axis.text.x = element_text(size = 8, angle = 45, hjust = 1),
      axis.text.y = element_text(size = 8),
      legend.position = "right",
      panel.grid.minor.x = element_line(color = "grey90", linewidth = 0.2),  # Hour grid lines
      panel.grid.major.x = element_line(color = "grey90", linewidth = 0.4),  # 2-hour grid lines  
      panel.grid.major.y = element_line(color = "grey90", linewidth = 0.2),  # Horizontal grid
      panel.grid.minor.y = element_blank(),                                  # No minor horizontal grid
      plot.margin = margin(10, 10, 10, 10)
    )

} else {
  plot.new()
  text(0.5, 0.5, "No weekday heatmap data available", cex = 1.5)
}
```

```{r second_weekend-absolute, eval=(ANALYSE_SECOND_STATION == "Y"), fig.cap=paste(paste0(SECOND_STATION_NAME), "weekend shows by absolute listener numbers"), fig.width=7, fig.height=6, results="asis"}
cat("\\\\newpage\\n\\n")
cat("## Weekend Shows - Absolute Listener Numbers\\n\\n")
if (exists("second_weekend_absolute") && nrow(second_weekend_absolute) > 0) {
  chart_data <- second_weekend_absolute %>%
    head(100) %>%
    mutate(second_showname_factor = factor(second_showname, levels = rev(second_showname)))
  
  ggplot(chart_data, aes(x = second_avg_absolute_listeners, y = second_showname_factor)) +
    geom_col(fill = "steelblue") +
    labs(title = "Weekend Shows - Absolute Listener Numbers",
         x = "Average Listeners", y = "") +
    theme_minimal()
}
```

```{r second_show-performance-zscore-weekend-chart, eval=(ANALYSE_SECOND_STATION == "Y") && exists("second_show_performance_zscore") && nrow(second_show_performance_zscore) > 0, fig.cap=paste(paste0(SECOND_STATION_NAME), "complete weekend show performance"), fig.width=7, fig.height=6, results="asis"}
cat("\\\\newpage\\n\\n")
cat("## Weekend Shows - Performance\\n\\n")
if (exists("second_show_performance_zscore") && nrow(second_show_performance_zscore) > 0) {
  
  # Weekend shows only
  weekend_data <- second_show_performance_zscore %>%
    filter(day_type == "Weekend") %>%
    arrange(desc(second_avg_zscore_performance)) %>%
    mutate(second_impact_color = ifelse(second_avg_zscore_performance > 0, "Positive", "Negative"))
  
  if (nrow(weekend_data) > 0) {
    # Take top and bottom performers
    plot_data <- bind_rows(
      weekend_data %>% head(15),
      weekend_data %>% tail(10)
    ) %>% distinct()
    
    ggplot(plot_data, aes(x = second_avg_zscore_performance, y = reorder(second_showname, second_avg_zscore_performance))) +
      geom_col(aes(fill = second_impact_color), alpha = 0.8) +
      geom_vline(xintercept = 0, linetype = "dashed", color = "gray50") +
      scale_fill_manual(values = c("Positive" = "steelblue", "Negative" = "red")) +
      labs(title = paste("Weekend Shows Performance (Z-Score Based)"),
           subtitle = "Performance vs expected listening for weekend time slots",
           x = "Performance Score (Standard Deviations)", 
           y = "",
           fill = "Performance") +
      theme_minimal() +
      theme(legend.position = "bottom", axis.text.y = element_text(size = 8)) +
      scale_x_continuous(breaks = seq(-2, 2, 0.5))
  }
}
```

```{r second_weekend-heatmap-zscore, eval=(ANALYSE_SECOND_STATION == "Y") && exists("second_weekend_heatmap_zscore") && nrow(second_weekend_heatmap_zscore) > 0, fig.cap=paste(paste0(SECOND_STATION_NAME), "weekend shows hourly performance heatmap"), fig.width=8, fig.height=7, results="asis"}
cat("\\\\newpage\\n\\n")
cat("## Weekend Shows - Hourly Performance Heatmap\\n\\n")
if (exists("second_weekend_heatmap_zscore") && nrow(second_weekend_heatmap_zscore) > 0) {
  
  # Calculate the primary hour for each show (for grouping)
  show_primary_hour <- second_weekend_heatmap_zscore %>%
    group_by(second_showname) %>%
    summarise(primary_hour = min(hour), .groups = "drop")
  
  # Join back to get ordering
  plot_data <- second_weekend_heatmap_zscore %>%
    left_join(show_primary_hour, by = "second_showname")
  
  ggplot(plot_data, aes(x = hour, y = reorder(second_showname, desc(primary_hour)), fill = second_avg_zscore_performance)) +
    geom_tile(color = "grey60", linewidth = 0.1, width = 1.0, height = 1.0) +
    scale_fill_gradient2(
      low = "red", 
      mid = "white", 
      high = "blue",
      midpoint = 0,
      name = "Performance\nScore",
      breaks = seq(-2, 2, 0.5),
      limits = c(-2, 2)
    ) +
    scale_x_continuous(
      limits = c(-0.5, 23.5),              # Forces 0-23 range with padding
      breaks = seq(0, 23, 2),              # Labels every 2 hours  
      minor_breaks = 0:23,                 # Grid lines every hour
      labels = paste0(seq(0, 23, 2), ":00"),
      expand = c(0, 0)
    ) +
    labs(title = paste("Weekend Show Performance by Hour (Z-Score Based)"),
         subtitle = "Performance score shows how shows perform vs expected listening for each hour",
         x = "Hour of Day", 
         y = "") +
    theme_minimal() +
    theme(
      axis.text.x = element_text(size = 8, angle = 45, hjust = 1),
      axis.text.y = element_text(size = 8),
      legend.position = "right",
      panel.grid.minor.x = element_line(color = "grey90", linewidth = 0.2),  # Hour grid lines
      panel.grid.major.x = element_line(color = "grey90", linewidth = 0.4),  # 2-hour grid lines  
      panel.grid.major.y = element_line(color = "grey90", linewidth = 0.2),  # Horizontal grid
      panel.grid.minor.y = element_blank(),                                  # No minor horizontal grid
      plot.margin = margin(10, 10, 10, 10)
    )

} else {
  plot.new()
  text(0.5, 0.5, "No weekend heatmap data available", cex = 1.5)
}
```

```{r second_consistency_retention_introduction, eval=(ANALYSE_SECOND_STATION == "Y"), results="asis"}
cat("\\\\newpage\\n\\n")
cat("## Consistency & Listener Retention Analyses\\n\\n")

cat("These complementary analyses provide a comprehensive view of show quality and audience engagement:\\n\\n")

cat("**Performance Consistency Analysis**:\\n\\n")

cat("- Measures how reliably each show performs relative to its time slot average across multiple episodes\\n\\n")
cat("- Combines average performance with consistency penalties for shows with highly variable listener numbers\\n\\n")
cat("- A show that performs +10% one week and -5% the next is less valuable than one that consistently performs +2%\\n\\n")
cat("- Helps identify shows that can be relied upon for stable audience delivery, without judging show quality.\\n\\n")

cat("**Listener Retention Analysis**:\\n\\n")

cat("- Tracks audience behavior during individual episodes by comparing start-of-show vs end-of-show listener counts\\n\\n")
cat("- Measures whether a show successfully holds its audience throughout the broadcast\\n\\n")
cat("- Compares retention performance against other shows in the same time slot to control for natural hourly variations\\n\\n")
cat("- Identifies shows that genuinely engage listeners versus those that may initially attract but then lose audience\\n\\n")

cat("**Why Both Matter**:\\n\\n")

cat("- **Consistency** answers: \\"Can we depend on this show to deliver predictable results?\\"\\n\\n")
cat("- **Retention** answers: \\"Does this show genuinely engage its audience once they tune in?\\"\\n\\n")
cat("- Together they distinguish between shows that are reliably good versus occasionally lucky, and between shows that attract listeners versus those that truly hold their attention\\n\\n")
```

```{r second_consistency-retention-summary-stats, eval=(ANALYSE_SECOND_STATION == "Y"), results="asis"}
# Display both sets of summary statistics
if(exists("second_consistency_summary_stats")) {
  cat("**Performance Consistency Summary**:\\n")
  cat("- Shows analyzed:", second_consistency_summary_stats$total_shows_analyzed, "\\n")
  cat("- Broadcast hours analyzed:", format(second_consistency_summary_stats$total_sessions_analyzed, big.mark = ","), "\\n\\n")
  cat("- Average consistency score:", second_consistency_summary_stats$avg_consistency_score, "\\n")
  cat("- Most consistent show:", second_consistency_summary_stats$most_consistent_show, 
      "(", second_consistency_summary_stats$best_consistency_score, " consistency score)\\n")
  cat("- Least consistent show:", second_consistency_summary_stats$least_consistent_show,
      "(", second_consistency_summary_stats$worst_consistency_score, " consistency score)\\n")
  cat("- Shows above time-slot average:", second_consistency_summary_stats$shows_above_avg_performance, 
      "of", second_consistency_summary_stats$total_shows_analyzed, "\\n\\n")
}

if(exists("second_retention_summary_stats")) {
  cat("**Listener Retention Summary**:\\n\\n")
  cat("- Shows analyzed:", second_retention_summary_stats$total_shows_analyzed, "\\n")
  cat("- Broadcast hours analyzed:", format(second_retention_summary_stats$total_broadcast_hours, big.mark = ","), "\\n") 
  cat("- Average retention rate:", second_retention_summary_stats$avg_retention_rate, "%\\n")
  cat("- Best audience retainer:", second_retention_summary_stats$best_retainer, 
      "(", second_retention_summary_stats$best_retention_score, "% vs slot average)\\n")
  cat("- Worst audience retainer:", second_retention_summary_stats$worst_retainer,
      "(", second_retention_summary_stats$worst_retention_score, "% vs slot average)\\n\\n")
}
```

```{r second_consistency-weekday-chart, eval=(ANALYSE_SECOND_STATION == "Y"), fig.cap=paste("Weekday programme consistency on", paste0(SECOND_STATION_NAME)), fig.width=7, fig.height=6, results="asis"}
cat("\\\\newpage\\n\\n")
cat("### Weekday Shows - Programme Consistency\\n\\n")

if (exists("second_weekday_consistency") && nrow(second_weekday_consistency) > 0) {
  ggplot(second_weekday_consistency, aes(x = second_consistency_score, y = second_showname_factor)) +
    geom_col(aes(fill = second_consistency_score > 0)) +
    geom_vline(xintercept = 0, linetype = "dashed", alpha = 0.7) +
    scale_fill_manual(values = c("red", "steelblue"), 
                      labels = c("Poor/Inconsistent", "Good/Consistent"),
                      name = "Performance") +
    labs(title = "Weekday Programme Consistency",
         x = "Consistency Score", y = "") +
    theme_minimal() +
    theme(legend.position = "bottom")
} else {
  cat("Weekday consistency data not available.\\n")
}
```

```{r second_retention-weekday-chart, eval=(ANALYSE_SECOND_STATION == "Y"), fig.cap=paste("Weekday audience retention performance on", paste0(SECOND_STATION_NAME)), fig.width=7, fig.height=6, results="asis"}
cat("\\\\newpage\\n\\n")
cat("### Weekday Shows - Audience Retention\\n\\n")
if (exists("second_weekday_retention") && nrow(second_weekday_retention) > 0) {
  ggplot(second_weekday_retention, aes(x = second_avg_retention_vs_slot, y = second_showname_factor)) +
    geom_col(aes(fill = second_avg_retention_vs_slot > 0)) +
    geom_vline(xintercept = 0, linetype = "dashed", alpha = 0.7) +
    scale_fill_manual(values = c("red", "steelblue"), 
                      labels = c("Below Average", "Above Average"),
                      name = "Retention") +
    labs(title = "Weekday Audience Retention Performance",
         x = "% Retention vs Time Slot Average", y = "") +
    theme_minimal() +
    theme(legend.position = "bottom")
}
```

```{r second_retention-heatmap-weekday, eval=(ANALYSE_SECOND_STATION == "Y"), fig.cap=paste("Weekday shows: retention performance across different hours on", paste0(SECOND_STATION_NAME)), fig.width=7, fig.height=5, results="asis"}
cat("\\\\newpage\\n\\n")
cat("### Weekday Shows - Hourly Retention Patterns\\n\\n")
if (exists("second_weekday_retention_heatmap")) {
  print(second_weekday_retention_heatmap)
} else {
  cat("Weekday retention heatmap not available.\\n")
}
cat("**NOTE**: This heatmap shows shows that broadcast in multiple different weekday time slots. With limited data, these visualizations may not be available until more data is collected.\\n\\n")
```

```{r second_retention-summary-table-weekday-enhanced, eval=(ANALYSE_SECOND_STATION == "Y"), results = "asis"}
cat("\\\\newpage\\n\\n")
cat("### Weekday Shows - Audience Retention Performance\\n\\n")
# Enhanced weekday retention table with percentile-based grades
if (exists("second_weekday_retention_table") && nrow(second_weekday_retention_table) > 0) {
  
  # Print the table
  print(kable(second_weekday_retention_table,
        caption = paste("Weekday Shows: Audience Retention Performance on", paste0(SECOND_STATION_NAME)),
        col.names = c("Show", "Hours Analyzed", "Avg Retention %", 
                     "vs Slot Avg", "Retention Level", "Consistency"),
        escape = FALSE))
        
  # Show the thresholds for transparency
  cat("\\n**NOTE**: This table uses percentiles to classify Retention Level and Consistency based on all shows (weekday and weekend combined) to ensure consistent grading across the entire schedule. This means apparent inconsistencies may exist with other analyses that either separate weekday/weekend data or use absolute metrics.\\n\\n")
  cat("\\n**Grading Thresholds**\\n\\n")
  cat("- Excellent Retention: >", round(second_retention_thresholds$excellent, 1), "% vs slot avg (top 15%)\\n")
  cat("- Good Retention: >", round(second_retention_thresholds$good, 1), "% vs slot avg (top 35%)\\n") 
  cat("- Average Retention:", round(second_retention_thresholds$average, 1), "% to", round(second_retention_thresholds$good, 1), "% vs slot avg\\n")
  cat("- Poor Retention: <", round(second_retention_thresholds$average, 1), "% vs slot avg (bottom 15%)\\n\\n")
  
  cat("**Consistency Thresholds**\\n\\n")
  cat("- Very Consistent: <", round(second_consistency_thresholds$very_consistent, 1), " standard deviations (top 25%)\\n")
  cat("- Consistent: <", round(second_consistency_thresholds$consistent, 1), " standard deviations (top 50%)\\n")
  cat("- Variable: <", round(second_consistency_thresholds$variable, 1), " standard deviations (top 75%)\\n")
  cat("- Highly Variable: >", round(second_consistency_thresholds$variable, 1), " standard deviations (bottom 25%)")
} else {
  cat("No weekday retention data available after applying filters.\\n")
}
```

```{r second_consistency-weekend-chart, eval=(ANALYSE_SECOND_STATION == "Y"), fig.cap=paste("Weekend programme consistency on", paste0(SECOND_STATION_NAME)), fig.width=7, fig.height=6, results="asis"}
cat("\\\\newpage\\n\\n")
cat("### Weekend Shows - Programme Consistency\\n\\n")
if (exists("second_weekend_consistency") && nrow(second_weekend_consistency) > 0) {
  ggplot(second_weekend_consistency, aes(x = second_consistency_score, y = second_showname_factor)) +
    geom_col(aes(fill = second_consistency_score > 0)) +
    geom_vline(xintercept = 0, linetype = "dashed", alpha = 0.7) +
    scale_fill_manual(values = c("red", "steelblue"), 
                      labels = c("Poor/Inconsistent", "Good/Consistent"),
                      name = "Performance") +
    labs(title = "Weekend Programme Consistency",
         x = "Consistency Score", y = "") +
    theme_minimal() +
    theme(legend.position = "bottom")
} else {
  cat("Weekend consistency data not available.\\n")
}
```

```{r second_retention-weekend-chart, eval=(ANALYSE_SECOND_STATION == "Y"), fig.cap=paste("Weekend audience retention performance on", paste0(SECOND_STATION_NAME)), fig.width=7, fig.height=6, results="asis"}
cat("\\\\newpage\\n\\n")
cat("### Weekend Shows - Audience Retention\\n\\n")
if (exists("second_weekend_retention") && nrow(second_weekend_retention) > 0) {
  ggplot(second_weekend_retention, aes(x = second_avg_retention_vs_slot, y = second_showname_factor)) +
    geom_col(aes(fill = second_avg_retention_vs_slot > 0)) +
    geom_vline(xintercept = 0, linetype = "dashed", alpha = 0.7) +
    scale_fill_manual(values = c("red", "steelblue"), 
                      labels = c("Below Avg", "Above Avg"),
                      name = "Retention") +
    labs(title = "Weekend Audience Retention Performance",
         x = "% Retention vs Time Slot Average", y = "") +
    theme_minimal() +
    theme(legend.position = "bottom")
}
```

```{r second_retention-heatmap-weekend, eval=(ANALYSE_SECOND_STATION == "Y"), fig.cap=paste("Weekend shows: retention performance across different hours on", paste0(SECOND_STATION_NAME)), fig.width=7, fig.height=5, results="asis"}
cat("\\\\newpage\\n\\n")
cat("### Weekend Shows - Hourly Retention Heatmap\\n\\n")
if (exists("second_weekend_retention_heatmap")) {
  print(second_weekend_retention_heatmap)
} else {
  cat("Weekend retention heatmap not available.\\n")
}

cat("**NOTE**: This heatmap shows shows that broadcast in multiple different weekend time slots. With limited data, these visualizations may not be available until more data is collected.\\n\\n")
```

```{r second_retention-summary-table-weekend-enhanced, eval=(ANALYSE_SECOND_STATION == "Y"), results = "asis"}
cat("\\\\newpage\\n\\n")
cat("### Weekend Shows - Audience Retention Performance\\n\\n")
# Enhanced weekend retention table with percentile-based grades
if (exists("second_weekend_retention_table") && nrow(second_weekend_retention_table) > 0) {
  
  # Print the table
  print(kable(second_weekend_retention_table,
        caption = paste("Weekend Shows: Audience Retention Performance on", paste0(SECOND_STATION_NAME)),
        col.names = c("Show", "Hours Analyzed", "Avg Retention %", 
                     "vs Slot Avg", "Retention Level", "Consistency"),
        escape = FALSE))
  
  # Show the thresholds for transparency (same values as weekday for consistency)
  cat("\\n**NOTE**: This table uses percentiles to classify Retention Level and Consistency based on all shows (weekday and weekend combined) to ensure consistent grading across the entire schedule. This means apparent inconsistencies may exist with other analyses that either separate weekday/weekend data or use absolute metrics.\\n\\n")
  cat("\\n**Grading Thresholds**\\n\\n")
  cat("- Excellent Retention: >", round(second_retention_thresholds$excellent, 1), "% vs slot avg (top 15%)\\n")
  cat("- Good Retention: >", round(second_retention_thresholds$good, 1), "% vs slot avg (top 35%)\\n") 
  cat("- Average Retention:", round(second_retention_thresholds$average, 1), "% to", round(second_retention_thresholds$good, 1), "% vs slot avg\\n")
  cat("- Poor Retention: <", round(second_retention_thresholds$average, 1), "% vs slot avg (bottom 15%)\\n\\n")
  
  cat("**Consistency Thresholds**\\n\\n")
  cat("- Very Consistent: <", round(second_consistency_thresholds$very_consistent, 1), " standard deviations (top 25%)\\n")
  cat("- Consistent: <", round(second_consistency_thresholds$consistent, 1), " standard deviations (top 50%)\\n")
  cat("- Variable: <", round(second_consistency_thresholds$variable, 1), " standard deviations (top 75%)\\n")
  cat("- Highly Variable: >", round(second_consistency_thresholds$variable, 1), " standard deviations (bottom 25%)")
} else {
  cat("No weekend retention data available after applying filters.\\n")
}
```

```{r second_hourly-retention, eval=(ANALYSE_SECOND_STATION == "Y"), fig.cap=paste("Average audience retention by hour of day on", paste0(SECOND_STATION_NAME)), fig.width=7, fig.height=5, results="asis"}
cat("\\\\newpage\\n\\n")
cat("### Hourly Retention Patterns\\n\\n")
if (exists("second_hourly_retention_chart")) {
  print(second_hourly_retention_chart)
} else {
  cat("Hourly retention pattern data not available.\\n")
}

cat("**NOTE**: Hourly patterns require multiple episodes across different hours. With limited data, this may show partial patterns.\\n\\n")
```

```{r second_retention-consistency, eval=(ANALYSE_SECOND_STATION == "Y"), fig.cap=paste("Programming overview: retention performance vs variability shows the distribution of", paste0(SECOND_STATION_NAME), "show types"), fig.width=7, fig.height=4.5, results="asis"}
cat("\\\\newpage\\n\\n")
cat("### Retention Performance vs Variability\\n\\n")
if (exists("second_retention_consistency_chart")) {
  print(second_retention_consistency_chart)
}

cat(glue("This scatter plot provides an overview of ", paste0(SECOND_STATION_NAME), "\'s programming by plotting each show\'s retention performance against retention variability. It reveals the overall distribution and balance of the output.\\n\\n"))

cat("\\n\\n**Why This Analysis Matters**:\\n\\n")

cat("- Shows the diversity of programming performance across the station\\n\\n")
cat(glue("- Reveals whether ", paste0(SECOND_STATION_NAME), " has a balanced mix of reliable vs riskier shows\\n\\n"))
cat("- Helps assess the station\'s programming risk profile\\n\\n")

cat("**Overall Scatter Distribution**:\\n\\n")

cat("- **Tight clustering**: Indicates consistent programming approaches across the station\\n\\n")
cat("- **Wide scatter**: Suggests diverse programming styles with varying levels of success and predictability\\n\\n")
cat("- **Point density concentrations**: Reveals where the majority of the station\'s programming output falls on the performance/variability spectrum\\n\\n")

cat("**Programming Profile**:\\n\\n")

cat("- **Bottom-Right concentration**: More reliable, consistent audience retention\\n\\n")
cat("- **Top-Right spread**: Some programming achieves good retention, but with higher episode-to-episode variation\\n\\n")
cat("- **Bottom-Left presence**: Portion of programming that shows predictable, but modest, retention performance\\n\\n")
cat("- **Top-Left distribution**: Some programming exhibits both poor retention and high variability\\n\\n")
```

```{r second_dj-genre-heatmap, eval=(ANALYSE_SECOND_STATION == "Y"), fig.cap=paste("DJ genre preferences on", paste0(SECOND_STATION_NAME), ". Darker colors indicate higher percentages of that genre"), fig.width=9, fig.height=7, results="asis"}
cat("\\\\newpage\\n\\n")
cat(glue("# Who Plays What on ", paste0(SECOND_STATION_NAME), "?\\n\\n"))
cat("## DJ Genre Choices\\n\\n")

if (exists("second_dj_genre_plot_data") && nrow(second_dj_genre_plot_data) > 0) {
  ggplot(second_dj_genre_plot_data, aes(x = second_genre, y = second_presenter, fill = second_dj_pct)) +
    geom_tile(color = "grey60", linewidth = 0.1) +
    scale_fill_gradient2(low = "white", mid = "lightblue", high = "darkblue", name = "% of\\nTracks") +
    labs(title = paste("DJ Genre Preferences on", paste0(SECOND_STATION_NAME)),
         x = "Genre (30 most common)", y = "") +
    theme_minimal() +
    theme(axis.text.x = element_text(angle = 45, hjust = 1),
          axis.text.y = element_text(size = 8))
}
```

```{r second_dj-genre-bias, eval=(ANALYSE_SECOND_STATION == "Y"), fig.cap=paste("DJ genre bias compared to", paste0(SECOND_STATION_NAME), "average. Blue = above average, Red = below average"), fig.width=9, fig.height=7, results="asis"}
cat("\\\\newpage\\n\\n")
cat(glue("## DJ Genre Bias Compared to ", paste0(SECOND_STATION_NAME), " Average\\n\\n"))

if (exists("second_dj_genre_plot_data") && nrow(second_dj_genre_plot_data) > 0) {
  # Filter out STATION OVERALL for bias chart and check for valid data
  bias_data <- second_dj_genre_plot_data %>% 
    filter(second_presenter != "STATION OVERALL") %>%
    filter(!is.na(second_genre_bias), !is.na(second_genre), !is.na(second_presenter))
  
  if (nrow(bias_data) > 0) {
    ggplot(bias_data, aes(x = second_genre, y = second_presenter, fill = second_genre_bias)) +
      geom_tile(color = "grey60", linewidth = 0.1) +
      scale_fill_gradient2(low = "red", mid = "white", high = "blue", 
                          midpoint = 0, name = "% Diff\\nvs Station\\nAverage") +
      labs(title = paste("DJ Genre Bias Compared to", paste0(SECOND_STATION_NAME), "Average"),
           x = "Genre (30 most common)", y = "") +
      theme_minimal() +
      theme(axis.text.x = element_text(angle = 45, hjust = 1),
            axis.text.y = element_text(size = 8))
  } else {
    plot.new()
    text(0.5, 0.5, "Insufficient data for DJ genre bias analysis", cex = 1.5)
  }
} else {
  plot.new()
  text(0.5, 0.5, "No DJ genre data available", cex = 1.5)
}
cat(glue("**NOTE**: The analysis excludes ", paste0(SECOND_FEATURED_SHOW), " shows, Continuous music, and Replays.\\n\\n"))
```

```{r second_dj-similarity-chart, eval=(ANALYSE_SECOND_STATION == "Y"), fig.cap=paste("DJ similarity to", paste0(SECOND_STATION_NAME), "overall genre distribution"), fig.width=8, fig.height=7, results="asis"}
cat("\\\\newpage\\n\\n")
cat(glue("## DJ Similarity to ", paste0(SECOND_STATION_NAME), " Average\\n\\n"))
if (exists("second_dj_summary_table") && nrow(second_dj_summary_table) > 0) {
  # Filter for valid data
  similarity_data <- second_dj_summary_table %>%
    filter(!is.na(second_similarity_score), !is.na(second_presenter))
  
  if (nrow(similarity_data) > 0) {
    ggplot(similarity_data, aes(x = reorder(second_presenter, second_similarity_score), y = second_similarity_score)) +
      geom_col(fill = "steelblue") +
      coord_flip() +
      labs(title = paste("DJ Similarity to", paste0(SECOND_STATION_NAME), "Average"), 
           x = "", y = "Similarity Score (100 = identical to station average)",
           subtitle = "Higher scores indicate genre preferences closer to station average") +
      theme_minimal() +
      theme(axis.text.y = element_text(size = 9))
  } else {
    plot.new()
    text(0.5, 0.5, "Insufficient data for DJ similarity analysis", cex = 1.5)
  }
} else {
  plot.new()
  text(0.5, 0.5, "No DJ similarity data available", cex = 1.5)
}

cat(glue("**NOTE**: The analysis excludes", paste(EXCLUDE_TERMS, collapse = ", "), "shows\\n\\n"))
```

```{r second_dj-summary-table, eval=(ANALYSE_SECOND_STATION == "Y"), results="asis"}
cat("\\\\newpage\\n\\n")
cat("## DJ Genre Analysis Summary\\n\\n")
if (exists("second_dj_summary_table") && nrow(second_dj_summary_table) > 0) {
  
  # Display top 20 DJs for readability
  summary_display <- second_dj_summary_table %>%
    head(20)
  
  kable(summary_display,
        caption = paste("DJ Genre Analysis Summary for", paste0(SECOND_STATION_NAME)),
        col.names = c("DJ/Presenter", "Similarity Score", "Total Tracks", "Top Genre", "Top Genre %", "Genres Played"))
} else {
  cat("No DJ genre data available for summary table.\\n")
}


cat("**NOTES**:\\n\\n")

cat("- **Similarity Score**: How closely the DJ\'s genre mix matches the station average (0-100, higher = more similar) \\n\\n")
cat("- **Top Genre %**: Percentage of the DJ\'s tracks that are their most-played genre \\n\\n")
cat("- **Genres Played**: Number of different genres the DJ has played \\n\\n")
cat("- **Only includes**: DJs with 20+ tracked songs for statistical reliability \\n\\n")

cat("**This analysis excludes**: \\n\\n")

cat(glue("- ", paste(EXCLUDE_TERMS, collapse = ", "), "shows \\n\\n"))
cat("- Stand-in presenters \\n\\n")
cat("- Shows with insufficient data \\n\\n")
```

```{r second_genre-diversity-performance, eval=(ANALYSE_SECOND_STATION == "Y") && exists("second_dj_genre_retention") && nrow(second_dj_genre_retention) > 0, fig.cap=paste("Genre diversity vs retention performance for", paste0(SECOND_STATION_NAME), "DJs"), fig.width=7, fig.height=4, results="asis"}
cat("\\\\newpage\\n\\n")
cat("## Genre Diversity vs Performance\\n\\n")
if (exists("second_dj_genre_retention") && nrow(second_dj_genre_retention) > 0) {
  ggplot(second_dj_genre_retention, aes(x = second_genre_diversity_ratio, y = second_avg_retention_vs_slot)) +
    geom_point(aes(size = second_total_broadcast_hours, color = second_retention_category), alpha = 0.7) +
    geom_smooth(method = "lm", se = TRUE, alpha = 0.2) +
    labs(title = "Genre Diversity vs Retention Performance",
         x = "Genre Diversity Ratio",
         y = "Average Retention vs Time Slot (%)",
         size = "Broadcast\\nHours",
         color = "Retention\\nCategory") +
    theme_minimal() +
    guides(color = guide_legend(nrow = 1, byrow = TRUE),
    size = guide_legend(nrow = 1, byrow = TRUE)) +
    theme(legend.position = "bottom",
            legend.box = "vertical",
            legend.text = element_text(size = 8),
            legend.title = element_text(size = 9)) +
    geom_hline(yintercept = 0, linetype = "dashed", alpha = 0.5)
}

cat("**Understanding This Chart**:\\n\\n")

cat("This scatter plot helps answer the question: \\"Should DJs play a wide variety of music, or focus on what they do best?\\"\\n\\n")

cat("It shows the relationship between how musically diverse a DJ is (horizontal axis) and how well they retain listeners compared to other shows in the same time slot (vertical axis). Each dot represents one DJ, with larger dots indicating DJs who have more broadcast hours analyzed.\\n\\n")

cat("The blue line is a \\"trend line\\" that shows the overall pattern across all DJs. Think of it as the average relationship between diversity and retention:\\n\\n")

cat("- If the line slopes upward (left to right), it suggests that DJs with more diverse music choices tend to retain listeners better \\n\\n")
cat("- If the line slopes downward, it suggests that DJs who focus on fewer genres tend to perform better \\n\\n")
cat("- If the line is roughly flat, it means genre diversity doesn\'t seem to affect listener retention much either way \\n\\n")

cat("The shaded area around the blue line shows how confident we can be in this trend - a narrower band means we\'re more certain about the relationship.\\n\\n")

cat("**What the numbers mean**:\\n\\n")

cat("Genre Diversity Ratio:\\n\\n")

cat("- 0 = very focused (plays mostly one genre) \\n\\n")
cat("- 1 = very diverse (plays many genres equally) \\n\\n")

cat("Retention vs Slot Average:\\n\\n")

cat("- Positive numbers mean the DJ retains listeners better than average for their time slot \\n\\n")
cat("- Negative numbers mean below average listener retention for the time slot \\n\\n")
```

```{r second_genre-strategy-retention-table, eval=(ANALYSE_SECOND_STATION == "Y"), results="asis"}
cat("\\\\newpage\\n\\n")
cat("## Genre Strategy vs Retention Performance\\n\\n")
if (exists("second_genre_strategy_retention_table") && nrow(second_genre_strategy_retention_table) > 0) {
  
  # Display top performers (arranged by retention performance)
  strategy_display <- second_genre_strategy_retention_table %>%
    head(30)  # Show top 30 for readability
  
  kable(strategy_display,
        caption = paste("Genre Strategy vs Retention Performance for", paste0(SECOND_STATION_NAME)),
        col.names = c("DJ", "Primary Genre", "Primary %", "Diversity Ratio", 
                     "Retention vs Slot", "Hours Analyzed", "Retention Level"))
} else {
  cat("No DJ genre-retention data available for strategy analysis.\\n")
}
```

```{r second_genre-strategy-thresholds, eval=(ANALYSE_SECOND_STATION == "Y"), results = "asis"}
if (exists("second_retention_thresholds") && exists("second_genre_strategy_retention_table") && nrow(second_genre_strategy_retention_table) > 0) {
  cat("\\n**NOTES**:\\n\\n")
  cat("- This table uses percentiles to classify Retention Level based on all shows (weekday and weekend combined) to ensure consistent grading across the entire schedule. This means apparent inconsistencies may exist with other analyses that either separate weekday/weekend data or use absolute metrics.\\n\\n")
  cat("- This analysis combines DJ genre strategy with audience retention performance\\n\\n")
  cat("- Shows whether focused vs diverse music programming correlates with listener retention\\n\\n")
  cat("- Only includes DJs with sufficient data for both genre analysis and retention measurement\\n\\n")
  cat("- The analysis excludes special programming, stand-ins, and shows with insufficient data\\n\\n")

  cat("**Retention Level Thresholds**\\n\\n")
  cat("- Excellent Retention: Retention vs Slot Average >", round(second_retention_thresholds$excellent, 1), "% (top 15%)\\n\\n")
  cat("- Good Retention: Retention vs Slot Average >", round(second_retention_thresholds$good, 1), "% (top 35%)\\n\\n") 
  cat("- Average Retention: Retention vs Slot Average between", round(second_retention_thresholds$average, 1), "% and", round(second_retention_thresholds$good, 1), "%\\n\\n")
  cat("- Poor Retention: Retention vs Slot Average <", round(second_retention_thresholds$average, 1), "% (bottom 15%)\\n\\n")
}
```

```{r second_top-30-tracks-zscore, eval=(ANALYSE_SECOND_STATION == "Y") && exists("second_most_played_tracks_zscore") && nrow(second_most_played_tracks_zscore) > 0, fig.cap=paste("Impact of the 30 most played tracks on", paste0(SECOND_STATION_NAME)), fig.height=8, results="asis"}
cat("\\\\newpage\\n\\n")
cat(glue("# ", paste0(SECOND_STATION_NAME), "Impact Analyses\\n\\n"))
cat("## Most Playes Tracks Impact Analysis\\n\\n")

if (exists("second_most_played_tracks_zscore") && nrow(second_most_played_tracks_zscore) > 0) {
  
  # Prepare data for plotting - top 30 most played
  plot_data <- second_most_played_tracks_zscore %>%
    head(30) %>%
    mutate(
      second_track_short = str_trunc(second_track, 40),
      second_impact_color = ifelse(second_avg_zscore_impact > 0, "Positive", "Negative")
    )
  
  ggplot(plot_data, aes(x = second_avg_zscore_impact, y = reorder(second_track_short, second_plays))) +
    geom_col(aes(fill = second_impact_color), alpha = 0.8) +
    geom_vline(xintercept = 0, linetype = "dashed", color = "gray50") +
    scale_fill_manual(values = c("Positive" = "steelblue", "Negative" = "red")) +
    labs(title = paste("30 Most Played Tracks Impact Analysis (Z-Score Based)"),
         subtitle = "Impact score represents how much tracks deviate from expected listening patterns for their time slot",
         x = "Impact Score (Standard Deviations)", 
         y = "",
         fill = "Impact Type") +
    theme_minimal() +
    theme(legend.position = "bottom",
          axis.text.y = element_text(size = 8)) +
    scale_x_continuous(breaks = seq(-3, 3, 0.5))

} else {
  plot.new()
  text(0.5, 0.5, "No data available for most played tracks", cex = 1.5)
}
```

```{r second_track-impact-zscore-chart, eval=(ANALYSE_SECOND_STATION == "Y") && exists("second_track_impact_zscore") && nrow(second_track_impact_zscore) > 0, , fig.cap=paste("The best and worst performing tracks played on", paste0(SECOND_STATION_NAME)), fig.width=8, fig.height=8, results="asis"}
cat("\\\\newpage\\n\\n")
cat("## Tracks with the Best and Worst Impact\\n\\n")
if (exists("second_track_impact_zscore") && nrow(second_track_impact_zscore) > 0) {
  
  # Prepare data for plotting - top and bottom 20 tracks
  plot_data <- bind_rows(
    second_track_impact_zscore %>% 
      arrange(desc(second_avg_zscore_impact)) %>% 
      head(20),
    second_track_impact_zscore %>% 
      arrange(second_avg_zscore_impact) %>% 
      head(20)
  ) %>%
  distinct() %>%
  mutate(
    second_track_short = str_trunc(second_track, 40),
    second_impact_color = ifelse(second_avg_zscore_impact > 0, "Positive", "Negative")
  )
  
  ggplot(plot_data, aes(x = second_avg_zscore_impact, y = reorder(second_track_short, second_avg_zscore_impact))) +
    geom_col(aes(fill = second_impact_color), alpha = 0.8) +
    geom_vline(xintercept = 0, linetype = "dashed", color = "gray50") +
    scale_fill_manual(values = c("Positive" = "steelblue", "Negative" = "red")) +
    labs(title = paste("Best and Worst Tracks for Impact (Z-Score Based)"),
         subtitle = "Impact score represents how much tracks deviate from expected listening patterns for their time slot",
         x = "Impact Score (Standard Deviations)", 
         y = "",
         fill = "Impact Type") +
    theme_minimal() +
    theme(legend.position = "bottom",
          axis.text.y = element_text(size = 8)) +
    scale_x_continuous(breaks = seq(-3, 3, 0.5))

} else {
  plot.new()
  text(0.5, 0.5, "Insufficient data for z-score track impact analysis", cex = 1.5)
}
```

```{r second_artist-impact-zscore-chart, eval=(ANALYSE_SECOND_STATION == "Y") && exists("second_artist_impact_zscore") && nrow(second_artist_impact_zscore) > 0,  fig.cap=paste("Artist impact on listener numbers on", paste0(SECOND_STATION_NAME)), fig.width=8, fig.height=8, results="asis"}
cat("\\\\newpage\\n\\n")
cat("## Artist Impact Analysis\\n\\n")

if (exists("second_artist_impact_zscore") && nrow(second_artist_impact_zscore) > 0) {
  
  # Top and bottom 15 artists
  plot_data <- bind_rows(
    second_artist_impact_zscore %>% head(15),
    second_artist_impact_zscore %>% tail(15)
  ) %>%
  distinct() %>%
  mutate(
    second_impact_color = ifelse(second_avg_zscore_impact > 0, "Positive", "Negative")
  )
  
  ggplot(plot_data, aes(x = second_avg_zscore_impact, y = reorder(second_artist, second_avg_zscore_impact))) +
    geom_col(aes(fill = second_impact_color), alpha = 0.8) +
    geom_vline(xintercept = 0, linetype = "dashed", color = "gray50") +
    scale_fill_manual(values = c("Positive" = "steelblue", "Negative" = "red")) +
    labs(title = paste("Artist Impact Analysis (Z-Score Based)"),
         subtitle = "Impact score represents how much artists deviate from expected listening patterns",
         x = "Impact Score (Standard Deviations)", 
         y = "",
         fill = "Impact Type") +
    theme_minimal() +
    theme(legend.position = "bottom",
          axis.text.y = element_text(size = 8)) +
    scale_x_continuous(breaks = seq(-3, 3, 0.5))
}
```

```{r second_genre-impact-chart-z-score, eval=(ANALYSE_SECOND_STATION == "Y"), fig.cap=paste("Genre impact on listener numbers on", paste0(SECOND_STATION_NAME), "(The top 15 best genres, and the worst 15)"), fig.width=8, fig.height=8, results="asis"}
cat("\\\\newpage\\n\\n")
cat("## Genre Impact Anlysis\\n\\n")
cat("### Overall genre impact on listener numbers\\n\\n")

if (exists("second_genre_impact_zscore") && nrow(second_genre_impact_zscore) > 0) {
  
  plot_data <- second_genre_impact_zscore %>%
    mutate(
      second_impact_color = ifelse(second_avg_zscore_impact > 0, "Positive", "Negative")
    )
  
  ggplot(plot_data, aes(x = second_avg_zscore_impact, y = reorder(second_genre, second_avg_zscore_impact))) +
    geom_col(aes(fill = second_impact_color), alpha = 0.8) +
    geom_vline(xintercept = 0, linetype = "dashed", color = "gray50") +
    scale_fill_manual(values = c("Positive" = "steelblue", "Negative" = "red")) +
    labs(title = paste("Genre Impact Analysis (Z-Score Based)"),
         subtitle = "Impact score represents how much genres deviate from expected listening patterns",
         x = "Impact Score (Standard Deviations)", 
         y = "",
         fill = "Impact Type") +
    theme_minimal() +
    theme(legend.position = "bottom") +
    scale_x_continuous(breaks = seq(-3, 3, 0.5))
}
```

```{r second_genre-impact-by-hour-chart-z-score, eval=(ANALYSE_SECOND_STATION == "Y") && exists("second_genre_hour_heatmap_zscore") && nrow(second_genre_hour_heatmap_zscore) > 0, fig.cap=paste("Best and worst genre impacts on listener numbers by hour on", paste0(SECOND_STATION_NAME)), fig.width=7, fig.height=7, results="asis"}
cat("\\\\newpage\\n\\n")
cat("### Best and worst performing genres by hour\\n\\n")
if (exists("second_genre_hour_heatmap_zscore") && nrow(second_genre_hour_heatmap_zscore) > 0) {
  
  ggplot(second_genre_hour_heatmap_zscore, aes(x = hour, y = second_genre, fill = second_avg_zscore_impact)) +
    geom_tile(color = "grey60", linewidth = 0.1, width = 1.0, height = 1.0) +
    scale_fill_gradient2(
      low = "red", 
      mid = "white", 
      high = "blue",
      midpoint = 0,
      name = "Impact\nScore",
      breaks = seq(-2, 2, 0.5),
      limits = c(-2, 2)
    ) +
    scale_x_continuous(
      limits = c(-0.5, 23.5),              # Forces 0-23 range with padding
      breaks = seq(0, 23, 2),              # Labels every 2 hours starting from 6
      minor_breaks = 0:23,                 # Grid lines every hour
      labels = paste0(seq(0, 23, 2), ":00"),
      expand = c(0, 0)
    ) +
    labs(title = paste("Genre Performance by Hour (Z-Score Based)"),
         subtitle = "Impact score shows how genres perform vs expected listening for each time slot",
         x = "Hour of Day", 
         y = "") +
    theme_minimal() +
    theme(
      axis.text.x = element_text(size = 10, angle = 45, hjust = 1),
      axis.text.y = element_text(size = 9),
      legend.position = "right",
      panel.grid.minor.x = element_line(color = "grey90", linewidth = 0.2),  # Hour grid lines
      panel.grid.major.x = element_line(color = "grey90", linewidth = 0.4),  # 2-hour grid lines  
      panel.grid.major.y = element_line(color = "grey90", linewidth = 0.2),  # Horizontal grid
      panel.grid.minor.y = element_blank()                                   # No minor horizontal grid
    )
} else {
  plot.new()
  text(0.5, 0.5, "Insufficient data for genre-hour heatmap", cex = 1.5)
}
```

```{r second_sitting-in-chart, eval=(ANALYSE_SECOND_STATION == "Y") && SECOND_SITTING_IN_EXISTS, fig.cap=paste("Performance comparison between sitting-in and regular presenters for identical time slots on", paste0(SECOND_STATION_NAME)), fig.width=7, fig.height=5, results="asis"}
cat("\\\\newpage\\n\\n")
cat("## Sitting-in vs Regular DJ Analysis\\n\\n")
if (exists("second_sitting_in_show_summary") && nrow(second_sitting_in_show_summary) > 0) {
  
  # Create chart data
  sitting_in_chart_data <- second_sitting_in_show_summary %>%
    arrange(desc(second_avg_pct_difference)) %>%
    head(15) %>%  # Top 15 for readability
    mutate(
      comparison_label = paste(sitting_in_presenter, "vs", regular_presenter),
      comparison_factor = reorder(comparison_label, second_avg_pct_difference)
    )
  
  ggplot(sitting_in_chart_data, aes(x = second_avg_pct_difference, y = comparison_factor)) +
    geom_col(aes(fill = second_avg_pct_difference > 0)) +
    geom_vline(xintercept = 0, linetype = "dashed", alpha = 0.7) +
    scale_fill_manual(values = c("red", "steelblue"), 
                      labels = c("Sitting-in Worse", "Sitting-in Better"),
                      name = "Performance") +
    labs(title = "Sitting-in vs Regular DJ Performance",
         x = "% Difference in Listeners", y = "") +
    theme_minimal() +
    theme(legend.position = "bottom",
          axis.text.y = element_text(size = 8))
          
} else {
  plot.new()
  text(0.5, 0.5, "No sitting-in data available for comparison", cex = 1.5)
}
```

```{r second_sitting-in-table, eval=(ANALYSE_SECOND_STATION == "Y") && SECOND_SITTING_IN_EXISTS, results="asis"}
if (exists("second_sitting_in_show_summary") && nrow(second_sitting_in_show_summary) > 0) {
  
  sitting_in_table <- second_sitting_in_show_summary %>%
    arrange(desc(second_avg_pct_difference)) %>%
    head(10) %>%
    mutate(
      second_avg_pct_difference = round(second_avg_pct_difference, 1),
      second_sitting_in_win_rate = round(second_sitting_in_wins / second_episodes_compared * 100, 1),
      # Replace commas with spaces for better wrapping in Days column
      second_weekdays_analyzed = str_replace_all(second_weekdays_analyzed, ", ", " ")
    ) %>%
    select(regular_presenter, sitting_in_presenter, second_episodes_compared, 
           second_avg_pct_difference, second_sitting_in_wins, second_regular_wins, 
           second_weekdays_analyzed, second_performance_summary)
  
  print(kable(sitting_in_table,
        caption = "Sitting-in vs Regular Performance by Presenter Pair",
        col.names = c("Regular Presenter", "Sitting-in Presenter", "Hours", 
                     "% Diff", "Sitting-in Wins", "Regular Wins", 
                     "Days", "Summary")) %>%
    column_spec(5, width = "1.2cm") %>%  # Narrow "Sitting-in Wins" column
    column_spec(6, width = "1.2cm") %>%  # Also narrow "Regular Wins" for symmetry  
    column_spec(7, width = "1.5cm"))    # Set fixed width for Days column
        
  cat("\\n**Note**: Positive percentages indicate the sitting-in presenter performed better than the regular presenter.\\n")
} else {
  cat("No sitting-in comparison data available.\\n")
}
```

```{r second_live-recorded-chart, eval=(ANALYSE_SECOND_STATION == "Y") && SECOND_LIVE_RECORDED_EXISTS, fig.cap=paste("Live vs pre-recorded programming performance on", paste0(SECOND_STATION_NAME)), fig.width=7, fig.height=5, results="asis"}
cat("\\\\newpage\\n\\n")
cat("## Live vs Pre-recorded Impact Analysis\\n\\n")
if (exists("second_live_recorded_summary") && nrow(second_live_recorded_summary) > 0) {
  
  ggplot(second_live_recorded_summary, aes(x = interaction(second_live_recorded, day_type), y = second_avg_performance)) +
    geom_col(aes(fill = second_avg_performance > 0), width = 0.7) +
    geom_hline(yintercept = 0, linetype = "dashed", alpha = 0.7) +
    scale_fill_manual(values = c("red", "steelblue"), 
                      labels = c("Below Average", "Above Average"),
                      name = "Performance") +
    labs(title = "Live vs Pre-recorded Programming Impact",
         subtitle = "Performance vs time slot average",
         x = "", y = "% Performance vs Time Slot Average") +
    theme_minimal() +
    theme(legend.position = "bottom",
          axis.text.x = element_text(angle = 45, hjust = 1)) +
    scale_x_discrete(labels = c("Live.Weekday" = "Live\nWeekday",
                               "Pre-recorded.Weekday" = "Pre-recorded\nWeekday",
                               "Live.Weekend" = "Live\nWeekend", 
                               "Pre-recorded.Weekend" = "Pre-recorded\nWeekend"))
                               
} else {
  plot.new()
  text(0.5, 0.5, "No live vs pre-recorded data available", cex = 1.5)
}
```

```{r second_dj-live-vs-prerecorded-table, eval=(ANALYSE_SECOND_STATION == "Y") && SECOND_LIVE_RECORDED_EXISTS, results="asis"}
if (exists("second_dj_live_recorded_summary") && nrow(second_dj_live_recorded_summary) > 0) {
      print(kable(second_dj_live_recorded_analysis,
          caption = paste("DJ Performance: Live vs Pre-recorded Shows on", paste0(SECOND_STATION_NAME)),
          col.names = c("DJ", "Live Shows", "Pre-rec Shows", 
                       "Live % vs Avg", "Pre-rec % vs Avg", "Difference",
                       "Live Listeners", "Pre-rec Listeners", "Better When")) %>%
      column_spec(2, width = "1.2cm") %>%  # Narrow session count columns
      column_spec(3, width = "1.2cm") %>%
      column_spec(7, width = "1.3cm") %>%  # Narrow listener count columns  
      column_spec(8, width = "1.3cm"))
      
    cat("\\n**Analysis Notes**:\\n")
    cat("- Performance measured against time slot average\\n")
    cat("- Positive difference means DJ performs better when live\\n")
    cat("- Only time slots with both live and pre-recorded shows included\\n\\n")
} else {
  cat("No DJ live vs pre-recorded data available.")
}
```

```{r second_public-holiday-chart, eval=(ANALYSE_SECOND_STATION == "Y") && PUBLIC_HOLIDAY_IMPACT_EXISTS, fig.cap=paste("Public holiday impact on", paste0(SECOND_STATION_NAME), "listening patterns"), fig.width=7, fig.height=5, results="asis"}
cat("\\\\newpage\\n")
cat("## Public Holiday Impact Analysis\\n\\n")
if (is.list(second_public_holiday_impact) && "summary" %in% names(second_public_holiday_impact) && 
    nrow(second_public_holiday_impact$summary) > 0) {
  
  ggplot(second_public_holiday_impact$summary, aes(x = interaction(condition_type, day_type), y = avg_performance)) +
    geom_col(aes(fill = avg_performance > 0), width = 0.7) +
    geom_hline(yintercept = 0, linetype = "dashed", alpha = 0.7) +
    scale_fill_manual(values = c("red", "steelblue"), 
                      labels = c("Below Average", "Above Average"),
                      name = "Performance") +
    labs(title = "Public Holiday Impact Analysis",
         subtitle = "Listening behavior on public holidays vs regular days",
         x = "", y = "% Performance vs Baseline") +
    theme_minimal() +
    theme(legend.position = "bottom",
          axis.text.x = element_text(angle = 45, hjust = 1))
          
} else {
  plot.new()
  text(0.5, 0.5, "No public holiday data available for this period", cex = 1.5)
}
```

```{r second_public-holiday-table, eval=(ANALYSE_SECOND_STATION == "Y") && PUBLIC_HOLIDAY_IMPACT_EXISTS, results="asis"}
if (is.list(second_public_holiday_impact) && "summary" %in% names(second_public_holiday_impact) && 
    nrow(second_public_holiday_impact$summary) > 0) {
  
  public_holiday_table <- second_public_holiday_impact$summary %>%
    mutate(
      avg_performance = round(avg_performance, 1),
      avg_listeners = round(avg_listeners, 0)
    ) %>%
    select(condition_type, day_type, avg_performance, avg_listeners, time_slots, airtime_hours)
  
  print(kable(public_holiday_table,
        caption = paste("Public Holiday Impact on", paste0(SECOND_STATION_NAME)),
        col.names = c("Condition", "Day Type", "Performance %", "Avg Listeners", "Time Slots", "Airtime Hours")))
        
  cat("\\n**Analysis**: Compares listening patterns on public holidays vs regular days of the same type.\\n")
} else {
  cat("No public holiday impact data available for this period.\\n")
}
```

```{r second_featured-show-overall-performance, eval=((ANALYSE_SECOND_STATION == "Y") && SECOND_FEATURED_SHOW != "" && exists("second_featured_overall_performance")) && nrow(second_featured_overall_performance) > 0, fig.width=7, fig.height=3.75, results="asis"}
cat("\\\\newpage\\n\\n")
cat(paste("# ", SECOND_STATION_NAME, "Featured Show Analyses:", SECOND_FEATURED_SHOW, "\\n\\n"))
cat("## Overall Performance \\n\\n")

if (exists("second_featured_overall_performance") && nrow(second_featured_overall_performance) > 0) {

  # Calculate the hour range for better axis labels
  min_hour <- floor(min(second_featured_overall_performance$time_in_hour))
  max_hour <- ceiling(max(second_featured_overall_performance$time_in_hour))
  
  ggplot(second_featured_overall_performance, aes(x = time_in_hour, y = second_avg_listeners, color = weekday)) +
    geom_line(linewidth = 1.2) +
    geom_point(size = 1.5) +
    labs(title = paste(paste0(SECOND_FEATURED_SHOW), "Overall Performance"), 
         x = paste0("Time (", min_hour, ":00-", max_hour, ":00)"), 
         y = "Average Listeners", 
         color = "Day") +
    theme_minimal() +
    theme(legend.position = "bottom", legend.title = element_text(size = 9),
          legend.text = element_text(size = 8)) +
    scale_x_continuous(breaks = seq(min_hour, max_hour, 0.25), 
                      labels = function(x) paste0(floor(x), ":", sprintf("%02d", (x %% 1) * 60))) +
    scale_y_continuous(labels = scales::comma) +
    guides(color = guide_legend(nrow = 1))
}
```

```{r second_featured-show-dow-patterns, eval=((ANALYSE_SECOND_STATION == "Y") && SECOND_FEATURED_SHOW != "" && exists("second_featured_dow_patterns")) && nrow(second_featured_dow_patterns) > 0, fig.cap=paste(paste0(SECOND_FEATURED_SHOW), "performance by day of week"), fig.width=7, fig.height=2.5, results="asis"}
cat("## Daily Audience Patterns\\n\\n")
if (exists("second_featured_dow_patterns") && nrow(second_featured_dow_patterns) > 0) {
  ggplot(second_featured_dow_patterns, aes(x = weekday, y = second_avg_listeners)) +
    geom_col(fill = "navy", alpha = 0.8) +
    labs(title = paste0(SECOND_FEATURED_SHOW, " Day-of-Week Patterns"), 
         x = "", y = "Average Listeners") +
    theme_minimal() +
    theme(axis.text.x = element_text(angle = 45, hjust = 1)) +
    scale_y_continuous(labels = scales::comma)
}
```

```{r second_featured-show-dj-performance, eval=((ANALYSE_SECOND_STATION == "Y") && SECOND_FEATURED_SHOW != "" && exists("second_featured_dj_performance")) && nrow(second_featured_dj_performance) > 0, fig.cap=paste(paste0(SECOND_FEATURED_SHOW), "presenter performance comparison"), fig.width=7, fig.height=2, results="asis"}
cat("\\\\newpage\\n\\n")
cat("## DJ Performance Analysis\\n\\n")
if (exists("second_featured_dj_performance") && nrow(second_featured_dj_performance) > 0) {
  chart_data <- second_featured_dj_performance %>%
    arrange(desc(second_avg_listeners)) %>%
    head(10) %>%
    mutate(second_presenter_factor = factor(second_presenter, levels = rev(second_presenter)))
  
  ggplot(chart_data, aes(x = second_presenter_factor, y = second_avg_listeners)) +
    geom_col(fill = "darkblue", alpha = 0.8) +
    coord_flip() +
    labs(title = paste0(SECOND_FEATURED_SHOW, " DJ Performance Analysis"), 
         x = "", y = "Average Listeners") +
    theme_minimal() +
    scale_y_continuous(labels = scales::comma)
}
```

```{r second_featured-show-dj-table, eval=((ANALYSE_SECOND_STATION == "Y") && SECOND_FEATURED_SHOW != ""), results="asis"}
if (exists("second_featured_dj_performance") && nrow(second_featured_dj_performance) > 0) {
  dj_table <- second_featured_dj_performance %>%
    mutate(
      second_avg_listeners = round(second_avg_listeners, 0),
      second_pct_vs_featured_avg = round(second_pct_vs_featured_avg, 1),
      second_shows_presented = round(second_sessions / HOUR_NORMALISATION, 0)
    ) %>%
    select(second_presenter, second_avg_listeners, second_shows_presented, second_pct_vs_featured_avg)
  
  print(kable(dj_table,
        caption = paste(paste0(SECOND_FEATURED_SHOW, " Presenter Performance Summary")),
        col.names = c("Presenter", "Avg Listeners", "Shows", "% vs Show Avg")))
}
```

```{r second_featured-show-genre-diversity, eval=((ANALYSE_SECOND_STATION == "Y") && SECOND_FEATURED_SHOW != "" && exists("second_featured_genre_diversity")) && nrow(second_featured_genre_diversity) > 0, fig.cap=paste("Genre diversity in", paste0(SECOND_FEATURED_SHOW), "listener choices"), fig.width=7, fig.height=2.5, results="asis"}
cat("## Genre Diversity Analysis\\n\\n")
if (exists("second_featured_genre_diversity") && nrow(second_featured_genre_diversity) > 0) {
  ggplot(second_featured_genre_diversity, aes(x = second_genre_diversity_ratio)) +
    geom_histogram(bins = 20, fill = "purple", alpha = 0.7, color = "white", linewidth = 0.3) +
    labs(title = paste0(SECOND_FEATURED_SHOW, " Genre Diversity Analysis"), 
         x = "Genre Diversity Ratio (Unique Genres / Total Tracks)", 
         y = "Number of Days") +
    theme_minimal()
}
```

```{r second_featured-show-diversity-summary, eval=((ANALYSE_SECOND_STATION == "Y") && SECOND_FEATURED_SHOW != "" && exists("second_featured_genre_diversity")) && nrow(second_featured_genre_diversity) > 0, results="asis"}
if (exists("second_featured_genre_diversity") && nrow(second_featured_genre_diversity) > 0) {
  diversity_summary <- second_featured_genre_diversity %>%
    summarise(
      avg_diversity = round(mean(second_genre_diversity_ratio, na.rm = TRUE), 3),
      min_diversity = round(min(second_genre_diversity_ratio, na.rm = TRUE), 3),
      max_diversity = round(max(second_genre_diversity_ratio, na.rm = TRUE), 3),
      .groups = "drop"
    )
  
  cat("**Genre Diversity Summary**:\\n\\n")
  cat("- Average diversity ratio:", diversity_summary$avg_diversity, "\\n\\n")
  cat("- Most focused day:", diversity_summary$min_diversity, "\\n\\n")
  cat("- Most diverse day:", diversity_summary$max_diversity, "\\n\\n")
  cat("\\n**Analysis**: This shows the randomness of individual listener choices. A ratio close to 1.0 means a very diverse genre selection, while lower ratios indicate more focused musical tastes.\\n\\n")
}
```

```{r second_featured-show-genre-table, eval=((ANALYSE_SECOND_STATION == "Y") && SECOND_FEATURED_SHOW != ""), results="asis"}
cat("\\\\newpage\\n\\n")
if (exists("second_featured_genre_analysis") && nrow(second_featured_genre_analysis) > 0) {
  top_genres_table <- second_featured_genre_analysis %>%
    head(15) %>%
    mutate(
      second_avg_listeners = round(second_avg_listeners, 0),
      second_listener_impact = round(second_listener_impact, 0)
    ) %>%
    select(second_genre, second_plays, second_avg_listeners, second_listener_impact)
  
  print(kable(top_genres_table,
        caption = paste(paste0(SECOND_FEATURED_SHOW, " Most Requested Genres")),
        col.names = c("Genre", "Requests", "Avg Listeners", "Listener Impact")))
}
```

```{r second_featured-show-tracks-table, eval=((ANALYSE_SECOND_STATION == "Y") && SECOND_FEATURED_SHOW != ""), results="asis"}
if (exists("second_featured_track_analysis") && nrow(second_featured_track_analysis) > 0) {
  top_tracks_table <- second_featured_track_analysis %>%
    filter(!grepl(paste(EXCLUDE_TERMS, collapse = "|"), second_artist, ignore.case = TRUE)) %>%
    filter(!grepl(paste(EXCLUDE_TERMS, collapse = "|"), second_song, ignore.case = TRUE)) %>%
    head(20) %>%
    mutate(
      track = paste(second_artist, "-", second_song),
      second_avg_listeners = round(second_avg_listeners, 0),
      second_listener_impact = round(second_listener_impact, 0)
    ) %>%
    select(track, second_requests, second_avg_listeners, second_listener_impact)
  
  print(kable(top_tracks_table,
        caption = paste(paste0(SECOND_FEATURED_SHOW, " Most Requested Tracks")),
        col.names = c("Track", "Requests", "Avg Listeners", "Listener Impact")))
        
  cat("\\n**NOTE**: If no tracks have been requested more than once in the report period, then this table will be empty.\\n")
}
```

```{r combined-weather-header, eval=(ANALYSE_WEATHER == "Y") && exists("combined_weather_summary") && nrow(combined_weather_summary) > 0, results="asis"}
cat("\\\\newpage\\n\\n")
cat("# Weather Impact Analysis\\n\\n")
# Determine how many stations are being analyzed
stations_analyzed <- unique(combined_weather_summary$station)
station_count <- length(stations_analyzed)

if (station_count > 1) {
  cat("Comparative weather impact analysis across", station_count, "stations:", paste(stations_analyzed, collapse = ", "), "\n\n")
} else {
  cat("Weather impact analysis for", stations_analyzed[1], "\n\n")
}

cat("**IMPORTANT**: These findings are exploratory and speculative. Correlation does not imply causation!\n\n")
```

```{r combined-weather-conditions-chart, eval=(ANALYSE_WEATHER == "Y") && exists("combined_weather_summary") && nrow(combined_weather_summary) > 0, fig.width=10, fig.height=6}
if (exists("combined_weather_summary") && nrow(combined_weather_summary) > 0) {
  
  # Order weather categories logically
  weather_order <- c("Clear/Sunny", "Partly Cloudy", "Cloudy/Overcast", "Light Rain", 
                    "Moderate Rain", "Rain", "Heavy Rain", "Fog/Mist", "Snow", "Thunderstorm")
  
  combined_weather_summary$weather_category <- factor(
    combined_weather_summary$weather_category, 
    levels = weather_order[weather_order %in% combined_weather_summary$weather_category]
  )
  
  ggplot(combined_weather_summary, aes(x = weather_category, y = vs_baseline, fill = station)) +
    geom_col(position = "dodge", alpha = 0.8) +
    geom_hline(yintercept = 0, linetype = "dashed", color = "gray50") +
    labs(title = "Weather Conditions Impact on Listening",
         subtitle = "Percentage change from station baseline by weather type",
         x = "Weather Condition", 
         y = "% Change from Baseline",
         fill = "Station") +
    theme_minimal() +
    theme(axis.text.x = element_text(angle = 45, hjust = 1),
          legend.position = "bottom") +
    scale_y_continuous(labels = function(x) paste0(x, "%"))
}
```

```{r combined-temperature-impact-chart, eval=(ANALYSE_WEATHER == "Y") && exists("combined_temp_analysis") && nrow(combined_temp_analysis) > 0, fig.width=10, fig.height=6}
if (exists("combined_temp_analysis") && nrow(combined_temp_analysis) > 0) {
  
  # Order temperature categories logically
  temp_order <- c("Very Cold (< 5°C)", "Cold (5-10°C)", "Cool (10-15°C)", 
                  "Mild (15-20°C)", "Warm (20-25°C)", "Hot (25-30°C)", "Very Hot (> 30°C)")
  
  combined_temp_analysis$temp_category <- factor(
    combined_temp_analysis$temp_category,
    levels = temp_order[temp_order %in% combined_temp_analysis$temp_category]
  )
  
  ggplot(combined_temp_analysis, aes(x = temp_category, y = total_listeners, fill = station)) +
    geom_boxplot(alpha = 0.7) +
    labs(title = "Temperature Impact on Listening Patterns",
         subtitle = "Distribution of listener counts by temperature range",
         x = "Temperature Range", 
         y = "Total Listeners",
         fill = "Station") +
    theme_minimal() +
    theme(axis.text.x = element_text(angle = 45, hjust = 1),
          legend.position = "bottom") +
    scale_y_continuous(labels = scales::comma)
}
```

```{r combined-rain-impact-chart, eval=(ANALYSE_WEATHER == "Y") && exists("combined_rain_analysis") && nrow(combined_rain_analysis) > 0, fig.width=10, fig.height=6}
if (exists("combined_rain_analysis") && nrow(combined_rain_analysis) > 0) {
  
  # Order rain categories logically
  rain_order <- c("No Rain", "Light Rain (< 1mm)", "Moderate Rain (1-5mm)", 
                  "Heavy Rain (5-10mm)", "Very Heavy Rain (> 10mm)")
  
  combined_rain_analysis$rain_category <- factor(
    combined_rain_analysis$rain_category,
    levels = rain_order[rain_order %in% combined_rain_analysis$rain_category]
  )
  
  # Calculate baseline for each station and day type
  combined_rain_with_baseline <- combined_rain_analysis %>%
    group_by(station, day_type) %>%
    mutate(
      baseline = mean(avg_listeners),
      pct_change = ((avg_listeners - baseline) / baseline) * 100
    ) %>%
    ungroup()
  
  ggplot(combined_rain_with_baseline, aes(x = rain_category, y = pct_change, fill = station)) +
    geom_col(position = "dodge", alpha = 0.8) +
    geom_hline(yintercept = 0, linetype = "dashed", color = "gray50") +
    facet_wrap(~day_type, scales = "free_y") +
    labs(title = "Rain Impact on Listening by Day Type",
         subtitle = "Percentage change from baseline by rainfall intensity",
         x = "Rainfall Category", 
         y = "% Change from Baseline",
         fill = "Station") +
    theme_minimal() +
    theme(axis.text.x = element_text(angle = 45, hjust = 1),
          legend.position = "bottom",
          strip.text = element_text(face = "bold")) +
    scale_y_continuous(labels = function(x) paste0(x, "%"))
}
```

```{r combined-daylight-impact-chart, eval=(ANALYSE_WEATHER == "Y") && exists("combined_daylight_analysis") && nrow(combined_daylight_analysis) > 0, fig.width=10, fig.height=6}
if (exists("combined_daylight_analysis") && nrow(combined_daylight_analysis) > 0) {
  
  # Create hourly averages by light condition and station
  daylight_hourly_summary <- combined_daylight_analysis %>%
    group_by(station, hour, light_condition, day_type) %>%
    summarise(avg_listeners = mean(avg_listeners, na.rm = TRUE), .groups = "drop")
  
  ggplot(daylight_hourly_summary, aes(x = hour, y = avg_listeners, color = light_condition)) +
    geom_line(linewidth = 1.2) +
    geom_point(size = 2) +
    facet_grid(day_type ~ station, scales = "free_y") +
    labs(title = "Daylight vs Darkness Listening Patterns",
         subtitle = "Hourly listening patterns by light conditions across stations",
         x = "Hour of Day", 
         y = "Average Listeners",
         color = "Light Condition") +
    theme_minimal() +
    theme(legend.position = "bottom",
          strip.text = element_text(face = "bold")) +
    scale_x_continuous(breaks = seq(0, 23, 4)) +
    scale_y_continuous(labels = scales::comma) +
    scale_color_manual(values = c("Daylight" = "orange", "Darkness" = "navy"))
}
```

```{r combined-weather-summary-stats, eval=(ANALYSE_WEATHER == "Y") && exists("combined_weather_summary") && nrow(combined_weather_summary) > 0, results="asis"}
if (exists("combined_weather_summary") && nrow(combined_weather_summary) > 0) {
  cat("\\\\newpage\\n\\n")
  cat("## Weather Impact Summary\n\n")
  
  # Find best and worst weather conditions for each station
  weather_extremes <- combined_weather_summary %>%
    group_by(station) %>%
    arrange(vs_baseline) %>%
    summarise(
      worst_weather = as.character(first(weather_category)),  # Convert to character
      worst_impact = first(vs_baseline),
      best_weather = as.character(last(weather_category)),    # Convert to character
      best_impact = last(vs_baseline),
      .groups = "drop"
    )
  
  for (i in 1:nrow(weather_extremes)) {
    station_name <- weather_extremes$station[i]
    cat(glue("**", station_name, ":**\\n\\n\\n"))
    cat(glue("- Best weather for listening: ", weather_extremes$best_weather[i], 
        " (+", round(weather_extremes$best_impact[i], 1), "% vs baseline)\\n\\n\\n"))
    cat(glue("- Worst weather for listening: ", weather_extremes$worst_weather[i], 
        " (", round(weather_extremes$worst_impact[i], 1), "% vs baseline)\\n\\n\\n"))
  }
  
  # Overall observations
  total_conditions <- length(unique(as.character(combined_weather_summary$weather_category)))  # Convert here too
  total_observations <- sum(combined_weather_summary$observations)
  
  cat("**Analysis Coverage:**\n\n")
  cat(glue("- Weather conditions analyzed: ", total_conditions, "\\n\\n\\n"))
  cat(glue("- Total observations: ", scales::comma(total_observations), "\\n\\n\\n"))
  cat(glue("- Stations compared: ", length(unique(combined_weather_summary$station)), "\\n\\n\\n"))
  
  cat("*Remember: These patterns may reflect correlation rather than causation. Weather conditions often coincide with other factors (holidays, events, seasonal programming) that may also influence listening habits.*\n\n")
  cat("*Correlation does not imply causation!\n\n")
}
```

```{r station-comparison-chart, eval=(ANALYSE_SECOND_STATION == "Y" | ANALYSE_COMPARISON_STATION == "Y"), fig.width=8, fig.height=3, results="asis"}
cat("\\\\newpage\\n\\n")
cat("# Cross-Station Comparisons\\n\\n")
cat("## Overall Listener Numbers\\n\\n")
# Create combined station performance data
station_comparison_data <- data.frame(
  station = MAIN_STATION_NAME,
  avg_listeners = if(exists("main_summary_stats")) main_summary_stats$avg_daily_listeners else NA,
  peak_listeners = if(exists("main_summary_stats")) main_summary_stats$peak_listeners else NA
)

if (ANALYSE_SECOND_STATION == "Y" && exists("second_summary_stats")) {
  station_comparison_data <- rbind(station_comparison_data,
    data.frame(
      station = SECOND_STATION_NAME,
      avg_listeners = second_summary_stats$avg_daily_listeners,
      peak_listeners = second_summary_stats$peak_listeners
    ))
}

if (ANALYSE_COMPARISON_STATION == "Y" && exists("comparison_summary_stats")) {
  station_comparison_data <- rbind(station_comparison_data,
    data.frame(
      station = COMPARISON_STATION_NAME,
      avg_listeners = comparison_summary_stats$avg_daily_listeners,
      peak_listeners = comparison_summary_stats$peak_listeners
    ))
}

if (nrow(station_comparison_data) > 1) {
  ggplot(station_comparison_data, aes(x = reorder(station, avg_listeners), y = avg_listeners)) +
    geom_col(aes(fill = station), alpha = 0.8) +
    coord_flip() +
    labs(title = "Cross-Station Average Daily Listeners Comparison",
         x = "", y = "Average Daily Listeners") +
    theme_minimal() +
    theme(legend.position = "none") +
    scale_y_continuous(labels = scales::comma)
}
```

```{r station-hourly-comparison-chart, eval=(ANALYSE_SECOND_STATION == "Y" | ANALYSE_COMPARISON_STATION == "Y"), fig.width=8, fig.height=6, results="asis"}
cat("## Hourly Performance Comparison\\n\\n")
if (exists("hourly_changes_long") && nrow(hourly_changes_long) > 0) {
  ggplot(hourly_changes_long, aes(x = hour, y = pct_change, color = station)) +
    geom_line(linewidth = 1.2) +
    geom_point(size = 2) +
    geom_hline(yintercept = 0, linetype = "dashed", color = "gray50") +
    labs(title = "Station Comparison Analysis",
         subtitle = "Hourly Performance vs Daily Average",
         x = "Time", y = "% Change from Daily Average",
         color = "Station") +
    theme_minimal() +
    scale_x_continuous(breaks = seq(0, 23, 4)) +
    theme(legend.position = "bottom")
} else {
  plot.new()
  text(0.5, 0.5, "Station comparison data not available", cex = 1.5)
}
```

```{r cross-station-genre-chart, eval=(ANALYSE_SECOND_STATION == "Y" | ANALYSE_COMPARISON_STATION == "Y"), fig.width=10, fig.height=6, results="asis"}
cat("\\\\newpage\\n\\n")
cat("## Cross-Station Genre Analysis\\n\\n")
cat("### Comparative analysis of musical genre preferences across stations.\\n\\n")

if (exists("cross_station_genre_focused") && nrow(cross_station_genre_focused) > 0) {
  ggplot(cross_station_genre_focused, aes(x = reorder(genre, pct), y = pct, fill = station)) +
    geom_col(position = "dodge", alpha = 0.8) +
    coord_flip() +
    labs(title = "Cross-Station Genre Comparison",
         subtitle = "Percentage of total tracks played by genre",
         x = "Genre", y = "% of Station Output", fill = "Station") +
    theme_minimal() +
    theme(legend.position = "bottom",
          axis.text.y = element_text(size = 9)) +
    scale_fill_brewer(type = "qual", palette = "Set2") +
    guides(fill = guide_legend(nrow = 1))
}
```

```{r genre-difference-analysis, eval=(ANALYSE_SECOND_STATION == "Y" | ANALYSE_COMPARISON_STATION == "Y"), results="asis"}
if (exists("cross_station_genre_focused") && nrow(cross_station_genre_focused) > 0) {

  # Create a "difference" analysis showing which station focuses most on each genre
  genre_leaders <- cross_station_genre_focused %>%
    group_by(genre) %>%
    arrange(desc(pct)) %>%
    slice(1) %>%
    ungroup() %>%
    arrange(desc(pct)) %>%
    head(10)
  
  cat("### Genre Leadership Analysis\n\n")
  cat("Which station plays the most of each genre:\n\n")
  
  for(i in 1:nrow(genre_leaders)) {
    genre_name <- genre_leaders$genre[i]
    station_name <- genre_leaders$station[i]
    percentage <- round(genre_leaders$pct[i], 1)
    
    cat(glue("- **", genre_name, "**: ", station_name, " (", percentage, "% of their output)\\n\\n\\n"))
  }
  cat("\n")
}
```

```{r genre-diversity-comparison, eval=(ANALYSE_SECOND_STATION == "Y" | ANALYSE_COMPARISON_STATION == "Y"), fig.width=8, fig.height=5, results="asis"}
if (exists("cross_station_genre_data") && nrow(cross_station_genre_data) > 0) {

cat("\\\\newpage\\n")
cat("## Genre Diversity Comparison\\n")

  # Genre diversity comparison - how many genres does each station play?
  genre_diversity_comparison <- cross_station_genre_data %>%
    group_by(station) %>%
    summarise(
      total_genres = n(),
      avg_genre_pct = mean(pct, na.rm = TRUE),
      top_genre_pct = max(pct, na.rm = TRUE),
      diversity_score = 1 - (sum((pct/100)^2)),  # Herfindahl diversity index
      .groups = "drop"
    ) %>%
    mutate(diversity_score = round(diversity_score, 3))
  
  ggplot(genre_diversity_comparison, aes(x = reorder(station, diversity_score), y = diversity_score)) +
    geom_col(aes(fill = station), alpha = 0.8, show.legend = FALSE) +
    coord_flip() +
    labs(title = "Genre Diversity Comparison",
         subtitle = "Higher scores = more diverse genre selection",
         x = "Station", y = "Diversity Score (0-1)") +
    theme_minimal() +
    scale_fill_brewer(type = "qual", palette = "Set2")
}
```

```{r genre-focus-table, eval=(ANALYSE_SECOND_STATION == "Y" | ANALYSE_COMPARISON_STATION == "Y"), results="asis"}
if (exists("genre_diversity_comparison") && nrow(genre_diversity_comparison) > 0) {
  
  diversity_table <- genre_diversity_comparison %>%
    mutate(
      diversity_score = round(diversity_score, 3),
      avg_genre_pct = round(avg_genre_pct, 1),
      top_genre_pct = round(top_genre_pct, 1)
    ) %>%
    arrange(desc(diversity_score))
  
  print(kable(diversity_table,
        caption = "Station Genre Strategy Comparison",
        col.names = c("Station", "Genres Played", "Avg Genre %", "Top Genre %", "Diversity Score")))
        
  cat("\\n**Diversity Score**: Measures how evenly distributed genres are (1.0 = perfectly diverse, 0.0 = only one genre)\\n")
  cat("**Strategy Insights**:\\n")
  cat("- Higher diversity = broader appeal, more variety\\n")  
  cat("- Lower diversity = focused format, clear identity\\n")
}
```

\\newpage
# Monthly Listener Trends
## Monthly Performance Trends

```{r monthly-trends-chart, eval=monthly_trends_available && nrow(monthly_trends_clean) > 1, fig.cap="Monthly performance trends across all analyzed stations", fig.width=8, fig.height=5}

if (monthly_trends_available && nrow(monthly_trends_clean) > 1) {
  
  # Create combined monthly chart data for all enabled stations
  monthly_chart_data <- data.frame()
  
  # Always include main station
  main_monthly_data <- monthly_trends_clean %>%
    select(month, avg_listeners, point_size, point_alpha) %>%
    mutate(station = MAIN_STATION_NAME)
  
  monthly_chart_data <- rbind(monthly_chart_data, main_monthly_data)
  
  # Add second station if enabled and data exists
  if (ANALYSE_SECOND_STATION == "Y" && "avg_second" %in% names(monthly_trends_clean)) {
    second_monthly_data <- monthly_trends_clean %>%
      filter(!is.na(avg_second)) %>%
      select(month, point_size, point_alpha) %>%
      mutate(
        avg_listeners = monthly_trends_clean$avg_second[!is.na(monthly_trends_clean$avg_second)],
        station = SECOND_STATION_NAME
      )
    
    monthly_chart_data <- rbind(monthly_chart_data, second_monthly_data)
  }
  
  # Add comparison station if enabled and data exists
  if (ANALYSE_COMPARISON_STATION == "Y" && "avg_comparison" %in% names(monthly_trends_clean)) {
    comparison_monthly_data <- monthly_trends_clean %>%
      filter(!is.na(avg_comparison)) %>%
      select(month, point_size, point_alpha) %>%
      mutate(
        avg_listeners = monthly_trends_clean$avg_comparison[!is.na(monthly_trends_clean$avg_comparison)],
        station = COMPARISON_STATION_NAME
      )
    
    monthly_chart_data <- rbind(monthly_chart_data, comparison_monthly_data)
  }
  
  # Convert month to date for proper ordering
  monthly_chart_data <- monthly_chart_data %>%
    mutate(month_date = as.Date(paste0(month, "-01")))
  
  # Create the chart
  stations_analyzed <- unique(monthly_chart_data$station)
  station_count <- length(stations_analyzed)
  
  # Create color palette
  station_colors <- c()
  station_colors[MAIN_STATION_NAME] <- "blue"
  if (ANALYSE_SECOND_STATION == "Y") station_colors[SECOND_STATION_NAME] <- "green"
  if (ANALYSE_COMPARISON_STATION == "Y") station_colors[COMPARISON_STATION_NAME] <- "red"
  
  p_monthly <- ggplot(monthly_chart_data, aes(x = month_date, y = avg_listeners, color = station)) +
    geom_line(linewidth = 1.2, aes(group = station)) +
    geom_point(aes(size = point_size, alpha = point_alpha)) +
    labs(
      title = "Monthly Performance Trends",
      subtitle = if(exists("trend_message") && trend_message != "") trend_message else 
                 paste("Trends across", station_count, "stations"),
      x = "Month", 
      y = "Average Listeners", 
      color = "Station"
    ) +
    theme_minimal() +
    theme(
      axis.text.x = element_text(angle = 45, hjust = 1, size = 8),
      legend.position = "bottom", 
      legend.title = element_text(size = 9)
    ) +
    scale_color_manual(values = station_colors) +
    scale_size_identity() + 
    scale_alpha_identity() +
    scale_x_date(date_labels = "%b %Y", date_breaks = "1 month") +
    scale_y_continuous(labels = scales::comma) +
    guides(size = "none", alpha = "none")
  
  print(p_monthly)
  
} else {
  # Show message instead of blank space
  plot.new()
  if (exists("trend_message") && trend_message != "") {
    text(0.5, 0.5, trend_message, cex = 1.2, adj = 0.5)
  } else {
    text(0.5, 0.5, "Monthly trends require data from multiple months", cex = 1.2, adj = 0.5)
  }
}
```

```{r monthly-trends-summary, eval=monthly_trends_available && exists("monthly_trends_summary"), results="asis"}
if (monthly_trends_available && exists("monthly_trends_summary") && monthly_trends_summary$months_analyzed > 0) {
  
  cat("## Monthly Performance Summary\n\n")
  
  cat(glue("- **Months Analyzed**: ", monthly_trends_summary$months_analyzed, "\\n\\n\\n"))
  cat(glue("- **Date Range**: ", monthly_trends_summary$date_range, "\\n\\n\\n"))
  cat(glue("- **", MAIN_STATION_NAME, " Best Month**: ", monthly_trends_summary$main_best_month, 
      " (", format(round(monthly_trends_summary$main_best_month_listeners), big.mark = ","), " listeners)\\n\\n\\n"))
  cat(glue("- **", MAIN_STATION_NAME, " Worst Month**: ", monthly_trends_summary$main_worst_month, 
      " (", format(round(monthly_trends_summary$main_worst_month_listeners), big.mark = ","), " listeners)\\n\\n\\n"))
  
  if ("main_avg_growth_rate" %in% names(monthly_trends_summary)) {
    cat(glue("- **Average Monthly Growth**: ", monthly_trends_summary$main_avg_growth_rate, "%\\n\\n\\n"))
  }
  
  # Add second station stats if available
  if (ANALYSE_SECOND_STATION == "Y" && exists("monthly_trends_clean") && "avg_second" %in% names(monthly_trends_clean)) {
    second_best_month <- monthly_trends_clean$month[which.max(monthly_trends_clean$avg_second)]
    second_best_listeners <- max(monthly_trends_clean$avg_second, na.rm = TRUE)
    second_worst_month <- monthly_trends_clean$month[which.min(monthly_trends_clean$avg_second)]
    second_worst_listeners <- min(monthly_trends_clean$avg_second, na.rm = TRUE)
    
    cat(glue("- **", SECOND_STATION_NAME, " Best Month**: ", second_best_month, 
        " (", format(round(second_best_listeners), big.mark = ","), " listeners)\\n\\n\\n"))
    cat(glue("- **", SECOND_STATION_NAME, " Worst Month**: ", second_worst_month, 
        " (", format(round(second_worst_listeners), big.mark = ","), " listeners)\\n\\n\\n"))
  }
  
  # Add comparison station stats if available
  if (ANALYSE_COMPARISON_STATION == "Y" && exists("monthly_trends_clean") && "avg_comparison" %in% names(monthly_trends_clean)) {
    comp_best_month <- monthly_trends_clean$month[which.max(monthly_trends_clean$avg_comparison)]
    comp_best_listeners <- max(monthly_trends_clean$avg_comparison, na.rm = TRUE)
    comp_worst_month <- monthly_trends_clean$month[which.min(monthly_trends_clean$avg_comparison)]
    comp_worst_listeners <- min(monthly_trends_clean$avg_comparison, na.rm = TRUE)
    
    cat(glue("- **", COMPARISON_STATION_NAME, " Best Month**: ", comp_best_month, 
        " (", format(round(comp_best_listeners), big.mark = ","), " listeners)\\n\\n\\n"))
    cat(glue("- **", COMPARISON_STATION_NAME, " Worst Month**: ", comp_worst_month, 
        " (", format(round(comp_worst_listeners), big.mark = ","), " listeners)\\n"))
  }
  
  cat("\n")
}
```

\\newpage
# Statistical Appendix

## Data Quality and Coverage

```{r data-quality, results="asis"}
cat(glue("- **Total Observations**: ", format(nrow(data), big.mark = ","), "\\n\\n\\n"))
cat(glue("- **Date Range**: ", format(min(data$date), "%d %B %Y"), " to ", format(max(data$date), "%d %B %Y"), "\\n\\n\\n"))
cat(glue("- **Days Analyzed**: ", length(unique(data$date)), "\\n\\n\\n"))
cat(glue("- **Missing Data Points**: ", format(sum(is.na(data$main_total_listeners)), big.mark = ","), 
    " (", round(mean(is.na(data$main_total_listeners)) * 100, 1), "%)\\n\\n\\n"))

if (ANALYSE_SECOND_STATION == "Y") {
  cat(glue("- **", paste0(SECOND_STATION_NAME), " Data Points**: ", 
      format(sum(!is.na(data$second_total_listeners)), big.mark = ","), "\\n\\n\\n"))
}

if (ANALYSE_COMPARISON_STATION == "Y") {
  cat(glue("- **", paste0(COMPARISON_STATION_NAME), " Data Points**: ", 
      format(sum(!is.na(data$comparison_total_listeners)), big.mark = ","), "\\n\\n\\n"))
}

# Show and presenter coverage
unique_shows <- length(unique(data$main_showname[!is.na(data$main_showname) & data$main_showname != ""]))
unique_presenters <- length(unique(data$main_presenter[!is.na(data$main_presenter) & data$main_presenter != ""]))

cat(glue("- **Unique Shows Identified**: ", unique_shows, "\\n\\n\\n"))
cat(glue("- **Unique Presenters Identified**: ", unique_presenters, "\\n\\n\\n"))

# Music data coverage
if ("main_artist" %in% names(data)) {
  music_coverage <- sum(!is.na(data$main_artist) & data$main_artist != "" & data$main_artist != "Unknown")
  cat(glue("- **Music Data Coverage**: ", format(music_coverage, big.mark = ","), 
      " observations (", round((music_coverage / nrow(data)) * 100, 1), "%)\\n\\n\\n"))
  
  unique_artists <- length(unique(data$main_artist[!is.na(data$main_artist) & data$main_artist != "" & data$main_artist != "Unknown"]))
  unique_tracks <- length(unique(paste(data$main_artist, data$main_song)[!is.na(data$main_artist) & data$main_artist != "" & data$main_artist != "Unknown"]))
  
  cat(glue("- **Unique Artists Played**: ", format(unique_artists, big.mark = ","), "\\n\\n\\n"))
  cat(glue("- **Unique Tracks Played**: ", format(unique_tracks, big.mark = ","), "\\n\\n\\n"))
}
```

## Methodology Notes

```{r methodology-notes, results="asis"}
cat("- **Performance Measurement**: Show performance is calculated as the percentage difference from the hourly baseline, allowing fair comparison between different time slots.\\n\\n")

cat("- **Retention Analysis**: Audience retention measures how well shows maintain their audience throughout episodes, compared to the expected retention for that time slot.\\n\\n")

cat("- **Impact Analysis**: Music impact is measured by comparing listener numbers immediately before, during, and after track playback, controlling for time-of-day effects.\\n\\n")

cat("- **Consistency Scoring**: Consistency is measured using coefficient of variation, where lower scores indicate more predictable performance.\\n\\n")

cat("- **Statistical Significance**: Correlations and comparisons are only reported when sufficient data points are available (typically n>=10 for basic analysis, n>=30 for advanced statistics).\\n\\n")

if (exists("confidence_intervals") && confidence_intervals) {
  cat("- **Confidence Intervals**: Where possible, 95% confidence intervals are provided for key metrics.\\n\\n")
}
```

## Limitations and Considerations

```{r limitations, results="asis"}
cat("- **Online Only**: This analysis covers online streaming data only and does not include traditional broadcast metrics or alternative platforms.\\n\\n")

cat("- **Correlation vs Causation**: All relationships identified are correlational; causation cannot be inferred from this data alone.\\n\\n")

cat("- **External Factors**: The analysis cannot account for all external factors that may influence listening (marketing campaigns, news events, technical issues, etc.).\\n\\n")

cat("- **Sample Size Variations**: Some analyses may have limited sample sizes for certain shows or time periods, affecting reliability of conclusions.\\n\\n")

cat("- **Seasonal Effects**: Results may be influenced by seasonal patterns not fully captured in the analysis period.\\n\\n")

cat("- **Technical Limitations**: Data collection is subject to server availability, network conditions, and streaming platform reliability.\\n\\n")
```

\\newpage
# Glossary

**% vs Hour Avg (Legacy)**: How a show performs compared to the average for that specific hour across all days. A positive percentage means the show attracts more listeners than average for that time slot.

**Airtime Hours**: Total hours of programming analyzed for each show.

**Artist Impact**: The immediate effect on listener numbers when a specific artist\'s music is played, measured as percentage change from baseline.

**Average Listeners**: Mean number of concurrent listeners during a show or time period.

**Consistency Score**: A measure of how predictable a show\'s performance is, with lower scores indicating more consistent performance patterns.

**Day Type**: Classification of days as either "Weekday" (Monday-Friday) or "Weekend" (Saturday-Sunday).

**DJ/Show Performance:** Uses Impact Score to evaluate how presenters and shows perform relative to expectations for their assigned time slots. This provides fair comparison between breakfast show hosts and late-night presenters by accounting for natural audience size differences throughout the day.

**Genre Bias**: How much more or less a DJ plays certain genres compared to the station\'s overall music mix. For example, +15% Rock bias means the DJ plays 15% more rock music than the station average.

**Genre Diversity Ratio**: A measure of how varied a DJ\'s musical choices are across different genres.

**Impact Score:** A statistical measure (z-score) that shows how much a track, artist, genre, DJ, or show performs compared to what\'s typically expected for that specific time slot and day type. Replaces percentage-based "% vs Hour Avg" measurements to provide more accurate analysis.

**Live vs Pre-recorded**: Analysis comparing audience performance between live broadcasts and pre-recorded content.

**Monthly Growth Rate**: The average percentage change in listeners from month to month.

**Peak Hours**: Generally refers to the highest listening periods, typically 10am-6pm on weekends and morning/evening drive times on weekdays.

**Performance vs Time Slot**: Shows how well a program performs relative to the baseline expectation for its scheduled time.

**Retention Performance**: How well a show maintains its audience throughout an episode, compared to what would be expected for that time slot.

**Retention Variability**: A measure of how consistent a show\'s retention performance is from episode to episode.

**Sessions**: Individual 5-minute data collection periods. 12 sessions = 1 hour of programming.

**Similarity Score**: A percentage showing how closely a DJ\'s music choices match the overall station\'s genre distribution.

**Time Slot Analysis**: Comparing performance within similar time periods to ensure fair comparison between different shows.

**Track Impact**: The immediate effect on listener numbers when a specific song is played.

**Weather Appeal**: Categorization of weather conditions to test theories about how weather affects listening habits.

**Z-Score (Impact Score):** A statistical measure that shows how much a track, artist, genre, DJ, or show performs compared to what\'s typically expected for that specific time slot and day type. 

Z-scores solve a key problem in radio analytics: a song played at 8am (when listening naturally increases) will always look better than the same song played at 10pm (when listening naturally decreases) if you just look at raw percentages.

**How to interpret Z-scores:**

- **+2.0**: Performs 2 standard deviations better than expected for that time slot (excellent) \n
- **+1.0**: Performs 1 standard deviation better than expected (very good) \n
- **0.0**: Performs exactly as expected for that time slot (neutral) \n
- **-1.0**: Performs 1 standard deviation worse than expected (concerning) \n
- **-2.0**: Performs 2 standard deviations worse than expected (poor) \n

**Why Z-scores matter:** They reveal genuine musical and presenter impact by filtering out time-of-day effects. A track with a +1.5 z-score genuinely engages the audience regardless of whether it\'s played during morning drive time or late evening.

**Example:** If a song gets +20% listeners at 8am vs -5% listeners at 10pm using traditional percentage analysis, both might actually have the same +1.2 z-score, showing the song consistently performs well for its time slot.

## Music and Content Analysis

**DJ Similarity Score**: A percentage showing how closely a DJ\'s music choices match the overall station\'s genre distribution. Higher scores mean the DJ\'s choices are more typical of the station\'s general playlist.

**Genre Impact:** Shows how different musical genres affect listener numbers using Impact Score methodology. Positive scores indicate genres that consistently attract listeners regardless of when they\'re played, while negative scores indicate genres that tend to lose listeners. This analysis helps identify which musical styles work best for your audience.

**Total Unique Artists/Tracks**: The number of different musical artists and individual songs played during the analysis period.

**Track/Artist Impact:** Measures how individual songs or artists affect listening figures using Impact Score analysis. This reveals which music genuinely engages your audience versus tracks that only appear successful due to being played during peak listening hours.

## Visual Chart Explanations

**Heatmap**: A colour-coded chart where different colours represent different values. Typically:

- **Darker blue**: Higher listener numbers or better performance \n
- **Red/Orange**: Lower listener numbers or below-average performance \n
- **White/Light colours**: Average or neutral performance \n

**Bar Charts (Horizontal)**:

- **Blue bars extending right**: Above-average performance \n
- **Red bars extending left**: Below-average performance \n
- **Length of bar**: How much above or below average \n

**Scatter Plot (Performance vs Variability)**:

- **Top right quadrant**: Good performance AND consistent (ideal) \n
- **Bottom right quadrant**: Good performance but unpredictable \n
- **Top left quadrant**: Poor performance but at least consistent \n
- **Bottom left quadrant**: Poor performance AND unpredictable (needs attention) \n

## Data Collection Terms

**`r DATA_COLLECTION`-minute Observations**: The system automatically checks listener numbers every `r DATA_COLLECTION` minutes, 24 hours a day. This creates a detailed picture of how audiences change throughout the day.

**Shoutcast Server**: The technology that delivers the radio stream to listeners\' computers and devices. It provides real-time data about how many people are listening.

**AAC vs MP3 Streams**: Different audio formats for the radio stream. Most listeners use one or the other, but both are counted together for total audience figures.

```{r comparison-glossary, results="asis", eval=ANALYSE_COMPARISON_STATION == "Y"}
cat("\\n## Comparison and Context\\n\\n")
cat(glue("**", paste0(COMPARISON_STATION_NAME), "**: A comparison station used to provide context for ", paste0(MAIN_STATION_NAME), "\'s performance and industry benchmarking.\\n\\n"))
```

```{r second-station-glossary, results="asis", eval=ANALYSE_SECOND_STATION == "Y"}
cat(glue("**", paste0(SECOND_STATION_NAME), "**: ", paste0(MAIN_STATION_NAME), "\'s secondary service.\\n\\n"))
```

\\newpage
# Executive Summary Tables

## `r MAIN_STATION_NAME` Top Performing Shows by Category

```{r exec-summary-weekday-shows-zscore, results="asis"}
if (exists("main_top_shows_by_category_zscore") && nrow(main_top_shows_by_category_zscore) > 0) {
  
  weekday_shows <- main_top_shows_by_category_zscore %>%
    filter(day_type == "Weekday")
  
  if (nrow(weekday_shows) > 0) {
    cat("### Top Weekday Shows (Impact Score Based)\n\n")
    print(kable(weekday_shows %>% select(-day_type),
          caption = paste("Top Weekday Shows -", paste0(MAIN_STATION_NAME)),
          col.names = c("Show", "Impact Score", "Avg Listeners", "Airtime Hours")))
    cat("\n\n")
  }
}

```{r exec-summary-weekend-shows-zscore, results="asis"}
if (exists("main_top_shows_by_category_zscore") && nrow(main_top_shows_by_category_zscore) > 0) {
  
  weekend_shows <- main_top_shows_by_category_zscore %>%
    filter(day_type == "Weekend")
  
  if (nrow(weekend_shows) > 0) {
    cat("### Top Weekend Shows (Impact Score Based)\n\n")
    print(kable(weekend_shows %>% select(-day_type),
          caption = paste("Top Weekend Shows -", paste0(MAIN_STATION_NAME)),
          col.names = c("Show", "Impact Score", "Avg Listeners", "Airtime Hours")))
    cat("\n\n")
  }
}


```{r summary-table-second-weekday, eval=ANALYSE_SECOND_STATION == "Y", results="asis"}
cat(glue("## ", paste0(SECOND_STATION_NAME), " Top Performing Shows by Category\\n\\n"))
# Best weekday shows - Second Station
if (exists("second_top_shows_by_category_zscore") && nrow(second_top_shows_by_category_zscore) > 0) {
  
  second_weekday_shows <- second_top_shows_by_category_zscore %>%
    filter(day_type == "Weekday")
  
  if (nrow(second_weekday_shows) > 0) {
    cat("### Top Weekday Shows (Impact Score Based)\n\n")
    print(kable(second_weekday_shows %>% select(-day_type),
          caption = paste("Top Weekday Shows -", paste0(SECOND_STATION_NAME)),
          col.names = c("Show", "Impact Score", "Avg Listeners", "Airtime Hours")))
    cat("\n\n")
  }
}
```

```{r summary-table-second-weekend, eval=ANALYSE_SECOND_STATION == "Y", results="asis"}
if (exists("second_top_shows_by_category_zscore") && nrow(second_top_shows_by_category_zscore) > 0) {
  
  second_weekend_shows <- second_top_shows_by_category_zscore %>%
    filter(day_type == "Weekend")
  
  if (nrow(second_weekend_shows) > 0) {
    cat("### Top Weekend Shows (Impact Score Based)\n\n")
    print(kable(second_weekend_shows %>% select(-day_type),
          caption = paste("Top Weekend Shows -", paste0(SECOND_STATION_NAME)),
          col.names = c("Show", "Impact Score", "Avg Listeners", "Airtime Hours")))
    cat("\n\n")
  }
}
```

## `r MAIN_FEATURED_SHOW` Show Performance Summary

```{r featured-show-table}
if (exists("main_featured_dj_performance") && nrow(main_featured_dj_performance) > 0) {
  featured_summary <- main_featured_dj_performance %>%
    mutate(
      main_avg_listeners = round(main_avg_listeners, 0),
      main_pct_vs_featured_avg = round(main_pct_vs_featured_avg, 1),
      main_shows_presented = round(main_sessions / HOUR_NORMALISATION, 0)
    ) %>%
    select(main_presenter, main_avg_listeners, main_shows_presented, main_pct_vs_featured_avg)
  
  kable(featured_summary,
        caption = paste(paste0(MAIN_FEATURED_SHOW), "Presenter Performance Summary"),
        col.names = c("Presenter", "Avg Listeners", "Shows", paste("% vs", paste0(MAIN_FEATURED_SHOW), "Avg")))
} else {
  cat(paste0(MAIN_FEATURED_SHOW), "performance data not available.\\n")
}
```

```{r main_live-recorded-summary, eval=MAIN_LIVE_RECORDED_EXISTS, results="asis"}
cat(glue("## Live vs Pre-recorded Summary for ", paste0(MAIN_STATION_NAME)))
if (exists("main_live_recorded_summary") && nrow(main_live_recorded_summary) > 0) {
  live_recorded_table <- main_live_recorded_summary %>%
    mutate(
      main_avg_performance = round(main_avg_performance, 1),
      main_avg_listeners = round(main_avg_listeners, 0)
    ) %>%
    select(main_live_recorded, day_type, main_avg_performance, main_airtime_hours, main_avg_listeners)
  
  kable(live_recorded_table,
        caption = paste(paste0(MAIN_STATION_NAME), "Live vs Pre-recorded Performance Summary"),
        col.names = c("Show Type", "Day Type", "% vs Avg", "Airtime Hours", "Avg Listeners"))
} else {
  cat("Live vs pre-recorded data not available for ", paste0(MAIN_STATION_NAME), ".\\n")
}
```

```{r second_live-recorded-summary, eval=SECOND_LIVE_RECORDED_EXISTS, results="asis"}
cat(glue("## Live vs Pre-recorded Summary for ", paste0(SECOND_STATION_NAME)))
if (exists("second_live_recorded_summary") && nrow(second_live_recorded_summary) > 0) {
  second_live_recorded_table <- second_live_recorded_summary %>%
    mutate(
      second_avg_performance = round(second_avg_performance, 1),
      second_avg_listeners = round(second_avg_listeners, 0)
    ) %>%
    select(second_live_recorded, day_type, second_avg_performance, second_airtime_hours, second_avg_listeners)
  
  kable(second_live_recorded_table,
        caption = paste(paste0(SECOND_STATION_NAME), "Live vs Pre-recorded Performance Summary"),
        col.names = c("Show Type", "Day Type", "% vs Avg", "Airtime Hours", "Avg Listeners"))
} else {
  cat("Live vs pre-recorded data not available for ", paste0(SECOND_STATION_NAME),".\\n")
}
```

## Most Impactful Artists on `r MAIN_STATION_NAME`

```{r main_exec-summary-best-artists-zscore, results="asis"}
if (exists("main_best_artists_zscore") && nrow(main_best_artists_zscore) > 0) {
  cat("### Best Performing Artists (Impact Score Based)\n\n")
  print(kable(main_best_artists_zscore,
        caption = paste("Best Artists -", paste0(MAIN_STATION_NAME)),
        col.names = c("Artist", "Impact Score", "Plays", "Avg Listeners")))
  cat("\n\n")
}
```

```{r main_exec-summary-worst-artists-zscore, results="asis"}
if (exists("main_worst_artists_zscore") && nrow(main_worst_artists_zscore) > 0) {
  cat("### Worst Performing Artists (Impact Score Based)\n\n")
  print(kable(main_worst_artists_zscore,
        caption = paste("Worst Artists -", paste0(MAIN_STATION_NAME)),
        col.names = c("Artist", "Impact Score", "Plays", "Avg Listeners")))
  cat("\n\n")
}
```

```{r second_exec-summary-best-artists-zscore, eval=(ANALYSE_SECOND_STATION=="Y"), results="asis"}
cat(glue("## Most Impactful Artists on ", paste0(SECOND_STATION_NAME), "\\n\\n"))
if (exists("second_best_artists_zscore") && nrow(second_best_artists_zscore) > 0) {
  cat("### Best Performing Artists (Impact Score Based)\\n\\n")
  print(kable(second_best_artists_zscore,
        caption = paste("Best Artists -", paste0(SECOND_STATION_NAME)),
        col.names = c("Artist", "Impact Score", "Plays", "Avg Listeners")))
  cat("\\n\\n")
}

```{r second_main_exec-summary-worst-artists-zscore, eval=(ANALYSE_SECOND_STATION=="Y"), results="asis"}
if (exists("second_worst_artists_zscore") && nrow(second_worst_artists_zscore) > 0) {
  cat("### Worst Performing Artists (Impact Score Based)\n\n")
  print(kable(second_worst_artists_zscore,
        caption = paste("Worst Artists -", paste0(SECOND_STATION_NAME)),
        col.names = c("Artist", "Impact Score", "Plays", "Avg Listeners")))
  cat("\n\n")
}
```

## Genre Performance Summary for `r MAIN_STATION_NAME`

```{r main_exec-summary-best-genres-zscore, results="asis"}
if (exists("main_best_genres_zscore") && nrow(main_best_genres_zscore) > 0) {
  cat("### Best Performing Genres (Impact Score Based)\\n\\n")
  print(kable(main_best_genres_zscore,
        caption = paste("Best Genres -", paste0(MAIN_STATION_NAME)),
        col.names = c("Genre", "Impact Score", "Plays", "Avg Listeners")))
  cat("\n\n")
}
```

```{r main_exec-summary-worst-genres-zscore, results="asis"}
if (exists("main_worst_genres_zscore") && nrow(main_worst_genres_zscore) > 0) {
  cat("### Worst Performing Genres (Impact Score Based)\\n\\n")
  print(kable(main_worst_genres_zscore,
        caption = paste("Worst Genres -", paste0(MAIN_STATION_NAME)),
        col.names = c("Genre", "Impact Score", "Plays", "Avg Listeners")))
  cat("\n\n")
}

```{r second_exec-summary-best-genres-zscore, eval=(ANALYSE_SECOND_STATION=="Y"), results="asis"}
cat(glue("## Genre Performance Summary for ", paste0(SECOND_STATION_NAME), "\\n\\n"))
if (exists("second_best_genres_zscore") && nrow(second_best_genres_zscore) > 0) {
  cat("### Best Performing Genres (Impact Score Based)\\n\\n")
  print(kable(second_best_genres_zscore,
        caption = paste("Best Genres -", paste0(SECOND_STATION_NAME)),
        col.names = c("Genre", "Impact Score", "Plays", "Avg Listeners")))
  cat("\n\n")
}
```

```{r second_exec-summary-worst-genres-zscore, eval=(ANALYSE_SECOND_STATION=="Y"), results="asis"}
if (exists("second_worst_genres_zscore") && nrow(second_worst_genres_zscore) > 0) {
  cat("### Worst Performing Genres (Impact Score Based)\\n\\n")
  print(kable(second_worst_genres_zscore,
        caption = paste("Worst Genres -", paste0(SECOND_STATION_NAME)),
        col.names = c("Genre", "Impact Score", "Plays", "Avg Listeners")))
  cat("\n\n")
}
```

\\newpage
## `r MAIN_STATION_NAME` Genre Classification Guide

```{r main-genre-artists-summary}
if (exists("main_genre_artist_summary") && nrow(main_genre_artist_summary) > 0) {
  # Create a readable version showing top genres and their artists
  main_genre_artists_table <- main_genre_artist_summary %>%
    head(50) %>%  # Show top 50 genres by total plays
    mutate(
      main_total_plays = as.character(main_total_plays)
    ) %>%
    select(main_genre, main_total_plays, main_top_artists)
  
  kable(main_genre_artists_table,
        caption = paste("Genre Classification Guide: Most Played Artists by Genre on", paste0(MAIN_STATION_NAME)),
        col.names = c("Genre", "Total Plays", "Top Artists (Play Count)"),
        longtable = TRUE) %>%
    kable_styling(latex_options = c("repeat_header")) %>%
    column_spec(3, width = "8cm")  # Make the artists column wider
} else {
  cat("Main station genre-artist data not available.\\n")
}
```

**NOTES**:

- Artists may appear in more than one genre since genre allocation is track-based \n
- Shows top 5 most-played artists per genre (minimum 2 plays required) \n
- Genres are ordered by total number of plays across all artists \n
- If you disagree with a genre allocation, please direct feedback to MusicBrainz/last.fm/Wikipedia rather than the report author \n


```{r second-genre-artists-summary, eval=ANALYSE_SECOND_STATION == "Y", results="asis"}
cat("\\\\newpage\\n\\n")
cat("## ", SECOND_STATION_NAME, " Genre Classification Guide\\n\\n")
if (exists("second_genre_artist_summary") && nrow(second_genre_artist_summary) > 0) {
  # Create a readable version for second station
  second_genre_artists_table <- second_genre_artist_summary %>%
    head(50) %>%  # Show top 50 genres by total plays
    mutate(
      second_total_plays = as.character(second_total_plays)
    ) %>%
    select(second_genre, second_total_plays, second_top_artists)
  
  print(kable(second_genre_artists_table,
        caption = paste("Genre Classification Guide: Most Played Artists by Genre on", paste0(SECOND_STATION_NAME)),
        col.names = c("Genre", "Total Plays", "Top Artists (Play Count)"),
        longtable = TRUE) %>%
    kable_styling(latex_options = c("repeat_header")) %>%
    column_spec(3, width = "8cm"))
  
  cat("**NOTES**:\n\n")

  cat("- Artists may appear in more than one genre since genre allocation is track-based\n\n")
  cat("- Shows top 5 most-played artists per genre (minimum 2 plays required)\n\n")
  cat("- Genres are ordered by total number of plays across all artists\n\n")
  cat("- If you disagree with a genre allocation, please direct feedback to MusicBrainz/last.fm/Wikipedia rather than the report author\n\n")

} else {
  cat("Second station genre-artist data not available.\\n")
}
```


---

*Report generated on `r Sys.Date()` using data from `r min(data$date)` to `r max(data$date)`*

*All analysis is based on online streaming data only and does not include traditional broadcast metrics.*

*Analysis conducted using R statistical software with data collected every `r DATA_COLLECTION` minutes via automated monitoring systems.*
'

# Write the R Markdown file
date_range_clean <- gsub("[^A-Za-z0-9]+", "_", date_range)
markdown_file <- paste0(gsub("[^A-Za-z0-9]+", "_", MAIN_STATION_NAME), "_listener_analysis_report.Rmd")
pdf_file <- paste0(gsub("[^A-Za-z0-9]+", "_", MAIN_STATION_NAME), "_Listener_Analysis_", date_range_clean, ".pdf")
writeLines(rmd_content, markdown_file)

# Generate the PDF report
if (require(rmarkdown, quietly = TRUE)) {
  cat("Generating PDF report...\n")
  tryCatch({
    rmarkdown::render(markdown_file, 
                      output_format = "pdf_document",
                      output_file = pdf_file)
    cat("PDF report generated successfully:", pdf_file, "\n")
  }, error = function(e) {
    cat("Error generating PDF:", e$message, "\n")
    cat("R Markdown file created:", markdown_file, "\n")
  })
} else {
  cat("rmarkdown package not available.\n")
  cat("R Markdown file created:", markdown_file, "\n")
}

cat("Analysis complete!\n")
