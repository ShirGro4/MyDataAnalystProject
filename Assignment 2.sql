-- 1

SELECT pp.ProductID, pp.Name, pp.Color, pp.ListPrice, pp.Size
FROM Production.Product AS pp LEFT JOIN Sales.SalesOrderDetail AS sod ON sod.ProductID=pp.ProductID
WHERE sod.ProductID IS NULL
ORDER BY pp.ProductID ASC

-- 2

SELECT sc.CustomerID, ISNULL(pp.LastName, 'unknown') AS 'LastName', ISNULL(pp.FirstName, 'Unknown') AS 'FirstName'
FROM Sales.Customer AS sc LEFT JOIN Sales.SalesOrderHeader AS soh ON sc.CustomerID=soh.CustomerID
						  LEFT JOIN Person.Person AS pp ON sc.CustomerID=pp.BusinessEntityID
WHERE soh.CustomerID IS NULL
ORDER BY sc.CustomerID ASC


-- 3

SELECT TOP (10) (COUNT(s.SalesOrderID)) AS CountOfOrders, sc.CustomerID, p.FirstName, p.LastName
FROM Sales.Customer AS sc JOIN Person.Person AS p ON sc.PersonID=p.BusinessEntityID
						JOIN Sales.SalesOrderHeader AS s ON sc.CustomerID=s.CustomerID
GROUP BY  sc.CustomerID, p.FirstName, p.LastName
ORDER BY CountOfOrders DESC

-- 4

SELECT p.FirstName, p.LastName, emp.JobTitle, emp.HireDate, 
		COUNT(emp.BusinessEntityID) OVER(PARTITION BY emp.JobTitle) AS 'CountOfTitle'
FROM HumanResources.Employee AS emp
	JOIN Person.Person AS p ON emp.BusinessEntityID=p.BusinessEntityID

-- 5


SELECT y.SalesOrderID,
		 y.CustomerID, 
		 y.LastName,
		 y.FirstName, 
		 LastOrder, 
		 PreviousOrder
FROM (
	SELECT s.SalesOrderID,
	sc.CustomerID,
	p.LastName,
	p.FirstName, 
	orderdate AS LastOrder,
	LAG(s.OrderDate) OVER (PARTITION BY sc.customerid ORDER BY s.orderdate) AS PreviousOrder,
	DENSE_RANK () OVER (PARTITION BY sc.customerid ORDER BY max(orderdate) DESC) AS rn
	FROM Sales.Customer AS sc JOIN Person.Person AS p ON sc.PersonID=p.BusinessEntityID
							JOIN Sales.SalesOrderHeader AS s ON sc.CustomerID=s.CustomerID 
	GROUP BY OrderDate, s.SalesOrderID, sc.CustomerID, p.LastName, p.FirstName
	)y
WHERE rn=1 
ORDER BY CustomerID DESC

-- 6

with cte
as
(select YEAR(soh.OrderDate) as y,
sod.SalesOrderID, 
pp.LastName, 
pp.FirstName, 
sum(sod.UnitPrice*(1-sod.UnitPriceDiscount)*OrderQty) over (partition by sod.salesorderid) as total
from Sales.Customer as sc join Sales.SalesOrderHeader as soh
				 on sc.CustomerID=soh.CustomerID 
								join Sales.SalesOrderDetail as sod on soh.SalesOrderID=sod.SalesOrderID
								join Person.Person as pp on sc.PersonID=pp.BusinessEntityID

) ,
cte2
as
(select y,  FirstName, LastName, total,
 max(total) over (partition by y) as totalperyear
from cte
)
select y, FirstName, LastName, totalperyear
from cte2
where total = totalperyear
group by FirstName, LastName, y, total, totalperyear
order by y asc, total desc


-- 7

SELECT s_month, ISNULL([2011], 0) AS '2011', ISNULL([2012], 0) AS '2012', ISNULL([2013], 0) AS '2013', ISNULL([2014], 0) AS '2014'
FROM (SELECT year(OrderDate) AS s_year, month(OrderDate) AS s_month, COUNT(SalesOrderID) AS counta
FROM Sales.SalesOrderHeader
GROUP BY year(OrderDate), MONTH(OrderDate)) y
PIVOT (sum(counta) FOR s_year IN ([2011], [2012], [2013], [2014])) AS pvt


-- 8

WITH MonthlyCosts AS (
    SELECT
        YEAR(OrderDate) AS OrderYear,
        MONTH(OrderDate) AS OrderMonth,
        SUM(UnitPrice) AS MonthlyCost
    FROM
        Sales.SalesOrderHeader soh
         JOIN Sales.SalesOrderDetail sod ON soh.SalesOrderID = sod.SalesOrderID
    GROUP BY
        YEAR(OrderDate),
        MONTH(OrderDate)
),
CumulativeCosts AS (
    SELECT
        OrderYear,
        OrderMonth,
        MonthlyCost,
        SUM(MonthlyCost) OVER (PARTITION BY OrderYear ORDER BY OrderMonth) AS CumulativeCost
    FROM
        MonthlyCosts
)
SELECT
    OrderYear,
    OrderMonth,
    MonthlyCost,
    CumulativeCost
