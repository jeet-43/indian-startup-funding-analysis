## Indian Startup Funding Analysis (2015 to 2020)

An end to end data analytics project that cleans a genuinely messy real world dataset of Indian startup funding deals, analyzes it with SQL, and visualizes it in a four page Power BI dashboard built around one specific business problem instead of open ended exploration.

This is my first data analytics project. I built it to practice the full workflow end to end, from cleaning messy raw data through to a dashboard that answers a specific business question, rather than just following a tutorial. There are rough edges I am aware of and have documented honestly below rather than hidden, and I expect my approach to cleaning, SQL, and dashboard design to keep improving as I take on more projects and learn more.

## Dataset Source

This project uses the [Indian Startup Funding](https://www.kaggle.com/datasets/sudalairajkumar/indian-startup-funding/suggestions) dataset from Kaggle, originally compiled by Sudalai Raj Kumar. The raw file is included in this repo as `raw_startup_funding.csv` exactly as downloaded, before any cleaning.

## Business Problem

A seed stage VC fund is designing its investment thesis and needs to know three things before allocating capital:

1. Which sectors show sustained funding momentum across multiple years, versus sectors whose apparent lead is driven by one off mega rounds?
2. Where is funding activity broad, meaning many deals, versus concentrated, meaning a few large deals, and what does that imply about competition for a new entrant?
3. Which city and sector combinations show high deal activity but comparatively low total capital, suggesting overlooked opportunity relative to more saturated hubs?

Full context and success criteria are in `Business_Problem_Document.pdf`.

## Repository Contents

| File | Description |
|---|---|
| `Business_Problem_Document.pdf` | The business problem this analysis was scoped to answer, and why it matters |
| `Startup_Funding_Cleaning_Beginner.ipynb` | Step by step Python and pandas cleaning notebook, runs end to end with no errors |
| `raw_startup_funding.csv` | Original, unmodified dataset, 3,044 rows and 10 columns |
| `clean_startup_funding.csv` | Cleaned output of the notebook, ready for SQL and BI |
| `startup_funding.db` | SQLite database loaded from the cleaned CSV |
| `startup_funding_sql_queries.sql` | Business question SQL, basic through advanced window functions, including the query behind each dashboard page |
| `startup_funding_dashboard.pbix` | Four page Power BI dashboard, one page per business question plus an overview |
| `LICENSE` | MIT license |

## Data Cleaning Highlights

- `Amount in USD` was stored as text with Indian style comma formatting, for example "20,00,00,000", had about 32 percent missing values, and used non numeric placeholders like "undisclosed." All of this was converted into real numbers with a documented cleaning function.
- `Industry Vertical` had 821 unique raw spellings. Exact spelling and casing duplicates were merged, for example E-commerce, Ecommerce, and eCommerce became one category. The long tail of roughly 800 remaining values is mostly niche, one off business descriptions rather than spelling noise, and was intentionally left unmerged to avoid misclassifying genuinely different businesses. `industry_vertical_clean` ends at 797 unique values.
- `InvestmentnType` had 55 raw variants, including typos, inconsistent casing, and embedded newline characters. These were standardized with pattern matching, for example any Series A, B, or C variant, Pre Series A, and Seed or Angel merged, down to 15 clean categories in `investment_type_clean`.
- `City Location` had duplicate city names caused by inconsistent spelling, for example Bangalore and Bengaluru, and Gurgaon and Gurugram. These were merged into a single `city_clean` column so that city level totals are not silently split across two rows.
- Hidden non breaking space characters, stray literal backslash n text, and malformed dates with extra or missing slashes were cleaned throughout.

The notebook was verified to run end to end with `jupyter nbconvert --execute` and reproduces `clean_startup_funding.csv` exactly.

## Dashboard

The dashboard has four pages, each built around one part of the business problem.

**Page 1, Overview.** Four KPI cards (Total Funding, Deal Count, Avg Deal Size, Disclosed Deal Percent) plus a short framing of the business problem, so a viewer is oriented before looking at any chart.

**Page 2, Sector Momentum.** A line chart of total funding by year for the six major sectors, answering question one. Sector funding leadership shifts every year rather than one category dominating. E-commerce peaked in 2017 at nearly 6 billion dollars, the single highest point on the chart, while Transportation stayed flat for years before spiking alone to about 4 billion dollars in 2019. That isolated, single year spike, with no momentum before or after, is a mega round effect rather than sustained sector growth, unlike the steadier multi year climb seen in Consumer Internet through 2016 and 2017.

**Page 3, Broad Activity vs. Concentrated Bets.** A scatter plot of deal count against total funding per sector, answering question two. E-commerce is the true funding leader overall, with nearly 8 billion dollars raised through a moderate 299 deals. Consumer Internet is the most accessible market by far, spreading about 6.25 billion dollars across roughly 942 deals at a fraction of the average check size, around 664 thousand dollars per deal. Transportation sits at the opposite extreme, with about 4 billion dollars concentrated into just 8 deals at an average of roughly 509 million dollars each, a market controlled by a handful of gatekeepers rather than one with room for many new entrants. Technology and HealthTech sit in the middle on both dimensions.

**Page 4, City Opportunity Map.** A matrix of deal count by city and sector across the top eight cities, answering question three. Bengaluru dominates overall activity, with 588 of 1,703 deals across these eight cities, driven mainly by Consumer Internet and Technology. Sector concentration reveals a sharper gap, though. All six Transportation deals in this dataset sit in just Bengaluru and Gurugram, while Mumbai and New Delhi, despite ranking second and third in total deal volume with 358 and 258 deals, show zero Transportation funding. For a VC targeting Transportation, this signals either genuine whitespace in India's other major hubs, or that Transportation capital simply has not reached them yet, a gap worth investigating before assuming national saturation.

## Key Insights

- Sector funding leadership changes year to year. Consumer Internet led 2016, E-commerce peaked in 2017, and Transportation spiked alone in 2019. The 2019 lead is a mega round effect, not sustained momentum.
- Total capital raised can look similar across sectors while the underlying deal structure is completely different. E-commerce and Consumer Internet both raised roughly similar totals to Transportation, but through very different numbers of deals, which means a new entrant faces very different competitive dynamics depending on which sector they target.
- About 32 percent of deals have no disclosed funding amount, and non disclosure rates vary by funding stage, which is relevant context for reading any "total funding" figure at face value.
- City level deal activity does not always line up with sector level capital access. Mumbai and New Delhi are the second and third busiest cities overall but have no recorded Transportation deals at all, while that same sector clusters entirely in Bengaluru and Gurugram.

## Project Status

- Business problem defined
- Data cleaning in Python and pandas, notebook verified to run end to end with zero errors
- SQL business question analysis, all 14 queries verified against the cleaned database
- Four page Power BI dashboard, one page per business question plus an overview

## How to Reproduce

1. Clone this repo.
2. Open `Startup_Funding_Cleaning_Beginner.ipynb` and run all cells. This regenerates `clean_startup_funding.csv`.
3. Load `clean_startup_funding.csv` into `startup_funding.db`, SQLite, or your own database.
4. Run `startup_funding_sql_queries.sql`.
5. Open `startup_funding_dashboard.pbix` in Power BI Desktop.

## Known Limitations

- Sector cleaning only merges exact spelling and casing variants of major categories. The long tail of niche categories is not further grouped, see Data Cleaning Highlights above.
- 2018 through 2020 has far fewer records than 2015 through 2017, which likely reflects gaps in how the source dataset was compiled rather than an actual funding slowdown. Year over year comparisons across that boundary should be read with caution.
- `investors_name` can list multiple comma separated investors per deal, so investor level counts reflect row mentions, not unique co-investment structures.
- The city and sector filters used across the dashboard focus on the top 6 to 8 values by activity, so smaller cities and niche sectors are not represented in the charts, though they remain in the underlying data.

## Author

Jeet Makhija, [LinkedIn](https://linkedin.com/in/jeet-makhija), [GitHub](https://github.com/jeet-43)
