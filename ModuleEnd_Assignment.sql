USE ecomm;
-- 1 mpute mean for WarehouseToHome 
SET SQL_SAFE_UPDATES = 0;

UPDATE customer_churn 
SET WarehouseToHome = (
    SELECT avg_value
    FROM (
        SELECT ROUND(AVG(WarehouseToHome)) AS avg_value
        FROM customer_churn
    ) AS temp)
WHERE WarehouseToHome IS NULL;

-- 2 Impute mean for HourSpendOnApp
UPDATE customer_churn
SET HourSpendOnApp = (
    SELECT average_value
    FROM (
        SELECT ROUND(AVG(HourSpendOnApp)) AS average_value
        FROM customer_churn
    ) AS temp
)
WHERE HourSpendOnApp IS NULL;

-- 3 Impute mean for OrderAmountHikeFromlastYear
update customer_churn 
set OrderAmountHikeFromlastYear =
(select average_value from(select round(AVG(OrderAmountHikeFromlastYear)) as  average_value from customer_churn)
as temp) 
where OrderAmountHikeFromlastYear is null;

-- 4.Impute mean for DaySinceLastOrder

update customer_churn 
set DaySinceLastOrder =
(select average_value from(select round(AVG(DaySinceLastOrder)) as  average_value from customer_churn)
as temp) 
where DaySinceLastOrder is null;

-- 5 Impute mode for Tenure
UPDATE customer_churn
SET Tenure = (
    SELECT modevalue
    FROM (
        SELECT Tenure AS modevalue
        FROM customer_churn
        WHERE Tenure IS NOT NULL
        GROUP BY Tenure
        ORDER BY COUNT(*) DESC
        LIMIT 1
    ) AS temp
)
WHERE Tenure IS NULL;

-- 6. Impute mode for CouponUsed
UPDATE customer_churn
SET CouponUsed = (
    SELECT mode_value
    FROM (
        SELECT CouponUsed AS mode_value
        FROM customer_churn
        WHERE CouponUsed IS NOT NULL
        GROUP BY CouponUsed
        ORDER BY COUNT(*) DESC
        LIMIT 1
    ) AS temp
)
WHERE CouponUsed IS NULL;

-- 7. Impute mode for OrderCount
UPDATE customer_churn
SET OrderCount = (
    SELECT order_value
    FROM (
        SELECT OrderCount AS ordervalue
        FROM customer_churn
        WHERE OrderCount IS NOT NULL
        GROUP BY OrderCount
        ORDER BY COUNT(*) DESC
        LIMIT 1
    ) AS temp
)
WHERE OrderCount IS NULL;

-- 8. Remove WarehouseToHome outliers
		DELETE FROM customer_churn
		WHERE WarehouseToHome > 100;

-- SELECT * FROM customer_churn WHERE WarehouseToHome > 100;
---------------------------------------------------------------- -------------------------
-- Dealing with Inconsistencies:
-- 1 Replace Phone with Mobile Phone
		UPDATE customer_churn
		SET PreferredLoginDevice = 'Mobile Phone'
		WHERE PreferredLoginDevice = 'Phone';
        
        UPDATE customer_churn
		SET PreferedOrderCat = 'Mobile Phone'
		WHERE PreferedOrderCat  = 'Phone';

 -- 2 Replace COD with Cash on Delivery
      UPDATE customer_churn
	  SET PreferredPaymentMode ='Cash on Delivery'
      WHERE PreferredPaymentMode ='COD';
      
   -- Replace CC with Credit Card
       UPDATE customer_churn
	  SET PreferredPaymentMode ='Credit Card'
      WHERE PreferredPaymentMode ='CC';
   
   ---------------------------------------------------------------- -------------------------
 SET SQL_SAFE_UPDATES = 1;
 
