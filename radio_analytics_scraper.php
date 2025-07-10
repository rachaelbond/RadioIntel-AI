<?php

/**
 * Radio Analytics Statistics Collector v:2.3
 *
 * (c) Rachael Bond, 2025
 *
 * Released under GPL 3.0
 *
 *	GPL 3.0 License:
 *	
 *	This program is free software: you can redistribute it and/or modify
 *	it under the terms of the GNU General Public License as published by
 *	the Free Software Foundation, either version 3 of the License, or
 *	any later version.
 *
 *	This program is distributed in the hope that it will be useful,
 *	but WITHOUT ANY WARRANTY; without even the implied warranty of
 *	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 *	GNU General Public License for more details.
 *
 *	You should have received a copy of the GNU General Public License
 *	along with this program. If not, see https://www.gnu.org/licenses/
 *
 * What's new in this release (2.3)?
 * 1. Improved statistics collection for comparison radio station that combines the figures for their multiple streams,
 *    and takes into account that they run an Icecast server rather than Shoutcast
 *
 * What's new in this release (2.2)?
 * 1. Now collects the data for 2 main stations, UK Public Holidays, the weather, and Sunrise/Set
 * 2. I really hate, and I cannot stress enough just how much I loathe, last.fm's API.
 *	Have implemented the MusicBrainz API as the primary genre source instead,
 *	falling back to last.fm and, then, Wikipedia if needed.
 *
 * What's new in this release (2.1)?
 * 1. Fixes bugs in the show information identification and decoding from the JSON programme file
 * 2. Attempts to scrape genre information from Wikipedia if last.fm draws a blank
 *
 * What's new in this relase (2.0)?
 * 1. Completely re-written code, with automatic SQL table creation and updating.
 * 2. Decodes the JSON programme information
 *	Hopefully, this means no more dodgy show and presenter data
 * 3. We now have separate `showname` and `presenter` SQL columns rather than just `dj`
 *	This is useful for certain shows where the performance of the individual presenters can now be compared
 * 4. From the JSON file we now know if a show is live ('0'), or pre-recorded ('1')
 * 5. Uses last.fm's API to try to get genre information for the now-playing track
 * 6. Implements modern, robust SQL connections and commands that, hopefully, prevent injection attacks
 *
 * To-Do (Possibly....)
 * 1. Implement some sort of school holidays API
 * 2. Implement a "major events" API
 *
 * Q&As:
 * 1. Why the hell is this written in PHP?
 *	Because C++ is a nightmare for JSON decoding and web-scraping
 *	It can be done, but life is short
 *	Also, PHP scripts just work and are easy to follow...
 *	    and I'm not talking people through how to edit and compile C++ code. Sorry
 * 2. Genre searches?
 *	The script checks SQL to see if we already have the song info and, if not,
 *	    tries to grab the genre from the MusicBrainz API (no API key needed)
 *	If MusicBrainz fails, the script then tries last.fm and, finally, Wikipedia (which might give a general band genre)
 *	If all those sources fail, we just accept defeat and go home
 *	For last.fm you need a free API key:
 *	    (a) Create a last.fm account at https://www.last.fm/join
 *	    (b) Go to https://www.last.fm/api and click on "Get an API account"
 *		A last.fm API key will be generated instantly
 *	If you don't want to use last.fm, leave $lastfm_api_key empty in the configuration section
 * 3. The weather? Seriously??
 *	Yeah, I know... talk about throwing the kitchen sink at things!
 *	But sure, why not? Grab a free API key from https://www.openweathermap.org
 *	If you're not bothered, just leave $openweather_api_key empty in the configuration section
 * 4. Which listening figures are used?
 *	If the Shoutcast server has both the overall number of listeners and the unique number (ie., with different IP addresses)
 *	then the data collected is for the unique number of listeners
 * 5. How do I analyse the data?
 *	Use the companion radio_analytics.R script. Simples. I couldn't make it any easier!
 *	This generates the pdf report.
 *	The script is for the *free* R statistics program, available for all o/s, from https://www.r-project.org/
 *	I strongly suggest using the desktop IDE r-studio rather than just the command line version of R
 *	Enter the SQL connection information at the top of the script,
 *	    and decide on the date range - leave as "ALL" for a cumulative report for all the SQL data.
 * 7. Why isn't the code neater?
 *	See above about life being short. It works. It's not untidy (everything is divided into functions),
 *	but there is probably code duplication over the different functions.
 *	Gimme a break... I've spent a stupid amount of time on this and am doing it for free.
 *	Does it really matter if I copy/pasted some code blocks? :-/
 *
 * CONFIGURATION:
 *
 * Fill in the info for these variables and create the SQL database
 * The code will then automatically create, or update, the SQL table as needed
 *
 * Probably worth setting $debug=true for the first few runs
 *
 * Run this script automatically with a systemd timer or as a cron job
 * I've been running it every 5 minutes :)
 *
 * Nothing else should need to be edited after this section
 *
 *********************************************************************************************************
 *
 * IMPORTANT!!! FOR DEVS:
 * 
 * 1. There are certain functions in the scraper that you're going to have to write your own code for.
 *        It's impossible to create a generalised schedule grabber, so those 2 functions are left empty.
 * 2. Similarly, you'll need to figure out how to determing whether a DJ is live or pre-recorded
 *        - if you're bothered about such things.
 * 3. The manually_fix_things() function can be used to sort out data inconsistencies on an ad-hoc basis.
 *
 *********************************************************************************************************
 */

$debug = false;

$server = '';
$user = '';
$pass = '';
$db = '';
$table = 'analytics';

$main_station_name = '';
$main_station_website = '';

$lastfm_api_key = '';
$lastfm_shared_secret = '';

$openweather_api_key = '';
$lat = ;
$lng = ;

$main_shoutcast_url_stream1 = '';
$main_shoutcast_url_stream2 = '';

$second_shoutcast_url_stream1 = '';
$second_shoutcast_url_stream2 = '';

$comparison_shoutcast_url = '';

$main_schedule_url = '';
$second_schedule_url = '';
$comparison_schedule_url = '';

/************************************************
 *
 * STOP EDITING!!!!
 * Seriously... just don't do it, mmm-kay???
 *
 ************************************************/

$code_version = '2.3';

// Set timezone
date_default_timezone_set('Europe/London');

// Current date/time
$date = date('Y-m-d');
$time = date('H:i');

/**
 * Check SQL database exists and create it if it doesn't
 */
