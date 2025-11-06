-- 1. Switch to the team role. All subsequent commands will be executed as 'data_team'.
SET ROLE data_team;

-- 2. Drop the old table. As we are now 'data_team', we have the necessary permissions.
DROP TABLE IF EXISTS berlin_labels.district_features;

-- 3. Create the new table. The owner of this table will automatically be 'data_team'.
CREATE TABLE berlin_labels.district_features AS (
    SELECT
        d.district_id,
        -- Transport columns
        COALESCE(b.bus_tram_stop_count, 0) AS bus_tram_stop_count,
        COALESCE(u.uban_station_count, 0) AS uban_station_count,
        COALESCE(s.sbahn_station_count, 0) AS sbahn_station_count,
        -- Accessibility columns
        COALESCE(ba.bank_count, 0) AS bank_count,
        COALESCE(po.post_office_count, 0) AS post_office_count,
        COALESCE(su.supermarket_count, 0) AS supermarket_count,
        COALESCE(ma.mall_count, 0) AS mall_count,
        -- Sport-related features
        COALESCE(sc.num_sport_clubs, 0) AS num_sport_clubs,
        COALESCE(g.num_gyms, 0) AS num_gyms,
        COALESCE(p.num_pools, 0) AS num_pools,
        -- Healthcare columns
        COALESCE(h.hospital_count, 0) AS hospital_count,
        COALESCE(ph.pharmacy_count, 0) AS pharmacy_count,
        COALESCE(de.dental_office_count, 0) AS dental_office_count,
        -- Crime column (latest year)
        COALESCE(cr.total_crime_cases_latest_year, 0) AS total_crime_cases_latest_year,
        -- Nightlife related features
        COALESCE(ev.evening_venue_count, 0) AS evening_venue_count_9pm_11pm,
        COALESCE(lv.late_venue_count, 0) AS late_venue_count_after_11pm,
        COALESCE(nc.night_club_count, 0) AS night_club_count,
        -- Venue related features
        COALESCE(rc.restaurant_count, 0) AS restaurant_count, 
        COALESCE(bc.bar_count, 0) AS bar_count,             
        COALESCE(cc.cafe_count, 0) AS cafe_count,         
     
        -- Bike lanes columns 
        COALESCE(bl.bike_lane_count, 0) AS bike_lane_count,       
        COALESCE(bl.total_bike_lane_km, 0) AS total_bike_lane_km,
        
        -- Cultural and Art/Music features
        COALESCE(cu.num_culture_places, 0) AS num_culture_places,
        COALESCE(am.num_art_places, 0) AS num_art_places,
        COALESCE(am.num_music_places, 0) AS num_music_places
    FROM
        berlin_source_data.districts d
    -- Subquery for bus/tram stops
    LEFT JOIN (
        SELECT district_id, COUNT(DISTINCT stop_id) AS bus_tram_stop_count
        FROM berlin_source_data.bus_tram_stops GROUP BY district_id
    ) b ON d.district_id = b.district_id
    -- Subquery for U-Bahn stations
    LEFT JOIN (
        SELECT district_id, COUNT(DISTINCT station) AS uban_station_count
        FROM berlin_source_data.ubahn GROUP BY district_id
    ) u ON d.district_id = u.district_id
    -- Subquery for S-Bahn stations
    LEFT JOIN (
        SELECT district_id, COUNT(DISTINCT station_id) AS sbahn_station_count
        FROM berlin_source_data.sbahn GROUP BY district_id
    ) s ON d.district_id = s.district_id
    -- Subquery for banks
    LEFT JOIN (
        SELECT district_id, COUNT(DISTINCT bank_id) AS bank_count
        FROM berlin_source_data.banks GROUP BY district_id
    ) ba ON d.district_id = ba.district_id
    -- Subquery for post offices
    LEFT JOIN (
        SELECT district_id, COUNT(DISTINCT id) AS post_office_count
        FROM berlin_source_data.post_offices GROUP BY district_id
    ) po ON d.district_id = po.district_id
    -- Subquery for supermarkets
    LEFT JOIN (
        SELECT district_id, COUNT(DISTINCT store_id) AS supermarket_count
        FROM berlin_source_data.supermarkets GROUP BY district_id
    ) su ON d.district_id = su.district_id
    -- Subquery for malls
    LEFT JOIN (
        SELECT district_id, COUNT(DISTINCT id) AS mall_count
        FROM berlin_source_data.malls GROUP BY district_id
    ) ma ON d.district_id = ma.district_id
    -- Subquery for Gyms
    LEFT JOIN (
        SELECT district_id, COUNT(DISTINCT gym_id) AS num_gyms
        FROM berlin_source_data.gyms GROUP BY district_id
    ) g ON d.district_id = g.district_id
    -- Subquery for Pools
    LEFT JOIN (
        SELECT district_id, COUNT(DISTINCT pool_id) AS num_pools
        FROM berlin_source_data.pools GROUP BY district_id
    ) p ON d.district_id = p.district_id
    -- Subquery for Sport clubs and activities
    LEFT JOIN (
        SELECT
            district_id, COUNT(DISTINCT club_id) AS num_sport_clubs
        FROM berlin_source_data.social_clubs_activities
        WHERE club = 'sport' OR leisure IN ('fitness_centre', 'sports_centre', 'stadium', 'pitch', 'track', 'ice_rink', 'marina', 'dance') OR sport IS NOT NULL
        GROUP BY district_id
    ) sc ON d.district_id = sc.district_id
    -- Subquery for Hospitals
    LEFT JOIN (
        SELECT district_id, COUNT(DISTINCT hospital_id) AS hospital_count
        FROM berlin_source_data.hospitals_refactored GROUP BY district_id
    ) h ON d.district_id = h.district_id
    -- Subquery for Pharmacies
    LEFT JOIN (
        SELECT district_id, COUNT(DISTINCT pharmacy_id) AS pharmacy_count
        FROM berlin_source_data.pharmacies GROUP BY district_id
    ) ph ON d.district_id = ph.district_id
    -- Subquery for Dental Offices
    LEFT JOIN (
        SELECT district_id, COUNT(DISTINCT osm_id) AS dental_office_count
        FROM berlin_source_data.dental_offices GROUP BY district_id
    ) de ON d.district_id = de.district_id
    -- Subquery for Crime Statistics (latest year)
    LEFT JOIN (
        SELECT
            district_id,
            SUM(total_number_cases) AS total_crime_cases_latest_year
        FROM
            berlin_source_data.crime_statistics
        WHERE
            year = (SELECT MAX(year) FROM berlin_source_data.crime_statistics)
        GROUP BY
            district_id
    ) cr ON d.district_id = cr.district_id
    -- Subquery for Evening Venues (9pm-11pm) from 'venues' table
    LEFT JOIN (
        SELECT
            district_id,
            COUNT(*) AS evening_venue_count
        FROM
            berlin_source_data.venues
        WHERE
            operating_hours_category = 'Evening (9pm-11pm)'
        GROUP BY
            district_id
    ) ev ON d.district_id = ev.district_id
    -- Subquery for Late Venues (After 11pm) from 'venues' table
    LEFT JOIN (
        SELECT
            district_id,
            COUNT(*) AS late_venue_count
        FROM
            berlin_source_data.venues
        WHERE
            operating_hours_category = 'Late (After 11pm)'
        GROUP BY
            district_id
    ) lv ON d.district_id = lv.district_id
    -- Subquery for Night Clubs from 'night_clubs' table
    LEFT JOIN (
        SELECT
            district_id,
            COUNT(DISTINCT id) AS night_club_count
        FROM
            berlin_source_data.night_clubs
        GROUP BY
            district_id
    ) nc ON d.district_id = nc.district_id
    -- Subquery for Restaurants from 'venues' table
    LEFT JOIN (
        SELECT
            district_id,
            COUNT(DISTINCT venue_id) AS restaurant_count
        FROM
            berlin_source_data.venues
        WHERE
            category = 'restaurant'
        GROUP BY
            district_id
    ) rc ON d.district_id = rc.district_id
    -- Subquery for Bars from 'venues' table
    LEFT JOIN (
        SELECT
            district_id,
            COUNT(DISTINCT venue_id) AS bar_count
        FROM
            berlin_source_data.venues
        WHERE
            category = 'bar'
        GROUP BY
            district_id
    ) bc ON d.district_id = bc.district_id
    -- Subquery for Cafes from 'venues' table
    LEFT JOIN (
        SELECT
            district_id,
            COUNT(DISTINCT venue_id) AS cafe_count
        FROM
            berlin_source_data.venues
        WHERE
            category = 'cafe'
        GROUP BY
            district_id
    ) cc ON d.district_id = cc.district_id
    -- Subquery for Bike Lanes 
    LEFT JOIN (
        SELECT
            district_id,
            COUNT(DISTINCT bikelane_id) AS bike_lane_count,
            SUM(length_m)/1000 AS total_bike_lane_km
        FROM berlin_source_data.bike_lanes
        GROUP BY district_id
    ) bl ON d.district_id = bl.district_id
    --  Cultural venues (including theaters)
    LEFT JOIN (
        SELECT 
            sca.district_id,
            COUNT(DISTINCT sca.club_id) + COALESCE(t.num_theaters, 0) AS num_culture_places
        FROM berlin_source_data.social_clubs_activities sca
        LEFT JOIN (
            SELECT district_id, COUNT(DISTINCT theater_id) AS num_theaters
            FROM berlin_source_data.theaters
            GROUP BY district_id
        ) t ON sca.district_id = t.district_id
        WHERE 
            sca.amenity IN ('community_centre', 'social_centre', 'social_club')
            OR sca.club IN ('culture', 'history', 'academic', 'charity', 'politics', 'humanist')
        GROUP BY sca.district_id, t.num_theaters
    ) cu ON d.district_id = cu.district_id

    --  Art and Music venues
    LEFT JOIN (
        SELECT 
            district_id,
            SUM(CASE WHEN art_type = 'art' THEN num_places ELSE 0 END) AS num_art_places,
            SUM(CASE WHEN art_type = 'music' THEN num_places ELSE 0 END) AS num_music_places
        FROM (
            SELECT 
                district_id,
                CASE 
                    WHEN amenity IN ('music_venue', 'music_school', 'studio') 
                         OR club = 'music' THEN 'music'
                    WHEN amenity IN ('dancing_school', 'events_venue', 'arts_centre') 
                         OR club IN ('art', 'dance') THEN 'art'
                    ELSE 'other'
                END AS art_type,
                COUNT(DISTINCT club_id) AS num_places
            FROM berlin_source_data.social_clubs_activities
            WHERE 
                amenity IN (
                    'arts_centre', 'events_venue', 
                    'music_venue', 'music_school', 
                    'dancing_school', 'studio'
                )
                OR club IN ('art', 'music', 'dance')
            GROUP BY district_id, art_type
        ) t
        GROUP BY district_id
    ) am ON d.district_id = am.district_id
);

-- 4. Revert to the original user role (good practice).
RESET ROLE;

-- Check the final table
SELECT * FROM berlin_labels.district_features;
