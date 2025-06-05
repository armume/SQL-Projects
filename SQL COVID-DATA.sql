
Select *
From Portafoliocovid..Covdeath
Where continent is not null 
order by 3,4


Select date,location,population,total_cases,new_cases,total_deaths
From Portafoliocovid..Covdeath
order by 1,2

---TOTAL DE CASOS CONTRA TOTAL DE MUERTES

Select location,date, total_cases, total_deaths
From Portafoliocovid..Covdeath
WHERE location like '%states%'
order by 1,2


--TOTAL DE CASOS VRS POBLACION  MUESTRA EL PORCENTAJE DE LA POBLACION QUE TIENE COVID
Select location,date, total_cases, population, (total_cases/population)*100 as populationpercentage
From Portafoliocovid..Covdeath
WHERE location like '%Costa Rica%'
order by 1,2

---PAISES CON CON EL MAYOR PORCENTAJE DE INFECCION PERCENT POPULATION INFECTED(PPI)---
Select location, population, MAX(total_cases) AS HIGHESTINFECTION, MAX((total_cases/population))*100 as PPI 
From Portafoliocovid..Covdeath
group by location,population
order by PPI desc


-----
Select location, population,date, MAX(total_cases) AS HIGHESTINFECTION, MAX((total_cases/population))*100 as PPI 
From Portafoliocovid..Covdeath
group by location,population,date
order by PPI desc

---ORDENADO POR CONTINENTE CON LA MAYOR CANTIDAD DE DE MUERTES TOTAL DEATH COUNT (TDC)---
Select continent, MAX(cast(total_cases as int)) AS TDC 
From Portafoliocovid..Covdeath
Where continent is not null
group by continent
order by TDC desc

---

Select Location, SUM(cast(new_deaths as bigint)) as TotalDeathCount
From Portafoliocovid..Covdeath
--Where location like '%states%'
Where continent is null
and Location not in('World', 'European Union','international' )
Group by Location
order by TotalDeathCount desc


---ORDENADO POR CONTINENTE CON LOS CASOS NUEVOS A LO LARGO DEL MUNDO---
Select SUM(new_cases) as total_cases, SUM(cast(new_deaths as bigint)) as total_deaths, SUM(cast(new_deaths as bigint))/SUM(New_Cases)*100 as DeathPercentage
From Portafoliocovid..Covdeath
--Where location like '%states%'
where continent is not null 
--Group By date
order by 1,2


