pins: Pin, Discover and Share Resources
================

<!-- badges: start -->

[![R-CMD-check](https://github.com/rstudio/pins/workflows/R-CMD-check/badge.svg)](https://github.com/rstudio/pins/actions)
[![CRAN
Status](https://www.r-pkg.org/badges/version/pins)](https://cran.r-project.org/package=pins)
[![Codecov test
coverage](https://codecov.io/gh/rstudio/pins/branch/master/graph/badge.svg)](https://codecov.io/gh/rstudio/pins?branch=master)
<!-- badges: end -->

## Overview

<img src="man/figures/logo.png" align="right" width="130px"/>

You can use the `pins` package to:

-   **Pin** remote resources locally with `pin()`, work offline and
    cache results.
-   **Discover** new resources across different boards using
    `pin_find()`.
-   **Share** resources in local folders, with RStudio Connect, on S3,
    and more.

## Installation

``` r
# Install the released version from CRAN:
install.packages("pins")
```

To get a bug fix, or use a feature from the development version, you can
install pins from GitHub.

``` r
# install.packages("remotes")
remotes::install_github("rstudio/pins")
```

## Usage

``` r
library(pins)
```

### Pin

There are two main ways to pin a resource:

-   Pin a remote file with `pin(url)`. This will download the file and
    make it available in a local cache:

    ``` r
    url <- "https://raw.githubusercontent.com/facebook/prophet/master/examples/example_retail_sales.csv"
    retail_sales <- read.csv(pin(url))
    ```

    This makes subsequent uses much faster and allows you to work
    offline. If the resource changes, `pin()` will automatically
    re-download it; if goes away, `pin()` will keep the local cache.

-   Pin an expensive local computation with `pin(object, name)`:

    ``` r
    library(dplyr)
    retail_sales %>%
      group_by(month = lubridate::month(ds, T)) %>%
      summarise(total = sum(y)) %>%
      pin("sales_by_month")
    ```

    Then later retrieve it with `pin_get(name)`.

    ``` r
    pin_get("sales_by_month")
    #> # A tibble: 12 x 2
    #>    month   total
    #>    <ord>   <int>
    #>  1 Jan   6896303
    #>  2 Feb   6890866
    #>  3 Mar   7800074
    #>  4 Apr   7680417
    #>  5 May   8109219
    #>  6 Jun   7451431
    #>  7 Jul   7470947
    #>  8 Aug   7639700
    #>  9 Sep   7130241
    #> 10 Oct   7363820
    #> 11 Nov   7438702
    #> 12 Dec   8656874
    ```

### Discover

You can also discover remote resources using `pin_find()` which searches
any registered boards. For instance, we can search datasets mentioning
“air” in installed packages with:

``` r
pin_find("air", board = "packages")
#> # A tibble: 4 x 6
#>   name             description                           cols  rows class board 
#>   <chr>            <chr>                                <int> <int> <chr> <chr> 
#> 1 datasets/airmil… Passenger Miles on Commercial US Ai…    NA    NA <NA>  packa…
#> 2 datasets/AirPas… Monthly Airline Passenger Numbers 1…    NA    NA <NA>  packa…
#> 3 datasets/airqua… New York Air Quality Measurements       NA    NA <NA>  packa…
#> 4 datasets/HairEy… Hair and Eye Color of Statistics St…    NA    NA <NA>  packa…
```

Notice that the full name of a pin is `<owner>/<name>`. This namespacing
allows multiple people (or packages) to create pins with the same name.

You can then retrieve a pin through `pin_get()`:

``` r
airmiles <- pin_get("datasets/airmiles", board = "packages")
```

### Share

You can share resources with others by publishing to:

-   Shared folders, `board_local()`.
-   GitHub, `board_github()`.
-   RStudio Connect, `board_rsconnect()`
-   Azure, `board_azure()`
-   S3, `board_s3()`

Learn more in `vignette("boards-understanding")`

### RStudio

Experimental support for `pins` was introduced in RStudio Connect 1.7.8
so that you can use [RStudio](https://rstudio.com/products/rstudio/) and
[RStudio Connect](https://rstudio.com/products/connect/) to discover and
share resources within your organization with ease. To enable new
boards, use [RStudio’s Data
Connections](https://blog.rstudio.com/2017/08/16/rstudio-preview-connections/)
to start a new ‘pins’ connection and then select which board to connect
to:

<center>
<img src="tools/readme/rstudio-connect-board.png" width="70%">
</center>

Once connected, you can use the connections pane to track the pins you
own and preview them with ease. Notice that one connection is created
for each board.

<center>
<img src="tools/readme/rstudio-explore-pins.png" width="50%">
</center>

To **discover** remote resources, simply expand the “Addins” menu and
select “Find Pin” from the dropdown. This addin allows you to search for
pins across all boards, or scope your search to particular ones as well:

<center>
<img src="tools/readme/rstudio-discover-pins.png" width="60%">
</center>

You can then **share** local resources using the RStudio Connect board.
Lets use `dplyr` and the `hpiR_seattle_sales` pin to analyze this
further and then pin our results in RStudio Connect.

``` r
board <- board_rsconnect()

seattle_sales %>%
  group_by(baths = ceiling(baths)) %>%
  summarise(sale = floor(mean(sale_price))) %>%
  pin("sales-by-baths", board = board)
```

After a pin is published, you can then browse to the pin’s content from
the RStudio Connect web interface.

<center>
<img src="tools/readme/rstudio-share-resources.png" width="90%">
</center>

You can now set the appropriate permissions in RStudio Connect, and
voila! From now on, those with access can make use of this remote file
locally!

For instance, a colleague can reuse the `sales-by-baths` pin by
retrieving it from RStudio Connect and visualize its contents using
ggplot2:

``` r
library(ggplot2)
board <- board_rsconnect()

pin_get("sales-by-baths", board = board) %>%
  ggplot(aes(x = baths, y = sale)) +
  geom_point() + 
  geom_smooth(method = 'lm', formula = y ~ exp(x))
```

Pins can also be automated using scheduled R Markdown. This makes it
much easier to create Shiny applications that rely on scheduled data
updates or to share prepared resources across multiple pieces of
content. You no longer have to fuss with file paths on RStudio Connect,
mysterious resource URLs, or redeploying application code just to update
a dataset!
