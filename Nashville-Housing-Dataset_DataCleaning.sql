
-----# DATA CLEANING #------

-- Data lookup
Select *
From Nashville_Housing_Data..HousingData



-- Standardized data format 

Select SaleDate, CONVERT(date, SaleDate) AS 'SaleDate_Updated'
From Nashville_Housing_Data..HousingData

ALTER Table Nashville_Housing_Data..HousingData
Add SaleDate_Updated Date;

Update Nashville_Housing_Data..HousingData
SET SaleDate_Updated = CONVERT(date, SaleDate)

-- Populate property address (due to NULL presence)
-- Note: same ParcelID = same PropertyAdress

Select *
From Nashville_Housing_Data..HousingData
Where PropertyAddress is null	-- around 30 records
Order by ParcelID

-- Self-join: 
Select H1.ParcelID, H1.[UniqueID ], H1.PropertyAddress, H2.ParcelID, H2.[UniqueID ],
ISNULL(H1.PropertyAddress, H2.PropertyAddress)
From Nashville_Housing_Data..HousingData AS H1
Join Nashville_Housing_Data..HousingData AS H2
	On H1.ParcelID = H2.ParcelID
	and H1.[UniqueID ] <> H2.[UniqueID ]
Where H1.PropertyAddress is null


Update H1
SET PropertyAddress = ISNULL(H1.PropertyAddress, H2.PropertyAddress)
From Nashville_Housing_Data..HousingData AS H1
Join Nashville_Housing_Data..HousingData AS H2
	On H1.ParcelID = H2.ParcelID
	and H1.[UniqueID ] <> H2.[UniqueID ]
Where H1.PropertyAddress is null



-- reformat address columns

Select *
From Nashville_Housing_Data..HousingData

Select 
SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress)-1) AS 'Address',
SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress)+1, LEN(PropertyAddress)) AS 'City'
From Nashville_Housing_Data..HousingData

-- New column for address
ALTER Table Nashville_Housing_Data..HousingData
Add Property_Address nvarchar(255);
Update Nashville_Housing_Data..HousingData
SET  Property_Address = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress)-1)

-- New column for city
ALTER Table Nashville_Housing_Data..HousingData
Add Property_City nvarchar(255);
Update Nashville_Housing_Data..HousingData
SET  Property_City = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress)+1, LEN(PropertyAddress))





-- Dealing with OwnerAdress (Columns condinsed with whole address)
Select OwnerAddress
From Nashville_Housing_Data..HousingData

Select
PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3),
PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2),
PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1)
From Nashville_Housing_Data..HousingData

-- New column for owner address
ALTER Table Nashville_Housing_Data..HousingData
Add Owner_Address nvarchar(255);

ALTER Table Nashville_Housing_Data..HousingData
Add Owner_City nvarchar(255);
Update Nashville_Housing_Data..HousingData
SET  Owner_Address = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3)

-- New column for owner city

Update Nashville_Housing_Data..HousingData
SET  Owner_City = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2)

-- New column for owner state
ALTER Table Nashville_Housing_Data..HousingData
Add Owner_State nvarchar(255);
Update Nashville_Housing_Data..HousingData
SET  Owner_State = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1)


-- Check
Select *
From Nashville_Housing_Data..HousingData


-- Re-adjust SoldAsVacant column (Y, N, Yes, and No values presented)

Select Distinct(SoldAsVacant), COUNT(SoldAsVacant)
From Nashville_Housing_Data..HousingData
Group by SoldAsVacant
order by 2


Select SoldAsVacant,
CASE When SoldAsVacant = 'Y' THEN 'Yes'
	 When SoldAsVacant = 'N' THEN 'No'
	 ELSE SoldAsVacant
	 END
From Nashville_Housing_Data..HousingData

Update Nashville_Housing_Data..HousingData
SET  SoldAsVacant = CASE When SoldAsVacant = 'Y' THEN 'Yes'
	 When SoldAsVacant = 'N' THEN 'No'
	 ELSE SoldAsVacant
	 END



-- Remove duplicates (accroding to this dataset)

With tmpCTE AS(
Select *,
	ROW_NUMBER() Over (
	Partition by ParcelID,
				 PropertyAddress,
				 SalePrice,
				 SaleDate,
				 LegalReference
				 Order by UniqueID ) row_num
From Nashville_Housing_Data..HousingData
)
DELETE
From tmpCTE
Where row_num > 1
--Order by PropertyAddress
