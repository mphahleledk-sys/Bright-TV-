select * from `bright_light_project`.`default`.`bright_tv_dataset_viewership` limit 100;


----Trying to join the two datasets (User Profile & Viwership)
SELECT 
    v.UserID0,
    v.Channel2,
    v.RecordDate2,
    v.`Duration 2`,
    u.Name,
    u.Surname,
    u.Gender,
    u.Age,
    u.Province
FROM bright_light_project.default.bright_tv_dataset_viewership v
INNER JOIN bright_light_project.default.1774896982744_bright_tv_dataset u 
    ON v.UserID0 = u.UserID;

SELECT *
FROM bright_light_project.default.1774896982744_bright_tv_dataset u 
WHERE 
    -- Check Gender
    Gender IS NULL OR TRIM(Gender) = '' OR LOWER(Gender) = 'none'
    -- Check Race
    OR Race IS NULL OR TRIM(Race) = '' OR LOWER(Race) IN ('none', 'other', 'others')
    -- Check Province
    OR Province IS NULL OR TRIM(Province) = '' OR LOWER(Province) = 'none'
    -- Check Social Media Handle
    OR `Social Media Handle` IS NULL OR TRIM(`Social Media Handle`) = '';

    -- Standardizing all missing values
UPDATE bright_light_project.default.1774896982744_bright_tv_dataset u 
SET 
    Gender = CASE 
        WHEN Gender IS NULL OR TRIM(Gender) = '' OR LOWER(Gender) = 'none' THEN 'Unknown' 
        ELSE TRIM(Gender) 
    END,
    Race = CASE 
        WHEN Race IS NULL OR TRIM(Race) = '' OR LOWER(Race) = 'none' THEN 'Unknown'
        WHEN LOWER(TRIM(Race)) IN ('other', 'others') THEN 'Other'
        ELSE TRIM(Race) 
    END,
    Province = CASE 
        WHEN Province IS NULL OR TRIM(Province) = '' OR LOWER(Province) = 'none' THEN 'Unknown' 
        ELSE TRIM(Province) 
    END,
    `Social Media Handle` = COALESCE(NULLIF(TRIM(`Social Media Handle`), ''), 'Unknown');


--- Changing UCT to SA Time zone
    SELECT 
    UserID0,
    Channel2,
    -- Convert to South Africa Standard Time
    from_utc_timestamp(
        CAST(CONCAT(DATE(RecordDate2), ' ', date_format(`Recorded Time`, 'HH:mm:ss')) AS TIMESTAMP),
        'Africa/Johannesburg'
    ) AS SA_Time
FROM bright_light_project.default.bright_tv_dataset_viewership v;


SELECT
CASE
WHEN date_format(v.`Recorded Time`, 'HH:mm:ss') between '05:00:00' AND '08:59:59' THEN '01.Early Morning '
WHEN date_format(v.`Recorded Time`, 'HH:mm:ss') between '09:00:00' AND '11:59:59' THEN '02.Mid morning'
WHEN date_format(v.`Recorded Time`, 'HH:mm:ss') between '12:00:00' AND '15:59:59' THEN '03.Afternoon'
WHEN date_format(v.`Recorded Time`, 'HH:mm:ss') between '16:00:00' AND '18:59:59' THEN '04.Evening'
ELSE '05.Night'
END AS Time_viewership, 

CASE
WHEN u.Age is NULL THEN '01.unknown'
WHEN u.Age BETWEEN 18 AND 30 THEN '02.Young Adults'
WHEN u.Age BETWEEN 31 AND 45 THEN '03.Adults'
WHEN u.Age BETWEEN 46 AND 60 THEN '04.Mid Adults'
WHEN u.Age BETWEEN 61 AND 75 THEN '05.Senior Adults'
ELSE '06.Older Adults'
END AS Age_group_buckets
FROM bright_light_project.default.bright_tv_dataset_viewership v
INNER JOIN bright_light_project.default.1774896982744_bright_tv_dataset u ON v.UserID0 = u.UserID;


WITH CleanedProfiles AS (
    SELECT 
        UserID,
        Name,
        Surname,
        CASE 
            WHEN Gender IS NULL OR TRIM(Gender) = '' OR LOWER(Gender) = 'none' THEN 'Unknown'
            ELSE TRIM(Gender)
        END AS Gender,
        CASE 
            WHEN Race IS NULL OR TRIM(Race) = '' OR LOWER(Race) = 'none' THEN 'Unknown'
            WHEN LOWER(TRIM(Race)) IN ('other','others') THEN 'Other'
            ELSE TRIM(Race)
        END AS Race,
        CASE 
            WHEN Province IS NULL OR TRIM(Province) = '' OR LOWER(Province) = 'none' THEN 'Unknown'
            ELSE TRIM(Province)
        END AS Province,
        COALESCE(NULLIF(TRIM(`Social Media Handle`), ''), 'Unknown') AS SocialMediaHandle,
        Age
    FROM bright_light_project.default.1774896982744_bright_tv_dataset
),
JoinedData AS (
    SELECT 
        v.UserID0,
        v.Channel2,
        v.RecordDate2,
        from_utc_timestamp(
            CAST(CONCAT(DATE(v.RecordDate2), ' ', date_format(v.`Recorded Time`, 'HH:mm:ss')) AS TIMESTAMP),
            'Africa/Johannesburg'
        ) AS SA_Time,
        u.Gender,
        u.Race,
        u.Age,
        u.Province,
        CASE
            WHEN date_format(v.`Recorded Time`, 'HH:mm:ss') BETWEEN '05:00:00' AND '08:59:59' THEN '01.Early Morning'
            WHEN date_format(v.`Recorded Time`, 'HH:mm:ss') BETWEEN '09:00:00' AND '11:59:59' THEN '02.Mid Morning'
            WHEN date_format(v.`Recorded Time`, 'HH:mm:ss') BETWEEN '12:00:00' AND '15:59:59' THEN '03.Afternoon'
            WHEN date_format(v.`Recorded Time`, 'HH:mm:ss') BETWEEN '16:00:00' AND '18:59:59' THEN '04.Evening'
            ELSE '05.Night'
        END AS Time_viewership,
        CASE
            WHEN u.Age IS NULL THEN '01.Unknown'
            WHEN u.Age BETWEEN 18 AND 30 THEN '02.Young Adults'
            WHEN u.Age BETWEEN 31 AND 45 THEN '03.Adults'
            WHEN u.Age BETWEEN 46 AND 60 THEN '04.Mid Adults'
            WHEN u.Age BETWEEN 61 AND 75 THEN '05.Senior Adults'
            ELSE '06.Older Adults'
        END AS Age_group_buckets
    FROM bright_light_project.default.bright_tv_dataset_viewership v
    INNER JOIN CleanedProfiles u 
        ON v.UserID0 = u.UserID
)
SELECT *
FROM JoinedData;
