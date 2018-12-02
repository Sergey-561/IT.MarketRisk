-- ����� 1:
--��������� 2 ������� � ������� � ������ � ����. (�������� ������ ������ ���������):
SELECT * INTO [MarketRisk].[dbo].[base_price] FROM [MarketRisk].[dbo].[base1]
UNION ALL
SELECT * FROM [MarketRisk].[dbo].[base2]
GO
--��������� ����������� ���� ������ ������� ������:
ALTER TABLE [MarketRisk].[dbo].[instrs$] ALTER COLUMN [ID] INT NOT NULL;
ALTER TABLE [MarketRisk].[dbo].[bond_discription$] ALTER COLUMN [ISIN, RegCode, NRDCode] VARCHAR (50) NOT NULL;
ALTER TABLE [MarketRisk].[dbo].[base_price] ALTER COLUMN [ISIN] VARCHAR (50) NOT NULL;
ALTER TABLE [MarketRisk].[dbo].[base_price] ALTER COLUMN ID INT NOT NULL;
GO
--��������� ��������� ����� ��� ������:
ALTER TABLE [MarketRisk].[dbo].[instrs$] ADD PRIMARY KEY (ID);
ALTER TABLE [MarketRisk].[dbo].[bond_discription$] ADD PRIMARY KEY ([ISIN, RegCode, NRDCode]);
GO
--��������� ������� ����� � ����� (instrs � base_price �� ID):
ALTER TABLE [MarketRisk].[dbo].[base_price] ADD CONSTRAINT FK_baseprice FOREIGN KEY (ID) 
REFERENCES [MarketRisk].[dbo].[instrs$] (ID)   
  --��� ����� ������ bond_discription � base_price ���������� ������� ������ ������� � ISIN �� base_price:
	 SELECT [MarketRisk].[dbo].[base_price].[ID] INTO [MarketRisk].[dbo].[extraISIN_ID] -- ����� ID � ������� ISIN
	 FROM [MarketRisk].[dbo].[base_price] LEFT JOIN [MarketRisk].[dbo].[bond_discription$] 
	 ON [base_price].[ISIN] = [bond_discription$].[ISIN, RegCode, NRDCode]
	 WHERE [bond_discription$].[ISIN, RegCode, NRDCode] IS NULL;
	 GO
	-- �������� ������ ������� � ��������� �������:
	SELECT * INTO [MarketRisk].[dbo].[extraISIN]
	FROM [MarketRisk].[dbo].[base_price]  
	WHERE [ID] IN (SELECT [ID] FROM [MarketRisk].[dbo].[extraISIN_ID]);
	GO
	-- ������� ���������� ������� �� �������� ������� [base_price]:
	DELETE FROM [MarketRisk].[dbo].[base_price]  
	WHERE [ID] IN (SELECT [ID] FROM [MarketRisk].[dbo].[extraISIN_ID]);
	GO
--������������� ����� ����� (bond_discription$ � base_price �� ISIN):
ALTER TABLE [MarketRisk].[dbo].[base_price] ADD CONSTRAINT FK_baseprice2 FOREIGN KEY (ISIN)     
REFERENCES [MarketRisk].[dbo].[bond_discription$] ([ISIN, RegCode, NRDCode]);    
GO


--����� 2:
--������� ���� ������� ����� � ����������� �������, � ������ ������ [GuarantVal]:
SELECT COUNT(*)*100/(SELECT COUNT(*) FROM [MarketRisk].[dbo].[bond_discription$] ) FROM [MarketRisk].[dbo].[bond_discription$] WHERE [GuarantVal]=' '; 
GO 
-- ������ ����� ������� ��� ������� ������� , ���� ���������� ������� �������� ��������� 90%, ��� � ���� ������.
SELECT [ISIN, RegCode, NRDCode], [GuarantVal] INTO [MarketRisk].[dbo].[bond_discription_GuarantVal] FROM [MarketRisk].[dbo].[bond_discription$] WHERE [GuarantVal] !=' '; 
GO 
-- ������� ������ ������ �� ������� bond_discription$
ALTER TABLE [MarketRisk].[dbo].[bond_discription$] DROP COLUMN [GuarantVal]; 
GO


