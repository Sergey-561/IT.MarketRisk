--������� 2.
-- ��������� ���� ������ ��� ����������� ���������� ������� � ���������� � �������� 
ALTER TABLE [MarketRisk].[dbo].[bond_discription$] ALTER COLUMN [BegDistDate] float;
  ALTER TABLE [MarketRisk].[dbo].[bond_discription$] ALTER COLUMN [BegDistDate] datetime;
-- �������� ������� � ����������� �����������, ������� �� ����� 
--������������ � python. ������� ISIN � ������ ��������� �������� ������� �� ������� � ������������ ������. 
 SELECT [ISIN], [CPN] INTO [MarketRisk].[dbo].[coupon_data]
FROM [MarketRisk].[dbo].[base_price]
WHERE [CPN] != ' '
GO
UPDATE [MarketRisk].[dbo].[coupon_data]
SET [CPN] = REPLACE([CPN], ',', '.');
GO

-- ������� ������ ������� [CPN] �� ��������.
ALTER TABLE [MarketRisk].[dbo].[coupon_data] ALTER COLUMN [CPN] float NOT NULL;
GO
--��� ������ ���������� ��������� ������� ������ ��������� �������� �������.
SELECT [ISIN], AVG([CPN]) as coupon
INTO [MarketRisk].[dbo].[coupon_data2]
FROM [MarketRisk].[dbo].[coupon_data]
GROUP BY [ISIN]
GO

-- ������� ����� ������� �� ������ ������� [bond_discription$] � ������ �� �������� ������ ������� �� ���� 
--����������� ��� ���������� ������� 2 �����������. ������ ������� ������ ��� �������� � python.

SELECT [ISIN, RegCode, NRDCode], [IssuerName], [SumMarketVal], [EndMtyDate], [BegDistDate], [SecurityType], [CouponType], [HaveOffer], [CouponPerYear], [Basis], [FaceFTName], [AmortisedMty], [FaceValue], [coupon]
INTO [MarketRisk].[dbo].[bond_information]
FROM [MarketRisk].[dbo].[bond_discription$] LEFT JOIN [MarketRisk].[dbo].[coupon_data2]
ON [MarketRisk].[dbo].[bond_discription$].[ISIN, RegCode, NRDCode] = [MarketRisk].[dbo].[coupon_data2].[ISIN]
WHERE [IssuerName] !=' '
GO

