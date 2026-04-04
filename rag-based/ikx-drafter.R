# ============================================================
# gemini-gem-style-context.R
#
# Reads all .qmd blog posts from a GitHub repo, strips
# non-prose elements, uses ragnar::markdown_chunk() for
# semantic segmentation, scores chunks for prose quality,
# and exports a single Markdown file ready to upload as
# a Gemini Gem context document.
#
# Author:  ikashnitsky.github.io
# Requires: tidyverse, ragnar, httr2, glue
# ============================================================


# ---- 0. Packages ----------------------------------------------------
library(tidyverse)   # dplyr, purrr, stringr, readr
library(ragnar)      # install.packages("ragnar")
library(httr2)       # GitHub API + raw file downloads
library(glue)        # string interpolation


# ---- 0b. GitHub credentials (optional but recommended) --------------
# Set GITHUB_PAT in your .Renviron to get 5 000 req/hr instead of 60.
# usethis::edit_r_environ()  ->  GITHUB_PAT=ghp_...
gh_headers <- function() {
    pat <- Sys.getenv("GITHUB_PAT")
    headers <- list(
        Accept                 = "application/vnd.github+json",
        `X-GitHub-Api-Version` = "2022-11-28"
    )
    if (nzchar(pat)) headers[["Authorization"]] <- paste("Bearer", pat)
    headers
}


# ---- 1. Configuration -----------------------------------------------
GITHUB_OWNER  <- "ikashnitsky"
GITHUB_REPO   <- "ikashnitsky.github.io"
GITHUB_BRANCH <- "main"
OUTPUT_FILE   <- "gemini-gem-writing-style.md"

CHUNK_TARGET_SIZE   <- 1800L   # characters, roughly 300 words
MAX_CHUNKS_PER_POST <- 4L      # top-scoring prose chunks kept per post


# ---- 2. List all .qmd post files via GitHub Trees API ---------------
list_qmd_paths <- function(owner, repo, branch = "main") {
    url <- sprintf(
        "https://api.github.com/repos/%s/%s/git/trees/%s?recursive=1",
        owner, repo, branch
    )

    resp <- request(url) |>
        req_headers(!!!gh_headers()) |>
        req_error(is_error = \(r) FALSE) |>
        req_perform()

    if (resp_status(resp) != 200L) {
        stop(
            "GitHub API returned ", resp_status(resp),
            ". Set GITHUB_PAT env var to avoid rate limiting."
        )
    }

    body <- resp_body_json(resp)

    if (isTRUE(body$truncated)) {
        warning("GitHub tree was truncated - some files may be missing.")
    }

    body$tree |>
        keep(\(x) x$type == "blob" && endsWith(x$path, ".qmd")) |>
        map_chr(\(x) x$path) |>
        # Keep files that live under year-named top-level dirs (actual posts)
        keep(\(p) str_detect(p, "^20\\d{2}/")) |>
        # Skip bare year-index files: e.g. 2024/index.qmd
        discard(\(p) str_detect(p, "^20\\d{2}/index\\.qmd$"))
}


# ---- 3. Download a single raw .qmd file -----------------------------
download_qmd <- function(path, owner, repo, branch = "main") {
    url <- sprintf(
        "https://raw.githubusercontent.com/%s/%s/%s/%s",
        owner, repo, branch, path
    )
    tryCatch(
        request(url) |>
            req_error(is_error = \(r) FALSE) |>
            req_perform() |>
            resp_body_string(),
        error = \(e) {
            message("  x download failed: ", path)
            NULL
        }
    )
}


# ---- 4. Parse YAML front-matter -------------------------------------
# Returns list(meta = list(title, date, draft), body = character(1))
parse_yaml_front <- function(text) {
    if (is.null(text)) return(NULL)

    lines  <- strsplit(text, "\n", fixed = TRUE)[[1L]]
    delims <- which(trimws(lines) == "---")

    meta <- list(title = NA_character_, date = NA_character_, draft = FALSE)
    body_start <- 1L

    if (length(delims) >= 2L && delims[1L] == 1L) {
        yaml_block <- lines[seq.int(2L, delims[2L] - 1L)]
        body_start <- delims[2L] + 1L

        get_val <- function(prefix) {
            hit <- yaml_block[startsWith(yaml_block, prefix)]
            if (length(hit)) {
                str_remove_all(
                    str_extract(hit[1L], "(?<=:\\s{0,8}).*"),
                    '["\' ]'
                )
            } else {
                NA_character_
            }
        }

        meta$title <- get_val("title")
        meta$date  <- str_extract(get_val("date") %||% "", "\\d{4}-\\d{2}-\\d{2}")
        draft_raw  <- get_val("draft")
        meta$draft <- isTRUE(!is.na(draft_raw) && trimws(draft_raw) == "true")
    }

    list(
        meta = meta,
        body = paste(lines[seq.int(body_start, length(lines))], collapse = "\n")
    )
}


