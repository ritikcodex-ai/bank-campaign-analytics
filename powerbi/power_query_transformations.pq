// =============================================================================
// POWER QUERY M SCRIPTS
// Project  : Bank Term Deposit Campaign Effectiveness Analytics
// File     : power_query_transformations.pq
// Analyst  : Ritik
// Version  : 1.0
// =============================================================================
// HOW TO USE:
//   1. In Power BI Desktop → Transform Data (Power Query Editor)
//   2. Select the relevant table in the left panel
//   3. Home → Advanced Editor → paste the relevant script below
//   4. Click Done → Close & Apply
//
// IMPORTANT: Do NOT perform any business logic transformations here.
//   All derived columns and business rules were applied in SQL Script 01.
//   Power Query is used ONLY to set correct data types and verify load.
// =============================================================================


// =============================================================================
// SCRIPT 1 — bank_analysis TABLE
// =============================================================================
// Purpose : Set correct column types after CSV load.
//           Power BI sometimes infers text columns as incorrect types.
// Replace : The "Source" line path with your actual file location.
// =============================================================================

let
    // ── Load CSV ──────────────────────────────────────────────────────────────
    Source = Csv.Document(
        File.Contents("C:\YOUR_PATH\data\processed\bank_analysis.csv"),
        [
            Delimiter    = ",",
            Columns      = 26,
            Encoding     = 65001,   // UTF-8
            QuoteStyle   = QuoteStyle.None
        ]
    ),

    // ── Promote headers ───────────────────────────────────────────────────────
    PromotedHeaders = Table.PromoteHeaders(
        Source,
        [PromoteAllScalars = true]
    ),

    // ── Set column data types ─────────────────────────────────────────────────
    // Integer columns: numeric for aggregation and filtering
    // Text columns   : categorical for slicers and group-by visuals
    TypedColumns = Table.TransformColumnTypes(
        PromotedHeaders,
        {
            // ── Original numeric columns ──────────────────────────────────────
            { "age",               Int64.Type   },
            { "balance",           Int64.Type   },
            { "day",               Int64.Type   },
            { "duration",          Int64.Type   },
            { "campaign",          Int64.Type   },
            { "pdays",             Int64.Type   },
            { "previous",          Int64.Type   },
            { "month_num",         Int64.Type   },

            // ── Derived numeric columns ───────────────────────────────────────
            { "subscription_flag", Int64.Type   },
            { "valid_call_flag",   Int64.Type   },

            // ── Original categorical columns ──────────────────────────────────
            { "job",               type text    },
            { "marital",           type text    },
            { "education",         type text    },
            { "default",           type text    },
            { "housing",           type text    },
            { "loan",              type text    },
            { "contact",           type text    },
            { "month",             type text    },
            { "poutcome",          type text    },
            { "y",                 type text    },

            // ── Derived categorical columns ───────────────────────────────────
            { "age_band",                 type text },
            { "balance_tier",             type text },
            { "contact_frequency_band",   type text },
            { "debt_burden_flag",         type text },
            { "prior_contact_flag",       type text },
            { "call_quality_band",        type text }
        }
    ),

    // ── Verification step ─────────────────────────────────────────────────────
    // Row count check — add this as a documentation comment.
    // Expected: 45,211 rows × 26 columns
    // If row count differs, re-export bank_analysis from MySQL.
    FinalTable = TypedColumns

in
    FinalTable


// =============================================================================
// SCRIPT 2 — campaign_roi_summary TABLE
// =============================================================================

let
    Source = Csv.Document(
        File.Contents("C:\YOUR_PATH\data\processed\campaign_roi_summary.csv"),
        [Delimiter = ",", Columns = 11, Encoding = 65001]
    ),

    PromotedHeaders = Table.PromoteHeaders(Source, [PromoteAllScalars = true]),

    TypedColumns = Table.TransformColumnTypes(
        PromotedHeaders,
        {
            { "Scenario",               type text    },
            { "Strategy_Description",   type text    },
            { "Total_Calls",            Int64.Type   },
            { "Subscriptions",          Int64.Type   },
            { "Conversion_Rate_Pct",    type number  },
            { "Total_Cost_INR",         Int64.Type   },
            { "Cost_Lakh_INR",          type number  },
            { "Cost_Per_Acquisition",   type number  },
            { "Calls_Eliminated",       Int64.Type   },
            { "Spend_Saved_Lakh_INR",   type number  },
            { "Calls_Per_Subscription", type number  }
        }
    )

in
    TypedColumns


// =============================================================================
// SCRIPT 3 — monthly_summary TABLE
// =============================================================================

let
    Source = Csv.Document(
        File.Contents("C:\YOUR_PATH\data\processed\monthly_summary.csv"),
        [Delimiter = ",", Columns = 7, Encoding = 65001]
    ),

    PromotedHeaders = Table.PromoteHeaders(Source, [PromoteAllScalars = true]),

    TypedColumns = Table.TransformColumnTypes(
        PromotedHeaders,
        {
            { "month_num",            Int64.Type  },
            { "month",                type text   },
            { "Total_Contacts",       Int64.Type  },
            { "Subscriptions",        Int64.Type  },
            { "Conversion_Rate_Pct",  type number },
            { "Non_Subscriptions",    Int64.Type  },
            { "Campaign_Cost_Lakh",   type number }
        }
    ),

    // Sort chronologically so the line chart renders Jan→Dec correctly
    SortedByMonth = Table.Sort(
        TypedColumns,
        {{ "month_num", Order.Ascending }}
    )

in
    SortedByMonth


// =============================================================================
// SCRIPT 4 — segment_summary TABLE
// =============================================================================

let
    Source = Csv.Document(
        File.Contents("C:\YOUR_PATH\data\processed\segment_summary.csv"),
        [Delimiter = ",", Columns = 8, Encoding = 65001]
    ),

    PromotedHeaders = Table.PromoteHeaders(Source, [PromoteAllScalars = true]),

    TypedColumns = Table.TransformColumnTypes(
        PromotedHeaders,
        {
            { "age_band",              type text   },
            { "job",                   type text   },
            { "balance_tier",          type text   },
            { "debt_burden_flag",      type text   },
            { "poutcome",              type text   },
            { "Contacts",              Int64.Type  },
            { "Subscriptions",         Int64.Type  },
            { "Conversion_Rate_Pct",   type number }
        }
    )

in
    TypedColumns


// =============================================================================
// SORT ORDER TABLES
// =============================================================================
// Power BI sorts text columns alphabetically by default.
// This breaks ordinal columns like age_band (sorts A→Z, not young→old)
// and balance_tier (sorts alphabetically, not low→high).
//
// FIX: Use "Sort by Column" feature:
//   1. Select the text column in Fields pane (e.g., age_band)
//   2. Column Tools → Sort by Column → select the numeric sort key
//
// Required sort-by mappings:
//   age_band              → sort by: age_band itself (prefixed 1./2./3. handles it)
//   balance_tier          → sort by: balance_tier itself (prefixed 1./2./3. handles it)
//   contact_frequency_band → sort by: itself (prefixed 1./2./3./4. handles it)
//   month (text)          → sort by: month_num (integer)
//
// The prefix numbering system (e.g., "1. Young (18-30)") was deliberately
// added in SQL Script 01 specifically to make Power BI sort correctly
// without needing a separate sort column.
// =============================================================================
