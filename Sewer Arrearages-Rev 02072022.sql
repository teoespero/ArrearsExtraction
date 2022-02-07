/*
	Preparation
	Generate the Aging Report (Springbrook) for each cycle using the billing date as
	basis...

	Billing Date 2021
	----------------------------
	Cycle 1 - 6/4/2021
	Cycle 2,3 - 6/11/2021
	Cycle 4,5,6 - 5/21/2021
	Cycle 7,8,9,10 - 5/31/2021
	----------------------------

	The Aging report we created for water will be the same file used in sewer
*/



-----------------------------------------------
-- PRELIMINNARIES

-- get sewer service codes used in springbrook
select 
	distinct
	service_code,
	[description]
from ub_service
where
	SUBSTRING(service_code,1,2) in ('SB', 'SF', 'SW')


-------------------------------------------------------------------------
-- GENERATE SEWER MASTER LIST
-- 
-- This list will contain all the accounts that has a SEWER
-- code attached to it ('SB', 'SF', 'SW',) 
select 
	distinct
	replicate('0', 6 - len(srv.cust_no)) + cast (srv.cust_no as varchar)+ '-'+replicate('0', 3 - len(srv.cust_sequence)) + cast (srv.cust_sequence as varchar) as AccountNum
from ub_service_rate srv
where
	service_code in (
	select 
		distinct
		service_code
	from ub_service
	where
		SUBSTRING(service_code,1,2) in ('SB', 'SF', 'SW')
	)
order by
	replicate('0', 6 - len(srv.cust_no)) + cast (srv.cust_no as varchar)+ '-'+replicate('0', 3 - len(srv.cust_sequence)) + cast (srv.cust_sequence as varchar)


--- 
/*
	Step 1
	Generate the Aging Report (Springbrook) for each cycle using the billing date as
	basis...


	Billing Date 2021
	----------------------------
	Cycle 1 - 6/4/2021
	Cycle 2,3 - 6/11/2021
	Cycle 4,5,6 - 5/21/2021
	Cycle 7,8,9,10 - 5/31/2021
	----------------------------
*/

select 
	replicate('0', 6 - len(mast.cust_no)) + cast (mast.cust_no as varchar)+ '-'+replicate('0', 3 - len(mast.cust_sequence)) + cast (mast.cust_sequence as varchar) as AccountNum,
	CONVERT(varchar(10),mast.connect_date,101) as ConnectDate,
	CONVERT(varchar(10),mast.final_date,101) as FinalDate,
	lot_no
	into #step01
from ub_master mast
where
	replicate('0', 6 - len(mast.cust_no)) + cast (mast.cust_no as varchar)+ '-'+replicate('0', 3 - len(mast.cust_sequence)) + cast (mast.cust_sequence as varchar) in (
	)

-- step 02
-- get st category, irrigation info
select 
	s01.AccountNum,
	lot.lot_no,
	lot.misc_2 as STCategory,
	lot.misc_16 as Irrigation,
	s01.ConnectDate,
	s01.FinalDate
	into #step02
from #step01 s01
inner join
	lot 
	on lot.lot_no=s01.lot_no

-- step 03
-- get the connect date and final date info
-- paste this in excel
select *
from #step02

-- step04
-- get the current total balance (All service codes)

-- code revised 02 03 2022
-- this part of the code has been revised to account for finalized accounts
-- within the same billing period

select 
	replicate('0', 6 - len(hist.cust_no)) + cast (hist.cust_no as varchar)+ '-'+replicate('0', 3 - len(hist.cust_sequence)) + cast (hist.cust_sequence as varchar) as AccountNum,
	hist.amount,
	hist.transaction_id,
	hist.tran_date
	into #step04
from  ub_history hist
where
	replicate('0', 6 - len(hist.cust_no)) + cast (hist.cust_no as varchar)+ '-'+replicate('0', 3 - len(hist.cust_sequence)) + cast (hist.cust_sequence as varchar)in (
		select s02.AccountNum
		from #step02 s02
	)
	and hist.tran_type = 'balance'
	and hist.batch_month=01
	and hist.batch_year=2022
