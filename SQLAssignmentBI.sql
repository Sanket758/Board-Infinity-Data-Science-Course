show databases;
use northwind;
show tables;
select * from order_details;
select * from orders;
select * from categories;
select * from products;
select * from employees;

ALTER TABLE `northwind`.`order details` 
RENAME TO  `northwind`.`order_details` ;

# Query 1
# first we will get the order id and then calculate the subtotal using given formula and group them by order id so that multiple id's will be grouped
select OrderID, 
    sum(UnitPrice * Quantity * (1 - Discount)) as sub_total
from order_details
group by OrderID;

# Query 2
# looking in orders table shippeddate is the whole date with dd-mm-yyyy format, we only need year so using year() function on it
# we will need to use join to join two tables as shippeddate is in orders table where as sub_total is calcualated on order_details table
select distinct date(a.ShippedDate) as ShippedDate, 
    a.OrderID, 
    b.sub_total, 
    year(a.ShippedDate) as Year
from orders a 
inner join
(
    select OrderID, 
    sum(UnitPrice * Quantity * (1 - Discount)) as sub_total
	from order_details
	group by OrderID
) b on a.OrderID = b.OrderID
where a.ShippedDate is not null;


# Query 3 
# First we select all the employee names and as our order details is in different table we will need to do a join
# on orders table we will need to calculate the sub-total and join it
select distinct a.Country, 
    a.LastName, 
    a.FirstName, 
    b.OrderID, 
    c.sub_total as Total_Sales
from employees a
inner join orders b on b.EmployeeID = a.EmployeeID
inner join 
(
    select distinct OrderID, 
        round(sum(UnitPrice * Quantity * (1 - Discount)), 2) as sub_total
    from order_details
    group by OrderID    
) c on b.OrderID = c.OrderID
order by a.LastName, a.FirstName, a.Country;

# Query 4 
 -- using order by it will arrange the product name to be in alphabetical order
select ProductName, ProductID, SupplierID, CategoryID, QuantityPerUnit, UnitPrice 
from products 
order by ProductName;

# Query 5
# Get all the products from product table where discontinues=N 
select ProductID, ProductName
from products
where Discontinued = 'N'
order by ProductName;

# Query 6
# we can calculate the discount by sub total formula 
select distinct b.OrderID, 
    b.ProductID, 
    a.ProductName, 
    b.UnitPrice, 
    b.Quantity, 
    b.Discount, 
    round(b.UnitPrice * b.Quantity * (1 - b.Discount), 2) as AddedDiscountPrice
from products a
inner join order_details b on a.ProductID = b.ProductID
order by b.OrderID;

# Query 7: Normal Joins
select distinct a.CategoryID, 
    a.CategoryName,  
    b.ProductName, 
    sum(round(c.UnitPrice * c.Quantity * (1 - c.Discount), 2)) as ProductSales
from order_details c
inner join orders d on d.OrderID = c.OrderID
inner join products b on b.ProductID = c.ProductID
inner join categories a on a.CategoryID = b.CategoryID
group by a.CategoryID, a.CategoryName, b.ProductName
order by a.CategoryName, b.ProductName, ProductSales;

# Query 7: joins and subquery
select distinct a.CategoryID, 
    a.CategoryName, 
    b.ProductName, 
    sum(c.ExtendedPrice) as ProductSales
from categories a 
inner join products b on a.CategoryID = b.CategoryID
inner join 
(
    select distinct y.OrderID, 
        y.ProductID, 
        x.ProductName, 
        y.UnitPrice, 
        y.Quantity, 
        y.Discount, 
        round(y.UnitPrice * y.Quantity * (1 - y.Discount), 2) as ExtendedPrice
    from products x
    inner join order_details y on x.ProductID = y.ProductID
    order by y.OrderID
) c on c.ProductID = b.ProductID
inner join orders d on d.OrderID = c.OrderID
group by a.CategoryID, a.CategoryName, b.ProductName
order by a.CategoryName, b.ProductName, ProductSales;

# Query 8
# Just put a limit of 10 to get the top ten products
select * from
(
    select distinct ProductName as Top_Ten_Expensive_Products, UnitPrice
    from products
    order by UnitPrice desc
) as a
limit 10;

# Query 9
# To merge we can just use union operation and add one more collumn to show the relationship
select City, CompanyName, ContactName, 'Customer' as new_collumn 
from customers
union
select City, CompanyName, ContactName, 'Supplier'
from suppliers
order by City, CompanyName;

# Query 10
# Just get the avg price from the unitprice and only show those values from whole products table, we can use subquery here
select distinct ProductName, UnitPrice
from products
where UnitPrice > (select avg(UnitPrice) from products)
order by UnitPrice;

# Query 11
# to get the quartes we can use Quarter method on the date values
select distinct a.CategoryName, 
    b.ProductName, 
    sum(c.UnitPrice * c.Quantity * (1 - c.Discount)) as ProductSales,
    concat('Qtr ', quarter(d.ShippedDate)) as ShippedQuarter
from categories a
inner join products b on a.CategoryID = b.CategoryID
inner join order_details c on b.ProductID = c.ProductID
inner join orders d on d.OrderID = c.OrderID
where d.ShippedDate between date('1997-01-01') and date('1997-12-31')
group by a.CategoryName, 
    b.ProductName, 
    concat('Qtr ', quarter(d.ShippedDate))
order by a.CategoryName, 
    b.ProductName, 
    ShippedQuarter;
    
# Query no 12
# getting total sales by the category
select CategoryName, format(sum(ProductSales), 2) as CategorySales
from
(
    select distinct a.CategoryName, 
        b.ProductName, 
        format(sum(c.UnitPrice * c.Quantity * (1 - c.Discount)), 2) as ProductSales,
        concat('Qtr ', quarter(d.ShippedDate)) as ShippedQuarter
    from categories as a
    inner join products as b on a.CategoryID = b.CategoryID
    inner join order_details as c on b.ProductID = c.ProductID
    inner join orders as d on d.OrderID = c.OrderID 
    where d.ShippedDate between date('1997-01-01') and date('1997-12-31')
    group by a.CategoryName, 
        b.ProductName, 
        concat('Qtr ', quarter(d.ShippedDate))
    order by a.CategoryName, 
        b.ProductName, 
        ShippedQuarter
) as x
group by CategoryName
order by CategoryName;

# Query 13
# just use the case in sql to show the values of every qtr
select a.ProductName, 
    d.CompanyName, 
    year(OrderDate) as OrderYear,
    format(sum(case quarter(c.OrderDate) when '1' 
        then b.UnitPrice*b.Quantity*(1-b.Discount) else 0 end), 0) 'Qtr 1',
    format(sum(case quarter(c.OrderDate) when '2' 
        then b.UnitPrice*b.Quantity*(1-b.Discount) else 0 end), 0) 'Qtr 2',
    format(sum(case quarter(c.OrderDate) when '3' 
        then b.UnitPrice*b.Quantity*(1-b.Discount) else 0 end), 0) 'Qtr 3',
    format(sum(case quarter(c.OrderDate) when '4' 
        then b.UnitPrice*b.Quantity*(1-b.Discount) else 0 end), 0) 'Qtr 4' 
from products a 
inner join order_details b on a.ProductID = b.ProductID
inner join orders c on c.OrderID = b.OrderID
inner join customers d on d.CustomerID = c.CustomerID 
group by a.ProductName, 
    d.CompanyName, 
    year(OrderDate)
order by a.ProductName, d.CompanyName;