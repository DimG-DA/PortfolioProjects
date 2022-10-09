
--1*Shows number of confirmed cases and deaths before vaccine rollout by country
SELECT cvd.location, SUM(cvd.new_cases) AS cases, SUM(CAST(cvd.new_deaths AS FLOAT)) AS deaths,
ROUND(SUM(CAST(cvd.new_deaths AS FLOAT)) / SUM(cvd.new_cases+0.0001)*100,2) AS death_pcent_prevac
FROM DA_Portfolio.dbo.Covid19Deaths$ cvd
LEFT JOIN DA_Portfolio.dbo.Covid19Vaccinations$ cvv
ON cvd.location = cvv.location AND cvd.date = cvv.date
WHERE cvd.continent IS NOT NULL AND CAST(cvv.total_vaccinations AS FLOAT) =0
GROUP BY cvd.location
ORDER BY 1

--2*Shows number of confirmed cases and deaths after vaccine rollout by country
--+0.0001 prevents zero division error
SELECT cvd.location, SUM(cvd.new_cases) AS cases, SUM(CAST(cvd.new_deaths AS FLOAT)) AS deaths,
ROUND(SUM(CAST(cvd.new_deaths AS FLOAT)) / SUM(cvd.new_cases+0.0001)*100,2) AS death_pcent_prevac
FROM DA_Portfolio.dbo.Covid19Deaths$ cvd
LEFT JOIN DA_Portfolio.dbo.Covid19Vaccinations$ cvv
ON cvd.location = cvv.location AND cvd.date = cvv.date
WHERE cvd.continent IS NOT NULL AND CAST(cvv.total_vaccinations AS FLOAT) >1
GROUP BY cvd.location
ORDER BY 1

 
--3* Shows confirmed cases and deaths by country
SELECT location, SUM(new_cases) AS cases, SUM(CAST(new_deaths AS FLOAT)) AS deaths,
ROUND(SUM(CAST(new_deaths AS FLOAT))/ SUM(new_cases+0.0001)*100,2) AS death_pcent
FROM DA_Portfolio.dbo.Covid19Deaths$
GROUP BY location
ORDER BY 1

--4*Shows number of confirmed cases and deaths occured in the UK before vaccine rollout
SELECT cvd.location, SUM(cvd.new_cases) AS cases, SUM(CAST(cvd.new_deaths AS FLOAT)) AS deaths,
ROUND(SUM(CAST(cvd.new_deaths AS FLOAT)) / SUM(cvd.new_cases+0.0001)*100,2) AS death_pcent_prevac
FROM DA_Portfolio.dbo.Covid19Deaths$ cvd
LEFT JOIN DA_Portfolio.dbo.Covid19Vaccinations$ cvv
ON cvd.location = cvv.location AND cvd.date = cvv.date
WHERE cvd.continent IS NOT NULL AND CAST(cvv.total_vaccinations AS FLOAT) =0 AND cvd.location = 'United Kingdom'
GROUP BY cvd.location
ORDER BY 1

--*Shows how many cases and deaths occured globally after introduction of vaccines by country
--+0.0001 prevents zero division error
SELECT cvd.location, SUM(cvd.new_cases) AS cases, SUM(CAST(cvd.new_deaths AS FLOAT)) AS deaths,
ROUND(SUM(CAST(cvd.new_deaths AS FLOAT)) / SUM(cvd.new_cases+0.0001)*100,2) AS death_pcent_prevac
FROM DA_Portfolio.dbo.Covid19Deaths$ cvd
LEFT JOIN DA_Portfolio.dbo.Covid19Vaccinations$ cvv
ON cvd.location = cvv.location AND cvd.date = cvv.date
WHERE cvd.continent IS NOT NULL AND CAST(cvv.total_vaccinations AS FLOAT) >1 AND cvd.location = 'United Kingdom'
GROUP BY cvd.location
ORDER BY 1


--5*Shows number of months taken for vaccine rollout to begin
WITH T1 AS
(SELECT MAX(date) AS last_date, location
FROM DA_Portfolio.dbo.Covid19Vaccinations$
WHERE continent IS NOT NULL AND location = 'United Kingdom' AND new_vaccinations > 0
GROUP BY location)
SELECT MIN(cvv.date) first_day, MAX(cvv.date) day_prevac, DATEDIFF(month, MIN(cvv.date), MAX(cvv.date)) month_interval
FROM DA_Portfolio.dbo.Covid19Vaccinations$ cvv
JOIN T1 ON cvv.location = T1.location
WHERE continent IS NOT NULL AND cvv.location = 'United Kingdom' AND new_vaccinations = 0 AND date < T1.last_date;



