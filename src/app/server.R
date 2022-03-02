# Shiny app to run this python style transfer tool

library(shiny)
library(shinyjs)
library(shinyalert)
library(reticulate)
library(tools)
library(httr)

# Helper function to prevent doubleclicking run button etc.
buttonLocker <- function(buttons) {
  for (button in buttons)
    toggleState(button)
} 


server <- function(input, output, session) {
  session$userData$rootTmpPath <- tempdir()
  session$userData$buttons <- c("renderButton", "styleLocalURL", "mainLocalURL", 
                                "inputMainLocal", "inputStyleLocal",
                                "inputMainURL", "inputStyleURL")
  
    # Get the uploaded file paths
  mainPath <- reactive({
    if (input$mainLocalURL != "URL") {
      filename <- basename(input$inputMainLocal$datapath)
      file.copy(input$inputMainLocal$datapath, session$userData$rootTmpPath, overwrite = T)
      paste0(session$userData$rootTmpPath, "/", filename)
    } else {
      # Download the file, print the name
      filename <- basename(input$inputMainURL)
      # Sanitise if we have extra things on the end of the extension
      filename <- gsub("\\?\\d*$", "", filename)
      newMainPath <- paste0(session$userData$rootTmpPath, "/", filename)
      GET(input$inputMainURL,
          write_disk(newMainPath, overwrite = T))
      newMainPath
    }
  })
  
  
  # Copy files to a known directory so we know where they'll be copied to
  stylePath <- reactive({
    if (input$styleLocalURL != "URL") {
      filename <- basename(input$inputStyleLocal$datapath)
      file.copy(input$inputStyleLocal$datapath, session$userData$rootTmpPath, overwrite = T)
      paste0(session$userData$rootTmpPath, "/", filename)
    } else {
      filename <- basename(input$inputStyleURL)
      # Sanitise if we have extra things on the end of the extension
      filename <- gsub("\\?\\d*$", "", filename)
      newStylePath <- paste0(session$userData$rootTmpPath, "/", filename)
      GET(input$inputStyleURL,
          write_disk(newStylePath, overwrite = T))
      newStylePath
      
    }
  })

  
  
  observeEvent(input$renderButton, {
    buttonLocker(session$userData$buttons)
    # Make sure we have both inputs
    if ((is.null(input$inputMainLocal) & input$inputMainURL == "") | (is.null(input$inputStyleLocal) & input$inputStyleURL == "")) {
      shinyalert("Error", "Please submit both an image to permutate and a style image.")
      buttonLocker(session$userData$buttons)
      return()
    }
    
    
    # Run python code
    source_python("styleTransfer.py")
    session$userData$outputFilename <- tryCatch({
      runModel(mainPath(), stylePath())
    },
    error = function(cond){
      shinyalert("Error", cond)
      return()
    })

    # Insert the figure
    # If we've run it before, remove the old one
    removeUI(selector = "#stylisedImage", immediate = T)
    
    insertUI(selector = "#imageInsert",
             ui = tags$div(id = "stylisedImage",
                           fluidRow(
                             column(12,
                                    imageOutput("finalImage"))
                           )))
    
    # Release the lock
    buttonLocker(session$userData$buttons)  
  }) 
  # Handle rendering the image
  output$imageInsert <- renderUI({
    input$renderButton
    if (!is.null(session$userData$rootTmpPath)) {
      addResourcePath("imgpath", session$userData$rootTmpPath)
      framePrint <- tags$img(src=paste0("imgpath/", session$userData$outputFilename),
                             style = "max-height: 100%; max-width: 100%;")
    }
  })
  
  # Clean up temp files
#  session$onSessionEnded(function(tempPath = session$userData$rootTmpPath) {
#    unlink(tempPath, recursive = T)
#  })

}