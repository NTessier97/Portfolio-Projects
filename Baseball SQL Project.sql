
--Barry Bonds career statistics

SELECT nameFIRST, nameLAST, yearID, teamID, G, AB, R, H, 2B, 3B, HR, RBI, SB, CS, BB, SO, IBB, HBP, SH, SF, GIDP FROM Batting
	INNER JOIN people
	ON batting.playerID=people.playerID
	WHERE nameFIRST = 'Barry'
	AND nameLAST = 'Bonds'
	ORDER BY yearID ASC;

--Tim Lincecum Career statistics

SELECT nameFIRST, nameLAST, yearID, teamID, W, L, G, GS, CG, SHO, SV, H, ER, HR, BB, SO, BAOpp, ERA FROM pitching
	INNER JOIN people
	ON pitching.playerID = people.playerID
	WHERE nameFIRST = 'Tim'
	AND nameLAST = 'Lincecum'
	ORDER BY yearID ASC;

--Players with more RBIs than games played in a season

SELECT yearID, nameFIRST, nameLAST, G, RBI, RBI-G AS Differential FROM batting
	JOIN people
	ON batting.playerID = people.playerID
	WHERE RBI>G
	AND G >= 100
	ORDER BY Differential DESC;

--ERAs of 300 game winners

ALTER TABLE pitching
ADD InningsPitched AS IPOuts/3

SELECT nameFIRST, nameLAST, SUM(W) AS W, CONVERT(DECIMAL(3,2),(9*(CAST(SUM(ER) AS numeric)/CAST(SUM(InningsPitched) AS numeric)))) AS ERA FROM Pitching
	INNER JOIN people
	ON pitching.playerID = people.playerID
	WHERE InningsPitched >=1
	GROUP BY nameFIRST, nameLAST
	HAVING SUM(W) >= 300
	ORDER BY ERA ASC;

--Players to both win 20 games and lose 20 games in a season post 1900 

SELECT yearID, nameFIRST, nameLAST, W, L FROM Pitching
	JOIN people
	ON Pitching.playerID = people.playerID
	WHERE W >= 20 AND L >=20 AND yearID >= 1900
	ORDER BY yearID DESC;

--Players with both 200 Homeruns and 200 Stolen Bases in career

SELECT CONCAT(nameFIRST,' ',nameLAST) AS FullName, SUM(HR) AS HR, SUM(SB) AS SB FROM people
	JOIN batting
	ON batting.playerID = people.playerID
	GROUP BY batting.playerID, people.nameFIRST, people.nameLAST
	HAVING SUM(HR) >= 200 AND SUM(SB) >= 200
	ORDER BY HR DESC;

--Highest percentage of hits as homeruns in a season minimum 300 at bats

SELECT yearID, nameFIRST, nameLAST, H, HR, CONVERT(DECIMAL(4,2),(CAST(HR AS numeric)/CAST(H AS numeric))*100) AS pctHR FROM batting
	INNER JOIN people
	ON batting.playerID = people.playerID
	WHERE HR != 0 AND AB >= 300
	ORDER BY pctHR DESC;

--Players with 100 home runs on three different teams

SELECT teams.nameFIRST, teams.nameLAST, teams.teamHR, teams.teamID FROM 
	(SELECT people.nameFIRST, people.nameLAST, batting.teamID, SUM(batting.HR) AS teamHR, COUNT(*) OVER(PARTITION BY batting.playerID) AS numteams FROM batting
		INNER JOIN people
		ON batting.playerID = people.playerID
		GROUP BY batting.playerID, people.nameFIRST, people.nameLAST, batting.teamID
		HAVING SUM(HR) >= 100) AS Teams
		WHERE numTeams = 3;
		
--Players hitting homeruns in 20 or more seasons

SELECT nameFIRST, nameLAST, COUNT(DISTINCT batting.yearID) AS numSeasons FROM batting
	INNER JOIN people
	ON batting.playerID=people.playerID
	WHERE HR >= 1
	GROUP BY nameFirst, nameLAST, batting.playerID
	HAVING COUNT(DISTINCT batting.yearID) >=20
	ORDER BY numSeasons DESC;

--Most Homeruns by left handed hitting shortstops (sort of)
--Due to the imitations of the database this query only accurately works if a player exclusively played shortstop for a full season. 
--Would need a game by game/positional breakdown from batting to complete it.

SELECT DISTINCT nameFIRST, nameLAST, bats, POS, SUM(fielding.G) AS G, SUM(batting.HR) AS HR FROM batting	
	INNER JOIN fielding
	ON batting.playerID=fielding.playerID AND batting.yearID=fielding.yearID
	INNER JOIN people
	ON fielding.playerID=people.playerID
	WHERE bats = 'L' AND POS = 'SS'
	GROUP BY batting.playerID, nameFIRST, nameLAST, bats, POS
	HAVING SUM(fielding.G) >= 1000
	ORDER BY HR DESC;

--Most HRs by country

SELECT nameFIRST, nameLAST, birthCountry, HR FROM
	(SELECT nameFIRST, nameLAST, birthCountry, SUM(HR) AS HR, RANK() OVER(PARTITION BY birthCountry ORDER BY SUM(HR) DESC) AS Rank FROM batting
		INNER JOIN people
		ON batting.playerID=people.playerID
		WHERE birthCountry IS NOT NULL AND nameFIRST IS NOT NULL
		GROUP BY batting.playerID, birthCountry, nameFIRST, nameLAST) AS CountryHR
	WHERE Rank = 1;

--Youngest Debut

SELECT CONCAT(nameFIRST,' ', nameLAST) AS FullName, YEAR(Debut)-birthYear AS DebutAge FROM people
	GROUP BY nameFIRST, nameLAST, birthYear, debut
	HAVING YEAR(Debut)-birthYear IS NOT NULL
	ORDER BY DebutAge DESC;

--Most HR in a season to not lead MLB

SELECT yearID, CONCAT(nameFIRST, ' ', nameLAST) AS FullName, HR FROM
	(SELECT yearID, nameFIRST, nameLAST, HR, RANK() OVER(PARTITION BY yearID ORDER BY HR DESC) AS Rank FROM batting
		INNER JOIN people
		ON batting.playerID=people.playerID) AS SECHR
	WHERE Rank = 2
	ORDER BY HR DESC;

--Most Career HR and never lead MLB
SELECT nameFIRST, nameLAST, SUM(HR) AS CareerHR FROM batting
	INNER JOIN people
	ON batting.playerID=people.playerID
	WHERE batting.playerID NOT IN
		(SELECT playerID FROM	
			(SELECT batting.playerID, RANK() OVER(PARTITION BY yearID ORDER BY HR DESC) AS HRRank FROM batting
				GROUP BY batting.playerID, yearID, HR) AS CareerNo
			WHERE HRRank = 1)
	GROUP BY batting.playerID, nameFIRST, nameLAST
	ORDER BY CareerHR DESC;
