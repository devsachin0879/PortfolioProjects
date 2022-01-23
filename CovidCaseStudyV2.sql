--Select TOP 10000 * FROM [PortfolioProject].[dbo].[CovidDeaths] 
--Where continent IS NOT NULL 
--Order by 3,4

--Select TOP 10000 * FROM [PortfolioProject].[dbo].[CovidDeaths] 
--Where continent = 'North America'
--Order by 3,4

--Select TOP 10 * FROM [PortfolioProject].[dbo].[CovidVaccination]


-- Select data that we are going to be using
Select 
	[location]
	,[date]
	,[total_cases]
	,[new_cases]
	,[total_deaths]
	,[population]
FROM CovidDeaths
WHERE continent IS NOT NULL AND location like '%lithua%'
Order by 1,2 --i.e.location and date
;

-- looking at total cases and total deaths
--shows likelihood of dying if a person contract covid in a particular country
Select 
	[location]
	,[date]
	,[total_cases]
	,[total_deaths]
	,(total_deaths/total_cases) *100 AS [Death %]
FROM CovidDeaths
Where [location] = 'India' AND continent IS NOT NULL 
Order by 1,2
;


-- looking at the total cases vs populatoin
-- sjows % of population got covid
Select 
	[location]
	,[date]
	,[population]
	,[total_cases]
	,(total_cases/[population])*100 AS [Cases %]
FROM CovidDeaths
--Where location = 'India'AND continent IS NOT NULL 
Order by 1,2
;


-- looking at countries with highest infection rate compared to population
Select 
	[location]
	,[population]
	,MAX([total_cases]) AS [Higest Infection Count]
	,MAX((total_cases/[population])*100) AS [Max Infection %]
FROM CovidDeaths
--Where continent IS NOT NULL
GROUP BY location,population
Order by MAX((total_cases/[population])*100) DESC


-- looking at countries with highest death count 
Select 
	[location]
	,[population]
	,MAX(CAST(total_deaths as int)) AS [Higest Death Count]
FROM CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location,population
Order by [Higest Death Count] DESC


--- BREAKING THINGS DOWN BY CONTINENT

--showing continents with the highest death count per population
Select 
	continent
	--location
	,MAX(CAST(total_deaths as int)) AS [Higest Death Count]
FROM CovidDeaths
WHERE continent IS NOT NULL
GROUP BY continent
Order by [Higest Death Count] DESC


-- GLOBAL NUMBERS

-- showing total cases, deaths and death % globally per day
Select 
	date
	,SUM(new_cases) AS [Total Cases]
	,SUM(CAST(new_deaths AS int))  AS [Total Deaths]
	,(SUM(CAST(new_deaths AS int))/SUM(new_cases))*100 AS [Global Death % per day] 
FROM CovidDeaths
WHERE continent IS NOT NULL
GROUP BY [date]
ORDER BY 1,2


---- showing total cases, deaths and death % globally till 21-01-2022
Create View PercentDeathGlobal AS 
Select 
	SUM(new_cases) AS [Total Cases]
	,SUM(CAST(new_deaths AS int))  AS [Total Deaths]
	,(SUM(CAST(new_deaths AS int))/SUM(new_cases))*100 AS [Global Death % per day] 
FROM CovidDeaths
WHERE continent IS NOT NULL

Select * FROM PercentDeathGlobal


--- looking at total vacination vs total population
Select 
	dea.continent
	,dea.location
	,dea.date,dea.population
	,vac.new_vaccinations
	,SUM(CAST(vac.new_vaccinations AS bigint)) OVER(partition by dea.location ORDER by dea.location,dea.date) AS [Rolling Sum Vaccinations]
FROM CovidDeaths AS dea
JOIN CovidVaccination AS vac
ON dea.location = vac.location
AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2,3


---- Temp Table
DROP TABLE IF EXISTS #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(
continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
new_vaccinations numeric,
[Rolling Sum Vaccinations] numeric
)
INSERT INTO #PercentPopulationVaccinated
Select 
	dea.continent
	,dea.location
	,dea.date
	,dea.population
	,vac.new_vaccinations
	,SUM(CAST(vac.new_vaccinations AS bigint)) OVER(partition by dea.location ORDER by dea.location,dea.date) AS [Rolling Sum Vaccinations]
FROM CovidDeaths AS dea
JOIN CovidVaccination AS vac
ON dea.location = vac.location
AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
--ORDER BY 2,3

Select *,([Rolling Sum Vaccinations]/population)*100
FROM #PercentPopulationVaccinated

--- CTE

With PopVsVac(continent,location,date,population,new_vaccinations,[Rolling Sum Vaccinations])
AS
(
Select 
	dea.continent
	,dea.location
	,dea.date
	,dea.population
	,vac.new_vaccinations
	,SUM(CAST(vac.new_vaccinations AS bigint)) OVER(partition by dea.location ORDER by dea.location,dea.date) AS [Rolling Sum Vaccinations]
FROM CovidDeaths AS dea
JOIN CovidVaccination AS vac
ON dea.location = vac.location
AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
--ORDER BY 2,3
)
Select *,([Rolling Sum Vaccinations]/population)*100
FROM PopVsVac




--- VIEW to store data for later visualisation

CREATE VIEW PercentPopulationVaccinated AS
Select 
	dea.continent
	,dea.location
	,dea.date
	,dea.population
	,vac.new_vaccinations
	,SUM(CAST(vac.new_vaccinations AS bigint)) OVER(partition by dea.location ORDER by dea.location,dea.date) AS [Rolling Sum Vaccinations]
FROM CovidDeaths AS dea
JOIN CovidVaccination AS vac
ON dea.location = vac.location
AND dea.date = vac.date
WHERE dea.continent IS NOT NULL

Select * FROM PercentPopulationVaccinated

-- Vaccination VS population
Select 
	tblVac.continent
	,tblVac.location
	,tblVac.population
	,MAX(tblVac.[Rolling Sum Vaccinations]) AS [MAX Vaccination]
	,(MAX(tblVac.[Rolling Sum Vaccinations])/tblVac.population)*100 AS [% Vaccination]
FROM 
(
Select 
	dea.continent
	,dea.location
	,dea.date
	,dea.population
	,vac.new_vaccinations
	,SUM(CAST(vac.new_vaccinations AS bigint)) OVER(partition by dea.location ORDER by dea.location,dea.date) AS [Rolling Sum Vaccinations]
FROM CovidDeaths AS dea
JOIN CovidVaccination AS vac
ON dea.location = vac.location
AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
--ORDER BY 2,3
) AS tblVac
--WHERE tblVac.continent IS NOT NULL
GROUP BY tblVac.location,tblVac.continent,tblVac.population
ORDER BY [% Vaccination] DESC,tblVac.location 
