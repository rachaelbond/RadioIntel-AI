# Radio Intel AI DJ & Listener Analysis Script v:4.0
# Comprehensive analysis of online listener data with new SQL structure, and AI DJ features
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
#
# =============================================================================
# SYSTEM DEPENDENCIES
# =============================================================================
# 
# This script requires the following system-level dependencies:
# 
# REQUIRED:
#   - ffmpeg/ffprobe: For reliable ID3v2 tag reading from audio files
#   - Ubuntu/Debian: sudo apt-get install ffmpeg
#   - CentOS/RHEL: sudo yum install ffmpeg  
#   - macOS: brew install ffmpeg
#   - Windows: Download from https://ffmpeg.org/download.html
#
# The script will fall back to R packages (av, tuneR) if ffprobe is not 
# available, but metadata extraction quality will be significantly reduced,
# especially for ID3v2 tagged MP3 files.
#
# =============================================================================

# Clear the environment of any old data
rm(list = ls())
options(warn = 1)  # Show warnings immediately
gc(reset = TRUE)  # Initial cleanup

# Prevent R from hoarding memory
options(expressions = 5000)  # Reduce expression memory
Sys.setenv("R_GC_MEM_GROW" = "1")  # More aggressive garbage collection
Sys.setenv("R_MAX_VSIZE" = "4Gb")  # Limit R's memory hunger

if (Sys.which("ffprobe") == "") {
  warning("ffprobe not found! Audio metadata extraction will be limited. Install ffmpeg for full functionality.")
  cat("⚠️  ffprobe not available - metadata extraction will be limited\n")
  cat("   Install ffmpeg for full ID3v2 tag support\n")
} else {
  cat("✅ ffprobe found - full metadata extraction available\n")
}

# =============================================================================
# USER CONFIGURATION - EDIT THESE SETTINGS
# =============================================================================

# REPORT TYPE: Choose what data to analyze
# Option 1: "ALL" - Use all available data (cumulative report)
# Option 2: Specific month - Use format "YYYY-MM" (e.g., "2025-01", "2024-12")
REPORT_TYPE <- "ALL"  # Change this to "2025-01" for January 2025 only, etc.
#REPORT_TYPE <- "2025-07"

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
DB_TABLE <- ""
DB_TYPE <- "mariadb" # OR: DB_TYPE <- "mysql"

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
EXCLUDE_TERMS_ABSOLUTE_LISTENERS <- c("")

DATA_COLLECTION <- 5 # How often the data is collected by the PHP script in minutes
REALTIME_UPDATE_ENABLED <- TRUE
TOTAL_PLAYS_FILTER <- 2

PLAYOUT_SYSTEM <- "LOCAL" # HOOK FOR EXTENSIBLE FUNCTIONS, eg. LOCAL, LIQUIDSOAP, ZETTA, WIDEORBIT, ENCO_DAD, RADIOMAN
PLAYOUT_SYSTEM_SQL_USER <- "" # Empty for local playback
PLAYOUT_SYSTEM_SQL_PASSWORD <- "" # Empty for local playback
PLAYOUT_DB_HOST <- "" # Empty for local playback
PLAYOUT_DB_PORT <- "" # Empty for local playback
PLAYOUT_DB_NAME <- "" # Empty for local playback
NETWORK_MUSIC_PATH <- "" # Empty for non-LOCAL
PLAYOUT_TARGET <- "M3U" 

REALTIME_UPDATE_ENABLED <- TRUE
USE_TIME_MARKS <- TRUE
TIME_MARK_BLOCK_LENGTH <- 29 # In minutes (Time block excluding commercials or news)
CROSS_FADE_IN <- 0 # Seconds of cross-fade at start of track. Can use the start and fade times from a playout system DB
CROSS_FADE_OUT <- 0 # Seconds of cross-fade at end of track. Can use the start and fade times from a playout system DB
INTO_BREAK_BUFFER <- 10 # Seconds to leave for into-break message, to be dynamically allocated when needed to help account for playout system drift
PREALLOCATE_INTO_BREAK_MESSAGE <- TRUE
ALLOW_ARTIST_DOUBLE_PLAY <- TRUE
ESTIMATED_DURATION_OF_INTROS <- 50 # Not really needed now due to changes in intro generation

TALKING_POINTS_TABLE <- "dj_talking_points"
AI_DJ_HISTORY_TABLE <- "ai_dj_history"
AI_DJ_EXCLUSION_DAYS <- 2  # Number of days to exclude AI DJ played tracks
RECENT_PLAY_EXCLUSION_HOURS <- 6 # Number of hours to exclude regular DJ played tracks

AVAILABLE_TRACKS_TABLE <- "available_tracks"

# Artist knowledge for double-plays.
# For instance, entries might match Bob Dylan with The Beatles
# via George Harrison and Bob Dylan both being in The Traveling Wilburys.
# Example SQL file included in git.
ARTIST_EQUIVALENCIES_TABLE <- "artist_equivalencies" 

USE_FOR_INTROS <- "claude" # "claude" or "chatgpt"
CHATGPT_API_KEY <- ""
CLAUDE_ANTHROPIC_API_KEY <- ""

GOOGLE_TTS_API_KEY <- ""

AWS_ACCESS_KEY_ID <- ""
AWS_SECRET_ACCESS_KEY <- ""
AWS_DEFAULT_REGION <- ""

# Configuration for TTS
TTS_ENABLED <- TRUE # Set to FALSE to disable TTS
TTS_SERVICE <- "google"  # Options: "google", "amazon", "microsoft", "espeak"
# Google TTS
GOOGLE_TTS_VOICE <- "en-GB-Wavenet-C"  # British voice
#GOOGLE_TTS_VOICE <- "en-GB-Neural2-A"  # British voice
AMAZON_TTS_VOICE <- "Amy"       # British female voices: "Amy", "Emma"

TTS_OUTPUT_DIR <- ""  # Directory to save audio files
TTS_SPEED <- 0.975  # Speaking rate (0.25 to 4.0 for cloud services)
TTS_PITCH <- -1.0
TTS_VOLUME <- 8
TTS_SAMPLE_RATE <- 22050    # Sample rate in Hz (optional)
TTS_EFFECTS_PROFILES <- c("large-home-entertainment-class-device")  # Audio profile for radio

# Create output directory if it doesn't exist
if (!dir.exists(TTS_OUTPUT_DIR)) {
  dir.create(TTS_OUTPUT_DIR, recursive = TRUE)
  cat("📁 Created TTS output directory:", TTS_OUTPUT_DIR, "\n")
}

DEBUG_TO_CONSOLE <- "Y"

# =============================================================================
# END USER CONFIGURATION - DON'T EDIT BELOW THIS LINE
# =============================================================================

# Install required packages if not already installed
required_packages <- c("Rserve", "DBI", "RMariaDB", "RMySQL", "odbc", "RCurl", "dplyr", "ggplot2", "kableExtra", 
                       "lubridate", "tidyr", "scales", "gridExtra", "corrplot",
                       "nnet", "randomForest", "xgboost", "glmnet", "forecast", "zoo",
                       "stringr", "stringdist", "knitr", "rmarkdown", "glue", "jsonlite", "e1071",
                       "text2speech", "httr", "aws.polly", "tuneR", "googleLanguageR", "av")

for(pkg in required_packages) {
  if(!require(pkg, character.only = TRUE)) {
    install.packages(pkg)
    library(pkg, character.only = TRUE)
  }
}

# Load required libraries
library(Rserve)
library(DBI)
library(RMariaDB)
library(RMySQL)
library(odbc)
library(RCurl)
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
library(stringdist)
library(knitr)
library(rmarkdown)
library(glue)
library(jsonlite)
library(nnet)
library(randomForest)
library(xgboost)
library(glmnet)
library(zoo)
library(e1071)
library(httr)
library(text2speech)
library(aws.polly)
library(googleLanguageR)
library(tuneR)
library(av)

# =============================================================================
# CREATE TALKING POINTS TABLE AND AI DJ HISTORY TABLE IF THEY DON'T EXIST
# =============================================================================

#create_ai_dj_tables <- function() {
  cat("🗄️ Setting up DJ talking points and AI DJ history tables...\n")
  
  tryCatch({
    # Connect to database using existing connection settings
    if (DB_TYPE == "mysql") {
      con <- dbConnect(RMySQL::MySQL(), 
                       host = DB_HOST, 
                       dbname = DB_NAME, 
                       username = DB_USER, 
                       password = DB_PASSWORD, 
                       port = DB_PORT)
    } else if (DB_TYPE == "mariadb") {
      con <- dbConnect(RMariaDB::MariaDB(), 
                       host = DB_HOST, 
                       dbname = DB_NAME, 
                       username = DB_USER, 
                       password = DB_PASSWORD, 
                       port = DB_PORT)
    }
    
    # =============================================================================
    # CREATE TALKING POINTS TABLE (existing functionality)
    # =============================================================================
    
    talking_points_table_exists <- dbExistsTable(con, TALKING_POINTS_TABLE)
    
    if (!talking_points_table_exists) {
      cat("   📝 Creating new talking points table...\n")
      
      create_sql <- paste0("
        CREATE TABLE `", TALKING_POINTS_TABLE, "` (
          `id` int(11) NOT NULL AUTO_INCREMENT,
          `artist` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
          `song` text COLLATE utf8mb4_unicode_ci DEFAULT NULL,
          `style` text COLLATE utf8mb4_unicode_ci DEFAULT NULL,
          `dj_intros` text COLLATE utf8mb4_unicode_ci DEFAULT NULL,
          `factoids` text COLLATE utf8mb4_unicode_ci DEFAULT NULL,
          `last_updated` timestamp DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
          `duration` decimal(4,1) DEFAULT NULL,
          `last_used` timestamp DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
          `data_source` varchar(50) DEFAULT 'chatGPT',
          `data_quality` enum('excellent','good','fair','poor') DEFAULT 'fair',
          UNIQUE KEY (`id`),
          KEY `artist` (`artist`),
          KEY `song` (`song`),
          KEY `last_updated` (`last_updated`),
          KEY `data_quality` (`data_quality`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
      ")
      
      dbExecute(con, create_sql)
      cat("   ✅ Talking points table created successfully\n")
    } else {
      cat("   ✅ Talking points table already exists\n")
    }
    
    # =============================================================================
    # CREATE-ARTIST EQUIVALENCIES TABLE
    # =============================================================================
    
    # Check if table exists and create if needed
    table_exists <- dbExistsTable(con, ARTIST_EQUIVALENCIES_TABLE)
    
    if (!table_exists) {
      cat("   📝 Creating new artist equivalencies table...\n")
      
      create_sql <- paste0("
    CREATE TABLE `", ARTIST_EQUIVALENCIES_TABLE, "` (
      `id` int(11) NOT NULL AUTO_INCREMENT,
      `artist_1` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
      `artist_2` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
      `relationship_type` enum('same_artist','band_member','collaboration','spinoff') COLLATE utf8mb4_unicode_ci DEFAULT 'same_artist',
      `notes` text COLLATE utf8mb4_unicode_ci DEFAULT NULL,
      `active` tinyint(1) DEFAULT 1,
      `created_date` timestamp DEFAULT CURRENT_TIMESTAMP,
      `updated_date` timestamp DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
      UNIQUE KEY (`id`),
      KEY `artist_1` (`artist_1`),
      KEY `artist_2` (`artist_2`),
      KEY `active` (`active`),
      UNIQUE KEY `unique_pair` (`artist_1`, `artist_2`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  ")
      
      dbExecute(con, create_sql)
      cat("   ✅ Artist equivalencies table created successfully\n")
    } else {
      cat("   ✅ Artist equivalencies table already exists\n")
    }
    
    # =============================================================================
    # CREATE AI DJ HISTORY TABLE (NEW!)
    # =============================================================================
    
    ai_history_exists <- dbExistsTable(con, AI_DJ_HISTORY_TABLE)
    
    if (!ai_history_exists) {
      cat("   🤖 Creating new AI DJ history table...\n")
      
      create_ai_history_sql <- paste0("
        CREATE TABLE `", AI_DJ_HISTORY_TABLE, "` (
          `id` int(11) NOT NULL AUTO_INCREMENT,
          `artist` varchar(255) NOT NULL,
          `song` text NOT NULL,
          `genre` varchar(100) DEFAULT NULL,
          `introduction_used` text DEFAULT NULL,
          `decision_reason` text DEFAULT NULL,
          `selection_algorithm` varchar(50) DEFAULT 'fuzzy_bayesian',
          `context_factors` text COLLATE utf8mb4_unicode_ci DEFAULT NULL,
          `listener_count_when_selected` int(11) DEFAULT NULL,
          `played_at` timestamp DEFAULT CURRENT_TIMESTAMP,
          UNIQUE KEY (`id`),
          KEY `artist_song` (`artist`, `song`(100)),
          KEY `played_at` (`played_at`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
      ")
      
      dbExecute(con, create_ai_history_sql)
      cat("   ✅ AI DJ history table created successfully\n")
    } else {
      cat("   ✅ AI DJ history table already exists\n")
    }
    
    # =============================================================================
    # CREATE AVAILABLE TRACKS TABLE
    # =============================================================================
    
    available_tracks_exists <- dbExistsTable(con, AVAILABLE_TRACKS_TABLE)
    
    if (!available_tracks_exists) {
      cat("   🎵 Creating new enhanced available tracks table...\n")
      
      create_available_tracks_sql <- paste0("
        CREATE TABLE `", AVAILABLE_TRACKS_TABLE, "` (
          `id` int(11) NOT NULL AUTO_INCREMENT,
          `artist` longtext COLLATE utf8mb4_unicode_ci NOT NULL,
          `song` longtext COLLATE utf8mb4_unicode_ci NOT NULL,
          `album` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
          `duration_seconds` decimal(7,3) NOT NULL DEFAULT '9999.999' COMMENT 'Duration in seconds with millisecond precision',
          `file_path` varchar(500) COLLATE utf8mb4_unicode_ci NOT NULL,
          `file_size_bytes` bigint DEFAULT NULL,
          `file_format` varchar(10) DEFAULT NULL COMMENT 'File extension (mp3, flac, wav, etc)',
          `bitrate` int DEFAULT NULL COMMENT 'Audio bitrate in kbps (e.g. 320)',
          `sample_rate` int DEFAULT NULL COMMENT 'Sample rate in Hz (e.g. 44100, 48000, 96000)',
          `bit_depth` tinyint DEFAULT NULL COMMENT 'Bit depth (8, 16, 24, 32)',
          `channels` tinyint DEFAULT NULL COMMENT 'Number of audio channels (1=mono, 2=stereo, 6=5.1, etc)',
          `channel_layout` varchar(20) DEFAULT NULL COMMENT 'Channel layout description (stereo, 5.1, etc)',
          `codec` varchar(20) DEFAULT NULL COMMENT 'Audio codec (mp3, flac, aac, etc)',
          `source` enum('playout_system','dj_collection','network_share','manual_import') COLLATE utf8mb4_unicode_ci DEFAULT 'network_share',
          `network_location` varchar(500) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
          `last_scanned` timestamp DEFAULT CURRENT_TIMESTAMP,
          `last_verified` timestamp DEFAULT CURRENT_TIMESTAMP,
          `verified_exists` tinyint(1) DEFAULT 1,
          `scan_errors` text COLLATE utf8mb4_unicode_ci DEFAULT NULL,
          `genre` longtext COLLATE utf8mb4_unicode_ci DEFAULT NULL,
          `year` int DEFAULT NULL,
          `added_by` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT 'system',
          `notes` text COLLATE utf8mb4_unicode_ci DEFAULT NULL,
          `active` tinyint(1) DEFAULT 1,
          `created_at` timestamp DEFAULT CURRENT_TIMESTAMP,
          `updated_at` timestamp DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
          UNIQUE KEY (`id`),
          KEY `duration` (`duration_seconds`),
          KEY `source` (`source`),
          KEY `verified_exists` (`verified_exists`),
          KEY `active` (`active`),
          KEY `last_scanned` (`last_scanned`),
          KEY `genre` (`genre`),
          KEY `bitrate` (`bitrate`),
          KEY `sample_rate` (`sample_rate`),
          KEY `bit_depth` (`bit_depth`),
          KEY `channels` (`channels`),
          KEY `file_format` (`file_format`),
          KEY `codec` (`codec`),
          UNIQUE KEY `unique_track_path` (`artist`, `song`, `file_path`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
      ")
      
      dbExecute(con, create_available_tracks_sql)
      cat("   ✅ Enhanced available tracks table created successfully\n")
    } else {
      cat("   ✅ Available tracks table already exists\n")
    }
    
    dbDisconnect(con)
#    return(TRUE)
    
  }, error = function(e) {
    cat("   ❌ Database error:", e$message, "\n")
    if (exists("con")) dbDisconnect(con)
#    return(FALSE)
  })

#}

# =============================================================================
# BEWARE! HERE BE DRAGONS...
# =============================================================================

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
# STATISTICAL AND REPORT GENERATION FUNCTIONS FROM HERE ↓↓↓
# =============================================================================

update_statistics <- function(data) {
  cat("📊 UPDATING STATISTICAL ANALYSIS...\n")

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
main_dow_analysis <<- data %>%
  group_by(weekday, hour) %>%
  summarise(
    main_avg_listeners = mean(main_total_listeners, na.rm = TRUE),
    main_avg_stream1 = mean(main_stream1, na.rm = TRUE),
    main_avg_stream2 = mean(main_stream2, na.rm = TRUE),
    .groups = 'drop'
  )

# Calculate hourly averages for percentage comparisons
main_hourly_avg <<- data %>%
  group_by(hour) %>%
  summarise(main_overall_avg = mean(main_total_listeners, na.rm = TRUE), .groups = 'drop')

# Create percentage difference data for day of week patterns
main_dow_comparison <<- main_dow_analysis %>%
  left_join(main_hourly_avg, by = "hour") %>%
  mutate(pct_diff = ((main_avg_listeners - main_overall_avg) / main_overall_avg) * 100)

# Clean data for plotting
main_dow_comparison_clean <<- main_dow_comparison %>%
  filter(!is.na(pct_diff), !is.infinite(pct_diff), !is.na(hour), !is.na(weekday))

# Prepare data for line charts
main_dow_comparison_line_chart <<- main_dow_comparison_clean %>%
  mutate(weekday = factor(weekday, levels = c("Monday", "Tuesday", "Wednesday", 
                                              "Thursday", "Friday", "Saturday", "Sunday")))

# Prepare data for heatmaps
main_dow_analysis_clean <<- main_dow_analysis %>%
  filter(!is.na(main_avg_listeners), !is.infinite(main_avg_listeners), !is.na(hour), !is.na(weekday))

# Set factor levels for heatmap display (reversed for proper ordering)
main_dow_comparison_clean$weekday <<- factor(main_dow_comparison_clean$weekday, 
                                            levels = rev(levels(main_dow_comparison_line_chart$weekday)))

main_dow_analysis_clean$weekday <<- factor(main_dow_analysis_clean$weekday, 
                                          levels = rev(levels(main_dow_comparison_line_chart$weekday)))

# =============================================================================
# PART 1B: BASIC SHOW ANALYSIS - MAIN STATION
# =============================================================================

# Basic show analysis with hourly baseline comparison
main_show_hourly_analysis <<- data %>%
  filter(!is.na(main_showname), main_showname != "", main_showname != "Unknown", main_stand_in != 1) %>%
  group_by(main_showname, main_presenter, main_stand_in, hour, day_type) %>%
  summarise(
    main_avg_listeners = mean(main_total_listeners, na.rm = TRUE),
    main_sessions = n(),
    .groups = 'drop'
  ) %>%
  filter(main_sessions >= 3)

# Calculate hourly baselines for show performance (by day type)
main_hourly_baseline <<- data %>%
  group_by(hour, day_type) %>%
  summarise(main_hour_avg = mean(main_total_listeners, na.rm = TRUE), .groups = 'drop')

# Calculate show performance vs hourly average
main_show_hourly_performance <<- main_show_hourly_analysis %>%
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
  second_dow_analysis <<- data %>%
    group_by(weekday, hour) %>%
    summarise(
      second_avg_listeners = mean(second_total_listeners, na.rm = TRUE),
      .groups = 'drop'
    )
  
  second_hourly_avg <<- data %>%
    group_by(hour) %>%
    summarise(second_overall_avg = mean(second_total_listeners, na.rm = TRUE), .groups = 'drop')
  
  second_dow_comparison <<- second_dow_analysis %>%
    left_join(second_hourly_avg, by = "hour") %>%
    mutate(pct_diff = ((second_avg_listeners - second_overall_avg) / second_overall_avg) * 100)
  
  second_dow_comparison_clean <<- second_dow_comparison %>%
    filter(!is.na(pct_diff), !is.infinite(pct_diff), !is.na(hour), !is.na(weekday))
  
  second_dow_comparison_line_chart <<- second_dow_comparison_clean %>%
    mutate(weekday = factor(weekday, levels = c("Monday", "Tuesday", "Wednesday", 
                                                "Thursday", "Friday", "Saturday", "Sunday")))
  
  second_dow_analysis_clean <<- second_dow_analysis %>%
    filter(!is.na(second_avg_listeners), !is.infinite(second_avg_listeners), !is.na(hour), !is.na(weekday))
  
  second_dow_comparison_clean$weekday <<- factor(second_dow_comparison_clean$weekday, 
                                                levels = rev(levels(second_dow_comparison_clean$weekday)))
  
  second_dow_analysis_clean$weekday <<- factor(second_dow_analysis_clean$weekday, 
                                              levels = rev(levels(second_dow_analysis_clean$weekday)))
  
  # Basic show analysis for second station
  second_show_hourly_analysis <<- data %>%
    filter(!is.na(second_showname), second_showname != "", second_showname != "Unknown", second_stand_in != 1) %>%
    group_by(second_showname, second_presenter, second_stand_in, hour, day_type) %>%
    summarise(
      second_avg_listeners = mean(second_total_listeners, na.rm = TRUE),
      second_sessions = n(),
      .groups = 'drop'
    ) %>%
    filter(second_sessions >= 3)
  
  second_hourly_baseline <<- data %>%
    group_by(hour, day_type) %>%
    summarise(second_hour_avg = mean(second_total_listeners, na.rm = TRUE), .groups = 'drop')
  
  second_show_hourly_performance <<- second_show_hourly_analysis %>%
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
  comparison_dow_analysis <<- data %>%
    group_by(weekday, hour) %>%
    summarise(
      comparison_avg_listeners = mean(comparison_total_listeners, na.rm = TRUE),
      .groups = 'drop'
    )
  
  comparison_hourly_avg <<- data %>%
    group_by(hour) %>%
    summarise(comparison_overall_avg = mean(comparison_total_listeners, na.rm = TRUE), .groups = 'drop')
  
  comparison_dow_comparison <<- comparison_dow_analysis %>%
    left_join(comparison_hourly_avg, by = "hour") %>%
    mutate(pct_diff = ((comparison_avg_listeners - comparison_overall_avg) / comparison_overall_avg) * 100)
  
  comparison_dow_comparison_clean <<- comparison_dow_comparison %>%
    filter(!is.na(pct_diff), !is.infinite(pct_diff), !is.na(hour), !is.na(weekday))
  
  comparison_dow_comparison_line_chart <<- comparison_dow_comparison_clean %>%
    mutate(weekday = factor(weekday, levels = c("Monday", "Tuesday", "Wednesday", 
                                                "Thursday", "Friday", "Saturday", "Sunday")))
  
  comparison_dow_analysis_clean <<- comparison_dow_analysis %>%
    filter(!is.na(comparison_avg_listeners), !is.infinite(comparison_avg_listeners), !is.na(hour), !is.na(weekday))
  
  comparison_dow_comparison_clean$weekday <<- factor(comparison_dow_comparison_clean$weekday, 
                                                    levels = rev(levels(comparison_dow_comparison_clean$weekday)))
  
  comparison_dow_analysis_clean$weekday <<- factor(comparison_dow_analysis_clean$weekday, 
                                                  levels = rev(levels(comparison_dow_analysis_clean$weekday)))
  
  # Basic show analysis for comparison station
  comparison_show_hourly_analysis <<- data %>%
    filter(!is.na(comparison_showname), comparison_showname != "", comparison_showname != "Unknown", comparison_stand_in != 1) %>%
    group_by(comparison_showname, comparison_presenter, comparison_stand_in, hour, day_type) %>%
    summarise(
      comparison_avg_listeners = mean(comparison_total_listeners, na.rm = TRUE),
      comparison_sessions = n(),
      .groups = 'drop'
    ) %>%
    filter(comparison_sessions >= 3)
  
  comparison_hourly_baseline <<- data %>%
    group_by(hour, day_type) %>%
    summarise(comparison_hour_avg = mean(comparison_total_listeners, na.rm = TRUE), .groups = 'drop')
  
  comparison_show_hourly_performance <<- comparison_show_hourly_analysis %>%
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
  main_weekday_heatmap_data <<- main_show_hourly_performance %>%
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
  main_primary_hours <<- main_weekday_heatmap_data %>%
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
    slice_head(n=1) %>%
    ungroup() %>%
    select(main_showname, primary_hour = hour)
  
  # Create final heatmap data with time slot ordering
  main_weekday_heatmap_data <<- main_weekday_heatmap_data %>%
    left_join(main_primary_hours, by = "main_showname") %>%
    # Only keep shows that have a valid primary hour
    filter(!is.na(primary_hour)) %>%
    arrange(primary_hour, main_showname) %>%
    select(main_showname, hour, main_pct_vs_hour) %>%
    mutate(main_showname = factor(main_showname, levels = rev(unique(main_showname))))
  
  # Weekend shows performance heatmap data  
  main_weekend_heatmap_data <<- main_show_hourly_performance %>%
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
  main_weekend_primary_hours <<- main_weekend_heatmap_data %>%
    group_by(main_showname, hour) %>%
    summarise(
      hour_sessions = sum(main_sessions),
      hour_coverage = n(),
      .groups = 'drop'
    ) %>%
    group_by(main_showname) %>%
    filter(hour_sessions >= 5) %>%
    arrange(desc(hour_sessions)) %>%
    slice_head(n=1) %>%
    ungroup() %>%
    select(main_showname, primary_hour = hour)
  
  # Create final weekend heatmap data
  main_weekend_heatmap_data <<- main_weekend_heatmap_data %>%
    left_join(main_weekend_primary_hours, by = "main_showname") %>%
    filter(!is.na(primary_hour)) %>%
    arrange(primary_hour, main_showname) %>%
    select(main_showname, hour, main_pct_vs_hour) %>%
    mutate(main_showname = factor(main_showname, levels = rev(unique(main_showname))))
  
  cat("Main station heatmap data created:", nrow(main_weekday_heatmap_data), "weekday,", nrow(main_weekend_heatmap_data), "weekend data points\n")
  
} else {
  main_weekday_heatmap_data <<- data.frame()
  main_weekend_heatmap_data <<- data.frame()
}

# =============================================================================
# SECOND STATION PERFORMANCE HEATMAPS (IF ENABLED)
# =============================================================================

if (ANALYSE_SECOND_STATION == "Y" && exists("second_show_hourly_performance") && nrow(second_show_hourly_performance) > 0) {
  
  # Weekday shows performance heatmap data for second station
  second_weekday_heatmap_data <<- second_show_hourly_performance %>%
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
  second_primary_hours <<- second_weekday_heatmap_data %>%
    group_by(second_showname, hour) %>%
    summarise(
      hour_sessions = sum(second_sessions),
      hour_coverage = n(),
      .groups = 'drop'
    ) %>%
    group_by(second_showname) %>%
    filter(hour_sessions >= 5) %>%
    arrange(desc(hour_sessions)) %>%
    slice_head(n=1) %>%
    ungroup() %>%
    select(second_showname, primary_hour = hour)
  
  # Create final second station weekday heatmap data
  second_weekday_heatmap_data <<- second_weekday_heatmap_data %>%
    left_join(second_primary_hours, by = "second_showname") %>%
    filter(!is.na(primary_hour)) %>%
    arrange(primary_hour, second_showname) %>%
    select(second_showname, hour, second_pct_vs_hour) %>%
    mutate(second_showname = factor(second_showname, levels = rev(unique(second_showname))))
  
  # Weekend shows for second station
  second_weekend_heatmap_data <<- second_show_hourly_performance %>%
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
  second_weekend_primary_hours <<- second_weekend_heatmap_data %>%
    group_by(second_showname, hour) %>%
    summarise(
      hour_sessions = sum(second_sessions),
      hour_coverage = n(),
      .groups = 'drop'
    ) %>%
    group_by(second_showname) %>%
    filter(hour_sessions >= 5) %>%
    arrange(desc(hour_sessions)) %>%
    slice_head(n=1) %>%
    ungroup() %>%
    select(second_showname, primary_hour = hour)
  
  # Create final second station weekend heatmap data
  second_weekend_heatmap_data <<- second_weekend_heatmap_data %>%
    left_join(second_weekend_primary_hours, by = "second_showname") %>%
    filter(!is.na(primary_hour)) %>%
    arrange(primary_hour, second_showname) %>%
    select(second_showname, hour, second_pct_vs_hour) %>%
    mutate(second_showname = factor(second_showname, levels = rev(unique(second_showname))))
  
  cat("Second station heatmap data created:", nrow(second_weekday_heatmap_data), "weekday,", nrow(second_weekend_heatmap_data), "weekend data points\n")
  
} else {
  second_weekday_heatmap_data <<- data.frame()
  second_weekend_heatmap_data <<- data.frame()
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
incomplete_coverage_check <<- data %>%
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
robust_hourly_baseline <<- data %>%
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
  main_hourly_baseline <<- robust_hourly_baseline
} else {
  cat("Keeping original baseline - insufficient robust data\n")
}

# IMPROVED: Add data quality flags to show performance data
if (exists("main_show_hourly_performance")) {
  main_show_hourly_performance <<- main_show_hourly_performance %>%
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
main_absolute_performance <<- main_show_hourly_analysis %>%
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
  
  second_absolute_performance <<- second_show_hourly_analysis %>%
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
  
  comparison_absolute_performance <<- comparison_show_hourly_analysis %>%
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
  main_weekday_absolute <<- main_absolute_performance %>%
    filter(day_type == "Weekday") %>%
    filter(!grepl(paste(EXCLUDE_TERMS_ABSOLUTE_LISTENERS, collapse = "|"), main_showname, ignore.case = TRUE)) %>%
    head(100)  # Limit for chart readability
  
  # Weekend absolute listeners (for charts)
  main_weekend_absolute <<- main_absolute_performance %>%
    filter(day_type == "Weekend") %>%
    filter(!grepl(paste(EXCLUDE_TERMS_ABSOLUTE_LISTENERS, collapse = "|"), main_showname, ignore.case = TRUE)) %>%
    head(100)  # Limit for chart readability
  
}

# Second station - filtered datasets (if enabled)
if (ANALYSE_SECOND_STATION == "Y" && exists("second_absolute_performance")) {
  
  second_weekday_absolute <<- second_absolute_performance %>%
    filter(day_type == "Weekday") %>%
    filter(!grepl(paste(EXCLUDE_TERMS, collapse = "|"), second_showname, ignore.case = TRUE)) %>%
    head(100)
  
  second_weekend_absolute <<- second_absolute_performance %>%
    filter(day_type == "Weekend") %>%
    filter(!grepl(paste(EXCLUDE_TERMS, collapse = "|"), second_showname, ignore.case = TRUE)) %>%
    head(100)
  
}

# Comparison station - filtered datasets (if enabled)
if (ANALYSE_COMPARISON_STATION == "Y" && exists("comparison_absolute_performance")) {
  
  comparison_weekday_absolute <<- comparison_absolute_performance %>%
    filter(day_type == "Weekday") %>%
    filter(!grepl(paste(EXCLUDE_TERMS, collapse = "|"), comparison_showname, ignore.case = TRUE)) %>%
    head(100)
  
  comparison_weekend_absolute <<- comparison_absolute_performance %>%
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
    top_shows <<- main_weekend_absolute %>% head(5)
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
main_show_summary <<- main_show_hourly_performance %>%
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
main_best_weekday_shows <<- main_show_summary %>%
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
main_best_weekend_shows <<- main_show_summary %>%
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
main_all_weekday_shows <<- main_show_summary %>%
  filter(day_type == "Weekday") %>%
  filter(!grepl(paste(EXCLUDE_TERMS, collapse = "|"), main_showname, ignore.case = TRUE)) %>%
  filter(main_stand_in != 1) %>%
  arrange(desc(main_avg_performance))

main_all_weekend_shows <<- main_show_summary %>%
  filter(day_type == "Weekend") %>%
  filter(!grepl(paste(EXCLUDE_TERMS, collapse = "|"), main_showname, ignore.case = TRUE)) %>%
  filter(main_stand_in != 1) %>%
  arrange(desc(main_avg_performance))


# =============================================================================
# PART 3C: DJ PERFORMANCE ANALYSIS (Z-SCORE BASED)
# =============================================================================

# Calculate hourly baseline statistics (mean and standard deviation)
main_hourly_baseline_stats <<- data %>%
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
  main_dj_performance_zscore <<- data %>%
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
    main_top_djs_zscore <<- main_dj_performance_zscore %>%
      filter(main_avg_zscore_performance > 0) %>%
      head(15)
    
    # Underperforming DJs
    main_bottom_djs_zscore <<- main_dj_performance_zscore %>%
      filter(main_avg_zscore_performance < 0) %>%
      tail(10) %>%
      arrange(main_avg_zscore_performance)
    
    cat("✓ Z-score DJ performance analysis completed\n")
    cat("  - DJs analyzed:", nrow(main_dj_performance_zscore), "\n")
    cat("  - Top performers:", nrow(main_top_djs_zscore), "\n")
    
  } else {
    main_top_djs_zscore <<- data.frame()
    main_bottom_djs_zscore <<- data.frame()
  }
  
} else {
  main_dj_performance_zscore <<- data.frame()
  main_top_djs_zscore <<- data.frame()
  main_bottom_djs_zscore <<- data.frame()
}

# =============================================================================
# PART 3D: SHOW PERFORMANCE ANALYSIS (Z-SCORE BASED)
# =============================================================================

if (exists("main_hourly_baseline_stats") && nrow(main_hourly_baseline_stats) > 0) {
  
  cat("Running z-score based show performance analysis for main station...\n")
  
  # Calculate z-scores for show performance
  main_show_performance_zscore <<- data %>%
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
    main_top_shows_zscore <<- main_show_performance_zscore %>%
      filter(main_avg_zscore_performance > 0) %>%
      head(15)
    
    # Underperforming shows
    main_bottom_shows_zscore <<- main_show_performance_zscore %>%
      filter(main_avg_zscore_performance < 0) %>%
      tail(10) %>%
      arrange(main_avg_zscore_performance)
    
    cat("✓ Z-score show performance analysis completed\n")
    cat("  - Shows analyzed:", nrow(main_show_performance_zscore), "\n")
    cat("  - Top performers:", nrow(main_top_shows_zscore), "\n")
    
  } else {
    main_top_shows_zscore <<- data.frame()
    main_bottom_shows_zscore <<- data.frame()
  }
  
} else {
  main_show_performance_zscore <<- data.frame()
  main_top_shows_zscore <<- data.frame()
  main_bottom_shows_zscore <<- data.frame()
}

# =============================================================================
# PART 3E: WEEKDAY AND WEEKEND HEATMAPS (Z-SCORE BASED)
# =============================================================================

if (exists("main_hourly_baseline_stats") && nrow(main_hourly_baseline_stats) > 0) {
  
  cat("Creating z-score based weekday and weekend heatmaps for main station...\n")
  
  # Calculate z-scores for all shows by hour and day type
  main_show_heatmap_zscore <<- data %>%
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
  main_weekday_heatmap_zscore <<- main_show_heatmap_zscore %>%
    filter(day_type == "Weekday")
  
  main_weekend_heatmap_zscore <<- main_show_heatmap_zscore %>%
    filter(day_type == "Weekend")
  
  if (nrow(main_weekday_heatmap_zscore) > 0) {
    cat("✓ Weekday heatmap data created:", nrow(main_weekday_heatmap_zscore), "show-hour combinations\n")
  }
  
  if (nrow(main_weekend_heatmap_zscore) > 0) {
    cat("✓ Weekend heatmap data created:", nrow(main_weekend_heatmap_zscore), "show-hour combinations\n")
  }
  
} else {
  main_weekday_heatmap_zscore <<- data.frame()
  main_weekend_heatmap_zscore <<- data.frame()
}

# =============================================================================
# PART 3F: SECOND STATION SHOW SUMMARIES (IF ENABLED)
# =============================================================================

if (ANALYSE_SECOND_STATION == "Y") {
  
  # Create show summaries with safe aggregation
  second_show_summary <<- second_show_hourly_performance %>%
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
  second_best_weekday_shows <<- second_show_summary %>%
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
  second_best_weekend_shows <<- second_show_summary %>%
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
  second_all_weekday_shows <<- second_show_summary %>%
    filter(day_type == "Weekday") %>%
    filter(!grepl(paste(EXCLUDE_TERMS, collapse = "|"), second_showname, ignore.case = TRUE)) %>%
    filter(second_stand_in != 1) %>%
    arrange(desc(second_avg_performance))
  
  second_all_weekend_shows <<- second_show_summary %>%
    filter(day_type == "Weekend") %>%
    filter(!grepl(paste(EXCLUDE_TERMS, collapse = "|"), second_showname, ignore.case = TRUE)) %>%
    filter(second_stand_in != 1) %>%
    arrange(desc(second_avg_performance))

  # =============================================================================
  # PART 3H: SECOND STAION DJ PERFORMANCE ANALYSIS (Z-SCORE BASED) (If ENABLED)
  # =============================================================================
  
  # Calculate hourly baseline statistics (mean and standard deviation)
  second_hourly_baseline_stats <<- data %>%
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
    second_dj_performance_zscore <<- data %>%
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
      second_top_djs_zscore <<- second_dj_performance_zscore %>%
        filter(second_avg_zscore_performance > 0) %>%
        head(15)
      
      # Underperforming DJs
      second_bottom_djs_zscore <<- second_dj_performance_zscore %>%
        filter(second_avg_zscore_performance < 0) %>%
        tail(10) %>%
        arrange(second_avg_zscore_performance)
      
      cat("✓ Z-score DJ performance analysis completed\n")
      cat("  - DJs analyzed:", nrow(second_dj_performance_zscore), "\n")
      cat("  - Top performers:", nrow(second_top_djs_zscore), "\n")
      
    } else {
      second_top_djs_zscore <<- data.frame()
      second_bottom_djs_zscore <<- data.frame()
    }
    
  } else {
    second_dj_performance_zscore <<- data.frame()
    second_top_djs_zscore <<- data.frame()
    second_bottom_djs_zscore <<- data.frame()
  }
  
  # =============================================================================
  # PART 3I: SECOND STATION SHOW PERFORMANCE ANALYSIS (Z-SCORE BASED) (IF ENABLED)
  # =============================================================================
  
  if (exists("second_hourly_baseline_stats") && nrow(second_hourly_baseline_stats) > 0) {
    
    cat("Running z-score based show performance analysis for second station...\n")
    
    # Calculate z-scores for show performance
    second_show_performance_zscore <<- data %>%
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
      second_top_shows_zscore <<- second_show_performance_zscore %>%
        filter(second_avg_zscore_performance > 0) %>%
        head(15)
      
      # Underperforming shows
      second_bottom_shows_zscore <<- second_show_performance_zscore %>%
        filter(second_avg_zscore_performance < 0) %>%
        tail(10) %>%
        arrange(second_avg_zscore_performance)
      
      cat("✓ Z-score show performance analysis completed\n")
      cat("  - Shows analyzed:", nrow(second_show_performance_zscore), "\n")
      cat("  - Top performers:", nrow(second_top_shows_zscore), "\n")
      
    } else {
      second_top_shows_zscore <<- data.frame()
      second_bottom_shows_zscore <<- data.frame()
    }
    
  } else {
    second_show_performance_zscore <<- data.frame()
    second_top_shows_zscore <<- data.frame()
    second_bottom_shows_zscore <<- data.frame()
  }
  
  # =============================================================================
  # PART 3J: SECOND STATION WEEKDAY AND WEEKEND HEATMAPS (Z-SCORE BASED) (IF ENABLED)
  # =============================================================================
  
  if (exists("second_hourly_baseline_stats") && nrow(second_hourly_baseline_stats) > 0) {
    
    cat("Creating z-score based weekday and weekend heatmaps for second station...\n")
    
    # Calculate z-scores for all shows by hour and day type
    second_show_heatmap_zscore <<- data %>%
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
    second_weekday_heatmap_zscore <<- second_show_heatmap_zscore %>%
      filter(day_type == "Weekday")
    
    second_weekend_heatmap_zscore <<- second_show_heatmap_zscore %>%
      filter(day_type == "Weekend")
    
    if (nrow(second_weekday_heatmap_zscore) > 0) {
      cat("✓ Weekday heatmap data created:", nrow(second_weekday_heatmap_zscore), "show-hour combinations\n")
    }
    
    if (nrow(second_weekend_heatmap_zscore) > 0) {
      cat("✓ Weekend heatmap data created:", nrow(second_weekend_heatmap_zscore), "show-hour combinations\n")
    }
    
  } else {
    second_weekday_heatmap_zscore <<- data.frame()
    second_weekend_heatmap_zscore <<- data.frame()
  }
  
}

# =============================================================================
# PART 3K: COMPARISON STATION SHOW SUMMARIES (IF ENABLED)
# =============================================================================

if (ANALYSE_COMPARISON_STATION == "Y") {
  
  # Comparison station show summaries
  comparison_show_summary <<- comparison_show_hourly_performance %>%
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
  comparison_best_weekday_shows <<- comparison_show_summary %>%
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
  
  comparison_best_weekend_shows <<- comparison_show_summary %>%
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
  comparison_hourly_baseline_stats <<- data %>%
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
    comparison_dj_performance_zscore <<- data %>%
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
      comparison_top_djs_zscore <<- comparison_dj_performance_zscore %>%
        filter(comparison_avg_zscore_performance > 0) %>%
        head(15)
      
      # Underperforming DJs
      comparison_bottom_djs_zscore <<- comparison_dj_performance_zscore %>%
        filter(comparison_avg_zscore_performance < 0) %>%
        tail(10) %>%
        arrange(comparison_avg_zscore_performance)
      
      cat("✓ Z-score DJ performance analysis completed\n")
      cat("  - DJs analyzed:", nrow(comparison_dj_performance_zscore), "\n")
      cat("  - Top performers:", nrow(comparison_top_djs_zscore), "\n")
      
    } else {
      comparison_top_djs_zscore <<- data.frame()
      comparison_bottom_djs_zscore <<- data.frame()
    }
    
  } else {
    comparison_dj_performance_zscore <<- data.frame()
    comparison_top_djs_zscore <<- data.frame()
    comparison_bottom_djs_zscore <<- data.frame()
  }
  
  # =============================================================================
  # PART 3N: COMPARISON STATION SHOW PERFORMANCE ANALYSIS (Z-SCORE BASED) (IF ENABLED)
  # =============================================================================
  
  if (exists("comparison_hourly_baseline_stats") && nrow(comparison_hourly_baseline_stats) > 0) {
    
    cat("Running z-score based show performance analysis for comparison station...\n")
    
    # Calculate z-scores for show performance
    comparison_show_performance_zscore <<- data %>%
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
      comparison_top_shows_zscore <<- comparison_show_performance_zscore %>%
        filter(comparison_avg_zscore_performance > 0) %>%
        head(15)
      
      # Underperforming shows
      comparison_bottom_shows_zscore <<- comparison_show_performance_zscore %>%
        filter(comparison_avg_zscore_performance < 0) %>%
        tail(10) %>%
        arrange(comparison_avg_zscore_performance)
      
      cat("✓ Z-score show performance analysis completed\n")
      cat("  - Shows analyzed:", nrow(comparison_show_performance_zscore), "\n")
      cat("  - Top performers:", nrow(comparison_top_shows_zscore), "\n")
      
    } else {
      comparison_top_shows_zscore <<- data.frame()
      comparison_bottom_shows_zscore <<- data.frame()
    }
    
  } else {
    comparison_show_performance_zscore <<- data.frame()
    comparison_top_shows_zscore <<- data.frame()
    comparison_bottom_shows_zscore <<- data.frame()
  }
  
  # =============================================================================
  # PART 3O: COMPARISON STATION WEEKDAY AND WEEKEND HEATMAPS (Z-SCORE BASED) (IF ENABLED)
  # =============================================================================
  
  if (exists("comparison_hourly_baseline_stats") && nrow(comparison_hourly_baseline_stats) > 0) {
    
    cat("Creating z-score based weekday and weekend heatmaps for comparison station...\n")
    
    # Calculate z-scores for all shows by hour and day type
    comparison_show_heatmap_zscore <<- data %>%
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
    comparison_weekday_heatmap_zscore <<- comparison_show_heatmap_zscore %>%
      filter(day_type == "Weekday")
    
    comparison_weekend_heatmap_zscore <<- comparison_show_heatmap_zscore %>%
      filter(day_type == "Weekend")
    
    if (nrow(comparison_weekday_heatmap_zscore) > 0) {
      cat("✓ Weekday heatmap data created:", nrow(comparison_weekday_heatmap_zscore), "show-hour combinations\n")
    }
    
    if (nrow(comparison_weekend_heatmap_zscore) > 0) {
      cat("✓ Weekend heatmap data created:", nrow(comparison_weekend_heatmap_zscore), "show-hour combinations\n")
    }
    
  } else {
    comparison_weekday_heatmap_zscore <<- data.frame()
    comparison_weekend_heatmap_zscore <<- data.frame()
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
    top_3 <<- main_best_weekend_shows %>% head(3)
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
main_episode_performance <<- data %>%
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
main_show_consistency <<- main_episode_performance %>%
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
  consistency_thresholds <<- list(
    very_consistent = quantile(main_show_consistency$main_performance_sd, 0.25, na.rm = TRUE),  # Top 25%
    consistent = quantile(main_show_consistency$main_performance_sd, 0.50, na.rm = TRUE),        # Top 50%
    variable = quantile(main_show_consistency$main_performance_sd, 0.75, na.rm = TRUE)           # Top 75%
    # Highly variable = above 75th percentile
  )
  
  # Add consistency categories to the data
  main_show_consistency <<- main_show_consistency %>%
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
  main_weekday_consistency <<- main_show_consistency %>%
    filter(day_type == "Weekday", !is.na(main_consistency_score)) %>%
    arrange(desc(main_consistency_score)) %>%
    head(100) %>%  # Limit for chart readability
    mutate(main_showname_factor = factor(paste(main_showname), 
                                         levels = rev(paste(main_showname))))
  
  # Weekend consistency data (for charts)  
  main_weekend_consistency <<- main_show_consistency %>%
    filter(day_type == "Weekend", !is.na(main_consistency_score)) %>%
    arrange(desc(main_consistency_score)) %>%
    head(100) %>%
    mutate(main_showname_factor = factor(paste(main_showname), 
                                         levels = rev(paste(main_showname))))
  
  # Calculate summary statistics
  main_consistency_summary_stats <<- list(
    main_total_shows_analyzed = nrow(main_show_consistency),
    main_total_episodes_analyzed = sum(main_show_consistency$main_total_episodes),
    main_avg_consistency_score = round(mean(main_show_consistency$main_consistency_score, na.rm = TRUE), 1),
    main_most_consistent_show = main_show_consistency %>% 
      filter(main_consistency_score == max(main_consistency_score, na.rm = TRUE)) %>% 
      slice_head(n=1) %>% 
      unite(show_presenter, main_showname, main_presenter, sep = " - ") %>%
      pull(show_presenter),
    main_best_consistency_score = round(max(main_show_consistency$main_consistency_score, na.rm = TRUE), 1),
    main_least_consistent_show = main_show_consistency %>% 
      filter(main_consistency_score == min(main_consistency_score, na.rm = TRUE)) %>% 
      slice_head(n=1) %>% 
      unite(show_presenter, main_showname, main_presenter, sep = " - ") %>%
      pull(show_presenter),
    main_worst_consistency_score = round(min(main_show_consistency$main_consistency_score, na.rm = TRUE), 1),
    main_shows_above_avg_performance = sum(main_show_consistency$main_avg_performance > 0, na.rm = TRUE),
    main_shows_below_avg_performance = sum(main_show_consistency$main_avg_performance <= 0, na.rm = TRUE)
  )
  
} else {
  # Create empty objects if no data
  main_weekday_consistency <<- data.frame()
  main_weekend_consistency <<- data.frame()
  main_consistency_summary_stats <<- list(
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
  second_episode_performance <<- data %>%
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
  second_show_consistency <<- second_episode_performance %>%
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
    consistency_thresholds <<- list(
      very_consistent = quantile(second_show_consistency$second_performance_sd, 0.25, na.rm = TRUE),  # Top 25%
      consistent = quantile(second_show_consistency$second_performance_sd, 0.50, na.rm = TRUE),        # Top 50%
      variable = quantile(second_show_consistency$second_performance_sd, 0.75, na.rm = TRUE)           # Top 75%
      # Highly variable = above 75th percentile
    )
    
    # Add consistency categories to the data
    second_show_consistency <<- second_show_consistency %>%
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
    second_weekday_consistency <<- second_show_consistency %>%
      filter(day_type == "Weekday", !is.na(second_consistency_score)) %>%
      arrange(desc(second_consistency_score)) %>%
      head(100) %>%  # Limit for chart readability
      mutate(second_showname_factor = factor(paste(second_showname), 
                                           levels = rev(paste(second_showname))))
    
    # Weekend consistency data (for charts)  
    second_weekend_consistency <<- second_show_consistency %>%
      filter(day_type == "Weekend", !is.na(second_consistency_score)) %>%
      arrange(desc(second_consistency_score)) %>%
      head(100) %>%
      mutate(second_showname_factor = factor(paste(second_showname), 
                                           levels = rev(paste(second_showname))))
    
    # Calculate summary statistics
    second_consistency_summary_stats <<- list(
      second_total_shows_analyzed = nrow(second_show_consistency),
      second_total_episodes_analyzed = sum(second_show_consistency$second_total_episodes),
      second_avg_consistency_score = round(mean(second_show_consistency$second_consistency_score, na.rm = TRUE), 1),
      second_most_consistent_show = second_show_consistency %>% 
        filter(second_consistency_score == max(second_consistency_score, na.rm = TRUE)) %>% 
        slice_head(n=1) %>% 
        unite(show_presenter, second_showname, second_presenter, sep = " - ") %>%
        pull(show_presenter),
      second_best_consistency_score = round(max(second_show_consistency$second_consistency_score, na.rm = TRUE), 1),
      second_least_consistent_show = second_show_consistency %>% 
        filter(second_consistency_score == min(second_consistency_score, na.rm = TRUE)) %>% 
        slice_head(n=1) %>% 
        unite(show_presenter, second_showname, second_presenter, sep = " - ") %>%
        pull(show_presenter),
      second_worst_consistency_score = round(min(second_show_consistency$second_consistency_score, na.rm = TRUE), 1),
      second_shows_above_avg_performance = sum(second_show_consistency$second_avg_performance > 0, na.rm = TRUE),
      second_shows_below_avg_performance = sum(second_show_consistency$second_avg_performance <= 0, na.rm = TRUE)
    )
    
  } else {
    # Create empty objects if no data
    second_weekday_consistency <<- data.frame()
    second_weekend_consistency <<- data.frame()
    second_consistency_summary_stats <<- list(
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
  comparison_episode_performance <<- data %>%
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
  comparison_show_consistency <<- comparison_episode_performance %>%
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
    comparison_show_consistency <<- comparison_show_consistency %>%
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
main_episode_retention_raw <<- data %>%
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
main_retention_hourly_baseline <<- main_episode_retention_raw %>%
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
main_episode_retention_performance <<- main_episode_retention_raw %>%
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
main_show_retention_summary <<- main_episode_retention_performance %>%
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
  retention_thresholds <<- list(
    excellent = quantile(main_show_retention_summary$main_avg_retention_vs_slot, 0.85, na.rm = TRUE),  # Top 15%
    good = quantile(main_show_retention_summary$main_avg_retention_vs_slot, 0.65, na.rm = TRUE),       # Top 35%
    average = quantile(main_show_retention_summary$main_avg_retention_vs_slot, 0.15, na.rm = TRUE)     # Bottom 15%
    # Poor = below 15th percentile
  )
  
  # Calculate percentile thresholds for retention consistency (using retention_consistency SD)
  retention_consistency_thresholds <<- list(
    very_consistent = quantile(main_show_retention_summary$main_retention_consistency, 0.25, na.rm = TRUE),
    consistent = quantile(main_show_retention_summary$main_retention_consistency, 0.50, na.rm = TRUE),
    variable = quantile(main_show_retention_summary$main_retention_consistency, 0.75, na.rm = TRUE)
  )
  
  # Add retention categories
  main_show_retention_summary <<- main_show_retention_summary %>%
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
  main_weekday_retention <<- main_show_retention_summary %>%
    filter(day_type == "Weekday") %>%
    arrange(desc(main_avg_retention_vs_slot)) %>%
    head(25) %>%  # Top 25 for chart readability
    mutate(main_showname_factor = factor(main_showname, levels = rev(main_showname)))
  
  # Weekend retention data (for charts)
  main_weekend_retention <<- main_show_retention_summary %>%
    filter(day_type == "Weekend") %>%
    arrange(desc(main_avg_retention_vs_slot)) %>%
    head(25) %>%
    mutate(main_showname_factor = factor(main_showname, levels = rev(main_showname)))
  
  # Calculate summary statistics
  main_retention_summary_stats <<- list(
    main_total_shows_analyzed = nrow(main_show_retention_summary),
    main_total_episodes_analyzed = sum(main_show_retention_summary$main_broadcast_hours),
    main_avg_retention_rate = round(mean(main_show_retention_summary$main_avg_retention_rate, na.rm = TRUE), 1),
    main_avg_retention_vs_slot = round(mean(main_show_retention_summary$main_avg_retention_vs_slot, na.rm = TRUE), 1),
    main_best_retainer = main_show_retention_summary %>% 
      filter(main_avg_retention_vs_slot == max(main_avg_retention_vs_slot, na.rm = TRUE)) %>% 
      slice_head(n=1) %>% 
      pull(main_showname),
    main_best_retention_score = round(max(main_show_retention_summary$main_avg_retention_vs_slot, na.rm = TRUE), 1),
    main_worst_retainer = main_show_retention_summary %>% 
      filter(main_avg_retention_vs_slot == min(main_avg_retention_vs_slot, na.rm = TRUE)) %>% 
      slice_head(n=1) %>% 
      pull(main_showname),
    main_worst_retention_score = round(min(main_show_retention_summary$main_avg_retention_vs_slot, na.rm = TRUE), 1)
  )
  
} else {
  main_retention_summary_stats <<- list(
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
  
  main_retention_heatmap_data <<- main_episode_retention_performance %>%
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
  main_weekday_retention_heatmap_data <<- main_retention_heatmap_data %>% 
    filter(day_type == "Weekday")
  
  if (nrow(main_weekday_retention_heatmap_data) > 0) {
    # Order shows by average retention performance
    main_weekday_retention_heatmap_data <<- main_weekday_retention_heatmap_data %>%
      arrange(desc(hour), main_showname) %>%
      mutate(
        show_label = paste(main_showname),
        show_factor = factor(show_label, levels = unique(show_label))
      )
    
    main_weekday_retention_heatmap <<- ggplot(main_weekday_retention_heatmap_data, 
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
    main_weekday_retention_heatmap <<- ggplot() + 
      labs(title = "No weekday multi-hour show data available") + 
      theme_void()
  }
  
  # Create weekend retention heatmap  
  main_weekend_retention_heatmap_data <<- main_retention_heatmap_data %>% 
    filter(day_type == "Weekend")
  
  if (nrow(main_weekend_retention_heatmap_data) > 0) {
    # Order shows by average retention performance
    main_weekend_retention_heatmap_data <<- main_weekend_retention_heatmap_data %>%
      arrange(desc(hour), main_showname) %>%
      mutate(
        show_label = paste(main_showname),
        show_factor = factor(show_label, levels = unique(show_label))
      )
    
    main_weekend_retention_heatmap <<- ggplot(main_weekend_retention_heatmap_data, 
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
    main_weekend_retention_heatmap <<- ggplot() + 
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
  main_weekday_retention_heatmap <<- ggplot() + 
    labs(title = "Retention data not available") + 
    theme_void()
  main_weekend_retention_heatmap <<- ggplot() + 
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
  main_retention_thresholds <<- list(
    excellent = quantile(main_show_retention_summary$main_avg_retention_vs_slot, 0.85, na.rm = TRUE),  # Top 15%
    good = quantile(main_show_retention_summary$main_avg_retention_vs_slot, 0.65, na.rm = TRUE),       # Top 35% 
    average = quantile(main_show_retention_summary$main_avg_retention_vs_slot, 0.35, na.rm = TRUE)     # Bottom 35%
    # Poor = below 35th percentile
  )
  
  # Calculate data-driven thresholds for consistency (lower standard deviation = more consistent)
  main_consistency_thresholds <<- list(
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
  main_retention_thresholds <<- list(excellent = 2, good = 0, average = -2)
  main_consistency_thresholds <<- list(very_consistent = 2, consistent = 4, variable = 6)
}

#Weekdays Retention Performace Table
create_weekday_retention_table <<- function() {
  if (exists("main_show_retention_summary") && nrow(main_show_retention_summary) > 0) {
    
    # Filter for weekday shows
    main_weekday_retention_data <<- main_show_retention_summary %>%
      filter(day_type == "Weekday") %>%
      filter(!grepl(paste(EXCLUDE_TERMS, collapse = "|"), main_showname, ignore.case = TRUE))
      # filter(main_stand_in != 1)
    
    if (nrow(main_weekday_retention_data) > 0) {
      
      # Create the enhanced table with grades
      main_weekday_retention_table <<- main_weekday_retention_data %>%
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
create_weekend_retention_table <<- function() {
  if (exists("main_show_retention_summary") && nrow(main_show_retention_summary) > 0) {
    
    # Filter for weekend shows
    main_weekend_retention_data <<- main_show_retention_summary %>%
      filter(day_type == "Weekend") %>%
      filter(!grepl(paste(EXCLUDE_TERMS, collapse = "|"), main_showname, ignore.case = TRUE))
      # filter(main_stand_in != 1)
    
    if (nrow(main_weekend_retention_data) > 0) {
      
      # Create the enhanced table with grades (using same thresholds as weekday)
      main_weekend_retention_table <<- main_weekend_retention_data %>%
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
main_weekday_retention_table <<- create_weekday_retention_table()
main_weekend_retention_table <<- create_weekend_retention_table()

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
  
  main_hourly_retention_patterns <<- main_episode_retention_performance %>%
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
    main_hourly_retention_chart <<- ggplot(main_hourly_retention_patterns, 
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
    main_hourly_retention_chart <<- ggplot() + 
      labs(title = "No hourly retention data available") + 
      theme_void()
  }
  
} else {
  main_hourly_retention_chart <<- ggplot() + 
    labs(title = "Retention data not available") + 
    theme_void()
}

# =============================================================================
# PART 5J: RETENTION PERFORMANCE vs VARIABILITY SCATTER PLOT
# =============================================================================

# Create the retention performance vs variability scatter plot
if (exists("main_show_retention_summary") && nrow(main_show_retention_summary) > 0) {
  
  main_retention_consistency_chart <<- ggplot(main_show_retention_summary, 
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
  main_retention_consistency_chart <<- ggplot() + 
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
  
  main_consistency_summary_stats <<- list()
  
  # Basic statistics
  main_consistency_summary_stats$total_shows_analyzed <<- nrow(main_show_consistency)
  main_consistency_summary_stats$total_sessions_analyzed <<- sum(main_show_consistency$main_total_sessions, na.rm = TRUE)
  main_consistency_summary_stats$avg_consistency_score <<- round(mean(main_show_consistency$main_consistency_score, na.rm = TRUE), 2)
  
  # Best and worst performers
  best_show <<- main_show_consistency %>% 
    arrange(desc(main_consistency_score)) %>% 
    slice_head(n=1)
  
  worst_show <<- main_show_consistency %>% 
    arrange(main_consistency_score) %>% 
    slice_head(n=1)
  
  main_consistency_summary_stats$most_consistent_show <<- best_show$main_showname[1]
  main_consistency_summary_stats$best_consistency_score <<- round(best_show$main_consistency_score[1], 2)
  main_consistency_summary_stats$least_consistent_show <<- worst_show$main_showname[1]
  main_consistency_summary_stats$worst_consistency_score <<- round(worst_show$main_consistency_score[1], 2)
  
  # Shows above average performance
  main_consistency_summary_stats$shows_above_avg_performance <<- sum(main_show_consistency$main_avg_performance > 0, na.rm = TRUE)
  
  cat("Main station consistency summary stats created\n")
  
} else {
  main_consistency_summary_stats <<- list(
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
  
  main_retention_summary_stats <<- list()
  
  # Basic statistics
  main_retention_summary_stats$total_shows_analyzed <<- nrow(main_show_retention_summary)
  main_retention_summary_stats$total_broadcast_hours <<- sum(main_show_retention_summary$main_broadcast_hours, na.rm = TRUE)
  main_retention_summary_stats$avg_retention_rate <<- round(mean(main_show_retention_summary$main_avg_retention_rate, na.rm = TRUE), 1)
  
  # Best and worst retainers
  best_retainer <<- main_show_retention_summary %>% 
    arrange(desc(main_avg_retention_vs_slot)) %>% 
    slice_head(n=1)
  
  worst_retainer <<- main_show_retention_summary %>% 
    arrange(main_avg_retention_vs_slot) %>% 
    slice_head(n=1)
  
  main_retention_summary_stats$best_retainer <<- best_retainer$main_showname[1]
  main_retention_summary_stats$best_retention_score <<- round(best_retainer$main_avg_retention_vs_slot[1], 1)
  main_retention_summary_stats$worst_retainer <<- worst_retainer$main_showname[1]
  main_retention_summary_stats$worst_retention_score <<- round(worst_retainer$main_avg_retention_vs_slot[1], 1)
  
  cat("Main station retention summary stats created\n")
  
} else {
  main_retention_summary_stats <<- list(
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
  second_episode_retention_raw <<- data %>%
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
  second_retention_hourly_baseline <<- second_episode_retention_raw %>%
    group_by(hour, day_type) %>%
    summarise(
      second_slot_avg_retention = mean(second_retention_rate, na.rm = TRUE),
      second_slot_avg_peak_gain = mean(second_peak_gain, na.rm = TRUE),
      second_slot_avg_volatility = mean(second_volatility, na.rm = TRUE),
      second_episodes_in_slot = n(),
      .groups = 'drop'
    )
  
  # Compare each episode's retention to its time slot average
  second_episode_retention_performance <<- second_episode_retention_raw %>%
    left_join(second_retention_hourly_baseline, by = c("hour", "day_type")) %>%
    mutate(
      second_retention_vs_slot = second_retention_rate - second_slot_avg_retention,
      second_peak_gain_vs_slot = second_peak_gain - second_slot_avg_peak_gain,
      second_volatility_vs_slot = second_volatility - second_slot_avg_volatility
    )
  
  # Summarize retention performance by show across all episodes
  second_show_retention_summary <<- second_episode_retention_performance %>%
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
    retention_thresholds <<- list(
      excellent = quantile(second_show_retention_summary$second_avg_retention_vs_slot, 0.85, na.rm = TRUE),  # Top 15%
      good = quantile(second_show_retention_summary$second_avg_retention_vs_slot, 0.65, na.rm = TRUE),       # Top 35%
      average = quantile(second_show_retention_summary$second_avg_retention_vs_slot, 0.15, na.rm = TRUE)     # Bottom 15%
      # Poor = below 15th percentile
    )
    
    # Calculate percentile thresholds for retention consistency (using retention_consistency SD)
    retention_consistency_thresholds <<- list(
      very_consistent = quantile(second_show_retention_summary$second_retention_consistency, 0.25, na.rm = TRUE),
      consistent = quantile(second_show_retention_summary$second_retention_consistency, 0.50, na.rm = TRUE),
      variable = quantile(second_show_retention_summary$second_retention_consistency, 0.75, na.rm = TRUE)
    )
    
    # Add retention categories
    second_show_retention_summary <<- second_show_retention_summary %>%
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
    second_weekday_retention <<- second_show_retention_summary %>%
      filter(day_type == "Weekday") %>%
      arrange(desc(second_avg_retention_vs_slot)) %>%
      head(25) %>%  # Top 25 for chart readability
      mutate(second_showname_factor = factor(second_showname, levels = rev(second_showname)))
    
    # Weekend retention data (for charts)
    second_weekend_retention <<- second_show_retention_summary %>%
      filter(day_type == "Weekend") %>%
      arrange(desc(second_avg_retention_vs_slot)) %>%
      head(25) %>%
      mutate(second_showname_factor = factor(second_showname, levels = rev(second_showname)))
    
    # Calculate summary statistics
    second_retention_summary_stats <<- list(
      second_total_shows_analyzed = nrow(second_show_retention_summary),
      second_total_episodes_analyzed = sum(second_show_retention_summary$second_broadcast_hours),
      second_avg_retention_rate = round(mean(second_show_retention_summary$second_avg_retention_rate, na.rm = TRUE), 1),
      second_avg_retention_vs_slot = round(mean(second_show_retention_summary$second_avg_retention_vs_slot, na.rm = TRUE), 1),
      second_best_retainer = second_show_retention_summary %>% 
        filter(second_avg_retention_vs_slot == max(second_avg_retention_vs_slot, na.rm = TRUE)) %>% 
        slice_head(n=1) %>% 
        pull(second_showname),
      second_best_retention_score = round(max(second_show_retention_summary$second_avg_retention_vs_slot, na.rm = TRUE), 1),
      second_worst_retainer = second_show_retention_summary %>% 
        filter(second_avg_retention_vs_slot == min(second_avg_retention_vs_slot, na.rm = TRUE)) %>% 
        slice_head(n=1) %>% 
        pull(second_showname),
      second_worst_retention_score = round(min(second_show_retention_summary$second_avg_retention_vs_slot, na.rm = TRUE), 1)
    )
    
  } else {
    second_retention_summary_stats <<- list(
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
    
    second_retention_heatmap_data <<- second_episode_retention_performance %>%
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
    second_weekday_retention_heatmap_data <<- second_retention_heatmap_data %>% 
      filter(day_type == "Weekday")
    
    if (nrow(second_weekday_retention_heatmap_data) > 0) {
      # Order shows by average retention performance
      second_weekday_retention_heatmap_data <<- second_weekday_retention_heatmap_data %>%
        arrange(desc(hour), second_showname) %>%
        mutate(
          show_label = paste(second_showname),
          show_factor = factor(show_label, levels = unique(show_label))
        )
      
      second_weekday_retention_heatmap <<- ggplot(second_weekday_retention_heatmap_data, 
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
      second_weekday_retention_heatmap <<- ggplot() + 
        labs(title = "No weekday multi-hour show data available") + 
        theme_void()
    }
    
    # Create weekend retention heatmap  
    second_weekend_retention_heatmap_data <<- second_retention_heatmap_data %>% 
      filter(day_type == "Weekend")
    
    if (nrow(second_weekend_retention_heatmap_data) > 0) {
      # Order shows by average retention performance
      second_weekend_retention_heatmap_data <<- second_weekend_retention_heatmap_data %>%
        arrange(desc(hour), second_showname) %>%
        mutate(
          show_label = paste(second_showname),
          show_factor = factor(show_label, levels = unique(show_label))
        )
      
      second_weekend_retention_heatmap <<- ggplot(second_weekend_retention_heatmap_data, 
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
      second_weekend_retention_heatmap <<- ggplot() + 
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
    second_weekday_retention_heatmap <<- ggplot() + 
      labs(title = "Retention data not available") + 
      theme_void()
    second_weekend_retention_heatmap <<- ggplot() + 
      labs(title = "Retention data not available") + 
      theme_void()
  }
  
  # Create enhanced retention tables with percentile-based grades
  if (exists("second_show_retention_summary") && nrow(second_show_retention_summary) > 0) {
    
    # Calculate data-driven thresholds for retention performance
    # These thresholds are calculated from ALL shows (weekday + weekend) for consistency
    second_retention_thresholds <<- list(
      excellent = quantile(second_show_retention_summary$second_avg_retention_vs_slot, 0.85, na.rm = TRUE),  # Top 15%
      good = quantile(second_show_retention_summary$second_avg_retention_vs_slot, 0.65, na.rm = TRUE),       # Top 35% 
      average = quantile(second_show_retention_summary$second_avg_retention_vs_slot, 0.35, na.rm = TRUE)     # Bottom 35%
      # Poor = below 35th percentile
    )
    
    # Calculate data-driven thresholds for consistency (lower standard deviation = more consistent)
    second_consistency_thresholds <<- list(
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
    second_retention_thresholds <<- list(excellent = 2, good = 0, average = -2)
    second_consistency_thresholds <<- list(very_consistent = 2, consistent = 4, variable = 6)
  }
  
  #Weekdays Retention Performace Table
  create_weekday_retention_table <<- function() {
    if (exists("second_show_retention_summary") && nrow(second_show_retention_summary) > 0) {
      
      # Filter for weekday shows
      second_weekday_retention_data <<- second_show_retention_summary %>%
        filter(day_type == "Weekday") %>%
        filter(!grepl(paste(EXCLUDE_TERMS, collapse = "|"), second_showname, ignore.case = TRUE))
      # filter(second_stand_in != 1)
      
      if (nrow(second_weekday_retention_data) > 0) {
        
        # Create the enhanced table with grades
        second_weekday_retention_table <<- second_weekday_retention_data %>%
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
  create_weekend_retention_table <<- function() {
    if (exists("second_show_retention_summary") && nrow(second_show_retention_summary) > 0) {
      
      # Filter for weekend shows
      second_weekend_retention_data <<- second_show_retention_summary %>%
        filter(day_type == "Weekend") %>%
        filter(!grepl(paste(EXCLUDE_TERMS, collapse = "|"), second_showname, ignore.case = TRUE))
      # filter(second_stand_in != 1)
      
      if (nrow(second_weekend_retention_data) > 0) {
        
        # Create the enhanced table with grades (using same thresholds as weekday)
        second_weekend_retention_table <<- second_weekend_retention_data %>%
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
  second_weekday_retention_table <<- create_weekday_retention_table()
  second_weekend_retention_table <<- create_weekend_retention_table()
  
  cat("Retention performance tables created!\n")
  if (DEBUG_TO_CONSOLE == "Y") {
    cat("- Weekday retention table: ", nrow(second_weekday_retention_table), " shows\n")
    cat("- Weekend retention table: ", nrow(second_weekend_retention_table), " shows\n")
  }

  # Calculate hourly retention patterns across the day
  if (exists("second_episode_retention_performance") && nrow(second_episode_retention_performance) > 0) {
    
    second_hourly_retention_patterns <<- second_episode_retention_performance %>%
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
      second_hourly_retention_chart <<- ggplot(second_hourly_retention_patterns, 
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
      second_hourly_retention_chart <<- ggplot() + 
        labs(title = "No hourly retention data available") + 
        theme_void()
    }
    
  } else {
    second_hourly_retention_chart <<- ggplot() + 
      labs(title = "Retention data not available") + 
      theme_void()
  }
  
  # Create the retention performance vs variability scatter plot
  if (exists("second_show_retention_summary") && nrow(second_show_retention_summary) > 0) {
    
    second_retention_consistency_chart <<- ggplot(second_show_retention_summary, 
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
    second_retention_consistency_chart <<- ggplot() + 
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
    
    second_consistency_summary_stats <<- list()
    
    # Basic statistics
    second_consistency_summary_stats$total_shows_analyzed <<- nrow(second_show_consistency)
    second_consistency_summary_stats$total_sessions_analyzed <<- sum(second_show_consistency$second_total_sessions, na.rm = TRUE)
    second_consistency_summary_stats$avg_consistency_score <<- round(mean(second_show_consistency$second_consistency_score, na.rm = TRUE), 2)
    
    # Best and worst performers
    best_show <<- second_show_consistency %>% 
      arrange(desc(second_consistency_score)) %>% 
      slice_head(n=1)
    
    worst_show <<- second_show_consistency %>% 
      arrange(second_consistency_score) %>% 
      slice_head(n=1)
    
    second_consistency_summary_stats$most_consistent_show <<- best_show$second_showname[1]
    second_consistency_summary_stats$best_consistency_score <<- round(best_show$second_consistency_score[1], 2)
    second_consistency_summary_stats$least_consistent_show <<- worst_show$second_showname[1]
    second_consistency_summary_stats$worst_consistency_score <<- round(worst_show$second_consistency_score[1], 2)
    
    # Shows above average performance
    second_consistency_summary_stats$shows_above_avg_performance <<- sum(second_show_consistency$second_avg_performance > 0, na.rm = TRUE)
    
    cat("Second station consistency summary stats created\n")
    
  } else {
    second_consistency_summary_stats <<- list(
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
    
    second_retention_summary_stats <<- list()
    
    # Basic statistics
    second_retention_summary_stats$total_shows_analyzed <<- nrow(second_show_retention_summary)
    second_retention_summary_stats$total_broadcast_hours <<- sum(second_show_retention_summary$second_broadcast_hours, na.rm = TRUE)
    second_retention_summary_stats$avg_retention_rate <<- round(mean(second_show_retention_summary$second_avg_retention_rate, na.rm = TRUE), 1)
    
    # Best and worst retainers
    best_retainer <<- second_show_retention_summary %>% 
      arrange(desc(second_avg_retention_vs_slot)) %>% 
      slice_head(n=1)
    
    worst_retainer <<- second_show_retention_summary %>% 
      arrange(second_avg_retention_vs_slot) %>% 
      slice_head(n=1)
    
    second_retention_summary_stats$best_retainer <<- best_retainer$second_showname[1]
    second_retention_summary_stats$best_retention_score <<- round(best_retainer$second_avg_retention_vs_slot[1], 1)
    second_retention_summary_stats$worst_retainer <<- worst_retainer$second_showname[1]
    second_retention_summary_stats$worst_retention_score <<- round(worst_retainer$second_avg_retention_vs_slot[1], 1)
    
    cat("Second station retention summary stats created\n")
    
  } else {
    second_retention_summary_stats <<- list(
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
  comparison_episode_retention_raw <<- data %>%
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
  comparison_retention_hourly_baseline <<- comparison_episode_retention_raw %>%
    group_by(hour, day_type) %>%
    summarise(
      comparison_slot_avg_retention = mean(comparison_retention_rate, na.rm = TRUE),
      comparison_slot_avg_peak_gain = mean(comparison_peak_gain, na.rm = TRUE),
      comparison_slot_avg_volatility = mean(comparison_volatility, na.rm = TRUE),
      comparison_episodes_in_slot = n(),
      .groups = 'drop'
    )
  
  # Compare each episode's retention to its time slot average
  comparison_episode_retention_performance <<- comparison_episode_retention_raw %>%
    left_join(comparison_retention_hourly_baseline, by = c("hour", "day_type")) %>%
    mutate(
      comparison_retention_vs_slot = comparison_retention_rate - comparison_slot_avg_retention,
      comparison_peak_gain_vs_slot = comparison_peak_gain - comparison_slot_avg_peak_gain,
      comparison_volatility_vs_slot = comparison_volatility - comparison_slot_avg_volatility
    )
  
  # Summarize retention performance by show across all episodes
  comparison_show_retention_summary <<- comparison_episode_retention_performance %>%
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
    comparison_retention_summary_stats <<- list(
      comparison_total_shows_analyzed = nrow(comparison_show_retention_summary),
      comparison_total_episodes_analyzed = sum(comparison_show_retention_summary$comparison_broadcast_hours),
      comparison_avg_retention_rate = round(mean(comparison_show_retention_summary$comparison_avg_retention_rate, na.rm = TRUE), 1),
      comparison_best_retainer = comparison_show_retention_summary$comparison_showname[which.max(comparison_show_retention_summary$comparison_avg_retention_vs_slot)],
      comparison_best_retention_score = round(max(comparison_show_retention_summary$comparison_avg_retention_vs_slot, na.rm = TRUE), 1),
      comparison_worst_retainer = comparison_show_retention_summary$comparison_showname[which.min(comparison_show_retention_summary$comparison_avg_retention_vs_slot)],
      comparison_worst_retention_score = round(min(comparison_show_retention_summary$comparison_avg_retention_vs_slot, na.rm = TRUE), 1)
    )
  } else {
    comparison_retention_summary_stats <<- list(
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
    
    comparison_hourly_retention_patterns <<- comparison_episode_retention_performance %>%
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
      comparison_hourly_retention_chart <<- ggplot(comparison_hourly_retention_patterns, 
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
      comparison_hourly_retention_chart <<- ggplot() + 
        labs(title = "No hourly retention data available") + 
        theme_void()
    }
    
  } else {
    comparison_hourly_retention_chart <<- ggplot() + 
      labs(title = "Retention data not available") + 
      theme_void()
  }
  
  # Create the retention performance vs variability scatter plot
  if (exists("comparison_show_retention_summary") && nrow(comparison_show_retention_summary) > 0) {
    
    comparison_retention_consistency_chart <<- ggplot(comparison_show_retention_summary, 
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
    comparison_retention_consistency_chart <<- ggplot() + 
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
      retention_dist <<- table(main_show_retention_summary$main_retention_grade)
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
main_station_genre_distribution <<- data %>%
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
main_dj_genre_analysis <<- data %>%
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
main_dj_genre_summary <<- main_dj_genre_analysis %>%
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
  
  main_dj_summary_table <<- main_dj_genre_summary %>%
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
  main_dj_summary_table <<- data.frame()
  cat("No DJ genre data available for summary table\n")
}

# =============================================================================
# PART 6D: LINK DJ GENRE ANALYSIS TO RETENTION PERFORMANCE
# =============================================================================

if (exists("main_show_retention_summary") && nrow(main_show_retention_summary) > 0) {
  
  # Create DJ-to-show mapping to link genre analysis with retention data
  # This handles cases where DJ names might be in show names or presenter fields
  main_dj_show_mapping <<- main_show_retention_summary %>%
    filter(!grepl(paste(EXCLUDE_TERMS, collapse = "|"), main_showname, ignore.case = TRUE)) %>%
    mutate(
      # Extract DJ name - this might need customization based on actual data
      main_dj_name = case_when(
        # Handle specific known mappings (customize as needed)
        grepl("The Mellow Show", main_showname, ignore.case = TRUE) ~ "Gary Ziepe",
        grepl("Countdown", main_showname, ignore.case = TRUE) ~ "Rob van Dijk",
        # For most cases, assume show name is DJ name (or use presenter field if available)
        TRUE ~ main_showname
      )
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
  main_dj_genre_retention <<- main_dj_genre_summary %>%
    inner_join(main_dj_show_mapping, by = c("main_presenter" = "main_dj_name")) %>%
    mutate(
      # Round for display
      main_avg_retention_vs_slot = round(main_avg_retention_vs_slot, 1),
      main_total_broadcast_hours = round(main_total_broadcast_hours, 0)
    ) %>%
    arrange(desc(main_avg_retention_vs_slot))
  
} else {
  # Create empty dataset if retention data not available
  main_dj_genre_retention <<- data.frame()
}

# Create the Genre Strategy vs Retention Performance table
if (exists("main_dj_genre_retention") && nrow(main_dj_genre_retention) > 0) {
  
  # Create the summary table for Genre Strategy vs Retention Performance
  main_genre_strategy_retention_table <<- main_dj_genre_retention %>%
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
  main_genre_strategy_retention_table <<- data.frame()
  cat("No DJ genre-retention data available for strategy table\n")
}

# =============================================================================
# PART 6E: CREATE CHART-READY DATASETS
# =============================================================================

# Prepare data for genre heatmaps (top genres and DJs)
main_top_genres <<- main_station_genre_distribution %>%
  head(30) %>%  # Top 30 genres for chart readability
  pull(main_genre)

# DJ genre data for plotting (including station baseline)
main_dj_genre_plot_data <<- main_dj_genre_analysis %>%
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
  second_station_genre_distribution <<- data %>%
    filter(!is.na(second_genre), second_genre != "", second_genre != "-", second_genre != "Unknown") %>%
    # Exclude special programming from baseline
    filter(!grepl(paste(EXCLUDE_TERMS, collapse = "|"), second_showname, ignore.case = TRUE)) %>%
    count(second_genre) %>%
    mutate(
      second_station_pct = (n / sum(n)) * 100
    ) %>%
    arrange(desc(second_station_pct))
  
  # Calculate DJ genre distributions
  second_dj_genre_analysis <<- data %>%
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
  second_dj_genre_summary <<- second_dj_genre_analysis %>%
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
    
    second_dj_summary_table <<- second_dj_genre_summary %>%
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
    second_dj_summary_table <<- data.frame()
    cat("No DJ genre data available for summary table\n")
  }
  
  if (exists("second_show_retention_summary") && nrow(second_show_retention_summary) > 0) {
    
    # Create DJ-to-show mapping to link genre analysis with retention data
    # This handles cases where DJ names might be in show names or presenter fields
    second_dj_show_mapping <<- second_show_retention_summary %>%
      filter(!grepl(paste(EXCLUDE_TERMS, collapse = "|"), second_showname, ignore.case = TRUE)) %>%
      mutate(
        # Extract DJ name - this might need customization based on actual data
        second_dj_name = case_when(
          # Handle specific known mappings (customize as needed)
          grepl("The Mellow Show", second_showname, ignore.case = TRUE) ~ "Gary Ziepe",
          grepl("Countdown", second_showname, ignore.case = TRUE) ~ "Rob van Dijk",
          # For most cases, assume show name is DJ name (or use presenter field if available)
          TRUE ~ second_showname
        )
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
    second_dj_genre_retention <<- second_dj_genre_summary %>%
      inner_join(second_dj_show_mapping, by = c("second_presenter" = "second_dj_name")) %>%
      mutate(
        # Round for display
        second_avg_retention_vs_slot = round(second_avg_retention_vs_slot, 1),
        second_total_broadcast_hours = round(second_total_broadcast_hours, 0)
      ) %>%
      arrange(desc(second_avg_retention_vs_slot))
    
  } else {
    # Create empty dataset if retention data not available
    second_dj_genre_retention <<- data.frame()
  }
  
  # Create the Genre Strategy vs Retention Performance table
  if (exists("second_dj_genre_retention") && nrow(second_dj_genre_retention) > 0) {
    
    # Create the summary table for Genre Strategy vs Retention Performance
    second_genre_strategy_retention_table <<- second_dj_genre_retention %>%
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
    second_genre_strategy_retention_table <<- data.frame()
    cat("No DJ genre-retention data available for strategy table\n")
  }
  
  # Prepare data for genre heatmaps (top genres and DJs)
  second_top_genres <<- second_station_genre_distribution %>%
    head(30) %>%  # Top 30 genres for chart readability
    pull(second_genre)
  
  # DJ genre data for plotting (including station baseline)
  second_dj_genre_plot_data <<- second_dj_genre_analysis %>%
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
  comparison_station_genre_distribution <<- data %>%
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
    diversity_stats <<- summary(main_dj_genre_summary$main_genre_diversity_ratio)
    cat("  - Genre diversity range:", round(diversity_stats["Min."], 3), "to", round(diversity_stats["Max."], 3), "\n")
    
    # Show top 3 most similar DJs to station average
    if (nrow(main_dj_genre_summary) >= 3) {
      top_similar <<- main_dj_genre_summary %>% head(3)
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
# Originally designed for "Top 15" but now generalized for any featured show

cat("Running Analysis 7: Featured Show Analysis...\n")

# =============================================================================
# PART 7A: CHECK FEATURED SHOW CONFIGURATION
# =============================================================================

# Check if featured show variables are defined, if not set defaults
if (!exists("MAIN_FEATURED_SHOW")) {
  MAIN_FEATURED_SHOW <<- NULL  # No default - must be explicitly set
  cat("MAIN_FEATURED_SHOW not set for main station analysis\n")
}

if (ANALYSE_SECOND_STATION == "Y" && !exists("SECOND_FEATURED_SHOW")) {
  SECOND_FEATURED_SHOW <<- NULL  # No default - must be explicitly set
  cat("SECOND_FEATURED_SHOW not set for second station analysis\n")
}

if (ANALYSE_COMPARISON_STATION == "Y" && !exists("COMPARISON_FEATURED_SHOW")) {
  COMPARISON_FEATURED_SHOW <<- NULL  # No default - must be explicitly set
  cat("COMPARISON_FEATURED_SHOW not set for comparison station analysis\n")
}

# =============================================================================
# PART 7B: MAIN STATION FEATURED SHOW ANALYSIS
# =============================================================================

if (!is.null(MAIN_FEATURED_SHOW)) {
  
  cat("Analyzing main station featured show:", MAIN_FEATURED_SHOW, "\n")
  
  # Extract featured show data
  main_featured_data <<- data %>%
    filter(main_showname == MAIN_FEATURED_SHOW, ignore.case = TRUE) %>%

        filter(!is.na(main_presenter), main_presenter != "", main_presenter != "Unknown")
  
  if (nrow(main_featured_data) > 0) {
    
    # Overall performance by 5-minute intervals and weekday
    main_featured_overall_performance <<- main_featured_data %>%
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
    main_featured_dj_performance <<- main_featured_data %>%
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
    main_featured_dow_patterns <<- main_featured_data %>%
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
    main_featured_time_trends <<- main_featured_data %>%
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
      main_featured_genre_diversity <<- main_featured_data %>%
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
      main_featured_genre_diversity <<- data.frame()
    }
    
    # Featured show summary stats
    main_featured_summary_stats <<- list(
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
    main_featured_summary_stats <<- list(show_name = MAIN_FEATURED_SHOW, message = "No data available")
  }
  
  # Featured show genre analysis
  main_featured_genre_analysis <<- main_featured_data %>%
    filter(!is.na(main_genre), main_genre != "", main_genre != "Unknown", main_genre != "-") %>%
    group_by(main_genre) %>%
    summarise(
      main_plays = n(),
      main_avg_listeners = mean(main_total_listeners, na.rm = TRUE),
      .groups = 'drop'
    ) %>%
    filter(main_plays >= TOTAL_PLAYS_FILTER) %>%
    mutate(
      main_baseline = mean(main_featured_data$main_total_listeners, na.rm = TRUE),
      main_listener_impact = main_avg_listeners - main_baseline
    ) %>%
    arrange(desc(main_plays))
  
  # Featured show track analysis  
  main_featured_track_analysis <<- main_featured_data %>%
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
    second_featured_data <<- data %>%
      filter(second_showname == SECOND_FEATURED_SHOW, ignore.case = TRUE) %>%
      
      filter(!is.na(second_presenter), second_presenter != "", second_presenter != "Unknown")
    
    if (nrow(second_featured_data) > 0) {
      
      # Overall performance by 5-minute intervals and weekday
      second_featured_overall_performance <<- second_featured_data %>%
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
      second_featured_dj_performance <<- second_featured_data %>%
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
      second_featured_dow_patterns <<- second_featured_data %>%
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
      second_featured_time_trends <<- second_featured_data %>%
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
        second_featured_genre_diversity <<- second_featured_data %>%
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
        second_featured_genre_diversity <<- data.frame()
      }
      
      # Featured show summary stats
      second_featured_summary_stats <<- list(
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
      second_featured_summary_stats <<- list(show_name = SECOND_FEATURED_SHOW, message = "No data available")
    }
    
    # Featured show genre analysis
    second_featured_genre_analysis <<- second_featured_data %>%
      filter(!is.na(second_genre), second_genre != "", second_genre != "Unknown", second_genre != "-") %>%
      group_by(second_genre) %>%
      summarise(
        second_plays = n(),
        second_avg_listeners = mean(second_total_listeners, na.rm = TRUE),
        .groups = 'drop'
      ) %>%
      filter(second_plays >= TOTAL_PLAYS_FILTER) %>%
      mutate(
        second_baseline = mean(second_featured_data$second_total_listeners, na.rm = TRUE),
        second_listener_impact = second_avg_listeners - second_baseline
      ) %>%
      arrange(desc(second_plays))
    
    # Featured show track analysis  
    second_featured_track_analysis <<- second_featured_data %>%
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
  comparison_featured_data <<- data %>%
    filter(comparison_showname == COMPARISON_FEATURED_SHOW | grepl(COMPARISON_FEATURED_SHOW, comparison_showname, ignore.case = TRUE)) %>%
    filter(!is.na(comparison_presenter), comparison_presenter != "", comparison_presenter != "Unknown")
  
  if (nrow(comparison_featured_data) > 0) {
    
    # Comparison station featured show analysis (similar structure)
    comparison_featured_overall_performance <<- comparison_featured_data %>%
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
    
    comparison_featured_dj_performance <<- comparison_featured_data %>%
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
  main_track_impact_zscore <<- data %>%
    filter(!is.na(main_artist),
           main_artist != "",
           main_artist != "Unknown",
           main_artist != "-") %>%
    filter(!is.na(main_song),
           main_song != "",
           main_song != "Unknown",
           main_song != "-") %>%
    # Join with baseline statistics
    left_join(main_hourly_baseline_stats, by = c("hour", "day_type")) %>%
    # Only include observations where we have baseline stats
    filter(!is.na(main_hour_mean), !is.na(main_hour_sd), main_hour_sd > 0) %>%
    # Calculate z-score for each observation
    mutate(
      main_listener_zscore = (main_total_listeners - main_hour_mean) / main_hour_sd
    ) %>%
    # Group by track and calculate average impact
    group_by(main_artist, main_song, main_genre) %>%
    summarise(
      main_plays = n(),
      main_avg_zscore_impact = mean(main_listener_zscore, na.rm = TRUE),
      main_avg_listeners = mean(main_total_listeners, na.rm = TRUE),
      main_zscore_consistency = sd(main_listener_zscore, na.rm = TRUE),
      .groups = 'drop'
    ) %>%
    # Filter for tracks with sufficient plays
    filter(main_plays >= TOTAL_PLAYS_FILTER) %>%
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
    main_top_tracks_zscore <<- main_track_impact_zscore %>%
      filter(main_avg_zscore_impact > 0) %>%
      head(15) %>%
      mutate(
        main_avg_zscore_impact = round(main_avg_zscore_impact, 2),
        main_avg_listeners = round(main_avg_listeners, 0),
        main_zscore_consistency = round(main_zscore_consistency, 2)
      )
    
    # Bottom 15 most negative impact tracks  
    main_bottom_tracks_zscore <<- main_track_impact_zscore %>%
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
      
      main_most_played_tracks_zscore <<- main_track_impact_zscore %>%
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
      main_most_played_tracks_zscore <<- data.frame()
      cat("❌ No z-score track data available for most played analysis\n")
    }
    
    cat("✓ Z-score track impact analysis completed\n")
    cat("  - Tracks analyzed:", nrow(main_track_impact_zscore), "\n")
    cat("  - Positive impact tracks:", sum(main_track_impact_zscore$main_avg_zscore_impact > 0), "\n")
    cat("  - Negative impact tracks:", sum(main_track_impact_zscore$main_avg_zscore_impact < 0), "\n")
    
  } else {
    cat("❌ Insufficient data for z-score track impact analysis\n")
    main_top_tracks_zscore <<- data.frame()
    main_bottom_tracks_zscore <<- data.frame()
  }
  
} else {
  cat("❌ No data available for z-score track impact analysis\n")
  main_track_impact_zscore <<- data.frame()
  main_top_tracks_zscore <<- data.frame()
  main_bottom_tracks_zscore <<- data.frame()
}

# =============================================================================
# PART 8B: ARTIST IMPACT ANALYSIS
# =============================================================================

if (exists("main_hourly_baseline_stats") && nrow(main_hourly_baseline_stats) > 0) {
  
  cat("Running z-score based artist impact analysis for main station...\n")
  
  # Calculate z-scores for artist impact
  main_artist_impact_zscore <<- data %>%
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
    main_top_artists_zscore <<- main_artist_impact_zscore %>%
      filter(main_avg_zscore_impact > 0) %>%
      head(15) %>%
      mutate(
        main_avg_zscore_impact = round(main_avg_zscore_impact, 2),
        main_avg_listeners = round(main_avg_listeners, 0)
      )
    
    main_bottom_artists_zscore <<- main_artist_impact_zscore %>%
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
    main_top_artists_zscore <<- data.frame()
    main_bottom_artists_zscore <<- data.frame()
  }
  
} else {
  main_artist_impact_zscore <<- data.frame()
  main_top_artists_zscore <<- data.frame()
  main_bottom_artists_zscore <<- data.frame()
}

# =============================================================================
# PART 8C: GENRE IMPACT ANALYSIS
# =============================================================================

if (exists("main_hourly_baseline_stats") && nrow(main_hourly_baseline_stats) > 0) {
  
  cat("Running z-score based genre impact analysis for main station...\n")
  
  # Calculate z-scores for genre impact
  main_genre_impact_zscore <<- data %>%
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
    main_top_genres_zscore <<- main_genre_impact_zscore %>%
      filter(main_avg_zscore_impact > 0) %>%
      head(10) %>%
      mutate(
        main_avg_zscore_impact = round(main_avg_zscore_impact, 2),
        main_avg_listeners = round(main_avg_listeners, 0)
      )
    
    main_bottom_genres_zscore <<- main_genre_impact_zscore %>%
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
    main_top_genres_zscore <<- data.frame()
    main_bottom_genres_zscore <<- data.frame()
  }
  
} else {
  main_genre_impact_zscore <<- data.frame()
  main_top_genres_zscore <<- data.frame()
  main_bottom_genres_zscore <<- data.frame()
}

# =============================================================================
# PART 8D: BEST & WORST PERFORMING GENRES BY HOUR
# =============================================================================

if (exists("main_hourly_baseline_stats") && nrow(main_hourly_baseline_stats) > 0) {
  
  cat("Running z-score based hourly genre performance analysis for main station...\n")
  
  # Calculate z-scores for genre performance by hour
  main_hourly_genre_zscore <<- data %>%
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
  main_hourly_genre_zscore <<- data.frame()
}

if (exists("main_hourly_baseline_stats") && nrow(main_hourly_baseline_stats) > 0) {
  
  cat("Running z-score based hourly genre heatmap analysis for main station...\n")
  
  # Calculate z-scores for ALL genre-hour combinations for heatmap
  main_genre_hour_heatmap_zscore <<- data %>%
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
  top_genres <<- main_genre_hour_heatmap_zscore %>%
    group_by(main_genre) %>%
    summarise(total_plays = sum(main_plays), .groups = 'drop') %>%
    arrange(desc(total_plays)) %>%
    head(15) %>%
    pull(main_genre)
  
  # Filter for top genres and reasonable hours
  main_genre_hour_heatmap_zscore <<- main_genre_hour_heatmap_zscore %>%
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
  main_genre_hour_heatmap_zscore <<- data.frame()
}

# =============================================================================
# PART 8E: SITTING-IN VS REGULAR DJ ANALYSIS
# =============================================================================

# Step 1: Identify sitting-in presenters using the stand_in column
main_sitting_in_data <<- data %>%
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
  main_regular_shows_lookup <<- data %>%
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
    slice_head(n=1) %>%  # Take first if tied
    ungroup() %>%
    select(timeslot_key, weekday, hour, minute, 
           regular_showname = main_showname, regular_presenter = main_presenter, 
           regular_appearances = main_appearances, regular_avg_listeners = main_avg_listeners)
  
  # Step 3: Create sitting-in vs regular comparisons
  main_sitting_in_comparisons <<- main_sitting_in_data %>%
    inner_join(main_regular_shows_lookup, by = "timeslot_key") %>%
    filter(sitting_in_presenter != regular_presenter) %>%  # Ensure different presenters
    filter(regular_appearances >= 1) %>%  # Regular show must have appeared multiple times
    mutate(
      main_pct_difference = ((main_total_listeners - regular_avg_listeners) / regular_avg_listeners) * 100
    )
  
  # Step 4: Summarize sitting-in performance by show
  if (nrow(main_sitting_in_comparisons) > 0) {
    main_sitting_in_show_summary <<- main_sitting_in_comparisons %>%
      group_by(regular_showname, regular_presenter, sitting_in_presenter) %>%
      summarise(
        main_episodes_compared = round(n() / HOUR_NORMALISATION, 0),  # This is "timeslots_compared" equivalent
        main_avg_pct_difference = mean(main_pct_difference, na.rm = TRUE),
        main_median_pct_difference = median(main_pct_difference, na.rm = TRUE),
        main_best_performance = max(main_pct_difference, na.rm = TRUE),
        main_worst_performance = min(main_pct_difference, na.rm = TRUE),
        main_sitting_in_wins = round((sum(main_pct_difference > 0)/ (sum(main_pct_difference > 0) + sum(main_pct_difference < 0))) * 100, 0),
        main_regular_wins = round((sum(main_pct_difference < 0)/ (sum(main_pct_difference > 0) + sum(main_pct_difference < 0))) * 100, 0),
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
    main_sitting_in_show_summary <<- data.frame()
  }
} else {
  main_sitting_in_comparisons <<- data.frame()
  main_sitting_in_show_summary <<- data.frame()
}

if (exists("main_sitting_in_show_summary") && 
    is.data.frame(main_sitting_in_show_summary) && 
    nrow(main_sitting_in_show_summary) > 0) {
  MAIN_SITTING_IN_EXISTS <<- TRUE
  cat("✓ Main station sitting-in vs regular analysis results available for report\n")
} else {
  MAIN_SITTING_IN_EXISTS <<- FALSE
  cat("❌ Main station sitting-in vs regular analysis - no results for report\n")
}

# =============================================================================
# PART 8F: LIVE VS PRE-RECORDED IMPACT ANALYSIS
# =============================================================================

# Step 1: Filter to time slots that have BOTH live and recorded shows with sufficient data
main_valid_timeslots <<- data %>%
  filter(!is.na(main_recorded), main_recorded %in% c(0, 1)) %>%
  group_by(hour, day_type, main_live_recorded) %>%
  summarise(main_sessions = n(), .groups = "drop") %>%
  # Only keep time slots where BOTH live and pre-recorded have ≥3 sessions
  group_by(hour, day_type) %>%
  filter(n() == 2, all(main_sessions >= 3)) %>%  # Must have exactly 2 types (Live + Pre-recorded), both with ≥3 sessions
  select(hour, day_type) %>%
  distinct()

# Step 2: Calculate live vs recorded performance for valid time slots only
main_live_recorded_analysis <<- data %>%
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
  main_lr_hourly_baseline <<- main_live_recorded_analysis %>%
    group_by(hour, day_type) %>%
    summarise(
      main_hour_avg = mean(main_avg_listeners),  # Simple average of live and pre-recorded
      .groups = 'drop'
    )
  
  main_live_recorded_performance <<- main_live_recorded_analysis %>%
    left_join(main_lr_hourly_baseline, by = c("hour", "day_type")) %>%
    mutate(
      main_pct_vs_hour = ((main_avg_listeners - main_hour_avg) / main_hour_avg) * 100
    )
  
  # Summary statistics
  main_live_recorded_summary <<- main_live_recorded_performance %>%
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
  main_live_recorded_summary <<- data.frame()
}

# Set flag based on results for main station
if (exists("main_live_recorded_summary") && 
    is.data.frame(main_live_recorded_summary) && 
    nrow(main_live_recorded_summary) > 0) {
  MAIN_LIVE_RECORDED_EXISTS <<- TRUE
  cat("✓ Main station live vs pre-recorded analysis results available for report\n")
} else {
  MAIN_LIVE_RECORDED_EXISTS <<- FALSE
  cat("❌ Main station live vs pre-recorded analysis - no results for report\n")
}

# DJ LIVE VS PRE-RECORDED INDIVIDUAL ANALYSIS
# Filter for main station data and get valid time slots
cat("Checking main station live vs pre-recorded data availability...\n")

# Check data availability upfront
main_available_types <<- data %>%
  filter(!is.na(main_recorded), main_recorded %in% c(0, 1)) %>%
  distinct(main_live_recorded) %>%
  pull(main_live_recorded)

if (length(main_available_types) < 2) {
  cat("Main station: Live vs Pre-recorded analysis skipped - only", 
      paste(main_available_types, collapse = ", "), "shows available\n")
  main_dj_live_recorded_analysis <<- data.frame()
  MAIN_DJ_LIVE_RECORDED_EXISTS <<- FALSE
} else {
  cat("Main station: Both live and pre-recorded shows available - proceeding with analysis\n")
  
  # Filter for main station data and get valid time slots
  main_dj_live_recorded_analysis <<- data %>%
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
    group_by(main_showname, main_presenter, main_live_recorded) %>%
    summarise(
      main_avg_listeners = mean(main_total_listeners, na.rm = TRUE),
      main_avg_performance = mean(main_pct_vs_hour, na.rm = TRUE),
      main_sessions = n(),
      .groups = "drop"
    ) %>%
    # Only keep DJs with sufficient data - and ensure showname matches presenter
    filter(main_sessions >= 3, main_showname == main_presenter) %>%
    # Check which DJs have both live and pre-recorded data
    group_by(main_showname, main_presenter) %>%
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
    # Round numbers for display and convert sessions to hours
    mutate(
      `main_avg_performance_Live` = round(`main_avg_performance_Live`, 1),
      `main_avg_performance_Pre-recorded` = round(`main_avg_performance_Pre-recorded`, 1),
      main_performance_difference = round(main_performance_difference, 1),
      `main_avg_listeners_Live` = round(`main_avg_listeners_Live`, 0),
      `main_avg_listeners_Pre-recorded` = round(`main_avg_listeners_Pre-recorded`, 0),
      `main_sessions_Live` = round(`main_sessions_Live` / HOUR_NORMALISATION, 0),
      `main_sessions_Pre-recorded` = round(`main_sessions_Pre-recorded` / HOUR_NORMALISATION, 0)
    ) %>%
    # Select columns for the table
    select(main_showname, `main_sessions_Live`, `main_sessions_Pre-recorded`, 
           `main_avg_performance_Live`, `main_avg_performance_Pre-recorded`, main_performance_difference,
           `main_avg_listeners_Live`, `main_avg_listeners_Pre-recorded`, main_better_when)
  
  # Set flag based on results
  if (exists("main_dj_live_recorded_analysis") && 
      is.data.frame(main_dj_live_recorded_analysis) && 
      nrow(main_dj_live_recorded_analysis) > 0) {
    MAIN_DJ_LIVE_RECORDED_EXISTS <<- TRUE
    cat("✓ Main station DJ live vs pre-recorded analysis results available for report\n")
  } else {
    MAIN_DJ_LIVE_RECORDED_EXISTS <<- FALSE
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
# PART 8G: GENERALIZED IMPACT ANALYSIS FRAMEWORK
# =============================================================================

# This framework can be used for any binary condition (e.g., Public Holidays)
create_impact_analysis <<- function(data_df, condition_column, condition_value, condition_name, station_prefix = "main") {
  
  # Create column names dynamically
  total_listeners_col <<- paste0(station_prefix, "_total_listeners")
  
  # Check if condition column exists
  if (!condition_column %in% names(data_df)) {
    cat("Warning: Column", condition_column, "not found. Skipping", condition_name, "analysis.\n")
    return(data.frame())
  }
  
  # Filter and analyze
  impact_data <<- data_df %>%
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
    impact_summary <<- impact_data %>%
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
# PART 8H: PUBLIC HOLIDAY IMPACT
# =============================================================================

main_public_holiday_impact <<- create_impact_analysis(
  data, 
  "public_holiday", 
  1, 
  "Public Holiday",
  "main"
)
  
  PUBLIC_HOLIDAY_IMPACT_EXISTS <<- FALSE
  
  # Check if Public Holiday impact analysis has results
  if (exists("main_public_holiday_impact") && 
      is.list(main_public_holiday_impact) && 
      "summary" %in% names(main_public_holiday_impact) && 
      nrow(main_public_holiday_impact$summary) > 0) {
    PUBLIC_HOLIDAY_IMPACT_EXISTS <<- TRUE
    cat("✓ Public Holiday impact analysis results available for report\n")
  } else {
    cat("❌ Public Holiday impact analysis - no results for report\n")
  }
  
  if (DEBUG_TO_CONSOLE == "Y") {
    cat("Public Holiday report flag:\n")
    cat("  - PUBLIC_HOLIDAY_IMPACT_EXISTS:", PUBLIC_HOLIDAY_IMPACT_EXISTS, "\n")
  }

# =============================================================================
# PART 8I: SECOND STATION IMPACT ANALYSES (IF ENABLED)
# =============================================================================

if (ANALYSE_SECOND_STATION == "Y") {

  if (exists("data") && nrow(data) > 0) {
    
    cat("Running z-score based track impact analysis for second station...\n")
    
    # Step 1: Calculate z-scores for track impact
    second_track_impact_zscore <<- data %>%
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
      second_top_tracks_zscore <<- second_track_impact_zscore %>%
        filter(second_avg_zscore_impact > 0) %>%
        head(15) %>%
        mutate(
          second_avg_zscore_impact = round(second_avg_zscore_impact, 2),
          second_avg_listeners = round(second_avg_listeners, 0),
          second_zscore_consistency = round(second_zscore_consistency, 2)
        )
      
      # Bottom 15 most negative impact tracks  
      second_bottom_tracks_zscore <<- second_track_impact_zscore %>%
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
        
        second_most_played_tracks_zscore <<- second_track_impact_zscore %>%
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
        second_most_played_tracks_zscore <<- data.frame()
        cat("❌ No z-score track data available for most played analysis\n")
      }
      
      cat("✓ Z-score track impact analysis completed\n")
      cat("  - Tracks analyzed:", nrow(second_track_impact_zscore), "\n")
      cat("  - Positive impact tracks:", sum(second_track_impact_zscore$second_avg_zscore_impact > 0), "\n")
      cat("  - Negative impact tracks:", sum(second_track_impact_zscore$second_avg_zscore_impact < 0), "\n")
      
    } else {
      cat("❌ Insufficient data for z-score track impact analysis\n")
      second_top_tracks_zscore <<- data.frame()
      second_bottom_tracks_zscore <<- data.frame()
    }
    
  } else {
    cat("❌ No data available for z-score track impact analysis\n")
    second_track_impact_zscore <<- data.frame()
    second_top_tracks_zscore <<- data.frame()
    second_bottom_tracks_zscore <<- data.frame()
  }

  if (exists("second_hourly_baseline_stats") && nrow(second_hourly_baseline_stats) > 0) {
    
    cat("Running z-score based artist impact analysis for second station...\n")
    
    # Calculate z-scores for artist impact
    second_artist_impact_zscore <<- data %>%
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
      second_top_artists_zscore <<- second_artist_impact_zscore %>%
        filter(second_avg_zscore_impact > 0) %>%
        head(15) %>%
        mutate(
          second_avg_zscore_impact = round(second_avg_zscore_impact, 2),
          second_avg_listeners = round(second_avg_listeners, 0)
        )
      
      second_bottom_artists_zscore <<- second_artist_impact_zscore %>%
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
      second_top_artists_zscore <<- data.frame()
      second_bottom_artists_zscore <<- data.frame()
    }
    
  } else {
    second_artist_impact_zscore <<- data.frame()
    second_top_artists_zscore <<- data.frame()
    second_bottom_artists_zscore <<- data.frame()
  }
  
  if (exists("second_hourly_baseline_stats") && nrow(second_hourly_baseline_stats) > 0) {
    
    cat("Running z-score based genre impact analysis for second station...\n")
    
    # Calculate z-scores for genre impact
    second_genre_impact_zscore <<- data %>%
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
      second_top_genres_zscore <<- second_genre_impact_zscore %>%
        filter(second_avg_zscore_impact > 0) %>%
        head(10) %>%
        mutate(
          second_avg_zscore_impact = round(second_avg_zscore_impact, 2),
          second_avg_listeners = round(second_avg_listeners, 0)
        )
      
      second_bottom_genres_zscore <<- second_genre_impact_zscore %>%
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
      second_top_genres_zscore <<- data.frame()
      second_bottom_genres_zscore <<- data.frame()
    }
    
  } else {
    second_genre_impact_zscore <<- data.frame()
    second_top_genres_zscore <<- data.frame()
    second_bottom_genres_zscore <<- data.frame()
  }
  
  if (exists("second_hourly_baseline_stats") && nrow(second_hourly_baseline_stats) > 0) {
    
    cat("Running z-score based hourly genre performance analysis for second station...\n")
    
    # Calculate z-scores for genre performance by hour
    second_hourly_genre_zscore <<- data %>%
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
    second_hourly_genre_zscore <<- data.frame()
  }
  
  if (exists("second_hourly_baseline_stats") && nrow(second_hourly_baseline_stats) > 0) {
    
    cat("Running z-score based hourly genre heatmap analysis for second station...\n")
    
    # Calculate z-scores for ALL genre-hour combinations for heatmap
    second_genre_hour_heatmap_zscore <<- data %>%
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
    top_genres <<- second_genre_hour_heatmap_zscore %>%
      group_by(second_genre) %>%
      summarise(total_plays = sum(second_plays), .groups = 'drop') %>%
      arrange(desc(total_plays)) %>%
      head(15) %>%
      pull(second_genre)
    
    # Filter for top genres and reasonable hours
    second_genre_hour_heatmap_zscore <<- second_genre_hour_heatmap_zscore %>%
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
    second_genre_hour_heatmap_zscore <<- data.frame()
  }

  # Step 1: Identify sitting-in presenters using the stand_in column
  second_sitting_in_data <<- data %>%
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
    second_regular_shows_lookup <<- data %>%
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
      slice_head(n=1) %>%  # Take first if tied
      ungroup() %>%
      select(timeslot_key, weekday, hour, minute, 
             regular_showname = second_showname, regular_presenter = second_presenter, 
             regular_appearances = second_appearances, regular_avg_listeners = second_avg_listeners)
    
    # Step 3: Create sitting-in vs regular comparisons
    second_sitting_in_comparisons <<- second_sitting_in_data %>%
      inner_join(second_regular_shows_lookup, by = "timeslot_key") %>%
      filter(sitting_in_presenter != regular_presenter) %>%  # Ensure different presenters
      filter(regular_appearances >= 1) %>%  # Regular show must have appeared multiple times
      mutate(
        second_pct_difference = ((second_total_listeners - regular_avg_listeners) / regular_avg_listeners) * 100
      )
    
    # Step 4: Summarize sitting-in performance by show
    if (nrow(second_sitting_in_comparisons) > 0) {
      second_sitting_in_show_summary <<- second_sitting_in_comparisons %>%
        group_by(regular_showname, regular_presenter, sitting_in_presenter) %>%
        summarise(
          second_episodes_compared =round(n() / HOUR_NORMALISATION, 0),  # This is "timeslots_compared" equivalent
          second_avg_pct_difference = mean(second_pct_difference, na.rm = TRUE),
          second_median_pct_difference = median(second_pct_difference, na.rm = TRUE),
          second_best_performance = max(second_pct_difference, na.rm = TRUE),
          second_worst_performance = min(second_pct_difference, na.rm = TRUE),
          second_sitting_in_wins = round((sum(second_pct_difference > 0)/ (sum(second_pct_difference > 0) + sum(second_pct_difference < 0))) * 100, 0),
          second_regular_wins = round((sum(second_pct_difference < 0)/ (sum(second_pct_difference > 0) + sum(second_pct_difference < 0))) * 100, 0),
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
      second_sitting_in_show_summary <<- data.frame()
    }
  } else {
    second_sitting_in_comparisons <<- data.frame()
    second_sitting_in_show_summary <<- data.frame()
  }
  
  if (ANALYSE_SECOND_STATION == "Y") {
    if (exists("second_sitting_in_show_summary") && 
        is.data.frame(second_sitting_in_show_summary) && 
        nrow(second_sitting_in_show_summary) > 0) {
      SECOND_SITTING_IN_EXISTS <<- TRUE
      cat("✓ Second station sitting-in vs regular analysis results available for report\n")
    } else {
      SECOND_SITTING_IN_EXISTS <<- FALSE
      cat("❌ Second station sitting-in vs regular analysis - no results for report\n")
    }
  } else {
    SECOND_SITTING_IN_EXISTS <<- FALSE
  }
  
  if (DEBUG_TO_CONSOLE == "Y") {
    cat("Sitting-in analysis report flags:\n")
    cat("  - MAIN_SITTING_IN_EXISTS:", MAIN_SITTING_IN_EXISTS, "\n")
    if (ANALYSE_SECOND_STATION == "Y") {
      cat("  - SECOND_SITTING_IN_EXISTS:", SECOND_SITTING_IN_EXISTS, "\n")
    }
  }
  
  # Step 1: Filter to time slots that have BOTH live and recorded shows with sufficient data
  second_valid_timeslots <<- data %>%
    filter(!is.na(second_recorded), second_recorded %in% c(0, 1)) %>%
    group_by(hour, day_type, second_live_recorded) %>%
    summarise(second_sessions = n(), .groups = "drop") %>%
    # Only keep time slots where BOTH live and pre-recorded have ≥3 sessions
    group_by(hour, day_type) %>%
    filter(n() == 2, all(second_sessions >= 3)) %>%  # Must have exactly 2 types (Live + Pre-recorded), both with ≥3 sessions
    select(hour, day_type) %>%
    distinct()
  
  # Step 2: Calculate live vs recorded performance for valid time slots only
  second_live_recorded_analysis <<- data %>%
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
    second_lr_hourly_baseline <<- second_live_recorded_analysis %>%
      group_by(hour, day_type) %>%
      summarise(
        second_hour_avg = mean(second_avg_listeners),  # Simple average of live and pre-recorded
        .groups = 'drop'
      )
    
    second_live_recorded_performance <<- second_live_recorded_analysis %>%
      left_join(second_lr_hourly_baseline, by = c("hour", "day_type")) %>%
      mutate(
        second_pct_vs_hour = ((second_avg_listeners - second_hour_avg) / second_hour_avg) * 100
      )
    
    # Summary statistics
    second_live_recorded_summary <<- second_live_recorded_performance %>%
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
    second_live_recorded_summary <<- data.frame()
  }
  
  if (ANALYSE_SECOND_STATION == "Y") {
    if (exists("second_live_recorded_summary") && 
        is.data.frame(second_live_recorded_summary) && 
        nrow(second_live_recorded_summary) > 0) {
      SECOND_LIVE_RECORDED_EXISTS <<- TRUE
      cat("✓ Second station live vs pre-recorded analysis results available for report\n")
    } else {
      SECOND_LIVE_RECORDED_EXISTS <<- FALSE
      cat("❌ Second station live vs pre-recorded analysis - no results for report\n")
    }
  } else {
    SECOND_LIVE_RECORDED_EXISTS <<- FALSE
  }
  
  if (DEBUG_TO_CONSOLE == "Y") {
    cat("Live vs pre-recorded analysis report flags:\n")
    cat("  - MAIN_LIVE_RECORDED_EXISTS:", MAIN_LIVE_RECORDED_EXISTS, "\n")
    if (ANALYSE_SECOND_STATION == "Y") {
      cat("  - SECOND_LIVE_RECORDED_EXISTS:", SECOND_LIVE_RECORDED_EXISTS, "\n")
    }
  }
  

  # DJ LIVE VS PRE-RECORDED INDIVIDUAL ANALYSIS
  # Filter for second station data and get valid time slots
  cat("Checking second station live vs pre-recorded data availability...\n")
  
  # Check data availability upfront
  second_available_types <<- data %>%
    filter(!is.na(second_recorded), second_recorded %in% c(0, 1)) %>%
    distinct(second_live_recorded) %>%
    pull(second_live_recorded)
  
  if (length(second_available_types) < 2) {
    cat("Second station: Live vs Pre-recorded analysis skipped - only", 
        paste(second_available_types, collapse = ", "), "shows available\n")
    second_dj_live_recorded_analysis <<- data.frame()
    SECOND_DJ_LIVE_RECORDED_EXISTS <<- FALSE
  } else {
    cat("Second station: Both live and pre-recorded shows available - proceeding with analysis\n")
    
    # Filter for main station data and get valid time slots
    second_dj_live_recorded_analysis <<- data %>%
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
      group_by(second_showname, second_presenter, second_live_recorded) %>%
      summarise(
        second_avg_listeners = mean(second_total_listeners, na.rm = TRUE),
        second_avg_performance = mean(second_pct_vs_hour, na.rm = TRUE),
        second_sessions = n(),
        .groups = "drop"
      ) %>%
      # Only keep DJs with sufficient data - and ensure showname matches presenter
      filter(second_sessions >= 3, second_showname == second_presenter) %>%
      # Check which DJs have both live and pre-recorded data
      group_by(second_showname, second_presenter) %>%
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
      # Round numbers for display and convert sessions to hours
      mutate(
        `second_avg_performance_Live` = round(`second_avg_performance_Live`, 1),
        `second_avg_performance_Pre-recorded` = round(`second_avg_performance_Pre-recorded`, 1),
        second_performance_difference = round(second_performance_difference, 1),
        `second_avg_listeners_Live` = round(`second_avg_listeners_Live`, 0),
        `second_avg_listeners_Pre-recorded` = round(`second_avg_listeners_Pre-recorded`, 0),
        `second_sessions_Live` = round(`second_sessions_Live` / HOUR_NORMALISATION, 0),
        `second_sessions_Pre-recorded` = round(`second_sessions_Pre-recorded` / HOUR_NORMALISATION, 0)
      ) %>%
      # Select columns for the table
      select(second_showname, `second_sessions_Live`, `second_sessions_Pre-recorded`, 
             `second_avg_performance_Live`, `second_avg_performance_Pre-recorded`, second_performance_difference,
             `second_avg_listeners_Live`, `second_avg_listeners_Pre-recorded`, second_better_when)
    
    # Set flag based on results
    if (exists("second_dj_live_recorded_analysis") && 
        is.data.frame(second_dj_live_recorded_analysis) && 
        nrow(second_dj_live_recorded_analysis) > 0) {
      SECOND_DJ_LIVE_RECORDED_EXISTS <<- TRUE
      cat("✓ Second station DJ live vs pre-recorded analysis results available for report\n")
    } else {
      SECOND_DJ_LIVE_RECORDED_EXISTS <<- FALSE
      cat("❌ MSeconfdtation DJ live vs pre-recorded analysis - no results for report\n")
    }
  }
  
  if (DEBUG_TO_CONSOLE == "Y") {
    cat("Second station DJ live vs pre-recorded report flag:\n")
    cat("  - SECOND_DJ_LIVE_RECORDED_EXISTS:", SECOND_DJ_LIVE_RECORDED_EXISTS, "\n")
    if (SECOND_DJ_LIVE_RECORDED_EXISTS) {
      cat("  - Number of DJs analyzed:", nrow(second_dj_live_recorded_analysis), "\n")
    }
  }
  
  # This framework can be used for any binary condition (e.g., Public Holidays)
  create_impact_analysis <<- function(data_df, condition_column, condition_value, condition_name, station_prefix = "second") {
    
    # Create column names dynamically
    total_listeners_col <<- paste0(station_prefix, "_total_listeners")
    
    # Check if condition column exists
    if (!condition_column %in% names(data_df)) {
      cat("Warning: Column", condition_column, "not found. Skipping", condition_name, "analysis.\n")
      return(data.frame())
    }
    
    # Filter and analyze
    impact_data <<- data_df %>%
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
      impact_summary <<- impact_data %>%
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
  
  # Use the generic function for second station public holiday analysis
  second_public_holiday_impact <<- create_impact_analysis(
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
    SECOND_PUBLIC_HOLIDAY_IMPACT_EXISTS <<- TRUE
    cat("✓ Second station public holiday impact analysis results available for report\n")
  } else {
    SECOND_PUBLIC_HOLIDAY_IMPACT_EXISTS <<- FALSE
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
# PART 8J: COMPLETE GENRE-ARTIST CLASSIFICATION ANALYSIS
# =============================================================================
  
cat("Running Genre-Artist Classification Analysis...\n")
  
# =============================================================================
# MAIN STATION GENRE-ARTIST ANALYSIS
# =============================================================================
  
if ("main_genre" %in% names(data) && "main_artist" %in% names(data)) {
    
  main_genre_artist_analysis <<- data %>%
    filter(!is.na(main_genre), main_genre != "", main_genre != "Unknown", main_genre != "-") %>%
    filter(!is.na(main_artist), main_artist != "", main_artist != "Unknown") %>%
    group_by(main_genre, main_artist) %>%
    summarise(
      main_plays = n(),
      main_avg_listeners = mean(main_total_listeners, na.rm = TRUE),
      .groups = 'drop'
    ) %>%
    # Keep only artists with at least 2 plays in each genre
    filter(main_plays >= TOTAL_PLAYS_FILTER) %>%
    # Create rankings within each genre
    group_by(main_genre) %>%
    arrange(desc(main_plays), desc(main_avg_listeners)) %>%
    mutate(
      main_artist_rank = row_number(),
      main_genre_total_plays = sum(main_plays)
    ) %>%
    ungroup()
    
    # Create summary table with top 5 artists per genre
    main_genre_artist_summary <<- main_genre_artist_analysis %>%
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
    
    cat("Second station: Created genre-artist analysis for", nrow(main_genre_artist_summary), "genres\n")
    
  } else {
    main_genre_artist_summary <<- data.frame()
    cat("Second station: No genre/artist data available\n")
  }
  
  # =============================================================================
  # SECOND STATION GENRE-ARTIST ANALYSIS (IF ENABLED)
  # =============================================================================
  
  if (ANALYSE_SECOND_STATION == "Y" && "second_genre" %in% names(data) && "second_artist" %in% names(data)) {
    
    second_genre_artist_analysis <<- data %>%
      filter(!is.na(second_genre), second_genre != "", second_genre != "Unknown", second_genre != "-") %>%
      filter(!is.na(second_artist), second_artist != "", second_artist != "Unknown") %>%
      group_by(second_genre, second_artist) %>%
      summarise(
        second_plays = n(),
        second_avg_listeners = mean(second_total_listeners, na.rm = TRUE),
        .groups = 'drop'
      ) %>%
      # Keep only artists with at least 2 plays in each genre
      filter(second_plays >= TOTAL_PLAYS_FILTER) %>%
      # Create rankings within each genre
      group_by(second_genre) %>%
      arrange(desc(second_plays), desc(second_avg_listeners)) %>%
      mutate(
        second_artist_rank = row_number(),
        second_genre_total_plays = sum(second_plays)
      ) %>%
      ungroup()
    
    # Create summary table with top 5 artists per genre
    second_genre_artist_summary <<- second_genre_artist_analysis %>%
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
    second_genre_artist_summary <<- data.frame()
    if (ANALYSE_SECOND_STATION == "Y") {
      cat("Second station: No genre/artist data available\n")
    }
  }
  
  # =============================================================================
  # COMPARISON STATION GENRE-ARTIST ANALYSIS (IF ENABLED)
  # =============================================================================
  
  if (ANALYSE_COMPARISON_STATION == "Y" && "comparison_genre" %in% names(data) && "comparison_artist" %in% names(data)) {
    
    comparison_genre_artist_analysis <<- data %>%
      filter(!is.na(comparison_genre), comparison_genre != "", comparison_genre != "Unknown", comparison_genre != "-") %>%
      filter(!is.na(comparison_artist), comparison_artist != "", comparison_artist != "Unknown") %>%
      group_by(comparison_genre, comparison_artist) %>%
      summarise(
        comparison_plays = n(),
        comparison_avg_listeners = mean(comparison_total_listeners, na.rm = TRUE),
        .groups = 'drop'
      ) %>%
      filter(comparison_plays >= TOTAL_PLAYS_FILTER) %>%
      group_by(comparison_genre) %>%
      arrange(desc(comparison_plays), desc(comparison_avg_listeners)) %>%
      mutate(
        comparison_artist_rank = row_number(),
        comparison_genre_total_plays = sum(comparison_plays)
      ) %>%
      ungroup()
    
    comparison_genre_artist_summary <<- comparison_genre_artist_analysis %>%
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
    comparison_genre_artist_summary <<- data.frame()
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
weather_columns <<- c("weather_temp", "weather_condition", "weather_rain", "sunrise_time", "sunset_time")
missing_columns <<- weather_columns[!weather_columns %in% names(data)]

if (length(missing_columns) > 0) {
  cat("Warning: Missing weather columns:", paste(missing_columns, collapse = ", "), "\n")
  cat("Weather analysis will be limited or skipped.\n")
  
  # Create empty results for missing data
  main_weather_summary_stats <<- list(
    analysis_available = FALSE,
    missing_columns = missing_columns,
    message = "Weather data not available in dataset"
  )
  
} else {
  
  # =============================================================================
  # PART 9B: PREPARE WEATHER DATA
  # =============================================================================
  
  # Clean and prepare weather data
  main_weather_data <<- data %>%
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
  main_weather_summary <<- main_weather_data %>%
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
    main_weather_summary <<- main_weather_summary %>%
      mutate(
        second_overall_baseline = mean(main_weather_data$second_total_listeners, na.rm = TRUE),
        second_vs_baseline = ((second_avg_listeners - second_overall_baseline) / second_overall_baseline) * 100
      )
  }
  
  # =============================================================================
  # PART 9D: TEMPERATURE IMPACT ANALYSIS
  # =============================================================================
  
  main_temperature_impact <<- main_weather_data %>%
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
  main_weekend_weather <<- main_weather_data %>%
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
    main_weekend_weather <<- main_weekend_weather %>%
      mutate(
        second_weekend_baseline = mean(second_avg_listeners, na.rm = TRUE),
        second_weekend_impact = ((second_avg_listeners - second_weekend_baseline) / second_weekend_baseline) * 100
      )
  }
  
  # =============================================================================
  # PART 9F: DAYLIGHT VS DARKNESS LISTENING
  # =============================================================================
  
  main_daylight_analysis <<- main_weather_data %>%
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
  
  main_rain_impact <<- main_weather_data %>%
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
  
  main_seasonal_trends <<- main_weather_data %>%
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
  
  main_weather_summary_stats <<- list(
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
  second_weather_summary <<- main_weather_data %>%
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
  
  comparison_weather_summary <<- main_weather_data %>%
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
  combined_weather_summary <<- data.frame()
  
  # Main station data (always included)
  main_for_combined <<- main_weather_summary %>%
    filter(!is.na(weather_category)) %>%
    select(weather_category, main_avg_listeners, main_vs_baseline, main_observations) %>%
    rename(avg_listeners = main_avg_listeners, 
           vs_baseline = main_vs_baseline,
           observations = main_observations) %>%
    mutate(station = MAIN_STATION_NAME)
  
  combined_weather_summary <<- rbind(combined_weather_summary, main_for_combined)
  
  # Second station data (if enabled) - get from main_weather_summary, not second_weather_summary
  if (ANALYSE_SECOND_STATION == "Y" && "second_avg_listeners" %in% names(main_weather_summary)) {
    second_for_combined <<- main_weather_summary %>%
      filter(!is.na(weather_category), !is.na(second_avg_listeners)) %>%
      select(weather_category, second_avg_listeners, second_vs_baseline, main_observations) %>%
      rename(avg_listeners = second_avg_listeners, 
             vs_baseline = second_vs_baseline,
             observations = main_observations) %>%  # Use same observations count
      mutate(station = SECOND_STATION_NAME)
    
    combined_weather_summary <<- rbind(combined_weather_summary, second_for_combined)
  }
  
  # Comparison station data (if enabled and exists as separate summary)
  # Comparison station data (if enabled and exists as separate summary)
  if (ANALYSE_COMPARISON_STATION == "Y" && exists("comparison_weather_summary") && nrow(comparison_weather_summary) > 0) {
    comparison_filtered <<- comparison_weather_summary %>%
      filter(!is.na(weather_category))

    comparison_for_combined <<- comparison_filtered %>%
      select(weather_category, comparison_avg_listeners, comparison_vs_baseline, comparison_observations) %>%
      rename(avg_listeners = comparison_avg_listeners, 
             vs_baseline = comparison_vs_baseline,
             observations = comparison_observations) %>%
      mutate(station = COMPARISON_STATION_NAME)
    
    combined_weather_summary <<- rbind(combined_weather_summary, comparison_for_combined)
  }
  
  # Then continue with the final cleanup section...
  # Final cleanup
  combined_weather_summary <<- combined_weather_summary %>%
    filter(!is.na(weather_category),     # Remove any remaining NAs
           !is.na(vs_baseline),          # Remove NAs in the impact calculations
           !is.na(avg_listeners),        # Remove NAs in listener data
           weather_category != "",        # Remove empty categories
           observations >= 50)            # Ensure sufficient data
  
  # Final cleanup
  combined_weather_summary <<- combined_weather_summary %>%
    filter(!is.na(weather_category),     # Remove any remaining NAs
           !is.na(vs_baseline),          # Remove NAs in the impact calculations
           !is.na(avg_listeners),        # Remove NAs in listener data
           weather_category != "",        # Remove empty categories
           observations >= 50)            # Ensure sufficient data
  
  # Create combined temperature analysis for all enabled stations
  combined_temp_analysis <<- data.frame()
  
  if (exists("main_weather_data")) {
    # Main station temperature data
    main_temp_data <<- main_weather_data %>%
      select(temp_category, main_total_listeners) %>%
      rename(total_listeners = main_total_listeners) %>%
      mutate(station = MAIN_STATION_NAME) %>%
      filter(!is.na(total_listeners))
    
    combined_temp_analysis <<- rbind(combined_temp_analysis, main_temp_data)
    
    # Add second station if enabled
    if (ANALYSE_SECOND_STATION == "Y" && "second_total_listeners" %in% names(main_weather_data)) {
      second_temp_data <<- main_weather_data %>%
        select(temp_category, second_total_listeners) %>%
        rename(total_listeners = second_total_listeners) %>%
        mutate(station = SECOND_STATION_NAME) %>%
        filter(!is.na(total_listeners))
      
      combined_temp_analysis <<- rbind(combined_temp_analysis, second_temp_data)
    }
    
    # Add comparison station if enabled
    if (ANALYSE_COMPARISON_STATION == "Y" && "comparison_total_listeners" %in% names(main_weather_data)) {
      comparison_temp_data <<- main_weather_data %>%
        select(temp_category, comparison_total_listeners) %>%
        rename(total_listeners = comparison_total_listeners) %>%
        mutate(station = COMPARISON_STATION_NAME) %>%
        filter(!is.na(total_listeners))
      
      combined_temp_analysis <<- rbind(combined_temp_analysis, comparison_temp_data)
    }
  }
  
  # Create combined rain analysis for all enabled stations
  combined_rain_analysis <<- data.frame()
  
  if (exists("main_rain_impact")) {
    # Main station rain data
    main_rain_data <<- main_rain_impact %>%
      select(rain_category, day_type, main_avg_listeners, main_observations) %>%
      rename(avg_listeners = main_avg_listeners, observations = main_observations) %>%
      mutate(station = MAIN_STATION_NAME)
    
    combined_rain_analysis <<- rbind(combined_rain_analysis, main_rain_data)
  }
  
  # Add second station rain data if available - calculate from main_weather_data
  if (ANALYSE_SECOND_STATION == "Y" && exists("main_weather_data") && "second_total_listeners" %in% names(main_weather_data)) {
    second_rain_impact <<- main_weather_data %>%
      group_by(rain_category, day_type) %>%
      summarise(
        avg_listeners = mean(second_total_listeners, na.rm = TRUE),
        observations = n(),
        .groups = 'drop'
      ) %>%
      filter(observations >= 20) %>%
      mutate(station = SECOND_STATION_NAME)
    
    combined_rain_analysis <<- rbind(combined_rain_analysis, second_rain_impact)
  }
  
  # Add comparison station rain data if available
  if (ANALYSE_COMPARISON_STATION == "Y" && exists("main_weather_data") && "comparison_total_listeners" %in% names(main_weather_data)) {
    comparison_rain_impact <<- main_weather_data %>%
      group_by(rain_category, day_type) %>%
      summarise(
        avg_listeners = mean(comparison_total_listeners, na.rm = TRUE),
        observations = n(),
        .groups = 'drop'
      ) %>%
      filter(observations >= 20) %>%
      mutate(station = COMPARISON_STATION_NAME)
    
    combined_rain_analysis <<- rbind(combined_rain_analysis, comparison_rain_impact)
  }
  
  # Create combined daylight analysis for all enabled stations
  combined_daylight_analysis <<- data.frame()
  
  if (exists("main_daylight_analysis")) {
    # Main station daylight data
    main_daylight_data <<- main_daylight_analysis %>%
      select(light_condition, hour, day_type, main_avg_listeners, main_observations) %>%
      rename(avg_listeners = main_avg_listeners, observations = main_observations) %>%
      mutate(station = MAIN_STATION_NAME)
    
    combined_daylight_analysis <<- rbind(combined_daylight_analysis, main_daylight_data)
  }
  
  # Add second station daylight data if available
  if (ANALYSE_SECOND_STATION == "Y" && exists("main_weather_data") && "second_total_listeners" %in% names(main_weather_data)) {
    second_daylight_analysis <<- main_weather_data %>%
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
    
    combined_daylight_analysis <<- rbind(combined_daylight_analysis, second_daylight_analysis)
  }
  
  # Add comparison station daylight data if available
  if (ANALYSE_COMPARISON_STATION == "Y" && exists("main_weather_data") && "comparison_total_listeners" %in% names(main_weather_data)) {
    comparison_daylight_analysis <<- main_weather_data %>%
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
    
    combined_daylight_analysis <<- rbind(combined_daylight_analysis, comparison_daylight_analysis)
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
main_station_hourly_comparison <<- data %>%
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
  
  second_station_hourly_comparison <<- data %>%
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
  second_station_hourly_comparison <<- data.frame()
}

# =============================================================================
# PART 10C: COMPARISON STATION HOURLY COMPARISON (IF ENABLED)
# =============================================================================

if (ANALYSE_COMPARISON_STATION == "Y") {
  
  comparison_station_hourly_comparison <<- data %>%
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
  comparison_station_hourly_comparison <<- data.frame()
}

# =============================================================================
# PART 10D: COMBINE ALL STATION COMPARISONS
# =============================================================================

# Combine all available stations into one dataset for plotting
hourly_changes_long <<- bind_rows(
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
station_comparison_summary <<- hourly_changes_long %>%
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
peak_hours_analysis <<- hourly_changes_long %>%
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
  competitive_analysis <<- hourly_changes_long %>%
    pivot_wider(names_from = station, values_from = pct_change, names_prefix = "station_") %>%
    # Calculate which station wins each hour
    rowwise() %>%
    mutate(
      leading_station = {
        station_cols <<- select(., starts_with("station_"))
        station_names <<- gsub("station_", "", names(station_cols))
        station_names[which.max(unlist(station_cols))]
      },
      leading_performance = max(c_across(starts_with("station_")), na.rm = TRUE)
    ) %>%
    ungroup()
  
  # Summary of competitive performance
  competitive_summary <<- competitive_analysis %>%
    count(leading_station, name = "hours_leading") %>%
    mutate(
      pct_hours_leading = (hours_leading / sum(hours_leading)) * 100
    ) %>%
    arrange(desc(hours_leading))
  
} else {
  competitive_analysis <<- data.frame()
  competitive_summary <<- data.frame()
}

# =============================================================================
# PART 10H: CROSS-STATION GENRE COMPARISON
# =============================================================================

# Create genre comparison data
if ((ANALYSE_SECOND_STATION == "Y" | ANALYSE_COMPARISON_STATION == "Y")) {
  
  # Main station genre distribution
  main_genre_comparison <<- data %>%
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
    second_genre_comparison <<- data %>%
      filter(!is.na(second_genre), second_genre != "", second_genre != "-", second_genre != "Unknown") %>%
      filter(!grepl(paste(EXCLUDE_TERMS, collapse = "|"), second_showname, ignore.case = TRUE)) %>%
      count(second_genre, name = "second_plays") %>%
      mutate(
        second_pct = (second_plays / sum(second_plays)) * 100,
        station = SECOND_STATION_NAME
      ) %>%
      rename(genre = second_genre, plays = second_plays, pct = second_pct)
  } else {
    second_genre_comparison <<- data.frame()
  }
  
  # Comparison station genre distribution (if enabled)
  if (ANALYSE_COMPARISON_STATION == "Y") {
    comparison_genre_comparison <<- data %>%
      filter(!is.na(comparison_genre), comparison_genre != "", comparison_genre != "-", comparison_genre != "Unknown") %>%
      filter(!grepl(paste(EXCLUDE_TERMS, collapse = "|"), comparison_showname, ignore.case = TRUE)) %>%
      count(comparison_genre, name = "comparison_plays") %>%
      mutate(
        comparison_pct = (comparison_plays / sum(comparison_plays)) * 100,
        station = COMPARISON_STATION_NAME
      ) %>%
      rename(genre = comparison_genre, plays = comparison_plays, pct = comparison_pct)
  } else {
    comparison_genre_comparison <<- data.frame()
  }
  
  # Combine all stations
  cross_station_genre_data <<- bind_rows(
    main_genre_comparison,
    second_genre_comparison,
    comparison_genre_comparison
  ) %>%
    filter(pct >= 1) %>%  # Only show genres that are >1% of station's output
    arrange(desc(pct))
  
  # Get top genres across all stations for focused comparison
  top_cross_genres <<- cross_station_genre_data %>%
    group_by(genre) %>%
    summarise(max_pct = max(pct, na.rm = TRUE), .groups = "drop") %>%
    arrange(desc(max_pct)) %>%
    head(15) %>%
    pull(genre)
  
  # Filtered data for the main chart
  cross_station_genre_focused <<- cross_station_genre_data %>%
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
      station_data <<- station_comparison_summary[i, ]
      cat("    *", station_data$station, ": Peak at", station_data$peak_hour, ":00 (+", 
          round(station_data$peak_performance, 1), "%), Low at", station_data$lowest_hour, ":00 (", 
          round(station_data$lowest_performance, 1), "%)\n")
    }
  }
  
  if (nrow(competitive_summary) > 0) {
    cat("  - Competitive analysis:\n")
    for (i in 1:nrow(competitive_summary)) {
      comp_data <<- competitive_summary[i, ]
      cat("    *", comp_data$leading_station, "leads", comp_data$hours_leading, "hours (", 
          round(comp_data$pct_hours_leading, 1), "%)\n")
    }
  }
  
  # Show peak listening hour across all stations
  if (nrow(peak_hours_analysis) > 0) {
    best_overall_hour <<- peak_hours_analysis[which.max(peak_hours_analysis$avg_performance_all_stations), ]
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
is_single_month_report <<- REPORT_TYPE != "ALL" && grepl("^\\d{4}-\\d{2}$", REPORT_TYPE)
is_date_range_report <<- !is.null(START_DATE) && !is.null(END_DATE)
is_cumulative_report <<- REPORT_TYPE == "ALL"

cat("Monthly trends analysis type:", 
    ifelse(is_single_month_report, "Single month with context", 
           ifelse(is_date_range_report, "Date range", "Cumulative")), "\n")

# =============================================================================
# PART 11B: MAIN MONTHLY TRENDS CALCULATION
# =============================================================================

if (is_single_month_report) {
  
  # For single-month reports, try to get neighboring months for context
  report_date <<- as.Date(paste0(REPORT_TYPE, "-01"))
  context_start <<- report_date - months(2)  # 2 months before
  context_end <<- report_date + months(2)    # 2 months after (or to current date)
  
  cat("Attempting to retrieve context data for", REPORT_TYPE, "from", context_start, "to", context_end, "\n")
  
  # Try to connect to database for additional context (if database access available)
  tryCatch({
    if (exists("DATABASE_HOST") && exists("con")) {
      
      # Build context query
      context_query <<- paste0(
        "SELECT * FROM ", DB_TABLE, " WHERE date >= '", context_start, 
        "' AND date <= '", context_end, "' ORDER BY date, time"
      )
      
      context_data <<- dbGetQuery(con, context_query)
      
      if (nrow(context_data) > 0) {
        # Process context data similar to main data processing
        context_data <<- context_data %>%
          mutate(
            date = as.Date(date),
            main_total_listeners = main_stream1 + main_stream2,
            second_total_listeners = second_stream1 + second_stream2,
            comparison_total_listeners = comparison_stream,
            month = format(date, "%Y-%m")
          )
        
        # Create monthly comparison from context data
        monthly_comparison <<- context_data %>%
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
        
        monthly_trends_available <<- TRUE
        monthly_trends_type <<- "expanded"
        
        cat("Retrieved", nrow(monthly_comparison), "months of context data\n")
        
      } else {
        monthly_trends_available <<- FALSE
        monthly_trends_type <<- "no_data"
      }
      
    } else {
      monthly_trends_available <<- FALSE
      monthly_trends_type <<- "no_database_access"
    }
    
  }, error = function(e) {
    cat("Database context retrieval failed:", e$message, "\n")
    monthly_trends_available <<- FALSE
    monthly_trends_type <<- "error"
  })
  
} else {
  
  # For multi-month or cumulative reports, use existing data
  if (nrow(data) > 0) {
    
    monthly_comparison <<- data %>%
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
      monthly_trends_available <<- TRUE
      monthly_trends_type <<- "normal"
    } else {
      monthly_trends_available <<- FALSE
      monthly_trends_type <<- "insufficient"
    }
    
  } else {
    monthly_trends_available <<- FALSE
    monthly_trends_type <<- "no_data"
  }
}

# =============================================================================
# PART 11C: CREATE TREND MESSAGE FOR REPORTS
# =============================================================================

if (is_single_month_report) {
  trend_message <<- case_when(
    monthly_trends_type == "expanded" ~ paste0("Monthly trends shown for ", REPORT_TYPE, " (report focus) and neighboring months for context"),
    monthly_trends_type == "no_data" ~ paste0("No monthly trend data available for ", REPORT_TYPE, " or neighboring months"),
    monthly_trends_type == "no_database_access" ~ "Single-month report: Extended trends require database access",
    monthly_trends_type == "error" ~ "Unable to retrieve monthly trend data"
  )
} else {
  trend_message <<- ""
}

# =============================================================================
# PART 11D: MONTHLY TRENDS ANALYSIS (IF AVAILABLE)
# =============================================================================

if (monthly_trends_available && exists("monthly_comparison") && nrow(monthly_comparison) > 1) {
  
  # Clean monthly data for visualization
  monthly_trends_clean <<- monthly_comparison %>%
    filter(is.finite(avg_listeners), !is.na(avg_listeners)) %>%
    mutate(
      # Format month for display
      month_display = format(as.Date(paste0(month, "-01")), "%b %Y"),
      # Create point size for highlighting (if single-month report)
      point_size = ifelse(exists("is_report_month") && is_report_month == TRUE, 4, 2),
      point_alpha = ifelse(exists("is_report_month") && is_report_month == TRUE, 1, 0.7)
    )
  
  # Calculate month-over-month growth rates
  monthly_growth_analysis <<- monthly_trends_clean %>%
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
  monthly_trends_summary <<- list(
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
    monthly_trends_summary$main_avg_growth_rate <<- round(mean(monthly_growth_analysis$main_growth_rate, na.rm = TRUE), 1)
    monthly_trends_summary$main_best_growth_month <<- monthly_growth_analysis$month[which.max(monthly_growth_analysis$main_growth_rate)]
    monthly_trends_summary$main_best_growth_rate <<- round(max(monthly_growth_analysis$main_growth_rate, na.rm = TRUE), 1)
  }
  
} else {
  monthly_trends_clean <<- data.frame()
  monthly_growth_analysis <<- data.frame()
  monthly_trends_summary <<- list(
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
  monthly_seasonal_analysis <<- monthly_trends_clean %>%
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
  seasonal_summary <<- monthly_seasonal_analysis %>%
    group_by(season) %>%
    summarise(
      avg_listeners = mean(avg_listeners, na.rm = TRUE),
      months_in_season = n(),
      .groups = 'drop'
    ) %>%
    arrange(desc(avg_listeners))
  
} else {
  monthly_seasonal_analysis <<- data.frame()
  seasonal_summary <<- data.frame()
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

main_summary_stats <<- list()

# Basic listener statistics
main_summary_stats$avg_daily_listeners <<- mean(data$main_total_listeners, na.rm = TRUE)
main_summary_stats$max_listeners <<- max(data$main_total_listeners, na.rm = TRUE)
main_summary_stats$min_listeners <<- min(data$main_total_listeners, na.rm = TRUE)

# Peak hour analysis - extract from existing hourly analysis
if (exists("main_hourly_listening") && nrow(main_hourly_listening) > 0) {
  peak_hour_data <<- main_hourly_listening %>%
    arrange(desc(main_avg_listeners))
  
  main_summary_stats$peak_hour <<- peak_hour_data$hour[1]
  main_summary_stats$peak_listeners <<- peak_hour_data$main_avg_listeners[1]
} else {
  # Fallback calculation if hourly analysis doesn't exist
  peak_hour_data <<- data %>%
    group_by(hour) %>%
    summarise(avg_listeners = mean(main_total_listeners, na.rm = TRUE), .groups = 'drop') %>%
    arrange(desc(avg_listeners))
  
  main_summary_stats$peak_hour <<- peak_hour_data$hour[1]
  main_summary_stats$peak_listeners <<- peak_hour_data$avg_listeners[1]
}

# Best day analysis - extract from existing daily analysis
if (exists("main_daily_listening") && nrow(main_daily_listening) > 0) {
  best_day_data <<- main_daily_listening %>%
    arrange(desc(main_avg_listeners))
  
  main_summary_stats$best_day <<- best_day_data$weekday[1]
  main_summary_stats$best_day_avg <<- best_day_data$main_avg_listeners[1]
} else {
  # Fallback calculation
  best_day_data <<- data %>%
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
  
  main_summary_stats$best_day <<- best_day_data$weekday_name[1]
  main_summary_stats$best_day_avg <<- best_day_data$avg_listeners[1]
}

# Date range and observation counts
main_summary_stats$start_date <<- min(data$date)
main_summary_stats$end_date <<- max(data$date)
main_summary_stats$total_days <<- length(unique(data$date))
main_summary_stats$total_observations <<- nrow(data[!is.na(data$main_total_listeners),])

# Show statistics - extract from existing show summaries
if (exists("main_show_summary")) {
  main_summary_stats$total_shows_analyzed <<- nrow(main_show_summary)
  main_summary_stats$avg_shows_per_day <<- main_summary_stats$total_shows_analyzed / main_summary_stats$total_days
}

# Music statistics (if available)
if ("main_artist" %in% names(data)) {
  music_data <<- data %>% filter(!is.na(main_artist), main_artist != "", main_artist != "Unknown")
  if (nrow(music_data) > 0) {
    main_summary_stats$total_tracks_played <<- nrow(music_data)
    main_summary_stats$unique_artists <<- length(unique(music_data$main_artist))
    main_summary_stats$unique_tracks <<- length(unique(paste(music_data$main_artist, music_data$main_song)))
    main_summary_stats$music_coverage_pct <<- (nrow(music_data) / nrow(data)) * 100
  }
}

if (exists("main_show_performance_zscore") && nrow(main_show_performance_zscore) > 0) {
  
  main_top_shows_by_category_zscore <<- main_show_performance_zscore %>%
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
  main_top_shows_by_category_zscore <<- data.frame()
}

if (exists("main_artist_impact_zscore") && nrow(main_artist_impact_zscore) > 0) {
  
  # Best impactful artists
  main_best_artists_zscore <<- main_artist_impact_zscore %>%
    filter(main_avg_zscore_impact > 0) %>%
    arrange(desc(main_avg_zscore_impact)) %>%
    head(10) %>%
    mutate(
      main_avg_zscore_impact = round(main_avg_zscore_impact, 2),
      main_avg_listeners = round(main_avg_listeners, 0)
    ) %>%
    select(main_artist, main_avg_zscore_impact, main_plays, main_avg_listeners)
  
  # Worst impactful artists
  main_worst_artists_zscore <<- main_artist_impact_zscore %>%
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
  main_best_artists_zscore <<- data.frame()
  main_worst_artists_zscore <<- data.frame()
}
if (exists("main_genre_impact_zscore") && nrow(main_genre_impact_zscore) > 0) {
  
  # Best performing genres
  main_best_genres_zscore <<- main_genre_impact_zscore %>%
    filter(main_avg_zscore_impact > 0) %>%
    arrange(desc(main_avg_zscore_impact)) %>%
    head(10) %>%
    mutate(
      main_avg_zscore_impact = round(main_avg_zscore_impact, 2),
      main_avg_listeners = round(main_avg_listeners, 0)
    ) %>%
    select(main_genre, main_avg_zscore_impact, main_plays, main_avg_listeners)
  
  # Worst performing genres
  main_worst_genres_zscore <<- main_genre_impact_zscore %>%
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
  main_best_genres_zscore <<- data.frame()
  main_worst_genres_zscore <<- data.frame()
}

cat("Main station summary stats created\n")

# =============================================================================
# SECOND STATION SUMMARY STATS (IF ENABLED)
# =============================================================================

if (ANALYSE_SECOND_STATION == "Y") {
  
  second_summary_stats <<- list()
  
  # Basic listener statistics
  second_summary_stats$avg_daily_listeners <<- mean(data$second_total_listeners, na.rm = TRUE)
  second_summary_stats$max_listeners <<- max(data$second_total_listeners, na.rm = TRUE)
  second_summary_stats$min_listeners <<- min(data$second_total_listeners, na.rm = TRUE)
  
  # Peak hour analysis
  if (exists("second_hourly_listening") && nrow(second_hourly_listening) > 0) {
    peak_hour_data <<- second_hourly_listening %>%
      arrange(desc(second_avg_listeners))
    
    second_summary_stats$peak_hour <<- peak_hour_data$hour[1]
    second_summary_stats$peak_listeners <<- peak_hour_data$second_avg_listeners[1]
  } else {
    # Fallback calculation
    peak_hour_data <<- data %>%
      group_by(hour) %>%
      summarise(avg_listeners = mean(second_total_listeners, na.rm = TRUE), .groups = 'drop') %>%
      arrange(desc(avg_listeners))
    
    second_summary_stats$peak_hour <<- peak_hour_data$hour[1]
    second_summary_stats$peak_listeners <<- peak_hour_data$avg_listeners[1]
  }
  
  # Best day analysis
  if (exists("second_daily_listening") && nrow(second_daily_listening) > 0) {
    best_day_data <<- second_daily_listening %>%
      arrange(desc(second_avg_listeners))
    
    second_summary_stats$best_day <<- best_day_data$weekday[1]
    second_summary_stats$best_day_avg <<- best_day_data$second_avg_listeners[1]
  } else {
    # Fallback calculation
    best_day_data <<- data %>%
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
    
    second_summary_stats$best_day <<- best_day_data$weekday_name[1]
    second_summary_stats$best_day_avg <<- best_day_data$avg_listeners[1]
  }
  
  # Date range and observation counts
  second_summary_stats$start_date <<- min(data$date)
  second_summary_stats$end_date <<- max(data$date)
  second_summary_stats$total_observations <<- nrow(data[!is.na(data$second_total_listeners),])
  
  # Show statistics
  if (exists("second_show_summary")) {
    second_summary_stats$total_shows_analyzed <<- nrow(second_show_summary)
  }
  
  # Music statistics (if available)
  if ("second_artist" %in% names(data)) {
    music_data <<- data %>% filter(!is.na(second_artist), second_artist != "", second_artist != "Unknown")
    if (nrow(music_data) > 0) {
      second_summary_stats$total_tracks_played <<- nrow(music_data)
      second_summary_stats$unique_artists <<- length(unique(music_data$second_artist))
      second_summary_stats$unique_tracks <<- length(unique(paste(music_data$second_artist, music_data$second_song)))
      second_summary_stats$music_coverage_pct <<- (nrow(music_data) / nrow(data)) * 100
    }
  }
  
  if (exists("second_show_performance_zscore") && nrow(second_show_performance_zscore) > 0) {
    
    second_top_shows_by_category_zscore <<- second_show_performance_zscore %>%
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
    second_top_shows_by_category_zscore <<- data.frame()
  }
  
  if (exists("second_artist_impact_zscore") && nrow(second_artist_impact_zscore) > 0) {
    
    # Best impactful artists
    second_best_artists_zscore <<- second_artist_impact_zscore %>%
      filter(second_avg_zscore_impact > 0) %>%
      arrange(desc(second_avg_zscore_impact)) %>%
      head(10) %>%
      mutate(
        second_avg_zscore_impact = round(second_avg_zscore_impact, 2),
        second_avg_listeners = round(second_avg_listeners, 0)
      ) %>%
      select(second_artist, second_avg_zscore_impact, second_plays, second_avg_listeners)
    
    # Worst impactful artists
    second_worst_artists_zscore <<- second_artist_impact_zscore %>%
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
    second_best_artists_zscore <<- data.frame()
    second_worst_artists_zscore <<- data.frame()
  }
  
  if (exists("second_genre_impact_zscore") && nrow(second_genre_impact_zscore) > 0) {
    
    # Best performing genres
    second_best_genres_zscore <<- second_genre_impact_zscore %>%
      filter(second_avg_zscore_impact > 0) %>%
      arrange(desc(second_avg_zscore_impact)) %>%
      head(10) %>%
      mutate(
        second_avg_zscore_impact = round(second_avg_zscore_impact, 2),
        second_avg_listeners = round(second_avg_listeners, 0)
      ) %>%
      select(second_genre, second_avg_zscore_impact, second_plays, second_avg_listeners)
    
    # Worst performing genres
    second_worst_genres_zscore <<- second_genre_impact_zscore %>%
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
    second_best_genres_zscore <<- data.frame()
    second_worst_genres_zscore <<- data.frame()
  }
  
  cat("Second station summary stats created\n")
}

# =============================================================================
# COMPARISON STATION SUMMARY STATS (IF ENABLED)
# =============================================================================

if (ANALYSE_COMPARISON_STATION == "Y") {
  
  comparison_summary_stats <<- list()
  
  # Basic listener statistics
  comparison_summary_stats$avg_daily_listeners <<- mean(data$comparison_total_listeners, na.rm = TRUE)
  comparison_summary_stats$max_listeners <<- max(data$comparison_total_listeners, na.rm = TRUE)
  comparison_summary_stats$min_listeners <<- min(data$comparison_total_listeners, na.rm = TRUE)
  
  # Peak hour analysis
  if (exists("comparison_hourly_listening") && nrow(comparison_hourly_listening) > 0) {
    peak_hour_data <<- comparison_hourly_listening %>%
      arrange(desc(comparison_avg_listeners))
    
    comparison_summary_stats$peak_hour <<- peak_hour_data$hour[1]
    comparison_summary_stats$peak_listeners <<- peak_hour_data$comparison_avg_listeners[1]
  } else {
    # Fallback calculation
    peak_hour_data <<- data %>%
      group_by(hour) %>%
      summarise(avg_listeners = mean(comparison_total_listeners, na.rm = TRUE), .groups = 'drop') %>%
      arrange(desc(avg_listeners))
    
    comparison_summary_stats$peak_hour <<- peak_hour_data$hour[1]
    comparison_summary_stats$peak_listeners <<- peak_hour_data$avg_listeners[1]
  }
  
  # Best day analysis
  if (exists("comparison_daily_listening") && nrow(comparison_daily_listening) > 0) {
    best_day_data <<- comparison_daily_listening %>%
      arrange(desc(comparison_avg_listeners))
    
    comparison_summary_stats$best_day <<- best_day_data$weekday[1]
    comparison_summary_stats$best_day_avg <<- best_day_data$comparison_avg_listeners[1]
  } else {
    # Fallback calculation
    best_day_data <<- data %>%
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
    
    comparison_summary_stats$best_day <<- best_day_data$weekday_name[1]
    comparison_summary_stats$best_day_avg <<- best_day_data$avg_listeners[1]
  }
  
  # Date range and observation counts
  comparison_summary_stats$start_date <<- min(data$date)
  comparison_summary_stats$end_date <<- max(data$date)
  comparison_summary_stats$total_observations <<- nrow(data[!is.na(data$comparison_total_listeners),])
  
  # Show statistics
  if (exists("comparison_show_summary")) {
    comparison_summary_stats$total_shows_analyzed <<- nrow(comparison_show_summary)
  }
  
  # Music statistics (if available)
  if ("comparison_artist" %in% names(data)) {
    music_data <<- data %>% filter(!is.na(comparison_artist), comparison_artist != "", comparison_artist != "Unknown")
    if (nrow(music_data) > 0) {
      comparison_summary_stats$total_tracks_played <<- nrow(music_data)
      comparison_summary_stats$unique_artists <<- length(unique(music_data$comparison_artist))
      comparison_summary_stats$unique_tracks <<- length(unique(paste(music_data$comparison_artist, music_data$comparison_song)))
      comparison_summary_stats$music_coverage_pct <<- (nrow(music_data) / nrow(data)) * 100
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
  same_month <<- format(main_summary_stats$start_date, "%Y-%m") == format(main_summary_stats$end_date, "%Y-%m")
  
  date_range <<- if (same_month) {
    format(main_summary_stats$start_date, "%B %Y")
  } else {
    paste(format(main_summary_stats$start_date, "%B %Y"), "-", format(main_summary_stats$end_date, "%B %Y"))
  }
}

# Monthly trends availability flag
monthly_trends_available <<- exists("monthly_trends_clean") && nrow(monthly_trends_clean) > 1

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
}

# =============================================================================
# PDF REPORT GENERATION - COMPLETE GENERALIZED RMD CONTENT ↓↓↓
# =============================================================================

generate_report <- function() {
  
  update_statistics(data) # Make sure we have the latest and greatest stats

  current_dir <- dirname(rstudioapi::getActiveDocumentContext()$path)

  # Create R Markdown content for the report
  rmd_content <- '
---
title:
  "`r MAIN_STATION_NAME` Listener Analysis Report
\n
`r date_range`"
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
  - \\usepackage{transparent}
  - \\usepackage{graphicx}
  - \\usepackage{wallpaper}
---

```{r setup, include=FALSE}
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

- `r MAIN_STATION_NAME`\'s ShoutCast server page provides data for both the absolute number of listeners, and the number of unique listeners. The data collected is for the number of unique listeners, i.e. the number of ShoutCast connections from unique IP addresses. \n
- While it might seem reasonable to assume that 648MW and DAB listeners will follow similar listening patterns to the online audience, this might not necessarily be the case. \n
- Most performance metrics use Z-Score comparisons rather than absolute numbers, or percentages, to account for natural variations in listening patterns throughout the day. DJ performance is measured against the average for their specific time slots, ensuring fair comparison between peak and off-peak presenters. \n
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
      weekday_data %>% head(20),
      weekday_data %>% tail(20)
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
      panel.grid.minor.y = element_blank()
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
      panel.grid.minor.y = element_blank()
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
- The analysis for Gary Ziepe includes The Mellow Show.
- The analysis for Rob van Dijk includes the Countdown show.

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
- The analysis for Gary Ziepe includes The Mellow Show
- The analysis for Rob van Dijk includes the Countdown show

\\newpage
## DJ Genre Analysis Summary

```{r main_dj-summary-table}
if (exists("main_dj_summary_table") && nrow(main_dj_summary_table) > 0) {
  
  # Display top 30 DJs for readability
  summary_display <- main_dj_summary_table %>%
    head(30)
  
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
                     "% Diff", "Sitting-in Win %", "Regular Win %", 
                     "Days", "Summary")) %>%
    column_spec(3, width = "0.75cm") %>%  # Narrow "Hours" column
    column_spec(4, width = "0.75cm") %>%  # Narrow "% Diff" column
    column_spec(5, width = "1.3cm") %>%  # Narrow "Sitting-in Wins" column
    column_spec(6, width = "1.2cm") %>%  # Also narrow "Regular Wins" for symmetry  
    column_spec(7, width = "1.75cm"))    # Set fixed width for Days column
        
cat(glue("\\n**Note**: Win % shows relative performance in {DATA_COLLECTION}-minute interval comparisons.\\n"))
} else {
  cat("No sitting-in comparison data available.\\n")
}
```

```{r main_live-recorded-chart, eval=MAIN_LIVE_RECORDED_EXISTS, fig.cap=paste("Live vs pre-recorded programming performance on", paste0(MAIN_STATION_NAME)), fig.width=7, fig.height=5, results="asis"}
cat("\\\\newpage\\n\\n")
cat("## Live vs Pre-recorded Impact Analysis\\n\\n")
if (MAIN_DJ_LIVE_RECORDED_EXISTS) {
cat("### Overall Live vs Pre-recorded Impact\\n\\n")
}
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

```{r main_dj-live-vs-prerecorded-table, eval=MAIN_DJ_LIVE_RECORDED_EXISTS, results="asis"}
cat("### Live vs Pre-recorded Impact for Individual DJs\\n\\n")
      print(kable(main_dj_live_recorded_analysis,
          caption = paste("DJ Performance: Live vs Pre-recorded Hours on", paste0(MAIN_STATION_NAME)),
          col.names = c("DJ", "Live Hours", "Pre-rec Hours", 
                       "Live % vs Avg", "Pre-rec % vs Avg", "Difference",
                       "Live Listeners", "Pre-rec Listeners", "Better When")) %>%
      column_spec(2, width = "1.2cm") %>%  # Narrow session count columns
      column_spec(3, width = "1.2cm") %>%
      column_spec(7, width = "1.3cm") %>%  # Narrow listener count columns  
      column_spec(8, width = "1.3cm"))
      
    cat("\\n**Analysis Notes**:\\n\\n")
    cat("- Performance measured against time slot average\\n\\n")
    cat("- Positive difference means DJ performs better when live\\n\\n")
    cat("- Only time slots with both live and pre-recorded shows included\\n\\n")
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
      weekday_data %>% head(20),
      weekday_data %>% tail(20)
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
      panel.grid.minor.y = element_blank()
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
      panel.grid.minor.y = element_blank()
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
  
  # Display top 30 DJs for readability
  summary_display <- second_dj_summary_table %>%
    head(30)
  
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

```{r second_top-30-tracks-zscore, eval=(ANALYSE_SECOND_STATION == "Y") && exists("second_most_played_tracks_zscore") && nrow(second_most_played_tracks_zscore) > 0, fig.cap=paste("Impact of the 30 most played tracks on", paste0(SECOND_STATION_NAME)), fig.width=8, fig.height=8, results="asis"}
cat("\\\\newpage\\n\\n")
cat(glue("# ", paste0(SECOND_STATION_NAME), " Impact Analyses\\n\\n"))
cat("## Most Played Tracks Impact Analysis\\n\\n")

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
                     "% Diff", "Sitting-in Win %", "Regular Win %", 
                     "Days", "Summary")) %>%
    column_spec(3, width = "0.75cm") %>%  # Narrow "Hours" column
    column_spec(4, width = "0.75cm") %>%  # Narrow "% Diff" column
    column_spec(5, width = "1.3cm") %>%  # Narrow "Sitting-in Wins" column
    column_spec(6, width = "1.2cm") %>%  # Also narrow "Regular Wins" for symmetry  
    column_spec(7, width = "1.75cm"))    # Set fixed width for Days column
        
cat(glue("\\n**Note**: Win % shows relative performance in {DATA_COLLECTION}-minute interval comparisons.\\n"))
} else {
  cat("No sitting-in comparison data available.\\n")
}
```

```{r second_live-recorded-chart, eval=(ANALYSE_SECOND_STATION == "Y") && SECOND_LIVE_RECORDED_EXISTS, fig.cap=paste("Live vs pre-recorded programming performance on", paste0(SECOND_STATION_NAME)), fig.width=7, fig.height=5, results="asis"}
cat("\\\\newpage\\n\\n")
cat("## Live vs Pre-recorded Impact Analysis\\n\\n")
if (SECOND_DJ_LIVE_RECORDED_EXISTS) {
cat("### Overall Live vs Pre-recorded Impact\\n\\n")
}
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

```{r second_dj-live-vs-prerecorded-table, eval=(ANALYSE_SECOND_STATION == "Y") && SECOND_DJ_LIVE_RECORDED_EXISTS, results="asis"}
cat("### Live vs Pre-recorded Impact for Individual DJs\\n\\n")
      print(kable(second_dj_live_recorded_analysis,
          caption = paste("DJ Performance: Live vs Pre-recorded Hours on", paste0(SECOND_STATION_NAME)),
          col.names = c("DJ", "Live Hours", "Pre-rec Hours", 
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
    slice_head(n=1) %>%
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

```{r monthly-trends-chart, eval=monthly_trends_available && nrow(monthly_trends_clean) > 1, fig.cap="Monthly performance trends across all analyzed stations", fig.width=8, fig.height=5, results="asis"}
cat("\\\\newpage\\n\\n")
cat("# Monthly Listener Trends\\n\\n")
cat("## Monthly Performance Trends\\n\\n")

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

}

# =============================================================================
# ML DJ MODEL TRAINING
# =============================================================================

# =============================================================================
# 🔥 BURN DOWN THE HOUSE - BUILD REAL AI! 🔥
# =============================================================================

build_real_ai <- function() {
  cat("\n🔥🔥🔥 I'M BURNING DOWN THE HOUSE! REAL AI #FTW 🔥🔥🔥\n")
  
  if (!exists("ml_features") || nrow(ml_features) < 100) {
    update_statistics(data)
    ml_features <<- prepare_ml_features(data)
  }
  
  if (!exists("current_context")) {
    cat("🔄 Creating current context...\n")
    analyze_current_context(ml_features = ml_features, force_fresh_data = FALSE)
  }
  
    # =========================================================================
    # STEP 1: BUILD REAL LEARNING DATASET
    # =========================================================================
  
  cat("🧠 STEP 1: Creating REAL learning dataset...\n")
  
  # Create proper AI training data - every track play is a learning example
  ai_training_data <- ml_features %>%
    arrange(datetime) %>%
    mutate(
      # REAL target: what actually happened next
      next_listeners = lead(main_total_listeners, 1),
      listener_change = next_listeners - main_total_listeners,
      pct_change = (listener_change / pmax(main_total_listeners, 1)) * 100,
      
      # Success/failure binary outcome
      was_success = ifelse(listener_change > 0, 1, 0),
      was_big_success = ifelse(listener_change > 5, 1, 0),
      was_failure = ifelse(listener_change < -5, 1, 0),
      
      # Context features for AI
      hour_normalized = hour / 24,
      is_weekend = ifelse(day_type == "Weekend", 1, 0),
      is_prime = ifelse(hour >= 7 & hour <= 10 | hour >= 16 & hour <= 19, 1, 0),
      
      # Momentum features
      recent_trend = main_total_listeners - lag(main_total_listeners, 3),
      medium_trend = main_total_listeners - lag(main_total_listeners, 6),
      
      # Artist/track encoding (AI will learn patterns)
      artist_hash = as.numeric(as.factor(main_artist)) %% 1000,
      track_hash = as.numeric(as.factor(paste(main_artist, main_song))) %% 10000,
      genre_hash = as.numeric(as.factor(ifelse(!is.na(main_genre), main_genre, "Unknown"))) %% 100,
      
      # Weather encoding
      weather_numeric = case_when(
        is.na(weather_condition) ~ 0,
        grepl("rain|storm", weather_condition, ignore.case = TRUE) ~ 1,
        grepl("cloud|overcast", weather_condition, ignore.case = TRUE) ~ 2, 
        grepl("sun|clear", weather_condition, ignore.case = TRUE) ~ 3,
        TRUE ~ 2
      ),
      
      # Show context
      is_live = ifelse(!is.na(main_live_recorded) & main_live_recorded == "Live", 1, 0),
      
      # Advanced features
      listener_volatility = zoo::rollapply(main_total_listeners, width = 6, FUN = sd, fill = 0, align = "right"),
      momentum_acceleration = recent_trend - lag(recent_trend, 1)
    ) %>%
    filter(!is.na(next_listeners), !is.na(recent_trend)) %>%
    # Clean the data
    mutate(
      listener_volatility = ifelse(is.na(listener_volatility), 0, listener_volatility),
      momentum_acceleration = ifelse(is.na(momentum_acceleration), 0, momentum_acceleration)
    )
  
  cat("   ✅", nrow(ai_training_data), "learning examples created\n")
  
    # =========================================================================
    # STEP 2: POISON NON-EXISTENT TRACKS IN AI TRAINING DATA
    #         (DJs might play tracks from their own music collections,
    #          or the now-playing metadata may be wrong!)
    # =========================================================================
  
  cat("🔍 Checking track availability in collection...\n")
  
  ai_training_data <- validate_training_data_against_available_tracks(ai_training_data)
  
    # =========================================================================
    # STEP 3: INTELLIGENT FEATURE MATRIX
    # =========================================================================
  
  cat("🎯 STEP 2: Building intelligent feature matrix...\n")
  
  # Features the AI will learn from
  feature_columns <- c(
    "main_total_listeners", "hour_normalized", "is_weekend", "is_prime",
    "recent_trend", "medium_trend", "listener_volatility", "momentum_acceleration",
    "artist_hash", "track_hash", "genre_hash", "weather_numeric", "is_live"
  )
  
  X <- ai_training_data[, feature_columns]
  X[is.na(X)] <- 0  # Clean NAs
  
  # Targets
  y_regression <- ai_training_data$pct_change
  y_success <- ai_training_data$was_success
  y_big_success <- ai_training_data$was_big_success
  
  cat("   ✅ Feature matrix:", nrow(X), "x", ncol(X), "\n")
  cat("   ✅ Success rate:", round(mean(y_success, na.rm = TRUE) * 100, 1), "%\n")
  
    # =========================================================================
    # STEP 4: TRAIN MULTIPLE AI MODELS
    # =========================================================================
  
  cat("🤖 STEP 3: Training REAL AI models...\n")
  
  # Split data
  set.seed(42)
  train_size <- floor(0.8 * nrow(X))
  train_idx <- sample(nrow(X), train_size)
  
  X_train <- X[train_idx, ]
  X_test <- X[-train_idx, ]
  y_train <- y_regression[train_idx]
  y_test <- y_regression[-train_idx]
  y_success_train <- y_success[train_idx]
  y_success_test <- y_success[-train_idx]
  
  # MODEL 1: GRADIENT BOOSTING (like XGBoost but simpler)
  cat("   🌳 Training Gradient Boosting AI...\n")
  
  # Simple gradient boosting implementation
  gb_models <- list()
  gb_predictions <- rep(0, nrow(X_train))
  learning_rate <- 0.1
  n_estimators <- 100
  
  for (i in 1:n_estimators) {
    # Calculate residuals
    residuals <- y_train - gb_predictions
    
    # Fit a simple tree (linear model as proxy)
    tree_data <- data.frame(X_train, target = residuals)
    tree_model <- lm(target ~ ., data = tree_data)
    
    # Store model
    gb_models[[i]] <- tree_model
    
    # Update predictions
    tree_pred <- predict(tree_model, X_train)
    gb_predictions <- gb_predictions + learning_rate * tree_pred
    
    if (i %% 20 == 0) {
      rmse <- sqrt(mean((y_train - gb_predictions)^2))
      cat("     Iteration", i, "- RMSE:", round(rmse, 2), "\n")
    }
  }
  
  # Test gradient boosting
  gb_test_pred <- rep(0, nrow(X_test))
  for (i in 1:length(gb_models)) {
    tree_pred <- predict(gb_models[[i]], X_test)
    gb_test_pred <- gb_test_pred + learning_rate * tree_pred
  }
  
  gb_rmse <- sqrt(mean((y_test - gb_test_pred)^2))
  cat("   ✅ Gradient Boosting RMSE:", round(gb_rmse, 2), "%\n")
  
  # MODEL 2: DEEP NEURAL NETWORK
  cat("   🧠 Training Deep Neural Network...\n")
  
  if (require("nnet", quietly = TRUE)) {
    # Scale features
    X_train_scaled <- scale(X_train)
    X_test_scaled <- scale(X_test, center = attr(X_train_scaled, "scaled:center"), 
                           scale = attr(X_train_scaled, "scaled:scale"))
    
    # Deep network
    set.seed(42)
    deep_nn <- nnet(X_train_scaled, y_train,
                    size = 15,          # More neurons
                    decay = 0.001,      # Less regularization
                    linout = TRUE,
                    skip = FALSE,       # No skip connections
                    MaxNWts = 20000,
                    trace = FALSE,
                    maxit = 1000)       # More iterations
    
    nn_test_pred <- predict(deep_nn, X_test_scaled)
    nn_rmse <- sqrt(mean((y_test - nn_test_pred)^2))
    cat("   ✅ Deep Neural Network RMSE:", round(nn_rmse, 2), "%\n")
  } else {
    deep_nn <- NULL
    nn_rmse <- 999
  }
  
  # MODEL 3: RANDOM FOREST ENSEMBLE
  cat("   🌲 Training Random Forest Ensemble...\n")
  
  if (require("randomForest", quietly = TRUE)) {
    set.seed(42)
    rf_model <- randomForest(X_train, y_train,
                             ntree = 1000,      # More trees
                             mtry = floor(sqrt(ncol(X_train))),
                             nodesize = 3,      # Smaller nodes
                             importance = TRUE)
    
    rf_test_pred <- predict(rf_model, X_test)
    rf_rmse <- sqrt(mean((y_test - rf_test_pred)^2))
    cat("   ✅ Random Forest RMSE:", round(rf_rmse, 2), "%\n")
    
    # Show feature importance
    importance <- importance(rf_model)[, 1]
    top_features <- head(sort(importance, decreasing = TRUE), 5)
    cat("   🎯 Top AI features:", paste(names(top_features), collapse = ", "), "\n")
  } else {
    rf_model <- NULL
    rf_rmse <- 999
  }
  
    # =========================================================================
    # STEP 5: TRACK INTELLIGENCE DATABASE
    # =========================================================================
  
  cat("🎵 STEP 4: Building Track Intelligence Database...\n")
  
  # For each track, learn its AI patterns (WITH FILTERING!)
  track_intelligence <- ai_training_data %>%
    # FILTER OUT PLACEHOLDERS
    filter(!is.na(main_artist), 
           main_artist != "", 
           main_artist != "Unknown",
           main_artist != "DJ Chat",
           main_artist != "Advertisement", 
           main_artist != "Advert",
           main_artist != "-") %>%
    filter(!is.na(main_song), 
           main_song != "", 
           main_song != "Unknown",
           main_song != "-") %>%
    group_by(main_artist, main_song) %>%
    summarise(
      # Basic stats
      total_plays = n(),
      avg_success_rate = mean(was_success, na.rm = TRUE),
      avg_listener_change = mean(listener_change, na.rm = TRUE),
      
      # AI patterns
      works_in_decline = mean(was_success[recent_trend < -10], na.rm = TRUE),
      works_in_growth = mean(was_success[recent_trend > 10], na.rm = TRUE),
      works_weekend = mean(was_success[is_weekend == 1], na.rm = TRUE),
      works_weekday = mean(was_success[is_weekend == 0], na.rm = TRUE),
      works_prime = mean(was_success[is_prime == 1], na.rm = TRUE),
      works_offpeak = mean(was_success[is_prime == 0], na.rm = TRUE),
      
      # Context preferences
      best_hour = {
        hour_performance <- tapply(was_success, hour, mean, na.rm = TRUE)
        if (all(is.na(hour_performance))) 12 else as.numeric(names(which.max(hour_performance)))
      },
      
      # Volatility handling
      handles_volatility = mean(was_success[listener_volatility > 5], na.rm = TRUE),
      
      .groups = 'drop'
    ) %>%
    filter(total_plays >= TOTAL_PLAYS_FILTER) %>%
    mutate(
      # AI intelligence scores
      decline_specialist = ifelse(!is.na(works_in_decline) & works_in_decline > 0.6, 1, 0),
      growth_specialist = ifelse(!is.na(works_in_growth) & works_in_growth > 0.6, 1, 0),
      weekend_specialist = ifelse(!is.na(works_weekend) & works_weekend > works_weekday + 0.2, 1, 0),
      prime_specialist = ifelse(!is.na(works_prime) & works_prime > works_offpeak + 0.2, 1, 0),
      
      # Overall AI confidence
      ai_confidence = pmin(total_plays / 10, 1.0),
      
      # Replace NAs
      works_in_decline = ifelse(is.na(works_in_decline), avg_success_rate, works_in_decline),
      works_in_growth = ifelse(is.na(works_in_growth), avg_success_rate, works_in_growth),
      works_weekend = ifelse(is.na(works_weekend), avg_success_rate, works_weekend),
      works_weekday = ifelse(is.na(works_weekday), avg_success_rate, works_weekday)
    )
  
  cat("   ✅ AI learned patterns for", nrow(track_intelligence), "tracks\n")
  
    # =========================================================================
    # STEP 6 (DEBUG): SHOW WHAT TRACKS THE AI ACTUALLY LEARNED
    # =========================================================================
  
  cat("🎵 TRACKS THE AI LEARNED PATTERNS FOR:\n")
  if (exists("track_intelligence") && nrow(track_intelligence) > 0) {
    
    learned_tracks <- track_intelligence %>%
      arrange(desc(total_plays)) %>%
      select(main_artist, main_song, total_plays, avg_success_rate)
    
  } else {
    cat("❌ No track_intelligence data found\n")
  }
  
    # =========================================================================
    # STEP 7: CREATE AI SYSTEM
    # =========================================================================
  
  real_ai_system <- list(
    # Trained models
    models = list(
      gradient_boosting = gb_models,
      deep_neural_net = deep_nn,
      random_forest = rf_model,
      learning_rate = learning_rate
    ),
    
    # Feature information
    features = list(
      columns = feature_columns,
      scaling_center = if (exists("X_train_scaled")) attr(X_train_scaled, "scaled:center") else NULL,
      scaling_scale = if (exists("X_train_scaled")) attr(X_train_scaled, "scaled:scale") else NULL
    ),
    
    # AI intelligence
    track_intelligence = track_intelligence,
    
    # Performance
    performance = list(
      gb_rmse = gb_rmse,
      nn_rmse = if (exists("nn_rmse")) nn_rmse else 999,
      rf_rmse = if (exists("rf_rmse")) rf_rmse else 999,
      best_model = names(c(gb_rmse, nn_rmse, rf_rmse))[which.min(c(gb_rmse, nn_rmse, rf_rmse))]
    ),
    
    # Training metadata
    training_examples = nrow(ai_training_data),
    success_rate = mean(y_success, na.rm = TRUE),
    created = Sys.time()
  )
  
  cat("✅ REAL AI SYSTEM BUILT!\n")
  cat("   🎯 Best model:", real_ai_system$performance$best_model, "\n")
  cat("   📊 Training examples:", real_ai_system$training_examples, "\n")
  cat("   🎵 Tracks learned:", nrow(track_intelligence), "\n")
  cat("   🧠 Average success rate:", round(real_ai_system$success_rate * 100, 1), "%\n\n")
  
  return(real_ai_system)
}

# =========================================================================
# ML TRAINING HELPER FUNCTION: FEATURE ENGINEERING AND DATA PREPARATION
# =========================================================================

prepare_ml_features <- function(data) {
  cat("🤖 PREPARING ML FEATURES FOR TRACK RECOMMENDATION...\n")
  
  # Create comprehensive feature set for ML analysis
  ml_features <- data %>%
    filter(!is.na(main_total_listeners), 
           !is.na(main_artist), 
           main_artist != "", 
           main_artist != "Unknown",
           main_artist != "DJ Chat",
           main_artist != "Advertisement", 
           main_artist != "Advert",
           main_artist != "-") %>%
    mutate(
      # Create the missing key variables from actual column names
      track_key = paste(main_artist, main_song, sep = " - "),
      artist_key = main_artist,
      genre_key = ifelse(!is.na(main_genre) & main_genre != "" & main_genre != "-", 
                         main_genre, "Unknown"),
      
      # Time-based features
      hour_sin = sin(2 * pi * hour / 24),
      hour_cos = cos(2 * pi * hour / 24),
      day_of_week = as.numeric(weekday),
      day_sin = sin(2 * pi * day_of_week / 7),
      day_cos = cos(2 * pi * day_of_week / 7),
      is_weekend = ifelse(day_type == "Weekend", 1, 0),
      is_prime_time = ifelse(hour >= 7 & hour <= 10 | hour >= 16 & hour <= 19, 1, 0),
      
      # Weather features (only if columns exist)
      weather_temp_norm = if("weather_temp" %in% names(data)) {
        ifelse(!is.na(weather_temp), scale(weather_temp)[,1], 0)
      } else { 0 },
      
      weather_encoded = case_when(
        !("weather_condition" %in% names(data)) ~ 0,
        is.na(weather_condition) ~ 0,
        grepl("rain|storm", weather_condition, ignore.case = TRUE) ~ 1,
        grepl("cloud|overcast", weather_condition, ignore.case = TRUE) ~ 2,
        grepl("sun|clear", weather_condition, ignore.case = TRUE) ~ 3,
        TRUE ~ 2  # Default for unknown weather
      ),
      
      # Show/presenter features (only if columns exist)
      is_live = if("is_live" %in% names(data)) {
        ifelse(!is.na(is_live), as.numeric(is_live), 1)
      } else { 1 },  # Assume live if unknown
      
      show_encoded = if("main_showname" %in% names(data)) {
        as.numeric(as.factor(ifelse(!is.na(main_showname), main_showname, "Unknown")))
      } else { 1 },
      
      presenter_encoded = if("main_presenter" %in% names(data)) {
        as.numeric(as.factor(ifelse(!is.na(main_presenter), main_presenter, "Unknown")))
      } else { 1 }
    ) %>%
    arrange(datetime) %>%
    mutate(
      # Momentum and trend features (calculated after arrange)
      listener_momentum = main_total_listeners - lag(main_total_listeners, 1, default = main_total_listeners[1]),
      listener_trend_3 = main_total_listeners - lag(main_total_listeners, 3, default = main_total_listeners[1]),
      listener_trend_6 = main_total_listeners - lag(main_total_listeners, 6, default = main_total_listeners[1]),
      
      # Volatility measures (rolling standard deviation approximation)
      listener_volatility = {
        # Calculate rolling volatility using a window approach
        n_obs <- n()
        volatility <- numeric(n_obs)
        
        for (i in 1:n_obs) {
          window_start <- max(1, i - 5)
          window_data <- main_total_listeners[window_start:i]
          volatility[i] <- ifelse(length(window_data) > 1, sd(window_data, na.rm = TRUE), 0)
        }
        volatility
      },
      
      # Performance vs. historical average for this hour/day combination
      hour_day_baseline = {
        # Calculate baseline for each hour/day combination
        baseline_data <- data %>%
          filter(!is.na(main_total_listeners)) %>%
          group_by(hour, day_type) %>%
          summarise(baseline_listeners = mean(main_total_listeners, na.rm = TRUE), .groups = 'drop')
        
        # Join with current data
        current_with_baseline <- data.frame(hour = hour, day_type = day_type) %>%
          left_join(baseline_data, by = c("hour", "day_type"))
        
        ifelse(!is.na(current_with_baseline$baseline_listeners), 
               current_with_baseline$baseline_listeners, 
               mean(main_total_listeners, na.rm = TRUE))
      },
      
      # Performance deviation from baseline
      performance_vs_baseline = main_total_listeners - hour_day_baseline,
      performance_vs_baseline_pct = (performance_vs_baseline / pmax(hour_day_baseline, 1)) * 100,
      
      # Track/artist/genre encoding for ML
      track_encoded = as.numeric(as.factor(track_key)),
      artist_encoded = as.numeric(as.factor(artist_key)),
      genre_encoded = as.numeric(as.factor(genre_key)),
      
      # Sequence features (what happened before this track)
      prev_track_encoded = lag(track_encoded, 1, default = track_encoded[1]),
      prev_artist_encoded = lag(artist_encoded, 1, default = artist_encoded[1]),
      prev_genre_encoded = lag(genre_encoded, 1, default = genre_encoded[1]),
      
      # Listener flow (change from previous observation)
      listener_flow = listener_momentum,
      listener_flow_pct = (listener_flow / pmax(lag(main_total_listeners, 1, default = main_total_listeners[1]), 1)) * 100,
      
      # Time since last play of this track (approximate)
      hours_since_track = {
        # This is a simplified version - in practice you'd want more sophisticated tracking
        track_positions <- match(track_key, unique(track_key))
        current_position <- seq_along(track_key)
        
        # Rough approximation assuming data is hourly
        ifelse(track_positions == current_position, 999, current_position - track_positions)
      },
      
      # Binary success indicators for training
      listener_success = ifelse(listener_momentum > 0, 1, 0),
      big_listener_success = ifelse(listener_momentum > 5, 1, 0),
      listener_failure = ifelse(listener_momentum < -5, 1, 0),
      
      # Categorical features for different ML models
      hour_category = case_when(
        hour >= 6 & hour < 10 ~ "Morning",
        hour >= 10 & hour < 14 ~ "Midday", 
        hour >= 14 & hour < 18 ~ "Afternoon",
        hour >= 18 & hour < 22 ~ "Evening",
        TRUE ~ "Overnight"
      ),
      
      audience_size_category = case_when(
        main_total_listeners < quantile(main_total_listeners, 0.25, na.rm = TRUE) ~ "Small",
        main_total_listeners < quantile(main_total_listeners, 0.75, na.rm = TRUE) ~ "Medium",
        TRUE ~ "Large"
      ),
      
      momentum_category = case_when(
        listener_momentum > 5 ~ "Strong Growth",
        listener_momentum > 0 ~ "Growth",
        listener_momentum > -5 ~ "Stable", 
        TRUE ~ "Decline"
      )
    )
  
  # Add some additional computed features
  ml_features <- ml_features %>%
    mutate(
      # Hour interaction features
      hour_weekend_interaction = hour * is_weekend,
      hour_live_interaction = hour * is_live,
      
      # Momentum acceleration (second derivative)
      momentum_acceleration = listener_momentum - lag(listener_momentum, 1, default = 0),
      
      # Audience engagement proxy
      engagement_score = case_when(
        performance_vs_baseline_pct > 10 ~ 3,  # High engagement
        performance_vs_baseline_pct > 0 ~ 2,   # Medium engagement
        performance_vs_baseline_pct > -10 ~ 1, # Low engagement
        TRUE ~ 0  # Very low engagement
      ),
      
      # Risk factors
      high_volatility = ifelse(listener_volatility > quantile(listener_volatility, 0.8, na.rm = TRUE), 1, 0),
      declining_trend = ifelse(listener_trend_6 < -10, 1, 0),
      
      # Feature for model training (next period's listener count)
      next_listeners = lead(main_total_listeners, 1),
      next_listener_change = next_listeners - main_total_listeners,
      next_listener_change_pct = (next_listener_change / pmax(main_total_listeners, 1)) * 100
    )
  
  # Clean up any infinite or invalid values
  ml_features <- ml_features %>%
    mutate(across(where(is.numeric), ~ifelse(is.infinite(.x) | is.nan(.x), 0, .x)))
  
  cat("✅ ML features prepared successfully!\n")
  cat("   📊 Observations:", nrow(ml_features), "\n")
  cat("   🔧 Features created:", ncol(ml_features) - ncol(data), "new features\n")
  cat("   🎵 Unique tracks:", length(unique(ml_features$track_key)), "\n")
  cat("   🎨 Unique artists:", length(unique(ml_features$artist_key)), "\n")
  cat("   🎼 Unique genres:", length(unique(ml_features$genre_key)), "\n")
  
  # Show sample of key features
  key_features <- c("main_total_listeners", "listener_momentum", "listener_trend_3", 
                    "performance_vs_baseline", "engagement_score", "hour_category")
  available_features <- intersect(key_features, names(ml_features))
  
  if (length(available_features) > 0) {
    cat("   📈 Sample of key features:\n")
    sample_data <- ml_features %>%
      slice_tail(n = 3) %>%
      select(datetime, all_of(available_features))
    
    print(sample_data)
  }
  
  return(ml_features)
}

# =============================================================================
# UNIFIED CURRENT CONTEXT ANALYZER
# =============================================================================

analyze_current_context <- function(ml_features = NULL, force_fresh_data = TRUE, minutes_back = 360) {
  
  # ==========================================================================
  # Unified function to analyze current radio context with optional fresh data fetch.
  #
  # Parameters:
  # - ml_features: Existing processed data (if available)
  # - force_fresh_data: If TRUE, fetches latest data from SQL first
  # - minutes_back: How far back to look for fresh data (default 6 hours)
  #
  # Returns:
  # - Comprehensive current context analysis including engagement, trends, risk assessment
  # =========================================================================
  
  # cat("⚡ ANALYZING CURRENT CONTEXT...\n")
  
  # =========================================================================
  # STEP 1: GET THE DATA (FRESH FROM SQL OR USE EXISTING)
  # =========================================================================
  
  if (force_fresh_data) {
    cat("🔄 Fetching fresh data from SQL...\n")
    
    if (!exists("REALTIME_UPDATE_ENABLED") || !REALTIME_UPDATE_ENABLED) {
      cat("⚠️ Real-time updates disabled. Using existing data.\n")
      force_fresh_data <- FALSE
    } else {
      # Fetch fresh data from database
      tryCatch({
        con <- create_sql_connection(connection_name = "current_context")
        
        if (is.null(con)) {
          cat("❌ Database connection failed. Using existing data.\n")
          force_fresh_data <- FALSE
        } else {
          # Calculate time window for fresh data
          cutoff_time <- Sys.time() - as.difftime(minutes_back, units = "mins")
          cutoff_datetime <- format(cutoff_time, "%Y-%m-%d %H:%M:%S")
          
          # Query for latest data
          latest_query <- paste0("
            SELECT * FROM ", DB_TABLE, "
            WHERE CONCAT(date, ' ', time) >= '", cutoff_datetime, "'
            ORDER BY date DESC, time DESC
            LIMIT ", minutes_back * 2)
          
          cat("   📡 Querying SQL for data since", cutoff_datetime, "\n")
          
          # Execute query
          latest_data <- dbGetQuery(con, latest_query)
          dbDisconnect(con)
          
          if (nrow(latest_data) == 0) {
            cat("❌ No recent data found in SQL. Using existing data.\n")
            force_fresh_data <- FALSE
          } else {
            # Process the fresh data (same preprocessing as main data)
            latest_data <- latest_data %>%
              mutate(
                datetime = as.POSIXct(paste(date, time), format = "%Y-%m-%d %H:%M", tz = "UTC"),
                date = as.Date(date),
                hour = hour(datetime),
                minute = minute(datetime),
                weekday = weekdays(date),
                main_total_listeners = main_stream1 + main_stream2,
                day_type = ifelse(weekday %in% c("Saturday", "Sunday"), "Weekend", "Weekday"),
                
                # Create additional ML features if needed
                track_key = paste(main_artist, main_song, sep = " - "),
                artist_key = main_artist,
                genre_key = ifelse(!is.na(main_genre) & main_genre != "" & main_genre != "-", 
                                   main_genre, "Unknown"),
                
                # Basic momentum calculations
                listener_momentum = main_total_listeners - lag(main_total_listeners, 3),
                is_live = ifelse(!is.na(main_recorded) & main_recorded == 0, 1, 0)
              ) %>%
              arrange(desc(datetime))
            
            # Use this fresh data as our ml_features
            ml_features <- latest_data
            
            cat("✅ Retrieved", nrow(latest_data), "fresh records from SQL\n")
            cat("   📊 Latest timestamp:", format(latest_data$datetime[1], "%Y-%m-%d %H:%M:%S"), "\n")
          }
        }
        
      }, error = function(e) {
        cat("❌ Database fetch failed:", e$message, ". Using existing data.\n")
        force_fresh_data <- FALSE
      })
    }
  }
  
  # If we don't have fresh data and no ml_features provided, we can't proceed
  if (is.null(ml_features) || nrow(ml_features) == 0) {
    cat("❌ No data available for context analysis\n")
    return(NULL)
  }
  
  # =========================================================================
  # STEP 2: EXTRACT CURRENT SESSION INFORMATION
  # =========================================================================
  
  # Get the most recent data point for current context
  current_session <- ml_features %>%
    arrange(desc(datetime)) %>%
    slice_head(n = 1)
  
  if (nrow(current_session) == 0) {
    cat("❌ No current session data available\n")
    return(NULL)
  }
  
  # Extract current context variables
  current_hour <- current_session$hour
  current_day_type <- current_session$day_type
  current_listeners <- current_session$main_total_listeners
  current_show <- if("main_showname" %in% names(current_session)) current_session$main_showname else "Unknown"
  current_presenter <- if("main_presenter" %in% names(current_session)) current_session$main_presenter else "Unknown"
  current_weather <- if("weather_condition" %in% names(current_session)) current_session$weather_condition else NA
  current_is_live <- if("is_live" %in% names(current_session)) current_session$is_live else 0
  
  # =========================================================================
  # STEP 3: ANALYZE RECENT TRAJECTORY (LAST 6 SESSIONS)
  # =========================================================================
  
  recent_trajectory <- ml_features %>%
    arrange(desc(datetime)) %>%
    slice_head(n = 6) %>%
    arrange(datetime) %>%
    mutate(
      trajectory_position = row_number(),
      trajectory_trend = main_total_listeners - lag(main_total_listeners, 1, default = main_total_listeners[1])    )
  
  # Calculate trajectory metrics
  trajectory_metrics <- list(
    current_listeners = current_listeners,
    trend_direction = case_when(
      mean(recent_trajectory$trajectory_trend, na.rm = TRUE) > 2 ~ "Strong Upward",
      mean(recent_trajectory$trajectory_trend, na.rm = TRUE) > 0 ~ "Upward",
      mean(recent_trajectory$trajectory_trend, na.rm = TRUE) > -2 ~ "Stable",
      mean(recent_trajectory$trajectory_trend, na.rm = TRUE) > -5 ~ "Downward",
      TRUE ~ "Strong Downward"
    ),
    momentum = mean(recent_trajectory$trajectory_trend, na.rm = TRUE),
    volatility = sd(recent_trajectory$main_total_listeners, na.rm = TRUE),
    trajectory_consistency = sd(recent_trajectory$trajectory_trend, na.rm = TRUE)
  )
  
  # =========================================================================
  # STEP 4: HISTORICAL BASELINE ANALYSIS
  # =========================================================================
  
  # Get historical baseline for this context (hour + day type)
  historical_baseline <- ml_features %>%
    filter(hour == current_hour, day_type == current_day_type) %>%
    summarise(
      baseline_listeners = mean(main_total_listeners, na.rm = TRUE),
      baseline_sd = sd(main_total_listeners, na.rm = TRUE),
      baseline_sessions = n(),
      .groups = 'drop'
    )
  
  # Calculate performance vs baseline
  performance_vs_baseline <- if (nrow(historical_baseline) > 0 && historical_baseline$baseline_sessions >= 10) {
    list(
      vs_baseline_absolute = current_listeners - historical_baseline$baseline_listeners,
      vs_baseline_percentage = ((current_listeners - historical_baseline$baseline_listeners) / 
                                  pmax(historical_baseline$baseline_listeners, 1)) * 100,
      z_score = (current_listeners - historical_baseline$baseline_listeners) / 
        pmax(historical_baseline$baseline_sd, 1),
      baseline_available = TRUE
    )
  } else {
    list(
      vs_baseline_absolute = 0,
      vs_baseline_percentage = 0,
      z_score = 0,
      baseline_available = FALSE
    )
  }
  
  # =========================================================================
  # STEP 5: SHOW CONTEXT ANALYSIS
  # =========================================================================
  
  show_context <- if (!is.na(current_show) && current_show != "" && current_show != "Unknown") {
    show_historical <- ml_features %>%
      filter(main_showname == current_show, hour == current_hour) %>%
      summarise(
        show_avg_listeners = mean(main_total_listeners, na.rm = TRUE),
        show_sessions = n(),
        show_best = max(main_total_listeners, na.rm = TRUE),
        show_worst = min(main_total_listeners, na.rm = TRUE),
        .groups = 'drop'
      )
    
    if (nrow(show_historical) > 0 && show_historical$show_sessions >= 5) {
      list(
        show_performance = "Available",
        vs_show_avg = current_listeners - show_historical$show_avg_listeners,
        vs_show_avg_pct = ((current_listeners - show_historical$show_avg_listeners) / 
                             pmax(show_historical$show_avg_listeners, 1)) * 100,
        show_percentile = rank(c(show_historical$show_worst, current_listeners, show_historical$show_best))[2] / 3
      )
    } else {
      list(show_performance = "Limited_Data", vs_show_avg = 0, vs_show_avg_pct = 0, show_percentile = 0.5)
    }
  } else {
    list(show_performance = "Unknown", vs_show_avg = 0, vs_show_avg_pct = 0, show_percentile = 0.5)
  }
  
  # =========================================================================
  # STEP 6: WEATHER CONTEXT ANALYSIS (IF AVAILABLE)
  # =========================================================================
  
  weather_context <- if (!is.na(current_weather) && current_weather != "") {
    weather_historical <- ml_features %>%
      filter(weather_condition == current_weather, hour == current_hour, day_type == current_day_type) %>%
      summarise(
        weather_avg_listeners = mean(main_total_listeners, na.rm = TRUE),
        weather_sessions = n(),
        .groups = 'drop'
      )
    
    if (nrow(weather_historical) > 0 && weather_historical$weather_sessions >= 5) {
      list(
        weather_effect = "Available",
        vs_weather_avg = current_listeners - weather_historical$weather_avg_listeners,
        weather_factor = weather_historical$weather_avg_listeners / historical_baseline$baseline_listeners
      )
    } else {
      list(weather_effect = "Limited_Data", vs_weather_avg = 0, weather_factor = 1.0)
    }
  } else {
    list(weather_effect = "Unknown", vs_weather_avg = 0, weather_factor = 1.0)
  }
  
  # =========================================================================
  # STEP 7: PRESENTER CONTEXT (IF AVAILABLE)
  # =========================================================================
  
  presenter_context <- if (!is.na(current_presenter) && current_presenter != "" && current_presenter != "Unknown") {
    presenter_historical <- ml_features %>%
      filter(main_presenter == current_presenter, hour == current_hour) %>%
      summarise(
        presenter_avg_listeners = mean(main_total_listeners, na.rm = TRUE),
        presenter_sessions = n(),
        .groups = 'drop'
      )
    
    if (nrow(presenter_historical) > 0 && presenter_historical$presenter_sessions >= 10) {
      list(
        presenter_performance = "Available",
        vs_presenter_avg = current_listeners - presenter_historical$presenter_avg_listeners,
        presenter_factor = presenter_historical$presenter_avg_listeners / historical_baseline$baseline_listeners
      )
    } else {
      list(presenter_performance = "Limited_Data", vs_presenter_avg = 0, presenter_factor = 1.0)
    }
  } else {
    list(presenter_performance = "Unknown", vs_presenter_avg = 0, presenter_factor = 1.0)
  }
  
  # =========================================================================
  # STEP 8: ENGAGEMENT LEVEL AND RISK ASSESSMENT
  # =========================================================================
  
  # Determine audience engagement level
  engagement_level <- case_when(
    performance_vs_baseline$z_score > 2 ~ "Exceptional",
    performance_vs_baseline$z_score > 1 ~ "High",
    performance_vs_baseline$z_score > -0.5 ~ "Normal",
    performance_vs_baseline$z_score > -1.5 ~ "Below Average",
    TRUE ~ "Poor"
  )
  
  # Risk assessment for next track selection
  risk_tolerance <- case_when(
    trajectory_metrics$trend_direction %in% c("Strong Upward", "Upward") ~ "High",
    trajectory_metrics$trend_direction == "Stable" & engagement_level %in% c("High", "Exceptional") ~ "Medium-High",
    trajectory_metrics$trend_direction == "Stable" ~ "Medium",
    trajectory_metrics$trend_direction == "Downward" ~ "Low",
    TRUE ~ "Very Low"
  )
  
  # =========================================================================
  # STEP 9: COMPILE COMPREHENSIVE CONTEXT SUMMARY
  # =========================================================================
  
  context_summary <- list(
    # Time context
    current_hour = current_hour,
    current_day_type = current_day_type,
    
    # Audience metrics
    current_listeners = current_listeners,
    trajectory = trajectory_metrics,
    recent_trend = if(nrow(recent_trajectory) >= 4) {
      current_listeners - recent_trajectory$main_total_listeners[4]
    } else { 0 },
    
    medium_trend = if(nrow(recent_trajectory) >= 6) {
      current_listeners - recent_trajectory$main_total_listeners[6]  
    } else { 0 },
    
    listener_volatility = if(nrow(recent_trajectory) >= 6) {
      sd(recent_trajectory$main_total_listeners[1:6], na.rm = TRUE)
    } else { 0 },
    
    momentum_acceleration = if(nrow(recent_trajectory) >= 4) {
      recent_trend_calc <- current_listeners - recent_trajectory$main_total_listeners[4]
      prev_trend <- recent_trajectory$main_total_listeners[4] - recent_trajectory$main_total_listeners[min(6, nrow(recent_trajectory))]
      recent_trend_calc - prev_trend
    } else { 0 },
    performance = performance_vs_baseline,
    engagement_level = engagement_level,
    
    # Show context
    current_show = current_show,
    current_presenter = current_presenter,
    is_live = current_is_live,
    show_context = show_context,
    presenter_context = presenter_context,
    
    # Environmental context
    current_weather = current_weather,
    weather_context = weather_context,
    
    # Strategic context
    risk_tolerance = risk_tolerance,
    
    # Data metadata
    data_freshness = if(force_fresh_data) "Fresh" else "Cached",
    analysis_time = Sys.time(),
    data_recency = current_session$datetime,
    
    # Store recent data for other functions
    recent_data = recent_trajectory
  )
  
  # Update global context variable
  current_context <<- context_summary
  
  # =========================================================================
  # STEP 10: SUMMARY OUTPUT
  # =========================================================================
  
  cat("\n✅ CURRENT CONTEXT:\n")
  cat("   👥 Current listeners:", current_listeners, "\n")
  cat("   📈 Trend direction:", trajectory_metrics$trend_direction, "\n")
  cat("   🎯 Engagement level:", engagement_level, "\n")
  cat("   🎲 Risk tolerance:", risk_tolerance, "\n")
  cat("   📺 Show context:", show_context$show_performance, "\n")
  cat("   🌤️ Weather context:", weather_context$weather_effect, "\n")
  cat("   🎤 Presenter context:", presenter_context$presenter_performance, "\n")
  cat("   💾 Data source:", if(force_fresh_data) "Fresh SQL" else "Cached", "\n")
  
  return(TRUE)
}

    # =========================================================================
    # CONVENIENCE WRAPPER FUNCTIONS FOR UNIFIED CURRENT CONTEXT ANALYZER
    # =========================================================================

# Quick context check without fetching fresh data
check_current_context <- function() {
  analyze_current_context(ml_features = ml_features, force_fresh_data = FALSE)
}

# Force fresh context update
refresh_current_context <- function() {
  analyze_current_context(force_fresh_data = TRUE)
}

# Get context status
current_context_status <- function() {
  if (!exists("current_context") || is.null(current_context)) {
    cat("❌ No current context available. Run analyze_current_context()\n")
    return(FALSE)
  }
  
  data_age <- difftime(Sys.time(), current_context$analysis_time, units = "mins")
  
  cat("📊 CURRENT CONTEXT STATUS:\n")
  cat("   Analysis age:", round(as.numeric(data_age), 1), "minutes\n")
  cat("   Data source:", current_context$data_freshness, "\n")
  cat("   Current listeners:", current_context$current_listeners, "\n")
  cat("   Engagement:", current_context$engagement_level, "\n")
  cat("   Risk tolerance:", current_context$risk_tolerance, "\n")
  
  if (data_age > 15) {
    cat("⚠️ Context is getting stale - consider refreshing\n")
  }
  
  return(TRUE)
}

cat("⚡ UNIFIED CURRENT CONTEXT ANALYZER LOADED!\n")
cat("Usage:\n")
cat("  analyze_current_context()                    # Fresh data + full analysis\n")
cat("  analyze_current_context(force_fresh_data = FALSE)  # Use cached data\n")
cat("  check_current_context()                     # Quick cached analysis\n")
cat("  refresh_current_context()                   # Force fresh update\n")
cat("  current_context_status()                    # Check context status\n")

# =============================================================================
# ML DJ SYSTEM
# =============================================================================


# =============================================================================
# DYNAMIC GENRE TARGET GENERATION
# =============================================================================

generate_dynamic_genre_targets <- function(min_threshold = 0.01, smoothing_factor = 0.8) {
  cat("🎯 GENERATING DYNAMIC GENRE TARGETS FROM STATION DATA...\n")
  
  # Check if statistics are available
  if (!exists("main_station_genre_distribution") || is.null(main_station_genre_distribution)) {
    cat("⚠️ main_station_genre_distribution not found - running update_statistics()...\n")
    tryCatch({
      update_statistics(data)
    }, error = function(e) {
      cat("❌ Failed to update statistics:", e$message, "\n")
      cat("🔄 Falling back to hardcoded genre targets\n")
      return(get_fallback_genre_targets())
    })
  }
  
  if (!exists("main_station_genre_distribution") || is.null(main_station_genre_distribution)) {
    cat("❌ Still no genre distribution available - using fallback\n")
    return(get_fallback_genre_targets())
  }
  
  # Convert genre distribution to targets
  genre_stats <- main_station_genre_distribution
  
  if (is.null(genre_stats) || nrow(genre_stats) == 0) {
    cat("❌ Genre distribution is empty - using fallback\n")
    return(get_fallback_genre_targets())
  }
  
  cat(sprintf("📊 Found %d genres in station distribution\n", nrow(genre_stats)))
  
  # Calculate proportions (assuming genre_stats has 'percentage' or 'proportion' column)
  if ("percentage" %in% names(genre_stats)) {
    genre_stats$proportion <- genre_stats$percentage / 100
  } else if ("proportion" %in% names(genre_stats)) {
    # Already have proportions
  } else if ("count" %in% names(genre_stats)) {
    # Calculate from counts
    genre_stats$proportion <- genre_stats$count / sum(genre_stats$count)
  } else {
    cat("❌ Cannot determine proportions from genre stats - using fallback\n")
    return(get_fallback_genre_targets())
  }
  
  # Apply smoothing to avoid extreme concentrations
  # This prevents one genre from dominating too much
  genre_stats$smoothed_proportion <- genre_stats$proportion * smoothing_factor + 
    (1 - smoothing_factor) * (1 / nrow(genre_stats))
  
  # Filter out genres below minimum threshold
  significant_genres <- genre_stats %>%
    filter(smoothed_proportion >= min_threshold) %>%
    arrange(desc(smoothed_proportion))
  
  # Group very small genres into "Other"
  small_genres <- genre_stats %>%
    filter(smoothed_proportion < min_threshold)
  
  if (nrow(small_genres) > 0) {
    other_proportion <- sum(small_genres$smoothed_proportion)
    significant_genres <- rbind(significant_genres, 
                                data.frame(main_genre = "Other", 
                                           proportion = NA,
                                           smoothed_proportion = other_proportion))
  }
  
  # Renormalize to ensure total = 1.0
  significant_genres$final_proportion <- significant_genres$smoothed_proportion / 
    sum(significant_genres$smoothed_proportion)
  
  # Convert to named list format for compatibility
  dynamic_targets <- setNames(significant_genres$final_proportion, 
                              significant_genres$main_genre)
  
  # Display results
  cat("🎵 DYNAMIC GENRE TARGETS:\n")
  for (i in 1:length(dynamic_targets)) {
    cat(sprintf("   %s: %.1f%%\n", names(dynamic_targets)[i], dynamic_targets[i] * 100))
  }
  
  cat(sprintf("📊 Total genres: %d (including %.1f%% 'Other')\n", 
              length(dynamic_targets), 
              ifelse("Other" %in% names(dynamic_targets), dynamic_targets[["Other"]] * 100, 0)))
  
  return(dynamic_targets)
}

# =============================================================================
# FALLBACK FUNCTION (HARDCODED TARGETS)
# =============================================================================

get_fallback_genre_targets <- function() {
  cat("🔄 Using fallback hardcoded genre targets\n")
  
  return(list(
    "Classic Rock" = 0.15,
    "Pop Rock" = 0.12,
    "Rock" = 0.10,
    "Power Pop" = 0.10,
    "Synth-Pop" = 0.08,
    "Folk Rock" = 0.07,
    "Soft Rock" = 0.05,
    "Alternative" = 0.05,
    "Reggae" = 0.05,
    "Folk" = 0.05,
    "Funk" = 0.05,
    "New Wave" = 0.05,
    "Soul" = 0.03,
    "Blues" = 0.02,
    "Other" = 0.03
  ))
}

# =============================================================================
# DJ_THINKING_CONFIG GENERATION
# =============================================================================

create_dynamic_dj_config <- function() {
  cat("🤖 CREATING DYNAMIC DJ THINKING CONFIG...\n")
  
  # Generate dynamic genre targets
  dynamic_genre_targets <- generate_dynamic_genre_targets()
  
  # Create config with dynamic targets
  DJ_THINKING_CONFIG <- list(
    genre_targets = dynamic_genre_targets,
    
    # Keep existing exploration settings
    exploration_by_hour = list(
      "morning" = 0.15,      # 15% adventurous during morning drive
      "midday" = 0.30,       # 30% adventurous during midday
      "afternoon" = 0.25,    # 25% adventurous during afternoon
      "evening" = 0.20,      # 20% adventurous during evening
      "night" = 0.40         # 40% adventurous during late night
    ),
    
    # How far back to look for genre balance (in tracks)
    genre_balance_window = 10,
    
    # Minimum time between same artist plays (in hours)
    artist_spacing = 2.0,
    
    # Risk tolerance by listener trend
    risk_by_trend = list(
      "growing" = 0.30,      # More adventurous when growing
      "stable" = 0.20,       # Moderate when stable
      "declining" = 0.10     # Conservative when declining
    )
  )
  
  return(DJ_THINKING_CONFIG)
}

# =============================================================================
# AI DJ SYSTEM ENTRY POINTS
# =============================================================================

# =============================================================================
# MODE-AWARE MAIN EXECUTION FUNCTION
# =============================================================================

run_radio_intel_ai <- function() {
  
  DJ_THINKING_CONFIG <<- create_dynamic_dj_config()
  
  # Mode-specific settings
  PERPETUAL_TRACK_COUNT <<- 1      # Number of tracks to generate in perpetual mode
  ASSISTANT_RECOMMENDATION_COUNT <<- 5  # Number of recommendations for DJ assistant
  
  FUZZY_DJ_CONFIG <<- list(
    # Score bands for fuzzy thinking (instead of precise rankings)
    score_bands = list(
      "excellent" = c(1.2, Inf),
      "very_good" = c(1.0, 1.2),
      "good" = c(0.8, 1.0),
      "okay" = c(0.6, 0.8),
      "poor" = c(0, 0.6)
    ),
    
    # Selection probabilities within each band
    band_selection_weights = list(
      "excellent" = 1.0,
      "very_good" = 0.8,
      "good" = 0.6,
      "okay" = 0.3,
      "poor" = 0.1
    ),
    
    # Novelty bonus settings
    novelty_settings = list(
      # How much to boost tracks based on recency of artist/track plays
      recency_bonus_max = 0.3,        # Max 30% bonus for fresh tracks
      artist_spacing_target = 8,       # Prefer artists not played in last 8 tracks
      track_spacing_target = 20,       # Prefer tracks not played in last 20 tracks
      
      # Exploration randomness
      exploration_randomness = 0.2,    # 20% random variation in scores
      serendipity_factor = 0.1         # 10% chance of random "gut feeling" picks
    ),
    
    # Genre saturation awareness
    genre_saturation = list(
      recent_window = 8,               # Look at last 8 tracks for saturation
      saturation_penalty = 0.5,        # 50% penalty if genre is saturated
      saturation_threshold = 0.4       # 40%+ = saturated
    )
  )
  
  # DJ conversational style
  style <- "dry_witty_radio6"
  
  cat("🎙️ RADIO INTEL AI STARTING...\n")
  cat(sprintf("🔧 Runtime Mode: %s\n", AI_RUNTIME_MODE))
  
  analyze_current_context(ml_features = ml_features, force_fresh_data = TRUE)
  
  # Run based on selected mode
  switch(AI_RUNTIME_MODE,
         "timing" = run_timing_mode(),
         "perpetual" = run_perpetual_mode(), 
         "assistant" = run_assistant_mode(),
         {
           cat(sprintf("❌ Unknown runtime mode: %s\n", AI_RUNTIME_MODE))
           cat("   Valid modes: timing, perpetual, assistant\n")
           return(NULL)
         }
  )
}

# =============================================================================
# TIMED MODE
# =============================================================================

run_timing_mode <- function() {
  cat(paste0("🎯 TIMING MODE: Precise ", TIME_MARK_BLOCK_LENGTH, "-minute block generation\n"))
  
  # Get AI recommendations
  fuzzy_recs <- get_ai_recommendations()
  if (is.null(fuzzy_recs) || nrow(fuzzy_recs) == 0) {
    cat("❌ No recommendations received\n")
    return(NULL)
  }
  
  # Process tracks with durations
  track_list_with_durations <- add_durations_to_tracks(fuzzy_recs)
  
  # Set intro_type to 1 for timing mode (normal intros)
  track_list_with_durations$intro_type <- 1
  
  track_list_with_durations <- create_double_play_fat_tracks(track_list_with_durations)
  
  # Generate intros with measured durations
  candidate_track_list <- generate_and_measure_block_intros(track_list_with_durations)
  
  candidate_intro_durations <- sapply(candidate_track_list$intro_details, function(x) x$actual_duration)
  candidate_intro_filenames <- sapply(candidate_track_list$intro_details, function(x) x$wav_filename)
  candidate_intro_full_paths <- sapply(candidate_track_list$intro_details, function(x) x$wav_filepath)
  candidate_intro_texts <- sapply(candidate_track_list$intro_details, function(x) x$intro_text)
  
  track_list_with_durations$estimated_intro_duration <- candidate_intro_durations
  
  track_list_with_durations$total_estimated_duration <- 
    track_list_with_durations$track_duration + candidate_intro_durations
  
  track_list_with_durations$effective_duration_with_fades <- 
    track_list_with_durations$track_duration + candidate_intro_durations - CROSS_FADE_IN - CROSS_FADE_OUT
  
  track_list_with_durations$track_duration_nett <- 
    track_list_with_durations$track_duration - CROSS_FADE_IN - CROSS_FADE_OUT
  
  track_list_with_durations$intro_filenames <- candidate_intro_filenames
  track_list_with_durations$intro_full_path <- candidate_intro_full_paths
  
  track_list_with_durations$intro_text <- candidate_intro_texts
  
  # Find optimal combination and apply surgical timing
  selected_block <- find_optimal_track_combination(track_list_with_durations)
  
  filled_result <- fill_timing_gaps(selected_block, selected_block$estimated_intro_duration)
  
  filled_result$complete_block <- decompress_fat_tracks(filled_result$complete_block)
  
  # Build meaningful context for the block
  if (!is.null(filled_result$complete_block) && length(filled_result$complete_block) > 0) {
    
    block_context <- list(
      day_type = if(exists("current_context") && !is.null(current_context$current_day_type)) current_context$current_day_type else "Unknown",
      recent_trend = if(exists("current_context") && !is.null(current_context$recent_trend)) current_context$recent_trend else 0,
      weather = if(exists("current_context") && !is.null(current_context$current_weather)) current_context$current_weather else "Unknown",
      listener_volatility = if(exists("current_context") && !is.null(current_context$listener_volatility)) current_context$listener_volatility else 0,
      is_live = if(exists("current_context") && !is.null(current_context$is_live)) as.logical(current_context$is_live) else FALSE,
      block_size = length(filled_result$complete_block),
      current_listeners = if(exists("current_context") && !is.null(current_context$current_listeners)) current_context$current_listeners else 0
    )
    
    # Log only track elements (not intros/fillers)
    for (i in 1:length(filled_result$complete_block)) {
      element <- filled_result$complete_block[[i]]
      
      if (!is.null(element$type) && element$type == "track") {
        position_context <- block_context
        position_context$position <- i
        position_context$element_type <- "track"
        
        record_ai_dj_selection(
          artist = if(!is.null(element$artist)) element$artist else "Unknown",
          song = if(!is.null(element$song)) element$song else "Unknown",
          genre = if(!is.null(element$main_genre)) element$main_genre else "Unknown",
          introduction = if(!is.null(element$intro_text)) element$intro_text else "",
          decision_reason = paste("Timed block position", i),
          algorithm = "block_scheduler",
          context_factors = toJSON(position_context, auto_unbox = TRUE),
          current_listeners = if(exists("current_context") && !is.null(current_context$current_listeners)) current_context$current_listeners else 0
        )
      }
    }
  }

  # Display results
  display_complete_block(filled_result$complete_block)
  
  return(filled_result)
}

# =============================================================================
# PERPETUAL MODE (CONTINUOUS OPERATION)
# =============================================================================

run_perpetual_mode <- function() {
  cat("🔄 PERPETUAL MODE: Continuous single track generation\n")
  
  # Get AI recommendations (more than needed for selection)
  fuzzy_recs <- get_ai_recommendations(limit = PERPETUAL_TRACK_COUNT * 3)
  if (is.null(fuzzy_recs) || nrow(fuzzy_recs) == 0) {
    cat("❌ No recommendations received\n")
    return(NULL)
  }
  
  # Process tracks with durations
  track_list_with_durations <- add_durations_to_tracks(fuzzy_recs)
  
  # Set intro_type to 3 for perpetual mode (allows idents to be tacked on)
  track_list_with_durations$intro_type <- 3
  
  # Select just the top track (instead of optimal combination)
  valid_tracks <- track_list_with_durations[!is.na(track_list_with_durations$track_duration), ]
  selected_single_track <- valid_tracks[order(-valid_tracks$fuzzy_dj_score), ][1, , drop = FALSE]
  
  # Use the SAME PIPELINE as timing mode:
  candidate_track_list <- generate_and_measure_block_intros(selected_single_track)
  
  candidate_intro_durations <- sapply(candidate_track_list$intro_details, function(x) x$actual_duration)
  candidate_intro_filenames <- sapply(candidate_track_list$intro_details, function(x) x$wav_filename)
  candidate_intro_full_paths <- sapply(candidate_track_list$intro_details, function(x) x$wav_filepath)
  candidate_intro_texts <- sapply(candidate_track_list$intro_details, function(x) x$intro_text)
  
  selected_single_track$estimated_intro_duration <- candidate_intro_durations
  
  selected_single_track$total_estimated_duration <- 
    selected_single_track$track_duration + candidate_intro_durations
  
  selected_single_track$effective_duration_with_fades <- 
    selected_single_track$track_duration + candidate_intro_durations - CROSS_FADE_IN - CROSS_FADE_OUT
  
  selected_single_track$track_duration_nett <- 
    selected_single_track$track_duration - CROSS_FADE_IN - CROSS_FADE_OUT
  
  selected_single_track$intro_filenames <- candidate_intro_filenames
  selected_single_track$intro_full_path <- candidate_intro_full_paths
  
  selected_single_track$intro_text <- candidate_intro_texts
  
  selected_single_track$optimization_improved <- NULL
  selected_single_track$block_position <- NULL
  selected_single_track$total_music_duration <- NULL
  selected_single_track$talk_time_needed <- NULL
  
  # Pass through greedy allocator and surgical timer (they handle perpetual mode)
  filled_result <- fill_timing_gaps(selected_single_track, selected_single_track$estimated_intro_duration)
  
  # Build meaningful context for the block
  if (!is.null(filled_result$complete_block) && length(filled_result$complete_block) > 0) {
    
    perpetual_context <- list(
      day_type = if(exists("current_context") && !is.null(current_context$current_day_type)) current_context$current_day_type else "Unknown",
      recent_trend = if(exists("current_context") && !is.null(current_context$recent_trend)) current_context$recent_trend else 0,
      weather = if(exists("current_context") && !is.null(current_context$current_weather)) current_context$current_weather else "Unknown",
      listener_volatility = if(exists("current_context") && !is.null(current_context$listener_volatility)) current_context$listener_volatility else 0,
      is_live = if(exists("current_context") && !is.null(current_context$is_live)) as.logical(current_context$is_live) else FALSE,
      block_size = length(filled_result$complete_block),
      mode = "perpetual",
      current_listeners = if(exists("current_context") && !is.null(current_context$current_listeners)) current_context$current_listeners else 0
    )
    
    # Log only track elements (not intros/fillers)
    for (i in 1:length(filled_result$complete_block)) {
      element <- filled_result$complete_block[[i]]
      if (!is.null(element$type) && element$type == "track") {
          record_ai_dj_selection(
            artist = if(!is.null(element$artist)) element$artist else "Unknown",
            song = if(!is.null(element$song)) element$song else "Unknown", 
            genre = if(!is.null(element$main_genre)) element$main_genre else "Unknown",
            introduction = if(!is.null(element$intro_text)) element$intro_text else "",
            decision_reason = "Perpetual mode selection",
            algorithm = "perpetual_dj",
            context_factors = toJSON(perpetual_context, auto_unbox = TRUE),
            current_listeners = if(exists("current_context") && !is.null(current_context$current_listeners)) current_context$current_listeners else 0
          )
          break
        }
      }
    }
  
  # Display results (same function as timing mode)
  display_complete_block(filled_result$complete_block)
  
  return(filled_result)  # Same structure as timing mode!
}

# =============================================================================
# ASSISTANT MODE (DJ HELPER)
# =============================================================================

run_assistant_mode <- function() {
  cat("🤝 ASSISTANT MODE: DJ recommendation helper\n")
  cat(sprintf("💡 Providing %d recommendations with technical details\n", ASSISTANT_RECOMMENDATION_COUNT))
  
  # Get AI recommendations
  fuzzy_recs <- get_ai_recommendations(limit = ASSISTANT_RECOMMENDATION_COUNT)
  if (is.null(fuzzy_recs) || nrow(fuzzy_recs) == 0) {
    cat("❌ No recommendations received\n")
    return(NULL)
  }
  
  # Process tracks with durations (no audio generation)
  track_list_with_durations <- add_durations_to_tracks(fuzzy_recs)
  
  # Filter to valid tracks only
  valid_tracks <- track_list_with_durations[!is.na(track_list_with_durations$track_duration), ]
  if (nrow(valid_tracks) == 0) {
    cat("❌ No valid tracks with durations found\n")
    return(NULL)
  }
  
  # Select top recommendations
  selected_recommendations <- valid_tracks[order(-valid_tracks$fuzzy_dj_score), ][1:min(ASSISTANT_RECOMMENDATION_COUNT, nrow(valid_tracks)), ]
  
  # Generate intro suggestions (text only, no audio)
  assistant_result <- generate_assistant_recommendations(selected_recommendations)
  
  # Display interactive recommendations
  display_assistant_output(assistant_result)
  
  return(assistant_result)
}

# =============================================================================
# ASSISTANT MODE FUNCTIONS
# =============================================================================

generate_assistant_recommendations <- function(selected_tracks) {
  cat("💡 Generating DJ assistant recommendations...\n")
  
  recommendations <- list()
  
  for (i in 1:nrow(selected_tracks)) {
    track <- selected_tracks[i, ]
    
    # Generate intro text (no audio) with SSML stripped
    intro_details <- get_and_save_dj_intro(track, intro_type = 1)
    
    # Strip SSML tags for DJ reading
    clean_intro <- if (!is.null(intro_details)) {
      strip_ssml_tags(intro_details$intro_text)
    } else {
      paste("Introduce", track$main_artist, "with", track$main_song)
    }
    
    recommendations[[i]] <- list(
      track = track,
      intro_text = clean_intro,
      is_top_pick = (i == 1),  # First track is top recommendation
      technical_notes = generate_technical_notes(track)
    )
  }
  
  return(list(
    mode = "assistant",
    recommendations = recommendations,
    top_pick = recommendations[[1]],
    alternatives = recommendations[-1]
  ))
}

strip_ssml_tags <- function(text) {
  if (is.null(text)) return("")
  
  # Remove SSML tags but keep the content
  clean_text <- gsub("<speak>|</speak>", "", text)
  clean_text <- gsub("<p>|</p>", "", clean_text)
  clean_text <- gsub("<break[^>]*>", " [pause] ", clean_text)
  clean_text <- gsub("<prosody[^>]*>|</prosody>", "", clean_text)
  clean_text <- gsub("<emphasis[^>]*>|</emphasis>", "", clean_text)
  clean_text <- gsub("<[^>]*>", "", clean_text)  # Remove any remaining tags
  
  # Clean up extra spaces
  clean_text <- gsub("\\s+", " ", clean_text)
  clean_text <- trimws(clean_text)
  
  return(clean_text)
}

generate_technical_notes <- function(track) {
  notes <- c()
  
  # Duration info
  duration_mins <- round(track$track_duration / 60, 1)
  notes <- c(notes, sprintf("Duration: %.1f min (%.0fs)", duration_mins, track$track_duration))
  
  # Tempo/energy suggestions
  if (track$track_duration < 180) {
    notes <- c(notes, "Short track - good for tempo building")
  } else if (track$track_duration > 300) {
    notes <- c(notes, "Long track - allows for break/prep time")
  }
  
  # AI confidence
  if (track$ai_confidence > 0.7) {
    notes <- c(notes, "High AI confidence - strong recommendation")
  } else if (track$ai_confidence < 0.3) {
    notes <- c(notes, "Lower confidence - consider context")
  }
  
  # File info
  if (!is.na(track$track_file_name)) {
    notes <- c(notes, sprintf("File: %s", track$track_file_name))
  }
  
  return(notes)
}

display_assistant_output <- function(result) {
  cat("\n🤝 DJ ASSISTANT RECOMMENDATIONS:\n")
  cat(paste0(rep("=", 70), collapse = ""), "\n")
  
  # Top pick
  top <- result$top_pick
  cat("🏆 TOP RECOMMENDATION:\n")
  cat(sprintf("🎵 %s - %s\n", top$track$main_artist, top$track$main_song))
  cat(sprintf("🤖 AI Score: %.3f | Genre: %s\n", top$track$fuzzy_dj_score, top$track$main_genre))
  cat(sprintf("💬 Suggested intro (** Written for AI DJ **): \"%s\"\n", top$intro_text))
  if (nchar(top$intro_text) > 100) cat("   ...(truncated)\n")
  
  cat("📋 Technical notes:\n")
  for (note in top$technical_notes) {
    cat(sprintf("   • %s\n", note))
  }
  
  cat("\n" , paste0(rep("-", 70), collapse = ""), "\n")
  
  # Alternatives
  if (length(result$alternatives) > 0) {
    cat("🎯 ALTERNATIVE PICKS:\n\n")
    
    for (i in 1:length(result$alternatives)) {
      alt <- result$alternatives[[i]]
      cat(sprintf("%d. %s - %s\n", i + 1, alt$track$main_artist, alt$track$main_song))
      cat(sprintf("   🤖 Score: %.3f | Genre: %s | Duration: %.1f min\n", 
                  alt$track$fuzzy_dj_score, alt$track$main_genre, alt$track$track_duration / 60))
      cat(sprintf("   💬 (** Written for AI DJ **)\"%s\"\n", alt$intro_text))
      if (nchar(alt$intro_text) > 80) cat("   ...\n")
      cat("\n")
    }
  }
  
  cat(paste0(rep("=", 70), collapse = ""), "\n")
  cat("💡 TIP: Copy and modify these intros for your on-air delivery!\n")
}

# =============================================================================
# GET FUZZY_DJ_RECOMMENDATIONS TO SUPPORT DIFFERENT MODES
# =============================================================================

get_ai_recommendations <- function(limit = NULL) {
  # Default parameters for different modes
  if (AI_RUNTIME_MODE == "timing") {
    # Timing mode needs more tracks for optimal selection
    n_recs <- round(((TIME_MARK_BLOCK_LENGTH * 60) / (240 - CROSS_FADE_IN - CROSS_FADE_OUT)) * 2,0) # Average song length + average intro length
    #n_recs <- if (!is.null(limit)) limit else 20
    tier <- "3"  
    style <- "dry_witty_radio6"
  } else if (AI_RUNTIME_MODE == "perpetual") {
    # Perpetual mode needs fewer but high-quality tracks
    n_recs <- if (!is.null(limit)) limit else (PERPETUAL_TRACK_COUNT * 3)
    tier <- "2"
    style <- "dry_witty_radio6"  
  } else if (AI_RUNTIME_MODE == "assistant") {
    # Assistant mode needs variety for DJ choice
    n_recs <- if (!is.null(limit)) limit else (ASSISTANT_RECOMMENDATION_COUNT)
    tier <- "1"
    style <- "dry_witty_radio6"
  } else {
    # Fallback
    n_recs <- if (!is.null(limit)) limit else 15
    tier <- "3"
    style <- "dry_witty_radio6"
  }
  
  cat(sprintf("🎯 Getting %d recommendations for %s mode\n", n_recs, AI_RUNTIME_MODE))
  
  # Call actual function
  return(get_fuzzy_dj_recommendations(n_recs, tier, style))
}

# =============================================================================
# FUZZY RECOMMENDATIONS
# =============================================================================

get_fuzzy_dj_recommendations <- function(n = 5, tier = 1, style = "dry_witty_radio6", force_update = FALSE) {
  cat("\n🌫️🎧 FUZZY DJ-THINKING AI (BAYESIAN STYLE) 🎧🌫️\n\n")
  cat("💭   The difference between 1.238 and 1.201 doesn't matter - \n")
  cat("     it's all good music... Rock on Tommy!\n\n")
  cat(paste0(rep("=", 75), collapse = ""), "\n\n")
  
  if (!exists("real_ai_system")) {
    cat("❌ Missing current_context or real_ai_system\n")
    real_ai_system <<- build_real_ai()
  }
  
  # Update context and get fresh data
  if (force_update) {
    success <- analyze_current_context(ml_features = ml_features, force_fresh_data = TRUE)
    if (!success) {
      cat("⚠️ Using cached data\n")
    }
  }
  
  # Get fresh data for analysis
  fresh_data <- if (exists("current_context") && "recent_data" %in% names(current_context)) {
    current_context$recent_data
  } else {
    data %>% arrange(desc(datetime)) %>% slice_head(n = 50)
  }
  
  # Step 1: Get basic DJ analysis (reuse existing functions)
  genre_analysis <- analyze_recent_genre_mix(FUZZY_DJ_CONFIG$genre_saturation$recent_window, fresh_data)
  genre_needs <- calculate_genre_needs(genre_analysis, current_context$current_hour)
  exploration_factor <- calculate_exploration_factor(
    current_context$current_hour,
    current_context$recent_trend,
    current_context$listener_volatility
  )
  
  # Step 2: Get candidate tracks and apply basic DJ scoring
  candidates <- real_ai_system$track_intelligence %>%
    filter(total_plays >= TOTAL_PLAYS_FILTER) %>%
    mutate(track_id = paste(main_artist, "-", main_song))
  
  # Filter out recent plays and artists
  if (exists("fresh_recent_plays_global") && nrow(fresh_recent_plays_global) > 0) {
    original_count <- nrow(candidates)
    candidates <- candidates %>%
      filter(!track_id %in% fresh_recent_plays_global$track_id)
    cat("🚫 Filtered out", original_count - nrow(candidates), "recently played tracks\n")
  }
  
  cat("🔍 Debug context values:\n")
  cat("recent_trend:", current_context$recent_trend, "\n")
  cat("current_day_type:", current_context$current_day_type, "\n") 
  cat("current_hour:", current_context$current_hour, "\n")
  
  # Apply basic DJ thinking (reuse existing logic)
  candidates_with_dj_scoring <- candidates %>%
    left_join(data %>% 
                filter(main_genre != "-", main_genre != "", main_genre != "Unknown") %>%
                select(main_artist, main_song, main_genre) %>% 
                distinct(), 
              by = c("main_artist", "main_song")) %>%
    filter(!is.na(main_genre), main_genre != "-", main_genre != "", main_genre != "Unknown") %>%
    left_join(genre_needs %>% select(main_genre, need_score), by = "main_genre") %>%
    mutate(
      need_score = ifelse(is.na(need_score), 0, need_score),
      
      # Base DJ score - with NaN handling
      base_ai_score = (case_when(
        current_context$recent_trend < -5 ~ works_in_decline * 2.0,
        current_context$recent_trend > 5 ~ works_in_growth * 1.5,
        TRUE ~ avg_success_rate
      ) * 0.5 + 
        case_when(
          current_context$current_day_type == "Weekend" ~ works_weekend,
          TRUE ~ works_weekday
        ) * 0.3 +
        case_when(
          current_context$current_hour >= 7 & current_context$current_hour <= 10 | 
            current_context$current_hour >= 16 & current_context$current_hour <= 19 ~ works_prime,
          TRUE ~ works_offpeak
        ) * 0.2) * ai_confidence,
      
      # Clean up any NaN or infinite values in base score
      base_ai_score = case_when(
        is.na(base_ai_score) | is.infinite(base_ai_score) ~ 0.5,  # Default to neutral score
        base_ai_score < 0 ~ 0.1,  # Minimum score
        TRUE ~ base_ai_score
      ),
      
      # Genre balance scoring
      genre_balance_score = case_when(
        need_score > 0.10 ~ 1.3,
        need_score > 0.05 ~ 1.15,
        need_score > 0 ~ 1.05,
        need_score > -0.05 ~ 1.0,
        TRUE ~ 0.8
      ),
      
      # Initial DJ score (before fuzzy processing) - with safety checks
      dj_ai_score = base_ai_score * genre_balance_score,
      
      # Final safety check for DJ score
      dj_ai_score = case_when(
        is.na(dj_ai_score) | is.infinite(dj_ai_score) ~ 0.5,
        dj_ai_score < 0 ~ 0.1,
        TRUE ~ dj_ai_score
      )
    ) %>%
    # Filter out any remaining problematic tracks
    filter(!is.na(dj_ai_score), 
           !is.infinite(dj_ai_score),
           !is.na(ai_confidence),
           ai_confidence > 0)
  
  if (nrow(candidates_with_dj_scoring) == 0) {
    cat("❌ No valid candidates after initial scoring\n")
    return(NULL)
  }
  
  cat(sprintf("📊 Initial AI candidates: %d tracks\n", nrow(candidates_with_dj_scoring)))
  
  cat("🚫 APPLYING RECENT PLAY FILTERING...\n")
  
  all_excluded_tracks <- character()
  
  # Get main station recent plays using sql_query function
  cat("   🔍 Checking main station recent plays...\n")
  cutoff_time <- format(Sys.time() - as.difftime(RECENT_PLAY_EXCLUSION_HOURS, units = "hours"), "%Y-%m-%d %H:%M:%S")
  
  main_query <- paste0("
  SELECT DISTINCT CONCAT(main_artist, ' - ', main_song) as track_id
  FROM ", DB_TABLE, "
  WHERE CONCAT(date, ' ', time) >= '", cutoff_time, "'
    AND main_artist IS NOT NULL AND main_song IS NOT NULL
    AND main_artist != '' AND main_song != ''
")
  
  main_recent <- sql_query(main_query, "main_station_recent_plays")
  
  if (!is.null(main_recent) && nrow(main_recent) > 0) {
    all_excluded_tracks <- c(all_excluded_tracks, main_recent$track_id)
    cat(sprintf("   🚫 Main station exclusions (%dh): %d tracks\n", 
                RECENT_PLAY_EXCLUSION_HOURS, nrow(main_recent)))
  } else {
    cat("   ✅ No main station recent plays found\n")
  }
  
  # Get AI DJ recent plays using sql_query function
  cat("   🔍 Checking AI DJ recent plays...\n")
  ai_query <- paste0("
  SELECT DISTINCT CONCAT(artist, ' - ', song) as track_id
  FROM ", AI_DJ_HISTORY_TABLE, "
  WHERE played_at >= DATE_SUB(NOW(), INTERVAL ", AI_DJ_EXCLUSION_DAYS, " DAY)
")
  
  ai_recent <- sql_query(ai_query, "ai_dj_recent_plays")
  
  if (!is.null(ai_recent) && nrow(ai_recent) > 0) {
    all_excluded_tracks <- c(all_excluded_tracks, ai_recent$track_id)
    cat(sprintf("   🚫 AI DJ exclusions (%dd): %d tracks\n", 
                AI_DJ_EXCLUSION_DAYS, nrow(ai_recent)))
  } else {
    cat("   ✅ No AI DJ recent plays found\n")
  }
  
  # Remove duplicates from exclusion list
  unique_excluded_tracks <- unique(all_excluded_tracks)
  
  if (length(unique_excluded_tracks) > 0) {
    cat(sprintf("   📊 Total unique exclusions: %d tracks\n", length(unique_excluded_tracks)))
    
    # Show some examples
    cat("   🎵 Sample exclusions:\n")
    for (i in 1:min(3, length(unique_excluded_tracks))) {
      cat(sprintf("      '%s'\n", unique_excluded_tracks[i]))
    }
    if (length(unique_excluded_tracks) > 3) {
      cat(sprintf("      ... and %d more\n", length(unique_excluded_tracks) - 3))
    }
    
    # Create track_id for candidates if it doesn't exist (using space-dash-space format to match DB)
    if (!"track_id" %in% names(candidates_with_dj_scoring)) {
      candidates_with_dj_scoring <- candidates_with_dj_scoring %>%
        mutate(track_id = paste(main_artist, " - ", main_song))  # Note: space-dash-space to match DB format
    }
    
    # Apply the exclusion filter
    original_count <- nrow(candidates_with_dj_scoring)
    
    candidates_with_dj_scoring <- candidates_with_dj_scoring %>%
      filter(!track_id %in% unique_excluded_tracks)
    
    filtered_count <- nrow(candidates_with_dj_scoring)
    excluded_count <- original_count - filtered_count
    
    cat(sprintf("   📊 Filtering results: %d → %d candidates (%d excluded)\n", 
                original_count, filtered_count, excluded_count))
    
    if (excluded_count > 0) {
      cat("   🚫 Successfully excluded recent plays!\n")
      
      # Show which candidates were actually excluded (for debugging)
      excluded_candidates <- candidates_with_dj_scoring %>%
        mutate(temp_track_id = paste(main_artist, " - ", main_song)) %>%
        filter(temp_track_id %in% unique_excluded_tracks) %>%
        select(-temp_track_id)
      
      if (nrow(excluded_candidates) > 0) {
        cat("   🎯 Example excluded candidates:\n")
        for (i in 1:min(3, nrow(excluded_candidates))) {
          cat(sprintf("      %s - %s\n", excluded_candidates$main_artist[i], excluded_candidates$main_song[i]))
        }
      }
    } else {
      cat("   ⚠️ No candidates were excluded (possible format mismatch)\n")
      
      # Debug: show format comparison
      if (nrow(candidates_with_dj_scoring) > 0) {
        sample_candidate_id <- paste(candidates_with_dj_scoring$main_artist[1], " - ", candidates_with_dj_scoring$main_song[1])
        sample_exclusion_id <- unique_excluded_tracks[1]
        
        cat("   🔍 Debug format comparison:\n")
        cat(sprintf("      Candidate format: '%s'\n", sample_candidate_id))
        cat(sprintf("      Exclusion format: '%s'\n", sample_exclusion_id))
        cat("      Match: ", sample_candidate_id %in% unique_excluded_tracks, "\n")
      }
    }
    
  } else {
    cat("   ✅ No recent plays to exclude\n")
  }
  
  # Final check
  if (nrow(candidates_with_dj_scoring) == 0) {
    cat("❌ No candidates remaining after recent play filtering!\n")
    cat("💡 Consider reducing RECENT_PLAY_EXCLUSION_HOURS or AI_DJ_EXCLUSION_DAYS\n")
    cat(sprintf("   Current settings: Main station = %dh, AI DJ = %dd\n", 
                RECENT_PLAY_EXCLUSION_HOURS, AI_DJ_EXCLUSION_DAYS))
    return(NULL)
  }
  
  cat(sprintf("✅ Proceeding with %d filtered candidates\n", nrow(candidates_with_dj_scoring)))
  
  # Step 3: Apply fuzzy/Bayesian thinking
  candidates_with_novelty <- calculate_novelty_bonuses(candidates_with_dj_scoring, genre_analysis$recent_tracks)
  fuzzy_candidates <- apply_fuzzy_score_banding(candidates_with_novelty)
  
  # Step 4: Probabilistic selection
  final_recommendations <- probabilistic_genre_selection(fuzzy_candidates, genre_needs, n)
  
  if (tier > 1) {
    final_recommendations <- filter_tracks_with_intro_availability(final_recommendations, style)
  }
  
  if (is.null(fuzzy_candidates)) {
    cat("❌ No tracks with intro availability\n")
    return(NULL)
  }
  
  if (nrow(final_recommendations) == 0) {
    cat("❌ No recommendations selected\n")
    return(NULL)
  }
  
  # Step 5: Display results
  cat("🌫️ FUZZY DJ RECOMMENDATIONS (PROBABILISTIC SELECTION):\n")
  cat("🎲 Selected from fuzzy score bands, not rigid rankings\n")
  cat(paste0(rep("=", 75), collapse = ""), "\n")
  
  for (i in 1:nrow(final_recommendations)) {
    rec <- final_recommendations[i, ]
    # intro <- get_artist_intro(rec$main_artist, rec$main_song)
    cat(sprintf("%d. %s - %s\n", i, rec$main_artist, rec$main_song))
    cat(sprintf("   🌫️ Fuzzy Score: %.3f (%s band) | Original DJ: %.3f\n",
                rec$fuzzy_dj_score, rec$score_band, rec$dj_ai_score))
    cat(sprintf("   🎯 Genre: %s | Novelty: %+.1f%% | Serendipity: %.2fx\n",
                rec$main_genre, rec$novelty_bonus * 100, rec$serendipity_factor))
    cat(sprintf("   📊 Base Factors: AI %.3f × Genre %.2fx = %.3f\n",
                rec$base_ai_score, rec$genre_balance_score, rec$dj_ai_score))
    # cat("   🎙️ Song introduction: ", intro)
    cat("\n")
  }
  
  # Summary
  band_summary <- final_recommendations %>%
    count(score_band) %>%
    arrange(desc(n))
  
  cat("🎯 FUZZY SELECTION SUMMARY:\n")
  cat("   🌫️ Selected from bands:\n")
  for (i in 1:nrow(band_summary)) {
    cat(sprintf("      %s: %d tracks\n", band_summary$score_band[i], band_summary$n[i]))
  }
  
  return(final_recommendations)
}

# =============================================================================
# ANALYZE RECENT GENRE MIX
# =============================================================================

analyze_recent_genre_mix <- function(recent_tracks = 10, fresh_data = NULL) {
  cat("🎨 ANALYZING RECENT GENRE MIX...\n")
  
  # Use fresh data if available, otherwise fall back to main data
  data_source <- if (!is.null(fresh_data)) fresh_data else data
  
  if (is.null(data_source) || nrow(data_source) == 0) {
    cat("❌ No data available for genre analysis\n")
    return(NULL)
  }
  
  # Get recent tracks with genres - EXCLUDE "-" and other non-music entries
  recent_genre_data <- data_source %>%
    arrange(desc(datetime)) %>%
    filter(!is.na(main_genre), 
           main_genre != "", 
           main_genre != "Unknown",
           main_genre != "-",           # EXCLUDE dashes
           main_genre != "Advertisement",
           main_genre != "DJ Chat",
           !is.na(main_artist), 
           main_artist != "",
           main_artist != "Unknown",
           main_artist != "DJ Chat",
           main_artist != "Advertisement",
           main_artist != "-") %>%      # EXCLUDE artist dashes too
    slice_head(n = recent_tracks * 2) %>%  # Get extra to account for filtering
    slice_head(n = recent_tracks) %>%      # Take final count after filtering
    select(datetime, main_artist, main_song, main_genre)
  
  if (nrow(recent_genre_data) == 0) {
    cat("❌ No recent genre data available after filtering\n")
    return(NULL)
  }
  
  # Calculate genre distribution
  genre_distribution <- recent_genre_data %>%
    count(main_genre, sort = TRUE) %>%
    mutate(
      percentage = n / sum(n),
      percentage_display = round(percentage * 100, 1)
    )
  
  # Calculate artist repetition
  artist_counts <- recent_genre_data %>%
    count(main_artist, sort = TRUE) %>%
    filter(n > 1)
  
  # Count excluded tracks for information
  excluded_tracks <- data_source %>%
    arrange(desc(datetime)) %>%
    slice_head(n = recent_tracks * 2) %>%
    filter(main_genre == "-" | main_artist == "-" | 
             main_genre %in% c("", "Unknown", "Advertisement", "DJ Chat") |
             main_artist %in% c("", "Unknown", "DJ Chat", "Advertisement")) %>%
    nrow()
  
  cat("   📊 Recent", nrow(recent_genre_data), "music tracks genre breakdown:\n")
  for (i in 1:min(5, nrow(genre_distribution))) {
    cat(sprintf("      %s: %d tracks (%.1f%%)\n", 
                genre_distribution$main_genre[i],
                genre_distribution$n[i],
                genre_distribution$percentage_display[i]))
  }
  
  if (excluded_tracks > 0) {
    cat(sprintf("   🚫 Excluded %d non-music entries ('-', long tracks, ads, etc.)\n", excluded_tracks))
  }
  
  if (nrow(artist_counts) > 0) {
    cat("   🔄 Artist repetitions:\n")
    for (i in 1:min(3, nrow(artist_counts))) {
      cat(sprintf("      %s: %d times\n", 
                  artist_counts$main_artist[i],
                  artist_counts$n[i]))
    }
  }
  
  return(list(
    genre_distribution = genre_distribution,
    artist_counts = artist_counts,
    recent_tracks = recent_genre_data,
    analysis_window = nrow(recent_genre_data),
    excluded_count = excluded_tracks
  ))
}

# =============================================================================
# CALCULATE GENRE NEEDS
# =============================================================================

calculate_genre_needs <- function(genre_analysis, current_hour) {
  cat("🎯 CALCULATING GENRE NEEDS...\n")
  
  if (is.null(genre_analysis)) {
    cat("❌ No genre analysis available\n")
    return(NULL)
  }
  
  # Get current genre distribution
  current_distribution <- genre_analysis$genre_distribution %>%
    select(main_genre, current_percentage = percentage)
  
  # Convert targets to dataframe
  target_df <- data.frame(
    main_genre = names(DJ_THINKING_CONFIG$genre_targets),
    target_percentage = unlist(DJ_THINKING_CONFIG$genre_targets),
    stringsAsFactors = FALSE
  )
  
  # Calculate needs
  genre_needs <- target_df %>%
    left_join(current_distribution, by = "main_genre") %>%
    mutate(
      current_percentage = ifelse(is.na(current_percentage), 0, current_percentage),
      need_score = target_percentage - current_percentage,
      need_urgency = case_when(
        need_score > 0.15 ~ "High",
        need_score > 0.05 ~ "Medium", 
        need_score > -0.05 ~ "Low",
        TRUE ~ "Oversupplied"
      )
    ) %>%
    arrange(desc(need_score))
  
  cat("   📈 Genre needs analysis:\n")
  top_needs <- genre_needs %>% filter(need_score > 0) %>% slice_head(n = 5)
  for (i in 1:nrow(top_needs)) {
    cat(sprintf("      %s: %.1f%% needed (%s urgency)\n",
                top_needs$main_genre[i],
                top_needs$need_score[i] * 100,
                top_needs$need_urgency[i]))
  }
  
  oversupplied <- genre_needs %>% filter(need_score < -0.05)
  if (nrow(oversupplied) > 0) {
    cat("   ⚠️ Oversupplied genres:\n")
    for (i in 1:min(3, nrow(oversupplied))) {
      cat(sprintf("      %s: %.1f%% oversupplied\n",
                  oversupplied$main_genre[i],
                  abs(oversupplied$need_score[i]) * 100))
    }
  }
  
  return(genre_needs)
}

# =============================================================================
# CALCULATE EXPLORATION FACTOR
# =============================================================================

calculate_exploration_factor <- function(current_hour, recent_trend, listener_volatility) {
  cat("🔍 CALCULATING EXPLORATION FACTOR...\n")
  
  # Determine time of day exploration base
  time_exploration <- case_when(
    current_hour >= 6 & current_hour < 10 ~ DJ_THINKING_CONFIG$exploration_by_hour$morning,
    current_hour >= 10 & current_hour < 14 ~ DJ_THINKING_CONFIG$exploration_by_hour$midday,
    current_hour >= 14 & current_hour < 18 ~ DJ_THINKING_CONFIG$exploration_by_hour$afternoon,
    current_hour >= 18 & current_hour < 22 ~ DJ_THINKING_CONFIG$exploration_by_hour$evening,
    TRUE ~ DJ_THINKING_CONFIG$exploration_by_hour$night
  )
  
  # Adjust based on listener trend
  trend_adjustment <- case_when(
    recent_trend > 10 ~ DJ_THINKING_CONFIG$risk_by_trend$growing,
    recent_trend > -10 ~ DJ_THINKING_CONFIG$risk_by_trend$stable,
    TRUE ~ DJ_THINKING_CONFIG$risk_by_trend$declining
  )
  
  # Adjust based on volatility (more conservative if volatile)
  volatility_adjustment <- case_when(
    listener_volatility > 30 ~ 0.8,  # Reduce exploration
    listener_volatility > 20 ~ 0.9,  # Slightly reduce
    TRUE ~ 1.0  # Normal exploration
  )
  
  # Final exploration factor
  exploration_factor <- time_exploration * trend_adjustment * volatility_adjustment
  exploration_factor <- pmax(0.05, pmin(0.50, exploration_factor))  # Clamp between 5% and 50%
  
  cat(sprintf("   🎲 Exploration factor: %.1f%% (Time: %.1f%%, Trend: %.1f%%, Volatility: %.1f%%)\n",
              exploration_factor * 100, time_exploration * 100, 
              trend_adjustment * 100, volatility_adjustment * 100))
  
  return(exploration_factor)
}

# =============================================================================
# CALCULATE NOVELTY BONUSES
# =============================================================================

calculate_novelty_bonuses <- function(candidates, recent_history) {
  cat("🎲 CALCULATING NOVELTY AND SERENDIPITY BONUSES...\n")
  
  if (is.null(recent_history) || nrow(recent_history) == 0) {
    cat("   ⚠️ No recent history - all tracks get novelty bonus\n")
    return(candidates %>% mutate(
      novelty_bonus = FUZZY_DJ_CONFIG$novelty_settings$recency_bonus_max,
      serendipity_factor = 1.0
    ))
  }
  
  # Recent artists and tracks
  recent_artists <- recent_history %>%
    slice_head(n = FUZZY_DJ_CONFIG$novelty_settings$artist_spacing_target) %>%
    pull(main_artist) %>%
    unique()
  
  recent_tracks <- recent_history %>%
    slice_head(n = FUZZY_DJ_CONFIG$novelty_settings$track_spacing_target) %>%
    mutate(track_id = paste(main_artist, "-", main_song)) %>%
    pull(track_id) %>%
    unique()
  
  # Calculate genre saturation
  recent_genres <- recent_history %>%
    slice_head(n = FUZZY_DJ_CONFIG$genre_saturation$recent_window) %>%
    filter(main_genre != "-", main_genre != "", !is.na(main_genre)) %>%
    count(main_genre) %>%
    mutate(saturation = n / FUZZY_DJ_CONFIG$genre_saturation$recent_window) %>%
    filter(saturation >= FUZZY_DJ_CONFIG$genre_saturation$saturation_threshold)
  
  saturated_genres <- recent_genres$main_genre
  
  cat(sprintf("   🎨 %d artists played recently (avoid repetition)\n", length(recent_artists)))
  cat(sprintf("   🎵 %d tracks played recently (avoid repetition)\n", length(recent_tracks)))
  if (length(saturated_genres) > 0) {
    cat(sprintf("   🚫 Saturated genres: %s\n", paste(saturated_genres, collapse = ", ")))
  }
  
  # Apply novelty bonuses
  enhanced_candidates <- candidates %>%
    mutate(
      # Artist novelty bonus
      artist_novelty = ifelse(
        !main_artist %in% recent_artists, 
        FUZZY_DJ_CONFIG$novelty_settings$recency_bonus_max,
        0
      ),
      
      # Track novelty bonus
      track_novelty = ifelse(
        !track_id %in% recent_tracks,
        FUZZY_DJ_CONFIG$novelty_settings$recency_bonus_max * 0.5,  # Smaller bonus than artist
        0
      ),
      
      # Genre saturation penalty
      genre_saturation_penalty = ifelse(
        main_genre %in% saturated_genres,
        -FUZZY_DJ_CONFIG$genre_saturation$saturation_penalty,
        0
      ),
      
      # Combined novelty bonus
      novelty_bonus = artist_novelty + track_novelty + genre_saturation_penalty,
      
      # Add exploration randomness (Bayesian uncertainty)
      exploration_uncertainty = rnorm(n(), mean = 0, sd = FUZZY_DJ_CONFIG$novelty_settings$exploration_randomness),
      
      # Serendipity factor (random "gut feeling")
      serendipity_factor = ifelse(
        runif(n()) < FUZZY_DJ_CONFIG$novelty_settings$serendipity_factor,
        runif(n(), min = 0.8, max = 1.4),  # Random boost/penalty
        1.0
      )
    )
  
  cat(sprintf("   🎲 Applied novelty bonuses: %.1f%% to %.1f%%\n", 
              min(enhanced_candidates$novelty_bonus) * 100, 
              max(enhanced_candidates$novelty_bonus) * 100))
  
  return(enhanced_candidates)
}

# =============================================================================
# FUZZY SCORE BANDING
# =============================================================================

apply_fuzzy_score_banding <- function(candidates) {
  cat("🌫️ APPLYING FUZZY SCORE BANDING (de Finetti style)...\n")
  
  # Apply all the bonuses to get final fuzzy scores
  candidates_with_fuzzy <- candidates %>%
    mutate(
      # Clean up any remaining NaN values in component scores
      novelty_bonus = ifelse(is.na(novelty_bonus), 0, novelty_bonus),
      serendipity_factor = ifelse(is.na(serendipity_factor) | serendipity_factor <= 0, 1.0, serendipity_factor),
      exploration_uncertainty = ifelse(is.na(exploration_uncertainty), 0, exploration_uncertainty),
      
      # Final fuzzy DJ score with all factors
      fuzzy_dj_score = dj_ai_score * (1 + novelty_bonus) * serendipity_factor + exploration_uncertainty,
      
      # Clean up the final fuzzy score
      fuzzy_dj_score = case_when(
        is.na(fuzzy_dj_score) | is.infinite(fuzzy_dj_score) ~ 0.5,  # Default to neutral
        fuzzy_dj_score < 0 ~ 0.1,  # Minimum score
        TRUE ~ fuzzy_dj_score
      ),
      
      # Assign to fuzzy bands instead of precise rankings
      score_band = case_when(
        fuzzy_dj_score >= FUZZY_DJ_CONFIG$score_bands$excellent[1] ~ "excellent",
        fuzzy_dj_score >= FUZZY_DJ_CONFIG$score_bands$very_good[1] ~ "very_good", 
        fuzzy_dj_score >= FUZZY_DJ_CONFIG$score_bands$good[1] ~ "good",
        fuzzy_dj_score >= FUZZY_DJ_CONFIG$score_bands$okay[1] ~ "okay",
        TRUE ~ "poor"
      ),
      
      # Selection weight based on band
      selection_weight = case_when(
        score_band == "excellent" ~ FUZZY_DJ_CONFIG$band_selection_weights$excellent,
        score_band == "very_good" ~ FUZZY_DJ_CONFIG$band_selection_weights$very_good,
        score_band == "good" ~ FUZZY_DJ_CONFIG$band_selection_weights$good,
        score_band == "okay" ~ FUZZY_DJ_CONFIG$band_selection_weights$okay,
        TRUE ~ FUZZY_DJ_CONFIG$band_selection_weights$poor
      ),
      
      # Final safety check
      selection_weight = ifelse(is.na(selection_weight) | selection_weight <= 0, 0.1, selection_weight)
    ) %>%
    # Filter out any tracks that still have problematic scores
    filter(!is.na(fuzzy_dj_score), 
           !is.infinite(fuzzy_dj_score),
           fuzzy_dj_score > 0,
           !is.na(selection_weight),
           selection_weight > 0)
  
  if (nrow(candidates_with_fuzzy) == 0) {
    cat("❌ No valid candidates after fuzzy processing\n")
    return(NULL)
  }
  
  # Show band distribution
  band_summary <- candidates_with_fuzzy %>%
    count(score_band, sort = TRUE)
  
  cat("   📊 Fuzzy score band distribution:\n")
  for (i in 1:nrow(band_summary)) {
    cat(sprintf("      %s: %d tracks\n", band_summary$score_band[i], band_summary$n[i]))
  }
  
  cat(sprintf("   ✅ %d clean tracks ready for probabilistic selection\n", nrow(candidates_with_fuzzy)))
  
  return(candidates_with_fuzzy)
}

# =============================================================================
# PROBABILISTIC SELECTION WITHIN BANDS
# =============================================================================

probabilistic_genre_selection <- function(fuzzy_candidates, genre_needs, n_recommendations = 5) {
  cat("🎰 PROBABILISTIC SELECTION WITHIN FUZZY BANDS...\n")
  
  selected_tracks <- data.frame()
  selected_genres <- character()
  
  # Get priority genres (those with high need scores)
  priority_genres <- genre_needs %>%
    filter(need_score > 0.05) %>%  # Only genres with meaningful need
    arrange(desc(need_score)) %>%
    pull(main_genre)
  
  cat(sprintf("   🎯 Priority genres: %s\n", paste(priority_genres[1:min(3, length(priority_genres))], collapse = ", ")))
  
  for (pick in 1:n_recommendations) {
    cat(sprintf("\n   🎲 Pick %d: ", pick))
    
    # =============================================================================
    # HELPER FUNCTION: CREATE VALID CANDIDATE POOL
    # =============================================================================
    
    create_valid_pool <- function(base_candidates) {
      # Count current artist usage
      if (nrow(selected_tracks) > 0) {
        artist_counts <- table(selected_tracks$main_artist)
        # Filter based on existing selections
        valid_pool <- base_candidates %>%
          filter(
            !track_id %in% selected_tracks$track_id,  # No duplicate tracks
            !(main_artist %in% names(artist_counts)[artist_counts >= 2])  # Max 2 per artist
          )
      } else {
        # First pick - no constraints yet
        valid_pool <- base_candidates
      }
      
      return(valid_pool)
    }
    
    # =============================================================================
    # CANDIDATE SELECTION WITH VALIDATION
    # =============================================================================
    
    # Determine if we should prioritize a needed genre
    should_prioritize_genre <- runif(1) < 0.7 && length(priority_genres) > 0
    
    candidates_pool <- NULL
    
    if (should_prioritize_genre) {
      # Pick from priority genres, but still use fuzzy selection within genre
      available_priority_genres <- setdiff(priority_genres, selected_genres)
      if (length(available_priority_genres) == 0) {
        available_priority_genres <- priority_genres  # Reset if all used
      }
      
      target_genre <- sample(available_priority_genres, 1, prob = rep(1, length(available_priority_genres)))
      
      # Get genre-specific candidates with validation
      genre_candidates <- fuzzy_candidates %>%
        filter(main_genre == target_genre)
      
      candidates_pool <- create_valid_pool(genre_candidates)
      
      cat(sprintf("Targeting %s genre (%d candidates)", target_genre, nrow(candidates_pool)))
      
      # If no valid candidates for target genre, fall back to open selection
      if (nrow(candidates_pool) == 0) {
        cat(" - No valid candidates, switching to open selection")
        candidates_pool <- create_valid_pool(fuzzy_candidates)
        cat(sprintf(" (%d candidates)", nrow(candidates_pool)))
      }
      
    } else {
      # Open selection from all candidates with validation
      candidates_pool <- create_valid_pool(fuzzy_candidates)
      cat(sprintf("Open selection (%d candidates)", nrow(candidates_pool)))
    }
    
    # =============================================================================
    # EMERGENCY FALLBACK: RELAX ARTIST LIMITS IF NEEDED
    # =============================================================================
    
    if (nrow(candidates_pool) == 0) {
      cat(" - No candidates with artist limits, relaxing constraints")
      
      # Fallback: allow artist limit breach but still prevent exact duplicates
      candidates_pool <- fuzzy_candidates %>%
        filter(!track_id %in% selected_tracks$track_id)
      
      cat(sprintf(" (%d candidates)", nrow(candidates_pool)))
      
      # Final check - if still no candidates, skip this pick
      if (nrow(candidates_pool) == 0) {
        cat(" - No candidates available")
        next
      }
    }
    
    # =============================================================================
    # PROBABILISTIC SELECTION
    # =============================================================================
    
    # Probabilistic selection within the pool using fuzzy weights
    if (nrow(candidates_pool) == 1) {
      selected_track <- candidates_pool[1, ]
    } else {
      # Sample based on selection weights (higher weight = higher probability)
      selection_probs <- candidates_pool$selection_weight / sum(candidates_pool$selection_weight)
      selected_idx <- sample(1:nrow(candidates_pool), 1, prob = selection_probs)
      selected_track <- candidates_pool[selected_idx, ]
    }
    
    cat(sprintf(" → %s - %s (%.3f score, %s band)",
                selected_track$main_artist, selected_track$main_song,
                selected_track$fuzzy_dj_score, selected_track$score_band))
    
    # Add to selections
    selected_tracks <- rbind(selected_tracks, selected_track)
    selected_genres <- c(selected_genres, selected_track$main_genre)
  }
  
  cat("\n")
  return(selected_tracks)
}

# =============================================================================
# CHECK INTRO AVAILABILITY
# =============================================================================

filter_tracks_with_intro_availability <- function(fuzzy_candidates, style = "dry_witty_radio6") {
  cat("🎙️ FILTERING TRACKS BY INTRO AVAILABILITY (PER-TRACK ERROR HANDLING)...\n")
  
  if (is.null(fuzzy_candidates) || nrow(fuzzy_candidates) == 0) {
    cat("❌ No candidates to filter\n")
    return(fuzzy_candidates)
  }
  
  cat(sprintf("📊 Checking intro availability for %d candidates\n", nrow(fuzzy_candidates)))
  
  available_intros <- sql_query(
    paste0("SELECT DISTINCT artist, song FROM ", TALKING_POINTS_TABLE, 
           " WHERE style = '", style, "'")
  )
    
    # Create lookup for existing intros
    if (nrow(available_intros) > 0) {
      available_lookup <- available_intros %>%
        mutate(lookup_key = paste(artist, song, sep = "|||")) %>%
        pull(lookup_key)
    } else {
      available_lookup <- character(0)
    }
    
    # Phase 1: Check which tracks already have intros
    candidates_with_status <- fuzzy_candidates %>%
      mutate(
        lookup_key = paste(main_artist, main_song, sep = "|||"),
        has_cached_intro = lookup_key %in% available_lookup,
        intro_status = ifelse(has_cached_intro, "cached", "needs_generation")
      ) %>%
      select(-lookup_key)
    
    cached_count <- sum(candidates_with_status$has_cached_intro)
    needs_generation_count <- sum(!candidates_with_status$has_cached_intro)
    
    cat(sprintf("📋 Status: %d cached, %d need generation\n", cached_count, needs_generation_count))
    
    # Phase 2: Generate intros for tracks that need them (per-track error handling)
    if (needs_generation_count > 0) {
      cat(sprintf("\n🎙️ GENERATING INTROS for %d tracks...\n", needs_generation_count))
      
      tracks_needing_generation <- candidates_with_status %>%
        filter(intro_status == "needs_generation")
      
      for (i in 1:nrow(tracks_needing_generation)) {
        track <- tracks_needing_generation[i, ]
        cat(sprintf("   🎯 Generate %d/%d: %s - %s... ", i, nrow(tracks_needing_generation), 
                    track$main_artist, track$main_song))
        
        # Wrap EACH track's generation in its own error handling
        generation_success <- tryCatch({
          generate_artist_intro(track$main_artist, track$main_song, 1, 2)
        }, error = function(e) {
          cat(sprintf("ERROR: %s ", e$message))
          FALSE  # Mark this track as failed, but continue with others
        })
        
        if (generation_success) {
          cat("✅ Success\n")
          # Update status to generated
          candidates_with_status <- candidates_with_status %>%
            mutate(intro_status = ifelse(
              main_artist == track$main_artist & main_song == track$main_song,
              "generated_success",
              intro_status
            ))
        } else {
          cat("❌ Failed\n")
          # Mark as generation failed
          candidates_with_status <- candidates_with_status %>%
            mutate(intro_status = ifelse(
              main_artist == track$main_artist & main_song == track$main_song,
              "generation_failed",
              intro_status
            ))
        }
        
        # Small delay to be nice to APIs (continue regardless of individual failures)
        if (i < nrow(tracks_needing_generation)) {
          Sys.sleep(0.5)  # Increased delay to help with rate limiting
        }
      }
    }
    
    # Phase 3: Filter to only tracks with successful intro availability
    successful_tracks <- candidates_with_status %>%
      filter(intro_status %in% c("cached", "generated_success"))
    
    # Show final results
    final_cached <- sum(candidates_with_status$intro_status == "cached")
    final_generated <- sum(candidates_with_status$intro_status == "generated_success")
    final_failed <- sum(candidates_with_status$intro_status == "generation_failed")
    
    cat(sprintf("\n✅ Final results:\n"))
    cat(sprintf("   💾 Cached intros: %d\n", final_cached))
    cat(sprintf("   🎙️ Generated intros: %d\n", final_generated))
    cat(sprintf("   ❌ Failed generations: %d\n", final_failed))
    cat(sprintf("   🎯 Total usable: %d/%d tracks (%.1f%%)\n", 
                nrow(successful_tracks), nrow(fuzzy_candidates),
                (nrow(successful_tracks) / nrow(fuzzy_candidates)) * 100))
    
    if (needs_generation_count > 0) {
      generation_success_rate <- (final_generated / needs_generation_count) * 100
      cat(sprintf("   📈 Generation success rate: %.1f%%\n", generation_success_rate))
    }
    
    if (nrow(successful_tracks) == 0) {
      cat("⚠️ WARNING: No tracks have intro availability after generation attempts!\n")
      return(NULL)
    }
    
    # Clean up temporary columns
    final_candidates <- successful_tracks %>%
      select(-intro_status, -has_cached_intro)
    
    return(final_candidates)
}

# =============================================================================
# SELECT ONE TRACK FROM FUZZY RECOMMENDATIONS
# =============================================================================

select_ai_dj_track <- function(fuzzy_recs) {
  cat("🎯 SELECTING AI DJ TRACK FROM FUZZY RECOMMENDATIONS...\n")
  
  if (is.null(fuzzy_recs) || nrow(fuzzy_recs) == 0) {
    cat("❌ No recommendations available for selection\n")
    return(NULL)
  }
  
  # Option 2: Weight by selection_weight (respects fuzzy system)
  selected_track <- fuzzy_recs %>%
    slice_sample(n = 1, weight_by = selection_weight)
  
  cat("🎲 SELECTED TRACK:\n")
  cat(sprintf("   🎵 %s - %s\n", selected_track$main_artist, selected_track$main_song))
  cat(sprintf("   🌫️ Fuzzy Score: %.3f (%s band)\n", 
              selected_track$fuzzy_dj_score, selected_track$score_band))
  cat(sprintf("   🎯 Genre: %s | Selection Weight: %.3f\n", 
              selected_track$main_genre, selected_track$selection_weight))
  
  return(selected_track)
}

get_artist_intro <- function(artist, song, intro_type = 1, artist2 = NULL, song2 = NULL, style = "dry_witty_radio6") {
  
  # Handle double-play intros
  if (!is.null(artist2) && !is.null(song2)) {
    cat(sprintf("🎙️ Retrieving double-play intro for: %s - %s & %s - %s\n", artist, song, artist2, song2))
    artist_sql <- paste0(artist, " - ", artist2)
    song_sql <- paste0(song, " - ", song2)
  } else {
    cat(sprintf("🎙️ Retrieving intro for: %s - %s\n", artist, song))
    artist_sql <- artist
    song_sql <- song
  }
  
  tryCatch({
    # Use new global SQL connection system
    con <- create_sql_connection(connection_name = "get_intro")
    
    # First try: fetch random intro from DB using ORDER BY RAND() with parameterized query
    query <- paste0("SELECT * FROM ", TALKING_POINTS_TABLE, " WHERE artist = ? AND song = ? AND style = ? ORDER BY RAND() LIMIT 1")
    
    result <- dbGetQuery(con, query, params = list(artist_sql, song_sql, style))
    
    if (!is.null(result) && nrow(result) > 0) {
      # Check freshness
      last_updated <- as.POSIXct(result$last_updated[1])
      age_days <- as.numeric(difftime(Sys.time(), last_updated, units = "days"))
      msg <- if (age_days < 30) "📂 Cached data found" else "⏰ Cached data is stale"
      cat(sprintf("%s for %s (%.1f days old)\n", msg, artist, age_days))
      
      # Get clean intro
      clean_intro_result <- clean_intro(result, intro_type)
      
      dbDisconnect(con)
      return(clean_intro_result)
    }
    
    dbDisconnect(con)
    
    # No cached intro found - try generic fallback
    cat("📝 No specific intro found, checking for generic fallback...\n")
    
    con2 <- create_sql_connection(connection_name = "generic_intro")
    generic_query <- paste0("SELECT * FROM ", TALKING_POINTS_TABLE, " WHERE artist = ? AND song = ? AND style = ? ORDER BY RAND() LIMIT 1")
    generic_result <- dbGetQuery(con2, generic_query, params = list("generic", "generic", style))
    
    dbDisconnect(con2)
    
    if (!is.null(generic_result) && nrow(generic_result) > 0) {
      cat("🎭 Using generic intro as fallback\n")
      return(clean_intro(generic_result, intro_type))
    }
    
    # No intro available at all
    cat("❌ No intro available (specific or generic)\n")
    return(NULL)
    
  }, error = function(e) {
    cat("❌ Error retrieving intro:", e$message, "\n")
    # Ensure connections are closed even on error
    if (exists("con") && dbIsValid(con)) dbDisconnect(con)
    if (exists("con2") && dbIsValid(con2)) dbDisconnect(con2)
    return(NULL)
  })
}

# =============================================================================
# CLEAN INTRO FUNCTION
# =============================================================================

clean_intro <- function(result, intro_type) {
  # Check if result has any rows
  if (nrow(result) == 0) {
    return(NULL)
  }
  
  # Since we're now using ORDER BY RAND() LIMIT 1, we just have one result
  # Look for properly formatted intro
  intro_trimmed <- trimws(result$dj_intros[1])
  song_intro <- NULL
  
  if (grepl('^\\d+\\.\\s*\\"', intro_trimmed) && grepl('\\"$', intro_trimmed)) {
    cleaned <- sub('^\\d+\\.\\s*\\"', '', intro_trimmed)
    song_intro <- sub('\\"$', '', cleaned)
  } else {
    # Clean up any leading numbers and quotes
    cleaned <- gsub('^\\d+\\.\\s*["\'""]?', '', intro_trimmed)
    song_intro <- gsub('["\'""]$', '', cleaned)
  }
  
  # 35% chance of adding a station ident before the song intro
  if (runif(1) < 0.35 && intro_type == 0) {
    ident_intro <- get_random_ident()
    if (!is.null(ident_intro)) {
      
      # Check if song_intro is already SSML
      if (grepl("^<speak>", song_intro)) {
        # Remove <speak> tags from both and create unified SSML
        ident_clean <- gsub("^<speak>|</speak>$", "", ident_intro)
        song_clean <- gsub("^<speak>|</speak>$", "", song_intro)
        combined_text <- paste0("<speak>", ident_clean, "<break time='800ms'/>", song_clean, "</speak>")
      } else {
        # Neither has SSML, wrap both
        combined_text <- paste0(
          "<speak>",
          ident_intro,
          "<break time='800ms'/>",
          song_intro,
          "</speak>"
        )
      }
      return(combined_text)
    }
  }
  
  return(song_intro)
}

# =============================================================================
# GET RANDOM IDENT FUNCTION
# =============================================================================

get_random_ident <- function() {
  tryCatch({
    # Randomly choose ident type
    rand_choice <- runif(1)
    
    ident_type <- if (rand_choice < 0.60) {
      "dj-ident"      # Combined DJ + station ident (60%)
    } else if (rand_choice < 0.85) {
      "dj"            # DJ introduction only (25%)
    } else {
      "ident"         # Station ident only (15%)
    }
    
    # Get random ident using SQL connection with parameterized query
    con <- create_sql_connection(connection_name = "random_ident")
    query <- paste0("SELECT dj_intros FROM ", TALKING_POINTS_TABLE, " WHERE artist = ? AND song = ? ORDER BY RAND() LIMIT 1")
    result <- dbGetQuery(con, query, params = list("intros", ident_type))
    
    dbDisconnect(con)
    
    if (!is.null(result) && nrow(result) > 0) {
      return(result$dj_intros[1])
    }
    
    return(NULL)
    
  }, error = function(e) {
    cat("⚠️ Error getting random ident:", e$message, "\n")
    if (exists("con") && dbIsValid(con)) dbDisconnect(con)
    return(NULL)
  })
}

# =============================================================================
# CORE FUNCTION 2: GENERATE ARTIST INTRO
# =============================================================================

generate_artist_intro <- function(artist, song, intro_type = 1, number_intros = 4, 
                                  artist2 = NULL, song2 = NULL, style = "dry_witty_radio6") {
  
  if (!is.null(artist2) && !is.null(song2)) {
    cat(sprintf("🎙️ Generating double-play intro for: %s - %s & %s - %s (type: %d)\n", 
                artist, song, artist2, song2, intro_type))
  } else {
    cat(sprintf("🎙️ Generating intro for: %s - %s (type: %d)\n", artist, song, intro_type))
  }
  
  # Build the AI prompt based on intro type
  if ((intro_type == 0 || intro_type == 1 || intro_type == 3) && (number_intros > 1)) {
    prompt <- create_single_track_prompt(artist, song, number_intros)
  } else if (intro_type == 2) {
    prompt <- create_double_play_prompt(artist, song, artist2, song2)
  } else {
    prompt <- create_single_track_prompt(artist, song, 1)
  }
  
  # =============================================================================
  # RESPECT USE_FOR_INTROS SETTING WITH FALLBACK
  # =============================================================================
  
  intro_block <- NULL
  source <- "unknown"
  quality <- "unknown"
  
  # Check which service to use as primary
  primary_service <- if (exists("USE_FOR_INTROS")) USE_FOR_INTROS else "chatgpt"
  
  # Check API key availability
  chatgpt_available <- exists("CHATGPT_API_KEY") && !is.null(CHATGPT_API_KEY) && CHATGPT_API_KEY != ""
  claude_available <- exists("CLAUDE_ANTHROPIC_API_KEY") && !is.null(CLAUDE_ANTHROPIC_API_KEY) && CLAUDE_ANTHROPIC_API_KEY != ""
  
  if (!chatgpt_available && !claude_available) {
    cat("❌ No API keys available for intro generation\n")
    return(FALSE)
  }
  
  # Try primary service first
  if (primary_service == "claude" && claude_available) {
    cat("🤖 Trying Claude API (primary)...\n")
    intro_block <- intro_from_claude(prompt)
    source <- "Claude"
    quality <- "excellent"
    
    # Fallback to ChatGPT if Claude fails and ChatGPT is available
    if (is.null(intro_block) && chatgpt_available) {
      cat("🔄 Claude failed, trying ChatGPT fallback...\n")
      intro_block <- intro_from_chatgpt(prompt)
      source <- "chatGPT"
      quality <- "excellent"
    }
    
  } else if (primary_service == "chatgpt" && chatgpt_available) {
    cat("🤖 Trying ChatGPT API (primary)...\n")
    intro_block <- intro_from_chatgpt(prompt)
    source <- "chatGPT"
    quality <- "excellent"
    
    # Fallback to Claude if ChatGPT fails and Claude is available
    if (is.null(intro_block) && claude_available) {
      cat("🔄 ChatGPT failed, trying Claude fallback...\n")
      intro_block <- intro_from_claude(prompt)
      source <- "Claude"
      quality <- "excellent"
    }
    
  } else {
    # Primary service not available, try whatever is available
    if (claude_available) {
      cat("⚠️ Primary service not available, using Claude...\n")
      intro_block <- intro_from_claude(prompt)
      source <- "Claude"
      quality <- "excellent"
    } else if (chatgpt_available) {
      cat("⚠️ Primary service not available, using ChatGPT...\n")
      intro_block <- intro_from_chatgpt(prompt)
      source <- "chatGPT"
      quality <- "excellent"
    }
  }
  
  if (is.null(intro_block)) {
    cat("❌ All available AI services failed to generate intro\n")
    return(FALSE)
  }
  
  # =============================================================================
  # PROCESS AND STORE THE GENERATED INTROS
  # =============================================================================
  
  # Process and store intros using existing logic
  success <- process_and_store_intros(intro_block, artist, song, artist2, song2, style, source, quality)
  
  if (success) {
    cat("✅ Intro generation and storage successful\n")
    return(TRUE)
  } else {
    cat("❌ Failed to process and store generated intros\n")
    return(FALSE)
  }
}

# =============================================================================
# HELPER FUNCTION: CREATE SINGLE TRACK PROMPT
# =============================================================================

create_single_track_prompt <- function(artist, song, number_intros) {
  return(paste0(
    "Write ", number_intros, " tonally varied DJ-style introductions for the song '", song, "' by ", artist, ". ",
    "These should be in the voice of a witty, slightly world-weary, female DJ on ", MAIN_STATION_NAME, ", with a tone similar to BBC Radio 6: dry, clever, slightly sardonic, and self-aware. ",
    "Requirements: ",
    "- Use SSML markup throughout. ",
    "- Each introduction should be between 5 and 7 sentences long, excluding all SSML markup. Do not exceed or fall below this range. ",
    "- Enclose each introduction in a separate SSML <speak> block, and enclose each sentence in a SSML <p> block. ",
    "- Keep punctuation light, but do use it where needed. Use SSML markup <break time=\"600ms\"/> or similar for timing where natural pauses would help pacing. ",
    "- Use <emphasis> or <prosody> where appropriate, but sparingly. ",
    "- Where possible, use <prosody volume='+2dB' pitch='+5%'>Track Title</prosody> instead of <emphasis> tags to help maintain consistent audio levels. ",
    "- Avoid Americanisms or clichés unless you're intentionally subverting them. ",
    "- Try to include 1 or 2 subtle or interesting facts about the artist or the song in a humorous way. ",
    "- If the DJ refers to herself, she's female. ",
    "- The AI DJ may acknowledge that she's an AI. ",
    "- Do not include time, date, day, or current weather references that might be wrong when the introduction is played (e.g., 'this morning', 'weekend vibes', 'on this Tuesday'). ",
    "- If you reference current culture, keep it truly current. Avoid dated material like lockdowns or ringtones."
  ))
}

# =============================================================================
# HELPER FUNCTION: CREATE DOUBLE PLAY PROMPT
# =============================================================================

create_double_play_prompt <- function(artist1, song1, artist2, song2) {
  return(paste0(
    "Write a DJ-style introduction for a double-play: '", song1, "' by ", artist1, " followed by '", song2, "' by ", artist2, ". ",
    "This should be in the voice of a witty, slightly world-weary, female DJ on ", MAIN_STATION_NAME, ", with a tone similar to BBC Radio 6: dry, clever, slightly sardonic, and self-aware. ",
    "Requirements: ",
    "- Use SSML markup throughout with a single <speak> block containing the entire introduction. ",
    "- The introduction should be between 6 and 8 sentences long, excluding all SSML markup. ",
    "- Enclose each sentence in a SSML <p> block. ",
    "- Try to find a clever connection between the two tracks (thematic, historical, musical, or just absurdly tangential). ",
    "- Use <prosody volume='+2dB' pitch='+5%'> for track titles to maintain consistent audio levels. ",
    "- Include interesting facts about one or both artists/songs. ",
    "- Avoid time, date, weather, or other temporal references. ",
    "- The DJ may acknowledge that she's an AI. ",
    "- Keep the tone dry and clever, not overly enthusiastic."
  ))
}

# =============================================================================
# HELPER FUNCTION: PROCESS AND STORE INTROS
# =============================================================================

process_and_store_intros <- function(intro_block, artist, song, artist2 = NULL, song2 = NULL, 
                                     style, source, quality) {
  
  if (!is.null(artist2) && !is.null(song2)) {
    # Double-play - treat entire response as single intro
    intros <- c(trimws(intro_block))
  } else {
    # Single track - split on double newlines as before
    intros <- unlist(strsplit(intro_block, "\\n\\s*\\n"))
    intros <- intros[intros != "" & !is.na(intros)]
  }
  
  # Validate each intro for proper SSML format
  valid_intros <- c()
  
  for (i in seq_along(intros)) {
    intro <- trimws(intros[i])
    
    if (grepl("^<speak>", intro, ignore.case = TRUE) && 
        grepl("</speak>$", intro, ignore.case = TRUE)) {
      valid_intros <- c(valid_intros, intro)
      cat(sprintf("   ✅ Intro %d: Valid SSML format\n", i))
    } else {
      cat(sprintf("   ❌ Intro %d: Invalid format - missing <speak> tags\n", i))
    }
  }
  
  if (length(valid_intros) == 0) {
    cat("❌ No valid intros found after validation\n")
    return(FALSE)
  }
  
  # Prepare artist/song names for database
  if (!is.null(artist2) && !is.null(song2)) {
    artist_sql <- paste0(artist, " - ", artist2)
    song_sql <- paste0(song, " - ", song2)
  } else {
    artist_sql <- artist
    song_sql <- song
  }
  
  # Store intros in database using SQL connection
  tryCatch({
    con <- create_sql_connection(connection_name = "store_intros")
    
    stored_count <- 0
    for (intro in valid_intros) {
      insert_query <- paste0("INSERT INTO ", TALKING_POINTS_TABLE, 
                             " (artist, song, style, dj_intros, data_source, data_quality) VALUES (?, ?, ?, ?, ?, ?)")
      
      # Use parameterized query for safety
      result <- dbExecute(con, insert_query, params = list(
        artist_sql, song_sql, style, intro, source, quality
      ))
      
      if (result > 0) stored_count <- stored_count + 1
    }
    
    dbDisconnect(con)
    
    cat(sprintf("✅ Successfully stored %d/%d valid intros\n", stored_count, length(valid_intros)))
    return(TRUE)
    
  }, error = function(e) {
    cat("❌ Error storing intros:", e$message, "\n")
    if (exists("con") && dbIsValid(con)) dbDisconnect(con)
    return(FALSE)
  })
}

# =============================================================================
# HELPER FUNCTION: CLEAN INTRO
# =============================================================================

clean_intro <- function(result, intro_type = 1) {
  if (is.null(result) || nrow(result) == 0) {
    return(NULL)
  }
  
  # Extract the intro text
  song_intro <- result$dj_intros[1]
  
  if (is.null(song_intro) || is.na(song_intro) || trimws(song_intro) == "") {
    return(NULL)
  }
  
  # Clean up any formatting issues
  song_intro <- trimws(song_intro)
  
  # Remove any trailing quotes or unwanted characters
  song_intro <- gsub('^["\'""]', '', song_intro)
  song_intro <- gsub('["\'""]$', '', song_intro)
  
  # 35% chance of adding a station ident before the song intro (only for intro_type 3)
  if (runif(1) < 0.35 && intro_type == 3) {
    ident_intro <- get_random_ident()
    if (!is.null(ident_intro)) {
      return(combine_ident_with_intro(ident_intro, song_intro))
    }
  }
  
  return(song_intro)
}

# =============================================================================
# HELPER FUNCTION: GET RANDOM IDENT
# =============================================================================

get_random_ident <- function() {
  tryCatch({
    # Randomly choose ident type
    rand_choice <- runif(1)
    
    ident_type <- if (rand_choice < 0.60) {
      "dj-ident"      # Combined DJ + station ident (60%)
    } else if (rand_choice < 0.85) {
      "dj"            # DJ introduction only (25%)
    } else {
      "ident"         # Station ident only (15%)
    }
    
    # Get random ident using SQL connection
    query <- paste0("SELECT dj_intros FROM ", TALKING_POINTS_TABLE, 
                    " WHERE artist = 'intros' AND song = '", ident_type, 
                    "' ORDER BY RAND() LIMIT 1")
    
    result <- sql_query(query, connection_name = "random_ident")
    
    if (!is.null(result) && nrow(result) > 0) {
      return(result$dj_intros[1])
    }
    
    return(NULL)
    
  }, error = function(e) {
    cat("⚠️ Error getting random ident:", e$message, "\n")
    return(NULL)
  })
}

# =============================================================================
# HELPER FUNCTION: COMBINE IDENT WITH INTRO
# =============================================================================

combine_ident_with_intro <- function(ident_intro, song_intro) {
  # Check if song_intro is already SSML
  if (grepl("^<speak>", song_intro)) {
    # Remove <speak> tags from both and create unified SSML
    ident_clean <- gsub("^<speak>|</speak>$", "", ident_intro)
    song_clean <- gsub("^<speak>|</speak>$", "", song_intro)
    combined_text <- paste0("<speak>", ident_clean, "<break time='800ms'/>", song_clean, "</speak>")
  } else {
    # Neither has SSML, wrap both
    combined_text <- paste0(
      "<speak>",
      ident_intro,
      "<break time='800ms'/>",
      song_intro,
      "</speak>"
    )
  }
  
  return(combined_text)
}

# =============================================================================
# CORE FUNCTION 3: CHECK INTRO AVAILABILITY
# =============================================================================

check_intro_availability <- function(artist, song, style = "dry_witty_radio6") {
  tryCatch({
    # Check for specific intros
    specific_query <- paste0("SELECT COUNT(*) as intro_count FROM ", TALKING_POINTS_TABLE, 
                             " WHERE artist = '", artist, "' AND song = '", song, 
                             "' AND style = '", style, "'")
    
    specific_result <- sql_query(specific_query, connection_name = "check_specific")
    
    # Check for generic fallback intros
    generic_query <- paste0("SELECT COUNT(*) as intro_count FROM ", TALKING_POINTS_TABLE, 
                            " WHERE artist = 'generic' AND song = 'generic'")
    
    generic_result <- sql_query(generic_query, connection_name = "check_generic")
    
    has_specific_intros <- !is.null(specific_result) && specific_result$intro_count[1] > 0
    has_generic_fallback <- !is.null(generic_result) && generic_result$intro_count[1] > 0
    
    return(has_specific_intros || has_generic_fallback)
    
  }, error = function(e) {
    # If database check fails, assume intro availability to avoid blocking everything
    cat(sprintf("⚠️ Intro check failed for %s - %s: %s\n", artist, song, e$message))
    return(TRUE)  # Fail open - assume availability
  })
}

# =============================================================================
# CORE FUNCTION 4: BATCH INTRO AVAILABILITY CHECK
# =============================================================================

filter_tracks_with_intro_availability <- function(track_candidates, style = "dry_witty_radio6") {
  cat("🎙️ FILTERING TRACKS BY INTRO AVAILABILITY (BATCH MODE)...\n")
  
  if (is.null(track_candidates) || nrow(track_candidates) == 0) {
    cat("❌ No candidates to filter\n")
    return(track_candidates)
  }
  
  cat(sprintf("📊 Batch checking intro availability for %d candidates\n", nrow(track_candidates)))
  
  tryCatch({
    # Debug: Check the input data structure
    # cat("🔍 DEBUG: Input data structure:\n")
    # cat("   Columns:", paste(names(track_candidates), collapse = ", "), "\n")
    # cat("   Sample artist:", if(nrow(track_candidates) > 0) track_candidates$main_artist[1] else "NO DATA", "\n")
    # cat("   Sample song:", if(nrow(track_candidates) > 0) track_candidates$main_song[1] else "NO DATA", "\n")
    
    # Test normalize function on single values first
    if (nrow(track_candidates) > 0) {
      test_artist <- track_candidates$main_artist[1]
      test_song <- track_candidates$main_song[1]
      
      cat("🧪 Testing normalize function:\n")
      tryCatch({
        norm_artist <- normalize_for_sql_search(test_artist, "%")
        norm_song <- normalize_for_sql_search(test_song, "%")
        cat("   ✅ Single value test passed\n")
        cat("   Original artist:", test_artist, "→ Normalized:", norm_artist, "\n")
      }, error = function(e) {
        cat("   ❌ Single value test failed:", e$message, "\n")
        stop("normalize_for_sql_search function is broken")
      })
    }
    
    # Create a list of all artist-song combinations to check
    check_pairs <- track_candidates %>%
      select(main_artist, main_song) %>%
      distinct()
    
    cat("🔍 Processing", nrow(check_pairs), "unique artist-song pairs\n")
    
    # Process in smaller chunks to isolate the problem
    safe_pairs <- data.frame()
    
    for (i in 1:nrow(check_pairs)) {
      tryCatch({
        artist <- check_pairs$main_artist[i]
        song <- check_pairs$main_song[i]
        
        # Handle missing values
        if (is.na(artist) || artist == "" || artist == "Unknown") {
          cat(sprintf("   ⚠️ Skipping invalid artist at row %d: '%s'\n", i, artist))
          next
        }
        if (is.na(song) || song == "" || song == "Unknown") {
          cat(sprintf("   ⚠️ Skipping invalid song at row %d: '%s'\n", i, song))
          next
        }
        
        # Test normalize on this specific pair
        norm_artist <- normalize_for_sql_search(artist, "%")
        norm_song <- normalize_for_sql_search(song, "%")
        
        # If we get here, it worked
        safe_pairs <- rbind(safe_pairs, data.frame(
          main_artist = artist,
          main_song = song,
          artist_normalized = norm_artist,
          song_normalized = norm_song
        ))
        
      }, error = function(e) {
        cat(sprintf("   ❌ Failed on row %d (%s - %s): %s\n", i, 
                    check_pairs$main_artist[i], check_pairs$main_song[i], e$message))
      })
    }
    
    cat(sprintf("✅ Successfully processed %d/%d pairs\n", nrow(safe_pairs), nrow(check_pairs)))
    
    if (nrow(safe_pairs) == 0) {
      cat("❌ No valid artist-song pairs to check\n")
      return(track_candidates[0, ])  # Return empty dataframe
    }
    
    # Build a single query using LIKE with normalized values (safe from SQL injection)
    conditions <- paste(sprintf("(artist LIKE '%%%s%%' AND song LIKE '%%%s%%')", 
                                safe_pairs$artist_normalized, 
                                safe_pairs$song_normalized), 
                        collapse = " OR ")
    
    batch_query <- paste0("SELECT DISTINCT artist, song FROM ", TALKING_POINTS_TABLE, 
                          " WHERE (", conditions, ") AND style = '", style, "'")
    
    # cat("🔍 DEBUG: Sample query part:", substr(batch_query, 1, 200), "...\n")
    
    available_intros <- sql_query(batch_query, connection_name = "batch_check")
    
    if (is.null(available_intros)) {
      cat("⚠️ Batch query failed, checking generic fallback...\n")
      # Check if we have generic fallbacks
      generic_query <- paste0("SELECT COUNT(*) as count FROM ", TALKING_POINTS_TABLE, 
                              " WHERE artist = 'generic' AND song = 'generic'")
      generic_result <- sql_query(generic_query, connection_name = "generic_check")
      
      if (!is.null(generic_result) && generic_result$count[1] > 0) {
        cat("✅ Generic fallbacks available - keeping all tracks\n")
        return(track_candidates)
      } else {
        cat("❌ No intros available (specific or generic)\n")
        return(track_candidates[0, ])  # Return empty dataframe
      }
    }
    
    # ===========================================================================
    # SMART FILTERING: Keep existing intros + generate missing ones
    # ===========================================================================
    
    final_tracks <- track_candidates %>%
      filter(sapply(1:n(), function(i) {
        # Normalize this candidate's info
        norm_artist <- normalize_for_sql_search(main_artist[i], "%")
        norm_song <- normalize_for_sql_search(main_song[i], "%")
        
        # Check if any available intro matches this normalized version
        has_existing_intro <- any(sapply(1:nrow(available_intros), function(j) {
          db_artist_norm <- normalize_for_sql_search(available_intros$artist[j], "%")
          db_song_norm <- normalize_for_sql_search(available_intros$song[j], "%")
          
          # Use grepl for fuzzy matching since normalize adds % wildcards
          grepl(norm_artist, db_artist_norm, fixed = TRUE) && 
            grepl(norm_song, db_song_norm, fixed = TRUE)
        }))
        
        if (has_existing_intro) {
          cat(sprintf("\n📂 Found existing intro: %s - %s\n", main_artist[i], main_song[i]))
          return(TRUE)  # Keep tracks that already have intros
        }
        
        # No existing intro - try to generate one
        cat(sprintf("\n🎭 Attempting to generate intro for: %s - %s\n", main_artist[i], main_song[i]))
        
        tryCatch({
          generation_success <- generate_artist_intro(main_artist[i], main_song[i], 1, 3, style = style)
          
          if (generation_success) {
            cat(sprintf("   ✅ Successfully generated intro for %s - %s\n", main_artist[i], main_song[i]))
            return(TRUE)  # Keep tracks where we successfully generated intros
          } else {
            cat(sprintf("   ❌ Failed to generate intro for %s - %s\n", main_artist[i], main_song[i]))
            return(FALSE)  # Remove tracks where generation failed
          }
          
        }, error = function(e) {
          cat(sprintf("   ❌ Error generating intro for %s - %s: %s\n", main_artist[i], main_song[i], e$message))
          return(FALSE)  # Remove tracks where generation errored
        })
      }))
    
    cat(sprintf("✅ Final result: %d tracks with intros (existing + generated)\n", nrow(final_tracks)))
    
    return(final_tracks)
    
  }, error = function(e) {
    cat("❌ Batch filtering failed:", e$message, "\n")
    cat("🔄 Falling back to original candidate list\n")
    return(track_candidates)  # Return original list if filtering fails
  })
}

# =============================================================================
# INTEGRATION FUNCTION: GET AND SAVE DJ INTRO
# =============================================================================

get_and_save_dj_intro <- function(selected_track, intro_type = 1, selected_track2 = NULL) {
  cat("🎭 GENERATING DJ INTRO...\n")
  
  if (is.null(selected_track)) {
    cat("❌ No track selected\n")
    return(NULL)
  }
  
  # Get intro text based on whether it's single or double play
  if (is.null(selected_track2)) {
    # Single track intro
    intro_text <- get_artist_intro(selected_track$main_artist, selected_track$main_song, intro_type)
    if (is.null(intro_text)) {
      result <- generate_artist_intro(selected_track$main_artist, selected_track$main_song, 1, 1)
      if (result) {
        intro_text <- get_artist_intro(selected_track$main_artist, selected_track$main_song, intro_type)
      }
    }
  } else {
    # Double-play intro
    cat("🎭 Attempting double-play intro generation...\n")
    
    # Try to get/generate double-play intro
    intro_text <- get_artist_intro(selected_track$main_artist, selected_track$main_song, 2,
                                     artist2 = selected_track2$main_artist, 
                                     song2 = selected_track2$main_song)
    
    if (is.null(intro_text)) {
      # Double-play failed, generate it
      result <- generate_artist_intro(selected_track$main_artist, selected_track$main_song, 2, 1,
                                      artist2 = selected_track2$main_artist, 
                                      song2 = selected_track2$main_song)
      
      if (result) {
        # Try to get it again after generation
        intro_text <- get_artist_intro(selected_track$main_artist, selected_track$main_song, 2,
                                         artist2 = selected_track2$main_artist, 
                                         song2 = selected_track2$main_song)
      }
    }
    
  }
  
  if (is.null(intro_text) || intro_text == "" || is.na(intro_text)) {
    cat("❌ Failed to get intro text\n")
    return(NULL)
  }
  
  # Create intro details structure
  intro_details <- list(
    timestamp = Sys.time(),
    artist = if (is.null(selected_track2)) {
      selected_track$main_artist
    } else {
      paste0(selected_track$main_artist, " - ", selected_track2$main_artist)
    },
    song = if (is.null(selected_track2)) {
      selected_track$main_song
    } else {
      paste0(selected_track$main_song, " - ", selected_track2$main_song)
    },
    genre = selected_track$main_genre,
    intro_type = intro_type,
    intro_text = intro_text,
    intro_length = nchar(intro_text),
    algorithm = "radio_intel_intro_system"
  )
  
  cat("✅ DJ Intro generated successfully:\n")
  cat(sprintf("   📊 Pre-Processing Length: %d characters\n", nchar(intro_text)))
  
  return(intro_details)
}

# =============================================================================
# CORE FUNCTION: GENERATE AND MEASURE BLOCK INTROS
# =============================================================================

generate_and_measure_block_intros <- function(selected_tracks) {
  cat("🎙️ GENERATING AND MEASURING REAL INTRO WAV FILES...\n")
  cat("📊 Processing", nrow(selected_tracks), "tracks\n\n")
  
  if (is.null(selected_tracks) || nrow(selected_tracks) == 0) {
    cat("❌ No tracks provided\n")
    return(NULL)
  }
  
  intro_results <- list()
  total_estimated_duration <- 0
  total_actual_duration <- 0
  
  for (i in 1:nrow(selected_tracks)) {
    track <- selected_tracks[i, ]
    
    cat(sprintf("🎤 Track %d/%d: %s - %s (intro_type: %d)\n", 
                i, nrow(selected_tracks), track$main_artist, track$main_song, track$intro_type))
    
    tryCatch({
      
      if (track$intro_type == 2) {
        # =============================================================================
        # DOUBLE-PLAY INTRO - USE BOTH TRACKS FROM METADATA
        # =============================================================================
        
        cat(sprintf("   🎭 Generating double-play intro for: %s + %s\n", 
                    track$main_song, track$partner_main_song))
        
        # Create partner track object from embedded metadata
        partner_track <- list(
          main_artist = track$partner_main_artist,
          main_song = track$partner_main_song
        )
        
        # Generate double-play intro
        intro_details <- get_and_save_dj_intro(track, 2, partner_track)
        
        if (is.null(intro_details)) {
          cat("   ⚠️ Double-play intro failed, using single intro\n")
          intro_details <- get_and_save_dj_intro(track, 1)
        }
        
      } else if (track$intro_type == 1) {
        # =============================================================================
        # SINGLE TRACK INTRO
        # =============================================================================
        
        intro_details <- get_and_save_dj_intro(track, 1)
        
      } else {
        # intro_type == 0 - no intro needed
        cat("   ⏭️ No intro needed (intro_type = 0)\n")
        intro_details <- NULL
      }
      
      # =============================================================================
      # CONVERT TO SPEECH AND MEASURE DURATION
      # =============================================================================
      
      if (!is.null(intro_details)) {
        cat("🗣️ Converting intro text to speech...\n")
        
        # Generate speech WAV file
        speech_result <- generate_speech_wav(intro_details)
        
        if (!is.null(speech_result) && !is.null(speech_result$audio_file)) {
          cat("⏱️ Measuring actual WAV duration...\n")
          
          # Measure actual duration from WAV file
          actual_duration <- measure_wav_duration(speech_result$audio_file)
          
          # Store complete result
          intro_result <- list(
            track_position = i,
            artist = track$main_artist,
            song = track$main_song,
            intro_text = intro_details$intro_text,
            estimated_duration = ESTIMATED_DURATION_OF_INTROS,
            actual_duration = actual_duration,
            wav_filename = speech_result$audio_filename,
            wav_filepath = speech_result$audio_file,
            generated_at = Sys.time()
          )
          
          intro_results[[i]] <- intro_result
          total_estimated_duration <- total_estimated_duration + ESTIMATED_DURATION_OF_INTROS
          total_actual_duration <- total_actual_duration + actual_duration
          
          cat(sprintf("   ✅ Generated WAV: %s (%.1f seconds)\n", 
                      speech_result$audio_filename, actual_duration))
        } else {
          cat("   ❌ TTS failed - creating fallback\n")
          intro_results[[i]] <- create_fallback_intro_result(track, i)
          total_estimated_duration <- total_estimated_duration + 10
          total_actual_duration <- total_actual_duration + 10
        }
      } else {
        # No intro needed
        intro_results[[i]] <- list(
          track_position = i,
          artist = track$main_artist,
          song = track$main_song,
          intro_text = NULL,
          estimated_duration = 0,
          actual_duration = 0,
          wav_filename = NULL,
          wav_filepath = NULL,
          generated_at = Sys.time()
        )
      }
      
    }, error = function(e) {
      cat("   ❌ Error:", e$message, "\n")
      intro_results[[i]] <<- create_fallback_intro_result(track, i)
      total_estimated_duration <<- total_estimated_duration + 10
      total_actual_duration <<- total_actual_duration + 10
    })
    
    cat("\n")
  }
  
  # Summary
  cat("🎯 INTRO GENERATION SUMMARY:\n")
  cat(sprintf("   📊 Tracks processed: %d\n", length(intro_results)))
  cat(sprintf("   ⏰ Total actual duration: %.1f seconds\n", total_actual_duration))
  
  successful_wavs <- sum(sapply(intro_results, function(x) !is.null(x$wav_filename)))
  cat(sprintf("   🎧 WAV files generated: %d/%d\n", successful_wavs, length(intro_results)))
  
  return(list(
    selected_tracks = selected_tracks,
    intro_details = intro_results,
    total_actual_duration = total_actual_duration
  ))
}

# =============================================================================
# HELPER FUNCTION: CREATE FALLBACK INTRO RESULT
# =============================================================================

create_fallback_intro_result <- function(track, position, intro_text) {
  return(list(
    track_position = position,
    artist = track$main_artist,
    song = track$main_song,
    intro_text = intro_text,
    estimated_duration = if(exists("ESTIMATED_DURATION_OF_INTROS")) ESTIMATED_DURATION_OF_INTROS else 30,
    actual_duration = if(exists("ESTIMATED_DURATION_OF_INTROS")) ESTIMATED_DURATION_OF_INTROS else 30,
    wav_filename = NULL,
    wav_filepath = NULL,
    generated_at = Sys.time()
  ))
}

# =============================================================================
# SURGICAL TIMING SYSTEM - DURATION-AWARE FILLER SELECTION
# =============================================================================

get_precision_filler <- function(gap_seconds, filler_type = "out-of-break") {
  cat(sprintf("🎯 Getting precision %s filler for %.1fs gap...\n", filler_type, gap_seconds))
  
  # Calculate smart min/max based on gap size and filler type
  if (filler_type == "out-of-break") {
    # Out-of-break fillers: use 40-70% of available gap
    min_duration <- max(3, gap_seconds * 0.99)
    max_duration <- min(25, gap_seconds * 0.99)
  } else if (filler_type == "into-break") {
    # Into-break fillers: use 50-90% of available gap (more aggressive)
    min_duration <- max(2, gap_seconds * 0.5)
    max_duration <- min(30, gap_seconds * 0.9)
  } else if (filler_type == "dj-ident") {
    # DJ-ident: chunky fillers, 30-70% of gap
    min_duration <- max(3, gap_seconds * 0.3)
    max_duration <- min(20, gap_seconds * 0.7)
  } else if (filler_type == "dj-or-ident") {
    # DJ or ident: shorter fillers, 20-60% of gap
    min_duration <- max(2, gap_seconds * 0.2)
    max_duration <- min(12, gap_seconds * 0.6)
  } else if (filler_type == "ident") {
    # Legacy ident support
    min_duration <- max(2, gap_seconds * 0.2)
    max_duration <- min(12, gap_seconds * 0.4)
  }
  
  # Fix backwards ranges for small gaps
  if (min_duration > max_duration) {
    temp_duration <- max_duration
    max_duration <- min_duration
    min_duration <- temp_duration
  }
  
  cat(sprintf("   📊 Seeking %s filler: %.1fs - %.1fs duration\n", 
              filler_type, min_duration, max_duration))
  
  tryCatch({
    con <- create_sql_connection(connection_name = "precision_filler")
    
    # Build the precision query based on filler type - USING STRING CONCATENATION
    if (filler_type == "out-of-break") {
      query <- paste0("SELECT dj_intros, duration FROM ", TALKING_POINTS_TABLE, 
                      " WHERE artist = 'breaks' AND song = 'out-of-break'",
                      " AND duration BETWEEN ", min_duration, " AND ", max_duration,
                      " ORDER BY RAND() LIMIT 1")
    } else if (filler_type == "into-break") {
      query <- paste0("SELECT dj_intros, duration FROM ", TALKING_POINTS_TABLE, 
                      " WHERE artist = 'breaks' AND song = 'into-break'",
                      " AND duration <= ", max_duration,
                      " ORDER BY duration DESC LIMIT 1")
    } else if (filler_type == "dj-ident") {
      query <- paste0("SELECT dj_intros, duration FROM ", TALKING_POINTS_TABLE,
                      " WHERE artist = 'intros' AND song = 'dj-ident'",
                      " AND duration BETWEEN ", min_duration, " AND ", max_duration, 
                      " ORDER BY RAND() LIMIT 1")
    } else if (filler_type == "dj-or-ident") {
      query <- paste0("SELECT dj_intros, duration FROM ", TALKING_POINTS_TABLE,
                      " WHERE artist = 'intros' AND song IN ('dj', 'ident')",
                      " AND duration BETWEEN ", min_duration, " AND ", max_duration, 
                      " ORDER BY RAND() LIMIT 1")
    } else if (filler_type == "ident") {
      # Legacy support
      query <- paste0("SELECT dj_intros, duration FROM ", TALKING_POINTS_TABLE,
                      " WHERE artist = 'intros' AND song IN ('dj', 'ident', 'dj-ident')",
                      " AND duration BETWEEN ", min_duration, " AND ", max_duration, 
                      " ORDER BY RAND() LIMIT 1")
    }
    
    # Execute precision query - NO PARAMETERS NEEDED
    result <- dbGetQuery(con, query)
    dbDisconnect(con)
    
    if (!is.null(result) && nrow(result) > 0) {
      selected_filler <- result[1, ]
      cat(sprintf("   ✅ Selected: '%.40s...' (%.1fs - using SQL duration!)\n", 
                  selected_filler$dj_intros, selected_filler$duration))
      return(selected_filler)
    } else {
      cat(sprintf("   ⚠️ No %s fillers found in range %.1f-%.1fs\n", 
                  filler_type, min_duration, max_duration))
      
      # Fallback: try wider range
      wider_min <- max(2, min_duration - 3)
      wider_max <- max_duration + 5
      
      # Fix backwards ranges in fallback too
      if (wider_min > wider_max) {
        temp_duration <- wider_max
        wider_max <- wider_min
        wider_min <- temp_duration
      }
      
      cat(sprintf("   🔄 Trying wider range: %.1f-%.1fs\n", wider_min, wider_max))
      
      con <- create_sql_connection(connection_name = "precision_filler_fallback")
      
      # Fallback query - try appropriate category for filler type
      if (filler_type == "out-of-break") {
        fallback_query <- paste0("SELECT dj_intros, duration FROM ", TALKING_POINTS_TABLE,
                                 " WHERE artist = 'breaks' AND song = 'out-of-break'",
                                 " AND duration BETWEEN ", wider_min, " AND ", wider_max,
                                 " ORDER BY RAND() LIMIT 1")
      } else if (filler_type == "into-break") {
        fallback_query <- paste0("SELECT dj_intros, duration FROM ", TALKING_POINTS_TABLE,
                                 " WHERE artist = 'breaks' AND song = 'into-break'",
                                 " AND duration BETWEEN ", wider_min, " AND ", wider_max,
                                 " ORDER BY RAND() LIMIT 1")
      } else {
        # For ident types, try any ident
        fallback_query <- paste0("SELECT dj_intros, duration FROM ", TALKING_POINTS_TABLE,
                                 " WHERE artist = 'intros' AND song IN ('dj', 'ident', 'dj-ident')",
                                 " AND duration BETWEEN ", wider_min, " AND ", wider_max, 
                                 " ORDER BY RAND() LIMIT 1")
      }
      
      fallback_result <- dbGetQuery(con, fallback_query)
      dbDisconnect(con)
      
      if (!is.null(fallback_result) && nrow(fallback_result) > 0) {
        selected_filler <- fallback_result[1, ]
        cat(sprintf("   ✅ Fallback selected: '%.40s...' (%.1fs)\n", 
                    selected_filler$dj_intros, selected_filler$duration))
        return(selected_filler)
      } else {
        # Final fallback - create emergency filler with SQL-style duration
        emergency_duration <- min(gap_seconds * 0.5, 8)
        cat(sprintf("   🚨 Emergency fallback - creating generic filler (%.1fs)\n", emergency_duration))
        
        # Different emergency text based on filler type
        emergency_text <- if (filler_type == "into-break") {
          "More music coming up shortly"
        } else if (filler_type == "out-of-break") {
          "Short transition"
        } else {
          paste0("This is ", MAIN_STATION_NAME)
        }
        
        return(data.frame(
          dj_intros = emergency_text,
          duration = emergency_duration
        ))
      }
    }
    
  }, error = function(e) {
    cat(sprintf("   ❌ Database error: %s\n", e$message))
    # Emergency fallback
    emergency_duration <- min(gap_seconds * 0.5, 5)
    emergency_text <- if (filler_type == "into-break") {
      "More music coming up"
    } else if (filler_type == "out-of-break") {
      "Generic transition"
    } else {
      paste0("This is ", MAIN_STATION_NAME)
    }
    
    return(data.frame(
      dj_intros = emergency_text,
      duration = emergency_duration
    ))
  })
}

# =============================================================================
# ENHANCED PRECISION FILLER WITH HIERARCHICAL SELECTION
# =============================================================================

get_hierarchical_ident_filler <- function(gap_seconds) {
  cat(sprintf("🎯 Getting hierarchical ident filler for %.1fs gap...\n", gap_seconds))
  
  # Try dj-ident first (chunky fillers for bigger gaps)
  cat("   🔍 Trying dj-ident fillers first (chunky)...\n")
  chunky_filler <- get_precision_filler(gap_seconds, "dj-ident")
  
  if (!is.null(chunky_filler)) {
    cat(sprintf("   ✅ Found chunky dj-ident: '%.40s...' (%.1fs)\n", 
                chunky_filler$dj_intros, chunky_filler$duration))
    return(chunky_filler)
  }
  
  # Fallback to shorter dj or ident fillers
  cat("   🔍 No suitable dj-ident found, trying shorter dj/ident...\n")
  short_filler <- get_precision_filler(gap_seconds, "dj-or-ident")
  
  if (!is.null(short_filler)) {
    cat(sprintf("   ✅ Found short dj/ident: '%.40s...' (%.1fs)\n", 
                short_filler$dj_intros, short_filler$duration))
    return(short_filler)
  }
  
  cat("   ⚠️ No suitable ident fillers found in any category\n")
  return(NULL)
}


# =============================================================================
# ENHANCED SURGICAL TIMING - MULTI-STAGE PRECISION FILLING
# =============================================================================

fill_timing_gaps <- function(selected_block, intro_durations) {
  cat("🎯 SURGICAL TIMING GAP FILLING - PRECISION MODE...\n")
  
  # Calculate current total duration using effective_duration_with_fades
  total_block_duration <- sum(selected_block$effective_duration_with_fades)
  
  # Use proper target calculation - only subtract INTO_BREAK_BUFFER
  if (AI_RUNTIME_MODE == "timing") {
  target_seconds <- (TIME_MARK_BLOCK_LENGTH * 60) - INTO_BREAK_BUFFER
  gap_seconds <- target_seconds - total_block_duration
  } else {
    target_seconds <- 0
    gap_seconds <- 0
  }
  
  cat(sprintf("   📊 Current gap: %.1f seconds\n", gap_seconds))
  cat(sprintf("   🎯 Target: %.0f seconds\n", target_seconds))
  cat(sprintf("   ⚡ Precision required: %.1f seconds to fill\n", gap_seconds))
  
  filler_elements <- list()
  total_filler_used <- 0
  remaining_gap <- gap_seconds
  
  # =============================================================================
  # STAGES 1-3: REGULAR SURGICAL TIMING (only if gap > 2s)
  # =============================================================================
  
  if (remaining_gap > 2 && AI_RUNTIME_MODE == 'timing') {
    
    # STAGE 1: PRIMARY OUT-OF-BREAK FILLER
    cat("\n🎯 STAGE 1: Primary out-of-break filler...\n")
    
    primary_filler <- get_precision_filler(remaining_gap, "out-of-break")
    
    if (!is.null(primary_filler)) {
      filler_elements[["opening_random"]] <- list(
        position = "before_track_1",
        content = list(
          text = primary_filler$dj_intros,
          duration = primary_filler$duration
        )
      )
      
      total_filler_used <- total_filler_used + primary_filler$duration
      remaining_gap <- remaining_gap - primary_filler$duration
      
      cat(sprintf("   ✅ Primary filler added: %.1fs (%.1fs gap remaining)\n", 
                  primary_filler$duration, remaining_gap))
    }
    
    # STAGE 2: MID-BLOCK IDENT (if gap still > 2s and we have multiple tracks)
    if (remaining_gap > 2 && nrow(selected_block) > 2 && AI_RUNTIME_MODE == 'timing') {
      cat("\n🎯 STAGE 2: Mid-block station ident...\n")
      
      # Find good position (avoid first and last tracks)
      mid_position <- ceiling(nrow(selected_block) / 2)
      if (mid_position == 1) mid_position <- 2
      if (mid_position == nrow(selected_block)) mid_position <- mid_position - 1
      
      ident_filler <- get_hierarchical_ident_filler(remaining_gap)
      
      if (!is.null(ident_filler)) {
        mid_filler_key <- paste0("before_track_", mid_position)
        filler_elements[[paste0("mid_ident_", mid_position)]] <- list(
          position = mid_filler_key,
          content = list(
            text = ident_filler$dj_intros,
            duration = ident_filler$duration
          )
        )
        
        total_filler_used <- total_filler_used + ident_filler$duration
        remaining_gap <- remaining_gap - ident_filler$duration
        
        cat(sprintf("   ✅ Mid-block ident added: %.1fs at position %d (%.1fs gap remaining)\n", 
                    ident_filler$duration, mid_position, remaining_gap))
      }
    }
    
    # STAGE 3: ADDITIONAL STATION IDENT (if gap still > 2s)
    if (remaining_gap > 2 && nrow(selected_block) > 1 && AI_RUNTIME_MODE == 'timing') {
      cat("\n🎯 STAGE 3: Additional station ident...\n")
      
      # Find position for additional ident (later in block)
      final_position <- min(nrow(selected_block), ceiling(nrow(selected_block) * 0.75))
      if (final_position == 1) final_position <- 2
      
      # Check if this position is already used
      final_filler_key <- paste0("before_track_", final_position)
      position_taken <- any(sapply(filler_elements, function(x) x$position == final_filler_key))
      
      if (!position_taken) {
        additional_ident <- get_hierarchical_ident_filler(remaining_gap)
        
        if (!is.null(additional_ident)) {
          filler_elements[[paste0("additional_ident_", final_position)]] <- list(
            position = final_filler_key,
            content = list(
              text = additional_ident$dj_intros,
              duration = additional_ident$duration
            )
          )
          
          total_filler_used <- total_filler_used + additional_ident$duration
          remaining_gap <- remaining_gap - additional_ident$duration
          
          cat(sprintf("   ✅ Additional ident added: %.1fs at position %d (%.1fs final gap)\n", 
                      additional_ident$duration, final_position, remaining_gap))
        }
      } else {
        cat("   ⚠️ Position already occupied - skipping additional ident\n")
      }
    }
    
  } else {
    cat("\n💤 STAGES 1-3: Gap too small for regular fillers\n")
  }
  
  # =============================================================================
  # STAGE 4: INTO-BREAK MESSAGE (INDEPENDENT - ALWAYS CHECK IF ENABLED)
  # =============================================================================
  
  if (PREALLOCATE_INTO_BREAK_MESSAGE && AI_RUNTIME_MODE == 'timing') {
    cat("\n🎯 STAGE 4: Pre-allocating into-break message...\n")
    
    # Calculate total space available up to full 30-minute target
    current_total_duration <- sum(selected_block$effective_duration_with_fades) + total_filler_used
    full_target <- TIME_MARK_BLOCK_LENGTH * 60  # Full 30 minutes
    available_space <- full_target - current_total_duration
    
    cat(sprintf("   📊 Current total duration: %.1fs\n", current_total_duration))
    cat(sprintf("   📊 Available space for into-break: %.1fs\n", available_space))
    
    if (available_space > 2) {  # Only if worthwhile
      into_break_filler <- get_precision_filler(available_space, "into-break")
      
      if (!is.null(into_break_filler)) {
        # Add to filler elements at the end
        filler_elements[["into_break_message"]] <- list(
          position = "end_of_block",
          content = list(
            text = into_break_filler$dj_intros,
            duration = into_break_filler$duration
          )
        )
        
        total_filler_used <- total_filler_used + into_break_filler$duration
        
        cat(sprintf("   ✅ Into-break message allocated: %.1fs\n", into_break_filler$duration))
        cat(sprintf("   📊 Total filler used (including into-break): %.1fs\n", total_filler_used))
      } else {
        cat("   ⚠️ No suitable into-break message found\n")
      }
    } else {
      cat("   ⚠️ Available space too small for into-break message\n")
    }
  } else {
    cat("\n💤 STAGE 4: Into-break pre-allocation disabled\n")
  }
  
  # =============================================================================
  # FINAL ASSESSMENT
  # =============================================================================
  
  final_gap <- gap_seconds - total_filler_used
  
  cat(sprintf("\n📊 SURGICAL TIMING RESULTS:\n"))
  cat(sprintf("   🎵 Original gap: %.1fs\n", gap_seconds))
  cat(sprintf("   ⚡ Total filler used: %.1fs\n", total_filler_used))
  cat(sprintf("   🎯 Final gap: %.1fs\n", final_gap))
  cat(sprintf("   💯 Precision: %.1f%% filled\n", 
              if(gap_seconds > 0) (total_filler_used / gap_seconds) * 100 else 0))
  
  if (abs(final_gap) <= 10) {
    cat("   ✅ SURGICAL SUCCESS - Perfect timing achieved!\n")
  } else if (final_gap > 0) {
    cat(sprintf("   ⚠️ Still %.1fs under - playout system will handle\n", final_gap))
  } else {
    cat(sprintf("   ⚠️ %.1fs over - acceptable variance\n", abs(final_gap)))
  }
  
  # Create complete block with file paths preserved
  complete_block <- create_complete_block(selected_block, intro_durations, filler_elements)
  
  return(list(
    complete_block = complete_block,
    filler_elements = filler_elements,
    filler_used = total_filler_used,
    final_gap = final_gap,
    precision_achieved = abs(final_gap) <= 10
  ))
}

# =============================================================================
# HELPER FUNCTION: CREATE COMPLETE BLOCK
# =============================================================================

create_complete_block <- function(selected_block, intro_durations, filler_elements) {
  cat("🎯 CREATING COMPLETE BLOCK STRUCTURE...\n")
  
  complete_elements <- list()
  element_count <- 1
  
  # Track which filler elements we've already added
  added_fillers <- character(0)
  
  # =============================================================================
  # PHASE 1: ADD OPENING FILLERS
  # =============================================================================
  
  # Add opening filler elements in correct order
  opening_order <- c("opening_random")
  for (filler_name in opening_order) {
    if (filler_name %in% names(filler_elements)) {
      filler <- filler_elements[[filler_name]]
      if (filler$position == "before_track_1") {
        complete_elements[[element_count]] <- list(
          type = "filler", 
          content = filler$content$text,
          duration = filler$content$duration,
          source = filler_name,
          
          # Generate TTS audio file for this filler
          filler_audio = generate_filler_audio(filler$content$text, filler_name),
          text = filler$content$text
        )
        element_count <- element_count + 1
        added_fillers <- c(added_fillers, filler_name)
        
        cat(sprintf("   ✅ Added opening filler: %s (%.1fs)\n", 
                    filler_name, filler$content$duration))
      }
    }
  }
  
  # =============================================================================
  # PHASE 2: ADD TRACKS WITH THEIR INTROS AND MID-BLOCK FILLERS
  # =============================================================================
  
  # Add tracks with their intros and any mid-block fillers
  for (i in 1:nrow(selected_block)) {
    track <- selected_block[i, ]
    
    # Check for mid-block filler before this track
    mid_filler_key <- paste0("before_track_", i)
    for (filler_name in names(filler_elements)) {
      if (filler_name %in% added_fillers) next  # Skip already added fillers
      filler <- filler_elements[[filler_name]]
      if (filler$position == mid_filler_key) {
        added_fillers <- c(added_fillers, filler_name)  # Mark as added
        complete_elements[[element_count]] <- list(
          type = "filler",
          content = filler$content$text,
          duration = filler$content$duration,
          source = filler_name,
          
          # Generate TTS audio file for this filler
          filler_audio = generate_filler_audio(filler$content$text, filler_name),
          text = filler$content$text
        )
        element_count <- element_count + 1
        
        cat(sprintf("   ✅ Added mid-block filler: %s (%.1fs)\n", 
                    filler_name, filler$content$duration))
      }
    }
    
    # Add intro (if not zero duration)
    if (intro_durations[i] > 0) {
      complete_elements[[element_count]] <- list(
        type = "intro",
        content = paste0("Intro for ", track$main_artist, " - ", track$main_song),
        duration = intro_durations[i],
        intro_type = if (!is.null(track$intro_type)) track$intro_type else 1,
        
        # Add intro file paths
        intro_filenames = track$intro_filenames,
        intro_full_path = track$intro_full_path,
        artist = track$main_artist,
        song = track$main_song
      )
      element_count <- element_count + 1
    }
    
    # Add track with ALL data from selected_block preserved + enriched
    complete_elements[[element_count]] <- list(
      type = "track",
      artist = track$main_artist,
      song = track$main_song,
      duration = track$track_duration,
      content = paste0(track$main_artist, " - ", track$main_song),
      
      # PRESERVE ALL ORIGINAL DATA FROM selected_block
      main_artist = track$main_artist,
      main_song = track$main_song,
      total_plays = track$total_plays,
      avg_success_rate = track$avg_success_rate,
      avg_listener_change = track$avg_listener_change,
      works_in_decline = track$works_in_decline,
      works_in_growth = track$works_in_growth,
      works_weekend = track$works_weekend,
      works_weekday = track$works_weekday,
      works_prime = track$works_prime,
      works_offpeak = track$works_offpeak,
      best_hour = track$best_hour,
      handles_volatility = track$handles_volatility,
      decline_specialist = track$decline_specialist,
      growth_specialist = track$growth_specialist,
      weekend_specialist = track$weekend_specialist,
      prime_specialist = track$prime_specialist,
      ai_confidence = track$ai_confidence,
      track_id = track$track_id,
      main_genre = track$main_genre,
      need_score = track$need_score,
      base_ai_score = track$base_ai_score,
      genre_balance_score = track$genre_balance_score,
      dj_ai_score = track$dj_ai_score,
      artist_novelty = track$artist_novelty,
      track_novelty = track$track_novelty,
      genre_saturation_penalty = track$genre_saturation_penalty,
      novelty_bonus = track$novelty_bonus,
      exploration_uncertainty = track$exploration_uncertainty,
      serendipity_factor = track$serendipity_factor,
      fuzzy_dj_score = track$fuzzy_dj_score,
      score_band = track$score_band,
      selection_weight = track$selection_weight,
      track_duration_mins = track$track_duration_mins,
      estimated_intro_duration = track$estimated_intro_duration,
      total_estimated_duration = track$total_estimated_duration,
      effective_duration_with_fades = track$effective_duration_with_fades,
      optimization_improved = track$optimization_improved,
      block_position = track$block_position,
      total_music_duration = track$total_music_duration,
      talk_time_needed = track$talk_time_needed,
      
      # CRITICAL FILE PATHS
      track_file_path = track$track_file_path,
      track_file_name = track$track_file_name,
      intro_type = track$intro_type,
      intro_filenames = track$intro_filenames,
      intro_full_path = track$intro_full_path,
      intro_text = track$intro_text,
      
      # ENRICHED DATA (intro duration from function parameter)
      intro_duration = intro_durations[i],
      track_duration = track$track_duration
    )
    
    for (field_name in names(track)) {
      if (grepl("^partner_", field_name)) {
        complete_elements[[element_count]][[field_name]] <- track[[field_name]]
      }
    }
    
    element_count <- element_count + 1
    
    cat(sprintf("   ✅ Added track %d: %s - %s (%.1fs)\n", 
                i, track$main_artist, track$main_song, track$track_duration))
  }
  
  # =============================================================================
  # PHASE 3: ADD END-OF-BLOCK FILLERS (INTO-BREAK MESSAGES)
  # =============================================================================
  
  # Process any remaining fillers that haven't been added yet
  for (filler_name in names(filler_elements)) {
    if (filler_name %in% added_fillers) next  # Skip already added fillers
    
    filler <- filler_elements[[filler_name]]
    
    # Handle end-of-block positioned fillers (like into-break messages)
    if (filler$position == "end_of_block") {
      complete_elements[[element_count]] <- list(
        type = "filler",
        content = filler$content$text,
        duration = filler$content$duration,
        source = filler_name,
        
        # Generate TTS audio file for this filler
        filler_audio = generate_filler_audio(filler$content$text, filler_name),
        text = filler$content$text
      )
      element_count <- element_count + 1
      added_fillers <- c(added_fillers, filler_name)
      
      cat(sprintf("   ✅ Added end-of-block filler: %s (%.1fs)\n", 
                  filler_name, filler$content$duration))
    } else {
      # Log any unprocessed fillers for debugging
      cat(sprintf("   ⚠️ Unprocessed filler: %s (position='%s')\n", 
                  filler_name, filler$position))
    }
  }
  
  # =============================================================================
  # FINAL SUMMARY
  # =============================================================================
  
  cat(sprintf("\n   📊 Complete block created:\n"))
  cat(sprintf("   📁 Total elements: %d\n", length(complete_elements)))
  cat(sprintf("   📻 Fillers processed: %s\n", 
              if(length(added_fillers) > 0) paste(added_fillers, collapse=", ") else "none"))
  
  return(complete_elements)
}

# =============================================================================
# HELPER FUNCTION: GENERATE FILLER AUDIO FILES
# =============================================================================

generate_filler_audio <- function(filler_text, filler_name) {
  cat(sprintf("🎵 Generating audio for filler: %s\n", filler_name))
  
  # Create timestamp for unique filename
  timestamp <- format(Sys.time(), "%Y%m%d_%H%M%S")
  
  # Create safe filename from filler name
  safe_name <- gsub("[^A-Za-z0-9_]", "_", filler_name)
  filename <- paste0(timestamp, "_filler_", safe_name, ".wav")
  full_path <- file.path(TTS_OUTPUT_DIR, filename)
  
  # Generate the actual audio file using TTS
  if (TTS_ENABLED) {
    tryCatch({
      # Create a filler-compatible intro_details object for existing TTS system
      filler_intro_details <- list(
        intro_text = filler_text,
        artist = "FILLER",                    # Use "FILLER" as artist
        song = gsub("[^A-Za-z0-9]", "_", filler_name)  # Clean filler name as song
      )
      
      # Use existing generate_speech_wav function
      speech_result <- generate_speech_wav(filler_intro_details)
      
      if (!is.null(speech_result) && !is.null(speech_result$audio_file)) {
        # Update the filename and path to match what we want
        filename <- basename(speech_result$audio_filename)
        full_path <- speech_result$audio_file
        
        cat(sprintf("   ✅ Generated: %s\n", filename))
        
      } else {
        cat("   ⚠️ TTS generation returned no audio file\n")
        # Create placeholder file or use fallback
      }
      
    }, error = function(e) {
      cat(sprintf("   ⚠️ TTS generation failed: %s\n", e$message))
      # Create placeholder file or use fallback
    })
  } else {
    cat("   🔇 TTS disabled - creating placeholder entry\n")
  }
  
  return(list(
    filename = filename,
    full_path = full_path,
    text = filler_text
  ))
}

# =============================================================================
# DISPLAY FUNCTION: SHOW COMPLETE BLOCK
# =============================================================================

display_complete_block <- function(complete_block) {
  cat("\n🎯 COMPLETE BLOCK WITH SURGICAL TIMING:\n")
  cat(paste0(rep("=", 80), collapse = ""), "\n")
  
  total_duration <- 0
  element_num <- 1
  
  # Work with indexed list structure from create_complete_block()
  for (element in complete_block) {
    
    if (element$type == "filler") {
      total_duration <- total_duration + element$duration
      
      cat(sprintf("%d. 📻 FILLER (%.1fs): %s\n", 
                  element_num, element$duration, substr(element$content, 1, 60)))
      
      # Show filler audio file info if available
      if (!is.null(element$filler_audio)) {
        cat(sprintf("     📁 Audio: %s\n", element$filler_audio$filename))
        cat(sprintf("     📂 Path: %s\n\n", element$filler_audio$full_path))
      } else {
        cat(sprintf("     📝 Source: %s\n\n", element$source))
      }
      
    } else if (element$type == "intro") {
      total_duration <- total_duration + element$duration
      
      cat(sprintf("%d. 🎙️ INTRO (%.1fs): %s\n", 
                  element_num, element$duration, element$content))
      
      # Show intro file paths if available
      if (!is.null(element$intro_filenames)) {
        cat(sprintf("     📁 Intro: %s\n", element$intro_filenames))
        cat(sprintf("     📂 Path: %s\n\n", element$intro_full_path))
      } else {
        cat("     📝 No intro file\n\n")
      }
      
    } else if (element$type == "track") {
      total_duration <- total_duration + element$duration
      duration_min <- element$duration / 60
      
      cat(sprintf("%d. 🎵 %s - %s (%.1f min)\n", 
                  element_num, element$artist, element$song, duration_min))
      
      # Show all the rich file path data
      if (!is.null(element$track_file_name)) {
        cat(sprintf("     📁 Track: %s\n", element$track_file_name))
        cat(sprintf("     📂 Track Path: %s\n", element$track_file_path))
      }
      
      if (!is.null(element$intro_duration) && element$intro_duration > 0) {
        cat(sprintf("     🎙️ Intro Duration: %.1fs\n", element$intro_duration))
        if (!is.null(element$intro_filenames)) {
          cat(sprintf("     📁 Intro: %s\n", element$intro_filenames))
          cat(sprintf("     📂 Intro Path: %s\n", element$intro_full_path))
        }
      }
      
      # Show key AI/scoring data
      if (!is.null(element$fuzzy_dj_score)) {
        cat(sprintf("     🤖 AI Score: %.3f", element$fuzzy_dj_score))
        if (!is.null(element$ai_confidence)) {
          cat(sprintf(" (Confidence: %.3f)", element$ai_confidence))
        }
        cat("\n")
      }
      
      # Show genre and timing info
      if (!is.null(element$main_genre)) {
        cat(sprintf("     🎼 Genre: %s", element$main_genre))
        if (!is.null(element$effective_duration_with_fades)) {
          cat(sprintf(" | Effective Duration: %.1fs", element$effective_duration_with_fades))
        }
        cat("\n")
      }
      
      cat("\n")
    }
    
    element_num <- element_num + 1
  }
  
  cat(paste0(rep("=", 80), collapse = ""), "\n")
  
  # =============================================================================
  # COMPLETE BLOCK SUMMARY WITH ENRICHED DATA
  # =============================================================================
  
  if (!is.null(complete_block) && length(complete_block) > 0) {
    
    # Count different element types
    filler_count <- sum(sapply(complete_block, function(x) x$type == "filler"))
    intro_count <- sum(sapply(complete_block, function(x) x$type == "intro"))
    track_count <- sum(sapply(complete_block, function(x) x$type == "track"))
    
    # Calculate total duration using enriched data
    total_block_duration <- sum(sapply(complete_block, function(x) {
      if (x$type == "track" && !is.null(x$track_duration_nett)) {
        return(x$track_duration_nett)
      } else {
        return(x$duration)
      }
    }))
    
    # Calculate gap using the same target as surgical timing
    target_seconds <- TIME_MARK_BLOCK_LENGTH * 60  # Full 30 minutes
    gap_seconds <- target_seconds - total_block_duration
    gap_minutes <- gap_seconds / 60
    
    cat("📊 COMPLETE BLOCK SUMMARY (ENRICHED DATA):\n")
    cat(sprintf("   🎵 Total block duration: %.1f minutes (%.0f seconds)\n", 
                total_block_duration / 60, total_block_duration))
    cat(sprintf("   🎯 Target duration: %.1f minutes\n", TIME_MARK_BLOCK_LENGTH))
    cat(sprintf("   📈 Gap: %+.1f minutes (%+.0f seconds) %s\n", 
                gap_minutes, gap_seconds, 
                if(gap_seconds > 0) "UNDER target" else "OVER target"))
    cat(sprintf("   💯 Fill percentage: %.1f%%\n", 
                (total_block_duration / target_seconds) * 100))
    
    cat(sprintf("\n   🎵 Elements: %d tracks + %d intros + %d fillers = %d total\n", 
                track_count, intro_count, filler_count, length(complete_block)))
    
    # Show average AI confidence if available
    ai_scores <- sapply(complete_block, function(x) {
      if (x$type == "track" && !is.null(x$fuzzy_dj_score)) x$fuzzy_dj_score else NA
    })
    ai_scores <- ai_scores[!is.na(ai_scores)]
    
    if (length(ai_scores) > 0) {
      cat(sprintf("   🤖 Average AI Score: %.3f (range: %.3f - %.3f)\n", 
                  mean(ai_scores), min(ai_scores), max(ai_scores)))
    }
    
    # Show genre distribution
    genres <- sapply(complete_block, function(x) {
      if (x$type == "track" && !is.null(x$main_genre)) x$main_genre else NA
    })
    genres <- genres[!is.na(genres)]
    
    if (length(genres) > 0) {
      genre_table <- table(genres)
      cat(sprintf("   🎼 Genres: %s\n", 
                  paste(names(genre_table), collapse=", ")))
    }
    
  } else {
    cat("❌ Missing complete block data for summary\n")
  }
}

# =============================================================================
# RECORD AI DJ SELECTION
# =============================================================================

record_ai_dj_selection <- function(artist, song, genre = NULL, introduction = NULL, 
                                   decision_reason = "AI DJ selection", algorithm = "ai_dj",
                                   context_factors = "{}", current_listeners = 0) {
  
  cat("📝 Recording AI DJ selection...\n")
  
  tryCatch({
    # Check if the AI DJ log table is configured
    if (!exists("AI_DJ_HISTORY_TABLE") || is.null(AI_DJ_HISTORY_TABLE) || AI_DJ_HISTORY_TABLE == "") {
      cat("   ⚠️ AI_DJ_HISTORY_TABLE not configured - skipping recording\n")
      return(TRUE)  # Don't fail if logging isn't set up
    }
    
    # Prepare the insert query with SQL connection
    insert_query <- paste0("INSERT INTO ", AI_DJ_HISTORY_TABLE, 
                           " (played_at, artist, song, genre, introduction_used, decision_reason, ",
                           "selection_algorithm, context_factors, listener_count_when_selected) ",
                           "VALUES (NOW(), ?, ?, ?, ?, ?, ?, ?, ?)")
    
    # Use SQL connection with parameterized query
    con <- create_sql_connection(connection_name = "record_selection")
    
    result <- dbExecute(con, insert_query, params = list(
      artist, song, genre, introduction, decision_reason, 
      algorithm, context_factors, current_listeners
    ))
    
    dbDisconnect(con)
    
    if (result > 0) {
      cat("   ✅ AI DJ selection recorded successfully\n")
      return(TRUE)
    } else {
      cat("   ⚠️ No rows affected in AI DJ selection recording\n")
      return(FALSE)
    }
    
  }, error = function(e) {
    cat("   ❌ Error recording AI DJ selection:", e$message, "\n")
    if (exists("con") && dbIsValid(con)) dbDisconnect(con)
    return(FALSE)
  })
}

# =============================================================================
# TEXT-TO-SPEECH FUNCTIONS
# =============================================================================

generate_speech_wav <- function(intro_details) {
  if (!TTS_ENABLED) {
    cat("🔇 TTS disabled in configuration\n")
    return(intro_details)
  }
  
  cat("🗣️ CONVERTING TO SPEECH...\n")
  
  if (is.null(intro_details) || is.null(intro_details$intro_text)) {
    cat("❌ No intro text to convert\n")
    return(intro_details)
  }
  
  # Create filename with timestamp
  timestamp_str <- format(Sys.time(), "%Y%m%d_%H%M%S")
  artist_clean <- gsub("[^A-Za-z0-9]", "_", intro_details$artist)
  song_clean <- gsub("[^A-Za-z0-9]", "_", intro_details$song)
  
  audio_filename <- paste0(timestamp_str, "_", artist_clean, "_", song_clean, ".wav")
  audio_filepath <- file.path(TTS_OUTPUT_DIR, audio_filename)
  
  # Try different TTS methods using enhanced text
  tts_success <- FALSE
  
  enhanced_text <- enhanced_text_for_speech(intro_details$intro_text)
  #enhanced_text <- intro_details$intro_text
  
  if (TTS_SERVICE %in% c("google", "amazon", "microsoft")) {
    # Cloud-based TTS services with enhanced text
    tts_success <- try_cloud_tts(enhanced_text, audio_filepath)
    #tts_success <- try_cloud_tts(intro_details$intro_text, audio_filepath)
  } else if (TTS_SERVICE == "espeak") {
    # Local eSpeak TTS with enhanced text
    tts_success <- try_espeak_tts(enhanced_text, audio_filepath)
  }
  
  if (tts_success) {
    intro_details$audio_file <- audio_filepath
    intro_details$audio_filename <- audio_filename
    intro_details$tts_service <- TTS_SERVICE
    intro_details$tts_timestamp <- Sys.time()
    
    cat("✅ Speech generated successfully!\n")
    cat(sprintf("   🎧 Audio file: %s\n", audio_filename))
    cat(sprintf("   💾 Full path: %s\n", audio_filepath))

  } else {
    cat("❌ TTS conversion failed\n")
  }
  
  return(intro_details)
}

# =============================================================================
# HELPER FUNCTIONS FOR TTS
# =============================================================================


# Main TTS dispatcher - tries cloud services first, falls back to eSpeak
try_cloud_tts <- function(text, output_path) {
  tryCatch({
    # Try the configured TTS service
    if (TTS_SERVICE == "google") {
      return(try_google_tts(text, output_path))
    } else if (TTS_SERVICE == "amazon") {
      return(try_amazon_tts(text, output_path))
    } else if (TTS_SERVICE == "microsoft") {
      return(try_microsoft_tts(text, output_path))
    } else {
      cat("❌ Unknown TTS service:", TTS_SERVICE, "\n")
      return(FALSE)
    }
    
  }, error = function(e) {
    cat("❌ Cloud TTS error:", e$message, "\n")
    cat("💡 Trying fallback eSpeak method...\n")
    return(try_espeak_tts(text, output_path))
  })
}

# Google TTS using direct API
try_google_tts <- function(text, output_path) {
  tryCatch({
    if (!exists("GOOGLE_TTS_API_KEY") || is.null(GOOGLE_TTS_API_KEY) || GOOGLE_TTS_API_KEY == "") {
      cat("❌ Google TTS API key not configured\n")
      return(FALSE)
    }
    
    cat("\n🔍 Attempting Google TTS synthesis...\n")
    cat("🔍 Voice:", GOOGLE_TTS_VOICE, "\n")
    cat("🔍 Speed:", TTS_SPEED, "\n")
    cat("🔍 Processed Length:", nchar(text), "characters\n")
    
    # Check if text contains SSML markup
    is_ssml <- grepl("<speak>|<prosody>|<break>", text)
    
    # Create request body with pitch and SSML support
    request_body <- list(
      input = if(is_ssml) {
        list(ssml = text)
      } else {
        list(text = text)
      },
      voice = list(
        languageCode = "en-GB",
        name = if(exists("GOOGLE_TTS_VOICE") && !is.null(GOOGLE_TTS_VOICE)) GOOGLE_TTS_VOICE else "en-GB-Neural2-A",
        ssmlGender = "FEMALE"
      ),
      audioConfig = list(
        audioEncoding = "LINEAR16",
        speakingRate = if(exists("TTS_SPEED") && !is.null(TTS_SPEED)) TTS_SPEED else 1.0,
        pitch = if(exists("TTS_PITCH") && !is.null(TTS_PITCH)) TTS_PITCH else 0.0,
        volumeGainDb = if(exists("TTS_VOLUME") && !is.null(TTS_VOLUME)) TTS_VOLUME else 0.0,
        # sampleRateHertz = if(exists("TTS_SAMPLE_RATE") && !is.null(TTS_SAMPLE_RATE)) TTS_SAMPLE_RATE else NULL,
        effectsProfileId = if(exists("TTS_EFFECTS_PROFILES") && !is.null(TTS_EFFECTS_PROFILES)) TTS_EFFECTS_PROFILES else NULL
      )
    )
    
    # Debug: show what we're sending
    # cat("🔍 Request body:\n")
    # cat(toJSON(request_body, auto_unbox = TRUE, pretty = TRUE), "\n")
    
    # Make API request
    response <- POST(
      url = paste0("https://texttospeech.googleapis.com/v1/text:synthesize?key=", GOOGLE_TTS_API_KEY),
      body = toJSON(request_body, auto_unbox = TRUE),
      add_headers("Content-Type" = "application/json")
    )
    
    if (status_code(response) == 200) {
      # Extract audio content and decode from base64
      result <- fromJSON(content(response, "text"))
      audio_data <- base64enc::base64decode(result$audioContent)
      
      # Write to file
      writeBin(audio_data, output_path)
      cat("✅ Google TTS successful\n")
      
      return(TRUE)
    } else {
      cat("❌ Google TTS API error:", status_code(response), "\n")
      cat("❌ Error response:", content(response, "text"), "\n")
      return(FALSE)
    }
    
  }, error = function(e) {
    cat("❌ Google TTS error:", e$message, "\n")
    return(FALSE)
  })
}


# Amazon TTS using aws.polly
try_amazon_tts <- function(text, output_path) {
  tryCatch({
    if (!exists("AWS_ACCESS_KEY_ID") || !exists("AWS_SECRET_ACCESS_KEY")) {
      cat("❌ AWS credentials not configured\n")
      return(FALSE)
    }
    
    # Set environment variables
    Sys.setenv(AWS_ACCESS_KEY_ID = AWS_ACCESS_KEY_ID)
    Sys.setenv(AWS_SECRET_ACCESS_KEY = AWS_SECRET_ACCESS_KEY) 
    Sys.setenv(AWS_DEFAULT_REGION = AWS_DEFAULT_REGION)
    
    cat("\n🔍 Attempting Amazon Polly synthesis...\n")
    
    is_ssml <- grepl("<speak>|<prosody>|<break>", text)
    text_type <- if(is_ssml) "ssml" else "text"
    voice_param <- if(exists("AMAZON_TTS_VOICE") && !is.null(AMAZON_TTS_VOICE)) AMAZON_TTS_VOICE else "Amy"
    
    cat("🔍 Text content preview:", substr(text, 1, 100), "...\n")
    cat("🔍 SSML detected:", is_ssml, "\n")
    cat("🔍 Text type:", text_type, "\n")
    
    cat("🔍 Voice:", if(exists("AMAZON_TTS_VOICE") && !is.null(AMAZON_TTS_VOICE)) AMAZON_TTS_VOICE else "Amy", "\n")
    
    
    
    cat("🔍 Calling synthesize with:\n")
    cat("   text_type =", text_type, "\n")
    cat("   voice =", AMAZON_TTS_VOICE, "\n")
    cat("   output_format = pcm\n")
    
    # Synthesize speech
    result <- aws.polly::synthesize(
      text = text,
      voice = voice_param,
      output_format = "wav",  # Use PCM for better quality control
      text_type = text_type,  # This tells Polly it's SSML
      sample_rate = "22050"   # Specify sample rate for consistency
    )
    
    # Save to file
    if (class(result)[1] == "Wave") {
      tuneR::writeWave(result, filename = output_path)
      cat("✅ Amazon TTS successful\n")
      return(TRUE)
    } else {
      cat("❌ Unexpected Amazon TTS result format\n")
      return(FALSE)
    }
    
  }, error = function(e) {
    cat("❌ Amazon TTS error:", e$message, "\n")
    return(FALSE)
  })
}

# Microsoft TTS using text2speech package
try_microsoft_tts <- function(text, output_path) {
  tryCatch({
    if (!requireNamespace("text2speech", quietly = TRUE)) {
      cat("❌ text2speech package not installed\n")
      return(FALSE)
    }
    
    cat("\n🔍 Attempting Microsoft TTS synthesis...\n")
    
    # Use Microsoft TTS
    speech_result <- tts_microsoft(
      text = text,
      output_format = "wav",
      voice = "en-GB-LibbyNeural",  # British female voice
      save_local = TRUE,
      save_local_dest = output_path
    )
    
    if (file.exists(output_path)) {
      cat("✅ Microsoft TTS successful\n")
      return(TRUE)
    } else {
      cat("❌ Microsoft TTS failed - no output file\n")
      return(FALSE)
    }
    
  }, error = function(e) {
    cat("❌ Microsoft TTS error:", e$message, "\n")
    return(FALSE)
  })
}

# Local eSpeak fallback
try_espeak_tts <- function(text, output_path) {
  tryCatch({
    cat("\n🔍 Attempting eSpeak synthesis...\n")
    
    # Clean text for command line
    text_clean <- gsub('"', '\\"', text)
    text_clean <- gsub("'", "\\'", text_clean)
    
    # Create eSpeak command with British female voice
    espeak_command <- sprintf(
      'espeak -v en-gb+f3 -s 150 -w "%s" "%s"',
      output_path,
      text_clean
    )
    
    # Run command
    result <- system(espeak_command, intern = FALSE)
    
    if (result == 0 && file.exists(output_path)) {
      cat("✅ eSpeak TTS successful (British female voice)\n")
      return(TRUE)
    } else {
      cat("❌ eSpeak TTS failed\n")
      return(FALSE)
    }
    
  }, error = function(e) {
    cat("❌ eSpeak error:", e$message, "\n")
    cat("💡 Please install eSpeak: sudo apt-get install espeak (Linux) or brew install espeak (Mac)\n")
    return(FALSE)
  })
}

# =============================================================================
# FUNCTION: ENHANCE TEXT FOR MORE NATURAL SPEECH
#             (Improves pronunciation,
#             and removes problematic unicode/punctiation)
# =============================================================================

enhanced_text_for_speech <- function(text) {
  # Add natural pauses and emphasis for better TTS delivery
  enhanced_text <- text
  
  enhanced_text <- gsub("\n", "", enhanced_text, fixed = TRUE)
  enhanced_text <- gsub("300ms", "350ms", enhanced_text, fixed = TRUE)
  enhanced_text <- gsub("400ms", "600ms", enhanced_text, fixed = TRUE)
  
  # Clean up any accidental references to Radio 6
  enhanced_text <- gsub("BBC Radio 6", MAIN_STATION_NAME, enhanced_text, fixed = TRUE)
  enhanced_text <- gsub("Radio 6", MAIN_STATION_NAME, enhanced_text, fixed = TRUE)
  enhanced_text <- gsub("BBC 6", MAIN_STATION_NAME, enhanced_text, fixed = TRUE)

  # Specific improvements
  enhanced_text <- gsub("And now,", "And now", enhanced_text, fixed = TRUE)
  enhanced_text <- gsub("Next up,", "Next up", enhanced_text, fixed = TRUE)
  enhanced_text <- gsub("Alright,", "Alright", enhanced_text, fixed = TRUE)
  enhanced_text <- gsub("Now then,", "Now then", enhanced_text, fixed = TRUE)
  enhanced_text <- gsub(", listeners", " listeners ...", enhanced_text, fixed = TRUE)
  enhanced_text <- gsub(", dear listeners", " dear listeners ...", enhanced_text, fixed = TRUE)
  enhanced_text <- gsub(", dear listener", " dear listener ...", enhanced_text, fixed = TRUE)
  enhanced_text <- gsub(", folks", " folks ...", enhanced_text, fixed = TRUE)
  enhanced_text <- gsub(", darlings", " darlings ...", enhanced_text, fixed = TRUE)
  enhanced_text <- gsub(", lovely people", " lovely people ...", enhanced_text, fixed = TRUE)
  enhanced_text <- gsub(", good people", " good people ...", enhanced_text, fixed = TRUE)
  enhanced_text <- gsub(", everyone.", " everyone!", enhanced_text, fixed = TRUE)
  enhanced_text <- gsub(", observant listeners", " observant listeners ...", enhanced_text, fixed = TRUE)
  enhanced_text <- gsub(", observant listener", " observant listener ...", enhanced_text, fixed = TRUE)
  enhanced_text <- gsub(", friends", " friends ...", enhanced_text, fixed = TRUE)
  enhanced_text <- gsub(", my friends", " my friends ...", enhanced_text, fixed = TRUE)
  enhanced_text <- gsub(", comrades", " comrades ...", enhanced_text, fixed = TRUE)
  enhanced_text <- gsub(", mind", "", enhanced_text, fixed = TRUE)
  enhanced_text <- gsub(", shall we?", " shall we?", enhanced_text, fixed = TRUE)
  enhanced_text <- gsub(", come to think of it.", " come to think of it!", enhanced_text, fixed = TRUE)
  
  # Clean up regex errors
  enhanced_text <- gsub("\u2013", " ... ", enhanced_text, fixed = TRUE)  # En dash
  enhanced_text <- gsub("\u2014", " ... ", enhanced_text, fixed = TRUE)  # Em dash
  enhanced_text <- gsub("\u2018", "'", enhanced_text, fixed = TRUE)      # Left single quotation mark
  enhanced_text <- gsub("\u2019", "'", enhanced_text, fixed = TRUE)      # Right single quotation mark
  enhanced_text <- gsub("\u201C", '"', enhanced_text, fixed = TRUE)      # Left double quotation mark
  enhanced_text <- gsub("\u201D", '"', enhanced_text, fixed = TRUE)      # Right double quotation mark
  enhanced_text <- gsub("\u2026", " ... ", enhanced_text, fixed = TRUE)  # Horizontal ellipsis
  enhanced_text <- gsub("([A-Za-z]):([A-Za-z])", "\\1 - \\2", enhanced_text) # Get rid of colons
  enhanced_text <- gsub("\\s*&\\s*", " and ", enhanced_text) # Get rid of amplisands
  enhanced_text <- gsub(")", "", enhanced_text, fixed = TRUE)
  enhanced_text <- gsub(", eh?", "!", enhanced_text, fixed = TRUE)
  enhanced_text <- gsub(", but ", " but ", enhanced_text, fixed = TRUE)
  enhanced_text <- gsub(" but ", " ... but ", enhanced_text, fixed = TRUE)
  enhanced_text <- gsub(" bass ", " base ", enhanced_text, fixed = TRUE)
  enhanced_text <- gsub("Ah,", "Aaaah ... ", enhanced_text, fixed = TRUE)
  enhanced_text <- gsub("Ah ", "Aaaah ... ", enhanced_text, fixed = TRUE)
  enhanced_text <- gsub(", though, ", " though, ", enhanced_text, fixed = TRUE)
  enhanced_text <- gsub(", however, ", " however, ", enhanced_text, fixed = TRUE)
  
  enhanced_text <- gsub(" 'round ", " around ", enhanced_text, fixed = TRUE)
  enhanced_text <- gsub("Now, ", "Now ", enhanced_text, fixed = TRUE)
  enhanced_text <- gsub("Then, ", "Then ", enhanced_text, fixed = TRUE)
  enhanced_text <- gsub("And yes, ", "And yes ... ", enhanced_text, fixed = TRUE)
  enhanced_text <- gsub("Take that, ", "Take that ", enhanced_text, fixed = TRUE)
  enhanced_text <- gsub("The sort of ", "This is the sort of ", enhanced_text, fixed = TRUE)
  enhanced_text <- gsub("Had a ", "I had a ", enhanced_text, fixed = TRUE)
  enhanced_text <- gsub("Been thinking ", "I've been thinking ", enhanced_text, fixed = TRUE)
  enhanced_text <- gsub("Reached ", "It reached ", enhanced_text, fixed = TRUE)
  enhanced_text <- gsub("See what I did there? No? Moving on then.", "See what I did there? ... ... No? ... ... OK ... moving on then ... ", enhanced_text, fixed = TRUE)
  enhanced_text <- gsub(", I suppose", " ... ... I suppose", enhanced_text, fixed = TRUE)
  enhanced_text <- gsub(", isn't it?", " ... isn't it?", enhanced_text, fixed = TRUE)
  enhanced_text <- gsub(", won't you?", " ... won't you?", enhanced_text, fixed = TRUE)
  enhanced_text <- gsub(" who isn't ", " who isn't? ", enhanced_text, fixed = TRUE)
  enhanced_text <- gsub(", mind you", " mind you", enhanced_text, fixed = TRUE)
  enhanced_text <- gsub(", actually", " actually", enhanced_text, fixed = TRUE)
  enhanced_text <- gsub(", really", " really", enhanced_text, fixed = TRUE)
  enhanced_text <- gsub(" 648 ", " 6-4-8 ", enhanced_text, fixed = TRUE)
  enhanced_text <- gsub(" 9-to-5 ", " 9 to 5 ", enhanced_text, fixed = TRUE)
  enhanced_text <- gsub("AI DJ", "A.I.D.J", enhanced_text, fixed = TRUE)
  enhanced_text <- gsub("A.I. D.J.", "A.I.D.J", enhanced_text, fixed = TRUE)
  enhanced_text <- gsub(" AI", " A.I", enhanced_text, fixed = TRUE)
  enhanced_text <- gsub(">AI", "> A.I", enhanced_text, fixed = TRUE)
  enhanced_text <- gsub(" A.Is", " A.I's", enhanced_text, fixed = TRUE)
  enhanced_text <- gsub(" DJ", " D.J", enhanced_text, fixed = TRUE)
  enhanced_text <- gsub(" D.J.", " D.J ", enhanced_text, fixed = TRUE)
  enhanced_text <- gsub(" US ", " U.S ", enhanced_text, fixed = TRUE)
  enhanced_text <- gsub(" U.S. ", " U.S ", enhanced_text, fixed = TRUE)
  enhanced_text <- gsub(" USA ", " U.S.A ", enhanced_text, fixed = TRUE)
  enhanced_text <- gsub(" U.S.A. ", " U.S.A ", enhanced_text, fixed = TRUE)
  enhanced_text <- gsub(" UK ", " U.K ", enhanced_text, fixed = TRUE)
  enhanced_text <- gsub(" U.K. ", " U.K ", enhanced_text, fixed = TRUE)
  enhanced_text <- gsub(" LA ", " L.A ", enhanced_text, fixed = TRUE)
  enhanced_text <- gsub(" L.A. ", " L.A ", enhanced_text, fixed = TRUE)
  enhanced_text <- gsub("CPE", "C.P.E", enhanced_text, fixed = TRUE)
  enhanced_text <- gsub("DAB", "D.A.B", enhanced_text, fixed = TRUE)
  enhanced_text <- gsub("ELP", "E.L.P", enhanced_text, fixed = TRUE)
  enhanced_text <- gsub("ELO", "E.L.O", enhanced_text, fixed = TRUE)
  enhanced_text <- gsub("BJH", "B.J.H", enhanced_text, fixed = TRUE)
  enhanced_text <- gsub("OMD", "O.M.D", enhanced_text, fixed = TRUE)
  enhanced_text <- gsub("CSN", "C.S.N", enhanced_text, fixed = TRUE)
  enhanced_text <- gsub("GPS", "G.P.S", enhanced_text, fixed = TRUE)
  enhanced_text <- gsub("ZTT", "Z.T.T", enhanced_text, fixed = TRUE)
  enhanced_text <- gsub("EDM", "E.D.M", enhanced_text, fixed = TRUE)
  enhanced_text <- gsub("CGI", "C.G.I", enhanced_text, fixed = TRUE)
  enhanced_text <- gsub(" ZZ Top ", " Zee Zee Top ", enhanced_text, fixed = TRUE)
  enhanced_text <- gsub("Chuck Es", "Chuck E's", enhanced_text, fixed = TRUE)
  enhanced_text <- gsub(" Im ", " I'm ", enhanced_text, fixed = TRUE)
  enhanced_text <- gsub(" theyre ", " they're ", enhanced_text, fixed = TRUE)
  enhanced_text <- gsub(" Theyre ", " They're ", enhanced_text, fixed = TRUE)
  enhanced_text <- gsub(" youre ", " you're ", enhanced_text, fixed = TRUE)
  enhanced_text <- gsub(" Youre ", " You're ", enhanced_text, fixed = TRUE)
  enhanced_text <- gsub(" youve ", " you've ", enhanced_text, fixed = TRUE)
  enhanced_text <- gsub(" Youve ", " You've ", enhanced_text, fixed = TRUE)
  enhanced_text <- gsub(" hes ", " he's ", enhanced_text, fixed = TRUE)
  enhanced_text <- gsub(" Hes ", " He's ", enhanced_text, fixed = TRUE)
  enhanced_text <- gsub(" shes ", " she's ", enhanced_text, fixed = TRUE)
  enhanced_text <- gsub(" Shes ", " She's ", enhanced_text, fixed = TRUE)
  enhanced_text <- gsub(" hasnt ", " hasn't ", enhanced_text, fixed = TRUE)
  enhanced_text <- gsub(" isnt ", " isn't ", enhanced_text, fixed = TRUE)
  enhanced_text <- gsub(" wasnt ", " wasn't ", enhanced_text, fixed = TRUE)
  enhanced_text <- gsub(" 'N' ", " n' ", enhanced_text, fixed = TRUE)
  enhanced_text <- gsub(" 'n' ", " n' ", enhanced_text, fixed = TRUE)
  enhanced_text <- gsub("\\bDa\\b", "Dah", enhanced_text)
  enhanced_text <- gsub("\\bda\\b", "dah", enhanced_text)
  enhanced_text <- gsub(" Da<", " Dah<", enhanced_text, fixed = TRUE)
  enhanced_text <- gsub(" da<", " dah<", enhanced_text, fixed = TRUE)
  enhanced_text <- gsub(" Da, ", " Dah, ", enhanced_text, fixed = TRUE)
  enhanced_text <- gsub(" da, ", " dah, ", enhanced_text, fixed = TRUE)
  enhanced_text <- gsub(" Da. ", " Dah. ", enhanced_text, fixed = TRUE)
  enhanced_text <- gsub(" da. ", " dah. ", enhanced_text, fixed = TRUE)
  enhanced_text <- gsub(" Da' ", " Dah' ", enhanced_text, fixed = TRUE)
  enhanced_text <- gsub(" da' ", " dah' ", enhanced_text, fixed = TRUE)
  enhanced_text <- gsub(" Da\" ", " Dah\" ", enhanced_text, fixed = TRUE)
  enhanced_text <- gsub(" da\" ", " dah\" ", enhanced_text, fixed = TRUE)
  enhanced_text <- gsub(" Irn-Bru ", " Iron Brew ", enhanced_text, fixed = TRUE)
  enhanced_text <- gsub(" Je ne sais quoi", " <lang xml:lang=\"fr-FR\">Je ne sais quoi</lang>", enhanced_text, fixed = TRUE)
  enhanced_text <- gsub(" je ne sais quoi", " <lang xml:lang=\"fr-FR\">Je ne sais quoi</lang>", enhanced_text, fixed = TRUE)
  
  cat(enhanced_text)
  return(enhanced_text)
}

measure_wav_duration <- function(audio_file_path) {
  if (is.null(audio_file_path) || !file.exists(audio_file_path)) {
    return(10)  # Fallback duration
  }
  
  tryCatch({
    # Option 1: Estimate from file size (rough approximation)
    file_info <- file.info(audio_file_path)
    file_size_kb <- file_info$size / 1024
    
    # Rough estimate: 1 second ≈ 16-32 KB for typical TTS audio
    estimated_duration <- file_size_kb / 48
    #return(round(estimated_duration, 1)
    
    # Option 2: Get duration from av
    file_technical <- av::av_media_info(audio_file_path)
    return(round(as.numeric(file_technical$duration), 1))
    
  }, error = function(e) {
    cat("   ⚠️ Could not determine audio duration:", e$message, "\n")
    return(30)  # Conservative fallback
  })
}

# =============================================================================
# AI SERVICES
# =============================================================================

intro_from_claude <- function(prompt) {
  
  tryCatch({
    res <- httr::POST(
      url = "https://api.anthropic.com/v1/messages",
      httr::add_headers(
        "x-api-key" = CLAUDE_ANTHROPIC_API_KEY,
        "Content-Type" = "application/json",
        "anthropic-version" = "2023-06-01"
      ),
      body = jsonlite::toJSON(list(
        model = "claude-sonnet-4-20250514",
        max_tokens = 1500,
        messages = list(
          list(role = "user", content = prompt)
        )
      ), auto_unbox = TRUE),
      timeout(45)
    )
    
    # Check HTTP status code
    if (res$status_code != 200) {
      cat("❌ Claude API HTTP error:", res$status_code, "\n")
      return(NULL)
    }
    
    res_json <- jsonlite::fromJSON(httr::content(res, as = "text", encoding = "UTF-8"))
    
    if (!is.null(res_json$error)) {
      cat("❌ Claude API error:", res_json$error$message, "\n")
      return(NULL)
    }
    
    intro_block <- res_json$content$text
    
    # Validate we got something back
    if (is.null(intro_block) || nchar(trimws(intro_block)) == 0) {
      cat("❌ Claude returned empty response\n")
      return(NULL)
    }
    
    return(intro_block)
    
  }, error = function(e) {
    return(NULL)
    
  })
}


intro_from_chatgpt <- function(prompt) {
  
  tryCatch({
    res <- httr::POST(
      url = "https://api.openai.com/v1/chat/completions",
      httr::add_headers(Authorization = paste("Bearer", CHATGPT_API_KEY), `Content-Type` = "application/json"),
      body = jsonlite::toJSON(list(
        model = "gpt-4",
        messages = list(
          list(role = "system", content = "you are a witty, slightly world-weary, female DJ on ", MAIN_STATION_NAME, " with a dry, clever, slightly sardonic, and self-aware sense of humour in the style of a BBC Radio 6 presenter"),
          list(role = "user", content = prompt)
        ),
        temperature = 0.8,
        max_tokens = 1500),
        auto_unbox = TRUE),
      timeout(45)
    )
    
    # Check HTTP status code
    if (res$status_code != 200) {
      cat("❌ chatGPT API HTTP error:", res$status_code, "\n")
      return(NULL)
    }
    
    res_json <- jsonlite::fromJSON(httr::content(res, as = "text", encoding = "UTF-8"))
    
    if (!is.null(res_json$error)) {
      cat("❌ chatGPT API error:", res_json$error$message, "\n")
      return(NULL)
    }
    
    intro_block <- res_json$choices$message$content[1]
    
    # Validate we got something back
    if (is.null(intro_block) || nchar(trimws(intro_block)) == 0) {
      cat("❌ chatGPT returned empty response\n")
      return(NULL)
    }
    
    return(intro_block)
    
  }, error = function(e) {
    return(NULL)
    
  })
}

# =============================================================================
# BATCH INTRO GENERATION UTILITY
# =============================================================================

generate_batch_intros <- function(track_list, style = "dry_witty_radio6", overwrite_existing = FALSE) {
  cat("🎙️ BATCH INTRO GENERATION...\n")
  cat(sprintf("📊 Processing %d tracks\n", nrow(track_list)))
  
  if (is.null(track_list) || nrow(track_list) == 0) {
    cat("❌ No tracks provided\n")
    return(NULL)
  }
  
  results <- list(
    total_tracks = nrow(track_list),
    generated = 0,
    skipped = 0,
    failed = 0,
    errors = c()
  )
  
  for (i in 1:nrow(track_list)) {
    track <- track_list[i, ]
    cat(sprintf("\n🎵 Track %d/%d: %s - %s\n", i, nrow(track_list), track$main_artist, track$main_song))
    
    # Check if intro already exists (unless overwriting)
    if (!overwrite_existing) {
      has_intro <- check_intro_availability(track$main_artist, track$main_song, style)
      if (has_intro) {
        cat("   ⏭️ Intro already exists, skipping\n")
        results$skipped <- results$skipped + 1
        next
      }
    }
    
    # Generate new intro
    tryCatch({
      success <- generate_artist_intro(track$main_artist, track$main_song, 1, 3, style = style)
      
      if (success) {
        results$generated <- results$generated + 1
        cat("   ✅ Generated successfully\n")
        
        # Add small delay to be nice to AI APIs
        Sys.sleep(2)
      } else {
        results$failed <- results$failed + 1
        cat("   ❌ Generation failed\n")
      }
      
    }, error = function(e) {
      results$failed <- results$failed + 1
      results$errors <- c(results$errors, sprintf("Track %d: %s", i, e$message))
      cat("   ❌ Error:", e$message, "\n")
    })
  }
  
  cat("\n📊 BATCH GENERATION SUMMARY:\n")
  cat(sprintf("   ✅ Generated: %d\n", results$generated))
  cat(sprintf("   ⏭️ Skipped: %d\n", results$skipped))
  cat(sprintf("   ❌ Failed: %d\n", results$failed))
  
  if (length(results$errors) > 0) {
    cat("\n❌ ERRORS:\n")
    for (error in results$errors) {
      cat(sprintf("   %s\n", error))
    }
  }
  
  return(results)
}

# =============================================================================
# ADD DURATIONS TO TRACKS
# =============================================================================

add_durations_to_tracks <- function(track_list, intro_details = NULL) {
  cat("🎵 Getting track durations and metadata...\n")
  
  if (is.null(track_list) || nrow(track_list) == 0) {
    cat("❌ No tracks provided\n")
    return(track_list)
  }
  
  # Initialize all duration and metadata columns
  track_list$track_duration <- NA
  track_list$track_file_path <- NA
  track_list$track_file_name <- NA
  track_list$selected_version <- NA
  track_list$track_duration_mins <- NA
  track_list$estimated_intro_duration <- NA
  track_list$total_estimated_duration <- NA
  track_list$effective_duration_with_fades <- NA
  track_list$track_duration_nett <- NA
  
  # Add intro file columns if intro details provided
  if (!is.null(intro_details)) {
    track_list$intro_filenames <- NA
    track_list$intro_full_path <- NA
    track_list$actual_intro_duration <- NA
  }
  
  # Playout system specific columns (for external systems only)
  if (exists("PLAYOUT_SYSTEM") && PLAYOUT_SYSTEM != "LOCAL") {
    track_list$playout_fade_in <- NA
    track_list$playout_fade_out <- NA
    track_list$playout_intro_start <- NA
    track_list$playout_segue_start <- NA
    track_list$playout_source <- NA
    track_list$track_duration_nett_playout <- NA
    track_list$effective_duration_with_playout_cues <- NA
  }
  
  found_count <- 0
  playout_count <- 0
  
  # =============================================================================
  # DETERMINE DATA SOURCE AND PROCESS TRACKS
  # =============================================================================
  
  if (exists("PLAYOUT_SYSTEM") && PLAYOUT_SYSTEM == "LOCAL") {
    cat("🎵 Using local database for track data...\n")
    result <- process_tracks_local_database(track_list, intro_details)
    track_list <- result$track_list
    found_count <- result$found_count
    
  } else if (exists("PLAYOUT_SYSTEM") && PLAYOUT_SYSTEM != "LOCAL") {
    cat(sprintf("🎵 Using %s playout system for track data...\n", PLAYOUT_SYSTEM))
    
    tryCatch({
      result <- process_tracks_with_playout(track_list, intro_details)
      track_list <- result$track_list
      found_count <- result$found_count
      playout_count <- result$playout_count
      
    }, error = function(e) {
      cat(sprintf("❌ Playout system error: %s\n", e$message))
      cat("   Falling back to local database...\n")
      
      # Fallback to local database
      result <- process_tracks_local_database(track_list, intro_details)
      track_list <- result$track_list
      found_count <- result$found_count
    })
    
  } else {
    # Default to local if PLAYOUT_SYSTEM not configured
    cat("🎵 PLAYOUT_SYSTEM not configured, using local database...\n")
    result <- process_tracks_local_database(track_list, intro_details)
    track_list <- result$track_list
    found_count <- result$found_count
  }
  
  # =============================================================================
  # CALCULATE ALL DERIVED TIMING FIELDS
  # =============================================================================
  
  track_list <- calculate_all_timing_fields(track_list)
  
  # =============================================================================
  # ADD INTRO FILE INFORMATION IF PROVIDED
  # =============================================================================
  
  if (!is.null(intro_details) && length(intro_details$intro_details) > 0) {
    cat("🎙️ Adding intro file information...\n")
    
    for (i in 1:min(nrow(track_list), length(intro_details$intro_details))) {
      intro <- intro_details$intro_details[[i]]
      if (!is.null(intro)) {
        track_list$intro_filenames[i] <- intro$wav_filename
        track_list$intro_full_path[i] <- intro$wav_filepath
        track_list$actual_intro_duration[i] <- intro$actual_duration
        
        # Update estimated intro duration with actual value
        track_list$estimated_intro_duration[i] <- intro$actual_duration
      }
    }
    
    # Recalculate timing fields with actual intro durations
    track_list <- calculate_all_timing_fields(track_list)
  }
  
  # =============================================================================
  # SUMMARY REPORTING
  # =============================================================================
  
  cat(sprintf("✅ Duration lookup complete: %d/%d tracks found\n", found_count, nrow(track_list)))
  
  if (exists("PLAYOUT_SYSTEM") && PLAYOUT_SYSTEM != "LOCAL") {
    cat(sprintf("🎵 Playout system data: %d/%d tracks with cue points\n", playout_count, found_count))
  }
  
  if (found_count > 0) {
    valid_durations <- track_list$track_duration[!is.na(track_list$track_duration)]
    if (length(valid_durations) > 0) {
      duration_range <- range(valid_durations)
      cat(sprintf("📊 Duration range: %.0f - %.0f seconds (%.1f - %.1f minutes)\n", 
                  duration_range[1], duration_range[2], 
                  duration_range[1]/60, duration_range[2]/60))
    }
    
    if (!is.null(intro_details)) {
      valid_intros <- track_list$actual_intro_duration[!is.na(track_list$actual_intro_duration)]
      if (length(valid_intros) > 0) {
        intro_range <- range(valid_intros)
        cat(sprintf("🎙️ Intro range: %.1f - %.1f seconds\n", intro_range[1], intro_range[2]))
      }
    }
  }
  
  return(track_list)
}

# =============================================================================
# PROCESS TRACKS WITH LOCAL DATABASE
# =============================================================================

process_tracks_local_database <- function(track_list, intro_details) {
  found_count <- 0
  
  tryCatch({
    con <- create_sql_connection(connection_name = "track_durations")
    
    for (i in 1:nrow(track_list)) {
      tryCatch({
        # Normalize for fuzzy search
        artist_query <- normalize_for_sql_search(track_list$main_artist[i], "%")
        song_query <- normalize_for_sql_search(track_list$main_song[i], "%")
        
        # Find matching versions using LIKE for fuzzy matching (no LIMIT 1)
        query <- paste0("SELECT artist, song, duration_seconds, file_path, file_format ",
                        "FROM available_tracks ",
                        "WHERE artist LIKE '%", artist_query, "%' ",
                        "AND song LIKE '%", song_query, "%' ",
                        "AND song NOT LIKE '%intro%' ",
                        "AND song NOT LIKE '%prelude%' ",
                        "AND song NOT LIKE '%outro%' ",
                        "AND song NOT LIKE '%interlude%' ",
                        "ORDER BY artist, song")
        
        matches <- dbGetQuery(con, query)
        
        if (nrow(matches) > 0) {
          # Pass all matches to selection function
          selected_track <- select_best_track_version(matches, track_list$main_artist[i], track_list$main_song[i])
          
          if (!is.null(selected_track)) {
            track_list$track_duration[i] <- selected_track$duration_seconds[1]
            track_list$track_file_path[i] <- selected_track$file_path[1]
            track_list$track_file_name[i] <- basename(selected_track$file_path[1])
            track_list$selected_version[i] <- paste(selected_track$artist[1], " - ", selected_track$song[1])
            found_count <- found_count + 1
          }
        } else {
          cat(sprintf("   ❌ No match found for: %s - %s\n", 
                      track_list$main_artist[i], track_list$main_song[i]))
        }
        
      }, error = function(e) {
        cat(sprintf("   ❌ Error processing track %d (%s - %s): %s\n", 
                    i, track_list$main_artist[i], track_list$main_song[i], e$message))
      })
    }
    
    dbDisconnect(con)
    
  }, error = function(e) {
    cat("❌ Error accessing duration database:", e$message, "\n")
    if (exists("con") && dbIsValid(con)) dbDisconnect(con)
  })
  
  return(list(track_list = track_list, found_count = found_count))
}

# =============================================================================
# PROCESS TRACKS WITH PLAYOUT SYSTEM
# =============================================================================

process_tracks_with_playout <- function(track_list, intro_details) {
  found_count <- 0
  playout_count <- 0
  
  playout_con <- create_playout_connection()
  
  for (i in 1:nrow(track_list)) {
    tryCatch({
      artist <- track_list$main_artist[i]
      song <- track_list$main_song[i]
      
      # Normalize for fuzzy search
      artist_query <- normalize_for_sql_search(artist, "%")
      song_query <- normalize_for_sql_search(song, "%")
      
      # Query playout system based on type
      track_data <- switch(PLAYOUT_SYSTEM,
                           "ZETTA" = query_zetta_track_data(playout_con, artist_query, song_query),
                           "WIDEORBIT" = query_wideorbit_track_data(playout_con, artist_query, song_query),
                           "ENCO_DAD" = query_enco_track_data(playout_con, artist_query, song_query),
                           "RADIOMAN" = query_radioman_track_data(playout_con, artist_query, song_query),
                           NULL
      )
      
      if (!is.null(track_data)) {
        # Set basic track data
        track_list$track_duration[i] <- track_data$duration
        track_list$track_file_path[i] <- track_data$file_path
        track_list$track_file_name[i] <- track_data$file_name
        track_list$selected_version[i] <- paste(track_data$artist, " - ", track_data$title)
        
        # Set playout cue points
        track_list$playout_fade_in[i] <- track_data$fade_in
        track_list$playout_fade_out[i] <- track_data$fade_out
        track_list$playout_intro_start[i] <- track_data$intro_start
        track_list$playout_segue_start[i] <- track_data$segue_start
        track_list$playout_source[i] <- PLAYOUT_SYSTEM
        
        found_count <- found_count + 1
        playout_count <- playout_count + 1
        
      } else {
        # Fallback to defaults
        track_list$playout_fade_in[i] <- CROSS_FADE_IN
        track_list$playout_fade_out[i] <- CROSS_FADE_OUT
        track_list$playout_intro_start[i] <- 0
        track_list$playout_segue_start[i] <- NA
        track_list$playout_source[i] <- "default"
        
        cat(sprintf("   ⚠️ No playout data for: %s - %s\n", artist, song))
      }
      
    }, error = function(e) {
      cat(sprintf("   ❌ Error processing track %d (%s - %s): %s\n", 
                  i, track_list$main_artist[i], track_list$main_song[i], e$message))
    })
  }
  
  dbDisconnect(playout_con)
  
  return(list(track_list = track_list, found_count = found_count, playout_count = playout_count))
}

# =============================================================================
# CALCULATE ALL TIMING FIELDS
# =============================================================================

calculate_all_timing_fields <- function(track_list) {
  
  # Set defaults if config variables don't exist
  cross_fade_in <- if(exists("CROSS_FADE_IN")) CROSS_FADE_IN else 3
  cross_fade_out <- if(exists("CROSS_FADE_OUT")) CROSS_FADE_OUT else 3
  estimated_intro <- if(exists("ESTIMATED_DURATION_OF_INTROS")) ESTIMATED_DURATION_OF_INTROS else 30
  
  track_list <- track_list %>%
    mutate(
      # Basic calculations
      track_duration_mins = round(track_duration / 60, 1),
      estimated_intro_duration = ifelse(is.na(estimated_intro_duration), estimated_intro, estimated_intro_duration),
      total_estimated_duration = track_duration + estimated_intro_duration,
      
      # Standard cross-fade calculations
      track_duration_nett = track_duration - cross_fade_in - cross_fade_out,
      effective_duration_with_fades = total_estimated_duration - cross_fade_in - cross_fade_out
    )
  
  # Add playout system calculations if available
  if (exists("PLAYOUT_SYSTEM") && PLAYOUT_SYSTEM != "LOCAL" && "playout_fade_in" %in% names(track_list)) {
    track_list <- track_list %>%
      mutate(
        track_duration_nett_playout = track_duration - playout_fade_in - playout_fade_out,
        effective_duration_with_playout_cues = track_duration_nett_playout + estimated_intro_duration
      )
  }
  
  return(track_list)
}

# =============================================================================
# PLAYOUT SYSTEM SPECIFIC TRACK QUERIES (UPDATED WITH NORMALIZATION)
# =============================================================================

query_zetta_track_data <- function(con, artist_query, song_query) {
  query <- "
    SELECT 
      s.Title,
      s.Artist,
      s.Duration / 1000.0 as duration,
      af.FileName as file_name,
      af.FilePath as file_path,
      cp.IntroStart / 1000.0 as intro_start,
      cp.VocalStart / 1000.0 as vocal_start,
      cp.SegueStart / 1000.0 as segue_start,
      cp.FadeOut / 1000.0 as fade_out,
      cp.EndCue / 1000.0 as end_cue
    FROM Songs s
    JOIN AudioFiles af ON s.SongID = af.SongID
    LEFT JOIN CuePoints cp ON s.SongID = cp.SongID
    WHERE s.Artist LIKE ? AND s.Title LIKE ?
      AND s.Title NOT LIKE '%intro to%' 
      AND s.Title NOT LIKE '%prelude%' 
      AND s.Title NOT LIKE '%outro%' 
      AND s.Title NOT LIKE '%interlude%'
    ORDER BY s.LastModified DESC
    LIMIT 1
  "
  
  result <- dbGetQuery(con, query, list(paste0("%", artist_query, "%"), paste0("%", song_query, "%")))
  
  if (nrow(result) > 0) {
    row <- result[1, ]
    return(list(
      artist = row$Artist,
      title = row$Title,
      duration = row$duration,
      file_path = row$file_path,
      file_name = row$file_name,
      fade_in = if(is.na(row$intro_start)) CROSS_FADE_IN else max(0, row$intro_start),
      fade_out = if(is.na(row$fade_out)) CROSS_FADE_OUT else max(0, row$fade_out),
      intro_start = row$intro_start,
      segue_start = row$segue_start
    ))
  }
  
  return(NULL)
}

query_wideorbit_track_data <- function(con, artist_query, song_query) {
  query <- "
    SELECT 
      Title,
      Artist,
      Duration / 1000.0 as duration,
      FileName as file_name,
      FilePath as file_path,
      Intro / 1000.0 as intro_start,
      Segue / 1000.0 as segue_start,
      Outro / 1000.0 as outro_start,
      [End] / 1000.0 as end_cue
    FROM MusicLibrary
    WHERE Artist LIKE ? AND Title LIKE ?
      AND Title NOT LIKE '%intro to%' 
      AND Title NOT LIKE '%prelude%' 
      AND Title NOT LIKE '%outro%' 
      AND Title NOT LIKE '%interlude%'
    ORDER BY DateModified DESC
    LIMIT 1
  "
  
  result <- dbGetQuery(con, query, list(paste0("%", artist_query, "%"), paste0("%", song_query, "%")))
  
  if (nrow(result) > 0) {
    row <- result[1, ]
    return(list(
      artist = row$Artist,
      title = row$Title,
      duration = row$duration,
      file_path = row$file_path,
      file_name = row$file_name,
      fade_in = if(is.na(row$intro_start)) CROSS_FADE_IN else row$intro_start,
      fade_out = if(is.na(row$outro_start)) CROSS_FADE_OUT else row$outro_start,
      intro_start = row$intro_start,
      segue_start = row$segue_start
    ))
  }
  
  return(NULL)
}

query_enco_track_data <- function(con, artist_query, song_query) {
  query <- "
    SELECT 
      Title,
      Artist,
      Duration,
      FileName as file_name,
      FilePath as file_path,
      StartCue as start_cue,
      IntroCue as intro_start,
      SegueCue as segue_start,
      OutCue as fade_out,
      EndCue as end_cue
    FROM AudioLibrary
    WHERE Artist LIKE ? AND Title LIKE ?
      AND Title NOT LIKE '%intro to%' 
      AND Title NOT LIKE '%prelude%' 
      AND Title NOT LIKE '%outro%' 
      AND Title NOT LIKE '%interlude%'
    ORDER BY LastUpdate DESC
    LIMIT 1
  "
  
  result <- dbGetQuery(con, query, list(paste0("%", artist_query, "%"), paste0("%", song_query, "%")))
  
  if (nrow(result) > 0) {
    row <- result[1, ]
    return(list(
      artist = row$Artist,
      title = row$Title,
      duration = row$Duration,
      file_path = row$file_path,
      file_name = row$file_name,
      fade_in = if(is.na(row$start_cue)) CROSS_FADE_IN else row$start_cue,
      fade_out = if(is.na(row$fade_out)) CROSS_FADE_OUT else row$fade_out,
      intro_start = row$intro_start,
      segue_start = row$segue_start
    ))
  }
  
  return(NULL)
}

query_radioman_track_data <- function(con, artist_query, song_query) {
  query <- "
    SELECT 
      Title,
      Artist,
      Duration,
      Filename as file_name,
      FilePath as file_path,
      FadeIn as fade_in,
      FadeOut as fade_out,
      IntroTime as intro_start,
      SegueTime as segue_start
    FROM Tracks
    WHERE Artist LIKE ? AND Title LIKE ?
      AND Title NOT LIKE '%intro to%' 
      AND Title NOT LIKE '%prelude%' 
      AND Title NOT LIKE '%outro%' 
      AND Title NOT LIKE '%interlude%'
    ORDER BY Modified DESC
    LIMIT 1
  "
  
  result <- dbGetQuery(con, query, list(paste0("%", artist_query, "%"), paste0("%", song_query, "%")))
  
  if (nrow(result) > 0) {
    row <- result[1, ]
    return(list(
      artist = row$Artist,
      title = row$Title,
      duration = row$Duration,
      file_path = row$file_path,
      file_name = row$file_name,
      fade_in = if(is.na(row$fade_in)) CROSS_FADE_IN else row$fade_in,
      fade_out = if(is.na(row$fade_out)) CROSS_FADE_OUT else row$fade_out,
      intro_start = row$intro_start,
      segue_start = row$segue_start
    ))
  }
  
  return(NULL)
}

# =============================================================================
# PLAYOUT CONNECTION HELPER
# =============================================================================

create_playout_connection <- function() {
  if (!exists("PLAYOUT_DB_HOST") || PLAYOUT_DB_HOST == "") {
    stop("Playout database connection not configured")
  }
  
  # Create connection based on database type
  if (PLAYOUT_SYSTEM %in% c("ZETTA", "WIDEORBIT")) {
    # SQL Server connection
    con <- DBI::dbConnect(
      odbc::odbc(),
      driver = "ODBC Driver 17 for SQL Server",
      server = paste0(PLAYOUT_DB_HOST, ",", PLAYOUT_DB_PORT),
      database = PLAYOUT_DB_NAME,
      uid = PLAYOUT_SYSTEM_SQL_USER,
      pwd = PLAYOUT_SYSTEM_SQL_PASSWORD
    )
  } else {
    # Generic connection for Enco/RadioMan
    con <- DBI::dbConnect(
      RMariaDB::MariaDB(),
      host = PLAYOUT_DB_HOST,
      port = PLAYOUT_DB_PORT,
      user = PLAYOUT_SYSTEM_SQL_USER,
      password = PLAYOUT_SYSTEM_SQL_PASSWORD,
      dbname = PLAYOUT_DB_NAME
    )
  }
  
  return(con)
}

# =============================================================================
# TRACK VERSION SELECTION FUNCTION (PLACEHOLDER)
# =============================================================================

select_best_track_version <- function(matches, original_artist, original_song) {
  if (nrow(matches) == 0) return(NULL)
  
  # For now, just return first match (maintains current behavior)
  # Future: Add logic for studio vs live, 7" vs 12", duration preferences, etc.
  return(matches[1, ])
}

#########################################################
# DELETE THIS NONSENSE!!!!!
#########################################################

add_durations_to_tracksDEMO <- function(track_list) {
  cat("⏰ Adding duration data to track list...\n")
  
  durations <- get_batch_track_durations(track_list)
  
  if (!is.null(durations) && length(durations) == nrow(track_list)) {
    track_list$track_duration <- durations
    
    # Add some helpful derived columns
    track_list <- track_list %>%
      mutate(
        track_duration_mins = round(track_duration / 60, 1),
        estimated_intro_duration = ESTIMATED_DURATION_OF_INTROS,  # Conservative estimate
        total_estimated_duration = track_duration + estimated_intro_duration,
        effective_duration_with_fades = total_estimated_duration - CROSS_FADE_IN - CROSS_FADE_OUT,
        track_file_path = "/home/rachael/Music/xxxx-yyyy",
        track_file_name = "test.flac"
      )
    
    
    cat("✅ Duration data added successfully\n")
    cat("📊 Duration range:", min(track_list$track_duration), "-", max(track_list$track_duration), "seconds\n")
    
    return(track_list)
  } else {
    cat("❌ Failed to get duration data\n")
    return(track_list)
  }
}

get_batch_track_durations <- function(track_list) {
  cat("🎵 Getting batch track durations via API...\n")
  
  if (is.null(track_list) || nrow(track_list) == 0) {
    cat("❌ No tracks provided\n")
    return(NULL)
  }
  
  # Format the track list for the prompt
  track_requests <- paste(
    paste0(1:nrow(track_list), ". ", track_list$main_artist, " - ", track_list$main_song),
    collapse = "\n"
  )
  
  prompt <- paste0(
    "Please provide the duration in seconds for each of these tracks. ",
    "Respond with ONLY the numbers, one per line, in the same order. ",
    "Use 'NA' if you don't know a track's duration. ",
    "No other text, no explanations, just integers or NA:\n\n",
    track_requests
  )
  
  cat("📊 Requesting durations for", nrow(track_list), "tracks\n")
  
  # =============================================================================
  # CHECK WHICH API KEYS ARE AVAILABLE
  # =============================================================================
  
  claude_available <- exists("CLAUDE_ANTHROPIC_API_KEY") && !is.null(CLAUDE_ANTHROPIC_API_KEY) && CLAUDE_ANTHROPIC_API_KEY != ""
  chatgpt_available <- exists("CHATGPT_API_KEY") && !is.null(CHATGPT_API_KEY) && CHATGPT_API_KEY != ""
  
  cat("🔑 API Key Status:\n")
  cat("   Claude:", ifelse(claude_available, "✅ Available", "❌ Not set"), "\n")
  cat("   ChatGPT:", ifelse(chatgpt_available, "✅ Available", "❌ Not set"), "\n")
  
  if (!claude_available && !chatgpt_available) {
    cat("⚠️ No API keys available - using duration estimates\n")
    return(get_duration_estimates(track_list))
  }
  
  # =============================================================================
  # TRY CLAUDE FIRST (IF AVAILABLE)
  # =============================================================================
  
  if (claude_available) {
    tryCatch({
      cat("🤖 Trying Claude API...\n")
      
      res <- httr::POST(
        url = "https://api.anthropic.com/v1/messages",
        httr::add_headers(
          "x-api-key" = CLAUDE_ANTHROPIC_API_KEY,
          "Content-Type" = "application/json",
          "anthropic-version" = "2023-06-01"
        ),
        body = jsonlite::toJSON(list(
          model = "claude-3-5-sonnet-20241022",
          max_tokens = 500,
          messages = list(
            list(role = "user", content = prompt)
          )
        ), auto_unbox = TRUE),
        timeout(30)
      )
      
      if (res$status_code == 200) {
        raw_content <- httr::content(res, as = "text", encoding = "UTF-8")
        res_json <- jsonlite::fromJSON(raw_content, simplifyVector = FALSE)
        
        if (!is.null(res_json$content) && length(res_json$content) > 0) {
          response_text <- res_json$content[[1]]$text
          
          # Parse response into vector of durations
          duration_lines <- strsplit(trimws(response_text), "\n")[[1]]
          duration_lines <- trimws(duration_lines)
          duration_lines <- duration_lines[duration_lines != ""]
          
          durations <- suppressWarnings(as.numeric(duration_lines))
          
          if (length(durations) == nrow(track_list)) {
            cat("✅ Claude success:", length(durations), "durations received\n")
            return(durations)
          } else {
            cat("⚠️ Claude duration count mismatch. Expected:", nrow(track_list), "Got:", length(durations), "\n")
            stop("Count mismatch")
          }
        } else {
          stop("No content in Claude response")
        }
      } else {
        stop(paste("Claude API error:", res$status_code))
      }
      
    }, error = function(e) {
      cat("❌ Claude failed:", e$message, "\n")
    })
  } else {
    cat("⏭️ Skipping Claude (API key not available)\n")
  }
  
  # =============================================================================
  # TRY CHATGPT (IF AVAILABLE AND CLAUDE FAILED)
  # =============================================================================
  
  if (chatgpt_available) {
    tryCatch({
      cat("🔄 Trying ChatGPT", ifelse(claude_available, "fallback", ""), "...\n")
      
      res <- httr::POST(
        url = "https://api.openai.com/v1/chat/completions",
        httr::add_headers(Authorization = paste("Bearer", CHATGPT_API_KEY), `Content-Type` = "application/json"),
        body = jsonlite::toJSON(list(
          model = "gpt-4",
          messages = list(
            list(role = "system", content = "You provide track durations in seconds. Respond with only numbers, one per line."),
            list(role = "user", content = prompt)
          ),
          temperature = 0,
          max_tokens = 300
        ), auto_unbox = TRUE),
        timeout(30)
      )
      
      if (res$status_code == 200) {
        raw_content <- httr::content(res, as = "text", encoding = "UTF-8")
        res_json <- jsonlite::fromJSON(raw_content, simplifyVector = FALSE)
        
        if (!is.null(res_json$choices) && length(res_json$choices) > 0) {
          response_text <- res_json$choices[[1]]$message$content
          
          # Parse response
          duration_lines <- strsplit(trimws(response_text), "\n")[[1]]
          duration_lines <- trimws(duration_lines)
          duration_lines <- duration_lines[duration_lines != ""]
          
          durations <- suppressWarnings(as.numeric(duration_lines))
          
          if (length(durations) == nrow(track_list)) {
            cat("✅ ChatGPT success:", length(durations), "durations received\n")
            return(durations)
          } else {
            cat("⚠️ ChatGPT duration count mismatch. Expected:", nrow(track_list), "Got:", length(durations), "\n")
            stop("Count mismatch")
          }
        } else {
          stop("No choices in ChatGPT response")
        }
      } else {
        stop(paste("ChatGPT API error:", res$status_code))
      }
      
    }, error = function(e2) {
      cat("❌ ChatGPT also failed:", e2$message, "\n")
    })
  } else {
    cat("⏭️ Skipping ChatGPT (API key not available)\n")
  }
  
  # =============================================================================
  # ULTIMATE FALLBACK - ESTIMATES
  # =============================================================================
  
  cat("🔄 All APIs failed or unavailable - using duration estimates\n")
  return(get_duration_estimates(track_list))
}

# =============================================================================
# HELPER FUNCTION: DURATION ESTIMATES
# =============================================================================

get_duration_estimates <- function(track_list) {
  cat("📊 Generating duration estimates...\n")
  
  estimated_durations <- sapply(1:nrow(track_list), function(i) {
    artist <- track_list$main_artist[i]
    song <- track_list$main_song[i]
    
    # Basic estimates based on patterns
    duration <- case_when(
      grepl("Progressive|Pink Floyd|Yes|Genesis|King Crimson", artist, ignore.case = TRUE) ~ sample(300:600, 1),
      grepl("Punk|Ramones|Clash|Buzzcocks", artist, ignore.case = TRUE) ~ sample(120:240, 1),
      grepl("Bob Dylan|Leonard Cohen|Neil Young", artist, ignore.case = TRUE) ~ sample(240:420, 1),
      grepl("Radio|News|Weather|Ident", song, ignore.case = TRUE) ~ sample(60:180, 1),
      grepl("Instrumental|Outro|Intro", song, ignore.case = TRUE) ~ sample(120:300, 1),
      TRUE ~ sample(180:300, 1)  # 3-5 minutes for most tracks
    )
    
    return(duration)
  })
  
  cat("⚠️ Generated estimated durations for", nrow(track_list), "tracks\n")
  return(estimated_durations)
}

# =============================================================================
# ANALYZE ARTIST ENTHUSIASM
# =============================================================================

analyze_artist_enthusiasm <- function(track_list_with_durations) {
  cat("🎨 ANALYZING AI'S ARTIST ENTHUSIASM...\n")
  
  artist_analysis <- track_list_with_durations %>%
    filter(!is.na(effective_duration_with_fades)) %>%
    group_by(main_artist) %>%
    summarise(
      track_count = n(),
      avg_score = mean(fuzzy_dj_score, na.rm = TRUE),
      max_score = max(fuzzy_dj_score, na.rm = TRUE),
      total_duration = sum(effective_duration_with_fades, na.rm = TRUE) / 60,
      .groups = 'drop'
    ) %>%
    filter(track_count > 1) %>%  # Only artists with multiple tracks
    arrange(desc(avg_score))
  
  if (nrow(artist_analysis) > 0) {
    cat("🎭 Artists with multiple tracks (AI seems enthusiastic about):\n")
    for (i in 1:nrow(artist_analysis)) {
      artist <- artist_analysis[i, ]
      cat(sprintf("   %s: %d tracks, avg score %.3f, %.1f min total\n",
                  artist$main_artist, artist$track_count, artist$avg_score, artist$total_duration))
    }
    
    if (ALLOW_ARTIST_DOUBLE_PLAY) {
      cat("✅ Double-plays allowed - AI can express artist enthusiasm\n")
    } else {
      cat("🚫 Double-plays disabled - AI will be restricted to one per artist\n")
    }
  } else {
    cat("✅ No artist repeats in recommendations\n")
  }
  
  return(artist_analysis)
}

# =============================================================================
# OPTIMIZED TRACK COMBINATION WITH INTELLIGENT BACKTRACKING
# =============================================================================

find_optimal_track_combination <- function(track_list_with_durations, target_minutes = TIME_MARK_BLOCK_LENGTH) {
  cat("🎯 FINDING OPTIMAL TRACK COMBINATION\n")
  cat("📊 Target duration:", target_minutes, "minutes (", target_minutes * 60, "seconds)\n")
  
  # Filter out tracks with NA durations and deduplicate
  valid_tracks <- track_list_with_durations %>%
    filter(!is.na(effective_duration_with_fades)) %>%
    distinct(main_artist, main_song, .keep_all = TRUE) %>%
    arrange(desc(fuzzy_dj_score))
  
  if (nrow(valid_tracks) == 0) {
    cat("❌ No tracks with valid durations\n")
    return(NULL)
  }
  
  target_seconds <- (target_minutes * 60) - INTO_BREAK_BUFFER
  
  # =============================================================================
  # STEP 1: IMPROVED GREEDY SELECTION
  # =============================================================================
  
  cat("\n🎲 STEP 1: Improved greedy selection...\n")
  greedy_selection <- greedy_select(valid_tracks, target_seconds)
  
  if (is.null(greedy_selection) || nrow(greedy_selection) == 0) {
    cat("❌ Greedy selection failed\n")
    return(NULL)
  }
  
  initial_total <- sum(greedy_selection$effective_duration_with_fades)
  initial_gap <- target_seconds - initial_total
  
  # EARLY TERMINATION: If gap is already acceptable, skip optimization
  if (abs(initial_gap) <= 25) {  # Within surgical range
    cat(sprintf("   ✅ Gap already acceptable: %.1f seconds - skipping optimization\n", initial_gap))
    
    greedy_selection$block_position <- 1:nrow(greedy_selection)
    greedy_selection$total_music_duration <- initial_total
    greedy_selection$talk_time_needed <- initial_gap
    greedy_selection$optimization_improved <- FALSE
    
    return(greedy_selection)
  }
  
  cat(sprintf("   ⏰ Greedy result: %.1f min, gap: %.1f min - needs optimization\n", 
              initial_total / 60, initial_gap / 60))
  
  # =============================================================================
  # STEP 2: AGGRESSIVE OPTIMIZATION PASSES
  # =============================================================================
  
  best_selection <- greedy_selection
  best_gap <- abs(initial_gap)
  best_total <- initial_total
  
  cat("\n🧠 STEP 2: Aggressive optimization passes...\n")
  
  # Pass 1: Try single track swaps
  cat("   🔄 Pass 1: Single track swaps...\n")
  swap_result <- try_single_swaps(best_selection, valid_tracks, target_seconds)
  if (!is.null(swap_result) && abs(swap_result$gap) < best_gap) {
    best_selection <- swap_result$selection
    best_gap <- abs(swap_result$gap)
    best_total <- swap_result$total
    cat(sprintf("   ✅ Improved! New gap: %.1f min\n", swap_result$gap / 60))
    
    # Check if now acceptable
    if (best_gap <= 25) {
      cat("   🎯 Gap now acceptable - stopping optimization\n")
      best_selection$optimization_improved <- TRUE
      return(finalize_selection(best_selection, best_total, target_seconds - best_total))
    }
  }
  
  # Pass 2: Try adding tracks (with lower threshold)
  cat("   🔄 Pass 2: Try adding tracks...\n")
  add_result <- try_adding_tracks(best_selection, valid_tracks, target_seconds)
  if (!is.null(add_result) && abs(add_result$gap) < best_gap) {
    best_selection <- add_result$selection
    best_gap <- abs(add_result$gap)
    best_total <- add_result$total
    cat(sprintf("   ✅ Improved! New gap: %.1f min\n", add_result$gap / 60))
    
    # Check if now acceptable
    if (best_gap <= 25) {
      cat("   🎯 Gap now acceptable - stopping optimization\n")
      best_selection$optimization_improved <- TRUE
      return(finalize_selection(best_selection, best_total, target_seconds - best_total))
    }
  }
  
  # Pass 3: Try 1-for-2 swaps (only if gap still large)
  if (best_gap > 45) {
    cat("   🔄 Pass 3: 1-for-2 swaps (large gap)...\n")
    combo_result <- try_combo_swaps(best_selection, valid_tracks, target_seconds)
    if (!is.null(combo_result) && abs(combo_result$gap) < best_gap) {
      best_selection <- combo_result$selection
      best_gap <- abs(combo_result$gap)
      best_total <- combo_result$total
      cat(sprintf("   ✅ Improved! New gap: %.1f min\n", combo_result$gap / 60))
    }
  } else {
    cat("   ✅ Gap reasonable - skipping expensive 1-for-2 swaps\n")
  }
  
  return(finalize_selection(best_selection, best_total, target_seconds - best_total, abs(initial_gap) > best_gap))
}

# =============================================================================
# HELPER: FINALIZE SELECTION
# =============================================================================

finalize_selection <- function(selection, total, gap, improved = TRUE) {
  selection$block_position <- 1:nrow(selection)
  selection$total_music_duration <- total
  selection$talk_time_needed <- gap
  selection$optimization_improved <- improved
  
  cat(sprintf("\n🎯 FINAL RESULT: %.1f min total, %.1f sec gap, %d tracks\n", 
              total / 60, gap, nrow(selection)))
  
  return(selection)
}

# =============================================================================
# HELPER: INITIAL GREEDY SELECTION
# =============================================================================

greedy_select <- function(valid_tracks, target_seconds) {
  selected_tracks <- data.frame()
  total_duration <- 0
  
  cat("   🎯 Target: ", round(target_seconds / 60, 1), " minutes\n")
  
  for (i in 1:nrow(valid_tracks)) {
    track <- valid_tracks[i, ]
    
    # Skip if already selected
    if (nrow(selected_tracks) > 0) {
      already_selected <- any(selected_tracks$main_artist == track$main_artist & 
                                selected_tracks$main_song == track$main_song)
      if (already_selected) next
    }
    
    new_total <- total_duration + track$effective_duration_with_fades
    
    # IMPROVED LOGIC: More aggressive filling
    if (new_total <= target_seconds || nrow(selected_tracks) < 4) {  # Require at least 4 tracks
      selected_tracks <- rbind(selected_tracks, track)
      total_duration <- new_total
      
      cat(sprintf("   ✅ Added: %s - %s (%.1f min total)\n", 
                  track$main_artist, track$main_song, total_duration / 60))
    }
    
    # IMPROVED STOPPING CRITERIA: More aggressive filling
    # Don't stop until we're at least 90% filled AND have reasonable track count
    fill_percentage <- total_duration / target_seconds
    if (fill_percentage >= 0.90 && nrow(selected_tracks) >= 6) {
      cat(sprintf("   🎯 Good fill achieved: %.1f%% with %d tracks\n", 
                  fill_percentage * 100, nrow(selected_tracks)))
      break
    }
    
    # Safety valve: don't go crazy with track count
    if (nrow(selected_tracks) >= 12) {
      cat("   ⚠️ Maximum track count reached\n")
      break
    }
  }
  
  final_gap <- target_seconds - total_duration
  cat(sprintf("   📊 Greedy result: %.1f min total, %.1f min gap\n", 
              total_duration / 60, final_gap / 60))
  
  return(selected_tracks)
}

# =============================================================================
# HELPER: TRY SINGLE TRACK SWAPS
# =============================================================================

try_single_swaps <- function(current_selection, valid_tracks, target_seconds) {
  current_total <- sum(current_selection$effective_duration_with_fades)
  current_gap <- abs(target_seconds - current_total)
  best_result <- NULL
  
  # SAFETY: Ensure we have finite values to work with
  if (!is.finite(current_total) || !is.finite(target_seconds) || !is.finite(current_gap)) {
    cat("   ⚠️ Invalid numeric values in swap calculation\n")
    return(NULL)
  }
  
  # Try swapping each selected track
  for (i in 1:nrow(current_selection)) {
    # Remove track i
    temp_selection <- current_selection[-i, ]
    temp_total <- sum(temp_selection$effective_duration_with_fades)
    
    # SAFETY: Check temp_total is valid
    if (!is.finite(temp_total)) next
    
    # Try adding each unused track
    unused_tracks <- valid_tracks %>%
      anti_join(current_selection, by = c("main_artist", "main_song"))
    
    if (nrow(unused_tracks) == 0) next  # Skip if no unused tracks
    
    for (j in 1:min(nrow(unused_tracks), 10)) {  # Try top 10 unused tracks
      candidate <- unused_tracks[j, ]
      
      # SAFETY: Check candidate duration is valid
      if (!is.finite(candidate$effective_duration_with_fades)) next
      
      new_total <- temp_total + candidate$effective_duration_with_fades
      new_gap <- abs(target_seconds - new_total)
      
      # CRITICAL FIX: Use is.finite() to check for valid comparison
      if (is.finite(new_gap) && is.finite(current_gap) && new_gap < current_gap) {
        new_selection <- rbind(temp_selection, candidate) %>%
          arrange(desc(fuzzy_dj_score))
        
        best_result <- list(
          selection = new_selection,
          total = new_total,
          gap = target_seconds - new_total
        )
        current_gap <- new_gap
      }
    }
  }
  
  return(best_result)
}

# =============================================================================
# HELPER: TRY ADDING TRACKS
# =============================================================================

try_adding_tracks <- function(current_selection, valid_tracks, target_seconds) {
  current_total <- sum(current_selection$effective_duration_with_fades)
  current_gap <- target_seconds - current_total
  
  # IMPROVED: Much lower threshold - try to fill gaps >45 seconds
  if (current_gap < 45) return(NULL)  # Only skip if gap is really small
  
  cat(sprintf("   🔍 Trying to fill %.1f min gap\n", current_gap / 60))
  
  unused_tracks <- valid_tracks %>%
    anti_join(current_selection, by = c("main_artist", "main_song")) %>%
    filter(effective_duration_with_fades <= current_gap)
  
  if (nrow(unused_tracks) == 0) {
    cat("   ⚠️ No unused tracks fit in remaining gap\n")
    return(NULL)
  }
  
  cat(sprintf("   📊 Found %d potential tracks to add\n", nrow(unused_tracks)))
  
  # Find best fitting track
  best_track <- unused_tracks %>%
    mutate(gap_after_adding = abs(current_gap - effective_duration_with_fades)) %>%
    arrange(gap_after_adding, desc(fuzzy_dj_score)) %>%
    slice_head(n = 1) %>%
    select(-gap_after_adding)
  
  new_selection <- rbind(current_selection, best_track) %>%
    arrange(desc(fuzzy_dj_score))
  new_total <- current_total + best_track$effective_duration_with_fades
  new_gap <- target_seconds - new_total
  
  cat(sprintf("   ✅ Added %s - %s, new gap: %.1f min\n", 
              best_track$main_artist, best_track$main_song, new_gap / 60))
  
  return(list(
    selection = new_selection,
    total = new_total,
    gap = target_seconds - new_total
  ))
}

# =============================================================================
# HELPER: TRY COMBINATION SWAPS (1-for-2)
# =============================================================================

try_combo_swaps <- function(current_selection, valid_tracks, target_seconds) {
  cat("🔄 Pass 3: 1-for-2 swaps (bulletproof version)...\n")
  
  # =============================================================================
  # SAFETY CHECKS
  # =============================================================================
  
  # Check inputs
  if (is.null(current_selection) || nrow(current_selection) == 0) {
    cat("   ⚠️ No current selection provided\n")
    return(NULL)
  }
  
  if (is.null(valid_tracks) || nrow(valid_tracks) == 0) {
    cat("   ⚠️ No valid tracks provided\n")
    return(NULL)
  }
  
  if (is.na(target_seconds) || target_seconds <= 0) {
    cat("   ⚠️ Invalid target_seconds:", target_seconds, "\n")
    return(NULL)
  }
  
  # Check required columns
  required_cols <- c("main_artist", "main_song", "effective_duration_with_fades", "fuzzy_dj_score")
  missing_cols <- setdiff(required_cols, names(current_selection))
  if (length(missing_cols) > 0) {
    cat("   ⚠️ Missing columns in current_selection:", paste(missing_cols, collapse = ", "), "\n")
    return(NULL)
  }
  
  missing_cols <- setdiff(required_cols, names(valid_tracks))
  if (length(missing_cols) > 0) {
    cat("   ⚠️ Missing columns in valid_tracks:", paste(missing_cols, collapse = ", "), "\n")
    return(NULL)
  }
  
  # =============================================================================
  # CALCULATE CURRENT STATE
  # =============================================================================
  
  # Calculate current totals (with safety)
  current_durations <- current_selection$effective_duration_with_fades
  if (any(is.na(current_durations))) {
    cat("   ⚠️ NA durations found in current selection\n")
    return(NULL)
  }
  
  current_total <- sum(current_durations)
  current_gap <- abs(target_seconds - current_total)
  
  cat("   📊 Current total:", round(current_total / 60, 1), "min, gap:", round(current_gap / 60, 1), "min\n")
  
  # Only try if gap is significant
  if (current_gap < 60) {  # Less than 1 minute gap
    cat("   ✅ Gap too small for 1-for-2 swaps\n")
    return(NULL)
  }
  
  best_result <- NULL
  best_gap <- current_gap
  improvements_tried <- 0
  
  # =============================================================================
  # TRY EACH TRACK REMOVAL
  # =============================================================================
  
  for (i in 1:nrow(current_selection)) {
    track_to_remove <- current_selection[i, ]
    
    cat(sprintf("   🎵 Trying to replace: %s - %s (%.1f min)\n", 
                track_to_remove$main_artist, track_to_remove$main_song,
                track_to_remove$effective_duration_with_fades / 60))
    
    # Calculate what we'd have without this track
    remaining_selection <- current_selection[-i, ]
    remaining_total <- sum(remaining_selection$effective_duration_with_fades)
    available_time <- target_seconds - remaining_total
    
    cat(sprintf("   📏 Available time for replacements: %.1f min\n", available_time / 60))
    
    # =============================================================================
    # FIND UNUSED TRACKS (SAFE METHOD)
    # =============================================================================
    
    # Create track IDs for safe comparison
    current_track_ids <- paste(current_selection$main_artist, current_selection$main_song, sep = "|||")
    valid_track_ids <- paste(valid_tracks$main_artist, valid_tracks$main_song, sep = "|||")
    
    # Find unused tracks
    unused_indices <- which(!valid_track_ids %in% current_track_ids)
    
    if (length(unused_indices) < 2) {
      cat("   ⚠️ Not enough unused tracks for combinations\n")
      next
    }
    
    unused_tracks <- valid_tracks[unused_indices, ]
    
    # Filter to tracks that could reasonably fit
    max_individual_duration <- available_time * 0.7  # Conservative limit for individual tracks
    suitable_tracks <- unused_tracks[unused_tracks$effective_duration_with_fades <= max_individual_duration, ]
    
    if (nrow(suitable_tracks) < 2) {
      cat("   ⚠️ Not enough suitable tracks for combinations\n")
      next
    }
    
    cat(sprintf("   📊 Found %d suitable unused tracks for combinations\n", nrow(suitable_tracks)))
    
    # =============================================================================
    # TRY TRACK COMBINATIONS (SAFELY)
    # =============================================================================
    
    # Limit to top tracks by score to avoid excessive combinations
    top_candidates <- suitable_tracks %>%
      arrange(desc(fuzzy_dj_score)) %>%
      slice_head(n = 8)  # Limit to top 8 candidates
    
    combinations_tried <- 0
    
    for (j in 1:(nrow(top_candidates) - 1)) {
      for (k in (j + 1):nrow(top_candidates)) {
        
        track1 <- top_candidates[j, ]
        track2 <- top_candidates[k, ]
        
        # Safety checks for individual tracks
        duration1 <- track1$effective_duration_with_fades[1]  # Force single value
        duration2 <- track2$effective_duration_with_fades[1]  # Force single value
        
        if (is.na(duration1) || is.na(duration2)) {
          cat("   ⚠️ NA duration found in combination candidates\n")
          next
        }
        
        combo_duration <- duration1 + duration2
        
        # Check if combination fits
        if (combo_duration <= available_time) {
          
          new_total <- remaining_total + combo_duration
          new_gap <- abs(target_seconds - new_total)
          
          # Check if this is an improvement
          if (new_gap < best_gap) {
            
            cat(sprintf("   ✅ Better combination found! %s (%.1f) + %s (%.1f) = %.1f min total\n",
                        track1$main_song, duration1 / 60, track2$main_song, duration2 / 60, new_total / 60))
            
            # Build new selection
            new_selection <- rbind(remaining_selection, track1, track2)
            new_selection <- new_selection[order(-new_selection$fuzzy_dj_score), ]  # Sort by score
            
            best_result <- list(
              selection = new_selection,
              total = new_total,
              gap = target_seconds - new_total
            )
            
            best_gap <- new_gap
            improvements_tried <- improvements_tried + 1
          }
        }
        
        combinations_tried <- combinations_tried + 1
        
        # Limit combinations to avoid excessive processing
        if (combinations_tried >= 20) {
          cat("   📊 Tried 20 combinations, moving to next track\n")
          break
        }
      }
      
      if (combinations_tried >= 20) break
    }
  }
  
  # =============================================================================
  # RESULTS
  # =============================================================================
  
  if (!is.null(best_result)) {
    improvement <- (current_gap - best_gap) / 60
    cat(sprintf("   🎯 Pass 3 improvement: %.1f minutes better gap\n", improvement))
  } else {
    cat("   😐 No improvements found in Pass 3\n")
  }
  
  return(best_result)
}

# =============================================================================
# ARTIST EQUIVALENCY CHECKER
# =============================================================================

are_artists_equivalent <- function(artist1, artist2) {
  
  # Quick check for exact match
  if (artist1 == artist2) return(TRUE)
  
  # Handle NULL or empty values
  if (is.null(artist1) || is.null(artist2) || artist1 == "" || artist2 == "") {
    return(FALSE)
  }
  
  # Check database for equivalency using SQL connection
  tryCatch({
    con <- create_sql_connection(connection_name = "artist_equivalency")
    
    query <- "
    SELECT COUNT(*) as matches 
    FROM artist_equivalencies 
    WHERE active = 1 
      AND ((artist_1 = ? AND artist_2 = ?) 
           OR (artist_1 = ? AND artist_2 = ?))
    "
    
    result <- dbGetQuery(con, query, params = list(artist1, artist2, artist2, artist1))
    dbDisconnect(con)
    
    if (!is.null(result) && nrow(result) > 0) {
      return(result$matches[1] > 0)
    } else {
      return(FALSE)
    }
    
  }, error = function(e) {
    if (exists("con") && dbIsValid(con)) dbDisconnect(con)
    cat("   ⚠️ Error checking artist equivalency:", e$message, "\n")
    return(FALSE)
  })
}

# =============================================================================
# BATCH ARTIST EQUIVALENCY CHECKER (MORE EFFICIENT)
# =============================================================================

check_artists_equivalent_batch <- function(artist_pairs) {
  # artist_pairs should be a data frame with columns: artist1, artist2
  # Returns a vector of TRUE/FALSE values
  
  if (is.null(artist_pairs) || nrow(artist_pairs) == 0) {
    return(logical(0))
  }
  
  # Quick exact matches
  exact_matches <- artist_pairs$artist1 == artist_pairs$artist2
  
  # For non-exact matches, check database
  non_exact_pairs <- artist_pairs[!exact_matches, ]
  
  if (nrow(non_exact_pairs) == 0) {
    return(exact_matches)  # All were exact matches
  }
  
  tryCatch({
    # Load all active equivalencies once
    all_equivalencies_query <- "SELECT artist_1, artist_2 FROM artist_equivalencies WHERE active = 1"
    all_equivalencies <- sql_query(all_equivalencies_query, connection_name = "batch_equivalency")
    
    if (is.null(all_equivalencies) || nrow(all_equivalencies) == 0) {
      # No equivalencies in database, return exact matches only
      return(exact_matches)
    }
    
    # Check each non-exact pair against the equivalencies
    db_matches <- logical(nrow(non_exact_pairs))
    
    for (i in 1:nrow(non_exact_pairs)) {
      artist1 <- non_exact_pairs$artist1[i]
      artist2 <- non_exact_pairs$artist2[i]
      
      # Check if this pair exists in either direction
      db_matches[i] <- any(
        (all_equivalencies$artist_1 == artist1 & all_equivalencies$artist_2 == artist2) |
          (all_equivalencies$artist_1 == artist2 & all_equivalencies$artist_2 == artist1)
      )
    }
    
    # Combine exact matches with database matches
    final_result <- exact_matches
    final_result[!exact_matches] <- db_matches
    
    return(final_result)
    
  }, error = function(e) {
    cat("   ⚠️ Error in batch artist equivalency check:", e$message, "\n")
    return(exact_matches)  # Fallback to exact matches only
  })
}

# =============================================================================
# FUZZY ARTIST MATCHING
# =============================================================================

are_artists_fuzzy_equivalent <- function(artist1, artist2, threshold = 0.8) {

  # Then try normalized matching
  norm1 <- normalize_for_sql_search(artist1)
  norm2 <- normalize_for_sql_search(artist2)
  
  if (norm1 == norm2) {
    return(TRUE)
  }
  
  # Finally, try string similarity (if available)
  if (requireNamespace("stringdist", quietly = TRUE)) {
    similarity <- 1 - stringdist::stringdist(norm1, norm2, method = "jw")
    return(similarity >= threshold)
  }
  
  return(FALSE)
}

# =============================================================================
# ARTIST EQUIVALENCY MANAGEMENT FUNCTIONS
# =============================================================================

add_artist_equivalency <- function(artist1, artist2, notes = "") {
  # Add a new artist equivalency to the database
  
  cat(sprintf("➕ Adding artist equivalency: '%s' = '%s'\n", artist1, artist2))
  
  tryCatch({
    con <- create_sql_connection(connection_name = "add_equivalency")
    
    # Check if equivalency already exists
    check_query <- "
    SELECT COUNT(*) as existing 
    FROM artist_equivalencies 
    WHERE ((artist_1 = ? AND artist_2 = ?) OR (artist_1 = ? AND artist_2 = ?))
      AND active = 1
    "
    
    existing <- dbGetQuery(con, check_query, params = list(artist1, artist2, artist2, artist1))
    
    if (existing$existing[1] > 0) {
      cat("   ⚠️ Equivalency already exists\n")
      dbDisconnect(con)
      return(FALSE)
    }
    
    # Add new equivalency
    insert_query <- "
    INSERT INTO artist_equivalencies (artist_1, artist_2, notes, active, created_at)
    VALUES (?, ?, ?, 1, NOW())
    "
    
    result <- dbExecute(con, insert_query, params = list(artist1, artist2, notes))
    dbDisconnect(con)
    
    if (result > 0) {
      cat("   ✅ Artist equivalency added successfully\n")
      return(TRUE)
    } else {
      cat("   ❌ Failed to add artist equivalency\n")
      return(FALSE)
    }
    
  }, error = function(e) {
    if (exists("con") && dbIsValid(con)) dbDisconnect(con)
    cat("   ❌ Error adding artist equivalency:", e$message, "\n")
    return(FALSE)
  })
}

remove_artist_equivalency <- function(artist1, artist2) {
  # Remove (deactivate) an artist equivalency
  
  cat(sprintf("➖ Removing artist equivalency: '%s' = '%s'\n", artist1, artist2))
  
  tryCatch({
    con <- create_sql_connection(connection_name = "remove_equivalency")
    
    # Deactivate the equivalency (don't delete, for audit trail)
    update_query <- "
    UPDATE artist_equivalencies 
    SET active = 0, updated_at = NOW()
    WHERE ((artist_1 = ? AND artist_2 = ?) OR (artist_1 = ? AND artist_2 = ?))
      AND active = 1
    "
    
    result <- dbExecute(con, update_query, params = list(artist1, artist2, artist2, artist1))
    dbDisconnect(con)
    
    if (result > 0) {
      cat(sprintf("   ✅ Deactivated %d equivalency record(s)\n", result))
      return(TRUE)
    } else {
      cat("   ⚠️ No active equivalency found to remove\n")
      return(FALSE)
    }
    
  }, error = function(e) {
    if (exists("con") && dbIsValid(con)) dbDisconnect(con)
    cat("   ❌ Error removing artist equivalency:", e$message, "\n")
    return(FALSE)
  })
}

list_artist_equivalencies <- function(limit = 50) {
  # List all active artist equivalencies
  
  cat("📋 LISTING ARTIST EQUIVALENCIES:\n")

  tryCatch({
    query <- paste0("\
    SELECT artist_1, artist_2, notes, created_date
    FROM artist_equivalencies 
    WHERE active = 1 
    ORDER BY created_date DESC
    LIMIT ", limit)
    
    result <- sql_query(query, connection_name = "list_equivalencies")
    
    if (is.null(result) || nrow(result) == 0) {
      cat("   📭 No artist equivalencies found\n")
      return(NULL)
    }
    
    cat(sprintf("   📊 Found %d active equivalencies:\n", nrow(result)))
    
    for (i in 1:nrow(result)) {
      equiv <- result[i, ]
      notes_preview <- if (nchar(equiv$notes) > 30) paste0(substr(equiv$notes, 1, 30), "...") else equiv$notes
      cat(sprintf("   %d. '%s' = '%s' %s\n", 
                  i, equiv$artist_1, equiv$artist_2,
                  if (equiv$notes != "") paste0("(", notes_preview, ")") else ""))
    }
    
    return(result)
    
  }, error = function(e) {
    cat("   ❌ Error listing artist equivalencies:", e$message, "\n")
    return(NULL)
  })
}

# =============================================================================
# DOUBLE-PLAY HANDLING
# =============================================================================

create_double_play_fat_tracks <- function(track_list_with_durations) {
  cat("🎭 CREATING DOUBLE-PLAY 'FAT TRACKS'...\n")
  
  if (is.null(track_list_with_durations) || nrow(track_list_with_durations) == 0) {
    cat("❌ No tracks to process\n")
    return(track_list_with_durations)
  }
  
  if (!ALLOW_ARTIST_DOUBLE_PLAY) {
    cat("🚫 Double-plays disabled in config\n")
    return(track_list_with_durations)
  }
  
  # Work with a copy to avoid issues
  result_tracks <- track_list_with_durations
  
  # FIRST: Create all partner columns upfront to avoid dataframe corruption
  original_col_names <- names(result_tracks)
  for (col_name in original_col_names) {
    partner_col_name <- paste0("partner_", col_name)
    if (!partner_col_name %in% names(result_tracks)) {
      result_tracks[[partner_col_name]] <- NA
    }
  }
  
  rows_to_remove <- c()
  double_play_count <- 0
  
  for (i in 1:(nrow(result_tracks) - 1)) {
    # Skip if this row is already marked for removal
    if (i %in% rows_to_remove) next
    
    # Skip if intro_type is not 1 (normal single track)
    if (result_tracks$intro_type[i] != 1) next
    
    current_artist <- result_tracks$main_artist[i]
    
    # Look for equivalent artists in remaining tracks
    for (j in (i+1):nrow(result_tracks)) {
      # Skip if this row is already marked for removal
      if (j %in% rows_to_remove) next
      
      # Skip if intro_type is not 1
      if (result_tracks$intro_type[j] != 1) next
      
      other_artist <- result_tracks$main_artist[j]
      
      if (are_artists_equivalent(current_artist, other_artist)) {
        cat(sprintf("   🎭 Creating fat track: %s - %s + %s - %s\n", 
                    result_tracks$main_artist[i], result_tracks$main_song[i],
                    result_tracks$main_artist[j], result_tracks$main_song[j]))
        
        # Store original track 1 duration
        original_duration_1 <- result_tracks$track_duration[i]
        track_2_duration <- result_tracks$track_duration[j]
        
        # Copy ALL track 2 fields to partner fields (structure already exists)
        for (col_name in original_col_names) {
          partner_col_name <- paste0("partner_", col_name)
          result_tracks[[partner_col_name]][i] <- result_tracks[[col_name]][j]
        }
        
        # Update track 1 with combined duration and settings
        combined_duration <- original_duration_1 + track_2_duration
        result_tracks$track_duration[i] <- combined_duration
        result_tracks$intro_type[i] <- 2  # CRITICAL: Set to double-play
        
        # Recalculate derived timing fields
        result_tracks$track_duration_mins[i] <- round(combined_duration / 60, 1)
        result_tracks$total_estimated_duration[i] <- combined_duration + result_tracks$estimated_intro_duration[i]
        result_tracks$effective_duration_with_fades[i] <- result_tracks$total_estimated_duration[i] - CROSS_FADE_IN - CROSS_FADE_OUT
        
        cat(sprintf("      💾 Combined duration: %.1fs + %.1fs = %.1fs\n", 
                    original_duration_1, track_2_duration, combined_duration))
        cat(sprintf("      🎭 Set intro_type[%d] = %d\n", i, result_tracks$intro_type[i]))
        
        # Mark track 2 for removal
        rows_to_remove <- c(rows_to_remove, j)
        double_play_count <- double_play_count + 1
        break  # Only pair with first equivalent found
      }
    }
  }
  
  # Remove partner tracks
  if (length(rows_to_remove) > 0) {
    cat(sprintf("      🗑️ Removing partner tracks: %s\n", paste(rows_to_remove, collapse = ", ")))
    result_tracks <- result_tracks[-rows_to_remove, ]
    rownames(result_tracks) <- NULL
  }
  
  cat(sprintf("✅ Created %d double-play fat track(s)\n", double_play_count))
  cat(sprintf("📊 Final candidate count: %d\n", nrow(result_tracks)))
  
  return(result_tracks)
}

# =============================================================================
# 2) DECOMPRESS FAT TRACKS (REVERSE THE PROCESS)
# =============================================================================

decompress_fat_tracks <- function(complete_block_list) {
  cat("🎭 DECOMPRESSING FAT TRACKS FROM LIST STRUCTURE...\n")
  
  if (is.null(complete_block_list) || length(complete_block_list) == 0) {
    cat("❌ No elements to decompress\n")
    return(complete_block_list)
  }
  
  decompressed_elements <- list()
  element_count <- 1
  
  for (i in 1:length(complete_block_list)) {
    element <- complete_block_list[[i]]
    
    # Only process track elements
    if (element$type == "track") {
      
      # Safe check for intro_type
      intro_type <- if (is.null(element$intro_type) || is.na(element$intro_type)) 1 else element$intro_type
      
      if (intro_type == 2) {
        # Fat track - decompress to two tracks
        cat(sprintf("   🎭 Decompressing: %s + %s\n", element$main_song, element$partner_main_song))
        
        # =============================================================================
        # CREATE TRACK 1 (LEAD) - RESTORE ORIGINAL DURATION
        # =============================================================================
        
        track1 <- element
        
        # Calculate original track 1 duration
        original_track1_duration <- element$track_duration - element$partner_track_duration
        track1$track_duration <- original_track1_duration
        track1$duration <- original_track1_duration  # Update both duration fields
        track1$intro_type <- 2  # Keep double-play intro
        
        # FIXED: Recalculate track1 effective duration with original duration only
        if (!is.null(track1$intro_duration)) {
          track1$effective_duration_with_fades <- original_track1_duration + track1$intro_duration - CROSS_FADE_IN - CROSS_FADE_OUT
        } else {
          track1$effective_duration_with_fades <- original_track1_duration - CROSS_FADE_IN - CROSS_FADE_OUT
        }
        
        # Remove all partner_ fields from track1
        partner_fields <- names(track1)[grepl("^partner_", names(track1))]
        for (field in partner_fields) {
          track1[[field]] <- NULL
        }
        
        # =============================================================================
        # CREATE TRACK 2 (FOLLOW) - USE PARTNER DATA
        # =============================================================================
        
        track2 <- track1  # Start with clean track1 structure
        
        # FIXED: Copy partner data back to main fields properly
        for (field_name in names(element)) {
          if (grepl("^partner_", field_name)) {
            original_field_name <- sub("^partner_", "", field_name)
            if (original_field_name %in% names(track2)) {
              track2[[original_field_name]] <- element[[field_name]]
            }
          }
        }
        
        # FIXED: Ensure track2 gets correct name and duration
        track2$main_song <- element$partner_main_song
        track2$main_artist <- element$partner_main_artist
        track2$song <- element$partner_main_song          # For display function
        track2$artist <- element$partner_main_artist      # For display function
        track2$track_duration <- element$partner_track_duration
        track2$duration <- element$partner_track_duration
        
        # Set track 2 specific settings
        track2$intro_type <- 0  # No intro for second track
        track2$estimated_intro_duration <- 0
        track2$intro_duration <- 0
        
        # FIXED: Recalculate track2 effective duration with correct duration
        track2$effective_duration_with_fades <- track2$track_duration - CROSS_FADE_IN - CROSS_FADE_OUT
        
        # Clear intro file references for track2
        track2$intro_filenames <- NA
        track2$intro_full_path <- NA
        track2$actual_intro_duration <- 0
        
        # Update content field for track2
        track2$content <- paste0(track2$main_artist, " - ", track2$main_song)
        
        # Add both tracks to decompressed list
        decompressed_elements[[element_count]] <- track1
        element_count <- element_count + 1
        decompressed_elements[[element_count]] <- track2
        element_count <- element_count + 1
        
        cat(sprintf("      ✅ Split into: %s (%.1fs) + %s (%.1fs)\n", 
                    track1$main_song, track1$track_duration,
                    track2$main_song, track2$track_duration))
        
      } else {
        # Single track - add as-is
        decompressed_elements[[element_count]] <- element
        element_count <- element_count + 1
      }
      
    } else {
      # Non-track element (intro, filler) - add as-is
      decompressed_elements[[element_count]] <- element
      element_count <- element_count + 1
    }
  }
  
  fat_track_count <- sum(sapply(complete_block_list, function(x) {
    x$type == "track" && !is.null(x$intro_type) && !is.na(x$intro_type) && x$intro_type == 2
  }))
  
  cat(sprintf("✅ Decompressed %d fat track(s) into %d total elements\n", 
              fat_track_count, length(decompressed_elements)))
  
  return(decompressed_elements)
}

# =============================================================================
# MAINTENANCE FUNCTIONS
# =============================================================================

cleanup_old_intros <- function(days_old = 90, style = "dry_witty_radio6") {
  cat(sprintf("🧹 CLEANING UP INTROS OLDER THAN %d DAYS...\n", days_old))
  
  tryCatch({
    cleanup_query <- paste0("DELETE FROM ", TALKING_POINTS_TABLE, 
                            " WHERE style = '", style, 
                            "' AND last_updated < DATE_SUB(NOW(), INTERVAL ", days_old, " DAY)",
                            " AND artist != 'generic' AND artist != 'intros'")
    
    con <- create_sql_connection(connection_name = "cleanup")
    deleted_count <- dbExecute(con, cleanup_query)
    dbDisconnect(con)
    
    cat(sprintf("✅ Cleaned up %d old intros\n", deleted_count))
    return(deleted_count)
    
  }, error = function(e) {
    cat("❌ Error during cleanup:", e$message, "\n")
    if (exists("con") && dbIsValid(con)) dbDisconnect(con)
    return(0)
  })
}

# =============================================================================
# SYSTEM STATUS AND MAINTENANCE
# =============================================================================

check_intro_system_status <- function() {
  cat("🎙️ CHECKING INTRO SYSTEM STATUS...\n")
  cat(paste0(rep("=", 50), collapse = ""), "\n")
  
  tryCatch({
    # Check if talking points table exists and has data
    table_query <- paste0("SELECT COUNT(*) as total_intros FROM ", TALKING_POINTS_TABLE)
    total_result <- sql_query(table_query, connection_name = "status_check")
    
    if (!is.null(total_result)) {
      total_intros <- total_result$total_intros[1]
      cat("✅ Talking points table accessible\n")
      cat(sprintf("   📊 Total intros in database: %.f0\n", total_intros))
      
      # Check by style
      style_query <- paste0("SELECT style, COUNT(*) as count FROM ", TALKING_POINTS_TABLE, 
                            " GROUP BY style ORDER BY count DESC")
      style_result <- sql_query(style_query, connection_name = "style_check")
      
      if (!is.null(style_result) && nrow(style_result) > 0) {
        cat("   🎨 Intro styles available:\n")
        for (i in 1:min(5, nrow(style_result))) {
          cat(sprintf("      %s: %f intros\n", style_result$style[i], style_result$count[i]))
        }
      }
      
      # Check for generic fallbacks
      generic_query <- paste0("SELECT COUNT(*) as generic_count FROM ", TALKING_POINTS_TABLE, 
                              " WHERE artist = 'generic' AND song = 'generic'")
      generic_result <- sql_query(generic_query, connection_name = "generic_check")
      
      if (!is.null(generic_result)) {
        generic_count <- generic_result$generic_count[1]
        cat(sprintf("   🎭 Generic fallback intros: %d\n", generic_count))
      }
      
      # Check idents
      ident_query <- paste0("SELECT song as ident_type, COUNT(*) as count FROM ", TALKING_POINTS_TABLE, 
                            " WHERE artist = 'intros' GROUP BY song")
      ident_result <- sql_query(ident_query, connection_name = "ident_check")
      
      if (!is.null(ident_result) && nrow(ident_result) > 0) {
        cat("   📻 Station idents available:\n")
        for (i in 1:nrow(ident_result)) {
          cat(sprintf("      %s: %f idents\n", ident_result$ident_type[i], ident_result$count[i]))
        }
      }
      
    } else {
      cat("❌ Cannot access talking points table\n")
    }
    
    # Check if AI services are configured
    cat("\n🤖 AI SERVICE CONFIGURATION:\n")
    if (exists("CHATGPT_API_KEY") && !is.null(CHATGPT_API_KEY) && CHATGPT_API_KEY != "") {
      cat("   ✅ ChatGPT API configured\n")
    } else {
      cat("   ❌ ChatGPT API not configured\n")
    }
    
    if (exists("CLAUDE_ANTHROPIC_API_KEY") && !is.null(CLAUDE_ANTHROPIC_API_KEY) && CLAUDE_ANTHROPIC_API_KEY != "") {
      cat("   ✅ Claude API configured\n")
    } else {
      cat("   ❌ Claude API not configured\n")
    }
    
    # Test SQL connection
    cat("\n🔌 SQL CONNECTION TEST:\n")
    connection_test <- test_sql_connection()
    if (connection_test) {
      cat("   ✅ SQL connection working\n")
    } else {
      cat("   ❌ SQL connection failed\n")
    }
    
    cat("\n✅ Intro system status check complete\n")
    
  }, error = function(e) {
    cat("❌ Error checking intro system status:", e$message, "\n")
  })
}


# =============================================================================
# CONFIGURATION VALIDATION
# =============================================================================

validate_intro_system_config <- function() {
  cat("🔧 VALIDATING INTRO SYSTEM CONFIGURATION...\n")
  
  required_vars <- c("TALKING_POINTS_TABLE", "MAIN_STATION_NAME")
  missing_vars <- required_vars[!sapply(required_vars, function(x) exists(x, envir = .GlobalEnv))]
  
  if (length(missing_vars) > 0) {
    cat("❌ Missing required configuration variables:\n")
    for (var in missing_vars) {
      cat(sprintf("   - %s\n", var))
    }
    return(FALSE)
  }
  
  optional_vars <- c("AI_DJ_HISTORY_TABLE", "ESTIMATED_DURATION_OF_INTROS", "CHATGPT_API_KEY", "CLAUDE_ANTHROPIC_API_KEY")
  for (var in optional_vars) {
    if (exists(var, envir = .GlobalEnv)) {
      cat(sprintf("✅ %s: configured\n", var))
    } else {
      cat(sprintf("⚠️ %s: not configured (optional)\n", var))
    }
  }
  
  cat("✅ Configuration validation complete\n")
  return(TRUE)
}

# Run validation on load
validate_intro_system_config()


# =============================================================================
# HELPER FUNCTIONS
# =============================================================================

    # =========================================================================
    # HELPER 1: SQL CONNECTION
    # =========================================================================

create_sql_connection <- function(auto_disconnect = FALSE, connection_name = "default") {
  
  # Creates a robust database connection using existing configuration variables.
  #
  # Parameters:
  # - auto_disconnect: If TRUE, returns a list with connection and auto-disconnect function
  # - connection_name: Optional name for connection (useful for debugging)
  #
  # Returns:
  # - Database connection object (if auto_disconnect = FALSE)
  # - List with $con and $disconnect() function (if auto_disconnect = TRUE)
  
  #cat("🔌 Establishing SQL connection (", connection_name, ")...\n")
  
  tryCatch({
    # Validate configuration variables exist
    required_vars <- c("DB_TYPE", "DB_HOST", "DB_NAME", "DB_USER", "DB_PASSWORD", "DB_PORT")
    missing_vars <- required_vars[!sapply(required_vars, function(x) exists(x, envir = .GlobalEnv))]
    
    if (length(missing_vars) > 0) {
      stop("Missing configuration variables: ", paste(missing_vars, collapse = ", "))
    }
    
    # Create connection based on database type
    if (DB_TYPE == "mysql") {
      # Check if RMySQL package is available
      if (!requireNamespace("RMySQL", quietly = TRUE)) {
        stop("RMySQL package not installed. Install with: install.packages('RMySQL')")
      }
      
      con <- dbConnect(RMySQL::MySQL(), 
                       host = DB_HOST, 
                       dbname = DB_NAME, 
                       username = DB_USER, 
                       password = DB_PASSWORD, 
                       port = DB_PORT)
      
    } else if (DB_TYPE == "mariadb") {
      # Check if RMariaDB package is available
      if (!requireNamespace("RMariaDB", quietly = TRUE)) {
        stop("RMariaDB package not installed. Install with: install.packages('RMariaDB')")
      }
      
      con <- dbConnect(RMariaDB::MariaDB(), 
                       host = DB_HOST, 
                       dbname = DB_NAME, 
                       username = DB_USER, 
                       password = DB_PASSWORD, 
                       port = DB_PORT)
      
    } else {
      stop("Unsupported database type: ", DB_TYPE, ". Supported types: 'mysql', 'mariadb'")
    }
    
    # Test the connection
    if (!dbIsValid(con)) {
      stop("Database connection failed validation")
    }
    
    # cat("✅ Successfully connected to", DB_TYPE, "database at", DB_HOST, "\n")
    
    # Return connection object or auto-disconnect wrapper
    if (auto_disconnect) {
      # Return connection with auto-disconnect function
      return(list(
        con = con,
        disconnect = function() {
          if (dbIsValid(con)) {
            dbDisconnect(con)
            # cat("🔌 Database connection closed (", connection_name, ")\n")
          }
        },
        # Convenience method for running queries with auto-cleanup
        query = function(sql) {
          tryCatch({
            result <- dbGetQuery(con, sql)
            return(result)
          }, error = function(e) {
            cat("❌ Query error:", e$message, "\n")
            return(NULL)
          })
        }
      ))
    } else {
      return(con)
    }
    
  }, error = function(e) {
    cat("❌ Database connection failed (", connection_name, "):", e$message, "\n")
    cat("   Check database configuration variables:\n")
    cat("   - DB_TYPE:", if(exists("DB_TYPE")) DB_TYPE else "NOT SET", "\n")
    cat("   - DB_HOST:", if(exists("DB_HOST")) DB_HOST else "NOT SET", "\n")
    cat("   - DB_NAME:", if(exists("DB_NAME")) DB_NAME else "NOT SET", "\n")
    cat("   - DB_USER:", if(exists("DB_USER")) DB_USER else "NOT SET", "\n")
    cat("   - DB_PORT:", if(exists("DB_PORT")) DB_PORT else "NOT SET", "\n")
    return(NULL)
  })
}

    # =========================================================================
    # HELPER 1B: WRAPPER FUNCTIONS
    # =========================================================================

# Quick query with automatic connection management
sql_query <- function(query_sql, connection_name = "query") {
  
  #Execute a SQL query with automatic connection management.
  #Perfect for one-off queries without managing connections manually.
  
  db_wrapper <- create_sql_connection(auto_disconnect = TRUE, connection_name = connection_name)
  
  if (is.null(db_wrapper)) {
    return(NULL)
  }
  
  result <- db_wrapper$query(query_sql)
  db_wrapper$disconnect()
  
  return(result)
}

# Test database connection (useful for debugging)
test_sql_connection <- function() {
  
  #Test database connection and return basic information.
  cat("🧪 Testing SQL connection...\n")
  
  con <- create_sql_connection(connection_name = "test")
  if (is.null(con)) {
    return(FALSE)
  }
  
  tryCatch({
    # Get database version and basic info
    if (DB_TYPE == "mysql") {
      version_info <- dbGetQuery(con, "SELECT VERSION() as version")
    } else if (DB_TYPE == "mariadb") {
      version_info <- dbGetQuery(con, "SELECT VERSION() as version")
    }
    
    # Check if main table exists
    table_exists <- dbExistsTable(con, DB_TABLE)
    
    if (table_exists) {
      # Get record count
      count_query <- paste0("SELECT COUNT(*) as total FROM ", DB_TABLE)
      record_count <- dbGetQuery(con, count_query)
      
      # Get date range
      date_range_query <- paste0("SELECT MIN(date) as earliest, MAX(date) as latest FROM ", DB_TABLE)
      date_range <- dbGetQuery(con, date_range_query)
    }
    
    # Display results
    cat("✅ Database connection test successful!\n")
    cat("   Database version:", version_info$version, "\n")
    cat("   Main table (", DB_TABLE, "):", if(table_exists) "EXISTS" else "NOT FOUND", "\n")
    
    if (table_exists) {
      cat("   Total records:", record_count$total, "\n")
      cat("   Date range:", date_range$earliest, "to", date_range$latest, "\n")
    }
    
    dbDisconnect(con)
    return(TRUE)
    
  }, error = function(e) {
    cat("❌ Connection test failed:", e$message, "\n")
    if (dbIsValid(con)) dbDisconnect(con)
    return(FALSE)
  })
}

    # =========================================================================
    # HELPER FUNCTION 1: SQL CONNECTION USAGE EXAMPLES
    # =========================================================================

    # # Example 1: Basic connection (manual management)
    # con <- create_sql_connection(connection_name = "main_analysis")
    # data <- dbGetQuery(con, paste0("SELECT * FROM ", DB_TABLE, " LIMIT 10"))
    # dbDisconnect(con)

    # # Example 2: Auto-disconnect wrapper
    # db <- create_sql_connection(auto_disconnect = TRUE, connection_name = "auto_managed")
    # data <- db$query(paste0("SELECT * FROM ", DB_TABLE, " LIMIT 10"))
    # db$disconnect()  # Clean up

    # # Example 3: One-liner query (easiest)
    # data <- sql_query(paste0("SELECT * FROM ", DB_TABLE, " WHERE date = CURDATE()"))

    # # Example 4: Test connection
    # test_sql_connection()

    # =========================================================================
    # HELPER FUNCTION 2: GLOBAL NORMALIZATION
    # =========================================================================

normalize_for_sql_search <- function(text, wildcard = "%") {
  if (is.na(text) || text == "") return("")
  
  text <- tolower(text)
  text <- gsub("\\s+(and|&|\\+).*$", " ", text)
  text <- gsub("\\s+(feat|ft|featuring).*$", " ", text)
  text <- gsub("\\[.*?\\]|\\(.*?\\)|\\{.*?\\}", "" , text)
  text <- gsub("[^a-zA-Z0-9 ]", " ", text)
  text <- gsub("\\b(the|and|n)\\b", " ", text)
  text <- trimws(text)
  text <- gsub("\\s+", " ", text)
  text <- gsub(" ", wildcard, text, fixed = TRUE)
  
  return(text)
}

# =============================================================================
# HELPER 2: ENHANCED TRAINING DATA VALIDATION AGAINST AVAILABLE TRACKS
# =============================================================================

validate_training_data_against_available_tracks <- function(ai_training_data) {
  cat("📊 Validating training data against available track library...\n")
  
  if (is.null(ai_training_data) || nrow(ai_training_data) == 0) {
    cat("❌ No training data provided\n")
    return(ai_training_data)
  }
  
  original_count <- nrow(ai_training_data)
  
  # =============================================================================
  # GET AVAILABLE TRACKS FROM APPROPRIATE SOURCE
  # =============================================================================
  
  all_available <- get_available_tracks_for_validation()
  
  if (is.null(all_available) || nrow(all_available) == 0) {
    cat("❌ No available tracks found - cannot validate training data\n")
    return(ai_training_data)
  }
  
  cat(sprintf("📊 Loaded %d available tracks for validation\n", nrow(all_available)))
  
  # =============================================================================
  # NORMALIZE AND DEDUPLICATE
  # =============================================================================
  
  # Normalize everything in bulk using vectorized operations
  all_available$norm_artist <- sapply(all_available$artist, normalize_for_sql_search, ".*")
  all_available$norm_song <- sapply(all_available$song, normalize_for_sql_search, ".*")
  
  all_available <- all_available %>%
    distinct(norm_artist, norm_song, .keep_all = TRUE)
  
  ai_training_data$norm_artist <- sapply(ai_training_data$main_artist, normalize_for_sql_search, ".*")
  ai_training_data$norm_song <- sapply(ai_training_data$main_song, normalize_for_sql_search, ".*")
  
  cat(sprintf("📊 Normalized to %d unique available tracks\n", nrow(all_available)))
  
  # =============================================================================
  # VALIDATE TRAINING DATA TRACKS
  # =============================================================================
  
  removed_count <- 0
  
  # Create lookup using grepl (much faster than SQL)
  for (i in 1:nrow(ai_training_data)) {
    artist_matches <- grepl(ai_training_data$norm_artist[i], all_available$norm_artist)
    song_matches <- grepl(ai_training_data$norm_song[i], all_available$norm_song)
    
    if (!any(artist_matches & song_matches)) {
      # Track not found in available library - mark as unknown
      cat(sprintf("   ❌ Removing: %s - %s (not in library)\n", 
                  ai_training_data$main_artist[i], ai_training_data$main_song[i]))
      
      ai_training_data$main_artist[i] <- "Unknown"
      ai_training_data$main_song[i] <- "Unknown"
      removed_count <- removed_count + 1
    }
  }
  
  # Clean up temporary columns
  ai_training_data$norm_artist <- NULL
  ai_training_data$norm_song <- NULL
  
  # =============================================================================
  # SUMMARY REPORTING
  # =============================================================================
  
  final_valid_count <- sum(ai_training_data$main_artist != "Unknown")
  
  cat(sprintf("✅ Training data validation complete:\n"))
  cat(sprintf("   📊 Original tracks: %d\n", original_count))
  cat(sprintf("   ❌ Removed (not in library): %d\n", removed_count))
  cat(sprintf("   ✅ Valid tracks remaining: %d\n", final_valid_count))
  cat(sprintf("   💯 Validation rate: %.1f%%\n", (final_valid_count / original_count) * 100))
  
  if (removed_count > 0) {
    cat("   📝 Removed tracks likely from DJs' private collections\n")
  }
  
  return(ai_training_data)
}

# =============================================================================
# GET AVAILABLE TRACKS FROM APPROPRIATE SOURCE
# =============================================================================

get_available_tracks_for_validation <- function() {
  
  # Determine which system to query
  if (!exists("PLAYOUT_SYSTEM")) {
    cat("⚠️ PLAYOUT_SYSTEM not configured, defaulting to local database\n")
    playout_system <- "LOCAL"
  } else {
    playout_system <- PLAYOUT_SYSTEM
  }
  
  tryCatch({
    if (playout_system == "LOCAL") {
      return(get_local_available_tracks())
    } else {
      return(get_playout_available_tracks(playout_system))
    }
  }, error = function(e) {
    cat(sprintf("❌ Error getting available tracks from %s: %s\n", playout_system, e$message))
    
    # Fallback to local if external system fails
    if (playout_system != "LOCAL") {
      cat("   Falling back to local database...\n")
      return(get_local_available_tracks())
    } else {
      return(NULL)
    }
  })
}

# =============================================================================
# GET TRACKS FROM LOCAL DATABASE
# =============================================================================

get_local_available_tracks <- function() {
  cat("📊 Loading available tracks from local database...\n")
  
  con <- create_sql_connection()
  
  # Get ALL available tracks once
  all_available <- dbGetQuery(con, "SELECT artist, song FROM available_tracks WHERE song NOT LIKE '%intro%' AND song NOT LIKE '%prelude%' AND song NOT LIKE '%outro%' AND song NOT LIKE '%interlude%'")
  
  dbDisconnect(con)
  
  return(all_available)
}

# =============================================================================
# GET TRACKS FROM PLAYOUT SYSTEM
# =============================================================================

get_playout_available_tracks <- function(playout_system) {
  cat(sprintf("📊 Loading available tracks from %s playout system...\n", playout_system))
  
  con <- create_playout_connection()
  
  # Query based on playout system type
  all_available <- switch(playout_system,
                          "ZETTA" = get_zetta_available_tracks(con),
                          "WIDEORBIT" = get_wideorbit_available_tracks(con),
                          "ENCO_DAD" = get_enco_available_tracks(con),
                          "RADIOMAN" = get_radioman_available_tracks(con),
                          {
                            cat(sprintf("❌ Unknown playout system: %s\n", playout_system))
                            return(NULL)
                          }
  )
  
  dbDisconnect(con)
  
  return(all_available)
}

# =============================================================================
# PLAYOUT SYSTEM SPECIFIC TRACK LISTING QUERIES
# =============================================================================

get_zetta_available_tracks <- function(con) {
  query <- "
    SELECT DISTINCT
      s.Artist as artist,
      s.Title as song
    FROM Songs s
    JOIN AudioFiles af ON s.SongID = af.SongID
    WHERE s.Artist IS NOT NULL 
      AND s.Title IS NOT NULL
      AND s.Artist != ''
      AND s.Title != ''
      AND af.FileName IS NOT NULL
      AND s.Title NOT LIKE '%intro%'
      AND s.Title NOT LIKE '%prelude%'
      AND s.Title NOT LIKE '%outro%'
      AND s.Title NOT LIKE '%interlude%'
    ORDER BY s.Artist, s.Title
  "
  
  return(dbGetQuery(con, query))
}

get_wideorbit_available_tracks <- function(con) {
  query <- "
    SELECT DISTINCT
      Artist as artist,
      Title as song
    FROM MusicLibrary
    WHERE Artist IS NOT NULL 
      AND Title IS NOT NULL
      AND Artist != ''
      AND Title != ''
      AND FileName IS NOT NULL
      AND Title NOT LIKE '%intro%'
      AND Title NOT LIKE '%prelude%'
      AND Title NOT LIKE '%outro%'
      AND Title NOT LIKE '%interlude%'
    ORDER BY Artist, Title
  "
  
  return(dbGetQuery(con, query))
}

get_enco_available_tracks <- function(con) {
  query <- "
    SELECT DISTINCT
      Artist as artist,
      Title as song
    FROM AudioLibrary
    WHERE Artist IS NOT NULL 
      AND Title IS NOT NULL
      AND Artist != ''
      AND Title != ''
      AND FileName IS NOT NULL
      AND Title NOT LIKE '%intro%'
      AND Title NOT LIKE '%prelude%'
      AND Title NOT LIKE '%outro%'
      AND Title NOT LIKE '%interlude%'
    ORDER BY Artist, Title
  "
  
  return(dbGetQuery(con, query))
}

get_radioman_available_tracks <- function(con) {
  query <- "
    SELECT DISTINCT
      Artist as artist,
      Title as song
    FROM Tracks
    WHERE Artist IS NOT NULL 
      AND Title IS NOT NULL
      AND Artist != ''
      AND Title != ''
      AND Filename IS NOT NULL
      AND Title NOT LIKE '%intro%'
      AND Title NOT LIKE '%prelude%'
      AND Title NOT LIKE '%outro%'
      AND Title NOT LIKE '%interlude%'
    ORDER BY Artist, Title
  "
  
  return(dbGetQuery(con, query))
}

# =============================================================================
# M3U PLAYLIST GENERATION
# =============================================================================

create_m3u_playlist <- function(result, playlist_name = NULL, include_intros = TRUE) {
  cat("🎵 Creating M3U playlist from Radio Intel AI result...\n")
  
  if (is.null(result) || is.null(result$complete_block)) {
    cat("❌ No valid result provided\n")
    return(NULL)
  }
  
  # Generate playlist filename if not provided
  if (is.null(playlist_name)) {
    timestamp <- format(Sys.time(), "%Y%m%d_%H%M%S")
    playlist_name <- sprintf("radio_intel_ai_%s_%s.m3u", AI_RUNTIME_MODE, timestamp)
  }
  
  # Ensure .m3u extension
  if (!grepl("\\.m3u$", playlist_name, ignore.case = TRUE)) {
    playlist_name <- paste0(playlist_name, ".m3u")
  }
  
  playlist_path <- file.path(TTS_OUTPUT_DIR, playlist_name)
  
  # Create directory if it doesn't exist
  output_dir <- dirname(playlist_path)
  if (!dir.exists(output_dir)) {
    dir.create(output_dir, recursive = TRUE)
    cat(sprintf("📁 Created directory: %s\n", output_dir))
  }
  
  # Extract tracks and file paths from complete_block
  playlist_entries <- extract_playlist_entries(result$complete_block, include_intros)
  
  if (length(playlist_entries) == 0) {
    cat("❌ No playable entries found in result\n")
    return(NULL)
  }
  
  # Write M3U file
  write_m3u_file(playlist_path, playlist_entries, result)
  
  cat(sprintf("✅ M3U playlist created: %s\n", playlist_name))
  cat(sprintf("📂 Full path: %s\n", playlist_path))
  cat(sprintf("🎵 Contains %d entries\n", length(playlist_entries)))
  
  return(playlist_path)
}

# =============================================================================
# EXTRACT PLAYLIST ENTRIES FROM COMPLETE BLOCK
# =============================================================================

extract_playlist_entries <- function(complete_block, include_intros) {
  playlist_entries <- list()
  
  for (element in complete_block) {
    if (element$type == "track") {
      # Use the SAME field names as display_complete_block()
      track_entry <- list(
        type = "track",
        file_path = element$track_file_path,               # Same as display
        title = sprintf("%s - %s", element$artist, element$song),  # Same as display
        duration = element$track_duration,                # Using track_duration like display
        genre = element$main_genre,                      # Same as display
        ai_score = element$fuzzy_dj_score                # Same as display
      )
      playlist_entries <- append(playlist_entries, list(track_entry))
      
    } else if (element$type == "intro" && include_intros) {
      # Use the SAME field names as display_complete_block()
      intro_entry <- list(
        type = "intro",
        file_path = element$intro_full_path,             # Same as display
        title = sprintf("Intro: %s - %s", element$artist, element$song),  # Same as display
        duration = element$intro_duration,               # Same as display
        genre = "Spoken",
        ai_score = NA
      )
      playlist_entries <- append(playlist_entries, list(intro_entry))
      
    } else if (element$type == "filler" && include_intros) {
      # Use the SAME field names as display_complete_block()
      filler_entry <- list(
        type = "filler",
        file_path = element$filler_audio$full_path,      # Same as display
        title = sprintf("DJ Filler: %s", substr(element$content, 1, 50)),  # Same as display
        duration = element$duration,                     # Same as display
        genre = "Spoken",
        ai_score = NA
      )
      playlist_entries <- append(playlist_entries, list(filler_entry))
    }
  }
  
  return(playlist_entries)
}

# =============================================================================
# WRITE M3U FILE
# =============================================================================

write_m3u_file <- function(playlist_path, playlist_entries, result) {
  
  # Create directory if it doesn't exist
  output_dir <- dirname(playlist_path)
  if (!dir.exists(output_dir)) {
    dir.create(output_dir, recursive = TRUE)
    cat(sprintf("📁 Created directory: %s\n", output_dir))
  }
  
  # Open file for writing
  con <- file(playlist_path, "w")
  
  tryCatch({
    # Write M3U header
    writeLines("#EXTM3U", con)
    writeLines(sprintf("# Generated by Radio Intel AI (%s mode) on %s", 
                       AI_RUNTIME_MODE, format(Sys.time(), "%Y-%m-%d %H:%M:%S")), con)
    
    # Add timing summary for timing mode - FIX THE SAPPLY ISSUE
    if (AI_RUNTIME_MODE == "timing" && !is.null(result$final_gap)) {
      # CRITICAL FIX: Use unlist() to ensure we get a numeric vector, not a list
      durations <- unlist(lapply(playlist_entries, function(x) {
        if (is.null(x$duration)) return(0)
        if (is.list(x$duration)) return(as.numeric(x$duration[[1]]))
        return(as.numeric(x$duration))
      }))
      
      total_duration <- sum(durations, na.rm = TRUE)
      
      # Safely convert result$final_gap to numeric
      final_gap_numeric <- if(is.list(result$final_gap)) {
        as.numeric(result$final_gap[[1]])
      } else {
        as.numeric(result$final_gap)
      }
      
      # Only write the line if we have valid numeric values
      if (is.finite(total_duration) && is.finite(final_gap_numeric)) {
        writeLines(sprintf("# Block duration: %.1f minutes, Gap: %.1fs", 
                           total_duration / 60, final_gap_numeric), con)
      }
    }
    
    writeLines("", con)  # Blank line
    
    # Write entries with better error handling
    for (i in 1:length(playlist_entries)) {
      entry <- playlist_entries[[i]]
      
      # Safely extract values with proper type checking
      duration <- if(is.null(entry$duration)) {
        0 
      } else if(is.list(entry$duration)) {
        as.numeric(entry$duration[[1]])
      } else {
        as.numeric(entry$duration)
      }
      
      title <- if(is.null(entry$title)) {
        "Unknown" 
      } else if(is.list(entry$title)) {
        as.character(entry$title[[1]])
      } else {
        as.character(entry$title)
      }
      
      file_path <- if(is.null(entry$file_path)) {
        "" 
      } else if(is.list(entry$file_path)) {
        as.character(entry$file_path[[1]])
      } else {
        as.character(entry$file_path)
      }
      
      # Write EXTINF line with duration and title (only if duration is valid)
      if (is.finite(duration) && !is.na(duration)) {
        extinf_line <- sprintf("#EXTINF:%.0f,%s", duration, title)
        writeLines(extinf_line, con)
      } else {
        # Fallback if duration is invalid
        extinf_line <- sprintf("#EXTINF:0,%s", title)
        writeLines(extinf_line, con)
      }
      
      # Write file path
      normalized_path <- normalize_path_for_playlist(file_path)
      writeLines(normalized_path, con)
      
      # Optional: Add genre/comment info with type checking
      if (!is.null(entry$genre) && !is.na(entry$genre)) {
        genre_val <- if(is.list(entry$genre)) {
          as.character(entry$genre[[1]])
        } else {
          as.character(entry$genre)
        }
        writeLines(sprintf("# Genre: %s", genre_val), con)
      }
      
      if (!is.null(entry$ai_score) && !is.na(entry$ai_score)) {
        ai_score_val <- if(is.list(entry$ai_score)) {
          as.numeric(entry$ai_score[[1]])
        } else {
          as.numeric(entry$ai_score)
        }
        if (is.finite(ai_score_val) && !is.na(ai_score_val)) {
          writeLines(sprintf("# AI Score: %.3f", ai_score_val), con)
        }
      }
      
      writeLines("", con)  # Blank line between entries
    }
    
  }, finally = {
    close(con)
  })
}

# =============================================================================
# PATH NORMALIZATION FOR PLAYLISTS
# =============================================================================

normalize_path_for_playlist <- function(file_path) {
  if (is.null(file_path) || is.na(file_path)) {
    return("")
  }
  
  # Convert to absolute path if relative
  if (!file.exists(file_path)) {
    cat(sprintf("⚠️ Warning: File not found: %s\n", file_path))
  }
  
  # Normalize path separators for the current OS
  normalized_path <- normalizePath(file_path, mustWork = FALSE)
  
  return(normalized_path)
}

# =============================================================================
# CONVENIENCE FUNCTIONS
# =============================================================================

# Create music-only playlist (no intros/fillers)
create_music_only_playlist <- function(result, playlist_name = NULL) {
  return(create_m3u_playlist(result, playlist_name, include_intros = FALSE))
}

# Create complete playlist with intros and fillers
create_complete_playlist <- function(result, playlist_name = NULL) {
  return(create_m3u_playlist(result, playlist_name, include_intros = TRUE))
}

# =============================================================================
# INITIALIZATION
# =============================================================================

cat("🤖🎙️ AI DJ SELECTION & TTS SYSTEM LOADED! 🎙️🤖\n\n")
cat("⚙️ Configuration:\n")
cat(sprintf("  • TTS Enabled: %s\n", TTS_ENABLED))
cat(sprintf("  • TTS Service: %s\n", TTS_SERVICE))
cat(sprintf("  • Output Directory: %s\n", TTS_OUTPUT_DIR))
if (TTS_SERVICE == "amazon") {
  cat(sprintf("  • Voice: %s\n", AMAZON_TTS_VOICE))
} else {
  cat(sprintf("  • Voice: %s\n", GOOGLE_TTS_VOICE))
}

main_menu <- paste0("\n🚀 QUICK START: \n
  Reports:
    1) Generate statistical PDF report:                 report()
    2) View curent context (Full):                      context_full()
    3) View curent context (Summary):                   context_short()
    4) List artist connections:                         artist_links(number)
    5) List introduction styles:                        styles() \n

  AI Model Maintenance:
    1) Train AI model:                                  train_ai()
    2) Update the AI's context                          update_context()
       (usually automatic):
    3) Update the main statistics                       update_stats()
       (usually automatic): \n

  Utilities:
    1) Scan music library                               scan_music()
       (WARNING! May take hours. Requires ffmpeg):
    2) Time all generic links,                          benchmark()
       intros/outros, and idents:
    3) Validate system configuration:                   validate_config()
    4) Check intro system status:                       check_intro_system()
    5) Add artist connection:                           add_link(\"artist 1\", \"artist 2\", \"note (optional)\")
    6) Remove artist connection:                        remove_link(\"artist 1\", \"artist 2\")
    7) Generate introduction:                           generate(\"artist\", \"song\", \"style (optional)\")
    8) Remove old introductions:                        clean_introductions(days_old, \"style\") \n
    
  Database Queries:
    1) Are two artists connected?                       are_linked(\"artist 1\", \"artist 2\")
    2) Do two names \"fuzzy\" match?                      are_equivalent(\"name 1\", \"name 2\")
    3) Does introduction exist in database?             check_intro(\"artist\", \"song\") \n

  DJ Functions:
    1) Get suggestions on what to play next:            suggestions()
    2) Run AI DJ without time marks (Perpetual mode):   ai_dj()
    3) Run AI DJ with time marks (Broadcast mode):      ai_dj_timed() \n
    
  ** Return to this menu at any time by entering: help() ** \n
")

cat(main_menu)

# =============================================================================
# MAIN ENTRY POINTS FOR FUNCTION CALLS
# =============================================================================

# =========================================================================
# OPTION 1-1: GENERATE STATISTICAL REPORT
# =========================================================================

report <- function() {
  generate_report()
}

# =========================================================================
# OPTION 1-2: FULL CONTEXT REPORT
# =========================================================================

context_full <- function() {
  check_current_context()
}

# =========================================================================
# OPTION 1-3: SUMMARY CONTEXT REPORT
# =========================================================================

context_short <- function() {
  analyze_current_context()
  #current_context_status()
}

# =========================================================================
# OPTION 1-4: LIST ARTIST EQUIVALENCIES
# =========================================================================

artist_links <- function(n = 50) {
  list_artist_equivalencies(n)
}

# =========================================================================
# OPTION 2-1: TRAIN AI MODEL
# =========================================================================

train_ai <- function() {
  real_ai_system <<- build_real_ai()
}

# =========================================================================
# OPTION 2-2: UPDATE MODEL CONTEXT (Usually happens automatically)
# =========================================================================

update_context <- function() {
  refresh_current_context()
}

# =========================================================================
# OPTION 2-3: UPDATE MAIN STATISTICS (Usually happens automatically)
# =========================================================================

update_stats <- function() {
  update_statistics(data)
}


# =========================================================================
# OPTION 3-1: SCAN MUSIC LIBRARY
# =========================================================================

scan_music <- function() {
  
}

# =========================================================================
# OPTION 3-2: SCAN MUSIC LIBRARY
# =========================================================================

benchmark <- function() {
  
}

# =========================================================================
# OPTION 3-3: VALIDATE SYSTEM CONFIGURATION
# =========================================================================

validate_config <- function() {
  validate_intro_system_config()
}

# =========================================================================
# OPTION 3-4: CHECK INTRO SYSTEM STATUS
# =========================================================================

check_intro_system <- function() {
  check_intro_system_status()
}

# =========================================================================
# OPTION 3-5: ADD ARTIST EQUIVALENCY
# =========================================================================

add_link <- function(artist1, artist2, notes = "") {
  add_artist_equivalency(artist1, artist2, notes)
}

# =========================================================================
# OPTION 3-6: REMOVE ARTIST EQUIVALENCY
# =========================================================================

remove_link <- function(artist1, artist2) {
  remove_artist_equivalency(artist1, artist2)
}

# =========================================================================
# OPTION 3-7: GENERATE INTRODUCTION
# =========================================================================

generate <- function(artist, song, style = "dry_witty_radio6") {
  generate_artist_intro(artist, song, intro_type = 1, number_intros = 3, style)
}

# =========================================================================
# OPTION 3-8: REMOVE OLD INTRODUCTIONS
# =========================================================================

clean_introductions <- function(days_old, style) {
  cleanup_old_intros(days_old, style)
}

# ======-==================================================================
# OPTION 4-1: ARE TWO ARTISTS EQUIVALENT?
# =========================================================================

are_linked <- function(artist1, artist2) {
  are_artists_equivalent(artist1, artist2)
}

# =========================================================================
# OPTION 4-2: DO TWO NAMES FUZZY MATCH?
# =========================================================================

are_equivalent <- function(name1, name2) {
  are_artists_fuzzy_equivalent(name1, name2)
}

# =========================================================================
# OPTION 4-3: DO TWO NAMES FUZZY MATCH?
# =========================================================================

check_intro <- function(artist, song) {
  check_intro_availability(artist, song)
}

# ======-==================================================================
# OPTION 5-1: DJ ASSISTANCE
# =========================================================================

suggestions <- function(n = 5) {
  AI_RUNTIME_MODE <<- "assistant"
  result <- run_radio_intel_ai()
}

# =========================================================================
# OPTION 5-2: FULLY AUTONOMOUS ML DJ WITHOUT TIME MARKS
# =========================================================================

ai_dj <- function() {
  AI_RUNTIME_MODE <<- "perpetual"
  result <- run_radio_intel_ai()
}

# =========================================================================
# OPTION 5-3: FULLY AUTONOMOUS ML DJ WITH TIME MARKS
# =========================================================================

ai_dj_timed <- function(minutes = TIME_MARK_BLOCK_LENGTH) {
  AI_RUNTIME_MODE <<- "timing"
  result <- run_radio_intel_ai()

    if (PLAYOUT_TARGET == "M3U") {
    playlist_path <- create_m3u_playlist(result, "my_radio_show_2025")
    }

}

# =========================================================================
# PRINT MAIN MENU
# =========================================================================

help <- function() {
  cat(main_menu)
}

menu <- function() {
  cat(main_menu)
}
