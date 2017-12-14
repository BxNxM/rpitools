import subprocess

def page(display):
    display.head_page_bar_switch(False, False)

    padding = 4
    shape_width = 20
    top = padding + 8
    bottom = display.disp.height-padding - 8
    # Move left to right keeping track of the current x position for drawing shapes.
    x = padding
    # Draw an ellipse.
    display.draw.ellipse((x, top , x+shape_width, bottom), outline=255, fill=0)
    x += shape_width+padding
    # Draw a rectangle.
    display.draw.rectangle((x, top, x+shape_width, bottom), outline=255, fill=0)
    x += shape_width+padding
    # Draw a triangle.
    display.draw.polygon([(x, bottom), (x+shape_width/2, top), (x+shape_width, bottom)], outline=255, fill=0)
    x += shape_width+padding
    # Draw an X.
    display.draw.line((x, bottom, x+shape_width, top), fill=255)
    display.draw.line((x, top, x+shape_width, bottom), fill=255)
    x += shape_width+padding

    display.virtual_button("right")

def main():
    print("hello bello")
