#%%
import tensorflow as tf
import tensorflow_hub as hub

import matplotlib.pyplot as plt
import matplotlib as mpl
mpl.rcParams['figure.figsize'] = (12, 12)
mpl.rcParams['axes.grid'] = False

import numpy as np
import PIL.Image

#%%
def tensorToImage(tensor):
    tensor *= 255
    tensor = np.array(tensor, dtype = np.uint8)
    if np.ndim(tensor) > 3:
        assert tensor.shape[0] == 1
        tensor = tensor[0]
    return PIL.Image.fromarray(tensor)

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

def showImg(img, title=None):
    if len(img.shape) > 3:
        img = tf.squeeze(img, axis=0)
    plt.imshow(img)
    if title:
        plt.title(title)

#%%
# contentPath = tf.keras.utils.get_file(None, 'file:///Z:/Downloads2/force-of-will.jpg')
# stylePath = tf.keras.utils.get_file(None, 'file:///Z:/Downloads2/thrillofpossibility.jpg')
contentPath = 'Z:/Downloads2/force-of-will.jpg'
stylePath = 'Z:/Downloads2/thrillofpossibility.jpg'

contentImage = loadImg(contentPath)
styleImage = loadImg(stylePath)

plt.subplot(1,2,1)
showImg(contentImage, 'Content Image')

plt.subplot(1,2,2)
showImg(styleImage, 'Style Image')


# %%
# Load model
styliseModel = hub.load('../../model')

# run model
results = styliseModel(tf.constant(contentImage), tf.constant(styleImage))

#%%
stylisedImage = results[0]

# Visualise model
plt.subplot(1,2,2)
showImg(stylisedImage, 'Stylised Image')

# %%