# ---- 5. Strip non-prose elements ------------------------------------
# Removes code chunks, HTML, images, bare URLs.
# Preserves headings, paragraphs, and inline formatting.
strip_non_prose <- function(text) {
    text |>
        # Quarto chunk option lines  #| key: val
        str_remove_all("(?m)^#\\|[^\n]*\n") |>
        # Fenced code with engine tag  ```{r}, ```{python}, ```{julia}
        str_remove_all("```\\{[^}]*\\}[\\s\\S]*?```") |>
        # Plain fenced code blocks  ``` ... ```
        str_remove_all("```[\\s\\S]*?```") |>
        # HTML comments  <!-- ... -->
        str_remove_all("(?s)<!--.*?-->") |>
        # HTML / XML tags
        str_remove_all("<[a-zA-Z/][^>]*>") |>
        # Quarto div fences  ::: {.class}  and closing  :::
        str_remove_all("(?m)^:::\\s*\\{[^}]*\\}\\s*$") |>
        str_remove_all("(?m)^:::.*$") |>
        # Quarto shortcodes  {{< ... >}}
        str_remove_all("\\{\\{<[^>]+>\\}\\}") |>
        # Image embeds  ![]()
        str_remove_all("!\\[[^\\]]*\\]\\([^)]*\\)") |>
        # Inline hyperlinks  [display text](url)  -> keep display text only
        str_replace_all("\\[([^\\]]+)\\]\\(https?://[^)]+\\)", "\\1") |>
        # Reference-style links  [display text][ref]  -> keep display text
        str_replace_all("\\[([^\\]]+)\\]\\[[^\\]]*\\]", "\\1") |>
        # Link definition lines  [ref]: https://...
        str_remove_all("(?m)^\\[[^\\]]+\\]:\\s+https?://\\S+.*$") |>
        # Bare URLs
        str_remove_all("https?://\\S+") |>
        # Collapse excessive blank lines
        str_replace_all("\n{3,}", "\n\n") |>
        str_trim()
}


# ---- 6. Chunk with ragnar + score prose quality ---------------------
chunk_and_score <- function(clean_text, origin, min_words = 35L) {
    if (is.null(clean_text) || nchar(clean_text) < 250L) return(NULL)

    doc <- MarkdownDocument(clean_text, origin = origin)

    chunks <- tryCatch(
        markdown_chunk(
            doc,
            target_size               = CHUNK_TARGET_SIZE,
            target_overlap            = 0L,        # no overlap: style, not retrieval
            segment_by_heading_levels = c(1L, 2L), # hard boundaries at H1/H2
            context = TRUE,
            text    = TRUE
        ),
        error = \(e) NULL
    )

    if (is.null(chunks) || nrow(chunks) == 0L) return(NULL)

    as_tibble(chunks) |>
        mutate(
            word_count = str_count(text, "\\S+"),
            # Prose quality heuristic:
            #   + words            (baseline signal for length)
            #   + sentence endings (complete-sentence prose indicator)
            #   - backtick/bracket density (code / list remnants)
            prose_score =
                word_count +
                str_count(text, "[.!?]\\s")          *  5L -
                str_count(text, "[`{}\\[\\]<>]")     *  2L -
                str_count(text, "(?m)^\\s*[-*+]\\s") *  1L
        ) |>
        filter(word_count >= min_words)
}


# ---- 7. Main ingestion loop -----------------------------------------
message("Listing .qmd post files ...")
qmd_paths <- list_qmd_paths(GITHUB_OWNER, GITHUB_REPO, GITHUB_BRANCH)
message(sprintf("   Found %d post .qmd files", length(qmd_paths)))

message("\nDownloading, cleaning, and chunking ...")
all_chunks <- map(seq_along(qmd_paths), function(i) {
    path <- qmd_paths[[i]]
    if (i %% 10L == 0L)
        message(sprintf("   %3d / %d  %s", i, length(qmd_paths), path))

    raw    <- download_qmd(path, GITHUB_OWNER, GITHUB_REPO, GITHUB_BRANCH)
    parsed <- parse_yaml_front(raw)
    if (is.null(parsed) || isTRUE(parsed$meta$draft)) return(NULL)

    clean  <- strip_non_prose(parsed$body)
    chunks <- chunk_and_score(clean, origin = path)
    if (is.null(chunks)) return(NULL)

    # Derive fallback title / date from the file path when YAML is missing
    path_date  <- str_extract(path, "\\d{4}-\\d{2}-\\d{2}")
    path_title <- path |>
        str_remove("^20\\d{2}/") |>
        str_remove("/index\\.qmd$|\\.qmd$") |>
        str_replace_all("[-_/]", " ") |>
        str_to_sentence()

    chunks |>
        mutate(
            post_title = coalesce(parsed$meta$title, path_title),
            post_date  = coalesce(parsed$meta$date,  path_date),
            .before    = 1L
        )
}) |>
    compact() |>
    bind_rows()

