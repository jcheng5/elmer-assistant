library(dotenv)
library(shiny)
library(shinychat)
library(elmer)
library(bslib)

prompt <- paste(readLines("prompt.generated.md"), collapse = "\n")

ui <- page_fluid(
  class = "pt-5",
  tags$style("a:not(:hover) { text-decoration: none; }"),
  chat_ui("chat")
)

server <- function(input, output, session) {
  chat <- chat_openai(model = "gpt-4o", system_prompt = prompt)
  observeEvent(input$chat_user_input, {
    chat_append("chat", chat$stream_async(input$chat_user_input))
  })
  chat_append("chat", "👋 Hi, I'm **Elmer Assistant**! I'm here to answer questions about [elmer](https://github.com/hadley/elmer) and [shinychat](https://github.com/jcheng5/shinychat), or to generate code for you.")
}

shinyApp(ui, server)
