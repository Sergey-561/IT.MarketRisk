-- Пункт 1:
--Объединим 2 таблицы с данными о торгах в одну. (названия таблиц должны совпадать):
SELECT * INTO [MarketRisk].[dbo].[base_price] FROM [MarketRisk].[dbo].[base1]
UNION ALL
SELECT * FROM [MarketRisk].[dbo].[base2]
GO
--Установим необходимые типы данных связных таблиц:
ALTER TABLE [MarketRisk].[dbo].[instrs$] ALTER COLUMN [ID] INT NOT NULL;
ALTER TABLE [MarketRisk].[dbo].[bond_discription$] ALTER COLUMN [ISIN, RegCode, NRDCode] VARCHAR (50) NOT NULL;
ALTER TABLE [MarketRisk].[dbo].[base_price] ALTER COLUMN [ISIN] VARCHAR (50) NOT NULL;
ALTER TABLE [MarketRisk].[dbo].[base_price] ALTER COLUMN ID INT NOT NULL;
GO
--Установим первичные ключи для связей:
ALTER TABLE [MarketRisk].[dbo].[instrs$] ADD PRIMARY KEY (ID);
ALTER TABLE [MarketRisk].[dbo].[bond_discription$] ADD PRIMARY KEY ([ISIN, RegCode, NRDCode]);
GO
--Установим внешние ключи и связи (instrs и base_price по ID):
ALTER TABLE [MarketRisk].[dbo].[base_price] ADD CONSTRAINT FK_baseprice FOREIGN KEY (ID) 
REFERENCES [MarketRisk].[dbo].[instrs$] (ID)   
  --Для связи таблиц bond_discription и base_price необходимо вынести лишние строчки с ISIN из base_price:
	 SELECT [MarketRisk].[dbo].[base_price].[ID] INTO [MarketRisk].[dbo].[extraISIN_ID] -- найдём ID с лишними ISIN
	 FROM [MarketRisk].[dbo].[base_price] LEFT JOIN [MarketRisk].[dbo].[bond_discription$] 
	 ON [base_price].[ISIN] = [bond_discription$].[ISIN, RegCode, NRDCode]
	 WHERE [bond_discription$].[ISIN, RegCode, NRDCode] IS NULL;
	 GO
	-- Сохраним лишние строчки в отдельной таблице:
	SELECT * INTO [MarketRisk].[dbo].[extraISIN]
	FROM [MarketRisk].[dbo].[base_price]  
	WHERE [ID] IN (SELECT [ID] FROM [MarketRisk].[dbo].[extraISIN_ID]);
	GO
	-- Удаляем сохранённые строчки из основной таблицы [base_price]:
	DELETE FROM [MarketRisk].[dbo].[base_price]  
	WHERE [ID] IN (SELECT [ID] FROM [MarketRisk].[dbo].[extraISIN_ID]);
	GO
--Устанавливаем связи далее (bond_discription$ и base_price по ISIN):
ALTER TABLE [MarketRisk].[dbo].[base_price] ADD CONSTRAINT FK_baseprice2 FOREIGN KEY (ISIN)     
REFERENCES [MarketRisk].[dbo].[bond_discription$] ([ISIN, RegCode, NRDCode]);    
GO


--Пункт 2:
--Считаем долю нулевых строк в определённом столюце, в данном случае [GuarantVal]:
SELECT COUNT(*)*100/(SELECT COUNT(*) FROM [MarketRisk].[dbo].[bond_discription$] ) FROM [MarketRisk].[dbo].[bond_discription$] WHERE [GuarantVal]=' '; 
GO 
-- Создаём новую таблицу для данного столбца , если количество нулевых значений превышает 90%, как в этом случае.
SELECT [ISIN, RegCode, NRDCode], [GuarantVal] INTO [MarketRisk].[dbo].[bond_discription_GuarantVal] FROM [MarketRisk].[dbo].[bond_discription$] WHERE [GuarantVal] !=' '; 
GO 
-- Удаляем редкую строку из таблицы bond_discription$
ALTER TABLE [MarketRisk].[dbo].[bond_discription$] DROP COLUMN [GuarantVal]; 
GO


