---raw data

create table lifestyle (person_id INT PRIMARY KEY,gender text,age INT, occupation text, sleep_duration numeric,
quality_of_sleep INT, physical_activity_level INT, stress_level INT, bmi_category text,heart_rate INT, 
sleep_disorder text);

select * from lifestyle;

---normalised data

--- person table 
create table Person ( person_id INT PRIMARY KEY, gender text, age INT, occupation text);

insert into Person (person_id, gender, age, occupation)
select person_id,gender, age,occupation
from lifestyle;

select * from Person;


/* sleep table */
create table sleep_details(sleep_id serial primary key,person_id int references person(person_id),sleep_duration
numeric,quality_of_sleep int,sleep_disorder text);

insert into sleep_details(person_id,sleep_duration,quality_of_sleep,sleep_disorder)
select person_id, sleep_duration,quality_of_sleep,sleep_disorder 
from lifestyle;

select * from sleep_details;


/*health info table*/
create table Health_Info (health_id SERIAL PRIMARY KEY, person_id INT REFERENCES Person(person_id),physical_activity INT,
stress_level INT, bmi_category text,heart_rate INT,daily_steps INT );

insert into health_info (person_id,physical_activity, stress_level,bmi_category, heart_rate, daily_steps) 
select Person_ID, Physical_Activity_level, Stress_Level, BMI_Category, Heart_Rate,Daily_Steps 
from lifestyle;

select * from health_info;


/* Problems */


---category 1 : demographic insights


--- 1. which occupation tends to get less sleep? 
select p.occupation, round(avg(s.sleep_duration),2) as avg_sleep
from Person p 
join sleep_details s on p.person_id=s.person_id 
group by p.occupation 
order by avg_sleep asc;


--- 2. Are males or females more stressed? 
select p.gender,round(avg(h.stress_level),2) as avg_stress 
from Person p 
join health_info h on p.person_id=h.person_id
group by p.gender
order by avg_stress desc;


--- 3. which age groups shows the lowest sleep quality? 
select case  when p.age between 20 and 29 then '20-29' 
   when p.age between 30 and 39 then '30-39'
   when p.age between 40 and 49 then '40-49' 
   else '50+' 
   end as age_group,
  round(avg(s.quality_of_sleep),2) as avg_quality
from Person p
join sleep_details s on p.person_id=s.person_id
group by age_group 
order by avg_quality asc;


--- category 2 : sleep patterns


---4. which BMI category has lowest average quality of sleep ?
select h.bmi_category, round(avg(s.quality_of_sleep),2) as avg_quality
from sleep_details s 
join health_info h on s.person_id = h.person_id 
group by h.bmi_category 
order by avg_quality desc;


---category 3 : health,stress and activity

--- 5. which occupation has highest average daily steps ?
select p.occupation,round(avg(h.Daily_Steps), 2) as avg_steps 
from health_info h 
join person p on p.person_id=h.person_id 
group by p.occupation 
order by avg_steps desc;


---6. Does a lower heart rate correlate with higher sleep quality among individuals?
select round(avg(heart_rate),2)as avg_hr
from health_info
where person_id in(
 select person_id 
 from sleep_details
 where quality_of_sleep>7
); 


---7. What are the most and least stressful occupations based on average stress levels?
with stress_cte as (
  select p.occupation, round(avg(h.stress_level),2) as avg_stress
  from person p
  join health_info h on p.person_id = h.person_id
  group by p.occupation
)
select *, rank() over(order by avg_stress desc) as stress_rank
from stress_cte;


---category 4 : overall wellness and risks assessment


--- 8. find people with above average heart rate 
select person_id, heart_rate 
from health_info
where heart_rate > (select avg(heart_rate) from health_info);



--- 9. who all are at high risk due to obesity,low sleep quality or low physical activity? 
select p.Person_id, p.Occupation, h.BMI_Category, s.sleep_duration, h.Physical_activity,
case when h.BMI_category='Obese'
       or s.sleep_duration < 6 
	   or h.physical_activity < 50 then 'High Risk' 
	   else 'Low Risk' end as risk_category
from person p 
join sleep_details s on p.person_id=s.person_id 
join health_info h on s.person_id=h.person_id;


/* 10. Which occupations rank highest in overall wellness when combining physical activity, 
sleep quality, and stress level?*/
with health_cte as (
  select p.occupation,
         round(avg(h.physical_activity),2) as avg_activity,
         round(avg(s.quality_of_sleep),2) as avg_sleep_quality,
         round(avg(h.stress_level),2) as avg_stress
  from person p
  join health_info h on p.person_id = h.person_id
  join sleep_details s on p.person_id = s.person_id
  group by p.occupation
)
select occupation,
       (avg_activity + avg_sleep_quality - avg_stress) as health_score,
       rank() over(order by (avg_activity + avg_sleep_quality - avg_stress) desc) as rank
from health_cte;