--6*Shows total interval in months between first confirmed covid 19 case to rollout of vaccine in each country
WITH T1 AS
(SELECT MAX(date) AS last_date, location
FROM DA_Portfolio.dbo.Covid19Vaccinations$
WHERE continent IS NOT NULL AND new_vaccinations > 0
GROUP BY location)
SELECT T1.location, MIN(cvd.date) first_day, MAX(cvv.date) day_prevac, DATEDIFF(month, MIN(cvd.date), MAX(cvd.date)) month_interval
FROM DA_Portfolio.dbo.Covid19Deaths$ cvd
JOIN T1 ON cvd.location = T1.location
JOIN DA_Portfolio.dbo.Covid19Vaccinations$ cvv
ON cvd.location = cvv.location AND cvd.date = cvv.date
WHERE cvd.continent IS NOT NULL AND new_vaccinations = 0 AND cvv.date < T1.last_date
GROUP BY T1.location
ORDER BY 4, 2;



--7* Shows global vaccination rate and percentile by country
WITH T1 AS
(SELECT location, ROUND(MAX(people_vaccinated/population)*100,2) AS vax_pcent
FROM DA_Portfolio.dbo.Covid19Vaccinations$ 
WHERE continent IS NOT NULL
GROUP BY location
HAVING ROUND(MAX(people_vaccinated/population)*100,2) < 100)
SELECT *, NTILE(10) OVER (ORDER BY T1.vax_pcent) AS ntile_vax
FROM T1
ORDER BY 2 DESC, 1


SELECT av_age_due_covid, av_age_with_covid, med_age_due_covid, med_age_with_covid FROM DA_Portfolio.dbo.Covid19Deaths$
WHERE location = 'United Kingdom'

--8* Ranking countries (locations) by their gdp_per_capita then ordering by rate of death of confirmed covid cases.
WITH T1 AS
(SELECT DISTINCT(location), CASE WHEN gdp_per_capita > 5.0e4 THEN '1st' 
			 WHEN gdp_per_capita > CAST(3.8e4 AS FLOAT) AND gdp_per_capita <= CAST(5.0e4 AS FLOAT) THEN '2nd' 
			 WHEN gdp_per_capita > CAST(2.6e4 AS FLOAT) AND gdp_per_capita <= CAST(3.8e4 AS FLOAT) THEN '3rd'
			 WHEN gdp_per_capita > CAST(2.0e4 AS FLOAT) AND gdp_per_capita <= CAST(2.6e4 AS FLOAT) THEN '4th'
			 WHEN gdp_per_capita > CAST(1.4e4 AS FLOAT) AND gdp_per_capita <= CAST(2.0e4 AS FLOAT) THEN '5th'
			 WHEN gdp_per_capita > CAST(8.0e3 AS FLOAT) AND gdp_per_capita <= CAST(1.4e4 AS FLOAT) THEN '6th'
			 WHEN gdp_per_capita > CAST(2.0e3 AS FLOAT) AND gdp_per_capita <= CAST(8.0e3 AS FLOAT) THEN '7th'
			 WHEN gdp_per_capita > CAST(0 AS FLOAT) AND gdp_per_capita <= CAST(2.0e3 AS FLOAT) THEN '8th'
			 END AS gdp_cap_rank
FROM DA_Portfolio.dbo.Covid19Deaths$
WHERE continent IS NOT NULL)
SELECT cvd.location, MAX(cvd.total_cases) AS cases, MAX(cvd.total_deaths) AS deaths, 
ROUND(MAX(cvd.total_deaths) / MAX(cvd.total_cases+0.00001)*100,2), T1.gdp_cap_rank
FROM DA_Portfolio.dbo.Covid19Deaths$ cvd
JOIN T1 on cvd.location = T1.location
GROUP BY cvd.location, T1.gdp_cap_rank
ORDER BY 5, 4 DESC


--9*Show max number of confirmed cases and deaths per day in UK
SELECT location, MAX(CAST(new_deaths AS FLOAT)) AS max_deaths, MAX(new_cases) AS max_cases, ROUND(MAX(CAST(new_deaths AS FLOAT))/MAX(new_cases)*100,2) AS max_deathrate
FROM DA_Portfolio.dbo.Covid19Deaths$ 
WHERE continent IS NOT NULL AND location = 'United Kingdom'
GROUP BY location

--10*
SELECT location, ROUND(AVG(CAST(new_deaths AS FLOAT)),0) AS max_deaths, ROUND(AVG(new_cases),0) AS max_cases, ROUND(AVG(CAST(new_deaths AS FLOAT))/AVG(new_cases)*100,2) AS avg_deathrate
FROM DA_Portfolio.dbo.Covid19Deaths$ 
WHERE continent IS NOT NULL AND location = 'United Kingdom'
GROUP BY location


--11* Use percentile window function to rank countries based on the gdp-per-capita and ordering by % of death rate.
WITH T1 AS
(SELECT DISTINCT(location), NTILE(8) OVER(ORDER BY gdp_per_capita) AS ntile_gdp
FROM DA_Portfolio.dbo.Covid19Deaths$
WHERE continent IS NOT NULL)
SELECT cvd.location, MAX(cvd.total_cases) AS cases, MAX(cvd.total_deaths) AS deaths, 
ROUND(MAX(cvd.total_deaths) / MAX(cvd.total_cases+0.00001)*100,2) AS death_pcent, T1.ntile_gdp
FROM DA_Portfolio.dbo.Covid19Deaths$ cvd
JOIN T1 on cvd.location = T1.location
GROUP BY cvd.location, T1.ntile_gdp
ORDER BY 5, 4 DESC


