library(dotenv)
library(shiny)
library(shinychat)
library(ellmer)
library(bslib)

prompt <- paste(readLines("prompt.generated.md"), collapse = "\n")

ui <- page_fluid(
  class = "pt-5",
  tags$style("a:not(:hover) { text-decoration: none; }"),
  chat_ui("chat")
)

server <- function(input, output, session) {
  chat <- chat_openai(model = "gpt-4o", system_prompt = prompt)
  # chat <- chat_claude(model = "claude-3-5-sonnet-latest", system_prompt = prompt)
  observeEvent(input$chat_user_input, {
    chat_append("chat", chat$stream_async(input$chat_user_input))
  })
  chat_append("chat", "👋 Hi, I'm **Ellmer Assistant**! I'm here to answer questions about [ellmer](https://github.com/tidyverse/ellmer) and [shinychat](https://github.com/posit-dev/shinychat), or to generate code for you.")
}

shinyApp(ui, server)
