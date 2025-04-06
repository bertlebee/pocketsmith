# PocketSmith Powerquery
Setup:
1. In a new workbook, create a new blank query (`Get Data`/`From Other Sources`/`Blank Query`). 
1. On the `Home` tab, click `Manage Parameters`/`New Parameter`
1. Create a Parameter called `X-Developer-Key` with your PocketSmith API key as the value. This key can be used to do pretty much anything with your PocketSmith account. Don't share this workbook with anyone, as it contains your key.
1. Save `Powerquery.pq` from this repo on your computer somewhere
1. Rename your blank query to `PocketSmith` using the expression:
```m
= Expression.Evaluate(Text.FromBinary(Text.FromBinary(File.Contents("C:\your\local\path.pq"))), #shared)
```
> alternatively; the yolo approach, loading directly from my repo. **Warning**: If I change something, any queries you've built may break. And I will be changing things :D
>
>    ```m
>    = Expression.Evaluate(Text.FromBinary(Web.Contents("https://raw.githubusercontent.com/bertlebee/pocketsmith/refs/heads/master/Pocketsmith.pq")), #shared)
>    ```
> this will load the most recent version when you refresh.
1. Right click on your `PocketSmith` query and click `Reference`. If all has gone well, you should see a list of functions you can execute to get data.
examples:
```m
PocketSmith[User]() //logged in user info
PocketSmith[Transactions]() //transactions
... etc.
```