order by
	replicate('0', 6 - len(hist.cust_no)) + cast (hist.cust_no as varchar)+ '-'+replicate('0', 3 - len(hist.cust_sequence)) + cast (hist.cust_sequence as varchar),
	hist.transaction_id desc,
	hist.tran_date desc

--select *
--from #step04
--where
--AccountNum = '017226-000'


-- find the latest balance based on trandate
-- for the billing period and use it
-- deleted accounts that are finaled on a date before
-- this period will not be included
select t.AccountNum, t.amount, t.tran_date, t.transaction_id
from #step04 t
inner join (
	select AccountNum, 
	--max(tran_date) as MaxDate,
	max(transaction_id) as MaxTrans
    from #step04
    group by AccountNum
) tm 
on 
	t.AccountNum = tm.AccountNum 
	--and t.tran_date = tm.MaxDate 
	and t.transaction_id=tm.MaxTrans
--and t.AccountNum = '017226-000'
order by
	t.AccountNum,
	t.tran_date




--select 
--	replicate('0', 6 - len(hist.cust_no)) + cast (hist.cust_no as varchar)+ '-'+replicate('0', 3 - len(hist.cust_sequence)) + cast (hist.cust_sequence as varchar) as AccountNum,
--	hist.amount,
--	hist.transaction_id
--	into #step04
--from  ub_history hist
--where
--	replicate('0', 6 - len(hist.cust_no)) + cast (hist.cust_no as varchar)+ '-'+replicate('0', 3 - len(hist.cust_sequence)) + cast (hist.cust_sequence as varchar)in (
--		select s02.AccountNum
--		from #step02 s02
--	)
--	and hist.tran_type = 'balance'
--	and hist.batch_month=01
--	and hist.batch_year=2022
--	and hist.batch_no=10

--select 
--	s04.AccountNum,
--	--bill.service_code,
--	sum(bill.amount) as Balance
--from ub_bill_detail bill
--inner join
--	#step04 s04
--	on s04.AccountNum=replicate('0', 6 - len(bill.cust_no)) + cast (bill.cust_no as varchar)+ '-'+replicate('0', 3 - len(bill.cust_sequence)) + cast (bill.cust_sequence as varchar)
--	and s04.transaction_id=bill.transaction_id
--group by
--	s04.AccountNum



-- get total balances for deleted
---- Deleted
select 
	replicate('0', 6 - len(bal.cust_no)) + cast (bal.cust_no as varchar)+ '-'+replicate('0', 3 - len(bal.cust_sequence)) + cast (bal.cust_sequence as varchar) as AccountNum,
	sum(bal.balance_fwd) as Balance
from ub_balance bal
where
	replicate('0', 6 - len(bal.cust_no)) + cast (bal.cust_no as varchar)+ '-'+replicate('0', 3 - len(bal.cust_sequence)) + cast (bal.cust_sequence as varchar) in (
	)
group by
	replicate('0', 6 - len(bal.cust_no)) + cast (bal.cust_no as varchar)+ '-'+replicate('0', 3 - len(bal.cust_sequence)) + cast (bal.cust_sequence as varchar)



-- get 2021 service rate balance
-- the date is based on billing date for cycle see step01


-- code is modified to use the latest balance generated for the account
-- if the account is still active during this period or if the account
-- is finalized during this period it will use the latest balance generated
select 
	replicate('0', 6 - len(hist.cust_no)) + cast (hist.cust_no as varchar)+ '-'+replicate('0', 3 - len(hist.cust_sequence)) + cast (hist.cust_sequence as varchar) as AccountNum,
	hist.amount,
	hist.transaction_id,
	hist.tran_date
	into #step05
from  ub_history hist
where
	replicate('0', 6 - len(hist.cust_no)) + cast (hist.cust_no as varchar)+ '-'+replicate('0', 3 - len(hist.cust_sequence)) + cast (hist.cust_sequence as varchar)in (
		select s02.AccountNum
		from #step02 s02
	)
	and hist.tran_type = 'balance'
	and hist.batch_month=05
	and hist.batch_year=2021


