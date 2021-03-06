IF OBJECT_ID('PURCHASEORDER5123') IS NOT NULL
DROP TABLE PURCHASEORDER5123;

IF OBJECT_ID('INVENTORY5123') IS NOT NULL
DROP TABLE INVENTORY5123;

IF OBJECT_ID('ORDERLINE5123') IS NOT NULL
DROP TABLE ORDERLINE5123;

IF OBJECT_ID('ORDER5123') IS NOT NULL
DROP TABLE [ORDER5123];

IF OBJECT_ID('AUTHORISEDPERSON5123') IS NOT NULL
DROP TABLE AUTHORISEDPERSON5123;

IF OBJECT_ID('ACCOUNTPAYMENT5123') IS NOT NULL
DROP TABLE ACCOUNTPAYMENT5123;

IF OBJECT_ID('CLIENTACCOUNT5123') IS NOT NULL
DROP TABLE CLIENTACCOUNT5123;

IF OBJECT_ID('PRODUCT5123') IS NOT NULL
DROP TABLE PRODUCT5123;

IF OBJECT_ID('LOCATION5123') IS NOT NULL
DROP TABLE [LOCATION5123];

IF OBJECT_ID('GENERALLEDGER5123') IS NOT NULL
DROP TABLE GENERALLEDGER5123;

GO

CREATE TABLE GENERALLEDGER5123(
    ITEMID INTEGER,
    DESCRIPTION NVARCHAR(100),
    AMOUNT MONEY,
    CONSTRAINT PK_GENERALLEDGER PRIMARY KEY (ITEMID),
    CONSTRAINT UQ_GENERALEDGER_DESCRIPTION UNIQUE(DESCRIPTION)
);

INSERT INTO GENERALLEDGER5123 (ITEMID, DESCRIPTION, AMOUNT) VALUES
(1, 'ASSETSCASH', 100000.00),
(2, 'ASSETSSTOCK', 0),
(3, 'ASSETSACCOUNT', 0);

CREATE TABLE [LOCATION5123](
    LOCATIONID NVARCHAR(8),
    LOCNAME NVARCHAR(50) NOT NULL,
    ADDRESS NVARCHAR(200) NOT NULL,
    MANAGER NVARCHAR(100),
    CONSTRAINT PK_LOCATION PRIMARY KEY (LOCATIONID)
);

CREATE TABLE PRODUCT5123(
    PRODUCTID INTEGER IDENTITY(10001, 1),
    PRODNAME NVARCHAR(100) NOT NULL,
    BUYPRICE MONEY,
    SELLPRICE MONEY,
    CONSTRAINT PK_PRODUCT PRIMARY KEY(PRODUCTID),
    CONSTRAINT CHK_WHOLESALE_RETAIL CHECK(BUYPRICE < SELLPRICE)
);

CREATE TABLE CLIENTACCOUNT5123(
    ACCOUNTID INTEGER IDENTITY(30001, 1),
    ACCTNAME NVARCHAR(100) NOT NULL,
    BALANCE MONEY NOT NULL,
    CREDITLIMIT MONEY NOT NULL,
    CONSTRAINT PK_CLIENTACCOUNT PRIMARY KEY(ACCOUNTID),
    CONSTRAINT CHK_CLIENTACCOUNT_BALANCE_CREDIT CHECK(BALANCE<=CREDITLIMIT),
    CONSTRAINT UQ_CLENTACCOUNT_NAME UNIQUE(ACCTNAME)
);

CREATE TABLE ACCOUNTPAYMENT5123(
    ACCOUNTID INTEGER,
    DATETIMERECEIVED DATETIME,
    AMOUNT MONEY NOT NULL,
    CONSTRAINT PK_ACCOUNTPAYMENT PRIMARY KEY(ACCOUNTID, DATETIMERECEIVED),
    CONSTRAINT FK_ACCOUNTPAYMENT_ACCOUNT FOREIGN KEY (ACCOUNTID) REFERENCES CLIENTACCOUNT5123,
    CONSTRAINT CHK_ACCOUNTPAYMENT_AMOUNT CHECK(AMOUNT >0)
);

CREATE TABLE AUTHORISEDPERSON5123(
    USERID INTEGER IDENTITY(50001, 1),
    FIRSTNAME NVARCHAR(100) NOT NULL,
    SURNAME NVARCHAR(100) NOT NULL,
    EMAIL NVARCHAR(100) NOT NULL,
    [PASSWORD] NVARCHAR(100) NOT NULL,
    ACCOUNTID INTEGER NOT NULL,
    CONSTRAINT PK_AUTHORISEDPERSON PRIMARY KEY(USERID),
    CONSTRAINT FK_AUTHORISEDPERSON_CLIENTACCOUNT FOREIGN KEY(ACCOUNTID) REFERENCES CLIENTACCOUNT5123,
    CONSTRAINT CHK_AUTHORISEDPERSON_EMAIL CHECK(EMAIL LIKE '%@%')
);

CREATE TABLE [ORDER5123](
    ORDERID INTEGER IDENTITY(70001, 1),
    SHIPPINGADDRESS NVARCHAR(200) NOT NULL,
    DATETIMECREATED DATETIME NOT NULL,
    DATETIMEDISPATCHED DATETIME,
    TOTAL MONEY NOT NULL,
    USERID INTEGER NOT NULL,
    CONSTRAINT PK_ORDER PRIMARY KEY(ORDERID),
    CONSTRAINT FK_ORDER_AUTHORISEDPERSON FOREIGN KEY(USERID) REFERENCES AUTHORISEDPERSON5123,
    CONSTRAINT CHK_ORDER_TOTAL CHECK(TOTAL >= 0)
);


