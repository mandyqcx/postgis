--取出一些数据
create temp table temp_table_1 as
select
b.poi_id,
a.id,
a.poi_gps_id,
a.latitude,
a.longitude
from poi_gps_rectangle a
JOIN chr.poi_gps b
ON a.poi_gps_id = b.id
WHERE a.is_deleted = 'N'
AND b.is_deleted = 'N'
and b.poi_id =1667
order by a.poi_gps_id,a.id;


select * from temp_table_1;

--对经纬度的坐标系进行转换，但是之前的srid是0，所以转换不了
select
st_transform(ST_MakePoint(longitude,latitude),21459)
from temp_table_1;

--必须先设置坐标系为一个已知的srid,然后才可以转换坐标系
select
st_srid(ST_MakePoint(longitude,latitude)),
st_setsrid(ST_MakePoint(longitude,latitude),4326),
st_srid(st_setsrid(ST_MakePoint(longitude,latitude),4326))
from temp_table_1;


--转换坐标系
select
  st_astext(st_transform(st_setsrid(ST_MakePoint(longitude,latitude),4326),21459)),
  st_transform(st_setsrid(ST_MakePoint(longitude,latitude),4326),21459)
from temp_table_1;


create temp table temp_table_2 as
select
foo.poi_gps_id,
ST_MakePolygon(ST_AddPoint(foo.open_line, ST_StartPoint(foo.open_line),-1)) as Polygon--要构建矩形，需要一条头尾相连的线段，所以连接线段的第一个点和最后一个点
from
(select
t.poi_gps_id,
st_Makeline(st_transform(st_setsrid(ST_MakePoint(t.longitude,t.latitude),4326),21459)) open_line
from temp_table_1 t
group by t.poi_gps_id) as foo;



select
poi_gps_id,
st_area(Polygon)
from temp_table_2;


select * from temp_table_3
where poi_gps_id =43848;


43857	19974.52067913633
20000.27 m²(平方米);

43848	25277.386372500532
25309.91 m²(平方米);

113.1104281,23.0556376
113.1084747,23.0555735
113.1085095,23.0546747
113.1104630,23.0547388

113.1116196,23.0622552
113.1096826,23.0620129
113.1098492,23.0608852
113.1117862,23.0611274



create temp table temp_table_3 as
select
  *,
  st_astext(st_transform(st_setsrid(ST_MakePoint(longitude,latitude),4326),21459)),
  st_transform(st_setsrid(ST_MakePoint(longitude,latitude),4326),21459)
from temp_table_1;



select * from temp_table_3
where id in(83883,83884);



select st_distance(st_transform(st_setsrid(ST_MakePoint(113.1112247,23.0649284),4326),21459),
       st_transform(st_setsrid(ST_MakePoint(113.1092877,23.0646862),4326),21459));



select st_distance(st_transform(st_setsrid(ST_MakePoint(113.1116196,23.0622552),4326),21459),
       st_transform(st_setsrid(ST_MakePoint(113.1098492,23.0608852),4326),21459));