--����� 3;
-- ���������, �� ����� ������ ������� ���� ����, � ������� ��� ��������� ��� �������� �� ���� �� ����� 10%.
ALTER TABLE [MarketRisk].[dbo].[base_price] ALTER COLUMN [TIME] INT; --������� ������ ������ � ������� [TIME]
-- ��������� ������� � ������� � ������ � ��������� ������� [MarketRisk].[dbo].[task3] � �������� � ��� ���������� �� �������.
SELECT * INTO [MarketRisk].[dbo].[task3] FROM [MarketRisk].[dbo].[base_price]	
ORDER BY [TIME];	
GO
-- ������� ������ ��� ����������  ID, [TIME], BID, � ����� �������� ���������� �������� ���������� ID, BID.
--�������� ���������� ����� ������� �� ID.
SELECT ID, [TIME], ISIN, BID, LAG(BID,1,0) OVER (ORDER BY ID) AS BID_prev, LAG(ID,1,0) OVER (ORDER BY ID) AS ID_prev
INTO [MarketRisk].[dbo].[task3_1] FROM [MarketRisk].[dbo].[task3]
ORDER BY [ID];	
GO
--������ �� ������� ���, � ������� ��� ���������� � ������ �� ������ ������ ������ 
--� ������� ���� ������), ���� � ��� ��� ���� ���������.
DELETE FROM [MarketRisk].[dbo].[task3_1] WHERE ID != ID_prev AND BID != ' ';
GO

-- ��� ������ ������ ������ ���������, ������� ���� �� ��� �� ���� ������ ��� ���������
SELECT ID, COUNT([TIME]) AS no_trade_days 
INTO [MarketRisk].[dbo].[task3_2] FROM [MarketRisk].[dbo].[task3_1] 
WHERE BID=BID_prev OR BID=' ' GROUP BY ID;
GO

-- ��� ������ ������ ������ ���������, �� �������� ���� � ��� ���� ����������.
SELECT ID, COUNT([TIME]) AS information_days
INTO [MarketRisk].[dbo].[task3_3] FROM [MarketRisk].[dbo].[task3_1] 
GROUP BY ID;
GO

-- ��������� ������ � ������ ��� ������ ������ ������ ���� ����, � ������� �� ��� �� ���� ������ ��� ���������.
--������� ������ �� ������ ������, �� ������� ���� ����, � ������� ��� ��������� ��� �������� �� ����, ���� �� ����� 10%.
SELECT [MarketRisk].[dbo].[task3_3].[ID],no_trade_days , information_days, no_trade_days*100/information_days AS share
INTO [MarketRisk].[dbo].[task3_4]
FROM [MarketRisk].[dbo].[task3_2] RIGHT JOIN [MarketRisk].[dbo].[task3_3]
ON [MarketRisk].[dbo].[task3_3].[ID]= [MarketRisk].[dbo].[task3_2].[ID]
WHERE [MarketRisk].[dbo].[task3_2].[no_trade_days] IS NULL OR no_trade_days*100/information_days <= 10; 
GO

-- ������ �� ��������� ������ ����� ����� �������� ������ ��, ������� �������� ����������� � 
-- ��������� �� ���������� ����� � ������ �������� ������. 
SELECT [MarketRisk].[dbo].[task3_4].[ID], Exchange, CFIName, EmitentName
INTO [MarketRisk].[dbo].[task3_5]
FROM [MarketRisk].[dbo].[task3_4] INNER JOIN [MarketRisk].[dbo].[instrs$]
ON [MarketRisk].[dbo].[task3_4].[ID]= [MarketRisk].[dbo].[instrs$].[ID]
WHERE Exchange = '���������� ����� / �� - ��������' 
AND (CFIName = '��������� / ������ / �������������' OR CFIName = '��������� / ������ / ������������');  
GO

--����� 36 ������ �����. ��� ����� ������ �� ����� ���� ���������. 
SELECT TOP(3) EmitentName
FROM [MarketRisk].[dbo].[task3_5]
GROUP BY EmitentName;
GO