CREATE TABLE ORDERLINE5123(
    ORDERID INTEGER,
    PRODUCTID INT,
    QUANTITY INT NOT NULL,
    DISCOUNT DECIMAL DEFAULT 0,
    SUBTOTAL MONEY NOT NULL,
    CONSTRAINT PK_ORDERLINE PRIMARY KEY(ORDERID, PRODUCTID),
    CONSTRAINT FK_ORDERLINE_ORDER FOREIGN KEY(ORDERID) REFERENCES [ORDER5123],
    CONSTRAINT FK_ORDERLINE_PRODUCT FOREIGN KEY(PRODUCTID) REFERENCES PRODUCT5123,
    CONSTRAINT CHK_ORDER_DISCOUNT CHECK(DISCOUNT >=0 AND DISCOUNT <= 0.25),
    CONSTRAINT CHK_ORDERLINE_SUBTOTAL CHECK(SUBTOTAL > 0)
);

CREATE TABLE INVENTORY5123(
    PRODUCTID INT,
    LOCATIONID NVARCHAR(8),
    NUMINSTOCK INTEGER NOT NULL,
    CONSTRAINT PK_INVENTORY PRIMARY KEY(PRODUCTID, LOCATIONID),
    CONSTRAINT FK_INVENTORY_PRODUCT FOREIGN KEY(PRODUCTID) REFERENCES PRODUCT5123,
    CONSTRAINT FK_INVENTORY_LOCATION FOREIGN KEY(LOCATIONID) REFERENCES LOCATION5123,
    CONSTRAINT CHK_INVENTORY_NUMINSTOCK CHECK(NUMINSTOCK >=0)
);

CREATE TABLE PURCHASEORDER5123(
    PRODUCTID INT,
    LOCATIONID NVARCHAR(8),
    DATETIMECREATED DATETIME,
    QUANTITY INTEGER,
    TOTAL MONEY,
    CONSTRAINT PK_PURCHASEORDER PRIMARY KEY(PRODUCTID, LOCATIONID, DATETIMECREATED),
    CONSTRAINT FK_PURCHASEORDER_PRODUCT FOREIGN KEY(PRODUCTID) REFERENCES PRODUCT5123,
    CONSTRAINT FK_PURCHASEORDER_LOCATION FOREIGN KEY(LOCATIONID) REFERENCES LOCATION5123,
    CONSTRAINT CHK_PURCHASEORDER_QUANTITY CHECK(QUANTITY > 0)
);

GO


--SELECT * FROM SYS.TABLES;

--------------------------

-- SET UP LOCATION, PRODUCT AND INVENTORY
BEGIN

    INSERT INTO LOCATION5123(LOCATIONID, LOCNAME, ADDRESS, MANAGER)VALUES
    ('MLB3931', 'Melbourne South East', '123 Demon Street, Mornington, 3931', 'Bruce Wayne');

    INSERT INTO PRODUCT5123(PRODNAME, BUYPRICE, SELLPRICE) VALUES
    ('APPLE ME PHONE X', '890.00', 1295.00 );

    DECLARE @PRODID INT = @@IDENTITY;

    INSERT INTO INVENTORY5123(PRODUCTID, LOCATIONID, NUMINSTOCK) VALUES
    (@PRODID, 'MLB3931', 0);

    -- ADD A NEW CLIENT ACCOUNT AND A NEW AUTHORISED USER FOR THAT ACCOUNT

    INSERT INTO CLIENTACCOUNT5123(ACCTNAME, BALANCE, CREDITLIMIT) VALUES
    ('FREDS LOCAL PHONE STORE', '0', 10000.00 );

    DECLARE @ACCOUNTID INT = @@IDENTITY;

    INSERT INTO AUTHORISEDPERSON5123(FIRSTNAME, SURNAME, EMAIL, [PASSWORD], ACCOUNTID) VALUES
    ('Fred', 'Flintstone', 'fred@fredsphones.com', 'secret', @ACCOUNTID);

    DECLARE @USERID INT = @@IDENTITY;

    -----------

    -- BUY SOME STOCK

    -- ADD A PURCHASE ORDER ROW
    INSERT INTO PURCHASEORDER5123(PRODUCTID, LOCATIONID, DATETIMECREATED, QUANTITY, TOTAL) VALUES
    (@PRODID,  'MLB3931', '10-Apr-2020', 50, 44500.00);

    -- UPDATE OUR INVENTORY FOR THAT STOCK
    UPDATE INVENTORY5123 SET NUMINSTOCK = 50 WHERE PRODUCTID = @PRODID AND LOCATIONID = 'MLB3931';

    -- UPDATE THE GENERAL LEDGER INCREASING THE VALUE OF OUR STOCK ASSETS AND DECREASING THE CASH ASSETS
    UPDATE GENERALLEDGER5123 SET AMOUNT = AMOUNT - 44500.00 WHERE DESCRIPTION = 'ASSETSCASH';
    UPDATE GENERALLEDGER5123 SET AMOUNT = AMOUNT + 44500.00 WHERE DESCRIPTION = 'ASSETSSTOCK';

    -----------

    -- CUSTOMER MAKES AN ORDER - (INITIALLY THE ORDER IS NOT FULFILLED)

    INSERT INTO ORDER5123(SHIPPINGADDRESS, DATETIMECREATED, DATETIMEDISPATCHED, TOTAL, USERID) VALUES
    ('7 Lucky Strike, Bedrock, USB, 1111', '20-Apr-2020', NULL, 6151.25, @USERID);

    DECLARE @ORDERID INT = @@IDENTITY;

    INSERT INTO ORDERLINE5123(ORDERID, PRODUCTID, QUANTITY, DISCOUNT, SUBTOTAL) VALUES
    (@ORDERID, @PRODID, 5, 0.05, '6151.25');

    -- WE FULLFILL THE ORDER

    -- UPDATE THE ORDER TO GIVE IT A FULLFUILLED DATE
    UPDATE ORDER5123 SET DATETIMEDISPATCHED = '21-Apr-2020' WHERE ORDERID = @ORDERID;

    -- UPDATE THE CLIENTS ACCOUNT BALANCE TO INCLUDE THE VALUE OF THE ORDER
    UPDATE CLIENTACCOUNT5123 SET BALANCE = BALANCE + 6151.25 WHERE ACCOUNTID = @ACCOUNTID;

    -- UPDATE THE GENERAL LEDGER INCREASING VALUE OF ACCOUNTS, DECEASING VALUE OF STOCK
    UPDATE GENERALLEDGER5123 SET AMOUNT = AMOUNT + 6151.25  WHERE DESCRIPTION = 'ASSETSACCOUNT';
    UPDATE GENERALLEDGER5123 SET AMOUNT = AMOUNT - (5*890) WHERE DESCRIPTION = 'ASSETSSTOCK';

    -------------

    -- CLIENT MAKES AN ACCOUNT OFF THIER ACCOUNT BALANCE

    -- ADD A ROW TO ACCOUNTPAYMENT5123
    INSERT INTO ACCOUNTPAYMENT5123(ACCOUNTID, DATETIMERECEIVED, AMOUNT) VALUES
        (@ACCOUNTID, '25-Apr-2020', '2000.00');

    -- UPDATE THE CLIENT ACCOUNT TO REFLECT THE BALANCE CHANGE
    UPDATE CLIENTACCOUNT5123 SET BALANCE = BALANCE - 2000.00 WHERE ACCOUNTID = @ACCOUNTID;

    -- UPDATE THE GENERAL LEDGER - INCREASE ASSETSCASH AND DECREASE ASSETS ACCOUNT
    UPDATE GENERALLEDGER5123 SET AMOUNT = AMOUNT + 2000.00 WHERE DESCRIPTION = 'ASSETSCASH';
    UPDATE GENERALLEDGER5123 SET AMOUNT = AMOUNT - 2000.00 WHERE DESCRIPTION = 'ASSETSACCOUNT';