FROM
    CumulativeCosts
ORDER BY
    OrderYear,
    OrderMonth;

-- 9
SELECT hd.Name AS DepartmentName,
		 he.BusinessEntityID AS EmployeeID, 
		 CONCAT(FirstName, ' ', LastName) AS EmployeeName, 
		 HireDate,
		DATEDIFF (MM, hiredate, GETDATE()) AS Seniority, 
		LAG(CONCAT(firstname, ' ' , LastName)) OVER (PARTITION BY hd.name ORDER BY hiredate) AS PreviousEmpname,
		LAG (hiredate,1) OVER (PARTITION BY hd.name ORDER BY hiredate ASC) AS PreviousEmpHireDate,
		DATEDIFF(DD, LAG (hiredate,1) OVER (PARTITION BY hd.name ORDER BY DATEDIFF(MM, hiredate, GETDATE()) DESC), HireDate) AS DiffDate
FROM HumanResources.Employee AS he JOIN Person.Person AS pp ON he.BusinessEntityID=pp.BusinessEntityID
									JOIN HumanResources.EmployeeDepartmentHistory AS hed ON hed.BusinessEntityID=he.BusinessEntityID 
									JOIN HumanResources.Department AS hd ON hed.DepartmentID=hd.DepartmentID

ORDER BY hd.Name ASC, HireDate DESC



-- 10

SELECT he.HireDate, hed.DepartmentID, STRING_AGG(CAST(he.BusinessEntityID AS VARCHAR)+' '+pp.FirstName+' '+pp.LastName, ' , ') TeamEmployees
FROM HumanResources.Employee AS he 
	JOIN HumanResources.EmployeeDepartmentHistory AS hed
	ON he.BusinessEntityID = hed.BusinessEntityID
	JOIN Person.Person AS pp
	ON hed.BusinessEntityID = pp.BusinessEntityID
GROUP BY he.HireDate, hed.DepartmentID
ORDER BY he.HireDate DESC






-- 6


-- good to go from here
select YEAR(OrderDate), sod.SalesOrderID, pp.LastName, pp.FirstName, sod.UnitPrice*(1-sod.UnitPriceDiscount)*OrderQty as total
from Sales.Customer as sc join Sales.SalesOrderHeader as soh on sc.CustomerID=soh.CustomerID join Sales.SalesOrderDetail as sod on soh.SalesOrderID=sod.SalesOrderID
									join Person.Person as pp on sc.PersonID=pp.BusinessEntityID 
order by LastName

with cte
as
(select YEAR(soh.OrderDate) as y,
sod.SalesOrderID, 
pp.LastName, 
pp.FirstName, 
sum(sod.UnitPrice*(1-sod.UnitPriceDiscount)*OrderQty) over (partition by sod.salesorderid) as total
from Sales.Customer as sc join Sales.SalesOrderHeader as soh
				 on sc.CustomerID=soh.CustomerID 
								join Sales.SalesOrderDetail as sod on soh.SalesOrderID=sod.SalesOrderID
								join Person.Person as pp on sc.PersonID=pp.BusinessEntityID

) 
select y, format(max(total), 'c', 'en-us') as total
from cte
group by y
order by y asc, total desc



WITH cteperson
AS
(SELECT *
FROM Person.Person),
ctecustomer
as (select *
	from Sales.Customer),
ctesod
AS (SELECT max(UnitPrice*(1-UnitPriceDiscount)*OrderQty) as total, SalesOrderID
	FROM Sales.SalesOrderDetail),
ctesoh
as (select *
	from Sales.SalesOrderHeader)

SELECT FirstName, LastName
FROM ctecustomer as sc join ctesoh as soh on sc.CustomerID=soh.CustomerID join ctesod as sod on soh.SalesOrderID=sod.SalesOrderID
									join cteperson as pp on sc.PersonID=pp.BusinessEntityID
group by YEAR(OrderDate), soh.SalesOrderID





















select STUFF((select he.BusinessEntityID, CONCAT(FirstName,' ' ,LastName) as cd
					from HumanResources.Employee AS he JOIN Person.Person AS pp ON he.BusinessEntityID=pp.BusinessEntityID
					for xml path('')) ,1,1,'') x
select HireDate, hd.DepartmentID, CONCAT(FirstName,' ' ,LastName) as empname
from HumanResources.Employee AS he JOIN Person.Person AS pp ON he.BusinessEntityID=pp.BusinessEntityID
									JOIN HumanResources.EmployeeDepartmentHistory AS hed ON hed.BusinessEntityID=he.BusinessEntityID 
									JOIN HumanResources.Department AS hd ON hed.DepartmentID=hd.DepartmentID
order by HireDate desc