--  Data Transformation:
     -- Rename PreferedOrderCat
		 ALTER TABLE customer_churn
		 RENAME COLUMN PreferedOrderCat TO PreferredOrderCat;
		 
     -- Rename HourSpendOnApp
        ALTER TABLE customer_churn
        RENAME COLUMN HourSpendOnApp TO HoursSpentOnApp;
     
     -- Creating New Columns:
      ALTER TABLE customer_churn ADD COLUMN ComplaintReceived VARCHAR(10);  
      UPDATE customer_churn 
      SET ComplaintReceived =
			CASE
				WHEN Complain = 1 THEN 'Yes'
				ELSE 'No'
			END;
   
	 ALTER TABLE customer_churn ADD COLUMN ChurnStatus VARCHAR(10); 
	 UPDATE customer_churn 
      SET ChurnStatus =
		  CASE
			 WHEN Churn =1 THEN 'Churned'
			 ELSE 'Active'
		  END;   
-- Column Dropping:  
         ALTER TABLE customer_churn DROP COLUMN Complain;
         ALTER TABLE customer_churn DROP COLUMN Churn;
----------------------------------------------------------------------------------------------------------------------------------------- 
-- Data Exploration & Analysis
     -- Count churned and active customers	
          SELECT ChurnStatus,COUNT(*) AS CustomerCount FROM customer_churn GROUP BY ChurnStatus;
          
     -- Average tenure and total cashback of churned customers
		 SELECT AVG(Tenure) AS AverageTenure, SUM(CashbackAmount) AS TotalCashbackAmount
         FROM customer_churn WHERE ChurnStatus = 'Churned';
         
	 -- Percentage of churned customers who complained
        SELECT ROUND(SUM(CASE WHEN ComplaintReceived = 'Yes' THEN 1 ELSE 0 END)
        * 100.0 / COUNT(*),2) AS ComplaintPercentage
		FROM customer_churn WHERE ChurnStatus = 'Churned';
        
	 --  City tier with highest churned customers whose category is Laptop & Accessory
        SELECT CityTier,COUNT(*) AS ChurnedCustomers
        FROM customer_churn WHERE ChurnStatus = 'Churned' AND PreferredOrderCat = 'Laptop & Accessory'
        GROUP BY CityTier ORDER BY ChurnedCustomers DESC LIMIT 1;
        
     -- Most preferred payment mode among active customers
       SELECT PreferredPaymentMode, COUNT(*) AS CustomerCount
       FROM customer_churn WHERE ChurnStatus = 'Active'
	   GROUP BY PreferredPaymentMode ORDER BY CustomerCount DESC LIMIT 1;
       
	 -- Total order amount hike for single customers preferring mobile phones
       SELECT SUM(OrderAmountHikeFromlastYear) AS TotalOrderAmountHike
	   FROM customer_churn WHERE MaritalStatus = 'Single' AND PreferredOrderCat = 'Mobile Phone';
       
     -- Average devices registered by customers using UPI
       SELECT AVG(NumberOfDeviceRegistered) AS AverageDevicesRegistered
	   FROM customer_churn WHERE PreferredPaymentMode = 'UPI';

     -- . City tier with the highest number of customers
        SELECT CityTier, COUNT(*) AS CustomerCount FROM customer_churn
        GROUP BY CityTier ORDER BY CustomerCount DESC LIMIT 1;
     
     -- Gender that used the highest number of coupons
        SELECT Gender, SUM(CouponUsed) AS TotalCouponsUsed FROM customer_churn
        GROUP BY Gender ORDER BY TotalCouponsUsed DESC LIMIT 1;
        
	-- Number of customers and maximum hours spent on app in each order category
       SELECT PreferredOrderCat, COUNT(*) AS CustomerCount,MAX(HoursSpentOnApp) AS MaximumHoursSpent
       FROM customer_churn GROUP BY PreferredOrderCat;
       
    -- Total order count for credit-card users with maximum satisfaction score
       SELECT SUM(OrderCount) AS TotalOrderCount FROM customer_churn 
	   WHERE PreferredPaymentMode = 'Credit Card' AND SatisfactionScore = 
      (SELECT MAX(SatisfactionScore) FROM customer_churn);
      
	-- Average satisfaction score of customers who complained
      SELECT AVG(SatisfactionScore) AS AverageSatisfactionScore
      FROM customer_churn WHERE ComplaintReceived = 'Yes';
    
    -- Preferred order categories among customers who used more than 5 coupons
		SELECT DISTINCT PreferredOrderCat
		FROM customer_churn WHERE CouponUsed > 5;
        
	-- Top 3 order categories with highest average cashback
		SELECT PreferredOrderCat,AVG(CashbackAmount) AS AverageCashback
		FROM customer_churn
		GROUP BY PreferredOrderCat
		ORDER BY AverageCashback DESC
		LIMIT 3;

