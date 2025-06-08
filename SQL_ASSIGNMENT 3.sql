
--TASK 1 

WITH ConsecutiveTasks AS (
    SELECT
        Task_ID,
        Start_Date,
        End_Date,
        ROW_NUMBER() OVER (ORDER BY Start_Date) - ROW_NUMBER() OVER (PARTITION BY DATEADD(DAY, -DATEDIFF(DAY, '2000-01-01', Start_Date), Start_Date)) AS Project_Group
    FROM Projects
),
ProjectBoundaries AS (
    SELECT
        MIN(Start_Date) AS Project_Start_Date,
        MAX(End_Date) AS Project_End_Date,
        DATEDIFF(DAY, MIN(Start_Date), MAX(End_Date)) + 1 AS Project_Duration
    FROM ConsecutiveTasks
    GROUP BY Project_Group
)
SELECT
    Project_Start_Date,
    Project_End_Date
FROM ProjectBoundaries
ORDER BY Project_Duration, Project_Start_Date;

--TASK 2

WITH FriendSalaries AS (
    SELECT 
        s.ID AS Student_ID,
        s.Name AS Student_Name,
        p1.Salary AS Student_Salary,
        p2.Salary AS Friend_Salary
    FROM Students s
    JOIN Friends f ON s.ID = f.ID
    JOIN Packages p1 ON s.ID = p1.ID
    JOIN Packages p2 ON f.Friend_ID = p2.ID
)
SELECT 
    Student_Name
FROM FriendSalaries
WHERE Friend_Salary > Student_Salary
ORDER BY Friend_Salary;

--TASK 3

SELECT DISTINCT 
    f1.X, 
    f1.Y
FROM Functions f1
JOIN Functions f2
ON f1.X = f2.Y AND f1.Y = f2.X
WHERE f1.X <= f1.Y
ORDER BY f1.X, f1.Y;


--TASK 4

SELECT
    c.contest_id,
    c.hacker_id,
    c.name,
    SUM(COALESCE(ss.total_submissions, 0)),
    SUM(COALESCE(ss.total_accepted_submissions, 0)),
    SUM(COALESCE(vs.total_views, 0)),
    SUM(COALESCE(vs.total_unique_views, 0))
FROM
    Contests c
LEFT JOIN
    Colleges col ON c.contest_id = col.contest_id
LEFT JOIN
    Challenges ch ON col.college_id = ch.college_id
LEFT JOIN
    View_Stats vs ON ch.challenge_id = vs.challenge_id
LEFT JOIN
    Submission_Stats ss ON ch.challenge_id = ss.challenge_id
GROUP BY
    c.contest_id, c.hacker_id, c.name
HAVING
    SUM(COALESCE(ss.total_submissions, 0)) != 0 OR
    SUM(COALESCE(ss.total_accepted_submissions, 0)) != 0 OR
    SUM(COALESCE(vs.total_views, 0)) != 0 OR
    SUM(COALESCE(vs.total_unique_views, 0)) != 0
ORDER BY
    c.contest_id;

--TASK 5

WITH DailySubmissions AS (
    SELECT
        submission_date,
        hacker_id,
        COUNT(submission_id) AS total_submissions
    FROM
        Submissions
    GROUP BY
        submission_date, hacker_id
),
RankedDailySubmissions AS (
    SELECT
        submission_date,
        hacker_id,
        total_submissions,
        RANK() OVER (PARTITION BY submission_date ORDER BY total_submissions DESC, hacker_id ASC) as rnk
    FROM
        DailySubmissions
),
UniqueHackersPerDay AS (
    SELECT DISTINCT
        submission_date,
        hacker_id
    FROM
        Submissions
),
CumulativeUniqueHackers AS (
    SELECT
        s.submission_date,
        COUNT(DISTINCT uh.hacker_id) AS unique_hackers_count
    FROM
        Submissions s
    JOIN
        UniqueHackersPerDay uh ON uh.submission_date <= s.submission_date
    GROUP BY
        s.submission_date
)
SELECT
    s.submission_date,
    cu.unique_hackers_count,
    rds.hacker_id,
    h.name
FROM
    Submissions s
JOIN
    CumulativeUniqueHackers cu ON s.submission_date = cu.submission_date
JOIN
    RankedDailySubmissions rds ON s.submission_date = rds.submission_date AND s.hacker_id = rds.hacker_id
JOIN
    Hackers h ON rds.hacker_id = h.hacker_id
WHERE
    rds.rnk = 1
GROUP BY
    s.submission_date, cu.unique_hackers_count, rds.hacker_id, h.name
ORDER BY
    s.submission_date;

--TASK 6

SELECT
    ROUND(
        ABS(MAX(LAT_N) - MIN(LAT_N)) +
        ABS(MAX(LONG_W) - MIN(LONG_W)),
    4)
FROM
    STATION;

--TASK 7

