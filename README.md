# Radio Station Listener Analysis System

A comprehensive real-time analytics platform for online radio stations, providing detailed insights into listener behavior, music preferences, and show performance through automated data collection and sophisticated statistical analysis.

## 🎯 Overview

This system automatically monitors online radio streams every 5 minutes, collecting listener counts, track information, and show metadata. It enriches this data with weather information and musical genre classification from multiple APIs, then generates detailed PDF reports with over 50 different analyses and visualizations.

## 📊 Key Features

### Real-Time Data Collection
- **Automated monitoring** of Shoutcast/Icecast streams every 5 minutes
- **Multi-stream support** (AAC, MP3, multiple stations)
- **Weather correlation** using OpenWeatherMap API
- **Show scheduling integration** via JSON endpoints
- **Robust error handling** and retry mechanisms

### Music Intelligence
- **Automatic genre classification** using MusicBrainz, Last.fm, and Wikipedia APIs
- **Track-level categorization** (not just artist-level)
- **Duplicate detection** and data validation
- **Genre bias analysis** for individual presenters

### Advanced Analytics
- **Listener impact analysis** - which tracks/artists/genres attract or lose listeners
- **Show performance metrics** with statistical significance testing
- **DJ similarity scoring** compared to station averages
- **Temporal pattern analysis** (hourly, daily, seasonal trends)
- **Retention rate calculations** and audience flow analysis

### Comprehensive Reporting
- **50+ visualizations** including heatmaps, scatter plots, and trend analysis
- **Executive summary tables** for quick decision-making
- **Genre performance breakdowns** with confidence intervals
- **Comparative analysis** between different time periods
- **Professional PDF output** with LaTeX formatting

## 🛠 Technical Architecture

### Data Collection (PHP)
```
Shoutcast APIs → PHP Scraper → MariaDB/MySQL
      ↓
Weather APIs → Genre APIs → Scheduling APIs
```

### Analysis Engine (R)
```
Database → R Analytics → PDF Report
    ↓
Statistical Models → Visualizations → Executive Tables
```

## 📋 Requirements

### PHP Scraper
- PHP 7.4+ with cURL support
- MariaDB/MySQL 5.7+
- API keys for Last.fm and OpenWeatherMap (optional)
- Cron job or systemd timer capability

### R Analysis
- R 4.0+
- Required packages: `DBI`, `RMariaDB`, `dplyr`, `ggplot2`, `kableExtra`, `lubridate`, `tidyr`, `scales`, `rmarkdown`
- LaTeX distribution for PDF generation

## 🚀 Quick Start

### 1. Database Setup
```sql
-- Database and table creation is automatic
-- Just ensure your MySQL/MariaDB user has CREATE privileges
```

### 2. Configure PHP Scraper
```php
// Edit configuration section in scraper.php
$server = 'your-database-host';
$user = 'your-db-user';
$pass = 'your-db-password';
$db = 'your-database-name';

$lastfm_api_key = 'your-lastfm-key';  // Optional
$openweather_api_key = 'your-weather-key';  // Optional

// Update stream URLs for your station
$stream_url = 'http://your-shoutcast-server:port/status';
```

### 3. Set Up Automated Collection
```bash
# Add to crontab for 5-minute collection
*/5 * * * * /usr/bin/php /path/to/scraper.php >/dev/null 2>&1
```

### 4. Configure R Analysis
```r
# Edit configuration in analysis.R
DB_HOST <- "your-database-host"
DB_USER <- "your-db-user" 
DB_PASSWORD <- "your-db-password"
DB_NAME <- "your-database-name"

REPORT_TYPE <- "ALL"  # or "YYYY-MM" for specific month
```

### 5. Generate Reports
```r
# Run the R script
source("analysis.R")
# PDF report will be automatically generated
```

## 📈 Sample Analytics

### Listener Impact Analysis
- **Track Performance**: Which songs increase/decrease listener numbers
- **Artist Impact**: Most and least popular artists by audience retention
- **Genre Analysis**: Musical styles that attract or repel listeners
- **Temporal Patterns**: Best/worst performing time slots

### Show Performance Metrics
- **Retention Rates**: How well shows hold their audience
- **Comparative Analysis**: Performance vs. time slot averages
- **Presenter Insights**: Individual DJ performance metrics
- **Content Analysis**: Music diversity and genre preferences

### Advanced Visualizations
- **Performance Heatmaps**: Listener patterns by hour/day
- **Scatter Plot Analysis**: Performance vs. consistency
- **Trend Analysis**: Month-over-month comparisons
- **Impact Charts**: Visual representation of music effects

## 🔧 Customization

### Adding New Streams
Update the stream monitoring URLs in the PHP configuration section. The system supports multiple simultaneous streams.

### Custom Analysis Periods
```r
# Specific date range
START_DATE <- "2024-01-01"
END_DATE <- "2024-12-31"

# Single month focus
REPORT_TYPE <- "2024-06"

# All available data
REPORT_TYPE <- "ALL"
```

### Genre Classification
The system uses a fallback hierarchy:
1. **MusicBrainz** (most accurate)
2. **Last.fm** (comprehensive)
3. **Wikipedia** (fallback for artist-level genres)

## 📊 Report Outputs

### Executive Summary
- Top performing shows by category
- Best/worst tracks and artists
- Genre performance rankings
- Key performance indicators

### Detailed Analysis
- Hourly listener patterns
- Weather correlation analysis
- DJ music diversity scoring
- Statistical significance testing
- Confidence intervals and trend analysis

### Visual Analytics
- Over 30 charts and graphs
- Professional formatting
- Color-coded performance indicators
- Interactive-style legends and annotations

## 🤝 Contributing

This system was designed for flexibility and extensibility:

### Easy Modifications
- **New APIs**: Add additional music metadata sources
- **Custom Metrics**: Extend the analysis with domain-specific KPIs
- **Additional Streams**: Support for more radio stations
- **Enhanced Visualizations**: Add new chart types or styling

### Data Export Options
- Raw CSV export capabilities
- JSON API endpoints (easily added)
- Database views for external BI tools
- Custom report formatting

## 📝 License

GPL 3.0 - See LICENSE file for details

## 🎵 Use Cases

Perfect for:
- **Commercial Radio Stations** - Audience analysis and programming decisions
- **Internet Radio** - Content optimization and listener retention
- **Podcast Networks** - Performance tracking and trend analysis  
- **Music Research** - Academic studies on listener behavior
- **Broadcasting Consultants** - Data-driven programming advice

## 🔍 Data Privacy

- **No personal data collection** - Only aggregate listener counts
- **IP anonymization** - Unique listeners by IP without storage
- **GDPR compliant** - No personally identifiable information
- **Configurable retention** - Set your own data retention periods

## 📞 Support

For questions about implementation or customization, please open an issue with:
- Your radio platform (Shoutcast/Icecast version)
- Database configuration
- Sample of any error messages
- Description of your specific use case

---

*Built for radio professionals who believe in data-driven programming decisions. Transform your listener data into actionable insights.*
