
Select *
From CovidProject..CovidVaccinations
Order by 3,4

Select *
From CovidProject..CovidDeaths
Where continent is not null
Order by 3,4

-- Covid Deaths table:

Select location, date, total_cases, new_cases, total_deaths, population
From CovidProject..CovidDeaths
order by 1,2

-- Investigating total cases vs total deaths in Egypt

Select location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS 'Death_Percentage'
From CovidProject..CovidDeaths
where location = 'Egypt'
Order by 1,2

-- Investigating total cases vs population
Select location, date, total_cases, population, (total_cases/population)*100 AS 'Infection_Percentage'
From CovidProject..CovidDeaths
Where location = 'Egypt'
Order by 1,2

-- Delete an Unknown country
DELETE FROM CovidProject..CovidDeaths 
WHERE location = 'Israel';

-- Countries of high infection count 
Select location, population, MAX(total_cases) as 'HighInfectionCount', Max((total_cases/population)*100) AS 'PopulationInfectedPercent'
From CovidProject..CovidDeaths
Group by location, population
Order by PopulationInfectedPercent DESC

-- Countries of high death count per population

Select location, population, MAX(cast(total_deaths as int)) as 'TotalDeathCount'
From CovidProject..CovidDeaths
Where continent is not null
Group by location, population
Order by TotalDeathCount DESC

-- Continent point of view

Select continent, MAX(cast(total_deaths as int)) as 'TotalDeathCount'
From CovidProject..CovidDeaths
Where continent is not null
Group by continent
Order by TotalDeathCount DESC


-- Global analysis

Select date, SUM(new_cases) AS 'GlobalCases', SUM(cast(new_deaths as int)) AS 'GlobalDeaths',
SUM(cast(new_deaths as int))/SUM(new_cases)*100 AS 'DeathPercentage'
From CovidProject..CovidDeaths
Where continent is not null
AND new_cases is not null
AND new_deaths is not null
Group by date
order by 1,2


-- Join CovidDeaths & CovidVaccinations

Select *
From CovidProject..CovidDeaths AS CD
Join CovidProject..CovidVaccinations AS CV
	On CD.location = CV.location
	AND CD.date = CV.date


-- Total population vs vaccinations
-- use CTE

With PopvsVac (continent, location, date, population, new_vaccinations)
as
(
Select CD.location, CD.date, CD.population, CV.new_vaccinations,
SUM(CONVERT(bigint, CV.new_vaccinations)) OVER (Partition by CD.location Order by CD.location,
CD.date) AS 'RollingPeopleVaccinated'
From CovidProject..CovidDeaths AS CD
Join CovidProject..CovidVaccinations AS CV
	On CD.location = CV.location
	AND CD.date = CV.date
Where CD.continent is not null
)
Select *
From PopvsVac


-- Rate of people vaccinated Worldwide

Select CD.location, CD.date,
(SUM(CONVERT(int, CV.people_vaccinated))/CD.population)*100 AS 'PeopleVaccinatedPercentage'
From CovidProject..CovidDeaths AS CD
Join CovidProject..CovidVaccinations AS CV
	On CD.location = CV.location
	AND CD.date = CV.date
Where CD.continent is not null
Group by CD.location, CD.date, CD.population


-- Rate of people vaccinated in Egypt

Select CD.location, CD.date,
(SUM(CONVERT(int, CV.people_vaccinated))/CD.population)*100 AS 'PeopleVaccinatedPercentage'
From CovidProject..CovidDeaths AS CD
Join CovidProject..CovidVaccinations AS CV
	On CD.location = CV.location
	AND CD.date = CV.date
Where CD.continent is not null
AND CD.location = 'Egypt'
Group by CD.location, CD.date, CD.population


-- TEMP table:

DROP Table if exists #PercentPeopleVacinated
Create Table #PercentPeopleVacinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations nvarchar(255),
RollingPeopleVaccinated numeric
)

Insert into #PercentPeopleVacinated
Select CD.location, CD.date, CD.population, CV.new_vaccinations,
SUM(CONVERT(int, CV.new_vaccinations)) OVER (Partition by CD.location Order by CD.location,
CD.date) AS 'RollingPeopleVaccinated'

From CovidProject..CovidDeaths AS CD
Join CovidProject..CovidVaccinations AS CV
	On CD.location = CV.location
	AND CD.date = CV.date
--Where CD.continent is not null

Select *, (RollingPeopleVaccinated/Population)*100
From #PercentPeopleVacinated


-- Creating View to visualization

Create View NewPercentPeopleVacinated AS
Select CD.location, CD.date, CD.population, CV.new_vaccinations,
SUM(CONVERT(bigint, CV.new_vaccinations)) OVER (Partition by CD.location Order by CD.location,
CD.date) AS 'RollingPeopleVaccinated'

From CovidProject..CovidDeaths AS CD
Join CovidProject..CovidVaccinations AS CV
	On CD.location = CV.location
	AND CD.date = CV.date
Where CD.continent is not null

Select *
From NewPercentPeopleVacinated