END;

GO
----------------------------
    -- THE FOLLOWING MUST BE COMPLETED AS A SINGLE TRANSACTION
    -- insert the specified values into the table LOCATION5123
    -- ADD A ROW FOR THIS LOCATION TO THE INVENTORY5123 TABLE **FOR EACH** PRODUCT IN THE PRODUCT5123 TABLE
    -- I.E. IF THERE ARE 4 PRODUCTS THIS WILL BE 4 NEW ROWS IN THE INVENTORY TABLE
    -- RETURN THE LOCID OF THE NEW LOCATION

    -- EXCEPTIONS
    -- if the location id is a duplicate throw error: number 51001  message : 'Duplicate Location ID'
    -- for any other errors throw error : number 50000  message:  error_message()

---------------------------------------------Add Location---------------------------------------------

IF OBJECT_ID('ADD_LOCATION') IS NOT NULL
DROP PROCEDURE ADD_LOCATION;
GO

CREATE PROCEDURE ADD_LOCATION @PLOCID INT, @PLOCNAME NVARCHAR(50), @PLOCADDRESS NVARCHAR(200), @PMANAGER NVARCHAR(100) AS

begin
    begin try
        begin transaction
            --if @PLOCID = MLB3931
            --throw 51001, 'Duplicate location ID (ADD_LOCATION)', 1
            insert into [LOCATION5123] (LOCATIONID, LOCNAME, ADDRESS, MANAGER) 
            values (@PLOCID, @PLOCNAME, @PLOCADDRESS, @PMANAGER);

            declare @PRODID integer
            set @PRODID = 0

                declare product_cursor cursor local for select PRODUCTID from PRODUCT5123;
                    open product_cursor;
                    fetch from product_cursor into @PRODID;

                    while @@fetch_status = 0
                    begin
                        insert into INVENTORY5123 (PRODUCTID, LOCATIONID, NUMINSTOCK)
                        values (@PRODID, @PLOCID, 13);       

                        fetch next from product_cursor into @PRODID;        
                    end

                close product_cursor
            deallocate product_cursor
        commit transaction
    end try

    begin catch
        if error_number() = MLB3931
            throw 51001, 'Duplicate location ID', 1
        else if error_number() = 50000
            throw
        else  
            begin 
                declare @errormessage nvarchar(max) = error_message();
                throw 50000, @errormessage, 1
            end;
    end catch;
end;

go
--exception to add location
--execption to throw duplicate error
--exception to throw error
exec ADD_LOCATION @PLOCID = 'MLB5555', @PLOCNAME = 'Springfield', @PLOCADDRESS = '742 Evergreen Terrace', @PMANAGER = 'Homer Simpson'
exec ADD_LOCATION @PLOCID = 'MLB3931', @PLOCNAME = 'Langley Falls', @PLOCADDRESS = '1024 Cherry Street', @PMANAGER = 'Steve Smith'
exec ADD_LOCATION @PLOCID = 0, @PLOCNAME = 'Rhode Island', @PLOCADDRESS = '31 Spooner Street', @PMANAGER = 'Peter Griffon'

