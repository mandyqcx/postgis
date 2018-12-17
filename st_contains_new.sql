drop table temp_poi_gps_rectangle;
CREATE TABLE tmp.temp_poi_gps_rectangle AS
SELECT foo.poi_gps_id,
ST_MakePolygon(ST_AddPoint(foo.open_line, ST_StartPoint(foo.open_line), -1)) AS polygon_area
FROM
(SELECT t.poi_gps_id,
 ST_MakeLine(ST_MakePoint(t.longitude, t.latitude)) AS open_line
 FROM
 (SELECT b.poi_id,
  a.id,
  a.poi_gps_id,
  a.latitude,
  a.longitude
  FROM chr.poi_gps_rectangle a
  JOIN chr.poi_gps b
       ON a.poi_gps_id=b.id
  JOIN chr.poi c
       ON b.poi_id=c.id
  WHERE a.is_deleted='N'
  AND b.is_deleted='N'
  AND c.is_deleted='N'
  AND c.id=1736
  ORDER BY
  a.poi_gps_id,
  a.id) AS t
 GROUP BY
 t.poi_gps_id) AS foo;

create index idx_temp_poi_gps_rectangle_polygon_area on tmp.temp_poi_gps_rectangle
using GIST(polygon_area);


select
a.poi_gps_id
from temp_poi_gps_rectangle a
where ST_contains(a.polygon_area,st_makepoint(113.1205626,22.9921981));