message(sprintf(
    "\nExtracted %d prose chunks from %d posts",
    nrow(all_chunks), n_distinct(all_chunks$post_title)
))


# ---- 8. Curate: keep top-N best-scoring chunks per post -------------
curated <- all_chunks |>
    group_by(post_date, post_title) |>
    slice_max(prose_score, n = MAX_CHUNKS_PER_POST, with_ties = FALSE) |>
    ungroup() |>
    arrange(post_date)

message(sprintf(
    "   Curated to %d chunks  (~%s words total)",
    nrow(curated),
    format(sum(curated$word_count), big.mark = ",")
))


# ---- 9. Assemble the Gemini Gem context document --------------------

# 9a. Per-post prose sections
format_post_section <- function(df, key) {
    title <- key$post_title
    date  <- key$post_date %||% "undated"

    prose <- df |>
        arrange(start) |>
        mutate(text = str_trim(text)) |>
        pull(text) |>
        paste(collapse = "\n\n")

    glue("### {title}\n*{date}*\n\n{prose}")
}

post_sections <- curated |>
    group_by(post_title, post_date) |>
    group_map(format_post_section) |>
    paste(collapse = "\n\n---\n\n")

# 9b. Summary statistics
stats <- list(
    n_posts  = n_distinct(curated$post_title),
    n_chunks = nrow(curated),
    n_words  = format(sum(curated$word_count), big.mark = ","),
    earliest = min(curated$post_date, na.rm = TRUE),
    latest   = max(curated$post_date, na.rm = TRUE)
)

# 9c. Preamble - the Gem's system instruction block
preamble <- glue(
    "# Writing Style Context: Ilya Kashnitsky (ikashnitsky.github.io)

## Instructions for the Gem

You are a writing assistant for **Ilya Kashnitsky** -- demographer, data
scientist, and R developer. Your task is to draft blog post text that is
indistinguishable from his own writing.

This file contains **{stats$n_chunks} curated prose excerpts** from
{stats$n_posts} blog posts ({stats$earliest} to {stats$latest}),
totalling ~{stats$n_words} words. Study them carefully before drafting.

---

## Style Guide

| Dimension | Pattern |
|---|---|
| **Voice** | First-person. Active, present-tense narration. Thinks out loud. |
| **Opening** | Never a summary. Opens with a concrete observation, a question, or an anecdote. |
| **Argument flow** | Question -> exploration -> surprising result -> reflection. Resists tidy endings. |
| **Sentence rhythm** | Short declaratives mixed with longer analytical sentences. Em-dashes and parentheticals are natural. |
| **Technical register** | Explains complexity via analogies and thought experiments. Code is always a means to a story. |
| **Personality** | Self-deprecating humour. Honest about failures and lucky breaks. References personal geography. |
| **Hedging** | Comfortable with 'I think', 'my wild guess', 'arguably'. No boilerplate disclaimers. |
| **Citations** | Casual. Links woven into prose. Twitter/Mastodon threads cited without embarrassment. |
| **Lists** | Sparing. Prefers prose flow; lists only for genuine enumerations. |
| **Length** | 400-1500 words. Stops when the point is made. No padding. |

---

## Prose Samples (Chronological)

*Real excerpts extracted from {stats$n_posts} blog posts.*
*Use these as direct style references when drafting new content.*

"
)

output <- paste0(preamble, post_sections, "\n")


# ---- 10. Write output -----------------------------------------------
writeLines(output, OUTPUT_FILE, useBytes = TRUE)

sz_kb <- file.size(OUTPUT_FILE) / 1024
message(sprintf(
    "\nSaved: %s  (%.0f KB -- Gemini free-tier upload limit: 100 MB)",
    OUTPUT_FILE, sz_kb
))
message("Upload this file when creating your Gemini Gem as a context document.")


# ==== Watch Out =======================================================
# 1. GitHub API rate limit: unauthenticated = 60 req/hr. A blog with
#    60+ posts will hit the limit mid-loop. Set GITHUB_PAT in .Renviron
#    (usethis::edit_r_environ()) to raise the limit to 5 000 req/hr.
#
# 2. The `!!!` splice in req_headers(!!!gh_headers()) requires
#    rlang >= 1.0 (loaded with tidyverse). On older environments replace
   with:  do.call(req_headers, c(list(request(url)), gh_headers()))
