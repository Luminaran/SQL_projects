SELECT Location, date, total_cases, new_cases, total_deaths, population
FROM covid_data_deaths$
ORDER BY 1, 2

-- Looking at Total Cases VS Total Deaths, and likehood of dying of covid in the United States

SELECT Location, date, total_cases, new_cases, total_deaths, population, (total_deaths/total_cases) * 100 AS death_percentage
FROM covid_data_deaths$
WHERE location like '%states%'
ORDER BY 1, 2

--Looking at total cases vs population in USA
-- See what % of people in thbe USA got COVID at some point
SELECT Location, date, Population, total_cases, (total_cases/Population)  AS total_infected
FROM covid_data_deaths$
WHERE location like '%states%'
ORDER BY 1, 2

-- Countries with highest infection rate per capita
SELECT Location, Population, MAX(total_cases) AS highest_infection_count, ROUND((MAX(total_cases)/Population), 3)  AS percent_pop_infected
FROM covid_data_deaths$
GROUP BY Location, Population
ORDER BY percent_pop_infected DESC

-- Countries with highest total deaths
SELECT Location, MAX(cast(total_deaths as int)) AS total_death_count
FROM covid_data_deaths$
WHERE continent is not null
GROUP BY Location
ORDER BY total_death_count DESC

-- total deaths by continent
SELECT Location, MAX(cast(total_deaths as int)) AS total_death_count
FROM covid_data_deaths$
WHERE continent is null AND location NOT LIKE '%income%' AND location NOT LIKE '%world%'
GROUP BY Location
ORDER BY total_death_count DESC

-- Total likelihood of dying if you get covid globally
SELECT SUM(new_cases) AS total_cases, SUM(cast(new_deaths as int)) AS total_deaths, ROUND(SUM(cast(new_deaths as int))/SUM(new_cases), 4) as global_death_rate
FROM covid_data_deaths$
WHERE continent is not null
ORDER BY 1, 2

-- Look at second table
SELECT *
FROM covid_data_vaccinations$

-- Join tables and look at total population VS vaccinations for USA
SELECT death.continent, death.location, death.date, death.population, vacc.new_vaccinations,
SUM(Cast(vacc.new_vaccinations as bigint)) OVER (Partition by death.Location ORDER by death.location, death.date) AS rolling_vaccinations
FROM covid_data_deaths$ death
JOIN covid_data_vaccinations$ vacc
ON death.location = vacc.location AND death.date = vacc.date
WHERE death.location like '%Canada%'
ORDER BY 2, 3

-- USE CTE
With pop_vs_vacc (continent, location, date, population, new_vaccinations, rolling_vaccinations)
as
(
SELECT death.continent, death.location, death.date, death.population, vacc.new_vaccinations,
SUM(Cast(vacc.new_vaccinations as bigint)) OVER (Partition by death.Location ORDER by death.location, death.date) AS rolling_vaccinations
FROM covid_data_deaths$ death
JOIN covid_data_vaccinations$ vacc
ON death.location = vacc.location AND death.date = vacc.date
WHERE death.location like '%Canada%'

)
SELECT *, (rolling_vaccinations/population)  AS vaccination_ratio
FROM pop_vs_vacc
order by date

--- Worldwide total population vs vaccination rate
SELECT death.continent, death.location, death.date, death.population, vacc.new_vaccinations,
SUM(Cast(vacc.new_vaccinations as bigint)) OVER (Partition by death.Location ORDER BY death.location, death.date) AS rolling_vaccinations_global
FROM covid_data_deaths$ death
JOIN covid_data_vaccinations$ vacc
ON death.location = vacc.location AND death.date = vacc.date
WHERE death.continent IS NOT null AND death.location NOT LIKE '%income%' AND death.location NOT LIKE '%world%'
ORDER BY 2, 3

-- USE CTE
With pop_vs_vacc_global (continent, location, date, population, new_vaccinations, rolling_vaccinations_global)
as
(
SELECT death.continent, death.location, death.date, death.population, vacc.new_vaccinations,
SUM(Cast(vacc.new_vaccinations as bigint)) OVER (Partition by death.Location ORDER by death.location, death.date) AS rolling_vaccinations_global
FROM covid_data_deaths$ death
JOIN covid_data_vaccinations$ vacc
ON death.location = vacc.location AND death.date = vacc.date


)
SELECT *, (rolling_vaccinations_global/population)  AS vaccination_ratio_global
FROM pop_vs_vacc_global
order by location, date

-- Create View for data visualizations
CREATE VIEW global_rolling_vaccinations
as
SELECT death.continent, death.location, death.date, death.population, vacc.new_vaccinations,
SUM(Cast(vacc.new_vaccinations as bigint)) OVER (Partition by death.Location ORDER BY death.location, death.date) AS rolling_vaccinations_global
FROM covid_data_deaths$ death
JOIN covid_data_vaccinations$ vacc
ON death.location = vacc.location AND death.date = vacc.date
WHERE death.continent IS NOT null AND death.location NOT LIKE '%income%' AND death.location NOT LIKE '%world%'

SELECT * 
FROM global_rolling_vaccinations