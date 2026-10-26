-- очистка данных 

select * from NashvilleHousing

-- стандартизация Data format
select SaleDate, convert(Date, SaleDate) 
	from NashvilleHousing

alter table NashvilleHousing
 add SaleDateConverted Date;

UPDATE NashvilleHousing
	set SaleData = convert(Date, SaleDate)

-- populate Property Address data

SELECT "PropertyAddress"
    FROM nashvillehousing 
    ORDER BY "ParcelID";

SELECT a."ParcelID", a."PropertyAddress",
       b."ParcelID", b."PropertyAddress",
       COALESCE(a."PropertyAddress", b."PropertyAddress") AS filled_address
FROM nashvillehousing a
JOIN nashvillehousing b
  ON a."ParcelID" = b."ParcelID"
 AND a."UniqueID " <> b."UniqueID "
WHERE a."PropertyAddress" IS NULL
  AND b."PropertyAddress" IS NOT NULL;

UPDATE nashvillehousing a
SET "PropertyAddress" = b."PropertyAddress"
FROM nashvillehousing b
WHERE a."ParcelID" = b."ParcelID"
  AND a."UniqueID " <> b."UniqueID "
  AND a."PropertyAddress" IS NULL
  AND b."PropertyAddress" IS NOT NULL;

-- Разделяем адресс на индивидуальные колонки
-- (Address, City, State)

SELECT "PropertyAddress"
    FROM nashvillehousing 
    ORDER BY "ParcelID";

ALTER TABLE nashvillehousing
    ADD COLUMN property_street TEXT,
    ADD COLUMN property_city   TEXT,
    ADD COLUMN owner_street    TEXT,
    ADD COLUMN owner_city      TEXT,
    ADD COLUMN owner_state     TEXT;

UPDATE nashvillehousing
SET property_street = btrim(split_part("PropertyAddress", ',', 1)),
    property_city   = btrim(split_part("PropertyAddress", ',', 2)),
    owner_street    = btrim(split_part("OwnerAddress",    ',', 1)),
    owner_city      = btrim(split_part("OwnerAddress",    ',', 2)),
    owner_state     = btrim(split_part("OwnerAddress",    ',', 3));

SELECT property_street, property_city, owner_street, owner_city, owner_state
FROM nashvillehousing
WHERE "OwnerAddress" IS NOT NULL
LIMIT 5

-- приводим Y and N, во все Yes and No
select Distinct("SoldAsVacant"), count("SoldAsVacant")
	from nashvilleHousing
	group by "SoldAsVacant"

update nashvillehousing
set "SoldAsVacant" = CASE "SoldAsVacant"
					when 'Y' THEN 'Yes'
					when 'N' THEN 'No'
					Else 'SoldAsVacant'
					End

select "SoldAsVacant", count("SoldAsVacant")
	from nashvilleHousing
	group by "SoldAsVacant"

BEGIN;

UPDATE nashvillehousing a
SET "SoldAsVacant" = CASE r."SoldAsVacant"
                         WHEN 'Y' THEN 'Yes'
                         WHEN 'N' THEN 'No'
                         ELSE r."SoldAsVacant"
                     END
FROM sold_restore r
WHERE a."UniqueID " = r."Unique_ID "

SELECT "SoldAsVacant", COUNT(*) FROM nashvillehousing GROUP BY 1;

-- убираем дубликаты
-- Сколько дублей (до удаления)
SELECT COUNT(*) AS dup_rows
FROM (SELECT ROW_NUMBER() OVER (
              PARTITION BY "ParcelID", "PropertyAddress", "SalePrice", "SaleDate", "LegalReference"
              ORDER BY "UniqueID ") AS rn
      FROM nashvillehousing) t
WHERE rn > 1;
 
WITH numbered AS (
    SELECT "UniqueID ",
           ROW_NUMBER() OVER (
               PARTITION BY "ParcelID", "PropertyAddress", "SalePrice", "SaleDate", "LegalReference"
               ORDER BY "UniqueID ") AS rn
    FROM nashvillehousing
)
DELETE FROM nashvillehousing
WHERE "UniqueID " IN (SELECT "UniqueID " FROM numbered WHERE rn > 1);
 
-- Итог: было 56 477, должно стать 56 373
SELECT COUNT(*) AS rows_after FROM nashvillehousing;