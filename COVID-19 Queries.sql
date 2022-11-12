

/*
Covid 19 Data Exploration 
Skills used: Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types, Subqueries Types
*/

-- Taking a look at the entire covid_deaths table

Select *
From covid_deaths cd 
Where continent is not null 
order by 3,4


-- Select Data that we are going to be starting with

Select Location, date, total_cases, new_cases, total_deaths, population
From covid_deaths cd 
Where continent is not null 
order by 1,2


-- Total Cases vs. Total Deaths
-- Shows the likelihood of dying if you contract covid in your country

Select Location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
From covid_deaths cd 
-- Where location like '%states%'
where continent is not null
order by 1,2


-- Total Cases vs. Population
-- Shows what percentage of the population infected with Covid

Select Location, date, Population, total_cases,  (total_cases/population)*100 as PercentPopulationInfected
From covid_deaths cd 
-- Where location like '%states%'
order by 1,2


-- Countries with Highest Infection Rate compared to Population

Select Location, Population, MAX(total_cases) as HighestInfectionCount,  Max((total_cases/population))*100 as PercentPopulationInfected
From covid_deaths cd 
-- Where location like '%states%'
Group by Location, Population
order by PercentPopulationInfected desc


-- Countries with Highest Death Count per Population

Select Location, MAX(Total_deaths) as TotalDeathCount
From covid_deaths cd 
-- Where location like '%states%'
Where continent is not null 
Group by Location
order by TotalDeathCount desc



-- BREAKING THINGS DOWN BY CONTINENT

-- Showing continents with the highest death count per population

Select continent, MAX(Total_deaths) as TotalDeathCount
From covid_deaths cd 
Where continent is not null 
Group by continent
order by TotalDeathCount desc



-- GLOBAL NUMBERS

-- Showing total number of cases, deaths and the death percentage globally 

Select SUM(new_cases) as total_cases, SUM(new_deaths) as total_deaths, SUM(new_deaths)/SUM(New_Cases)*100 as DeathPercentage
From covid_deaths cd 
where continent is not null 
order by 1,2



-- Total Population vs. Vaccinations
-- Shows Percentage of Population that has recieved at least one Covid Vaccine as a rolling sum of daily vaccinations. Joining covid deaths table with vaccinations table

Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(vac.new_vaccinations) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
-- , (RollingPeopleVaccinated/population)*100
From covid_deaths dea
Join covid_vaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 
order by 2,3


-- Using CTE to perform Calculation on Partition By in previous query

With PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
as
(
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(vac.new_vaccinations) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
-- , (RollingPeopleVaccinated/population)*100
From covid_deaths dea
Join covid_vaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 
-- order by 2,3
)
Select *, (RollingPeopleVaccinated/Population)*100 as percentage_population_vaccinated
From PopvsVac



-- Using Temp Table to perform Calculation on Partition By in previous query

DROP Table if exists PercentPopulationVaccinated
Create Table PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)

Insert into PercentPopulationVaccinated
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
--where dea.continent is not null 
--order by 2,3

Select *, (RollingPeopleVaccinated/Population)*100
From PercentPopulationVaccinated


-- Creating View to store data for later visualizations

-- Create View PercentPopulationVaccinated as

with sum_people_vaccinated as
(Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(vac.new_vaccinations) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
From covid_deaths dea
Join covid_vaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
order by RollingPeoplevaccinated)
select distinct max(RollingPeopleVaccinated) OVER (partition by location) as people_vaccinated, location
from sum_people_vaccinated
order by people_vaccinated desc

select people_vaccinated/population as percentage, people_vaccinated, location 
from covid_deaths cd 
where people_vaccinated = ()

-- Using a previous query to create a view 

/*create view new_vaccinations
(continent, location, date, population, new_vaccinations, RollingPeopleVaccinated
)
as*/
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(vac.new_vaccinations) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
From covid_deaths dea
Join covid_vaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
order by location, RollingPeoplevaccinated


select distinct max(RollingPeopleVaccinated) OVER (partition by location) as people_vaccinated, max(RollingPeopleVaccinated*100/population) OVER (partition by location) as percentage_people_vaccinated ,location
from new_vaccinations
order by percentage_people_vaccinated desc

-- Same but with people fully vaccinated instead of new vaccinations 

create view sum_people_fully_vaccinated
(continent, location, date, population, new_vaccinations, people_fully_vac
)
as
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, max(vac.people_fully_vaccinated) OVER (Partition by dea.Location Order by dea.location, dea.Date) as people_fully_vac
From covid_deaths dea
Join covid_vaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
order by location, people_fully_vac

