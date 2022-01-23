/********************************/
/***** Queries for Tableau *****/
/*******************************/


--1 
Select 
	SUM(new_cases) AS total_cases
	,SUM(CAST(new_deaths AS int)) AS total_deaths
	,(SUM(CAST(new_deaths AS int))/SUM(new_cases)) AS DeathPercentage
FROM CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 1,2


--2
Select 
	location
	,SUM(CAST(new_deaths AS int)) AS TotalDeathCount
FROM CovidDeaths
Where continent IS NULL
AND location NOT IN ('World','European Union','International','Upper middle income','High income','Lower middle income','Low income')
GROUP BY location
ORDER BY TotalDeathCount DESC


--3
Select 
	location
	,population
	,MAX(total_cases) AS HighestInfectionCount
	,MAX((total_cases/population))*100 AS PercentpopulationInfected
	--,(total_cases/population)*100 
FROM CovidDeaths
GROUP BY location,population,total_cases
ORDER BY PercentpopulationInfected DESC


--4
Select 
	location
	,population
	,date
	,MAX(total_cases) AS HighestInfectionCount
	,MAX((total_cases/population)) * 100 AS PercentPopulationInfected
FROM CovidDeaths
GROUP BY location,population,date
ORDER BY PercentPopulationInfected DESC