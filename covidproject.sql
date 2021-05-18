/*
	SQL Server
	Covid 19 Data Exploration 
	Skills used: Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types
*/

Select * 
From
PortfolioProject..CovidDeaths
Where continent is NOT NULL
ORDER BY 3,4

-- Select Data that we are going to be using

Select location, date, total_cases, new_cases, total_deaths, population
From
PortfolioProject..CovidDeaths
Where continent is NOT NULL
ORDER BY 1,2

-- Total Cases vs Total Deaths
-- Likelihood of dying if contracted in India
Select location, date, total_cases, total_deaths, round(((total_deaths/total_cases) * 100),4) as PercentTotalDeathsPerTotalCases
From
PortfolioProject..CovidDeaths
Where location like '%india%'
and continent is NOT NULL
ORDER BY 1,2

-- Total Cases vs Population
-- Percentage of population who got covid

Select location, date,population, total_cases, round(((total_cases/population) * 100), 4) as PercentTotalCasesPerPopulation
From
PortfolioProject..CovidDeaths
Where location like '%india%'
ORDER BY 1,2

-- Countries with highest infection rate compared to population

Select location,population, MAX(total_cases) as HighestInfectionCount, round((MAX(total_cases/population) * 100), 4) as PercentHighestInfectionPerPopulation
From
PortfolioProject..CovidDeaths
--Where location like '%india%'
Group by location, population
ORDER BY PercentHighestInfectionPerPopulation desc

-- Countries with highest death count per population

Select location,population, MAX(Cast(total_deaths as Int)) as HighestDeathCount
From
PortfolioProject..CovidDeaths
--Where location like '%india%'
Where continent is NOT NULL
Group by location, population
ORDER BY HighestDeathCount desc

-- Countries with highest infection count per population

Select location,population, MAX(total_cases) as HighestInfectionCount
From
PortfolioProject..CovidDeaths
--Where location like '%india%'
Where continent is NOT NULL
Group by location, population
ORDER BY HighestInfectionCount desc

-- Countries with highest death count per continent

Select continent, MAX(Cast(total_deaths as Int)) as HighestDeathCount
From
PortfolioProject..CovidDeaths
--Where location like '%india%'
Where continent is NOT NULL
Group by continent
ORDER BY HighestDeathCount desc

-- Global numbers

-- Overall newcases, newdeaths and deathpercentage
Select SUM(new_cases) as TotalCases, SUM(CONVERT(int,new_deaths)) as TotalDeaths, 
SUM(CONVERT(int,new_deaths))/SUM(new_cases)*100 as DeathPercentage
From
PortfolioProject..CovidDeaths
Where continent is NOT NULL

-- Date wise new cases, new deaths and deathpercentage
Select date,SUM(new_cases) as NewCases, SUM(CONVERT(int,new_deaths)) as NewDeaths, 
Round((SUM(CONVERT(int,new_deaths))/SUM(new_cases)*100), 4) as DeathPercentage
From
PortfolioProject..CovidDeaths
Where continent is NOT NULL
GROUP BY date
Order by date

-- Vaccinations table

-- Total populations vs Vaccinations
Select dea.continent,dea.location,dea.date,population, vac.new_vaccinations
From PortfolioProject..CovidDeaths as dea
JOIN PortfolioProject..CovidVaccinations as vac
ON dea.location = vac.location
AND dea.date = vac.date
Where dea.continent is NOT NULL
ORDER BY 2,3

-- Sum of new vaccincations over location
Select dea.continent,dea.location,dea.date,population, vac.new_vaccinations,
SUM(Cast(vac.new_vaccinations as int)) OVER (PARTITION BY dea.location order by dea.location,dea.date) as PeopleVaccinatedRunningTotal
From PortfolioProject..CovidDeaths as dea
JOIN PortfolioProject..CovidVaccinations as vac
ON dea.location = vac.location
AND dea.date = vac.date
Where dea.continent is NOT NULL
ORDER BY 2,3

-- CTE
WITH PopulationVsVaccination(continent, location, date, population,new_vaccincations,PeopleVaccinatedRunningTotal)
as
(
Select dea.continent,dea.location,dea.date,population, vac.new_vaccinations,
SUM(Cast(vac.new_vaccinations as int)) OVER (PARTITION BY dea.location order by dea.location,dea.date) as PeopleVaccinatedRunningTotal
From PortfolioProject..CovidDeaths as dea
JOIN PortfolioProject..CovidVaccinations as vac
ON dea.location = vac.location
AND dea.date = vac.date
Where dea.continent is NOT NULL
)

select *, (PeopleVaccinatedRunningTotal/population) * 100 as TotalVaccinationPerPopulation from PopulationVsVaccination;

-- create temp tables
DROP TABLE IF EXISTS #PopulationVsVaccination
Create table #PopulationVsVaccination
(
	Continent nvarchar(255),
	Location nvarchar(255),
	Date datetime,
	Population numeric,
	New_vaccinations numeric,
	PeopleVaccinatedRunningTotal numeric
)

INSERT INTO #PopulationVsVaccination
Select dea.continent,dea.location,dea.date,population, vac.new_vaccinations,
SUM(Cast(vac.new_vaccinations as int)) OVER (PARTITION BY dea.location order by dea.location,dea.date) as PeopleVaccinatedRunningTotal
From PortfolioProject..CovidDeaths as dea
JOIN PortfolioProject..CovidVaccinations as vac
ON dea.location = vac.location
AND dea.date = vac.date
Where dea.continent is NOT NULL

SELECT  *, (PeopleVaccinatedRunningTotal/population) * 100 as TotalVaccinationPerPopulation FROM #PopulationVsVaccination



-- Creating View to store data for visualizations - 1
-- Percent population vs Vaccinated

Create View PercentPopulationVaccinated as
Select dea.continent,dea.location,dea.date,population, vac.new_vaccinations,
SUM(Cast(vac.new_vaccinations as int)) OVER (PARTITION BY dea.location order by dea.location,dea.date) as PeopleVaccinatedRunningTotal
From PortfolioProject..CovidDeaths as dea
JOIN PortfolioProject..CovidVaccinations as vac
ON dea.location = vac.location
AND dea.date = vac.date
Where dea.continent is NOT NULL

Select * from PercentPopulationVaccinated

-- Creating View to store data for visualizations - 2
-- Date wise Cases Vs Deaths and death percentage

Create View DateWiseCasesVsDeaths as
Select date,SUM(new_cases) as NewCases, SUM(CONVERT(int,new_deaths)) as NewDeaths, 
Round((SUM(CONVERT(int,new_deaths))/SUM(new_cases)*100), 4) as DeathPercentage
From
PortfolioProject..CovidDeaths
Where continent is NOT NULL
GROUP BY date

Select * from DateWiseCasesVsDeaths

-- Creating View to store data for visualizations - 3
-- Countries with highest death count per population

Create view HighestDeathCountPerPopulation as 
Select location,population, MAX(Cast(total_deaths as Int)) as HighestDeathCount
From
PortfolioProject..CovidDeaths
--Where location like '%india%'
Where continent is NOT NULL
Group by location, population

Select * from HighestDeathCountPerPopulation
