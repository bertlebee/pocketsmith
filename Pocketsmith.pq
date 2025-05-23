// PocketSmith tools
//
// Author:  Rob Walsh
// Repo:    https://github.com/bertlebee/pocketsmith
// License: MIT
//
(key as text) =>
    let
        baseurl = "https://api.pocketsmith.com/v2",
        defaultHeaders = [
            #"X-Developer-Key" = key,
            #"Accept" = "application/json"
        ],
        //private functions
        queryParams = (optional params as nullable list) as record =>
            if params <> null then
                Record.Combine(List.Select(params, each _ is record))
            else
                {[]},
        queryOptions = (optional params as nullable list) => [
            Headers = defaultHeaders,
            Query = queryParams(params)
        ],
        tableFromJson = (json as list) =>
            let
                baseTable = Table.FromList(json, Splitter.SplitByNothing(), null, null, ExtraValues.Error),
                colNames = List.Distinct(
                    List.Accumulate(json, {}, (acc, next) => List.Combine({acc, Record.FieldNames(next)}))
                ),
                expanded = Table.ExpandRecordColumn(baseTable, "Column1", colNames, colNames)
            in
                expanded,
        get = (route as list, optional params as record) =>
            let
                url = baseurl & List.Accumulate(route, "", (acc, next) => acc & "/" & next),
                options = queryOptions({params}),
                data =
                    try
                        let
                            response = Web.Contents(url, options), data = Json.Document(response)
                        in
                            data
                        otherwise Json.Document(Json.FromValue({[
                            error = [url = url, options = options]
                        ]}))
            in
                data,
        getPaged = (route as list, optional params as record) =>
            let
                //default to 1000 per page
                currentParams = queryParams({[per_page = "1000"], params}),
                //todo check if page has been provided already
                ResultsList = List.Generate(
                    //start with page 1
                    () =>
                        [
                            page = 1,
                            data = tableFromJson(get(route, queryParams({[page = Text.From(page)], currentParams})))
                        ],
                    //continue while we have more pages to fetch
                    each Table.RowCount([data]) > 1,
                    //and not (Record.HasFields("error")),
                    //get the next page
                    each
                        [
                            page = [page] + 1,
                            data = tableFromJson(get(route, queryParams({[page = Text.From(page)], currentParams})))
                        ],
                    //return data only (ignore page)
                    each [data]
                ),
                result = Table.Combine(ResultsList)
            in
                result,
        me = get({"me"}),
        userId = Text.From(me[id]) as text,
        cats =
            let
                Source = get({"users", userId, "categories"}),
                #"Converted to Table" = Table.FromList(
                    Source, Splitter.SplitByNothing(), null, null, ExtraValues.Error
                ),
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
                    Custom1,
                    {{"L1.Title", Order.Ascending}, {"L2.Title", Order.Ascending}, {"L3.Title", Order.Ascending}}
                )
            in
                #"Sorted Rows",
        //public functions
        PocketSmith = [
            User = () => me,
            Institutions = () => tableFromJson(get("users", userId, "institutions")),
            Accounts = () => tableFromJson(get({"users", userId, "accounts"})),
            Transaction_Accounts = () => tableFromJson(get({"users", userId, "transaction_accounts"})),
            Transactions = (optional query as record) => getPaged({"users", userId, "transactions"}, query),
            Categories = () => cats,
            CategoryRules = () => tableFromJson(get({"users", userId, "category_rules"})),
            Labels = () => get({"users", userId, "labels"})
        ]
    in
        PocketSmith
