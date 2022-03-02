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
      # Fix the height and width of the image to the row dimensions
      tags$style(HTML("div#imageInsert img {max-width: 100%; max-height: 100%;}")),
      column(width = 12,
             htmlOutput("imageInsert")
        )
    )
)