-- Preferred payment modes of customers whose average tenure is 10 months and order count > 500
		SELECT DISTINCT PreferredPaymentMode
		FROM customer_churn WHERE Tenure = 10 AND OrderCount > 500;
  
  -- Categorize customers based on warehouse distance
		  SELECT
			CASE
				WHEN WarehouseToHome <= 5 THEN 'Very Close Distance'
				WHEN WarehouseToHome <= 10 THEN 'Close Distance'
				WHEN WarehouseToHome <= 15 THEN 'Moderate Distance'
				ELSE 'Far Distance'
			END AS DistanceCategory,
			ChurnStatus, COUNT(*) AS CustomerCount
		FROM customer_churn
		GROUP BY
			CASE
				WHEN WarehouseToHome <= 5 THEN 'Very Close Distance'
				WHEN WarehouseToHome <= 10 THEN 'Close Distance'
				WHEN WarehouseToHome <= 15 THEN 'Moderate Distance'
				ELSE 'Far Distance'
			END,
			ChurnStatus
		ORDER BY DistanceCategory, ChurnStatus;

-- Customers who are married, City Tier-1 and order count greater than average
			SELECT
				CustomerID,
				OrderCount,
				PreferredOrderCat,
				PreferredPaymentMode,
				CityTier,
				MaritalStatus
			FROM customer_churn
			WHERE MaritalStatus = 'Married' AND CityTier = 1 AND OrderCount >
			(SELECT AVG(OrderCount) FROM customer_churn);

   -- Create customer_returns
		CREATE TABLE customer_returns (
			ReturnID INT PRIMARY KEY,
			CustomerID INT,
			ReturnDate DATE,
			RefundAmount DECIMAL(10,2)
		);
--  Insert  data
		INSERT INTO customer_returns
		(ReturnID, CustomerID, ReturnDate, RefundAmount)
		VALUES
		(1001, 50022, '2023-01-01', 2130),
		(1002, 50316, '2023-01-23', 2000),
		(1003, 51099, '2023-02-14', 2290),
		(1004, 52321, '2023-03-08', 2510),
		(1005, 52928, '2023-03-20', 3000),
		(1006, 53749, '2023-04-17', 1740),
		(1007, 54206, '2023-04-21', 3250),
		(1008, 54838, '2023-04-30', 1990);

-- Display return details + customer details for churned customers who complained
		SELECT
			r.ReturnID,
			r.CustomerID,
			r.ReturnDate,
			r.RefundAmount,
			c.ChurnStatus,
			c.ComplaintReceived,
			c.Tenure,
			c.PreferredPaymentMode,
			c.PreferredOrderCat,
			c.SatisfactionScore,
			c.OrderCount,
			c.CashbackAmount
		FROM customer_returns r
		JOIN customer_churn c
			ON r.CustomerID = c.CustomerID
		WHERE c.ChurnStatus = 'Churned'
		  AND c.ComplaintReceived = 'Yes';



SET SQL_SAFE_UPDATES = 1;