--Пункт 3;
-- Определим, по каким ценным бумагам доля дней, в которые нет котировки или торговли не было не более 10%.
ALTER TABLE [MarketRisk].[dbo].[base_price] ALTER COLUMN [TIME] INT; --изменим формат данных в столбце [TIME]
-- Скопируем таблицу с данными о торгах в отдельную таблицу [MarketRisk].[dbo].[task3] и проведем в ней сортировку по времени.
SELECT * INTO [MarketRisk].[dbo].[task3] FROM [MarketRisk].[dbo].[base_price]	
ORDER BY [TIME];	
GO
-- Возьмем нужные нам переменные  ID, [TIME], BID, а также значения предыдущих периодов переменных ID, BID.
--Проведем сортировку новой таблице по ID.
SELECT ID, [TIME], ISIN, BID, LAG(BID,1,0) OVER (ORDER BY ID) AS BID_prev, LAG(ID,1,0) OVER (ORDER BY ID) AS ID_prev
INTO [MarketRisk].[dbo].[task3_1] FROM [MarketRisk].[dbo].[task3]
ORDER BY [ID];	
GO
--Удалим из таблицы дни, в которые нет информации о торгах по данной ценной бумаге 
--в прошлый день торгов), если в эти дни были котировки.
DELETE FROM [MarketRisk].[dbo].[task3_1] WHERE ID != ID_prev AND BID != ' ';
GO

-- Для каждой ценной бумаги посчитаем, сколько дней по ней не было торгов или котировки
SELECT ID, COUNT([TIME]) AS no_trade_days 
INTO [MarketRisk].[dbo].[task3_2] FROM [MarketRisk].[dbo].[task3_1] 
WHERE BID=BID_prev OR BID=' ' GROUP BY ID;
GO

-- Для каждой ценной бумаги посчитаем, по скольким дням о ней есть информация.
SELECT ID, COUNT([TIME]) AS information_days
INTO [MarketRisk].[dbo].[task3_3] FROM [MarketRisk].[dbo].[task3_1] 
GROUP BY ID;
GO

-- Объединим данные и найдем для каждой ценной бумаги долю дней, в которые по ней не было торгов или котировки.
--Выберем только те ценные бумаги, по которым доля дней, в которые нет котировки или торговли не было, была не более 10%.
SELECT [MarketRisk].[dbo].[task3_3].[ID],no_trade_days , information_days, no_trade_days*100/information_days AS share
INTO [MarketRisk].[dbo].[task3_4]
FROM [MarketRisk].[dbo].[task3_2] RIGHT JOIN [MarketRisk].[dbo].[task3_3]
ON [MarketRisk].[dbo].[task3_3].[ID]= [MarketRisk].[dbo].[task3_2].[ID]
WHERE [MarketRisk].[dbo].[task3_2].[no_trade_days] IS NULL OR no_trade_days*100/information_days <= 10; 
GO

-- Теперь из имеющихся ценных бумаг нужно отобрать только те, которые являются облигациями и 
-- торгуются на Московской Бирже в режиме Основных торгов. 
SELECT [MarketRisk].[dbo].[task3_4].[ID], Exchange, CFIName, EmitentName
INTO [MarketRisk].[dbo].[task3_5]
FROM [MarketRisk].[dbo].[task3_4] INNER JOIN [MarketRisk].[dbo].[instrs$]
ON [MarketRisk].[dbo].[task3_4].[ID]= [MarketRisk].[dbo].[instrs$].[ID]
WHERE Exchange = 'Московская Биржа / МБ - Основной' 
AND (CFIName = 'Облигации / Сектор / Корпоративные' OR CFIName = 'Облигации / Сектор / Региональные');  
GO

--Всего 36 ценных бумаг. Нам нужен список из любых трех эмитентов. 
SELECT TOP(3) EmitentName
FROM [MarketRisk].[dbo].[task3_5]
GROUP BY EmitentName;
GO