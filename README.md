# PocketSmith Powerquery
Powerquery Library for Pocketsmith.

## Examples:
```m
PocketSmith[User]() //logged in user info
PocketSmith[Transactions]() //all transactions
PocketSmith[Transactions]([per_page = "500", start_date = "2025-02-25", end_date = "2025-05-20"]) //all transactions, retrieved 500 at a time, between 25/2/2025 and 20/5/2025
... etc.
```

## Setup
1. Save `pocketsmith clean.xlsx` from this repo to your computer
2. Open `Power Query Editor`
3. Select the `X-Developer-Key` parameter copy your [pocketsmith developer key](https://developers.pocketsmith.com/docs/introduction#tools-just-for-me) into the `Current Value` field.

## (Optional but recommended) Freeze version
Every time you refresh your queries, "Pocketsmith.pq" is downloaded from this repo again. **That means any changes I make may break your queries**.

To avoid this:
1. Create a copy of `Powerquery.pq` on your computer, noting where it is.
2. Open `Power Query Editor`
3. Select the `LocalPath` parameter and update it with the full path where you saved `Powerquery.pq`
4. Select the `Source` Parameter and change it to `Local`
5. Refresh your queries. You are now using the local version.

### Update frozen version
If you want an updated version, save a fresh copy of `Pocketsmith.pq` in its place.

# Troubleshooting
Do you own a mac? Powerquery is somewhat crippled. Use windows if you can. Some issues and solutions
## "This workbook contains Power Query queries loaded to the Data Model which can’t be refreshed in Excel for Mac."
- Simple option: delete the offending query and create a new one, ensuring that you don't check "Add this data to the Data Model" when loading.
- Easier option:
    - Open in Excel **in Windows**
    - Click "Data" > "Queries & Connections"
    - Right click on each query > "Load To..."
    - Ensure "Add this data to the Data Model" is **UN**checked

## Something Something "on premise data gateway"
- See reply on 26-Apr-2023 [here](https://answers.microsoft.com/en-us/msoffice/forum/all/excel-power-query-an-on-premises-data-gateway-is/6ac3292d-d710-4fd2-8cfa-999ec8553157)