SELECT STUFF((SELECT ', '+ City
			FROM Employees
			FOR XML PATH(''))	,1,1,'') -- יש פה סאבקוורי שנמשך עד סוף הפאת' ולכן יש שני סוגריים


select STUFF((select he.BusinessEntityID, CONCAT(FirstName,' ' ,LastName) as cd
					from HumanResources.Employee AS he JOIN Person.Person AS pp ON he.BusinessEntityID=pp.BusinessEntityID
					for xml path('')) ,1,1,'') x
group by hiredate

select HireDate, hd.DepartmentID, CONCAT(FirstName,' ' ,LastName) as empname
from HumanResources.Employee AS he JOIN Person.Person AS pp ON he.BusinessEntityID=pp.BusinessEntityID
									JOIN HumanResources.EmployeeDepartmentHistory AS hed ON hed.BusinessEntityID=he.BusinessEntityID 
									JOIN HumanResources.Department AS hd ON hed.DepartmentID=hd.DepartmentID
order by HireDate desc


  






select *, row_number() over (partition by hed.businessentityid order by startdate) as rn
from (
select *, stuff((
select he.BusinessEntityID, ' ', CONCAT(FirstName,' ' ,LastName) as empname, ',', ' '
from HumanResources.Employee AS he JOIN Person.Person AS pp ON he.BusinessEntityID=pp.BusinessEntityID
for xml path(''), TYPE).value('.', 'NVARCHAR(MAX)') ,1,1,'') as TeamEmployees 
from 
(Select HireDate, hd.DepartmentID
from HumanResources.Employee AS he JOIN Person.Person AS pp ON he.BusinessEntityID=pp.BusinessEntityID
									JOIN HumanResources.EmployeeDepartmentHistory AS hed ON hed.BusinessEntityID=he.BusinessEntityID 
									JOIN HumanResources.Department AS hd ON hed.DepartmentID=hd.DepartmentID
group by HireDate, hd.DepartmentID
) hh 
) ff
order by HireDate desc






select he.BusinessEntityID, FirstName, lastname, HireDate, hd.DepartmentID -- הדיפרטמנט הראשון שהעובד היה בו
from HumanResources.Employee AS he   JOIN Person.Person AS pp ON he.BusinessEntityID=pp.BusinessEntityID
									 JOIN HumanResources.EmployeeDepartmentHistory AS hed ON hed.BusinessEntityID=he.BusinessEntityID JOIN HumanResources.Department AS hd ON hed.DepartmentID=hd.DepartmentID
									 
order by HireDate


select *
from (select firstname, lastname, hd.DepartmentID, he.BusinessEntityID, JobTitle, Name, DENSE_RANK() over (partition by he.businessentityid order by startdate) as rn
from HumanResources.Employee AS he   JOIN Person.Person AS pp ON he.BusinessEntityID=pp.BusinessEntityID
									 JOIN HumanResources.EmployeeDepartmentHistory AS hed ON hed.BusinessEntityID=he.BusinessEntityID JOIN HumanResources.Department AS hd ON hed.DepartmentID=hd.DepartmentID) yy
									  
where rn=1
order by FirstName


select *
from HumanResources.EmployeeDepartmentHistory


select Name, DepartmentID, *
from HumanResources.Department 















select DENSE_RANK() over (partition by he.businessentityid order by startdate) as rn
from (

select *, stuff((
select he.BusinessEntityID, ' ', CONCAT(FirstName,' ' ,LastName) as empname, ',', ' '
for xml path(''), TYPE).value('.', 'NVARCHAR(MAX)') ,1,1,'') as TeamEmployees
(
from 
	(Select HireDate, hd.DepartmentID
	from HumanResources.Employee AS he JOIN Person.Person AS pp ON he.BusinessEntityID=pp.BusinessEntityID
									JOIN HumanResources.EmployeeDepartmentHistory AS hed ON hed.BusinessEntityID=he.BusinessEntityID 
									JOIN HumanResources.Department AS hd ON hed.DepartmentID=hd.DepartmentID
	group by HireDate, hd.DepartmentID
	) hh
	)ew
	) ef
order by HireDate desc    











select  *, format(max(total), 'c', 'en-us')
from (
select *,
	 sum(df.UnitPrice*(1-df.UnitPriceDiscount)*df.OrderQty) over (partition by df.salesorderid) as total
from (
select YEAR(soh.OrderDate) as y,sod.SalesOrderID, pp.LastName, pp.FirstName, UnitPrice, UnitPriceDiscount, OrderQty
from Sales.Customer as sc join Sales.SalesOrderHeader as soh
				 on sc.CustomerID=soh.CustomerID
								join Sales.SalesOrderDetail as sod on soh.SalesOrderID=sod.SalesOrderID
								join Person.Person as pp on sc.PersonID=pp.BusinessEntityID
	) df
	group by y, df.SalesOrderID) dfs









select y, format(max(total), 'c', 'en-us') as total
from cte
group by y
order by y asc, total desc