select * from PRODUCT5123
select * from INVENTORY5123
select * from LOCATION5123

-----------------------------------------Get Location by ID-------------------------------------------

-- return the specified location.

    -- EXCEPTIONS
    -- if the location id is invalid throw error: number 51002  message : 'Location Doesnt Exist'
    -- for any other errors throw error : number 50000  message:  error_message()
IF OBJECT_ID('GET_LOCATION_BY_ID') IS NOT NULL
DROP PROCEDURE GET_LOCATION_BY_ID ;
GO

CREATE PROCEDURE GET_LOCATION_BY_ID @PLOCID INT, @PRETURNSTRING nvarchar(1000) output  AS
BEGIN
    begin try
        select @PLOCID = concat ('Location ID:', LOCATIONID, 'Location Name:', LOCNAME, 'Address', ADDRESS, 'Manager', MANAGER)
        from LOCATION5123 
        where @PLOCID = LOCATIONID
    end try

    begin catch
        if error_number() = ' '
            throw 51002, 'Location does not exist', 1
        else if error_number() = 50000
            throw
        else  
            begin 
                declare @errormessage nvarchar(max) = error_message();
                throw 50000, @errormessage, 1
            end;
    end catch;
end;

begin
    declare @output nvarchar(1000);
        exec GET_LOCATION_BY_ID @PLOCID = ' ', @PRETURNSTRING = @output output;
        exec GET_LOCATION_BY_ID @PLOCID = 'MLB5555', @PRETURNSTING = @output output;
end;
--------------------------------------------Add Product-----------------------------------------------

   -- THE FOLLOWING MUST BE COMPLETED AS A SINGLE TRANSACTION
    -- insert the specified values into the table PRODUCT5123
    -- ADD A ROW FOR THIS PRODUCT TO THE INVENTORY5123 TABLE **FOR EACH** LOCTAION IN THE LOCATION5123 TABLE
    -- I.E. IF THERE ARE 4 LOCATIONS THIS WILL BE 4 NEW ROWS IN THE INVENTORY TABLE
    -- RETURN THE NEW PRODUCTS PRODUCTID   
IF OBJECT_ID('ADD_PRODUCT') IS NOT NULL
DROP PROCEDURE ADD_PRODUCT ;
GO

CREATE PROCEDURE ADD_PRODUCT @PPRODNAME NVARCHAR(100), @PBUYPRICE MONEY, @PSELLPRICE MONEY AS
begin
    begin try
        begin transaction
            insert into PRODUCT5123 (PRODNAME, PBUYPRICE, SELLPRICE)
            values (@PRODNAME, @PBUYPRICE, @PSELLPRICE);

            declare @PRODNAME integer
            declare @LOCATIONID nvarchar(8)

                declare location_cursor cursor local for select LOCATIONID from [LOCATION5123];
                    open location_cursor;
                    fetch from location_cursor into @LOCATIONID

                    while @@fetch_status = 0
                    
                    begin
                        insert into INVENTORY5123 (PRODUCTID, LOCATIONID, NUMINSTOCK)
                        values (@PRODID, @LOCATIONID, 50);

                        fetch next from location_cursor into @LOCATIONID
                    end
                close location_cursor
                deallocate location_cursor
        commit transaction;
    end try
    begin catch
            begin 
                declare @errormessage nvarchar(max) = error_message();
                throw 50000, @errormessage, 1
            end;
    end catch;
 end;
    -- EXCEPTIONS
    -- for any other errors throw error : number 50000  message:  error_message()
exec ADD_PRODUCT @PRODNAME = 'Zelda: Breath of the Wild', @PBUYPRICE = 79, @SELLPRICE = 50
exec ADD_PRODUCT @PRODNAME = 'Nintendo Switch', @BUYPRICE = 350, @SELLPRICE = 250

-----------------------------------------Get Product by ID--------------------------------------------

-- return the specified PRODUCT.
IF OBJECT_ID('GET_PRODUCT_BY_ID') IS NOT NULL
DROP PROCEDURE GET_PRODUCT_BY_ID ;
GO

CREATE PROCEDURE GET_PRODUCT_BY_ID @PPRODID INT, @PRETURNSTRING nvarchar(1000) output AS
begin
    begin try
        select @PPRODID = concat ('Product ID: ', PRODUCTID, 'Product Name: ', PRODNAME, 'Buy Price: ', BUYPRICE, 'Sell Price: ', SELLPRICE)
        from PRODUCT5123
        where @PPRODID = PRODUCTID
    end try

    begin catch
        if error_number() = ' '
            throw 52002, 'Product Doesnt Exist', 1
        else if error_number() = 50000
            throw 
        else
            begin
                declare @errormessage nvarchar(max) = error_message();
                throw 50000, @errormessage, 1
            end;
        end catch;
end;

begin
    declare @output nvarchar(1000);
        exec GET_PRODUCT_BY_ID @PPRODID = ' ', @PRETURNSTRING = @output output;
        exec GET_PRODUCT_BY_ID @PPRODID = 'Car', @PRETURNSTRING = @output output;
end;

-- EXCEPTIONS
    -- if the PRODUCT id is invalid throw error: number 52002  message : 'Product Doesnt Exist'
    -- for any other errors throw error : number 50000  message:  error_message()
    
