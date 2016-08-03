USE [FordhamDatabase]
GO

/****** Object:  Table [dbo].[BETA_CALCULATIONS]    Script Date: 12/13/2015 12:19:51 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO
DROP TABLE [dbo].[BETA_CALCULATIONS]

CREATE TABLE [dbo].[BETA_CALCULATIONS](
	[Stock] [varchar](50) NULL,
	[Date] [date] NULL,
	[Open] [real] NULL,
	[High] [real] NULL,
	[Low] [real] NULL,
	[Close] [real] NULL,
	[Volume] bigint  NULL,
	[adjClose] [real] NULL
) ON [PRIMARY]

GO

create unique index idx1 on BETA_CALCULATIONS(Stock,[Date])


select * into #tmp from (
		SELECT *,  ROW_NUMBER() OVER (PARTITION BY Stock, Date ORDER BY Stock, Date) AS rn
        FROM    BETA_CALCULATIONS
        ) a
		where rn > 1
select distinct Stock, Date from #tmp

delete b from BETA_CALCULATIONS b join #tmp on  b.Stock=#tmp.Stock and b.Date=#tmp.Date

insert into BETA_CALCULATIONS
select 
distinct 
[Stock],
	[Date],
	[Open],
	[High],
	[Low] ,
	[Close],
	[Volume],
	[adjClose]

	from #tmp
;


WITH    CTE_PRICES AS
        (
        /* limit all closing prices from 2000 and on */
		SELECT  *, ROW_NUMBER() OVER (PARTITION BY Stock ORDER BY Date) AS rn
        FROM    BETA_CALCULATIONS
        WHERE Date >= '2014-12-01'
		)
		,
		STOCK_PRICE_CHANGE AS (
		/* calc abs price change per stock/day */
		SELECT yest.stock, today.date , ABS(today.adjClose - yest.adjClose)/yest.adjClose*100 AS PRICE_CHANGE
	    FROM CTE_PRICES today JOIN CTE_PRICES yest ON today.Stock=yest.Stock and today.rn = yest.rn +1
	    WHERE   yest.Stock IN ('GOOG','AACC','AAWW','SNP500', 'AMZN','MSFT') 
		) ,
		SNP_PRICE_CHANGE AS (
		/* calc abs price change for S&P500 for each day */
		SELECT yest.stock, today.date , ABS(today.adjClose - yest.adjClose)/yest.adjClose*100 AS PRICE_CHANGE
	    FROM CTE_PRICES today JOIN CTE_PRICES yest ON today.Stock=yest.Stock and today.rn = yest.rn +1
		WHERE yest.Stock='SNP500'
		)
		,
		AVG_SP AS (SELECT AVG(PRICE_CHANGE) as avg_chg 	FROM SNP_PRICE_CHANGE) , 
		SNP_VAR AS (
		/* calc var for S&P500 for the whole date range */
		SELECT  SUM((snp.PRICE_CHANGE - AVG_SP.avg_chg)*(snp.PRICE_CHANGE - avg_sp.avg_chg))/(COUNT(*)-1)
		  AS variance, COUNT(*) AS SNP_DAY_COUNT FROM SNP_PRICE_CHANGE snp , AVG_SP	
		)

		,
		STOCK_COVAR AS (
		/* for each stock calc covar as 
				SUM of 
					(index price change - avg of index price change) 
					times (stock price change - avg of stock price change)
				divided by stock price number of observations
        */
		SELECT st.Stock, 
			SUM
			 (
			  (snp.PRICE_CHANGE -	avg_sp.avg_chg ) *
			  (st.PRICE_CHANGE - avg_st.avg_chg)
			 )
			 /
			(MAX(avg_st.STOCK_COUNT)-1) as covariance,
			MAX(avg_st.STOCK_COUNT) AS DAY_COUNT
			
			--avg_sp.avg_chg as avg_snp_price_change, snp.PRICE_CHANGE as snp_price_change, snp.Date as snp_date, st.date, st.PRICE_CHANGE, avg_st.avg_chg
			 FROM  AVG_SP,
			 STOCK_PRICE_CHANGE st JOIN
			 SNP_PRICE_CHANGE snp
			 ON snp.Date=st.Date
			 JOIN 
			 ( SELECT Stock, AVG(PRICE_CHANGE) as avg_chg, COUNT(*) AS STOCK_COUNT FROM STOCK_PRICE_CHANGE GROUP BY Stock) avg_st
			 ON st.Stock=avg_st.Stock
		GROUP BY st.Stock
		)

		SELECT stcovar.Stock, (SELECT SNP_DAY_COUNT from SNP_VAR), DAY_COUNT, stcovar.covariance , (SELECT variance from SNP_VAR) as snp_variance, stcovar.covariance / (SELECT variance from SNP_VAR) as beta
		FROM STOCK_COVAR stcovar





