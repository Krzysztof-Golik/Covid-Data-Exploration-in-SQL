

SELECT *
FROM PortfolioProject..CovidDeaths
WHERE continent is not NULL
Order by 3,4

--SELECT *
--FROM CovidVaccinations
--Order by 3,4

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM PortfolioProject..CovidDeaths
WHERE continent != ''

--Looking at total cases vs total deaths



select location, date, total_cases, total_deaths, 
(convert(float, total_deaths) / NULLIF(Convert(float, total_cases), 0))*100 as DeathPercantage
from PortfolioProject..CovidDeaths
Where location like '%states%'


--looking at total cases vs population

select location, date, population, total_cases,
(convert(float, total_cases) / NULLIF(Convert(float, population), 0))*100 as InfectionPercentage
from PortfolioProject..CovidDeaths
--Where location like '%states%'


-- looking at countries with biggest infection to population rate


select location, population, MAX(total_cases) as HighestInfectionCount,
MAX((convert(float, total_cases) / NULLIF(Convert(float, population), 0)))*100 as InfectionPercentage
from PortfolioProject..CovidDeaths
group by location, population
order by InfectionPercentage desc

-- countreis with highest death count per population

select location, MAX(cast (total_deaths as int)) as TotalDeathCount
from PortfolioProject..CovidDeaths
WHERE continent != ''
group by location
order by TotalDeathCount desc

--Lets break things down by continent

select continent, MAX(cast (total_deaths as int)) as TotalDeathCount
from PortfolioProject..CovidDeaths
WHERE continent != ''
group by continent
order by TotalDeathCount desc

--Better version below

select location, MAX(cast (total_deaths as int)) as TotalDeathCount
from PortfolioProject..CovidDeaths
WHERE continent = ''
group by location
order by TotalDeathCount desc

--Continents with the highest death count per population

select continent, MAX(cast (total_deaths as int)) as TotalDeathCount
from PortfolioProject..CovidDeaths
WHERE continent != ''
group by continent
order by TotalDeathCount desc

--Global numbers

select date, total_cases, total_deaths, 
(convert(float, total_deaths) / NULLIF(Convert(float, total_cases), 0))*100 as DeathPercantage
from PortfolioProject..CovidDeaths
Where continent != ''
group by date

select date, SUM(cast(new_cases as int)), SUM(CAST(new_deaths as int))
from PortfolioProject..CovidDeaths
Where continent != ''
group by date

select date, SUM(cast(new_cases as int)), SUM(CAST(new_deaths as int)), SUM(cast(new_deaths as int))/SUM(CAST(new_cases as int))*100  as DeathPercentage
from PortfolioProject..CovidDeaths
Where continent != ''
group by date
order by 1, 2

SELECT 
    date, 
    SUM(CAST(new_cases AS INT)) AS TotalCases, 
    SUM(CAST(new_deaths AS INT)) AS TotalDeaths,
    COALESCE(CAST(SUM(CAST(new_deaths AS INT)) AS DECIMAL(10, 2)) / NULLIF(CAST(SUM(CAST(new_cases AS INT)) AS DECIMAL(10, 2)), 0) * 100, 0) AS DeathPercentage
FROM 
    PortfolioProject..CovidDeaths
WHERE 
    continent != ''
GROUP BY 
    date
ORDER BY 
    date, TotalCases;


SELECT  
    SUM(CAST(new_cases AS INT)) AS TotalCases, 
    SUM(CAST(new_deaths AS INT)) AS TotalDeaths,
    COALESCE(CAST(SUM(CAST(new_deaths AS INT)) AS DECIMAL(20, 2)) / NULLIF(CAST(SUM(CAST(new_cases AS INT)) AS DECIMAL(20, 2)), 0) * 100, 0) AS DeathPercentage
FROM 
    PortfolioProject..CovidDeaths
WHERE 
    continent != ''
--GROUP BY 
--    date
ORDER BY 
    date, TotalCases;



--looking at total vaccinations vs total population

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.location order by dea.location, dea.date) as SumOfVac
--, (SumOfVac/population)*100
	FROM PortfolioProject..CovidDeaths as dea
	JOIN PortfolioProject..CovidVaccinations as vac
		ON dea.location = vac.location
		and dea.date = vac.date
		where dea.continent != ''
		order by 2, 3

--USE CTE



WITH PopvsVac (Continent, Location, Date, Population, new_vaccinations, SumOfVac) AS
(
    SELECT 
        dea.continent, 
        dea.location, 
        dea.date, 
        dea.population, 
        vac.new_vaccinations,
        SUM(CONVERT(INT, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.date) AS SumOfVac
    FROM 
        PortfolioProject..CovidDeaths AS dea
    JOIN 
        PortfolioProject..CovidVaccinations AS vac
    ON 
        dea.location = vac.location
    AND 
        dea.date = vac.date
    WHERE 
        dea.continent != ''
)
SELECT *, (SumOfVac/ NULLIF(population, 0))*100
FROM PopvsVac;




--Temp table


CREATE TABLE #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
date,
Population numeric,
new_vaccinations numeric,
SumOfVac numeric
)