WITH RECURSIVE Numbers AS (
    SELECT 2 AS n
    UNION ALL
    SELECT n + 1 FROM Numbers WHERE n < 1000
)
SELECT GROUP_CONCAT(n ORDER BY n SEPARATOR '&')
FROM Numbers
WHERE NOT EXISTS (
    SELECT 1
    FROM Numbers AS d
    WHERE d.n < n AND n % d.n = 0
);

--TASK 8

WITH RankedOccupations AS (
    SELECT
        Name,
        Occupation,
        ROW_NUMBER() OVER (PARTITION BY Occupation ORDER BY Name) AS rn
    FROM
        OCCUPATIONS
)
SELECT
    MAX(CASE WHEN Occupation = 'Doctor' THEN Name ELSE NULL END) AS Doctor,
    MAX(CASE WHEN Occupation = 'Professor' THEN Name ELSE NULL END) AS Professor,
    MAX(CASE WHEN Occupation = 'Singer' THEN Name ELSE NULL END) AS Singer,
    MAX(CASE WHEN Occupation = 'Actor' THEN Name ELSE NULL END) AS Actor
FROM
    RankedOccupations
GROUP BY
    rn
ORDER BY
    rn;

--TASK 9

SELECT
    b.N,
    CASE
        WHEN b.P IS NULL THEN 'Root' -- A node is a Root if its parent is NULL
        WHEN children.P IS NULL THEN 'Leaf' -- A node is a Leaf if it is not a parent to any other node
        ELSE 'Inner' -- Otherwise, it is an Inner node (has a parent and is a parent)
    END AS NodeType
FROM
    BST b
LEFT JOIN
    (SELECT DISTINCT P FROM BST WHERE P IS NOT NULL) AS children ON b.N = children.P
ORDER BY
    b.N;

--TASK 10

SELECT
    c.company_code,
    c.founder,
    COUNT(DISTINCT lm.lead_manager_code),
    COUNT(DISTINCT sm.senior_manager_code),
    COUNT(DISTINCT m.manager_code),
    COUNT(DISTINCT e.employee_code)
FROM
    Company c
LEFT JOIN
    Lead_Manager lm ON c.company_code = lm.company_code
LEFT JOIN
    Senior_Manager sm ON c.company_code = sm.company_code
LEFT JOIN
    Manager m ON c.company_code = m.company_code
LEFT JOIN
    Employee e ON c.company_code = e.company_code
GROUP BY
    c.company_code,
    c.founder
ORDER BY
    CAST(SUBSTRING(c.company_code, 2) AS UNSIGNED INTEGER);

--TASK 11

SELECT
    S.Name
FROM
    Students S
JOIN
    Packages P1 ON S.ID = P1.ID -- Join to get the student's own salary (P1)
JOIN
    Friends F ON S.ID = F.ID -- Join to find the student's best friend (F)
JOIN
    Packages P2 ON F.Friend_ID = P2.ID -- Join to get the best friend's salary (P2)
WHERE
    P2.Salary > P1.Salary -- Filter where the friend's salary is higher
ORDER BY
    P2.Salary ASC; -- Order by the friend's salary in ascending order

--TASK12



--TASK 15
SELECT
    S.Name,
    P.Salary
FROM
    Students S
JOIN
    (SELECT ID, Salary, ROW_NUMBER() OVER (ORDER BY Salary DESC) AS rn FROM Packages) AS P
ON
    S.ID = P.ID
WHERE
    P.rn <= 5;

--TASK 16

UPDATE YourTableName
SET
    column_A = column_A + column_B,
    column_B = column_A - column_B,
    column_A = column_A - column_B;

--TASK 19

SELECT
    A.artist_name,
    G.genre_name
FROM
    ARTIST A
JOIN
    ARTIST_TO_GENRE_MAPPING ATM ON A.artist_id = ATM.artist_id
JOIN
    GENRE G ON ATM.genre_id = G.genre_id
ORDER BY
    A.artist_name ASC;

--TASK 20

SELECT
    C.contest_id,
    C.hacker_id,
    C.name,
    SUM(COALESCE(SS.total_submissions, 0)),
    SUM(COALESCE(SS.total_accepted_submissions, 0)),
    SUM(COALESCE(VS.total_views, 0)),
    SUM(COALESCE(VS.total_unique_views, 0))
FROM
    Contests C
LEFT JOIN
    Colleges Col ON C.contest_id = Col.contest_id
LEFT JOIN
    Challenges Ch ON Col.college_id = Ch.college_id
LEFT JOIN
    View_Stats VS ON Ch.challenge_id = VS.challenge_id
LEFT JOIN
    Submission_Stats SS ON Ch.challenge_id = SS.challenge_id
GROUP BY
    C.contest_id, C.hacker_id, C.name
HAVING
    SUM(COALESCE(SS.total_submissions, 0)) != 0 OR
    SUM(COALESCE(SS.total_accepted_submissions, 0)) != 0 OR
    SUM(COALESCE(VS.total_views, 0)) != 0 OR
    SUM(COALESCE(VS.total_unique_views, 0)) != 0
ORDER BY
    C.contest_id;