select t.AccountNum, t.amount, t.tran_date, t.transaction_id
into #step05b
from #step05 t
inner join (
	select AccountNum, 
	--max(tran_date) as MaxDate,
	max(transaction_id) as MaxTrans
    from #step05
    group by AccountNum
) tm 
on 
	t.AccountNum = tm.AccountNum 
	--and t.tran_date = tm.MaxDate 
	and t.transaction_id=tm.MaxTrans
--and t.AccountNum = '017226-000'
order by
	t.AccountNum,
	t.tran_date


--select distinct
--*
--from #step05
--where AccountNum='014042-000'

--select *
--from ub_bill_detail
--where 
--transaction_id in (
--6910495,
--6948638
--)

--select *
--from ub_history
--where
--	transaction_id in (
--	6910495,
--	6948638
--)


/*
Batch no Prefix
cycle 1 - 10
cycle 2 - 20
cycle 3 - 30
cycle 4 - 40
cycle 5 - 50
cycle 6 - 60
cycle 7 - 70
cycle 8 - 80
cycle 9 - 90
cycle 10 - 100
*/

select 
	s05.AccountNum,
	CONVERT(varchar(10),bill.tran_date,101) as TransDate,
	--bill.service_code,
	sum(bill.amount) as Amount
from ub_bill_detail bill
inner join
	#step05b s05
	on s05.AccountNum=replicate('0', 6 - len(bill.cust_no)) + cast (bill.cust_no as varchar)+ '-'+replicate('0', 3 - len(bill.cust_sequence)) + cast (bill.cust_sequence as varchar)
	and s05.transaction_id=bill.transaction_id
	inner join
	ub_history hist
	on s05.transaction_id=hist.transaction_id
where
	bill.service_code in (
		select 
			distinct
			service_code
		from ub_service
		where
			SUBSTRING(service_code,1,2) in ('SB', 'SF', 'SW')
	)
	--and bill.cust_no=14042
	--and bill.cust_sequence=0
	group by
		s05.AccountNum,
		CONVERT(varchar(10),bill.tran_date,101)
	order by 
		s05.AccountNum,
		CONVERT(varchar(10),bill.tran_date,101)


---- Get service rate balances for deleted  accounts
select 
	replicate('0', 6 - len(bal.cust_no)) + cast (bal.cust_no as varchar)+ '-'+replicate('0', 3 - len(bal.cust_sequence)) + cast (bal.cust_sequence as varchar) as AccountNum,
	sum(bal.balance_fwd) as Balance
from ub_balance bal
where
	replicate('0', 6 - len(bal.cust_no)) + cast (bal.cust_no as varchar)+ '-'+replicate('0', 3 - len(bal.cust_sequence)) + cast (bal.cust_sequence as varchar) in (
	)
	and bal.service_code in (
		select 
			distinct
			service_code
		from ub_service
		where
			SUBSTRING(service_code,1,2) in ('SB', 'SF', 'SW')
	)
group by
	replicate('0', 6 - len(bal.cust_no)) + cast (bal.cust_no as varchar)+ '-'+replicate('0', 3 - len(bal.cust_sequence)) + cast (bal.cust_sequence as varchar)

--service rate Balance as of 01 2022

select 
	replicate('0', 6 - len(hist.cust_no)) + cast (hist.cust_no as varchar)+ '-'+replicate('0', 3 - len(hist.cust_sequence)) + cast (hist.cust_sequence as varchar) as AccountNum,
	hist.amount,
	hist.tran_date,
	hist.transaction_id
	into #step06
from  ub_history hist
where
	replicate('0', 6 - len(hist.cust_no)) + cast (hist.cust_no as varchar)+ '-'+replicate('0', 3 - len(hist.cust_sequence)) + cast (hist.cust_sequence as varchar)in (
		select s02.AccountNum
		from #step02 s02
	)
	and hist.tran_type = 'balance'
	and hist.batch_month=01
	and hist.batch_year=2022