create view people_fully_vaccinated_percentage
(people_vaccinated, percentage_people_vaccinated,location)
as
select distinct max(people_fully_vac) OVER (partition by location) as people_vaccinated, max(people_fully_vac*100/population) OVER (partition by location) as percentage_people_vaccinated ,location
from sum_people_fully_vaccinated
order by percentage_people_vaccinated desc

create view total_deaths_per_country
(total_deaths,country)
as
select distinct sum(new_deaths) as total_deaths, location
from covid_deaths cd 
group by location
order by total_deaths desc

-- Totals by continent 

/*create view totals_by_continent
(continent, total_cases, total_deaths, total_vaccinations)
as*/
select distinct cd.continent, sum(cd.new_cases) as Total_Cases, sum(cd.new_deaths) as Total_Deaths, sum(vac.new_vaccinations) as Total_Vaccinations
from covid_deaths cd 
join covid_vaccinations vac 
	On cd.location = vac.location
	and cd.date = vac.date
group by cd.continent
order by Total_Deaths desc

-- Totals globally 

/*create view totals_globally
(total_cases, total_deaths, total_vaccinations)
as*/
select distinct sum(cd.new_cases) as Total_Cases, sum(cd.new_deaths) as Total_Deaths, sum(vac.new_vaccinations) as Total_Vaccinations
from covid_deaths cd 
join covid_vaccinations vac 
	On cd.location = vac.location
	and cd.date = vac.date
	
-- Rolling sum of number of cases daily, with partition by location. After the partition by statement I had to add the order by date, otherwise for every day the 
-- query returns the total sum of cases by country.	
	
/*create view rolling_number_cases_per_country
(location, date, total_cases)
as*/
select distinct cd.location, cd.date, sum(cd.new_cases) over (partition by cd.location order by cd.date) as total_cases
from covid_deaths cd
-- where location like '%states%'


select distinct max(total_cases) as total_cases, location
from covid_deaths cd 
group by location
order by total_cases desc

-- creating a view of total cases, deaths and vaccinations by country plus aditional indicators (For Tableau visualization)

create view totals_by_country
(location, population, total_cases, total_deaths, total_vaccinations, gdp_per_capita, cardiovascular_death_rate, life_expectancy,human_development_index, percentage_deaths_per_population)
as
select cd.location, max(population) as population, sum(cd.new_cases) as total_cases, sum(cd.new_deaths) as total_deaths, sum(cv.new_vaccinations) as total_vaccinations,
max(gdp_per_capita) as gdp_per_capita, max(cardiovasc_death_rate) as cardiovascular_death_rate, max(life_expectancy) as life_expectancy, max(human_development_index) as human_development_index, (sum(cd.new_deaths)*100)/(max(cd.population))
from covid_deaths cd 
inner join covid_vaccinations cv 
	on cd.location = cv.location 
	and cd.date = cv.date
group by cd.location
order by total_vaccinations desc

-- DIFFERENT TYPES OF SUBQUERIES --

-- A subquery as a data source --

select cv.location, sum(cd.new_deaths) total_deaths, cv.total_vaccinations
from covid_deaths cd 
	inner join
	(select location, sum(new_vaccinations) total_vaccinations
	from covid_vaccinations 
	group by location) cv
	on cd.location = cv.location
group by location

-- Subquery with data fabrication --

-- Creation of a table with three different groups based on the percentage of covid deaths by population
	
select 'level_1_death%' death_percentage_level, 0 low_limit, 0.1199 high_limit
union all
select 'level_2_death%' death_percentage_level, 0.12 low_limit, 0.2599 high_limit
union all
select 'level_3_death%' death_percentage_level, 0.26 low_limit, 1 high_limit

/*create view death_rate_by_country
(location, population, death_rate)
as*/
select location, max(population) population, (sum(new_deaths))*100/max(population) death_rate
from covid_deaths cd 
group by location

select drbc.location, drbc.population, drbc.death_rate, max(levels.death_percentage_level) death_rate_level
from death_rate_by_country drbc 
	inner join
	(select 'low' death_percentage_level, 0 low_limit, 0.1199 high_limit
	union all
	select 'medium' death_percentage_level, 0.12 low_limit, 0.2599 high_limit
	union all
	select 'high' death_percentage_level, 0.26 low_limit, 1 high_limit) levels
	on drbc.death_rate
		between levels.low_limit and levels.high_limit
group by location
order by drbc.death_rate

-- A task oriented subquery --

select cv.location, sum(new_vaccinations) total_vaccinations, death_rate
from (select location, sum(new_deaths)*100/max(population) death_rate
	  from covid_deaths
	  group by location) cd
	  inner join covid_vaccinations cv 
	  on cd.location = cv.location
group by cv.location

select location, ((total_deaths*100)/total_cases) rate, total_deaths, total_cases
from totals_by_country tbc
group by location 
order by rate desc




	




