/*--------------------------------------------------------

Covid-19 Data Exploration to discover trends from the 
corrolation of death rate drop since the vaccine, hospitalitations.
country death rates and more. 

Author: i.R.
Date modified: 09/09/2022
--------------------------------------------------------*/

Select * 
From [Covid-Study]..CovidProject
order by 3,4			-- Order the table by locations name and date



--- Select Data that we are going to be starting with
Select Location, date, total_cases, new_cases, total_deaths, population
From [Covid-Study]..CovidProject
order by 1,2			-- Order the table by location name and date



-- Total Cases v Total Deaths (death rate)
-- The death rate is the likelihood that someone is to die by contracting covid-19
Select Location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathRate
From [Covid-Study]..CovidProject
Where location like '%guatemala%'	-- We are going to look at the death rate of guatemala
order by 1,2 



-- Total Cases v Population 
-- We are going to look at the amount of the population that has been infected
Select Location, date, total_cases, population, (total_cases/population)*100 as InfectionRate
From [Covid-Study]..CovidProject
Where location like 'guatemala'		
order by 1,2



-- Countries with highest infection rate compared to population
Select Location, population, MAX(total_cases) as HighestInfectionCount, 
cast(max(total_cases/population)*100 as decimal(10,2)) as PercentPopulationInfected
From [Covid-Study]..CovidProject
group by Location, population	-- Will display only one field per location 
order by PercentPopulationInfected desc



-- Countries with highest death count per population
Select Location, max(cast(Total_deaths as int)) as TotalDeathCount
from [Covid-Study]..CovidProject
where continent is not null
Group by location
order by TotalDeathCount desc



-- organazing data by continent with the highest death count
/* (we might need to fix this later on cus i think is grabing just the max death count from
the country that has the max deaths. )
*/
Select continent, max(cast(Total_deaths as int)) as TotalDeathCount
from [Covid-Study]..CovidProject
where continent is not null
Group by continent
order by TotalDeathCount desc



-- Global Numbers



Select sum(new_cases) as total_cases, sum(cast(new_deaths as int)) as total_deaths, 
sum(cast(new_deaths as int))/sum(new_cases)*100 as DeathRate
from [Covid-Study]..CovidProject
where continent is not null
-- Group by date
order by 1,2



-- Total Population v Vaccinations
-- We are showing the rolling number of people vaccinated by country and by each passing day
Select continent, location, date, population, new_vaccinations,
sum(cast(new_vaccinations as BIGINT)) over (Partition by location 
order by location, date ROWS UNBOUNDED PRECEDING) as PeopleVaccinated
from [Covid-Study]..CovidProject
where continent is not null
order by 2,3
/*
We had to use BIGINT in the cast aggregate section instead 
of int due to the size of the sum

As well we had to use ROW UNBOUNDED PRECEDING [all rows before the current row -> fixed]
*/



-- Using CTE to perform calculation on partition By in previous query
-- Using the with clause to make a temporary table, in this case PopvVac

With PopvVac (Continent, location, date, population
, new_vaccinations, PeopleVaccinated)
as
(
Select continent, location, date, population, new_vaccinations
, sum(cast(new_vaccinations as BIGINT)) over (Partition by location 
order by location, date ROWS UNBOUNDED PRECEDING) as PeopleVaccinated
from [Covid-Study]..CovidProject
where continent is not null
)
Select *, (PeopleVaccinated/Population)*100 as VaccinationRate
from PopvVac



-- Creating a new table as temp instead of CTE
Drop Table if exists #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated(
	Continent nvarchar(255),
	location nvarchar(255),
	Date datetime,
	Population numeric,
	new_Vaccinations numeric,
	PeopleVaccinated numeric
)
Insert into #PercentPopulationVaccinated
Select continent, location, date, population, new_vaccinations
, sum(cast(new_vaccinations as BIGINT)) over (Partition by location 
order by location, date ROWS UNBOUNDED PRECEDING) as PeopleVaccinated
from [Covid-Study]..CovidProject
Select *, (PeopleVaccinated/Population)*100 as VaccinationRate
from #PercentPopulationVaccinated



-- We are going to create a view to store data for visualization
Use [Covid-Study]		-- We had tu specify that we're going to be using that data base
Go
Create View PercentPopulationVaccinated as
Select continent, location, date, population, new_vaccinations
, sum(cast(new_vaccinations as BIGINT)) over (Partition by location 
order by location, date ROWS UNBOUNDED PRECEDING) as PeopleVaccinated
from [Covid-Study]..CovidProject
Where continent is not null

