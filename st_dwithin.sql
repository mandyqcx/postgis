select * from poi_gps limit 2;


drop table if EXISTS table1;
create temp table table1 as
select
  id,
  latitude,
  longitude,
  poi_id,
  st_transform(st_setsrid(ST_MakePoint(longitude,latitude),4326),21459) as point_geo,
  st_astext(st_transform(st_setsrid(ST_MakePoint(longitude,latitude),4326),21459)) as point
from chr.poi_gps
WHERE is_deleted='N';



drop table if exists table2;
create temp table table2 as
SELECT
a.data_time,
b.mn_code,
d.enterprise_name,
sum(CASE WHEN a.device_id LIKE '%LNG' THEN data_value ELSE NULL END) AS lng,
sum(CASE WHEN a.device_id LIKE '%LAT' THEN data_value ELSE NULL END) AS lat
FROM chr.history_data a
LEFT JOIN chr.device b
ON a.device_id = b.device_id
LEFT JOIN chr.monpoint c
ON b.mn_code = c.mn_code
LEFT JOIN chr.enterprise d
ON c.enterprise_code = d.enterprise_code
WHERE (
      a.device_id LIKE '%LNG' OR
      a.device_id LIKE '%LAT'
      )
      AND a.data_time >='2018-09-12'::timestamp
      AND a.data_time <'2018-09-13'::timestamp
      AND b.is_deleted = 'N'
      AND c.is_deleted = 'N'
      AND d.is_deleted = 'N'
      AND d.industry_id=7
GROUP BY a.data_time,b.mn_code,d.enterprise_name;



drop table if exists table3;
create temp table table3 as
select
  data_time,
  mn_code,
  enterprise_name,
  lng,
  lat,
  st_transform(st_setsrid(ST_MakePoint(lng,lat),4326),21459) as point_geo,
  st_astext(st_transform(st_setsrid(ST_MakePoint(lng,lat),4326),21459)) as point
  from table2;


select a.id,a.poi_id,a.longitude,a.latitude,b.data_time,b.lng,b.lat
from table1 a
LEFT JOIN table3 b
    on st_dwithin(a.point_geo,b.point_geo,2)
where b.point is not null;