function ensureTableExists($conn, $table, $debug = false) {
    // Check if the streams table exists
    $result = $conn->query("SHOW TABLES LIKE '".$table."'");
    
    if ($result->num_rows == 0) {
        // Table doesn't exist, create it with all new columns
        $create_sql = "
        CREATE TABLE `".$table."` (
            `stamp` int(11) NOT NULL AUTO_INCREMENT,
            `date` text COLLATE utf8mb4_unicode_ci NOT NULL,
            `time` varchar(5) COLLATE utf8mb4_unicode_ci NOT NULL,
            `main_stream1` int(11) DEFAULT NULL,
            `main_stream2` int(11) DEFAULT NULL,
            `main_showname` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
            `main_presenter` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
            `main_stand_in` tinyint(1) DEFAULT NULL,
            `main_recorded` tinyint(1) DEFAULT NULL,
            `main_artist` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
            `main_song` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
            `main_genre` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
            `second_stream1` int(11) DEFAULT NULL,
            `second_stream2` int(11) DEFAULT NULL,
            `second_showname` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
            `second_presenter` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
            `second_stand_in` tinyint(1) DEFAULT NULL,
            `second_recorded` tinyint(1) DEFAULT NULL,
            `second_artist` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
            `second_song` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
            `second_genre` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
            `comparison_stream` int(11) DEFAULT NULL,
            `comparison_showname` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
            `comparison_presenter` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
            `comparison_stand_in` tinyint(1) DEFAULT NULL,
            `comparison_recorded` tinyint(1) DEFAULT NULL,
            `comparison_artist` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
            `comparison_song` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
            `comparison_genre` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
            `public_holiday` tinyint(1) DEFAULT 0,
            `weather_temp` decimal(4,1) DEFAULT NULL,
            `weather_condition` varchar(50) DEFAULT NULL,
            `weather_rain` decimal(4,1) DEFAULT NULL,
            `major_event` varchar(100) DEFAULT NULL,
            `sunrise_time` time DEFAULT NULL,
            `sunset_time` time DEFAULT NULL,
            PRIMARY KEY (`stamp`),
            KEY `idx_date` (`date`(20)),
            KEY `idx_main_artist` (`main_artist`),
            KEY `idx_main_song` (`main_song`),
            KEY `idx_main_artist_song` (`main_artist`, `main_song`),
            KEY `idx_main_genre` (`main_genre`),
            KEY `idx_main_showname` (`main_showname`),
            KEY `idx_main_dj` (`main_presenter`),
            KEY `idx_second_artist` (`second_artist`),
            KEY `idx_second_song` (`second_song`),
            KEY `idx_second_artist_song` (`second_artist`, `second_song`),
            KEY `idx_second_genre` (`second_genre`),
            KEY `idx_second_showname` (`second_showname`),
            KEY `idx_second_dj` (`second_presenter`),
            KEY `idx_public_holiday` (`public_holiday`),
            KEY `idx_weather` (`weather_condition`),
            KEY `idx_date_time` (`date`(10), `time`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
        ";
        
        if ($conn->query($create_sql)) {
            if ($debug) {
                error_log("Created analytics table with enhanced schema successfully");
            }
        } else {
            if ($debug) {
                throw new Exception("Error creating analytics table: " . $conn->error);
            }
        }
    } else {
        // Table exists, check if all required columns exist and add them if missing
        checkAndAddMissingColumns($conn, $table, $debug);
    }
}

function checkAndAddMissingColumns($conn, $table, $debug) {
    // Get current table structure
    $result = $conn->query("DESCRIBE ".$table);
    $existing_columns = [];
    
    while ($row = $result->fetch_assoc()) {
        $existing_columns[] = $row['Field'];
    }
    
    // Define ALL required columns with their definitions (including new ones)
    $required_columns = [
        'stamp' => 'int(11) NOT NULL AUTO_INCREMENT PRIMARY KEY',
        'date' => 'text COLLATE utf8mb4_unicode_ci NOT NULL',
        'time' => 'varchar(5) COLLATE utf8mb4_unicode_ci NOT NULL',
        'main_stream1' => 'int(11) DEFAULT NULL',
        'main_stream2' => 'int(11) DEFAULT NULL',
        'main_showname' => 'varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL',
        'main_presenter' => 'varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL',
        'main_stand_in' => 'tinyint(1) DEFAULT NULL',
        'main_recorded' => 'tinyint(1) DEFAULT NULL',
        'main_artist' => 'varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL',
        'main_song' => 'varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL',
        'main_genre' => 'varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL',
        'second_stream1' => 'int(11) DEFAULT NULL',
        'second_stream2' => 'int(11) DEFAULT NULL',
        'second_showname' => 'varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL',
        'second_presenter' => 'varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL',
        'second_stand_in' => 'tinyint(1) DEFAULT NULL',
        'second_recorded' => 'tinyint(1) DEFAULT NULL',
        'second_artist' => 'varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL',
        'second_song' => 'varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL',
        'second_genre' => 'varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL',
        'comparison_stream' => 'int(11) DEFAULT NULL',
        'comparison_showname' => 'varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL',
        'comparison_presenter' => 'varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL',
        'comparison_stand_in' => 'tinyint(1) DEFAULT NULL',
        'comparison_recorded' => 'tinyint(1) DEFAULT NULL',
        'comparison_artist' => 'varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL',
        'comparison_song' => 'varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL',
        'comparison_genre' => 'varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL',
        'public_holiday' => 'tinyint(1) DEFAULT 0',
        'weather_temp' => 'decimal(4,1) DEFAULT NULL',
        'weather_condition' => 'varchar(50) DEFAULT NULL',
        'weather_rain' => 'decimal(4,1) DEFAULT NULL',
        'major_event' => 'varchar(100) DEFAULT NULL',  // NEW - Sports/cultural events
        'sunrise_time' => 'time DEFAULT NULL',
        'sunset_time' => 'time DEFAULT NULL'
    ];
    
    // Check each required column
    foreach ($required_columns as $column => $definition) {
        if (!in_array($column, $existing_columns)) {
            // Column is missing, add it
            if ($column === 'stamp') {
                continue; // Skip stamp as it should already exist
            }
            
            $alter_sql = "ALTER TABLE ".$table." ADD COLUMN `{$column}` {$definition}";
            
            if ($conn->query($alter_sql)) {
                if ($debug) {
                    error_log("Added missing column: {$column}");
                }
            } else {
                if ($debug) {
                    error_log("Error adding column {$column}: " . $conn->error);
                }
            }
        }
    }
    
    // Check and add new indexes
    addMissingIndexes($conn, $table, $debug);
}

function addMissingIndexes($conn, $table, $debug) {
    // Get existing indexes
    $result = $conn->query("SHOW INDEX FROM ".$table);
    $existing_indexes = [];
    
    while ($row = $result->fetch_assoc()) {
        $existing_indexes[] = $row['Key_name'];
    }

    // Define required indexes (including new ones)
    $required_indexes = [
        'idx_date' => 'CREATE INDEX idx_date ON '.$table.' (date(20))',
        'idx_main_artist' => 'CREATE INDEX idx_main_artist ON '.$table.' (main_artist)',
        'idx_main_song' => 'CREATE INDEX idx_main_song ON '.$table.' (main_song)',
        'idx_main_artist_song' => 'CREATE INDEX idx_main_artist_song ON '.$table.' (main_artist, main_song)',
        'idx_main_genre' => 'CREATE INDEX idx_main_genre ON '.$table.' (main_genre)',
        'idx_main_showname' => 'CREATE INDEX idx_main_ahowname ON '.$table.' (main_showname)',
        'idx_main_dj' => 'CREATE INDEX idx_main_dj ON '.$table.' (main_presenter)',
        'idx_second_artist' => 'CREATE INDEX idx_second_artist ON '.$table.' (second_artist)',
        'idx_second_song' => 'CREATE INDEX idx_second_song ON '.$table.' (second_song)',
        'idx_second_artist_song' => 'CREATE INDEX idx_second_artist_song ON '.$table.' (second_artist, second_song)',
        'idx_second_genre' => 'CREATE INDEX idx_second_genre ON '.$table.' (second_genre)',
        'idx_second_showname' => 'CREATE INDEX idx_second_ahowname ON '.$table.' (second_showname)',
        'idx_second_dj' => 'CREATE INDEX idx_second_dj ON '.$table.' (second_presenter)',
        'idx_public_holiday' => 'CREATE INDEX idx_public_holiday ON '.$table.' (public_holiday)',
        'idx_weather' => 'CREATE INDEX idx_weather ON '.$table.' (weather_condition)',
        'idx_date_time' => 'CREATE INDEX idx_date_time ON '.$table.' (date(10), time)'
    ];
    
    foreach ($required_indexes as $index_name => $create_sql) {
        if (!in_array($index_name, $existing_indexes)) {
            if ($conn->query($create_sql)) {
                if ($debug) {
                    error_log("Added missing index: {$index_name}");
                }
            } else {
                if ($debug) {
                    error_log("Could not add index {$index_name}: " . $conn->error);
                }
            }
        }
    }
}

/**
 * Generalized function to grab Shoutcast/Icecast listener numbers and now-playing track
 * Handles all Shoutcast/Icecast server types and automatically sums multiple streams
 */
function getStreamStats($url, $debug = false) {
    $stats = [
        'listeners' => 0,
        'track' => null,
        'status' => 'offline'
    ];
    $processed_flag = 0;
    
    if (empty($url)) {
        return $stats;
    }
    
    $html = getWebPage($url);
    if (!$html) {
        if ($debug) {
            echo "Failed to fetch page\n";
        }
        return $stats;
    }
    
    if ($debug) {
        echo "Processing URL: {$url}\n";
    }
    
    // Try JSON API first (but not for .xsl status pages)
    if (!strpos($url, '.xsl')) {
        $json_url = str_replace('/index.html', '/stats?json=1', $url);
        if ($debug) echo "Trying JSON API: {$json_url}\n";
        
        $json_data = @file_get_contents($json_url);
        if ($json_data !== false) {
            $data = json_decode($json_data, true);
            if ($data && isset($data['currentlisteners'])) {
                $stats['listeners'] = (int)$data['currentlisteners'];
                $stats['track'] = isset($data['songtitle']) && !empty(trim($data['songtitle'])) ? 
                                 substr(trim($data['songtitle']), 0, 90) : null;
                $stats['status'] = 'online';
                
                if ($debug) {
                    echo "JSON API success: {$stats['listeners']} listeners\n";
                }
                $processed_flag = 1;
            }
        }
        if ($debug && $processed_flag == 0) echo "JSON API failed or returned no data\n";
        
	if ($processed_flag == 0) {
        // Try XML API
        $xml_url = str_replace('/index.html', '/stats', $url);
        if ($debug) echo "Trying XML API: {$xml_url}\n";
        
        $xml_data = @file_get_contents($xml_url);
        if ($xml_data !== false) {
            $xml = @simplexml_load_string($xml_data);
            if ($xml && isset($xml->CURRENTLISTENERS)) {
                $stats['listeners'] = (int)$xml->CURRENTLISTENERS;
                $stats['track'] = isset($xml->SONGTITLE) && !empty(trim((string)$xml->SONGTITLE)) ? 
                                 substr(trim((string)$xml->SONGTITLE), 0, 90) : null;
                $stats['status'] = 'online';
                
                if ($debug) {
                    echo "XML API success: {$stats['listeners']} listeners\n";
                }
                $processed_flag = 1;
            }
        }
	}
        if ($debug && $processed_flag == 0) echo "XML API failed or returned no data\n";
    }
    
    // Fall back to HTML parsing
    if ($debug && $processed_flag == 0) {
        echo "HTML length: " . strlen($html) . " chars\n";
    }
    
    if ($processed_flag == 0) {
    $listeners = 0;
    
    // First: Check for multi-stream Icecast pages and sum all streams
    if (strpos($url, '.xsl') !== false) {
        if ($debug) echo "Detected Icecast status page - checking for multiple streams\n";
        
        // Method 1: Look for multiple "Current Listeners" entries and sum them
        if (preg_match_all('/Current Listeners:\s*<[^>]*>\s*(\d+)\s*</', $html, $matches)) {
            $total_listeners = 0;
            foreach ($matches[1] as $stream_listeners) {
                $stream_count = (int)$stream_listeners;
                // Filter out obvious non-listener numbers (bitrates, etc.)
                if ($stream_count > 0 && $stream_count < 1000) {
                    $total_listeners += $stream_count;
                    if ($debug) {
                        echo "Found stream with {$stream_count} listeners\n";
                    }
                }
            }
            if ($total_listeners > 0) {
                $listeners = $total_listeners;
                if ($debug) {
                    echo "Total Icecast listeners (method 1): {$listeners}\n";
                }
            }
        }
        
        // Method 2: Use a table-based extraction pattern
        if ($listeners == 0) {
            if ($debug) echo "Trying table-based extraction\n";
            
            $bitrates = ['256', '128', '64', '32'];
            $total_listeners = 0;
            foreach ($bitrates as $bitrate) {
                $pattern = '/<td class="streamdata">' . $bitrate . '<\/td><\/tr><tr><td>Current Listeners:<\/td><td class="streamdata">(\d+)<\/td>/';
                if (preg_match($pattern, $html, $matches)) {
                    $listeners_count = (int)$matches[1];
                    $total_listeners += $listeners_count;
                    if ($debug) {
                        echo "Found {$bitrate}kbps stream with {$listeners_count} listeners\n";
                    }
                }
            }
            if ($total_listeners > 0) {
                $listeners = $total_listeners;
                if ($debug) {
                    echo "Total Icecast listeners (method 2): {$listeners}\n";
                }
            }
        }
        
        // If the above patterns didn't work, try alternative Icecast patterns
        if ($listeners == 0) {
            if ($debug) echo "Trying alternative Icecast patterns\n";
            
            // Debug: show what Current Listeners entries we can find
            if ($debug && preg_match_all('/Current Listeners/i', $html, $debug_matches)) {
                echo "Found " . count($debug_matches[0]) . " 'Current Listeners' text occurrences\n";
                // Show some context around each match
                $pos = 0;
                for ($i = 0; $i < min(3, count($debug_matches[0])); $i++) {
                    $pos = strpos($html, 'Current Listeners', $pos);
                    if ($pos !== false) {
                        $context = substr($html, max(0, $pos-50), 150);
                        echo "Context " . ($i+1) . ": " . htmlspecialchars($context) . "\n";
                        $pos += 10;
                    }
                }
            }
        }
    }
    
    // Second: If no multi-stream found, use single-stream patterns
    if ($listeners == 0) {
        $patterns = [
            // Try to get unique listeners from Shoutcast first!
            // This handles "listeners (45 of 5000)" format by taking the first number (45)
            '/listeners\s*\(\s*(\d+)(?:\s|$)/',
            
            // Prioritize UNIQUE listeners over total listeners for Shoutcast
            '/(\d+)\s*unique listeners?/i',
            
            // Specific unique listener patterns
            '/Stream is up[^>]*with (\d+) of \d+ listeners/i',
            '/(\d+) of \d+ listeners/i',
            
            // Standard Shoutcast formats
            '/(\d+)\s*listeners?\s*\(/',
            '/Current Listeners:\s*(\d+)/i',
            '/Listeners:\s*(\d+)/i',
            
            // Alternative formats
            '/Stream is up.*?(\d+).*?listener/is',
            '/Status.*?(\d+).*?listener/is',
            '/Online.*?(\d+).*?listener/is',
            
            // Numbers followed by "listening" or similar
            '/(\d+)\s*(?:currently\s*)?listening/i',
            '/(\d+)\s*(?:people\s*)?tuned\s*in/i',
            '/(\d+)\s*connected/i',
            
            // Shoutcast v2 formats
            '/streamstatus[^>]*>.*?(\d+).*?<\/streamstatus>/is',
            '/listenercount[^>]*>(\d+)<\/listenercount>/i',
            
            // XML-style data
            '/<CURRENTLISTENERS>(\d+)<\/CURRENTLISTENERS>/i',
            
            // JSON embedded in HTML
            '/\{[^}]*"(?:listeners?|currentlisteners?)"\s*:\s*(\d+)/i',
            
            // Generic patterns (but avoid bitrates for Icecast pages)
            '/(\d+)[^0-9]*listener/i',
            '/listener[^0-9]*(\d+)/i'
        ];
        
        foreach ($patterns as $pattern) {
            if (preg_match($pattern, $html, $matches)) {
                $potential_listeners = (int)$matches[1];
                
                // For Icecast pages, be more restrictive to avoid bitrates
                if (strpos($url, '.xsl') !== false) {
                    // Skip obvious bitrates and large numbers
                    if ($potential_listeners >= 32 && $potential_listeners <= 320 && 
                        in_array($potential_listeners, [32, 64, 96, 128, 192, 256, 320])) {
                        if ($debug) {
                            echo "Skipping potential bitrate: {$potential_listeners}\n";
                        }
                        continue;
                    }
                }
                
                // Sanity check: reasonable listener count
                if ($potential_listeners >= 0 && $potential_listeners <= 10000) {
                    $listeners = $potential_listeners;
                    if ($debug) {
                        echo "Found {$listeners} listeners using pattern: " . substr($pattern, 0, 30) . "...\n";
                    }
                    break;
                }
            }
        }
    }
    
    // Set the listener count and status
    if ($listeners > 0) {
        $stats['listeners'] = $listeners;
        $stats['status'] = 'online';
    }
    
    // Extract track information
    $track_patterns = [
        '/<a href="currentsong\?sid=1">([^<]+)<\/a>/',
        '/Current Song:.*?<[^>]*>([^<]+)</is',
        '/Now Playing:.*?<[^>]*>([^<]+)</is',
        '/Track:.*?<[^>]*>([^<]+)</is',
        '/<SONGTITLE>([^<]+)<\/SONGTITLE>/',
        '/"(?:song|track|title)"\s*:\s*"([^"]+)"/',
        '/<meta[^>]*content="([^"]*)"[^>]*song/i',
        '/song[^>]*content="([^"]*)"[^>]*>/i'
    ];
    
    foreach ($track_patterns as $pattern) {
        if (preg_match($pattern, $html, $matches)) {
            $track = trim($matches[1]);
            if (!empty($track) && $track !== '-' && !preg_match('/^RC-\d+-?$/', $track)) {
                $stats['track'] = substr($track, 0, 90);
                if ($debug) {
                    echo "Found track: '{$stats['track']}'\n";
                }
                break;
            }
        }
    }
    }
    
    if ($debug) {
        echo "Final result: {$stats['listeners']} listeners, track: " . 
             ($stats['track'] ? "'{$stats['track']}'" : 'null') . ", status: {$stats['status']}\n";
    }
    
    $stats['track'] = robust_entity_decode($stats['track']);

    // Split track into artist and song
    $track_info = splitTrackInfo($stats['track']);
    $stats['artist'] = $track_info['artist'];
    $stats['song'] = $track_info['song'];

    return $stats;
}

/**
 * getCurrentShowDetails Function (Type 1)
 *
 * Every station will have a different format for their schedule.
 * Put code here to return the showname, presenter, and whether the show is pre-recorded or live.
 */
function getCurrentShowDetailsType1($schedule_url, $debug = false) {
    if (empty($schedule_url)) {
	return [
            'showname' => '',
            'presenter' => '',
            'recorded' => '',
	];
    }

    return [
        'showname' => $current_show['showname'],
        'presenter' => $current_show['presenter'] ?: 'Various',
        'recorded' => $current_show['recorded'] == '1' ? 1 : 0,
    ];
}


/**
 * getCurrentShowDetails Function (Type 2)
 *
 * Every station will have a different format for their schedule.
 * Put code here to return the showname, presenter, and whether the show is pre-recorded or live.
 * This function allows for an alternative schedule format to the Type 1 function above.
 * Leave empty if not required. 
 */
function getCurrentShowDetailsType2($schedule_url, $debug = false) {
    if (empty($schedule_url)) {
	return [
            'showname' => '',
            'presenter' => '',
            'recorded' => '',
	];
    }

    return [
        'showname' => $showname,
        'presenter' => $presenter,
        'recorded' => $recorded,
    ];
}

/**
 * Main genre lookup function - tries all sources in order
 */
function getGenre($conn, $table, $artist, $song, $api_key, $station_name, $station_website, $code_version, $debug = false) {
    if (empty($artist) || empty($song) || $artist === 'Unknown Artist') {
        return null;
    }

    // First, check if we already have genre data across all column sets
    //$existing_genre = checkExistingGenre($conn, $artist, $song);
    //if ($existing_genre) {
    //    return $existing_genre;
    //}
    
    // No existing data, so search external APIs in order of preference
    $sources = [
        'MusicBrainz' => function() use ($artist, $song, $station_name, $station_website, $code_version) {
            return getGenreFromMusicBrainz($artist, $song, $station_name, $station_website, $code_version);
        },
        'Last.fm' => function() use ($artist, $song, $api_key, $station_name, $station_website, $code_version) {
            return getGenreFromLastFm($artist, $song, $api_key, $station_name, $station_website, $code_version);
        },
        'Wikipedia' => function() use ($artist, $station_name, $station_website, $code_version) {
            return getGenreFromWikipedia($artist, $station_name, $station_website, $code_version);
        }
    ];
    
    foreach ($sources as $source_name => $source_function) {
        if ($debug) {
            echo "Trying {$source_name} for: {$artist} - {$song}\n";
        }
        
        $genre = $source_function();
        
        if ($genre) {
            if ($debug) {
                error_log("{$source_name} genre found: {$artist} - {$song} = {$genre}");
            }
            return ucwords($genre, " \t\r\n\f\v'-");
        }
        
        if ($debug) {
            echo "{$source_name} failed for: {$artist} - {$song}\n";
        }
    }
    
    if ($debug) {
        echo "No genre found for: {$artist} - {$song}\n";
    }
    
    return null;
}

/**
 * Common HTTP context creation for all API calls
 */
function createHttpContext($station_name, $station_website, $code_version, $timeout = 10) {
    return stream_context_create([
        'http' => [
            'header' => [
                'User-Agent: '.$station_name.' Listener Analysis/'.$code_version.' ('.$station_website.')',
                'Accept: application/json'
            ],
            'timeout' => $timeout
        ]
    ]);
}

/**
 * Common API call function with error handling
 */
function makeApiCall($url, $station_name, $station_website, $code_version, $delay_ms = 0) {
    if ($delay_ms > 0) {
        usleep($delay_ms * 1000); // Convert ms to microseconds
    }
    
    $context = createHttpContext($station_name, $station_website, $code_version);
    $response = @file_get_contents($url, false, $context);
    
    if ($response === false) {
        return null;
    }
    
    $data = json_decode($response, true);
    return $data ?: null;
}

/**
 * Common genre validation function
 */
function isValidGenre($genre, $artist = '') {
    if (empty($genre) || strlen($genre) < 2) {
        return false;
    }
    
    $genre_lower = strtolower($genre);
    $artist_lower = strtolower($artist);
    
    // Skip if it contains the artist name
    if (!empty($artist) && (strpos($genre_lower, $artist_lower) !== false || strpos($artist_lower, $genre_lower) !== false)) {
        return false;
    }
    
    // Common non-genre terms to filter out
    $non_genre_terms = [
        // Years and decades
        '1960s', '1970s', '1980s', '1990s', '2000s', '2010s', '2020s',
        '1960', '1970', '1980', '1990', '2000', '2010', '2020',
        
        // Pure nationalities
        'american', 'british', 'english', 'irish', 'scottish', 'welsh', 
        'canadian', 'australian', 'german', 'french', 'italian', 'spanish',
        
        // Non-musical terms
        'actor', 'actress', 'politician', 'author', 'writer', 'director',
        'band', 'group', 'artist', 'musician', 'singer', 'songwriter',
        
        // Vague terms
        'music', 'song', 'album', 'single', 'track', 'popular', 'famous',
        'hit', 'favorite', 'chart', 'number one', 'top', 'best'
    ];
    
    foreach ($non_genre_terms as $term) {
        if ($genre_lower === $term || strpos($genre_lower, $term) !== false) {
            return false;
        }
    }
    
    // Filter out pure year patterns
    if (preg_match('/^\d{4}s?$/', $genre)) {
        return false;
    }
    
    // Valid genre patterns
    $valid_genre_patterns = [
        'rock', 'pop', 'jazz', 'blues', 'folk', 'country', 'electronic', 'dance',
        'hip hop', 'rap', 'r&b', 'soul', 'funk', 'disco', 'house', 'techno',
        'ambient', 'classical', 'opera', 'reggae', 'ska', 'punk', 'metal',
        'grunge', 'alternative', 'indie', 'new wave', 'synthpop', 'psychedelic',
        'progressive', 'experimental', 'industrial', 'gothic', 'emo', 'hardcore',
        'world music', 'latin', 'african', 'celtic', 'bluegrass', 'gospel',
        'spiritual', 'soundtrack', 'instrumental', 'acoustic', 'fusion'
    ];
    
    // Check if genre contains any valid patterns
    foreach ($valid_genre_patterns as $pattern) {
        if (strpos($genre_lower, $pattern) !== false) {
            return true;
        }
    }
    
    // Check for compound genres and music style suffixes
    if (preg_match('/\b(?:hard|soft|heavy|death|black|power|symphonic|melodic)\s+(?:rock|metal|jazz|blues)\b/', $genre_lower) ||
        preg_match('/\w+(?:core|step|wave|beat|bass|punk)$/', $genre_lower)) {
        return true;
    }
    
    return false;
}

/**
 * Extract best genre from tags array (common to MusicBrainz and Last.fm)
 */
function extractBestGenreFromTags($tags, $artist) {
    $genre_scores = [];
    
    foreach ($tags as $tag) {
        $tag_name = isset($tag['name']) ? trim($tag['name']) : (isset($tag['tag']) ? trim($tag['tag']) : '');
        $tag_count = isset($tag['count']) ? (int)$tag['count'] : 1;
        
        if (isValidGenre($tag_name, $artist)) {
            $genre_scores[$tag_name] = $tag_count;
        }
    }
    
    if (empty($genre_scores)) {
        return null;
    }
    
    // Return the tag with the highest count
    arsort($genre_scores);
    return key($genre_scores);
}

/**
 * Check for existing genre data in SQL
 */
function checkExistingGenre($conn, $artist, $song) {
    $stmt = $conn->prepare("
        SELECT 
            main_genre,
            second_genre,
            comparison_genre
        FROM streams 
        WHERE 
            (main_artist = ? AND main_song = ? AND main_genre IS NOT NULL AND main_genre != '-')
            OR 
            (second_artist = ? AND second_song = ? AND second_genre IS NOT NULL AND second_genre != '-')
            OR 
            (comparison_artist = ? AND comparison_song = ? AND comparison_genre IS NOT NULL AND comparison_genre != '-')
        LIMIT 1
    ");
    
    // Bind the same artist/song 3 times for each column set
    $stmt->bind_param("ssssss", $artist, $song, $artist, $song, $artist, $song);
    $stmt->execute();
    $result = $stmt->get_result();
    
    if ($row = $result->fetch_assoc()) {
        // Return the first non-empty genre found
        $genres = [$row['main_genre'], $row['second_genre'], $row['comparison_genre']];
        foreach ($genres as $genre) {
            if (!empty($genre) && $genre != '-') {
                $stmt->close();
                return $genre;
            }
        }
    }
    
    $stmt->close();
    return null;
}

/**
 * MusicBrainz genre lookup
 */
function getGenreFromMusicBrainz($artist, $song, $station_name, $station_website, $code_version) {
    if (empty($artist) || empty($song) || $artist === 'Unknown Artist') {
        return null;
    }
    
    $artist_clean = trim($artist);
    $song_clean = trim($song);
    
    // Search for recordings
    $search_query = urlencode("artist:\"{$artist_clean}\" AND recording:\"{$song_clean}\"");
    $search_url = "https://musicbrainz.org/ws/2/recording?query={$search_query}&fmt=json&limit=5";
    
    $data = makeApiCall($search_url, $station_name, $station_website, $code_version, 100); // 100ms delay for MusicBrainz
    
    if (!$data || !isset($data['recordings']) || empty($data['recordings'])) {
        // Try broader artist search
        return searchMusicBrainzByArtist($artist_clean, $station_name, $station_website, $code_version);
    }
    
    // Look for genre information in recordings
    foreach ($data['recordings'] as $recording) {
        if (isset($recording['tags']) && !empty($recording['tags'])) {
            $genre = extractBestGenreFromTags($recording['tags'], $artist);
            if ($genre) {
                return $genre;
            }
        }
        
        // Check artist-credit for genre info
        if (isset($recording['artist-credit']) && !empty($recording['artist-credit'])) {
            foreach ($recording['artist-credit'] as $credit) {
                if (isset($credit['artist']['id'])) {
                    $artist_genre = getMusicBrainzArtistGenre($credit['artist']['id'], $station_name, $station_website, $code_version);
                    if ($artist_genre) {
                        return $artist_genre;
                    }
                }
            }
        }
    }
    
    return null;
}

/**
 * Search MusicBrainz by artist only
 */
function searchMusicBrainzByArtist($artist, $station_name, $station_website, $code_version) {
    $search_query = urlencode("artist:\"{$artist}\"");
    $search_url = "https://musicbrainz.org/ws/2/artist?query={$search_query}&fmt=json&limit=3";
    
    $data = makeApiCall($search_url, $station_name, $station_website, $code_version, 100);
    
    if (!$data || !isset($data['artists']) || empty($data['artists'])) {
        return null;
    }
    
    foreach ($data['artists'] as $artist_data) {
        if (isset($artist_data['tags']) && !empty($artist_data['tags'])) {
            $genre = extractBestGenreFromTags($artist_data['tags'], $artist);
            if ($genre) {
                return $genre;
            }
        }
        
        if (isset($artist_data['id'])) {
            $artist_genre = getMusicBrainzArtistGenre($artist_data['id'], $station_name, $station_website, $code_version);
            if ($artist_genre) {
                return $artist_genre;
            }
        }
    }
    
    return null;
}

/**
 * Get detailed artist information from MusicBrainz
 */
function getMusicBrainzArtistGenre($artist_id, $station_name, $station_website, $code_version) {
    $artist_url = "https://musicbrainz.org/ws/2/artist/{$artist_id}?inc=tags&fmt=json";
    
    $data = makeApiCall($artist_url, $station_name, $station_website, $code_version, 100);
    
    if ($data && isset($data['tags']) && !empty($data['tags'])) {
        return extractBestGenreFromTags($data['tags'], '');
    }
    
    return null;
}

/**
 * Last.fm genre lookup
 */
function getGenreFromLastFm($artist, $song, $api_key, $station_name, $station_website, $code_version) {
    if (empty($artist) || empty($song) || $artist === 'Unknown Artist' || empty($api_key)) {
        return null;
    }
    
    $artist_encoded = urlencode(trim($artist));
    $song_encoded = urlencode(trim($song));
    
    $url = "http://ws.audioscrobbler.com/2.0/?method=track.getInfo&api_key={$api_key}&artist={$artist_encoded}&track={$song_encoded}&format=json";
    
    $data = makeApiCall($url, $station_name, $station_website, $code_version);
    
    if (!$data || !isset($data['track'])) {
        return null;
    }
    
    $track = $data['track'];
    
    // Check track tags first
    if (isset($track['toptags']['tag']) && !empty($track['toptags']['tag'])) {
        $tags = is_array($track['toptags']['tag']) ? $track['toptags']['tag'] : [$track['toptags']['tag']];
        $genre = extractBestGenreFromTags($tags, $artist);
        if ($genre) {
            return $genre;
        }
    }
    
    // Fall back to artist info
    if (isset($track['artist']['name'])) {
        return getLastFmArtistGenre($track['artist']['name'], $api_key, $station_name, $station_website, $code_version);
    }
    
    return null;
}

/**
 * Get artist genre from Last.fm
 */
function getLastFmArtistGenre($artist, $api_key, $station_name, $station_website, $code_version) {
    $artist_encoded = urlencode(trim($artist));
    $url = "http://ws.audioscrobbler.com/2.0/?method=artist.getInfo&api_key={$api_key}&artist={$artist_encoded}&format=json";
    
    $data = makeApiCall($url, $station_name, $station_website, $code_version);
    
    if ($data && isset($data['artist']['tags']['tag']) && !empty($data['artist']['tags']['tag'])) {
        $tags = is_array($data['artist']['tags']['tag']) ? $data['artist']['tags']['tag'] : [$data['artist']['tags']['tag']];
        return extractBestGenreFromTags($tags, $artist);
    }
    
    return null;
}

/**
 * Wikipedia genre lookup
 */
function getGenreFromWikipedia($artist, $station_name, $station_website, $code_version) {
    if (empty($artist) || $artist === 'Unknown Artist') {
        return null;
    }
    
    return getGenreFromWikipediaInfobox($artist, $station_name, $station_website, $code_version);
}

/**
 * Extract genre from Wikipedia infobox
 */
function getGenreFromWikipediaInfobox($artist, $station_name, $station_website, $code_version) {
    // Clean artist name for Wikipedia search
    $artist_clean = str_replace([' & ', ' and ', '&'], [' ', ' ', ' '], $artist);
    $artist_encoded = urlencode(trim($artist_clean));
    
    // Search for the article
    $search_url = "https://en.wikipedia.org/w/api.php?action=query&format=json&list=search&srsearch=" . $artist_encoded . "&srlimit=1";
    
    $search_data = makeApiCall($search_url, $station_name, $station_website, $code_version);
    
    if (!$search_data || !isset($search_data['query']['search'][0]['title'])) {
        return null;
    }
    
    $page_title = $search_data['query']['search'][0]['title'];
    
    // Get the page content
    $content_url = "https://en.wikipedia.org/w/api.php?action=query&format=json&prop=revisions&rvprop=content&rvslots=main&titles=" . urlencode($page_title);
    
    $content_data = makeApiCall($content_url, $station_name, $station_website, $code_version);
    
    if (!$content_data || !isset($content_data['query']['pages'])) {
        return null;
    }
    
    $pages = $content_data['query']['pages'];
    $page = reset($pages);
    
    if (!isset($page['revisions'][0]['slots']['main']['*'])) {
        return null;
    }
    
    $wikitext = $page['revisions'][0]['slots']['main']['*'];
    
    // Extract genre from infobox
    $genre = extractGenreFromInfobox($wikitext, $artist);
    
    return $genre;
}

/**
 * Extract genre from Wikipedia infobox wikitext
 */
function extractGenreFromInfobox($wikitext, $artist) {
    // Look for infobox musical artist or similar
    if (!preg_match('/\{\{(?:Infobox|infobox)\s+(?:musical artist|musician|singer|band|person)/i', $wikitext)) {
        return null;
    }
    
    // Extract genre field from infobox
    $patterns = [
        '/\|\s*genre[s]?\s*=\s*([^\|\}]+)/i',
        '/\|\s*style[s]?\s*=\s*([^\|\}]+)/i',
        '/\|\s*music[_\s]?style[s]?\s*=\s*([^\|\}]+)/i'
    ];
    
    foreach ($patterns as $pattern) {
        if (preg_match($pattern, $wikitext, $matches)) {
            $genre_text = trim($matches[1]);
            
            if (empty($genre_text)) {
                continue;
            }
            
            // Clean up the genre text
            $genre_text = cleanWikipediaGenre($genre_text);
            
            if (isValidInfoboxGenre($genre_text, $artist)) {
                return $genre_text;
            }
        }
    }
    
    return null;
}

/**
 * Clean Wikipedia genre text
 */
function cleanWikipediaGenre($genre_text) {
    // Clean up standard wiki markup
    $genre_text = preg_replace('/\[\[([^\|\]]+)(?:\|[^\]]+)?\]\]/', '$1', $genre_text); // [[Rock music|Rock]] -> Rock
    $genre_text = preg_replace('/\{\{[^}]+\}\}/', '', $genre_text); // Remove templates
    $genre_text = preg_replace('/<!--.*?-->/s', '', $genre_text); // Remove comments
    $genre_text = preg_replace('/<[^>]+>/', '', $genre_text); // Remove HTML tags
    $genre_text = preg_replace('/<ref[^>]*>.*?<\/ref>/is', '', $genre_text); // Remove references
    
    // Handle multiple genres - take the first one
    $genres = preg_split('/[,\n\|]/', $genre_text);
    $first_genre = trim($genres[0]);
    
    // Remove common prefixes
    $first_genre = preg_replace('/^(American|British|English|Irish|Scottish|Welsh|Canadian|Australian)\s+/i', '', $first_genre);
    $first_genre = preg_replace('/\s+/', ' ', $first_genre);
    $first_genre = preg_replace('/^\*\s*/', '', $first_genre);
    $first_genre = preg_replace('/\s+music$/i', '', $first_genre);
    
    return trim($first_genre);
}

/**
 * Validate Wikipedia infobox genre
 */
function isValidInfoboxGenre($genre, $artist) {
    if (empty($genre) || strlen($genre) > 50) {
        return false;
    }
    
    $genre_lower = strtolower($genre);
    $artist_lower = strtolower($artist);
    
    // Skip if contains artist name
    if (strpos($genre_lower, $artist_lower) !== false || strpos($artist_lower, $genre_lower) !== false) {
        return false;
    }
    
    // Skip pure nationalities
    $pure_nationalities = ['american', 'british', 'english', 'irish', 'scottish', 'welsh', 'canadian', 'australian'];
    if (in_array($genre_lower, $pure_nationalities)) {
        return false;
    }
    
    // Skip non-musical terms
    $non_music_terms = ['actor', 'actress', 'politician', 'author', 'writer', 'director'];
    foreach ($non_music_terms as $term) {
        if (strpos($genre_lower, $term) !== false) {
            return false;
        }
    }
    
    return true;
}

/**
 * Split track data into Artist and Song
 */
function splitTrackInfo($track) {
    if (empty($track) || $track === '-') {
        return ['artist' => null, 'song' => null];
    }
    
    // Split on " - " (note the spaces)
    $parts = explode(' - ', $track, 2);
    
    if (count($parts) >= 2) {
        $artist = trim($parts[0]);
        $song = trim($parts[1]);
        
        // Clean up common issues
        $artist = $artist !== '' ? $artist : null;
        $song = $song !== '' ? $song : null;
        
        return ['artist' => $artist, 'song' => $song];
    } else {
        // If no " - " found, treat the whole thing as song with unknown artist
        return ['artist' => 'Unknown Artist', 'song' => trim($track)];
    }
}

/**
 * Function to check if the current song is the same as the last entry in SQL
 * and modify the artist to "-" if it's a duplicate
 * This helps prevent "double-accounting" in the analysis code
 */
function checkAndHandleDuplicateSong($conn, $table, $current_artist, $current_song, $debug = false) {
    // Skip the check if we don't have valid song data
    if (empty($current_artist) || empty($current_song) || 
        $current_artist === 'Unknown Artist' || $current_song === '-') {
        return $current_artist;
    }
    
    // Get the most recent entry from the database
    $stmt = $conn->prepare("
        SELECT main_artist, main_song 
        FROM ".$table."  
        ORDER BY stamp DESC 
        LIMIT 1
    ");
    
    if (!$stmt->execute()) {
        if ($debug) {
            echo "Error checking for duplicate song: " . $stmt->error . "\n";
        }
        return $current_artist; // Return original artist if query fails
    }
    
    $result = $stmt->get_result();
    $last_entry = $result->fetch_assoc();
    $stmt->close();
    
    // If no previous entries exist, return the original artist
    if (!$last_entry) {
        if ($debug) {
            echo "No previous entries found - keeping original artist\n";
        }
        return $current_artist;
    }
    
    $last_artist = $last_entry['main_artist'];
    $last_song = $last_entry['main_song'];
    
    // Check if the current song matches the last entry
    // We'll compare both artist and song to be more precise
    if (($current_artist === $last_artist || $last_artist === '-') && $current_song === $last_song) {
        if ($debug) {
            echo "Duplicate song detected: '{$current_artist} - {$current_song}'\n";
            echo "Setting artist to '-' to exclude from analysis\n";
        }
        return '-'; // This will cause the song to be excluded from statistical analysis
    }
    
    // Get the most recent entry from the database
    $stmt = $conn->prepare("
        SELECT second_artist, second_song 
        FROM ".$table."  
        ORDER BY stamp DESC 
        LIMIT 1
    ");
    
    if (!$stmt->execute()) {
        if ($debug) {
            echo "Error checking for duplicate song: " . $stmt->error . "\n";
        }
        return $current_artist; // Return original artist if query fails
    }
    
    $result = $stmt->get_result();
    $last_entry = $result->fetch_assoc();
    $stmt->close();
    
    // If no previous entries exist, return the original artist
    if (!$last_entry) {
        if ($debug) {
            echo "No previous entries found - keeping original artist\n";
        }
        return $current_artist;
    }
    
    $last_artist = $last_entry['second_artist'];
    $last_song = $last_entry['second_song'];
    
    // Check if the current song matches the last entry
    // We'll compare both artist and song to be more precise
    if (($current_artist === $last_artist || $last_artist === '-') && $current_song === $last_song) {
        if ($debug) {
            echo "Duplicate song detected: '{$current_artist} - {$current_song}'\n";
            echo "Setting artist to '-' to exclude from analysis\n";
        }
        return '-'; // This will cause the song to be excluded from statistical analysis
    }
    
    // Get the most recent entry from the database
    $stmt = $conn->prepare("
        SELECT comparison_artist, comparison_song 
        FROM ".$table."  
        ORDER BY stamp DESC 
        LIMIT 1
    ");
    
    if (!$stmt->execute()) {
        if ($debug) {
            echo "Error checking for duplicate song: " . $stmt->error . "\n";
        }
        return $current_artist; // Return original artist if query fails
    }
    
    $result = $stmt->get_result();
    $last_entry = $result->fetch_assoc();
    $stmt->close();
    
    // If no previous entries exist, return the original artist
    if (!$last_entry) {
        if ($debug) {
            echo "No previous entries found - keeping original artist\n";
        }
        return $current_artist;
    }
    
    $last_artist = $last_entry['comparison_artist'];
    $last_song = $last_entry['comparison_song'];
    
    // Check if the current song matches the last entry
    // We'll compare both artist and song to be more precise
    if (($current_artist === $last_artist || $last_artist === '-') && $current_song === $last_song) {
        if ($debug) {
            echo "Duplicate song detected: '{$current_artist} - {$current_song}'\n";
            echo "Setting artist to '-' to exclude from analysis\n";
        }
        return '-'; // This will cause the song to be excluded from statistical analysis
    }
    
    if ($debug) {
        echo "No duplicate detected - keeping original artist '{$current_artist}'\n";
        echo "Last entry was: '{$last_artist} - {$last_song}'\n";
        echo "Current entry is: '{$current_artist} - {$current_song}'\n";
    }
    
    return $current_artist; // Return original artist if no duplicate
}

/**
 * Is the DJ a stand-in for a regular presenter?
 * Put your own code here!
 */
function is_stand_in_dj($presenter) {
	return 0;
}

/**
 * Check if today is a UK public holiday
 * Uses UK government API
 */
function checkPublicHoliday($date, $station_name, $station_website, $code_version) {
    static $holiday_cache = null;
    
    // Only fetch once per script run
    if ($holiday_cache === null) {
        $year = date('Y', strtotime($date));
        $url = "https://www.gov.uk/bank-holidays.json";
        
        $context = stream_context_create([
            'http' => [
                'header' => [
                    'User-Agent: '.$station_name.' Listener Analysis/'.$code_version.' ('.$station_website.')',
                    'Accept: application/json'
                ],
                'timeout' => 10
            ]
        ]);
        
        $response = @file_get_contents($url, false, $context);
        if ($response !== false) {
            $data = json_decode($response, true);
            $holiday_cache = [];
            
            // Extract England and Wales holidays
            if (isset($data['england-and-wales']['events'])) {
                foreach ($data['england-and-wales']['events'] as $holiday) {
                    $holiday_cache[] = $holiday['date'];
                }
            }
        } else {
            $holiday_cache = []; // Empty array to prevent repeated API calls
        }
    }
    
    return in_array($date, $holiday_cache) ? 1 : 0;
}

/**
 * Get weather data from OpenWeatherMap
 */
function getWeatherData($lat, $lng, $api_key = null, $station_name, $station_website,$code_version) {
    if (empty($api_key) || empty($lat) || empty($lng)) {
        return ['temp' => null, 'condition' => null, 'rain' => null];
    }
    
    $url = "https://api.openweathermap.org/data/2.5/weather?lat={$lat}&lon={$lng}&appid={$api_key}&units=metric";
    
    $context = stream_context_create([
        'http' => [
            'header' => [
                'User-Agent: '.$station_name.' Listener Analysis/'.$code_version.' ('.$station_website.')',
                'Accept: application/json'
            ],
            'timeout' => 10
        ]
    ]);
    
    $response = @file_get_contents($url, false, $context);
    if ($response === false) {
        return ['temp' => null, 'condition' => null, 'rain' => null];
    }
    
    $data = json_decode($response, true);
    
    return [
        'temp' => isset($data['main']['temp']) ? round($data['main']['temp'], 1) : null,
        'condition' => isset($data['weather'][0]['main']) ? $data['weather'][0]['main'] : null,
        'rain' => isset($data['rain']['1h']) ? $data['rain']['1h'] : 0
    ];
}

/**
 * Get sunrise/sunset times for radio station's location
 * Uses free sunrise-sunset API
 */
function getSunTimes($lat, $lng, $date, $station_name, $station_website, $code_version) {
    static $sun_cache = [];

    // Cache by date to avoid repeated API calls
    if (isset($sun_cache[$date])) {
        return $sun_cache[$date];
    }

    if (empty($lat) || empty($lng)) {
	$sun_cache[$date] = ['sunrise' => '00:00:00', 'sunset' => '00:00:00'];
	return $sun_cache[$date];
    }
        
    $url = "https://api.sunrise-sunset.org/json?lat={$lat}&lng={$lng}&date={$date}&formatted=0";
    
    $context = stream_context_create([
        'http' => [
            'header' => [
                'User-Agent: '.$station_name.' Listener Analysis/'.$code_version.' ('.$station_website.')',
                'Accept: application/json'
            ],
            'timeout' => 10
        ]
    ]);
    
    $response = @file_get_contents($url, false, $context);
    if ($response === false) {
        $sun_cache[$date] = ['sunrise' => null, 'sunset' => null];
        return $sun_cache[$date];
    }
    
    $data = json_decode($response, true);
    
    $sunrise = null;
    $sunset = null;
    
    if (isset($data['results']['sunrise'])) {
        $sunrise = date('H:i:s', strtotime($data['results']['sunrise']));
    }
    
    if (isset($data['results']['sunset'])) {
        $sunset = date('H:i:s', strtotime($data['results']['sunset']));
    }
    
    $sun_cache[$date] = ['sunrise' => $sunrise, 'sunset' => $sunset];
    return $sun_cache[$date];
}

/**
 * Improved cURL function with better error handling
 */
function getWebPage($url, $timeout = 10) {
    $ch = curl_init();
    curl_setopt_array($ch, [
        CURLOPT_URL => $url,
        CURLOPT_USERAGENT => 'Mozilla/5.0 (X11; Linux i686; rv:83.0) Gecko/20100101 Firefox/83.0',
        CURLOPT_RETURNTRANSFER => true,
        CURLOPT_FOLLOWLOCATION => true,
        CURLOPT_SSL_VERIFYPEER => false,
        CURLOPT_TIMEOUT => $timeout,
        CURLOPT_CONNECTTIMEOUT => 5,
        CURLOPT_ENCODING => 'gzip, deflate'
    ]);
    
    $result = curl_exec($ch);
    $http_code = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    curl_close($ch);
    
    return ($result !== false && $http_code == 200) ? $result : false;
}

/**
 * Manually fix any issues
 */
function manually_fix_things($string, $string2 = NULL) {
    if (empty($string) && empty($string2)) {
	return array('', '');
    }

    if (empty($string)) {
	return '';
    }

    if (!$string2) {

/**
 * Manually fix things like Artist names, Genres here
 */

        return $string;

    } else {

	if ($string2 == "-") {
	    $string2 = $string;
	}

/**
 * Manually fix double-variable data, like DJ name AND show name, here
 */

        return array($string, $string2);
    }
}

/**
 * Get rid of HTML characters etc from strings
 */
function robust_entity_decode($string) {
    // Decode named entities (includes &apos; with ENT_XML1)
    $string = html_entity_decode($string, ENT_QUOTES | ENT_XML1, 'UTF-8');

    // Decode numeric decimal entities (e.g. &#039;)
    $string = preg_replace_callback('/&#(\d+);/', function ($matches) {
        return mb_convert_encoding(pack('n', $matches[1]), 'UTF-8', 'UTF-16BE');
    }, $string);

    // Decode numeric hex entities (e.g. &#x27;)
    $string = preg_replace_callback('/&#x([a-fA-F0-9]+);/', function ($matches) {
        return mb_convert_encoding(pack('n', hexdec($matches[1])), 'UTF-8', 'UTF-16BE');
    }, $string);

    // Strip non-printable and invisible Unicode characters
    $string = preg_replace('/[\x00-\x1F\x7F\xAD\x{200B}-\x{200D}\x{FEFF}]/u', '', $string);

    // Normalize space characters (e.g. non-breaking space to regular space)
    $string = str_replace([
        "\xC2\xA0", // non-breaking space (U+00A0)
        "\xE2\x80\xAF", // narrow no-break space (U+202F)
        "\xE2\x80\x8A", // hair space (U+200A)
    ], ' ', $string);

    // Trim any leading/trailing whitespace
    $string = trim($string);

    return $string;
}

/**
 * Main execution block
 */
try {
    if ($debug) {
	echo "Collecting statistics...\n";
    }

    // Get current show information for main station
    $main_show_info = getCurrentShowDetailsType1($main_schedule_url, $debug);
    $main_showname = isset($main_show_info['error']) ? 'Unknown' : $main_show_info['showname'];
    $main_presenter = isset($main_show_info['error']) ? 'Unknown' : $main_show_info['presenter'];
    $main_recorded = isset($main_show_info['error']) ? 0 : $main_show_info['recorded'];

    $main_showname = robust_entity_decode($main_showname);
    $main_presenter = robust_entity_decode($main_presenter);
    $main_stand_in = is_stand_in_dj($main_presenter);

    $clean_details = manually_fix_things($main_showname, $main_presenter);
    $main_showname = $clean_details[0];
    $main_presenter = $clean_details[1];

    if (empty($main_showname)) {
	$main_showname = 'Unknown';
    }
    if (empty($main_presenter)) {
	$main_presenter = 'Unknown';
    }

    // Get current show information for second station
    $second_show_info = getCurrentShowDetailsType2($second_schedule_url, $debug);
    $second_showname = isset($second_show_info['error']) ? 'Unknown' : $second_show_info['showname'];
    $second_presenter = isset($second__show_info['error']) ? 'Unknown' : $second_show_info['presenter'];
    $second_recorded = isset($second_show_info['error']) ? 0 : $second_show_info['recorded'];

    $second_showname = robust_entity_decode($second_showname);
    $second_presenter = robust_entity_decode($second_presenter);
    $second_stand_in = is_stand_in_dj($second_presenter);

    $clean_details = manually_fix_things($second_showname, $second_presenter);
    $second_showname = $clean_details[0];
    $second_presenter = $clean_details[1];

    if (empty($second_showname)) {
	$second_showname = 'Unknown';
    }
    if (empty($second_presenter)) {
	$second_presenter = 'Unknown';
    }

    // Get current show information for comparison station
    $comparison_show_info = getCurrentShowDetailsType1($comparison_schedule_url, $debug);
    $comparison_showname = isset($second_show_info['error']) ? 'Unknown' : $comparison_show_info['showname'];
    $comparison_presenter = isset($second__show_info['error']) ? 'Unknown' : $comparison_show_info['presenter'];
    $comparison_recorded = isset($second_show_info['error']) ? 0 : $comparison_show_info['recorded'];

    $comparison_showname = robust_entity_decode($comparison_showname);
    $comparison_presenter = robust_entity_decode($comparison_presenter);
    $comparison_stand_in = is_stand_in_dj($comparison_presenter);

    $clean_details = manually_fix_things($comparison_showname, $comparison_presenter);
    $comparison_showname = $clean_details[0];
    $comparison_presenter = $clean_details[1];

    if (empty($comparison_showname)) {
	$comparison_showname = 'Unknown';
    }
    if (empty($comparison_presenter)) {
	$comparison_presenter = 'Unknown';
    }

    if ($debug) {
	echo "Current shows: $main_showname by $main_presenter; $second_showname by $second_presenter; $comparison_showname by $comparison_presenter".PHP_EOL;
    }
    
    // Get stream statistics
    $main_stream1 = getStreamStats($main_shoutcast_url_stream1, $debug);
    $main_stream2 = getStreamStats($main_shoutcast_url_stream2, $debug);

    $main_stream1_listeners = $main_stream1['listeners'];
    $main_stream2_listeners = $main_stream2['listeners'];
    $main_artist = $main_stream1['artist'];
    $main_song = $main_stream1['song'];

    $second_stream1 = getStreamStats($second_shoutcast_url_stream1, $debug);
    $second_stream2 = getStreamStats($second_shoutcast_url_stream2, $debug);

    $second_stream1_listeners = $second_stream1['listeners'];
    $second_stream2_listeners = $second_stream2['listeners'];
    $second_artist = $second_stream1['artist'];
    $second_song = $second_stream1['song'];

    $comparison_stream = getStreamStats($comparison_shoutcast_url, $debug);

    $comparison_stream_listeners = $comparison_stream['listeners'];
    $comparison_artist = $comparison_stream['artist'];
    $comparison_song = $comparison_stream['song'];

    $public_holiday = checkPublicHoliday($date, $main_station_name, $main_station_website, $code_version);
    $weather = getWeatherData($lat, $lng, $openweather_api_key, $main_station_name, $main_station_website, $code_version);
    $weather_temp = $weather['temp'];
    $weather_condition = $weather['condition'];
    $weather_rain = $weather['rain'];
    $sun_times = getSunTimes($lat, $lng, $date, $main_station_name, $main_station_website, $code_version);
    $sunrise_time = $sun_times['sunrise'];
    $sunset_time = $sun_times['sunset'];

    // Not currently implemented:
    //$major_event = checkMajorEvents($date);
    $major_event = null;
    
    // Get database connection
    $conn = new mysqli($server, $user, $pass, $db);
    ensureTableExists($conn, $table, $debug);
    
    if ($conn->connect_error) {
        throw new Exception("Connection failed: " . $conn->connect_error);
    }

    // Check if the last SQL entry was the same song, which can happen if it's a long track
    // If so, set artist = '-' so that the second entry can be excluded from the analysis to avoid double counting
    $main_artist = checkAndHandleDuplicateSong($conn, $table, $main_artist, $main_song, $debug);
    $second_artist = checkAndHandleDuplicateSong($conn, $table, $second_artist, $second_song, $debug);
    $comparison_artist = checkAndHandleDuplicateSong($conn, $table, $comparison_artist, $comparison_song, $debug);

    if ($main_artist !== '-' && $main_artist !== 'Unknown Artist') {
	$main_genre = getGenre($conn, $table, $main_artist, $main_song, $lastfm_api_key, $main_station_name, $main_station_website, $code_version, $debug);
	$main_genre = robust_entity_decode($main_genre);
	$main_genre = manually_fix_things($main_genre);
    }
    if (empty($main_genre)) {
	$main_genre = '-';
    }

    if ($second_artist !== '-' && $second_artist !== 'Unknown Artist') {
	$second_genre = getGenre($conn, $table, $second_artist, $second_song, $lastfm_api_key, $main_station_name, $main_station_website, $code_version, $debug);
	$second_genre = robust_entity_decode($second_genre);
	$second_genre = manually_fix_things($second_genre);
    }
    if (empty($second_genre)) {
	$second_genre = '-';
    }

    if ($comparison_artist !== '-' && $comparison_artist !== 'Unknown Artist') {
	$comparison_genre = getGenre($conn, $table, $comparison_artist, $comparison_song, $lastfm_api_key, $main_station_name, $main_station_website, $code_version, $debug);
	$comparison_genre = robust_entity_decode($comparison_genre);
	$comparison_genre = manually_fix_things($comparison_genre);
    }
    if (empty($comparison_genre)) {
	$comparison_genre = '-';
    }

    $stmt = $conn->prepare("INSERT INTO ".$table." (date, time, main_stream1, main_stream2, main_showname, main_presenter, main_stand_in, main_recorded, main_artist, main_song, main_genre, 
        second_stream1, second_stream2, second_showname, second_presenter, second_stand_in, second_recorded, second_artist, second_song, second_genre,
        comparison_stream, comparison_showname, comparison_presenter, comparison_stand_in, comparison_recorded, comparison_artist, comparison_song, comparison_genre,
        public_holiday, weather_temp, weather_condition, weather_rain, major_event, sunrise_time, sunset_time) 
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)");
    $stmt->bind_param("ssiissiisssiissiisssissiisssidsdsss", 
        $date, $time, $main_stream1_listeners, $main_stream2_listeners, $main_showname, $main_presenter, $main_stand_in, $main_recorded, $main_artist, $main_song, $main_genre, 
        $second_stream1_listeners, $second_stream2_listeners, $second_showname, $second_presenter, $second_stand_in, $second_recorded, $second_artist, $second_song, $second_genre, 
        $comparison_stream_listeners, $comparison_showname, $comparison_presenter, $comparison_stand_in, $comparison_recorded, $comparison_artist, $comparison_song, $comparison_genre, 
        $public_holiday, $weather_temp, $weather_condition, $weather_rain, $major_event, $sunrise_time, $sunset_time);    
    if ($stmt->execute()) {
        // echo "Record inserted successfully\n";
    } else {
        throw new Exception("Error inserting record: " . $stmt->error);
    }

    $stmt->close();
    $conn->close();
    
} catch (Exception $e) {
    if ($debug) {
	echo "Error: " . $e->getMessage() . "\n";
    }
    exit(1);
}

if ($debug) {
    echo "Statistics collection completed successfully\n";
}

exit(0);

?>