Insert into #PercentPopulationVaccinated
        SELECT 
        dea.continent, 
        dea.location, 
        dea.date, 
        dea.population, 
        vac.new_vaccinations,
        SUM(CONVERT(INT, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.date) AS SumOfVac
    FROM 
        PortfolioProject..CovidDeaths AS dea
    JOIN 
        PortfolioProject..CovidVaccinations AS vac
    ON 
        dea.location = vac.location
    AND 
        dea.date = vac.date
    WHERE 
        dea.continent != ''
SELECT *, (SumOfVac/ NULLIF(population, 0))*100
FROM #PercentPopulationVaccinated




IF OBJECT_ID('tempdb..#PercentPopulationVaccinated') IS NOT NULL
    DROP TABLE #PercentPopulationVaccinated;


-- Create the temporary table
CREATE TABLE #PercentPopulationVaccinated
(
    Continent NVARCHAR(255),
    Location NVARCHAR(255),
    date DATETIME,
    Population NUMERIC,
    new_vaccinations NUMERIC,
    SumOfVac NUMERIC
);

-- Insert data into the temporary table
INSERT INTO #PercentPopulationVaccinated
SELECT 
    dea.continent, 
    dea.location, 
    TRY_CONVERT(DATETIME, dea.date) AS date,
    dea.population, 
    CASE 
        WHEN ISNUMERIC(vac.new_vaccinations) = 1 
        THEN CONVERT(NUMERIC, vac.new_vaccinations) 
        ELSE NULL 
    END AS new_vaccinations,
    SUM(CASE 
            WHEN ISNUMERIC(vac.new_vaccinations) = 1 
            THEN CONVERT(NUMERIC, vac.new_vaccinations) 
            ELSE 0 
        END) OVER (PARTITION BY dea.location ORDER BY TRY_CONVERT(DATETIME, dea.date)) AS SumOfVac
FROM 
    PortfolioProject..CovidDeaths AS dea
JOIN 
    PortfolioProject..CovidVaccinations AS vac
ON 
    dea.location = vac.location
AND 
    TRY_CONVERT(DATETIME, dea.date) = TRY_CONVERT(DATETIME, vac.date)
WHERE 
    dea.continent != ''
AND 
    ISNUMERIC(vac.new_vaccinations) = 1;

-- Select from the temporary table with proper division
SELECT *, 
       COALESCE((SumOfVac / NULLIF(population, 0)) * 100, 0) AS VaccinationPercentage
FROM #PercentPopulationVaccinated;

-- Drop the temporary table after use
DROP TABLE #PercentPopulationVaccinated;


select continent, MAX(cast (total_deaths as int)) as TotalDeathCount
from PortfolioProject..CovidDeaths
WHERE continent != ''
group by continent
order by TotalDeathCount desc

--Create view for future visualizations

Create View PercentPopulationVaccinated as 
SELECT 
    dea.continent, 
    dea.location, 
    TRY_CONVERT(DATETIME, dea.date) AS date,
    dea.population, 
    CASE 
        WHEN ISNUMERIC(vac.new_vaccinations) = 1 
        THEN CONVERT(NUMERIC, vac.new_vaccinations) 
        ELSE NULL 
    END AS new_vaccinations,
    SUM(CASE 
            WHEN ISNUMERIC(vac.new_vaccinations) = 1 
            THEN CONVERT(NUMERIC, vac.new_vaccinations) 
            ELSE 0 
        END) OVER (PARTITION BY dea.location ORDER BY TRY_CONVERT(DATETIME, dea.date)) AS SumOfVac
FROM 
    PortfolioProject..CovidDeaths AS dea
JOIN 
    PortfolioProject..CovidVaccinations AS vac
ON 
    dea.location = vac.location
AND 
    TRY_CONVERT(DATETIME, dea.date) = TRY_CONVERT(DATETIME, vac.date)
WHERE 
    dea.continent != ''
AND 
    ISNUMERIC(vac.new_vaccinations) = 1;
	

	SELECT * 
FROM sys.views 
WHERE name = 'PercentPopulationVaccinated';


USE YourDatabaseName;
GO

CREATE VIEW YourViewName AS
SELECT * FROM YourTableName;




USE PortfolioProject;
GO

CREATE VIEW PercentPopulationVaccinated AS 
SELECT 
    dea.continent, 
    dea.location, 
    TRY_CONVERT(DATETIME, dea.date) AS date,
    dea.population, 
    CASE 
        WHEN ISNUMERIC(vac.new_vaccinations) = 1 
        THEN CONVERT(NUMERIC, vac.new_vaccinations) 
        ELSE NULL 
    END AS new_vaccinations,
    SUM(CASE 
            WHEN ISNUMERIC(vac.new_vaccinations) = 1 
            THEN CONVERT(NUMERIC, vac.new_vaccinations) 
            ELSE 0 
        END) OVER (PARTITION BY dea.location ORDER BY TRY_CONVERT(DATETIME, dea.date)) AS SumOfVac
FROM 
    PortfolioProject..CovidDeaths AS dea
JOIN 
    PortfolioProject..CovidVaccinations AS vac
ON 
    dea.location = vac.location
AND 
    TRY_CONVERT(DATETIME, dea.date) = TRY_CONVERT(DATETIME, vac.date)
WHERE 
    dea.continent != ''
AND 
    ISNUMERIC(vac.new_vaccinations) = 1;
GO

-- Query to check if the view was created successfully
SELECT * 
FROM sys.views 
WHERE name = 'PercentPopulationVaccinated';
GO













































































