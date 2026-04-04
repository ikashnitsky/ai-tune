# ..........................................................
# 2026-03-30 -- sys-prompts
# prepare input diles with {btw}                -----------
# Ilya Kashnitsky, ilya.kashnitsky@gmail.com
# ..........................................................

library(tidyverse)
library(magrittr)
library(here)
library(fs)
library(btw)
library(ellmer)
library(ragnar)

posts <- dir_ls(
    "x:/gh/ikashnitsky.github.io", recurse = TRUE, glob = "*.qmd"
) |>
  map_chr(read_as_markdown)

posts_chunks <- posts |>
    markdown_chunk()

posts |> write_lines(here("rag-posts.md"))
posts_chunks |> write_csv(here("rag-posts.csv"))


style_chunks <- posts |>
    mutate(
        n_tokens = subtract(end, start)
    ) |>
    # Keep only substantive chunks
    filter(
        n_tokens >= 80,          # long enough to show style
        !is.na(text),
        str_squish(text) != "",
        # strip nav/boilerplate signals
        !str_detect(text, regex("^(tags:|categories:|share this|subscribe|©)", ignore_case = TRUE))
    ) |>
    # One representative chunk per post to maximise diversity
    group_by(origin) |>
    slice_max(n_tokens, n = 3) |>   # top 3 richest chunks per post
    ungroup() |>
    # Build clean markdown blocks
    mutate(
        md_block = if_else(
            !is.na(headings) & headings != "",
            str_glue("### {headings}\n\n{text}"),
            text
        )
    )
