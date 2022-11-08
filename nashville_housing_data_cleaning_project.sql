SELECT * FROM nashville_housing

-- Standardize Date Format
SELECT SaleDate, CONVERT(Date, SaleDate)
FROM nashville_housing

ALTER TABLE nashville_housing
ADD sale_date_converted Date;

UPDATE nashville_housing
SET sale_date_converted = CONVERT(Date, SaleDate)

SELECT sale_date_converted
FROM nashville_housing

-- Populate Property Address Data
SELECT PropertyAddress, ParcelID
FROM nashville_housing
WHERE PropertyAddress is null

SELECT a.ParcelID, a.PropertyAddress, b.ParcelID, b.propertyAddress, ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM nashville_housing a
JOIN nashville_housing b
	ON a.ParcelID = b.ParcelID
	AND a.[UniqueID ] <> b.[UniqueID ]
WHERE a.PropertyAddress is null

UPDATE a
SET PropertyAddress = ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM nashville_housing a
JOIN nashville_housing b
	ON a.ParcelID = b.ParcelID
	AND a.[UniqueID ] <> b.[UniqueID ]
WHERE a.PropertyAddress is null

-- Breaking up address into individual columns for address/city/state

SELECT 
SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1) as address,
SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) +1, LEN(PropertyAddress)) as city
FROM nashville_housing

ALTER TABLE nashville_housing
ADD property_split_address NVARCHAR(255);

UPDATE nashville_housing
SET property_split_address = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1)

ALTER TABLE nashville_housing
ADD property_split_city NVARCHAR(255);

UPDATE nashville_housing
SET property_split_city = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) +1, LEN(PropertyAddress))

SELECT
PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3),
PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2),
PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1)
FROM nashville_housing

ALTER TABLE nashville_housing
ADD property_split_state NVARCHAR(255);

UPDATE nashville_housing
SET property_split_state = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1)

-- Change Y & N to yes and no in 'Sold as Vacant' field

SELECT DISTINCT(SoldAsVacant), COUNT(SoldAsVacant)
FROM nashville_housing
GROUP BY SoldAsVacant
Order BY 2 Desc

SELECT SoldAsVacant
, CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
	   WHEN SoldAsVacant = 'N' THEN 'No'
	   ELSE SoldAsVacant
	   END
FROM nashville_housing

UPDATE nashville_housing
SET SoldAsVacant = CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
	   WHEN SoldAsVacant = 'N' THEN 'No'
	   ELSE SoldAsVacant
	   END

-- Remove Duplicates
WITH row_num_cte AS (
SELECT *,
	ROW_NUMBER() OVER (
	PARTITION BY ParcelID,
				 PropertyAddress,
				 SalePrice,
				 SaleDate,
				 LegalReference
				 ORDER BY 
					UniqueID
					) row_num

FROM nashville_housing
)
DELETE
FROM row_num_cte
WHERE row_num > 1

-- Delete Unused Columns

ALTER TABLE nashville_housing
DROP COLUMN OwnerAddress, TaxDistrict, PropertyAddress