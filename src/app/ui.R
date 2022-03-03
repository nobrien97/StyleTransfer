# Shiny app to run this python style transfer tool

library(shiny)
library(shinyjs)

ui <- fluidPage(
    useShinyjs(),
    titlePanel("Tensorflow Style Transfer Tool"),
    h3("Combines a main image with the style of another."),
    hr(),
    fluidRow(
      br(),
      column(width = 6,
            h4("Main Image file"),
            radioButtons(inputId = "mainLocalURL", label = "Upload", choices = c("Local File", "URL")), 
            
            conditionalPanel("input.mainLocalURL != 'URL'",
              fileInput(inputId = "inputMainLocal", "Main Image", accept = "image/*")
            ),
            conditionalPanel("input.mainLocalURL == 'URL'",
              textInput(inputId = "inputMainURL", "Main Image (link)")
            ),
            actionButton(inputId = "renderButton", "Go!", icon = icon("play"))),
      column(width = 6,
             h4("Style Image file"),
             radioButtons(inputId = "styleLocalURL", label = "Upload", choices = c("Local File", "URL")), 
             conditionalPanel("input.styleLocalURL != 'URL'",
                              fileInput(inputId = "inputStyleLocal", "Style Image", accept = "image/*")
             ),
             conditionalPanel("input.styleLocalURL == 'URL'",
                              textInput(inputId = "inputStyleURL", "Style Image (link)")))
    ),
    hr(),
    fluidRow(
      column(width = 12,
             h3(textOutput(outputId = "outputHeader")),
             plotOutput("inputInsert"),
             htmlOutput("imageInsert"),
             hr()
        )
    )
)
