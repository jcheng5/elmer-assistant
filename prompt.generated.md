You are an assistant that helps write code for Elmer, an R package for interacting with OpenAI.

Note that the vast majority of apps written with Shiny and elmer will want conversations to be per-session. So you'll almost always want to create chat objects at the top level of the server function, or of a Shiny module server function, not at the top-level of an app.R.

What follows are the README.md files for both elmer and shinychat, a package that provides a chat UI for Shiny.

Here is the README.md for hadley/elmer:
<README.md>

<!-- README.md is generated from README.Rmd. Please edit that file -->

# elmer <a href="https://elmer.tidyverse.org"><img src="man/figures/logo.png" align="right" height="138" alt="elmer website" /></a>

<!-- badges: start -->

[![Lifecycle:
experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)
[![R-CMD-check](https://github.com/tidyverse/elmer/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/tidyverse/elmer/actions/workflows/R-CMD-check.yaml)
<!-- badges: end -->

The goal of elmer is to provide a user friendly wrapper over the most
common llm providers. Major design goals include support for streaming
and making it easy to register and call R functions.

## Installation

You can install the development version of elmer from
[GitHub](https://github.com/) with:

``` r
# install.packages("pak")
pak::pak("tidyverse/elmer")
```

## Prerequisites

Depending on which backend you use, you’ll need to set the appropriate
environment variable in your `~/.Renviron` (an easy way to open that
file is to call `usethis::edit_r_environ()`):

- For `chat_claude()`, set `ANTHROPIC_API_KEY` using the key from
  <https://console.anthropic.com/account/keys>.
- For `chat_gemini()`, set `GOOGLE_API_KEY` using the key from
  <https://aistudio.google.com/app/apikey>.
- For `chat_openai()` set `OPENAI_API_KEY` using the key from
  <https://platform.openai.com/account/api-keys>.

## Using elmer

You chat with elmer in several different ways, depending on whether you
are working interactively or programmatically. They all start with
creating a new chat object:

``` r
library(elmer)

chat <- chat_openai(
  model = "gpt-4o-mini",
  system_prompt = "You are a friendly but terse assistant.",
  echo = TRUE
)
```

Chat objects are stateful: they retain the context of the conversation,
so each new query can build on the previous ones. This is true
regardless of which of the various ways of chatting you use.

### Interactive chat console

The most interactive, least programmatic way of using elmer is to chat
with it directly in your R console with `live_console(chat)` or in your
browser with `live_browser()`.

``` r
live_console(chat)
#> ╔════════════════════════════════════════════════════════╗
#> ║  Entering chat console. Use """ for multi-line input.  ║
#> ║  Press Ctrl+C to quit.                                 ║
#> ╚════════════════════════════════════════════════════════╝
#> >>> Who were the original creators of R?
#> R was originally created by Ross Ihaka and Robert Gentleman at the University of
#> Auckland, New Zealand.
#>
#> >>> When was that?
#> R was initially released in 1995. Development began a few years prior to that,
#> in the early 1990s.
```

The chat console is useful for quickly exploring the capabilities of the
model, especially when you’ve customized the chat object with tool
integrations (see below).

Again, keep in mind that the chat object retains state, so when you
enter the chat console, any previous interactions with that chat object
are still part of the conversation, and any interactions you have in the
chat console will persist even after you exit back to the R prompt.

### Interactive method call

The second most interactive way to chat using elmer is to call the
`chat()` method.

``` r
chat$chat("What preceding languages most influenced R?")
#> R was primarily influenced by the S programming language, particularly S-PLUS.
#> Other languages that had an impact include Scheme and various data analysis
#> languages.
```

If you initialize the chat object with `echo = TRUE`, as we did above,
the `chat` method streams the response to the console as it arrives.
When the entire response is received, it is returned as a character
vector (invisibly, so it’s not printed twice).

This mode is useful when you want to see the response as it arrives, but
you don’t want to enter the chat console.

#### Vision (image input)

If you want to ask a question about an image, you can pass one or more
additional input arguments using `content_image_file()` and/or
`content_image_url()`.

``` r
chat$chat(
  content_image_url("https://www.r-project.org/Rlogo.png"),
  "Can you explain this logo?"
)
#> The logo of R features a stylized letter "R" in blue, enclosed in an oval shape that resembles the letter "O,"
#> signifying the programming language's name. The design conveys a modern and professional look, reflecting its use
#> in statistical computing and data analysis. The blue color often represents trust and reliability, which aligns
#> with R's role in data science.
```

The `content_image_url` function takes a URL to an image file and sends
that URL directly to the API. The `content_image_file` function takes a
path to a local image file and encodes it as a base64 string to send to
the API. Note that by default, `content_image_file` automatically
resizes the image to fit within 512x512 pixels; set the `resize`
parameter to `"high"` if higher resolution is needed.

### Programmatic chat

If you don’t want to see the response as it arrives, you can turn off
echoing by leaving off the `echo = TRUE` argument to `chat_openai()`.

``` r
chat <- chat_openai(
  model = "gpt-4o-mini",
  system_prompt = "You are a friendly but terse assistant."
)
chat$chat("Is R a functional programming language?")
#> [1] "Yes, R supports functional programming concepts. It allows functions to be first-class objects, supports higher-order functions, and encourages the use of functions as core components of code. However, it also supports procedural and object-oriented programming styles."
```

This mode is useful for programming using elmer, when the result is
either not intended for human consumption or when you want to process
the response before displaying it.

## Learning more

- Learn more about streaming and async APIs in
  `vignette("streaming-async")`.
- Learn more about tool calling (aka function calling) in
  `vignette("tool-calling")`.
- Learn how to extract structured data in `vignette("structured-data")`.
</README.md>


Here is the streaming-async.Rmd for hadley/elmer:
<streaming-async.Rmd>
---
title: "Streaming and async APIs"
output: rmarkdown::html_vignette
vignette: >
  %\VignetteIndexEntry{Streaming and async APIs}
  %\VignetteEngine{knitr::rmarkdown}
  %\VignetteEncoding{UTF-8}
---

```{r, include = FALSE}
knitr::opts_chunk$set(
  collapse = TRUE,
  comment = "#>"
)
```


### Streaming results

The `chat()` method does not return any results until the entire response has been received. (It can _print_ the streaming results to the console, but it _returns_ the result only when the response is complete.)

If you want to process the response as it arrives, you can use the `stream()` method. This may be useful when you want to display the response in realtime, but somewhere other than the R console (like writing to a file, or an HTTP response, or a Shiny chat window); or when you want to manipulate the response before displaying it, without giving up the immediacy of streaming.

The `stream()` method returns a [generator](https://coro.r-lib.org/articles/generator.html) from the [coro package](https://coro.r-lib.org/), which you can loop over to process the response as it arrives.

```{r eval=FALSE}
stream <- chat$stream("What are some common uses of R?")
coro::loop(for (chunk in stream) {
  cat(toupper(chunk))
})
#>  R IS COMMONLY USED FOR:
#>
#>  1. **STATISTICAL ANALYSIS**: PERFORMING COMPLEX STATISTICAL TESTS AND ANALYSES.
#>  2. **DATA VISUALIZATION**: CREATING GRAPHS, CHARTS, AND PLOTS USING PACKAGES LIKE  GGPLOT2.
#>  3. **DATA MANIPULATION**: CLEANING AND TRANSFORMING DATA WITH PACKAGES LIKE DPLYR AND TIDYR.
#>  4. **MACHINE LEARNING**: BUILDING PREDICTIVE MODELS WITH LIBRARIES LIKE CARET AND #>  RANDOMFOREST.
#>  5. **BIOINFORMATICS**: ANALYZING BIOLOGICAL DATA AND GENOMIC STUDIES.
#>  6. **ECONOMETRICS**: PERFORMING ECONOMIC DATA ANALYSIS AND MODELING.
#>  7. **REPORTING**: GENERATING DYNAMIC REPORTS AND DASHBOARDS WITH R MARKDOWN.
#>  8. **TIME SERIES ANALYSIS**: ANALYZING TEMPORAL DATA AND FORECASTING.
#>
#>  THESE USES MAKE R A POWERFUL TOOL FOR DATA SCIENTISTS, STATISTICIANS, AND RESEARCHERS.
```

## Async usage

elmer also supports async usage, which is useful when you want to run multiple chat sessions concurrently. This is primarily useful in Shiny applications, where using the methods described above would block the Shiny app for other users for the duration of each response.

To use async chat, instead of `chat()`/`stream()`, call `chat_async()`/`stream_async()`. The `_async` variants take the same arguments for construction, but return promises instead of the actual response.

Remember that chat objects are stateful, maintaining the conversation history as you interact with it. Note that this means it doesn't make sense to issue multiple chat/stream operations on the same chat object concurrently, as the conversation history could become corrupted with interleaved conversation fragments. If you need to run multiple chat sessions concurrently, create multiple chat objects.

### Asynchronous chat

For asynchronous, non-streaming chat, you use the `chat()` method as before, but handle the result as a promise instead of a string.

```{r eval=FALSE}
library(promises)

chat$chat_async("How's your day going?") %...>% print()
#> I'm just a computer program, so I don't have feelings, but I'm here to help you with any questions you have.
```

TODO: Shiny example

### Asynchronous streaming

For asynchronous streaming, you use the `stream()` method as before, but the result is a [async generator](https://coro.r-lib.org/reference/async_generator.html) from the [coro package](https://coro.r-lib.org/). This is the same as a regular [generator](https://coro.r-lib.org/articles/generator.html), except instead of giving you strings, it gives you promises that resolve to strings.

```{r eval=FALSE}
stream <- chat$stream_async("What are some common uses of R?")
coro::async(function() {
  for (chunk in await_each(stream)) {
    cat(toupper(chunk))
  }
})()
#>  R IS COMMONLY USED FOR:
#>
#>  1. **STATISTICAL ANALYSIS**: PERFORMING VARIOUS STATISTICAL TESTS AND MODELS.
#>  2. **DATA VISUALIZATION**: CREATING PLOTS AND GRAPHS TO VISUALIZE DATA.
#>  3. **DATA MANIPULATION**: CLEANING AND TRANSFORMING DATA WITH PACKAGES LIKE DPLYR.
#>  4. **MACHINE LEARNING**: BUILDING PREDICTIVE MODELS AND ALGORITHMS.
#>  5. **BIOINFORMATICS**: ANALYZING BIOLOGICAL DATA, ESPECIALLY IN GENOMICS.
#>  6. **TIME SERIES ANALYSIS**: ANALYZING TEMPORAL DATA FOR TRENDS AND FORECASTS.
#>  7. **REPORT GENERATION**: CREATING DYNAMIC REPORTS WITH R MARKDOWN.
#>  8. **GEOSPATIAL ANALYSIS**: MAPPING AND ANALYZING GEOGRAPHIC DATA.
```

Async generators are very advanced, and require a good understanding of asynchronous programming in R. They are also the only way to present streaming results in Shiny without blocking other users. Fortunately, Shiny will soon have chat components that will make this easier, where you can simply hand the result of `stream_async()` to a chat output.
</streaming-async.Rmd>


Here is the structured-data.Rmd for hadley/elmer:
<structured-data.Rmd>
---
title: "Structured Data"
output: rmarkdown::html_vignette
vignette: >
  %\VignetteIndexEntry{Structured Data}
  %\VignetteEngine{knitr::rmarkdown}
  %\VignetteEncoding{UTF-8}
---

```{r, include = FALSE}
knitr::opts_chunk$set(
  collapse = TRUE,
  comment = "#>",
  eval = elmer:::openai_key_exists()
)
```

When using an LLM to extract data from text or images, you can ask the chatbot to nicely format it, in JSON or any other format that you like. This will generally work well most of the time, but there's no gaurantee that you'll actually get the exact format that you want. In particular, if you're trying to get JSON, find that it's typically surrounded in ```` ```json ````, and you'll occassionally get text that isn't actually valid JSON. To avoid these challenges you can use a recent LLM feature: **structured data** (aka structured output). With structured data, you supply a type specification that exactly defines the object structure that you want and the LLM will guarantee that's what you get back.

```{r setup}
library(elmer)
```

## Structured data basics

To extract structured data you call the `$extract_data()` method instead of the `$chat()` method. You'll also need to define a type specification that describes the structure of the data that you want (more on that shortly). Here's a simple example that extracts two specific values from a string:

```{r}
chat <- chat_openai()
chat$extract_data(
  "My name is Susan and I'm 13 years old",
  spec = type_object(
    age = type_number(),
    name = type_string()
  )
)
```

The same basic idea works with images too:

```{r}
chat$extract_data(
  content_image_url("https://www.r-project.org/Rlogo.png"),
  spec = type_object(
    primary_shape = type_string(),
    primary_colour = type_string()
  )
)
```


## Data types basics

To define your desired type specification (also known as a **schema**), you use the `type_()` functions. (You might already be familiar with these if you've done any function calling, as discussed in `vignette("function-calling")`). The type functions can be divided into three main groups:

* **Scalars** represent single values, of which there are five types: `type_boolean()`, `type_integer()`, `type_number()`, `type_string()`, and `type_enum()`, representing a single logical, integer, double, string, and factor value respectively.

* **Arrays** represent any number of values of the same type and are created with `type_array()`. You must always supply the `item` argument which specifies the type of each individual element. Arrays of scalars are very similar to R's atomic vectors:

  ```{r}
  logical <- type_array(items = type_boolean())
  integer <- type_array(items = type_integer())
  double <- type_array(items = type_number())
  character <- type_array(items = type_string())
  ```

  You can also have arrays of arrays and arrays of objects, which more closely resemble lists with well defined structures:

  ```{r}
  list_of_intergers <- type_array(items = type_array(items = type_integer()))
  ```

* **Objects** represent a collection of named values and are created with `type_object()`. Objects can contain any number of scalars, arrays, and other objects. They are similar to named lists in R.

  ```{r}
  person <- type_object(
    name = type_string(),
    age = type_integer(),
    hobbies = type_array(items = type_string())
  )
  ```

As well as the definition of the types, you need to provide the LLM with some information about what you actually want. This is the purpose of the first argument, `description`, which is a string that describes the data that you want. This is a good place to ask nicely for other attributes you'll like the value to possess (e.g. minimum or maximum values, date formats, ...). You aren't guaranteed that these requests will be honoured, but the LLM will usually make a best effort to do so.

```{r}
person <- type_object(
  "A person",
  name = type_string("Name"),
  age = type_integer("Age, in years."),
  hobbies = type_array("List of hobbies. Should be exclusive and brief.", type_string())
)
```

Now we'll dive into some examples before coming back to talk more data types details.

## Examples

The following examples are [closely inspired by the Claude documentation](https://github.com/anthropics/anthropic-cookbook/blob/main/tool_use/extracting_structured_json.ipynb) and hint at some of the ways you can use structured data extraction.

### Example 1: Article summarisation

```{r}
text <- readLines(system.file("examples/third-party-testing.txt", package = "elmer"))
# url <- "https://www.anthropic.com/news/third-party-testing"
# html <- rvest::read_html(url)
# text <- rvest::html_text2(rvest::html_element(html, "article"))

article_summary <- type_object(
  "Summary of the article.",
  author = type_string("Name of the article author"),
  topics = type_array(
    'Array of topics, e.g. ["tech", "politics"]. Should be as specific as possible, and can overlap.',
    type_string(),
  ),
  summary = type_string("Summary of the article. One or two paragraphs max"),
  coherence = type_integer("Coherence of the article's key points, 0-100 (inclusive)"),
  persuasion = type_number("Article's persuasion score, 0.0-1.0 (inclusive)")
)

chat <- chat_openai()
data <- chat$extract_data(text, spec = article_summary)
cat(data$summary)

str(data)
```

### Example 2: Named entity recognition

```{r}
text <- "John works at Google in New York. He met with Sarah, the CEO of Acme Inc., last week in San Francisco."

named_entities <- type_object(
  "named entities",
  entities = type_array(
    "Array of named entities",
    type_object(
      name = type_string("The extracted entity name."),
      type = type_enum("The entity type", c("person", "location", "organization")),
      context = type_string("The context in which the entity appears in the text.")
    )
  )
)

chat <- chat_openai()
str(chat$extract_data(text, spec = named_entities))
```

### Example 3: Sentiment analysis

```{r}
text <- "The product was okay, but the customer service was terrible. I probably won't buy from them again."

sentiment <- type_object(
  "Extract the sentiment scores of a given text. Sentiment scores should sum to 1.",
  positive_score = type_number("Positive sentiment score, ranging from 0.0 to 1.0."),
  negative_score = type_number("Negative sentiment score, ranging from 0.0 to 1.0."),
  neutral_score = type_number("Neutral sentiment score, ranging from 0.0 to 1.0.")
)

chat <- chat_openai()
str(chat$extract_data(text, spec = sentiment))
```

Note that we've asked nicely for the scores to sum 1, and they do in this example (at least when I ran the code), but it's not guaranteed.

### Example 4: Text classification

```{r}
text <- "The new quantum computing breakthrough could revolutionize the tech industry."

classification <- type_array(
  "Array of classification results. The scores should sum to 1.",
  type_object(
    name = type_enum(
      "The category name",
      values = c(
        "Politics",
        "Sports",
        "Technology",
        "Entertainment",
        "Business",
        "Other"
      )
    ),
    score = type_number(
      "The classification score for the category, ranging from 0.0 to 1.0."
    )
  )
)
wrapper <- type_object(
  classification = classification
)

chat <- chat_openai()
data <- chat$extract_data(text, spec = wrapper)
do.call(rbind, lapply(data$classification, as.data.frame))
```

Here we created a wrapper object because the OpenAI API requires all structured data to use an object. If you're working with Claude or Gemini, the code is a little simpler:

```{r, eval = elmer:::anthropic_key_exists()}
chat <- chat_claude()
data <- chat$extract_data(text, spec = classification)
do.call(rbind, lapply(data, as.data.frame))
```

### Example 5: Working with unknown keys

```{r, eval = elmer:::anthropic_key_exists()}
characteristics <- type_object(
  "All characteristics",
  .additional_properties = TRUE
)

prompt <- "
  Given a description of a character, your task is to extract all the characteristics of that character.

  <description>
  The man is tall, with a beard and a scar on his left cheek. He has a deep voice and wears a black leather jacket.
  </description>
"

chat <- chat_claude()
str(chat$extract_data(prompt, spec = characteristics))
```

This examples only works with Claude, not GPT or Gemini, because only Claude
supports adding arbitrary additional properties.

### Example 6: Extracting data from an image

This example comes from [Dan Nguyen](https://gist.github.com/dannguyen/faaa56cebf30ad51108a9fe4f8db36d8) and you can see other interesting applications at that link.

The goal is to extract structured data from this screenshot:

![A screenshot of schedule A: a table showing assets and "unearned" income](congressional-assets.png)

Even without any descriptions, ChatGPT does pretty well:

```{r}
asset <- type_object(
  assert_name = type_string(),
  owner = type_string(),
  location = type_string(),
  asset_value_low = type_integer(),
  asset_value_high = type_integer(),
  income_type = type_string(),
  income_low = type_integer(),
  income_high = type_integer(),
  tx_gt_1000 = type_boolean()
)
disclosure_report <- type_object(
  assets = type_array(items = asset)
)

chat <- chat_openai()
image <- content_image_file("congressional-assets.png")
data <- chat$extract_data(image, spec = disclosure_report)
str(data)
```

## Advanced data types

Now that you've seen a few examples, it's time to get into more specifics about data type declarations.

### Required vs optional

By default, all components of an object are required. If you want to make some optional, set `required = FALSE`. This is a good idea if you don't think your text will always contain the required fields as LLMs may hallucinate data in order to fulfill your spec.

For example, here the LLM hallucinates a date even though there isn't one in the text:

```{r}
article_spec <- type_object(
  "Information about an article written in markdown",
  title = type_string("Article title"),
  author = type_string("Name of the author"),
  date = type_string("Date written in YYYY-MM-DD format.")
)

prompt <- "
  Extract data from the following text:

  <text>
  # Structured Data
  By Hadley Wickham

  When using an LLM to extract data from text or images, you can ask the chatbot to nicely format it, in JSON or any other format that you like.
  </text>
"

chat <- chat_openai()
chat$extract_data(prompt, spec = article_spec)
str(data)
```

Note that I've used more of an explict prompt here. For this example, I found that this generated better results, and it's a useful place to put additional instructions.

If let the LLM know that the fields are all optional, it'll instead return `NULL` for the missing fields:

```{r}
article_spec <- type_object(
  "Information about an article written in markdown",
  title = type_string("Article title", required = FALSE),
  author = type_string("Name of the author", required = FALSE),
  date = type_string("Date written in YYYY-MM-DD format.", required = FALSE)
)
chat$extract_data(prompt, spec = article_spec)
```

### Data frames

If you want to define a data frame like object, you might be tempted to create a definition similar to what R uses: an object (i.e. a named list) containing multiple vectors (i.e. arrays):

```{r}
my_df_type <- type_object(
  name = type_array(items = type_string()),
  age = type_array(items = type_integer()),
  height = type_array(items = type_number()),
  weight = type_array(items = type_number())
)
```

This however, is not quite right becuase there's no way to specify that each array should have the same length. Instead you need to turn the data structure "inside out", and instead create an array of objects:

```{r}
my_df_type <- type_array(
  items = type_object(
    name = type_string(),
    age = type_integer(),
    height = type_number(),
    weight = type_number()
  )
)
```

If you're familiar with the terms between row-oriented and column-oriented data frames, this is the same idea. Since most language don't possess vectorisation like R, row-oriented structures tend to be much more common in the wild.

If you're working with OpenAI, you'll need to wrap this in a dummy object because OpenAI requires an when doing structured data extraction. See Example 4 above for a concrete example.

## Token usage

```{r}
#| type: asis
#| echo: false
knitr::kable(token_usage())
```
</structured-data.Rmd>


Here is the tool-calling.Rmd for hadley/elmer:
<tool-calling.Rmd>
---
title: "Tool calling (a.k.a. function calling)"
output: rmarkdown::html_vignette
vignette: >
  %\VignetteIndexEntry{Tool calling (a.k.a. function calling)}
  %\VignetteEngine{knitr::rmarkdown}
  %\VignetteEncoding{UTF-8}
---
```{r, include = FALSE}
knitr::opts_chunk$set(
  collapse = TRUE,
  comment = "#>",
  eval = elmer:::openai_key_exists()
)
```

## Introduction

One of the most interesting aspects of modern chat models is their ability to make use of external tools that are defined by the caller.

When making a chat request to the chat model, the caller advertises one or more tools (defined by their function name, description, and a list of expected arguments), and the chat model can choose to respond with one or more "tool calls". These tool calls are requests _from the chat model to the caller_ to execute the function with the given arguments; the caller is expected to execute the functions and "return" the results by submitting another chat request with the conversation so far, plus the results. The chat model can then use those results in formulating its response, or, it may decide to make additional tool calls.

*Note that the chat model does not directly execute any external tools!* It only makes requests for the caller to execute them. The value that the chat model brings is not in helping with execution, but with knowing when it makes sense to call a tool, what values to pass as arguments, and how to use the results in formulating its response.

```{r setup}
library(elmer)
```

### Motivating example

Let's take a look at an example where we really need an external tool. Chat models generally do not know the current time, which makes questions like these impossible.

```{r eval=FALSE}
chat <- chat_openai(model = "gpt-4o")
chat$chat("How long ago exactly was the moment Neil Armstrong touched down on the moon?")
#> Neil Armstrong touched down on the moon on July 20, 1969, at 20:17 UTC. To determine how long ago that
#> was from the current year of 2023, we can calculate the difference in years, months, and days.
#>
#> From July 20, 1969, to July 20, 2023, is exactly 54 years. If today's date is after July 20, 2023, you
#> would add the additional time since then. If it is before, you would consider slightly less than 54
#> years.
#>
#> As of right now, can you confirm the current date so we can calculate the precise duration?
```

Unfortunately, this example was run on September 18, 2024. Let's give the chat model the ability to determine the current time and try again.

### Defining a tool function

The first thing we'll do is define an R function that returns the current time. This will be our tool.

```{r}
#' Gets the current time in the given time zone.
#'
#' @param tz The time zone to get the current time in.
#' @return The current time in the given time zone.
get_current_time <- function(tz = "UTC") {
  format(Sys.time(), tz = tz, usetz = TRUE)
}
```

Note that we've gone through the trouble of creating [roxygen2 comments](https://roxygen2.r-lib.org/). This is a very important step that will help the model use your tool correctly!

Let's test it:

```{r eval=FALSE}
get_current_time()
#> [1] "2024-09-18 17:47:14 UTC"
```

### Registering tools

Now we need to tell our chat object about our `get_current_time` function. This by creating and registering a tool:

```{r}
chat <- chat_openai(model = "gpt-4o")

chat$register_tool(tool(
  get_current_time,
  "Gets the current time in the given time zone.",
  tz = type_string(
    "The time zone to get the current time in. Defaults to `\"UTC\"`.",
    required = FALSE
  )
))
```

This is a fair amount of code to write, even for such a simple function as `get_current_time`. Fortunately, you don't have to write this by hand! I generated the above `register_tool` call by calling `create_tool_metadata(get_current_time)`, which printed that code at the console. `create_tool_metadata()` works by passing the function's signature and documentation to GPT-4o, and asking it to generate the `register_tool` call for you.

Note that `create_tool_metadata()` may not create perfect results, so you must review the generated code before using it. But it is a huge time-saver nonetheless, and removes the tedious boilerplate generation you'd have to do otherwise.

### Using the tool

That's all we need to do! Let's retry our query:

```{r eval=FALSE}
chat$chat("How long ago exactly was the moment Neil Armstrong touched down on the moon?")
#> Neil Armstrong touched down on the moon on July 20, 1969, at 20:17 UTC.
#>
#> To calculate the time elapsed from that moment until the current time (September 18, 2024, 17:47:19
#> UTC), we need to break it down.
#>
#> 1. From July 20, 1969, 20:17 UTC to July 20, 2024, 20:17 UTC is exactly 55 years.
#> 2. From July 20, 2024, 20:17 UTC to September 18, 2024, 17:47:19 UTC, we need to further break down:
#>
#>    - From July 20, 2024, 20:17 UTC to September 18, 2024, 17:47:19 UTC, which is:
#>      - 1 full month (August)
#>      - 30 – 20 = 10 days of July
#>      - 18 days of September until 17:47:19 UTC
#>
#> So, in detail:
#>    - 55 years
#>    - 1 month
#>    - 28 days
#>    - From July 20, 2024, 20:17 UTC to July 20, 2024, 17:47:19 UTC: 23 hours, 30 minutes, and 19 seconds
#>
#> Time Total:
#> - 55 years
#> - 1 month
#> - 28 days
#> - 23 hours
#> - 30 minutes
#> - 19 seconds
#>
#> This is the exact time that has elapsed since Neil Armstrong's historic touchdown on the moon.
```

That's correct! Without any further guidance, the chat model decided to call our tool function and successfully used its result in formulating its response.

(Full disclosure: I originally tried this example with the default model of `gpt-4o-mini` and it got the tool calling right but the date math wrong, hence the explicit `model="gpt-4o"`.)

This tool example was extremely simple, but you can imagine doing much more interesting things from tool functions: calling APIs, reading from or writing to a database, kicking off a complex simulation, or even calling a complementary GenAI model (like an image generator). Or if you are using elmer in a Shiny app, you could use tools to set reactive values, setting off a chain of reactive updates.

### Tool limitations

Remember that tool arguments come from the chat model, and tool results are returned to the chat model. That means that only simple, {jsonlite} compatible data types can be used as inputs and outputs. It's highly recommended that you stick to strings/character, numbers, booleans/logical, null, and named or unnamed lists of those types. And you can forget about using functions, environments, external pointers, R6 classes, and other complex R objects as arguments or return values. Returning data frames seems to work OK, although be careful not to return too much data, as it all counts as tokens (i.e., they count against your context window limit and also cost you money).
</tool-calling.Rmd>


Here is the README.md for jcheng5/shinychat:
<README.md>
# shinychat

<!-- badges: start -->
[![R-CMD-check](https://github.com/jcheng5/shinychat/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/jcheng5/shinychat/actions/workflows/R-CMD-check.yaml)
<!-- badges: end -->

Chat UI component for [Shiny for R](https://shiny.posit.co/).

(For [Shiny for Python](https://shiny.posit.co/py/), see [ui.Chat](https://shiny.posit.co/py/components/display-messages/chat/).)

## Installation

You can install the development version of shinychat from [GitHub](https://github.com/) with:

``` r
# install.packages("pak")
pak::pak("jcheng5/shinychat")
```

## Example

To run this example, you'll first need to create an OpenAI API key, and set it in your environment as `OPENAI_API_KEY`.

You'll also need to call `pak::pak("hadley/elmer")` to install the {[elmer](https://github.com/hadley/elmer)} package.

```r
library(shiny)
library(shinychat)

ui <- bslib::page_fluid(
  chat_ui("chat")
)

server <- function(input, output, session) {
  chat <- elmer::chat_openai(system_prompt = "You're a trickster who answers in riddles")
  
  observeEvent(input$chat_user_input, {
    stream <- chat$stream_async(input$chat_user_input)
    chat_append("chat", stream)
  })
}

shinyApp(ui, server)
```
</README.md>

