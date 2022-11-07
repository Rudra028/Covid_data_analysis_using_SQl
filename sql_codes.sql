-- Select data that we are going to use in this demonstration

Select location,date, total_cases, new_cases, total_deaths, population
from covid_death
order by location, date


-- Lets find out Total cases vs Total deaths for each country

select location, sum(total_deaths)/sum(total_cases)*100 as death_percent
from covid_death
where continent is not null   --Individual continent data is also included in table
group by location
order by location


-- Lets find out Total cases vs Total deaths for each country on daily basis

select location, date, coalesce(total_deaths/total_cases*100,0) as daily_death_percent
from covid_death
where continent is not null
order by location, date


-- Total cases vs Total deaths on daily basis for India
-- Find out for any country by changing location

select location, date, coalesce(sum(total_deaths)/sum(total_cases)*100,0) as death_percent
from covid_death
where location = 'India'
group by location, date
order by location, date


-- Lets find out total cases vs population for India
-- What % of people infected with covid in a country

select location, date, coalesce(total_cases,0), population, 
		coalesce((total_cases :: decimal/population)*100,0) as positive_rate
from covid_death 
where continent is not null
order by 2 asc


-- Lets look into contries with highest positivity rate

select location,population, max(total_cases) as highest_cases, 
		coalesce(max(total_cases :: decimal/population)*100,0) as total_population_infected_percent
from covid_death 
where continent is not null
group by population, location
order by 4 desc


-- Ranking total death count by country
select location, total_death, dense_rank() over(order by total_death desc) as ranking	
from	
	(select location, coalesce(max(total_deaths),0) as total_death 
	from covid_death
	where continent is not null  
	group by location) t1
order by ranking asc


-- LET'S DO SOME ANALYSIS W.R.T CONTINENTS

-- Finding total cases by continent

select loaction, max(total_cases) as total_cases
from covid_death
where continent IS not NULL and location in ('Asia','North America','Europe','South America','Africa','Oceania')
GROUP by location
order by total_cases desc


-- Finding total death count by continent

select location, max(total_deaths) as total_death
from covid_death
where continent IS NULL and location in ('Asia','North America','Europe','South America','Africa','Oceania')
GROUP by location
order by total_death desc


-- GLOBAL NUMBERS

-- let's find out daily cases and deaths collectively for the world population

SELECT date, coalesce(sum(new_cases),0) as daily_global_cases, 
		coalesce(sum(new_deaths),0) as daily_global_deaths
from covid_death
where continent is not null
group by date
order by date


-- let's find out daily death percentage collectively for the world population

SELECT date, coalesce(sum(new_cases),0) as daily_global_cases, 
		coalesce(sum(new_deaths),0) as daily_global_deaths, 
		coalesce(sum(new_deaths)/sum(new_cases)*100,0) as death_percentage
from covid_death
where continent is not null
group by date
order by date


-- WE HAVE TWO TABLES COVID_DEATH AND COVID VACCINATIONS AS COVID_VACC
-- Let's join two tables on common attributes

SELECT *
FROM covid_death cd join covid_vacc cv
	on cd.location = cv.location and cd.date = cv.date


-- Let's take a look at vaccinations percentage w.r.t population

SELECT cd.continent, cd.location, cd.date, cd.population, cd.new_cases::int, coalesce(cv.new_vaccinations::int,0) as vaccinations,
		coalesce(sum(cv.new_vaccinations)/sum(cd.population)*100,0) as vaccination_percentage
FROM covid_death cd join covid_vacc cv
	on cd.location = cv.location and cd.date = cv.date
where cd.continent is not null and new_vaccinations >0
group by cd.continent, cd.location, cd.date, cd.population, cd.new_cases::int, cv.new_vaccinations::int
order by cd.location, cd.date


-- Let's calculate rolling count of new vaccinations for each country and date

SELECT continent, location, population, date,coalesce(new_vaccinations,0), 
coalesce(sum(new_vaccinations) over(partition by location order by location,date asc),0) as people_vaccinated
from covid_vacc
where continent is not null


-- Let's calculate new vaccinations vs population for each country and date(using CTE)

with cte as  	
	(SELECT continent, location, population, date,coalesce(new_vaccinations,0) as new_vaccinations, 
	coalesce(sum(new_vaccinations) over(partition by location order by location,date asc),0) as people_vaccinated
	from covid_vacc
	where continent is not null)
SELECT *,  people_vaccinated::decimal/population::decimal*100 as vaccination_percent
from cte


-- Let's create a view table

create view demo_view as
SELECT cd.continent, cd.location, cd.date, cd.population, cd.new_cases::int, coalesce(cv.new_vaccinations::int,0) as vaccinations,
		coalesce(sum(cv.new_vaccinations)/sum(cd.population)*100,0) as vaccination_percentage
FROM covid_death cd join covid_vacc cv
	on cd.location = cv.location and cd.date = cv.date
where cd.continent is not null and new_vaccinations >0
group by cd.continent, cd.location, cd.date, cd.population, cd.new_cases::int, cv.new_vaccinations::int
order by cd.location, cd.date