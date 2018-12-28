--Задание 2.
-- Изменение типа данных для возможности вычисления времени в диаграммах и графиках 
ALTER TABLE [MarketRisk].[dbo].[bond_discription$] ALTER COLUMN [BegDistDate] float;
  ALTER TABLE [MarketRisk].[dbo].[bond_discription$] ALTER COLUMN [BegDistDate] datetime;
-- Создадим таблицу с необходимой информацией, которую мы будем 
--обрабатывать в python. Возьмем ISIN и размер ближайшей купонной выплаты из таблицы с результатами торгов. 
 SELECT [ISIN], [CPN] INTO [MarketRisk].[dbo].[coupon_data]
FROM [MarketRisk].[dbo].[base_price]
WHERE [CPN] != ' '
GO
UPDATE [MarketRisk].[dbo].[coupon_data]
SET [CPN] = REPLACE([CPN], ',', '.');
GO

-- Изменим формат столбца [CPN] на числовой.
ALTER TABLE [MarketRisk].[dbo].[coupon_data] ALTER COLUMN [CPN] float NOT NULL;
GO
--Для каждой облигациии посчитаем средний размер ближайшей купонной выплаты.
SELECT [ISIN], AVG([CPN]) as coupon
INTO [MarketRisk].[dbo].[coupon_data2]
FROM [MarketRisk].[dbo].[coupon_data]
GROUP BY [ISIN]
GO

-- Создаем общую таблицу на основе таблицы [bond_discription$] и данных по среднему купону таблицу со всей 
--необходимой для выполнения задания 2 информацией. Данная таблица готова для выгрузки в python.

SELECT [ISIN, RegCode, NRDCode], [IssuerName], [SumMarketVal], [EndMtyDate], [BegDistDate], [SecurityType], [CouponType], [HaveOffer], [CouponPerYear], [Basis], [FaceFTName], [AmortisedMty], [FaceValue], [coupon]
INTO [MarketRisk].[dbo].[bond_information]
FROM [MarketRisk].[dbo].[bond_discription$] LEFT JOIN [MarketRisk].[dbo].[coupon_data2]
ON [MarketRisk].[dbo].[bond_discription$].[ISIN, RegCode, NRDCode] = [MarketRisk].[dbo].[coupon_data2].[ISIN]
WHERE [IssuerName] !=' '
GO

