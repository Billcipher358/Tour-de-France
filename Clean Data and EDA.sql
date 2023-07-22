-- DATA CLEANING
--1.CLEANING DATA IN TABLE FINISHER
--Create new column Country
select*from finisher

select Rider, trim(')' from trim('('from right(Rider,5)))
from finisher

alter table finisher
add Country varchar(MAX);

update finisher
set Country =  trim(')' from trim('('from right(rider,5)))

select Rider, Country from finisher 
where Country in (
select Country
from finisher
where Country not like '[A-Z][A-Z][A-Z]')

UPDATE finisher
SET Country = 
    CASE 
        WHEN Rider = 'Lance Armstrong (USA)[a]' and Country = 'A)[a]' THEN 'USA'
        WHEN Rider in ('Vicenzo Borgarello (Italy)','Ottavio Pratesi (Italy)') and Country = 'taly' THEN 'ITA'
        WHEN Rider = 'Jan Ullrich (GER)[b]' and Country = 'R)[b]' THEN 'GER'
		WHEN Rider = 'Lance Armstrong (USA)[b]' and Country = 'A)[b]' THEN 'USA'
		WHEN Rider = 'Franco Pellizotti (ITA)[a]' and Country = 'A)[a]' THEN 'ITA'
		WHEN Rider = 'Alberto Contador (ESP)[a]' and Country = 'P)[a]' THEN 'ESP'
		WHEN Rider = 'Denis Menchov (RUS)[c]' and Country = 'S)[c]' THEN 'RUS'
		WHEN Rider = 'Chris Froome (UK)' and Country = ' (UK' THEN 'UK'
		WHEN Rider = 'Nairo Quintana (COL)[56]' and Country = '[56]' THEN 'COL'
		WHEN Rider = 'Aleksandr Vlasova' and Country = 'ov[a]' THEN NULL
		WHEN Rider = 'Aleksandr Riabushenko' and Country = 'henko' THEN NULL
        ELSE Country -- Keep the original value if it doesn't match any conditions
    END

UPDATE finisher
SET Rider = REPLACE(Rider, 'Aleksandr Vlasov[a]', 'Aleksandr Vlasova')
WHERE Rider = 'Aleksandr Vlasov[a]'

DELETE FROM finisher
WHERE Rider = 'not attributed[a]'

--Fix the column Rider
select Rider from finisher

ALTER TABLE Finisher
ADD Extracted_Rider NVARCHAR(100)

UPDATE finisher
SET Extracted_Rider =
    CASE
      WHEN CHARINDEX('(', Rider) > 0 THEN SUBSTRING(Rider, 1, CHARINDEX('(', Rider) - 1)
      ELSE Rider
    END 

select Extracted_Rider from finisher where Extracted_Rider not like '[A-Z][a-z]% [A-Z][a-z]%' or  Extracted_Rider LIKE '%[0-9]%'

UPDATE finisher
SET Extracted_Rider  = 
    CASE 
        WHEN Extracted_Rider  = 'Rodolfo Muller[27] ' THEN 'Rodolfo Muller'
		ELSE Extracted_Rider  -- Keep the original value if it doesn't match any conditions
    END

ALTER TABLE finisher
drop column Rider


--2.CLEANING DATA IN TABLE STAGES
select * from stages

--Fix the column Type
UPDATE stages
SET Type = 
    CASE 
        WHEN Type in ('Flat','Flat cobblestone stage') THEN 'Flat stage'
		 WHEN Type in ('High mountain stage','Medium mountain stage','Medium mountain stage[c]','Medium-mountain stage','Mountain Stage','Mountain Stage (s)','Stage with mountain','Stage with mountain(s)','Stage with mountains') THEN 'Mountain stage'      
         WHEN Type = 'Plain stage with cobblestones' THEN 'Plain stage'
		ELSE Type -- Keep the original value if it doesn't match any conditions
    END

select Type, count(*) from stages group by Type

--3.CLEANING DATA IN TABLE TOURS
select * from tours

--fix the Dates column
update tours
set Dates = replace(Dates, '?','-')

--fix the Stages column
alter table tours
add stage_num numeric, Prologue nvarchar(100), Split_stage numeric

update tours
set stage_num = cast(trim(SUBSTRING(Stages, 0, 3)) as numeric)
UPDATE tours
SET Prologue = CASE WHEN Stages LIKE '%Prologue%' THEN 'Prologue' ELSE 'No prologue' END
UPDATE tours
SET Split_stage = Case
	when Stages like '%two%' then 2
	when Stages like '%three%' then 3
	when Stages like '%four%' then 4
	when Stages like '%five%' then 5
	when Stages like '%six%' then 6
	when Stages like '%seven%' then 7
	when Stages like '%eight%' then 8
	else 0 end

alter table tours
drop column Stages

--Fix the column Distance
update tours
set Distance = replace(Distance, '?', ' ')

alter table tours
add Distance_km varchar(max), Distance_mi varchar(max)

update tours
set Distance_km = trim(SUBSTRING(Distance, 0, CHARINDEX('km', Distance)))

update tours
set Distance_mi = trim(SUBSTRING(Distance, CHARINDEX('(', Distance)+1, CHARINDEX('mi', Distance) -CHARINDEX('(', Distance)-1))

alter table tours
drop column Distance

--4.CLEANING DATA IN TABLE WINNERS
select * from winners

--fix the column Rider
select Rider from winners where Rider like '%?%'
--The name of the riders contains French character, so I decide to keep them originally, the same as the Team column

-- EXPLORATORY DATA ANALYSIS

-- When did the Tour de France start?
select min(Year) from tours 

-- How long has been Tour de France celebrated?
select max(Year)-min(Year) from tours 

-- How many riders do register to attend the tournament? 
select sum(Starters)/count(Year) as attend from tours

-- Approximately how many countries are the riders come from?
select count(distinct Country) from finisher 

-- Which year has the longest route? How long was it? How many stages?
select Year, Distance_mi, Stage_num
from tours
order by Distance_mi desc
 
 -- How many average stages per tournament?
select avg(stage_num) from tours

-- What is the average length of the route per tournament?
select avg(cast(replace(Distance_mi,',','') as numeric)) from tours

-- How many different sections of stages? Who is the most winner of each section
with cte as(
select distinct Type, Winner, count(Winner) as winner_times,
Rank() OVER (PARTITION BY Type ORDER BY count(Winner) DESC) AS Rank
from stages 
group by Type, Winner)

select Type, Winner 
from cte 
where Rank = 1

-- How much percentage of riders can finish all stage?
select sum(cast(Finishers as float)) / sum(cast(Starters as float))*100 from tours

-- Who are the best historical riders? What are their best record?
with cte as(
select top 5 Rider, count(Rider) as champion from winners
group by Rider
order by champion desc)

select cte.Rider, cte.champion, w.Avg_Speed, w.Time
from cte
inner join winners as w
on cte.Rider = w.Rider

--What are the best historical team? How many championships do they have?
select Team, count(Team) as champion
from winners
group by Team
order by champion desc
