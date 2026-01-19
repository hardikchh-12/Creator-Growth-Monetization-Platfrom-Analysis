--------------------------
select * from creators
select * from events
select * from links
select * from sales


---------------------------
with first_events as (
	select c.creator_id,
	min(case when e.event_type = 'signup' then e.event_date end) as signup, 
	min(case when e.event_type = 'create_link' then e.event_date end) as first_link,
	min(case when e.event_type = 'share_link' then e.event_date end) as first_share,
	min(case when e.event_type = 'purchase' then e.event_date end) as first_purchase 
from creators as c left join events as e on
c.creator_id = e.creator_id
group by c.creator_id
)
select * from first_events 
where first_share<first_purchase and first_link<first_share and signup is not NULL
order by creator_id;





