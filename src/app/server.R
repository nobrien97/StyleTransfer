# Shiny app to run this python style transfer tool

library(shiny)
library(shinyjs)
library(shinyalert)
library(shinycssloaders)
library(reticulate)
library(tools)
library(httr)
library(magick)

# Helper function to prevent doubleclicking run button etc.
buttonLocker <- function(buttons) {
  for (button in buttons)
    toggleState(button)
} 

# Helper function for errors involving files
# We return a string error message if we have an invalid file
# Otherwise we return an int: 1 = converted webp 'main' to png
#                             2 = converted webp 'style' to png
#                             3 = converted webps 'main' and 'style' to png
#                             0 = we got ourselves a non-webp image
fileCheck <- function(main, style, pyscript) {
  source_python(pyscript)
  mainFile <- imgType(main)
  styleFile <- imgType(style)
  
  validTypes = c("bmp", "gif", "jpeg", "png", "webp")
  
  # Try to convert webp files
  if (mainFile == "webp" & styleFile == "webp") {
    convertWebp(main)
    convertWebp(style)
    return(3)
  }
  
  if (mainFile == "webp") {
    convertWebp(main)
    return(1)
  }
  
  if (styleFile == "webp") {
    convertWebp(style)
    return(2)
  }
  
  if (!any(mainFile == validTypes)) {
    return("Invalid main file. Please upload an BMP, GIF, JPEG, or PNG image.")
  }
  
  if (!any(styleFile == validTypes)) {
    return("Invalid style file. Please upload an BMP, GIF, JPEG, or PNG image.")
  }
  
  return(0)
}

# Helper function for moving files to a temp directory, and downloading from URL
fileMove <- function(URL = TRUE, curPath, newPath, newName) {
  if (URL) {
    # Download the file, print the name
    filename <- paste0(newName, ".", file_ext(sub("\\?.+", "", curPath)))
    # Sanitise if we have extra things on the end of the extension
    filename <- gsub("\\?\\d*$", "", filename)
    newMainPath <- paste0(newPath, "/", filename)
    GET(curPath,
        write_disk(newMainPath, overwrite = T))
    return(newMainPath) 
  } else {
    filename <- paste0(newName, ".", file_ext(curPath))
    ext <- file_ext(filename)
    file.copy(curPath, paste0(newPath, "/", filename), overwrite = T)
    return(paste0(newPath, "/", filename))
  }
}


server <- function(input, output, session) {
  # When we start up, make sure our 'result' header lets the user know we are 
  # loading the model before they start putting in inputs
  html(id = "outputHeader", "Loading model...")
  session$userData$rootTmpPath <- tempdir()
  session$userData$buttons <- c("renderButton", "styleLocalURL", "mainLocalURL", 
                                "inputMainLocal", "inputStyleLocal",
                                "inputMainURL", "inputStyleURL")
  
  # Initialise python code, load the model and make sure the user can't do 
  # anything until that's done
  source_python("styleTransfer.py")
  
  buttonLocker(session$userData$buttons)
  model <- loadModel('../../model')
  output$outputHeader <- renderText({"Result"})
  buttonLocker(session$userData$buttons)
  
  # Create reactives to return correct paths and move files to tempdir() if needed
  mainPath <- reactive({
    if (input$mainLocalURL != "URL") {
      fileMove(URL = F, curPath = input$inputMainLocal$datapath, 
               newPath = session$userData$rootTmpPath, newName = paste0("main", as.integer(runif(1, 0, .Machine$integer.max))))
    } else {
      fileMove(URL = T, curPath = input$inputMainURL, 
               newPath = session$userData$rootTmpPath, newName = paste0("main", as.integer(runif(1, 0, .Machine$integer.max))))
    }
  })
  
  stylePath <- reactive({
    if (input$styleLocalURL != "URL") {
      fileMove(URL = F, curPath = input$inputStyleLocal$datapath, 
               newPath = session$userData$rootTmpPath, newName = paste0("style", as.integer(runif(1, 0, .Machine$integer.max))))
    } else {
      fileMove(URL = T, curPath = input$inputStyleURL, 
               newPath = session$userData$rootTmpPath, newName = paste0("style", as.integer(runif(1, 0, .Machine$integer.max))))
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
    
    
    # Move the files to temp, get their paths
    mImg <- mainPath()
    sImg <- stylePath()    
    
    # Check that both files are images, and that it's readable
    errorMsg <- fileCheck(mImg, sImg, "styleTransfer.py")
    if (nchar(errorMsg) > 3) {
      shinyalert("Error", errorMsg)
      return()
    } else if (errorMsg == 1) {
      mImg <- paste0(file_path_sans_ext(mImg), ".png")
    } else if (errorMsg == 2) {
      sImg <- paste0(file_path_sans_ext(sImg), ".png")
    } else if (errorMsg == 3) {
      mImg <- paste0(file_path_sans_ext(mImg), ".png")
      sImg <- paste0(file_path_sans_ext(sImg), ".png")
    }
    
    # Store the input filenames so we can plot them later
    session$userData$lastInputMain <- mImg
    session$userData$lastInputStyle <- sImg
    
    # Run the model
    session$userData$outputFilename <- tryCatch({
      runModel(mImg, sImg, model)
    },
    error = function(cond){
      shinyalert("Error", "Could not read one (or both) of the input images.")
      return()
    })

    # Insert the figure
    # If we've run it before, remove the old one
    removeUI(selector = "#stylisedImage", immediate = T)
    # Remove the last image 
    if (!is.null(session$userData$lastGeneratedImage)) {
      file.remove(session$userData$lastGeneratedImage)
    }
    # Set the path name of this just generated image
    session$userData$lastGeneratedImage <- paste0(session$userData$rootTmpPath, "/", session$userData$outputFilename)
    

    # Release the lock
    buttonLocker(session$userData$buttons)  
  }) 
  # Handle rendering the image
  output$imageInsert <- renderUI({
    input$renderButton
    if (!is.null(session$userData$outputFilename)) {
      addResourcePath("imgpath", session$userData$rootTmpPath)
      framePrint <- tags$img(src=paste0("imgpath/", session$userData$outputFilename),
                             style = "max-height: 100%; max-width: 100%; margin-left: auto; margin-right: auto; display: block;")
      
    } #else {
      #framePrint <- tags$img(src="www/banner.jpg"),
       #                      style = "max-height: 100%; max-width: 100%; margin-left: auto; margin-right: auto; display: block;")
    #}
  })
  
  output$inputInsert <- renderPlot({
    input$renderButton
    if (!is.null(session$userData$outputFilename)) {
      mainImg <- image_read(file_path_as_absolute(session$userData$lastInputMain))
      styleImg <- image_read(file_path_as_absolute(session$userData$lastInputStyle))
      par(mfrow=c(1,2))
      plot(as.raster(mainImg))
      plot(as.raster(styleImg))
    }
    
  })
  

}