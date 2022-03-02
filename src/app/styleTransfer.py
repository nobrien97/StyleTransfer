import tensorflow as tf
import tensorflow_hub as hub
import numpy as np
import PIL.Image
from os import path
from random import randint

def loadImg(pathToImg):
    maxDim = 512
    img = tf.io.read_file(pathToImg)
    img = tf.image.decode_image(img, channels = 3)
    img = tf.image.convert_image_dtype(img, tf.float32)

    shape = tf.cast(tf.shape(img)[:-1], tf.float32)
    longDim = max(shape)
    scale = maxDim / longDim

    newShape = tf.cast(shape * scale, tf.int32)
    
    img = tf.image.resize(img, newShape)
    img = img[tf.newaxis, :]
    return img

def exportImage(tf_img):
    tf_img = tf_img * 255
    tf_img = np.array(tf_img, dtype = np.uint8)
    if (np.ndim(tf_img) > 3):
        assert tf_img.shape[0] == 1
        tf_img = tf_img[0]
    return PIL.Image.fromarray(tf_img)

def runModel(img, style):    
    suffix = str(randint(0, 1e32))
    img = path.abspath(img)
    style = path.abspath(style)
    # Load images from file
    contentImage = loadImg(img)
    styleImage = loadImg(style)

    # Load and run the model
    styliseModel = hub.load('../../model')
    stylisedModel = styliseModel(tf.constant(contentImage), tf.constant(styleImage))[0]

    # Save the image
    imgName = path.splitext(img)
    exportImage(stylisedModel).save(imgName[0] + "_stylised" + suffix + imgName[1])
    return (path.basename(imgName[0]) + "_stylised" + suffix + imgName[1])