select t.AccountNum, t.amount, t.tran_date, t.transaction_id
into #step06b
from #step06 t
inner join (
	select AccountNum, 
	--max(tran_date) as MaxDate,
	max(transaction_id) as MaxTrans
    from #step06
    group by AccountNum
) tm 
on 
	t.AccountNum = tm.AccountNum 
	--and t.tran_date = tm.MaxDate 
	and t.transaction_id=tm.MaxTrans
--and t.AccountNum = '017226-000'
order by
	t.AccountNum,
	t.tran_date

select *
from #step06b

select 
	s06.AccountNum,
	CONVERT(varchar(10),bill.tran_date,101) as TransDate,
	sum(bill.amount) as Balance
from ub_bill_detail bill
inner join
	#step06b s06
	on s06.AccountNum=replicate('0', 6 - len(bill.cust_no)) + cast (bill.cust_no as varchar)+ '-'+replicate('0', 3 - len(bill.cust_sequence)) + cast (bill.cust_sequence as varchar)
	and s06.transaction_id=bill.transaction_id
	inner join
	ub_history hist
	on s06.transaction_id=hist.transaction_id
where
	bill.service_code in (
		select 
			distinct
			service_code
		from ub_service
		where
			SUBSTRING(service_code,1,2) in ('SB', 'SF', 'SW')
	)
	group by
		s06.AccountNum,
	CONVERT(varchar(10),bill.tran_date,101),
			bill.tran_date
	order by 
		s06.AccountNum,
		bill.tran_date desc

-- get deleted water balances
--select 
--	replicate('0', 6 - len(hist.cust_no)) + cast (hist.cust_no as varchar)+ '-'+replicate('0', 3 - len(hist.cust_sequence)) + cast (hist.cust_sequence as varchar) as AccountNum,
--	hist.amount,
--	hist.transaction_id
--	into #step10
--from  ub_history hist
--where
--	replicate('0', 6 - len(hist.cust_no)) + cast (hist.cust_no as varchar)+ '-'+replicate('0', 3 - len(hist.cust_sequence)) + cast (hist.cust_sequence as varchar)in (
--	)
--	and hist.tran_type = 'balance'
--	and hist.batch_year >= 2020

--select 
--	s10.AccountNum,
--	CONVERT(varchar(10),bill.tran_date,101) as TransDate,
--	--bill.service_code,
--	bill.amount as Balance
--from ub_bill_detail bill
--inner join
--	#step10 s10
--	on s10.AccountNum=replicate('0', 6 - len(bill.cust_no)) + cast (bill.cust_no as varchar)+ '-'+replicate('0', 3 - len(bill.cust_sequence)) + cast (bill.cust_sequence as varchar)
--	and s10.transaction_id=bill.transaction_id
--where
--	bill.service_code in (
--		select 
--			distinct
--			service_code
--		from ub_service
--		where
--			SUBSTRING(service_code,1,2) in ('SB', 'SF', 'SW', 'SX')
--	)

--	group by
--		s10.AccountNum,
--	CONVERT(varchar(10),bill.tran_date,101),
--			bill.tran_date,
--			bill.amount
--	order by 
--		s10.AccountNum,
--		bill.tran_date desc

-- code for getting code balances
-- for deleted accounts have been revised
-- to use ub_balance
-- 02 02 2022

select 
	replicate('0', 6 - len(bal.cust_no)) + cast (bal.cust_no as varchar)+ '-'+replicate('0', 3 - len(bal.cust_sequence)) + cast (bal.cust_sequence as varchar) as accountnum,
	balance_fwd
