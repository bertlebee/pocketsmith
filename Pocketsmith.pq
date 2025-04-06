// PocketSmith tools
//
// Author:  Rob Walsh
// Repo:    https://github.com/bertlebee/pocketsmith
// License: MIT
//
let
    baseurl = "https://api.pocketsmith.com/v2",
    headers = [
        #"X-Developer-Key" = #"X-Developer-Key",
        #"Accept" = "application/json"
    ],
    startDate = "2020-01-01",
    endDate = "2050-01-01",
    perPage = 1000,
    //private functions
    get = (route as list, optional query as record) =>
        let
            url = baseurl & List.Accumulate(route, "", (acc, next) => acc & "/" & next),
            options = if query = null then [Headers = headers] else [Headers = headers, Query = query],
            response = Web.Contents(url, options),
            data =
                try
                    Json.Document(response)
                otherwise
                    Json.FromValue([Error = true, options = options, response = response])
        in
            data,
    getPaged = (route as list, optional page as number) =>
        let
            ResultsList = List.Generate(
                //start with empty record
                () => [page = 0, data = null],
                each [data] = null or Table.RowCount(Table.FromValue([data])) = perPage,
                //get the next page
                each
                    [
                        page = [page] + 1,
                        data = try
                            get(route, [page = Text.From([page] + 1), per_page = Text.From(perPage)])
                        otherwise
                            Json.Document("{}")
                    ],
                //return data only (ignore page count)
                each [data]
            ),
            result = List.Accumulate(
                ResultsList, {}, (acc, next) => if next <> null then List.Combine({acc, next}) else acc
            )
        in
            result,
    tableFromJson = (json) =>
        let
            baseTable = Table.FromList(json, Splitter.SplitByNothing(), null, null, ExtraValues.Error),
            colNames = List.Distinct(
                List.Accumulate(json, {}, (acc, next) => List.Combine({acc, Record.FieldNames(next)}))
            ),
            expanded = Table.ExpandRecordColumn(baseTable, "Column1", colNames, colNames)
        in
            expanded,
    me = get({"me"}),
    userId = Text.From(me[id]) as text,
    cats = () =>
        let
            Source = get({"users", userId, "categories"}),
            #"Converted to Table" = Table.FromList(Source, Splitter.SplitByNothing(), null, null, ExtraValues.Error),
            level11 = Table.ExpandRecordColumn(
                #"Converted to Table",
                "Column1",
                {
                    "id",
                    "title",
                    "colour",
                    "is_transfer",
                    "is_bill",
                    "refund_behaviour",
                    "parent_id",
                    "roll_up",
                    "created_at",
                    "updated_at"
                },
                {
                    "L1",
                    "L1.Title",
                    "colour",
                    "is_transfer",
                    "is_bill",
                    "refund_behaviour",
                    "parent_id",
                    "roll_up",
                    "created_at",
                    "updated_at"
                }
            ),
            #"Added Custom" = Table.AddColumn(level11, "id", each [L1]),
            level1 = Table.AddColumn(#"Added Custom", "level", each 1),
            #"Selected level 2" = Table.ExpandRecordColumn(
                #"Converted to Table", "Column1", {"id", "title", "children"}, {"L1", "L1.Title", "level 2"}
            ),
            #"Expanded level 2" = Table.ExpandListColumn(#"Selected level 2", "level 2"),
            #"Level 2" = Table.ExpandRecordColumn(
                #"Expanded level 2",
                "level 2",
                {
                    "id",
                    "title",
                    "colour",
                    "is_transfer",
                    "is_bill",
                    "refund_behaviour",
                    "parent_id",
                    "roll_up",
                    "created_at",
                    "updated_at"
                },
                {
                    "L2",
                    "L2.Title",
                    "colour",
                    "is_transfer",
                    "is_bill",
                    "refund_behaviour",
                    "parent_id",
                    "roll_up",
                    "created_at",
                    "updated_at"
                }
            ),
            level21 = Table.SelectRows(#"Level 2", each [L2] <> null and [L2] <> ""),
            #"Added Custom1" = Table.AddColumn(level21, "id", each [L2]),
            level2 = Table.AddColumn(#"Added Custom1", "level", each 2),
            #"Selected level 3" = Table.ExpandRecordColumn(
                #"Expanded level 2", "level 2", {"id", "title", "children"}, {"L2", "L2.Title", "children"}
            ),
            #"Expanded children" = Table.ExpandListColumn(#"Selected level 3", "children"),
            #"Level 3" = Table.ExpandRecordColumn(
                #"Expanded children",
                "children",
                {
                    "id",
                    "title",
                    "colour",
                    "is_transfer",
                    "is_bill",
                    "refund_behaviour",
                    "parent_id",
                    "roll_up",
                    "created_at",
                    "updated_at"
                },
                {
                    "L3",
                    "L3.Title",
                    "colour",
                    "is_transfer",
                    "is_bill",
                    "refund_behaviour",
                    "parent_id",
                    "roll_up",
                    "created_at",
                    "updated_at"
                }
            ),
            level31 = Table.SelectRows(#"Level 3", each [L3] <> null and [L3] <> ""),
            #"Added Custom4" = Table.AddColumn(level31, "id", each [L3]),
            level3 = Table.AddColumn(#"Added Custom4", "level", each 3),
            Custom1 = Table.Combine({level3, level2, level1}),
            #"Sorted Rows" = Table.Sort(
                Custom1, {
                    {"L1.Title", Order.Ascending},
                    {"L2.Title", Order.Ascending},
                    {"L3.Title", Order.Ascending}
                }
            )
        in
            #"Sorted Rows",
    //public functions
    PocketSmith = [
        User = me,
        Accounts = () => tableFromJson(get({"users", userId, "accounts"})),
        Categories = cats,
        Transactions = () => tableFromJson(getPaged({"users", userId, "transactions"})),
        Labels = () => get({"users", userId, "labels"})
    ]
in
    PocketSmith
