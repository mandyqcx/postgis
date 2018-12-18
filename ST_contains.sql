--因为要取出的数据量超过1千行记录，所以需要在tmp目录下新建一张表，将所需的数据插入这张表中
drop table if EXISTS tmp.chr_check_list_point1;
create table tmp.chr_check_list_point1(
mn varchar(64),
lng numeric(21,7),
lat numeric(21,7),
data_time timestamp(6),
point geometry);--几何字段的数据类型使用geometry


--在源表中取出数据插入到tmp下面新建的表，同时将根据经纬度构建出点在地球坐标系的坐标
insert into tmp.chr_check_list_point1(
mn,
lng,
lat,
data_time,
point)
select
mn,
lng,
lat,
data_time,
ST_MakePoint(lng,lat) AS point --使用st_makepoint(纬度，经度)函数构建点的坐标
from rpt_chr_check_list
where poi_name='汾江路路测线路';



--因为数据量很少，不超过一千，所有可以创建系统临时表，不需要定义字段的数据类型
CREATE TEMP TABLE tmp_poi_gps_rectangle1 AS
select
foo.poi_gps_id,
ST_MakePolygon(ST_AddPoint(foo.open_line, ST_StartPoint(foo.open_line),-1)) as Polygon
from
(select
t.poi_gps_id,
ST_MakeLine(ST_MakePoint(t.longitude,t.latitude)) open_line
from
(select
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
order by a.poi_gps_id,a.id)t
group by t.poi_gps_id) as foo;


--分解为
-- 1.取出指定道路的区块，一个区块一般是由5个点组成的，且点之间是有顺序的，所有要先对这些点做排序
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


--2.一个道路有多个区块，一个区块是由5个点组成的，要将这5个点组成一个矩形，需要先用这5个点构建成一条线段
select
t.poi_gps_id,
ST_MakeLine(ST_MakePoint(t.longitude,t.latitude)) open_line
from
(select
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
order by a.poi_gps_id,a.id)t
group by t.poi_gps_id;


--3.在构建成的线段基础上，构建成矩形
select
foo.poi_gps_id,
ST_MakePolygon(ST_AddPoint(foo.open_line, ST_StartPoint(foo.open_line),-1)) as Polygon--要构建矩形，需要一条头尾相连的线段，所以连接线段的第一个点和最后一个点
from
(select
t.poi_gps_id,
ST_MakeLine(ST_MakePoint(t.longitude,t.latitude)) open_line
from
(select
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
order by
  a.poi_gps_id,
  a.id)t
group by t.poi_gps_id) as foo;


drop table if exists tmp.chr_check_list_result1;
create table tmp.chr_check_list_result1(
mn varchar(64),
lng numeric(21,7),
lat numeric(21,7),
data_time timestamp(6),
poi_gps_id int4);



insert into tmp.chr_check_list_result1
(mn, lng, lat, data_time, poi_gps_id)
select
mn,
lng,
lat,
data_time,
poi_gps_id
from(
select
mn,
lng,
lat,
data_time,
poi_gps_id,
row_number() over (partition by mn,lng,lat,data_time order by poi_gps_id) as rn --因为一个点会在两个区块中，我们只需要一个区块即可，所以在条件中取rn=1
from tmp_poi_gps_rectangle1 a,
chr_check_list_point1 b
WHERE ST_Contains(a.polygon,b.point))t --判断点是否在矩形中，如果是返回true,否则返回false,st_contains写在where中作为条件，则返回的点都是在区块中
where rn=1;






