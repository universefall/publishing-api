
select

ci_limited.content_id as content_id,
ci.id as content_item_id,
t.locale as locale,
loc.base_path as base_path,
s.name as state,
ufv.number as version,
l.link_type as link_type,
l.target_content_id as link_target_content_id

from (
  select content_id from content_items group by content_id having content_id > '00000000-0000-0000-0000-000000000000' order by content_id asc limit 10
) ci_limited

left join link_sets ls on ls.content_id = ci_limited.content_id
left join links l on l.link_set_id = ls.id
join content_items ci on ci.content_id = ci_limited.content_id
join translations t on t.content_item_id = ci.id
join locations loc on loc.content_item_id = ci.id
join states s on s.content_item_id = ci.id
join user_facing_versions ufv on ufv.content_item_id = ci.id

order by ci_limited.content_id asc, ci.id asc