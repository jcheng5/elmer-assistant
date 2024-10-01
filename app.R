library(dotenv)
library(shiny)
library(shinychat)
library(elmer)
library(bslib)

files <- list.files("data", pattern = "*.md", full.names = TRUE)
project_prompts <- vapply(files, function(file) {
  project_name <- tools::file_path_sans_ext(basename(file))
  file_content <- readLines(file, warn = FALSE)
  file_content <- paste(file_content, collapse = "\n")
  paste0(
    "Here is the README.md for ",
    project_name,
    "\n\n<README>\n",
    file_content,
    "\n</README>\n\n"
  )
}, character(1))
project_prompts <- paste(project_prompts, collapse = "")
prompt <- paste0(
  paste(readLines("prompt.md"), collapse = "\n"),
  "\n\n",
  project_prompts
)

ui <- page_fluid(class = "pt-5",
  tags$style("a:not(:hover) { text-decoration: none; }"),
  chat_ui("chat")
)

server <- function(input, output, session) {
  chat <- new_chat_openai(model = "gpt-4o", system_prompt = prompt)
  observeEvent(input$chat_user_input, {
    chat_append("chat", chat$stream_async(input$chat_user_input))
  })
  chat_append("chat", "👋 Hi, I'm **Elmer Assistant**! I'm here to answer questions about [elmer](https://github.com/hadley/elmer) and [shinychat](https://github.com/jcheng5/shinychat), or to generate code for you.")
}

shinyApp(ui, server)