-------------------------------------------Purchase Stock----------------------------------------------

    -- THE FOLLOWING MUST BE COMPLETED AS A SINGLE TRANSACTION

    -- insert the A ROW TO THE PURCHASE ORDER TABLE
    -- USE THE CURRENT SYSTEM DATETIME AS FOR THE DATETIMECREATED FIELD
    -- CALCULATE THE TOTAL BASED ON THE BUYPRICE OF THE PRODUCT SPECIFICED AND THE QUANTITY IN @PQTY
    -- UPDATE INVENTORY5123 FOR THE SPECIFIED PRODUCT IN THE SPECIFIED LOCATION BY THE QTY PURCHASED
    -- DECREASE THE ASSETCASH ROW IN THE GENERAL LEDGER BY THE TOTAL AMOUNT OF THE ORDER
    -- INCREASE THE ASSETSTOCK ROW IN THE GENERAL LEDGER BY THE TOTAL AMOUNT OF THE ORDER

IF OBJECT_ID('PURCHASE_STOCK') IS NOT NULL
DROP PROCEDURE PURCHASE_STOCK;
GO

CREATE PROCEDURE PURCHASE_STOCK @PPRODID INT, @PLOCID INT, @PQTY INT AS
begin
    begin tran
        begin try
            declare @TOTAL integer
            select @TOTAL = BUYPRICE from PRODUCT5123
            set @TOTAL = @TOTAL * @PQTY

            insert into PURCHASEORDER5123(PRODUCTID, LOCATIONID, DATETIMECREATED, QUANTITY, TOTAL)
            values (@PRODID, @PLOCID, GETDATE(), @PQTY, @TOTAL)

            update INVENTORY5123
            set NUMINSTOCK = NUMINSTOCK + @PQTY
            where PRODUCTID = @PRODID and LOCATIONID = @PLOCID

            update GENERALLEDGER5123
            set AMOUNT = AMOUNT - @TOTAL
            where [DESCRIPTION] = 'ASSETSCASH'

            update GENERALLEDGER5123
            set AMOUNT = AMOUNT + @TOTAL
            where [DESCRIPTION] = 'ASSETSCASH'
        commit tran;
    end try

    begin catch
        rollback tran;
            if error_message() like '%FK_PURCHASEORDER_PRODUCT%'
                throw 52002, 'Product Doesnt Exist', 1

            else if error_message() like '%FK_PURCHASEORDER_LOCATION%'
                throw 51002, 'Location Doesnt Exist', 1

            else if error_number() = 59001
                throw;
            else
                begin
                    declare @errormessage nvarchar(max) = error_message();
                    throw 50000, @errormessage, 1
                end
    end catch;
end;

exec PURCHASE_STOCK @PRODID = 10001, @PLOCID = MLB3931, @PQTY = 1;

-- EXCEPTIONS
    -- if the LOCATUON id is invalid throw error: number 51002  message : 'Location Doesnt Exist'
    -- if the PRODUCT id is invalid throw error: number 52002  message : 'Product Doesnt Exist'
    -- IF THERE IS INSUFFICIENT ASSETSCASH IN THE GENERAL LEDGER THEN THROW ERROR: 59001 MESSAGE : 'INSUFFICIENT CASH'
    -- for any other errors throw error : number 50000  message:  error_message()

------------------------------------------Add Client Account-------------------------------------------

-- insert the specified values into the table CLIENTACCOUNT5123
-- RETURN THE NEW ACCOUNTS ACCOUNTID

IF OBJECT_ID('ADD_CLIENT_ACCOUNT') IS NOT NULL
DROP PROCEDURE ADD_CLIENT_ACCOUNT;
GO

CREATE PROCEDURE ADD_CLIENT_ACCOUNT @PACCTNAME NVARCHAR(100), @PBALANCE MONEY, @PCREDITLIMIT MONEY, @PACCOUNTID NVARCHAR(1000) AS
begin
    begin try
        insert into CLIENTACCOUNT5123 (ACCTNAME, BALANCE, CREDITLIMIT)
        values (@PACCTNAME, @PBALANCE, @PCREDITLIMIT)

        set @PACCOUNTID = concat('Account ID: ' , @@IDENTITY);
    end try

    begin catch
        if error_number() = 2627
            throw 53001, 'Duplicate Account Name', 1
        else
            begin
                declare @errormessage nvarchar(max) = error_message();
                throw 50000, @errormessage, 1
            end
    end catch
end;

select * from CLIENTACCOUNT5123
    begin
        declare @OT as nvarchar(1000)
        exec ADD_CLIENT_ACCOUNT @PACCTNAME='Itachi', @PBALANCE = 1000, @PCREDITLIMIT = 10000, @PACCOUNTID = @OT output
        select @OT
    end;
    -- EXCEPTIONS
    -- ACCOUNT NAME ALREADY EXISTS - SEE TABLE CONSTRAINTS - THROW ERROR 53001 : DUPLICATE ACCOUNT NAME
    -- for any other errors throw error : number 50000  message:  error_message()

------------------------------------------Add Authorized Person------------------------------------------

    -- insert the specified values into the table AUTHORISEDPERSON5123
    -- RETURN THE NEW USERS USER ID

IF OBJECT_ID('ADD_AUTHORISED_PERSON') IS NOT NULL
DROP PROCEDURE ADD_AUTHORISED_PERSON;

GO

CREATE PROCEDURE ADD_AUTHORISED_PERSON @PFIRSTNAME NVARCHAR(100), @PSURNAME NVARCHAR(100), @PEMAIL NVARCHAR(100), @PPASSWORD NVARCHAR(100), @PACCOUNTID INT AS
begin
    begin try
        insert into AUTHORISEDPERSON5123 (FIRSTNAME, SURNAME, EMAIL, [PASSWORD], ACCOUNTID)
        values (@PFIRSTNAME, @PSURNAME, @PEMAIL, @PPASSWORD, @PACCOUNTID)

        set @NEWUSERID = concat('New User ID: ' , @@IDENTITY)
    end try

    begin catch
        if error_number() = 547
            throw 53003, 'Invalid Email Address', 1
        else
            begin
                declare @errormessage nvarchar(max) = error_message();
                throw 50000, @errormessage, 1
            end
    end catch        
