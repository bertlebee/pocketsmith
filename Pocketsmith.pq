// PocketSmith tools
//
// Author:  Rob Walsh
// Repo:    https://github.com/bertlebee/pocketsmith
// License: MIT
let
    baseurl = "https://api.pocketsmith.com/v2/",
    headers = [
        #"X-Developer-Key" = #"X-Developer-Key",
        #"Accept" = "application/json"
    ],
    max_pages = 10,
    per_page = 1000,
    PocketSmith = (key as text)[
        Get = (Route as list, optional paged as logical) =>
            let
                url = baseurl & List.Accumulate(Route, "", (acc, next) => acc & "/" & next),
                data =
                    if paged <> null or paged then
                        List.Combine(
                            List.Generate(
                                () => [
                                    data = {},
                                    page = 1,
                                    count = 0,
                                    hasMorePages = true
                                ],
                                each _[count] < max_pages and _[hasMorePages],
                                each
                                    [
                                        data = try
                                            Json.Document(
                                                Web.Contents(
                                                    baseurl
                                                        & List.Accumulate(Route, "", (acc, next) => acc & "/" & next)
                                                        & "?&page="
                                                        & Number.ToText(_[page])
                                                        & "&per_page="
                                                        & per_page,
                                                    headers
                                                )
                                            ) otherwise {},
                                        page = _[page] + 1,
                                        count = _[count] + 1,
                                        hasMorePages = List.Count(_[data]) < per_page
                            
                                    ],
                                each _[data]
                            )
                        )
                    else
                        try
                            Json.Document(
                                Web.Contents(baseurl & List.Accumulate(Route, "", (acc, next) => acc & "/" & next))
                            )
            in
                data,
        UserId = () as text => Text.From(Get({"me"}))
    ]
in
    PocketSmith