from ub_balance bal
where
replicate('0', 6 - len(bal.cust_no)) + cast (bal.cust_no as varchar)+ '-'+replicate('0', 3 - len(bal.cust_sequence)) + cast (bal.cust_sequence as varchar) in (
)
and service_code in (
		select 
			distinct
			service_code
		from ub_service
		where
			SUBSTRING(service_code,1,2) in ('SB', 'SF', 'SW')
)
order  by
replicate('0', 6 - len(bal.cust_no)) + cast (bal.cust_no as varchar)+ '-'+replicate('0', 3 - len(bal.cust_sequence)) + cast (bal.cust_sequence as varchar)




-- get water payment
-- after the billing date on step 1
select 
	replicate('0', 6 - len(hist.cust_no)) + cast (hist.cust_no as varchar)+ '-'+replicate('0', 3 - len(hist.cust_sequence)) + cast (hist.cust_sequence as varchar) as AccountNum,
	hist.amount,
	hist.transaction_id
	into #step07
from  ub_history hist
where
	replicate('0', 6 - len(hist.cust_no)) + cast (hist.cust_no as varchar)+ '-'+replicate('0', 3 - len(hist.cust_sequence)) + cast (hist.cust_sequence as varchar)in (
		select s02.AccountNum
		from #step02 s02
	)
	and hist.tran_type = 'Payment'
	and hist.tran_date>= '05/21/2021'
	and hist.batch_year>=2021


select 
	s07.AccountNum,
	sum(bill.amount) as Payment
from ub_bill_detail bill
inner join
	#step07 s07
	on s07.AccountNum=replicate('0', 6 - len(bill.cust_no)) + cast (bill.cust_no as varchar)+ '-'+replicate('0', 3 - len(bill.cust_sequence)) + cast (bill.cust_sequence as varchar)
	and s07.transaction_id=bill.transaction_id
where
	bill.service_code in (
		select 
			distinct
			service_code
		from ub_service
		where
			SUBSTRING(service_code,1,2) in ('SB', 'SF', 'SW')
	)
Group By
	s07.AccountNum

-- payments made by deleted accounts

--select 
--	replicate('0', 6 - len(mast.cust_no)) + cast (mast.cust_no as varchar)+ '-'+replicate('0', 3 - len(mast.cust_sequence)) + cast (mast.cust_sequence as varchar) as AcctNum,
--	CONVERT(varchar(10),mast.final_date,101) as FinalDate,
--	(select top 1 hist.transaction_id from ub_history hist where replicate('0', 6 - len(hist.cust_no)) + cast (hist.cust_no as varchar)+ '-'+replicate('0', 3 - len(hist.cust_sequence)) + cast (hist.cust_sequence as varchar) = replicate('0', 6 - len(mast.cust_no)) + cast (mast.cust_no as varchar)+ '-'+replicate('0', 3 - len(mast.cust_sequence)) + cast (mast.cust_sequence as varchar) and hist.tran_date >= CONVERT(varchar(10),mast.final_date,101) and hist.tran_type in ('Payment','Adjustments') order by hist.tran_date desc) as Payment
--	--into #step11
--from ub_master mast
--where
--	replicate('0', 6 - len(mast.cust_no)) + cast (mast.cust_no as varchar)+ '-'+replicate('0', 3 - len(mast.cust_sequence)) + cast (mast.cust_sequence as varchar) in (

--	)
--order by replicate('0', 6 - len(mast.cust_no)) + cast (mast.cust_no as varchar)+ '-'+replicate('0', 3 - len(mast.cust_sequence)) + cast (mast.cust_sequence as varchar)

--select *
--from #step11

--select *
--from ub_bill_detail
--where
--cust_no=13973
--and cust_sequence=0
----and tran_date >= '12/28/2020'
--and tran_type = 'payment'

--select 
--	s11.AcctNum,
--	sum(bill.amount) as Payment
--from ub_bill_detail bill
--inner join
--	#step11 s11
--	on s11.AcctNum=replicate('0', 6 - len(bill.cust_no)) + cast (bill.cust_no as varchar)+ '-'+replicate('0', 3 - len(bill.cust_sequence)) + cast (bill.cust_sequence as varchar)
--	and s11.Payment=bill.transaction_id
--where
--	bill.service_code in (
--		select 
--			distinct
--			service_code
--		from ub_service
--		where
--			SUBSTRING(service_code,1,2) in ('SB', 'SF', 'SW', 'SX')
--	)
--Group By
--	s11.AcctNum

