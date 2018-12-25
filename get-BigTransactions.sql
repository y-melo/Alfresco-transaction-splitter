# Author: TayAcioli , Y Melo
# Date: Dec 21, 2018
# Version: 1.0.0
# Description: 
# Get transactions bigger than 1.000.000

set @biggerThan='1000000' ; 

select distinct
	alft.id as id, alft.commit_time_ms as epoch, (select distinct count(*) from alf_node where transaction_id=alft.id ) as count
from 
	alf_transaction as alft
having count > @biggerThan
order by count desc
limit 10;