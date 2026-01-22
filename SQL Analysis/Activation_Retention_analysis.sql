use Creator_product
--------------------------
select * from creators
select * from events
select * from links
select * from sales
---------------------------

-----------------------------LAYER 1 --------------------------------------
 --------ACTIVATION LAYER ( ACTIVATED/LINK CREATED WITHIN 7 DAYS OF SIGNUP) --------------

 with first_events as (
	select c.creator_id,
	min(case when e.event_type = 'signup' then e.event_date end) as signup, 
	min(case when e.event_type = 'create_link' then e.event_date end) as first_link
from creators as c left join events as e on
c.creator_id = e.creator_id
group by c.creator_id
),
active as (
select *,
(case when DATEADD(day,7,signup) >= first_link then 'Activated'
else 'Not activated'
end) as Active_status
from first_events 
where signup is not NULL
)
select Active_status,count(*) as After_7d
from active group by Active_status



-----------------------------LAYER 2 --------------------------------------
 ------------------------ FUNNEL LAYER  --------------

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

select 
    count(creator_id) as total_creators,
    -- Check for existence of each step
    count(signup) as reached_signup,
    count(case when first_link >= signup then 1 end) as reached_link,
    count(case when first_share >= first_link then 1 end) as reached_share,
    count(case when first_purchase >= first_share then 1 end) as reached_purchase
from first_events;



-----------------------------LAYER 3 --------------------------------------
 ---------- RETENTION LAYER (Are creators active within 30d of signup --------------




with first_events as (
	select c.creator_id,
	min(case when e.event_type = 'signup' then e.event_date end) as signup, 
	min(case when e.event_type = 'create_link' then e.event_date end) as first_link,
	min(case when e.event_type = 'share_link' then e.event_date end) as first_share,
	min(case when e.event_type = 'purchase' then e.event_date end) as first_purchase 
from creators as c left join events as e on
c.creator_id = e.creator_id
group by c.creator_id
),
activity as (
select *,
(case when DATEADD(day,30,signup) >= first_link or DATEADD(day,30,signup) >= first_share 
or DATEADD(day,30,signup) >= first_purchase then 'Retained' else 'Not Retained' end) as Retain,
(case when DATEADD(day,7,signup) >= first_link then 'Activated'
else 'Not activated'
end) as Active_status,
DATEADD(day,30,signup) as '30d'
from first_events
where signup is not NULL
)
select Active_status, Retain, count(*) as Creators from activity
group by active_status, Retain
order by Active_status


-----------------------------LAYER 4--------------------------------------
 ----------------------- MONETIZATION LAYER  ------------------

with creator as (
	select c.creator_id,
	count(case when e.event_type = 'signup' then 1 end) as signup, 
	count(case when e.event_type = 'create_link' then 1 end) as link,
	count(case when e.event_type = 'share_link' then 1 end) as share,
	count(case when e.event_type = 'purchase' then 1 end) as purchase 
from creators as c left join events as e on
c.creator_id = e.creator_id
group by c.creator_id
)
select *,round(purchase*100/share,2) as Percentage from creator
where share != 0 and link != 0 and signup != 0 
order by creator_id

-------

---Total monetization---

with creator as (
 select c.creator_id, sum(s.revenue) as total_revenuee
 from creators as c left join sales s  
 on c.creator_id=s.creator_id
 group by c.creator_id
),
cnt as (
select count(creator_id) as [Total Creators],round(sum(total_revenuee),2) as [Total Amount] from creator
)
select * from cnt













-------extra optimized-------------
/*
WITH event_pivot AS (
    SELECT
        creator_id,

        MIN(CASE WHEN event_type = 'signup'      THEN event_date END) AS signup_date,
        MIN(CASE WHEN event_type = 'create_link' THEN event_date END) AS first_link_date,
        MIN(CASE WHEN event_type = 'share_link'  THEN event_date END) AS first_share_date,
        MIN(CASE WHEN event_type = 'purchase'    THEN event_date END) AS first_purchase_date

    FROM events
    GROUP BY creator_id
),

activity AS (
    SELECT
        c.creator_id,
        e.signup_date,

        /* Precompute once */
        DATEADD(day, 7,  e.signup_date) AS d7,
        DATEADD(day, 30, e.signup_date) AS d30,

        /* Activation */
        CASE 
            WHEN e.first_link_date BETWEEN e.signup_date AND DATEADD(day,7,e.signup_date)
            THEN 1 ELSE 0 
        END AS is_activated,

        /* Retention */
        CASE 
            WHEN 
                e.first_link_date     BETWEEN e.signup_date AND DATEADD(day,30,e.signup_date)
             OR e.first_share_date    BETWEEN e.signup_date AND DATEADD(day,30,e.signup_date)
             OR e.first_purchase_date BETWEEN e.signup_date AND DATEADD(day,30,e.signup_date)
            THEN 1 ELSE 0
        END AS is_retained

    FROM creators c
    JOIN event_pivot e
      ON c.creator_id = e.creator_id
    WHERE e.signup_date IS NOT NULL
)

SELECT
    CASE WHEN is_activated = 1 THEN 'Activated' ELSE 'Not Activated' END AS activation_status,
    CASE WHEN is_retained  = 1 THEN 'Retained'  ELSE 'Not Retained'  END AS retention_status,

    COUNT(*)                                   AS creators,
    ROUND(AVG(is_retained) * 100.0, 2)         AS retention_rate

FROM activity
GROUP BY
    is_activated,
    is_retained
ORDER BY
    is_activated DESC,
    is_retained DESC;
*/

