# ..........................................................
# 2026-03-23 -- ai in R
# setup AI tools                -----------
# Ilya Kashnitsky, ilya.kashnitsky@gmail.com
# ..........................................................

library(tidyverse)
library(janitor)
library(magrittr)

library(ellmer)
library(btw)
library(gander)
library(reviewer)



# reviewer ----------------------------------------------------------------


options(
  reviewer.client = ellmer::chat_google_gemini()
)

review("X:/gh/laliga-preview/src/laliga-predictions-outcomes.R")

# it works!



# perplexity via api ------------------------------------------------------

options(
  ellmer.client = ellmer::chat_perplexity(api_key = sys.getenv("PERPLEXITY_API_KEY")
)

ellmer::chat_perplexity("is tidypolars better that collapse+kit")



# open router -------------------------------------------------------------


or <- ellmer::chat_openrouter(
  model = "nvidia/nemotron-3-super-120b-a12b:free",
  system_prompt = "you are a helpful assistant for R users"
)

or$chat("is tidypolars better that collapse+kit")
