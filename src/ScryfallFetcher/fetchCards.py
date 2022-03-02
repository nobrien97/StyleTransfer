import scrython


def selectCards(content: str, contentSet: str, style: str, styleSet: str, contentStyle = "", styleStyle = ""):
    # Get the cards, and make sure we actually have gotten the card
    if (len(contentStyle)):
        cardContent = scrython.Named(exact=content, set=contentSet, frame_effects=contentStyle)
        
    contentImg = cardContent.image_uris(image_type="art_crop")

    cardStyle = scrython.Named(exact=style, set=styleSet)
    styleImg = cardStyle.image_uris(image_type="art_crop")
    cardContent.set