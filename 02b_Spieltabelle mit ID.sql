SELECT      Customers.CustomerID, Customers.CompanyName, Customers.ContactName, Customers.ContactTitle, Customers.City, Customers.Country, Employees.LastName, Employees.FirstName, Orders.OrderDate, Orders.EmployeeID, Orders.Freight, Orders.ShipName, Orders.ShipAddress, Orders.ShipCity,
                   Orders.ShipCountry, [Order Details].OrderID, [Order Details].ProductID, [Order Details].UnitPrice, [Order Details].Quantity, Products.ProductName, Products.UnitsInStock
INTO KundenUmsatz
FROM         Customers INNER JOIN
                   Orders ON Customers.CustomerID = Orders.CustomerID INNER JOIN
                   Employees ON Orders.EmployeeID = Employees.EmployeeID INNER JOIN
                   [Order Details] ON Orders.OrderID = [Order Details].OrderID INNER JOIN
                   Products ON [Order Details].ProductID = Products.ProductID


insert into KundeUmsatz
select * from kundeumsatz
GO 9 


alter table kundeumsatz add ID int identity
GO