end;

    -- EXCEPTIONS
    -- EMAIL IS INVALID (DOESN'T CONTAIN AN @ - SEE TABLE CONSTRAINTS)  - THROW ERROR 53003 : INVALID EMAIL ADDRESS
    -- for any other errors throw error : number 50000  message:  error_message()
select * from CLIENTACCOUNT5123
select * from AUTHORISEDPERSON5123

begin
    declare @OT as NVARCHAR(30);
    exec ADD_AUTHORISED_PERSON @PFIRSTNAME='Itachi', @PSURNAME='Uchiha', @PEMAIL='Uchiha.Itachi12@gmail.com', @PPASSWORD='hiddenleaf', @PACCOUNTID=30002, @NEWUSERID = @OT output
    select @OT
end;

begin
    declare @OT as NVARCHAR(30)
    exec ADD_AUTHORISED_PERSON @PFIRSTNAME='Naruto', @PSURNAME='Uzumaki', @PEMAIL='Uzumaki.Naruto@gmail.com', @PPASSWORD='theBestHokage', @PAACOUNTID=30002, @NEWUSERID = @OT output
    select @OT
end;

------------------------------------------Make Account Payment------------------------------------------

    -- THE FOLLOWING MUST BE COMPLETED AS A SINGLE TRANSACTION
    -- insert the specified values into the table ACCOUNTPAYMENT5123 (USING THE CURRENT SYS DATETIME)
    -- UPDATE THE RELEVANT ACCOUNT IN CLENTACCOUNT5123 TO RELFECT THE BALANCE REDUCED BY THE PAYMENT
    -- UPDATE THE GENERAL LEDGER TO REDUCE ACCOUNT ASSETS BY THE PAYMENT AMOUNT
    -- UPDATE THE GENERAL LEDGER TO INCREASE CASH ASSETS BY THE PAYMENT AMOUNT

IF OBJECT_ID('MAKE_ACCOUNT_PAYMENT') IS NOT NULL
DROP PROCEDURE MAKE_ACCOUNT_PAYMENT;

GO

CREATE PROCEDURE MAKE_ACCOUNT_PAYMENT @PACCOUNTID INT, @PAMOUNT MONEY AS
begin
    begin tran
        begin try
            if @PAMOUNT < 0
                throw 53002, 'negative number', 1;
            else if (select ACCOUNTID from CLIENTACCOUNT5123 where ACCOUNTID = @PACCOUNTID) is null
                throw 53002, 'Account does not exist', 1
            else
                insert into ACCOUNTPAYMENT5123 (ACCOUNTID, DATETIMERECIEVED, AMOUNT)
                values (@PACCOUNTID, GETDATE(), @PAMOUNT);

                update CLIENTACCOUNT5123
                set BALANCE = BLANCE - @PAMOUNT
                where ACCOUNTID = @PACCOUNTID;

                update GENERALLEDGER5123
                set AMOUNT = AMOUNT - @PAMOUNT
                where [DESCRIPTION]='ASSETSACCOUNT';

                update GENERALLEDGER5123
                set AMOUNT = AMOUNT + @PAMOUNT
                where [DESCRIPTION]='ASSETSCASH';
        commit tran
    end try

    begin  catch
        rollback tran;
            if error_message() like '%FK_ACCOUNTPAYMENT_ACCOUNT%'
                throw 53002, 'Account does not exist', 1
            else if error_message() like '%CHK_ACCOUNTPAYMENT_AMOUNT%'
                throw 53004, ' Accout Payment Must be Positive', 1

            else
                begin
                    declare @errormessage nvarchar(max) = error_message();
                    throw 50000, @errormessage, 1
                end
            end catch
end;

Select * from GENERALLEDGER5123
Select * from ACCOUNTPAYMENT5123

begin
    exec MAKE_ACCOUNT_PAYMENT @PACCOUNTID = 30006, @PAMOUNT = 6
end

    -- EXCEPTIONS
    -- ACCOUNT DOESNT EXIST THROW ERROR 53002 : ACCOUNT DOES NOT EXIST 
    -- PAYMENT AMOUNT IS NEGATIVE (SEE TABLE CONSTRAINTS) THROW ERROR 53004 :   ACCOUNT PAYMENT AMOUNT MUST BE POSITIVE  
    -- for any other errors throw error : number 50000  message:  error_message()

----------------------------------------Get Client Account By ID---------------------------------------

IF OBJECT_ID('GET_CLIENT_ACCOUNT_BY_ID') IS NOT NULL
DROP PROCEDURE GET_CLIENT_ACCOUNT_BY_ID;

GO

CREATE PROCEDURE GET_CLIENT_ACCOUNT_BY_ID @PACCOUNTID INT AS
begin
    begin try
        set @PRETURNSTRING = (select concat('Account ID: ', A.ACCOUNTID, 'Account Name: ', ACCTNAME, 'Balance: ', BALANCE, 'Credit Limit: ', CREDITLIMIT, 'Authorized: ', A.FIRSTNAME)
        from CLIENTACCOUNT5123 C inner join AUTHORISEDPERSON5123 A on C.ACCOUNTID = A.ACCOUNTID
        where C.ACCOUNTID = @PACCOUNTID);

        if @PRETURNSTRING is null
            throw 53002, 'Account does not exist', 1;
    end try

    begin catch
        if error_number() = 53002
            throw;
        else
            begin
                declare @errormessage nvarchar(max) = error_message();
                throw 50000, @errormessage, 1
            end
    end catch
end;

    -- return the specified CLIENT ACCOUNT INCLUDING AND ALL AUTHORISED PERSONS DETAILS

    -- EXCEPTIONS
     -- ACCOUNT DOESNT EXIST THROW ERROR 53002 : ACCOUNT DOES NOT EXIST 
    -- for any other errors throw error : number 50000  message:  error_message()
select * from AUTHORISEDPERSON5123
select * from CLIENTACCOUNT5123

begin
    declare @OT nvarchar(1000)
        exec GET_CLIENT_ACCOUNT_BY_ID @PACCOUNTID = 30001, @PRETURNSTRING = @OT output
        select @OT
end;

----------------------------------------------Create Order----------------------------------------------

-- insert the specified values into the table ORDER5123
    -- SET THE TOTAL TO 0
    -- RETURN THE NEW ORDERS ORDERID

IF OBJECT_ID('CREATE_ORDER') IS NOT NULL
DROP PROCEDURE CREATE_ORDER;
GO


CREATE PROCEDURE CREATE_ORDER  @PSHIPPINGADDRESS NVARCHAR(200), @PUSERID INT, @PRETURNORDERID NVARCHAR(24) OUTPUT AS
BEGIN
    begin try
        insert into ORDER5123(SHIPPINGADDRESS, DATETIMECREATED, TOTAL, USERID) values
        (@PSHIPPINGADDRESS, GETDATE(), 1, @PUSERID)

        set @PRETURNORDERID = concat('Order ID: ', @@IDENTITY)
    end try

    begin catch
        if error_number() = 547
            throw 55002, 'User does not exist', 1
        else
            begin
                declare @errormessage nvarchar(max) = error_message();
                throw 50000, @errormessage, 1
            end
    end catch
END;

select * from AUTHORISEDPERSON5123

go
    begin
        declare @OT nvarchar(24)
        exec CREATE_ORDER @PSHIPPINGADDRESS = '1 test st', @PUSERID = 50001, @PRETURNORDERID = @OT output
end;
go
select * from ORDER5123

-- EXCEPTIONS
    -- USER DOES NOT EXIST : THROW ERROR 55002 : USER DOES NOT EXIST
    -- for any other errors throw error : number 50000  message:  error_message()

---------------------------------------------Get Order By ID--------------------------------------------

-- return the specified ORDER INCLUDING ALL RELATED ORDERLINES

IF OBJECT_ID('GET_ORDER_BY_ID') IS NOT NULL
DROP PROCEDURE GET_ORDER_BY_ID;

GO

CREATE PROCEDURE GET_ORDER_BY_ID @PORDERID INT, @PRETURNSTRING NVARCHAR(1000) AS
BEGIN
    begin try
        set @PRETURNSTRING = (select concat('Order ID : ', ORDERID,
        ' Shipping Address: ', SHIPPINGADDRESS, ' Date Time Created: ', DATETIMECREATED, ' Date Time Dispatched: ', DATETIMEDISPATCHED,
        ' Total: ', TOTAL, ' UserID : ', USERID ) 
        from ORDER5123
        where ORDERID = @PORDERID);

        if @PRETURNSTRING is null
        throw 54002, 'Order does not exist', 1
    end try

    begin catch
        if error_number() = 54002
        throw;
        else
         begin 
            declare @ERRORMESSAGE nvarchar(max) = error_message();
            throw 50000, @ERRORMESSAGE, 1 
         end 
    end catch
END;

    -- EXCEPTIONS
    -- ORDER DOES NOT EXIST THROW ERROR 54002 : ORDER DOES NOT EXIST 
    -- for any other errors throw error : number 50000  message:  error_message()END;

begin
declare @OT nvarchar(1000)
exec GET_ORDER_BY_ID @PORDERID = 70001, @PRETURNSTRING = @OT output
select @OT
end;

------------------------------------------Add Product to Order------------------------------------------

IF OBJECT_ID('ADD_PRODUCT_TO_ORDER') IS NOT NULL
DROP PROCEDURE ADD_PRODUCT_TO_ORDER;
GO

/*
CREATE PROCEDURE ADD_PRODUCT_TO_ORDER @PORDERID INT, @PPRODIID INT, @PQTY INT, @DISCOUNT DECIMAL AS
BEGIN

    -- THE FOLLOWING MUST BE COMPLETED AS A SINGLE TRANSACTION
    -- CHECK IF THE ORDER HAS ALREADY BEEN FULFILLED (HAS A DATETIMEDISATHCED VALUE)
    -- IF IT HAS BEEN FULFULLILLED GENERATE AN ERROR - SEE EXCEPTIONS SECTION
    -- IF IT HAS NOT BEEN FULLFILLED THEN
    -- IF THE PRODUCT HAS NOT ALREADY BEEN ADDED TO THAT ORDER (I.E. PK IS UNIQUE)
        -- insert the specified values into the table ORDERLINE5123
        -- CALCULATE THE SUBTOTAL VALUE BASED ON THE PRODUCTS SELLPRICE, THE QUANTITY AND THE DISCOUNT
        -- UPDATE THE ORDERS TOTAL - INCREASE IT BY THE VALUE OF THE ORDRLINES SUBTOTAL
    -- ELSE -- the product is aleady in that order 
        -- update the relevant orderline by adding the new quantity to the previous quantity,
        -- RE CALCULATE THE SUBTOTAL VALUE BASED ON THE PRODUCTS SELLPRICE, THE QUANTITY AND THE DISCOUNT
        -- UPDATE THE ORDERS TOTAL - INCREASE IT BY THE VALUE OF THE QTY ADDED TO THE ORDERLINE

    -- EXCEPTIONS
    -- ORDER DOES NOT EXIST THROW ERROR 54002 : ORDER DOES NOT EXIST 
    -- ORDER HAS ALREADY BEEN FULFILLED THROW ERROR 54002 : ORDER HAS ALRADY BEEN FULLFILLED
    -- PRODUCT DOES NOT EXIST THROW ERROR 52002 : PRODUCT DOES NOT EXIST
    -- DISCOUNT IS OUT OF PERMITTED RANGE (SEE TABLE CONSTRAINTS) THROW ERROR 54004 : DISCOUNT OUT OF RANGE
    -- for any other errors throw error : number 50000  message:  error_message()
END;
*/

IF OBJECT_ID('REMOVE_PRODUCT_FROM_ORDER') IS NOT NULL
DROP PROCEDURE REMOVE_PRODUCT_FROM_ORDER;
GO

/*
CREATE PROCEDURE REMOVE_PRODUCT_FROM_ORDER @PORDERID INT, @PPRODIID INT AS
BEGIN

    -- THE FOLLOWING MUST BE COMPLETED AS A SINGLE TRANSACTION
    -- CHECK IF THE ORDER HAS ALREADY BEEN FULFILLED (HAS A DATETIMEDISATHCED VALUE)
    -- IF IT HAS BEEN FULFULLILLED GENERATE AN ERROR - SEE EXCEPTIONS SECTION
    -- IF IT HAS NOT BEEN FULLFILLED THEN
    -- UPDATE THE ORDERS TOTAL - DECREASE IT BY THE VALUE OF THE ORDRLINES SUBTOTAL
    -- DELETE THE RELEVANT ROW FROM ORDERLINE5123

    -- EXCEPTIONS
    -- ORDER DOES NOT EXIST THROW ERROR 54002 : ORDER DOES NOT EXIST 
    -- ORDER HAS ALREADY BEEN FULFILLED THROW ERROR 54002 : ORDER HAS ALREADY BEEN FULLFILLED
    -- PRODUCT DOES NOT EXIST THROW ERROR 52002 : PRODUCT DOES NOT EXIST
    -- PRODUCT HAS NOT BEEN ADDED TO ORDER THROW ERROR 54005 : PRODUCT NOT ON ORDER
    -- for any other errors throw error : number 50000  message:  error_message()
END;
*/


IF OBJECT_ID('GET_OPEN_ORDERS') IS NOT NULL
DROP PROCEDURE GET_OPEN_ORDERS;
GO

/*
CREATE PROCEDURE GET_OPEN_ORDERS AS
BEGIN

    -- RETURN A CURSOR WHICH REFERENCES ALL CURRENTLY OPEN (NOT FULFILLED) ORDERS

    -- EXCEPTIONS
    -- for any other errors throw error : number 50000  message:  error_message()
END;
*/


IF OBJECT_ID('FULLFILL_ORDER') IS NOT NULL
DROP PROCEDURE FULLFILL_ORDER;

GO

/*
CREATE PROCEDURE FULLFILL_ORDER @PORDERID INT AS
BEGIN

    -- THE FOLLOWING MUST BE COMPLETED AS A SINGLE TRANSACTION

    -- CHECK IF THE ORDER HAS ALREADY BEEN FULFILLED (HAS A DATETIMEDISATHCED VALUE)
    -- IF IT HAS BEEN FULFULLILLED GENERATE AN ERROR - SEE EXCEPTIONS SECTION
    -- IF IT HAS NOT BEEN FULLFILLED THEN

    -- UPDATE THE ORDERS DATETIMEDISPATCHED WITH THE CURRENT DATE TIME
    -- ** TRICKY** FOR EACH PRODUCT IN THE ORDER FIND INVENTORY WHICH HAS SUFFICIENT UNITS OF THE PRODUCT IN STOCK 
            -- AND DECREASE THE INVENTORY BY THE AMOUNT OF THE PRODUCT IN TH ORDER
    -- INCREASE THE RELEVANT CLIENTACCOUNTS BALANCE BY THE TOTAL VALUE OF THE ORDER
    -- INCREASE THE GENERAL LEDGER ACCOUNT ASSETS AMOUNT BY THE TOTAL VALUE OF THE ORDER
    -- ** TRICKY** DECREASE THE GENERAL LEDGER STOCK ASSESTS AMOUNT BY THE WHOLESALE (QTY * BUYPRICE) OF ALL THE PRODUCTS IN THE ORDER

    -- EXCEPTIONS
    -- INSUFFICIENT INVENTORY OF ONE OR MORE PRODUCTS TO FULFILL ORDER THROW ERROR 54006: INSUFFUCIENT INVENTORY TO FULFILL
	-- CLIENT ACCOUNT DOES NOT HAVE SUFFICIENT CREDIT REMAINING TO PAY FOR ORDER THROW ERROR 53005 : INSUFFICIENT CREDIT
    -- ORDER HAS ALREADY BEEN FULFILLED THROW ERROR 54002 : ORDER HAS ALREADY BEEN FULLFILLED
    -- ORDER DOES NOT EXIST THROW ERROR 54002 : ORDER DOES NOT EXIST 
    -- for any other errors throw error : number 50000  message:  error_message()
END;
*/

