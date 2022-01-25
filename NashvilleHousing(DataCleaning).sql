/*

Cleaning Data

*/

Select * FROM [dbo].[NashvilleHousing]

-----------------------------------------------------------------------------------------------------

--- Standardize Sale Date
Select SaleDateCoverted,Cast(SaleDate as date) FROM NashvilleHousing

--Update NashvilleHousing
--Set SaleDate = CAST(SaleDate as date)

ALTER TABLE NashvilleHousing
ADD SaleDateCoverted Date;

Update NashvilleHousing
Set SaleDateCoverted = CAST(SaleDate as date)

-------------------------------------------------------------------------------------------------------

--Populate Property Address Data
Select *
FROM [dbo].[NashvilleHousing]
--where PropertyAddress IS NULL
ORDER BY ParcelID

-- now after checking some rows have same parcel id and for that id same address
-- and we also have some rows where property address is null
-- so if parcel id is same for 2 rows and 1 row have property address and other don't then populate the same address for the other one too.

Select 
	house1.ParcelID
	,house1.PropertyAddress
	,house2.ParcelID
	,house2.PropertyAddress
	,ISNULL(house1.ParcelID,house2.PropertyAddress)
FROM NashvilleHousing AS house1
JOIN NashvilleHousing AS house2
ON house2.ParcelID = house1.ParcelID
and house1.[UniqueID ] <> house2.[UniqueID ]
WHERE house1.PropertyAddress IS NULL

Update house1
SET PropertyAddress = ISNULL(house1.ParcelID,house2.PropertyAddress)
FROM NashvilleHousing AS house1
JOIN NashvilleHousing AS house2
ON house2.ParcelID = house1.ParcelID
and house1.[UniqueID ] <> house2.[UniqueID ]
WHERE house1.PropertyAddress IS NULL

--Select * FROM NashvilleHousing WHERE PropertyAddress IS NULL

--------------------------------------------------------------------------------------------------------------

-- Breaking out address into individual Columns (Address,City,State)

Select PropertyAddress FROM NashvilleHousing 

Select
	PropertyAddress
	,LEFT(PropertyAddress,LEN(PropertyAddress)-CHARINDEX(',',PropertyAddress))
FROM NashvilleHousing

--Select
--	PropertyAddress
--	,LEN(PropertyAddress)
--	,CHARINDEX(',',PropertyAddress)
--	,SUBSTRING(PropertyAddress,1,CHARINDEX(',',PropertyAddress)-2)
--FROM NashvilleHousing


Select
	PropertyAddress
	-- here i am getting an error Invalid length parameter passed to the LEFT or SUBSTRING function.
	-- it's giving this error because maybe in some row , is missing
	,SUBSTRING(PropertyAddress,1,CHARINDEX(',',PropertyAddress) - 1) 
FROM NashvilleHousing


--Trying to get make it correct
Select
	SUBSTRING(PropertyAddress,1,CHARINDEX(',',PropertyAddress + ',') - 1) AS Address
	,SUBSTRING(PropertyAddress,CHARINDEX(',',PropertyAddress + ',') +1,LEN(PropertyAddress)) AS City
FROM NashvilleHousing

-- adding columns for address and city
ALTER TABLE NashvilleHousing
ADD PropertySplitAddress NVARCHAR(255);

Update NashvilleHousing
SET PropertySplitAddress = SUBSTRING(PropertyAddress,1,CHARINDEX(',',PropertyAddress + ',') - 1)

ALTER TABLE NashvilleHousing
ADD PropertySplitCity NVARCHAR(255);

Update NashvilleHousing
Set PropertySplitCity = SUBSTRING(PropertyAddress,CHARINDEX(',',PropertyAddress + ',') +1,LEN(PropertyAddress))

--Select TOP 100 * FROM NashvilleHousing




--- owner address

Select OwnerAddress
FROM NashvilleHousing

-- parsename works with . so replacing , with .
Select 
	PARSENAME(REPLACE(OwnerAddress, ',','.'),3) AS [Address]
	,PARSENAME(REPLACE(OwnerAddress, ',','.'),2) AS [City]
	,PARSENAME(REPLACE(OwnerAddress, ',','.'),1) AS [State]
FROM NashvilleHousing


ALTER TABLE NashvilleHousing
ADD OwnerSplitAddress NVARCHAR(255);

Update NashvilleHousing
Set OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress, ',','.'),3)


ALTER TABLE NashvilleHousing
ADD OwnerSplitCity NVARCHAR(255);

Update NashvilleHousing
Set OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress, ',','.'),2)


ALTER TABLE NashvilleHousing
ADD OwnerSplitState NVARCHAR(255);

Update NashvilleHousing
Set OwnerSplitState = PARSENAME(REPLACE(OwnerAddress, ',','.'),1)

--Select TOP 100 * FROM NashvilleHousing



---------------------------------------------------------------------------------------------------------------------------------------

-- Change Y and N to Yes and No in SoldAsVacant field

Select DISTINCT SoldAsVacant
FROM NashvilleHousing

Select
	SoldAsVacant
	,CASE
		WHEN SoldAsVacant = 'Y' THEN 'Yes'
		WHEN SoldAsVacant = 'N' THEN 'No'
		Else SoldAsVacant
	END
FROM NashvilleHousing
WHERE SoldAsVacant = 'N' OR SoldAsVacant = 'Y'


Update NashvilleHousing
SET SoldAsVacant = CASE
		WHEN SoldAsVacant = 'Y' THEN 'Yes'
		WHEN SoldAsVacant = 'N' THEN 'No'
		Else SoldAsVacant
	END

-------------------------------------------------------------------------------------------------------------------------------

-- Remove Duplicates 


--here if parcel id, property id, sale date, sale price, legal reference is same then the row is duplicated
-- if 3 rows are same then it will give row no 1 to 1st,2 to 2nd and 3 to 3rd 

WITH Row_num_CTE
AS
(
Select 
	*
	,ROW_NUMBER() OVER(
	PARTITION BY ParcelID,
				 PropertyAddress,
				 SalePrice,
				 SaleDate,
				 LegalReference
				 ORDER BY [UniqueID ]) row_num
FROM NashvilleHousing
) 
DELETE
FROM Row_num_CTE
where row_num > 1


-------------------------------------------------------------------------------------------------------------------

-- Delete unused Columns

ALTER TABLE NashvilleHousing
DROP COLUMN OwnerAddress,TaxDistrict,PropertyAddress

--Select TOP 10 * FROM NashvilleHousing