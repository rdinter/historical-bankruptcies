---
output:
  html_document: default
  pdf_document: default
---

# Archived Bankruptcy Filing Data

(files were found via archive.org of the uscourts.gov website)

Main site archived in [May of 2005](https://web.archive.org/web/20050527002804/http://www.uscourts.gov:80/bnkrpctystats/statistics.htm). These are mostly the F-2 Tables, which has a default of twelve-month filings preceding. There are a few F-2: Three Tables, which would be quarterly level filings. Keep in mind that the Family Farmers Bankruptcy Act of 1986 was signed into law on 1986-10-27 and into effect on 1986-11-26. This would make the start of Chapter 12 for the quarter ending on 1986-12-31 and be the full value of 1986 Chapter 12.

Original files:

- Twelve-month period [ending on March 31](https://web.archive.org/web/20050903105140/http://www.uscourts.gov/bnkrpctystats/MarchBK1986-2003.pdf) from 1986-03-31 until 2003-03-31.
- Twelve-month period [ending on June 30](https://web.archive.org/web/20050903104927/http://www.uscourts.gov/bnkrpctystats/1960-0312-MonthJune.pdf) from 1983-06-30 until 2002-06-30 (plus the quarter ending 2003-06-30 and national values for twelve-month period ending on June 30 since 1960).
- Twelve-month period [ending on September 30](https://web.archive.org/web/20050903105110/http://www.uscourts.gov/bnkrpctystats/FY1987-2003.pdf) from 1987-09-30 until 2003-09-30.
- Twelve-month period [ending on December 31](https://web.archive.org/web/20050527002804/http://www.uscourts.gov:80/bnkrpctystats/Bk2002-1990Calendar.pdf) from 1990-12-31 until 2002-12-31.

I have attempted to break these files apart so that each F-2 table is its own .pdf. The naming convention is adopted similar to [current files f2 and f2_three](https://github.com/rdinter/historical-bankruptcies/tree/master/0-data/uscourts) tables. The `f2_XXXX-YY-ZZ.pdf` naming convention indicates that an F-2 twelve-month table ending on the quarter of XXXX-YY-ZZ is contained in the .pdf. A F-2 three-month is referenced as `f2_three_XXXX-YY-ZZ.pdf`.

| Year | March  | June   | September | December |
|:----:|:------:|:------:|:---------:|:--------:|
| 1983 |        | twelve |           |          |
| 1984 |        | twelve |           |          |
| 1985 |        | twelve |           |          |
| 1986 | twelve | twelve |           |          |
| 1987 | twelve | twelve | twelve    |          |
| 1988 | twelve | twelve | twelve    |          |
| 1989 | twelve | twelve | twelve    |          |
| 1990 | twelve | twelve | twelve    | twelve   |
| 1991 | twelve | twelve | twelve    | twelve   |
| 1992 | twelve | twelve | twelve    | twelve   |
| 1993 | twelve, missing 11th Circuit | twelve | twelve    | twelve   |
| 1994 | twelve | twelve | twelve    | twelve   |
| 1995 | twelve | twelve | twelve    | both     |
| 1996 | both   | both | both    | both   |
| 1997 | both   | both | both    | both   |
| 1998 | both   | both | both    | both   |
| 1999 | both   | both | both    | both   |
| 2000 | both   | both | both    | both   |
| 2001 | both   | both | both, missing 10th and 11th Circuit in twelve    | both   |
| 2002 | both   | both | both    | both   |
| 2003 | both   | both | both    | both   |

(We already have these beginning on 2001-03-31 from currently active USCourts.gov, but it's still a nice double-check)

In addition, there are explicit quarterly level files which appears to be what PACER charges over \$600 for plus some more.

* [Quarterly files](https://web.archive.org/web/20050903105023/http://www.uscourts.gov/bnkrpctystats/3Mos1995-2001.pdf) from quarter ending 1995-12-31 until 2001-12-31.

# Backsolving Quarterly Data

At this point, this becomes a recursive problem in attempting to determine the quarterly values prior to 1995-09-30. Let's start this off with realizing what is entailed in each 12-month file (the subscript A refers to 12-month files while the subscript Q refers to the quarterly version of the data):

$$ {March}_{t, A} = {March}_{t, Q} + {December}_{t-1, Q} + {September}_{t-1, Q} + {June}_{t-1, Q} $$
$$ {June}_{t, A} = {June}_{t, Q} + {March}_{t, Q} + {December}_{t-1, Q} + {September}_{t-1, Q} $$
$$ {September}_{t, A} = {September}_{t, Q} + {June}_{t, Q} + {March}_{t, Q} + {December}_{t-1, Q} $$
$$ {December}_{t, A} = {December}_{t, Q} + {September}_{t, Q} + {June}_{t, Q} + {March}_{t, Q} $$

We now have a system of equations and we mostly have all of the 12-month values going back until 1989-12-31, our first missing values. Knowing that we are first missing 1995-09-30, that is our first value we want to solve for, which can be done as such:

$$ {September}_{1995, Q} = {June}_{1996, A} - {June}_{1996, Q} - {March}_{1996, Q} - {December}_{1995, Q} $$

We now know the value for 1995-09-30, we can use this in order to solve for 1995-06-30 and continue recursively for each of the other quarters in this generalized fashion (rearranging the above equations):

$$ {June}_{t-1, Q} = {March}_{t, A} - {December}_{t-1, Q} - {September}_{t-1, Q} - {March}_{t, Q} $$
$$ {March}_{t, Q} = {December}_{t, A} - {December}_{t, Q} - {September}_{t, Q} - {June}_{t, Q} +  $$
$$ {December}_{t-1, Q} = {September}_{t, A} - {September}_{t, Q} - {June}_{t, Q} - {March}_{t, Q} $$
$$ {September}_{t-1, Q} = {June}_{t, A} - {June}_{t, Q} - {March}_{t, Q} - {December}_{t-1, Q} $$

Which will continue going until we run into the 11th Circuit issues in 1993-03-31, which compromises the ability to figure out quarterly values for the 11th Circuit. Then there is an abrupt stop in 1989-12-31 due to missing the 12-month value.

We can alternatively start from the beginning of our data to build up on each other. For instance, we know that the quarter ending in 1986-12-31 was the first instance of Chapter 12 although the Chapter was not officially available until 1986-11-26. Effectively, the 1986-12-31 filing quarter can be simply lumped into the 1987-03-31 quarter and we move forward.

$$ {March}_{1987, A} = {March}_{1987, Q} $$
$$ {June}_{1987, A} = {June}_{1987, Q} + {March}_{1987, Q} $$
$$ {September}_{1987, A} = {September}_{1987, Q} + {June}_{1987, Q} + {March}_{1987, Q} $$
$$ {December}_{1987, A} = {December}_{1987, Q} + {September}_{1987, Q} + {June}_{1987, Q} + {March}_{1987, Q} $$

The 1987-12-31 twelve-month filings missing in our data, which makes the quarter of 1987-12-31 unidentified and thus leads to the following values also unidentified:

$$ {March}_{1988, A} = {March}_{1988, Q} + \hat{December}_{1987, Q} + {September}_{1987, Q} + {June}_{1987, Q} $$
$$ {June}_{1988, A} = {June}_{1988, Q} + {March}_{1988, Q} + \hat{December}_{1987, Q} + {September}_{1987, Q} $$
$$ {September}_{1988, A} = {September}_{1988, Q} + {June}_{1988, Q} + {March}_{1988, Q} + \hat{December}_{1987, Q} $$

