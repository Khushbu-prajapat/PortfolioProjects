CREATE DATABASE Portfolioproject;
SHOW DATABASES;
USE Portfolioproject;
Select * from coviddeaths_updated ORDER BY 3, 4 ;

Select * from covidvaccinations_updated ORDER BY 3, 4;

-- Select data that we are going to use

SELECT location, date ,total_cases, new_cases, total_deaths, population 
FROM Coviddeaths_updated
ORDER BY 1,2 ;

-- looking at total. cases vs total deaths
-- shows likelihood of dying if u contract covid in your country

SELECT location, date ,total_cases, total_deaths, (total_deaths/total_cases)*100 AS Deathpercentage
FROM Coviddeaths_updated
WHERE location = 'Bahrain'
ORDER BY 1,2 ;

-- looking at the total cases vs population
-- shows what percentage of population got covid

SELECT location, date ,population, total_cases,(total_cases/population)*100 AS Casepercentage
FROM Coviddeaths_updated
-- WHERE location = 'Bahrain'
ORDER BY 1,2 ;

-- looking at countries with highest infection rate compared to population

SELECT location,population, max(total_cases) , max((total_cases/population))*100 AS Percentagepopulationinfected
FROM Coviddeaths_updated
GROUP BY location, population
ORDER BY Percentagepopulationinfected DESC ;

-- showing countries with the highest death count per population

SELECT location, MAX(CAST(total_deaths AS SIGNED)) AS totaldeathcount -- CAST AS SIGNED IN MYSQL AND 'NOT INT'
FROM Coviddeaths_updated
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY totaldeathcount DESC;

-- Let's break things by continent 
-- continents by highest death count

SELECT Continent, MAX(CAST(total_deaths AS SIGNED)) AS totaldeathcount 
FROM Coviddeaths_updated
WHERE continent IS NOT NULL
GROUP BY Continent
ORDER BY totaldeathcount DESC;

SELECT location, MAX(CAST(total_deaths AS SIGNED)) AS totaldeathcount 
FROM Coviddeaths_updated
WHERE continent IS NULL
GROUP BY location
ORDER BY totaldeathcount DESC;

-- Global numbers
SELECT date , SUM(new_cases) AS total_cases, SUM(cast(total_deaths AS SIGNED)) AS total_deaths,
(SUM(cast(total_deaths AS SIGNED))/SUM(new_cases))*100 
AS deathpercentage
FROM Coviddeaths_updated
-- WHERE location = 'Bahrain'
WHERE continent is not null
GROUP BY date
ORDER BY 1,2 ;

SELECT  SUM(new_cases) AS total_cases, SUM(cast(total_deaths AS SIGNED)) AS total_deaths,
(SUM(cast(total_deaths AS SIGNED))/SUM(new_cases))*100 
AS deathpercentage
FROM Coviddeaths_updated
ORDER BY 1,2 ;

-- looking at total population vs vaccinations

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
FROM coviddeaths_updated dea
JOIN covidvaccinations_updated vac
ON dea.location = vac.location
AND dea.date = vac.date
WHERE dea.continent is not null
ORDER BY 2,3 ;

--  vaccinations per day
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CAST(vac.new_vaccinations AS SIGNED)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS rollingpeoplevaccinated
FROM coviddeaths_updated dea
JOIN covidvaccinations_updated vac
ON dea.location = vac.location
AND dea.date = vac.date
WHERE dea.continent is not null
ORDER BY 2,3 ;

-- use CTE
WITH popvsvac (continent, location, date, population, new_vaccinations,rollingpeoplevaccinated)
AS -- to use rollingpeoplevaccinated values for calculations
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CAST(vac.new_vaccinations AS SIGNED)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS rollingpeoplevaccinated
FROM coviddeaths_updated dea
JOIN covidvaccinations_updated vac
ON dea.location = vac.location
AND dea.date = vac.date
WHERE dea.continent is not null
 )
 SELECT *, (rollingpeoplevaccinated/population)*100 -- to perform this function
 FROM popvsvac;
 
 -- TEMPORARY TABLE
/* CREATE TABLE percentpopulationvaccinated
 (
Continent nvarchar (255),
Location nvarchar (255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
);
 
INSERT INTO percentpopulationvaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CAST(vac.new_vaccinations AS SIGNED)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS rollingpeoplevaccinated
FROM coviddeaths_updated dea
JOIN covidvaccinations_updated vac
ON dea.location = vac.location
AND dea.date = vac.date
WHERE dea.continent is not null;
SELECT *, (rollingpeoplevaccinated/population)*100 -- to perform this function
 FROM percentpopulationvaccinated; */
 
 -- Drop the table if it already exists
DROP TABLE IF EXISTS percentpopulationvaccinated;

-- Create the table
CREATE TABLE percentpopulationvaccinated
(
    Continent NVARCHAR(255),
    Location NVARCHAR(255),
    Date DATETIME,
    Population NUMERIC,
    New_vaccinations NUMERIC,
    RollingPeopleVaccinated NUMERIC
);

-- Insert data into the table
INSERT INTO percentpopulationvaccinated
SELECT 
    dea.continent, 
    dea.location, 
    dea.date, 
    dea.population, 
    vac.new_vaccinations,
    SUM(CAST(IFNULL(vac.new_vaccinations, 0) AS DECIMAL)) 
        OVER (PARTITION BY dea.location ORDER BY dea.date) AS rollingpeoplevaccinated
FROM coviddeaths_updated dea
JOIN covidvaccinations_updated vac
    ON dea.location = vac.location
    AND dea.date = vac.date
WHERE dea.continent IS NOT NULL;

-- Query the table to calculate percentage population vaccinated
SELECT 
    Continent, 
    Location, 
    Date, 
    Population, 
    RollingPeopleVaccinated, 
    (RollingPeopleVaccinated / Population) * 100 AS PercentagePopulationVaccinated
FROM percentpopulationvaccinated
WHERE Population > 0
ORDER BY PercentagePopulationVaccinated DESC;

-- CREATING VIEW to store data for later vizualizations

CREATE VIEW PercentagePopulationVaccinated AS
SELECT 
    dea.continent, 
    dea.location, 
    dea.date, 
    dea.population, 
    vac.new_vaccinations,
    SUM(CAST(IFNULL(vac.new_vaccinations, 0) AS DECIMAL)) 
        OVER (PARTITION BY dea.location ORDER BY dea.date) AS rollingpeoplevaccinated
FROM coviddeaths_updated dea
JOIN covidvaccinations_updated vac
    ON dea.location = vac.location
    AND dea.date = vac.date
WHERE dea.continent IS NOT NULL;

