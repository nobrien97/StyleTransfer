# Shiny Style Transfer

A Shiny app that loads a Tensorflow Style-Transfer model and tries to generate a stylised output from a given 'main' image and 'style' image. Allows for local upload or downloads images from a given URL. It even checks if it can load an image from the URL and spits out an error if it can't!

Only crashes sometimes! 

This is just a little test project to learn a bit of python and tensorflow, as well as practicing my Shiny skills. As a result, it's a bit janky and probably won't work without a bit of tinkering. You'll likely need to modify your reticulate/python configuration in R/RStudio. Any necessary package requirements for R and Python can be found by reading the code in `src/app`. 
The model referenced in the scripts can be downloaded from [here](https://tfhub.dev/google/magenta/arbitrary-image-stylization-v1-256/2). 
