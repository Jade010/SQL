-- This is a project I created to determine what state I should move to based on data. I created this using SQL Server while working on my degree in Data Analytics. 
-- This project employs SQL table variables, data manipulation, data calculation, and updates, along with complex joins and subqueries to extract and consolidate the data from various tables.

-- creating a table variable
DECLARE @Demographics TABLE ([StateAbbrev] nvarchar(50)
				, [State Name] nvarchar(50)
				, [Population Size] decimal(8)
				, [#ofRetirees] decimal(8)
				, [%Retirees] decimal(8,2)
				, [Level of Retirees] nvarchar(50)
				, [#ofDisabledWorkers] decimal(8)
				, [%DisabledWorkers] decimal(8,2)
				, [>65Female] decimal(8)
				, [%Fem>65] decimal(8,2)
				, [>65Male] decimal(8)
				, [%Male>65] decimal(8)
				, [%Pop>65] decimal(8,2)
				, [PopChange2010-2018] decimal(8,2)
				, [#inPoverty] decimal(8)
				, [%inPoverty] decimal(8,2)
				, [PovertyCategory] nvarchar(50)
				, [HHMedIncome] decimal(8)
				, [%CompletedHS] decimal(8,2)
				, [#SmallBiz] decimal(8)
				, [#NewBiz2018] decimal(8)
				, [SmallBizJobsPerCapita] decimal(8)
				, [#NewJobsFromNewBus] decimal(8)
				, [Job Creation Rate] decimal(8,2)
				, [StatesGDPGrowth] decimal(8,2)
				, [GDP Growth Category] nvarchar(50)
				, [StatesUnemployedRate] decimal(8,2)
				, [Unemployment Category] nvarchar(50)
				, [%EmpInSmallBiz] decimal(8,2)
				, [#Wineries] decimal(8)
				, [%ofWhite] decimal(8,2)
				, [%ofBlack] decimal(8,2)
				, [%ofNativeAmerican] decimal(8,2)
				, [%ofAsian] decimal(8,2)
				, [%ofHispanic] decimal(8,2)
				, [DiversityIndex] decimal(8,2)
				, [DiversityCategory] nvarchar(50))

-- populating the rows and columns of the table
INSERT INTO @Demographics ([StateAbbrev], [State Name], [Population Size], [#ofRetirees], [#ofDisabledWorkers], [>65Female], [>65Male], [PopChange2010-2018], [#inPoverty], [%inPoverty], [HHMedIncome], [#SmallBiz],
[#NewBiz2018], [#NewJobsFromNewBus], [StatesGDPGrowth], [StatesUnemployedRate], [%EmpInSmallBiz])

SELECT pop.[State], pop.[StateName], [Population], [#Retirees], [#DisabledWorkers], [Over65Fem], [Over65Men], [PopChange2010-18], [Poverty#], [Poverty%], [MedHHIncome], [NumSmallBiz], [NumNewBiz2018], [NumNewJobsFromNewBiz2018], [StateGDPGrowth], [StateUnemploymentRate], [PercentEmpbySmBiz]

FROM [featherman].[ArraysHW_StatePopandRetirees] as pop
INNER JOIN [featherman].[ArraysHW_PopulationChange] as pc ON pc.[State] = pop.[State]
INNER JOIN [featherman].[ArraysHW_PovertyData_AndMedianIncome2016] as pov ON pov.[State] = pop.[State]
INNER JOIN [featherman].[ArraysHW_SmBizData2018] as biz ON biz.[State] = pop.[State]

UPDATE @Demographics SET [%Retirees] = IIF(([#ofRetirees]/[Population Size]) > 0, ([#ofRetirees]/[Population Size]) * 100, 0)
UPDATE @Demographics SET [%DisabledWorkers] = IIF(([#ofDisabledWorkers]/[Population Size]) > 0, ([#ofDisabledWorkers]/[Population Size])*100, 0)
UPDATE @Demographics SET [%Pop>65] = IIF(([>65Female]+[>65Male]) > 0, (([>65Female]+[>65Male])/ [Population Size])*100, 0)
UPDATE @Demographics SET [%Fem>65] = IIF(([>65Female]/[Population Size]) > 0, ([>65Female]/[Population Size]) * 100, 0) 
UPDATE @Demographics SET [%Male>65] = IIF(([>65Male]/[Population Size]) > 0, ([>65Male]/[Population Size]) * 100, 0) 

UPDATE @Demographics SET [Job Creation Rate] = IIF([#NewJobsFromNewBus] > 0, [#NewJobsFromNewBus]/[#NewBiz2018], 0)
UPDATE @Demographics SET [SmallBizJobsPerCapita] = [#SmallBiz] / ([Population Size] * [%EmpInSmallBiz] / 100)

UPDATE @Demographics SET [#Wineries] = (SELECT [NumWineries] FROM [featherman].[ArraysHW_NumBreweriesWineriesByState] as w WHERE w.[State] = [StateAbbrev])


UPDATE @Demographics SET [%CompletedHS] = (SELECT AVG([PercentCompletedHS]) FROM [featherman].[ArraysHW_PctOver25GradHS] as h WHERE h.[State] = [StateAbbrev])


UPDATE @Demographics SET [%ofWhite] = (SELECT AVG([%white]) FROM [featherman].[ArraysHW_ShareRaceByCity] as r WHERE r.[State] = [StateAbbrev])

UPDATE @Demographics SET [%ofBlack] = (SELECT AVG([%black]) FROM [featherman].[ArraysHW_ShareRaceByCity] as r WHERE r.[State] = [StateAbbrev])

UPDATE @Demographics SET [%ofNativeAmerican] = (SELECT AVG([%native_american]) FROM [featherman].[ArraysHW_ShareRaceByCity] as r WHERE r.[State] = [StateAbbrev])

UPDATE @Demographics SET [%ofAsian] = (SELECT AVG([%asian]) FROM [featherman].[ArraysHW_ShareRaceByCity] as r WHERE r.[State] = [StateAbbrev])

UPDATE @Demographics SET [%ofHispanic] = (SELECT AVG([%hispanic]) FROM [featherman].[ArraysHW_ShareRaceByCity] as r WHERE r.[State] = [StateAbbrev])

UPDATE @Demographics SET [DiversityIndex] = 1 - (POWER([%ofWhite]/100, 2) + POWER([%ofBlack]/100, 2) + POWER([%ofNativeAmerican]/100, 2) + POWER([%ofAsian]/100, 2) + POWER([%ofHispanic]/100, 2))


UPDATE @Demographics SET [DiversityCategory] = (CASE
				WHEN [DiversityIndex] <= .25 THEN 'Not diverse'
				WHEN [DiversityIndex] BETWEEN .26 AND .35 THEN 'Somewhat diverse'
				WHEN [DiversityIndex] BETWEEN .36 AND .55 THEN 'Very diverse'
				WHEN [DiversityIndex] >= .56 THEN 'Extremely diverse'
				WHEN [DiversityIndex] IS NULL THEN ''
				END)
UPDATE @Demographics SET [Level of Retirees] = (CASE
				WHEN [%Retirees] > 70.00 THEN 'Majority Retired'
				WHEN [%Retirees] BETWEEN 60.00 AND 70.00 THEN 'Many Retirees'
				WHEN [%Retirees] < 60.00 THEN 'Not as Many Retirees'
				WHEN [%Retirees] IS  NULL THEN ''
				END)

UPDATE @Demographics SET [PovertyCategory] = (CASE
			WHEN [%inPoverty] < 11.00 THEN 'Low level of Poverty'
			WHEN [%inPoverty] BETWEEN 11.00 AND 14.00 THEN 'Moderate level of Poverty'
			WHEN [%inPoverty] > 14.00 THEN 'High level of Poverty'
			WHEN [%inPoverty] IS NULL THEN ''
			END)

			
UPDATE @Demographics SET [Unemployment Category] = (CASE
			WHEN [StatesUnemployedRate] < 0.03 THEN 'Low level of Unemployment'
			WHEN [StatesUnemployedRate] BETWEEN 0.03 AND 0.05 THEN 'Moderate level of Unemployment'
			WHEN [StatesUnemployedRate] > 0.05 THEN 'High level of Unemployment'
			END )

UPDATE @Demographics SET [GDP Growth Category] = (CASE
			WHEN [StatesGDPGrowth] <= 0.02 THEN 'Stagnant Growth'
			WHEN [StatesGDPGrowth] = 0.03 THEN 'Slow Growth'
			WHEN [StatesGDPGrowth] = 0.04 THEN 'Moderate Growth'
			WHEN [StatesGDPGrowth] >= 0.05 THEN 'Fast Growth'
			END)


SELECT * FROM @Demographics




SELECT * 
INTO [MFJade].[dbo].[DemographicsOfUSA]
FROM @Demographics
