$STOP_ACTIVITY = 'scripts/SFMTA_Stop_Activity_2021-01-23_2021-02-05.csv'

# Use max "on"s across WEEKDAY, SATURDAY, SUNDAY
$MAX_ONS_PER_BSID = @"
    SELECT
        *,
        MAX([Measure Values]) AS max_ons
    FROM
        "$STOP_ACTIVITY"
    WHERE
        [Measure Names] == 'Total Ons'
    GROUP BY BS_ID
    ORDER BY BS_ID
"@
# q -H '-d,' -O -C read $MAX_ONS_PER_BSID

$LOG_ONS_PER_BSID = @"
    SELECT
        *,
        (CASE
            WHEN max_ons IS NULL THEN ''
            WHEN max_ons < 2     THEN '0..2'
            WHEN max_ons < 5     THEN '2..5'
            WHEN max_ons < 10    THEN '5..10'
            WHEN max_ons < 20    THEN '10..20'
            WHEN max_ons < 50    THEN '20..50'
            WHEN max_ons < 100   THEN '50..100'
            WHEN max_ons < 200   THEN '100..200'
            WHEN max_ons < 500   THEN '200..500'
            WHEN max_ons < 1000  THEN '500..1000'
                                 ELSE '1000..'
        END) AS log_max_ons
    FROM ($MAX_ONS_PER_BSID)
    ORDER BY BS_ID
"@
# q -H '-d,' -O -C read $LOG_ONS_PER_BSID

$FULL_QUERY = @"
    SELECT
        BS_ID + 10000 AS stop_code,
        BS_ID,
        STOP_NAME,
        STOP_LAT,
        STOP_LONG,
        max_ons,
        log_max_ons
    FROM ($LOG_ONS_PER_BSID)
    ORDER BY BS_ID
"@
q -H '-d,' -O -C read $FULL_QUERY