select 
	replicate('0', 6 - len(mast.cust_no)) + cast (mast.cust_no as varchar)+ '-'+replicate('0', 3 - len(mast.cust_sequence)) + cast (mast.cust_sequence as varchar) as AcctNum,
	CONVERT(varchar(10),mast.final_date,101) as FinalDate
	into #delp
from ub_master mast
where
	replicate('0', 6 - len(mast.cust_no)) + cast (mast.cust_no as varchar)+ '-'+replicate('0', 3 - len(mast.cust_sequence)) + cast (mast.cust_sequence as varchar) in (
)

-- payment by deleted accounts have been modified to
-- use bill details and ub_master to get payments after
-- the account's final date
select 
	dp.AcctNum,
	dp.FinalDate,
	--bill.transaction_id,
	--bill.tran_date,
	--bill.tran_type,
	sum(bill.amount) as amount
from #delp dp
inner join
	ub_bill_detail bill
	on replicate('0', 6 - len(bill.cust_no)) + cast (bill.cust_no as varchar)+ '-'+replicate('0', 3 - len(bill.cust_sequence)) + cast (bill.cust_sequence as varchar)=dp.AcctNum
	and bill.tran_date>=dp.FinalDate
	and tran_type='payment'
	and bill.service_code in (
		select 
			distinct
			service_code
		from ub_service
		where
			SUBSTRING(service_code,1,2) in ('SB', 'SF', 'SW')
	)
group by
	dp.AcctNum,
	dp.FinalDate,
	bill.transaction_id,
	bill.tran_date,
	bill.tran_type
order by
	dp.AcctNum


----------------------
---- code added 02 02 2022

----Water Balance as of August



--select 
--	replicate('0', 6 - len(curbal.cust_no)) + cast (curbal.cust_no as varchar)+ '-'+replicate('0', 3 - len(curbal.cust_sequence)) + cast (curbal.cust_sequence as varchar) as AccountNum,
--	sum(balance_fwd) as Balance
--from ub_balance curbal
--where
--	service_code in (
--	select 
--			distinct
--			service_code
--		from ub_service
--		where
--			SUBSTRING(service_code,1,2) in ('SB', 'SF', 'SW')
--	)
--	and replicate('0', 6 - len(curbal.cust_no)) + cast (curbal.cust_no as varchar)+ '-'+replicate('0', 3 - len(curbal.cust_sequence)) + cast (curbal.cust_sequence as varchar) in (
--		select AccountNum
--		from #step02
--	)
--group by
--	replicate('0', 6 - len(curbal.cust_no)) + cast (curbal.cust_no as varchar)+ '-'+replicate('0', 3 - len(curbal.cust_sequence)) + cast (curbal.cust_sequence as varchar)
--order by
--replicate('0', 6 - len(curbal.cust_no)) + cast (curbal.cust_no as varchar)+ '-'+replicate('0', 3 - len(curbal.cust_sequence)) + cast (curbal.cust_sequence as varchar)

/*
	get previous balance as from previous billing before Mar 04 2020
	------------------------------------------------------------------
	Cycle  1		02/07/20
	Cycle  2,3		02/14/20
	Cycle  4, 5, 6	02/21/20
	Cycle  7 - 10	02/28/20
	------------------------------------------------------------------
*/
select 
	replicate('0', 6 - len(hist.cust_no)) + cast (hist.cust_no as varchar)+ '-'+replicate('0', 3 - len(hist.cust_sequence)) + cast (hist.cust_sequence as varchar) as AccountNum,
	hist.amount,
	hist.tran_date,
	hist.transaction_id
	into #step08
