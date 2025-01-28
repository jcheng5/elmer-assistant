A chatbot that can answer questions about the R packages [ellmer](https://github.com/hadley/ellmer) and [shinychat](https://github.com/posit-dev/shinychat). It's implemented by simply stuffing the README.md files from both projects into a system prompt for GPT-4o.

## Live app

[https://jcheng.shinyapps.io/ellmer-assistant/](https://jcheng.shinyapps.io/ellmer-assistant/)

## Installation

```r
pak::pak(c("hadley/ellmer", "posit-dev/shinychat", "dotenv"))
```

You must also create a .env file containing your OpenAI API key:

```
OPENAI_API_KEY=your-api-key
```

## Starting the app

```r
shiny::runApp()
```

## License

[CC0](https://creativecommons.org/public-domain/cc0/)
