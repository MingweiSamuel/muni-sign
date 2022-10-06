$STOP_CENSUS = 'scripts/MarcelMoran_Bus_Stop_Census_Open_Data.csv'

# SIGNAGE RANKING:
# "no_sign",
# "paint_on_pavement",
# "paint_on_metal_pole",
# "paint_on_telephone_pole",
# "shelter_marking",
# "metal_sign"

$BEST_SIGNAGE = @"
    SELECT
        *,
        (CASE
            WHEN INSTR(Signage, 'metal_sign')               THEN '0 metal_sign'
            WHEN INSTR(Signage, 'shelter_marking')          THEN '1 shelter_marking'
            WHEN INSTR(Signage, 'paint_on_telephone_pole')  THEN '2 paint_on_telephone_pole'
            WHEN INSTR(Signage, 'paint_on_metal_pole')      THEN '3 paint_on_metal_pole'
            WHEN INSTR(Signage, 'paint_on_pavement')        THEN '4 paint_on_pavement'
                                                            ELSE '5 no_sign'
        END) AS best_signage
    FROM "$STOP_CENSUS"
"@
q -H '-d,' -O -C read $BEST_SIGNAGE