from  ub_history hist
where
	replicate('0', 6 - len(hist.cust_no)) + cast (hist.cust_no as varchar)+ '-'+replicate('0', 3 - len(hist.cust_sequence)) + cast (hist.cust_sequence as varchar)in (
		select s02.AccountNum
		from #step02 s02
	)
	and hist.tran_type = 'Balance'
	and hist.tran_date = '02/21/2020'
	and hist.batch_year=2020
	--and hist.batch_no=10

select t.AccountNum, t.amount, t.tran_date, t.transaction_id
into #step08b
from #step08 t
inner join (
	select AccountNum, 
	--max(tran_date) as MaxDate,
	max(transaction_id) as MaxTrans
    from #step08
    group by AccountNum
) tm 
on 
	t.AccountNum = tm.AccountNum 
	--and t.tran_date = tm.MaxDate 
	and t.transaction_id=tm.MaxTrans
--and t.AccountNum = '017226-000'
order by
	t.AccountNum,
	t.tran_date



select 
	s08.AccountNum,
	sum(bill.amount) as Balance
from ub_bill_detail bill
inner join
	#step08b s08
	on s08.AccountNum=replicate('0', 6 - len(bill.cust_no)) + cast (bill.cust_no as varchar)+ '-'+replicate('0', 3 - len(bill.cust_sequence)) + cast (bill.cust_sequence as varchar)
	and s08.transaction_id=bill.transaction_id
where
	bill.service_code in (
		select 
			distinct
			service_code
		from ub_service
		where
			SUBSTRING(service_code,1,2) in ('SB', 'SF', 'SW')
	)
Group By
	s08.AccountNum



-- get payment after billing period above

select 
	replicate('0', 6 - len(hist.cust_no)) + cast (hist.cust_no as varchar)+ '-'+replicate('0', 3 - len(hist.cust_sequence)) + cast (hist.cust_sequence as varchar) as AccountNum,
	hist.amount,
	hist.transaction_id
	into #step09
from  ub_history hist
where
	replicate('0', 6 - len(hist.cust_no)) + cast (hist.cust_no as varchar)+ '-'+replicate('0', 3 - len(hist.cust_sequence)) + cast (hist.cust_sequence as varchar)in (
		select s02.AccountNum
		from #step02 s02
	)
	and hist.tran_type = 'Payment'
	and (hist.tran_date>= '2/21/2020' and hist.tran_date < '5/21/2021')

select 
	s09.AccountNum,
	sum(bill.amount) as Payment
from ub_bill_detail bill
inner join
	#step09 s09
	on s09.AccountNum=replicate('0', 6 - len(bill.cust_no)) + cast (bill.cust_no as varchar)+ '-'+replicate('0', 3 - len(bill.cust_sequence)) + cast (bill.cust_sequence as varchar)
	and s09.transaction_id=bill.transaction_id
where
	bill.service_code in (
		select 
			distinct
			service_code
		from ub_service
		where
			SUBSTRING(service_code,1,2) in ('SB', 'SF', 'SW')
	)
Group By
	s09.AccountNum

--- merge

select 
	replicate('0', 6 - len(mast.cust_no)) + cast (mast.cust_no as varchar)+ '-'+replicate('0', 3 - len(mast.cust_sequence)) + cast (mast.cust_sequence as varchar) as AccountNum,
	mast.billing_cycle,
	mast.lot_no,
	lot.misc_1 as Boundary,
	lot.misc_2 as STCategoty,
	lot.misc_5 as Subdivision,
	lot.misc_16 as Irrigation,
	lot.zip
from ub_master mast
inner join
	lot 
	on lot.lot_no=mast.lot_no
where
	replicate('0', 6 - len(mast.cust_no)) + cast (mast.cust_no as varchar)+ '-'+replicate('0', 3 - len(mast.cust_sequence)) + cast (mast.cust_sequence as varchar) in (
	select AccountNum
	from #step02
	)



drop table #step01
drop table #step02
drop table #step04
drop table #step05
drop table #step05b
drop table #step06
drop table #step06b
drop table #step07
drop table #step08
drop table #step08b
drop table #step09
drop table #step10
drop table #step11
drop table #delp