--12*Shows months in which death rates are equal to or below 1%*
SELECT month_year, SUM(new_cases) AS cases, SUM(CAST(new_deaths AS FLOAT)) AS deaths, ROUND(SUM(CAST(new_deaths AS FLOAT))/ SUM(new_cases)* 100,2) AS death_pcent
FROM DA_Portfolio.dbo.Covid19Deaths$
WHERE continent IS NOT NULL AND location = 'United Kingdom'
GROUP BY month_year
HAVING ROUND(SUM(CAST(new_deaths AS FLOAT))/ SUM(new_cases)* 100,2) <= 1
ORDER BY 1

--13*Shows monthly total of new cases, deaths and percentage of confirmed cases who died from covid*
SELECT month_year, SUM(new_cases) AS cases, SUM(CAST(new_deaths AS FLOAT)) AS deaths, ROUND(SUM(CAST(new_deaths AS FLOAT))/ SUM(new_cases)* 100,2) AS death_pcent
FROM DA_Portfolio.dbo.Covid19Deaths$
WHERE continent IS NOT NULL AND location = 'United Kingdom'
GROUP BY month_year
ORDER BY 1


--14*Shows total confirmed cases & deaths and ordered by countries with highest death rate
SELECT location, SUM(new_cases) AS cases, SUM(CAST(new_deaths AS FLOAT)) AS deaths, ROUND(SUM(CAST(new_deaths AS FLOAT))/SUM(new_cases)*100,2) AS death_pcent
FROM DA_Portfolio.dbo.Covid19Deaths$
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY 4 DESC


--15* Shows a comparison of country and continent death rates from Covid19 
WITH T1 AS
(SELECT continent, SUM(CAST(new_deaths AS FLOAT)) AS deaths, SUM(new_cases) AS cases, 
ROUND(SUM(CAST(new_deaths AS FLOAT)) / SUM(new_cases),4) AS cont_pcent
FROM DA_Portfolio.dbo.Covid19Deaths$
GROUP BY continent)
SELECT T1.continent, cvd.location,  
ROUND(SUM(CAST(new_deaths AS FLOAT))/SUM(new_cases)*100,4) AS death_pcent, 
ROUND(MAX(T1.cont_pcent),4) AS cont_pcent
FROM T1 LEFT JOIN DA_Portfolio.dbo.Covid19Deaths$ cvd
ON T1.continent = cvd.continent
WHERE T1.continent IS NOT NULL
GROUP BY cvd.location, T1.continent
ORDER BY 1,3 DESC

--16* Shows percentage of populaton that have passed from covid by country
SELECT location, MAX(population) AS population, SUM(CAST(new_deaths AS FLOAT)) AS deaths, ROUND(SUM(CAST(new_deaths AS FLOAT))/MAX(population),4) AS death_by_pop
FROM DA_Portfolio.dbo.Covid19Deaths$
GROUP BY location
ORDER BY 1

--*17 Shows total covid deaths by month
SELECT MONTH(date) cal_month, MAX(CAST(total_deaths AS FLOAT)) max_death
FROM DA_Portfolio.dbo.Covid19Deaths$
WHERE continent IS NOT NULL
GROUP BY MONTH(date)
ORDER BY 2 DESC

--18* Union of daily deaths in October 2020, 2021 & 2022 (Month with most deaths)
SELECT date, SUM(CAST(new_deaths AS FLOAT)) new_deaths, YEAR(date) year
FROM DA_Portfolio.dbo.Covid19Deaths$
WHERE continent IS NOT NULL AND MONTH(date) = 10 AND YEAR(date) = 2020
GROUP BY date
UNION
SELECT date, SUM(CAST(new_deaths AS FLOAT)), YEAR(date) year
FROM DA_Portfolio.dbo.Covid19Deaths$
WHERE continent IS NOT NULL AND MONTH(date) = 10 AND YEAR(date) = 2021
GROUP BY date
UNION
SELECT date, SUM(CAST(new_deaths AS FLOAT)), YEAR(date) year
FROM DA_Portfolio.dbo.Covid19Deaths$
WHERE continent IS NOT NULL AND MONTH(date) = 10 AND YEAR(date) = 2022
GROUP BY date
ORDER BY date


--19* Shows daily deaths by monthly total for the UK
SELECT location, month_year, SUM(CAST(new_deaths AS FLOAT)) deaths, SUM(CAST(new_deaths AS FLOAT)) OVER (PARTITION BY month_year) AS monthly_death_count, 
ROUND(SUM(CAST(new_deaths AS FLOAT))/ SUM(CAST(new_deaths AS FLOAT)) OVER (PARTITION BY month_year)*100,2) AS pcent
FROM DA_Portfolio.dbo.Covid19Deaths$
WHERE continent IS NOT NULL AND location = 'United Kingdom'
GROUP BY location, month_year, new_deaths

