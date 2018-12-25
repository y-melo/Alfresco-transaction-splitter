-- get the transaction_id from the query 'get-BigTransactions.sql'
set @transact_id='31450';

select uuid from alf_node 
where transaction_id=@transact_id
limit 15000000;
