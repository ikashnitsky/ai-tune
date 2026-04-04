---
title: "Arranging subplots with ggplot2"
date: "2017-05-22"
image: teaser.png
categories: [r, ggplot2]
---

***

For [my recently published paper][gen], I produced not-so-standard figures that show the two step decomposition used in the analysis. Have a look:

![](fig-01.png)
**Figure 3 from my paper ([PDF][pdf])**

Actually, `ggplot2` is a very powerful and flexible tool that allows to draw figures with quite a complex layout. Today I want to show the code that aligns six square plots (actually, maps) just as in the figure above. And it's all about the handy function `ggplot2::annotation_custom()`. Since I used the layout more than once, I wrapped the code that produced it into a function that takes a list of 6 square plots as an input and yields the arranged figure with arrows as an output. Here is the commented code of the function.

```{r, eval=FALSE}
align_six_plots <- function(list.plots,
                                    family = "",
                                    labels=LETTERS[1:6],
                                    labels.size=8){

        require(tidyverse)
        require(gridExtra)

        gg <- ggplot()+
                coord_equal(xlim = c(0, 21), ylim = c(0, 30), expand = c(0,0))+

                annotation_custom(ggplotGrob(list.plots[[1]]),
                                  xmin = 0.5, xmax = 8.5, ymin = 21, ymax = 29)+

                annotation_custom(ggplotGrob(list.plots[[2]]),
                                  xmin = 12.5, xmax = 20.5, ymin = 19.5, ymax = 27.5)+
                annotation_custom(ggplotGrob(list.plots[[3]]),
                                  xmin = 12.5,xmax = 20.5,ymin = 10.5,ymax = 18.5)+

                annotation_custom(ggplotGrob(list.plots[[4]]),
                                  xmin = 0.5, xmax = 8.5, ymin = 9,ymax = 17)+
                annotation_custom(ggplotGrob(list.plots[[5]]),
                                  xmin = 0.5, xmax = 8.5, ymin = 0, ymax = 8)+
                annotation_custom(ggplotGrob(list.plots[[6]]),
                                  xmin = 12.5,xmax = 20.5, ymin = 0, ymax = 8)+

                labs(x = NULL, y = NULL)+
                theme_void()

        # DF with the coordinates of the 5 arrows
        df.arrows <- data.frame(id=1:5,
                                x=c(8.5,8.5,12.5,12.5,12.5),
                                y=c(21,21,10.5,10.5,10.5),
                                xend=c(12.5,12.5,8.5,8.5,12.5),
                                yend=c(20.5,17.5,10,7,7))

        # add arrows
        gg <- gg +
                geom_curve(data = df.arrows |> filter(id==1),
                           aes(x=x,y=y,xend=xend,yend=yend),
                           curvature = 0.1,
                           arrow = arrow(type="closed",length = unit(0.25,"cm"))) +
                geom_curve(data = df.arrows |> filter(id==2),
                           aes(x=x,y=y,xend=xend,yend=yend),
                           curvature = -0.1,
                           arrow = arrow(type="closed",length = unit(0.25,"cm"))) +
                geom_curve(data = df.arrows |> filter(id==3),
                           aes(x=x,y=y,xend=xend,yend=yend),
                           curvature = -0.15,
                           arrow = arrow(type="closed",length = unit(0.25,"cm"))) +
                geom_curve(data = df.arrows |> filter(id==4),
                           aes(x=x,y=y,xend=xend,yend=yend),
                           curvature = 0,
                           arrow = arrow(type="closed",length = unit(0.25,"cm"))) +
                geom_curve(data = df.arrows |> filter(id==5),
                           aes(x=x,y=y,xend=xend,yend=yend),
                           curvature = 0.3,
                           arrow = arrow(type="closed",length = unit(0.25,"cm")))

        # add labes
        gg <- gg + annotate('text',label = labels,
                            x=c(.5,12.5,12.5,.5,.5,12.5)+.5,
                            y=c(29,27.5,18.5,17,8,8)+.1,
                            size=labels.size,hjust=0, vjust=0, family = family)

        return(gg)
}
```

Let's check, if the function works. For that I create just a blank plot, clone it six times, store the six plots in a list, and finally feed it to the function.

```{r, eval=FALSE}
library(tidyverse)
library(ggthemes)

# create a simple blank square plot
p <- ggplot()+
  expand_limits(x = c(0,1), y = c(0,1))+
  theme_map()+
  theme(panel.border = element_rect(color = "black", size = 0.5, fill = NA),
        aspect.ratio = 1)

# clone this plot six times and store as a list of six
plots <- mget(rep("p", 6))

# use the function on the list
six <- align_six_plots(plots)

# save the output
ggsave("six_square_plots_aligned.png", six, width=12, height=18)
```

![](fig-02.png)

Just what we wanted to get.

***

::: {.callout-tip}
# To reproduce all the actual results and figures from [my paper][gen], have a look at this github [repo][git]
:::

[gen]: https://doi.org/10.1186/s41118-017-0018-2
[pdf]: https://ikashnitsky.github.io/doc/pubs/1705-genus-ik.pdf
[git]: https://github.com/ikashnitsky/genus-2017
---
title: "Colorcoded map: regional population structures at a glance"
date: "2017-06-30"
image: teaser.png
categories: [r, ggplot2, rspatial, dataviz, demography]
---

***

Data visualization is quite often a struggle to represent multiple relevant dimensions preserving the readability of the plot. In this post I will show my recent multidimensional dataviz prepared for [Rostock Retreat Visualization][retreat], an event that gathered demographers for an amazing "three days long coffebreak".

European population is rapidly ageing. But the process is not happening uniformly in all parts of Europe (see [my recent paper][gen] for more info). Regions differ quite a lot: Eastern Europe still undergoes demographic dividend; Southern European regions form a cluster of lowest-low fertility; Western Europe experiences the greying of the baby boomers; urban regions attract young professionals and force out young parents; peripheral rural regions lose their youths forever... How can we grasp all the differences at a glance?

Here I want to present a colorcoded map. For each NUTS-3 region the unique color is produced by mixing red, green, and blue color spectrums in the proportions that reflect,correspondingly, relative shares of elderly populating (aged 65+), population at working ages (15-64), and kids (0-14).

![](fig-01.png)

Each of the three variables mapped here is scaled between 0 and 1: otherwise, the map would be just green with slightly variations in tones because the share of working age population is ranged between 65-75% for modern European regions. Thus, it is important to note that this map is not meant to be able to inform the reader of the exact population structure in a specific region. Rather, it provides a snapshot of all the regional population structures, facilitating comparisons between them. So, by design, the colors are only meaningful in comparison only for the given set of regions in a given year, in this case 2015. If we want cross-year comparisons, the variables are to be scaled across the whole timeseries, meaning that each separate map would, most likely, become less contrast.

In the map we can easily spot the major differences between subregions of Europe. Turkey is still having relatively high fertility, especially in the south-eastern Kurdish part, thus it has higher share of kids and it's colored in blueish tones. The high-fertility Ireland is also evidently blue in the map. East-European regions are green due to the still lasting demographic dividend. Southern Europe is ageing fastest, thus the colors are reddish.

We can also see most of the major capital regions that are bright-green as opposed to the depleted periphery. In some countries there are huge regional differences: Northern and Southern Italy, Eastern and Western Germany.

It is striking how clearly can we see the borders between European countries: Poland and Germany, Czech Republic and Slovakia, Portugal and Spain, France and all the neighbors. The slowly evolving population structures bare  imprints of unique populations' histories, that largely correspond with state borders.

The obvious drawback of the map is that it is not colorblind friendly, and there is no way to make it so because color is the main player in this dataviz.

***

::: {.callout-tip}
# To reproduce the map from the scratch please see [the gist][gist]
:::

[retreat]: https://twitter.com/RostockRetreat
[gen]: https://doi.org/10.1186/s41118-017-0018-2
[gist]: https://gist.github.com/ikashnitsky/c7bf13f6c716f65ddba3e52073793f3f
---
title: "Data acquisition in R (1/4)"
date: "2017-10-17"
image: teaser.png
categories: [r, tutorial, data acquisition]
---

***

::: {.callout-note}
# The series consists of four posts:
 - **Loading prepared datasets**
 - [Accessing popular statistical databases][two]
 - [Demographic data sources][three]
 - Getting spatial data
:::

For each of the data acquisition options I provide a small visualization use case.

# Built-in datasets

For illustration purposes, many R packages include data samples. Base R comes with a `datasets` package that offers a wide range of simple, sometimes very famous, datasets. Quite a detailed list of built-in datasets from various packages is [maintained by Vincent Arel-Bundock][list].

The nice feature of the datasets form `datasets` package is that they are "always there". The unique names of the datasets may be referred as the objects from Global Environment. Let's have a look at a beautiful small dataset calls `swiss` - Swiss Fertility and Socioeconomic Indicators (1888) Data. I am going to check visually the difference in fertility based of rurality and domination of Catholic population.

```{r, eval=FALSE}
library(tidyverse)

swiss |>
        ggplot(aes(x = Agriculture, y = Fertility,
                   color = Catholic > 50))+
        geom_point()+
        stat_ellipse()+
        theme_minimal(base_family = "mono")
```

![](swiss.png)

# Gapminder

Some packages are created specifically to disseminate datasets in a ready to use format. One of the nice examples is a package `gapminder` that contains a neat dataset widely used by Hans Rosling in his Gapminder project.

```{r, eval=FALSE}
library(tidyverse)
library(gapminder)

gapminder |>
        ggplot(aes(x = year, y = lifeExp,
                   color = continent))+
        geom_jitter(size = 1, alpha = .2, width = .75)+
        stat_summary(geom = "path", fun.y = mean, size = 1)+
        theme_minimal(base_family = "mono")
```

![](gapminder.png)

# Grab a dataset by URL

If a dataset is hosted online and has a direct link to the file, it can be easily imported into the R session just specifying the URL. For illustration, I will access `Galton` dataset from `HistData` package using a direct link from [Vincent Arel-Bundock's list][list].

```{r, eval=FALSE}
library(tidyverse)

galton <- read_csv(
    "https://raw.githubusercontent.com/vincentarelbundock/Rdatasets/master/csv/HistData/Galton.csv"
)

galton |>
        ggplot(aes(x = father, y = height))+
        geom_point(alpha = .2)+
        stat_smooth(method = "lm")+
        theme_minimal(base_family = "mono")
```

![](galton.png)

# Download and unzip an archive

Quite often datasets are stored in archived from. With R it is very simple to download and unzip the desired data archives. As an example, I will download [Historical New York City Crime Data][ny] provided by the Government of the Sate of New York and hosted at data.gov portal. The logic of the process is: first, we create a directory for the unzipped data; second, we download the archive; finally, unzip the archive and read the data.

```{r, eval=FALSE}
library(tidyverse)
library(readxl)

# create a directory for the unzipped data
ifelse(!dir.exists("unzipped"), dir.create("unzipped"), "Directory already exists")

# specify the URL of the archive
url_zip <- "http://www.nyc.gov/html/nypd/downloads/zip/analysis_and_planning/citywide_historical_crime_data_archive.zip"

# storing the archive in a temporary file
f <- tempfile()
download.file(url_zip, destfile = f)
unzip(f, exdir = "unzipped/.")
```

If the zipped file is rather big and we don't want to download it again the next time we run the code, it might be useful to keep the archived data.

```{r, eval=FALSE}
# if we want to keep the .zip file
path_unzip <- "unzipped/data_archive.zip"
ifelse(!file.exists(path_unzip),
       download.file(url_zip, path_unzip, mode="wb"),
       'file alredy exists')
unzip(path_unzip, exdir = "unzipped/.")

```

Finally, let's read and plot some of the downloaded data.

```{r, eval=FALSE}
murder <- read_xls(
    "unzipped/Web Data 2010-2011/Seven Major Felony Offenses 2000 - 2011.xls",
    sheet = 1, range = "A5:M13"
) |>
        filter(OFFENSE |> substr(1, 6) == "MURDER") |>
        gather("year", "value", 2:13) |>
        mutate(year = year |> as.numeric())

murder |>
        ggplot(aes(year, value))+
        geom_point()+
        stat_smooth(method = "lm")+
        theme_minimal(base_family = "mono")+
        labs(title = "Murders in New York")
```

![](new-york.png)

# Figshare

In Academia it is becoming more and more popular to store the datasets accompanying papers in the specialized repositories. Figshare is one of the most popular free repositories. There is an R package `rfigshare` to access the datasets from this portal. As an example I will grab [the dataset on ice-hockey playes height][figshare] that I assembled manually for [my blog post][ice]. Please note that at the first run the package will ask to enter your Figshare login details to access API - a web page will be opened in browser.

There is a search function `fs_search`, though my experience shows that it is easier to search for a dataset in a browser and then use the id of a file to download it. The function `fs_download` turns an id number into a direct URL to download the file.

```{r, eval=FALSE}
library(tidyverse)
library(rfigshare)

url <- fs_download(article_id = "3394735")

hockey <- read_csv(url)

hockey |>
        ggplot(aes(x = year, y = height))+
        geom_jitter(size = 2, color = "#35978f", alpha = .1, width = .25)+
        stat_smooth(method = "lm", size = 1)+
        ylab("height, cm")+
        xlab("year of competition")+
        scale_x_continuous(
            breaks = seq(2005, 2015, 5), labels = seq(2005, 2015, 5)
        )+
        theme_minimal(base_family = "mono")
```

![](ice-hockey.png)

***

::: {.callout-tip}
# All the code chunks can be found in [this gist][gist]
:::

[two]: https://ikashnitsky.github.io/2017/data-acquisition-two
[three]: https://ikashnitsky.github.io/2017/data-acquisition-three
[odata]: https://github.com/ropensci/opendata
[list]: https://vincentarelbundock.github.io/Rdatasets/datasets.html
[ny]: https://catalog.data.gov/dataset/historical-new-york-city-crime-data-ad47e
[figshare]: https://dx.doi.org/10.6084/m9.figshare.3394735.v2
[ice]: https://ikashnitsky.github.io/2017/ice-hockey-players-height/
[gist]: https://gist.github.com/ikashnitsky/e1d93a51fe5e2b5ba770096060bacd8a
---
title: "Data acquisition in R (3/4)"
date: "2017-12-10"
image: teaser.png
categories: [r, tutorial, data acquisition]
---

***

::: {.callout-note}
# The series consists of four posts:
 - [Loading prepared datasets][one]
 - [Accessing popular statistical databases][two]
 - **Demographic data sources**
 - Getting spatial data
:::

For each of the data acquisition options I provide a small visualization use case.

# Human Mortality Database

When it comes to testing the big questions of human population dynamics, there is no more reliable data source than [Human Mortality Database][hmd]. This database is run by demographers who use state-of-the-art methodology to overcome issues in the data. As the result, the estimates are as precise as possible. Their [methods protocol][pro] is a masterpiece of demographic data processing. On the down side, the data of decent enough quality is available for only a bunch of countries. To explore the data I highly recommend [Human Mortality Database Explorer][exp] by [Jonas Schöley][jonas].

Thanks to [Tim Riffe][tim]’s `HMDHFDplus` package, one can now download HMD data with just a couple of lines of `R` code. Please note that an account at [mortality.org][hmd] is needed in order to download data. As one may guess from the package name, it also helps to grab data from equally brilliant [Human Fertility Database][hfd].

The following example is taken from my [earlier post][post] (and updated a bit). I think it illustrates nicely the power of automated data acquisition in `R`. Here I am going to download one year population population structures for both males and females for each single country of HMD. If you want to reproduce the result, beware that the script will download a couple of dozens megabits of data. Then I will calculate and visualize as small multiples sex ratios in all countries along age dimension. Sex ratios reflect the two basic regularities of human demographics: 1) there are always more boys being born; 2) males experience higher mortality throughout their life-course. Besides some artificial and well known exceptions, sex ratio at birth does not vary dramatically and is more or less constant at the level of 105-106 boys per 100 girls. Hence, differences in the sex ratio profiles of countries mainly reflect gender gap in mortality.

```{r, eval=FALSE}
# load required packages
library(HMDHFDplus)
library(tidyverse)
library(purrr)

# help function to list the available countries
country <- getHMDcountries()

# remove optional populations
opt_pop <- c("FRACNP", "DEUTE", "DEUTW", "GBRCENW", "GBR_NP")
country <- country[!country %in% opt_pop]

# temporary function to download HMD data for a simgle county (dot = input)
tempf_get_hmd <- . |> readHMDweb("Exposures_1x1", ik_user_hmd, ik_pass_hmd)

# download the data iteratively for all countries using purrr::map()
exposures <- country |> map(tempf_get_hmd)

# data transformation to apply to each county dataframe
tempf_trans_data <- . |>
        select(Year, Age, Female, Male) |>
        filter(Year %in% 2012) |>
        select(-Year) |>
        transmute(age = Age, ratio = Male / Female * 100)

# perform transformation
df_hmd <- exposures |>
        map(tempf_trans_data) |>
        bind_rows(.id = "country")

# summarize all ages older than 90 (too jerky)
df_hmd_90 <- df_hmd |>
        filter(age %in% 90:110) |>
        group_by(country) |>
        summarise(ratio = ratio |> mean(na.rm = T)) |>
        ungroup() |>
        transmute(country, age = 90, ratio)

# insert summarized 90+
df_hmd_fin <- bind_rows(df_hmd |> filter(!age %in% 90:110), df_hmd_90)

# finaly - plot
df_hmd_fin |>
        ggplot(aes(age, ratio, color = country, group = country))+
        geom_hline(yintercept = 100, color = "grey50", size = 1)+
        geom_line(size = 1)+
        scale_y_continuous(limits = c(0, 120),
                           expand = c(0, 0),
                           breaks = seq(0, 120, 20))+
        scale_x_continuous(limits = c(0, 90),
                           expand = c(0, 0),
                           breaks = seq(0, 80, 20))+
        facet_wrap(~country, ncol = 6)+
        theme_minimal(base_family = "mono", base_size = 15)+
        theme(legend.position = "none",
              panel.border = element_rect(size = .5, fill = NA,
                                          color = "grey50"))+
        labs(x = "Age",
             y = "Sex ratio, males per 100 females",
             title = "Sex ratio in all countries from Human Mortality Database",
             subtitle = "HMD 2012, via HMDHFDplus by @timriffe1",
             caption = "ikashnitsky.github.io")

```

![](hmd.png)

# United Nations World Population Prospects

Population Department of the United Nations provides high quality population estimates for all countries of the world. They update estimates every 2-3 years and publish openly as an interactive report [World Population Prospects][wpp]. One may find in these reports key highlights and, of course, rich data. The data is later wrapped in `R` packages called `wpp20xx`. Currently, the available packages are for the estimate updates 2008, 2010, 2012, 2015, and 2017. I will give here an example of `wpp2015` use adapted from my earlier [post][e0conv].

Using ridgeplot, the amazing type of dataviz promoted `ggridges` package by [Claus Wilke][wilke], I am going to show the impressive reduction of global inequality in male mortality that took place since 1950.

```{r, eval=FALSE}
library(wpp2015)
library(tidyverse)
library(ggridges)
library(viridis)

# get the UN country names
data(UNlocations)

countries <- UNlocations |> pull(name) |> paste

# data on male life expectancy at birth
data(e0M)

e0M |>
        filter(country %in% countries) |>
        select(-last.observed) |>
        gather(period, value, 3:15) |>
        ggplot(aes(x = value, y = period |> fct_rev()))+
        geom_density_ridges(aes(fill = period))+
        scale_fill_viridis(discrete = T, option = "B", direction = -1,
                           begin = .1, end = .9)+
        labs(x = "Male life expectancy at birth",
             y = "Period",
             title = "Global convergence in male life expectancy at birth since 1950",
             subtitle = "UNPD World Population Prospects 2015 Revision, via wpp2015",
             caption = "ikashnitsky.github.io")+
        theme_minimal(base_family =  "mono")+
        theme(legend.position = "none")

```

![](wpp2015.png)

# European Social Survey (ESS)

[European Social Survey][ess] provides uniquely rich nationally representative cross-county comparable information on the values of Europeans. Every two years a cross-sectional sample is taken in each participating country. All the data is easily available [upon registration][essreg]. Datasets are distributed as SAS, SPSS, or STATA files. Thanks to [Jorge Cimentada][jorge], these datasets are now easily available via `ess` package. I am going to visualize how respondents assessed their level of trust in police in all available countries at the latest round of the survey.

```{r, eval=FALSE}
library(ess)
library(tidyverse)

# help gunction to see the available countries
show_countries()

# check the available rounds for a selected country
show_country_rounds("Netherlands")

# get the full dataset of the last (8) round
df_ess <- ess_rounds(8, your_email =  ik_email)

# select a variable and calculate mean value
df_ess_select <- df_ess |>
        bind_rows() |>
        select(idno, cntry, trstplc) |>
        group_by(cntry) |>
        mutate(avg = trstplc |> mean(na.rm = T)) |>
        ungroup() |>
        mutate(cntry = cntry |> as_factor() |> fct_reorder(avg))

df_ess_select |>
        ggplot(aes(trstplc, fill = avg))+
        geom_histogram()+
        scale_x_continuous(limits = c(0, 11), breaks = seq(2, 10, 2))+
        scale_fill_gradient("Average\ntrust\nscore",
                            low = "black", high = "aquamarine")+
        facet_wrap(~cntry, ncol = 6)+
        theme_minimal(base_family = "mono")+
        labs(x = "Trust score [0 -- 10]",
             y = "# of respondents",
             title = "Trust in police",
             subtitle = "ESS wave 8 2017, via ess by @cimentadaj",
             caption = "ikashnitsky.github.io")

```

![](ess.png)

# American Community Survey and Census

There are several packages that provide access to the US Census and ACS data. Perhaps the most convenient one is the recent `tidycensus` package by [Kyle Walker][kyle]. One extremely useful feature of this approach is the ability to download geodata along with stats in the form of simple features. Simple features, a revolutionary approach to deal with spatial data in R implemented in `sf` package by [Edzer Pebesma][edz], allow to manage and visualize geodata tidy and efficiently. Note that in order to reproduce the following example one would have to install the development version of ggplot2.

Below I map median ages of census tracts population in Chicago based on the ACS estimates in 2015. To use `tidycensus`, an API key is required. API is instantly provided [upon registration][api].

```{r, eval=FALSE}
library(tidycensus)
library(tidyverse)
library(viridis)
library(janitor)
library(sf)
# to use geom_sf we need the latest development version of ggplot2
devtools::install_github("tidyverse/ggplot2", "develop")
library(ggplot2)

# you need a personal API key, available free at
# https://api.census.gov/data/key_signup.html
# normally, this key is to be stored in .Renviron

# see state and county codes and names
fips_codes |> View

# the available variables
load_variables(year = 2015, dataset = "acs5") |> View

# data on median age of population in Chicago
df_acs <- get_acs(
        geography = "tract",
        county = "Cook County",
        state = "IL",
        variables = "B01002_001E",
        year = 2015,
        key = ik_api_acs,
        geometry = TRUE
) |> clean_names()

# map the data
df_acs |>
        ggplot()+
        geom_sf(aes(fill = estimate |>
                            cut(breaks = seq(20, 60, 10))),
                color = NA)+
        scale_fill_viridis_d("Median age", begin = .4)+
        coord_sf(datum = NA)+
        theme_void(base_family =  "mono")+
        theme(legend.position = c(.15, .15))+
        labs(title = "Median age of population in Chicago\nby census tracts\n",
             subtitle = "ACS 2015, via tidycensus by @kyle_e_walker",
             caption = "ikashnitsky.github.io",
             x = NULL, y = NULL)
```

![](tidycensus.png)

***

::: {.callout-tip}
All the code chunks together can be found in [this gist][gist]
:::

[odata]: https://github.com/ropensci/opendata
[one]: https://ikashnitsky.github.io/2017/data-acquisition-one/
[two]: https://ikashnitsky.github.io/2017/data-acquisition-two
[hmd]: http://www.mortality.org
[tim]: https://twitter.com/timriffe1
[hfd]: http://www.humanfertility.org/
[pro]: http://www.mortality.org/Public/Docs/MethodsProtocol.pdf
[jonas]: https://twitter.com/jschoeley
[tim]: https://twitter.com/timriffe1
[post]: https://ikashnitsky.github.io/2017/hmd-all-sex-ratio/
[wpp]: https://esa.un.org/unpd/wpp/
[e0conv]: https://ikashnitsky.github.io/2017/global-male-life-expectancy-convergence/
[wilke]: https://twitter.com/ClausWilke
[ess]: http://www.europeansocialsurvey.org/about/
[essreg]: http://www.europeansocialsurvey.org/user/new
[jorge]: https://twitter.com/cimentadaj
[kyle]: https://twitter.com/kyle_e_walker
[edz]: https://twitter.com/edzerpebesma
[api]: https://api.census.gov/data/key_signup.html

[gist]: https://gist.github.com/ikashnitsky/2e4bb16e097b1a264eeeae13ca6d7ce3
---
title: "Data acquisition in R (2/4)"
date: "2017-11-07"
image: teaser.png
categories: [r, tutorial, data acquisition]
---

***

::: {.callout-note}
# The series consists of four posts:
 - [Loading prepared datasets][one]
 - **Accessing popular statistical databases**
 - [Demographic data sources][three]
 - Getting spatial data
:::

For each of the data acquisition options I provide a small visualization use case.

# Eurostat

The package `eurostat` has a function `search_eurostat` to search for the relevant datasets. Though, sadly enough, this function does not provide the codes of all the datasets that has the expression of interest in the title. For example, the search on the expression `life expectancy` produces an output with just 2 results, which does not make any sense. Thus, the best strategy is to go to [Eurostat website][estat], find the needed dataset code, and fetch the desired dataset by its code. Note that there is a [separate database for subregional level indicators][esreg].

I am going to download life expectancy estimates for European countries; the dataset code is `demo_mlexpec`.

```{r, eval=FALSE}
library(tidyverse)
library(lubridate)
library(eurostat)

# download the selected dataset
e0 <- get_eurostat("demo_mlexpec")
```

It can take a while because the dataset is quite big (0.4m obs). If the automated procedure does not work, one can download the data manually via the [Bulk Download Service][bulk] of Eurostat.

Let's have a look at the remaining life expectancy at age 65, the most common conventional age at retirement, in some European countries, separately for males, females, and total population. Some data preparation steps are needed. First, we only need the life expectancy  estimates for those aged 65. Next, we don't need total population, only males and females separately. Finally, let's select just a bunch of countries: Germany, France, Italy, Russia, Spain, the UK.

```{r, eval=FALSE}
e0 |>
        filter(! sex == "T",
               age == "Y65",
               geo %in% c("DE", "FR", "IT", "RU", "ES", "UK")) |>
        ggplot(aes(x = time |> year(), y = values, color = sex))+
        geom_path()+
        facet_wrap(~ geo, ncol = 3)+
        labs(y = "Life expectancy at age 65", x = NULL)+
        theme_minimal(base_family = "mono")
```

![](eurostat.png)

# World Bank

There are several packages that provide an API to World Bank data. Probably, the most elaborated one is a fairly recent [`wbstats`][wbstats]. Its `wbsearch` function really does great job searching through the database for the relevant datasets. For example, `wbsearch("fertility")` produces a dataframe of 339 entries with the codes and names of the relevant indicators.

```{r, eval=FALSE}
library(tidyverse)
library(wbstats)

# search for a dataset of interest
wbsearch("fertility") |> head
```

|     |indicatorID    |indicator                                                    |
|:----|:--------------|:------------------------------------------------------------|
|2479 |SP.DYN.WFRT.Q5 |Total wanted fertility rate (births per woman): Q5 (highest) |
|2480 |SP.DYN.WFRT.Q4 |Total wanted fertility rate (births per woman): Q4           |
|2481 |SP.DYN.WFRT.Q3 |Total wanted fertility rate (births per woman): Q3           |
|2482 |SP.DYN.WFRT.Q2 |Total wanted fertility rate (births per woman): Q2           |
|2483 |SP.DYN.WFRT.Q1 |Total wanted fertility rate (births per woman): Q1 (lowest)  |
|2484 |SP.DYN.WFRT    |Wanted fertility rate (births per woman)                     |

Let's have a look at the indicator `Lifetime risk of maternal death (%)` (code `SH.MMR.RISK.ZS`). World Bank provides a variety of country groupings. One of the curious groupings divides countries based on the advance over the Demographic Transition path. Below I plot our selected indicator for (1) the countries that have passed the Demographic Transition, (2) the countries that haven't yet experienced demographic dividend, and (3) the whole World.

```{r, eval=FALSE}
# fetch the selected dataset
df_wb <- wb(indicator = "SH.MMR.RISK.ZS", startdate = 2000, enddate = 2015)

# have look at the data for one year
df_wb |> filter(date == 2015) |> View

df_wb |>
        filter(iso2c %in% c("V4", "V1", "1W")) |>
        ggplot(aes(x = date |> as.numeric(), y = value, color = country))+
        geom_path(size = 1)+
        scale_color_brewer(NULL, palette = "Dark2")+
        labs(x = NULL, y = NULL, title = "Lifetime risk of maternal death (%)")+
        theme_minimal(base_family = "mono")+
        theme(panel.grid.minor = element_blank(),
              legend.position = c(.8, .9))

```

![](worldbank.png)

# OECD

Organization for Economic Cooperation and Development provides detailed economic and demographic data on the member countries. There is an R package `OECD` that streamlines the use of their data in R. The function `search_dataset` works nicely to browse the available datasets by keywords. Then `get_dataset` would fetch the chosen dataset. In the example below I grab the data on the duration of unemployment and then plot the data for the male population of EU16, EU28 and the US as heatmaps.

```{r, eval=FALSE}
library(tidyverse)
library(viridis)
library(OECD)

# search by keyword
search_dataset("unemployment") |> View

# download the selected dataset
df_oecd <- get_dataset("AVD_DUR")

# turn variable names to lowercase
names(df_oecd) <- names(df_oecd) |> tolower()

df_oecd |>
        filter(
            country %in% c("EU16", "EU28", "USA"), sex == "MEN", ! age == "1524"
        ) |>
        ggplot(aes(obstime, age, fill = obsvalue))+
        geom_tile()+
        scale_fill_viridis("Months", option = "B")+
        scale_x_discrete(breaks = seq(1970, 2015, 5) |> paste)+
        facet_wrap(~ country, ncol = 1)+
        labs(x = NULL, y = "Age groups",
             title = "Average duration of unemployment in months, males")+
        theme_minimal(base_family = "mono")
```

![](oecd.png)

# WID

[World Wealth and Income Database][wid] is a harmonized dataset on income and wealth inequality. The developers of the database provide an R package to get their data, which is only [available from github][widr] so far.

```{r, eval=FALSE}
library(tidyverse)

#install.packages("devtools")
devtools::install_github("WIDworld/wid-r-tool")
library(wid)
```

The function to acquire data is `download_wid()`. To specify the arguments, one would have to consult help pages of the package and select desired datasets.

```{r, eval=FALSE}
?wid_series_type
?wid_concepts
```

The following nice example is adapted from [the package vignette][vig]. It shows the share of wealth that was owned by the richest 1% and 10% of population in France and Great Britain.

```{r, eval=FALSE}
df_wid <- download_wid(
        indicators = "shweal", # Shares of personal wealth
        areas = c("FR", "GB"), # In France an Italy
        perc = c("p90p100", "p99p100") # Top 1% and top 10%
)

df_wid |>
        ggplot(aes(x = year, y = value, color = country)) +
        geom_path()+
        labs(
            title = "Top 1% and top 10% personal wealth shares in
            France and Great Britain",
             y = "top share"
        )+
        facet_wrap(~ percentile)+
        theme_minimal(base_family = "mono")

```

![](wid.png)

***

::: {.callout-tip}
# All the code chunks together can be found in [this gist][gist]
:::

[odata]: https://github.com/ropensci/opendata
[one]: https://ikashnitsky.github.io/2017/data-acquisition-one/
[three]: https://ikashnitsky.github.io/2017/data-acquisition-three
[estat]: http://ec.europa.eu/eurostat/data/database
[esreg]: http://ec.europa.eu/eurostat/web/regions/data/database
[bulk]: http://ec.europa.eu/eurostat/estat-navtree-portlet-prod/BulkDownloadListing
[wbstats]: https://cran.r-project.org/web/packages/wbstats/README.html
[wid]: http://wid.world/wid-world/
[widr]: https://github.com/WIDworld/wid-r-tool
[vig]: https://github.com/WIDworld/wid-r-tool/raw/master/inst/doc/wid-demo.pdf
[gist]: https://gist.github.com/ikashnitsky/2362ce308f47ff38c3da556384acd20f
---
title: "30 issues of Demographic Digest - the most frequent journals"
date: "2017-02-14"
image: teaser.png
categories: [r, demography, bibliometrics]
---

***

This week, the 30-th issue of my Demographic Digest [was published](http://demoscope.ru/weekly/2017/0715/digest01.php).

[Demographic Digest](/dd) is my project that started in November 2015. Twice a month I select fresh demographic papers and write brief summaries of them in Russian to be published in [Demoscope Weekly](http://demoscope.ru), the most popular Russian journal/website in social sciences. If you read Russian, you may want to browse [the archive](http://demoscope.ru/weekly/arc/arcdigest.php) or visit [the website](https://ikashnitsky.github.io/dem-digest/) of the project (which is still to be filled).

The project is in the transitional phase now. Since 2016 Demographic Digest welcomes contributions from from external authors. In February 2017 I launched the [first iteration of a project](https://www.hse.ru/org/hse/pfair/199751652.html) for the students of National Research University Higher School of Economics.

To draw a line after the first phase of the project, I analysed what journals supplied Demographic Digest most frequently. Also, my desire was to try visualizing data with treemaps, which I mentioned in the bonus part[^1] of [the latest digest issue](http://demoscope.ru/weekly/2017/0715/digest03.php).

For that, I exported the bibliographic data of all the papers covered in Demographic Digest. I use [Zotero](https://www.zotero.org) as a reference manager; the paper records are exported as a single .bib file, which I then saved as a [plain text (.txt) file](/share/1702-dd-stats/dd-bib.txt). Then I read this data in R, cleaned it, and finally visualized.


```{r, eval=FALSE}
# load required packages
library(tidyverse)
library(stringr)
library(readxl)
library(extrafont)
myfont <- "Roboto Condensed"

df <- data.frame(
    lines = readLines("https://ikashnitsky.github.io/share/1702-dd-stats/dd-bib.txt")
) |>
        mutate(lines = lines |> as.character()) |>

        # grab only the lines that contain journals' titles
        filter(lines |> str_detect("journaltitle")) |>

        # remove everything that is not the bare journal's title
        transmute(
            journals = lines |>
                       str_replace_all(
                            pattern = "\tjournaltitle = |\\Q{\\E|\\Q}\\E,|\\Q}\\E",
                            replacement = ""
                       )
        ) |>
        # calculate frequencies
        group_by(journals) |>
        summarise(n = n())
```

For one journal title, Ageing and Society, I failed to replace the "\&" using [regular expressions](https://www.rstudio.com/wp-content/uploads/2016/09/RegExCheatsheet.pdf). This one is to be fixed manually. I also corrected the title of Lancet journal removing the article "The". Finally, I corrected the frequencies for Population Studies and Population and Development Review subtracting 6, because for both journals I provided lists of most cited papers as a bonus. Following the same logic, I cleaned the data from the papers that appeared in the bonus part.

```{r, eval=FALSE}
# correct "Ageing and Society"
df[1,1] <- "Ageing and Society"

# correct the title of Lancet
df <- df |>
    mutate(journals = journals |> str_replace("The Lancet", "Lancet")) |>
    # correct "Population and Development Review" and "Population Studies" for 6 each
    # Reason - top cited papers bonus
    mutate(
        n = case_when(
            journals %in% c(
                "Population and Development Review",
                "Population Studies"
            ) ~ n - 6,
            TRUE ~ n
        )
    )
```

To provide some additional metrics of the journals, I downloaded bibliometric data from the [SCImago Journal & Country Rank project]()http://www.scimagojr.com/aboutus.php. Demographic journals usually have rather low SJR, compared to medical journals; that's why I downloaded the data only for journals in [Social Sciences](http://www.scimagojr.com/journalrank.php?area=3300) (the[.xlsx file](/doc/misc/dd-stats/scimagojr.xlsx)). Then I read the data in R and join to my data frame.

```{r, eval=FALSE}
# read SJR data for journals in Social Sciences
sjr <- readxl::read_excel(
    "https://ikashnitsky.github.io/share/1702-dd-stats/scimagojr.xlsx", 1
) |>
        mutate(id = Title |> tolower())

# join the data frames; note that I create an "id" variable in lower case
df_sjr <- left_join(df |> mutate(id = journals |> tolower), sjr, "id")
```

Finally, it's time to visualize the data. I use the amazing `treemap` package[^2].

```{r, eval=FALSE}
# Treemap visualization
library(treemap)

treemap(dtf = df_sjr,
        index = "journals",
        vSize = "n",
        vColor = "SJR",
        type = "value",
        n = 5,
        palette = "BrBG",
        border.col = "grey10",
        title = "Journals' frequency in Demographic Digest",
        title.legend = "SJR (only social sciences)",
        fontfamily.title = myfont,
        fontfamily.labels = myfont,
        fontfamily.legend = myfont,
        drop.unused.levels = T)
```

# Here is how the output looks

![](treemap-dd-stats.png)

Note that the lion's share of Population Studies is mainly explained by [the first issue of Demographic Digest](http://demoscope.ru/weekly/2015/0661/digest01.php), in which I covered all the papers from the brilliant special issue [Population — The long view](http://www.tandfonline.com/toc/rpst20/69/sup1).

***

[^1]: I finish each issue of Demographic Digest with a bonus, in which I cover fun papers, discuss some academia related issues, or just provide link to cool visualizations and projects.
[^2]: I also tried `portfolio` and `treemapify`, but liked the output from `treemap` most.


---
title: "R, GIS, and fuzzyjoin to reconstruct demographic data for NUTS regions of Denmark"
date: "2017-03-16"
image: teaser.png
categories: [r, rspatial]
---

***

NUTS stands for the [Nomenclature of Territorial Units For Statistics][nuts-overview]. The history of NUTS dates back to the beginning of 1970s, when European countries developed unified standards for systems of administrative geography. It was not until the beginning of this century when such a system finally became widely used. There are three main hierarchical levels of NUTS, and the most commonly used for regional analysis is NUTS-2.

![](fig-01-nuts.png){width="60%"}

**Figure 1. Illustration of the principle of NUTS hierarchical system**

One of the objectives of NUTS was to provide more or less comparable administrative divisions for all countries of Europe. Nevertheless, in 2013, population figures for single NUTS-2 regions ranged from 28.5 thousands in *Aland island* (Finland) to almost 12 million in *Ile-de-France* (Paris and surroundings, France).

# The broken time series

Quite arbitrary in its essence, territorial division tends to evolve. Changes in administrative boundaries can cause problems for regional analysis as they break the time series and therefore make it harder to analyze trends. Despite this inconvenience, the boundaries of regions actually change quite often based on the needs and interests of local or national governmenta. Eurostat [tracks all modifications][nuts-hist] providing detailed explanations of all the changes that happen between versions of NUTS (figure 2).

![](fig-02-nuts-changes.png)
**Figure 2. Changes in NUTS between versions 2006 and 2010**

Despite this, Eurostat does not recalculate historic demographic data to match the most recent NUTS version. This means that, for the most recent version of NUTS, there is missing data for all years before the latest administrative change. So researchers have to reconstruct historical data manually to obtain a long time series. Of course, crude assumptions often have to be accepted in order to approximate the population figures for the current regions that did not exist in the past.

To make thing even more complex, Eurostat provides the data only for the latest version of NUTS (at least, I did not work out how to download previous versions). In [my PhD project][phd] I carry out regional analysis for the NUTS-2 regions of European Union. To have the longest possible time series, when I did the data preparation in 2015, I chose the 2010 version of NUTS, on which the regional demographic projection [EUROPOP2013][proj] is based. For reproducibility, I uploaded the precise versions of the Eurostat data at NUTS-2 level on [population age structures][pop] and [deaths][deaths], as downloaded in 2015, to [figshare][figshare].

# Denmark

Some countries had to perform major changes in their systems of territorial division to fit the NUTS standards. [The most significant reform happened in Denmark in 2007][reform], where the former 271 municipalities were transformed into the new 98 municipalities. At the same time, NUTS was introduced, so that 98 municipalities were allocated to 11 NUTS-3 regions, which aggregate to 5 NUTS-2 regions. Typically, for a small country, there is only one NUTS-1 region in Denmark, which is the whole country.

As far as I know, there was no official attempt of Eurostat to reconstruct the time series for Denmark before 2007. The typical map of Eurostat for the pre-2007 period shows Denmark as “no data available” country (figure 3).

![](fig-03-nuts-2-life-exp.png)
**Figure 3. Life expectancy at birth in European NUTS-2 regions,  2006; a screenshot from the Eurostat's [interactive data exploratory tool][eurostat-map]**

Such a data loss is somewhat surprising for a country such as Denmark. It might be quite difficult to match the old and new municipal systems; but it should be relatively easy to re-aggregate the old municipalities into the new (higher level) NUTS regions. That is precisely what I did during my data preparation[^2] and what I now want to share in this post.

The task is basically to identify which of the old 271 municipalities are located within the modern 11 NUTS-3 regions and to aggregate the municipal data. Then, NUTS-3 data is easily aggregated for the NUTS-2 level. Such a task could have meant working late into the night, but luckily we live in the GIS era. I used GIS to match the old municipalities with the NUTS-3 regions. Here I want to show (with code) how the task can be performed using the amazing and opensource [R][cran]. Below I show the process of matching old municipalities to the NUTS regions and the process that I used to aggregate population data.

# Data

The data on the population age structures for the old 271 municipalities of Denmark was downloaded from the [official website of Statistics Denmark][stat-den]. The system only allows you to grab up to 10K cells for unregistered users and up to 100K for registered users. So the process of downloading the data involves some tedious manual manipulations. For the purpose of my phd project, I downloaded the data for the period 2001-2006; but, if needed, the data is available since 1979. The data, downloaded in 2015 and ‘tidied up’ can be found [here][data-mun-pop].

I have spent a lot of time trying to find geodata with the boundaries of the old municipalities. Now, coming back to the topic more than 1.5 year later, I failed to identify the original source of the shapefile, though I am pretty sure that it came from [here][aalborg] [^3]. The copy of the shapefile that I used can be found [here][geo-old].

Finally, we need a shapefile of NUTS-3 regions. It can be easily downloaded from [Eurostat geodata repository][eur-geo]. The shapefile that I used is "NUTS_2010_20M_SH.zip". The selection of the 11 Danish regions can be found [here][geo-dk].

The projection used for both shapefiles is [ESPG-3044][dk-prj], the one often used to map Denmark.

Now, the code to prepare the R session and load the data.

```{r, eval=FALSE}
# set locale and encoding parameters to read Danish
if(Sys.info()['sysname']=="Linux"){
        Sys.setlocale("LC_CTYPE", "da_DK.utf8")
        danish_ecnoding <- "WINDOWS-1252"
}else if(Sys.info()['sysname']=="Windows"){
        Sys.setlocale("LC_CTYPE", "danish")
        danish_ecnoding <- "Danish_Denmark.1252"
}

# load required packages (install first if needed)
library(tidyverse) # version: 1.0.0
library(ggthemes) # version: 3.3.0
library(rgdal) # version: 1.2-4
library(rgeos) # version: 0.3-21
library(RColorBrewer) # version: 1.1-2
mypal <- brewer.pal(11, "BrBG")
library(fuzzyjoin) # version: 0.1.2
library(viridis) # version: 0.3.4

# load Denmark pop structures for the old municipalities
df <- read_csv("https://ikashnitsky.github.io/share/1703-nuts2-denmark/BEF1A.csv.gz")

# create a directory for geodata
ifelse(!dir.exists("geodata"), dir.create("geodata"), "Directory already exists")

# download, unzip and read Danish NUTS-3 geodata (31KB)
url_nuts <-
    "https://ikashnitsky.github.io/share/1703-nuts2-denmark/denmark-nuts3-espg3044.tgz"
path_nuts <- "geodata/denmark-nuts3-espg3044.tgz"
ifelse(
    !file.exists(path_nuts),
    download.file(url_nuts, path_nuts, mode="wb"),
    'file alredy exists'
)
# If there are problems downloading the data automatically, please download it from
# https://ikashnitsky.github.io/share/1703-nuts2-denmark/denmark-nuts3-espg3044.tgz
untar(tarfile = path_nuts, exdir = "geodata")

sp_nuts3 <- readOGR(dsn = "geodata/.", layer = "denmark-nuts3-espg3044")
gd_nuts3 <- fortify(sp_nuts3, region = "NUTS_ID") # to the ggplot format

# download, unzip and read Danish old municipal geodata (6.0MB)
url_mun <-
    "https://ikashnitsky.github.io/share/1703-nuts2-denmark/kommune2006win1252.tgz"
path_mun <- "geodata/kommune2006win1252.tgz"
ifelse(
    !file.exists(path_mun),
    download.file(url_mun, path_mun, mode="wb"),
    'file alredy exists'
)
# If there are problems downloading the data automatically, please download it from
# https://ikashnitsky.github.io/share/1703-nuts2-denmark/kommune2006utf8.tgz
untar(tarfile = path_mun, exdir = "geodata")

sp_mun <- readOGR(
    dsn = "geodata/.", layer = "kommune2006win1252", encoding = danish_ecnoding
)
gd_mun <- fortify(sp_mun)

# coordinates of the municipalities
mun_coord <- bind_cols(as.data.frame(coordinates(sp_mun)), sp_mun@data[,1:3]) |>
        transmute(long = V1, lat = V2, enhedid, objectid, name = navn)
```

# Spatial matching

Let's first have a look at the map.

```{r, eval=FALSE}
ggplot()+
        geom_polygon(data = gd_nuts3, aes(long, lat, group = group),
                     color = brbg[3], fill = "grey90", size = 1)+
        geom_point(data = mun_coord, aes(long, lat),
                   color = brbg[10], size = 1)+
        theme_map()
```

![](fig-04-ref-map.png)
**Figure 4. Reference map of the old municipalities and NUTS-3 regions of Denmark**

We can easily see that the boundaries of the municipalities (light blue) are much more precise than that of the NUTS-3 regions (orange/brown). This is not a problem as long as all the centroids of the municipalities fall within the boundaries of the NUTS-3 regions, which seems to be true for all municipalities except for the easternmost one. A quick check reveals that this is [Christiansø][ch], a tiny fortified island, whose [history][ch-hist] goes back to the Middle Ages. It has a special status and [is not included][ch-stat-dk] into the NUTS system. For further manipulations, Christiansø can safely merge it with the close-by Bornholm.

To identify which municipalities fall into which NUTS regions, I use the spatial overlap function (`over`) from `sp` package. Here I should thank [Roger Bivand][biv], a person who made it possible to do any spatial analysis in R.

```{r, eval=FALSE}
# municipality coordinates to Spatial
mun_centr <- SpatialPoints(
    coordinates(sp_mun), proj4string = CRS(proj4string(sp_nuts3))
)

# spatial intersection with sp::over
inter <- bind_cols(mun_coord, over(mun_centr, sp_nuts3[,"NUTS_ID"])) |>
        transmute(long, lat, objectid,
                  nuts3 = as.character(NUTS_ID),
                  nuts2 = substr(nuts3, 1, 4))
```

Let's again check visually if the spatial matching worked okay.

```{r, eval=FALSE}
ggplot()+
        geom_polygon(data = gd_mun, aes(long, lat, group = group),
                     color = brbg[9], fill = "grey90", size = .1)+
        geom_polygon(data = gd_nuts3, aes(long, lat, group = group),
                     color = brbg[3], fill = NA, size = 1)+
        geom_point(data = inter, aes(long, lat, color = nuts3), size = 1)+
        geom_point(data = inter[is.na(inter$nuts3),],
                   aes(long, lat), color = "red", size = 7, pch = 1)+
        theme_map(base_size = 15)+
        theme(legend.position = c(1, 1),
              legend.justification = c(1, 1))
```

![](fig-05-map-match.png)
**Figure 5. Checking the spatial intersection between the old municipalities and NUTS-3 regions of Denmark**

Not bad. But there is an "NA" category that represents all the cases where the spatial match failed. How many such cases do we have?

```{r, eval=FALSE}
# how many failed cases do we have
sum(is.na(inter$nuts3))
```

```{r, eval=FALSE}
## [1] 3
```

```{r, eval=FALSE}
# where the intersection failed
inter[is.na(inter$nuts3),]
```

```{r, eval=FALSE}
##         long     lat objectid nuts3 nuts2
## 23  892474.0 6147918    46399  <NA>  <NA>
## 65  504188.4 6269329   105319  <NA>  <NA>
## 195 533446.8 6312770    47071  <NA>  <NA>
```

As there are only 3 cases, I decided to fix them manually.

```{r, eval=FALSE}
# fix the three cases manually
fixed <- inter
fixed[fixed$objectid=="46399", 4:5] <- c("DK014", "DK01")
fixed[fixed$objectid=="105319", 4:5] <- c("DK041", "DK04")
fixed[fixed$objectid=="47071", 4:5] <- c("DK050", "DK05")
```

The final visual check.

```{r, eval=FALSE}
ggplot()+
        geom_polygon(data = gd_mun, aes(long, lat, group = group),
                     color = brbg[9], fill = "grey90", size = .1)+
        geom_polygon(data = gd_nuts3, aes(long, lat, group = group),
                     color = brbg[3], fill = NA, size = 1)+
        geom_point(data = fixed, aes(long, lat, color = nuts3), size = 1)+
        theme_map(base_size = 15)+
        theme(legend.position = c(1, 1),
              legend.justification = c(1, 1))
```

![](fig-06-map-check.png)
**Figure 6. Re-checking the spatial intersection between the old municipalities and NUTS-3 regions of Denmark**

Now everything seems okay.

# Joining spatial and statistical data (fuzzy join)

The next task is to join the spatial data and statistical data together. The spatial layer for municipalities does not contain the codes that are used by Statistics Denmark, so I have to match municipalities in the two datasets by their names. This is quite a difficult task. Names can be written slightly differently, there are some special characters in Danish alphabet, and some municipalities may have experienced a change of name. To solve the task most efficiently, I used the ‘Fuzzy String Matching’ approach which is implemented in the  [`fuzzyjoin`][fuz] package by [David Robinson][drob].

First, I simplify the names in both datasets turning them into lowercase, replacing the character “å” with “aa”, and removing the “Kommune” word in the spatial dataset names. Please note that I downloaded (separately) a small selection from Statistics Denmark to have a [lightweight dataframe][stat-names] with municipal codes and names.

```{r, eval=FALSE}
# simplify municipalities names
mun_geo <- mun_coord |>
        transmute(name = sub(x = name, " Kommune", replacement = ""), objectid) |>
        mutate(name = gsub(x = tolower(name), "å", "aa"))

mun_stat <- read.csv2(
    "https://ikashnitsky.github.io/share/1703-nuts2-denmark/stat-codes-names.csv",
    fileEncoding = danish_ecnoding
) |>
        select(name) |>
        separate(name, into = c("code", "name"), sep = " ", extra = "merge") |>
        mutate(name = gsub("\\s*\\([^\\)]+\\)", "", x = name)) |>
        mutate(name = gsub(x = tolower(name), "å", "aa"))
```

Let's try fuzzy join.

```{r, eval=FALSE}
# first attempt
fuz_joined_1 <- regex_left_join(mun_geo, mun_stat, by = "name")
```

The resulting dataframe has 278 rows instead of 271. That means that for some municipalities in the spatial dataset there was more than one match. Let’s identify them.

```{r, eval=FALSE}
# identify more that 1 match (7 cases) and select which to drop
fuz_joined_1 |> group_by(objectid) |> mutate(n = n()) |> filter(n > 1)
```

```{r, eval=FALSE}
## Source: local data frame [14 x 5]
## Groups: objectid [7]
##
##         name.x objectid  code      name.y     n
##          <chr>    <dbl> <chr>       <chr> <int>
## 1       haslev   105112   313      haslev     2
## 2       haslev   105112   403       hasle     2
## 3  brønderslev    47003   739       rønde     2
## 4  brønderslev    47003   805 brønderslev     2
## 5    hirtshals    47037   817        hals     2
## 6    hirtshals    47037   819   hirtshals     2
## 7      rønnede    46378   385     rønnede     2
## 8      rønnede    46378   407       rønne     2
## 9     hvidebæk    46268   317    hvidebæk     2
## 10    hvidebæk    46268   681     videbæk     2
## 11    ryslinge    46463   477    ryslinge     2
## 12    ryslinge    46463   737          ry     2
## 13     aarslev    46494   497     aarslev     2
## 14     aarslev    46494   861        aars     2
```

So, for 7 municipalities, two matches were found. I will drop the imperfect match variants in the next iteration of fuzzy join.

The other issue is the municipalities for which no match was found in that statistical data.

```{r, eval=FALSE}
# show the non-matched cases
fuz_joined_1 |> filter(is.na(code))
```

```{r, eval=FALSE}
##              name.x objectid code name.y
## 1              faxe   105120 <NA>   <NA>
## 2 nykøbing falsters    46349 <NA>   <NA>
## 3       herstederne    46101 <NA>   <NA>
```

As there are only three such cases, I corrected them manually in the spatial data to match the statistical data. There are two cases of a difference in the way the name of municipality are written and [one case of name change][herst].

```{r, eval=FALSE}
# correct the 3 non-matching geo names
mun_geo_cor <- mun_geo

mun_geo_cor[mun_geo_cor$name=="faxe", "name"] <- "fakse"
mun_geo_cor[mun_geo_cor$name=="nykøbing falsters", "name"] <- "nykøbing f."
mun_geo_cor[mun_geo_cor$name=="herstederne", "name"] <- "albertslund"
```

Now the second attempt to match the datasets (spatial dataset is corrected).

```{r, eval=FALSE}
# second attempt
fuz_joined_2 <- regex_left_join(mun_geo_cor, mun_stat, by = "name")

# drop non-perfect match
fuz_joined_2 <- fuz_joined_2 |>
        group_by(objectid) |>
        mutate(n = n()) |>
        ungroup() |>
        filter(n < 2 | name.x==name.y)

fuz_joined_2 <- fuz_joined_2 |> transmute(name = name.x, objectid, code)
```

The output looks perfect. Now, the last step -- using the matched “objectid” field, I will finally attach the NUTS data to statistical codes.

```{r, eval=FALSE}
# finally, attach the NUTS info to matched table
key <- left_join(fuz_joined_2, fixed, "objectid")
```

# Aggregate old municipal data to NUTS levels

The previous manipulations yielded a dataframe that links statistical codes of the old municipalities with the corresponding NUTS regions. The last thing that has to be done is aggregation. I will attach the “key” dataset to a statistical dataset and aggregate the data at NUTS-3 and NUTS-2 levels.

```{r, eval=FALSE}
# finally, we only need to aggregate the old stat data
df_agr <- left_join(key, df, "code") |>
        filter(!is.na(name)) |>
        gather("year", "value", y2001:y2006)

df_nuts3 <- df_agr |>
        group_by(year, sex, age, nuts3) |>
        summarise(value = sum(value)) |>
        ungroup()

df_nuts2 <- df_agr |>
        group_by(year, sex, age, nuts2) |>
        summarise(value = sum(value)) |>
        ungroup()
```

Let’s now calculate the shares of working age population in Danish NUTS-3 regions in 2001 and map the information.

```{r, eval=FALSE}
# total population in 2001 by NUTS-3 regions
tot_01 <- df_nuts3 |>
        filter(year=="y2001") |>
        group_by(nuts3) |>
        summarise(tot = sum(value, na.rm = TRUE)) |>
        ungroup()

# working-age population in 2001 by NUTS-3 regions
working_01 <- df_nuts3 |>
        filter(year=="y2001", age %in% paste0("a0", 15:64)) |>
        group_by(nuts3) |>
        summarise(work = sum(value, na.rm = TRUE)) |>
        ungroup()

# calculate the shares of working age population
sw_01 <- left_join(working_01, tot_01, "nuts3") |>
        mutate(sw = work / tot * 100)
```

```{r, eval=FALSE}
# map the shares of working age population in 2001 by NUTS-3 regions
ggplot()+
        geom_polygon(data = gd_nuts3 |> left_join(sw_01, c("id" = "nuts3")),
                     aes(long, lat, group = group, fill = sw),
                     color = "grey50", size = 1) +
        scale_fill_viridis()+
        theme_map(base_size = 15)+
        theme(legend.position = c(1, 1),
              legend.justification = c(1, 1))
```

![](fig-07-map-sw.png)
**Figure 7. The share of working age (15-64) population by NUTS-3 regions of Denmark in 2001**

The result (thankfully!) looks realistic, with higher shares of the working-age population in the capital region, and in other regions that have relatively big cities.

***

::: {.callout-tip}
# [This post is written for Demotrends][demotrends]
:::

[nuts-overview]: http://ec.europa.eu/eurostat/web/nuts/overview
[nuts-hist]: http://ec.europa.eu/eurostat/web/nuts/history
[phd]: http://nidi.nl/en/research/al/270rdc
[proj]: http://ec.europa.eu/eurostat/web/population-demography-migration-projections/population-projections-data
[pop]: https://doi.org/10.6084/m9.figshare.3084394
[deaths]: https://doi.org/10.6084/m9.figshare.3084418
[eurostat-map]: http://ec.europa.eu/eurostat/cache/RCI
[cran]: https://cran.r-project.org
[stat-den]: www.statbank.dk/BEF1A
[data-mun-pop]: https://ikashnitsky.github.io/share/1703-nuts2-denmark/BEF1A.csv.gz
[aalborg]: http://www.geodatabiblioteket.dk/index.php
[geo-old]: https://ikashnitsky.github.io/share/1703-nuts2-denmark/kommune2006utf8.tgz
[eur-geo]: http://ec.europa.eu/eurostat/web/gisco/geodata/reference-data/administrative-units-statistical-units/nuts
[geo-dk]: https://ikashnitsky.github.io/share/1703-nuts2-denmark/denmark-nuts3-espg3044.tgz
[dk-prj]: https://epsg.io/3044
[ch]: https://en.wikipedia.org/wiki/Ertholmene
[ch-hist]: http://www.christiansoe.dk/historien
[ch-stat-dk]: http://www.dst.dk/da/Statistik/dokumentation/Nomenklaturer/NUTS
[fuz]: https://github.com/dgrtwo/fuzzyjoin
[drob]: http://varianceexplained.org/about/
[stat-names]: https://ikashnitsky.github.io/share/1703-nuts2-denmark/stat-names-codes.csv.gz
[herst]: http://albertslund.lokalavisen.dk/fra-herstederne-til-albertslund-/20131017/artikler/710179831
[biv]: https://www.nhh.no/en/employees/faculty/roger-bivand/
[figshare]: https://figshare.com/
[reform]: http://www.tandfonline.com/doi/abs/10.1080/03003930903560562
[demotrends]: https://demotrends.wordpress.com/2017/03/16/working-with-spatial-data-to-generate-a-consistent-demographic-time-series/

[^1]: Vrangbæk, K. (2010). Structural Reform in Denmark, 2007–09: Central Reform Processes in a Decentralised Environment. Local Government Studies, 36(2), 205–221. https://doi.org/10.1080/03003930903560562
[^2]: I have spent quite some time searching if someone else did the job before me and failed to find.
[^3]: There is a note on the website saying that, due to a planned change in the structure of the website, there might be some problems with data accuisition. I failed to download the geodata on 2017-02-23.
---
title: "Gender gap in Swedish mortality"
date: "2017-02-25"
image: teaser.png
categories: [r, demography]
---

***

# Swedish context

Sweden, with its high quality statistical record since 1748, is the natural choice for any demographic study that aims to cover population dynamics during a long period of time.

# Data

The data used for this visualization comes from [Human Mortality Database][hmd]. It can be easily accessed from an R session using [`HMDHFDplus`][hmdhfd] package by [Tim Riffe][tim] (for examples see my previous posts - [one][post1] and [two][post2]). For this exercise, I will use the dataset for Sweden that was provided for an application task for [Rostock Retreat Visualization][retr][^1].

```{r, eval=FALSE}
library(tidyverse)
library(viridis)
library(extrafont)

# download data
df_swe <- read_csv("http://www.rostock-retreat.org/files/application2017/SWE.csv")
# copy at https://ikashnitsky.github.io/doc/misc/application-rostock-retreat/SWE.csv

years <- c(1751, 1800, 1850, 1900, 1925, 1950, 1960, 1970, 1980, 1990, 2000, 2010)

# select years and calculate male-to-female arte-ratio of mortality
df_selected <- df_swe |> select(Year, Sex, Age, mx) |>
        filter(Year %in% years) |>
        spread(Sex, mx) |>
        transmute(year = Year, age = Age, value = m / f)
```

# Visualization

```{r, eval=FALSE}
ggplot(df_selected)+
        geom_hline(yintercept = 1, color = 'grey25', size = .5)+
        geom_point(aes(age, value), size = 2, pch=1, color = 'grey50')+
        stat_smooth(aes(age, value, group = 1, color = factor(year)), se = F)+
        facet_wrap(~year, ncol = 3)+
        labs(title = "Male-to-female age-specific mortality rate ratio, Sweden",
             subtitle = "Untill quite recent times, mortality of females was not
             much lower than that of males",
             caption = "\nData: Human Mortality Database (https://mortality.org)
             Note: Colored lines are produced with loess smoothing",
             x = "Age", y = "Rate ratio")+
        theme_minimal(base_size = 15, base_family = "Roboto Condensed") +
        theme(legend.position = 'none',
              plot.title = element_text(family = "Roboto Mono"))
```

![](sweden.png)

# Comment

Today it is common knowledge that male mortality is always higher than female. There are more males being born, then eventually the sex ratio levels due to higher male mortality (see [my previous post][post1]). Though, male mortality was not always much higher. Back in the days, when infant mortality was much higher and women used to have much higher fertility, there was almost no gender gap in age-specific mortality levels. Constant pregnancy and frequent childbirths had a strong negative impact on female health and survival statistics. We can see that only in the second half of the 20-th century gender gap in mortality became substantial in Sweden.

***

::: {.callout-tip}
# This post is based on my earlier [tweet](https://twitter.com/ikashnitsky/status/802310186560081920) and [gist](https://gist.github.com/ikashnitsky/872d3a97390a60d26eeb64f0f5600067)
:::

[^1]: By using this data, I agree to the [user agreement][lic]

[hmd]: http://www.mortality.org
[lic]: http://www.mortality.org/Public/UserAgreement.php
[hmdhfd]: https://cran.r-project.org/web/packages/HMDHFDplus/index.html
[tim]: https://sites.google.com/site/timriffepersonal/about-me
[post1]: https://ikashnitsky.github.io/2017/hmd-all-sex-ratio/
[post2]: https://ikashnitsky.github.io/2017/hmd-male-mortality-rus-jpn/
[retr]: http://www.rostock-retreat.org
---
title: "Accelerating ggplot2: use a canvas to speed up plots creation"
date: "2017-07-04"
image: teaser.png
categories: [r, ggplot2]
---

***

::: {.callout-important}
# Too wrong; don't read
Basically, this post turned out to be just a wrong, premature, and unnecessary attempt of code optimization. If you still want to have look, make sure that later you read [this post][tlp] by Thomas Lin Pedersen. You are warned
:::

***

::: {.callout-note}
# This post is updated on 2017-07-15
The earlier version had a terminology mistake [pointed out by Hadley Wickham][hadley]. I wrongly called creation time of the plots as rendering time.
:::

One of the nice features of the `gg`approach to plotting is that one can save plots as R objects at any step and use later to render and/or modify. I used that feature extensively while creating maps with `ggplot2` (see my previous posts: [one][one], [two][two], [three][three], [four][four], [five][five]). It is just convenient to first create a canvas with all the theme parameters appropriate for a map, and then overlay the map layer. At some point I decided to check if that workflow was computationally efficient or not. To my surprise, the usage of canvas reduces the creation time of a ggplot quite a lot. To my further surprise, this finding holds for simple plots as well as maps.

Let's start with a simple check.

```{r, eval=FALSE}
# load required packages
library(tidyverse)      # data manipulation and viz
library(ggthemes)       # themes for ggplot2
library(viridis)        # the best color palette
library(rgdal)          # deal with shapefiles
library(microbenchmark) # measure the speed of executing
library(extrafont)      # nice font
myfont <- "Roboto Condensed"
library(RColorBrewer)

# create a canvas
canv_mt <- ggplot(mtcars, aes(hp, mpg, color = cyl))+
        coord_cartesian()

# test speed with mocrobenchmark
test <- microbenchmark(
        without_canvas = ggplot(mtcars, aes(hp, mpg, color = cyl))+
                coord_cartesian()+
                geom_point()

        ,

        with_canvas = canv_mt+
                geom_point()

        ,

        times = 100
)

test

autoplot(test)+
        aes(fill = expr)+
        scale_fill_viridis(discrete = T)+
        theme_bw(base_size = 15, base_family = myfont)+
        theme(legend.position = "none",
              axis.text = element_text(size = 15))+
        labs(title = "The speed of creating a simple ggplot")
```

![](fig-01-test-simple.png)
**Figure 1. Microbenchmark output for a simple plot**

The median time of execution is 3.24 milliseconds for the plot **without** canvas and 2.29 milliseconds for the plot **with** canvas.

Next, let's do the same check for a map. For that, I will use the data prepared for [one of my earlier posts][four] and recreate the simple map that shows the division of European Union 27 into three subregions.

![](fig-02-sub.png)
**Figure 2. The map we use to test the plot creation speed**

```{r, eval=FALSE}
# load the already prepared data
load(url("https://ikashnitsky.github.io/doc/misc/map-subplots/df-27-261-urb-rur.RData"))
load(url("https://ikashnitsky.github.io/doc/misc/map-subplots/spatial-27-261.RData"))

# fortify spatial objects
neib <- fortify(Sneighbors)
bord <- fortify(Sborders)
fort <- fortify(Sn2, region = "id")

# join spatial and statistical data
fort_map <- left_join(df, fort, "id")

# pal for the subregions
brbg3 <- brewer.pal(11,"BrBG")[c(8,2,11)]

# create a blank map
basemap <- ggplot()+
        geom_polygon(data = neib,
                     aes(x = long, y = lat, group = group),
                     fill = "grey90",color = "grey90")+
        coord_equal(ylim = c(1350000,5450000),
                    xlim = c(2500000, 6600000),
                    expand = c(0,0))+
        theme_map(base_family = myfont)+
        theme(panel.border = element_rect(color = "black",size = .5,fill = NA),
              legend.position = c(1, 1),
              legend.justification = c(1, 1),
              legend.background = element_rect(colour = NA, fill = NA),
              legend.title = element_text(size = 15),
              legend.text = element_text(size = 15))+
        labs(x = NULL, y = NULL)

# test speed with mocrobenchmark
test_map <- microbenchmark(
        without_canvas =
                ggplot()+
                geom_polygon(data = neib,
                             aes(x = long, y = lat, group = group),
                             fill = "grey90",color = "grey90")+
                coord_equal(ylim = c(1350000,5450000),
                            xlim = c(2500000, 6600000),
                            expand = c(0,0))+
                theme_map(base_family = myfont)+
                theme(panel.border = element_rect(color = "black",
                                                  size = .5,fill = NA),
                      legend.position = c(1, 1),
                      legend.justification = c(1, 1),
                      legend.background = element_rect(colour = NA, fill = NA),
                      legend.title = element_text(size = 15),
                      legend.text = element_text(size = 15))+
                labs(x = NULL, y = NULL) +
                geom_polygon(data = fort_map,
                             aes(x = long, y = lat, group = group,
                                 fill = subregion), color = NA)+
                scale_fill_manual(values = rev(brbg3)) +
                theme(legend.position = "none")

        ,

        with_canvas =
                basemap +
                geom_polygon(data = fort_map,
                             aes(x = long, y = lat, group = group,
                                 fill = subregion), color = NA)+
                scale_fill_manual(values = rev(brbg3)) +
                theme(legend.position = "none")

        ,

        times = 100
)

autoplot(test_map)+
        aes(fill = expr)+
        scale_fill_viridis(discrete = T)+
        theme_bw(base_size = 15, base_family = myfont)+
        theme(legend.position = "none",
              axis.text = element_text(size = 15))+
        labs(title = "The speed of creating a map with ggplot2")
```

![](fig-03-test-map.png)
**Figure 3. Microbenchmark output for a map**

The median time of execution is 18.8 milliseconds for the map **without** canvas and 6.3 milliseconds for the map **with** canvas.

**Conclusion: Use canvas with `ggplot2`**

***

::: {.callout-tip}
# For the full script to reproduce the results check out this [gist][gist]
:::

[tlp]: https://www.data-imaginist.com/2017/beneath-the-canvas/
[one]: https://ikashnitsky.github.io/2017/denmark-nuts-reconstruction/
[two]: https://ikashnitsky.github.io/2017/map-hacking/
[three]: https://ikashnitsky.github.io/2017/align-six-maps/
[four]: https://ikashnitsky.github.io/2017/subplots-in-maps/
[five]: https://ikashnitsky.github.io/2017/colorcoded-map/
[gist]: https://gist.github.com/ikashnitsky/b9c5d0b838daa2338066dbaa3e035dcc
[hadley]: https://twitter.com/hadleywickham/status/882217871769837569
---
title: "Global convergence in male life expectancy at birth"
date: "2017-07-17"
image: teaser.png
categories: [r, demography]
---

***

In the modern history, the world has seen unprecedented decrease in human mortality -- the result of the Demographic Transition. Initially, the improvements occurred only in the most developed societies, and by the mid XX century the world population was roughly divided in two parts according to mortality patterns (see the bi-modal distribution). After the 2nd World War, the developing countries started to catch up, and there was a clear convergence in life expectancy at birth, the most common summary measure of mortality.

![](e0-convergence.png)

***

::: {.callout-tip}
# To reproduce the plot from the scratch please see [the gist][gist]
:::

[gist]: https://gist.github.com/ikashnitsky/2f6e29acbb9cbeb1694630c5932b8ad5
---
title: "Hello R world post"
date: "2017-01-29"
image: teaser.png
categories: [r]
---

***

Welcome to my blog!

My name is Ilya, I am a demographer. Here I plan to post some research related stuff. As I am crazy about [R](https://www.r-project.org), my post will touch upon this tool/environment -- I will share some tricks and cool visualizations. Eventually, I hope to contribute to the amazing [R-bloggers](https://www.r-bloggers.com) project. First, I am going to post older bits -- to gain momentum.

***
Just to start with, let me show you a small and handy self-written R function.
Quite often, visualizing data in R, we compose color palettes manually. It is nice to have a function that shows the actual colors of a vector with color values. Here it is.

```{r}
glimpse_colors <- function(colors_string){
        n <- length(colors_string)
        hist(1:n, breaks = 0:n, col = colors_string)
}
```

The function takes a vector of colors as input and produces a basic uniform histogram with one bar for each color, filled accordingly. Let's try it out. First, we create some colors, and then visualize them.

```{r}
library(RColorBrewer)
pal <- brewer.pal(n = 9, name = 'BrBG')
glimpse_colors(pal)
```

Enjoy!

P.S. If something similar exists in one of the well known packages, please tell me.

***
---
title: "Sex ratios in all countries from Human Mortality Database"
date: "2017-02-05"
image: teaser.png
categories: [r, hmd, demography]
---

***

Sex ratios reflect the two basic regularities of human demographics: 1) there are always more boys being born; 2) males experience higher mortality throughout their life-course. The sex ratio at birth does not vary dramatically[^1] and is more or less constant at the level of 105-106 boys per 100 girls. Hence, differences in the sex ratio profiles of countries mainly reflect gender gap in mortality. In this post I will compare sex ratios age profiles in all countries included in [Human Mortality Database](http://www.mortality.org).

[^1]: There are cases of big deviations from this natural constant. The most well known one is the skewed sex ratio in China, where decades of One Child Policy together with strong traditional son preference resulted in selective abortions. Read more: @frejka2010pdr; @feng2011pdr; @basten2013ps.

 `R` gives amazing opportunities to grab data fast and easy. Thanks to [Tim Riffe's](https://sites.google.com/site/timriffepersonal/) `HMDHFDplus` package, one can now download HMD data with just a couple of lines of `R` code.

There is a handy function in `HMDHFDplus` package -- `getHMDcountries()`. It lists the codes for all countries in HMD. So it becomes really easy to loop through the database and download data for all countries.

```{r, eval=FALSE}
# load required packages
library(tidyverse) # version 1.0.0
library(HMDHFDplus) # version 1.1.8

country <- getHMDcountries()

exposures <- list()
for (i in 1: length(country)) {
        cnt <- country[i]
        exposures[[cnt]] <- readHMDweb(cnt, "Exposures_1x1",
                                       ik_user_hmd, ik_pass_hmd)

        # let's print the progress
        paste(i,'out of',length(country))
}
```

::: {.callout-important}
# Use own credentials
Please note, the arguments `ik_user_hmd` and `ik_pass_hmd` are my login credentials at the website of [Human Mortality Database](http://www.mortality.org), which are stored locally at my computer. In order to access the data, one needs to create an account at [www.mortality.org](https://www.mortality.org/) and provide his own credentials to the `readHMDweb()` function.
:::

Next, I select 2012 for comparison -- it is quite recent, and for most of the HMD countries there are data for 2012. The loop goes through each of the countries' dataframe in `exposures` list, selects data for 2012 and calculates sex ratio at each age. I also remove data for several populations (like East and West Germany separately).

```{r, eval=FALSE}
sr_age <- list()

for (i in 1:length(exposures)) {
        di <- exposures[[i]]
        sr_agei <- di |> select(Year,Age,Female,Male) |>
                filter(Year %in% 2012) |>
                select(-Year) |>
                transmute(country = names(exposures)[i],
                          age = Age, sr_age = Male / Female * 100)
        sr_age[[i]] <- sr_agei
}
sr_age <- bind_rows(sr_age)

# remove optional populations
sr_age <- sr_age |>
    filter(!country %in% c("FRACNP","DEUTE","DEUTW","GBRCENW","GBR_NP"))
```

After age 90, sex ratios become quite jerky due to the relatively small numbers of survivors. I decided to aggregate data after the age 90.

```{r, eval=FALSE}
# summarize all ages older than 90 (too jerky)
sr_age_90 <- sr_age |> filter(age %in% 90:110) |>
        group_by(country) |> summarise(sr_age = mean(sr_age, na.rm = T)) |>
        ungroup() |> transmute(country, age=90, sr_age)

df_plot <- bind_rows(sr_age |> filter(!age %in% 90:110), sr_age_90)
```

Finally, I plot the resulting sex ratios.

```{r, eval=FALSE}
# get nice font
library(extrafont)
myfont <- "Roboto Condensed"

# finaly - plot
gg <- ggplot(df_plot, aes(age, sr_age, color = country, group = country))+
        geom_hline(yintercept = 100, color = 'grey50', size = 1)+
        geom_line(size = 1)+
        scale_y_continuous(
            limits = c(0, 120), expand = c(0, 0), breaks = seq(0, 120, 20)
        )+
        scale_x_continuous(
            limits = c(0, 90), expand = c(0, 0), breaks = seq(0, 80, 20)
        )+
        xlab('Age')+
        ylab('Sex ratio, males per 100 females')+
        facet_wrap(~country, ncol=6)+
        theme_minimal(base_family = myfont, base_size = 15)+
        theme(legend.position='none',
              panel.border = element_rect(size = .5, fill = NA))

gg
```

![](hmd-sex-ratios.png)

There is quite a variety in the sex ratio profiles. If the initial prevalence of males equalizes in Japan, Sweden, or Norway at around 60, in Russia, Belarus, and Ukraine this happens at around 30 due to very high male mortality. In many countries there are pronounced bumps in the sex ratio at ages 20-30, that are likely to be caused by international migration. For example, Scotland, Northern Ireland, Portugal, and New Zealand are experiencing substantial outflow of young men.

What happened in Taiwan?

***

::: {.callout-tip}
# This post is based on my earlier [tweet](https://twitter.com/ikashnitsky/status/785973218775478273) and [gist](https://gist.github.com/ikashnitsky/a578eaef6b122aa2aa2e3469fd2dcbe7)
:::
---
title: "Male mortality in Russia and Japan"
date: "2017-02-06"
image: teaser.png
categories: [r, hmd, demography]
---

***

Russia is sadly notorious for its ridiculously high adult male mortality. According to [Human Mortality Database data (2010)](http://www.mortality.org), the probability for a Russian men to survive from 20 to 60 was just 0.64 [^1]. For women the probability is 0.87. This huge gender disproportion in mortality results in a peculiar sex ratio profile (see [my old DemoTrends post](https://demotrends.wordpress.com/2015/01/14/the-land-of-babushka/) and [the previous blog post](https://ikashnitsky.github.io/2017/hmd-sex-all-ratio)).

Now let's compare age-specific mortality rates of Russian men to that of the Japanese. For years and years Japan performs best in reducing mortality. It became standard to compare mortality schedules of other countries to the Japanese one [^2].

First, I need to get HMD data for both Russian and Japanese males. Again, I am using the amazing `R` package `HMDHFDplus` of [Tim Riffe](https://sites.google.com/site/timriffepersonal/) to download HMD data with just a couple of lines of `R` code.

```{r, eval=FALSE}
# load required packages
library(tidyverse) # version 1.0.0
library(HMDHFDplus) # version 1.1.8

# load life tables for men, RUS and JPN
rus <- readHMDweb('RUS', "mltper_1x1", ik_user_hmd, ik_pass_hmd)
jpn <- readHMDweb('JPN', "mltper_1x1", ik_user_hmd, ik_pass_hmd)
```

::: {.callout-important}
# Use own credentials
Please note, the arguments `ik_user_hmd` and `ik_pass_hmd` are my login credentials at the website of [Human Mortality Database](http://www.mortality.org), which are stored locally at my computer. In order to access the data, one needs to create an account at [www.mortality.org](https://www.mortality.org/) and provide his own credentials to the `readHMDweb()` function.
:::

Next, I select the most recent year for comparison, 2014, and compute the rate ratio of age specific mortality rates.

```{r, eval=FALSE}
# compare mortality rates for 2014
ru <- rus |> filter(Year == 2014) |> transmute(age = Age, rus = mx)
jp <- jpn |> filter(Year == 2014) |> transmute(age = Age, jpn = mx)
df <- left_join(jp, ru, 'age') |> mutate(ru_rate = rus / jpn)
```

Finally, I plot the resulting rate ratio of male mortality in Russia and Japan.

```{r, eval=FALSE}
# get nice font
library(extrafont)
myfont <- "Roboto Condensed"

# plot
gg <- ggplot(df, aes(age, ru_rate)) +
        geom_hline(yintercept = 1, color = 'red') +
        geom_line(aes(group=1)) +
        scale_y_continuous('mortality rate ratio',
                           breaks = 0:10, labels = 0:10, limits = c(0, 10)) +
        annotate('text',x=c(0, 55), y = c(1.75,5),
                 color = c('red','black'), hjust = 0, vjust = 1, size = 7,
                 label = c('Japan','Russia'), family = myfont) +
        ggtitle('Compare age-specific mortality of males',
                subtitle = "Russia and Japan, 2014, HMD")+
        theme_bw(base_size = 15, base_family = myfont)
```

![](male-mortality-compare.png)

In the middle ages, male mortality in Russian is up to 10 times higher than in Japan!

***

::: {.callout-tip}
# This post is based on my earlier [tweet](https://twitter.com/ikashnitsky/status/792305556132331520) and [gist](https://gist.github.com/ikashnitsky/8df43c9a5dcd1798116ba09b336cdcf2)
:::

[^1]: To compare, the same probabilities for males in some developed countries are: France (0.89), Japan (0.92), US (0.87), UK (0.91).
[^2]: See for example the recent [NIDI working paper of Balachandran et. al (2017)](http://www.nidi.nl/shared/content/output/papers/nidi-wp-2017-01.pdf).
---
title: "Evolution of ice hockey players' height: IIHF world championships 2001-2016"
date: "2017-05-27"
image: teaser.png
categories: [r, sport]
---

***



The 2017 Ice Hockey World Championship has started. Thus I want to share a small research on the height of ice hockey players that I did almost a year ago and [published in Russian][habr].

When the TV camera shows the players returning to the changing rooms, it is difficult not to notice just how huge the players are compared to the surrounding people -- fans, journalists, coaches, or the ice arena workers. For example, here are the rising stars of the Finnish hockey -- Patrik Laine and Aleksander Barkov -- with the two fans in between.

![](fig-00-laine-barkov.jpg)
*[Source][photo]*

So the questions arise. Are ice hockey players really taller than average people? How is the height of ice hockey players evolving over time? Are there any lasting differences between countries?

# Data

IIHF, the organization that is in charge for the ice hockey world championships, publishes detailed information on the squads, including the data on player's height and weight. The raw data files are [here][raw]. I gathered the data of all players that participated in the 16 world championships between 2001 and 2016. The formatting of the data files changes from year to year complicating the data processing. So I did the data cleaning manually which took a bit more than 3 hours. The unifies dataset is [here][data]. Let's load the data and prepare the R session.

```{r, eval=FALSE}
# load required packages
library(tidyverse) # data manipulation and viz
library(lubridate) # easy manipulations with dates
library(ggthemes) # themes for ggplot2
library(texreg) # easy export of regression tables
library(xtable) # export a data frame into an html table
library(sysfonts) # change the font in figures


# download the IIHF data set; if there are some problems, you can download manually
# using the stable URL (https://dx.doi.org/10.6084/m9.figshare.3394735.v2)
df <- read.csv("https://ndownloader.figshare.com/files/5303173")

# color palette
brbg11 <- RColorBrewer::brewer.pal(11, "BrBG")
```

# Do the players become taller? (a crude comparison)

Let's first have a look at the pulled average height of all the players that participated.

```{r, eval=FALSE}
# mean height by championship
df_per <- df |> group_by(year) |>
        summarise(height = mean(height))

gg_period_mean <- ggplot(df_per, aes(x = year, y = height))+
        geom_point(size = 3, color = brbg11[9])+
        stat_smooth(method = "lm", size = 1, color = brbg11[11])+
        ylab("height, cm")+
        xlab("year of competition")+
        scale_x_continuous(breaks = seq(2005, 2015, 5), labels = seq(2005, 2015, 5))+
        theme_few(base_size = 15, base_family = "mono")+
        theme(panel.grid = element_line(colour = "grey75", size = .25))


gg_period_jitter <- ggplot(df, aes(x = year, y = height))+
        geom_jitter(size = 2, color = brbg11[9], alpha = .25, width = .75)+
        stat_smooth(method = "lm", size = 1, se = F, color = brbg11[11])+
        ylab("height, cm")+
        xlab("year of competition")+
        scale_x_continuous(breaks = seq(2005, 2015, 5), labels = seq(2005, 2015, 5))+
        theme_few(base_size = 15, base_family = "mono")+
        theme(panel.grid = element_line(colour = "grey75", size = .25))

gg_period <- cowplot::plot_grid(gg_period_mean, gg_period_jitter)
```

![](fig-01-period-height.png)

**Figure 1. The dynamics of the average height of the ice hockey players at the world championships, 2001--2016**

The positive trend is evident. In the 15 years the average height of a player increased by almost 2 cm (left panel). Is that a lot? To have an idea, we will compare this growth to the dynamics in the population, later in the post.

# Cohort approach

A more correct way to study the dynamics of players' height is to do the comparison between birth cohorts. Here we face an interesting data preparation issue -- some of the players participated in more that one championships. The question is: do we need to clean the duplicate records? If the goal is to see the average height of a player  at the certain championship (as in Figure 1), it is reasonable to keep all the records. Alternatively, if the aim is to analyze the dynamics of players' height itself, I argue, it would be wrong to assign bigger weight to those players that participated in more that one championship. Thus, for the further cohort analysis, I cleaned the dataset from the duplicates.

```{r, eval=FALSE}
dfu_h <- df |> select(year, name, country, position, birth, cohort, height) |>
        spread(year, height)
dfu_h$av.height <- apply(dfu_h[, 6:21], 1, mean, na.rm = T)
dfu_h$times_participated <- apply(!is.na(dfu_h[, 6:21]), 1, sum)

dfu_w <- df |> select(year, name, country, position, birth, cohort, weight) |>
        spread(year, weight)
dfu_w$av.weight <- apply(dfu_w[, 6:21], 1, mean, na.rm = T)


dfu <- left_join(
    dfu_h |> select(
        name, country, position, birth, cohort, av.height, times_participated
    ),
    dfu_w |> select(name, country, position, birth, cohort, av.weight),
    by = c("name", "country", "position", "birth", "cohort")
) |>
    mutate(bmi = av.weight / (av.height / 100) ^ 2)
```

The total number of observations decreased from 6292 to 3333. For those who participated in more that one championship, I averaged the data on height and weight as they can change during the life-course. How many times, on average, are ice hockey players honored to represent their countries in the world championships? A bit less than 2.

```{r, eval=FALSE}
# frequencies of participation in world championships
mean(dfu$times_participated)

df_part <- as.data.frame(table(dfu$times_participated))

gg_times_part <- ggplot(df_part, aes(y = Freq, x = Var1))+
        geom_bar(stat = "identity", fill = brbg11[8])+
        ylab("# of players")+
        xlab("times participated (out of 16 possible)")+
        theme_few(base_size = 15, base_family = "mono")+
        theme(panel.grid = element_line(colour = "grey75", size = .25))
```

![](fig-02-times-part.png)

**Figure 2. Histogram of the players by the number of times they participated in world championships over the period 2001-2016.**

But there are unique players that participated in a considerable number of championships. Let's have a look at those who participated at least 10 times out of 16 possible. There were just 14 such players.

```{r, eval=FALSE}
# the leaders of participation in world championships
leaders <- dfu |> filter(times_participated > 9)
View(leaders)
# save the table to html
print(xtable(leaders), type = "html", file = "table_leaders.html")
```

**Table 1. The most frequently participated players**
<style type="text/css">
.tg  {border-collapse:collapse;border-spacing:0;}
.tg td{font-family:Arial, sans-serif;font-size:14px;padding:3px 3px;border-style:solid;border-width:1px;overflow:hidden;word-break:normal;}
.tg th{font-family:Arial, sans-serif;font-size:14px;font-weight:normal;padding:3px 3px;border-style:solid;border-width:1px;overflow:hidden;word-break:normal;}
.tg .tg-ls8f{font-family:Georgia, serif !important;}
.tg .tg-oa1s{font-weight:bold;font-family:Georgia, serif !important;}
.tg .tg-jrsh{font-family:Georgia, serif !important;;text-align:center}
.tg .tg-lyle{font-weight:bold;font-family:Georgia, serif !important;;text-align:center}
</style>
<table class="tg">
  <tr>
    <th class="tg-oa1s">name </th>
    <th class="tg-lyle"> country </th>
    <th class="tg-lyle"> position </th>
    <th class="tg-lyle"> birth date</th>
    <th class="tg-lyle"> cohort </th>
    <th class="tg-lyle"> av.height </th>
    <th class="tg-lyle"> times _participated </th>
    <th class="tg-lyle"> av.weight </th>
    <th class="tg-lyle"> bmi </th>
  </tr>
  <tr>
    <td class="tg-ls8f"> ovechkin alexander </td>
    <td class="tg-jrsh"> RUS </td>
    <td class="tg-jrsh"> F </td>
    <td class="tg-jrsh"> 1985-09-17 </td>
    <td class="tg-jrsh"> 1985 </td>
    <td class="tg-jrsh"> 188.45 </td>
    <td class="tg-jrsh">  11 </td>
    <td class="tg-jrsh"> 98.36 </td>
    <td class="tg-jrsh"> 27.70 </td>
  </tr>
  <tr>
    <td class="tg-ls8f"> nielsen daniel </td>
    <td class="tg-jrsh"> DEN </td>
    <td class="tg-jrsh"> D </td>
    <td class="tg-jrsh"> 1980-10-31 </td>
    <td class="tg-jrsh"> 1980 </td>
    <td class="tg-jrsh"> 182.27 </td>
    <td class="tg-jrsh">  11 </td>
    <td class="tg-jrsh"> 79.73 </td>
    <td class="tg-jrsh"> 24.00 </td>
  </tr>
  <tr>
    <td class="tg-ls8f"> staal kim </td>
    <td class="tg-jrsh"> DEN </td>
    <td class="tg-jrsh"> F </td>
    <td class="tg-jrsh"> 1978-03-10 </td>
    <td class="tg-jrsh"> 1978 </td>
    <td class="tg-jrsh"> 182.00 </td>
    <td class="tg-jrsh">  10 </td>
    <td class="tg-jrsh"> 87.80 </td>
    <td class="tg-jrsh"> 26.51 </td>
  </tr>
  <tr>
    <td class="tg-ls8f"> green morten </td>
    <td class="tg-jrsh"> DEN </td>
    <td class="tg-jrsh"> F </td>
    <td class="tg-jrsh"> 1981-03-19 </td>
    <td class="tg-jrsh"> 1981 </td>
    <td class="tg-jrsh"> 183.00 </td>
    <td class="tg-jrsh">  12 </td>
    <td class="tg-jrsh"> 85.83 </td>
    <td class="tg-jrsh"> 25.63 </td>
  </tr>
  <tr>
    <td class="tg-ls8f"> masalskis edgars </td>
    <td class="tg-jrsh"> LAT </td>
    <td class="tg-jrsh"> G </td>
    <td class="tg-jrsh"> 1980-03-31 </td>
    <td class="tg-jrsh"> 1980 </td>
    <td class="tg-jrsh"> 176.00 </td>
    <td class="tg-jrsh">  12 </td>
    <td class="tg-jrsh"> 79.17 </td>
    <td class="tg-jrsh"> 25.56 </td>
  </tr>
  <tr>
    <td class="tg-ls8f"> ambuhl andres </td>
    <td class="tg-jrsh"> SUI </td>
    <td class="tg-jrsh"> F </td>
    <td class="tg-jrsh"> 1983-09-14 </td>
    <td class="tg-jrsh"> 1983 </td>
    <td class="tg-jrsh"> 176.80 </td>
    <td class="tg-jrsh">  10 </td>
    <td class="tg-jrsh"> 83.70 </td>
    <td class="tg-jrsh"> 26.78 </td>
  </tr>
  <tr>
    <td class="tg-ls8f"> granak dominik </td>
    <td class="tg-jrsh"> SVK </td>
    <td class="tg-jrsh"> D </td>
    <td class="tg-jrsh"> 1983-06-11 </td>
    <td class="tg-jrsh"> 1983 </td>
    <td class="tg-jrsh"> 182.00 </td>
    <td class="tg-jrsh">  10 </td>
    <td class="tg-jrsh"> 79.50 </td>
    <td class="tg-jrsh"> 24.00 </td>
  </tr>
  <tr>
    <td class="tg-ls8f"> madsen morten </td>
    <td class="tg-jrsh"> DEN </td>
    <td class="tg-jrsh"> F </td>
    <td class="tg-jrsh"> 1987-01-16 </td>
    <td class="tg-jrsh"> 1987 </td>
    <td class="tg-jrsh"> 189.82 </td>
    <td class="tg-jrsh">  11 </td>
    <td class="tg-jrsh"> 86.00 </td>
    <td class="tg-jrsh"> 23.87 </td>
  </tr>
  <tr>
    <td class="tg-ls8f"> redlihs mikelis </td>
    <td class="tg-jrsh"> LAT </td>
    <td class="tg-jrsh"> F </td>
    <td class="tg-jrsh"> 1984-07-01 </td>
    <td class="tg-jrsh"> 1984 </td>
    <td class="tg-jrsh"> 180.00 </td>
    <td class="tg-jrsh">  10 </td>
    <td class="tg-jrsh"> 80.40 </td>
    <td class="tg-jrsh"> 24.81 </td>
  </tr>
  <tr>
    <td class="tg-ls8f"> cipulis martins </td>
    <td class="tg-jrsh"> LAT </td>
    <td class="tg-jrsh"> F </td>
    <td class="tg-jrsh"> 1980-11-29 </td>
    <td class="tg-jrsh"> 1980 </td>
    <td class="tg-jrsh"> 180.70 </td>
    <td class="tg-jrsh">  10 </td>
    <td class="tg-jrsh"> 82.10 </td>
    <td class="tg-jrsh"> 25.14 </td>
  </tr>
  <tr>
    <td class="tg-ls8f"> holos jonas </td>
    <td class="tg-jrsh"> NOR </td>
    <td class="tg-jrsh"> D </td>
    <td class="tg-jrsh"> 1987-08-27 </td>
    <td class="tg-jrsh"> 1987 </td>
    <td class="tg-jrsh"> 180.18 </td>
    <td class="tg-jrsh">  11 </td>
    <td class="tg-jrsh"> 91.36 </td>
    <td class="tg-jrsh"> 28.14 </td>
  </tr>
  <tr>
    <td class="tg-ls8f"> bastiansen anders </td>
    <td class="tg-jrsh"> NOR </td>
    <td class="tg-jrsh"> F </td>
    <td class="tg-jrsh"> 1980-10-31 </td>
    <td class="tg-jrsh"> 1980 </td>
    <td class="tg-jrsh"> 190.00 </td>
    <td class="tg-jrsh">  11 </td>
    <td class="tg-jrsh"> 93.64 </td>
    <td class="tg-jrsh"> 25.94 </td>
  </tr>
  <tr>
    <td class="tg-ls8f"> ask morten </td>
    <td class="tg-jrsh"> NOR </td>
    <td class="tg-jrsh"> F </td>
    <td class="tg-jrsh"> 1980-05-14 </td>
    <td class="tg-jrsh"> 1980 </td>
    <td class="tg-jrsh"> 185.00 </td>
    <td class="tg-jrsh">  10 </td>
    <td class="tg-jrsh"> 88.30 </td>
    <td class="tg-jrsh"> 25.80 </td>
  </tr>
  <tr>
    <td class="tg-ls8f"> forsberg kristian </td>
    <td class="tg-jrsh"> NOR </td>
    <td class="tg-jrsh"> F </td>
    <td class="tg-jrsh"> 1986-05-05 </td>
    <td class="tg-jrsh"> 1986 </td>
    <td class="tg-jrsh"> 184.50 </td>
    <td class="tg-jrsh">  10 </td>
    <td class="tg-jrsh"> 87.50 </td>
    <td class="tg-jrsh"> 25.70 </td>
  </tr>
</table>

Alexander Ovechkin -- 11 times! But it has to be noted that not every player had a possibility to participate in all the 16 championships between 2001 and 2016. That depends on a numder of factors:
 - the birth cohort of the player;
 - whether his national team regularly qualified for the championship (Figure 3);
 - whether the player was good enough for the national team;
 - whether he was free from the NHL play-offs that often keep the best players off the world championships.

```{r, eval=FALSE}
# countries times participated
df_cnt_part <- df |> select(year, country, no) |>
        mutate(country = factor(paste(country))) |>
        group_by(country, year) |>
        summarise(value = sum(as.numeric(no))) |>
        mutate(value = 1) |>
        ungroup() |>
        mutate(country = factor(country, levels = rev(levels(country))),
               year = factor(year))

d_cnt_n <- df_cnt_part |> group_by(country) |>
        summarise(n = sum(value))

gg_cnt_part <- ggplot(data = df_cnt_part, aes(x = year, y = country))+
        geom_point(color = brbg11[11], size = 7)+
        geom_text(
            data = d_cnt_n, aes(y = country, x = 17.5, label = n, color = n),
            size = 7, fontface = 2
        )+
        geom_text(data = d_cnt_n, aes(y = country, x = 18.5, label = " "), size = 7)+
        scale_color_gradientn(colours = brbg11[7:11])+
        xlab(NULL)+
        ylab(NULL)+
        theme_bw(base_size = 25, base_family = "mono")+
        theme(legend.position = "none",
              axis.text.x = element_text(angle = 90, hjust = 1, vjust = 0.5))
```

![](fig-03-countries-part.png)

**Figure 3. Stats of the national teams participation in the world championships**

# Do the ice hochey players become taller? (regression analysis)

The regression analysis allows to address the research question -- the association between player's height and birth cohort -- accounting for the cross-national differences and player's position. I use OLS regressions, that are quite sensitive to outliers. I removed the birth cohorts for which there are less than 10 players -- 1963, 1997, and 1998.

```{r, eval=FALSE}
# remove small cohorts
table(dfu$cohort)
dfuc <- dfu |> filter(cohort < 1997, cohort > 1963)
```

So, the results. I add the variables one by one.

**Dependent variable**: player's height.
**Explaining variables**: 1) birth cohort; 2) position (compared to defenders); 3) country (compared to Russia).

```{r, eval=FALSE}
# relevel counrty variable to compare with Russia
dfuc$country <- relevel(dfuc$country, ref = "RUS")

# regression models
m1 <- lm(data = dfuc, av.height~cohort)
m2 <- lm(data = dfuc, av.height~cohort+position)
m3 <- lm(data = dfuc, av.height~cohort+position+country)

# export the models to html
htmlreg(list(m1, m2, m3), file = "models_height.html", single.row = T)
```

**Table2. The models**
<style type="text/css">
.tg  {border-collapse:collapse;border-spacing:0;}
.tg td{font-family:Arial, sans-serif;font-size:14px;padding:3px 3px;border-style:solid;border-width:1px;overflow:hidden;word-break:normal;}
.tg th{font-family:Arial, sans-serif;font-size:14px;font-weight:normal;padding:3px 3px;border-style:solid;border-width:1px;overflow:hidden;word-break:normal;}
.tg .tg-ls8f{font-family:Georgia, serif !important;}
.tg .tg-t6te{font-style:italic;font-family:Georgia, serif !important;;text-align:center}
.tg .tg-oa1s{font-weight:bold;font-family:Georgia, serif !important;}
.tg .tg-jrsh{font-family:Georgia, serif !important;;text-align:center}
.tg .tg-lyle{font-weight:bold;font-family:Georgia, serif !important;;text-align:center}
.tg .tg-mmdc{font-style:italic;font-family:Georgia, serif !important;}
</style>
<table class="tg">
  <tr>
    <th class="tg-oa1s"></th>
    <th class="tg-lyle">Model 1</th>
    <th class="tg-lyle">Model 2</th>
    <th class="tg-lyle">Model 3</th>
  </tr>
  <tr>
    <td class="tg-ls8f">(Intercept)</td>
    <td class="tg-jrsh">-10.17 (27.67)</td>
    <td class="tg-jrsh">-18.64 (27.01)</td>
    <td class="tg-jrsh">32.59 (27.00)</td>
  </tr>
  <tr>
    <td class="tg-ls8f">cohort</td>
    <td class="tg-jrsh">0.10 (0.01)***</td>
    <td class="tg-jrsh">0.10 (0.01)***</td>
    <td class="tg-jrsh">0.08 (0.01)***</td>
  </tr>
  <tr>
    <td class="tg-ls8f">positionF</td>
    <td class="tg-jrsh"></td>
    <td class="tg-jrsh">-2.59 (0.20)***</td>
    <td class="tg-jrsh">-2.59 (0.20)***</td>
  </tr>
  <tr>
    <td class="tg-ls8f">positionG</td>
    <td class="tg-jrsh"></td>
    <td class="tg-jrsh">-1.96 (0.31)***</td>
    <td class="tg-jrsh">-1.93 (0.30)***</td>
  </tr>
  <tr>
    <td class="tg-ls8f">countryAUT</td>
    <td class="tg-jrsh"></td>
    <td class="tg-jrsh"></td>
    <td class="tg-jrsh">-0.94 (0.55)</td>
  </tr>
  <tr>
    <td class="tg-ls8f">countryBLR</td>
    <td class="tg-jrsh"></td>
    <td class="tg-jrsh"></td>
    <td class="tg-jrsh">-0.95 (0.53)</td>
  </tr>
  <tr>
    <td class="tg-ls8f">countryCAN</td>
    <td class="tg-jrsh"></td>
    <td class="tg-jrsh"></td>
    <td class="tg-jrsh">1.13 (0.46)*</td>
  </tr>
  <tr>
    <td class="tg-ls8f">countryCZE</td>
    <td class="tg-jrsh"></td>
    <td class="tg-jrsh"></td>
    <td class="tg-jrsh">0.56 (0.49)</td>
  </tr>
  <tr>
    <td class="tg-ls8f">countryDEN</td>
    <td class="tg-jrsh"></td>
    <td class="tg-jrsh"></td>
    <td class="tg-jrsh">-0.10 (0.56)</td>
  </tr>
  <tr>
    <td class="tg-ls8f">countryFIN</td>
    <td class="tg-jrsh"></td>
    <td class="tg-jrsh"></td>
    <td class="tg-jrsh">0.20 (0.50)</td>
  </tr>
  <tr>
    <td class="tg-ls8f">countryFRA</td>
    <td class="tg-jrsh"></td>
    <td class="tg-jrsh"></td>
    <td class="tg-jrsh">-2.19 (0.69)**</td>
  </tr>
  <tr>
    <td class="tg-ls8f">countryGER</td>
    <td class="tg-jrsh"></td>
    <td class="tg-jrsh"></td>
    <td class="tg-jrsh">-0.61 (0.51)</td>
  </tr>
  <tr>
    <td class="tg-ls8f">countryHUN</td>
    <td class="tg-jrsh"></td>
    <td class="tg-jrsh"></td>
    <td class="tg-jrsh">-0.61 (0.86)</td>
  </tr>
  <tr>
    <td class="tg-ls8f">countryITA</td>
    <td class="tg-jrsh"></td>
    <td class="tg-jrsh"></td>
    <td class="tg-jrsh">-3.58 (0.61)***</td>
  </tr>
  <tr>
    <td class="tg-ls8f">countryJPN</td>
    <td class="tg-jrsh"></td>
    <td class="tg-jrsh"></td>
    <td class="tg-jrsh">-5.24 (0.71)***</td>
  </tr>
  <tr>
    <td class="tg-ls8f">countryKAZ</td>
    <td class="tg-jrsh"></td>
    <td class="tg-jrsh"></td>
    <td class="tg-jrsh">-1.16 (0.57)*</td>
  </tr>
  <tr>
    <td class="tg-ls8f">countryLAT</td>
    <td class="tg-jrsh"></td>
    <td class="tg-jrsh"></td>
    <td class="tg-jrsh">-1.38 (0.55)*</td>
  </tr>
  <tr>
    <td class="tg-ls8f">countryNOR</td>
    <td class="tg-jrsh"></td>
    <td class="tg-jrsh"></td>
    <td class="tg-jrsh">-1.61 (0.62)**</td>
  </tr>
  <tr>
    <td class="tg-ls8f">countryPOL</td>
    <td class="tg-jrsh"></td>
    <td class="tg-jrsh"></td>
    <td class="tg-jrsh">0.06 (1.12)</td>
  </tr>
  <tr>
    <td class="tg-ls8f">countrySLO</td>
    <td class="tg-jrsh"></td>
    <td class="tg-jrsh"></td>
    <td class="tg-jrsh">-1.55 (0.58)**</td>
  </tr>
  <tr>
    <td class="tg-ls8f">countrySUI</td>
    <td class="tg-jrsh"></td>
    <td class="tg-jrsh"></td>
    <td class="tg-jrsh">-1.80 (0.53)***</td>
  </tr>
  <tr>
    <td class="tg-ls8f">countrySVK</td>
    <td class="tg-jrsh"></td>
    <td class="tg-jrsh"></td>
    <td class="tg-jrsh">1.44 (0.50)**</td>
  </tr>
  <tr>
    <td class="tg-ls8f">countrySWE</td>
    <td class="tg-jrsh"></td>
    <td class="tg-jrsh"></td>
    <td class="tg-jrsh">1.18 (0.48)*</td>
  </tr>
  <tr>
    <td class="tg-ls8f">countryUKR</td>
    <td class="tg-jrsh"></td>
    <td class="tg-jrsh"></td>
    <td class="tg-jrsh">-1.82 (0.59)**</td>
  </tr>
  <tr>
    <td class="tg-ls8f">countryUSA</td>
    <td class="tg-jrsh"></td>
    <td class="tg-jrsh"></td>
    <td class="tg-jrsh">0.54 (0.45)</td>
  </tr>
  <tr>
    <td class="tg-mmdc">R2</td>
    <td class="tg-t6te">0.01</td>
    <td class="tg-t6te">0.06</td>
    <td class="tg-t6te">0.13</td>
  </tr>
  <tr>
    <td class="tg-mmdc">Adj. R2</td>
    <td class="tg-t6te">0.01</td>
    <td class="tg-t6te">0.06</td>
    <td class="tg-t6te">0.12</td>
  </tr>
  <tr>
    <td class="tg-mmdc">Num. obs.</td>
    <td class="tg-t6te">3319</td>
    <td class="tg-t6te">3319</td>
    <td class="tg-t6te">3319</td>
  </tr>
  <tr>
    <td class="tg-mmdc">RMSE</td>
    <td class="tg-t6te">5.40</td>
    <td class="tg-t6te">5.27</td>
    <td class="tg-t6te">5.10</td>
  </tr>
</table>

**Model 1**. One year change in the birth cohort year is associated with an increase of 0.1 cm in height. The coefficient is statistically significant, yet the variable explains only 1% of the variance. That's not a big problem since the aim of the modeling is to document the differences, rather than predict based on the model. Nevertheless, the low coefficient of determination means that there are other variables that explain the differences in players' height better than just the birth cohort.

**Model 2.** Defenders are the tallest ice hockey players: goalkeepers are 2 cm shorter, forwards are 2.6 cm shorter. All the coefficients are significant; R squared rose to 6%. It is worth noting that the coefficient for the birth cohort did not change when we added the new variable.

**Model 3**. It is interesting to control for countries for two reasons. First, some of the differences are significant themselves.  For example, Swedes, Slovaks, and Canadians are higher than Russians. In contrast, Japanese are 5.2 cm shorter, Italians -- 3.6 cm, French -- 2.2 cm (figure 4). Second, once the country controls are introduced, the coefficient for birth cohort decreased slightly meaning that some of the differences in height are explained by persisting cross-country differences. R squared rose to 13%.

```{r, eval=FALSE}
# players' height by country
gg_av.h_country <- ggplot(dfuc , aes(x = factor(cohort), y = av.height))+
        geom_point(color = "grey50", alpha = .25)+
        stat_summary(
            aes(group = country), geom = "line", fun.y = mean,
            size = .5, color = "grey50"
        )+
        stat_smooth(aes(group = country, color = country), geom = "line", size = 1)+
        facet_wrap(~country, ncol = 4)+
        coord_cartesian(ylim = c(170, 195))+
        scale_x_discrete(
            labels = paste(seq(1970, 1990, 10)), breaks = paste(seq(1970, 1990, 10))
        )+
        labs(x = "birth cohort", y = "height, cm")+
        theme_few(base_size = 15, base_family = "mono")+
        theme(legend.position = "none",
              panel.grid = element_line(colour = "grey75", size = .25))
```

![](fig-04-height-by-country.png)

**Figure 4. The height of ice hockey players by nations**

The last model indicates that from one birth cohort cohort to the other the height of ice hockey players increases 0.08 cm. That means an increase of 0.8 cm in a decade or a growth of 2.56 cm in the 32 years between 1964 and 1996. It is worth mentioning that once we run the analysis in cohorts and controlling for positions and nations, the speed of the player's height increase becomes much humbler than in the crude pulled analysis (Figure 1): 0.8 cm per decade compared to 1.2 cm per decade.

Before we go further and compare the growth in player's height to that of the population, let's do the modeling separately for defenders, goalkeepers, and forwards. The exploratory plot (Figure 5) suggests that the correlation is stronger for goalkeepers and weaker for defenders.

```{r, eval=FALSE}
dfuc_pos <- dfuc
levels(dfuc_pos$position) <- c("Defenders", "Forwards", "Goalkeeprs")

gg_pos <- ggplot(dfuc_pos , aes(x = cohort, y = av.height))+
        geom_jitter(aes(color = position), alpha = .5, size = 2)+
        stat_smooth(method = "lm", se = T, color = brbg11[11], size = 1)+
        scale_x_continuous(labels = seq(1970, 1990, 10), breaks = seq(1970, 1990, 10))+
        scale_color_manual(values = brbg11[c(8, 9, 10)])+
        facet_wrap(~position, ncol = 3)+
        xlab("birth cohort")+
        ylab("height, cm")+
        theme_few(base_size = 15, base_family = "mono")+
        theme(
            legend.position = "none",
            panel.grid = element_line(colour = "grey75", size = .25)
        )
```

![](fig-05-corr-by-pos.png)

**Figure 5. Correlation between height and birth cohort by position**

```{r, eval=FALSE}
# separate models for positions
m3d <- lm(data = dfuc |> filter(position == "D"), av.height~cohort+country)
m3f <- lm(data = dfuc |> filter(position == "F"), av.height~cohort+country)
m3g <- lm(data = dfuc |> filter(position == "G"), av.height~cohort+country)
htmlreg(
    list(m3d, m3f, m3g), file = "models_height_pos.html", single.row = T,
    custom.model.names = c("Model 3 D", "Model 3 F", "Model 3 G")
)
```

**Table 3. Model 3 -- separately for defenders, forwards, and goalkeepers**
<style type="text/css">
.tg  {border-collapse:collapse;border-spacing:0;}
.tg td{font-family:Arial, sans-serif;font-size:14px;padding:3px 3px;border-style:solid;border-width:1px;overflow:hidden;word-break:normal;}
.tg th{font-family:Arial, sans-serif;font-size:14px;font-weight:normal;padding:3px 3px;border-style:solid;border-width:1px;overflow:hidden;word-break:normal;}
.tg .tg-ls8f{font-family:Georgia, serif !important;}
.tg .tg-t6te{font-style:italic;font-family:Georgia, serif !important;;text-align:center}
.tg .tg-oa1s{font-weight:bold;font-family:Georgia, serif !important;}
.tg .tg-jrsh{font-family:Georgia, serif !important;;text-align:center}
.tg .tg-lyle{font-weight:bold;font-family:Georgia, serif !important;;text-align:center}
.tg .tg-mmdc{font-style:italic;font-family:Georgia, serif !important;}
</style>
<table class="tg">
  <tr>
    <th class="tg-oa1s"></th>
    <th class="tg-lyle">Model 3 D</th>
    <th class="tg-lyle">Model 3 F</th>
    <th class="tg-lyle">Model 3 G</th>
  </tr>
  <tr>
    <td class="tg-ls8f">(Intercept)</td>
    <td class="tg-jrsh">108.45 (46.46)*</td>
    <td class="tg-jrsh">49.32 (36.73)</td>
    <td class="tg-jrsh">-295.76 (74.61)***</td>
  </tr>
  <tr>
    <td class="tg-ls8f">cohort</td>
    <td class="tg-jrsh">0.04 (0.02)</td>
    <td class="tg-jrsh">0.07 (0.02)***</td>
    <td class="tg-jrsh">0.24 (0.04)***</td>
  </tr>
  <tr>
    <td class="tg-ls8f">countryAUT</td>
    <td class="tg-jrsh">0.14 (0.96)</td>
    <td class="tg-jrsh">-2.01 (0.75)**</td>
    <td class="tg-jrsh">0.47 (1.47)</td>
  </tr>
  <tr>
    <td class="tg-ls8f">countryBLR</td>
    <td class="tg-jrsh">0.30 (0.87)</td>
    <td class="tg-jrsh">-1.53 (0.73)*</td>
    <td class="tg-jrsh">-2.73 (1.55)</td>
  </tr>
  <tr>
    <td class="tg-ls8f">countryCAN</td>
    <td class="tg-jrsh">1.55 (0.78)*</td>
    <td class="tg-jrsh">0.39 (0.62)</td>
    <td class="tg-jrsh">3.45 (1.26)**</td>
  </tr>
  <tr>
    <td class="tg-ls8f">countryCZE</td>
    <td class="tg-jrsh">0.87 (0.84)</td>
    <td class="tg-jrsh">0.30 (0.67)</td>
    <td class="tg-jrsh">0.63 (1.36)</td>
  </tr>
  <tr>
    <td class="tg-ls8f">countryDEN</td>
    <td class="tg-jrsh">-0.60 (0.95)</td>
    <td class="tg-jrsh">0.10 (0.75)</td>
    <td class="tg-jrsh">-0.19 (1.62)</td>
  </tr>
  <tr>
    <td class="tg-ls8f">countryFIN</td>
    <td class="tg-jrsh">-0.55 (0.89)</td>
    <td class="tg-jrsh">-0.04 (0.67)</td>
    <td class="tg-jrsh">2.40 (1.32)</td>
  </tr>
  <tr>
    <td class="tg-ls8f">countryFRA</td>
    <td class="tg-jrsh">-3.34 (1.15)**</td>
    <td class="tg-jrsh">-2.06 (0.93)*</td>
    <td class="tg-jrsh">1.39 (2.07)</td>
  </tr>
  <tr>
    <td class="tg-ls8f">countryGER</td>
    <td class="tg-jrsh">0.48 (0.85)</td>
    <td class="tg-jrsh">-1.40 (0.72)</td>
    <td class="tg-jrsh">-0.65 (1.33)</td>
  </tr>
  <tr>
    <td class="tg-ls8f">countryHUN</td>
    <td class="tg-jrsh">-1.32 (1.47)</td>
    <td class="tg-jrsh">-0.70 (1.16)</td>
    <td class="tg-jrsh">0.65 (2.39)</td>
  </tr>
  <tr>
    <td class="tg-ls8f">countryITA</td>
    <td class="tg-jrsh">-2.08 (1.08)</td>
    <td class="tg-jrsh">-4.78 (0.82)***</td>
    <td class="tg-jrsh">-2.02 (1.62)</td>
  </tr>
  <tr>
    <td class="tg-ls8f">countryJPN</td>
    <td class="tg-jrsh">-4.13 (1.26)**</td>
    <td class="tg-jrsh">-6.52 (0.94)***</td>
    <td class="tg-jrsh">-2.27 (1.98)</td>
  </tr>
  <tr>
    <td class="tg-ls8f">countryKAZ</td>
    <td class="tg-jrsh">-1.23 (0.95)</td>
    <td class="tg-jrsh">-1.82 (0.79)*</td>
    <td class="tg-jrsh">1.79 (1.58)</td>
  </tr>
  <tr>
    <td class="tg-ls8f">countryLAT</td>
    <td class="tg-jrsh">-0.73 (0.95)</td>
    <td class="tg-jrsh">-1.39 (0.75)</td>
    <td class="tg-jrsh">-3.42 (1.49)*</td>
  </tr>
  <tr>
    <td class="tg-ls8f">countryNOR</td>
    <td class="tg-jrsh">-3.25 (1.07)**</td>
    <td class="tg-jrsh">-1.06 (0.85)</td>
    <td class="tg-jrsh">-0.10 (1.66)</td>
  </tr>
  <tr>
    <td class="tg-ls8f">countryPOL</td>
    <td class="tg-jrsh">0.82 (1.89)</td>
    <td class="tg-jrsh">-0.58 (1.55)</td>
    <td class="tg-jrsh">0.37 (2.97)</td>
  </tr>
  <tr>
    <td class="tg-ls8f">countrySLO</td>
    <td class="tg-jrsh">-1.57 (0.99)</td>
    <td class="tg-jrsh">-1.54 (0.79)</td>
    <td class="tg-jrsh">-2.25 (1.66)</td>
  </tr>
  <tr>
    <td class="tg-ls8f">countrySUI</td>
    <td class="tg-jrsh">-1.98 (0.91)*</td>
    <td class="tg-jrsh">-2.36 (0.71)***</td>
    <td class="tg-jrsh">1.12 (1.47)</td>
  </tr>
  <tr>
    <td class="tg-ls8f">countrySVK</td>
    <td class="tg-jrsh">2.94 (0.87)***</td>
    <td class="tg-jrsh">0.81 (0.67)</td>
    <td class="tg-jrsh">-0.70 (1.50)</td>
  </tr>
  <tr>
    <td class="tg-ls8f">countrySWE</td>
    <td class="tg-jrsh">0.75 (0.81)</td>
    <td class="tg-jrsh">1.24 (0.65)</td>
    <td class="tg-jrsh">1.37 (1.33)</td>
  </tr>
  <tr>
    <td class="tg-ls8f">countryUKR</td>
    <td class="tg-jrsh">-1.37 (1.01)</td>
    <td class="tg-jrsh">-1.77 (0.80)*</td>
    <td class="tg-jrsh">-3.71 (1.66)*</td>
  </tr>
  <tr>
    <td class="tg-ls8f">countryUSA</td>
    <td class="tg-jrsh">0.76 (0.78)</td>
    <td class="tg-jrsh">-0.08 (0.62)</td>
    <td class="tg-jrsh">2.58 (1.26)*</td>
  </tr>
  <tr>
    <td class="tg-mmdc">R2</td>
    <td class="tg-t6te">0.09</td>
    <td class="tg-t6te">0.10</td>
    <td class="tg-t6te">0.24</td>
  </tr>
  <tr>
    <td class="tg-mmdc">Adj. R2</td>
    <td class="tg-t6te">0.07</td>
    <td class="tg-t6te">0.09</td>
    <td class="tg-t6te">0.20</td>
  </tr>
  <tr>
    <td class="tg-mmdc">Num. obs.</td>
    <td class="tg-t6te">1094</td>
    <td class="tg-t6te">1824</td>
    <td class="tg-t6te">401</td>
  </tr>
  <tr>
    <td class="tg-mmdc">RMSE</td>
    <td class="tg-t6te">5.08</td>
    <td class="tg-t6te">5.08</td>
    <td class="tg-t6te">4.87</td>
  </tr>
</table>

The separate modeling shows that the average height of ice hockey players, that were born in 1964-1996 and participated in the world championships in 2001--2016, increased with the speed of 0.4 cm per decade for defenders, 0.7 cm -- for forwards, and (!) 2.4 cm -- for goalies. In three decades the average height of the goalkeepers increased by 7 cm!

Finally, let's compare these dynamics with those in the population.


# Compare to population

Our previous results expose significant height differences between players of various nations. Thus, it is reasonable to compare ice hockey players' height to the corresponding male population of their countries.

For the data on the height of males in population in the corresponding nations I used the [relevant scientific paper][hat]. I grabbed the data from the paper PDF using a nice little tool -- [tabula][tab] -- and also [deposited on figshare][cnt].

```{r, eval=FALSE}
# download the data from Hatton, T. J., & Bray, B. E. (2010).
# Long run trends in the heights of European men, 19th–20th centuries.
# Economics & Human Biology, 8(3), 405–413.
# http://doi.org/10.1016/j.ehb.2010.03.001
# stable URL, copied data (https://dx.doi.org/10.6084/m9.figshare.3394795.v1)

df_hb <- read.csv("https://ndownloader.figshare.com/files/5303878")

df_hb <- df_hb |>
        gather("country", "h_pop", 2:16) |>
        mutate(period = paste(period)) |>
        separate(period, c("t1", "t2"), sep = "/")|>
        transmute(cohort = (as.numeric(t1)+as.numeric(t2))/2, country, h_pop)

# calculate hockey players' cohort height averages for each country
df_hoc <- dfu |> group_by(country, cohort) |>
        summarise(h_hp = mean(av.height)) |>
        ungroup()
```

Unfortunately, our dataset on ice hockey players intersects with the data on population only for 8 countries: Austria, Denmark, Finland, France, Germany, Italy, Norway, and Sweden.

```{r, eval=FALSE}
# countries in both data sets
both_cnt <- levels(factor(df_hb$country))[which(levels(factor(df_hb$country)) %in% levels(df_hoc$country))]
both_cnt
```

```{r, eval=FALSE}
gg_hoc_vs_pop <- ggplot()+
        geom_path(data = df_hb |> filter(country %in% both_cnt),
                  aes(x = cohort, y = h_pop),
                  color = brbg11[9], size = 1)+
        geom_point(data = df_hb |> filter(country %in% both_cnt),
                   aes(x = cohort, y = h_pop),
                   color = brbg11[9], size = 2)+
        geom_point(data = df_hb |> filter(country %in% both_cnt),
                   aes(x = cohort, y = h_pop),
                   color = "white", size = 1.5)+
        geom_point(data = df_hoc |> filter(country %in% both_cnt),
                   aes(x = cohort, y = h_hp),
                   color = brbg11[3], size = 2, pch = 18)+
        stat_smooth(data = df_hoc |> filter(country %in% both_cnt),
                    aes(x = cohort, y = h_hp),
                    method = "lm", se = F, color = brbg11[1], size = 1)+
        facet_wrap(~country, ncol = 2)+
        labs(y = "height, cm", x = "birth cohort")+
        theme_few(base_size = 20, base_family = "mono")+
        theme(panel.grid = element_line(colour = "grey75", size = .25))
```

![](fig-06-players-vs-population.png)

**Figure 6. The comparison of height dynamics in ice hockey players (brown) and the corresponding male populations (green)**

In all the analyzed countries, ice hockey players are 2-5 cm higher that the nation's average. This is not very surprising since we expect some selection in sport. What is more interesting, in the developed countries the rapid increase in the height of males mostly leveled off in the birth cohorts of 1960s. Unlike the population trend, the height of ice hockey players continued to increase with roughly the same pace in all the analyzed countries except for Denmark.

For the cohorts of Europeans that were born in first half of 20-th century, the height of males increased by 1.18--1.74 cm per decade (Figure 7, middle panel). Starting from the birth cohorts of 1960s, the pace decreased to 0.15--0.80 per decade.


```{r, eval=FALSE}
# growth in population

df_hb_w <- df_hb |> spread(cohort, h_pop)
names(df_hb_w)[2:26] <- paste("y", names(df_hb_w)[2:26])

diffs <- df_hb_w[, 3:26]-df_hb_w[, 2:25]

df_hb_gr<- df_hb_w |>
        transmute(
            country,
            gr_1961_1980 = unname(apply(diffs[, 22:24], 1, mean, na.rm = T))*2,
            gr_1901_1960 = unname(apply(diffs[, 9:21], 1, mean, na.rm = T))*2,
            gr_1856_1900 = unname(apply(diffs[, 1:8], 1, mean, na.rm = T))*2
        ) |>
        gather("period", "average_growth", 2:4) |>
        filter(country %in% both_cnt) |>
        mutate(
            country = factor(country, levels = rev(levels(factor(country)))),
            period = factor(period, labels = c("1856-1900", "1901-1960", "1961-1980"))
        )


gg_hb_growth <- ggplot(df_hb_gr, aes(x = average_growth, y = country))+
        geom_point(aes(color = period), size = 3)+
        scale_color_manual(values = brbg11[c(8, 3, 10)])+
        scale_x_continuous(limits = c(0, 2.15))+
        facet_wrap(~period)+
        theme_few()+
        xlab("average growth in men's height over 10 years, cm")+
        ylab(NULL)+
        theme_few(base_size = 20, base_family = "mono")+
        theme(
            legend.position = "none",
            panel.grid = element_line(colour = "grey75", size = .25)
        )
```

![](fig-07-av-growth-pop.png)

**Figure 7. Average changes in male population**

The height increase for ice hockey players seems quite impressive if we compare it to the stagnating dynamics in the corresponding male populations. And the acceleration of goalkeepers' height is outright amazing.

The diverging trends in the height of ice hockey players and normal population is likely to be driven by the strengthening selection in sport.


# Selection in ice hockey

Looking through the literature on the selection in sport, I saw [the finding][sel] that showed a notable disproportion of professional sportsmen by the month of birth. There are much more sportsmen that were born in the first half of the year. They have a lasting advantage since the kids teams are usually formed by birth cohorts. Thus, those born earlier in the year always have a bit more time lived compared to their later born team mates, which means that they are physically more mature. It is easy to test the finding on our ice hockey players dataset.

```{r, eval=FALSE}
# check if there are more players born in earlier months
df_month <- df |> mutate(month = month(birth)) |>
        mutate(month = factor(month))

gg_month <- ggplot(df_month, aes(x = factor(month)))+
        geom_bar(stat = "count", fill = brbg11[8])+
        scale_x_discrete(breaks = 1:12, labels = month.abb)+
        labs(x = "month of birth", y = "# of players")+
        theme_few(base_size = 20, base_family = "mono")+
        theme(
            legend.position = "none",
            panel.grid = element_line(colour = "grey75", size = .25)
        )
```

![](fig-08-month-selectivity.png)

**Figure 8. The distribution of ice hockey players by month of birth**

True, the distribution is notably skewed -- there are much more players born in earlier months. When I further split the dataset by the decades of birth, it becomes clear that the effect becomes more evident with time (Figure 9). Indirectly, that means that the selection in ice hockey becomes tougher.

```{r, eval=FALSE}
# facet by decades
df_month_dec <- df_month |>
        mutate(dec = substr(paste(cohort), 3, 3) |>
                       factor(labels = paste("born in", c("1960s", "1970s", "1980s", "1990s"))))

gg_month_dec <- ggplot(df_month_dec, aes(x = factor(month)))+
        geom_bar(stat = "count", fill = brbg11[8])+
        scale_x_discrete(breaks = 1:12, labels = month.abb)+
        labs(x = "month of birth", y = "# of players")+
        facet_wrap(~dec, ncol = 2, scales = "free")+
        theme_few(base_size = 20, base_family = "mono")+
        theme(legend.position = "none",
              panel.grid = element_line(colour = "grey75", size = .25))
```

![](fig-09-month-selectivity-decades.png)


**Figure 9. The distribution of ice hockey players by month of birth -- separately by decades of birth**



***

::: {.callout-tip}
# The full R script can be downloaded [here][code]
:::



[habr]: https://habrahabr.ru/post/301340/
[photo]: https://www.instagram.com/p/BFjNdn7zORh
[raw]: http://www.iihf.com/iihf-home/history/past-tournaments/
[data]: https://dx.doi.org/10.6084/m9.figshare.3394735.v2
[hat]: https://dx.doi.org/10.1016/j.ehb.2010.03.001
[tab]: http://tabula.technology/
[cnt]: https://dx.doi.org/10.6084/m9.figshare.3394795.v1
[sel]: https://dx.doi.org/10.1080/02640410600908001
[code]: https://dx.doi.org/10.6084/m9.figshare.3395983.v2


---
title: "Hacking maps with ggplot2"
date: "2017-04-24"
image: teaser.png
categories: [r, ggplot2, rspatial]
---

***

This is a very short post on mapping with `ggplot2`.

Quite often, mapping some data, we do not need to follow scrupulously the formal requirements to geographical maps -- the idea is just to show the spatial dimension of the data. For instance, the network of rivers is not the most important information when we [map the elections outcome][ele]. Thus, the simplified mapping allows quite some freedom in transforming the geodata. The classical example of such geodata transformation is the [replacement and scaling of Alaska and Hawaii][ala] to be mapped alongside the mainland of the US. As one may see in this example, usually such geodata transformations utilize quite complex GIS tools in order to reposition an object in the coordinate system.

The interesting feature of mapping with `ggplot2` is that, before the actual plotting, geodata has to be fotrified (`ggplot2::fortify`) -- transformed to a simple dataframe object. Since fortified geodata is basically a dataframe, some simple transformations could be made really easily.

In my last [paper][osf], I needed to show a two-dimensional grouping of the European NUTS-2 regions in 4 quadrants according to GDP per capita and the share of working-age population (see Figure 8 in the [preprint][pre]). In line with the study setting, I did the grouping separately for Western, Southern, and Eastern Europe. I decided that the most straightforward way to show that on map would be to visually separate the 3 subregions of Europe. The task is easily doable through triggering the fortified geodata object -- see the code below.

First, the code to prepare the R session and load the (already prepared) data.

```{r, eval=FALSE}
library(tidyverse) # version 1.1.1
library(extrafont) # version 0.17
library(ggthemes) # version 3.4.0
font <- "Roboto Condensed"
library(hrbrthemes) # version 0.1.0
# The code is tested on a PC-win7-x64
# R version 3.3.3

# load the prepared geodata and stat data
load(url("https://ikashnitsky.github.io/share/1704-map-hacking/map-hacking.Rdata"))

# fortify the spatial objects
bord <- fortify(Sborders)
fort <- fortify(Sn2, region = 'id')
```

Next, I hack the geodata (`long` and `lat` variables) moving groups of NUTS-2 regions (Western, Southern, and Eastern Europe) apart. The appropriate values to move the groups of regions were found empirically.

```{r, eval=FALSE}
# hack geodata to separate macro-regions
fort_hack <- fort |>
        left_join(df |> select(id, subregion), 'id') |>
        mutate(long = ifelse(subregion=='E', long + 5e5, long),
               long = ifelse(subregion=='S', long + 2e5, long),
               lat = ifelse(subregion=='S', lat - 5e5, lat),
               long = ifelse(subregion=='W', long - 2e5, long))
```

Finally, we are ready to create the schematic map.

```{r, eval=FALSE}
# create color pallete
brbg <- RColorBrewer::brewer.pal(11,"BrBG")
brbg4 <- brbg[c(4,9,2,11)]

# create the two-dim legend
ggleg <- ggplot()+
        coord_equal(xlim = c(0,1), ylim = c(0,1), expand = c(0,0))+
        annotate('rect', xmin = .45, xmax = .6, ymin = .1, ymax = .25,
                 fill = brbg4[1], color = NA)+
        annotate('rect', xmin = .45, xmax = .6, ymin = .4, ymax = .55,
                 fill = brbg4[2], color = NA)+
        annotate('rect', xmin = .75, xmax = .9, ymin = .1, ymax = .25,
                 fill = brbg4[3], color = NA)+
        annotate('rect', xmin = .75, xmax = .9, ymin = .4, ymax = .55,
                 fill = brbg4[4], color = NA)+
        annotate('rect', xmin = .05, xmax = .95, ymin = .05, ymax = .95,
                 fill = NA, color = "grey20")+

        annotate('text', x = .35, y = c(.175, .475), vjust = .5, hjust = 1,
                 size = 6, fontface = 2, label = c('POOR', 'RICH'), family = font) +
        annotate('text', x = c(.525, .825), y = .65, vjust = 0, hjust = .5,
                 size = 6, fontface = 2, label = c('LOW', 'HIGH'), family = font)+
        annotate('text', x = .1, y = .9, vjust = 1, hjust = 0,
                 size = 7, fontface = 2, label = "LEGEND", family = font)+
        theme_map()

# create the blank map
basemap <- ggplot()+
        coord_equal(
            ylim=c(900000,5400000), xlim=c(2500000, 7000000), expand = c(0,0)
        )+
        theme_map()+
        theme(panel.border=element_rect(color = 'black',size=.5,fill = NA),
              legend.position = 'none')

# the main map
map_temp <- basemap +
        geom_map(map = fort_hack, data = df, aes(map_id=id, fill=group))+
        scale_fill_manual(values = brbg4[c(3, 1, 4, 2)])

# now combine the map and the legend
map <- ggplot() +
        coord_equal(xlim = c(0,1), ylim = c(0,1), expand = c(0,0))+
        annotation_custom(
            ggplotGrob(map_temp), xmin = 0, xmax = 1, ymin = 0, ymax = 1
        )+
        annotation_custom(
            ggplotGrob(ggleg), xmin = 0.72, xmax = 0.99, ymin = 0.72, ymax = 0.99
        )+
        labs(
            title = "Labour force and income in EU-27 NUTS-2 regions",
            subtitle = "Within each of the three macro-regions of Europe - Westren,
             Southern, and Eastern -\nNUTS-2 regions are classified in 4 groups
             according to the level of GDP per capita\nand the share of working
             age population in 2008",
            caption = "Data: Eurostat\nAuthor: Ilya Kashnitsky (ikashnitsky.github.io)"
        )+
        theme_ipsum_rc(plot_title_size = 30, subtitle_size = 20, caption_size = 15)
```

And here is the result.

***

![](hacked-map.png)

***

[ele]: https://twitter.com/data_debunk/status/856251551970717698
[ala]: https://rpubs.com/technocrat/thematic-alaska-hawaii
[osf]: https://osf.io/suwxf/
[pre]: https://ikashnitsky.github.io/doc/pubs/1702-nidi-wp-ik.pdf
---
title: "Young people neither in employment nor in education and training in Europe, 2000-2016"
date: "2017-07-18"
image: teaser.jpg
categories: [r, faceting]
---

***

As an example of Eurostat data usage I chose to show the dynamics of NEET (Young people neither in employment nor in education and training) in European countries. The example is using the brilliant `geofact` package.

```{r, eval=FALSE}
library(tidyverse)
library(lubridate)
library(forcats)
library(eurostat)
library(geofacet)
library(viridis)
library(ggthemes)
library(extrafont)

# Find the needed dataset code
# http://ec.europa.eu/eurostat/web/regions/data/database

# download fertility rates for countries
neet <- get_eurostat("edat_lfse_22")

# if the automated download does not work, the data can be grabbed manually at
# http://ec.europa.eu/eurostat/estat-navtree-portlet-prod/BulkDownloadListing

neet |>
        filter(geo |> paste |> nchar == 2,
               sex == "T", age == "Y18-24") |>
        group_by(geo) |>
        mutate(avg = values |> mean()) |>
        ungroup() |>
        ggplot(aes(x = time |> year(),
                   y = values))+
        geom_path(aes(group = 1))+
        geom_point(aes(fill = values), pch = 21)+
        scale_x_continuous(breaks = seq(2000, 2015, 5),
                           labels = c("2000", "'05", "'10", "'15"))+
        scale_y_continuous(expand = c(0, 0), limits = c(0, 40))+
        scale_fill_viridis("NEET, %", option = "B")+
        facet_geo(~ geo, grid = "eu_grid1")+
        labs(x = "Year",
             y = "NEET, %",
             title = "Young people neither in employment nor in education and training in Europe",
             subtitle = "Data: Eurostat Regional Database, 2000-2016",
             caption = "ikashnitsky.github.io")+
        theme_few(base_family =  "Roboto Condensed", base_size = 15)+
        theme(axis.text = element_text(size = 10),
              panel.spacing.x = unit(1, "lines"),
              legend.position = c(0, 0),
              legend.justification = c(0, 0))
```

![](neet-in-europe.png)

***

::: {.callout-tip}
# The whole code may be downloaded from [the gist][gist]
:::

[gist]: https://gist.github.com/ikashnitsky/5e073ccebbf1617e79d7d3cc080aceed
---
title: "Subplots in maps with ggplot2"
date: "2017-05-25"
image: teaser.png
categories: [r, ggplot2, rspatial]
---

***

Following the [surprising success][tw] of [my latest post][post], I decided to show yet another use case of the handy annotation custom function. Here I will show how to add small graphical information to maps -- just like putting a stamp on an envelope.

The example comes from my current work on a paper, in which I study the effect of urban/rural differences on the relative differences in population ageing (I plan to tell a bit more in one of the next posts). Let's have a look at the map we are going to reproduce in this post:

![](map.png)

So, with this map I want to show the location of more and less urbanized NUTS-2 regions of Europe. But I also want to show -- with subplots -- how I defined the three subregions of Europe (Eastern, Southern, and Western) and what is the relative frequency of the three categories of regions (Predominantly Rural, Intermediate, and Predominantly Rural) within each of the subregions. The logic of actions is simple: first prepare all the components, then assemble them in a composite plot. Let's go!

The code to prepare R session and load the data.

```{r, eval=FALSE}
# additional packages
library(tidyverse)
library(ggthemes)
library(rgdal)
library(viridis)
library(RColorBrewer)
library(extrafont)
myfont <- "Roboto Condensed"

# load the already prepared data
load(url("https://ikashnitsky.github.io/share/1705-map-subplots/df-27-261-urb-rur.RData"))
load(url("https://ikashnitsky.github.io/share/1705-map-subplots/spatial-27-261.RData"))
```

Now, I prepare the spatial objects to be plotted with ggplot2 and create a blank map of Europe -- our canvas.

```{r, eval=FALSE}
# fortify spatial objects
bord <- fortify(Sborders)
fort <- fortify(Sn2, region = "id")

# join spatial and statistical data
fort_map <- left_join(df,fort,"id")

# create a blank map
basemap <- ggplot()+
        geom_polygon(data = fortify(Sneighbors),aes(x = long, y = lat, group = group),
                     fill = "grey90",color = "grey90")+
        coord_equal(ylim = c(1350000,5450000), xlim = c(2500000, 6600000))+
        theme_map(base_family = myfont)+
        theme(panel.border = element_rect(color = "black",size = .5,fill = NA),
              legend.position = c(1, 1),
              legend.justification = c(1, 1),
              legend.background = element_rect(colour = NA, fill = NA),
              legend.title = element_text(size = 15),
              legend.text = element_text(size = 15))+
        scale_x_continuous(expand = c(0,0)) +
        scale_y_continuous(expand = c(0,0)) +
        labs(x = NULL, y = NULL)
```

![](basemap.png)

Okay, now the envelope is ready. It's time to prepare the stamps. Let's create a nice mosaic plot showing the distribution of NUTS-2 regions by subregions and the urb/rur categories. I found the simplest way to create a nice mosaic plot on [Stack Overflow][so].

```{r, eval=FALSE}
# create a nice mosaic plot; solution from SO:
# http://stackoverflow.com/a/19252389/4638884
makeplot_mosaic <- function(data, x, y, ...){
        xvar <- deparse(substitute(x))
        yvar <- deparse(substitute(y))
        mydata <- data[c(xvar, yvar)];
        mytable <- table(mydata);
        widths <- c(0, cumsum(apply(mytable, 1, sum)));
        heights <- apply(mytable, 1, function(x){c(0, cumsum(x/sum(x)))});

        alldata <- data.frame();
        allnames <- data.frame();
        for(i in 1:nrow(mytable)){
                for(j in 1:ncol(mytable)){
                        alldata <- rbind(alldata, c(widths[i],
                                                    widths[i+1],
                                                    heights[j, i],
                                                    heights[j+1, i]));
                }
        }
        colnames(alldata) <- c("xmin", "xmax", "ymin", "ymax")

        alldata[[xvar]] <- rep(dimnames(mytable)[[1]],
                               rep(ncol(mytable), nrow(mytable)));
        alldata[[yvar]] <- rep(dimnames(mytable)[[2]], nrow(mytable));

        ggplot(alldata, aes(xmin=xmin, xmax=xmax, ymin=ymin, ymax=ymax)) +
                geom_rect(color="white", aes_string(fill=yvar)) +
                xlab(paste(xvar, "(count)")) +
                ylab(paste(yvar, "(proportion)"));
}

typ_mosaic <- makeplot_mosaic(data = df |> mutate(type = as.numeric(type)),
                              x = subregion, y = type)+
        theme_void()+
        scale_fill_viridis(option = "B", discrete = T, end = .8)+
        scale_y_continuous(limits = c(0, 1.4))+
        annotate("text",x = c(27, 82.5, 186), y = 1.05,
                 label=c("EAST", "SOUTH", "WEST"),
                 size = 4, fontface = 2,
                 vjust = 0.5, hjust = 0,
                 family = myfont) +
        coord_flip()+
        theme(legend.position = "none")
```

![](mosaic.png)

Just what we needed. The next step is to build a small map showing the three subregions of Europe. But before we proceed to the maps, one thing has to be fixed. `ggplot2` [fails rendering nested polygons][poly]. With our regional dataset, London, for example, will not be shown if we do not account for this unpleasant feature.  Luckily, there is quite a simple [solution to fix that problem][fix].

```{r, eval=FALSE}
# a nice small function to overcome some mapping problems with nested polygons
# see more at SO
# https://stackoverflow.com/questions/21748852
gghole <- function (fort) {
        poly <- fort[fort$id %in% fort[fort$hole, ]$id, ]
        hole <- fort[!fort$id %in% fort[fort$hole, ]$id, ]
        out <- list(poly, hole)
        names(out) <- c("poly", "hole")
        return(out)
}
```

Now I build the small map of subregions.

```{r, eval=FALSE}
# pal for the subregions
brbg3 <- brewer.pal(11,"BrBG")[c(8,2,11)]

# annotate a small map of the subregions of Europe
an_sub <- basemap +
        geom_polygon(data = gghole(fort_map)[[1]],
                     aes(x = long, y = lat, group = group, fill = subregion),
                     color = NA)+
        geom_polygon(data  =  gghole(fort_map)[[2]],
                     aes(x = long, y = lat, group = group, fill = subregion),
                     color = NA)+
        scale_fill_manual(values = rev(brbg3)) +
        theme(legend.position = "none")
```

![](sub.png)

Finally, everything is ready to build the main map and stick the two subplots on top of it.

```{r, eval=FALSE}
# finally the map of Urb/Rur typology

caption <- "Classification: De Beer, J., Van Der Gaag, N., & Van Der Erf, R. (2014).
New classification of urban and rural NUTS 2 regions in Europe.
NIDI Working Papers, 2014/3.
Retrieved from http://www.nidi.nl/shared/content/output/papers/nidi-wp-2014-03.pdf
\nIlya Kashnitsky (ikashnitsky.github.io)"

typ <-  basemap +

        geom_polygon(data = gghole(fort_map)[[1]],
                     aes(x=long, y=lat, group=group, fill=type),
                     color="grey30",size=.1)+
        geom_polygon(data = gghole(fort_map)[[2]],
                     aes(x=long, y=lat, group=group, fill=type),
                     color="grey30",size=.1)+
        scale_fill_viridis("NEUJOBS\nclassification of\nNUTS-2 regions",
                           option = "B", discrete = T, end = .8)+
        geom_path(data = bord, aes(x = long, y = lat, group = group),
                  color = "grey20",size = .5) +

        annotation_custom(grob = ggplotGrob(typ_mosaic),
                          xmin = 2500000, xmax = 4000000,
                          ymin = 4450000, ymax = 5450000)+
        annotation_custom(grob = ggplotGrob(an_sub),
                          xmin = 5400000, xmax = 6600000,
                          ymin = 2950000, ymax = 4150000)+
        labs(title = "Urban / Rural classification of NUTS-2 regions of Europe\n",
             caption = paste(strwrap(caption, width = 95), collapse = '\n'))+
        theme(plot.title = element_text(size = 20),
              plot.caption = element_text(size = 12))
```

![](map.png)

Done!

Of course, it takes several iterations to position each element in its proper place. Then, one also needs to play with export parameters to finally get the desired output.

***

::: {.callout-tip}
# The full R script for this post is [here][code]
:::

[tw]: https://ikashnitsky.github.io/images/170525/prev-post-success.png
[post]: https://ikashnitsky.github.io/2017/align-six-maps/
[so]: http://stackoverflow.com/a/19252389/4638884
[poly]: https://stackoverflow.com/questions/21748852
[fix]: https://stackoverflow.com/a/32186989/4638884
[code]: https://ikashnitsky.github.io/share/1705-map-subplots/code.R
---
title: "Who is old? Visualizing the concept of prospective ageing with animated population pyramids"
date: "2017-03-31"
image: teaser.png
categories: [r, animaion]
---



***

![](swe-animated.gif)


This post is about illustrating the concept of prospective ageing, a relatively fresh approach in demography to refine our understanding of population ageing. This visualization was created in collaboration with my colleague [Michael Boissonneault][mic]: (mostly) his idea and (mostly) my implementation. The animated visualization builds upon Michael's viz prepared for the submission to the highly anticipated event at the end June 2017 -- [Rostock Retreat Visualization][rrviz]. My visualization of the [provided Swedish dataset][data] can be found in [the previous post][prev-post].

## Prospective ageing

Over the past decades the alarmist views of the upcoming population ageing disaster became widely spread. True, with the growing number of countries approaching the ending of the Demographic Transition, the average/median age of their population increases rapidly, which is something unprecedented in the documented human history. But does that imply an unbearable burden of elderly population in the nearest future? Not necessarily.

The demographic prospects depend a lot on how we define ageing. Quite recently [Waren Sanderson][waren] and [Sergei Scherbov][sch] proposed [^1] [^2] a new way to look at population ageing, they called it Prospective Ageing. The underlying idea is really simple -- age is not static: a person aged 65 (the conventional border deliminating elderly population) today is in many aspects not the same as a person ages 65 half a century ago. Health and lifespan improved a lot in the last decades, meaning that today people generally have much more remaining years of life at the moment of being recognized as elderly by the conventional standards. Thus, Sanderson and Scherbov proposed to define elderly population based on the estimation of the expected remaining length of life rather than years lived. Such a refined view of population ageing disqualifies the alarmist claims of the approaching demographic collapse. The would be paradoxical title of one the latest papers of Sanderson and Scherbov [^3] summarizes the phenomenon nicely: *Faster Increases in Human Life Expectancy Could Lead to Slower Population Aging*.

Of course, the choice of the new ageing threshold is a rather arbitrary question [^4]. It became usual to define this threshold at the remaining life expectancy of 15 years.

# Population pyramids for Sweden

Population pyramid is a simple and nice way to represent population composition and to compare changes in the age structure of a given population over time. We show the difference between conventional and prospective approach to the definition of the elderly population using Swedish data for the last half a century. Sweden is a natural choice for demographers aiming to play with rich and reliable data.

The data used for this visualization comes from [Human Mortality Database][hmd]. It can be easily accessed from an R session using [`HMDHFDplus`][hmdhfd] package by [Tim Riffe][tim] (for examples see my previous posts - [one][post1] and [two][post2]). For this exercise, I will use the dataset for Sweden that was provided for an application task for [Rostock Retreat Visualization][rrviz] [^5].

# Data preparation

```{r, eval=FALSE}
# load packages
library(tidyverse)
library(extrafont)
myfont <- "Ubuntu Mono"

# download data
df_swe <- read_csv("http://www.rostock-retreat.org/files/application2017/SWE.csv")
# copy at https://ikashnitsky.github.io/doc/misc/application-rostock-retreat/SWE.csv

# define the selection of years to visualize
years <- c(seq(1965, 2010, 5),2014)

df <- df_swe |> select(Year, Sex, Age, Exposure, ex) |>
        filter(Year %in% years) |>
        mutate(old_c = Age >= 65,
               old_p = ex <= 15) |>
        gather("type", "old", contains("old")) |>
        group_by(Year, Sex, type) |>
        mutate(share = Exposure / sum(Exposure)) |>
        ungroup() |>
        mutate(share = ifelse(Sex == 'f', share, -share))

names(df) <- names(df) |> tolower()


df_old <- df |> filter(old == T) |>
        group_by(year, sex, type, old) |>
        summarise(cum_old = sum(share)) |>
        ungroup()
```


# Visualization

Let's first have a look at the pyramids in 1965, 1990, and 2014 (the latest available year).

```{r, eval=FALSE}
gg_three <- ggplot(df |> filter(year %in% c(1965, 1990, 2014))) +
        geom_bar(aes(x = age, y = share, fill = sex, alpha = old),
                 stat = 'identity', width = 1)+
        geom_vline(xintercept = 64.5, size = .5, color = 'gold')+
        scale_y_continuous(breaks = c(-.01, 0, .01), labels = c(.01, 0, .01),
                           limits = c(-.02, .02), expand = c(0,0))+
        facet_grid(year~type) +
        theme_minimal(base_family = 'Ubuntu Mono') +
        theme(strip.text = element_blank(),
              legend.position = 'none',
              plot.title = element_text(hjust = 0.5, size = 20),
              plot.caption = element_text(hjust = 0, size = 10)) +
        coord_flip() +

        labs(y = NULL,
             x = 'Age') +

        geom_text(data = data_frame(type = c('old_c', 'old_p'),
                                    label = c('CONVENTIONAL', 'PROSPECTIVE')),
                  aes(label = label),
                  y = 0, x = 50, size = 5, vjust = 1,
                  family = 'Ubuntu Mono') +

        geom_text(data = df_old |> filter(year %in% c(1965, 1990, 2014), sex == 'f'),
                  aes(label = year),
                  y = 0, x = 30, vjust = 1, hjust = .5, size = 7,
                  family = 'Ubuntu Mono') +

        geom_text(data = df_old |> filter(year %in% c(1965, 1990, 2014), sex == 'f'),
                  aes(label = paste('Elderly\nfemales\n', round(cum_old*100,1), '%')),
                  y = .0125, x = 105, vjust = 1, hjust = .5, size = 4,
                  family = 'Ubuntu Mono') +

        geom_text(data = df_old |> filter(year %in% c(1965, 1990, 2014), sex == 'm'),
                  aes(label = paste('Elderly\nmales\n', round(-cum_old*100,1), '%')),
                  y = -.0125, x = 105, vjust = 1, hjust = .5, size = 4,
                  family = 'Ubuntu Mono')


#ggsave("figures/three-years.png", gg_three, width = 6, height = 8)
```

![](three-years.png)


# Animated pyramid

To get an animated pyramid I simply saved all the separate plots and then use the very convenient free online tool to make an animated image - [GIFCreator][gif] [^6].

```{r, eval=FALSE}
note <- 'The population pyramid can be used to compare change in the age structure of a given population over time. In many cases, doing so gives the impression of rapid aging. This is due to the fact that age is represented as a static variable; however, as Sanderson and Scherbov showed repeatedly, age is not static: a person age 65 in 1965 is in many aspects not the same as a person age 65 in 2015. In the right panel, old age is considered to start when the period remaining life expectancy reaches 15 years, thereby providing another look at the change in the age structure of a population. The gold line deliminates the conventional border of old age at 65. Elderly populations are filled with non-transparent colors. Authors: Michael Boissonneault, Ilya Kashnitsky (NIDI)'

# I will store the plots in a list
plots <- list()

for (i in 1:length(years)){

        gg <- ggplot(df |> filter(year == years[[i]])) +
                geom_bar(aes(x = age, y = share, fill = sex, alpha = old),
                         stat = 'identity', width = 1)+
                geom_vline(xintercept = 64.5, size = .5, color = 'gold')+
                scale_y_continuous(breaks = c(-.01, 0, .01), labels = c(.01, 0, .01),
                                   limits = c(-.02, .02), expand = c(0,0))+
                facet_wrap(~type, ncol = 2) +
                theme_minimal(base_family = 'Ubuntu Mono') +
                theme(strip.text = element_blank(),
                      legend.position = 'none',
                      plot.title = element_text(hjust = 0.5, size = 20),
                      plot.caption = element_text(hjust = 0, size = 10)) +
                coord_flip() +

                labs(title = paste("Sweden", years[i]),
                     caption = paste(strwrap(note, width = 106), collapse = '\n'),
                     y = NULL,
                     x = 'Age') +

                geom_text(data = data_frame(type = c('old_c', 'old_p'),
                                            label = c('CONVENTIONAL', 'PROSPECTIVE')),
                          aes(label = label),
                          y = 0, x = 115, size = 5, vjust = 1,
                          family = 'Ubuntu Mono') +

                geom_text(data = df_old |> filter(year == years[[i]], sex == 'f'),
                          aes(label = paste('Elderly\nfemales\n', round(cum_old*100,1), '%')),
                          y = .0125, x = 105, vjust = 1, hjust = .5, size = 4,
                          family = 'Ubuntu Mono') +

                geom_text(data = df_old |> filter(year == years[[i]], sex == 'm'),
                          aes(label = paste('Elderly\nmales\n', round(-cum_old*100,1), '%')),
                          y = -.0125, x = 105, vjust = 1, hjust = .5, size = 4,
                          family = 'Ubuntu Mono')

        plots[[i]] <- gg
}

# # a loop to save the plots
# for (i in 1:length(years)){
#         ggsave(paste0('figures/swe-', years[i], '.png'), plots[[i]],
#                       width = 8, height = 5.6)
# }
```


![](swe-animated.gif)

***

[^1]: Sanderson W, Scherbov S. 2005. Average remaining lifetimes can increase as human populations age. *Nature* **435**: 811–813 [DOI](https://doi.org/10.1038/nature03593): 10.1038/nature03593
[^2]: Sanderson W, Scherbov S. 2010. Remeasuring Aging. *Science* **329**: 1287–1288 [DOI](https://doi.org/10.1126/science.1193647): 10.1126/science.1193647
[^3]: Sanderson WC, Scherbov S. 2015. Faster Increases in Human Life Expectancy Could Lead to Slower Population Aging. *PLoS ONE* **10**: e0121922 [DOI](http://doi.org/10.1371/journal.pone.0121922): 10.1371/journal.pone.0121922
[^4]: See the [working paper](http://www.nidi.nl/shared/content/output/papers/nidi-wp-2017-01.pdf) of my colleagues devoted to this question
[^5]: By using this data, I agree to the [user agreement][lic]
[^6]: I did try to play with the package `gganimate`, though it produced a strange output.


[mic]: http://nidi.nl/en/staff/overview/boissonneault
[rrviz]: http://www.rostock-retreat.org
[data]: http://www.rostock-retreat.org/files/application2017/SWE.csv
[prev-post]: /2017/gender-gap-in-swedish-mortality/
[waren]: http://www.iiasa.ac.at/web/home/research/researchPrograms/WorldPopulation/Staff/Warren_Sanderson.html
[sch]: http://www.iiasa.ac.at/web/home/research/researchPrograms/WorldPopulation/Staff/Serguei-Scherbov.en.html
[post1]: https://ikashnitsky.github.io/2017/hmd-all-sex-ratio/
[post2]: https://ikashnitsky.github.io/2017/hmd-male-mortality-rus-jpn/
[hmd]: http://www.mortality.org
[lic]: http://www.mortality.org/Public/UserAgreement.php
[hmdhfd]: https://cran.r-project.org/web/packages/HMDHFDplus/index.html
[tim]: https://sites.google.com/site/timriffepersonal/about-me
[gif]: http://gifcreator.me



---
title: "Compare population age structures of Europe NUTS-3 regions and the US counties using ternary color-coding"
date: "2018-12-03"
image: teaser.png
categories: [r, demography, dataviz, rspatial]
---

***
```{r, include=FALSE}
knitr::opts_chunk$set(
  message = FALSE, warning = FALSE
)
```

On 28 November 2018 I presented a poster at [Dutch Demography Day][nvd] in Utrecht. Here it is:

```{r, echo=FALSE}
#| column: screen-inset
knitr::include_graphics("compare-poster.png")
```

The poster compares population age structures, represented as ternary compositions in three broad age groups, of European NUTS-3 regions and the United States counties. I used ternary color-coding, a dataviz approach that [Jonas Schöley][js] and me recently brought to R in [tricolore][tric] package.

In these maps, each region's population age composition is uniquely color-coded. Colors show direction and magnitude of deviation from the center point, which represents the average age composition. Hue component of a color encodes the direction of deviation: towards yellow – more elderly population (65+); cyan – more people at working ages (15–64); magenta–more kids (<15).

Of course, NUTS-3 regions and the US counties are not perfect to compare; on average, NUTS-3 regions are roughly ten times bigger. That's why the colors for European regions look quite muted, they are closer to the grey average composition.

The poster won [NVD][nvd] Poster Award via online voting of the conference participants.

![](poster-award.png)

***

::: {.callout-tip}
# Replication
This time I layouted the poster in [Inkscape][ink] rather than arranging everything with hundreds of R code lines. But all the elements of the posted are reproducible with code from [this github repo][repo].
:::

::: {.callout-note}
# See also
 - [Kashnitsky, I., & Schöley, J. (2018). Regional population structures at a glance. _The Lancet_, 392(10143), 209–210.][tl]
 - [My PhD project -- Regional demographic convergence in Europe][proj]
 - [Paper (Schöley & Willekens 2017) with the initial ideas for tricolore package][demres17]
 - [An example of ternary colorcoding used to visualize cause-of-death data][dr18]
:::

[nvd]: http://www.nvdemografie.nl/en/activities/dutch-demography-day/dutch-demography-day-2018
[js]: https://twitter.com/jschoeley
[tric]: https://cran.r-project.org/web/packages/tricolore/index.html
[ink]: https://inkscape.org
[repo]: https://github.com/ikashnitsky/compare-pop-eu-us

[tl]: https://doi.org/10.1186/s41118-017-0018-2
[proj]: https://osf.io/d4hjx/
[demres17]: https://doi.org/10.4054/DemRes.2017.36.21
[dr18]: https://github.com/ikashnitsky/demres-2018-geofacet
---
title: "Deep Catalan roots: playing with stringdist"
date: "2018-06-04"
image: teaser.jpg
categories: [r, demography]
---

***

# Preambule

This academic year I am participating in [European Doctoral School of Demography][edsd]. It is a unique one-year-long training for PhD students in demography. It keeps migrating across European research centers; this year Jim Vaupel's research group in Odense hosts the program. Best demographers visit us to give us various one-week-long courses. Here we are, the EDSD cohort 2017/18:

![](our-cohort.jpg)

# The creative task

Back in February (yes, I know, that was a quarter of a year ago, EDSD is quite dense), [Francisco Villavichencio][pancho] gave us a fascinating lecture on probabilistic string matching. Pancho used the approach in [one of his PhD papers][paper], in which he squeezed some demographic knowledge from scarce Catalan data on marriages that happened back in 16-17 centuries. Each marriage record contains name of a bride, name and surname of a groom, and the same data for two pairs their of parents. Having data for period spanning several adjacent generations, Pancho linked kids to their parents, thus getting interval censored dataset on demographic events of Renaissance Catalans. From this data he managed to estimate life expectancy of that population! Just make sure you check the paper if you want more details:

> Villavicencio F, Jordà JP, Pujadas-Mora JM. 2015. Reconstructing lifespans through historical marriage records of Barcelona from the sixteenth and seventeenth centuries. In *Population Reconstruction*, 199–216. Springer.

Our assignment was to play with a sample of the dataset and link daughters, who got married in 1597--1629, to their possible parents, who got married in 1573--1617, using string distance metrics. But that's not what I am about to show you.

# A side-walk solution

While doing the assignment, I decided to check if there lived "re-incarnations" of my group-mates in Barcelona back in the day. Instead of linking daughters to parents I linked us, 20 young demographers from various countries, to Catalans from 16-17 century. Here is how I handed in the assignment =)

![](hand-in.jpg)

So, let's dive into string distances and probabilistic string matching.

::: {.callout-important}
# Reproducibility note
For the sake of post's readability, this time I chose not to insert code chunks in the post. Instead, you are welcome to explore the [github repo][repo] that replicates all the analyses presented here. Since I cannot publish openly a big chunk of The Barcelona Historical Marriage Database, the guthub repo only contains minimal indicative data sample -- 10 best matching records to each of the groupmate's name.
:::

# Exploring the methods

There are multiple ways to calculate string distances. Most popular are implemented in `stringdist` R package. I'm not going to present the methods themselve, just check `stringdist` [documentation][doc] if interested. All of the methods are pretty costly computationally. Even when each particular comparison happens quite fast, the problem is that for each person, for whom a match is being searched, we need to run the comparison with each of the records in the other dataset. Of course, when you want to use several methods and average the result of their "voting", it takes even more time. Thus, a good idea is to narrow the list of candidates for matching as much as possible.

So, first I decided to compare the speed of these methods and choose the fastest for the first step comparison. Here is what I got calculating the distance between words "demography" and "democracy".

![](benchmarking.png)

As we see, there is quite some variation in the speed of different methods, and sometimes an iteration takes much longer than usual. The fastest method is "jw", Jaro-Winker distance. I use it for filtering out the pairs of candidate names that definitely have nothing in common. The choice of the cutting-off threshold is, of course, arbitrary and is based on empirical tests. The trade-off here is, on the one hand, to narrow down the list of candidates for match but, on the other hand, not to throw away the possible match based on just one distance measure.

# Finally, let's find our Catalan "ancestors"

Instead of choosing some cut-off value I ranked the results of "jw" distance and filtered 10 best fitting results for each of the names of my fellows. For these pre-selected candidates I calculated also several other distance measures: "osa", "lcs", "qgram", "cosine", and "jaccard". In the final tables I showed only 3 best matching results ranked by the geometric average of all the 6 calculated distances taken with equal weights.

## Here is the table for guys:

![](edsd-males.png)

My personal favorite here is **Hanbo Wo** becoming **Antonio Duc**.

## And a similar table for girls:

![](edsd-females.png)

Here I like **Elena Bastianelli** turning to **Elena Albanell**.

# Conclusions

There are 20 people in our EDSD group, 10 guys and 10 girls. We come from different countries: Germany, Italy, China, United States, Russia, Spain, Mexico, Bosnia, Poland, Hungary, Estonia, and Denmark. Our names are quite different from that of 16-17 century Catalans. Still, using string distance matching we can find similarly named persons in the historical dataset. This fun example just exposes the power of formal text mining approach.

***

::: {.callout-tip}
# Replication materials [at github][repo]
:::

[edsd]: https://www.demogr.mpg.de/en/education_career/european_doctoral_school_of_demography_1913/default.htm
[pancho]: https://twitter.com/VillavicencioFG
[paper]: https://link.springer.com/chapter/10.1007/978-3-319-19884-2_10
[doc]: https://cran.r-project.org/web/packages/stringdist/stringdist.pdf
[repo]: https://github.com/ikashnitsky/deep-catalan-roots
---
title: "A perfect RStudio layout"
date: "2018-05-22"
image: teaser.png
categories: [r, rstudio, trick]
---

***

Tiny things can separate life into "before" and "after". Here is one. For almost a year I've been daily sending mental "thank you" to [Ugo][ugo] who showed me how to re-organize panes in RStudio. Since then I've been spreading this tiny improvement so many times that I thought the tiny advise deserved a separate tiny post. Please note, below is an opinionated view of a comfortable UI improvement; feel free to ignore it if you don't like. This advise is **highly subjective**, though, I really believe it is useful.

I find the default 4-pane layout of RStudio is not perfect. One needs more space for the "Source" pane. Especially when RStudio is used as the main text editor, i.e. **the** program to write code, papers, blog posts, prepare presentations... Thus, the perfect solution is to move "Console" to the top-right position, leave least useful "History" in the bottom-left corner and collapse it, and move everything else to the bottom-right corner (see the screenshot).

![](layout-annotated.png)

Just go to "Tools" --> "Global options" --> "Pane layout" and fix it.

![](options.png)

That's it!

Just enjoy your improved RStudio, **the** program.

P.S. It is also very handy to memorize and use the hot keys for panes. `CTRL + #` moves focus to the pane, `CTRL + SHIFT + #` maximizes the pane.

![](hotkeys.png)

***

[ugo]: https://sciences.social/@ugobas
---
title: "sjrdata: all SCImago Journal & Country Rank data, ready for R"
date: "2018-09-23"
image: teaser.png
categories: [r, package, bibliometrics]
---

***

![](sjrdata-logo.png)

SCImago Journal & Country Rank provides valuable estimates of academic journals' prestige. The data is freely available at [the project website][site] and is distributed for deeper analysis in forms of .csv and .xlsx files. I downloaded all the files and pooled them together, ready to be used in R.

Basically, all the package gives you three easily accessible data frames: `sjr_journals` (Journal Rank), `sjr_countries` (Country Rank, year-by-year), and `sjr_countries_1996_2017` (Country Rank, all years together).

The whole process of data acquisition can be found in the [github repo][repo] (`dev` directory) or this [gist][gist].

# How to use `sjrdata`

Install the package from github, load it and use the data.

The installation will take a while since the main dataset `sjr_journals` is pretty heavy (15.7MB compressed).

```{r, eval=FALSE}
# install
devtools::install_github("ikashnitsky/sjrdata")

# load
library(sjrdata)

# use
View(sjr_countries)
```

# A couple of examples

Let's compare _Nature_ and _Science_.

```{r, eval=FALSE}
library(tidyverse)
library(sjrdata)

sjr_journals |>
    filter(title %in% c("Nature", "Science")) |>
    ggplot(aes(cites_doc_2years, sjr, color = title))+
    geom_path(size = 1, alpha = .5)+
    geom_label(aes(label = year |> str_sub(3, 4)),
              size = 3, label.padding = unit(.15, "line"))
```

![](nature-science.png)

Several demographic journals.

```{r, eval=FALSE}
sjr_journals |>
    filter(title %in% c(
        "Demography",
        "Population and Development Review",
        "European Journal of Population",
        "Population Studies",
        "Demographic Research",
        "Genus"
    )) |>
    ggplot(aes(cites_doc_2years, sjr, color = title))+
    geom_point()+
    stat_ellipse()+
    scale_color_brewer(palette = "Dark2")+
    coord_cartesian(expand = F)
```

![](demographic-journals.png)

***

[site]: https://www.scimagojr.com
[repo]: https://github.com/ikashnitsky/sjrdata
[gist]: https://gist.github.com/ikashnitsky/3133422ef85ff3f3d65be9926d6bd990
---
title: "Regional population structures at a glance"
date: "2018-07-21"
image: teaser.png
categories: [r, dataviz, demography]
---

***

![](full-text.png)

I am happy to announce that our paper is [published today in _The Lancet_][doi].

> Kashnitsky I, Schöley J. 2018. Regional population structures at a glance. *The Lancet* **392**: 209–210. [https://doi.org/10.1016/S0140-6736(18)31194-2][doi]

# At a glance

Demographic history of a population is imprinted in its age structure. A meaningful representation of regional population age structures can tell numerous demographic stories – at a glance. To produce such a snapshot of regional populations, we use an innovative approach of **ternary colour coding**.

Here is the map:

![](the-map.png)

# We let the data speak colours

With ternary colour coding, each element of a three-dimensional array of compositional data is represented with a unique colour. The resulting colours show direction and magnitude of deviations from the centrepoint, which represents the average age of the European population, and is dark grey. The hue component of a colour encodes the direction of deviation: yellow indicates an elderly population (>65 years), cyan indicates people of working age (15–64 years), and magenta indicates children (0–14 years).

The method is very flexible, and one can easily produce these meaningful colours using our [R package `tricolore`][tric]. Just explore the capabilities of the package in a built-in shiny app using the following lines of code:

```{r, eval=FALSE}
install.packages("tricolore")
library(tricolore)
DemoTricolore()
```

***

::: {.callout-tip}
# Replication materials [at github][repo]
:::

::: {.callout-important}
# Folow us on Twitter: [ikashnitsky][ik], [jschoeley][js]
:::

::: {.callout-note}
# See also
 - [**My PhD project -- Regional demographic convergence in Europe**][proj]
 - [Blog post on the first version of the map presented at Rostock Retreat Visualization in June 2017][post]
 - [Paper (Schöley & Willekens 2017) with the initial ideas for tricolore package][dr17]
 - [An example of ternary colorcoding used to visualize cause-of-death data][dr18]
 - [My other paper , which explores regional differences in population age structures][genus]
:::

[doi]: https://doi.org/10.1016/S0140-6736(18)31194-2
[tric]: https://github.com/jschoeley/tricolore
[repo]: https://github.com/ikashnitsky/the-lancet-2018
[ik]: https://twitter.com/ikashnitsky
[js]: https://twitter.com/jschoeley

[genus]: https://doi.org/10.1186/s41118-017-0018-2
[proj]: https://osf.io/d4hjx/
[post]: https://ikashnitsky.github.io/2017/colorcoded-map/
[dr17]: https://doi.org/10.4054/DemRes.2017.36.21
[dr18]: https://github.com/ikashnitsky/demres-2018-geofacet
---
title: "See you in Barcelona this summer"
date: "2019-03-07"
image: teaser.png
categories: [r, dataviz, demography]
---

***

![](tutors-bg.png)

Have you been feeling lately that you are missing out the coolest skill-set in academia?

<iframe src="https://gifer.com/embed/fxTM" width=480 height=269.011 frameBorder="0" allowFullScreen></iframe>

Here is you chance to cut in and dive into R.

In July [BaRacelona Summer School of Demography][bssd] welcomes dedicated scholars, aspiring or established, to help them migrate to the world of new oppoRtunities.

The school consists of 4 modules. You can take them all or choose specific ones. The first, instructed by [Tim Riffe][tim], introduces the basics of R. The second, instructed by [myself][ilya], focuses on visualizing data, very general with a slight tilt towards population data. The third, instructed by [Marie-Pier Bergeron Boucher][mariepier], presents the foundations of demographic analysis with R. Even if you are not (yet) a demographer these methods are very general and are usable in a wide range of social science disciplines. Finally, the fourth course, instructed by [Juan Galeano][juan], teaches the powerful ways to unleash the spatial dimension of data analysis.

There are still several places available, the call  closes on March 31st.

I'll be happy to see you in sunny Catalonia!

***

[bssd]: https://bit.ly/bssd2019
[tim]: https://twitter.com/timriffe1
[ilya]: https://twitter.com/ikashnitsky
[mariepier]: https://portal.findresearcher.sdu.dk/da/persons/mpbergeron
[juan]: https://twitter.com/CEDemografia
---
title: "Dotplot – the single most useful yet largely neglected dataviz type"
date: "2019-07-19"
image: teaser.jpeg
categories: [r, dataviz, trick]
---

***

::: {.callout-important}
I have to confess that the core message of this post is not really a fresh saying. But if I was given a chance to deliver one dataviz advise to every (ha-ha-ha) listening mind, I'd choose this: **forget multi-category bar plots and use dotplots instead**.
:::

I was converted several years ago after reading [this brilliant post][post]. Around the same time, as I figured out later, demographer Griffith Feeney wrote a [similar post][grif]. From fresher examples, there are chapters discussing dotplot visualizations in [Claus Wilke's book][wilk] and [Kieran Healy's book][heal]. So, what are dotplots and what's so special about them?

Basically, dotplots are the same regular barplots rotated 90 degrees and optimized on "ink usage", i.e. dots represent values along the continuous horizontal axis. This leaves the vertical axis for the categorical variable allowing to write out long labels for the categories as normal horizontally aligned text (nobody likes to read that awful 45 degrees labels). The use of dots instead of bars allows to represent several comparable values for each category.

Here is a sample of some ugly plots that I found in the recent papers in my personal library of papers.

![](examples.png)

It was not difficult to compose such a selection as these plots are, unfortunately, super popular. I think, the guy to blame here is (surprise-surprise) Excel. I'm failing to understand how such a basic plot type can be missed out.

Just to be clear, I'm guilty too. Before the happy rstats-ggplot switch, I've been producing the same Excel plots. Here is an example from my [2014 working paper][wp] on internal youth migration in the central regions of Russia.

![](two-figures.png)

These two figures became one in the final paper recently [published in GeoJournal][geoj]. I think it's a nice example how information dense, pretty looking (very subjective here), and easy to read a dotplot can be.

![](one-figure.png)

The figure shows discrepancy in migration estimates based on statistical record and census indirect estimates.

The code to replicate this figure is in [this gist][gist]. A couple of coding solutions might be interesting here. First, the trick to offset vertically the dots for the two cohorts. Yet I realise that the way I implemented it is a bit clumsy; if you know a more elegant solution please let me know. Also, I believe in some cases composing the legend manually pays off, especially when we are dealing with two-dimensional legend. If the plot has some empty area it's always a good idea to move the legend in the plotting area thus cutting away the margins.

***

[post]: http://www.b-eye-network.com/view/2468
[grif]: http://demographer.com/dsitl/08-cleveland-dot-plots/
[wilk]: https://serialmentor.com/dataviz/visualizing-amounts.html#dot-plots-and-heatmaps
[heal]: https://socviz.co/workgeoms.html#continuous-variables-by-group-or-category
[geoj]: https://doi.org/10.1007/s10708-018-9953-5
[wp]: https://ikashnitsky.github.io/www.nidi.nl/shared/content/output/papers/nidi-wp-2014-14.pdf
[gist]: https://gist.github.com/ikashnitsky/2f3e2b2af6f50911bb775bbce6eb0fb8
---
title: "Zotero hacks: unlimited synced storage and its smooth use with rmarkdown"
date: "2019-03-14"
image: teaser.png
categories: [r, tutorial]
---

***

::: {.callout-note}
# About this tutorial
Here is a bit refreshed translation of [my 2015 blog post][post], initially published on Russian blog platform [habr.com][habr]. The post shows how to organize a personal academic library of unlimited size for free. This is a funny case of a self written manual which I came back to multiple times myself and many many more times referred my friends to it, even non-Russian speakers who had to use Google Translator and infer the rest from screenshots. Finally, I decided to translate it adding some basic information on how to use Zotero with rmarkdown.
:::

![](teaser.png)

# A brief (and hopefully unnecessary for you) intro of bibliographic managers

Bibliographic manager is a life saver in everyday academic life. I suffer almost physical pain just thinking about colleagues who for some reason never started using one -- all those excel spreadsheets with favorite citations, messy folders with PDFs, constant hours lost for the joy-killing task of manual reference list formatting. Once you start using a reference manager this all becomes a happily forgotten nightmare.

I tend to think of bibliographic metadata as LEGO.

![](lego.jpg)

For each paper (book chapter / pre-print / R package) we have a number of metadata pieces -- title, authors, date published, etc. These are the LEGO blocks. For different bibliographic styles we just need to re-shuffle those blocks inserting various commas, semicolons, and quotation marks.

Bibliographic manager keeps track of all the LEGO blocks and knows (learns easily) how to compose proper citation styles out of them. All we need is to [download a specific journal's citation style][csl]. There are more than six thousand bibliographic styles! [This is my #1 argument against the conspiracy ideas of some centralized power that rules our world .)]

# Why Zotero?

There are dozens of bibliographic managers out there ([see a comparative table][wiki]). Some of them are free, the others require paid subscriptions. Probably, the most popular two are [Zotero][zotero] and [Mendeley][mendeley]. Both are free to use and make money by offering cloud storage to sync PDFs of the papers. Yet, both give some limited storage for free -- Zotero gives 300MB, and Mendeley gives 2GB.

Why do I choose and recommend Zotero then? Because it's fairly easy to set-up Zotero so that the free 300MB are only used to sync metadata (which in practice means almost infinite storage), and the PDFs are synced separately using a cloud solution of one's choice (I use Google Drive). **It's the main set-up hack that I'm showing in this blog post**. There is no similar hack for Mendeley, and with them at some point one is bound to pay for extra storage.

Another consideration in favor of Zotero is that it's an open-source program with strong community and outspoken commitment to stay free forever, while Mendeley is an Elsevier for-profit product. Academic community knows a lot about Elsevier in particular and for-profit products in general. Here the story of Academia.edu is very indicative. Have a look at [this Forbes piece][forbes]. As a career-long decision I'm confident in choosing Zotero. And the project keeps developing nicely -- just look at the recent Zotero blog entries on the new features such as [Google Docs integration][gdocs], [Unpaywall integration][unp] and [a new web service for quick citations][zbib].

Finally, an example of how strong Zotero community is. Once I figured out there the style repository does not have a style for Demographic Research, one of the best journals in demography. I've opened [a request on Zotero forum][req] and in two days the style was created.

# Prerequisites

1. [Download and install Zotero][down]. It's cross-platform and works smoothly with various systems, even when the same database is sycned in parallel on machines with different operation systems. I've used win+linux and win+mac -- no sync problems ever.

2. From the same [download page][down] go to install Zotero Connector, a browser extension that helps to retrieve bibliographic metadata.

3. Create an [account on Zotero website][reg]. It will be used later on to sync the database of bibliographic metadata.

4. Download and install the two plugins we'll need -- [ZotFile][zot] (organizes the database of PDFs) and [Better BibTeX][bbt] (exports the library to .bib, we'll use it later with rmarkdown). The plugins for Zotero are .xpi archives. To install the plugins open Zotero and click `Tools --> Add-ons`. A separate window for `Add-ons manager` will pop-up.

![](plugin.png)

There we need to click the options gear button and select `Install Add-on From File` option. Finally navigate to the .xpi file and install. Zotero will ask to restart, please do.

We are ready to go through the setup step-by-step.

# Zotero preferences

First, let's walk though Zotero Preferences. To edit them click `Edit --> Preferences`. A window with several tabs pops up.

**General**. I only uncheck the option to create automatic web page snapshots which I find not so useful compared with all the cluttering effect of all those multiple small files needed to replicate an html page locally.

![](pref-general.png)

**Sync**. Here we need to specify the account details to sync our database. It is important to uncheck the option of full-text sync otherwise the 300MB storage will quickly get filled. We'll have the solution for full text a bit later.

![](pref-sync.png)

**Search**. Defines the database for internal search engine. Defaults are reasonable.

**Export**. Choose the style for quick export using `Shift+Ctrl+C` shortcut.

**Cite**. Citation styles stored locally. One nice feature here is the `Get additional styles` link which brings an integrated selection from the whole [Zotero Styles Database][csl]. Styles can also be installed from local .csl files, for that press the `+` button. Don't miss the `Word Processors` sub-tab. There we can get the plugins that integrate Zotero to Microsoft Word and Libre Office.

![](pref-cite.png)

**Advanced**. Here we are most interested in the sub-tab `Files and Folders`. This is the most important step to separate the storage of metadata and files.

![](pref-files.png)

The **first** path should lead to a directory which stores the full-text PDFs, I call it `zotero-library`. This directory should be somewhere in the part of the local file system that is synced. In my case it's the directory named `ikashnitsky`, which I sync with Google Drive. The **second** path leads to the system files of Zotero, I call it `zotero-system`. This directory should be placed somewhere in the non-synced part of the local file system. It will be updated by the native Zotero sync, and it's better if those system files are not overwritten by any external sync software.

**Better BibTeX**. This tab appears after we install the Better BibTeX extension. The extension is needed to export the whole bibliographic library (or some of its parts) as a plain .bib text file. This step is needed to use Zotero in RStudio while writing academic papers with `rmarkdown`.

![](pref-bbt.png)

The most important option here is to define the rules for creating citation keys. There are almost infinite number of ways one can define these keys ([check the manual][keys]). My personal choice is `[auth:lower][year][journal:lower:abbr]`, which means that a key consists of the first author's name, publication year, and the first letters abbreviation of the journal's title, everything in lower case. Thus the key for my [most recent paper][tesg] published in *Tijdschrift voor economische en sociale geografie* is `kashnitsky2019tveesg`.

# ZotFile Preferences

Next we need to setup ZotFile. This extension helps to rename PDFs according to pre-defined rules and store them in a hierarchical database with meaningful names of the sub-directories. To open the setup window click `Tools --> ZotFile Preferences`. Again, the window has several tabs.

**General**. Here we define two paths. The **first** is the default location of the files downloaded by your browser. This option tells ZotFile where to look for the PDFs to process when you import a paper from the publisher's website (recall that earlier we installed Zotero Connector). The **second** path leads to the local directory created for the full-text PDFs, the one that I named `zotero-library` and which is synced with an external cloud solution of our choice.

![](zf-general.png)

To navigate easier in this database of PDFs check the option `Use subfolder defined by`. Here again we have a wide choice of the ways to define the rules to name the sub-directories. Click the info icon to learn the options. I choose to simply have a separate folder for each first author.

**Tablet Settings**. Apparently, this menu allows to setup an exchange of PDFs with a tablet. I've never used it, thus omit.

**Renaming Rules**. Here it's important to make sure that ZotFile is responsible for renaming. Then we define how to rename the PDFs based on the bibliographic metadata available. Again, here we have many many options. My choice is {% raw %}`{%a_}{%y_}{%t}`{% endraw %} which yields file names like `kashnitsky_2018_russian_periphery_is_dying_in_movement.pdf` (again an example for [my recent paper][geoj] in *GeoJournal*).

![](zf-renaming.png)

**Advanced Settings**. I only checked the option to replace all the non-standard symbols with plain ASCII.

**A very important note on ZotFile!**.

If you parse the metadata manually from a PDF, make sure to rename the file using ZotFile. For that right-click the metadata record `Manage Attachments --> Rename Attachments`. This action explicitly tells to use ZotFile for renaming and will move the renamed PDF to a proper sub-directory.  The attachment in Zotero should not look like a PDF file...

![](att-pdf.png)

... but rather should be a link to the renamed file.

![](att-link.png)

In these screenshot I also show the location of the actual PDFs in both cases (right-click the metadata record `Show File`). As you can see, in the first case the PDF is located in a meaninglessly named folder somewhere in the `zotero-system` directory. In contrast, the renamed by ZotFile PDF is located in a properly named sub-directory in `zotero-library`. Thus, in the latter case the PDF is synced to my Google Drive and can be accessed from anywhere.

![](gdrive.png)

More importantly, when I need to restore my whole database of academic papers on another machine, I just need to go through these steps. As long as the system metadata data base is synced by Zotero and I provide Zotero the link to a PDFs storage, it will recognize all the relative paths to the files, and the whole library is restored. This setup also makes it possible to have the same continuously synced library on multiple machines. The hack is in ZotFile which adds a `file` path line to the metadata of the papers.

![](zf-bib.png)

As long as I keep the settings unchanged, everything will be synced fine across multiple devices. In the end, I enjoy the unlimited storage of my PDFs with the very nice and reliable native sync of metadata form Zotero.

**Final remark on Zotero**. Feel free to clean from time to time all the clutter from `zotero-system/storage`.

# Use Zotero library in RStudio with `rmarkdown`

Zotero has a very nice built-in integration with Microsoft Word and Libre Office. A bit of magic is needed if one wants to use it with LaTeX or (like me) with `rmarkdown`. The magic part is the Better BibTeX plugin, which we've installed and set up earlier.

Better BibTeX offers an easy way to export bibliographic records from Zotero as plain .bib text and keep the file updated once the records are changed. Just right-click on the collection in Zotero and choose `Export Collection`.

![](bbt-export.png)

Then in the next window choose to export as Better BibTeX and check the option to `Keep updated`.

![](bbt-menu.png)

The output .bib file should be placed in the directory from which we are going to knit the .rmd file. The name of the .bib is specified in YAML header of the .rmd. Here is an example from my [running project][gf] with [jmaburto][jm].

![](yaml.png)

Note that the exact YAML functions may vary depending on the `rmarkdown` template package. In this case I'm using `bookdown`, which also allows to specify the desired bibliographic style, .csl file should also be copied to the knit directory.

Then, everything is ready to use the citation keys to generate citations throughout the text. For details on `rmarkdown` citation syntax, it's better to refer to [RStudio's manual][rmd] (see below) or [the relevant chapter][bookd] of [xieyihui][xie]'s book on `bookdown`.

<iframe width="100%" height="500px" style="background: #FFFFFF;" src="https://rmarkdown.rstudio.com/authoring_bibliographies_and_citations.html"></iframe>

The final hint here is to use `citr` package, which brings an easy and interactive way to select citations from the .bib file. Once the package in installed, an RStudio addin `Insert citation` appears which executes the `citr:::insert_citation()` command (you can assign a short-key to the addin). This function brings a shiny app to select a citation interactively. More details in the [github repo][citr].

::: {.callout-tip}
# Happy paper writing with Zotero and RStudio!
:::

***

[post]: https://habr.com/en/post/271045/
[habr]: https://habr.com/en/top/
[csl]: https://www.zotero.org/styles
[wiki]: https://en.wikipedia.org/wiki/Comparison_of_reference_management_software
[zotero]: https://www.zotero.org
[mendeley]: https://www.mendeley.com/download-desktop/
[gdocs]: https://www.zotero.org/blog/google-docs-integration/
[unp]: https://www.zotero.org/blog/improved-pdf-retrieval-with-unpaywall-integration/
[zbib]: https://www.zotero.org/blog/improved-pdf-retrieval-with-unpaywall-integration/
[forbes]: https://www.forbes.com/sites/drsarahbond/2017/01/23/dear-scholars-delete-your-account-at-academia-edu/
[req]: https://forums.zotero.org/discussion/57130/style-request-demographic-research
[down]: https://www.zotero.org/download/
[reg]: https://www.zotero.org/user/register/
[zot]: http://zotfile.com
[bbt]: https://retorque.re/zotero-better-bibtex/
[keys]: https://retorque.re/zotero-better-bibtex/citation-keys/
[tesg]: https://doi.org/10.1111/tesg.12357
[geoj]: https://doi.org/10.1007/s10708-018-9953-5
[gf]: https://doi.org/10.31219/osf.io/f49n6
[jm]: https://github.com/jmaburto
[xie]: https://github.com/yihui
[bookd]: https://bookdown.org/yihui/bookdown/citations.html
[rmd]: https://rmarkdown.rstudio.com/authoring_bibliographies_and_citations.html
[citr]: https://github.com/crsh/citr
---
title: "Show all data in the background of your faceted ggplot"
date: "2020-06-19"
image: teaser.png
aliases:
  - "/2023/background-data/"
categories: [r, faceting, dataviz, ggplot2, trick]
---

```{r, include=FALSE}
knitr::opts_chunk$set(
  message = FALSE, warning = FALSE
)
```

***

One of the game-changing features of `ggplot2` was the ease with which one can explore the dimensions of the data using **small multiples**.[^1] There is a small trick that I was to share today -- put all the data in background of every panel. This can considerably improve comparability of the data across the dimension which splits the dataset into the subsets for the small multiples. Better to show right away what I mean and then explain in details.

There is a weekly dataviz challenge organized by Cole Knaflic. [One particular challenge][swd] stroke me as an ultimate case to showcase this background data trick. Here are the two plots:[^2] **the challenge one** and **my version**.

[![Image to improve](swd-challenge.png)](https://ikashnitsky.github.io/2023/background-data/swd-challenge.png){width=70%}

[![My version](improved.png)](https://ikashnitsky.github.io/2023/background-data/improved.png)

It is impossible to meaningfully compare and distinguish multiple spaghetti lines at once. Thus, my choice here was to use small multiples and look at the lines one by one. But we still want to compare the lines. For this, I added the pale background lines that show the spread of all data. Note that I also sorted the small multiples in the decreasing order and added the average line in yellow.

But the **main trick** here is adding all the data in the background. And with `ggplot2` it's super easy to do. All we need is to add a layer to the plot in which we modify the data by removing the variable that was used for faceting.

Here we use the nice feature of `ggplot2` -- the layers inherit whatever you specify in the main `ggplot()` call. In this case our background layer is inheriting the `data` parameter and all we need is just to remove the variable that is later used for faceting. Consider the following pseudo-code:

```{r, eval=FALSE}
df |>
    ggplot(PLOT_PARAMETERS)+
    geom_WHATEVER(data = df |> select(-FACETING_VARIABLE))+
    facet_wrap(~ FACETING_VARIABLE)
```

Once we've done this, `gpplot2` no longer knows how to assign subsets of data to the corresponding small multiples. Note that this only happens in the layer where we perform the trick and explicitly throw out the faceting variable. As the result, in each small multiple we end up with all the data in this layer. Put this layer in the background, make it appropriately pale/transparent -- and that's it. I find this dataviz trick amazingly straightforward, simple, and powerful.

***

::: {.callout-tip}
# You can replicate the full figure above using the `R` code from this [gist][gist]
:::

::: {.callout-note}
# This post is one in the **faceting series**. Other posts:
- [Save space in faceted plots][shrink]
:::

[^1]: At some point [`lattice`][lat] became pretty popular for the task, but then `ggplot2` entered the scene.
[^2]: Images are clickable

[cole]: https://twitter.com/storywithdata
[swd]: https://twitter.com/storywithdata/status/1274019877779619841
[lat]: https://cran.r-project.org/web/packages/lattice
[gist]: https://gist.github.com/ikashnitsky/ee73b39e93f9d074d3362c7fb0d6c815
[shrink]: https://ikashnitsky.github.io/2023/shrink-space
---
title: "What is life expectancy? And, even more important, what it isn't"
date: "2021-03-05"
image: teaser.png
categories: [r, 101, demography]
---

***

It really is a remarkable achievement and maybe a lot of luck that the world mundanely operates with such a complex indicator as life expectancy. Unlike many statistics and quantities of general use that are being monitored and reported regularly, life expectancy is not observed directly. It's an output of a **mathematical model** called **life table**. And as any model it comes with a certain load of assumptions and limitations, which are easily forgotten and omitted in the everyday interpretations and misinterpretations of the indicator.

So, why do we need any mathematical modelling in the first place? Consider a seemingly simple task: you want to know how long people live. What can be easier? Let's just see how many years lived those who died recently. Why not? Such a metric would be massively driven by population age structure. For the most of the recent history human populations were rapidly growing, which means that each next generation was bigger than the previous one. Relative differences in the size of generations affect the age composition of those dying.

Okay. Then why don't we simply take a group of people born in the same year and see how long on average they live? We could (demographers call such groups cohorts). But it takes remarkably long to wait until the last person in the cohort dies. And we want to know what's happening **now**.

How can we learn what's happening now? Well, for that we need a mathematical model. We cannot observe the unfulfilled lifespans directly but we can construct/imagine an artificial population to help us understand the current mortality. The idea is simple: let’s take those dying now and divide them by the size of their age groups. This yields age-specific death rates – the key input for the life table needed to calculate life expectancy. Now, let's take an imaginary cohort and see how long would they live on average if they experience these observed age-specific death rates. The imaginary population is know as a **synthetic cohort**. And here comes the main assumption of the life table: The model assumes that the observed age-specific death rates stay unchanged throughout the hypothetical lives of the hypothetical people in the synthetic cohort.

This big assumption of unchanging age profile of death rates almost never holds in real life. Mortality in human populations keeps improving beyond the most optimistic expectations. For decades the best demographers were systematically underestimating the progress in mortality reduction [@oeppen2002s].

![](oeppen-vaupel.jpg)

**The horizontal lines are the limits of human population-level life expectancy as anticipated by renowned scholars; points are the actual data in the world leading countries. Source: (Oeppen and Vaupel, 2002)**

Life expectancy is a snapshot of the current mortality and is not a projection/forecast of the actual experience of the newborn cohorts. The current nature of period life expectancy is nicely [illustrated by Dr. Robert Chung][robert-1]: “I have a car that can display "driving range" given its estimate of fuel level and how I'm driving. When climbing a steep hill, the range can decrease a lot; when descending, the range can increase. That's what period e(x) is like.”

But if life expectancy talk about now and not the future, why is it called “expectancy” in the first place? This rather unfortunate and confusing [naming comes from statistics][robert-2], where “expected value” is a standard term for the mean of a distribution. The connotation crossing is rather unfortunate and as it strongly nudges the common future oriented misinterpretation of life expectancy.

The most popular error in public perception of period life expectancy forgets about the heavy assumption of the synthetic cohort (constant age-specific death rates throughout their hypothetic lives anchored in current year) and talks about the future of kids being born now. In normal years this large interpretation error is somewhat masked by the gradual and often close to linear improvements in mortality. A rule of thumb is to simply add ~6 years to period life expectancy to obtain a reasonable cohort estimate [@goldstein2006ps]. Mortality shocks like 2020 are a different story though. Here the "forward looking" (mis)interpretation of period life expectancy projects the **shock levels of mortality** into the future. Of course this doesn't happen. Shocks are called shocks because they are temporal.

Another important detail that often misses public attention is that life expectancy is not a single value – it can be estimated for every age. Most often and by default life expectancy is reported "at birth". But we can estimate remaining life expectancy for various ages. And here comes another popular misunderstanding of life expectancy. Too often we come across the references to human age and longevity in the past that sound something like: “She was 40, a very elderly lady by the standards of that time as people lived on average about 30 years back the”. True, there were times when life expectancy **at birth** was about 30 years even in the most developed now countries. This doesn't mean though that those who outlived this threshold age were getting old at young (by our current standards) ages. Let me illustrate.

Let's take Italian male population in 1872, the first available year in [Human Mortality Database][hmd]. Have a look at the survival of this synthetic cohort – the proportion of the initial cohort that is still alive by certain age. Half of the synthetic cohort died by age 15!

![](ita-lx.png)

And here is how remaining period life expectancy looked by age. Infant and child mortality was sooo high that those escaping early deaths had higher remaining life expectancy.

![](ita-ex.png)

At age 34 remaining life expectancy was the same as at birth. Only, it applied to the 41% survivors. And I guess the perception of age was not radically different among those survivors. It was all about selection and luck getting there. The high early life mortality is responsible for another popular demographic myth, which postulates that everybody used to have many kids in the past. No, people used to have many births, and only a fraction of those kids survived to adult life.

***

::: {.callout-tip}
# This post is based on my previous [Twitter thread][thread]
:::

[robert-1]: https://twitter.com/therealrchung/status/1365091610766155778
[robert-2]: https://twitter.com/therealrchung/status/1365313760416526340
[hmd]: https://www.mortality.org/
[thread]: https://twitter.com/ikashnitsky/status/1367856010476613632
---
title: "Were there too many unlikely results at the FIFA World Cup 2022 in Qatar?"
date: "2022-12-25"
image: teaser.jpg
categories: [r, football, package]
---

***

FIFA World Cup 2022 in Qatar saw many surprising results. In fact, too many -- some would argue. From the unbelievable loss of Argentina to Saudi Arabia at the very beginning of the group stage, via the loss of the magnificent Brazil to Cameroon at the end of the group stage, to the groundbreaking performance of Morocco who were competitive playing against all the usual grands.

Somewhere towards the middle of the group stage I started wondering -- is it ordinary to have so many surprises at the World Cup? What if this particular World Cup is really exceptional by the number of unlikely match outcomes? [^1] If so, how should I measure it?

Just a bit of thinking yielded an answer that was really on the surface -- **bookmakers**. They are the people who use all available knowledge to make money on the outcome expectations. Pretty soon I [figured out][so-data] that there is one website [oddsportal.com][oddsportal] that offers long historical data series of betting odds and match outcomes. The real challenge came at the step of scraping the website. Stack Overflow and other similar places are [filled][q1] with [questions][q2] about [scraping][q3] this specific tricky website. Having finally figured out how to do this (after countless trials and failures) I wrapped up the working solution into an R package [`oddor`][odd]. The idea is that the package provides both scraping tools and the cleaned extracted datasets. [^2]

Okay, so the data issue is solved. Now, it's time for the experiment, a really simple one. I simulate the scenario where I consistently bet on the **least likely outcome** and track how my fictional balance changes over time. Out of the three possible outcomes of the games -- (1) home team wins, (2) draw in main time, and (3) away team wins [^3] -- I always select the one that promises the highest odds, meaning that this outcome is considered the least likely of the three by the bookmakers.

Here are the results for the latest World Cup 2022 (darkest line with all the unlikely outcomes annotated) in comparison with three previous World Cups, 2018, 2014, and 2010.

![](world-cup-odds-since-2010.png){.preview-image}

Decreasing step lines in the plot represent my decreasing fictional balance. Each game I bet 1 coin on the least likely outcome. Most often I lose this bet, and my balance decreases. Though, sometimes the least likely outcome happens, then my balance increases substantially by the size of the unlikely outcome odds. For example, in case of Argentina losing to Saudi Arabia the odds for this outcome was 25.

We can see that the 2022 World Cup was really exceptional -- too often the outcomes that were considered the least likely happened. It's also evident that surprises happen more often at the group stage, especially in the third round when many leaders apparently have already reached their group-stage goals (think of the recent game Brazil--Cameroon, where Brazilians literally played with the second team). I would say it's **really** surprising -- if one bets consistently against the odds at all the group-stage games, at least in the last 4 World Cups (for which we have odds and outcomes data) this dead-simple strategy turns out to be beneficial. My wild guess is that the World Cups see masses of inexperienced new betters who are placing bets on their national teams whatever, which at the global scale is disbalancing the whole system. Alternatively, maybe we are just slow and bad at recognizing how football is becoming more international, and now more underdogs are able to give a decent fight to the traditional grands.

In contrast, Play-offs are apparently less chaotic and more predictable. Betting on the underdogs at the Play-offs stage would guarantee to lose money in all 4 recent World Cups.

Of course, the surprising beneficial result of the betting-on-the-underdog experiment at the group-stage games at World Cups made me curious about other competitions. So I did a similar analysis for the [Champions League (from season 2004--05)][cl] and for [English Premier League (from season 2003--04)][epl]. Predictably, no miracle happened -- betting consistently on the underdogs would almost always bring financial losses. So, either World Cups are just different, or all 4 last tournaments were exceptional with the latest being a crazy outlier. Would it be reasonable to try this no-brainer betting strategy at the group-stage of the next World Cup? I'm not sure. But let's see in 4 years. [^4]

***

::: {.callout-tip}
# Replicate this analysis using the `R` code from this [gist][gist]
:::

[^1]: Through discussions of [my earlier postings of this analysis][red1] I figured out that the usual term to describe these unlikely outcomes is "upset". I don't like the term since it seems to suggest inherently that one always supports the favorite, which is definitely no my case, I tend to cheer for the underdogs. The term I used initially was "sensations", which apparently makes little sense in English and reveals the direct translation from Russian happening in my head in this case. Throughout this post I'll use the term "unlikely outcome".
[^2]: For now I only scraped and added several football tournaments and leagues. Please, feel free to add more results via [GitHub pull requests][gh-pr].
[^3]: Of course, "home" and "away" designation is very arbitrary at world cups, still I use the terms for consistency.
[^4]: I guess I have to say that this is not a financial advise =)

[so-data]: https://opendata.stackexchange.com/a/9010/7044
[oddsportal.com]: https://oddsportal.com
[q1]: https://stackoverflow.com/q/34785764
[q2]: https://stackoverflow.com/q/23417638
[q3]: https://stackoverflow.com/q/56984218
[red1]: https://www.reddit.com/r/dataisbeautiful/comments/zcm4r0
[odd]: https://github.com/ikashnitsky/oddor
[gh-pr]: https://github.com/ikashnitsky/oddor/pulls
[cl]: https://www.reddit.com/r/dataisbeautiful/comments/zim8d6
[epl]: https://www.reddit.com/r/dataisbeautiful/comments/ziojgj
[gist]: https://gist.github.com/ikashnitsky/e7b391c03f9f5b98d589b2388d16089f
---
title: "#30DayMapChallenge my 25/30 contributions"
fig-cap-location: margin
reference-location: margin
date: "2023-12-21"
image: teaser.png
categories: [r, rspatial, ggplot2]
---

For four years I've been following [#30DayMapCallenge][30d] with admiration but not daring to commit to it. Producing maps was always an accompanying step in my main activities, and towards the end of a year it never felt possible to focus on producing them daily. This year I decided to cheat and re-publish many of my maps that accumulated over the years, and only produce new ones for a handful of days/topics. I mostly succeded with posting 25 out of 30. And out of these 25 submissions 6 are freshly coded, 2 are old educational materials turned into blog posts, and 5 more are new quick stuff done without coding. All the new code is available in the [gihub repo][git]; and the blog posts ([geocoding][one], [map-projections][one]) contain all the necessary `#rstats` code inline.

Below I list all my contributions as Mastodon post embeds. I use Mastodon because it's fully open, but the actual #30DayMapCallenge communication was mostly happening on Bluesky, which is still invite-only platform, closed to unregistered viewers. The bsky thread with my contributions is [here][bsky] (note that I'm linking the last post, scroll upwards). Enjoy exploring!

![](30dmc-2023.png)

|   |   |
|---|---|
| [01 points](#d1) | [16 Oceania](#d16) |
| [02 lines](#d2) | [17 flow](#d17) |
| [03 polygons](#d3) | ~~18 atmosphere~~ |
| [04 a bad map](#d4) | [19 5-minutes map](#d19) |
| [05 analog map](#d5) | [20 outdoors](#d20) |
| [06 Asia](#d6) | ~~21 raster~~ |
| [07 navigation](#d7) | [22 North is not always up](#d22) |
| [08 Africa](#d8) | [23 3D](#d23) |
| [09 hexagons](#d9) | ~~24 black & white~~ |
| [10 North America](#d10) | [25 Antarctica](#d25) |
| [11 retro](#d11) | ~~26 minimal~~ |
| [12 South America](#d12) | ~~27 dot~~ |
| [13 choropleth](#d13) | [28 Is it a chart or a map?](#d28) |
| [14 Europe](#d14) | [29 population](#d29) |
| [15 openstreetmap](#d15) | [30 my favourite](#d30) |

# {#d1}
# {#d2}
# {#d3}

:::{.column-page layout-ncol=3 height=500}
**2023-11-01 | points**
[bsky](https://bsky.app/profile/ikashnitsky.phd/post/3kd5pr6o6xj2t) | [fosstodon](https://fosstodon.org/@ikashnitsky/111337430617092755) | [blog](https://ikashnitsky.phd/2023/geocoding/)

**2023-11-02 | lines**
[bsky](https://bsky.app/profile/ikashnitsky.phd/post/3kd7xqamrlu2l) | [fosstodon](https://fosstodon.org/@ikashnitsky/111405404938875987) |
[blog](https://ikashnitsky.phd/2023/map-borders/)

**2023-11-03 | polygons**
[bsky](https://bsky.app/profile/ikashnitsky.phd/post/3kd7xqamrlu2l) | [fosstodon](https://fosstodon.org/@ikashnitsky/111405412363995030) |
[code](https://gist.github.com/ikashnitsky/90483ee3c3c230aa874dffb856d6074b)

{{< mastodon "https://fosstodon.org/@ikashnitsky/111337430617092755" >}}
{{< mastodon "https://fosstodon.org/@ikashnitsky/111405404938875987" >}}
{{< mastodon "https://fosstodon.org/@ikashnitsky/111405412363995030" >}}
:::

***

# {#d4}
# {#d5}
# {#d6}

:::{.column-page layout-ncol=3 height=500}
**2023-11-04 | points**
[bsky](https://bsky.app/profile/ikashnitsky.phd/post/3kdeawnbl4q24) | [fosstodon](https://fosstodon.org/@ikashnitsky/111405418702631776) | [blog](https://ikashnitsky.phd/2023/map-proj/)

**2023-11-05 | lines**
[bsky](https://bsky.app/profile/ikashnitsky.phd/post/3kdh7ufu3uy2v) | [fosstodon](https://fosstodon.org/@ikashnitsky/111405425388263054)

**2023-11-06 | polygons**
[bsky](https://bsky.app/profile/ikashnitsky.phd/post/3kdjejp7ipi2u) | [fosstodon](https://fosstodon.org/@ikashnitsky/111405431300734214) | [code](https://github.com/ikashnitsky/30DayMapChallenge/blob/main/src/06-asian-restaurants.R)

{{< mastodon "https://fosstodon.org/@ikashnitsky/111405418702631776" >}}
{{< mastodon "https://fosstodon.org/@ikashnitsky/111405425388263054" >}}
{{< mastodon "https://fosstodon.org/@ikashnitsky/111405431300734214" >}}
:::

***

# {#d7}
# {#d8}
# {#d9}

:::{.column-page layout-ncol=3 height=500}
**2023-11-07 | navigation**
[bsky](https://bsky.app/profile/ikashnitsky.phd/post/3kdmxhthkae2e) | [fosstodon](https://fosstodon.org/@ikashnitsky/111405445483890222)

**2023-11-08 | Africa**
[bsky](https://bsky.app/profile/ikashnitsky.phd/post/3kdocjzuvhq2e) | [fosstodon](https://fosstodon.org/@ikashnitsky/111405472725576212) | [code](https://github.com/ikashnitsky/30DayMapChallenge/blob/77d444be79c5170c83b2b6049847df7b5ec04536/src/08-africa-wpp.R)

**2023-11-09 | hexagons**
[bsky](https://bsky.app/profile/ikashnitsky.phd/post/3kdqlogcoko2e) | [fosstodon](https://fosstodon.org/@ikashnitsky/111405561927666632)

{{< mastodon "https://fosstodon.org/@ikashnitsky/111405445483890222" >}}
{{< mastodon "https://fosstodon.org/@ikashnitsky/111405472725576212" >}}
{{< mastodon "https://fosstodon.org/@ikashnitsky/111405561927666632" >}}
:::

***

# {#d10}
# {#d11}
# {#d12}

:::{.column-page layout-ncol=3 height=500}
**2023-11-10 | North America**
[bsky](https://bsky.app/profile/ikashnitsky.phd/post/3kdtg5brpke22) | [fosstodon](https://fosstodon.org/@ikashnitsky/111405574357933368) | [code](https://github.com/ikashnitsky/demres-geofacet) | [paper](https://doi.org/10.4054/demres.2019.41.17)

**2023-11-11 | retro**
[bsky](https://bsky.app/profile/ikashnitsky.phd/post/3kdvouy3l2o25) | [fosstodon](https://fosstodon.org/@ikashnitsky/111405579379722589) | [code](https://github.com/ikashnitsky/30DayMapChallenge/blob/77d444be79c5170c83b2b6049847df7b5ec04536/src/08-africa-wpp.R)

**2023-11-12 | South America**
[bsky](https://bsky.app/profile/ikashnitsky.phd/post/3keafyo6ga422) | [fosstodon](https://fosstodon.org/@ikashnitsky/111415413730412646) | [code](https://github.com/ikashnitsky/30DayMapChallenge/blob/main/src/12-south-america-copa.R)

{{< mastodon "https://fosstodon.org/@ikashnitsky/111405574357933368" >}}
{{< mastodon "https://fosstodon.org/@ikashnitsky/111405579379722589" >}}
{{< mastodon "https://fosstodon.org/@ikashnitsky/111415413730412646" >}}
:::

***

# {#d13}
# {#d14}
# {#d15}

:::{.column-page layout-ncol=3 height=500}
**2023-11-13 | choropleth**
[bsky](https://bsky.app/profile/ikashnitsky.phd/post/3ke3wnhy6322g) | [fosstodon](https://fosstodon.org/@ikashnitsky/111415503143998080) | [code](https://github.com/CPop-SDU/outsurvival-in-perspective) | [paper](http://doi.org/10.1136/bmjopen-2021-059964)

**2023-11-14 | Europe**
[bsky](https://bsky.app/profile/ikashnitsky.phd/post/3ke5kdkcsa22e) | [fosstodon](https://fosstodon.org/@ikashnitsky/111415506806961974) | [code](https://github.com/ikashnitsky/five-non-capitals) |
[reddit](https://www.reddit.com/r/dataisbeautiful/comments/u0r9fh)

**2023-11-15 | OpenStreetMap**
[bsky](https://bsky.app/profile/ikashnitsky.phd/post/3keaifn7xem2l) | [fosstodon](https://fosstodon.org/@ikashnitsky/111617074263351272) | [code](https://github.com/ikashnitsky/30DayMapChallenge/blob/main/src/12-south-america-copa.R)

{{< mastodon "https://fosstodon.org/@ikashnitsky/111415503143998080" >}}
{{< mastodon "https://fosstodon.org/@ikashnitsky/111415506806961974" >}}
{{< mastodon "https://fosstodon.org/@ikashnitsky/111617074263351272" >}}
:::

***

# {#d16}
# {#d17}
# {#d19}

:::{.column-page layout-ncol=3 height=500}
**2023-11-16 | Oceania**
[bsky](https://bsky.app/profile/ikashnitsky.phd/post/3kedm72lrgc2g) | [fosstodon](https://fosstodon.org/@ikashnitsky/111617077358434718)

**2023-11-17 | flow**
[bsky](https://bsky.app/profile/ikashnitsky.phd/post/3kefic276eg2p) | [fosstodon](https://fosstodon.org/@ikashnitsky/111617087998805744) | [code](https://github.com/ikashnitsky/30DayMapChallenge/blob/main/src/17-flow-places-lived.R)

**2023-11-19 | 5-minute map**
[bsky](https://bsky.app/profile/ikashnitsky.phd/post/3keuk5ixxbm2d) | [fosstodon](https://fosstodon.org/@ikashnitsky/111617092075958239)

{{< mastodon "https://fosstodon.org/@ikashnitsky/111617077358434718" >}}
{{< mastodon "https://fosstodon.org/@ikashnitsky/111617087998805744" >}}
{{< mastodon "https://fosstodon.org/@ikashnitsky/111617092075958239" >}}
:::

***

***

# {#d20}
# {#d22}
# {#d23}

:::{.column-page layout-ncol=3 height=500}
**2023-11-20 | outdoors**
[bsky](https://bsky.app/profile/ikashnitsky.phd/post/3kedm72lrgc2g) | [fosstodon](https://fosstodon.org/@ikashnitsky/111617097507129329) |
[code](https://github.com/ikashnitsky/30DayMapChallenge/blob/main/src/20-outdoors-strava.R)

**2023-11-22 | North is always up**
[bsky](https://bsky.app/profile/ikashnitsky.phd/post/3kery3gdarf23) | [fosstodon](https://fosstodon.org/@ikashnitsky/111617100355788689) | [reddit](https://www.reddit.com/r/dataisbeautiful/comments/o6hezy)

**2023-11-23 | 3D**
[bsky](https://bsky.app/profile/ikashnitsky.phd/post/3keujjd6ajm2d) | [fosstodon](https://fosstodon.org/@ikashnitsky/111617103299501948)

{{< mastodon "https://fosstodon.org/@ikashnitsky/111617097507129329" >}}
{{< mastodon "https://fosstodon.org/@ikashnitsky/111617100355788689" >}}
{{< mastodon "https://fosstodon.org/@ikashnitsky/111617103299501948" >}}
:::

***

# {#d25}
# {#d28}
# {#d29}

:::{.column-page layout-ncol=3 height=500}
**2023-11-25 | Antarctica**
[bsky](https://bsky.app/profile/ikashnitsky.phd/post/3kezt7zaify26) | [fosstodon](https://fosstodon.org/@ikashnitsky/111617105804689802) |
[code](https://github.com/ikashnitsky/30DayMapChallenge/blob/main/src/25-antarctica.R)

**2023-11-28 | Is this a chart or a map?**
[bsky](https://bsky.app/profile/ikashnitsky.phd/post/3kfagi4o2yw2k) | [fosstodon](https://fosstodon.org/@ikashnitsky/111617110232462236) | [reddit](https://www.reddit.com/r/dataisbeautiful/comments/o6hezy)

**2023-11-29 | Population**
[bsky](https://bsky.app/profile/ikashnitsky.phd/post/3kfczojm3yb25) | [fosstodon](https://fosstodon.org/@ikashnitsky/111617121105818580) |
[code](https://github.com/ikashnitsky/covid19-nuts3) |
[paper](https://doi.org/10.1016/j.worlddev.2020.105170) |
[reddit](https://www.reddit.com/r/dataisbeautiful/comments/ipek29)

{{< mastodon "https://fosstodon.org/@ikashnitsky/111617105804689802" >}}
{{< mastodon "https://fosstodon.org/@ikashnitsky/111617110232462236" >}}
{{< mastodon "https://fosstodon.org/@ikashnitsky/111617121105818580" >}}
:::

***

# {#d30}

**2023-11-30 | my favourite**
[bsky](https://bsky.app/profile/ikashnitsky.phd/post/3kfftqm6fqz2j) | [fosstodon](https://fosstodon.org/@ikashnitsky/111617126444313662) |
[code](https://github.com/ikashnitsky/the-lancet-2018) |
[paper](https://doi.org/10.1016/s0140-6736(18)31194-2) |
[reddit](https://www.reddit.com/r/dataisbeautiful/comments/915hxe)

{{< mastodon "https://fosstodon.org/@ikashnitsky/111617126444313662" >}}

***

[30d]: https://30daymapchallenge.com
[git]: https://github.com/ikashnitsky/30DayMapChallenge
[one]: https://ikashnitsky.phd/2023/geocoding/
[two]: https://ikashnitsky.phd/2023/map-proj/
[bsky]: https://bsky.app/profile/ikashnitsky.phd/post/3kgzxxhdgbm24
---
title: "Geocode address text strings using `tidygeocoder`"
date: "2023-11-01"
image: teaser.png
categories: [r, rspatial, ggplot2]
---

```{r, include=FALSE}
knitr::opts_chunk$set(
  message = FALSE, warning = FALSE
)
```

***

Deriving coordinates from a string of text that represents a physical location on Earth is a common geo data processing task. A usual use case would be an address question in a survey. There is a way to automate queries to a special GIS service so that it takes a text string as an input and returns the geographic coordinates. This used to be quite a challenging task since it required obtaining an API access to the GIS service like Google Maps. Things changed radically with the appearance of `tidygeocoder` that queries the free Open Street Map.

In this tiny example I'm using the birth places that students of my [2022 BSSD dataviz course][bssd] kindly contributed. In the class I asked students to fill a Google Form consisting of just two fields -- city and country of birth. The resulting small dataset is [here][data]

```{r}
library(tidyverse)
library(sf)

# download the data
# https://stackoverflow.com/a/28986107/4638884
library(gsheet)

raw <- gsheet2tbl(
    "https://docs.google.com/spreadsheets/d/1YlfLQc_aOOiTqaSGu5TI70OQy1ewTa_Ti0qAEOEcy58"
)

# clean a bit and join both fields in one text string
df <- raw |>
    janitor::clean_names() |>
    drop_na() |>
    mutate(text_to_geocode = paste(city_settlement, country, sep = ", "))
```

Now we are ready to unleash the power of `tidygeocoder`. The way the main unction in the package works is very similar to `mutate` -- you just specify which column of the dataset contains the text string to geocode, and it return the geographic coordinates.

```{r}
library(tidygeocoder)

df_geocoded <- df |>
    geocode(text_to_geocode, method = "osm")
```

The magic has already happened. The rest is just the routines to drop the points on the map. Yes, I am submitting this as my first 2023 entry to the [`#30DayMapChallenge`][30d] =)

```{r}
# convert coordinates to an sf object
df_plot <- df_geocoded |>
    drop_na() |>
    st_as_sf(
        coords = c("long", "lat"),
        crs = 4326
    )
```

Next are several steps to plot countries of the worlds as the background map layer. Note that I'm using the trick of producing a separate lines layer for the country borders, there is a [separate post][borders] about this small dataviz trick.

```{r}
# get world map outline (you might need to install the package)
world_outline <- spData::world |>
    st_as_sf()

# let's use a fancy projection
world_outline_robinson <- world_outline |>
    st_transform(crs = "ESRI:54030")

country_borders <- world_outline_robinson |>
    rmapshaper::ms_innerlines()
```

Now everything is ready to map!

```{r, out.width="100%"}
#| column: screen-inset
# map!
world_outline_robinson |>
    filter(!iso_a2 == "AQ") |> # get rid of Antarctica
    ggplot()+
    geom_sf(fill = "#269999", color = NA)+
    geom_sf(
        data = country_borders, size = .25,
        color = "#269999" |> prismatic::clr_lighten()
    )+
    geom_sf(
        data = df_plot, fill = "#dafa26",
        color = "#dafa26" |> prismatic::clr_darken(),
        size = 1.5, shape = 21
    )+
    coord_sf(datum = NA)+
    theme_minimal(base_family = "Atkinson Hyperlegible")+
    labs(
        title = "Birth places of the participants",
        subtitle = "Barcelona Summer School of Demography
        dataviz course at CED, July 2022",
        caption = "@ikashnitsky.phd"
    )+
    theme(
        text = element_text(color = "#ccffff"),
        plot.background = element_rect(fill = "#042222", color = NA),
        axis.text = element_blank(),
        plot.title = element_text(face = 2, size = 18, color = "#ccffff")
    )
```

That's it. Going from text to point on the map has never been easier.

***

::: {.callout-note}
# This post is one in the **dataviz course series**. Other posts:
- [The easiest way to radically improve map aesthetics][borders]
- [Show all data in the background of your faceted ggplot][bg]
- [Dotplot – the single most useful yet largely neglected dataviz type][dotplot]
- [Save space in faceted plots][shrink]
:::

[bssd]: https://github.com/ikashnitsky/dataviz-bssd/releases/tag/v.3.0
[borders]: https://ikashnitsky.phd/2023/map-borders/
[bg]: https://ikashnitsky.phd/2020/background-data/
[dotplot]: https://ikashnitsky.phd/2019/dotplot/
[data]: https://docs.google.com/spreadsheets/d/1YlfLQc_aOOiTqaSGu5TI70OQy1ewTa_Ti0qAEOEcy58
[30d]: https://30daymapchallenge.com
[shrink]: https://ikashnitsky.phd/2023/shrink-space/
---
title: "Easily re-using self-written functions: the power of gist + code snippet duo"
date: "2023-01-03"
image: teaser.png
categories: [r, rstudio, trick]
---

```{r, include=FALSE}
knitr::opts_chunk$set(
  message = FALSE, warning = FALSE
)
library(tidyverse)
```

***

Quite often data processing or analysis needs bring us to write own functions. Sometimes these self-defined functions are only meaningful and useful within a certain workflow or even a certain script. But other self-written functions may be more generic and reusable in other circumstances. For example, one may want to have a version of `ggsave()` that always enforces `bg = 'snow'`, or a `theme_own()` function with pre-saved preferences. Self-written functions live in `{.GlobalEnv}` and have to be re-defined in every new R session. Copying the same lines of code across projects can be boring. **How to "bookmark" the useful little own functions and reuse them easier in other projects?** This post offers an elegant solution.

One obvious way to store self-written functions would be to write an own package and have a easy access to these function via `library()` calls. While this may be quite comfortable for own coding purposes, the objective downside of this approach is replicability of the code -- once the code leaves your specific machine, one would have to install your package in order to run the code. This seems an overkill to store a couple of occasional arbitrarily useful functions.

I suggest a more convenient approach: store the functions as [GitHub gists][gists] and call them using the handy `devtools::source_gist()`. This allows to load self-written functions from standalone R scripts. And to avoid copying manually the lines of code that source a certain gist we may use code snippets. Let me give you an example.

I want to re-use a `ggplot2` theme with certain preferred parameters. Here are the lines of code that define my `theme_ik()` function.

```{r}
theme_ik <- function(
        base_size = 12,
        base_family = "sans",
        labs_color = "#074949",
        axis_color = "#002F2F",
        bg_color = "#eeffff",
        grid_color = "#ccffff"
){
    theme_minimal(base_size = base_size, base_family = base_family)+
        theme(
            plot.title = element_text(
                size = base_size*2, face = 2, color = labs_color
            ),
            plot.subtitle = element_text(color = labs_color),
            plot.caption = element_text(color = labs_color),
            axis.title = element_text(color = axis_color),
            axis.text = element_text(color = axis_color),
            plot.background = element_rect(color = NA, fill = bg_color),
            legend.position = "bottom",
            panel.spacing = unit(1, "lines"),
            panel.grid.major = element_line(color = grid_color),
            panel.grid.minor = element_blank(),
            line = element_line(lineend = "round")
        )
}
```

I store these lines of R code as [a gist][gist] here. Next, I only need to supply the ID part of the gist URL (`https://gist.github.com/ikashnitsky/653e1040a07364ae82b1bb312501a184`) to the `devtools::source_gist()` function and it will execute the script stored in the gist, which will result in function `theme_ik()` appearing in my `{.GlobalEnv}`. With the second line of code I set the default `ggplot2` theme to my self-written one.

```{r}
devtools::source_gist("653e1040a07364ae82b1bb312501a184")
theme_set(theme_ik())
```

Now, the final element of this recipe is to save the two lines above as a code snippet. I'm using RStudio, but code snippets are available in any decent IDE. To add a custom snippet we need to navigate to `Tools --> Edit Code Snippets...`. In the new window just add a custom snippet making sure to respect the indentation. [^1]

[![](snippet.png)](https://ikashnitsky.github.io/2023/gist-snippet/snippet.png)

That's it. Save the modified snippets, the new one is ready to be used. Now, when I type `thm` and then press `TAB`, `thm` transforms into the two lines of code that source the specific gist and set the custom theme to `theme_ik()`. Any ggplot that I will produce next in this R session will have my preferred theme defaults.

```{r, fig.width=8}
swiss |>
        ggplot(aes(x = Agriculture, y = Fertility))+
        geom_point()+
        labs(
            title = "Fertility and rurality in Swiss cantones, 1888"
        )
```

My preferred `ggplot2` theme here is optimized to produce plots that look nicely in my blog. [^2]
**Happy coding with snippets and easily re-usable custom functions!**

***

[^1]: Note that in the left tabset one can choose what kind of snippets to add. In R scripts snippets are called with `TAB`, in rmarkdown documents the hot-key for snippets is `SHIFT+TAB`.
[^2]: In case you read this anywhere else, this blog post is available at [https://ikashnitsky.github.io/2023/gist-snippet][post]

[gists]: https://gist.github.com
[gist]: https://gist.github.com/ikashnitsky/653e1040a07364ae82b1bb312501a184
[post]: https://ikashnitsky.github.io/2023/gist-snippet
---
title: "The easiest way to radically improve map aesthetics"
date: "2023-01-01"
image: teaser.png
categories: [r, rspatial, dataviz, trick]
---

```{r, include=FALSE}
knitr::opts_chunk$set(
  message = FALSE, warning = FALSE
)
```

***

Since R community developed brilliant tools to deal with spatial data, producing maps is no longer the privilege of a narrow group of people with very specific almost esoteric knowledge, skillset, and often super expensive software. With `#rspatial` packages, maps (at least the relatively simple ones) became just another type of dataviz.

[![](rgg-maps.png)](https://ikashnitsky.github.io/2023/map-borders/rgg-maps.png)

Just a few lines of code can reveal the eye-catching and visually pleasant spatial dimension of the data. Similarly, a few more lines of code can radically improve the pleasantness of a simple map -- just **add borders as lines in a separate spatial layer**.

[![](sketch.png)](https://ikashnitsky.github.io/2023/map-borders/sketch.png){.preview-image}

An often "quick and dirty" solution when composing a simple choropleth map is to use polygons outline as the borders. While this works okay to distinguish the polygons, the map quickly becomes unnecessarily overloaded. All the non-bordering outlines -- complicated coastal lines and islands' outlines -- look ugly and add nothing to the map.

Let's illustrate the ease of this trick mapping Greece with its numerous small islands. We'll use the beautiful `eurostat` package that has a built in spatial dataset with NUTS-3 regions of Europe.

```{r}
library(tidyverse)
library(sf)
library(cowplot)

set.seed(911)

# subset Greence, NUTS-3 regions
library(eurostat)
greece <- eurostat_geodata_60_2016 |>
    filter(LEVL_CODE==3,
           str_sub(geo, 1, 2) == "EL") |>
    # create random values for filling the polygons
    mutate(random = runif(length(id))) |>
    select(id, geometry, random) |>
    st_transform(crs = 3035)
```

First, here's the typical lazy (or rather no-brainer) way of using the polygons' outlines to show the borders between our spatial units.

```{r}
# plot with polygon outlines
greece |>
    ggplot()+
    geom_sf(aes(fill = random), color = 2, size = 1)+
    labs(title = "Polygons outlined")+
    scale_fill_viridis_c(begin = .5)+
    theme_map()+
    theme(plot.background = element_rect(color = NA, fill = "#eeffff"))

gg_outline <- last_plot()
```

Look at all the islands, especially the small ones -- what are all these red outlines for? Insted, we can add only the borders between the polygons as lines. For this we need to add another geospatial layer with lines. Where do we get it? This is extremely easy to produce thanks to the marvelous little package `rmapshaper` that has  a function `ms_innerlines()` exactly for the task. [^1]

```{r}
# produce border lines with rmapshaper::ms_innerlines()
library(rmapshaper)
bord <- greece |> ms_innerlines()
```

Now, let's plot the same map with proper borders between the polygons. Note that for the `sf` layer with polygons I set `color = NA` to get rid of the polygons outline. Then with the next call to `geom_sf()` I draw the line borders as a separate layer.

```{r}
# now plot without polygon outlines and with borders as lines
greece |>
    ggplot()+
    geom_sf(aes(fill = random), color = NA)+
    geom_sf(data = bord, color = 2, size = 1)+
    labs(title = "Borders as lines")+
    scale_fill_viridis_c(begin = .5)+
    theme_map()+
    theme(plot.background = element_rect(color = NA, fill = "#eeffff"))

gg_bord <- last_plot()

```

That's it! This is the simplest dataviz trick I know that can radically improve the outlook of simple choropleth maps. It's only one additional line of code. You can even create the borders `sf` object on the fly within the `ggplot` map creation code specifying the `data` parameter as `. %>% ms_innerlines()` [^2], like this:

```{r, eval=FALSE}
geom_sf(data = . %>% ms_innerlines(), color = 2, size = 1)
```

Finally, let's put the two maps side by side.

```{r, out.width="100%"}
#| column: screen-inset
# put side by side
library(patchwork)
(
    gg_outline + gg_bord
)  +
    plot_layout(guides = "collect")+
    plot_annotation(
        caption = "! Look at the islands",
        theme = theme(plot.background = element_rect(color = NA, fill = "#eeffff"))
    )
```

***

::: {.callout-tip}
# Replicate this analysis using the `R` code from this [gist][gist]. This post is partially based on my previous [Twitter thread][thread]
:::

::: {.callout-note}
# About this post
Publishing this post is my personal gestalt closure -- it spent more than three years in planning and then in drafts. Somehow, with this post I hit the wall of writer's block and it coincided with Twitter threads substituting blogging for me. Now, it's time to get back to blogging.
:::

[^1]: Before I found `rmapshaper` the task seemed overly complicated, I even asked [Stack Overflow][so]
[^2]: This is one specific case where the base R pipe `|>` cannot simply replace the {magrittr} pipe `%>%`; see more [here][pipe].

[so]: https://stackoverflow.com/questions/47760033
[thread]: https://twitter.com/ikashnitsky/status/1247875600305598464
[gist]: https://gist.github.com/ikashnitsky/cf2c29a29d39f79bb1c857a4fefc2cd4
[pipe]: https://bsky.app/profile/ikashnitsky.phd/post/3kilahv45c52n
---
title: "Improve your maps in one line of code changing map projections"
date: "2023-11-04"
image: teaser.png
categories: [r, rspatial, ggplot2]
---

```{r, include=FALSE}
knitr::opts_chunk$set(
  message = FALSE, warning = FALSE, out.width = "100%", out.height = "100%"
)
devtools::source_gist("653e1040a07364ae82b1bb312501a184")
theme_set(theme_ik())
```

***

Did you ever think why we (okay, I'm clearly biased, maybe just many of us, humans) love maps so much? Why do they often work so much better than other types of dataviz?

I think[^1] what makes the maps work is the speed with which we can recognize familiar shapes, most often countries. That's why it's so annoying when these shapes get distorted -- it hinders the smoothness of reading the map and kills the pleasure of the process. I'm sure this is the main reason why [cartograms][cart] exist forever as a cool idea but are rarely actually used -- people love the concept of them but hate actually looking at them. I deeply believe that immediate shape recognition is the kill feature of maps as a type of dataviz.

[^1]: And here I have to say that I'm not an expert in the area of visual perception or psychology of human processing of dataviz. I know this is a huge, thrilling area of research, I just never followed systemically. Strictly speaking, what I'm going to tell further is likely some digested version of what I've seen, read, and thought through over years of being into dataviz.

Geographic projections are a huge field of research in itself. There are infinite ways to project the  spherical globe (geoid) to the surface. It's a classical challenge with no single correct solution. Specific choice depends on the features we want to preserve/represent most correctly — distances, angles, shapes, or areas. In my experience, for most of our daily basic dataviz needs the most important is the shape — it helps recognizing objects and thus navigating through maps smoothly.

There is a brilliant 6-min video explainer of maps projections, I heartily recommend:

<iframe width="100%" height="650" src="https://www.youtube.com/embed/kIID5FDi2JQ" title="YouTube video player" frameborder="0" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture" allowfullscreen>
</iframe>

Beware, the choice of appropriate map projection can be a rabbit hole as deep as choosing fonts or colors for your dataviz -- you are warned. In all practical terms, a good strategy is to check what are the canonical projections for the territories one plans to map – that would help not to repel the reader through instantaneous non-recognition of the shape. One good resource for the task is http://epsg.io.

Just accept that the perfect projection does not exist -- there's no such thing as ~~free lunch~~ perfect projection. Map projections always excel or fail in specific contexts. Here is an example when a very non-standard geographic projection is just perfect for the data it is showing and the story it is telling.

[![](natgeo.png){width=70%}][natgeo]

Here is another [animated example][volc].

Even the most famous and [often][m1] [ridiculed][m2] Mercator projection has its major advantages -- it preserves the angles and that's why it was perfect for the early age of navigation. It's also pretty safe at preserving coordinates and thus most often is used as the basic projection in which geodata is stored and distributed. And this is the reason why we see it in published maps so often. Honestly, I'm really allergic to the view of Europe in Mercator projection.

[![](badeu.png){width=70%}][badeu]

And it's just unbelievable how often these repulsing maps come across in academic papers. Especially when you know that it really takes one line of code to fix it. So let's see how it's done.

***

For the illustration below I will produce maps of Europe in (A) Mercator and (B) Lambert Equal Area Azimuthal projections, as usual using the beautiful geodata stored in the `{eurostat}` package.

```{r}
library(tidyverse)
library(sf)
library(eurostat)

# the built-in dataset of EU boundaries
gd <- eurostat_geodata_60_2016 |>
    janitor::clean_names()

# filters out only NUTS-2 regions
gd_n2 <- gd |>
    filter(levl_code == 2)

# let's build the most basic map
gd_n2 |>
    ggplot() +
    geom_sf()
```

Note all the overseas territories of France, Spain, and Portugal. At the next step I will remove them to zoom in to the usual scope of mainland Europe. I will also [add borders between the countries as lines][bord].

```{r}
# remove overseas territories
gd_n2_main <- gd_n2 |>
    filter(
        !id %in% c(
            paste0('ES', c(63, 64, 70)),
            paste('FRY', 1:5, sep = ''),
            'PT20', 'PT30'
        )
    )

# the lines level with borders at country level
bord <- gd |>
    filter(levl_code == 0) |>
    rmapshaper::ms_innerlines()
```

Now, back to reprojecting. There are two ways of changing the projections with {sf}: either apply `st_transform(crs = [EPSG code])` to change your the projection of the geodata object OR fix it directly at the plotting stage via `coord_sf(crs = [EPSG code])`. I think it's generally easier to reproject the data once and work with it (panel B). But for completeness I will also show the on-the-fly `coord_sf()` when plotting in Mercator projection (panel A).

```{r, warning=FALSE, fig.width=16, fig.height=8}
#| column: screen-inset
# transform the projection to the one suitable for Europe
gd_n2_main_laea <- gd_n2_main |>
    st_transform(crs = 3035)

a <- gd_n2_main |>
    ggplot() +
    geom_sf(fill = "#F48FB1", color = NA)+
    geom_sf(data = bord, color = "#C2185B", size = .5)+
    coord_sf(crs = 3857)

b <- gd_n2_main_laea |>
    ggplot() +
    geom_sf(fill = "#DCE775", color = NA)+
    geom_sf(data = bord, color = "#AFB42B", size = .5)

library(patchwork)

a + b + plot_annotation(tag_levels = "A")
```

That's it. That's the whole one-line trick. Check out my other post based on my [dataviz course materials][dv].

***

::: {.callout-note}
# This post is one in the **dataviz course series**. Other posts:
- [The easiest way to radically improve map aesthetics][bord]
- [Show all data in the background of your faceted ggplot][bg]
- [Dotplot – the single most useful yet largely neglected dataviz type][dotplot]
- [Save space in faceted plots][shrink]
- [Geocode address text strings using `tidygeocoder`][gcode]
:::

[cart]: https://r-graph-gallery.com/cartogram.html
[30d]: https://30daymapchallenge.com
[volc]: https://twitter.com/ikashnitsky/status/1261186743585386496
[m1]: https://twitter.com/ikashnitsky/status/1442512307502780422
[m2]: https://twitter.com/ikashnitsky/status/1531395881559375872
[natgeo]: https://ikashnitsky.phd/2023/map-proj/natgeo.png
[badeu]: https://ikashnitsky.phd/2023/map-proj/badeu.png
[dv]: https://github.com/ikashnitsky/dataviz-art-skill

[bord]: https://ikashnitsky.phd/2023/map-borders/
[bg]: https://ikashnitsky.phd/2020/background-data/
[dotplot]: https://ikashnitsky.phd/2019/dotplot/
[shrink]: https://ikashnitsky.phd/2023/shrink-space/
[gcode]: https://ikashnitsky.phd/2023/geocoding/
---
title: "Save space in faceted plots"
date: "2023-02-27"
image: teaser.jpg
categories: [r, dataviz, trick, faceting]
---

```{r, include=FALSE}
knitr::opts_chunk$set(
  message = FALSE, warning = FALSE
)
library(tidyverse)
sysfonts::font_families()
sysfonts::font_add_google("Atkinson Hyperlegible", "ah")
library(showtext)
showtext_auto()
devtools::source_gist("653e1040a07364ae82b1bb312501a184")
theme_set(theme_ik(base_family = "ah"))
```

***

Faceting[^1] is probably the most distinctive feature that defined the early success and wide adoption of `ggplot2`. Small-multiples are often a great dataviz choice.[^2] But one common problem is when your panels for the subsets of data requite vastly different amount of space. By default the panels in faceted ggplots are all of the same size. If the data subsets are very different is size -- a common case yould be time series of varying length -- this results in a lot of plot space wasted in the panels with little data to show. In this post I'm showing how to deal with this common issue.

Let me first show you the solution. The cornerstone source of data in demography is [Human Mortality Database][hmd]. It provides demographic data of highest possible quality for a selection of available countries. The availability of data varies vastly across countries -- from 270+ years in Sweden to a handful of decades in many other countries with less exceptional population data statistics. Here are two plots from my recent papers that use HMD.

[![Figure A3 from @zarulli2021p](pnas.png)](https://ikashnitsky.github.io/2023/shrink-space/pnas.png){.preview-image}

[![Figure 3 from @aburto2022ije](ije.png)](https://ikashnitsky.github.io/2023/shrink-space/ije.png)

The trick in these plots is that countries are arranged by the length of time series. The width of each panel is net to the longest time series observed omong the countries in the column of small multiples. This is easily achieved via the parameter `space = "free"` in the `facet_grid()` call.

One slightly annoying nuance is that the `space = "free"` parameter is *only* available `facet_grid()`. That's why we need to specify both column and row variables for the layout of small multiples. Yet, usually we have just one meaningful faceting variable in such a setup, country in the examples above. That's why the steps of data preparation for these plots included the creation of variables `row` and `column` that explicitly located the position of each small multiple. You can find code that replicates both figures shown above [here][gh-pnas] and [here][gh-ije]. To illustrate the approach in this post we'll use a minimal example with generated data.

Consider a case when we have 6 countries, 3 of which have relatively long time series and 3 have relatively short period of observed data. To stay a bit closer to the examples above, let's say that we have data for Sweden (271 years worth of data), Denmark (186 years), Netherlands (169), Portugal (81), Japan (74), and Estonia (60). Let's generate some random data of the specified time series' length.

```{r}
set.seed(911)

raw <- tibble(
    country = c("Sweden", "Denmark", "Netherlands", "Portugal", "Japan", "Estonia"),
    n_years = c(271, 186, 169, 81, 74, 60)
) |>
    # mutate(country = country |> as_factor()) |>
    group_by(country) |>
    group_modify(~ runif(n = .x$n_years) |> tibble(random = _)) |>
    mutate(year = 2022 - seq_along(country)) |>
    ungroup()
```

Let's say I want a plot with 3 rows and 2 columns. First, here's how a simple faceted plot would look like.

```{r}
raw |>
    ggplot(aes(year, random, color = country))+
    geom_path()+
    facet_wrap(~country, ncol = 2)
```

See how much space is just wasted in the plot.

Next, we'll do the trick outlined above: arrange the countries by the length of available data and shrink the unused space in the two columns.

```{r}
arr <- raw |>
    mutate(
        country = country |> as_factor() |> fct_infreq()
    ) |>
    arrange(country, year) |>
    # create facet positioning variables on a 3x2 canvas
    mutate(
        row = country |>
            lvls_revalue(
                new_levels = 1:3 |> rep(2) |> paste()
            ),
        col = country |>
            lvls_revalue(
                new_levels = 1:2 |> rep(each = 3) |> paste()
            )
    ) |>
    ungroup()

arr |>
    ggplot(aes(year, random, color = country))+
    geom_path()+
    facet_grid(row~col, scales = "free_x", space = "free")
```

That's it, the rest is just visual polishing of the plot. At the very least, we need to get rid of the facet strips which are now meaningless counts of rows and columns and add country names as text annotations.

```{r}
arr |>
    ggplot(aes(year, random, color = country))+
    geom_path()+
    facet_grid(row~col, scales = "free_x", space = "free")+
    geom_text(
        data = function(x) x|> distinct(country, row, col),
        aes(label = country), x = 2020, y = 1.05,
        hjust = 1, vjust = 0, size = 5,
        family = "ah", fontface = 2
    )+
    scale_y_continuous(limits = c(0, 1.15), breaks = seq(0, 1, .25))+
    scale_x_continuous(breaks = seq(1750, 2000, 50))+
    theme(
        legend.position = "none",
        strip.text = element_blank()
    )
```

Enjoy more dataviz freedom with faceting tricks =)

[^1]: This is the term used for small-multiples in `ggplot2`
[^2]: See [the post][bg] in which I improve an overloaded line chart using small-multiples

[bg]: https://ikashnitsky.github.io/2020/background-data/
[hmd]: https://www.mortality.org
[gh-pnas]: https://github.com/ikashnitsky/sex-gap-e0-pnas
[gh-ije]: https://github.com/OxfordDemSci/ex2020

***

::: {.callout-note}
# This post is one in the **faceting series**. Other posts:
- [Show all data in the background of your faceted ggplot][bg]
:::
---
title: "Rotate the damn plot"
fig-cap-location: margin
reference-location: margin
date: "2024-12-18"
image: teaser.png
categories: [r, dataviz, trick]
---

Several days ago I saw [a post on LinkedIn by Jornt Mandemakers][orig] with some very curious results from [Gender and Generations Programme][ggp] surveys. While representing interesting data, it was a perfect example of a way too common academic dataviz fallacy, and I decided to finally write this blog post.

Here is the original plot by Jornt.

![](plot-to-redo.jpg)

We are going to replicate it and then redo -- all in hope to illustrate how much it can be improved with very very simple alterations. In fact, this post revives the argument I made in an earlier post called [Dotplot -- the single most useful yet largely neglected dataviz type][early]. Despite the nice title and the same  main message, I'm afraid the older post used a less indicative example. So I hope this time I'll manage to illustrate the key message a bit clearer. But the message itself stays the same -- **forget multi-category bar/column plots and use dotplots instead**. Or, put it the other way around: whenever you are visualizing a continuous measurement split into multiple categories, place the continuous variable on the horizontal (x) axis and the categorical variable on the vertical (y) axis. That's it. Just a simple trick improves the readability of your plot **a lot**.

Unfortunately, the use of crumpled multi-category bar plots is very widespread in academic papers. Have a look at a Google Lens search on the focal plot in this post. Google Lens browses the internet for similarly looking images, and they are plenty, most of them coming straight from academic papers.

![](google-lens.png)

# Rotate the damn plot

Over years of [teaching dataviz][artskill] to researchers I came to understanding that this particular mistreatment of data may be the most common and easily avoidable dataviz fallacy. Another dated attempt to spread this simple knowledge yielded an educational datatviz aimed at the general audience. Here it is.

![](04-magic.png)

As you can see, much better readable text is what we immediately get via such a simple alteration of the dataviz, just **Rotate the damn plot**. There are several more equally simple dataviz rules/principles that I [keep teaching][slides] and want to write-up better here in future. If you are interested, follow the dedicated BlueSky account @[damnplot.ikashnitsky.phd][bsky], I have big plans for it.

Okay. Enough with the lengthy intro. Let's replicate the plot from the very beginning of the post and then improve it.

# Digitizing the data

But first we need the data from the plot. Of course, I could have taken it from the original source, [Gender and Generations Programme][ggp]. Or I could have asked the authors to share only the data used for this plot. But for simple plots that use a handful of data points there is a better alternative -- digitizing the values from the plot itself. There are numerous software solutions that streamline the task, including an [R package {digitize}][digitize]. This time I used the brilliant [WebPlotDigitizer][wpd]. The idea of digitizing is very straightforward -- we read the actual values from a plot and thus convert the image into data underlying it. To do that we only need to provide the information about the coordinates of the plot grid.

![](digi-1.png)

Then the remaining task is to click all the data points in already known coordinate space.

![](digi-2.png)

Just 35 clicks, and we are ready to export a clean CSV file with the data of the plot. For replicability of this post I uploaded the data and code to a [gist][gist].

![](digi-3.png)

Funny enough, I tried to set various LLMs to do the job for me, and some of them even happily reported the extracted data. I was impressed. Really impressed. Until I figured out that, once again, bullshitters are gonna bullshit. All the so called digitized data happened to be approximate guesses of varied wildness. I'm pretty sure that this not so complex task can be reasonably automated. But so far the mainstream LLMs consistently failed to do this. Here is a sneak-peek of my discussion with Claude. Everything is really impressive until you check closely.

![](claude-chat.png)

# Replicating original plot

Having digitized the data manually, we are now good to go and finally replicate the original plot.

The following lines of code retrieve and reshape the data

```{r, message=FALSE}
library(tidyverse)

# Points digitized manually using
# https://web.eecs.utk.edu/~dcostine/personal/PowerDeviceLib/DigiTest/index.html
# Data uploaded to a gist
digi <- read_csv(
    "https://gist.githubusercontent.com/ikashnitsky/8cc26eab8165b0b79f67da761aa66a1e/raw/8d44c9e6ddea51de3cbb0fdb742fb75a62a307fd/data.csv",
    col_names = c("x", "happiness")
)

# get all combinations of the categories and attach the digitized data
df <- crossing(
    country = c("United Kingdom", "Estonia", "Denmark", "Netherlands", "Czech Republic", "Finland", "Austria") |> as_factor(),
    group = c("18-29", "30-39", "40-49", "50-59", "Total")
) |>
    mutate(happiness = digi |> pull(happiness))
```

Now we have the dataset ready to be plotted. First, let's try to recreate the original plot as closely as we can. Note that I use exactly the same colors, which I picked from the original plot using a [color picker tool][col]. I also tried to outsource this simple task to LLMs. Yes, you guessed it right -- they failed.

```{r}
# recreate the plot
df |>
    ggplot(aes(x = country, y = happiness, fill = group))+
    geom_col(position = position_dodge()) +
    labs(
        x = NULL,
        y = NULL,
        fill = NULL
    ) +
    coord_cartesian(ylim = c(6, NA), expand = 0)+
    scale_fill_manual(values = c("#2f74cc", "#ff7502", "#a3d384", "#ffbc00", "#908d90"))+
    theme_minimal()+
    theme(
        legend.position = "bottom",
        panel.grid.minor = element_blank()
    )
```

Here I'll briefly mention that there are more common issues with this particular plot. As a general rule think of any of your plots to be self-sufficient if just posted on social media without any additional context. Thus, it's always a good idea to add a brief meaningful title, label the axes properly, explain the legend, and maybe add a few annotations.

# Improving the plot

The following lines of code take care of {ggplot2} theme, setting it to the one with my preferred selection of options. Earlier I wrote [a dedicated blog post][theme] about this portable theming solution.

```{r, message=FALSE}
# custom theming
devtools::source_gist("653e1040a07364ae82b1bb312501a184")
sysfonts::font_add_google("Atkinson Hyperlegible", family = "ah")
theme_set(theme_ik(base_family = "ah", base_size = 11))
```

And finally the improved version of the plot.

```{r, warning=FALSE}
# Create the plot
df |>
    ggplot(aes(y = country, x = happiness, color = group))+
    geom_point(size = 3) +
    labs(
        title = "How happy are you with your home?",
        subtitle = "Happiness scores from Generations and Gender Programme surveys\non a scale of 0 to 10",
        x = NULL,
        y = NULL,
        color = "Age group"
    ) +
    scale_color_manual(values = c("#2f74cc", "#ff7502", "#a3d384", "#ffbc00", "#908d90"))+
    theme(
        legend.position = "bottom",
        panel.grid.minor.x = element_blank(),
        axis.text.y = element_text(size = 12)
    )+
    scale_x_continuous(position = "top")

```

Note that the essential difference here is that I switched the axes effectively **rotating the damn plot**. I also used dots instead of filled bars. There is a great advantage in doing this, which is nicely illustrated by this plot. Using dots allows to trim the continuous axis to zoom closer to the data. When you do the same to a bar plot, the visual representation ofthe data gets distorted via the disproportional changes to the areas of the filled bars. Claus Wilke points this out and explains more in his brilliant [dataviz book][wilke].

> One important limitation of bars is that they need to start at zero, so that the bar length is proportional to the amount shown.

And of course I added a title, subtitle, and legend caption. Note also a small handy trick that I use all the time -- I moved x-axis labels to the top of the plot which allows me to use the subtitle as the axis label and not only save some space but also make the process of reading the plot more straightforward.

Let me conclude with just reiterating that it is hard to overestimate how important is text in dataviz. It should be meaningful and sufficiently detailed, easily readable (i.e. necessarily horizontal and large enough), preferable using some nice font. **Pay attention to the text elements of you dataviz**!

[orig]: https://www.linkedin.com/feed/update/urn:li:activity:7271909125997924353/
[early]: https://ikashnitsky.phd/2019/dotplot/
[artskill]:https://github.com/ikashnitsky/dataviz-art-skill
[slides]: https://ikashnitsky.github.io/dataviz-art-skill/slides/slides-dataviz-bssd.html
[bsky]: https://bsky.app/profile/damnplot.ikashnitsky.phd
[ggp]: https://bsky.app/profile/ggp.bsky.social
[digitize]: https://cran.r-project.org/web/packages/digitize/index.html
[wpd]: https://web.eecs.utk.edu/~dcostine/personal/PowerDeviceLib/DigiTest/index.html
[gist]: https://gist.github.com/ikashnitsky/8cc26eab8165b0b79f67da761aa66a1e
[col]: https://chromewebstore.google.com/detail/snap-color-picker/nbpljhppefmpifoffhhmllmacfdckokh?hl=en&pli=1
[theme]: https://ikashnitsky.phd/2023/gist-snippet/
[wilke]: https://clauswilke.com/dataviz/visualizing-amounts.html#dot-plots-and-heatmaps

***

::: {.callout-note}
# This post is the first in the **Damn Plot series**. Other posts will follow, for now you may follow @[damnplot.ikashnitsky.phd][bsky] BlueSky account.
:::
---
draft: true
title: "Demographic Hall of Fame"
fig-cap-location: margin
reference-location: margin
date: "2024-01-01"
image: teaser.png
categories: [r, demography, bibliometrics]
---

<!-- Top-50 authors in 10 leading demographic journals -->

I selected 10 leading demographic journals and using Scopus data looked which demographers published most papers in there ✨
I also calculated the average citations per paper for these authors and average age of their papers (in color) 👀
Isn't this demographic Hall Of Fame? 😅

using author_id
selecting document types

![](top-50-labels.png)

UDP some critical reflections for this baby-step analysis:

Of course, there are multiple assumptions, imitations, and arbitrary decisions:
— I chose only 10 journals as the demographic core (I can't think of a way to summon all demographic papers from all the not exclusively demographic journals; this selection is subjective and likely biased towards my view of demographic literature, obvious gap that I see is the field of family demography)
— the top-50 is cut by the number of publications in these journals (obvious fix — to remove editorials; but there may also be a way to include citations as a proxy of importance at the step of determining the top)
— the time horizon may receive special attention, not just color (would it make sense to introduce some measure of career stage?)
— Scopus had a specific bias for recency (openalex is the tool going forward)

Having this noted, the rest is objective. I think, in a way this *is* a demographic hall of fame 😅

***

[init]: https://fosstodon.org/@ikashnitsky/111626330689709952
[gist]: https://gist.github.com/ikashnitsky/819a7a87ed3844db0cce637f71e1c9f4
[bsky]: https://bsky.app/profile/ikashnitsky.phd/post/3kh5zbmftvw2f
---
title: "[UPD] Zotero hacks: reliably setup unlimited storage for you personal academic library"
date: "2024-08-16"
image: zotero-teaser.png
categories: [r, tutorial]
---

***

# About this tutorial

In summer 2024, Zotero had a [major update to version 7][z7]. The update affected some of the setup routines that I outlined ages ago in the [Zotero hacks post][zotero-hacks]. The recipe laid out in that old post helped me painlessly update, move, and maintain my Zotero library for more than a decade; and judging by feedback it did so for many dozens of my friends, colleagues, and just occasional people who found the tutorial useful. It became easily the most viewed post in my blog. Now, with the recent update of Zotero, I decided to update the tutorial as well, but I'm keeping the old post untouched in case someone needs the routine that worked reliably for ages.

The essence of the tutorial stays the same -- it shows how to organize a personal academic library of unlimited size for free. Here I only slightly update some steps of the setup, refresh the screenshots, and provide occasional comments from 2024[^1].

[^1]: Hello from 2024! Throughout the post, I will add notes with comments on and additions to some of the 5 years old statements. Disclaimer: they aged really well.

![](zotero-teaser.png)

# A brief (and hopefully unnecessary to you) intro to bibliographic managers

Bibliographic manager is a life saver in everyday academic life. I suffer almost physical pain just thinking about colleagues who for some reason never started using one -- all those excel spreadsheets with favorite citations, messy folders with PDFs, constant hours lost for the joy-killing task of manual reference list formatting. Once you start using a reference manager this all becomes a happily forgotten nightmare.

I tend to think of bibliographic metadata as LEGO.

![](lego.jpg){width=60%}

For each paper (book chapter / pre-print / R package) we have a number of metadata pieces -- title, authors, date published, etc. These are the LEGO blocks. For different bibliographic styles we just need to re-shuffle those blocks inserting various commas, semicolons, and quotation marks.

Bibliographic manager keeps track of all the LEGO blocks and knows (learns easily) how to compose proper citation styles out of them. All we need is to [download a specific journal's citation style][csl]. There are more than six thousand bibliographic styles! And this is my #1 argument against the conspiracy ideas of some centralized power that rules our world =)

![](https://imgs.xkcd.com/comics/standards.png){width=100%}

# Why Zotero?

There are dozens of bibliographic managers out there ([see a comparative table][wiki]). Some of them are free, the others require paid subscriptions. Probably, the most popular two are [Zotero][zotero] ~~and [Mendeley][mendeley]. Both are free to use and make money by offering cloud storage to sync PDFs of the papers. Yet, both give some limited storage for free -- Zotero gives 300MB, and Mendeley gives 2GB.~~[^2]

[^2]: Mendeley, a bibliographic manager provided freely by Elsevier, used to be a very popular alternative to Zotero, and thus the previous version of tutorial used is for comparison. Yet, as if to illustrate the point I'm making here, the proprietary program was simply killed the program that was used daily by thousands of academics.

Why do I choose and recommend Zotero then? Because it's fairly easy to set-up Zotero so that the free 300MB are only used to sync metadata (which in practice means almost infinite storage), and the PDFs are synced separately using a cloud solution of one's choice (I use Google Drive). **It's the main set-up hack that I'm showing in this blog post**. ~~There is no similar hack for Mendeley, and with them at some point one is bound to pay for extra storage.~~

Another consideration in favor of Zotero is that it's an open-source program with strong community and outspoken commitment to stay free forever, while Mendeley is an Elsevier for-profit product. Academic community knows a lot about Elsevier in particular [^3] and for-profit products in general. Here the story of Academia.edu is very indicative -- have a look at [this Forbes piece][forbes]. As a career-long decision I'm confident in choosing Zotero. Free open-source software is a safe choice for your academic workflow for ages, even decades. Just my personal example: I started my academic journey in 2012 and was lucky enough to immediately adopt Zotero. In the 12 years since, I had 10 different primary machines running Windows, Linux, and MacOS. Throughout these years and across all these different environments, my library was safely and reliably synced and developed continuously and smoothly without a single collapse.

[^3]: Unfortunately to many of those who chose to use Mendeley at some point and was reluctant to switch, Elsevier first discontinued support of the mobile apps for Mendeley, both Android and iOS, [in 2021][mend21]; and [in 2023][mend23] the corporation decided to sunset the whole project. Just like that. Here is the best illustration why it's so much more reasonable and safe choice to choose open-source community driven projects.

Finally, an example of how strong Zotero community is. Once I figured out there the style repository does not have a style for Demographic Research, one of the best journals in demography. I've opened [a request on Zotero forum][req] and in two days the style was created.

# Prerequisites

1. [Download and install Zotero][down]. It's cross-platform and works smoothly with various systems, even when the same database is sycned in parallel on machines with different operation systems. I've used `win+linux` and `win+mac` -- no sync problems ever.

2. From the same [download page][down] go to install Zotero Connector, a browser extension that helps to retrieve bibliographic metadata.

3. Create an [account on Zotero website][reg]. It will be used later on to sync the database of bibliographic metadata.

4. Download and install the two plugins we'll need -- [Zotero Attanger][za][^4] (organizes the database of PDFs) and [Better BibTeX][bbt] (exports the collections of papers to `.bib` to later use with Quarto). The plugins for Zotero are `.xpi` archives. Direct link to just download the `.xpi` files: [Zotero Attanger][za-xpi] & [Better BibTeX][bbt-xpi]. To install the plugins open Zotero and click `Tools --> Plugins`. A separate window for `Plugins manager` will pop-up.

[^4]: Here is one of the main differences of the current tutorial from [the previous version][zotero-hacks]. [Zotfile][zotfile], the brilliant plugin that helped us for ages, is no longer actively maintained. Thus, we are using a new plugin called Zotero Attanger, which just ports the crucial functionality of Zotfile to Zotero 7.

![](plugins.png)

There we need to click the options gear button and select `Install Plugin From File` option. Finally navigate to the `.xpi` file and install. Zotero will ask to restart, please do.

We are ready to go through the setup step-by-step.

# Zotero preferences

Let's walk though Zotero Settings, one tab at a time. To see and edit them go to `Edit --> Settings`. A separate window with several tabs pops up.

## General

I only uncheck the option to create automatic web page snapshots which I find not so useful compared with all the cluttering effect of all those multiple small files needed to replicate an html page locally. [^5]

[^5]: Also note the added new option to have a dark interface. For years this was one of the main requested features, and it used to be solved via a specialized plugin [Zotero Night][zn].

![](pref-general.png)

Another important option here is `File Renaming` -- to define the rules for renaming the attached PDF files. But we are going to deal with it at the very end, after tuning the `Attanger` plugin settings.

## Sync

Here we need to specify the account details to sync our database. It is important to uncheck the option `Sync full-text content` otherwise the 300MB storage will quickly get filled. We'll have the solution for full text a bit later.

![](pref-sync.png)

## Export

Choose the style for quick export using `Shift+Ctrl+C` shortcut.

## Cite

Citation styles stored locally. One nice feature here is the `Get additional styles` link which brings an integrated selection from the whole [Zotero Styles Database][csl]. Styles can also be installed from local .csl files, for that press the `+` button. Don't miss the `Word Processors` options at the bottom of this tab. There we can get the plugins that integrate Zotero to Microsoft Word and Libre Office.

![](pref-cite.png)

## Advanced

Here we are most interested in the sub-tab `Files and Folders`. This is the most important step to separate the storage of metadata and files.

![](pref-files.png)

The **first** path should lead to a directory which stores the full-text PDFs, I call it `zotero-library`. This directory should be somewhere in the part of the local file system that is synced. In my case it's the directory named `ikx-sync`, which I sync with Google Drive. The **second** path leads to the system files of Zotero, I call it `zotero-system`. This directory should be placed somewhere in the non-synced part of the local file system. It will be updated by the native Zotero sync, and it's better if those system files are not overwritten by any external sync software.

## Attanger

Next we need to setup Zotero Attanger. This extension helps to rename PDFs according to pre-defined rules and store them in a hierarchical database with meaningful names of the sub-directories. There are 4 important steps here (annotated in the screenshot below).

We need to define two paths. The **first** is the default location of the files downloaded by your browser. This option tells Attanger where to look for recently downloaded PDFs to process when you import a paper from the publisher's website (recall that earlier we installed Zotero Connector). The **second** path leads to the local directory created for the full-text PDFs, the one that I named `zotero-library` and which is synced with an external cloud solution of our choice.

![](pref-za.png)

To navigate easier in this database of PDFs use the option `Subfolder`. Here again we have a wide choice of the ways to define the rules to name the sub-directories. Click the [`documentation` link to learn the naming options][naming]. I choose to simply have a separate folder for each first author. In my case the option is `{{{ authors max="1" case="lower" }}}`. The advantage of this convention is that I only reed to remember the first author -- and I can easily find all the PDFs in the same folder, synced securely to my Google Drive, I can easily find any paper in seconds

<!-- Some weird rendering issue with {{}} -- thus {{{ are to be rendered in {{ -->

![](show-gdrive.png)

...and even from my phone on the go.

![](show-gdrive-mobile.png){width=60%}

The `Filename` option defines the rules for renaming the attached PDF files. Clicking the button `Customize Filename Format` brings us to the `Filename Format` sub-menu of the `General` Settings tab. Here we set the template according to the same [Zotero naming rules][naming], click `documentation` link to learn the naming options.

![](pref-naming.png)

Again, the options are nearly infinite. My choice is to have attached PDFs named according to their FIRST AUTHOR then YEAR then TITLE, everything in [snake_case][case], which yields file names like `kashnitsky_2021_unequally_ageing_regions_of_europe.pdf` (again an example for [my paper][popst] in *Population Studies*). The code to get such name is:
`{{{ authors max="1" suffix="_" case="snake" }}}{{ year suffix="_" }}{{ title truncate="100" case="snake"}}`.

And here comes the kill feature of the proper setup -- paths to the full texts are stored in the metadata itself. This allows seamless transition between the machines (or even a simultaneous usage across several machines) as long as the relative file paths structure starting from the base file directory `zotero-library` stays unchanged.

![](pref-bib.png)

When I need to restore my whole database of academic papers on another machine, I just go through the steps in this tutorial. As long as the data base of system metadata (`zotero-system`) is synced by Zotero and a correct link to a PDFs storage (`zotero-library`) is specified, Zotero will recognize all the relative paths to the files, and will restore the whole library. This setup also makes it possible to have the same continuously synced library on multiple machines.

## Better BibTeX

This tab appears after we install the Better BibTeX extension. The plugin is needed to export the bibliographic library, in whole or some specific collections (aka folders), as plain `.bib` text files, which are later used while writing academic papers with LaTeX, rmarkdown, Quarto, or any other text based editor. `

![](pref-bbt.png)

The most important option here is to define the rules for creating citation keys. There are almost infinite number of ways one can define these keys ([check the manual][keys]). My personal choice is `[auth:lower][year][journal:lower:abbr]`, which means that a key consists of the first author's name, publication year, and the first letters abbreviation of the journal's title, everything in lower case. For example, the key for one of [my papers][popst] published in *Population Studies* is `kashnitsky2021ps`.

Once Better BibTeX is installed and fine-tuned, exporting to `.bib` is easily achieved via the context menu -- right click on a collection (or the whole library, but this would be slow and take a long whole) and choose `Export Collection`.

![](show-bbt-export.png)

In the next small window choose the parameters of the export. There are multiple formats to choose from, yet for our purposes the default `Better BibTeX` is prefect. Then there are several other options to choose.

`Keep Updated` would monitor the exported Zotero collection and will update/overwrite the exported `.bib` file whenever it sees any changes. This is very handy, but may be quite a burden for you machine, use with caution.

![](show-bbt-options.png)

`Export Files` allows to export PDFs together with the metadata. This may come super handy if you want to quickly share a collection of articles with full texts. If this option is checked, the output will be a folder with a `.bib` text file with the papers' metadata and an inset folder `files` with the actual PDFs.

![](show-bbt-folders.png)

The nice feature of `Better BibTeX` is that it keeps the relative paths to PDFs written down in the metadata itself. This allows importing the whole collection back to Zotero (or another bibliographic manager) with full texts carried along.

![](show-bbt-bib.png)

`Better BibTeX` takes care of citation keys, the option that we tuned first in this section. Citation keys are unique identifiers of papers (or other metadata entries) in the `.bib` collection. We use the later in Quarto (or LaTeX, rmarkdowm, etc) to actually cite papers. For further hints on using `.bib` files in authoring academic texts, I suggest checking out the [beautiful reference materials of Quarto][citing].

# Conclusions and a final remark on Zotero

This tutorial offers a time-proven recipe for tuning a personal Zotero library so that everything is synced seamlessly across multiple devices. Once set up properly, you will enjoy an unlimited storage of PDFs via any side cloud solution of your chouce coupled with the highly reliable and free native sync of metadata form Zotero. As a free open-source project Zotero is not aimed at generating profits, yet subscription fees are essential for the development and sustainability of this amazing project. Personal tiers may feel a bit hefty for individuals, especially students, but if you can convince your institutions to use Zotero and get an institutional subscription, find more info [here][get-involved].

::: {.callout-tip}
# Happy paper writing with Zotero and Quarto!
:::

***

[z7]: https://www.zotero.org/blog/zotero-7/
[zotero-hacks]: https://ikashnitsky.phd/2019/zotero
[post]: https://habr.com/en/post/271045/
[habr]: https://habr.com/en/top/

[csl]: https://www.zotero.org/styles
[wiki]: https://en.wikipedia.org/wiki/Comparison_of_reference_management_software
[zotero]: https://www.zotero.org
[mendeley]: https://www.mendeley.com/download-desktop/
[forbes]: https://www.forbes.com/sites/drsarahbond/2017/01/23/dear-scholars-delete-your-account-at-academia-edu/
[mend21]: https://www.reddit.com/r/PhD/comments/m6uo8b
[mend23]: https://www.reddit.com/r/academia/comments/15ezsxi

[req]: https://forums.zotero.org/discussion/57130/style-request-demographic-research
[down]: https://www.zotero.org/download/
[reg]: https://www.zotero.org/user/register/
[za]: https://github.com/MuiseDestiny/zotero-attanger
[za-xpi]: https://github.com/MuiseDestiny/zotero-attanger/releases/latest
[zotfile]: https://github.com/jlegewie/zotfile
[bbt]: https://retorque.re/zotero-better-bibtex/
[bbt-xpi]: https://github.com/retorquere/zotero-better-bibtex/releases/latest
[keys]: https://retorque.re/zotero-better-bibtex/citation-keys/
[zn]: https://github.com/tefkah/zotero-night

[popst]: https://doi.org/10.1080/00324728.2020.1788130

[naming]: https://www.zotero.org/support/file_renaming
[case]: https://cdn.myportfolio.com/45214904-6a61-4e23-98d6-b140f8654a40/dbb99049-2916-4bc8-824f-1816f5c4f06d_rw_1920.png?h=f0b45a30ba31ad414562d1085cd6c172
[citing]: https://quarto.org/docs/authoring/citations.html
[get-involved]: https://www.zotero.org/getinvolved/
---
title: "Beyond Fraud: How IHME Distorts Academic Metrics"
fig-cap-location: margin
reference-location: margin
date: "2025-10-13"
image: teaser.png
categories: [r, academia, bibliometrics, demography]
---

Recently, a [post on LinkedIn][li] highlighted a Google Scholar profile of an apparently just starting PhD researcher who suddenly started accumulating unbelievable counts of citations to his questionably numerous papers. Usually, such profiles are a clear indication of involvement into the worst publication practices, mostly paper mills. The post generated a predictable wave of comments along the lines of this common explanation. But this case is different, it is not the usual fraud per se. But this is a very curious and rather well known issue in public health / epidemiology / demography.

There is a powerful group initially called the Global Burden of Diseases established by Chris Murray. Then, with outsized funding by Gates Foundation, this group morphed into an institute called IHME -- Institute of Health Metrics Evaluation. They are known for existing outside the normal science practice. As part of this, they are churning out papers in The Lancet as if it's their pocket preprint server. (The most beautiful party of the story is how IHME awarded the editor in chief of The Lancet with a [$100k award for his service to science][1] 🙃).  And these papers routinely washout the definition of authorship, as some of them list more than a thousand authors. Any collaborator, however insignificant, who may have provided a data point in their global reviews, becomes a highly cited researcher by the conventional metrics.

![An illustration of the collaborative work on one of the IHME manuscript, courtesy of Gemini/nanobanana](1k-auth.png)

IHME really screwed up the bibliometrics evaluation of several scientific fields. Thousands of researchers around the world claim unwarranted recognition for their blown-up citation metrics. And fractional counting (when incoming citations are shared by coauthors according to their contribution) is simply not yet there as the general-use go-to research evaluation tool. The net effect of this authorship-citation inflation is not innocent. I did a back-of-an-envelope [calculation back in 2021][2]. Since I didn’t find back my old calculations, I re-did it today. In the world of bibliometrics without fractional counting (think of the most widely circulated numbers from Google Scholar, Scopus, WoS), when you cite a paper with many authors, each one of them receives a full citation point. Basically, papers with more co-authors inflate the currency of this market via generating more citation points once they get cited. Now, back to the IHME issue. Consider [just one of the many GBD papers][3]. Yes, it lists 940 names as authors, and it’s cited 7550 times ([OpenAlex, 2025-10-09][4]). This  creates 7.1 million citation points. Just one paper, published in 2020. Now, my field’s leading journal Demography has published 3838 papers since its launch in 1964, and [these papers were cited 258k times][5]. Accounting for multiple authorship of these papers, we get 572k citation points. So, just one fairly recent IHME paper generated 12 times more citation points than all of the papers ever published in Demography journal in it's 6+ decades since 1964. [Data and replication code here][6].

The whole IHME story is a fascinating one (covered in all details by Timothy Schwab: [initial article in The Nation][7] and [a dedicated book later][8]) I guess, at the core of it is a genuine scientific endeavor. Chris Murray was a visionary in his early career, and the creation of the Global Burden of Diseases was an important milestone, impossible without his enthusiasm and organizational talent. It was his burning fire and the talent of igniting others that brought him to the massive and exclusive funding by Bill and Melinda Gates, who were apparently genuinely impressed and saw this outsized funding as an opportunity to contribute largely to the development of global public health. Which it did. At the beginning. But then a curious side effect happened (akin the digression of absolute monarchs) — the generous finding placed IHME outside the normal feedback and evaluation loop of the normal scientific process. And with time the quality of their products declined dramatically. Not necessarily the GBD most. But their global population estimates [were very problematic][9], and also obsolete with [World Population Prospects][10]. Even more outrageous fuckup happened with their COVID spread model, losing in prediction accuracy to *every* other model, notably to the one created by one postdoc. Fun fact, they eventually quietly retired the COVID model [as if the embarrassment never happened][11].

**Scientific excellence is impossible without feedback!**

[1]: https://www.healthdata.org/news-events/newsroom/news-releases/activist-editor-richard-horton-lancet-receives-100000-roux-prize
[2]: https://x.com/ikashnitsky/status/1440960984341000193
[3]: https://www.thelancet.com/journals/lancet/article/piis0140-6736(20)30752-2/fulltext
[4]: https://openalex.org/works/w3092861045
[5]: https://openalex.org/sources/s30543418
[6]: https://gist.github.com/ikashnitsky/cc6d7ee2d9d0e5af78822e6a467820ad
[7]:  https://www.thenation.com/article/society/gates-covid-data-ihme
[8]: https://www.amazon.com/Bill-Gates-Problem-Reckoning-Billionaire/dp/1250850096
[9]: https://www.thelancet.com/journals/lancet/article/PIIS0140-6736(21)01051-5/fulltext
[10]: https://doi.org/10.31235/osf.io/5syef
[11]: https://x.com/phytools_liam/status/1449443388256923653

::: {.callout-tip}
# This post is a rather spontaneous attempt to pull together my previous fragmented mentions of the issue over [Twitter][twi] and a more recent [LinkedIn comment][lic]
:::

***

[twi]: https://x.com/search?q=from%3Aikashnitsky%20ihme&src=recent_search_click
[li]: https://www.linkedin.com/posts/publishing-with-integrity_i-was-sent-a-google-scholar-profile-via-a-activity-7381133506355056640-TU2d
[lic]: https://www.linkedin.com/feed/update/urn:li:activity:7381133506355056640?commentUrn=urn%3Ali%3Acomment%3A%28activity%3A7381133506355056640%2C7381207133352087552%29&dashCommentUrn=urn%3Ali%3Afsd_comment%3A%287381207133352087552%2Curn%3Ali%3Aactivity%3A7381133506355056640%29
---
draft: true
title: "Simple but exact tasks are not that simple for LLMs"
fig-cap-location: margin
reference-location: margin
date: "2025-07-11"
image: teaser.png
categories: [r, llm, dataviz]
---


<!-- Top-50 authors in 10 leading demographic journals -->

Recently a research paper made quite a splash [in] over social media, it claimed that experienced developers are wasting more time fiddling around with LLMs than actually saving time with their help. In this blog post I am going to show you how exactly such things may actually happen =)


This week marks a significant event in my new professional life -- I rolled out the yearly update of Lifelines, an important dataset developed by Data Science Lab of Statistics Denmark. Since recently, I am in charge of development and updating this product.

Briefly describe lifelines

And while I was updating the documentation of the package I needed to recreate a simple plot that illustrates the possible types of lifelines observed in the data set. The historical plot was developed at some point by someone and of course the code was never to be traced. So I needed to replicate the plot. Pretty straightforward.

Yet I came up with an idea of offloading the task to the magnificent large language models. The task seems both easy and possibly not that easy. So I uploaded the picture and asked the models to analyze it and then with the text prompt asked to recreate the plot by R scripting. This blog post documents their surprisingly lengthy and frustrating experience of solving the task through multiple top of the class models. In the end I managed to achieve a recent result that only requested minimal aesthetic tweaking. Spoiler: the most able model turned out to be Google's Gemini 2.5 Pro, which is surprisingly available for free via there exploratory project called Google AI Studio. You see I'm not trying to hoodwing you into reading this post further than necessary. Please continue if you wanted to see how different models attempt in the task struggled and mostly failed.


This document showcases various attempts by different Large Language Models (LLMs) to recreate a schematic illustration in R using `tidyverse` and `ggplot2`. The initial prompt provided an image of the desired plot.

## Claude 4.0 Sonnet via pplx

Claude 4.0 Sonnet is a large language model from Anthropic. It's known for its strong performance in a variety of natural language processing tasks, including text generation, summarization, and question answering. It is designed to be a more balanced model in terms of performance and cost. [28, 29, 39, 40]

### First Attempt



```{r}
#| eval: false
library(ggplot2)
library(dplyr)

# Create data for the diagonal lines (lifelines/cohort lines)
lines_data <- data.frame(
    xstart = c(1986, 1986, 1986, 1986, 1986, 1986, 1986),
    xend = c(2018, 2018, 2018, 2018, 2018, 2018, 2018),
    ystart = c(0, 10, 20, 30, 40, 50, 60),
    yend = c(32, 42, 52, 62, 72, 82, 92)
)

# Create data for the blue points (observed data points)
points_data <- data.frame(
    x = c(1987, 1987, 1996),
    y = c(87, 76, 62)
)

# Create the plot
ggplot() +
    # Add diagonal lines
    geom_segment(data = lines_data,
                 aes(x = xstart, y = ystart, xend = xend, yend = yend),
                 color = "blue",
                 size = 0.8) +

    # Add points
    geom_point(data = points_data,
               aes(x = x, y = y),
               color = "blue",
               size = 2) +

    # Set axis scales and labels
    scale_x_continuous(name = "Calendar time",
                       breaks = seq(1986, 2018, by = 8),
                       limits = c(1986, 2018)) +

    scale_y_continuous(name = "Age",
                       breaks = seq(0, 100, by = 20),
                       limits = c(0, 100)) +

    # Apply minimal theme with grid
    theme_minimal() +
    theme(
        panel.grid.major = element_line(color = "grey80", size = 0.5),
        panel.grid.minor = element_line(color = "grey90", size = 0.3),
        axis.title = element_text(size = 12),
        axis.text = element_text(size = 10)
    )

ggsave("/rout/rec-claude.pdf", width = 6, height = 4.5)
```

### Second Attempt

```{r}
#| eval: false
# Load the required libraries
library(ggplot2)
library(dplyr)

# Create a data frame for the individual line segments observed in the plot
# These represent different cohort groups over different time periods.
segments_data <- data.frame(
    x_start = c(1986, 1986, 1986, 1986, 1986, 2003, 2003, 2003, 2003, 2003),
    y_start = c(0, 10, 20, 30, 53, 0, 5, 10, 30, 40),
    x_end   = c(2002, 2002, 2002, 2002, 1995, 2018, 2018, 2018, 2018, 2018),
    y_end   = c(16, 26, 36, 46, 62, 15, 20, 25, 45, 55)
)

# Create a data frame for the three distinct data points
points_data <- data.frame(
    x_val = c(1987, 1988, 1995),
    y_val = c(87, 76, 62)
)

# Generate the plot
ggplot() +
    # Add the diagonal line segments
    geom_segment(
        data = segments_data,
        aes(x = x_start, y = y_start, xend = x_end, yend = y_end),
        color = "blue",
        linewidth = 0.6
    ) +

    # Add the data points
    geom_point(
        data = points_data,
        aes(x = x_val, y = y_val),
        color = "blue",
        size = 2.5
    ) +

    # Ensure the aspect ratio is 1:1, so lifelines have a true 45-degree slope
    coord_fixed(ratio = 1) +

    # Configure the axes to match the schematic
    scale_x_continuous(
        name = "Calendar time",
        breaks = seq(1986, 2018, by = 8),
        minor_breaks = seq(1986, 2018, by = 2),
        limits = c(1986, 2018),
        expand = c(0.01, 0.01)
    ) +
    scale_y_continuous(
        name = "Age",
        breaks = seq(0, 100, by = 20),
        minor_breaks = seq(0, 100, by = 10),
        limits = c(0, 100),
        expand = c(0.01, 0.01)
    ) +

    # Apply a minimal theme and customize the grid and panel
    theme_bw() +
    theme(
        axis.title.x = element_text(margin = margin(t = 15)),
        axis.title.y = element_text(margin = margin(r = 15)),
        panel.grid.major = element_line(color = "grey75", linewidth = 0.5),
        panel.grid.minor = element_line(color = "grey85", linetype = "dashed", linewidth = 0.35),
        panel.border = element_rect(color = "black", linewidth = 1)
    )

ggsave("/rout/rec-claude-two.pdf", width = 6, height = 4.5)
```

### Third Attempt

```{r}
#| eval: false
# Load the required libraries
library(ggplot2)
library(dplyr)

# Create a data frame for the individual line segments
# Data has been carefully adjusted to fit the 40-60 age range
segments_data <- data.frame(
    x_start = c(1986, 1986, 1986, 1986, 1986, 2003, 2003, 2003, 2003, 2003),
    y_start = c(40.5, 42.5, 44.5, 46.5, 48.5, 41.5, 43.5, 45.5, 47.5, 49.5),
    x_end   = c(2002, 2002, 2002, 2002, 1995, 2018, 2018, 2018, 2018, 2018),
    y_end   = c(56.5, 58.5, 60.5, 62.5, 57.5, 56.5, 58.5, 60.5, 62.5, 64.5)
)

# Create a data frame for the three distinct data points
# Adjusted to fall within the 40-60 age range
points_data <- data.frame(
    x_val = c(1987, 1988, 1995),
    y_val = c(58.5, 52.5, 48.5)
)

# Generate the plot
ggplot() +
    # Add the diagonal line segments
    geom_segment(
        data = segments_data,
        aes(x = x_start, y = y_start, xend = x_end, yend = y_end),
        color = "blue",
        linewidth = 0.6
    ) +

    # Add the data points
    geom_point(
        data = points_data,
        aes(x = x_val, y = y_val),
        color = "blue",
        size = 2.5
    ) +

    # Ensure the aspect ratio is 1:1 for proper Lexis surface representation
    coord_fixed(ratio = 1) +

    # Configure the axes for the 40-60 age range
    scale_x_continuous(
        name = "Calendar time",
        breaks = seq(1986, 2018, by = 8),
        minor_breaks = seq(1986, 2018, by = 2),
        limits = c(1986, 2018),
        expand = c(0.01, 0.01)
    ) +
    scale_y_continuous(
        name = "Age",
        breaks = seq(40, 60, by = 5),
        minor_breaks = seq(40, 60, by = 2.5),
        limits = c(40, 60),
        expand = c(0.01, 0.01)
    ) +

    # Apply a minimal theme and customize the grid and panel
    theme_bw() +
    theme(
        axis.title.x = element_text(margin = margin(t = 15)),
        axis.title.y = element_text(margin = margin(r = 15)),
        panel.grid.major = element_line(color = "grey75", linewidth = 0.5),
        panel.grid.minor = element_line(color = "grey85", linetype = "dashed", linewidth = 0.35),
        panel.border = element_rect(color = "black", linewidth = 1)
    )

ggsave("/rout/rec-claude-three.pdf", width = 6, height = 4.5)
```

### Fourth Attempt

```{r}
#| eval: false
# Load the required libraries
library(ggplot2)
library(dplyr)

# Create lifeline segments that END at death points
# These represent individual life trajectories until death
death_lifelines <- data.frame(
    x_start = c(1986, 1986, 1986),
    y_start = c(40.5, 34.5, 29.5),
    x_end   = c(1987, 1988, 1995),
    y_end   = c(58.5, 52.5, 48.5)
)

# Create lifeline segments with emigration gaps
# These show people leaving and re-entering the population
emigration_lifelines <- data.frame(
    # First segments (before emigration)
    x_start = c(1986, 1986, 1986, 1986),
    y_start = c(42.0, 44.0, 46.0, 48.0),
    x_end   = c(1992, 1994, 1990, 1993),
    y_end   = c(48.0, 50.0, 46.0, 49.0),

    # Second segments (after re-immigration)
    x_start_2 = c(1998, 2000, 1996, 2002),
    y_start_2 = c(54.0, 56.0, 52.0, 58.0),
    x_end_2   = c(2018, 2018, 2018, 2018),
    y_end_2   = c(74.0, 76.0, 72.0, 78.0)
)

# Continuous lifelines (no emigration)
continuous_lifelines <- data.frame(
    x_start = c(1986, 1986, 1986),
    y_start = c(41.0, 43.0, 45.0),
    x_end   = c(2018, 2018, 2018),
    y_end   = c(73.0, 75.0, 77.0)
)

# Death points (endpoints of lifelines)
death_points <- data.frame(
    x_val = c(1987, 1988, 1995),
    y_val = c(58.5, 52.5, 48.5)
)

# Generate the plot
ggplot() +
    # Add lifelines that end in death
    geom_segment(
        data = death_lifelines,
        aes(x = x_start, y = y_start, xend = x_end, yend = y_end),
        color = "blue",
        linewidth = 0.8
    ) +

    # Add first segments of emigration lifelines
    geom_segment(
        data = emigration_lifelines,
        aes(x = x_start, y = y_start, xend = x_end, yend = y_end),
        color = "blue",
        linewidth = 0.6
    ) +

    # Add second segments of emigration lifelines (after re-immigration)
    geom_segment(
        data = emigration_lifelines,
        aes(x = x_start_2, y = y_start_2, xend = x_end_2, yend = y_end_2),
        color = "blue",
        linewidth = 0.6
    ) +

    # Add continuous lifelines (no emigration)
    geom_segment(
        data = continuous_lifelines,
        aes(x = x_start, y = y_start, xend = x_end, yend = y_end),
        color = "blue",
        linewidth = 0.6
    ) +

    # Add death points at the END of lifelines
    geom_point(
        data = death_points,
        aes(x = x_val, y = y_val),
        color = "blue",
        size = 3,
        shape = 16
    ) +

    # Ensure proper Lexis surface representation
    coord_fixed(ratio = 1) +

    # Configure the axes
    scale_x_continuous(
        name = "Calendar time",
        breaks = seq(1986, 2018, by = 8),
        minor_breaks = seq(1986, 2018, by = 2),
        limits = c(1986, 2018),
        expand = c(0.01, 0.01)
    ) +
    scale_y_continuous(
        name = "Age",
        breaks = seq(40, 80, by = 10),
        minor_breaks = seq(40, 80, by = 5),
        limits = c(40, 80),
        expand = c(0.01, 0.01)
    ) +

    # Apply theme
    theme_bw() +
    theme(
        axis.title.x = element_text(margin = margin(t = 15)),
        axis.title.y = element_text(margin = margin(r = 15)),
        panel.grid.major = element_line(color = "grey75", linewidth = 0.5),
        panel.grid.minor = element_line(color = "grey85", linetype = "dashed", linewidth = 0.35),
        panel.border = element_rect(color = "black", linewidth = 1)
    )

ggsave("/rout/rec-claude-four.pdf", width = 6, height = 4.5)
```

### Fifth Attempt

```{r}
#| eval: false
# Load the required libraries
library(ggplot2)
library(dplyr)

# Create the main lifeline segments - these are the core diagonal lines
# Each represents a birth cohort aging through time
main_lifelines <- data.frame(
    x_start = c(1986, 1986, 1986, 1986, 1986),
    y_start = c(41, 43, 45, 47, 49),
    x_end   = c(2018, 2018, 2018, 2018, 2018),
    y_end   = c(73, 75, 77, 79, 81)
)

# Lifelines that end in death (these connect to the death points)
death_lifelines <- data.frame(
    x_start = c(1986, 1986, 1995),
    y_start = c(40, 42, 47),
    x_end   = c(1987, 1988, 1996),
    y_end   = c(58, 52, 48)
)

# Lifelines with emigration gaps - first segment
emigration_first <- data.frame(
    x_start = c(1986, 1986),
    y_start = c(44, 46),
    x_end   = c(1992, 1994),
    y_end   = c(50, 52)
)

# Lifelines with emigration gaps - second segment (after re-immigration)
emigration_second <- data.frame(
    x_start = c(1998, 2000),
    y_start = c(56, 58),
    x_end   = c(2018, 2018),
    y_end   = c(76, 78)
)

# Death points - these mark the observed deaths
death_points <- data.frame(
    x_val = c(1987, 1988, 1996),
    y_val = c(58, 52, 48)
)

# Create the plot
ggplot() +
    # Add main continuous lifelines
    geom_segment(
        data = main_lifelines,
        aes(x = x_start, y = y_start, xend = x_end, yend = y_end),
        color = "blue",
        linewidth = 0.7
    ) +

    # Add lifelines that end in death
    geom_segment(
        data = death_lifelines,
        aes(x = x_start, y = y_start, xend = x_end, yend = y_end),
        color = "blue",
        linewidth = 0.7
    ) +

    # Add first segments of emigration lifelines
    geom_segment(
        data = emigration_first,
        aes(x = x_start, y = y_start, xend = x_end, yend = y_end),
        color = "blue",
        linewidth = 0.7
    ) +

    # Add second segments of emigration lifelines
    geom_segment(
        data = emigration_second,
        aes(x = x_start, y = y_start, xend = x_end, yend = y_end),
        color = "blue",
        linewidth = 0.7
    ) +

    # Add death points
    geom_point(
        data = death_points,
        aes(x = x_val, y = y_val),
        color = "blue",
        size = 3
    ) +

    # Maintain 1:1 aspect ratio for proper Lexis surface
    coord_fixed(ratio = 1) +

    # Set up axes to match original
    scale_x_continuous(
        name = "Calendar time",
        breaks = seq(1986, 2018, by = 8),
        limits = c(1986, 2018),
        expand = c(0.02, 0.02)
    ) +

    scale_y_continuous(
        name = "Age",
        breaks = seq(40, 80, by = 10),
        limits = c(40, 80),
        expand = c(0.02, 0.02)
    ) +

    # Clean theme matching the original
    theme_minimal() +
    theme(
        panel.grid.major = element_line(color = "grey80", linewidth = 0.5),
        panel.grid.minor = element_line(color = "grey90", linewidth = 0.3),
        panel.border = element_rect(color = "black", fill = NA, linewidth = 1),
        axis.title = element_text(size = 12),
        axis.text = element_text(size = 10)
    )

ggsave("/rout/rec-claude-five.pdf", width = 6, height = 4.5)
```

## Gemini 2.5 Pro via pplx

Gemini 2.5 Pro is a powerful, multimodal large language model from Google. It excels at complex reasoning, coding, and analyzing large datasets containing text, images, audio, and video. [2, 5, 8, 9, 10]

```{r}
#| eval: false
# Load the tidyverse library, which includes ggplot2
library(tidyverse)

# --- 1. Prepare the Data ---

# Create a tibble (a modern data frame) for the points
# Each row represents a single point with x and y coordinates.
points_data <- tribble(
    ~calendar_time, ~age,
    1988,           88,
    1989,           77,
    1995,           63
)

# Create a tibble for the line segments.
# Each row defines a line with start (x_start, y_start) and end (x_end, y_end) coordinates.
lines_data <- tribble(
    ~x_start, ~y_start, ~x_end, ~y_end,
    1986,     53,       1996,   63,
    1990,     35,       2002,   47,
    1986,     19,       2002,   35,
    1986,     11,       2002,   27,
    2004,     30,       2018,   44,
    2004,     20,       2018,   34,
    2004,     0,        2018,   14
)

# --- 2. Build the Plot ---

# Create the plot using ggplot2
ggplot() +
    # Add the line segments using geom_segment
    geom_segment(
        data = lines_data,
        aes(x = x_start, y = y_start, xend = x_end, yend = y_end),
        color = "blue",
        linewidth = 1 # Adjust line thickness if needed
    ) +

    # Add the points using geom_point
    geom_point(
        data = points_data,
        aes(x = calendar_time, y = age),
        color = "blue",
        size = 3.5 # Adjust point size
    ) +

    # --- 3. Customize Appearance ---

    # Customize the x-axis to match the image
    scale_x_continuous(
        name = "Calendar time",
        breaks = seq(1986, 2018, by = 8), # Set breaks at 8-year intervals
        limits = c(1985, 2018)
    ) +

    # Customize the y-axis to match the image
    scale_y_continuous(
        name = "Age",
        breaks = seq(0, 100, by = 20), # Set breaks at 20-year intervals
        limits = c(0, 100)
    ) +

    # Apply a theme and customize the grid
    theme_bw() + # Start with a theme that has a white background and grid
    theme(
        panel.grid.major = element_line(color = "grey75"),
        panel.grid.minor = element_line(color = "grey90"),
        axis.title = element_text(size = 12),
        plot.background = element_rect(fill = "white", color = NA) # Ensure background is white
    )

ggsave("/rout/rec-gemini.pdf", width = 6, height = 4.5)
```

## Perplexity Research mode

Perplexity AI offers a "Research mode" that functions as an AI-powered search engine. It synthesizes information from various sources to provide comprehensive answers with citations, making it useful for in-depth research tasks. [15, 34, 45]

### First Attempt

```{r}
#| eval: false
# Load required libraries
library(ggplot2)
library(tidyverse)

# Create the data points from the image
data_points <- data.frame(
    calendar_time = c(1988, 1990, 1996),
    age = c(85, 75, 62)
)

# Create data for the trend lines
# Based on the image, there appear to be 3 parallel trend lines
trend_years <- seq(1986, 2018, length.out = 100)

# Create three trend lines with different intercepts but similar slopes
trend_data <- data.frame(
    calendar_time = rep(trend_years, 3),
    age = c(
        90 - 0.8 * (trend_years - 1986),  # Top trend line
        70 - 0.8 * (trend_years - 1986),  # Middle trend line
        50 - 0.8 * (trend_years - 1986)   # Bottom trend line
    ),
    line_group = rep(c("Line 1", "Line 2", "Line 3"), each = length(trend_years))
)

# Create the plot
ggplot() +
    # Add trend lines
    geom_line(data = trend_data,
              aes(x = calendar_time, y = age, group = line_group),
              color = "steelblue",
              size = 0.8) +

    # Add data points
    geom_point(data = data_points,
               aes(x = calendar_time, y = age),
               color = "steelblue",
               size = 3) +

    # Set axis labels
    labs(x = "Calendar time",
         y = "Age") +

    # Set axis limits and breaks
    scale_x_continuous(limits = c(1986, 2018),
                       breaks = seq(1986, 2018, by = 8)) +
    scale_y_continuous(limits = c(0, 100),
                       breaks = seq(0, 100, by = 20)) +

    # Apply minimal theme with grid
    theme_minimal() +

    # Customize the theme
    theme(
        panel.grid.major = element_line(color = "gray80", size = 0.5),
        panel.grid.minor = element_line(color = "gray90", size = 0.3),
        axis.text = element_text(size = 10),
        axis.title = element_text(size = 12),
        panel.background = element_rect(fill = "white", color = NA),
        plot.background = element_rect(fill = "white", color = NA)
    )

ggsave("/rout/rec-perplexity.pdf", width = 6, height = 4.5)
```

### Second Attempt

```{r}
#| eval: false
# Load required libraries
library(ggplot2)
library(dplyr)

# Create the exact data points from the image
data_points <- data.frame(
    calendar_time = c(1988, 1990, 1996),
    age = c(85, 75, 62)
)

# Create the three trend lines with exact parameters from image analysis
# All lines have slope = 0.344 but different intercepts
x_vals <- seq(1986, 2018, length.out = 100)

trend_data <- data.frame(
    calendar_time = rep(x_vals, 3),
    age = c(
        0.344 * x_vals - 630.7,  # Top trend line
        0.344 * x_vals - 647.7,  # Middle trend line
        0.344 * x_vals - 664.7   # Bottom trend line
    ),
    line_id = rep(c("line1", "line2", "line3"), each = length(x_vals))
)

# Create the exact plot
ggplot() +
    # Add the three trend lines
    geom_line(data = trend_data,
              aes(x = calendar_time, y = age, group = line_id),
              color = "#4682B4",  # Steel blue color
              size = 0.7,
              alpha = 0.8) +

    # Add the three data points
    geom_point(data = data_points,
               aes(x = calendar_time, y = age),
               color = "#4682B4",  # Steel blue color
               size = 2.5,
               alpha = 0.9) +

    # Set exact axis labels
    labs(x = "Calendar time",
         y = "Age") +

    # Set exact axis limits and breaks to match the image
    scale_x_continuous(
        limits = c(1986, 2018),
        breaks = c(1986, 1994, 2002, 2010, 2018),
        expand = c(0, 0)
    ) +

    scale_y_continuous(
        limits = c(0, 100),
        breaks = seq(0, 100, by = 20),
        expand = c(0, 0)
    ) +

    # Apply the exact theme to match the image
    theme_minimal() +

    theme(
        # Grid styling to match the image exactly
        panel.grid.major = element_line(color = "gray85", size = 0.5, linetype = "solid"),
        panel.grid.minor = element_line(color = "gray92", size = 0.3, linetype = "solid"),

        # Background and panel
        panel.background = element_rect(fill = "white", color = NA),
        plot.background = element_rect(fill = "white", color = NA),

        # Axis styling
        axis.line = element_blank(),
        axis.ticks = element_line(color = "gray60", size = 0.4),
        axis.ticks.length = unit(0.15, "cm"),
        axis.text = element_text(color = "gray30", size = 9),
        axis.title = element_text(color = "gray20", size = 10),

        # Remove legend
        legend.position = "none",

        # Plot margins
        plot.margin = margin(15, 15, 15, 15)
    )

ggsave("/rout/rec-perplexity-two.pdf", width = 6, height = 4.5)
```

## Grok via pplx

Grok is a large language model from xAI, known for its ability to access real-time information through its integration with the X (formerly Twitter) platform. It is designed to have a bit of a rebellious and witty personality. [13, 17, 21, 22, 35]

```{r}
#| eval: false
# Load required libraries
library(ggplot2)
library(dplyr)

# Data points from the schematic
data_points <- data.frame(
    calendar_time = c(1988, 1990, 1996),
    age = c(85, 75, 62)
)

# Create three parallel lines with the same slope, spaced evenly
x_vals <- seq(1986, 2018, length.out = 100)
slope <- 0.344  # Estimated slope from the schematic

trend_data <- data.frame(
    calendar_time = rep(x_vals, 3),
    age = c(
        slope * x_vals - 600,  # Top line
        slope * x_vals - 620,  # Middle line
        slope * x_vals - 640   # Bottom line
    ),
    line_id = rep(c("line1", "line2", "line3"), each = length(x_vals))
)

# Plot
ggplot() +
    # Add trend lines
    geom_line(
        data = trend_data,
        aes(x = calendar_time, y = age, group = line_id),
        color = "#377eb8",  # Blue
        size = 0.7
    ) +
    # Add points
    geom_point(
        data = data_points,
        aes(x = calendar_time, y = age),
        color = "#377eb8",
        size = 3
    ) +
    # Axes labels
    labs(x = "Calendar time", y = "Age") +
    # Axes limits and breaks
    scale_x_continuous(
        limits = c(1986, 2018),
        breaks = c(1986, 1994, 2002, 2010, 2018),
        expand = c(0, 0)
    ) +
    scale_y_continuous(
        limits = c(0, 100),
        breaks = seq(0, 100, by = 20),
        expand = c(0, 0)
    ) +
    # Minimal theme and grid styling
    theme_minimal(base_size = 12) +
    theme(
        panel.grid.major = element_line(color = "gray80", size = 0.5),
        panel.grid.minor = element_line(color = "gray90", size = 0.3),
        axis.line = element_blank(),
        axis.ticks = element_line(color = "gray60", size = 0.4),
        axis.ticks.length = unit(0.15, "cm"),
        axis.text = element_text(color = "gray30", size = 10),
        axis.title = element_text(color = "gray20", size = 12),
        legend.position = "none",
        plot.background = element_rect(fill = "white", color = NA),
        panel.background = element_rect(fill = "white", color = NA),
        plot.margin = margin(15, 15, 15, 15)
    )

ggsave("/rout/rec-grok.pdf", width = 6, height = 4.5)
```

## GPT 4.1 via pplx

GPT-4.1 is a family of large language models from OpenAI, designed with a focus on developer experience, including improved instruction following and coding capabilities. It comes in different sizes (GPT-4.1, GPT-4.1 mini, and GPT-4.1 nano) to suit various performance and cost needs. [3, 6, 7, 16, 24]

```{r}
#| eval: false
library(tidyverse)

# Data for points
points_df <- tibble(
    calendar_time = c(1986, 1986, 1994),
    age = c(88, 77, 63)
)

# Data for lines
line_starts <- tibble(
    start_time = c(1986, 1986, 1986, 1986, 1986),
    start_age = c(0, 20, 40, 60, 80)
)

line_ends <- tibble(
    end_time = c(2018, 2018, 2018, 2018, 2018),
    end_age = c(32, 52, 72, 92, 112) # 2018-1986 = 32
)

lines_df <- line_starts %>%
    mutate(end_time = end_time,
           end_age = start_age + (end_time - start_time)) %>%
    select(start_time, start_age, end_time, end_age)

# ERROR here -- next I fix it

# Data for lines
line_starts <- tibble(
    start_time = c(1986, 1986, 1986, 1986, 1986),
    start_age = c(0, 20, 40, 60, 80),
    end_time = c(2018, 2018, 2018, 2018, 2018),
    end_age = c(32, 52, 72, 92, 112) # 2018-1986 = 32
)

lines_df <- line_starts %>%
    mutate(end_time = end_time,
           end_age = start_age + (end_time - start_time)) %>%
    select(start_time, start_age, end_time, end_age)

# Prepare data for geom_segment
lines_plot <- tibble(
    x = rep(1986, 5),
    xend = rep(2018, 5),
    y = c(0, 20, 40, 60, 80),
    yend = c(32, 52, 72, 92, 112)
)

# Plot
ggplot() +
    geom_segment(data = lines_plot, aes(x = x, y = y, xend = xend, yend = yend), color = "blue") +
    geom_point(data = points_df, aes(x = calendar_time, y = age), color = "blue", size = 3) +
    scale_x_continuous(breaks = seq(1986, 2018, by = 8), limits = c(1985, 2019)) +
    scale_y_continuous(limits = c(0, 100)) +
    labs(x = "Calendar time", y = "Age") +
    theme_minimal() +
    theme(panel.grid.major = element_line(color = "grey80"))


ggsave("/rout/rec-gpt.pdf", width = 6, height = 4.5)
```

## o3 reasoning via pplx

OpenAI's o3 is a "reasoning" model, meaning it's specifically designed to tackle complex problems that require step-by-step logical thinking. It often takes more time to generate a response as it deliberates on the problem. [4, 18, 30, 36, 38]

```{r}
#| eval: false
# Install/load tidyverse (includes ggplot2)
# install.packages("tidyverse")
library(tidyverse)

## 1. Data -------------------------------------------------------------

# Points (blue dots)
points_df <- tribble(
    ~cal_time, ~age,
    1988, 88,
    1989, 78,
    1995, 63
)

# Diagonal life-lines (blue segments)
lines_df <- tribble(
    # x-start, y-start, x-end, y-end
    1986, 53,  1996, 63,   # upper line through dot at ≈63
    1988, 35,  2002, 48,   # middle “life line”
    1986, 19,  2002, 35,
    1986, 11,  2002, 27,
    2004, 30,  2018, 44,
    2004, 20,  2018, 34,
    2004,  0,  2018, 14
)

#' ERROR
#' Error in `tribble()`:
#' ! Must specify at least one column using the
#' `~name` syntax.
#' Run `rlang::last_trace()` to see where the error occurred.

# manual fix
# Diagonal life-lines (blue segments)
lines_df <- tribble(
    ~x_start, ~y_start, ~x_end, ~y_end,
    1986, 53,  1996, 63,   # upper line through dot at ≈63
    1988, 35,  2002, 48,   # middle “life line”
    1986, 19,  2002, 35,
    1986, 11,  2002, 27,
    2004, 30,  2018, 44,
    2004, 20,  2018, 34,
    2004,  0,  2018, 14
)

## 2. Plot -------------------------------------------------------------

ggplot() +
    # life-lines
    geom_segment(
        data = lines_df,
        aes(x = x_start, y = y_start, xend = x_end, yend = y_end),
        colour = "royalblue", linewidth = 0.9
    ) +
    # cohort points
    geom_point(
        data = points_df,
        aes(cal_time, age),
        colour = "royalblue", size = 3
    ) +
    # axes
    scale_x_continuous(
        name   = "Calendar time",
        limits = c(1985, 2019),
        breaks = seq(1986, 2018, by = 8)
    ) +
    scale_y_continuous(
        name   = "Age",
        limits = c(0, 100),
        breaks = seq(0, 100, by = 20)
    ) +
    # theme tweaks
    theme_bw() +
    theme(
        panel.grid.major = element_line(colour = "grey70"),
        panel.grid.minor = element_line(colour = "grey90"),
        axis.title       = element_text(size = 12),
        plot.background  = element_rect(fill = "white", colour = NA)
    )

ggsave("/rout/rec-o3.pdf", width = 6, height = 4.5)
```

## Claude Sonnet 4 web

This is another instance of using Claude Sonnet 4, likely through a different web interface. The core model is the same as the one used via pplx. [28, 29, 39, 40]

```{r}
#| eval: false
library(tidyverse)
library(ggplot2)

# Create the base plot
p <- ggplot() +
    # Set up the coordinate system and limits
    xlim(1986, 2018) +
    ylim(0, 100) +

    # Add the parallel trend lines (these appear to be cohort lines)
    # Each line represents a different birth cohort
    geom_abline(intercept = 50, slope = 1, color = "steelblue", size = 0.8) +
    geom_abline(intercept = 40, slope = 1, color = "steelblue", size = 0.8) +
    geom_abline(intercept = 30, slope = 1, color = "steelblue", size = 0.8) +
    geom_abline(intercept = 20, slope = 1, color = "steelblue", size = 0.8) +
    geom_abline(intercept = 10, slope = 1, color = "steelblue", size = 0.8) +
    geom_abline(intercept = 0, slope = 1, color = "steelblue", size = 0.8) +
    geom_abline(intercept = -10, slope = 1, color = "steelblue", size = 0.8) +

    # Add the data points visible in the original chart
    geom_point(data = data.frame(x = c(1988, 1989, 1996),
                                 y = c(85, 75, 62)),
               aes(x = x, y = y),
               color = "darkblue",
               size = 2.5) +

    # Customize the theme and appearance
    theme_minimal() +
    theme(
        panel.grid.major = element_line(color = "grey90", size = 0.5),
        panel.grid.minor = element_line(color = "grey95", size = 0.3),
        axis.line = element_line(color = "black", size = 0.5),
        axis.title = element_text(size = 12),
        axis.text = element_text(size = 10),
        plot.background = element_rect(fill = "white", color = NA),
        panel.background = element_rect(fill = "white", color = NA)
    ) +

    # Add axis labels
    labs(x = "Calendar time", y = "Age") +

    # Set axis breaks and limits
    scale_x_continuous(breaks = seq(1986, 2018, by = 8),
                       limits = c(1986, 2018)) +
    scale_y_continuous(breaks = seq(0, 100, by = 20),
                       limits = c(0, 100))

# Display the plot
print(p)

# Alternative version with more precise control over line positioning
p2 <- ggplot() +
    xlim(1986, 2018) +
    ylim(0, 100) +

    # Create cohort lines more precisely
    geom_segment(aes(x = 1986, y = 50, xend = 2018, yend = 82),
                 color = "steelblue", size = 0.8) +
    geom_segment(aes(x = 1986, y = 40, xend = 2018, yend = 72),
                 color = "steelblue", size = 0.8) +
    geom_segment(aes(x = 1986, y = 30, xend = 2018, yend = 62),
                 color = "steelblue", size = 0.8) +
    geom_segment(aes(x = 1986, y = 20, xend = 2018, yend = 52),
                 color = "steelblue", size = 0.8) +
    geom_segment(aes(x = 1986, y = 10, xend = 2018, yend = 42),
                 color = "steelblue", size = 0.8) +
    geom_segment(aes(x = 1986, y = 0, xend = 2018, yend = 32),
                 color = "steelblue", size = 0.8) +
    geom_segment(aes(x = 1986, y = -10, xend = 2010, yend = 14),
                 color = "steelblue", size = 0.8) +

    # Add data points
    geom_point(data = data.frame(x = c(1988, 1989, 1996),
                                 y = c(85, 75, 62)),
               aes(x = x, y = y),
               color = "darkblue",
               size = 2.5) +

    theme_minimal() +
    theme(
        panel.grid.major = element_line(color = "grey90", size = 0.5),
        panel.grid.minor = element_line(color = "grey95", size = 0.3),
        axis.line = element_line(color = "black", size = 0.5),
        axis.title = element_text(size = 12),
        axis.text = element_text(size = 10)
    ) +

    labs(x = "Calendar time", y = "Age") +
    scale_x_continuous(breaks = seq(1986, 2018, by = 8)) +
    scale_y_continuous(breaks = seq(0, 100, by = 20))

# Display the alternative version
print(p2)


ggsave("/rout/rec-claude-web.pdf", p2, width = 6, height = 4.5)
```

## Gemini 2.5 Flash web

Gemini 2.5 Flash is a more lightweight and faster version of the Gemini 2.5 Pro model. It's designed for tasks that require quick responses and high throughput, while still offering strong reasoning capabilities. [41, 44, 46, 47]

```{r}
#| eval: false
library(tidyverse)
library(ggplot2)

# Data for points
points_data <- tibble(
    calendar_time = c(1987.5, 1988, 1995),
    age = c(88, 77, 63)
)

# Data for lines (cohort lines)
# Each line represents Age = Calendar_time - Birth_Year
# We'll define start and end points for each segment
lines_data <- tribble(
    ~x,    ~y,    ~xend, ~yend,  ~cohort_year,
    1986,  12,    2001,  27,     1974, # Line 1: Age = time - 1974
    1986,  20,    2001,  35,     1966, # Line 2: Age = time - 1966
    1986,  35,    2001,  50,     1951, # Line 3: Age = time - 1951
    1986,  54,    1996,  64,     1932, # Line 4: Age = time - 1932
    2003,  0,     2018,  15,     2003, # Line 5: Age = time - 2003
    2003,  10,    2018,  25,     1993, # Line 6: Age = time - 1993
    2003,  30,    2018,  45,     1973, # Line 7: Age = time - 1973
    2003,  40,    2018,  55,     1963, # Line 8: Age = time - 1963
    2003,  52,    2018,  67,     1951  # Line 9: Age = time - 1951
)


# Create the plot
ggplot() +
    # Add the cohort lines
    geom_segment(data = lines_data, aes(x = x, y = y, xend = xend, yend = yend),
                 color = "blue", size = 0.5) +
    # Add the points
    geom_point(data = points_data, aes(x = calendar_time, y = age),
               color = "blue", size = 3, shape = 16) +
    # Set the scales and labels
    scale_x_continuous(name = "Calendar time",
                       breaks = seq(1986, 2018, by = 4),
                       limits = c(1986, 2018)) +
    scale_y_continuous(name = "Age",
                       breaks = seq(0, 100, by = 20),
                       limits = c(0, 100)) +
    # Add a grid
    theme_minimal() +
    theme(
        panel.grid.major = element_line(color = "grey80", linetype = "solid"),
        panel.grid.minor = element_line(color = "grey90", linetype = "solid"),
        axis.text = element_text(color = "black"),
        axis.title = element_text(color = "black")
    )

ggsave("/rout/rec-gemini-flash.pdf", width = 6, height = 4.5)
```

## DeepSeek Deep Think web

DeepSeek is a large language model developed by DeepSeek AI. It is known for its strong coding and reasoning abilities. The "Deep Think" likely refers to a mode or version of the model that emphasizes more in-depth processing.

```{r}
#| eval: false
library(tidyverse)
library(ggplot2)

# Create a data frame with axis break points
plot_data <- data.frame(
    x = c(1986, 1994, 2002, 2010, 2018),
    y = seq(0, 100, 20)
)

# ERROR Error in data.frame(x = c(1986, 1994, 2002, 2010, 2018), y = seq(0, 100,  :
# arguments imply differing number of rows: 5, 6

# manual fix
plot_data <- data.frame(
    x = c(1986, 1994, 2002, 2010, 2018),
    y = seq(0, 100, 25)
)

# Create the plot
ggplot() +
    # Add horizontal grid lines
    geom_hline(yintercept = seq(0, 100, 20),
               color = "gray90", linewidth = 0.5) +
    # Add vertical grid lines
    geom_vline(xintercept = c(1986, 1994, 2002, 2010, 2018),
               color = "gray90", linewidth = 0.5) +
    # Set axis breaks and labels
    scale_x_continuous(
        breaks = c(1986, 1994, 2002, 2010, 2018),
        limits = c(1986, 2018),
        expand = c(0, 0)
    ) +
    scale_y_continuous(
        breaks = seq(0, 100, 20),
        limits = c(0, 100),
        expand = c(0, 0)
    ) +
    # Add axis titles
    labs(
        title = "Calendar time",
        x = "",
        y = ""
    ) +
    # Apply minimal theme with customizations
    theme_minimal() +
    theme(
        panel.grid = element_blank(),
        plot.title = element_text(hjust = 0.5, size = 14, face = "bold"),
        axis.text = element_text(size = 10, color = "black"),
        axis.ticks = element_line(color = "black"),
        axis.ticks.length = unit(0.2, "cm"),
        panel.border = element_blank(),
        plot.margin = margin(20, 20, 20, 20)
    )

ggsave("/rout/rec-deepseek.pdf", width = 6, height = 4.5)```

## Mistral Small 3.2 24b free via OpenRouter

Mistral Small is a smaller, more efficient model from Mistral AI. It is designed to be a good balance of performance and speed, suitable for a wide range of tasks, and is often used in environments where lower latency is important. [19, 33, 37, 42, 48]

```{r}
#| eval: false
# Load necessary libraries
library(tidyverse)

# Create the data for the illustration
data <- data.frame(
    "Calendar_time" = c(rep(1986, 3), rep(1994, 3)),
    "Age" = c(85, 75, 65, 75, 65, 55)
)

# Also create a data frame for the lines
lines_data <- data.frame(
    "Calendar_time_start" = rep(1986, 10),
    "Age_start" = c(10, 20, 30, 40, 50, 60, 70, 80, 90, 100),
    "Slope" = c(1, 1, 1, 1, 1, 1, 1, 1, 1, 1)
) %>%
    mutate(
        "Age_end" = Age_start + (2016 - Calendar_time_start) * Slope,
        "Calendar_time_end" = 2016
    )

# Plotting using ggplot2
ggplot() +
    # Add background
    theme_bw() +
    theme(
        panel.grid.major = element_line(colour = "gray", size = 0.1),
        panel.grid.minor = element_blank(),
        panel.border = element_rect(colour = "black", fill = NA),
        axis.ticks = element_line(colour = "black"),
        panel.background = element_rect(fill = "white")
    ) +
    # Add the lines
    geom_segment(data = lines_data, aes(x = Calendar_time_start, y = Age_start, xend = Calendar_time_end, yend = Age_end), color = "blue", linewidth = 0.5) +
    # Add the data points
    geom_point(data = data, aes(x = Calendar_time, y = Age), size = 3, color = "blue") +
    # Set axis labels and limits
    labs(x = "Calendar time", y = "Age") +
    scale_x_continuous(expand = c(0, 0), breaks = c(1986, 1994, 2002, 2010, 2018)) +
    scale_y_continuous(expand = c(0, 0), breaks = seq(0, 100, by = 20))

ggsave("/rout/rec-mistral.pdf", width = 6, height = 4.5)
```

## Qwen 3 32B via Open Router

Qwen is a series of large language models from Alibaba Cloud. The 32B model is a large and powerful version, known for its strong multilingual capabilities and performance on a variety of tasks, including a "thinking" mode for more complex reasoning. [11, 12, 14, 23, 32]

```{r}
#| eval: false
library(tidyverse)

# Define the calendar time and age grid
Calendar_time <- 1986:2018  # Extend to match the range shown in the schematic
Age <- 10:100               # Age range from 0 to 100

# Generate all possible diagonal lines (each line represents a cohort)
lines_data <- crossing(Calendar_time, Age) %>%
    mutate(Cohort = {Calendar_time - Age}) |>
    filter(Cohort >= 1900) %>%  # Ensure valid birth year (for clarity)
    ungroup() %>%
    select(Cohort, Calendar_time, Age)

# Define example data points at specific (Calendar_time, Age) locations
points_data <- data.frame(
    Calendar_time = c(1986, 1986, 1994, 1994, 1994),
    Age = c(85, 75, 65, 75, 65)
)

# Create the plot
ggplot() +
    # Diagonal lines representing age over time (cohort paths)
    geom_segment(
        data = lines_data,
        aes(x = Cohort, y = 0, xend = Calendar_time, yend = Age),
        color = "steelblue", size = 0.3, alpha = 0.8
    ) +
    # Highlight example data points
    geom_point(
        data = points_data,
        aes(x = Calendar_time, y = Age),
        size = 3, color = "blue", shape = 1
    ) +
    # Aesthetic adjustments for a schematic look
    theme_minimal() +
    theme(
        axis.title.x = element_text(size = 12, face = "bold"),
        axis.title.y = element_text(size = 12, face = "bold"),
        axis.ticks.length = unit(0.25, "cm"),
        panel.grid.major = element_blank(),  # Remove major grid
        panel.grid.minor = element_blank(),
        panel.border = element_rect(color = "black", fill = NA, size = 1),
        aspect.ratio = 1  # Square aspect ratio for symmetry
    ) +
    # Axis labeling
    labs(
        x = "Calendar Time (Year)",
        y = "Age",
        title = "Age-Period-Cohort Schematic Illustration",
        subtitle = "Diagonal lines represent birth cohorts"
    ) +
    coord_cartesian(
        xlim = c(1986, 2018),  # Set x-axis limits to match the schematic
        ylim = c(0, 100)      # Set y-axis limits to match the schematic
    )

ggsave("/rout/rec-qwen.pdf", width = 6, height = 4.5)
```

## tencent/hunyuan-a13b-instruct:free via OpenRouter

Hunyuan is a large language model from Tencent. As with other major LLMs, it is capable of a wide range of natural language processing tasks.

```{r}
#| eval: false
# Load required libraries
library(tidyverse)

# 1. Synthetic Data (Example)

# Create data for a cohort (e.g., individuals born in 1990)
set.seed(123)  # For reproducibility
time_years <- 1990:2023  # Calendar time (x-axis)
age_years <- time_years - 1990  # Age = Time since birth (y-axis for cohort lines)

# Simulate an observed outcome (e.g., income, health score) that increases with age
outcome_data <- data.frame(
    time = time_years,
    age = age_years,
    outcome = 20 + 1.5 * age_years + rnorm(length(time_years), sd = 2),  # Outcome increases with age
    group = "1990 Cohort"  # Label for the cohort
)

# Add a second cohort (e.g., born in 1995) for comparison
outcome_data <- rbind(
    outcome_data,
    data.frame(
        time = time_years,
        age = time_years - 1995,
        outcome = 25 + 1.2 * age_years + rnorm(length(time_years), sd = 2),  # Slightly different slope
        group = "1995 Cohort"
    )
)

# Add example data points (e.g., survey measurements at specific times)
data_points <- data.frame(
    time = c(1990, 1995, 2000, 2005, 2010, 2015, 2020),
    age = c(0, 5, 10, 15, 20, 25, 30),
    outcome = c(24, 29, 32, 38, 43, 47, 50),  # Observed values
    group = "Observed"
)


# 2. Visualization with ggplot2

ggplot() +
    # Add cohort lines (diagonal, age progression over time)
    geom_line(
        data = outcome_data,
        aes(x = time, y = outcome, color = group, group = group),  # group = group to connect points
        linewidth = 0.7,
        alpha = 0.9
    ) +

    # Add observed data points (markers)
    geom_point(
        data = data_points,
        aes(x = time, y = outcome, color = group, size = group),
        shape = 16,  # Solid circle
        alpha = 0.9
    ) +

    # Add labels and titles
    labs(
        x = "Calendar Time (Year)",
        y = "Outcome (e.g., Annual Income, Health Score)",
        color = "Group/Cohort",
        size = "Data",
        title = "Age Progression of an Outcome Over Time"
    ) +

    # custom color palette
    scale_color_brewer(palette = "Set1") +
    scale_size_manual(values = c("Observed" = 3)) +

    # Adjust axes and theme
    scale_x_continuous(
        breaks = seq(1990, 2023, by = 5),  # Show every 5 years
        limits = c(1985, 2025)  # Extend axes slightly beyond data
    ) +
    scale_y_continuous(
        breaks = seq(20, 55, by = 5),  # Show every 5 years
        limits = c(18, 60)  # Extend y-axis
    ) +
    theme_minimal() +
    theme(
        axis.text.x = element_text(angle = 45, hjust = 1),  # Rotate x-axis labels
        legend.position = "top",  # Place legend on top
        legend.box = "horizontal",  # Align legend items horizontally
        plot.title = element_text(face = "bold"),  # Bold title
        panel.grid.major = element_line(color = "lightgray", linetype = "dashed"),
        panel.grid.minor = element_blank()
    ) +

    # Add a vertical line for a key event (e.g., policy change)
    annotate(
        "line",
        x = 2010, y = Inf, xend = 2010, yend = -Inf,
        color = "red", linetype = "dashed", linewidth = 1
    ) +
    annotate(
        "text",
        x = 2013, y = 50, label = "Policy Change",
        color = "red", angle = 45
    )

ggsave("/rout/rec-tencent.pdf", width = 6, height = 4.5)
```

## tngtech/deepseek-r1t2-chimera:free via OpenRouter

This model from TNG Technology Consulting is a "chimera" model, created by merging multiple DeepSeek models. This "Assembly of Experts" approach aims to combine the strengths of the parent models to create a more capable and efficient resulting model. [20, 25, 26, 27, 31]

```{r}
#| eval: false
library(tidyverse)
library(ggplot2)

# Create data for diagonal lines (each represents a "cohort")
lines <- tibble(
    cohort = seq(1900, 1980, by = 10),
    x_start = 1986,
    y_start = x_start - cohort
) %>%
    mutate(x_end = 2016, y_end = y_start + (x_end - x_start))

# Create sample data points
points <- tibble(
    year = c(1986, 1986, 1994, 1994, 2010, 2010),
    age = c(85, 75, 75, 65, 65, 55)
)

# Create plot
ggplot() +
    # Diagonal cohort lines
    geom_segment(
        data = lines,
        aes(x = x_start, y = y_start, xend = x_end, yend = y_end),
        color = "gray80",
        linewidth = 0.3
    ) +
    # Data points
    geom_point(
        data = points,
        aes(x = year, y = age),
        size = 3,
        shape = 21,
        fill = "#0072B2",
        color = "white",
        stroke = 1
    ) +
    # Ticks and labels
    scale_x_continuous(
        breaks = seq(1986, 2016, 7),
        limits = c(1980, 2020),
        expand = c(0, 0)
    ) +
    scale_y_continuous(
        breaks = seq(50, 90, 10),
        limits = c(50, 90),
        expand = c(0, 0)
    ) +
    # Theme
    theme_minimal() +
    theme(
        panel.grid = element_blank(),
        axis.line = element_line(color = "black"),
        axis.text = element_text(size = 10, color = "black")
    ) +
    labs(x = "Calendar Year", y = "Age")

ggsave("/rout/rec-deepseek-chimera.pdf", width = 6, height = 4.5)
```

## THE WINNER

After several iterations with different models, the following section presents the winning attempts, which successfully captured the essence of the original plot and incorporated the additional context provided in the prompts.

### Gemini 2.5 Pro via AI studio

This section details the successful interaction with Gemini 2.5 Pro through Google's AI Studio.

#### First Attempt

```{r}
#| eval: false
# Load the tidyverse library, which includes ggplot2
library(tidyverse)

# 1. Define data for the diagonal line segments (lifelines)
# Each row represents a line with start (x, y) and end (x_end, y_end) coordinates.
# The coordinates are estimated from the grid in the original image,
# ensuring each line has a slope of 1 (age increases by 1 per calendar year).
lifelines_data <- tibble::tribble(
    ~x_start, ~y_start, ~x_end, ~y_end,
    # Lifelines with points at the end
    1986, 86, 1988, 88,
    1986, 75, 1988, 77,
    1986, 53, 1996, 63,
    # Other lifelines, some are fragmented
    1986, 20, 2002, 36,
    1986, 12, 2002, 28,
    2004, 32, 2018, 46,
    2004, 24, 2018, 38,
    2004,  0, 2018, 14,
    2008,  0, 2018, 10
)

# 2. Define data for the blue points (events)
# Each row represents a single point with (x, y) coordinates.
events_data <- tibble::tribble(
    ~calendar_time, ~age,
    1988, 88,
    1988, 77,
    1996, 63
)

# 3. Create the plot using ggplot2
ggplot() +
    # Add the diagonal line segments
    geom_segment(
        data = lifelines_data,
        aes(x = x_start, y = y_start, xend = x_end, yend = y_end),
        color = "blue",
        linewidth = 0.7
    ) +
    # Add the blue points
    geom_point(
        data = events_data,
        aes(x = calendar_time, y = age),
        color = "blue",
        size = 3.5
    ) +
    # Set the scales for the X and Y axes
    scale_x_continuous(
        name = "Calendar time",
        limits = c(1986, 2018),
        breaks = seq(1986, 2018, by = 8),
        minor_breaks = seq(1986, 2018, by = 2),
        expand = c(0, 0) # Remove padding around the limits
    ) +
    scale_y_continuous(
        name = "Age",
        limits = c(0, 100),
        breaks = seq(0, 100, by = 20),
        expand = c(0, 0) # Remove padding around the limits
    ) +
    # Apply a minimal theme and customize the grid
    theme_bw() +
    theme(
        # Make grid lines lighter to match the original
        panel.grid.major = element_line(color = "grey80"),
        panel.grid.minor = element_line(color = "grey90"),
        # Ensure plot background is white
        plot.background = element_rect(fill = "white", color = NA),
        # Center the y-axis title
        axis.title.y = element_text(vjust = 0.5)
    )

ggsave("/rout/rec-ai-studio.pdf", width = 6, height = 4.5)
```

#### Second Try

```{r}
#| eval: false
# Load the tidyverse library, which includes ggplot2
library(tidyverse)

# 1. Define new data for the zoomed-in view (Age 40-60)
# The data is carefully created so lifelines and events appear within this window.
# The slope of each lifeline is still 1.
lifelines_data_zoomed <- tibble::tribble(
    ~x_start, ~y_start, ~x_end, ~y_end,
    # Lifelines with points at the end
    1992, 38, 2000, 46, # Enters the window and ends
    1998, 42, 2008, 52, # Starts and ends within the window
    2004, 50, 2010, 56, # Starts and ends within the window
    # Other lifeline fragments
    1994, 51, 2002, 59, # A fragment entirely within the window
    1990, 45, 2010, 65, # A longer line that passes through the entire window
    2000, 40, 2015, 55  # Starts at the bottom edge and stays within
)

# 2. Define data for the blue points in the new view
events_data_zoomed <- tibble::tribble(
    ~calendar_time, ~age,
    2000, 46,
    2008, 52,
    2010, 56
)

# 3. Create the plot using ggplot2
ggplot() +
    # Add the diagonal line segments
    geom_segment(
        data = lifelines_data_zoomed,
        aes(x = x_start, y = y_start, xend = x_end, yend = y_end),
        color = "blue",
        linewidth = 0.7
    ) +
    # Add the blue points
    geom_point(
        data = events_data_zoomed,
        aes(x = calendar_time, y = age),
        color = "blue",
        size = 3.5
    ) +
    # Set the scales for the X and Y axes for the zoomed-in view
    scale_x_continuous(
        name = "Calendar time",
        limits = c(1990, 2015),
        breaks = seq(1990, 2015, by = 5),
        minor_breaks = seq(1990, 2015, by = 1)
    ) +
    scale_y_continuous(
        name = "Age",
        limits = c(40, 60),
        breaks = seq(40, 60, by = 5),
        minor_breaks = seq(40, 60, by = 1)
    ) +
    # --- KEY MODIFICATION ---
    # Enforce a 1:1 aspect ratio for a true Lexis diagram visualization.
    # This makes the lifelines appear as perfect 45-degree lines.
    coord_fixed(ratio = 1) +
    # Apply a minimal theme and customize the grid
    theme_bw() +
    theme(
        panel.grid.major = element_line(color = "grey80"),
        panel.grid.minor = element_line(color = "grey90"),
        plot.background = element_rect(fill = "white", color = NA),
        axis.title.y = element_text(vjust = 0.5)
    )

ggsave("/rout/rec-ai-studio-two.pdf", width = 6, height = 4.5)
```

#### Third Try

```{r}
#| eval: false
# Load the tidyverse library, which includes ggplot2
library(tidyverse)

# --- 1. Define Data Based on Observational Scenarios ---

# Let's set the study window
study_start_time <- 1990
study_end_time <- 2015
age_min <- 0
age_max <- 20

# Define lifelines for different scenarios. Each segment is a row.
# A single individual with a gap will have multiple rows.
lifelines_data_conceptual <- tibble::tribble(
    ~person_id, ~x_start, ~y_start, ~x_end, ~y_end, ~scenario,
    # Scenario A: Born during study, ages out of the window
    "A", 1992, 0, 2012, 20, "Born in study, ages out",
    # Scenario B: Present at study start, dies during study
    "B", 1990, 8, 2000, 18, "Present at start, dies",
    # Scenario C: Immigrates into study, survives past study end
    "C", 1995, 12, 2008, 25, "Immigrates, survives", # y_end is >20, so it hits the top boundary
    # Scenario D: Emigration and Re-immigration, then survives past study end
    "D", 1998, 0, 2004, 6, "Emigration/Re-immigration", # Born, then emigrates
    "D", 2008, 10, 2015, 17, "Emigration/Re-immigration", # Re-immigrates, survives to study end
    # Scenario E: Born during study, dies during study
    "E", 2002, 0, 2014, 12, "Born in study, dies",
    # Scenario F: Immigrates and emigrates (lost to follow-up)
    "F", 2005, 5, 2010, 10, "Immigrates and emigrates"
)

# Define deaths data. Points must correspond to the end of a lifeline.
deaths_data_conceptual <- tibble::tribble(
    ~calendar_time, ~age, ~scenario,
    2000, 18, "Present at start, dies", # Person B
    2014, 12, "Born in study, dies"     # Person E
)

# --- 2. Create the Plot using ggplot2 ---

ggplot() +
    # Add the lifeline segments
    geom_segment(
        data = lifelines_data_conceptual,
        aes(x = x_start, y = y_start, xend = x_end, yend = y_end),
        color = "blue",
        linewidth = 0.8
    ) +
    # Add the points for deaths
    geom_point(
        data = deaths_data_conceptual,
        aes(x = calendar_time, y = age),
        color = "blue",
        size = 4,
        shape = 19 # Solid circle
    ) +
    # Set the coordinate system with a fixed 1:1 ratio and define plot limits
    coord_fixed(
        ratio = 1,
        xlim = c(study_start_time, study_end_time),
        ylim = c(age_min, age_max),
        expand = FALSE # Prevent padding around the plot
    ) +
    # Set axis breaks for clarity
    scale_x_continuous(breaks = seq(study_start_time, study_end_time, by = 5)) +
    scale_y_continuous(breaks = seq(age_min, age_max, by = 5)) +
    # Add informative labels, title, and caption
    labs(
        title = "Conceptual Lexis Diagram: Illustrating Lifeline Scenarios",
        subtitle = "Age 0-20, Calendar Time 1990-2015",
        x = "Calendar Time",
        y = "Age",
        caption = "Lifeline starts: Birth (Age=0), Immigration (inside plot), or present at study start (Time=1990).\nLifeline ends: Death (•), Emigration (no point), or exit from study window (at boundary)."
    ) +
    # Apply a clean theme
    theme_bw() +
    theme(
        plot.title = element_text(face = "bold"),
        plot.caption = element_text(hjust = 0, size = 9), # Align caption left
        panel.grid.minor = element_line(color = "grey92"),
        panel.grid.major = element_line(color = "grey85")
    )

ggsave("/rout/rec-gemini-three.pdf", width = 6, height = 4.5)
```

#### Fourth Try

```{r}
#| eval: false
# Load the tidyverse library, which includes ggplot2
library(tidyverse)

# --- 1. Define Updated Data and Parameters ---

# Set the new, wider study window
study_start_time <- 1986
study_end_time <- 2024
age_min <- 0
age_max <- 20

# Define lifelines for the new window.
# We will add a 'color' column directly based on the entry type.
lifelines_data_final <- tibble::tribble(
    ~person_id, ~x_start, ~y_start, ~x_end, ~y_end,
    # --- Born into the population (y_start == 0) ---
    "A", 1990, 0, 2010, 20, # Born, ages out of the window
    "B", 2005, 0, 2018, 13, # Born, dies during study
    "C", 1994, 0, 2002, 8,  # Born, emigrates...
    "C", 2008, 14, 2014, 20, # ...and re-immigrates, then ages out

    # --- Entered study already alive (y_start > 0) ---
    "D", 1986, 12, 2000, 26, # Present at study start, ages out
    "E", 1986, 4, 1998, 16,  # Present at study start, dies
    "F", 2000, 5, 2012, 17,  # Immigrates, survives to end of study
    "G", 2015, 10, 2021, 16  # Immigrates and then emigrates
) %>%
    # Add the color column based on the entry rule
    mutate(
        color = if_else(y_start == 0, "#0e4a4a", "#8aca4a") # Dark Teal for born, Lighter Green otherwise
    )

# Define deaths data (black points). Coordinates must match lifeline ends.
deaths_data_final <- tibble::tribble(
    ~calendar_time, ~age,
    2018, 13, # Person B
    1998, 16  # Person E
)

# --- 2. Create the Final Plot ---

ggplot() +
    # Add the colored lifeline segments
    geom_segment(
        data = lifelines_data_final,
        aes(x = x_start, y = y_start, xend = x_end, yend = y_end, color = color),
        linewidth = 0.9,
        show.legend = FALSE # Explicitly hide the legend
    ) +
    # Add the black points for deaths
    geom_point(
        data = deaths_data_final,
        aes(x = calendar_time, y = age),
        color = "black", # Set color to black
        size = 4,
        shape = 19 # Solid circle
    ) +
    # Use scale_color_identity to tell ggplot to use the color values directly
    scale_color_identity() +
    # Set the coordinate system with a fixed 1:1 ratio and precise limits
    coord_fixed(
        ratio = 1,
        xlim = c(study_start_time, study_end_time),
        ylim = c(age_min, age_max),
        expand = FALSE # No padding
    ) +
    # Set axis breaks for the new, wider time scale
    scale_x_continuous(breaks = seq(1990, 2020, by = 10)) +
    scale_y_continuous(breaks = seq(0, 20, by = 5)) +
    # Add final labels and title
    labs(
        title = "Conceptual Lexis Diagram: Individual Life Histories",
        subtitle = "Age 0-20, Calendar Time 1986-2024",
        x = "Calendar Time",
        y = "Age",
        caption = "Dark Teal: Born into population. Light Green: Entered population while alive (at start or via immigration)."
    ) +
    # Apply a clean theme
    theme_bw() +
    theme(
        plot.title = element_text(face = "bold", size = 14),
        plot.subtitle = element_text(size = 11),
        plot.caption = element_text(hjust = 0, size = 9, face = "italic"),
        panel.grid.minor = element_line(color = "grey92"),
        panel.grid.major = element_line(color = "grey85"),
        panel.border = element_rect(color = "black")
    )

ggsave("/rout/rec-gemini-four.pdf", width = 6, height = 4.5)
```

### FINAL tweaked version

This is the final, manually tweaked version of the code that produces the desired plot, incorporating a custom theme.

```{r}
#| eval: false
# set own theme
devtools::source_gist("653e1040a07364ae82b1bb312501a184")
sysfonts::font_add_google("Atkinson Hyperlegible", family = "ah")

# --- 1. Define Updated Data and Parameters ---

# Set the new, wider study window
study_start_time <- 1986
study_end_time <- 2024
age_min <- 0
age_max <- 20

# Define lifelines for the new window.
# We will add a 'color' column directly based on the entry type.
lifelines_data_final <- tibble::tribble(
    ~person_id, ~x_start, ~y_start, ~x_end, ~y_end,
    # --- Born into the population (y_start == 0) ---
    "A", 1990, 0, 2010, 20, # Born, ages out of the window
    "B", 2005, 0, 2018, 13, # Born, dies during study
    "C", 1994, 0, 2002, 8,  # Born, emigrates...
    "C", 2008, 14, 2014, 20, # ...and re-immigrates, then ages out

    # --- Entered study already alive (y_start > 0) ---
    "D", 1986, 12, 2000, 26, # Present at study start, ages out
    "E", 1986, 4, 1998, 16,  # Present at study start, dies
    "F", 2002, 5, 2014, 17,  # Immigrates and then emigrates
    "G", 2013, 10, 2023, 20  # Immigrates, survives to end of study
) %>%
    # Add the color column based on the entry rule
    mutate(
        color = c("#0e7a7a", "#0e7a7a", "#0e7a7a", "#0e7a7a", "#0e7a7a", "#8aca4a", "#8aca4a", "#8aca4a")
 # Teal for born, Lighter Green otherwise
    )

# Define deaths data (black points). Coordinates must match lifeline ends.
deaths_data_final <- tibble::tribble(
    ~calendar_time, ~age,
    2018, 13, # Person B
    1998, 16  # Person E
)

# --- 2. Create the Final Plot ---

ggplot() +
    # Add the colored lifeline segments
    geom_segment(
        data = lifelines_data_final,
        aes(x = x_start, y = y_start, xend = x_end, yend = y_end, color = color),
        linewidth = 0.9,
        show.legend = FALSE # Explicitly hide the legend
    ) +
    # Add the black points for deaths
    geom_point(
        data = deaths_data_final,
        aes(x = calendar_time, y = age),
        color = "black", # Set color to black
        size = 4,
        shape = 19 # Solid circle
    ) +
    # Use scale_color_identity to tell ggplot to use the color values directly
    scale_color_identity() +
    # Set the coordinate system with a fixed 1:1 ratio and precise limits
    coord_fixed(
        ratio = 1,
        xlim = c(study_start_time, study_end_time),
        ylim = c(age_min, age_max),
        expand = FALSE # No padding
    ) +
    # Set axis breaks for the new, wider time scale
    scale_x_continuous(breaks = seq(1990, 2020, by = 10)) +
    scale_y_continuous(breaks = seq(0, 20, by = 5)) +
    # Add final labels and title
    labs(
        title = "Lifeline scenarios on a Lexis surface",
        subtitle = "Age 0-20, Calendar Time 1986-2024",
        x = "Calendar Time",
        y = "Age",
        caption = "Lifeline starts: Birth (Age=0; teal color), Immigration (inside the plot; light-green color), or present at study start (Time=1986). Lifeline ends: Death (•), Emigration (no point), or exit from study window (at boundary)." |> str_wrap(120)
    )+
    # Apply a clean theme
    theme_ik(base_family = "ah")+
    theme(
        panel.border = element_rect(
            color = "#aafafa", linewidth = 0.5, fill = NA
        ),
        plot.caption = element_text(
            hjust = 0, face = "italic"),
    )

ggsave("/rout/illustrate-lifelines.pdf", width = 8, height = 6)
```
```

***

[in]: https://www.linkedin.com/feed/update/urn:li:activity:7349153537035030530/

[gist]: https://gist.github.com/ikashnitsky/819a7a87ed3844db0cce637f71e1c9f4
[bsky]: https://bsky.app/profile/ikashnitsky.phd/post/3kh5zbmftvw2f


---
draft: true
title: "My (already not just) academic path reflection"
fig-cap-location: margin
reference-location: margin
date: "2025-01-01"
image: teaser.png
categories: [demography, career, academia]
---

<!-- my first non R post in the blog -->

- Very successful academic path
- Lack of own research topic
- Diverse experience: research in several fields of demography and in several countries and research teams, extensive teaching in several contexts, outreach, communication with journalists, R package development, blog and social media
- Tons of early career researchers career mentoring
- Lack of formal scientific mentoring
- Recent experience of giving feedback to Sebastian
- I'm ready to be a scientific mentor now!
---
title: "My (already not just) academic path reflection - LLM jumpstarters"
fig-cap-location: margin
reference-location: margin
date: "2025-01-01"
image: teaser.png
categories: [demography, career, academia]
---

<!-- LLM jumpstarter prompt -->

# PROMPT

Please help me draft a blog post called "My (already not just) academic path reflection". Here is my CV to augment the factual points: https://ikashnitsky.github.io/x/cv/2025-02-cv-ilya-kashnitsky.pdf
Below are the bullet points that should provide the structure for the blog post. I plan to expand each bullet point into a paragraph of a section of the blog post.

- Very successful academic path
- Lack of own research topic
- Diverse experience: research in several fields of demography and in several countries and research teams, extensive teaching in several contexts, outreach, communication with journalists, R package development, blog and social media
- Tons of early career researchers career mentoring
- Lack of formal scientific mentoring
- Recent experience of giving feedback to Sebastian
- I'm ready to be a scientific mentor now!

<!-- chatGPT jumpstarter -->

# ChatGPT

**My (Already Not Just) Academic Path Reflection**

*Embarking on my academic journey, I have been fortunate to experience a trajectory marked by diverse roles and enriching experiences.* From earning a PhD in Demography at the University of Groningen in 2020 to serving as a Senior Researcher at Statistics Denmark, my path has been both rewarding and multifaceted.

*Despite these accomplishments, I have often grappled with the absence of a singular research focus.* This lack of a dedicated niche has sometimes left me questioning the depth of my expertise in any one area.

*However, this breadth has also been a strength.* My engagements span various domains within demography, including spatial analysis and population aging, and have taken me across multiple countries and research teams. Beyond research, I have embraced roles in teaching, outreach, and even R package development, maintaining an active presence through blogging and social media.

*A significant aspect of my journey has been mentoring early-career researchers.* Drawing from my own experiences, I have endeavored to offer guidance and support to those navigating the early stages of their academic careers.

*Interestingly, while I have provided mentorship, I have not had the experience of formal scientific mentoring myself.* This absence has underscored the importance of structured guidance in academia and has shaped my approach to supporting others.

*Recently, I had the opportunity to provide feedback to a colleague, Sebastian.* This experience was enlightening, reinforcing the value of constructive critique and the mutual growth it fosters.

*Reflecting on these experiences, I recognize that I am now prepared to step into the role of a scientific mentor.* I am eager to share my insights, support the development of emerging scholars, and contribute to a collaborative and nurturing academic environment.

<!-- deepseek jumpstarter -->

# DEEP SEEK

## My (Already Not Just) Academic Path Reflection

As I look back on my academic journey, I am struck by how far I’ve come and how much I’ve learned along the way. What began as a straightforward academic path has evolved into something far more diverse and multifaceted. This blog post is a reflection on my experiences, the challenges I’ve faced, and the lessons I’ve learned. It’s also a declaration of readiness to take on a new role: that of a scientific mentor.

### A Very Successful Academic Path

By many measures, my academic career has been a success. I’ve earned a PhD in Demography, published in reputable journals, and presented at international conferences. My work has taken me across Europe and beyond, allowing me to collaborate with leading researchers in the field. I’ve secured funding, won awards, and built a strong professional network. On paper, it looks like a classic academic success story. Yet, as I reflect on this path, I realize that success in academia is not just about ticking boxes or climbing the ladder. It’s about finding meaning in the work you do and making a tangible impact—something I’ve been striving to achieve in my own way.

### The Lack of a Clear Research Topic

One of the challenges I’ve faced is the absence of a single, well-defined research topic that I can call my own. While I’ve worked on a variety of projects—ranging from mortality and aging to migration and spatial demography—I’ve often felt like a jack-of-all-trades rather than a specialist. This lack of focus has sometimes made it difficult to position myself within the academic landscape. However, it has also allowed me to explore diverse areas of demography, gaining a broad perspective that I wouldn’t have had otherwise. I’ve come to see this not as a weakness, but as a strength that enables me to connect ideas across disciplines and contribute to interdisciplinary research.

### Diverse Experiences: Research, Teaching, Outreach, and More

My career has been anything but linear. I’ve conducted research in multiple fields of demography, worked in several countries, and collaborated with diverse research teams. Beyond research, I’ve taught in various contexts, from university courses to workshops, and developed an R package to make demographic methods more accessible. I’ve also engaged in science communication, writing blog posts, interacting with journalists, and maintaining an active presence on social media. These experiences have taught me the value of versatility and adaptability. They’ve also shown me that academia is not just about publishing papers—it’s about sharing knowledge, inspiring others, and contributing to the broader scientific community.

### Mentoring Early Career Researchers

One of the most rewarding aspects of my career has been mentoring early career researchers. Over the years, I’ve guided countless students and young professionals, helping them navigate the complexities of academia, develop their skills, and build their confidence. This role has given me a sense of purpose and fulfillment that goes beyond my own research achievements. It’s also made me realize how much I enjoy supporting others in their academic journeys. While I’ve always been happy to offer advice and encouragement, I’ve recently come to see mentoring as a more formal and integral part of my professional identity.

### The Lack of Formal Scientific Mentoring

Despite my success in mentoring others, I’ve often felt the absence of formal scientific mentoring in my own career. While I’ve had supportive colleagues and collaborators, I’ve never had a dedicated mentor who could provide consistent guidance and feedback. This has sometimes left me feeling isolated and uncertain about my direction. However, it has also pushed me to take ownership of my career and seek out opportunities for growth on my own. In a way, this lack of formal mentoring has made me more self-reliant and resourceful, qualities that I now bring to my own mentoring relationships.

### A Recent Mentoring Experience: Giving Feedback to Sebastian

A recent experience solidified my belief in the importance of mentoring. I had the opportunity to give feedback to Sebastian, a young researcher who was struggling with a project. As we discussed his work, I realized how much I’ve learned over the years—not just about demography, but about the process of doing research, communicating ideas, and overcoming challenges. Sharing this knowledge with Sebastian was incredibly rewarding, and it reminded me of the impact that a good mentor can have. It also made me realize that I’m ready to take on a more formal mentoring role, not just as an occasional advisor, but as a dedicated guide for early career researchers.

### I’m Ready to Be a Scientific Mentor Now!

After years of diverse experiences, both within and beyond academia, I feel ready to embrace the role of a scientific mentor. I want to help others navigate the challenges I’ve faced, share the lessons I’ve learned, and support them in achieving their goals. Mentoring is not just about imparting knowledge—it’s about building relationships, fostering growth, and creating a sense of community. I’m excited to take on this role and contribute to the development of the next generation of researchers. If my journey has taught me anything, it’s that success in academia is not just about individual achievements, but about the connections we make and the impact we have on others.

As I move forward, I look forward to continuing my research, teaching, and outreach efforts, but also to dedicating more time and energy to mentoring. My academic path may have started as a straightforward pursuit of knowledge, but it has evolved into something much richer and more meaningful. I’m grateful for the opportunities I’ve had and excited for what’s to come. Here’s to the next chapter—and to helping others write their own stories.

<!-- Claude jumpstarter -->

# CLAUDE

## My (Already Not Just) Academic Path Reflection

**The Traditional Success Story**

My academic journey has followed what many would consider a textbook path to success. I've published in respected journals, secured competitive funding, and established myself within my field. The metrics that academia values—citations, impact factors, and institutional affiliations—have all aligned favorably with my career trajectory. From the outside looking in, the conventional checkboxes of academic achievement have been ticked off one by one.

**Searching for My North Star**

Despite these external markers of success, I've often found myself wrestling with a fundamental question: what is *my* research topic? While colleagues built careers around specific niches, methodologies, or theoretical frameworks, my path has been less singularly focused. This absence of a clear research identity has been both a source of insecurity and, paradoxically, a catalyst for the diverse path I've forged.

**The Power of Academic Versatility**

What my career may lack in singular focus, it makes up for in breadth and adaptability. My research has spanned multiple subfields of demography, taking me across continents and introducing me to diverse research teams with varying approaches and priorities. I've taught everything from large introductory lectures to specialized graduate seminars, each requiring different pedagogical approaches. Beyond traditional academic outputs, I've developed R packages that serve the wider community, maintained an active blog and social media presence, and cultivated relationships with journalists to communicate research to broader audiences.

**The Accidental Mentor**

Perhaps the most unexpected development in my career has been the gravitational pull toward mentoring early career researchers. Without consciously seeking this role, I've found myself repeatedly providing guidance on everything from statistical methods to work-life balance, from publication strategies to career decisions. These conversations have become not just a peripheral activity but a central and deeply rewarding aspect of my professional identity.

**The Missing Piece**

Despite my comfort in advising others, I've navigated much of my own path without formal scientific mentorship. While administrative mentors have helped me understand promotion processes and institutional politics, I've largely lacked someone to help shape my research agenda, challenge my methodological choices, or push me toward more ambitious questions. This absence has fostered independence but also left me wondering what different paths might have opened with more guided scientific development.

**Learning to Guide by Being Guided**

A recent experience providing feedback to Sebastian revealed something significant: the act of critically engaging with another's research—identifying strengths, questioning assumptions, suggesting alternative approaches—crystallized my own scientific perspective in ways I hadn't previously recognized. The process of articulating what makes for rigorous, innovative, and meaningful research helped me realize that I've developed a coherent scientific viewpoint despite my diverse path.

**The Next Chapter: Embracing the Scientific Mentor Role**

This moment of clarity has brought me to an important realization: I'm ready to step fully into the role of a scientific mentor. The breadth of my experience, combined with the perspective gained from working across different research contexts, has equipped me to guide others not just in navigating academic careers but in shaping research agendas and advancing scientific understanding. What once felt like a liability—my non-linear research path—now reveals itself as a unique asset in helping others find their own way through the complex terrain of academic science.

<!-- ChatGPT CV augmented jumpstarter -->

# ChatGPT CV augmented

## **My (Already Not Just) Academic Path Reflection**

Looking back on my journey, my academic path has been filled with achievements, opportunities, and invaluable experiences that extend far beyond traditional research. What began as a structured pursuit of demography has evolved into a dynamic career spanning research, teaching, outreach, and mentoring. This reflection explores my trajectory—its successes, challenges, and the point I’ve now reached: I am ready to be a scientific mentor.

## **A Successful Academic Path**

My academic career has been marked by significant milestones. After completing a BSc in Geography at Moscow State University and an MSc in Demography at the Higher School of Economics in Moscow, I earned a PhD in Demography from the University of Groningen and the Netherlands Interdisciplinary Demographic Institute in 2020. My dissertation, *Changing Regional Inequalities in Ageing Across Europe*, examined demographic disparities across the continent.

Following my PhD, I navigated through various research positions, from Research Assistant to Assistant Professor at the Interdisciplinary Centre on Population Dynamics, University of Southern Denmark. Now, as a Senior Researcher (Specialkonsulent) at Statistics Denmark, I continue to contribute to the field, specializing in demographic research and data analysis. Additionally, I am an Associate Member of the Leverhulme Centre for Demographic Science at the University of Oxford and a board member of the Danish Demographic Association.

Beyond research, my work has received recognition, including the *EAPS Outreach Award* in 2018 and selection as a *Leading Population Expert* by Population Europe in 2022.

## **The Challenge: No Singular Research Topic**

Despite my accomplishments, one aspect of my academic career has always left me unsettled: I have never had a single, well-defined research focus. My interests span various areas within demography, including spatial analysis, population aging, internal migration, and COVID-19’s demographic impact.

While many researchers develop a signature topic early in their careers, I have instead followed a broad and interdisciplinary path. I have contributed to high-impact publications in *Nature Human Behaviour*, *BMJ Open*, and *Population Studies*, collaborated on projects in diverse domains, and even developed R packages like *sjrdata* and *tricolore*. While this diversity has enriched my experience, it has also made me feel like an academic generalist rather than a specialist.

## **A Multifaceted Career: Research, Teaching, and Outreach**

Although my research spans different topics, my career has been anything but narrow. I have worked in multiple countries (Russia, the Netherlands, Denmark, Germany, and the UK) and collaborated with international research teams. Teaching has been another major pillar of my work, with courses and workshops on data visualization, R programming, and demographic methods at institutions such as the University of Oxford, the Max Planck Institute for Demographic Research, and Universitat Autònoma de Barcelona.

Outreach has also been a passion of mine. I have actively communicated demographic insights to wider audiences, engaging with journalists and contributing to discussions on platforms like *Our World in Data*, *The Guardian*, and *The Economist*. My blog and social media presence have allowed me to share research, tutorials, and reflections on academia.

## **Mentoring Early-Career Researchers**

Throughout my career, I have been deeply involved in mentoring early-career researchers. I have provided career advice, guidance on academic writing, and insights into navigating academia’s challenges. Having gone through the ups and downs of research, funding, and publishing, I find it incredibly fulfilling to help others avoid pitfalls and develop their careers strategically.

## **The Absence of Formal Mentorship**

Interestingly, while I have mentored others, I have never had a formal scientific mentor myself. My academic journey has been largely self-directed, shaped by interactions with peers and collaborators rather than structured guidance. This has given me independence but also reinforced the importance of mentorship—something I lacked and now want to provide to others.

## **A Recent Mentorship Experience**

A recent experience that reinforced this realization was providing feedback to Sebastian Hanika, a PhD candidate at Lund University. Reviewing his work and discussing his research made me recognize how much I enjoy guiding and shaping the ideas of emerging scholars. It was a moment of clarity: I am ready to take on a formal mentorship role.

## **I Am Ready to Be a Scientific Mentor**

Reflecting on my journey, I see that my broad expertise, international experience, and commitment to outreach and mentoring have prepared me for this next step. I am eager to support young researchers, help them navigate academia, and create an environment where they can thrive.

Academia can be daunting, but good mentorship makes a difference. Now, I want to be the mentor I never had.

<!-- deepseek jumpstarter -->

# Deep Seek CV augmented

Certainly! Below is the augmented version of your blog post, incorporating factual details from your CV to enrich the narrative:

## My (Already Not Just) Academic Path Reflection

As I look back on my academic journey, I am struck by how far I’ve come and how much I’ve learned along the way. What began as a straightforward academic path has evolved into something far more diverse and multifaceted. This blog post is a reflection on my experiences, the challenges I’ve faced, and the lessons I’ve learned. It’s also a declaration of readiness to take on a new role: that of a scientific mentor.

### A Very Successful Academic Path

By many measures, my academic career has been a success. I’ve earned a **PhD in Demography** from the **University of Groningen**, where I defended my dissertation on *Changing regional inequalities in ageing across Europe* in 2020. My work has been published in reputable journals such as *Nature Human Behaviour*, *Population Studies*, and *The Lancet*, and I’ve presented at international conferences across Europe and beyond. I’ve held positions at prestigious institutions, including my current role as a **Senior Researcher at Statistics Denmark** and my **Associate Membership at the Leverhulme Centre for Demographic Science, University of Oxford**. I’ve also been recognized with awards such as the **EAPS Outreach Award** and the **Best Poster Award** from the Netherlands Demographic Society. On paper, it looks like a classic academic success story. Yet, as I reflect on this path, I realize that success in academia is not just about ticking boxes or climbing the ladder. It’s about finding meaning in the work you do and making a tangible impact—something I’ve been striving to achieve in my own way.

### The Lack of a Clear Research Topic

One of the challenges I’ve faced is the absence of a single, well-defined research topic that I can call my own. While I’ve worked on a variety of projects—ranging from **mortality and aging** to **migration** and **spatial demography**—I’ve often felt like a jack-of-all-trades rather than a specialist. For example, my research has explored topics as diverse as **non-survival to pension age in Denmark and Sweden**, **COVID-19’s impact on aging European regions**, and **internal youth migration in Russia**. This lack of focus has sometimes made it difficult to position myself within the academic landscape. However, it has also allowed me to explore diverse areas of demography, gaining a broad perspective that I wouldn’t have had otherwise. I’ve come to see this not as a weakness, but as a strength that enables me to connect ideas across disciplines and contribute to interdisciplinary research.

### Diverse Experiences: Research, Teaching, Outreach, and More

My career has been anything but linear. I’ve conducted research in multiple fields of demography, worked in several countries, and collaborated with diverse research teams. Beyond research, I’ve taught in various contexts, from university courses to workshops, and developed an **R package** (*DemoTools*) to make demographic methods more accessible. I’ve also engaged in science communication, writing blog posts, interacting with journalists, and maintaining an active presence on social media. My teaching experience includes courses like *Data Visualization – the Art/Skill Cocktail* at the **University of Oxford** and workshops on *Mapping in R* at the **University of Groningen**. These experiences have taught me the value of versatility and adaptability. They’ve also shown me that academia is not just about publishing papers—it’s about sharing knowledge, inspiring others, and contributing to the broader scientific community.

### Mentoring Early Career Researchers

One of the most rewarding aspects of my career has been mentoring early career researchers. Over the years, I’ve guided countless students and young professionals, helping them navigate the complexities of academia, develop their skills, and build their confidence. For example, I’ve served as an **external evaluator for PhD candidates** like **Sebastian Hanika** at **Lund University**, and I’ve reviewed master’s theses at the **National Research University Higher School of Economics**. This role has given me a sense of purpose and fulfillment that goes beyond my own research achievements. It’s also made me realize how much I enjoy supporting others in their academic journeys. While I’ve always been happy to offer advice and encouragement, I’ve recently come to see mentoring as a more formal and integral part of my professional identity.

### The Lack of Formal Scientific Mentoring

Despite my success in mentoring others, I’ve often felt the absence of formal scientific mentoring in my own career. While I’ve had supportive colleagues and collaborators, I’ve never had a dedicated mentor who could provide consistent guidance and feedback. This has sometimes left me feeling isolated and uncertain about my direction. However, it has also pushed me to take ownership of my career and seek out opportunities for growth on my own. In a way, this lack of formal mentoring has made me more self-reliant and resourceful, qualities that I now bring to my own mentoring relationships.

### A Recent Mentoring Experience: Giving Feedback to Sebastian

A recent experience solidified my belief in the importance of mentoring. I had the opportunity to give feedback to **Sebastian**, a young researcher who was struggling with a project. As we discussed his work, I realized how much I’ve learned over the years—not just about demography, but about the process of doing research, communicating ideas, and overcoming challenges. Sharing this knowledge with Sebastian was incredibly rewarding, and it reminded me of the impact that a good mentor can have. It also made me realize that I’m ready to take on a more formal mentoring role, not just as an occasional advisor, but as a dedicated guide for early career researchers.

### I’m Ready to Be a Scientific Mentor Now!

After years of diverse experiences, both within and beyond academia, I feel ready to embrace the role of a scientific mentor. I want to help others navigate the challenges I’ve faced, share the lessons I’ve learned, and support them in achieving their goals. Mentoring is not just about imparting knowledge—it’s about building relationships, fostering growth, and creating a sense of community. I’m excited to take on this role and contribute to the development of the next generation of researchers. If my journey has taught me anything, it’s that success in academia is not just about individual achievements, but about the connections we make and the impact we have on others.

As I move forward, I look forward to continuing my research, teaching, and outreach efforts, but also to dedicating more time and energy to mentoring. My academic path may have started as a straightforward pursuit of knowledge, but it has evolved into something much richer and more meaningful. I’m grateful for the opportunities I’ve had and excited for what’s to come. Here’s to the next chapter—and to helping others write their own stories.

This version of the blog post integrates specific details from your CV, such as your publications, teaching experiences, and mentoring activities, to provide a more comprehensive and personalized reflection on your academic journey.

<!-- Claude CV augmented jumpstarter -->

# Claude CV augmented

## The Traditional Success Story

My academic journey has followed what many would consider a textbook path to success. From my early beginnings at Moscow State University to earning my PhD at the University of Groningen, I've published in respected journals like *The Lancet*, *PNAS*, and *Population Studies*. My research on regional inequalities in aging across Europe has secured recognition, including the EAPS Outreach Award and an AURORA-II PhD Scholarship. The metrics that academia values—citations, impact factors, and institutional affiliations—have aligned favorably with my career trajectory, leading to my current position as Senior Researcher at Statistics Denmark and Associate Member at the Leverhulme Centre for Demographic Science at Oxford.

## Searching for My North Star

Despite these external markers of success, I've often found myself wrestling with a fundamental question: what is *my* research topic? While colleagues built careers around specific niches, my publications span diverse areas—from COVID-19 impacts on unequally aging regions to sex gaps in life expectancy, from internal youth migration in Russia to regional convergence in population aging across Europe. This absence of a clear research identity has been both a source of insecurity and, paradoxically, a catalyst for the diverse path I've forged.

## The Power of Academic Versatility

What my career may lack in singular focus, it makes up for in breadth and adaptability. My research has spanned multiple subfields of demography, taking me from Moscow to Groningen, from Odense to Copenhagen, and introducing me to diverse research teams with varying approaches. I've taught everything from specialized workshops on data visualization at the Barcelona Summer School of Demography to guest lectures on migration and R programming at various institutions. Beyond traditional academic outputs, I've developed R packages like DemoTools and tricolore that serve the wider community, maintained an active blog and social media presence (as evidenced by my BSKY and GitHub profiles), and cultivated relationships with outlets like The Atlantic, The Economist, and The Guardian to communicate research to broader audiences.

## The Accidental Mentor

Perhaps the most unexpected development in my career has been the gravitational pull toward mentoring early career researchers. Without consciously seeking this role, I've found myself repeatedly providing guidance through my teaching activities across institutions like the Max Planck Institute, Oxford, and Barcelona. These teaching experiences in data visualization, mapping in R, and demographic methods have become not just peripheral activities but central and deeply rewarding aspects of my professional identity, reflected in the community service section of my CV that shows my commitment to nurturing the field.

## The Missing Piece

Despite my comfort in advising others, I've navigated much of my own path without formal scientific mentorship. While I've had excellent PhD advisors in Leo van Wissen and Joop de Beer, and have collaborated with established scholars like James Vaupel (whom I helped commemorate through the memorial website), I've largely lacked someone to consistently help shape my research agenda across the various institutions where I've worked. This absence has fostered independence but also left me wondering what different paths might have opened with more guided scientific development throughout my career transitions from Russia to the Netherlands to Denmark.

## Learning to Guide by Being Guided

A recent experience providing feedback to Sebastian Hanika as an external PhD evaluator at Lund University revealed something significant: the act of critically engaging with another's research—identifying strengths, questioning assumptions, suggesting alternative approaches—crystallized my own scientific perspective in ways I hadn't previously recognized. This formal evaluation role, combined with my extensive peer review experience for journals like *Population Studies*, *Demography*, and *The BMJ*, has helped me develop a coherent scientific viewpoint despite my diverse path.

## The Next Chapter: Embracing the Scientific Mentor Role

This moment of clarity has brought me to an important realization: I'm ready to step fully into the role of a scientific mentor. The breadth of my experience across multiple countries and research contexts, combined with my board membership in the Danish Demographic Association and my involvement with organizations like IUSSP and EAPS, has equipped me to guide others not just in navigating academic careers but in shaping research agendas and advancing scientific understanding. What once felt like a liability—my non-linear research path spanning urbanization, mortality, and migration—now reveals itself as a unique asset in helping others find their own way through the complex terrain of academic science.
---
title: "Sidekick projects may be worthy distractions for an early academic"
fig-cap-location: margin
reference-location: margin
date: "2025-07-22"
image: teaser.png
categories: [academia, career, demography]
---

In the last few days, I've been thinking a lot about [Claus Wilke’s blog post][cw] on the essential need of writing and publishing a lot of papers for academic researchers. This is such a beautifully formulated argumentation for the position that may easily feel like a losing one in this debate. Quite often we hear calls claiming that researchers should publish just one paper per year. I always felt that this take is akin to the most radical populist statements – a simple solution proposed to fix a difficult issue.Such propositions often appeal to the wider audience on the first glance but turn out completely meaningless in all the practicalities and even harmful if being implemented literally.

Thinking about this blog post, I drew parallels to my own experience of making my first baby steps in academia. It so happened that my first proper scientific paper that was published in a good journal [@kashnitsky2016c] was a sidekick analysis at the beginning of my PhD trajectory. It evolved from an assignment during the R spatial course of Sebastian Klussener at [IDEM MPIDR](https://www.demogr.mpg.de/en/career_6122/international_advanced_studies_in_demography_6682/). I got so excited about the analysis and about the superpowers that R opened to me that a simple course assignment grew into the first, very raw, paper draft. Since it was not directly related to the topic of my then starting PhD project, I didn't sit too long on the first draft. So I just boldly submitted it to a top journal in the adjacent research field where the topic belonged. Now I realize how much of a long shot this was and how exceptionally lucky I was that the editor found this analysis interesting enough to give me a major-major-major revision. And then I realized that I was not in the position to improve the paper to fit the high bar of the journal. Then I invited [Maria Gunko][mg] to join me in this revision and together we worked hard on morphing my curious analysis into a proper paper, grounding it in the literature and building the stage for the analysis. After months of intense collaboration and two more rounds of revision, the paper got published. And to this day I feel grateful about the whole experience and I even feel satisfied with the paper.

I think that the most useful part of this experience was dealing with the editorial process in a constructed environment that was decoupled from the emotional attachment and the high stakes of my own PhD project. So when I hit the unavoidable hurdles of navigating academic publishing with my PhD papers I was much better prepared. It may actually be a worthy advice to all starting PhD students – craft a quick paper out of your master thesis or any other sidekick project and try to publish it: submit it to a proper academic journal, maybe get a desk-rejection and re-submit to another journal, receive the first comments from the reviewers… Just get the first experience of navigating the whole, often frustrating, process. We hear a lot how difficult it may be to accept rejections that are coming so often in academia. But hearing this multiple times is totally not the same as opening the damn email that you were nervously awaiting for a couple of months and reading in between the lengthy formal words about your paper the key phrase starting from "unfortunately". Yet, when this is connected to a sidekick project it's so much easier to process emotionally and mentally.

I realize that advice based on my success story from early PhD days may look a lot [survivorship bias](https://xkcd.com/1827/) driven. To balance this out a bit let me bring several less shining examples from my early career steps. My very first academic paper in English, based on my master thesis, happened to be published in a predatory journal 🙃 It was the first draft of a paper that I wrote in English. And I submitted it to a conference in Rome. Alas, this happened to be a conference organized by predators. The most surprising thing was that it actually was a physical conference in Rome, and I even attended it with great pleasure, wasting just 1.5 hours of the session with my talk. The rest of the four days in Rome were a beautiful debrief of my honeymoon trip that summer. But the biggest unpleasant surprise was when the conference organizers published all the conference papers in their predatory journal. This way my extra raw, never peer-reviewed, not even proofread properly draft suddenly became my first official doi assigned and Scopus indexed paper [@kashnitsky2013mjss]. I’m not too concerned, since the paper itself is just very raw but not too embarrassing. Yet I’m very happy that this unfortunate publication in a predatory journal, that was banned from Scopus a couple of years later, did not harm my just  starting academic path. Later on I developed this paper a lot, then submitted it to several reputable journals, got several desk rejections and one rejection after a thorough peer-review. Only after a journey of rejections and a thorough rework this paper finally landed in a proper journal [@kashnitsky2020g], five years after the initial accidental publication in the predatory journal, and the volume/issue printed version of the paper came only in 2020, 7 years later.

Linking back to the populist idea of limiting how many papers researchers may submit, I think that writing freely and crafting sidekick papers is exceptionally important for academic development, especially during the baby steps in the profession. Trying to regulate this intimate process can cause a lot of harm. Generally, learning to share publicly the outputs of your own efforts and then to deal with the feedback is essential for becoming a good scientist. Here I would just link to the evergreen talk of David Robinson called [The unreasonable effectiveness of public work][drob].

::: {.callout-tip}
# Have a look at the [gallery of Google's AI Studio images](https://github.com/ikashnitsky/ikashnitsky.github.io/blob/main/2025/sidekick-papers/gallery.md) that I generated in order to create some visual for the teaser of this blog post.
:::

***

[cw]: https://clauswilke.substack.com/p/from-the-archives-no-one-reads-your
[mg]: https://www.linkedin.com/in/maria-gunko-84198625a/
[drob]: https://posit.co/resources/videos/the-unreasonable-effectiveness-of-public-work
---
title: "Can deep football knowledge guarantee betting success? Systematic evaluation of football pundits' La Liga predictions"
fig-cap-location: margin
reference-location: margin
date: "2026-03-21"
image: teaser.png
categories: [r, football, dataviz, llm]
---

As football fans, we constantly hear pundits making bold predictions. But how often do they actually hit the targets? Let's check the track record of three popular Russian football pundits.

[Vadim Lukomskiy](https://t.me/lukomski), [Denis Alkhazov](https://t.me/alhasbro), and [Vladimir Grabchak](https://t.me/barcafamilyyy) air a fantastic [La Liga Preview podcast on YouTube][yt]. Each week they discuss the upcoming matchday and offer their bets, one per game. Next week, they start by reviewing the outcomes. For a long while I was wondering how do the weekly predictions add up in the long run --I wanted to see whether a thorough knowledge of the specific league and a deep involvement can allow the pundits to stay in the profitable zone while betting on all the games of the season.

So I decided to check it. In the current 2025-2026 season we have data up to matchday 28, and matchdays 6 and 18 were played midweek, so the guys happened to skip predictions. In total, 26 rounds, 10 games in each -- quite some data to play with.

The data collection was a curious workflow in itself. I took screenshots of the predictions directly from the YouTube videos and used LLMs (Gemini and Claude) to parse the images and compile them into a clean dataset. Yet, there was a challenge along the way. LLMs struggled with team names that were represented with small logo images. Here's how a typical screenshot looked like:

![][screenshot]

Sometimes they managed to pick up the names of the playing teams from the text description of the bet. But in other cases they had to leave placeholder marks "Team A" / "Team B". To fill the gaps, I cross-referenced it with a [dump of all played matches][fbref] in La Liga this season. This helped to figure out all the team names where the LLMs failed on the first run [^1].

[^1]: On the test run, Gemini gave me a perfect decoding of one screenshot. I thought that it used computer vision to read the team names from the logos, but it turned out that it just used the text transcript of the YouTube video that I linked in the initial prompt.

Anyways, with less effort than it would have taken to manually transcribe the predictions, I ended up with a tidy dataset of 259 predictions, including the predicted winner, the odds, and the actual match outcomes.

Naturally, I fired up R to answer two burning questions: was any of our three experts profitable in the long run, and whether they were systematically better at predicting the outcomes of some specific teams that they may know and understand the best?

## The Overall Scoreboard

First, let’s look at the overall performance. Evaluating a pundit isn't just about how many times they win; it's about the value of the odds they successfully predict.

![](summary.png)

I was amused to see the results. Two of the three pundits managed to win 44% of their bets with the cumulative effect bringing them to almost  a perfectly neutral balance as a result. So, even an extremely deep domain knowledge and a high involvement in the league doesn't translate into a profitable betting strategy. No real surprise here, but just another reminder that one does not fool the system that is designed to fool him.

## Just bet on XXX -- you cannot miss

Well, maybe our experts know some of the teams so well that they can predict the outcomes of these teams much better? You know, football is highly contextual. A pundit might struggle to predict some team's volatile form but perfectly read another's tactical setups. I wanted to see if the pundits have "specialty" teams.

To do this, I reshaped the data so that every match counted for both the Home and Away teams involved, calculating the success rate for each pundit-team combination.

![][img]

Wow! Some fascinating patterns emerge:

- **Lukomskiy's Yellow Submarine:** Vadim has an incredible read on **Villarreal**. Out of 21 predictions involving them, he got 14 right—a massive 66.7% success rate over a large sample size. He also consistently reads Athletic Bilbao and Real Sociedad well.
- **Alkhazov's Levante:** Denis has certain success (luck?) with **Levante**, accurately predicting 14 out of 26 matches (53.8%). Interestingly, while he struggles overall compared to Vadim, his read on mid-to-lower table clashes seems to be his bread and butter.
- **Grabchak's Flawless Osasuna:** Though his sample size is smaller, Vladimir went a perfect **7 for 7** on matches involving Osasuna.
- All three pundits have consistently failed with the big trio **Real Madrid**, **Barcelona**, and **Atletico Madrid**, which is quite surprising given the perpetual attention to these clubs and their often consistent performance.

**Do pundits really know something specific about some teams, or is it just a matter of luck?**

::: {.callout-tip}
# Code and data to reproduce this analysis are available on [GitHub][gh].
:::

***

[gh]: https://github.com/ikashnitsky/laliga-preview
[img]: https://github.com/ikashnitsky/laliga-preview/raw/main/out/by-team.png
[yt]: https://youtube.com/playlist?list=PLZgJT1M3SJ9XVvZFlcJeCKUMzrMYCrCwc&si=RVs-ryd-bKHXuOBB
[screenshot]: https://github.com/ikashnitsky/laliga-preview/blob/main/dat/screenshots/Screenshot_20260319-163345.png?raw=true
[fbref]: https://fbref.com/en/comps/12/schedule/La-Liga-Scores-and-Fixtures
---
title: "Page not found!"
title-block-banner: "#021515"
comments: false
toc: false
---

The page or item that you’re looking for isn’t here!

Try using the {{< fa magnifying-glass >}} **search button** at the top of the page or <a href="https://www.google.com/search?q=site%3Aikashnitsky.github.io" target="_blank">searching on Google.</a>
---
title: "Academic CV"
comments: false
toc: false
toc-location: right
title-block-banner: "#002F2F"
code-tools: false
published-title: CV last updated
date: 2026-03-25
engine: knitr
---

<!-- <button class="btn btn-lg btn-secondary" type="button"> -->
<!-- [{{< fa file-lines >}} Download current CV](https://ikashnitsky.github.io/x/cv/2026-03-cv-ilya-kashnitsky.pdf) -->
<!-- </button> -->

```{css echo=FALSE}
.embed-container {
    position: relative;
    padding-bottom: 92%;
    height: 0;
    overflow: hidden;
    max-width: 100%;
}

.embed-container iframe,
.embed-container object,
.embed-container embed {
    position: absolute;
    top: 0;
    left: 0;
    width: 100%;
    height: 100%;
}
```

```{=html}
<p class="text-center">
  <a class="btn btn-primary btn-lg cv-download" href="https://ikashnitsky.github.io/x/cv/2026-03-cv-ilya-kashnitsky.pdf" target="_blank">
    <i class="fa-solid fa-file-arrow-down"></i>&ensp;Download current CV
  </a>
</p>

<div class="embed-container">
  <iframe src="https://ikashnitsky.github.io/x/cv/2026-03-cv-ilya-kashnitsky.pdf" style="border:5px solid #dfff00"></iframe>
</div>
```
---
title: "."
comments: false
title-block-banner: img/dd-banner.png
code-tools: false
toc: false
toc-location: right
---

***

*Demographic Digest*  is a regular column at [Demoscope Weekly][1] which publishes (in Russian) brief summaries of fresh demographic papers from the best academic journals.

***

*Демографический Дайджест* – регулярная рубрика журнала [Демоскоп Weekly][1], в которой приводятся краткие обзоры демографических статей, публикуемых в ведущих зарубежных журналах.

***

### [[PROJECT WEBSITE]][2]

***

### [[ARCHIVE]][1]

[1]: http://demoscope.ru/weekly/arc/arcdigest.php
[2]: https://ikashnitsky.github.io/dem-digest

***

<script type="text/javascript" src="https://cdnjs.buymeacoffee.com/1.0.0/button.prod.min.js" data-name="bmc-button" data-slug="ikashnitsky" data-color="#269292" data-emoji="" data-font="Poppins" data-text="Buy me a coffee" data-outline-color="#ffffff" data-font-color="#ffffff" data-coffee-color="#FFDD00" ></script>
---
title: "demographeR's notes"
listing:
  - id: posts_2026
    contents: "2026/**/index.qmd"
    sort: "date desc"
    template: html/listing-grid.ejs
  - id: posts_2025
    contents: "2025/**/index.qmd"
    sort: "date desc"
    template: html/listing-grid.ejs
  - id: posts_2024
    contents: "2024/**/index.qmd"
    sort: "date desc"
    template: html/listing-grid.ejs
  - id: posts_2023
    contents: "2023/**/index.qmd"
    sort: "date desc"
    template: html/listing-grid.ejs
    categories: true
    feed:
      categories: r
  - id: posts_2022
    contents: "2022/**/index.qmd"
    sort: "date desc"
    template: html/listing-grid.ejs
  - id: posts_2021
    contents: "2021/**/index.qmd"
    sort: "date desc"
    template: html/listing-grid.ejs
  - id: posts_2020
    contents: "2020/**/index.qmd"
    sort: "date desc"
    template: html/listing-grid.ejs
  - id: posts_2019
    contents:
      - "2019/**/index.qmd"
      - "2019/**/index.md"
    sort: "date desc"
    template: html/listing-grid.ejs
  - id: posts_2018
    contents:
      - "2018/**/index.qmd"
      - "2018/**/index.md"
    sort: "date desc"
    template: html/listing-grid.ejs
  - id: posts_2017
    contents:
      - "2017/**/index.qmd"
      - "2017/**/index.md"
    sort: "date desc"
    template: html/listing-grid.ejs
    # type: grid
# image-placeholder: img/card-tw.png
page-layout: full
toc-title: Year
toc-location: right
date-format: "MMMM D, YYYY"
code-tools: false
comments: false
margin-header: |
    <button class="btn btn-lg btn-secondary" type="button">
    <a href="/subscribe.html"> {{< fa pen-to-square >}} <small>Subscribe</small></a>
    </button>
---

## 2026

::: {#posts_2026}
:::

## 2025

::: {#posts_2025}
:::

## 2024

::: {#posts_2024}
:::

## 2023

::: {#posts_2023}
:::

## 2022

::: {#posts_2022}
:::

## 2021

::: {#posts_2021}
:::

## 2020

::: {#posts_2020}
:::

## 2019

::: {#posts_2019}
:::

## 2018

::: {#posts_2018}
:::

## 2017

::: {#posts_2017}
:::

***

<center><button class="btn btn-lg btn-secondary" type="button"><a href="/subscribe.html"> {{< fa pen-to-square >}} Subscribe for email updates</a></button></center>
---
title: "."
image: img/ik.png
title-block-banner: img/abs-banner-me.png
code-tools: false
comments: false
toc: false
toc-location: right
about:
  template: jolla
  links:
    - icon: github
      text: Github
      href: https://github.com/ikashnitsky
    - icon: linkedin
      text: LinkedIn
      href: https://www.linkedin.com/in/ikashnitsky
    - icon: mastodon
      text: Mastodon
      href: https://fosstodon.org/@ikashnitsky
    - text: "{{< fa check-circle-fill >}} BlueSky"
      href: https://bsky.app/profile/ikashnitsky.phd
---

<button type="button" class="btn btn-warning">
<a href="https://ikashnitsky.github.io/x/cv/2024-06-cv-ilya-kashnitsky.pdf" style="color:#fff;"> {{< fa file-lines >}} CV</a>
</button>

<button type="button" class="btn btn-success">
<a href="https://orcid.org/0000-0003-1835-8687" style="color:#fff;"> {{< fa brands orcid >}} ORCID</a>
</button>

<button type="button" class="btn btn-info">
<a href="https://scholar.google.com/citations?user=tSQW1XYAAAAJ&hl=en" style="color:#fff;"> {{< ai google-scholar >}} Google Scholar</a>
</button>

# Welcome to my website!

I am a demographer.

This site gives an overview of my academic activities.

I am a Senior Researcher at [Statistics Denmark][dst] and an Associate Member at  [Leverhulme Centre for Demographic Science][lcds], University of Oxford .

Until recently I was an Assistant Professor at the [Interdisciplinary Centre on Population Dynamics][cpop], University of Southern Denmark, Odense, Denmark.

I did [my PhD project][phd] at the [University of Groningen][rug] and [Netherlands Interdisciplinary Demographic Institute][nidi] with the scientific supervision by [Leo van Wissen][lvw] and [Joop de Beer][jdb]. The focus of [the thesis][thesis] is on regional variations in aging across Europe, the demographic processes shaping them, their dynamics and possible implications for economies and societies. My interests include most topics relating to demography, population geography, spatial analysis and data visualization.

I am an avid [R](https://cran.r-project.org) user with deep interest in GIS, spatial analysis, and efficient data visualization, which I [teach often and with great pleasure](/tea). I am happy that [my blog](/) is included in the brilliant [R-bloggers](https://www.r-bloggers.com) project.

My main interest is demography. For three years, 2015--2017, I was systematically following the state-of-the-art research in the field and writing brief summaries (in Russian) of selected demographic papers in my [Demographic Digest](/dd).

***

## BIO

I was born in Israel, grew up in Moscow, during my PhD years lived in The Hague, and now live in Odense. Married and have two daughters. I got a bachelors in geography from Moscow State University in 2012, masters in demography from the National Research University Higher School of Economics (Moscow) in 2014, and PhD from University of Groningen in 2020.

```{r, echo=FALSE}
#| column: screen-inset
knitr::include_graphics("img/our-photo-x4.jpg")
```

***
Feel free to contact me via email
[ilya.kashnitsky at gmail dot com][mailto]

Ilya

<button class="btn btn-lg btn-secondary" type="button">
<a href="/subscribe.html"> {{< fa pen-to-square >}} Subscribe for email updates</a>
</button>

***

<script type="text/javascript" src="https://cdnjs.buymeacoffee.com/1.0.0/button.prod.min.js" data-name="bmc-button" data-slug="ikashnitsky" data-color="#269292" data-emoji="" data-font="Poppins" data-text="Buy me a coffee" data-outline-color="#ffffff" data-font-color="#ffffff" data-coffee-color="#FFDD00" ></script>

[rug]: http://www.rug.nl
[nidi]: http://nidi.nl/en
[phd]: https://osf.io/d4hjx/
[lvw]: https://nidi.nl/en/employees/leo-van-wissen/
[jdb]: https://nidi.nl/en/employees/joop-de-beer/
[6]: https://sites.google.com/site/ikashnitsky/home
[thesis]: https://doi.org/10.33612/diss.134195227
[indexation]: https://www.sdu.dk/en/forskning/forskningsenheder/samf/cpop/research/method_development_for_ageing_research/pension_age
[excess]: https://www.sdu.dk/en/forskning/forskningsenheder/samf/cpop/excessdeath
[orcid]: https://orcid.org/0000-0003-1835-8687
[gs]: https://scholar.google.com/citations?user=tSQW1XYAAAAJ&hl=en
[cv]: https://ikashnitsky.github.io/x/cv/2022-12-cv-ilya-kashnitsky.pdf
[cpop]: https://www.sdu.dk/en/forskning/forskningsenheder/samf/cpop
[cpop-me]: https://www.sdu.dk/en/forskning/forskningsenheder/samf/cpop/about_the_centre/our_people/cpop_dem/ilya_kashnitsky
[mailto]: mailto:ilya.kashnitsky@gmail.com
[dst]: https://www.dst.dk/en/
[lcds]: https://www.demography.ox.ac.uk/
---
title: ""
# title-block-banner: "#DFFF00"
comments: false
code-tools: false
toc: false
margin-header: |
    <button class="btn btn-lg btn-secondary" type="button">
    <a href="/">{{< fa house >}} <small>back to blog</mall></a>
    </button>
---

<iframe src="https://docs.google.com/forms/d/e/1FAIpQLScstzmmXx4TZeDHyf9YLmiew5FeHhVKhZhQLv6t6M9xd8a9Qw/viewform?hl=en&sembedded=true" width="100%" height="525" frameborder="0" marginheight="0" marginwidth="0">Loading…</iframe>

::: {.callout-note}
# **No** need to log into your Google account to submit the form
:::
